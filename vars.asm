;
;	vars.asm
;

	define	MOWN_GRASS			0
	define	GRASS						1
	define	WALL						2
	define	FUEL						3
	define 	GNOME 					4
	define	FLOWERS					5
;
;	System Variable locations in lower ram
;

;	Printing system variables

v_column						equ #fe00; 1
v_row								equ #fe01; 1
v_attr							equ #fe02; 1
v_pr_ops						equ #fe03; 1	bit 0: bold on/off, bit 1: inverse on/off
v_width							equ #fe04; 1
v_scroll						equ #fe05; 1
v_scroll_lines  		equ #fe06; 1
v_charset						equ #fe07; 2	Base location of character set - must be page aligned

; Input variables
v_keybuffer					equ #fe09; 8  Keyboard scanning map

; Game variables
v_level							equ #fe1f
v_score							equ #fe20
v_hiscore						equ #fe28
