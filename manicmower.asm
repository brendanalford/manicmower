;
; Manicmower.asm
;
; Your ass is grass (tm)
;
; Music by Gasman
; Title screen: Oh Crap it's almost the deadline
; Ingame: Ninja Milkman Conspiracy
; Level Complete: Fanfare
; High Score: Decadent Stardust

  LUA ALLPASS

  sj.insert_define("BUILD_TIMESTAMP", '"' .. os.date("%d/%m/%Y %H:%M:%S") .. '"');

  ENDLUA

  org 0x8000
  include "vars.asm"

init

  call init_print
  call init_misc
  call check_startup_keys
  call init_controls
  call init_interrupts

  ld a, (v_128k_detected)
  cp 0
  call z, stop_the_tape

after_init

  call cls
  call set_proportional_font

  call main_menu
  call cls

  call gamemanager
  call check_high_score

  jp after_init

  include "screen.asm"
  include "input.asm"
  include "misc.asm"
  include "gamemanager.asm"
  include "highscore.asm"
  include "maingame.asm"
  include "levels.asm"
  include "mainmenu.asm"

init_interrupts

  di
  ld a, intvec_table / 256
  ld i, a
  im 2

  ld a, 0x18
  ld (0xffff), a

; Set up AY player flag.

  xor a
  ld (v_player_active), a
  ld (v_module_page), a
  ei
  ret

restore_interrupts

  di
  ld a, 0x3F
  ld i, a
  im 0
  ei
  ret

interrupt_routine

  push hl
  push de
  push bc
  push af
  push ix
  push iy
  exx
  push hl
  push de
  push bc
  push af
  exx

  ld a, (v_player_active)
  cp 0
  jr z, interrupt_routine_check_custom_isr

  call play_music

interrupt_routine_check_custom_isr

  ld hl, (v_isr_location)
  ld a, h
  or l
  jr z, interrupt_routine_exit

  push hl
  pop de
  ld hl, interrupt_routine_exit
  push hl
  push de
  pop hl
  jp hl

interrupt_routine_exit

  exx
  pop hl
  pop de
  pop bc
  pop af
  exx
  pop iy
  pop ix
  pop af
  pop bc
  pop de
  pop hl

  ei
  reti

;
; Game text strings
;

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

str_level_begin

  defb AT, 22, 60, INK, 7, "Get ready for lawn "

str_level_index

  defb "X !", 0

str_game_over_damage

  defb AT, 22, 44, INK, 7, "Your mower has gone into", AT, 23, 60, "'self destruct' mode!", 0

str_game_over_fuel

  defb AT, 22, 60, INK, 7, "You've run out of fuel!", 0

str_build_timestamp

  defb AT, 0, 0, INK, 7, "Dev version: ", BUILD_TIMESTAMP, 0

; Default keys

default_keys

  defb "QAOPH"

; Hide turboloader here

  BLOCK 0xB300-$, 0x00

  include "turboloader.asm"

  BLOCK 0xB500-$, 0x00

; Interrupt vector table

intvec_table

  BLOCK 0xB601-$, 0xFF

;
; AY Module
; Player loads to B700
; Tune loads to C000 in relevant RAM page

  BLOCK 0xB700-$, 0x00

ay_player_base

  incbin "player.bin"

; Image and graphic assets

  BLOCK 0xC000-$, 0x00

  include "assets.asm"

  BLOCK 0xEC00-$, 0x00

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

; Level data for each individual screen.
; Data format is as follows:
; 0-13 lengths of flower bed from left and right sides of wall
; 14: Wall X,Y - each wall segment is 5 characters long. 0000 denotes end
; Gnome X,y - position of gmomes. 0000 denotes end
; Fuel x,y - position of fuel. 0000 denotes end
; Dog x,y - initial position of dog(s) in playfield. 0000 denotes end.

level_1_data

  defb 5, 3, 2, 1, 0, 0, 0, 0, 0, 0, 1, 2, 3, 5
  defb 10, 9, 15, 9, 0, 0
  defb 5, 5, 26, 5, 5, 12, 26, 12, 0, 0
  defb 10, 7, 13, 7, 20, 9, 0, 0
  defb 20, 12, 0, 0

level_2_data

  defb 3, 4, 2, 3, 4, 2, 2, 0, 2, 4, 5, 4, 4, 4
  defb 17, 3, 11, 6, 7, 8, 20, 8, 21, 8, 21, 11, 21, 13, 0, 0
  defb 8, 3, 24, 5, 16, 6, 22, 7, 15, 9, 12, 10, 8, 11, 20, 13, 14, 13, 18, 15, 0, 0
  defb 7, 2, 22, 2, 23, 7, 12, 9, 0, 0
  defb 20, 11, 0, 0

level_3_data
level_4_data
level_5_data
level_6_data
level_7_data
level_8_data

  BLOCK 0xEE00-$, 0x00

high_score_names

  defb "1. ", TAB, 20, INK, 5, "\"Flash, Flash!!!\"",0,"              ", 0
  defb "2. ", TAB, 20, INK, 5, "\"What is it, Dale? Can't you",0,"   ", 0
  defb "3. ", TAB, 20, INK, 5, "see I'm eating my bowl",0,"         ", 0
  defb "4. ", TAB, 20, INK, 5, "of Crunchy Nut Corn",0,"            ", 0
  defb "5. ", TAB, 20, INK, 5, "Flakes?\"",0,"                       ", 0
  defb "6. ", TAB, 20, INK, 5, "\"We've only got 15 seconds",0,"     ", 0
  defb "7. ", TAB, 20, INK, 5, "to save the universe!!!\"",0,"       ", 0
  defb "8. ", TAB, 20, INK, 5, "\"All right, all right! I'm",0,"     ", 0
  defb "9. ", TAB, 20, INK, 5, "ready. Now, what's all this",0,"    ", 0
  defb "10.", TAB, 20, INK, 5, "about a....\"",0,"                   ", 0


high_score_table

  defb "025000", 0, 0
  defb "020000", 0, 0
  defb "015000", 0, 0
  defb "010000", 0, 0
  defb "007500", 0, 0
  defb "005000", 0, 0
  defb "004000", 0, 0
  defb "003000", 0, 0
  defb "002000", 0, 0
  defb "001000", 0, 0


  BLOCK 0xF200-$, 0x00

fixed_charset

  incbin "fixedchars.dat"

  BLOCK 0xF500-$, 0x00

proportional_charset

  incbin "proportional.dat"

  BLOCK 0xFFF4-$, 0x00

  jp interrupt_routine

  BLOCK 0xFFFF-$, 0x00

  defb 0x18
