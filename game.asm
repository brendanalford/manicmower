;
; Game.asm
;
main_loop

  call frame_halt
  call mower_sound

; Are we done with the grass?

  ld a, (v_grass_left)
  cp 0
  jp z, main_loop_exit

  xor a
  ld (v_slow_movement), a

; Scan keyboard

check_keyboard

  xor a
  call scan_keys
  jp c, check_keyboard_input

  xor a
  ld (v_hit_solid), a

  jr mower_pre_move

check_keyboard_input

  ld b, a
  ld a, (v_hit_solid)
  cp 0
  jr nz, mower_pre_move

  ld a, b
  cp ' '
  jp z, main_loop_exit

check_mower_key_up

  cp 'Q'
  jr nz, check_mower_key_down
  xor a
  ld (v_mower_x_dir), a
  dec a
  ld (v_mower_y_dir), a
  ld a, 'a'
  ld (v_mower_graphic), a
  jp mower_pre_move

check_mower_key_down

  cp 'A'
  jr nz, check_mower_key_left
  xor a
  ld (v_mower_x_dir), a
  inc a
  ld (v_mower_y_dir), a
  ld a, 'b'
  ld (v_mower_graphic), a
  jp mower_pre_move

check_mower_key_left

  cp 'O'
  jr nz, check_mower_key_right
  xor a
  ld (v_mower_y_dir), a
  dec a
  ld (v_mower_x_dir), a
  ld a, 'c'
  ld (v_mower_graphic), a
  jp mower_pre_move

check_mower_key_right

  cp 'P'
  jr nz, check_mower_moving
  xor a
  ld (v_mower_y_dir), a
  inc a
  ld (v_mower_x_dir), a
  ld a, 'd'
  ld (v_mower_graphic), a

check_mower_moving

  ld a, (v_mower_x_dir)
  cp 0
  jr nz, mower_pre_move
  ld a, (v_mower_y_dir)
  cp 0
  jp z, main_loop_end

mower_pre_move

; Calculate destination of mower for some Checks

  ld a, (v_mowerx)
  ld l, a
  ld a, (v_mower_x_dir)
  add l
  ld l, a
  ld a, (v_mowery)
  ld h, a
  ld a, (v_mower_y_dir)
  add h
  ld h, a
  call calc_xy_to_hl
  ld de, level_buffer
  ex de, hl
  add hl, de

check_mowing_grass

  ld a, (hl)
  cp GRASS
  jr nz, check_mower_wall_collision

  xor a
  ld (hl), a

; 10 points for grass mown

  ld a, 1
  call add_to_pending_score

  jr mower_set_movement

check_mower_wall_collision

  ld a, (hl)
  cp WALL
  jr nz, check_flower_collision

  ld a, 2
  ld (v_hit_solid), a
  call add_damage
  call mower_sound_wall_collision


  ld hl, str_hit_wall
  ld a, STATUS_HIT_WALL
  call display_status_message

  xor a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a
  jp main_loop_end

check_flower_collision

  cp FLOWERS
  jr nz, check_fuel_collision

  xor a
  ld (hl), a

  ld hl, str_hit_flowers
  ld a, STATUS_HIT_FLOWERS
  call display_status_message

; Move slowly through flowerbeds

  ld a, 1
  ld (v_slow_movement), a
  call add_damage

  jp mower_set_movement

check_fuel_collision

  cp FUEL
  jr nz, check_gnome_collision

  xor a
  ld (hl), a
  ld a, 80
  ld (v_fuel), a
  ld a, FUEL_FRAMES
  ld (v_fuel_frame), a
  ld hl, str_fuel_bar
  call print

; 100 points for fuel pickup

  ld a, 10
  call add_to_pending_score
  jr mower_set_movement

check_gnome_collision

  cp GNOME
  jr nz, mower_set_movement

  ld a, 1
  ld (v_hit_solid), a
  call add_damage
  call mower_sound_gnome_collision

  ld hl, str_hit_gnome
  ld a, STATUS_HIT_GNOME
  call display_status_message

  xor a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a
  jp main_loop_end


mower_set_movement

  call mower_set_pixel_position
  ld a, (v_mowerx)
  ld b, a
  ld a, (v_mower_x_dir)
  add b
  ld (v_mowerx), a

  ld a, (v_mowery)
  ld b, a
  ld a, (v_mower_y_dir)
  add b
  ld (v_mowery), a

  ld b, 8

mower_move

  ld a, b
  cp 8
  jr z, mower_move_2

  call frame_halt

mower_move_2

  call mower_sound
  ld a, (v_slow_movement)
  cp 0
  jr z, mower_move_3
  call frame_halt

mower_move_3

  ld a, (v_mower_x_moving)
  ld (v_column), a
  ld a, (v_mower_y_moving)
  ld (v_row), a
  ld a, ' '
  call putchar_pixel

  ld a, (v_mower_x_moving)
  ld c, a
  ld a, (v_mower_x_dir)
  add a, c
  ld (v_mower_x_moving), a

  ld a, (v_mower_y_moving)
  ld c, a
  ld a, (v_mower_y_dir)
  add a, c
  ld (v_mower_y_moving), a

  ld a, (v_mower_x_moving)
  ld (v_column), a
  ld a, (v_mower_y_moving)
  ld (v_row), a
  ld a, (v_mower_graphic)
  call putchar_pixel

  call increment_score

  xor a
  out (0xfe), a
  djnz mower_move

main_loop_end

  call increment_score
  ld a, 2
  out (0xfe), a

  call survey_grass
  call handle_status

; Check damage

  ld a, (v_damage)
  cp 9
  jr nz, main_loop_end_2

; Too much damage, goneski

  call main_game_over_damage
  jp main_loop_exit

main_loop_end_2

  ld a, (v_fuel)
  cp 0
  jr nz, main_loop_end_3

  call main_game_over_out_of_fuel
  jp main_loop_exit

main_loop_end_3

  xor a
  out (0xfe), a

  jp main_loop

main_loop_exit

  xor a
  out (0xfe), a

  im 1
  ret

;
; Too much damage.
;

main_game_over_damage

  ld hl, str_game_over_damage
  ld a, STATUS_GAME_OVER
  call display_status_message

  ld a, ATTR_TRANS
  ld (v_attr), a
  ld a, (v_mowerx)
  ld (v_column), a
  ld a, (v_mowery)
  inc a
  inc a
  inc a
  ld (v_row), a

  ld bc, 0x80
  ld a, 'a'
  ld (v_mower_graphic), a

main_game_over_damage_loop

  halt
  push bc
  ld a, (v_mower_graphic)
  call putchar_8
  pop bc
  ld hl, bc

main_game_over_damage_loop_1

  ld a, (hl)
  and 0xf8
  out (0xfe), a
  push bc
  ld bc, 0x10

main_game_over_damage_loop_3

  djnz main_game_over_damage_loop_3
  pop bc

  dec hl
  ld a, h
  or l
  jr nz, main_game_over_damage_loop_1

  ld a, (v_mower_graphic)
  inc a
  ld (v_mower_graphic), a
  cp 'e'
  jr nz, main_game_over_damage_loop_2

  ld a, 'a'
  ld (v_mower_graphic), a

main_game_over_damage_loop_2

  ld hl, bc
  ld bc, 4
  sub hl, bc
  ld bc, hl

  ld a, b
  or c
  jr nz, main_game_over_damage_loop

  ld a, 7
  ld (v_attr), a
  ret

;
; Out of fuel
;

main_game_over_out_of_fuel

  ld hl, str_game_over_fuel
  ld a, STATUS_GAME_OVER
  call display_status_message

  ld d, 1

main_game_over_fuel_loop

  ld b, 10

main_game_over_fuel_loop_2

  push bc
  ld b, d

main_game_over_fuel_loop_3

  halt
  djnz main_game_over_fuel_loop_3
  pop bc

  push bc
  push de
  call mower_sound
  pop de
  pop bc
  djnz main_game_over_fuel_loop_2
  inc d
  ld a, d
  cp 0x08
  jr nz, main_game_over_fuel_loop

  ret

;
; Take care of frame flyback, time counts etc.
;

frame_halt

  halt
  di
  push hl
  push de
  push bc

  ld a, (v_fuel_frame)
  dec a
  cp 0
  jr nz, frame_halt_2

; Are we out of fuel?

  ld a, (v_fuel)
  cp 0
  jr z, frame_halt_2

; Decrement fuel

  dec a
  ld (v_fuel), a

; Display actual fuel left

  ld b, 175
  ld a, (v_fuel)
  add b
  ld (v_column), a
  ld a, 8
  ld (v_row), a
  ld a, ' '
  call putchar_pixel

  ld a, FUEL_FRAMES

frame_halt_2

  ld (v_fuel_frame), a

  ld a, (v_time_frame)
  dec a
  cp 0
  jr nz, frame_halt_3

; Decrement clock

  ld hl, v_time + 1

decrement_loop

  ld a, (hl)
  dec a
  cp '0' - 1
  jr nz, decrement_done

  ld a, '9'
  ld (hl), a
  dec hl
  jr decrement_loop

decrement_done

  ld (hl), a

  xor a
  ld (v_row), a
  ld a, 30
  ld (v_column), a
  ld a, 0x45
  ld (v_attr), a

  ld a, (v_time)
  call putchar_8
  ld a, 31
  ld (v_column), a
  ld a, (v_time + 1)
  call putchar_8

  ld a, 7
  ld (v_attr), a

  ld a, TIME_FRAMES

frame_halt_3

  ld (v_time_frame), a

  pop bc
  pop de
  pop hl
  ei
  ret

;
; Count how much grass there is left to mow and store it.
;

survey_grass

  ld a, 0
  ld (v_grass_left), a
  ld hl, level_buffer
  ld bc, LEVEL_BUFFER_LEN
  ld de, 0

survey_grass_loop

  ld a, (hl)
  cp GRASS
  jr nz, survey_grass_next

  ld a, 1
  ld (v_grass_left), a
  ret

survey_grass_next

  inc hl
  dec bc
  ld a, b
  or c
  jr nz, survey_grass_loop
  ret

;
; Handle status
; Decrement counter and erase message if expired
;

handle_status

  ld a, (v_status_delay)
  cp 0
  ret z
  dec a
  ld (v_status_delay), a
  cp 0
  ret nz
  call expire_status_message
  ret

;
; Expire the status message area
; (Write black/black attributes but don't erase the screen)
;

expire_status_message

  ld hl, 0x5ac0
  ld de, 0x5ac1
  ld bc, 0x40
  xor a
  ld (hl), a
  ldir
  ld (v_status_msg), a
  ret
;
; Clear the status message area
;
clear_status_message

  xor a
  ld (v_status_msg), a

  push hl
  ld a, 22
  ld (v_row), a
  xor a
  ld (v_column), a

clear_status_msg_loop

  ld a, ' '
  call putchar_8
  ld a, (v_column)
  inc a
  ld (v_column), a

  cp 32
  jr nz, clear_status_msg_loop

  xor a
  ld (v_column), a
  ld a, (v_row)
  cp 23
  jr z, clear_status_msg_loop_end
  ld a, 23
  ld (v_row), a
  jr clear_status_msg_loop
  ret

clear_status_msg_loop_end

  pop hl
  ret

;
; Display status message
; Address of message is in HL
; Message code is in A
; Bottom two lines are cleared beforehand
;

display_status_message

  ld b, a
  ld a, (v_status_msg)
  cp b
  jr nz, display_status_message_2

; Same message already displayed, just extend the timer

  ld a, 20
  ld (v_status_delay), a
  ret

display_status_message_2

  ld a, b
  push hl
  push af
  call clear_status_message
  pop af

  ld (v_status_msg), a
  ld a, 20
  ld (v_status_delay), a

  call set_proportional_font
  pop hl
  call print
  call set_fixed_font
  ret

; Called to display score and high score values.
;

display_score

  push bc
  xor a
  ld (v_row),a
  ld a, 6
  ld (v_column), a
  ld a, 0x45
  ld (v_attr), a

  ld a, 6
  ld b, a
  ld hl, v_score

display_score_loop

  ld a, (hl)
  call putchar_8
  ld a, (v_column)
  inc hl
  inc a
  ld (v_column), a
  djnz display_score_loop

  ld a, 6
  ld b, a
  ld a, 18
  ld (v_column), a
  ld hl, high_score_table

display_score_loop_2

  ld a, (hl)
  call putchar_8
  ld a, (v_column)
  inc hl
  inc a
  ld (v_column), a
  djnz display_score_loop_2

  pop bc
  ld a, 7
  ld (v_attr), a
  ret

;
; Adds the amount given in accumulator
; to the player's pending score
;

add_to_pending_score

  ld b, a
  ld a, (v_pending_score)
  add b
  ld (v_pending_score), a
  ret

;
; Handles adding any pending score to the
; player's current score.
;

increment_score

  ld a, (v_pending_score)
  cp 0
  ret z
  dec a
  ld (v_pending_score), a
  ld hl, v_score + 4

  ld a, 10
  ld (v_column), a
  ld a, 0
  ld (v_row), a
  ld a, 0x45
  ld (v_attr), a

increment_score_loop

  ld a, (hl)
  inc a
  cp '9' + 1
  jr nz, increment_score_done
  ld a, '0'
  ld (hl), a
  push hl
  call putchar_8
  pop hl
  ld a, (v_column)
  dec a
  ld (v_column), a
  dec hl
  jr increment_score_loop

increment_score_done
  ld (hl), a
  call putchar_8

  ret
;
; Add damage
; Amount of damage to add is held in accumulator
;

add_damage

  ld b, a
  ld a, (v_damage)
  add b
  cp 9

  jr c, add_damage_display

  ld a, 9

add_damage_display

  ld (v_damage), a
  ld b, a

; Repaint the damage meter

  ld a, 1
  ld (v_row), a
  ld a, 7
  ld (v_column), a
  ld a, ATTR_TRANS
  ld (v_attr), a

add_damage_loop

  ld a, 'k'
  call putchar_8
  ld a, (v_column)
  inc a
  ld (v_column), a
  djnz add_damage_loop
  ld a, 7
  ld (v_attr), a
  ret

;
; Main mower sound effect.
; Call at the beginning of each frame.
;
mower_sound

  push bc
  ld a, 0x11
  out (0xfe), a
  ld b, 0x20

mower_sound_loop

  djnz mower_sound_loop

  ld a, 0x1
  out (0xfe), a
  pop bc
  ret

mower_sound_wall_collision

  push hl
  push de
  push bc
  ld hl, 0
  ld bc, 0x60
  ld d, 0xff

mower_sound_wall_collision_loop

  ld a, (hl)
  and 0xf8
  out (0xfe), a
  push bc
  ld b, d

mower_sound_wall_collision_loop_inner

  djnz mower_sound_wall_collision_loop_inner
  pop bc
  dec d
  inc hl
  dec bc
  ld a, b
  or c
  jr nz, mower_sound_wall_collision_loop

  pop bc
  pop de
  pop hl
  ret

mower_sound_gnome_collision

  push hl
  push bc
  ld hl, 0
  ld bc, 0x200

mower_sound_gnome_collision_loop

  ld a, (hl)
  and 0xf8
  out (0xfe), a

  inc hl
  dec bc
  ld a, b
  or c
  jr nz, mower_sound_gnome_collision_loop

  pop bc
  pop hl
  ret


;
; Sets the pixel position of the mower based on
; current playfield coordinates
;
mower_set_pixel_position

  ld a, (v_mowerx)
  sla a
  sla a
  sla a
  ld (v_mower_x_moving), a
  ld a, (v_mowery)

; Map y coordinate from playfield to screen

  inc a
  inc a
  inc a

  sla a
  sla a
  sla a
  ld (v_mower_y_moving), a
  ret
