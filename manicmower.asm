  org 0x8000

init

  im 0
  call init_print

  call cls
  ld hl, str_wait
  call print

  call set_print_shadow_screen
  call cls

  ld hl, str_text
  call print

  ld hl, proportional_charset
  ld (v_charset), hl
  xor a
  ld (v_width), a

  ld hl, str_text
  call print

  call get_key
  call copy_shadow_screen
  call get_key
  call cls

  xor a
  ld (v_level), a

  call prepare_game

  call prepare_level
  call display_level
  call copy_shadow_screen

  im 1
  ret

  include "print.asm"
  include "input.asm"
  include "vars.asm"

prepare_game

  ld a, '0'
  ld hl, v_score
  ld b, 6

init_score

  ld (hl), a
  inc hl
  djnz init_score
  xor a
  ld (hl), a

;
; Called to display score and high score values.
;

display_score

  xor a
  ld (v_row),a
  ld a, 6 * 8
  ld (v_column), a
  ld a, %01000101
  ld (v_attr), a
  ld a, 8
  ld (v_width), a
  ld hl, v_score
  call print
  ld a, 18 * 8
  ld (v_column), a
  ld hl, high_score_table
  call print
  ret

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
  ld bc, 576

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
  inc hl
  ld a, h
  or l
  jr nz, prepare_dog_loop

; Set mower coordinates to start

  ld a, 15
  ld (v_mowerx), a
  ld a, 8
  ld (v_mowery), a
  xor a
  ld (v_mower_x_moving), a
  ld (v_mower_y_moving), a
  ld (v_mower_direction), a

; Set dog movement variables

  ld a, 0xff
  ld (v_dog_index), a
  ld a, 0
  ld (v_dog_x_moving), a
  ld (v_dog_y_moving), a

; Set damage / fuel levels

  ld (v_damage), a
  ld a, 80
  ld (v_fuel), a

  ret


; Converts x,y coordinates in HL to a byte
; offset for a screen buffer, returned in HL.

calc_xy_to_hl

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
  ret

;
; Game text strings
;

str_text

  defb "Manic Mower\n"
  defb "THE QUICK BROWN FOX JUMPS OVER\nTHE LAZY DOG\n"
  defb "0123456789\na b c d e f g h i j k l\nm n o p q r s t u v w x y z\n",0

str_wait

  defb "PLEASE WAIT...\n", 0

str_status

  defb AT, 0, 0, PAPER, 0, BRIGHT, 1, INK, 4, WIDTH, 8,  "SCORE        HIGH        TIME ", INK, 5, "99DAMAGE           FUEL "
  defb INK, 2, 'kkk', INK, 4, BRIGHT, 0, 'kkkkkkk', 0


; Game playfield is 32 x 18 (576 bytes)

  BLOCK 0xE200-$, 0x00
  BLOCK 0xE400-$, 0x00

; Offset table for level data.
; Each level is to be found at (Level data + (2 * (level - 1)))
level_data

  defw level_1_data
  defw level_2_data
  defw level_3_data
  defw level_4_data
  defw level_5_data
  defw level_6_data
  defw level_7_data
  defw level_8_data
  defw level_9_data
  defw level_10_data

; Level data for each individual screen.
; Data format is as follows:
; 0-13 lengths of flower bed from left and right sides of wall
; 14: Wall X,Y - each wall segment is 5 characters long. 0000 denotes end
; Gnome X,y - position of gmomes. 0000 denotes end
; Fuel x,y - position of fuel. 0000 denotes end
; Dog x,y - initial position of dog(s) in playfield. 0000 denotes end.


  BLOCK 0xE480-$, 0x00

level_1_data

  defb 3, 4, 2, 3, 4, 2, 2, 0, 2, 4, 5, 4, 4, 4
  defb 17, 3, 11, 6, 7, 8, 20, 8, 21, 8, 21, 11, 21, 13, 0, 0
  defb 8, 3, 24, 5, 16, 6, 22, 7, 15, 9, 12, 10, 8, 11, 20, 13, 14, 13, 18, 15, 0, 0
  defb 7, 2, 22, 2, 23, 7, 12, 9, 0, 0
  defb 24, 12, 0, 0

level_2_data
level_3_data
level_4_data
level_5_data
level_6_data
level_7_data
level_8_data
level_9_data
level_10_data

  BLOCK 0xE900-$, 0x00

high_score_names

  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0
  defb "Test                           ", 0

high_score_table

  defb "072500", 0
  defb "072500", 0
  defb "072500", 0
  defb "072500", 0
  defb "072500", 0
  defb "072500", 0
  defb "072500", 0
  defb "072500", 0
  defb "072500", 0
  defb "072500", 0

  BLOCK 0xEB00-$, 0x00

fixed_charset

  incbin "fixedchars.dat"

  BLOCK 0xF000-$, 0x00

proportional_charset

  incbin "proportional.dat"
