ADVMEMMAP_ACTIVE: equ $05ff
ADVMEMMAP_WPROTH: equ $06ff
ADVMEMMAP_WPROTL: equ $07ff
ADVMEMMAP_PAGE:   equ $04ff

INH_MF128: equ $08
INH_OPUS: equ $04
ENA_SHADOWROMS: equ $02
ENA_ADVMEM: equ $01

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

	xor a
	ld bc,ADVMEMMAP_WPROTH
	out (c),a
	ld bc,ADVMEMMAP_WPROTL
	out (c),a
	ld bc,ADVMEMMAP_ACTIVE
	out (c),a
	ret
