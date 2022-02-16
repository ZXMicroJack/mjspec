SPISTATUS: equ $3ff
SPIDATA: equ $2ff
SPISW_TXEN: equ $02
SPISW_RXEN: equ $04
SPISW_CSO: equ $01
SPISR_WAITN: equ $02
SPISR_DVALID: equ $01

spiwritea:
	ld bc,SPIDATA
	out (c),a
	ld bc,SPISTATUS
	xor a
	out (c),a
spiwrite_loop2:
	in a,(c)
	bit 1,a
	jr z,spiwrite_loop2
	ret

spireada:
	ld bc,SPISTATUS
	ld a,SPISW_RXEN
	out (c),a
	xor a
	out (c),a
spiread_loop:
	in a,(c)
	bit 0,a
	jr z,spiread_loop
	
	ld bc,SPIDATA
	in a,(c)
	ret

spiwrite: macro _spidata
	ld a,_spidata
	call spiwritea
endm

spiread: macro
	call spireada
endm

spireset: macro
	ld bc,SPIDATA
	in a,(c)
	spiset SPISW_CSO
endm

spiset: macro _spistatus
	ld bc,SPISTATUS
	ld a,_spistatus
	out (c),a
endm


