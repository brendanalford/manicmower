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

  defb 3, 2, 5, 5, 5, 5, 0, 1, 5, 2, 0, 1, 3, 1
  defb 11, 2, 7, 3, 17, 4, 23, 5, 17, 13, 7, 14, 20, 15, 0, 0
  defb 12, 3, 15, 5, 11, 7, 14, 8, 10, 9, 24, 9, 8, 10, 23, 10, 9, 12, 9, 13, 10, 13, 0, 0
  defb 8, 5, 12, 10, 9, 11, 8, 15, 12, 15, 0, 0
  defb 17, 12, 0, 0

level_4_data

  defb 3, 0, 2, 1, 0, 2, 3, 2, 2, 5, 2, 4, 1, 3
  defb 4, 5, 12, 7, 20, 7, 5, 8, 15, 10, 7, 13, 22, 15, 0, 0
  defb 12, 2, 14, 2, 13, 4, 17, 7, 19, 8, 21, 9, 23, 9, 15, 11, 16, 11, 23, 11
  defb 14, 12, 19, 12, 22, 12, 14, 13, 24, 14, 8, 15, 11, 15, 0, 0
  defb 15, 3, 20, 9, 8, 10, 13, 11, 16, 14, 0, 0
  defb 23, 5, 20, 8, 0,0

level_5_data

  defb 3, 4, 5, 3, 1, 5, 1, 3, 0, 3, 4, 1, 0, 0
  defb 7, 7, 6, 8, 11, 9, 11, 12, 13, 13, 15, 14, 0, 0
  defb 9, 2, 13, 2, 18, 2, 19, 2, 20, 3, 8, 4, 18, 4, 21, 4, 10, 5, 14, 5, 16, 6, 19, 6
  defb 19, 8, 16, 9, 11, 10, 16, 10, 18, 10, 9, 11, 18, 13, 21, 14, 8, 15, 18, 15, 22, 15, 23, 15, 0, 0
  defb 14, 3, 16, 7, 14, 10, 15, 11, 0, 0
  defb 18, 6, 22, 9, 7, 13, 0, 0

level_6_data
level_7_data
level_8_data
