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
	
include 'startup.asm'
include 'macros.asm'
include 'basicio.asm'

ADVMEMMAP_ACTIVE: equ $05ff
ADVMEMMAP_WPROTH: equ $06ff
ADVMEMMAP_WPROTL: equ $07ff
ADVMEMMAP_PAGE:   equ $04ff

include 'chksum.asm'

test_switchonoff:
	ld bc,ADVMEMMAP_PAGE
	or b,$e0
	ld a,0
	out (c),a

	ld hl,$eff0
	ld b,$10
	call dumphex

	ld bc,ADVMEMMAP_ACTIVE
	ld a,1
	out (c),a
	
	ld hl,$eff0
	ld b,$10
	call dumphex

	ld bc,ADVMEMMAP_ACTIVE
	ld a,0
	out (c),a
	ret

test_paging:
	ld bc,ADVMEMMAP_PAGE
	or b,$f0
	ld a,5
	out (c),a

	ld hl,$fff0
	ld b,$10
	call dumphex

	ld bc,ADVMEMMAP_PAGE
	or b,$f0
	ld a,0
	out (c),a

	ld hl,$fff0
	ld b,$10
	call dumphex
	ret

test_paging_write:
	ld bc,ADVMEMMAP_PAGE
	or b,$f0
	ld a,5
	out (c),a

	ld hl,$fff0
	push hl
	pop de
	inc de
	ld bc,$f
	ld a,$aa
	ld (hl),a
	ldir

	ld bc,ADVMEMMAP_PAGE
	or b,$f0
	ld a,0
	out (c),a

	ld hl,$fff0
	push hl
	pop de
	inc de
	ld bc,$f
	ld a,$55
	ld (hl),a
	ldir
	
	ret

test_paging_enabled:
	ld bc,ADVMEMMAP_ACTIVE
	ld a,1
	out (c),a
	
	call test_paging

	ld bc,ADVMEMMAP_ACTIVE
	ld a,0
	out (c),a
	ret

reset_paging:
	ld b,$10
	ld a,$00
reset_paging_loop:
	push bc
	ld bc,ADVMEMMAP_PAGE
	push af
	sla a
	sla a
	sla a
	sla a
	and $f0
	or b
	ld b,a
	xor a
	out (c),a
	pop af
	inc a
	pop bc
	djnz reset_paging_loop

	ld bc,ADVMEMMAP_WPROTH
	ld a,0
	out (c),a

	ld bc,ADVMEMMAP_WPROTL
	ld a,0
	out (c),a
	ret

main:
	call reset_paging

	; activate and copy rom
	ld bc,ADVMEMMAP_ACTIVE
	xor a
	out (c),a
	
	ld bc,ADVMEMMAP_PAGE
	ld a,1
maploop:
	out (c),a
	
	push af
	ld a,$10
	add a,b
	ld b,a
	pop af
	inc a
	cp $05
	jr nz,maploop

	; activate and copy rom
	di
	ld bc,ADVMEMMAP_ACTIVE
	ld a,1
	out (c),a
	
	ld hl,39616
	ld de,0
	ld bc,$4000
	ldir
	
	; protect and reboot
	ld bc,ADVMEMMAP_WPROTL
	ld a,$0f
	out (c),a
	
	ld bc,ADVMEMMAP_WPROTH
	xor a
	out (c),a
	
	rst $00

endcode:
