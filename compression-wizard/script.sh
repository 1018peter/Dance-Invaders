#!/bin/bash

for filename in $(find . -type f -name 'invader*' -a -name '*.png'); do
	echo 'Processing' $(basename $filename)
	./'FPGA Image Compression Wizard.exe' $(basename $filename) 2 0 0 1
done

