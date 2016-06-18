
  define HIGH_SCORE_TAB     26 * 8

;
; Displays the high score table.
;
display_high_scores

  ld b, 10
  ld a, b
  dec a
  ld (v_row), a
  ld ix, high_score_names
  ld iy, high_score_table

high_score_names_loop

  push bc
  push ix
  push iy

  xor a
  ld (v_column), a
  ld hl, ix
  ld a, %01000110
  ld (v_attr), a
  call print

  ld a, %01000110
  ld (v_attr), a

  call set_fixed_font
  ld a, HIGH_SCORE_TAB
  ld (v_column), a
  ld hl, iy
  call print
  call set_proportional_font

  pop iy
  pop ix
  or a
  ld bc, 40
  ld hl, ix
  add hl, bc
  ld ix, hl

  ld bc, 8
  ld hl, iy
  add hl, bc
  ld iy, hl

  pop bc
  djnz high_score_names_loop
  ret

;
; Checks to see if the current score in v_score
; merits a place in the high score table.
; Displays screen and accepts high score entry
; if required.
;
check_high_score

  ld de, v_score
  ld hl, high_score_table + (8 * 9)
  call compare_high_score

; Return if high score lower or equal to the bottom of
; the table

  ret nc

; Copy the score into slot number 10, it belongs there
; at the very least

  ld hl, v_score
  ld de, high_score_table + (8 * 9)
  ld bc, 6
  ldir

; And blank out the associated high score name (really just set)
; the termination byte

  ld hl, high_score_names + (40 * 9) + 7
  xor a
  ld (hl), a

  ld a, 9
  ld (v_high_score_index), a

; Loop to bubble the latest high score to its rightful place

check_high_score_2

  xor a
  ld h, a
  ld a, (v_high_score_index)
  ld l, a
  or a
  add hl, hl
  add hl, hl
  add hl, hl

  ld de, high_score_table
  add hl, de
  push hl
  pop de

; Latest high score is now in DE

  ld bc, 8
  sub hl, bc

; Current high score - 1 is in HL

  push hl
  push de
  call compare_high_score
  pop de
  pop hl
  jr nc, check_high_score_sort_complete

; Lower high score is bigger (again), swap them

  ld b, 6

check_high_score_sort_swap

  ld a, (de)
  ld c, a
  ld a, (hl)
  ld (de), a
  ld a, c
  ld (hl), a
  inc hl
  inc de
  djnz check_high_score_sort_swap

; Now swap the corresponding high score names

  xor a
  ld h, a
  ld a, (v_high_score_index)
  ld l, a
  push hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  ex de, hl
  pop hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, de
  ld de, 7
  add hl, de
  ld de, high_score_names
  add hl, de
  push hl
  ld de, 40
  sub hl, de
  ex de, hl
  pop hl

; HL contains current high score name, DE is high score - 1 name.
; Both offset by 7 bytes to start of string

  ld b, 32

check_high_score_name_swap

  ld a, (de)
  ld c, a
  ld a, (hl)
  ld (de), a
  ld a, c
  ld (hl), a
  inc hl
  inc de
  djnz check_high_score_name_swap

  ld a, (v_high_score_index)
  dec a
  ld (v_high_score_index), a
  cp 0
  jr nz, check_high_score_2

check_high_score_sort_complete

;
; Display the high score screen and allow the user to enter their
; name.
;

  ld hl, AY_HIGH_SCORE_TUNE
  ld a, 3
  call init_music

  call set_print_shadow_screen
  call cls
  call main_menu_logo
  call set_proportional_font
  ld hl, str_high_score_achieved
  call print
  call display_high_scores

  call set_print_main_screen
  call copy_shadow_screen_pixels
  call restart_music
  call fade_in_attrs

  di
  ld hl, high_score_isr
  ld (v_isr_location), hl
  ei

  ld a, (v_high_score_index)
  add 9
  ld (v_row), a
  ld a, 20
  ld (v_column), a

; Calculate position in high score name table and set IX
; as a pointer

  ld a, (v_high_score_index)
  ld l, a
  push hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  ex de, hl
  pop hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, de
  ld de, 7
  add hl, de
  ld de, high_score_names
  add hl, de
  ld ix, hl

; B = character count. Must not exceed 31.
; C = cursor flash status.

  ld c, 0
  ld b, 0
  ld a, %01000111
  ld (v_attr), a

enter_high_score_name

  halt

  inc c
  ld a, c
  sra a
  sra a
  sra a
  and 0x3
  cp 0
  jr z, enter_high_score_cursor_on
  cp 1
  jr z, enter_high_score_cursor_half
  ld a, ' '
  jr enter_high_score_name_2

enter_high_score_cursor_on

  ld a, 'n'
  jr enter_high_score_name_2

enter_high_score_cursor_half

  ld a, 'm'

enter_high_score_name_2

  push af
  call set_fixed_font
  pop af
  call putchar
  call set_proportional_font

enter_high_score_name_2a

  ld a, 1
  call scan_keys
  jr nc, enter_high_score_name

  cp CAPS_SHIFT
  jr z, enter_high_score_name_2a
  cp SYMBOL_SHIFT
  jr z, enter_high_score_name_2a

  cp DELETE
  jr nz, enter_high_score_name_3

; Is there anything to delete?

  ld a, b
  cp 0
  jr z, enter_high_score_name

; Clear cursor

  call set_fixed_font
  ld a, ' '
  call putchar
  call set_proportional_font

; Reposition pointers

  dec ix
  dec b

; Work out width of character we're deleting

  ld a, (ix)

  ld l, a
  xor a
  ld h, a
  ld de, proportional_data
  add hl, de
  ld a, (hl)
  ld d, a

; Subtract width of last character from print position

  ld a, (v_column)
  sub d
  ld (v_column), a

  jr enter_high_score_name_debounce

enter_high_score_name_3

  cp ENTER
  jr z, enter_high_score_end

; If delete or enter isn't pressed, don't
; allow any further key entry

  ld (v_buffer), a
  ld a, b
  cp 31
  jr z, enter_high_score_name

; Also don't allow any further entry
; if there's physically no room.

  ld a, (v_column)
  cp HIGH_SCORE_TAB - 32
  jr nc, enter_high_score_name

; Don't allow CS/SS on their own either

  ld a, (v_buffer)
  cp SYMBOL_SHIFT
  jp z, enter_high_score_name

; Store pressed character in IX and print it

  ld (ix), a
  push af
  call putchar
  pop af
  inc ix
  inc b

; Advance the cursor position by the number of
; pixels in the character

  ld l, a
  xor a
  ld h, a
  ld de, proportional_data
  add hl, de
  ld a, (hl)
  ld d, a
  ld a, (v_column)
  add d
  ld (v_column), a

enter_high_score_name_debounce

  call scan_keys
  jr c, enter_high_score_name_debounce

  jp enter_high_score_name

enter_high_score_end

; Terminate the high score string just entered

  ld (ix), 0
  ld a, b
  cp 0
  jr nz, enter_high_score_end_2
  ld hl, str_anonymous_coward
  ld de, ix
  ld bc,str_anonymous_coward_str_end - str_anonymous_coward
  ldir

enter_high_score_end_2

  di
  ld hl, 0
  ld (v_isr_location), hl
  ei

  call fade_out_attrs
  call mute_music
  ret

high_score_isr

  call move_logo_attrs
  ret

;
; Compares the high score pointed to by DE
; against that in HL. If DE is higher, returns
; carry set, else reset.
;
compare_high_score

  ld b, 6

compare_high_score_loop

  ld a, (de)
  cp (hl)
  jr c, compare_high_score_not_met
  jr z, compare_high_score_loop_next

  scf
  ret

compare_high_score_loop_next

  inc hl
  inc de
  djnz compare_high_score_loop

compare_high_score_not_met

  or a
  ret

str_high_score_achieved

  defb AT, 7, 56, INK, 6, BRIGHT, 1, "You have a high score!"
  defb AT, 21, 24, "Please type in your name and press"
  defb AT, 22, 60, "ENTER when complete.", 0

str_anonymous_coward

  defb "(Anonymous coward)", 0

str_anonymous_coward_str_end
