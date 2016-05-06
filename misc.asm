delay_frames

  halt
  dec bc
  ld a, b
  or c
  jr nz, delay_frames
  ret
