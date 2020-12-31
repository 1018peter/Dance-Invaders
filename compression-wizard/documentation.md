# FPGA Image Compression Wizard
---
Import the entire folder to your device and put the image file to be compressed in the same directory as the executable,
then run the executable.

The program supports three customizable options: The number of colors to use for the palette (in integer powers of 32), 
whether to use Gaussian Blur, and whether to sharpen the color (which is equivalent to using the magic wand tool to merge connected pixels
 that are similar in color.
 
 The program also accepts command-line arguments, as follows:
 - Arg 1: A string, containing the filename.
 - Arg 2: The size of the palette. Should be a power of 2 greater than 1.
 - Arg 3: An integer flag. 0 means not using Gaussian Blur.
 - Arg 4: An integer flag. 0 means not sharpening the color.
 - Arg 5: An integer flag. 0 means not looking for preexisting color chunks to initialize palettes with. A color chunk will only be used for initialization
 if it is at least as large as a palette should be on average.
 - Arg 6: An integer flag. 0 means not including the palette header in the output.
 - Arg 7: An integer flag. 0 means output as .coe, and 1 means output as .svh.
 
 If every command-line argument field is filled, verbosity will be disabled, and the program will not output any notification messages nor initiate any user queries.
 
 The program will output a preview image of the "compressed" file, a COE/SVH file representing the compressed file in dense matrix representation, 
 another in sparse matrix representation, and finally a diagnostics .txt file that displays metadata of the compression process.
 
 The COE files will be written to the directory "coe_dump" or "header_dump", the preview will be written to the directory "preview", and the diagnostics will be written to
 "diagnostics".
 
 The shell script "script.sh" can be executed to run the compression wizard on every file with a specified name pattern written in the code.



Note:
Dependencies: Boost C++, OpenImageIO.
