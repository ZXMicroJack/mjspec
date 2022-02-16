	; dump 0x56 hex bytes to serial port b bytes from 
	; address 56000
dumphex56:
	ld b,$56
	ld hl,56000
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

spiread16:
	ld b,16
main_read_loop:
	push bc
	spiread
	puth8a
	pop bc
	djnz main_read_loop
	crlf
	ret
