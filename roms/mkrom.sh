#!/bin/bash
if [ "$1" == "clean" ]; then
	rm *.bin *.hex
	exit
fi
cat 02_rom128.bin 04_mf128.bin 05_opus-22.bin 03_mf1.bin > roms.bin
../patches/mkhex.sh roms.bin > roms.hex
