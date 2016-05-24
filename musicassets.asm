;
; musicassets.asm
;

  org 0xC000

tune_main_menu

  incbin "tune_mainmenu.bin"

  BLOCK 0xDA00-$, 0x00

tune_ingame

  incbin "tune_ingame.bin"

  BLOCK 0xF600-$, 0x00

tune_gameover

  incbin "tune_gameover.bin"
