  org 0x8000

init

  xor a
  ld (v_column), a
  ld (v_row), a
  ld (v_pr_ops), a
  ld a, 8
  ld (v_width), a
  ld a, 7
  ld (v_attr), a
  ld hl, fixed_charset
  ld (v_charset), hl

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

  call prepare_level
  call display_level
  ret

  include "print.asm"
  include "input.asm"
  include "vars.asm"

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

  ld a, %01000010
  ld (v_attr), a
  ld a, ixl
  bit 0, a
  ld a, 'h'
  jr z, display_flowers_1
  ld a, 'i'

display_flowers_1

  call putchar_8
  ret


prepare_level

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

  ret

; Game playfield is 32 x 18 (576 bytes)


  BLOCK 0xE000-$, 0xff

level_buffer

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

level_1_data

  defb 3, 4, 2, 3, 4, 2, 2, 0, 2, 4, 5, 4, 4, 4
  defb 17, 3, 11, 6, 7, 8, 20, 8, 21, 8, 21, 10, 21, 12, 0, 0
  defb 8, 4, 24, 6, 16, 6, 22, 8, 15, 9, 12, 10, 8, 11, 20, 12, 14, 13, 17, 14, 0, 0
  defb 7, 2, 22, 2, 23, 7, 12, 9, 0, 0

level_2_data
level_3_data
level_4_data
level_5_data
level_6_data
level_7_data
level_8_data
level_9_data
level_10_data


str_text

  defb "Manic Mower\n"
  defb "THE QUICK BROWN FOX JUMPS OVER\nTHE LAZY DOG\n"
  defb "0123456789\na b c d e f g h i j k\n",0


  BLOCK 0xEB00-$, 0xff

fixed_charset

  incbin "fixedchars.dat"

  BLOCK 0xF000-$, 0xff

proportional_charset

  incbin "proportional.dat"
