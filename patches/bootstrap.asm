	org	56000

	di
	ld hl,04000h
	ld bc,00000h
loadloop:
	push bc
	ld bc,000ffh
inloop:
	in a,(c)
	bit 0,a
	jr z,inloop

	ld bc,001ffh
	in a,(c)
	cp 00dh
	jr z,quit
	push hl	
	ld b,010h
	ld hl,hexchars
h2bloop:
	cp (hl)	
	jr z,decode1
	inc hl	
	djnz h2bloop

decode1:
	ld a,010h
	sub b	
	pop hl	
	pop bc	
	bit 0,c
	jr nz,decode2
	ld (hl),a	
	inc bc	
	jr loadloop
decode2:
	ld b,a	
	ld a,(hl)	
	sla a
	sla a
	sla a
	sla a
	or b
	ld (hl),a	
	inc hl
	inc bc
	jr loadloop
quit:
	pop bc	
	ei	
	ret	
hexchars:
	defm "0123456789ABCDEF"
