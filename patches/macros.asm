cls: macro
	call cls
endm

puts: macro msg
	ld hl,msg
	call printstring
endm

puth8: macro num
	ld a,num
	call printhex8
endm

puth8a: macro
	call printhex8
endm

crlf: macro
	ld a,$0d
	rst $10
endm

ink: macro _ink
	ld a,$10
	rst $10
	ld a,_ink
	rst $10
endm

paper: macro _paper
	ld a,$11
	rst $10
	ld a,_paper
	rst $10
endm

goat: macro _x_ _y_
	ld a,$16
	rst $10
	ld a,_x_
	rst $10
	ld a,_y_
	rst $10
endm

specscreen: macro
	call specscreen
endm
