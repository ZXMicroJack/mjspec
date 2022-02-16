include 'startup.asm'
include 'macros.asm'
include 'basicio.asm'
include 'spi.asm'
include 'debug.asm'
include 'flash.asm'
include 'test.asm'
include 'server.asm'
include 'screen.asm'


msg_fetching_svr:     defm "Fetching server block \0"
msg_fetching_flash:   defm "Fetching flash block  \0"
msg_comparing_block:  defm "Comparing flash block \0"
msg_comparing_failed: defm "Compare failed block  \0"
msg_writing_flash:    defm "Writing flash block   \0"
msg_complete:     		defm "+++ Operation completed +++\0"

main_blank_block:
	push hl
	pop de
	inc de
	xor a
	ld (hl),a
	ld bc,$1000
	ldir
	ret

main_read_svr_block:
	push af
	goat 10 1
	puts msg_fetching_svr
	pop af
	puth8a
	
	ld b,16
	ld hl,$c000
blockread_loop:
	push hl
	push bc
	ld a,'s'
	call svr_getblock
	pop bc
	pop hl
	inc h
	djnz blockread_loop
	ret

main_write_flash_block:
	push af
	goat 10 1
	puts msg_writing_flash
	pop af
	push af
	puth8a
	goat 1 1
	
	ld b,16
	pop de
	ld e,$00
	ld hl,$c000
blockwrite_loop:
	push bc
	push hl
	push de

	call flash_write_enable
	pop de
	pop hl
	push hl
	push de
	ld a,$10
	call flash_write
	halt
	halt
	call flash_write_disable

; 	puth8 d
; 	pop de
; 	push de
; 	puth8 e
; 	pop de
; 	push de
; 	call flash_write_addr2
; 	crlf
; 
; 	pop de
; 	push de
; 	call flash_write_addr

	pop de
	ld a,$10
	add a,e
	ld e,a
	
	pop hl
	inc h
	
	pop bc
	djnz blockwrite_loop
; 	call flash_write_disable
	ret

main_read_flash_block:
	push af
	goat 10 1
	puts msg_fetching_flash
	pop af
	push af
	puth8a

	pop de
	push de
	ld e,$00
	ld hl,$f000
	ld a,$80
	call flash_read

	pop de
	ld e,$80
	ld hl,$f800
	ld a,$80
	call flash_read
	ret

main_compare:
	push af
	goat 10 1
	puts msg_comparing_block
	pop af
	push af
	puth8a

	ld hl,$c000
	ld de,$f000
main_compare_loop:
	ld a,(de)
	cp (hl)
	jr nz,main_compare_fail

	inc hl
	inc de
	ld a,d
	or a,e
	cp $00
	jr nz,main_compare_loop
	pop af
	scf
	jr main_compare_end
	
main_compare_fail:
	push hl
	goat 10 1
	puts msg_comparing_failed
	pop de
	pop af
	push de
	puth8a
	pop hl
	push hl
	puth8 h
	pop hl
	puth8 l
	scf
	ccf
main_compare_end:
	ret

main_complete:
	goat 12 1
	puts msg_complete

main_waitkey:
	ld bc,$fe
main_waitkey_loop:
	in a,(c)
	and $1f
	cp $1f
	jr z,main_waitkey_loop
	ret

main_init:
	cls
	spireset

	ld b,50
	call pause
	call svr_drainchars
	
	specscreen
	ink 7
	paper 0

	ld hl,$c100
	call main_blank_block
	ld hl,$f100
	call main_blank_block
	ret

main_end:
	ld a,'x'
	call sputchar
	call main_complete
	ret
