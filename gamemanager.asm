;
; Gamemanager.asm
; Routines for level setup, end of game handling etc.
;

gamemanager

  xor a
  ld (v_level), a
  call prepare_game
  call set_game_controls

gamemaanger_prep_level

  call set_print_shadow_screen
  call cls

  call prepare_level
  call display_level

  call set_print_main_screen
  xor a
  ld (v_attr), a
  call cls

  call copy_shadow_screen_pixels
  call fade_in_shadow_screen_attrs
  call set_print_main_screen

; Initialises the in game music, which lives in RAM page 1.

  ld hl, AY_GAME_TUNE
  ld a, 1
  call init_music
  call restart_music

; Set the initial level status message

  ld hl, str_level_begin
  ld a, STATUS_LEVEL_START
  call display_status_message

  call main_loop
  call fade_out_attrs
  call mute_music

; Was the game aborted

  ld a, (v_game_end_reason)
  cp GAME_ABORTED
  jr z, gamemanager_end

;check_game_over

  cp GAME_OVER
  jr nz, check_level_complete
  call gamemanager_game_over
  jp gamemanager_end

check_level_complete

  cp LEVEL_COMPLETE
  jr nz, gamemanager_end

  call gamemanager_level_complete
  ld hl, (v_level)
  inc (hl)
  jp gamemaanger_prep_level

gamemanager_end

  call mute_music
  call fade_out_attrs
  ret

;
; Handle Game Over scenario.
;

gamemanager_game_over

  ld hl, AY_GAMEOVER_TUNE
  ld a, 1
  call init_music
  call restart_music

  xor a
  ld (v_attr), a
  call cls
  call set_print_shadow_screen
  call cls

  call display_game_over_logo

  ld bc, 0x100

game_over_wait_keypressed

  halt
  call scan_keys
  jr z, gamemanager_end
  dec bc
  ld a, b
  or c
  jr nz, game_over_wait_keypressed
  ret

display_game_over_logo

  ld hl, img_game_over_logo
  ld de, 0x800 + (SHADOW_SCREEN_BYTES * 0x100)
  ld bc, 0x800
  ldir

  ld a, %01000010
  ld hl, SHADOW_SCREEN_ATTR * 0x100
  ld de, hl
  inc de
  ld bc, 0x300
  ld (hl), a
  ldir
  call copy_shadow_screen_pixels
  call fade_in_attrs
  ret

;
; Handle level complete scenario
;

gamemanager_level_complete


  ld hl, AY_LEVEL_COMPLETE_TUNE
  ld a, 3
  call init_music
  call restart_music

  xor a
  ld (v_attr), a
  call cls
  call set_print_shadow_screen
  call cls

  call display_level_complete

  call set_proportional_font

; Work out our time bonus

  ld ix, v_time
  ld hl, 0

gamemanager_lvc_calc_time

  ld a, (ix)
  cp '0'
  jr z, gamemanager_lvc_calc_time_2
  dec (ix)
  ld de, 10
  or a
  add hl, de
  jr gamemanager_lvc_calc_time

gamemanager_lvc_calc_time_2

  ld a, (ix+1)
  sub '0'
  ld e, a
  xor a
  ld d, a
  add hl, de

  ld (v_lvc_time_bonus), hl

; Start printing stats

  ld hl, str_time_bonus
  call print
  ld hl, (v_lvc_time_bonus)
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print
  ld hl, str_time_bonus_2
  call print
  ld hl, str_level_complete_tab
  call print


; Calculate time bonus and print it

  ld hl, 0
  ld bc, 100
  ld de, (v_lvc_time_bonus)

gamemanager_lvc_calc_time_bonus

  or a
  add hl, bc
  dec de
  ld a, d
  or e
  jr nz, gamemanager_lvc_calc_time_bonus

  ld (v_lvc_time_bonus), hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print

  ld hl, str_wages_earned
  call print
  ld hl, 150
  ld (v_lvc_wages), hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, str_level_complete_tab
  call print
  ld hl, str_pound
  call print
  ld hl, v_buffer
  call print
  call newline

; Did we hit any gnomes?

  ld a, (v_gnomes_hit)
  cp 0
  jr z, gamemanager_lvc_check_flowers

  ld hl, str_glue_to_stick_gnomes
  call print
  xor a
  ld h, a
  ld a, (v_gnomes_hit)
  ld l, a
  push hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print
  ld hl, str_glue_to_stick_gnomes_2
  ld a, (v_gnomes_hit)
  cp 1
  jr nz, gamemanager_lvc_check_gnomes_2
  ld hl, str_glue_to_stick_gnome_2

gamemanager_lvc_check_gnomes_2

  call print

; Calculate cost of hitting gnomes
; Multiply value in bc by 5

  pop bc
  ld hl, bc
  or a
  add hl, hl
  add hl, hl
  add hl, bc

  call display_and_subtract_cost

gamemanager_lvc_check_flowers

  ld a, (v_flowers_hit)
  cp 0
  jr z, gamemanager_lvc_check_rover

  ld hl, str_flower_cost
  call print
  xor a
  ld b, a
  ld a, (v_flowers_hit)
  ld c, a

; Calculate cost of hitting flowers
; Again, multiply value in bc by 5

  ld hl, bc
  or a
  add hl, hl
  add hl, hl
  add hl, bc

  call display_and_subtract_cost

; Check it we hit rover(s). This incurs a rather
; more severe financial penalty (as you probably
; don't have a conscience about mowing over a 8x8
; pixel sprite)

gamemanager_lvc_check_rover

  ld a, (v_dogs_hit)
  cp 0
  jr z, gamemanager_lvc_check_lawnmower

  ld hl, str_rover_vet_bill
  call print
  xor a
  ld b, a
  ld a, (v_dogs_hit)
  ld c, a

; Calculate cost of vets bill. £25 per impact.
; First multiply to 32

  push bc
  ld hl, bc
  or a
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl

; DE contains x 32 value

  ld de, hl
  pop hl
  or a
  add hl, hl
  add hl, hl
  add hl, hl

; HL now contains value x 8

  sub hl, bc

; ... and now x 7.

  ex de, hl

; 32 - 7 = 25 :)

  or a
  sub hl, de

  call display_and_subtract_cost

gamemanager_lvc_check_lawnmower

  ld a, (v_damage)
  cp 0
  jr z, gamemanager_lvc_do_totals

  ld hl, str_mower_repair
  call print
  xor a
  ld b, a
  ld a, (v_damage)
  ld c, a

; Mower damage is a far more reasonable
; £5 per damage point.

  ld hl, bc
  or a
  add hl, hl
  add hl, hl
  add hl, bc

  call display_and_subtract_cost

gamemanager_lvc_do_totals

; Work out cash in hand / cash bonus

  call newline
  ld hl, str_cash_in_hand
  call print
  ld hl, str_level_complete_tab
  call print
  ld hl, str_pound
  call print
  ld hl, (v_lvc_wages)
  push hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print

  ld hl, str_cash_bonus
  call print
  pop hl
  push hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print
  ld hl, str_cash_bonus_2
  call print
  ld hl, str_level_complete_tab
  call print
  pop hl
  ld de, hl

; Cash bonus is 20 x cash in hand

  or a
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl

  ex de, hl
  add hl, hl
  add hl, hl
  add hl, de
  ld (v_lvc_cash_bonus), hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print
  call newline

; Conclusion: add cash to time bonus and display it

  ld hl, (v_lvc_cash_bonus)
  ex de, hl
  ld hl, (v_lvc_time_bonus)
  or a
  add hl, de
  ld (v_lvc_total_bonus), hl
  push hl
  ld hl, str_total_bonus_score
  call print
  ld hl, str_level_complete_tab
  call print
  pop hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print

  ld hl, str_level_complete_any_key
  call print

  call copy_shadow_screen_pixels
  call fade_in_attrs

  call set_print_main_screen

  call get_key
  call fade_out_attrs

  call add_bonus_to_score

; Increment current level

  ld a, (v_level)
  inc a
  cp 8
  jr nz, gamemanager_game_incomplete

;
; Game complete. Woohoo!
;

  call set_print_shadow_screen
  call cls
  ld hl, img_game_complete
  ld de, SHADOW_SCREEN_BYTES * 0x100
  ld bc, 0x1000
  ldir
  ld de, SHADOW_SCREEN_ATTR * 0x100
  ld bc, 0x200
  ldir
  ld hl, str_game_complete
  call print
  call copy_shadow_screen_pixels
  call fade_in_attrs

  call set_print_main_screen
  call get_key
  call fade_out_attrs

; Back to the start. Poor suckers.

  xor a

gamemanager_game_incomplete

  ld (v_level), a
  call mute_music
  ret

;
; Displays Level Complete logo on the shadow screen
; ready for fade in.
;
display_level_complete

  ld hl, img_level_complete
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

;
; Displays and subtracts cost of damage
; (in HL) from wages earned.
;
display_and_subtract_cost

; Save value and print it

  push hl
  ld hl, str_level_complete_tab
  call print
  ld hl, str_pound
  call print
  pop hl
  push hl
  ld de, v_buffer
  call Num2Dec_NoTrail
  ld hl, v_buffer
  call print
  pop de

; Subtract it from wages Earned

  ld hl, (v_lvc_wages)
  or a
  sub hl, de
  ld (v_lvc_wages), hl
  ret

;
; Adds accrued bonus in v_lvc_total_bonus to the
; score.
; Doing it this was as it's easier to allow the
; game to work and increment in pure ASCII to
; save speed.
;
add_bonus_to_score

  ld hl, (v_lvc_total_bonus)
  ld a, h
  or l
  ret z
  dec hl
  ld (v_lvc_total_bonus), hl
  ld hl, v_score + 5

add_bonus_to_score_loop

  inc (hl)
  ld a, (hl)
  cp '9' + 1
  jr nz, add_bonus_to_score
  ld a, '0'
  ld (hl), a
  dec hl
  jr add_bonus_to_score_loop


prepare_game

  xor a
  ld (v_level), a
  ld a, '0'
  ld hl, v_score
  ld b, 6

init_score

  ld (hl), a
  inc hl
  djnz init_score
  xor a
  ld (hl), a
  ld (v_pending_score), a
  ret

  define LVC_TAB    28

str_time_bonus

  defb AT, 8, LVC_TAB, INK, 5, BRIGHT, 1, "Time bonus : ", 0

str_time_bonus_2

  defb " x 100", 0

str_wages_earned

  defb INK, 4, BRIGHT, 1, "\n", TAB, LVC_TAB, "Money earned :", 0

str_glue_to_stick_gnomes

  defb "\n", TAB, LVC_TAB, "Glue to stick ", 0

str_glue_to_stick_gnomes_2

  defb " gnomes :", 0

str_glue_to_stick_gnome_2

  defb " gnome :", 0

str_flower_cost

  defb INK, 4, BRIGHT, 1, "\n", TAB, LVC_TAB, "Flower bed repair :", 0

str_rover_vet_bill

  defb "\n", TAB, LVC_TAB, "Rover's vet bill : ", 0

str_mower_repair

  defb "\n", TAB, LVC_TAB, "Lawnmower repair bill : ", 0

str_cash_in_hand

  defb INK, 5, BRIGHT, 1, "\n", TAB, LVC_TAB, "Cash in hand : ", 0

str_cash_bonus

  defb INK, 6, BRIGHT, 1, "\n", TAB, LVC_TAB, "Cash bonus : ", 0

str_cash_bonus_2

  defb " x 20", 0

str_total_bonus_score

  defb INK, 2, BRIGHT, 1, "\n", TAB, LVC_TAB, "Total bonus score : ", 0

str_level_complete_any_key

  defb AT, 22, 48, INK, 5, BRIGHT, 1, "Press any key to continue...", 0

str_level_complete_tab

  defb TAB, 188, 0

str_pound

  defb 0x60, 0

str_game_complete

  defb AT, 17, 80, INK, 7, BRIGHT, 1, TEXTBOLD, "Congratulations!", TEXTNORM
  defb AT, 19, 12, "You have mown all eight lawns and lived"
  defb AT, 20, 12, "to tell the tale."
  defb AT, 21, 12, "Unfortunately, time (and grass growth)"
  defb AT, 22, 12, "stops for no one..."

str_press_any_key

  defb AT, 23, 160, INK, 4, "(press any key)", 0
