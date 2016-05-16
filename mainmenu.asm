;
; mainmenu.asm
;

main_menu

  xor a
  ld (v_attr), a
  call cls
  call set_print_shadow_screen
  call cls

  call main_menu_logo
  ld hl, v_playerkeys
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


str_main_menu_options

  defb AT, 10, 70, INK, 7, BRIGHT, 1, "1. Keyboard ("

str_main_menu_keys

  defb "*****)"

  defb AT, 11, 70, BRIGHT, 1, "2. Sinclair 1"
  defb AT, 12, 70, BRIGHT, 1, "3. Sinclair 2"
  defb AT, 13, 70, BRIGHT, 1, "4. Kempston"
  defb AT, 14, 70, BRIGHT, 1, "5. Cursor"
  defb AT, 16, 70, BRIGHT, 1, "6. View High Scores"
  defb AT, 18, 85, BRIGHT, 1, "7. Start Game", 0

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
