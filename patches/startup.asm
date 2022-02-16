	; move from screen to main memory
	ld hl,16384
	ld de,32768
	ld bc,endcode-32768
	ldir
	jp main

