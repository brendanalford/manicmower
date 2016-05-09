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

  jp check_dog_collision

check_keyboard_input

  ld b, a
  ld a, (v_hit_solid)
  cp 0
  jr nz, check_dog_collision

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
  jp check_dog_collision

check_mower_key_down

  cp 'A'
  jr nz, check_mower_key_left
  xor a
  ld (v_mower_x_dir), a
  inc a
  ld (v_mower_y_dir), a
  ld a, 'b'
  ld (v_mower_graphic), a
  jp check_dog_collision

check_mower_key_left

  cp 'O'
  jr nz, check_mower_key_right
  xor a
  ld (v_mower_y_dir), a
  dec a
  ld (v_mower_x_dir), a
  ld a, 'c'
  ld (v_mower_graphic), a
  jp check_dog_collision

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

check_dog_collision

; Store mower XY coords in DE

  ld a, (v_mowerx)
  ld d, a
  ld a, (v_mowery)
  ld e, a

  ld hl, v_dogbuffer

check_dog_collision_loop

; Load current dog XY coordinates to BC

  ld a, (hl)
  ld b, a
  inc hl
  ld a, (hl)
  ld c, a
  inc hl

; Exit if 0,0 (Last dog processed)

  ld a, c
  or b
  jp z, mower_pre_move

  ld a, d
  cp b
  jr nz, check_dog_collision_loop
  ld a, e
  cp c
  jr nz, check_dog_collision_loop

; Dead doggy

  call remove_hit_dog
  call splatter

  ld a, 4
  ld (v_hit_solid), a
  call add_damage

  ld hl, str_hit_dog
  ld a, STATUS_HIT_DOG
  call display_status_message

  xor a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a
  jp main_loop_end


; Calculate destination of mower for some Checks

mower_pre_move

  call calculate_mower_destination_coords
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
  jp mower_set_movement

check_gnome_collision

  cp GNOME
  jr nz, mower_set_movement
  ld a, BROKEN_GNOME
  ld (hl), a

  di
  push hl
  call calculate_mower_destination_coords

  inc h
  inc h
  inc h
  ld a, h
  ld (v_row), a
  ld a, l
  ld (v_column), a
  ld a, ATTR_TRANS
  ld (v_attr), a
  ld a,'i'
  call putchar_8
  ld a, 7
  ld (v_attr), a
  pop hl

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
  ei
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

  di
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
  ei

; Delay 2 seconds or so

  ld bc, 100
  call delay_frames

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

  ; Delay 2 seconds or so

  ld bc, 100
  call delay_frames
  ret

;
; Calculates the mower's destination coordinates
; and places them in HL = YX
;
calculate_mower_destination_coords

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
  ret

;
; Calculates the mower's current coordinates
; and places them in HL = YX
;
calculate_mower_current_coords

  ld a, (v_mowerx)
  ld l, a
  ld a, (v_mowery)
  ld h, a
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
