;
; BankSelector.asm
;
; Your ass is grass (tm)
;

  define BANK_M   0x5b5c
  org 25000

  di
  ld a, 0
  and 0x07
  ld b, a
  ld a, (BANK_M)
  and 0xf8
  or b
  ld (BANK_M), a
  ld bc, 0x7ffd
  out (c), a
  ei
  ret

  BLOCK 25030-$, 0x00

detect_128k

  di
  xor a
  ld (25029), a
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
  ld (25029), a

detect_128k_done

  ld a, (BANK_M)
  out (c), a
  ei
  ret

  BLOCK 25070-$, 0x00

launch

  di
  ld a, (BANK_M)
  and 0xf8
  ld (BANK_M), a
  ld bc, 0x7ffd
  out (c), a
  jp 0x8000

  BLOCK 25100-$, 0x00
