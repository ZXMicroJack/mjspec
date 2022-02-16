rom_cls:		equ $0daf
UART_STATUS: equ $ff
UART_DATA: equ $1ff

cls:
	call rom_cls
	ld a,$16
	rst $10
	ld a,0
	rst $10
	rst $10
	ret
	
printchar:
	rst $10
	ret
	
sputchar:
	ld bc,UART_DATA
	out (c),a
	ld bc,UART_STATUS
sputcharwait:
	in a,(c)
	bit 1,a
	jr z,sputcharwait
	ret

sgetchar:
	ld bc,UART_STATUS
sgetcharwait:
	in a,(c)
	bit 0,a
	jr z,sgetcharwait

	ld bc,UART_DATA
	in a,(c)
	ret

shaschar:
	ld bc,UART_STATUS
	in a,(c)
	rrca
	ret

printhex4:
	ld hl,hex
	ld c,a
	xor a
	ld b,a
	add hl,bc
	ld a,(hl)
	jp printchar

printhex8:
	push af
	sra a
	sra a
	sra a
	sra a
	and $0f
	call printhex4
	pop af
	and $0f
	jp printhex4

printstring:
	ld a,(hl)
	cp 0
	ret z
	call printchar
	inc hl
	jr printstring
hex: defm "0123456789ABCDEF"

