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
  include "interrupts.asm"
  include "textstrings.asm"

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

  include "highscoredata.asm"

  BLOCK 0xEE00-$, 0x00

  include "leveldata.asm"

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
