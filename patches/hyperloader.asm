; This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo
STATUS: equ    $eff
DATA: equ      $dff

  org $0556

load:
  inc d
  ex af,af'
  dec d

  di

  ; make entrypoint for other games that don't want to use the
  ; return procedure
  nop
  nop
  nop
  nop

  ; push SA/LD-RET routine to return to
  ld hl,$053f
  push hl

  ; get block size
  call getbyte ; lsb of block size
  ld l,a
  call getbyte ; msb of block size
  ld h,a

  ; compare expected lengths
  inc de
  inc de
  ld a,h
  cp d
  jr nz,wasteloop
  ld a,l
  cp e
  jr nz,wasteloop

  ; DE no longer needed - is duplicate of HL
  ; decrement and fetch flag byte
  dec hl
  ;dec hl
  call getbyte ; type of block

  ; does it match with expected
  ld d,a
  ex af,af'
  cp d
  jr nz,wasteloop


  dec hl ; don't read parity byte at the end into memory

loop:
  call getbyte
  ld (ix+00),a
  inc ix
  dec hl

  ; compare hl to 0
  xor a
  cp h
  jr nz,loop
  cp l
  jr nz,loop

  ; swallow the parity byte
  call getbyte
  scf
  ret

wasteloop:
  call getbyte
  dec hl

  ; compare hl to 0
  xor a
  cp h
  jr nz,wasteloop
  cp l
  jr nz,wasteloop

  scf
  ccf
  ret

getbyte:
  ld bc,STATUS
  in a,(c)
  bit 0,a
  jr z,skipblockread
  ; no data, do read
  ld a,1
  out (c),a
readwaituntilfull:
  in a,(c)
  bit 2,a
  jr z,readwaituntilfull

readwaitwhilebusy:
  in a,(c)
  bit 1,a
  jr nz,readwaitwhilebusy

  out (c),0

skipblockread:
  ld bc,DATA
  in a,(c)
  ret
