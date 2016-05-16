;
;	vars.asm
;

	define	MOWN_GRASS			0
	define	GRASS						1
	define	WALL						2
	define	FUEL						3
	define 	GNOME 					4
	define	FLOWERS					5
	define 	BROKEN_GNOME		6


	define 	LEVEL_BUFFER_LEN	576
	define	FUEL_FRAMES				30
	define	TIME_FRAMES				120

	define 	ATTR_TRANS				0xff

	define 	STATUS_HIT_WALL			0x1
	define 	STATUS_HIT_GNOME		0x2
	define	STATUS_HIT_FLOWERS	0x3
	define	STATUS_HIT_DOG			0x4
	define  STATUS_GAME_OVER		0xf

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
v_fuel_frame				equ #fe28; 1 - Frames left until fuel is decremented
v_time_frame				equ #fe29; 1 - Frames left until time is decremented
v_dogbuffer					equ #fe30; 16 - space for 8 indivdial dogs. Should be plenty.
v_mowerx						equ #fe40; 1	Mower X coordinate
v_mowery						equ #fe41; 1	Mower Y coordinate
v_mower_x_moving		equ #fe42; 1	Mower X coordinate (pixel) while moving
v_mower_y_moving		equ #fe43; 1	Mower Y coordinate (pixel) while moving
v_mower_move_pixels	equ #fe44; 1	Pixels left to move before new input
v_mower_x_dir				equ #fe45; 1	Mower x direction, 1 - down, 255 - up
v_mower_y_dir				equ #fe46; 1	Mower y direction, 1 - down, 255 - up
v_mower_graphic			equ #fe47; 1	Current mower graphic: a, b, c, d
v_dog_moving				equ #fe48; 1  Dog currently moving, 0 - no, 1 yes
v_dog_x_moving			equ #fe49; 1	Dog X coordinate (pixel) while moving
v_dog_y_moving			equ #fe4a; 1	Dog Y coordinate (pixel) while moving
v_dog_x_dir					equ #fe4b; 1	Dog x direction, 1 - down, 255 - up
v_dog_y_dir					equ #fe4c; 1	Dog y direction, 1 - down, 255 - up
v_damage						equ #fe51; 1	Damage level
v_fuel							equ #fe52; 1	Fuel level
v_hit_solid					equ #fe53; 1	Hit object - ignore keystrokes until key released
v_slow_movement			equ #fe54; 1	0 - normal movement, 1 - slow movement
v_pending_score			equ #fe55; 1	Pending score x 10
v_grass_left				equ #fe56; 1	Grass left to mow? 1 - yes, 0 - no
v_time							equ #fe57; 2	Time left
v_status_msg				equ #fe59; 1	Status message code, 0 - no message 1 - hit wall, 2 - hit gnome, 3 - hit flowers, 4 - hit dog
v_status_delay			equ #fe5a; 1	Delay in frames before erasing status message
v_playerkeys				equ #fe5b; 5	Keys used for controls (UDLRP)
v_playerup					equ #fe5b; 1	Key used for UP
v_playerdown				equ #fe5c; 1	Key used for DOWN
v_playerleft				equ #fe5d; 1	Key used for LEFT
v_playerright				equ #fe5e; 1	Key used for RIGHT
v_playerpause				equ #fe5f; 1	key used for Pause
