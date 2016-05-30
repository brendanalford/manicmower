;
; musicassets.asm
;

  org 0xC000

tune_main_menu

  incbin "tune_levelcomplete.bin"

  BLOCK 0xC800-$, 0x00

tune_ingame

  incbin "tune_highscore.bin"

  BLOCK 0xF600-$, 0x00
