#!/bin/bash
source prj
set -e
. /opt/Xilinx/14.7/ISE_DS/settings64.sh

cat << EOF | impact -batch
#cat << EOF
setMode -pff
setMode -pff
addConfigDevice  -name "${prj}" -path "$(pwd)"
setSubmode -pffspi
setAttribute -configdevice -attr multibootBpiType -value ""
addDesign -version 0 -name "0"
setMode -pff
addDeviceChain -index 0
setMode -pff
addDeviceChain -index 0
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr compressed -value "FALSE"
setAttribute -configdevice -attr autoSize -value "FALSE"
setAttribute -configdevice -attr fileFormat -value "mcs"
setAttribute -configdevice -attr fillValue -value "FF"
setAttribute -configdevice -attr swapBit -value "FALSE"
setAttribute -configdevice -attr dir -value "UP"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr multiboot -value "FALSE"
setAttribute -configdevice -attr spiSelected -value "TRUE"
setAttribute -configdevice -attr spiSelected -value "TRUE"
addPromDevice -p 1 -size 1024 -name 1M
setMode -pff
setMode -pff
setMode -pff
setMode -pff
addDeviceChain -index 0
setMode -pff
addDeviceChain -index 0
setSubmode -pffspi
setMode -pff
setAttribute -design -attr name -value "0000"
addDevice -p 1 -file "$(pwd)/${prj}.bit"
setMode -pff
setSubmode -pffspi
generate
setCurrentDesign -version 0
EOF

cat << EOF | impact -batch
#cat << EOF
setMode -bs
setMode -bs
setMode -bs
setCable -port svf -file ./tmp/${prj}prom.svf
#addDevice -p 1 -file "$(pwd)/${prj}.bit"
addDevice -p 1 -file "/opt/Xilinx/14.7/ISE_DS/ISE/spartan6/data/xc6slx25.bsd"
attachflash -position 1 -spi "M25P80"
assignfiletoattachedflash -position 1 -file "$(pwd)/${prj}.mcs"
Program -p 1 -dataWidth 1 -spionly -e -v -loadfpga 
EOF
clear

cat << EOF > t
cable usbblaster
detect
svf ./tmp/${prj}prom.svf
EOF

sudo jtag < t
