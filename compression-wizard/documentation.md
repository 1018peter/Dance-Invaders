Import the entire folder to your device and put the image file to be compressed in the same directory as the executable,
then run the executable.

The program supports three customizable options: The number of colors to use for the palette (in integer powers of 32), 
whether to use Gaussian Blur, and whether to sharpen the color (which is equivalent to using the magic wand tool to merge connected pixels
 that are similar in color.
 
 The program also accepts command-line arguments, as follows:
 - Arg 1: A string, containing the filename.
 - Arg 2: An integer flag. 0 means not using Gaussian Blur.
 - Arg 3: An integer flag. 0 means not sharpening the color.
 
 The program will output a preview image of the "compressed" file, a COE file representing the compressed file in dense matrix representation, 
 another in sparse matrix representation, and finally a diagnostics .txt file that displays metadata of the compression process.
