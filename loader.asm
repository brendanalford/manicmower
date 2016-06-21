;
; loader.asm
;
; Your ass is grass (tm)
;

; We'll use entry point 0x0563 for LD_BYTES so we don't get redirected
; through SA/LD-RET on completion.

  define LD_BYTES         0x0556

  org 25000
  di

  xor a
  ld hl, 0x5800
  push hl
  pop de
  inc de
  ld bc, 0x2ff
  ld (hl), a
  ldir

; Load title screen

  ld ix, 0x4000
  ld de, 0x1b00
  ld a, 0xff
  scf
  call LD_BYTES

; Load main game

  ld a, 0
  call pagein
  ld ix, 0x8000
  ld de, 0x8000
  ld a, 0xff
  scf
  call LD_BYTES

  call detect_128k

  ld a, (v_128k)
  cp 0
  jr z, start_game

; 128K detected - load music blocks

  ld a, 1
  call pagein
  ld ix, 0xc000
  ld de, 0x4000
  ld a, 0xff
  scf
  call LD_BYTES

  ld a, 3
  call pagein
  ld ix, 0xc000
  ld de, 0x4000
  ld a, 0xff
  scf
  call LD_BYTES

  ld a, 0
  call pagein

; Start game!

start_game

  xor a
  out (0xfe), a
  jp 0x8000

detect_128k

  xor a
  ld bc, 0x7ffd
  out (c), a
  ld a, 0x55
  ld (0xffff), a
  ld a, 7
  out (c), a
  ld a, (0xffff)
  cp 0x55
  jr z, detect_128k_done

  ld a, 1
  ld (v_128k), a

detect_128k_done

  ret

; We always want ROM 0 to be in place.
; So, we'll first write to 1FFD just in
; case we're on a +2A or +3, then do the
; proper write to 7FFD.

pagein

  push af
  ld bc, 0x1ffd
  ld a, 0x04  ; ROM 3 - 48K BASIC
  out (c), a
  pop af

  and 0x07
  ld b, a
  ld a, 0x10
  or b
  ld bc, 0x7ffd
  out (c), a
  ret

v_128k

  defb 0      ; 128K Detection flag
