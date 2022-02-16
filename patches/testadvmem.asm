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

calcchksum:
	ld bc,$0000
calcchksum_loop:
	ld a,(hl)
	scf
	ccf
	adc a,c
	jr nc,calcchksum_nocarry
	inc b
calcchksum_nocarry:
	ld c,a
	dec de
	inc hl
	xor a
	or d
	or e
	cp $00
	jr nz,calcchksum_loop
	ret
	
	

dumphex:
	push hl
	push bc
	ld a,(hl)
	puth8a
	pop bc
	pop hl
	inc hl
	djnz dumphex
	ret

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

test_paging_write_enabled:
	ld bc,ADVMEMMAP_ACTIVE
	ld a,1
	out (c),a
	
	call test_paging_write

	ld bc,ADVMEMMAP_ACTIVE
	ld a,0
	out (c),a
	ret

make_2021_rom:
	cls
	call reset_paging
	puth8 $00
	
	; switch on advmemmap
	puth8 $01
	ld bc,ADVMEMMAP_ACTIVE
	ld a,1
	out (c),a
	
	; switch page f to 5
	puth8 $02
	ld bc,ADVMEMMAP_PAGE
	ld a,$f0
	or b
	ld b,a
	ld a,5
	out (c),a
	
	; move 4k of rom to page 5
	puth8 $03
	ld hl,$1000
	ld de,$f000
	ld bc,$1000
	ldir

	; calc checksum over newly copied area
	crlf
	ld hl,$f000
	ld de,$1000
	call calcchksum
	push bc
	puth8 b
	pop bc
	puth8 c
	crlf
		
	; calc checksum over rom
	ld hl,$1000
	ld de,$1000
	call calcchksum
	push bc
	puth8 b
	pop bc
	puth8 c
	crlf
	
	puth8 $04
	ld hl,$f53b
	ld (hl),'2'
	inc hl
	ld (hl),'0'
	inc hl
	ld (hl),'2'
	inc hl
	ld (hl),'1'

	; page f back to 0
	puth8 $05
	ld bc,ADVMEMMAP_PAGE
	ld a,$f0
	or b
	ld b,a
	xor a
	out (c),a

	; set page 1 to 5
	puth8 $06
	di
	ld bc,ADVMEMMAP_PAGE
	ld a,$10
	or b
	ld b,a
	ld a,5
	out (c),a

	; check and store checksum in bc
	ld hl,$1000
	ld de,$1000
	call calcchksum
	push bc

	ld hl,$1000
	ld de,$f000
	ld bc,$1000
	ldir
	
	; page 1 back to 0
; 	ld bc,ADVMEMMAP_PAGE
; 	ld a,$10
; 	or b
; 	ld b,a
; 	xor a
; 	out (c),a

	; print stored checksum
	ei
	crlf
	pop bc
	push bc
	puth8 b
	pop bc
	puth8 c
	crlf
	
	
	
	; set write protect over page 1
	puth8 $07
	ld bc,ADVMEMMAP_WPROTL
	ld a,$02
	out (c),a

	puth8 $08
 	rst $0
	
	
	
main:
	
; 	call test_switchonoff
; 	call test_paging
; 	call test_paging_write_enabled
; 	call test_paging_enabled
; 	call test_paging_write
	call make_2021_rom
; 	goat 0,0
	

; 	ld bc,ADVMEMMAP_ACTIVE
; 	ld a,0
; 	out (c),a
	
	
	; 	ld a,4
; 	out ($fe),a
; 	ld hl,16384
; 	ld a,$aa
; 	ld (hl),a
	ret
endcode:
