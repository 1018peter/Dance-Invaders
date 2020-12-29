#include <OpenImageIO/imageio.h>
#include <boost/multi_array.hpp>
#include <array>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <list>
#include <utility>
#include <algorithm>
#include <stack>
#include <unordered_set>
using namespace OIIO;

struct RGBPixel;
struct Color;

struct Color {
	float R, G, B;
	Color& operator+=(const Color& rhs) {
		R += rhs.R;
		G += rhs.G;
		B += rhs.B;
		return *this;
	}

	Color operator*(float scalar) {
		return Color{ R * scalar, G * scalar, B * scalar };
	}

	int operator-(const Color& rhs) {
		return abs(rhs.R - R) + abs(rhs.G - G) + abs(rhs.B - B);
	}
	Color() = default;
	Color(float r, float g, float b) : R(r), G(g), B(b) {};

};

struct RGBPixel {
	int row, col;
	UINT8 R, G, B;
	int operator-(const RGBPixel& rhs) {
		return abs(int(rhs.R) - int(R)) + abs(int(rhs.G) - int(G)) + abs(int(rhs.B) - int(B));
	}
};

struct LowPrecisionRGBEqual {
	bool operator()(const RGBPixel& lhs, const RGBPixel& rhs) {
		return ((lhs.R >> 2) == (rhs.R >> 2) \
			&& (lhs.G >> 2) == (rhs.G >> 2) \
			&& (lhs.B >> 2) == (rhs.B >> 2));
	}
};

struct PaletteField {
	UINT8 R, G, B;
};

struct PalettePixel {
	int row, col, pid;
};

template<typename integral_T>
inline bool bit_select(integral_T from, int id) {
	return from & (1 << id);
}

int main(int argc, char *argv[]) {
	std::string cmd;
	std::string filename;
	if (argc > 7) {
		std::cout << "Too many arguments!\n";
		return -1;
	}

	if (argc == 1) {
		std::cout << "Please specify the filename: ";
		std::cin >> filename;
	}
	else filename = argv[1];
	std::string filename_raw;
	for (auto c : filename) if (c == '.') break; else filename_raw.push_back(c);
	
	auto source = ImageInput::open(filename);
	if (!source) {
		std::cout << "Failed to open file " << filename << ". Enter any key to end\n";
		std::cin >> cmd;
		return -1;
	}
	std::cout << "Opened file " << filename << '\n';



	const ImageSpec& spec = source->spec();
	int xres = spec.width;
	int yres = spec.height;
	int channels = spec.nchannels;
	if (channels != 3 && channels != 4) {
		std::cout << filename << " is not an RGB/RGBA file. Enter any key to end\n";
		std::cin >> cmd;
		return -1;
	}
	std::cout << "Decoded image specs.\n";
	std::vector<unsigned char> pixels(xres * yres * channels);
	source->read_image(TypeDesc::UINT8, &pixels[0]);
	std::cout << "Read file.\n";
	source->close();


	std::ofstream diagnostics(filename_raw + "_diagnostics.txt");
	diagnostics << "Source image: " << filename << '\n';
	diagnostics << "- Height (vertical resolution): " << yres << '\n';
	diagnostics << "- Width (horizontal resolution): " << xres << '\n';

	int palette_size;
	if (argc <= 2) {
		std::cout << "Please specify the size of the palette (Must be a power of 2 greater than 1): ";
		std::cin >> palette_size;
	}
	else palette_size = std::stoi(argv[2]);
	diagnostics << "Configurations: \n";
	diagnostics << "- Palette Size: " << palette_size << " colors (" << std::log2(palette_size) << " bits)\n";
	
	if (palette_size % 2 != 0) {
		std::cout << "Invalid palette size.\n";
		return -1;
	}

	bool enable_blur;
	if (argc <= 3) {
		while (1) {
			std::cout << "Apply Gaussian blur before quantization? (Y/n): ";
			std::cin >> cmd;
			if (cmd == "Y") {
				enable_blur = true;
				break;
			}
			else if (cmd == "n") {
				enable_blur = false;
				break;
			}
		}
	}
	else enable_blur = std::stoi(argv[3]);
	diagnostics << "- Gaussian Blur: " << ((enable_blur) ? "True\n" : "False\n");

	bool sharpen;
	if (argc <= 4) {
		while (1) {
			std::cout << "Sharpen color? (Y/n): ";
			std::cin >> cmd;
			if (cmd == "Y") {
				sharpen = true;
				break;
			}
			else if (cmd == "n") {
				sharpen = false;
				break;
			}
		}
	}
	else sharpen = std::stoi(argv[4]);
	diagnostics << "- Sharpen color: " << ((sharpen) ? "True\n" : "False\n");

	bool sample;
	if (argc <= 5) {
		while (1) {
			std::cout << "Arbitrary color sampling? (Y/n): ";
			std::cin >> cmd;
			if (cmd == "Y") {
				sample = true;
				break;
			}
			else if (cmd == "n") {
				sample = false;
				break;
			}
		}

	}
	else sample = std::stoi(argv[5]);
	diagnostics << "- Arbitrary color sampling: " << ((sample) ? "True\n" : "False\n");

	
	std::array<float, 3> Gaussian{ 6.0, 4.0, 1.0 };
	boost::multi_array<Color, 2>::extent_gen extent;
	boost::multi_array<Color, 2> A(extent[yres][xres]);
	boost::multi_array<Color, 2> B(extent[yres][xres]);
	boost::multi_array<Color, 2> C(extent[yres][xres]);
	std::vector<RGBPixel> RGBpixels;
	RGBpixels.reserve(xres * yres);
	int byte_n = 0;
	int row_n = 0, col_n = 0;
	RGBPixel curPixel;
	for (auto byte : pixels) {
		if (byte_n % channels == 0) {
			curPixel.R = byte;
		}
		else if (byte_n % channels == 1) {
			curPixel.G = byte;
		}
		else if(byte_n % channels == 2){
			curPixel.B = byte;
			curPixel.row = row_n;
			curPixel.col = col_n;
			if (enable_blur) { 
				A[curPixel.row][curPixel.col] = Color{ float(curPixel.R), float(curPixel.G), float(curPixel.B) }; 
				B[curPixel.row][curPixel.col] = Color{ 0,0,0 };
			}
			if (sharpen) {
				C[curPixel.row][curPixel.col] = Color{ float(curPixel.R), float(curPixel.G), float(curPixel.B) };
			}
			RGBpixels.push_back(curPixel);
			++col_n;
			if (col_n == xres) {
				col_n = 0;
				++row_n;
			}
		}
		++byte_n;
	}
	std::cout << "Decoded RGB pixels.\n";

	if (sharpen) {
		std::stack<std::pair<int, int>> dfs_stk;
		for (int y = 0; y < yres; ++y) {
			for (int x = 0; x < xres; ++x) {
				dfs_stk.push(std::make_pair(y, x));
				while (!dfs_stk.empty()) {
					int cur_y = dfs_stk.top().first;
					int cur_x = dfs_stk.top().second;
					dfs_stk.pop();
					if (cur_x < 0 || cur_y < 0 || cur_x >= xres || cur_y >= yres || (C[cur_y][cur_x] - C[y][x] < 96)) continue;
					C[cur_y][cur_x] = C[y][x];
					dfs_stk.push(std::make_pair(y + 1, x));
					dfs_stk.push(std::make_pair(y - 1, x));
					dfs_stk.push(std::make_pair(y, x + 1));
					dfs_stk.push(std::make_pair(y, x - 1));
				}
				
			}
		}
		if (enable_blur) {
			for (int y = 0; y < yres; ++y) {
				for (int x = 0; x < xres; ++x) {
					A[y][x] = C[y][x];
				}
			}
		}
		else {
			for (auto& pixel : RGBpixels) {
				pixel.R = UINT8(C[pixel.row][pixel.col].R);
				pixel.G = UINT8(C[pixel.row][pixel.col].G);
				pixel.B = UINT8(C[pixel.row][pixel.col].B);
			}
		}
	}

	if (enable_blur) {
		for (auto& pixel : RGBpixels) {
			B[pixel.row][pixel.col] += A[pixel.row][pixel.col] * (Gaussian[0]);
			for (int i = 1; i < 3; ++i) {
				if (pixel.row + i < yres) { 
					B[pixel.row][pixel.col] += A[pixel.row + i][pixel.col] * Gaussian[i]; 
				}
				if (pixel.row - i >= 0) {
					B[pixel.row][pixel.col] += A[pixel.row - i][pixel.col] * Gaussian[i];
				}
			}
		}
		for (auto& pixel : RGBpixels) {
			int mat_size = (5 - (pixel.row <= 1) - (pixel.row < 1) - (pixel.row > yres - 2) - (pixel.row >= yres - 2)) \
				* (5 - (pixel.col <= 1) - (pixel.col < 1) - (pixel.col > xres - 2) - (pixel.col >= xres - 2));
			Color blurred{ 0, 0, 0 };
			blurred += B[pixel.row][pixel.col] * (Gaussian[0]);
			for (int i = 1; i < 3; ++i) {
				if (pixel.col + i < xres) {
					blurred += B[pixel.row][pixel.col + i] * Gaussian[i];
				}
				if (pixel.col - i >= 0) {
					blurred += B[pixel.row][pixel.col - i] * Gaussian[i];
				}
			}
			float divi = 256;
			if (mat_size == 20) {
				divi = 240;
			}
			else if (mat_size == 16) {
				divi = 225;
			}
			else if (mat_size == 15) {
				divi = 176;
			}
			else if (mat_size == 12) {
				divi = 165;
			}
			else if (mat_size == 9) divi = 157;
			pixel.R = UINT8(blurred.R / divi);
			pixel.G = UINT8(blurred.G / divi);
			pixel.B = UINT8(blurred.B / divi);
		}
		std::cout << "Blur complete\n";
	}

	std::list<std::vector<RGBPixel>> pixel_buckets;
	std::list<std::vector<RGBPixel>> sampled_buckets;
	if (sample) {
		// Dump all pixels into a multiset identified by their colors
		boost::multi_array<std::vector<RGBPixel>, 3> hash_map(extent[64][64][64]);
		for (auto& pixel : RGBpixels) hash_map[pixel.R / 4][pixel.G / 4][pixel.B / 4].push_back(pixel);
		RGBpixels.clear();
		for(int i = 0; i < 64; i++)
			for(int j = 0; j < 64; j++)
				for (int k = 0; k < 64; k++) {
					if (hash_map[i][j][k].size()) std::cout << "(" << i << ", " << j << ", " << k << ") has size " << hash_map[i][j][k].size() << '\n';
					if (hash_map[i][j][k].size() >= yres * xres / palette_size) {
						std::cout << "Sampling (" << i << ", " << j << ", " << k << ")\n";
						sampled_buckets.push_back(hash_map[i][j][k]);
					}
					else for (auto& pixel : hash_map[i][j][k]) {
						RGBpixels.push_back(pixel);
					}
				}

	}

	pixel_buckets.push_back(RGBpixels);
	// Color quantization: Using median cut.
	while (pixel_buckets.size() + sampled_buckets.size() < palette_size) {
		std::cout << "Median cut progress: " << pixel_buckets.size() + sampled_buckets.size() << "/" << palette_size << '\n';
		UINT8 R_max = 0, R_min = UINT8_MAX, G_max = 0, G_min = UINT8_MAX, B_max = 0, B_min = UINT8_MAX;
		for (auto& bucket : pixel_buckets) {
			if (bucket.empty()) continue;
			if(pixel_buckets.size() + sampled_buckets.size() >= palette_size) break;
			for (auto& pixel : bucket) {
				R_max = std::max(pixel.R, R_max);
				R_min = std::min(pixel.R, R_min);
				G_max = std::max(pixel.G, G_max);
				G_min = std::min(pixel.G, G_min);
				B_max = std::max(pixel.B, B_max);
				B_min = std::min(pixel.B, B_min);
			}
			if (R_max < R_min || G_max < G_min || B_max < B_min) {
				std::cout << "Negative Range Error: Bucket appears to be empty in median cut.\n";
				return -1;
			}
			UINT8 range_R = R_max - R_min;
			UINT8 range_G = G_max - G_min;
			UINT8 range_B = B_max - B_min;
			if (range_R > range_G && range_R > range_B) {
				std::sort(bucket.begin(), bucket.end(), \
					[](const RGBPixel& lhs, const RGBPixel& rhs) {
						return lhs.R < rhs.R;
					});
			}
			else if (range_G > range_R && range_G > range_B) {
				std::sort(bucket.begin(), bucket.end(), \
					[](const RGBPixel& lhs, const RGBPixel& rhs) {
						return lhs.G < rhs.G;
					});
			}
			else {
				std::sort(bucket.begin(), bucket.end(), \
					[](const RGBPixel& lhs, const RGBPixel& rhs) {
						return lhs.B < rhs.B;
					});
			}
			pixel_buckets.push_front(std::vector<RGBPixel>());
			int count = 0;
			int b_size = bucket.size() / 2;
			RGBPixel pivot = bucket.back();
			for (count = 0; count < b_size; ++count) {
				pivot = bucket.back();
				pixel_buckets.front().push_back(bucket.back());
				bucket.pop_back();
			}
			
		}
	}
	std::cout << "Median cut was successful.\n";
	for (auto& bucket : sampled_buckets) pixel_buckets.push_back(bucket);
	// Compressed buffer.
	std::vector<unsigned char> compressed(xres* yres* channels);

	// COE of dense representation
	std::vector<bool> dense_coe(palette_size * 3 * 4);
	int palette_id_size = static_cast<int>(std::log2(palette_size));
	int x_axis_size = static_cast<int>(std::log2(xres));
	int y_axis_size = static_cast<int>(std::log2(yres));
	int sparse_tuple_size = y_axis_size + x_axis_size + palette_id_size;
	std::vector<bool> sparse_coe(palette_size * 3 * 4);

	// Header

	std::list<PalettePixel> p_pixels;

	std::list<std::vector<RGBPixel>>::iterator biggest_bucket(pixel_buckets.begin());
	int bucket_id = 0;
	for (auto bucket = pixel_buckets.begin(); bucket != pixel_buckets.end(); ++bucket) {
		if (bucket->size() > biggest_bucket->size())
			biggest_bucket = bucket;
		++bucket_id;
	}

	std::cout << "Found the color with the largest area. (" <<  biggest_bucket->size() << ")\n";
	std::cout << "Sparsity: " << float(biggest_bucket->size()) / float(yres * xres) << '\n';
	diagnostics << "Computation results: \n";
	diagnostics << "- Sparsity: " << float(biggest_bucket->size()) / float(yres * xres) << '\n';
	diagnostics << "- Header size: " << palette_size * palette_id_size << " bits.\n";
	diagnostics << "- Palette colors: \n";
	std::swap(*pixel_buckets.begin(), *biggest_bucket);

	bucket_id = 0;
	// Assign a color to each bucket using each bucket's average.
	for (auto& bucket : pixel_buckets) {
		std::cout << "Processing bucket " << std::dec << bucket_id << '\n';
		unsigned int R_sum = 0, G_sum = 0, B_sum = 0;
		for (const auto& pixel : bucket) {
			R_sum += pixel.R;
			G_sum += pixel.G;
			B_sum += pixel.B;
		}
		UINT8 avg_R = (bucket.empty()) ? 0 : static_cast<UINT8>(R_sum / bucket.size());
		UINT8 avg_G = (bucket.empty()) ? 0 : static_cast<UINT8>(G_sum / bucket.size());
		UINT8 avg_B = (bucket.empty()) ? 0 : static_cast<UINT8>(B_sum / bucket.size());
		std::cout << "The color for bucket " << std::dec << bucket_id;
		std::cout << " is 0x" << std::hex << std::setfill('0') << std::setw(2) << int(avg_R);
		std::cout << std::hex << std::setfill('0') << std::setw(2) << int(avg_G);
		std::cout << std::hex << std::setfill('0') << std::setw(2) << int(avg_B) << '\n';
		diagnostics << "- - Color code for palette " << std::dec << bucket_id \
			<< ": 0x" << std::hex << std::setfill('0') << std::setw(2) << int(avg_R) \
			<< std::hex << std::setfill('0') << std::setw(2) << int(avg_G) \
			<< std::hex << std::setfill('0') << std::setw(2) << int(avg_B) << "\n";
		

		// Write palette field.

		for (int j = 7; j >= 4; --j) { 
			dense_coe[bucket_id * 3 * 4 + 7 - j] = bit_select(avg_R, j);
			sparse_coe[bucket_id * 3 * 4 + 7 - j] = bit_select(avg_R, j);
		}
		for (int j = 7; j >= 4; --j) {
			dense_coe[bucket_id * 3 * 4 + 4 + 7 - j] = bit_select(avg_G, j);
			sparse_coe[bucket_id * 3 * 4 + 4 + 7 - j] = bit_select(avg_G, j);
		}
		for (int j = 7; j >= 4; --j) {
			dense_coe[bucket_id * 3 * 4 + 8 + 7 - j] = bit_select(avg_B, j);
			sparse_coe[bucket_id * 3 * 4 + 8 + 7 - j] = bit_select(avg_B, j);
		}

		for (auto& pixel : bucket) {
			pixel.R = avg_R;
			pixel.G = avg_G;
			pixel.B = avg_B;
			compressed[pixel.row * (xres * channels) + pixel.col * channels] = pixel.R;
			compressed[pixel.row * (xres * channels) + pixel.col * channels + 1] = pixel.G;
			compressed[pixel.row * (xres * channels) + pixel.col * channels + 2] = pixel.B;
			if (channels == 4) compressed[pixel.row * (xres * channels) + pixel.col * channels + 3] = 255;
			p_pixels.push_back(PalettePixel{ pixel.row, pixel.col, bucket_id });
		}
		++bucket_id;	
	}
	p_pixels.sort([](const PalettePixel& lhs, const PalettePixel& rhs) {
		if (lhs.row == rhs.row) return lhs.col < rhs.col;
		else return lhs.row < rhs.row;
	});
	for (auto& pixel : p_pixels) {
		// Fill the palette id.
		for (int i = palette_id_size - 1; i >= 0; --i) {
			dense_coe.push_back(bit_select(pixel.pid, i));
		}
	}


	std::cout << "Completed bit vectors of the dense COE.\n";
	diagnostics << "- Size of dense COE: " << std::dec << dense_coe.size() << " bits. (" << float(dense_coe.size()) / 1024.0 << " Kbits)\n";

	
	
int id = 0;
	for (auto& pixel : p_pixels) {
		if (pixel.pid == 0) continue;
		for (int i = 0; i < y_axis_size; ++i) {
			sparse_coe.push_back(bit_select(pixel.col, y_axis_size - i - 1));

		}
		for (int i = 0; i < x_axis_size; ++i) {
			sparse_coe.push_back(bit_select(pixel.col, x_axis_size - i - 1));
		}
		for (int i = 0; i < palette_id_size; ++i) {
			sparse_coe.push_back(bit_select(pixel.pid, palette_id_size - i - 1));
		}
		++id;
	}
	std::cout << "Completed bit vectors of the sparse COE.\n";
	diagnostics << "- Size of sparse COE: " << std::dec << sparse_coe.size() << " bits. (" << float(sparse_coe.size()) / 1024.0 << " Kbits)\n";
	std::string compressed_image_name = "compressed_" + filename;
	std::unique_ptr<ImageOutput> compressed_out = ImageOutput::create(compressed_image_name);
	ImageSpec spec_cmpr(xres, yres, channels, TypeDesc::UINT8);
	compressed_out->open(compressed_image_name, spec_cmpr);
	compressed_out->write_image(TypeDesc::UINT8, &compressed[0]);
	compressed_out->close();
	std::cout << "Created preview image of the compression with filename: " << compressed_image_name << '\n';
	
	std::ofstream dense_outfile("dense_" + filename_raw + ".coe");
	std::ofstream sparse_outfile("sparse_" + filename_raw + ".coe");
	std::string header_radix = "memory_initialization_radix=16;\n";
	std::string header_vector = "memory_initialization_vector=\n";
	dense_outfile << header_radix << header_vector;
	sparse_outfile << header_radix << header_vector;
	id = 0;
	UINT8 hex_digit = 0;
	std::stringstream convert_stream;
	std::string convert_buf;
	for (auto bit : dense_coe) {
		hex_digit += bit << (7 - (id % 8));
		if (id % 8 == 7) {
			if (id > 7)  dense_outfile << ",\n";
			dense_outfile << std::hex << std::setfill('0') << std::setw(2) << int(hex_digit);
			hex_digit = 0;
			convert_buf.clear();
		}
		++id;
	}
	if (id == dense_coe.size()) { 
		if (id % 8 == 0) dense_outfile << ";\n";
		else {
			dense_outfile << ",\n";
			dense_outfile << std::hex << std::setfill('0') << std::setw(2) << int(hex_digit) << ";\n";
		}
	}
	dense_outfile.close();
	std::cout << "Created dense_" << filename_raw << ".coe\n";

	convert_buf.clear();
	id = 0;
	for (auto bit : sparse_coe) {
		hex_digit += bit << (7 - (id % 8));
		if (id % 8 == 7) {
			if (id > 7)  sparse_outfile << ",\n";
			sparse_outfile << std::hex << std::setfill('0') << std::setw(2) << int(hex_digit);
			hex_digit = 0;
			convert_buf.clear();
		}
		++id;
	}
	if (id == sparse_coe.size()) { 
		if (id % 8 == 0) sparse_outfile << ";\n";
		else {
			sparse_outfile << ",\n";
			sparse_outfile << std::hex << std::setfill('0') << std::setw(2) << int(hex_digit) << ";\n";
		}
	}
	sparse_outfile.close();
	std::cout << "Created sparse_" << filename_raw << ".coe\n";

	diagnostics.close();

	std::cout << "Execution successful. Diagnostics saved as " << filename_raw << "_diagnostics.txt. Input any key to exit.\n";
	std::cin >> cmd;
	
	return 0;

}