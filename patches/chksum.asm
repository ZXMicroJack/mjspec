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

