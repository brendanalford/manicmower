;
; Manicmower.asm
;
; Your ass is grass (tm)
;

  org 0x8000
  include "vars.asm"

init

  call init_print

  ld hl, default_keys
  ld de, v_playerkeys
  ld bc, 5
  ldir

  call cls

  call set_proportional_font

  call main_menu
  call cls

  xor a
  ld (v_level), a

  call set_print_shadow_screen
  call cls
  
  call prepare_game
  call prepare_level
  call display_level

  call set_print_main_screen
  xor a
  ld (v_attr), a
  call cls

  call copy_shadow_screen_pixels
  call fade_in_shadow_screen_attrs

  xor a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a

  call set_print_main_screen

  call main_loop
  call fade_out_attrs

  call restore_basic_registers

  ret

  include "game.asm"
  include "screen.asm"
  include "input.asm"
  include "levels.asm"
  include "misc.asm"
  include "mainmenu.asm"

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
  ld (v_pending_score), a
  ret

;
; Restores registers for a return to BASIC.
;

restore_basic_registers

  ld iy, 0x5c3a
  exx
  ld hl, 0x2758
  exx
  ret
;
; Game text strings
;

str_text

  defb "Manic Mower\n"
  defb "THE QUICK BROWN FOX JUMPS OVER\nTHE LAZY DOG\n"
  defb "0123456789\na b c d e f g h i j k l\nm n o p q r s t u v w x y z\n",0

str_wait

  defb AT, 23, 0,  "Press any key to commence demo...\n", 0

str_status

  defb AT, 0, 0, PAPER, 0, BRIGHT, 1, INK, 4, WIDTH, 8,  "SCORE        HIGH        TIME ", INK, 5, "99DAMAGE ", INK, 4, "    ", INK, 6, "   ", INK, 2, "  ", INK, 5, " FUEL "
  defb INK, 2, 'kkk', INK, 4, 'kkkkkkk', 0

str_fuel_bar

  defb AT, 1, 22 * 8, BRIGHT, 1, INK, 2, "kkk", INK, 4, "kkkkkkk", 0

str_hit_wall

  defb AT, 22, 20, INK, 6, "Your mower needs 'mower' repairs...", 0

str_hit_gnome

  defb AT, 22, 50, INK, 5, "You have broken a gnome!", 0

str_hit_flowers

  defb AT, 22, 8, INK, 7, "I suppose it's better than pruning them...", 0

str_hit_dog

  defb AT, 22, 24, INK, 2, BRIGHT, 1, "Rover gets a short back and sides!", 0

str_game_over_damage

  defb AT, 22, 44, INK, 7, "Your mower has gone into", AT, 23, 60, "'self destruct' mode!", 0

str_game_over_fuel

  defb AT, 22, 60, INK, 7, "You've run out of fuel!", 0

; Image and graphic assets

  include "assets.asm"

; Default keys

default_keys

  defb "QAOPH"

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
  defb 20, 11, 0, 0

  ; dog was at 20, 11

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
