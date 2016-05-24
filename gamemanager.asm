;
; Gamemanager.asm
; Routines for level setup, end of game handling etc.
;

gamemanager

  call prepare_game
  call set_game_controls

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
  ld (v_game_end_reason), a
  ld (v_mower_x_dir), a
  ld (v_mower_y_dir), a

  call set_print_main_screen

; Initialises the in game music, which lives in RAM page 1.

  ld hl, AY_GAME_TUNE
  ld a, 1
  call init_music
  call restart_music

  call main_loop
  call fade_out_attrs
  call mute_music

; Was the game aborted

  ld a, (v_game_end_reason)
  cp GAME_ABORTED
  jr z, gamemanager_end

; Game over (handle level complete here TODO)

  ld hl, AY_GAMEOVER_TUNE
  ld a, 1
  call init_music
  call restart_music

  xor a
  ld (v_attr), a
  call cls
  call set_print_shadow_screen
  call cls

  call display_game_over_logo

  ld bc, 0x100

game_over_wait_keypressed

  halt
  call scan_keys
  jr z, gamemanager_end
  dec bc
  ld a, b
  or c
  jr nz, game_over_wait_keypressed

gamemanager_end

  call mute_music
  call fade_out_attrs
  ret

display_game_over_logo

  ld hl, img_game_over_logo
  ld de, 0x800 + (SHADOW_SCREEN_BYTES * 0x100)
  ld bc, 0x800
  ldir

  ld a, %01000010
  ld hl, SHADOW_SCREEN_ATTR * 0x100
  ld de, hl
  inc de
  ld bc, 0x300
  ld (hl), a
  ldir
  call copy_shadow_screen_pixels
  call fade_in_attrs
  ret

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
