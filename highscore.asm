
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
  ld a, 26 * 8
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

; Index of latest high score is now in v_high_score_index.
; Shift all of the high score names down from that point.

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
