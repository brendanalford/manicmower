;
; Manicmower.asm
;
; Your ass is grass (tm)
;

  org 0x8000

init

  im 0
  call init_print

  call cls
  call set_proportional_font

  ld hl, str_wait
  call print

  call set_fixed_font

  ld hl, fixed_charset
  ld (v_charset), hl

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

  call cls

  xor a
  ld (v_level), a

  call prepare_game

  call prepare_level
  call display_level
  call get_key

  call set_print_main_screen
  xor a
  ld (v_attr), a
  call cls

  call copy_shadow_screen_pixels
  call fade_in_shadow_screen_attrs

  ld a, 40
  ld (v_mowerx), a
  ld (v_mowery), a

main_loop

  ld a, 1
  out (0xfe), a
  ld a, (v_mowerx)
  ld (v_column), a
  ld a, (v_mowery)
  ld (v_row), a

  ld a, ' '
  call putchar_pixel
  ld a, (v_mowerx)
  inc a
  ld (v_mowerx), a
  ld (v_column), a
  ld a, 'd'
  call putchar_pixel

; Simulate fuel loss

  ld a, (v_mowerx)
  and 0x0f
  cp 0
  jr nz, main_next

  ld b, 175
  ld a, (v_fuel)
  add b
  ld (v_column), a
  ld a, 8
  ld (v_row), a
  ld a, ' '
  call putchar_pixel
  ld a, (v_fuel)
  dec a
  ld (v_fuel), a

main_next

  xor a
  out (0xfe), a

  halt

  ld a, (v_mowerx)
  cp 240
  jr nz, main_loop

  im 1
  ret


  include "vars.asm"
  include "screen.asm"
  include "input.asm"
  include "levels.asm"

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


;
; Game text strings
;

str_text

  defb "Manic Mower\n"
  defb "THE QUICK BROWN FOX JUMPS OVER\nTHE LAZY DOG\n"
  defb "0123456789\na b c d e f g h i j k l\nm n o p q r s t u v w x y z\n",0

str_wait

  defb "Press any key to commence demo...\n", 0

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
