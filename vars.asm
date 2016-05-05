;
;	vars.asm
;

	define	MOWN_GRASS			0
	define	GRASS						1
	define	WALL						2
	define	FUEL						3
	define 	GNOME 					4
	define	FLOWERS					5


; Workspace areas

pixel_row_buffer		equ #f800; 200
level_buffer				equ #fa00; 300


;	Printing system variables

v_column						equ #fe00; 1
v_row								equ #fe01; 1
v_attr							equ #fe02; 1
v_pr_ops						equ #fe03; 1	bit 0: bold on/off, bit 1: inverse on/off
v_width							equ #fe04; 1
v_charset						equ #fe07; 2	Base location of character set - must be page aligned
v_fadeattr					equ #fe08; 3	Temporary storage for attribute being faded
v_screen_bitmap			equ #fe09; 1  Page index of target drawing bitmap in ram
v_screen_attr				equ #fe0a; 1	Page index of target drawing attributes in ram

; Input variables

v_keybuffer					equ #fe10; 8  Keyboard scanning map

; Game variables

v_level							equ #fe1f
v_score							equ #fe20
v_hiscore						equ #fe28
v_dogbuffer					equ #fe30; 16 - space for 8 indivdial dogs. Should be plenty.
v_mowerx						equ #fe40; 1	Mower X coordinate
v_mowery						equ #fe41; 1	Mower Y coordinate
v_mower_x_moving		equ #fe42; 1	Mower X coordinate (pixel) while moving
v_mower_y_moving		equ #fe43; 1	Mower Y coordinate (pixel) while moving
v_mower_move_pixels	equ #fe44; 1	Pixels left to move before new input
v_mower_x_dir				equ #fe45; 1	Mower x direction, 1 - down, 255 - up
v_mower_y_dir				equ #fe46; 1	Mower y direction, 1 - down, 255 - up
v_mower_graphic			equ #fe47; 1	Current mower graphic: a, b, c, d
v_dog_index					equ #fe48; 1  Index of dog currently moving, FF if not
v_dog_x_moving			equ #fe49; 1	Dog X coordinate (pixel) while moving
v_dog_y_moving			equ #fe50; 1	Dog Y coordinate (pixel) while moving
v_damage						equ #fe51; 1	Damage level
v_fuel							equ #fe52; 1	Fuel level
