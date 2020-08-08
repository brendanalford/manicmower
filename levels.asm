; This is called when starting a new level.
; Draws the map and status from scratch
; Assumes other procedures are taking care of
; clearing screen, initialising the level, etc

display_level

  ld hl, fixed_charset
  ld (v_charset), hl

  xor a
  ld (v_column), a
  ld a, 3
  ld (v_row), a

  ld ix, level_buffer
  ld bc, LEVEL_BUFFER_LEN

display_level_loop

  ld a, (ix)
  cp GRASS
  call z, display_grass
  cp WALL
  call z, display_wall
  cp FLOWERS
  call z, display_flowers
  cp GNOME
  call z, display_gnome
  cp FUEL
  call z, display_fuel

  ld a, (v_column)
  inc a
  cp 32
  jr nz, display_level_next

  ld a, (v_row)
  inc a
  ld (v_row), a
  xor a

display_level_next

  ld (v_column), a
  inc ix
  dec bc
  ld a, b
  or c
  jr nz, display_level_loop

; Display dogs

  ld ix, v_dogbuffer

display_dog_loop

  ld hl, (ix)
  ld a, h
  or l
  jr z, display_mower

  ld a, 'f'
  call display_a_at_hl
  inc ix
  inc ix
  jr display_dog_loop

display_mower

  ld a, (v_mowerx)
  ld l, a
  ld a, (v_mowery)
  ld h, a
  ld a, 'a'
  call display_a_at_hl

  ld hl, str_status
  call print
  call display_score

  ret

; Displays the character held in A at coordinates
; H, L (H adjusted for game area).
; Assumes attributes are blue ink, green paper

display_a_at_hl

  push af
  push hl
  ld a, l
  ld (v_column), a
  ld a, 3
  add A, h
  ld (v_row), a
  pop hl
  ld a, %00100001
  bit 0, h
  jr z, display_a_at_hl_2
  ld a, %01100001

display_a_at_hl_2

  ld (v_attr),a
  pop af
  call putchar_8
  ret

display_grass

  ld a, ixl
  bit 5, a
  ld a, %00100000 ; green
  jr z, display_grass_2
  ld a, %01100000 ; bright green

display_grass_2

  ld (v_attr), a
  ld a, 'e'
  call putchar_8
  ret

display_wall

  ld a, %00010110
  ld (v_attr), a
  ld a, 'g'
  call putchar_8
  ret

display_flowers

  ld a, %00000010
  ld (v_attr), a
  ld a, ixl
  bit 0, a
  ld a, 'h'
  jr z, display_flowers_1
  ld a, 'i'

display_flowers_1

  call putchar_8
  ret

display_gnome

  ld a, ixl
  bit 5, a
  ld a, %00100001 ; green
  jr z, display_gnome_2
  ld a, %01100001 ; bright green

display_gnome_2

  ld (v_attr), a
  ld a, 'j'
  call putchar_8
  ret

display_fuel

  ld a, ixl
  bit 5, a
  ld a, %00100001 ; green
  jr z, display_fuel_2
  ld a, %01100001 ; bright green

display_fuel_2

  ld (v_attr), a
  ld a, 'l'
  call putchar_8
  ret

; Prepares the level buffer with current level data.
; Level number is taken from sysvar v_level.

prepare_level

  ld bc, 0
  ld a, (v_level)
  sla a
  ld c, a

  ld ix, level_data
  add ix, bc
  ld de, (ix)
  ld ix, de

; Cover entire playfield in grass at first

  ld hl, level_buffer
  ld de, level_buffer + 1
  ld bc, 575
  ld a, GRASS
  ld (hl), a
  ldir

; Do boundary walls

  ld hl, level_buffer
  ld de, level_buffer + 1
  ld bc, 31
  ld a, WALL
  ld (hl), a
  ldir

  ld hl, level_buffer + (32 * 17)
  ld de, level_buffer + (32 * 17) + 1
  ld bc, 31
  ld a, WALL
  ld (hl), a
  ldir

  ld hl, level_buffer + 31
  ld b, 17

prepare_level_side_wall

  ld a, WALL
  ld (hl), a
  inc hl
  ld (hl), a
  ld de, 31
  add hl, de
  djnz prepare_level_side_wall

; Now start doing the flowerbeds

  ld a, FLOWERS
  ld hl, level_buffer + (32 * 1) + 1
  ld de, level_buffer + (32 * 1) + 2
  ld bc, 29
  ld (hl), a
  ldir

  ld hl, level_buffer + (32 * 16) + 1
  ld de, level_buffer + (32 * 16) + 2
  ld bc, 29
  ld (hl), a
  ldir

; Start reading level data (pointed to by IX)

  ld b, 14
  ld hl, level_buffer + (32 * 2) + 1

prepare_flower_loop

  push hl
  ld de, 29
  add hl, de
  ld de, hl
  pop hl
  push hl

  push bc
  ld a, (ix)
  cp 0
  jr z, prepare_flower_next
  ld b, a
  ld a, FLOWERS

prepare_flower_inner_loop

  ld (hl), a
  ex de, hl
  ld (hl), a
  ex de, hl
  dec de
  inc hl
  djnz prepare_flower_inner_loop

prepare_flower_next

  pop bc
  pop hl

  ld de, 32
  add hl, de
  inc ix
  djnz prepare_flower_loop

; IX now points at wall X,Y positions

prepare_interior_walls

  ld hl, (ix)
  inc ix
  inc ix
  ld a, l
  or h
  jr z, prepare_gnomes

  call calc_xy_to_hl
  ex de, hl
  ld hl, level_buffer
  add hl, de

  ld b, 5
  ld a, WALL

prepare_interior_walls_loop

  ld (hl), a
  inc hl
  djnz prepare_interior_walls_loop
  jr prepare_interior_walls

prepare_gnomes

  ld hl, (ix)
  inc ix
  inc ix
  ld a, l
  or h
  jr z, prepare_fuel

  call calc_xy_to_hl
  ex de, hl
  ld hl, level_buffer
  add hl, de
  ld a, GNOME
  ld (hl), a
  jr prepare_gnomes

prepare_fuel

  ld hl, (ix)
  inc ix
  inc ix
  ld a, l
  or h
  jr z, prepare_dogs

  call calc_xy_to_hl
  ex de, hl
  ld hl, level_buffer
  add hl, de
  ld a, FUEL
  ld (hl), a
  jr prepare_fuel

; Dog coordinates don't go in the level buffer - we've got
; a separate area for that.

prepare_dogs

  ld hl, v_dogbuffer

prepare_dog_loop

  ld de, (ix)
  ld (hl), de
  inc ix
  inc ix
  inc hl
  ld a, (hl)
  inc hl
  or (hl)
  jr nz, prepare_dog_loop

; Set mower coordinates to start

  ld a, 15
  ld (v_mowerx), a
  ld a, 8
  ld (v_mowery), a

; Prepare other game vars

  xor a
  ld (v_mower_x_moving), a
  ld (v_mower_y_moving), a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a
  ld (v_hit_solid), a
  ld (v_slow_movement), a

  ld (v_game_end_reason), a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a

  ld (v_dogs_hit), a
  ld (v_gnomes_hit), a
  ld (v_flowers_hit), a

; Set dog movement variables

  ld a, 0xff
  ld (v_dog_moving), a
  xor a
  ld (v_dog_x_moving), a
  ld (v_dog_y_moving), a

  ld de, level_buffer

; No grass at initial mower or dog location(s)

  ld a, (v_mowerx)
  ld l, a
  ld a, (v_mowery)
  ld h, a

  call calc_xy_to_hl
  or a
  add hl, de
  ld (hl), MOWN_GRASS
  ld ix, v_dogbuffer

prepare_dog_patch

  ld hl, (ix)
  ld a, h
  or l
  jr z, prepare_misc
  call calc_xy_to_hl
  ld de, level_buffer
  or a
  add hl, de
  ld (hl), MOWN_GRASS
  inc ix
  inc ix
  jr prepare_dog_patch

prepare_misc

; Set damage / fuel levels

  ld (v_damage), a
  ld (v_dogs_hit), a
  ld (v_gnomes_hit), a
  ld (v_flowers_hit), a

  ld a, 80
  ld (v_fuel), a
  ld a, 'a'
  ld (v_mower_graphic), a

  ld a, '9'
  ld (v_time), a
  ld (v_time + 1), a

  ld a, FUELFRAMES
  ld (v_fuel_frame), a
  ld a, TIME_FRAMES
  ld (v_time_frame), a

  xor a
  ld (v_status_msg), a
  ld (v_status_delay), a
  ld (v_time_expired), a

; Set level start message index

  ld hl, str_level_index
  ld a, (v_level)
  add '1'
  ld (hl), a

  call survey_grass
  call display_score

  ret


; Converts x,y coordinates in HL to a byte
; offset for a screen buffer, returned in HL.

calc_xy_to_hl

  push af
  push de
  push hl
  pop de
  ld a, d
  srl a
  srl a
  srl a
  and 3
  ld h, a
  ld a, d
  sla a
  sla a
  sla a
  sla a
  sla a
  ld l, a
  ld a, e
  add a, l
  ld l, a
  pop de
  pop af
  ret
