;
; mainmenu.asm
;

main_menu

  xor a
  ld (v_attr), a
  call cls
  ld a, 7
  ld (v_attr), a
  call set_print_shadow_screen
  call cls

  call main_menu_logo
  ld hl, v_definekeys
  ld de, str_main_menu_keys
  ld bc, 5
  ldir

; Choose an inspiring saying (groan)

  ld a, r
  and 0x7
  add a
  ld c, a
  xor a
  ld b, a
  ld hl, str_main_menu_pun_table
  or a
  add hl, bc
  ld bc, (hl)
  ld hl, bc
  call print

  ld hl, str_main_menu_options
  call print

  call set_print_main_screen
  call copy_shadow_screen_pixels
  call fade_in_attrs

  call init_scrolly
  call init_logo_attrs

  call display_current_control_method

main_menu_loop

  halt
  call move_logo_attrs
  call move_scrolly
  xor a
  out (0xfe), a
  call scan_keys
  jr nc, main_menu_loop

  cp '1'
  jr c, main_menu_loop
  cp '9'
  jr nc, main_menu_loop

; Option selected between 1 and 8

  cp '6'
  jr nc, menu_other_selection

  sub '1'
  ld (v_control_method), a
  call display_current_control_method
  jr main_menu_loop

menu_other_selection

  cp '8'
  ret z
  jr main_menu_loop

; Redefine keys and high score viewing go here

main_menu_done

  ret

main_menu_logo

  ld hl, img_manic_mower_logo
  ld de, SHADOW_SCREEN_BYTES * 0x100
  ld bc, 0x800
  ldir

  ld a, %01000010
  ld hl, SHADOW_SCREEN_ATTR * 0x100
  ld de, hl
  inc de
  ld bc, 0x100
  ld (hl), a
  ldir
  ret

init_logo_attrs

  ld hl, logo_attr_buffer
  ld de, hl
  inc de
  ld bc, 0xff
  ld a, %01000010
  ld (hl), a
  ldir

  ld hl, logo_attr_buffer + 0x80
  ld a, %01000110
  ld (hl), a
  inc hl
  inc a
  ld (hl), a
  inc hl
  ld (hl), a
  inc hl
  dec a
  ld (hl), a
  ret

  xor a
  ld (v_logo_attr_ptr), a
  ret

move_logo_attrs

  ld b, 7
  ld de, 0x5800
  ld a, (v_logo_attr_ptr)
  ld c, a

move_logo_attrs_1

  push bc
  ld hl, logo_attr_buffer
  ld l, c
  ld b, 32

move_logo_attrs_2

  ld a, (hl)
  ld (de), a
  inc de
  inc l
  djnz move_logo_attrs_2


  ;ldir

  pop bc
  inc c
  djnz move_logo_attrs_1

  ld hl, v_logo_attr_ptr
  inc (hl)
  ret

init_scrolly

  ld hl, 0x5ae0
  ld de, 0x5ae1
  ld bc, 31
  ld a, %01000111
  ld (hl), a
  ldir

  ld hl, str_scrolly_message
  ld (v_scrolly_ptr), hl
  xor a
  ld (v_scrolly_bits), a
  ld (0x5aff), a
  ret

move_scrolly

  ld a, (v_scrolly_bits)
  cp 0
  jr nz, move_scrolly_2

; New character found

  ld a, 23
  ld (v_row), a
  ld a, 31
  ld (v_column), a

  ld ix, (v_scrolly_ptr)
  ld b, (ix)
  ld a, (ix + 1)
  inc ix
  cp 0
  ld (v_scrolly_ptr), ix
  jr nz, move_scrolly_prchar

  ld hl, str_scrolly_message
  ld (v_scrolly_ptr), hl

move_scrolly_prchar

  ld a, ATTR_TRANS
  ld (v_attr), a
  ld a, b
  push af
  call putchar_8
  pop af

  ld hl, proportional_data
  ld c, a
  ld b, 0
  or a
  add hl, bc
  ld a, (hl)
  ld (v_scrolly_bits), a
  ld a, 7
  ld (v_attr), a

move_scrolly_2

; Actually take care of moving the scrolling message

  ld b, 8
  ld ix, 0x50ff

move_scrolly_3

  push bc
  push ix
  ld b, 32

move_scrolly_4

  rl (ix)
  dec ix

  djnz move_scrolly_4

  pop ix
  inc ixh
  pop bc
  djnz move_scrolly_3

  ld hl, v_scrolly_bits
  dec (hl)
  ret

display_current_control_method

  ld hl, 0x5940 ; Line 10 of attr file
  ld de, 0x5941
  ld bc, 0x20 * 5
  ld a, 6
  ld (hl), a
  ldir

  xor a
  ld hl, 0x5940
  ld a, (v_control_method)
  rla
  rla
  rla
  rla
  rla
  add l
  ld l, a
  ld de, hl
  inc de
  ld bc, 0x1f
  ld a, %01000111
  ld (hl), a
  ldir
  ret

str_main_menu_options

  defb AT, 10, 70, INK, 6, BRIGHT, 0, "1. Keyboard ("

str_main_menu_keys

  defb "*****)"

  defb AT, 11, 70, "2. Sinclair 1"
  defb AT, 12, 70, "3. Sinclair 2"
  defb AT, 13, 70, "4. Kempston"
  defb AT, 14, 70, "5. Cursor"
  defb AT, 16, 70, BRIGHT, 1, INK, 7, "6. Redefine Keys"
  defb AT, 17, 70, BRIGHT, 1, "7. View High Scores"
  defb AT, 19, 85, BRIGHT, 1, "8. Start Game", 0

str_main_menu_pun_table

  defw str_main_menu_pun_1
  defw str_main_menu_pun_2
  defw str_main_menu_pun_3
  defw str_main_menu_pun_4
  defw str_main_menu_pun_5
  defw str_main_menu_pun_6
  defw str_main_menu_pun_7
  defw str_main_menu_pun_8

str_main_menu_pun_1

  defb AT, 7, 12, INK, 4, BRIGHT, 1, "A beautiful lawn doesn't happen by itself", 0

str_main_menu_pun_2

  defb AT, 7, 38, INK, 6, "If the grass looks greener, it's", AT, 8, 70,"probably astroturf", 0

str_main_menu_pun_3

  defb AT, 7, 24, INK, 5, "I fought the lawn, and the lawn won", 0

str_main_menu_pun_4

  defb AT, 7, 76, INK, 4, "Take that, grass!", 0

str_main_menu_pun_5

  defb AT, 7, 50, INK, 6, "Lawn Enforcement Officer", 0

str_main_menu_pun_6

  defb AT, 7, 66, INK, 5, "A cut above the rest", 0

str_main_menu_pun_7

  defb AT, 7, 64, INK, 4, "You grow it, we mow it", 0

str_main_menu_pun_8

  defb AT, 7, 80, INK, 6, "Get off my lawn", 0

str_scrolly_message

  defb " *** Manic Mower    (C) Brendan Alford 2016    Based on the crappy original written by myself in 1992 "
  defb "that somehow got published in Sinclair User...    "
  defb "Mow the lawns as quickly as possible while avoiding the walls, garden gnomes, plants and especially "
  defb "Rover the dog and his fellow mutts...   Pick up fuel cans to avoid running out of fuel...   "
  defb "Hitting obstacles will damage your mower causing it to burst into flames eventually...   "
  defb "Damage to your mower will need to be repaired before tackling the next lawn...                            "
  defb "Hello to all at S4E and WoS, and the Manic Mower Hardcore Fan Club (shakes head)...       ", 0
