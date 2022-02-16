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
include 'advmem.asm'
include 'chksum.asm'

title: defm "Download and start roms\0"

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
	call reset_paging

	call main_init
	goat 1 5
	puts title
	
	ld a,$01
	ld bc,ADVMEMMAP_ACTIVE
	out (c),a
	
		
	ld b,14
	ld a,$70
mainloop:
	push bc
	
	ld bc,ADVMEMMAP_PAGE | $f000
	out (c),a
	inc a

	push af
	call main_read_svr_block_f000
	pop af
		
	pop bc
	djnz mainloop

	; return to normal paging
	xor a
	ld bc,ADVMEMMAP_PAGE | $f000
	out (c),a

	goat 10 1
	puts msg_press_reset
	call main_end

	; switch in new roms and wait for reset
	di
	ld a,$03
	ld bc,ADVMEMMAP_ACTIVE
	out (c),a
	rst $00
	
	ld hl,0
	ld de,$f000
	ld bc,$1000
	ldir

	ld a,$01
	ld bc,ADVMEMMAP_ACTIVE
	out (c),a
	ei
	
	; read first altrom page
	cls
	xor a
	ld bc,ADVMEMMAP_PAGE | $f000
	out (c),a
	ld hl,$f000
	ld b,$40
	call dumphex
	crlf
	crlf

	; read first rom page
	ld hl,$0000
	ld b,$40
	call dumphex
	crlf
	crlf
	
	; read first rom page as pulled in by advram paging
	ld a,$71
	ld bc,ADVMEMMAP_PAGE | $f000
	out (c),a
	ld hl,$f000
	ld b,$40
	call dumphex

	xor a
	ld bc,ADVMEMMAP_PAGE | $f000
	out (c),a

	call main_waitkey
	
	ret

end:
	ret

msg_press_reset:
	defm "Done - press reset to start...\0"

endcode:
