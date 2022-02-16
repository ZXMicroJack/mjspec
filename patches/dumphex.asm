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
