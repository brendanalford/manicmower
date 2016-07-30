
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

  defb AT, 22, 24, INK, 6, BRIGHT, 1, "Rover gets a short back and sides!", 0

str_level_begin

  defb AT, 22, 60, INK, 7, "Get ready for lawn "

str_level_index

  defb "X !", 0

str_game_over_damage

  defb AT, 22, 44, INK, 7, "Your mower has gone into", AT, 23, 60, "'self destruct' mode!", 0

str_game_over_fuel

  defb AT, 22, 60, INK, 7, "You've run out of fuel!", 0

str_game_over_time

  defb AT, 22, 60, INK, 5, "You've run out of time!", 0

str_build_timestamp

  defb AT, 0, 0, INK, 7, "Dev version: ", BUILD_TIMESTAMP, 0

; Default keys

default_keys

  defb "QAOPH"
