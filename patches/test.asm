test_flash_write:	
;		write 0-255 at $e000
	ld hl,$e000
	xor a
	ld b,a
mainloop1:
	ld (hl),a
	inc hl
	inc a
	djnz mainloop1

	call flash_write_enable
	ld de,$ff00
	ld a,$10
	ld hl,$e000
	call flash_write
	call flash_write_disable
	halt
	call test_flash_read
	ret

test_flash_clear_buffer:
	ld hl,$e000
	push hl
	pop de
	inc de
	ld bc,256
	xor a
	ld (hl),a
	ldir
	ret

test_flash_read:
	ld de,$ff00
	ld a,$10
	ld hl,$e000
	call flash_read

	crlf
	ld hl,$e000
	ld b,$00
	call dumphex

	ret

test_flash_erase:
	call test_flash_clear_buffer
	call flash_write_enable
	ld de,$ff00
	call flash_sector_erase
	call flash_write_disable
	call test_flash_read

	ret

	test_connection:
	call svr_checkconnect
	jr z,test_connection_good

	puth8 $01
	ret
	
test_connection_good:
	puth8 $aa
	ret

test_svr_block_read:
	cls
	ld a,'s'
	ld hl,$c000
	call svr_getblock
	
	ld hl,$c000
	ld b,$00
	call dumphex
	ld b,100
	call pause
	cls

	ld a,'r'
	ld hl,$c000
	call svr_getblock
	
	ld hl,$c000
	ld b,$00
	call dumphex
	ld b,100
	call pause
	cls
	
	ld a,'s'
	ld hl,$c000
	call svr_getblock
	
	ld hl,$c000
	ld b,$00
	call dumphex
	ld b,100
	call pause
	cls

	ld a,'r'
	ld hl,$c000
	call svr_getblock
	
	ld hl,$c000
	ld b,$00
	call dumphex
	ld b,100
	call pause
	ret

