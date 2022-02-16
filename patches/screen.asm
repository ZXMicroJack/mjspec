; This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo

; print at d=x,e=y
; in: de -> xy
; mods: af
; out: de -> video position

SCREEN_ATTR_POS: equ 22528

specscreen:
	xor a
	out ($fe),a
	ld hl,SCREEN_ATTR_POS
	ld de,SCREEN_ATTR_POS+1
	ld bc,767
	ld (hl),a
	ldir

	ld de,2*2048+3*32+31+16384
  ld b,1
specscreen_triangleloop:
  push de
  push bc

specscreen_triangleloop1:
  push bc

  ld b,8
  push de
  ld a,$01
specscreen_triangleloop2:
  ld (de),a
  sla a
  set 0,a
  inc d
  djnz specscreen_triangleloop2
  pop de
  inc de
  pop bc

  djnz specscreen_triangleloop1

  pop bc
  pop de
  ld hl,31
	add hl,de
	push hl
	pop de

  inc b

  ld a,b
  cp 6
  jr nz,specscreen_triangleloop

  ld hl,SCREEN_ATTR_POS+19*32+31
  ld b,1
  ld de,specscreen_attr

specscreen_attrloop1:
  push bc

  push de
  push hl
specscreen_attrloop2:
  ld a,(de)
  ld (hl),a
  inc de
  inc hl
  djnz specscreen_attrloop2
  pop hl
  pop de

  ld bc,31
  add hl,bc
  pop bc
  inc b
  ld a,b
  cp 6
  jr nz,specscreen_attrloop1

  ret

specscreen_attr:
  defb %000010,%010110,%110100,%100001,%001000

