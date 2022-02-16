# targets
# 	bios.hex - main bios
#		hyperloader.hex - patch for ROM to load quicker roms
# tests
#		testbootstrap - test the loading of roms from sdram
#		testmemdump - test memdump feature
#		testmemtest - test memtest feature
#		testmainmenu - test main menu from bios
#		testdir - test directory mechanism - not sure what makes it pass
#		testscreen - test screen module
#		testmenus - test menus module

z80em_dir=../tools

all: runcode hyperloader.hex upgrade.bin flasherase.bin verify.bin verifyblank.bin testadvmem.bin download.bin startrom.bin downloadroms.bin

%.bin : %.asm
	z80asm -o$@ $<

%.hex: %.bin
	./mkhex.sh $< > $@

# final binaries
hyperloader.bin: hyperloader.asm
hyperloader.hex: hyperloader.bin

maindeps=startup.asm basicio.asm macros.asm screen.asm spi.asm server.asm test.asm flash.asm debug.asm mainroutines.asm advmem.asm

upgrade.bin: upgrade.asm $(maindeps)
flasherase.bin: flasherase.asm $(maindeps)
verify.bin: verify.asm $(maindeps)
verifyblank.bin: verifyblank.asm $(maindeps)
testadvmem.bin: testadvmem.asm $(maindeps)
download.bin: download.asm $(maindeps)
startrom.bin: startrom.asm $(maindep)
downloadroms.bin: downloadroms.asm $(maindep)

runcode: runcode.c
	gcc -o$@ $<

clean:
	$(RM) *.bin *.i *.tap *.op* *.o *~ zcc_opt.def *.reloc *.S *.hex *.err *.bmp *.lis
