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

title: defm "Download 16k binary\0"

main_read_svr_block_f000:
	push af
	goat 10 1
	puts msg_fetching_svr
	pop af
	puth8a
	
	ld b,16
	ld hl,$f000
blockread2_loop:
	push hl
	push bc
	ld a,'s'
	call svr_getblock
	pop bc
	pop hl
	inc h
	djnz blockread2_loop
	ret

main:
	call main_init
	goat 1 5
	puts title
		
	ld de,39616
	ld b,4
mainloop:
	push bc
	push de
	call main_read_svr_block_f000
	
	; get back address and copy downloaded block
	pop de
	push de
	ld hl,$f000
	ld bc,$1000
	ldir
	pop de
	
	; increment de by 4k
	ld a,$10
	add a,d
	ld d,a
	
	pop bc
	djnz mainloop
	ret
	
end:

	call main_end
	ret


endcode:
