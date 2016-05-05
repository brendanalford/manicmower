;
; Game.asm
;
main_loop

  halt
  ld a, 1
  out (0xfe), a

; Scan keyboard

  xor a
  call scan_keys
  jp nc, mower_pre_move

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

check_mower_wall_collision

  ld a, (hl)
  cp WALL
  jr nz, check_fuel_collision

  xor a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a
  jp main_loop_end

check_fuel_collision

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

  halt

mower_move_2

  ld a, 1
  out (0xfe), a
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
  xor a
  out (0xfe), a
  djnz mower_move

main_loop_fuel

; Simulate fuel loss

  ld b, 175
  ld a, (v_fuel)
  add b
  ld (v_column), a
  ld a, 8
  ld (v_row), a
  ld a, ' '
  call putchar_pixel
  ld a, (v_fuel)
  cp 0
  jr z, main_loop_end

  dec a
  ld (v_fuel), a

main_loop_end

  xor a
  out (0xfe), a
  jp main_loop

main_loop_exit

  xor a
  out (0xfe), a

  im 1
  ret

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
