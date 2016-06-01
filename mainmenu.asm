;
; mainmenu.asm
;

main_menu

; Init music Player
; Main menu music lives in RAM page 1

  ld hl, AY_MENU_TUNE
  ld a, 1
  call init_music

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

  call display_pun

  ld hl, str_main_menu_options
  call print
  call display_current_sound_option

  call set_print_main_screen
  call copy_shadow_screen_pixels
  call fade_in_attrs

  call init_scrolly
  call init_logo_attrs

  call display_current_control_method

  call restart_music

  di
  ld hl, main_menu_isr
  ld (v_isr_location), hl
  ei

main_menu_loop

  halt
  xor a
  out (0xfe), a
  call scan_keys
  jr nc, main_menu_loop

  cp '0'
  jr z, main_menu_done

  cp '9'
  jr z, modify_sound_options

  cp '1'
  jr c, main_menu_loop
  cp '8'
  jr nc, main_menu_loop

; Option selected between 1 and 8

  cp '6'
  jr nc, menu_other_selection

  sub '1'
  ld (v_control_method), a
  call display_current_control_method
  jr main_menu_loop

menu_other_selection

  cp '6'
  call z, redefine_keys
  cp '7'
  call z, show_high_score_table

  jr main_menu_loop

modify_sound_options

  ld a, (v_audio_options)
  inc a
  and 0x03
  ld b, a
  ld a, (v_128k_detected)
  cp 0
  jr nz, modify_sound_options_1

  ld a, b
  and 0x1
  ld b, a

modify_sound_options_1

  ld a, b
  cp 2
  jr nz, modify_sound_options_2

  inc a

modify_sound_options_2

  ld (v_audio_options), a
  call display_current_sound_option

; Consider impact on music if playing

  ld a, (v_audio_options)
  bit 1, a
  call z, mute_music
  call nz, restart_music

modify_sound_options_3

  halt

; ISR will move scrolly and logo attrs

  call scan_keys
  jr c, modify_sound_options_3

  jr main_menu_loop

; Redefine keys and high score viewing go here

main_menu_done

  call mute_music
  di
  ld hl, 0
  ld (v_isr_location), hl
  ei
  ret

;
; Called from ISR
;
main_menu_isr

  call move_logo_attrs
  call move_scrolly
  ret

;
; Choose an inspiring saying (most pretty groanworthy)
;
display_pun

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

display_current_sound_option

  ld a, (v_audio_options)
  add a, a
  ld c, a
  ld a, 0
  ld b, a
  ld hl, sound_option_table
  or a
  add hl, bc
  ld de, (hl)
  ld hl, de
  call print
  ret

;
; Redefine keys
;

redefine_keys

  ld hl, 0x38B7;  Wipe lines 56-191, leaving logo intact
  call screen_wipe

  call disable_main_menu_isr

  ld hl, str_redefine_keys
  call print

  ; call set_fixed_font
  ; ld hl, str_text
  ; call print
  ; call set_proportional_font

  call set_main_menu_isr

; Erase the currently defined keys so no conflict

  ld hl, v_definekeys
  ld de, v_definekeys + 1
  ld bc, 4
  xor a
  ld (hl), a

  ld ix, v_definekeys
  ld bc, 0

redefine_keys_loop

  halt

  call set_fixed_font

  inc c
  ld a, c
  sra a
  sra a
  sra a
  and 0x3
  cp 0
  jr z, redefine_keys_cursor_blank
  cp 1
  jr z, redefine_keys_cursor_half
  ld a, 'n'
  jr redefine_keys_loop_2

redefine_keys_cursor_blank

  ld a, ' '
  jr redefine_keys_loop_2

redefine_keys_cursor_half

  ld a, 'm'

redefine_keys_loop_2

  push af
  ld a, b
  or a
  add 11
  ld (v_row), a
  ld a, 150
  ld (v_column), a
  ld a, %01000110
  ld (v_attr), a
  pop af
  call putchar
  call set_proportional_font

  call scan_keys
  jr nc, redefine_keys_loop
  ld (v_curdefkey), a

; Check to see if we've used this one before

  ld hl, v_definekeys

redefine_keys_check_loop

  ld a, h
  cp ixh
  jr nz, redefine_keys_check_loop_2
  ld a, l
  cp ixl
  jr nz, redefine_keys_check_loop_2

; Current cursor reached, we're good, no duplicates

  jr redefine_keys_check_ok

redefine_keys_check_loop_2

; If key matches something else in the buffer, ignore it and loop back
; for another keypress

  ld a, (v_curdefkey)
  cp (hl)
  jr z, redefine_keys_loop
  inc hl
  jr redefine_keys_check_loop

redefine_keys_check_ok

  ld a, (v_curdefkey)
  ld (ix), a
  call putchar

redefine_keys_release_key

  call scan_keys
  jr c, redefine_keys_release_key

  inc ix
  inc b
  ld a, b
  cp 5
  jr nz, redefine_keys_loop

; Store keys just defined in screen message area

  ld hl, v_definekeys
  ld de, str_main_menu_keys
  ld bc, 5
  ldir


; Confirm if the keys are ok

  call disable_main_menu_isr
  ld hl, str_keys_ok
  call print
  call set_main_menu_isr

redefine_keys_confirm

  call get_key
  cp 'N'
  jp z, redefine_keys
  cp 'Y'
  jr z, redefine_keys_done
  jr redefine_keys_confirm

redefine_keys_done

  ld hl, 0x38B7
  call screen_wipe

  call disable_main_menu_isr

  call display_pun
  ld hl, str_main_menu_options
  call print
  call display_current_control_method
  call display_current_sound_option

  call set_main_menu_isr

  ret

show_high_score_table

  ld hl, 0x38B7;  Wipe lines 56-191, leaving logo intact
  call screen_wipe

  call disable_main_menu_isr

  ld hl, str_high_score_title
  call print
  call set_main_menu_isr

  call get_key

  ld hl, 0x38B7
  call screen_wipe

  call disable_main_menu_isr

  call display_pun
  ld hl, str_main_menu_options
  call print
  call display_current_control_method
  call display_current_sound_option

  call set_main_menu_isr
  ret


set_main_menu_isr

  di
  ld hl, main_menu_isr
  ld (v_isr_location), hl
  ei
  ret

disable_main_menu_isr

  di
  ld hl, 0
  ld (v_isr_location), hl
  ei
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
  defb AT, 17, 70, "7. View High Scores"
  defb AT, 21, 70, "0. Start Game", 0

sound_option_table

  defw  str_sound_none
  defw  str_sound_fx
  defw  0x00
  defw  str_sound_all

str_sound_none

  defb  AT, 19, 70, BRIGHT, 1, INK, 7, "9. Sound off    ", 0

str_sound_fx

  defb  AT, 19, 70, BRIGHT, 1, INK, 7, "9. Sound FX     ", 0

str_sound_all

  defb  AT, 19, 70, BRIGHT, 1, INK, 7, "9. Music+FX     ", 0

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

  defb AT, 7, 38, INK, 4, "If the grass looks greener, it's", AT, 8, 70,"probably astroturf", 0

str_main_menu_pun_3

  defb AT, 7, 24, INK, 4, "I fought the lawn, and the lawn won", 0

str_main_menu_pun_4

  defb AT, 7, 50, INK, 4, "a.k.a. Gasman Music Demo", 0

str_main_menu_pun_5

  defb AT, 7, 50, INK, 4, "Lawn Enforcement Officer", 0

str_main_menu_pun_6

  defb AT, 7, 66, INK, 4, "A cut above the rest", 0

str_main_menu_pun_7

  defb AT, 7, 64, INK, 4, "You grow it, we mow it", 0

str_main_menu_pun_8

  defb AT, 7, 80, INK, 4, "Get off my lawn", 0

str_scrolly_message

  defb " Manic Mower    Written by Brendan Alford    Music kindly donated by Gasman"
  defb "    Based on the crappy original written by myself in 1992 "
  defb "that somehow got published in Sinclair User...    "
  defb "Mow the lawns as quickly as possible while avoiding the walls, garden gnomes, plants and especially "
  defb "Rover the dog and his fellow mutts...   Pick up fuel cans to avoid running out of fuel...   "
  defb "Hitting obstacles will damage your mower causing it to burst into flames eventually...   "
  defb "Damage to your mower will need to be repaired before tackling the next lawn...                            "
  defb "Hello to all at S4E and WoS, and the Manic Mower Hardcore Fan Club (shakes head)...   ++++   ", 0

str_redefine_keys

  defb AT, 8, 80, INK, 7, BRIGHT, 1, "REDEFINE KEYS"
  defb AT, 11, 90, INK, 6, BRIGHT, 1, "Up........."
  defb AT, 12, 90, "Down...."
  defb AT, 13, 90, "Left......"
  defb AT, 14, 90, "Right...."
  defb AT, 15, 90, "Pause..", 0

str_keys_ok

  defb AT, 17, 50, "Are these keys ok? (y/n)", 0

str_high_score_title

  defb AT, 8, 70, INK, 2, BRIGHT, 1, "H ", INK, 3, "I ", INK, 4, "G ", INK, 5, "H   "
  defb INK, 6, "S ", INK, 7, "C ", INK, 2, "O ", INK, 3, "R ", INK, 4, "E ", INK, 5, "S", 0
