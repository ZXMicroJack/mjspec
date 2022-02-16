	org 32768

; flash_read - read a*16 bytes to (hl) from de * 16
; flash_sector_erase - erase sector at de*16
; flash_write_enable - enable writes to flash
; flash_write_disable - disable writes
; pause - pause for n/50 seconds
; flash_write - flash a*16 to (hl) from de * 16

; specscreen - spectrum screen up
; ink 7 - set ink to n
; paper 0 - set paper to n
; goat 10 10 - print at x,y;
; puts msg - print messageZ
; crlf - new line

; sputchar - put char in a to uart
; sgetchar - get char from uart to a
; printhex4 - put hex nybble
; printhex8 - put hex byte

; svr_drainchars - drain uart of characters
; svr_checkconnect - check for connection - zero set if good
; svr_getblock a = 's' for next block, or 'r' for previous block hl = address to write to

	; mainloop - cls and do other stuff
	
include 'mainroutines.asm'

title: defm "Erase flash\0"
operation: defm "Erasing flash chip\0"

main:
	call main_init
	goat 1 5
	puts title

	goat 10 1
	puts operation
	call flash_write_enable
	call flash_bulk_erase
	call flash_write_disable
	
	call main_end
	ret


endcode:
