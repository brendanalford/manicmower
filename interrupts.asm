init_interrupts

  di
  ld a, intvec_table / 256
  ld i, a
  im 2

  ld a, 0x18
  ld (0xffff), a

; Set up AY player flag.

  xor a
  ld (v_player_active), a
  ld (v_module_page), a
  ei
  ret

restore_interrupts

  di
  ld a, 0x3F
  ld i, a
  im 0
  ei
  ret

interrupt_routine

  push hl
  push de
  push bc
  push af
  push ix
  push iy
  exx
  push hl
  push de
  push bc
  push af
  exx

  ld a, (v_player_active)
  cp 0
  jr z, interrupt_routine_check_custom_isr

  call play_music

interrupt_routine_check_custom_isr

  ld hl, (v_isr_location)
  ld a, h
  or l
  jr z, interrupt_routine_exit

  push hl
  pop de
  ld hl, interrupt_routine_exit
  push hl
  push de
  pop hl
  jp hl

interrupt_routine_exit

  exx
  pop hl
  pop de
  pop bc
  pop af
  exx
  pop iy
  pop ix
  pop af
  pop bc
  pop de
  pop hl

  ei
  reti
