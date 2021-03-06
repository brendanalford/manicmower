;
; Game.asm
;
main_loop

  halt

  ld a, (v_audio_options)
  bit 0, a
  call nz, mower_sound

main_loop_2

; Break pressed to abort game?

  call check_break_pressed
  jp nc, main_loop_3

  ld a, GAME_ABORTED
  ld (v_game_end_reason), a
  jp main_loop_exit

main_loop_3

; Are we done with the grass?

  ld a, (v_grass_left)
  cp 0
  jp nz, main_loop_4

  ld a, LEVEL_COMPLETE
  ld (v_game_end_reason), a
  jp main_loop_exit

main_loop_4

  xor a
  ld (v_slow_movement), a

; Scan controls

check_control_input

  xor a
  call read_controls
  ld a, (v_controlbits)
  cp 0
  jp nz, control_input_made

  xor a
  ld (v_hit_solid), a

  jp check_dog_collision

control_input_made

  ld b, a
  ld a, (v_hit_solid)
  cp 0
  jr nz, check_dog_collision

check_game_paused

  ld hl, v_controlbits
  bit 4, (hl)
  jr z, check_mower_up

  call pause_game
  jr main_loop

check_mower_up

  bit 3, (hl)
  jr z, check_mower_down
  xor a
  ld (v_mower_x_dir), a
  dec a
  ld (v_mower_y_dir), a
  ld a, 'a'
  ld (v_mower_graphic), a
  jp check_dog_collision

check_mower_down

  bit 2, (hl)
  jr z, check_mower_left
  xor a
  ld (v_mower_x_dir), a
  inc a
  ld (v_mower_y_dir), a
  ld a, 'b'
  ld (v_mower_graphic), a
  jp check_dog_collision

check_mower_left

  bit 1, (hl)
  jr z, check_mower_right
  xor a
  ld (v_mower_y_dir), a
  dec a
  ld (v_mower_x_dir), a
  ld a, 'c'
  ld (v_mower_graphic), a
  jp check_dog_collision

check_mower_right

  bit 0, (hl)
  jr z, check_mower_moving
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

; Clear control bitmap at this point

  call clear_controls

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

  ld a, (v_dogs_hit)
  inc a
  ld (v_dogs_hit), a
  ld a, 4
  ld (v_hit_solid), a
  call add_damage
  call mower_sound_dog_collision

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


  ld a, (v_flowers_hit)
  inc a
  ld (v_flowers_hit), a

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
  ld a, FUELFRAMES
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

  push hl
  call calculate_mower_destination_coords

  inc h
  inc h
  inc h
  ld a, h
  ld (v_row), a
  ld a, l
  ld (v_column), a
  ld a, ATTRTRANS
  ld (v_attr), a
  ld a,'i'
  call putchar_8
  ld a, 7
  ld (v_attr), a
  pop hl


  ld a, (v_gnomes_hit)
  inc a
  ld (v_gnomes_hit), a

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

; If we're going to move a dog at this point, do it here

  call check_move_dog

  ld b, 8

mower_move

  ld a, b
  cp 8
  jr z, mower_move_2

  halt

mower_move_2

  ld a, (v_audio_options)
  bit 0, a
  call nz, mower_sound

  ld a, (v_slow_movement)
  cp 0
  jr z, mower_move_3
  halt

mower_move_3

; Move the mower

  call move_mower_pixel

; If there's a dog moving, take care of him also

  ld a, (v_dog_moving)
  cp 0
  jr z, mower_move_4

  call move_dog_pixel

mower_move_4

  call increment_score

  xor a
  out (0xfe), a

; Allow input when mower/dog is mid-move

  push af
  push bc
  push hl
  call read_controls
  pop hl
  pop bc
  pop af
  
  call end_frame
  djnz mower_move

main_loop_end

  call end_frame
  call increment_score
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

  ld a, (v_time_expired)
  cp 0
  jr z, main_loop_end_4

  call main_game_over_out_of_time
  jp main_loop_exit

main_loop_end_4

  xor a
  out (0xfe), a

  jp main_loop

main_loop_exit

  xor a
  out (0xfe), a
  ret

;
; Too much damage.
;

main_game_over_damage

  ld hl, str_game_over_damage
  ld a, STATUS_GAME_OVER
  call display_status_message

  ld a, ATTRTRANS
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

  push bc
  ld a, (v_mower_graphic)
  call putchar_8
  pop bc
  ld hl, bc

main_game_over_damage_loop_1

  ld a, (v_audio_options)
  bit 0, a
  jr z, main_game_over_damage_loop_1a

  ld a, (hl)
  and 0xf8
  out (0xfe), a

main_game_over_damage_loop_1a

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

; Delay 2 seconds or so

  ld bc, 100
  call delay_frames
  call mute_music

  ld a, GAME_OVER
  ld (v_game_end_reason), a
  ret

;
; Out of time
;

main_game_over_out_of_time

  ld hl, str_game_over_time
  ld a, STATUS_GAME_OVER
  call display_status_message
  jr main_game_over_out_of_fuel_2

;
; Out of fuel
;

main_game_over_out_of_fuel

  ld hl, str_game_over_fuel
  ld a, STATUS_GAME_OVER
  call display_status_message

main_game_over_out_of_fuel_2

  ld a, (v_audio_options)
  bit 0, a
  jr z, main_game_over_fuel_end

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
  ld a, (v_audio_options)
  bit 0, a
  call nz, mower_sound
  pop de
  pop bc
  djnz main_game_over_fuel_loop_2
  inc d
  ld a, d
  cp 0x08
  jr nz, main_game_over_fuel_loop

; Delay 2 seconds or so

main_game_over_fuel_end

  ld bc, 100
  call delay_frames
  call mute_music
  ld a, GAME_OVER
  ld (v_game_end_reason), a
  ret

;
; Check for each dog in the dog list:
; - Are we actually going to move the dog?
; - What direction we're going to send him in.
; - Can he actually move in that direction (mown grass only)
; If one is selected for movement, no others will move even
; if it turns out the selected one cant move.

check_move_dog

  xor a
  ld (v_dog_moving), a

  ld a, (v_cheat_mode)
  bit 4, a
  ret nz

  ld ix, v_dogbuffer

check_move_dog_2

; Check to see if we have a dog to consider

  ld a, (ix)
  or (ix+1)
  jr nz, check_move_dog_found

; End of dog list and no dog selected, return

  ret

check_move_dog_found

; Decide if we want to move this mutt

  call random
  and 0x3
  cp 0

  jr z, check_move_dog_selected

; Not moving this dog, consider others

  inc ix
  inc ix
  jr check_move_dog_2

check_move_dog_selected

; Moving this dog, pick a direction to move

  xor a
  ld (v_dog_x_dir), a
  ld (v_dog_y_dir), a


  call random
  and 3

; Check right

  cp 0
  jr nz, check_move_dog_sel_1

  ld a, 1
  ld (v_dog_x_dir), a
  jr check_move_dog_can_move

check_move_dog_sel_1

; Check left

  cp 1
  jr nz, check_move_dog_sel_2

  ld a, 255
  ld (v_dog_x_dir), a
  jr check_move_dog_can_move

check_move_dog_sel_2

; Check up

  cp 2
  jr nz, check_move_dog_sel_3

  ld a, 255
  ld (v_dog_y_dir), a
  jr check_move_dog_can_move

check_move_dog_sel_3

; If no direction has been chosen, go for move down

  ld a, 1
  ld a, 255
  ld (v_dog_y_dir), a

check_move_dog_can_move

; Calculate the dog's destination. He's still at IX
; Destination will be in HL
; While doing this, store the dog's current location in HL'

  ld a, (ix)
  ld l, a
  exx
  ld l, a
  exx
  ld a, (v_dog_x_dir)
  add l
  ld l, a

  ld a, (ix+1)
  ld h, a
  exx
  ld h, a
  exx
  ld a, (v_dog_y_dir)
  add h
  ld h, a

; Store destination in DE for later

  push hl
  pop de

; Check for collision with other doggies

  ld iy, v_dogbuffer

check_move_dog_is_unsociable

; Check if we've passed the end of the list

  ld a, (iy)
  or (iy+1)
  jr z, check_move_dog_free_to_move

  ld a, (iy)
  cp e
  jr nz, check_move_dog_unsociable_next
  ld a, (iy+1)
  cp d

; Return if there's a dog at the destination coords

  ret z

check_move_dog_unsociable_next

  inc iy
  inc iy
  jr check_move_dog_is_unsociable

check_move_dog_free_to_move

; Get offset into level buffer of destination

  call calc_xy_to_hl
  ld bc, level_buffer
  or a
  add hl, bc

; Mown grass?

  ld a, (hl)
  cp MOWN_GRASS
  ret nz

; Yay - criteria filled!
; 1) Update the dog position in the buffer
; 2) Set game variables for the move

  ld (ix), e
  ld (ix+1), d

  ld a, 1
  ld (v_dog_moving), a

; Set current pixel position of the dog
; This is in HL' from earlier

  exx
  ld a, l
  sla a
  sla a
  sla a
  ld (v_dog_x_moving), a

  ld a, h
  inc a
  inc a
  inc a

  sla a
  sla a
  sla a
  ld (v_dog_y_moving), a
  exx

; All vars set, the main loop will handle this from now on

  ret

;
; Moves the mower in the direction desired, pixel by pixel
;
move_mower_pixel

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
  ret


;
; Moves the dog in the direction desired, pixel by pixel
;
move_dog_pixel

  ld a, (v_dog_x_moving)
  ld (v_column), a
  ld a, (v_dog_y_moving)
  ld (v_row), a
  ld a, ' '
  call putchar_pixel

  ld a, (v_dog_x_moving)
  ld c, a
  ld a, (v_dog_x_dir)
  add a, c
  ld (v_dog_x_moving), a

  ld a, (v_dog_y_moving)
  ld c, a
  ld a, (v_dog_y_dir)
  add a, c
  ld (v_dog_y_moving), a

  ld a, (v_dog_x_moving)
  ld (v_column), a
  ld a, (v_dog_y_moving)
  ld (v_row), a
  ld a, 'f'
  call putchar_pixel
  ret

;
; Sits around not doing very much until a
; key is pressed to restart the game
;
pause_game

; Initialise scrolly pause message

  call clear_status_message
  call set_proportional_font
  ld hl, str_pause_scroll_message
  ld a, %01000010
  ld b, a
  ld a, 22
  ld c, a
  call init_scrolly

; First debounce, ensure no keys are pressed

pause_game_debounce

  ld b, 10

pause_game_debounce_1

  halt
  call move_scrolly
  xor a
  in a, (0xfe)
  and 0x1f
  cp 0x1f
  jr nz, pause_game_debounce
  dec b
  ld a, b
  cp 0
  jr nz, pause_game_debounce_1

pause_game_2

  halt
  call move_scrolly

move_pause_attrs

  ld de, 0x5ac0
  ld a, (v_logo_attr_ptr)

  ld hl, logo_attr_buffer
  ld l, a
  ld b, 31

move_pause_attrs_2

  ld a, (hl)
  ld (de), a
  inc de
  inc l
  djnz move_pause_attrs_2

  ld hl, v_logo_attr_ptr
  inc (hl)

  call scan_keys
  jr nc, pause_game_2
  call clear_controls
  call read_controls
  bit 4, (hl)
  jr nz, pause_game_2

  ld (v_status_delay), a
  call expire_status_message
  call set_fixed_font
  ret

str_pause_scroll_message

str_game_paused

  defb "Game paused - press any key to resume +++ ", 0xFF
  defw str_game_paused
