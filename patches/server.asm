; svr_getblock a = 's' for next block, or 'r' for previous block hl = address to write to
svr_getblock:
	push hl
	di
	call sputchar
	ld b,0
	pop hl
getblockloop:
	push hl
	push bc
	call sgetchar
	pop bc
	pop hl
	ld (hl),a
	inc hl
	djnz getblockloop
	ei
	ret

; svr_checkconnect - check for connection - zero set if good
svr_checkconnect:
	ld a,'h'
	call sputchar
	xor a
	call sgetchar
	cp 'h'
	ret

; svr_drainchars - drain uart of characters
svr_drainchars:
	call shaschar
	ret nc
	call sgetchar
	jr svr_drainchars
	ret

