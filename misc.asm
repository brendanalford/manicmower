;
; misc.asm
;

init_misc

  ld a, 1
  ld hl, v_audio_options
  ld (hl), a
  ld a, (v_128k_detected)
  cp 0
  ret z
  set 1, (hl)
  ret


init_controls

  ld hl, default_keys
  ld de, v_definekeys
  ld bc, 5
  ldir
  xor a
  ld (v_control_method), a
  ret

set_game_controls

  ld de, v_playerkeys
  ld bc, 5

  ld a, (v_control_method)
  cp 0
  jr nz, set_game_controls_2

  ld hl, v_definekeys
  jr set_game_controls_end

set_game_controls_2

  cp 1
  jr nz, set_game_controls_3

  ld hl, controls_sinclair1
  jr set_game_controls_end

set_game_controls_3

  cp 2
  jr nz, set_game_controls_4

  ld hl, controls_sinclair2
  jr set_game_controls_end

set_game_controls_4

  cp 4
  ret nz

  ld hl, controls_cursor

set_game_controls_end

  ldir
  ret

controls_sinclair1

  defb "98670"

controls_sinclair2

  defb "43125"

controls_cursor

  defb "76580"

;
; Reads the keyboard (or Kempston joystick) and sets the
; control bitmap appropriately
;
read_controls

  xor a
  ld (v_controlbits), a

  ld a, (v_control_method)
  cp 3
  jr nz, read_controls_keyboard

read_controls_kempston

  in a, (0x1f)
  and 0x1f
  ld (v_controlbits), a
  ret

read_controls_keyboard

  xor a
  call scan_keys
  ret nc

  ld hl, v_controlbits
  ld b, a
  ld a, (v_playerpause)
  cp b
  jr nz, read_controls_up

  set 4, (hl)
  ret

read_controls_up

  ld a, (v_playerup)
  cp b
  jr nz, read_controls_down

  set 3, (hl)
  ret

read_controls_down

  ld a, (v_playerdown)
  cp b
  jr nz, read_controls_left

  set 2, (hl)
  ret

read_controls_left

  ld a, (v_playerleft)
  cp b
  jr nz, read_controls_right

  set 1, (hl)
  ret

read_controls_right

  ld a, (v_playerright)
  cp b
  ret nz

  set 0, (hl)
  ret

;
; Checks if break was pressed. Carry flag reflects status.
;
check_break_pressed

  or a
  ld bc, 0xfefe
  in a, (c)
  bit 0, a
  ret nz
  ld bc, 0x7ffe
  in a, (c)
  bit 0, a
  ret nz
  scf
  ret

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


delay_frames

  halt
  dec bc
  ld a, b
  or c
  jr nz, delay_frames
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
  ld bc, 0x3f
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
; Before anyone calls the ISPCA, I'm not proud of this.
; It was in the original game though, so I'd better
; be faithful.
;
splatter

  call calculate_mower_current_coords
  dec h
  ld a, 'o'
  call splatter_main

  call calculate_mower_current_coords
  dec l
  ld a, 'p'
  call splatter_main

  call calculate_mower_current_coords
  inc h
  ld a, 'q'
  call splatter_main

  call calculate_mower_current_coords
  inc l
  ld a, 'r'
  call splatter_main

  ret

splatter_main

  push hl
  pop de

; XY coords now in DE

  ld bc, level_buffer
  call calc_xy_to_hl

  or a
  add hl, bc

; Buffer coords now in HL

  ld b, a
  ld a, (hl)

; Place splatter only on grass (mown/unmown)
  cp MOWN_GRASS
  jr z, display_splatter
  cp GRASS
  ret nz

display_splatter

  ld a, e
  ld (v_column), a
  ld a, d
  inc a
  inc a
  inc a
  ld (v_row), a
  bit 0, d
  ld a, %00100010 ; Green paper, red ink
  jr z, display_splatter_2
  ld a, %01100010 ; bright green

display_splatter_2

  ld (v_attr), a
  ld a, b
  call putchar_8
  ld a, 7
  ld (v_attr), a
  ret


;
; Address of dog to remove will be in HL-2.
; Remove this and move all other dogs in the
; buffer up two bytes.
;
remove_hit_dog

  dec hl
  dec hl
  ld bc, 0
  ld (hl), bc
  push hl
  pop de
  inc de
  inc de

remove_hit_dog_loop

  ld a, (de)
  ld b, a
  inc de
  ld a, (de)
  ld c, a
  inc de
  or b
  jr z, remove_hit_dog_done

  ld (hl), bc
  inc hl
  inc hl
  jr remove_hit_dog_loop

remove_hit_dog_done

  ret

;
; Main mower sound effect.
; Call at the beginning of each frame.
;
mower_sound

  push bc
  ld a, 0x10
  ;ld a, 0x11
  out (0xfe), a
  ld b, 0x10

mower_sound_loop

  djnz mower_sound_loop

  xor a
;  ld a, 0x1
  out (0xfe), a
  pop bc
  ret

mower_sound_dog_collision

  ld a, (v_audio_options)
  bit 0, a
  ret z

  push hl
  push de
  push bc
  ld hl, 0
  ld bc, 0x60
  ld d, 0xff

mower_sound_dog_collision_loop

  ld a, (hl)
  and 0xf8
  out (0xfe), a
  push bc
  ld b, d

mower_sound_dog_collision_loop_inner

  djnz mower_sound_dog_collision_loop_inner
  pop bc
  dec d
  inc hl
  dec bc
  ld a, b
  or c
  jr nz, mower_sound_dog_collision_loop

  pop bc
  pop de
  pop hl
  ret

mower_sound_gnome_collision

  ld a, (v_audio_options)
  bit 0, a
  ret z

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

mower_sound_wall_collision

  ld a, (v_audio_options)
  bit 0, a
  ret z

  ld bc, 0x80

main_sound_wall_collision_loop

  ld hl, bc

main_sound_wall_collision_loop_1

  ld a, (hl)
  and 0xf8
  out (0xfe), a
  push bc
  ld bc, 0x0002

main_sound_wall_collision_loop_2

  djnz main_sound_wall_collision_loop_2
  pop bc

  dec hl
  ld a, h
  or l
  jr nz, main_sound_wall_collision_loop_1

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


;	AY Player constants

	define ay_player_init   ay_player_base
	define ay_player_play   ay_player_base + 0x05
	define ay_player_mute   ay_player_base + 0x08

;
; Sets current music module to be played.
; Address of module should be in HL.
; RAM page of module should be in A.
;

init_music


  ld (v_module_page), a

; Do nothing if we're on a 48k

  ld a, (v_128k_detected)
  cp 0
  ret z

  halt
  di
  call pagein_module
  call ay_player_init + 3
  call pageout_module
  ei
  ret

;
; Calls music player.
; Assumes that RAM page 0 is to be paged in to C000-FFFF
; on return.
;
play_music

; Do nothing if we're on a 48k

  ld a, (v_128k_detected)
  cp 0
  ret z

; Don't play if music is currently off

  ld a, (v_audio_options)
  bit 1, a
  ret z

  call pagein_module
  ld hl, ay_player_init + 0x0a
  res 0, (hl)
  call ay_player_play
  call pageout_module
  ret

mute_music

; Do nothing if we're on a 48k

  ld a, (v_128k_detected)
  cp 0
  ret z

  halt
  di
  call pagein_module
  call ay_player_mute
  call pageout_module
  xor a
  ld (v_player_active), a
  ei
  ret

restart_music

; Do nothing if we're on a 48k

  ld a, (v_128k_detected)
  cp 0
  ret z

  halt
  di
  ld a, 1
  ld (v_player_active), a
  ei
  ret

pageout_module

  xor a
  jp page_in_ram

pagein_module

  ld a, (v_module_page)
;
; Paging support
; Pages in the RAM page in the accumulator
; to the C000-FFFF area. All but bits 0x2
; are masked off.
;

page_in_ram

  and 0x7
  push bc
  ld bc, 0x7ffd
  out (c), a
  pop bc
  ret
