`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 13:57:31
// Design Name: 
// Module Name: alien_pixel_reader
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alien_pixel_reader(
    input clk,
    input [1:0] frame_num,
    input [1:0] alien_type,
    input [3:0] size_select,
    input [1:0] deriv_select,
    input [10:0] read_addr,
    output logic palette_out
    );
    
    
parameter [18:0] address_0_0_0_0 = 0;
parameter [18:0] address_0_0_0_1 = 2048;
parameter [18:0] address_0_0_0_2 = 4096;
parameter [18:0] address_0_0_0_3 = 6144;
parameter [18:0] address_0_0_1_0 = 8192;
parameter [18:0] address_0_0_1_1 = 10240;
parameter [18:0] address_0_0_1_2 = 12288;
parameter [18:0] address_0_0_1_3 = 14336;
parameter [18:0] address_0_1_0_0 = 16384;
parameter [18:0] address_0_1_0_1 = 18432;
parameter [18:0] address_0_1_0_2 = 20480;
parameter [18:0] address_0_1_0_3 = 22528;
parameter [18:0] address_0_1_1_0 = 24576;
parameter [18:0] address_0_1_1_1 = 26624;
parameter [18:0] address_0_1_1_2 = 28672;
parameter [18:0] address_0_1_1_3 = 30720;
parameter [18:0] address_1_0_0_0 = 32768;
parameter [18:0] address_1_0_0_1 = 34690;
parameter [18:0] address_1_0_0_2 = 36612;
parameter [18:0] address_1_0_0_3 = 38534;
parameter [18:0] address_1_0_1_0 = 40456;
parameter [18:0] address_1_0_1_1 = 42378;
parameter [18:0] address_1_0_1_2 = 44300;
parameter [18:0] address_1_0_1_3 = 46222;
parameter [18:0] address_1_1_0_0 = 48144;
parameter [18:0] address_1_1_0_1 = 50066;
parameter [18:0] address_1_1_0_2 = 51988;
parameter [18:0] address_1_1_0_3 = 53910;
parameter [18:0] address_1_1_1_0 = 55832;
parameter [18:0] address_1_1_1_1 = 57754;
parameter [18:0] address_1_1_1_2 = 59676;
parameter [18:0] address_1_1_1_3 = 61598;
parameter [18:0] address_2_0_0_0 = 63520;
parameter [18:0] address_2_0_0_1 = 65320;
parameter [18:0] address_2_0_0_2 = 67120;
parameter [18:0] address_2_0_0_3 = 68920;
parameter [18:0] address_2_0_1_0 = 70720;
parameter [18:0] address_2_0_1_1 = 72520;
parameter [18:0] address_2_0_1_2 = 74320;
parameter [18:0] address_2_0_1_3 = 76120;
parameter [18:0] address_2_1_0_0 = 77920;
parameter [18:0] address_2_1_0_1 = 79720;
parameter [18:0] address_2_1_0_2 = 81520;
parameter [18:0] address_2_1_0_3 = 83320;
parameter [18:0] address_2_1_1_0 = 85120;
parameter [18:0] address_2_1_1_1 = 86920;
parameter [18:0] address_2_1_1_2 = 88720;
parameter [18:0] address_2_1_1_3 = 90520;
parameter [18:0] address_3_0_0_0 = 92320;
parameter [18:0] address_3_0_0_1 = 94002;
parameter [18:0] address_3_0_0_2 = 95684;
parameter [18:0] address_3_0_0_3 = 97366;
parameter [18:0] address_3_0_1_0 = 99048;
parameter [18:0] address_3_0_1_1 = 100730;
parameter [18:0] address_3_0_1_2 = 102412;
parameter [18:0] address_3_0_1_3 = 104094;
parameter [18:0] address_3_1_0_0 = 105776;
parameter [18:0] address_3_1_0_1 = 107458;
parameter [18:0] address_3_1_0_2 = 109140;
parameter [18:0] address_3_1_0_3 = 110822;
parameter [18:0] address_3_1_1_0 = 112504;
parameter [18:0] address_3_1_1_1 = 114186;
parameter [18:0] address_3_1_1_2 = 115868;
parameter [18:0] address_3_1_1_3 = 117550;
parameter [18:0] address_4_0_0_0 = 119232;
parameter [18:0] address_4_0_0_1 = 120800;
parameter [18:0] address_4_0_0_2 = 122368;
parameter [18:0] address_4_0_0_3 = 123936;
parameter [18:0] address_4_0_1_0 = 125504;
parameter [18:0] address_4_0_1_1 = 127072;
parameter [18:0] address_4_0_1_2 = 128640;
parameter [18:0] address_4_0_1_3 = 130208;
parameter [18:0] address_4_1_0_0 = 131776;
parameter [18:0] address_4_1_0_1 = 133344;
parameter [18:0] address_4_1_0_2 = 134912;
parameter [18:0] address_4_1_0_3 = 136480;
parameter [18:0] address_4_1_1_0 = 138048;
parameter [18:0] address_4_1_1_1 = 139616;
parameter [18:0] address_4_1_1_2 = 141184;
parameter [18:0] address_4_1_1_3 = 142752;
parameter [18:0] address_5_0_0_0 = 144320;
parameter [18:0] address_5_0_0_1 = 145778;
parameter [18:0] address_5_0_0_2 = 147236;
parameter [18:0] address_5_0_0_3 = 148694;
parameter [18:0] address_5_0_1_0 = 150152;
parameter [18:0] address_5_0_1_1 = 151610;
parameter [18:0] address_5_0_1_2 = 153068;
parameter [18:0] address_5_0_1_3 = 154526;
parameter [18:0] address_5_1_0_0 = 155984;
parameter [18:0] address_5_1_0_1 = 157442;
parameter [18:0] address_5_1_0_2 = 158900;
parameter [18:0] address_5_1_0_3 = 160358;
parameter [18:0] address_5_1_1_0 = 161816;
parameter [18:0] address_5_1_1_1 = 163274;
parameter [18:0] address_5_1_1_2 = 164732;
parameter [18:0] address_5_1_1_3 = 166190;
parameter [18:0] address_6_0_0_0 = 167648;
parameter [18:0] address_6_0_0_1 = 169000;
parameter [18:0] address_6_0_0_2 = 170352;
parameter [18:0] address_6_0_0_3 = 171704;
parameter [18:0] address_6_0_1_0 = 173056;
parameter [18:0] address_6_0_1_1 = 174408;
parameter [18:0] address_6_0_1_2 = 175760;
parameter [18:0] address_6_0_1_3 = 177112;
parameter [18:0] address_6_1_0_0 = 178464;
parameter [18:0] address_6_1_0_1 = 179816;
parameter [18:0] address_6_1_0_2 = 181168;
parameter [18:0] address_6_1_0_3 = 182520;
parameter [18:0] address_6_1_1_0 = 183872;
parameter [18:0] address_6_1_1_1 = 185224;
parameter [18:0] address_6_1_1_2 = 186576;
parameter [18:0] address_6_1_1_3 = 187928;
parameter [18:0] address_7_0_0_0 = 189280;
parameter [18:0] address_7_0_0_1 = 190530;
parameter [18:0] address_7_0_0_2 = 191780;
parameter [18:0] address_7_0_0_3 = 193030;
parameter [18:0] address_7_0_1_0 = 194280;
parameter [18:0] address_7_0_1_1 = 195530;
parameter [18:0] address_7_0_1_2 = 196780;
parameter [18:0] address_7_0_1_3 = 198030;
parameter [18:0] address_7_1_0_0 = 199280;
parameter [18:0] address_7_1_0_1 = 200530;
parameter [18:0] address_7_1_0_2 = 201780;
parameter [18:0] address_7_1_0_3 = 203030;
parameter [18:0] address_7_1_1_0 = 204280;
parameter [18:0] address_7_1_1_1 = 205530;
parameter [18:0] address_7_1_1_2 = 206780;
parameter [18:0] address_7_1_1_3 = 208030;
parameter [18:0] address_8_0_0_0 = 209280;
parameter [18:0] address_8_0_0_1 = 210432;
parameter [18:0] address_8_0_0_2 = 211584;
parameter [18:0] address_8_0_0_3 = 212736;
parameter [18:0] address_8_0_1_0 = 213888;
parameter [18:0] address_8_0_1_1 = 215040;
parameter [18:0] address_8_0_1_2 = 216192;
parameter [18:0] address_8_0_1_3 = 217344;
parameter [18:0] address_8_1_0_0 = 218496;
parameter [18:0] address_8_1_0_1 = 219648;
parameter [18:0] address_8_1_0_2 = 220800;
parameter [18:0] address_8_1_0_3 = 221952;
parameter [18:0] address_8_1_1_0 = 223104;
parameter [18:0] address_8_1_1_1 = 224256;
parameter [18:0] address_8_1_1_2 = 225408;
parameter [18:0] address_8_1_1_3 = 226560;
parameter [18:0] address_9_0_0_0 = 227712;
parameter [18:0] address_9_0_0_1 = 228770;
parameter [18:0] address_9_0_0_2 = 229828;
parameter [18:0] address_9_0_0_3 = 230886;
parameter [18:0] address_9_0_1_0 = 231944;
parameter [18:0] address_9_0_1_1 = 233002;
parameter [18:0] address_9_0_1_2 = 234060;
parameter [18:0] address_9_0_1_3 = 235118;
parameter [18:0] address_9_1_0_0 = 236176;
parameter [18:0] address_9_1_0_1 = 237234;
parameter [18:0] address_9_1_0_2 = 238292;
parameter [18:0] address_9_1_0_3 = 239350;
parameter [18:0] address_9_1_1_0 = 240408;
parameter [18:0] address_9_1_1_1 = 241466;
parameter [18:0] address_9_1_1_2 = 242524;
parameter [18:0] address_9_1_1_3 = 243582;
parameter [18:0] address_10_0_0_0 = 244640;
parameter [18:0] address_10_0_0_1 = 245608;
parameter [18:0] address_10_0_0_2 = 246576;
parameter [18:0] address_10_0_0_3 = 247544;
parameter [18:0] address_10_0_1_0 = 248512;
parameter [18:0] address_10_0_1_1 = 249480;
parameter [18:0] address_10_0_1_2 = 250448;
parameter [18:0] address_10_0_1_3 = 251416;
parameter [18:0] address_10_1_0_0 = 252384;
parameter [18:0] address_10_1_0_1 = 253352;
parameter [18:0] address_10_1_0_2 = 254320;
parameter [18:0] address_10_1_0_3 = 255288;
parameter [18:0] address_10_1_1_0 = 256256;
parameter [18:0] address_10_1_1_1 = 257224;
parameter [18:0] address_10_1_1_2 = 258192;
parameter [18:0] address_10_1_1_3 = 259160;
parameter [18:0] address_11_0_0_0 = 260128;
parameter [18:0] address_11_0_0_1 = 261010;
parameter [18:0] address_11_0_0_2 = 261892;
parameter [18:0] address_11_0_0_3 = 262774;
parameter [18:0] address_11_0_1_0 = 263656;
parameter [18:0] address_11_0_1_1 = 264538;
parameter [18:0] address_11_0_1_2 = 265420;
parameter [18:0] address_11_0_1_3 = 266302;
parameter [18:0] address_11_1_0_0 = 267184;
parameter [18:0] address_11_1_0_1 = 268066;
parameter [18:0] address_11_1_0_2 = 268948;
parameter [18:0] address_11_1_0_3 = 269830;
parameter [18:0] address_11_1_1_0 = 270712;
parameter [18:0] address_11_1_1_1 = 271594;
parameter [18:0] address_11_1_1_2 = 272476;
parameter [18:0] address_11_1_1_3 = 273358;
parameter [18:0] address_12_0_0_0 = 274240;
parameter [18:0] address_12_0_0_1 = 275040;
parameter [18:0] address_12_0_0_2 = 275840;
parameter [18:0] address_12_0_0_3 = 276640;
parameter [18:0] address_12_0_1_0 = 277440;
parameter [18:0] address_12_0_1_1 = 278240;
parameter [18:0] address_12_0_1_2 = 279040;
parameter [18:0] address_12_0_1_3 = 279840;
parameter [18:0] address_12_1_0_0 = 280640;
parameter [18:0] address_12_1_0_1 = 281440;
parameter [18:0] address_12_1_0_2 = 282240;
parameter [18:0] address_12_1_0_3 = 283040;
parameter [18:0] address_12_1_1_0 = 283840;
parameter [18:0] address_12_1_1_1 = 284640;
parameter [18:0] address_12_1_1_2 = 285440;
parameter [18:0] address_12_1_1_3 = 286240;
parameter [18:0] address_13_0_0_0 = 287040;
parameter [18:0] address_13_0_0_1 = 287762;
parameter [18:0] address_13_0_0_2 = 288484;
parameter [18:0] address_13_0_0_3 = 289206;
parameter [18:0] address_13_0_1_0 = 289928;
parameter [18:0] address_13_0_1_1 = 290650;
parameter [18:0] address_13_0_1_2 = 291372;
parameter [18:0] address_13_0_1_3 = 292094;
parameter [18:0] address_13_1_0_0 = 292816;
parameter [18:0] address_13_1_0_1 = 293538;
parameter [18:0] address_13_1_0_2 = 294260;
parameter [18:0] address_13_1_0_3 = 294982;
parameter [18:0] address_13_1_1_0 = 295704;
parameter [18:0] address_13_1_1_1 = 296426;
parameter [18:0] address_13_1_1_2 = 297148;
parameter [18:0] address_13_1_1_3 = 297870;
parameter [18:0] address_14_0_0_0 = 298592;
parameter [18:0] address_14_0_0_1 = 299240;
parameter [18:0] address_14_0_0_2 = 299888;
parameter [18:0] address_14_0_0_3 = 300536;
parameter [18:0] address_14_0_1_0 = 301184;
parameter [18:0] address_14_0_1_1 = 301832;
parameter [18:0] address_14_0_1_2 = 302480;
parameter [18:0] address_14_0_1_3 = 303128;
parameter [18:0] address_14_1_0_0 = 303776;
parameter [18:0] address_14_1_0_1 = 304424;
parameter [18:0] address_14_1_0_2 = 305072;
parameter [18:0] address_14_1_0_3 = 305720;
parameter [18:0] address_14_1_1_0 = 306368;
parameter [18:0] address_14_1_1_1 = 307016;
parameter [18:0] address_14_1_1_2 = 307664;
parameter [18:0] address_14_1_1_3 = 308312;
parameter [18:0] address_15_0_0_0 = 308960;
parameter [18:0] address_15_0_0_1 = 309538;
parameter [18:0] address_15_0_0_2 = 310116;
parameter [18:0] address_15_0_0_3 = 310694;
parameter [18:0] address_15_0_1_0 = 311272;
parameter [18:0] address_15_0_1_1 = 311850;
parameter [18:0] address_15_0_1_2 = 312428;
parameter [18:0] address_15_0_1_3 = 313006;
parameter [18:0] address_15_1_0_0 = 313584;
parameter [18:0] address_15_1_0_1 = 314162;
parameter [18:0] address_15_1_0_2 = 314740;
parameter [18:0] address_15_1_0_3 = 315318;
parameter [18:0] address_15_1_1_0 = 315896;
parameter [18:0] address_15_1_1_1 = 316474;
parameter [18:0] address_15_1_1_2 = 317052;
parameter [18:0] address_15_1_1_3 = 317630;

logic [18:0] pixel_addr;
always @* begin
case({{size_select, alien_type[1], frame_num[0], deriv_select}})
8'b00000000: pixel_addr = address_0_0_0_0 + read_addr;
8'b00000001: pixel_addr = address_0_0_0_1 + read_addr;
8'b00000010: pixel_addr = address_0_0_0_2 + read_addr;
8'b00000011: pixel_addr = address_0_0_0_3 + read_addr;
8'b00000100: pixel_addr = address_0_0_1_0 + read_addr;
8'b00000101: pixel_addr = address_0_0_1_1 + read_addr;
8'b00000110: pixel_addr = address_0_0_1_2 + read_addr;
8'b00000111: pixel_addr = address_0_0_1_3 + read_addr;
8'b00001000: pixel_addr = address_0_1_0_0 + read_addr;
8'b00001001: pixel_addr = address_0_1_0_1 + read_addr;
8'b00001010: pixel_addr = address_0_1_0_2 + read_addr;
8'b00001011: pixel_addr = address_0_1_0_3 + read_addr;
8'b00001100: pixel_addr = address_0_1_1_0 + read_addr;
8'b00001101: pixel_addr = address_0_1_1_1 + read_addr;
8'b00001110: pixel_addr = address_0_1_1_2 + read_addr;
8'b00001111: pixel_addr = address_0_1_1_3 + read_addr;
8'b00010000: pixel_addr = address_1_0_0_0 + read_addr;
8'b00010001: pixel_addr = address_1_0_0_1 + read_addr;
8'b00010010: pixel_addr = address_1_0_0_2 + read_addr;
8'b00010011: pixel_addr = address_1_0_0_3 + read_addr;
8'b00010100: pixel_addr = address_1_0_1_0 + read_addr;
8'b00010101: pixel_addr = address_1_0_1_1 + read_addr;
8'b00010110: pixel_addr = address_1_0_1_2 + read_addr;
8'b00010111: pixel_addr = address_1_0_1_3 + read_addr;
8'b00011000: pixel_addr = address_1_1_0_0 + read_addr;
8'b00011001: pixel_addr = address_1_1_0_1 + read_addr;
8'b00011010: pixel_addr = address_1_1_0_2 + read_addr;
8'b00011011: pixel_addr = address_1_1_0_3 + read_addr;
8'b00011100: pixel_addr = address_1_1_1_0 + read_addr;
8'b00011101: pixel_addr = address_1_1_1_1 + read_addr;
8'b00011110: pixel_addr = address_1_1_1_2 + read_addr;
8'b00011111: pixel_addr = address_1_1_1_3 + read_addr;
8'b00100000: pixel_addr = address_2_0_0_0 + read_addr;
8'b00100001: pixel_addr = address_2_0_0_1 + read_addr;
8'b00100010: pixel_addr = address_2_0_0_2 + read_addr;
8'b00100011: pixel_addr = address_2_0_0_3 + read_addr;
8'b00100100: pixel_addr = address_2_0_1_0 + read_addr;
8'b00100101: pixel_addr = address_2_0_1_1 + read_addr;
8'b00100110: pixel_addr = address_2_0_1_2 + read_addr;
8'b00100111: pixel_addr = address_2_0_1_3 + read_addr;
8'b00101000: pixel_addr = address_2_1_0_0 + read_addr;
8'b00101001: pixel_addr = address_2_1_0_1 + read_addr;
8'b00101010: pixel_addr = address_2_1_0_2 + read_addr;
8'b00101011: pixel_addr = address_2_1_0_3 + read_addr;
8'b00101100: pixel_addr = address_2_1_1_0 + read_addr;
8'b00101101: pixel_addr = address_2_1_1_1 + read_addr;
8'b00101110: pixel_addr = address_2_1_1_2 + read_addr;
8'b00101111: pixel_addr = address_2_1_1_3 + read_addr;
8'b00110000: pixel_addr = address_3_0_0_0 + read_addr;
8'b00110001: pixel_addr = address_3_0_0_1 + read_addr;
8'b00110010: pixel_addr = address_3_0_0_2 + read_addr;
8'b00110011: pixel_addr = address_3_0_0_3 + read_addr;
8'b00110100: pixel_addr = address_3_0_1_0 + read_addr;
8'b00110101: pixel_addr = address_3_0_1_1 + read_addr;
8'b00110110: pixel_addr = address_3_0_1_2 + read_addr;
8'b00110111: pixel_addr = address_3_0_1_3 + read_addr;
8'b00111000: pixel_addr = address_3_1_0_0 + read_addr;
8'b00111001: pixel_addr = address_3_1_0_1 + read_addr;
8'b00111010: pixel_addr = address_3_1_0_2 + read_addr;
8'b00111011: pixel_addr = address_3_1_0_3 + read_addr;
8'b00111100: pixel_addr = address_3_1_1_0 + read_addr;
8'b00111101: pixel_addr = address_3_1_1_1 + read_addr;
8'b00111110: pixel_addr = address_3_1_1_2 + read_addr;
8'b00111111: pixel_addr = address_3_1_1_3 + read_addr;
8'b01000000: pixel_addr = address_4_0_0_0 + read_addr;
8'b01000001: pixel_addr = address_4_0_0_1 + read_addr;
8'b01000010: pixel_addr = address_4_0_0_2 + read_addr;
8'b01000011: pixel_addr = address_4_0_0_3 + read_addr;
8'b01000100: pixel_addr = address_4_0_1_0 + read_addr;
8'b01000101: pixel_addr = address_4_0_1_1 + read_addr;
8'b01000110: pixel_addr = address_4_0_1_2 + read_addr;
8'b01000111: pixel_addr = address_4_0_1_3 + read_addr;
8'b01001000: pixel_addr = address_4_1_0_0 + read_addr;
8'b01001001: pixel_addr = address_4_1_0_1 + read_addr;
8'b01001010: pixel_addr = address_4_1_0_2 + read_addr;
8'b01001011: pixel_addr = address_4_1_0_3 + read_addr;
8'b01001100: pixel_addr = address_4_1_1_0 + read_addr;
8'b01001101: pixel_addr = address_4_1_1_1 + read_addr;
8'b01001110: pixel_addr = address_4_1_1_2 + read_addr;
8'b01001111: pixel_addr = address_4_1_1_3 + read_addr;
8'b01010000: pixel_addr = address_5_0_0_0 + read_addr;
8'b01010001: pixel_addr = address_5_0_0_1 + read_addr;
8'b01010010: pixel_addr = address_5_0_0_2 + read_addr;
8'b01010011: pixel_addr = address_5_0_0_3 + read_addr;
8'b01010100: pixel_addr = address_5_0_1_0 + read_addr;
8'b01010101: pixel_addr = address_5_0_1_1 + read_addr;
8'b01010110: pixel_addr = address_5_0_1_2 + read_addr;
8'b01010111: pixel_addr = address_5_0_1_3 + read_addr;
8'b01011000: pixel_addr = address_5_1_0_0 + read_addr;
8'b01011001: pixel_addr = address_5_1_0_1 + read_addr;
8'b01011010: pixel_addr = address_5_1_0_2 + read_addr;
8'b01011011: pixel_addr = address_5_1_0_3 + read_addr;
8'b01011100: pixel_addr = address_5_1_1_0 + read_addr;
8'b01011101: pixel_addr = address_5_1_1_1 + read_addr;
8'b01011110: pixel_addr = address_5_1_1_2 + read_addr;
8'b01011111: pixel_addr = address_5_1_1_3 + read_addr;
8'b01100000: pixel_addr = address_6_0_0_0 + read_addr;
8'b01100001: pixel_addr = address_6_0_0_1 + read_addr;
8'b01100010: pixel_addr = address_6_0_0_2 + read_addr;
8'b01100011: pixel_addr = address_6_0_0_3 + read_addr;
8'b01100100: pixel_addr = address_6_0_1_0 + read_addr;
8'b01100101: pixel_addr = address_6_0_1_1 + read_addr;
8'b01100110: pixel_addr = address_6_0_1_2 + read_addr;
8'b01100111: pixel_addr = address_6_0_1_3 + read_addr;
8'b01101000: pixel_addr = address_6_1_0_0 + read_addr;
8'b01101001: pixel_addr = address_6_1_0_1 + read_addr;
8'b01101010: pixel_addr = address_6_1_0_2 + read_addr;
8'b01101011: pixel_addr = address_6_1_0_3 + read_addr;
8'b01101100: pixel_addr = address_6_1_1_0 + read_addr;
8'b01101101: pixel_addr = address_6_1_1_1 + read_addr;
8'b01101110: pixel_addr = address_6_1_1_2 + read_addr;
8'b01101111: pixel_addr = address_6_1_1_3 + read_addr;
8'b01110000: pixel_addr = address_7_0_0_0 + read_addr;
8'b01110001: pixel_addr = address_7_0_0_1 + read_addr;
8'b01110010: pixel_addr = address_7_0_0_2 + read_addr;
8'b01110011: pixel_addr = address_7_0_0_3 + read_addr;
8'b01110100: pixel_addr = address_7_0_1_0 + read_addr;
8'b01110101: pixel_addr = address_7_0_1_1 + read_addr;
8'b01110110: pixel_addr = address_7_0_1_2 + read_addr;
8'b01110111: pixel_addr = address_7_0_1_3 + read_addr;
8'b01111000: pixel_addr = address_7_1_0_0 + read_addr;
8'b01111001: pixel_addr = address_7_1_0_1 + read_addr;
8'b01111010: pixel_addr = address_7_1_0_2 + read_addr;
8'b01111011: pixel_addr = address_7_1_0_3 + read_addr;
8'b01111100: pixel_addr = address_7_1_1_0 + read_addr;
8'b01111101: pixel_addr = address_7_1_1_1 + read_addr;
8'b01111110: pixel_addr = address_7_1_1_2 + read_addr;
8'b01111111: pixel_addr = address_7_1_1_3 + read_addr;
8'b10000000: pixel_addr = address_8_0_0_0 + read_addr;
8'b10000001: pixel_addr = address_8_0_0_1 + read_addr;
8'b10000010: pixel_addr = address_8_0_0_2 + read_addr;
8'b10000011: pixel_addr = address_8_0_0_3 + read_addr;
8'b10000100: pixel_addr = address_8_0_1_0 + read_addr;
8'b10000101: pixel_addr = address_8_0_1_1 + read_addr;
8'b10000110: pixel_addr = address_8_0_1_2 + read_addr;
8'b10000111: pixel_addr = address_8_0_1_3 + read_addr;
8'b10001000: pixel_addr = address_8_1_0_0 + read_addr;
8'b10001001: pixel_addr = address_8_1_0_1 + read_addr;
8'b10001010: pixel_addr = address_8_1_0_2 + read_addr;
8'b10001011: pixel_addr = address_8_1_0_3 + read_addr;
8'b10001100: pixel_addr = address_8_1_1_0 + read_addr;
8'b10001101: pixel_addr = address_8_1_1_1 + read_addr;
8'b10001110: pixel_addr = address_8_1_1_2 + read_addr;
8'b10001111: pixel_addr = address_8_1_1_3 + read_addr;
8'b10010000: pixel_addr = address_9_0_0_0 + read_addr;
8'b10010001: pixel_addr = address_9_0_0_1 + read_addr;
8'b10010010: pixel_addr = address_9_0_0_2 + read_addr;
8'b10010011: pixel_addr = address_9_0_0_3 + read_addr;
8'b10010100: pixel_addr = address_9_0_1_0 + read_addr;
8'b10010101: pixel_addr = address_9_0_1_1 + read_addr;
8'b10010110: pixel_addr = address_9_0_1_2 + read_addr;
8'b10010111: pixel_addr = address_9_0_1_3 + read_addr;
8'b10011000: pixel_addr = address_9_1_0_0 + read_addr;
8'b10011001: pixel_addr = address_9_1_0_1 + read_addr;
8'b10011010: pixel_addr = address_9_1_0_2 + read_addr;
8'b10011011: pixel_addr = address_9_1_0_3 + read_addr;
8'b10011100: pixel_addr = address_9_1_1_0 + read_addr;
8'b10011101: pixel_addr = address_9_1_1_1 + read_addr;
8'b10011110: pixel_addr = address_9_1_1_2 + read_addr;
8'b10011111: pixel_addr = address_9_1_1_3 + read_addr;
8'b10100000: pixel_addr = address_10_0_0_0 + read_addr;
8'b10100001: pixel_addr = address_10_0_0_1 + read_addr;
8'b10100010: pixel_addr = address_10_0_0_2 + read_addr;
8'b10100011: pixel_addr = address_10_0_0_3 + read_addr;
8'b10100100: pixel_addr = address_10_0_1_0 + read_addr;
8'b10100101: pixel_addr = address_10_0_1_1 + read_addr;
8'b10100110: pixel_addr = address_10_0_1_2 + read_addr;
8'b10100111: pixel_addr = address_10_0_1_3 + read_addr;
8'b10101000: pixel_addr = address_10_1_0_0 + read_addr;
8'b10101001: pixel_addr = address_10_1_0_1 + read_addr;
8'b10101010: pixel_addr = address_10_1_0_2 + read_addr;
8'b10101011: pixel_addr = address_10_1_0_3 + read_addr;
8'b10101100: pixel_addr = address_10_1_1_0 + read_addr;
8'b10101101: pixel_addr = address_10_1_1_1 + read_addr;
8'b10101110: pixel_addr = address_10_1_1_2 + read_addr;
8'b10101111: pixel_addr = address_10_1_1_3 + read_addr;
8'b10110000: pixel_addr = address_11_0_0_0 + read_addr;
8'b10110001: pixel_addr = address_11_0_0_1 + read_addr;
8'b10110010: pixel_addr = address_11_0_0_2 + read_addr;
8'b10110011: pixel_addr = address_11_0_0_3 + read_addr;
8'b10110100: pixel_addr = address_11_0_1_0 + read_addr;
8'b10110101: pixel_addr = address_11_0_1_1 + read_addr;
8'b10110110: pixel_addr = address_11_0_1_2 + read_addr;
8'b10110111: pixel_addr = address_11_0_1_3 + read_addr;
8'b10111000: pixel_addr = address_11_1_0_0 + read_addr;
8'b10111001: pixel_addr = address_11_1_0_1 + read_addr;
8'b10111010: pixel_addr = address_11_1_0_2 + read_addr;
8'b10111011: pixel_addr = address_11_1_0_3 + read_addr;
8'b10111100: pixel_addr = address_11_1_1_0 + read_addr;
8'b10111101: pixel_addr = address_11_1_1_1 + read_addr;
8'b10111110: pixel_addr = address_11_1_1_2 + read_addr;
8'b10111111: pixel_addr = address_11_1_1_3 + read_addr;
8'b11000000: pixel_addr = address_12_0_0_0 + read_addr;
8'b11000001: pixel_addr = address_12_0_0_1 + read_addr;
8'b11000010: pixel_addr = address_12_0_0_2 + read_addr;
8'b11000011: pixel_addr = address_12_0_0_3 + read_addr;
8'b11000100: pixel_addr = address_12_0_1_0 + read_addr;
8'b11000101: pixel_addr = address_12_0_1_1 + read_addr;
8'b11000110: pixel_addr = address_12_0_1_2 + read_addr;
8'b11000111: pixel_addr = address_12_0_1_3 + read_addr;
8'b11001000: pixel_addr = address_12_1_0_0 + read_addr;
8'b11001001: pixel_addr = address_12_1_0_1 + read_addr;
8'b11001010: pixel_addr = address_12_1_0_2 + read_addr;
8'b11001011: pixel_addr = address_12_1_0_3 + read_addr;
8'b11001100: pixel_addr = address_12_1_1_0 + read_addr;
8'b11001101: pixel_addr = address_12_1_1_1 + read_addr;
8'b11001110: pixel_addr = address_12_1_1_2 + read_addr;
8'b11001111: pixel_addr = address_12_1_1_3 + read_addr;
8'b11010000: pixel_addr = address_13_0_0_0 + read_addr;
8'b11010001: pixel_addr = address_13_0_0_1 + read_addr;
8'b11010010: pixel_addr = address_13_0_0_2 + read_addr;
8'b11010011: pixel_addr = address_13_0_0_3 + read_addr;
8'b11010100: pixel_addr = address_13_0_1_0 + read_addr;
8'b11010101: pixel_addr = address_13_0_1_1 + read_addr;
8'b11010110: pixel_addr = address_13_0_1_2 + read_addr;
8'b11010111: pixel_addr = address_13_0_1_3 + read_addr;
8'b11011000: pixel_addr = address_13_1_0_0 + read_addr;
8'b11011001: pixel_addr = address_13_1_0_1 + read_addr;
8'b11011010: pixel_addr = address_13_1_0_2 + read_addr;
8'b11011011: pixel_addr = address_13_1_0_3 + read_addr;
8'b11011100: pixel_addr = address_13_1_1_0 + read_addr;
8'b11011101: pixel_addr = address_13_1_1_1 + read_addr;
8'b11011110: pixel_addr = address_13_1_1_2 + read_addr;
8'b11011111: pixel_addr = address_13_1_1_3 + read_addr;
8'b11100000: pixel_addr = address_14_0_0_0 + read_addr;
8'b11100001: pixel_addr = address_14_0_0_1 + read_addr;
8'b11100010: pixel_addr = address_14_0_0_2 + read_addr;
8'b11100011: pixel_addr = address_14_0_0_3 + read_addr;
8'b11100100: pixel_addr = address_14_0_1_0 + read_addr;
8'b11100101: pixel_addr = address_14_0_1_1 + read_addr;
8'b11100110: pixel_addr = address_14_0_1_2 + read_addr;
8'b11100111: pixel_addr = address_14_0_1_3 + read_addr;
8'b11101000: pixel_addr = address_14_1_0_0 + read_addr;
8'b11101001: pixel_addr = address_14_1_0_1 + read_addr;
8'b11101010: pixel_addr = address_14_1_0_2 + read_addr;
8'b11101011: pixel_addr = address_14_1_0_3 + read_addr;
8'b11101100: pixel_addr = address_14_1_1_0 + read_addr;
8'b11101101: pixel_addr = address_14_1_1_1 + read_addr;
8'b11101110: pixel_addr = address_14_1_1_2 + read_addr;
8'b11101111: pixel_addr = address_14_1_1_3 + read_addr;
8'b11110000: pixel_addr = address_15_0_0_0 + read_addr;
8'b11110001: pixel_addr = address_15_0_0_1 + read_addr;
8'b11110010: pixel_addr = address_15_0_0_2 + read_addr;
8'b11110011: pixel_addr = address_15_0_0_3 + read_addr;
8'b11110100: pixel_addr = address_15_0_1_0 + read_addr;
8'b11110101: pixel_addr = address_15_0_1_1 + read_addr;
8'b11110110: pixel_addr = address_15_0_1_2 + read_addr;
8'b11110111: pixel_addr = address_15_0_1_3 + read_addr;
8'b11111000: pixel_addr = address_15_1_0_0 + read_addr;
8'b11111001: pixel_addr = address_15_1_0_1 + read_addr;
8'b11111010: pixel_addr = address_15_1_0_2 + read_addr;
8'b11111011: pixel_addr = address_15_1_0_3 + read_addr;
8'b11111100: pixel_addr = address_15_1_1_0 + read_addr;
8'b11111101: pixel_addr = address_15_1_1_1 + read_addr;
8'b11111110: pixel_addr = address_15_1_1_2 + read_addr;
8'b11111111: pixel_addr = address_15_1_1_3 + read_addr;
default : pixel_addr = 0;
endcase
end



alien_block_mem(
.clka(clk),
.addra(pixel_addr),
.douta(palette_out)
);

endmodule
