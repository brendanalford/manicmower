
  org 32768

; ENCODER: HL=^SOURCE,DE=^TARGET,IX=FULL_LENGTH; HL+=FULL_LENGTH,DE+=PAKD_LENGTH,IX=0,B=0,ACF!

  ld hl, image_src
  ld de, 0xc000
  ld ix, 0x1b00

  call rle2pack_init

  di
  halt
  ; DECODER: HL=^SOURCE,DE=^TARGET; HL+=PAKD_LENGTH,DE+=FULL_LENGTH,B!,AF!
  ld hl, 0xc000
  ld de, 0x4000
  call rle2pack_decode
  ret

rle2pack_init

  ld b,0

rle2pack_loop

  ld c,(hl)

rle2pack_find
  ld a, xh
  or xl
  jr z,rle2pack_exit
  dec ix
  inc hl
  inc b
  jr z,rle2pack_over
  ld a,(hl)
  cp c
  jr z,rle2pack_find

rle2pack_over

  call rle2pack_fill
  jr rle2pack_loop

rle2pack_exit

  cp b
  call nz,rle2pack_fill

; generate the end marker from the last byte!
  dec hl
  ld a,(hl)
  inc hl
  cpl
  jr rle2pack_exit_

rle2pack_fill

  dec b
  ld a,c
  jr z,rle2pack_fill_

rle2pack_exit_

  ld (de),a
  inc de
  ld (de),a
  inc de
  dec b
  ld a,b

rle2pack_fill_

  ld (de),a
  inc de
  push de
  pop bc
  ret

rle2pack_decode

; DECODER: HL=^SOURCE,DE=^TARGET; HL+=PAKD_LENGTH,DE+=FULL_LENGTH,B!,AF!

rle2upak_init

  ld b,1
  ld a,(hl)
  inc hl
  cp (hl)
  jr nz, rle2upak_fill
  inc hl
  ld b,(hl)
  inc hl
  inc b
  ret z
  inc b

rle2upak_fill

  ld (de),a
  inc de
  djnz $-2
  jr rle2upak_init


image_src

  incbin "easter_egg_raw.scr"
