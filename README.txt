MJ Spectrum core
================

This uses the ctrl-module from the same repo.  A lot of code in here is stolen from other opensource
projects.  As such, this is also open source.  Use it as you will.

This builds for the MJ board which has a JTAG board created
from a RPi Pico RP2040.  It has onboard EEPROM to store multiple images rather than replace the EEPROM
on the JTAG board.  For the most part, this code is adapted for MJ board, which is a QMTech XC6LX25, and
a daughter card with VGA, DeltaSigma DACs, tape in, SdCard, and keyboard / mouse.

Building
========

- `make -C patches hyperloader.hex`
- `cd roms; ./mkrom.sh; cd ..`
- build the ZPU code on ctrl-module
- use the `x` script in the script directory to build this project.  I will create an ISE project at 
  some point, just have not gotten round to it yet.

Disclaimer: I use linux only in my work, so have not considered the need for Windows as yet.  I'm
sure I'll get around to it.  Some mess exists, but since it's not a production ready piece of code
I'm happy no-one will suffer too badly from a little code mess.  I'll get around to it eventually.


