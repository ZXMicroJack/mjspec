FLASH_CMD_READ: equ $03
FLASH_CMD_PAGE_PROGRAM: equ $02	
FLASH_CMD_STATUS: equ $05
FLASH_CMD_WRITE_EN: equ $06
FLASH_CMD_WRITE_DIS: equ $04
FLASH_CMD_SECTOR_ERASE: equ $20
FLASH_CMD_BULK_ERASE: equ $C7	
	
; flash_read - read a*16 bytes to (hl) from de * 16
; flash_sector_erase - erase sector at de*16
; flash_write_enable - enable writes to flash
; flash_write_disable - disable writes
; pause - pause for n/50 seconds
; flash_write - flash a*16 to (hl) from de * 16

flash_write_addr2:
	push de
	pop de
	push de
	ld a,d
	sra a
	sra a
	sra a
	sra a
	and $0f
	puth8a
; 	call spiwritea
	pop de
	push de
	ld a,d
	sla a
	sla a
	sla a
	sla a
	and $f0
	srl e
	srl e
	srl e
	srl e
	or e
	puth8a
; 	call spiwritea
	pop de
	ld a,e
	sla a
	sla a
	sla a
	sla a
	and $f0
	puth8a
; 	call spiwritea
	ret


; write address de
flash_write_addr:
	push de
	pop de
	push de
	ld a,d
	sra a
	sra a
	sra a
	sra a
	and $0f
; 	puth8a
	call spiwritea
	pop de
	push de
	ld a,d
	sla a
	sla a
	sla a
	sla a
	and $f0
	srl e
	srl e
	srl e
	srl e
	or e
; 	puth8a
	call spiwritea
	pop de
	ld a,e
	sla a
	sla a
	sla a
	sla a
	and $f0
; 	puth8a
	call spiwritea
	ret
	
; flash_read - read a*16 bytes to (hl) from de * 16
flash_read:
	push hl
	push af
	push de
	spiset $00
	spiwrite FLASH_CMD_READ
	pop de
	call flash_write_addr

	
	pop bc
	pop hl

flash_read_loop1:
	push bc
	ld b,$10
	
	; 	read a bytes from flash
flash_read_loop2:
	push bc
	push hl
	spiread
	pop hl
	pop bc

	ld (hl),a
	inc hl

	djnz flash_read_loop2

	pop bc
	djnz flash_read_loop1
	
	spiset SPISW_CSO
	ret

flash_status:
	puth8 $a0
	spiset $00
	puth8 $a1
	spiwrite FLASH_CMD_STATUS
	puth8 $a2
	spiwrite $00
	puth8 $a3
	spiread
	push af
	puth8a
	spiset SPISW_CSO
	puth8 $a4
	pop af
	ret

flash_wait:
	spiset $00
	spiwrite FLASH_CMD_STATUS
flash_wait_loop:
	puth8 $ab
	spiread
	bit 0,a
	jr nz,flash_wait_loop
	spiset SPISW_CSO
	puth8 $ac
	ret
	

	
flash_wait1:
	puth8 $aa
	call flash_status
	push af
	puth8a
	pop af
	bit 0,a
	ret z ; not busy
	
	jr flash_wait1

; flash_write_enable - enable writes to flash
flash_write_enable:
	spiset $00
	spiwrite FLASH_CMD_WRITE_EN
	spiset SPISW_CSO
	ret


; flash_sector_erase - erase sector at de*16
flash_sector_erase:
	push de
	spiset $00
	spiwrite FLASH_CMD_SECTOR_ERASE
	pop de
	call flash_write_addr
	spiset SPISW_CSO
	
	; wait worst case scenario 3s
	ld b,150
flash_sector_erase_wait:
	halt
	djnz flash_sector_erase_wait
	ret

; flash_bulk_erase - erase chip
flash_bulk_erase:
	spiset $00
	spiwrite FLASH_CMD_BULK_ERASE
	spiset SPISW_CSO
	
	; wait worst case scenario 20s
	ld b,5
flash_sector_erase_pause_loop:
	push bc
	ld b,250
	call pause
	pop bc
	djnz flash_sector_erase_pause_loop
	ret
	
	
	
; 	call flash_wait
; 	ret



flash_write_disable:
	spiset $00
	spiwrite FLASH_CMD_WRITE_DIS
	spiset SPISW_CSO
	ret

pause:
	halt
	djnz pause
	ret

; flash_write - flash a*16 to (hl) from de * 16
flash_write:
	push hl
	push af
	push de
	spiset $00
	spiwrite FLASH_CMD_PAGE_PROGRAM
	pop de
	call flash_write_addr

	
	pop bc
	pop hl

flash_write_loop1:
	push bc
	ld b,$10
	
	; 	read a bytes from flash
flash_write_loop2:
	ld a,(hl)
	push bc
	push hl
; 	spiread
	spiwritea
	pop hl
	pop bc

	inc hl

	djnz flash_write_loop2

	pop bc
	djnz flash_write_loop1
	
	spiset SPISW_CSO
	ret	
