#!/bin/bash

for filename in $(find . -type f -name 'size*' -a -name '*.png'); do
	echo 'Processing' $(basename $filename)
	./'FPGA Image Compression Wizard.exe' $(basename $filename) 1 2 0 0 1 0 2
done

