;
;	screen.asm
;

;	Routines for printing proportional strings to the screen.
;	Control codes AT, PAPER, INK, BRIGHT
;	and INVERSE are handled as you'd expect.
;	HL holds the location of the string to print

;	Defines for in-string control codes

	define LEFT		8
	;define	RIGHT		9
	;define	DOWN		10
	;define	UP		11
	define	CR		13
	define	TAB		14
	define	ATTR		15
	define	INK		16
	define	PAPER		17
	define	FLASH		18
	define	BRIGHT		19
	define	INVERSE		20
	define	TEXTBOLD	21
	define  TEXTNORM	22
	define	AT		23
	define	WIDTH		24

;
;	Initialises the printing routines
;
init_print

	xor a
	ld (v_column), a
	ld (v_row), a
	ld (v_pr_ops), a
	ld a, 8
	ld (v_width), a
	dec a
	ld (v_attr), a
	ld hl, fixed_charset
	ld (v_charset), hl

;	Initialise the pixel row lookup buffer

	xor a
	ld b, a
	ld c, a
	ld ix, pixel_row_buffer

pixel_row_buffer_init

	ld a, c
	and 0x7
	ld h, a
	ld a, c
	rra
	rra
	rra
	and 0x18
	or h
	or 0x40
	ld h, a

	ld a, b
	rra
	rra
	rra
	and 0x1f
	ld l, a
	ld a, c
	rla
	rla
	and 0xe0
	or l
	ld l, a

	ld (ix), hl
	inc ix
	inc ix
	inc c
	ld a, c
	cp 192
	jr nz, pixel_row_buffer_init


;	Fall through to initialising the main/shadow screen setup

init_print_screen

	ld hl, v_screen_bitmap
	ld a, MAIN_SCREEN_BYTES
	ld (hl), a
	inc hl
	ld a, MAIN_SCREEN_ATTR
	ld (hl), a
	ret

;
;	Sets the fixed character set (with game graphics)
; as the default for printing
;
set_fixed_font

	ld hl, fixed_charset
	ld (v_charset), hl
	ld a, 8
	ld (v_width), a
	ret

;
;	Sets the proportional font as the default for printing
;
set_proportional_font

	ld hl, proportional_charset
	ld (v_charset), hl
	xor a
	ld (v_width), a
	ret

;
;	Set the main screen as the target drawing screen
;
set_print_main_screen

	jr init_print_screen

;
;	Set the shadow screen as the target drawing screen
;
set_print_shadow_screen

	ld hl, v_screen_bitmap
	ld a, SHADOW_SCREEN_BYTES
	ld (hl), a
	inc hl
	ld a, SHADOW_SCREEN_ATTR
	ld (hl), a
	ret

;
;	Copies the shadow screen to main screen
;
copy_shadow_screen

	ld hl, SHADOW_SCREEN_BYTES * 0x100
	ld de, MAIN_SCREEN_BYTES * 0x100
	ld bc, 0x1aff
	ldir
	ret

copy_shadow_screen_pixels

	ld hl, SHADOW_SCREEN_BYTES * 0x100
	ld de, MAIN_SCREEN_BYTES * 0x100
	ld bc, 0x17ff
	ldir
	ret

;
;	Fades in attributes from shadow screen
;

fade_in_shadow_screen_attrs

	ld hl, SHADOW_SCREEN_ATTR * 0x100
	ld de, MAIN_SCREEN_ATTR * 0x100
	ld bc, 0x300

;	Check if the fade is complete

fade_in_attrs_check

	ld a, (de)
	cp (hl)
	jr nz, fade_in_attrs

	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, fade_in_attrs_check

; All attrs in main screen equal to shadow, we're done

	ret

fade_in_attrs

	ld hl, SHADOW_SCREEN_ATTR * 0x100
	ld de, MAIN_SCREEN_ATTR * 0x100
	ld bc, 0x300

fade_in_attrs_loop

	push bc
	xor a
	ld c, a

; Consider ink first.

	ld a, (de)
	and 0x7
	ld b, a
	ld a, (hl)
	and 0x7
	cp b
	jr z, fade_in_attrs_paper

	ld a, b
	inc a
	and 0x7

fade_in_attrs_paper

	or c
	ld c, a

	; Now consider paper colour

	ld a, (de)
	sra a
	sra a
	sra a
	and 0x07
	ld b, a
	ld a, (hl)
	sra a
	sra a
	sra a
	and 0x07
	cp b
	jr z, fade_in_bright_flash

	ld a, b
	inc a

fade_in_bright_flash

	sla a
	sla a
	sla a
	and 0x38
	or c
	ld c, a

;	Set bright/flash attributes explicitly.

	ld a, (hl)
	and 0xc0
	or c

;	Store the new attribute and loop

	ex de, hl
	ld (hl), a
	ex de, hl

	pop bc
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, fade_in_attrs_loop

;	Wait for vsync, and loop until everything's faded in

	halt
	jr fade_in_shadow_screen_attrs

;
;	Fades out screen by reducing the ink/paper values until everything's black
;
fade_out_attrs

	ld hl, MAIN_SCREEN_ATTR * 0x100
	ld bc, 0x300

;	Check if the fade is complete

fade_out_attrs_check

	ld a, (hl)
	cp 0
	jr nz, fade_out_attrs_main

	inc hl

	dec bc
	ld a, b
	or c
	jr nz, fade_out_attrs_check

; All attrs in main screen are black, we're done

	ret

fade_out_attrs_main

	ld hl, MAIN_SCREEN_ATTR * 0x100
	ld bc, 0x300

fade_out_attrs_main_1

	ld a, (hl)
	ld d, a

	and 0x38
	ld e, a

	ld a, d
	and 0x7
	cp 0
	jr z, fade_out_attrs_paper

	dec a

fade_out_attrs_paper

	or e
	ld d, a

	and 0x07
	ld e, a
	ld a, d
	and 0x38
	sra a
	sra a
	sra a

	cp 0
	jr z, fade_out_attrs_done

	dec a

fade_out_attrs_done

	sla a
	sla a
	sla a

	or e
	ld (hl), a
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, fade_out_attrs_main_1


	jr fade_out_attrs

;
;	Prints a string to the screen.
;	Inputs: HL=location of string to be printed
;

print

;	Save all registers that are used by this routine

	push hl
	push de
	push bc
	push af

;	Once we have the current char value, HL always points to the next value to be read.

print_nextchar

	ld a, (hl)
	inc hl

;	Check for end of printable string, zero terminated

	cp 0
	jp z, print_done

;	Jump straight to character printing if obviously not
;	a control character

	cp 31
	jp nc, print_char

;	Check for carriage return

	cp '\n'
	jr nz, print_chk_left
	call newline
	jr print_nextchar

;	Check for Cursor Left control code

print_chk_left

	cp LEFT
	jr nz, print_chk_attr
	ld a, (v_width)
	ld b, a
	ld a, (v_column)
	sub b
	ld (v_column), a
	cp 0xff
	jr nz, print_nextchar
	ld a, 31
	ld (v_column), a
	ld a, (v_row)
	dec a
	ld (v_row), a
	cp 0xff
	jr nz, print_nextchar
	ld a, 23
	ld (v_row), a
	jr print_nextchar

;	Check for ATTR control code

print_chk_attr

	cp ATTR
	jp nz, print_chk_ink
	ld a, (hl)
	inc hl
	ld (v_attr), a
	jr print_nextchar

;	Check for INK control code

print_chk_ink

	cp INK
	jr nz, print_chk_tab
	ld a, (hl)
	inc hl
	and 7
	ld d, a
	ld a, (v_attr)
	and 0xf8
	or d
	ld (v_attr), a
	jr print_nextchar

;	Check for TAB control code

print_chk_tab

	cp TAB
	jr nz, print_chk_paper
	ld a, (hl)
	inc hl
	ld (v_column), a
	jr print_nextchar

;	Check for PAPER control code

print_chk_paper

	cp PAPER
	jr nz, print_chk_cr
	ld a, (hl)
	inc hl
	and 7
	rla
	rla
	rla
	ld d, a
	ld a, (v_attr)
	and 0xc7
	or d
	ld (v_attr), a
	jp print_nextchar

;	Check for carriage return (CR)s control code

print_chk_cr

	cp CR
	jr nz, print_chk_bright
	ld a, 0
	ld (v_column), a
	jp print_nextchar

;	Check for BRIGHT control code

print_chk_bright

	cp BRIGHT
	jr nz, print_chk_flash
	ld a, (hl)
	inc hl
	cp 0
	jr z, print_chk_bright_2
	ld a, 64

print_chk_bright_2

	ld d, a
	ld a, (v_attr)
	and 0xbf
	or d
	ld (v_attr), a
	jp print_nextchar

;	Check for FLASH control code

print_chk_flash

	cp FLASH
	jr nz, print_chk_at
	ld a, (hl)
	inc hl
	cp 0
	jr z, print_chk_flash_2
	ld a, 128

print_chk_flash_2

	ld d, a
	ld a, (v_attr)
	and 0x7f
	or d
	ld (v_attr), a
	jp print_chk_bold

;	Check for AT control code

print_chk_at

	cp AT
	jr nz, print_chk_bold
	ld a, (hl)
	inc hl
	cp 24
	jr c, print_chk_at_2
	ld a, 0

print_chk_at_2

	ld (v_row), a
	ld a, (hl)
	inc hl
	cp 249
	jr c, print_chk_at_3
	ld a, 0

print_chk_at_3

	ld (v_column), a
	jp print_nextchar

;	Check for BOLD control code

print_chk_bold

	cp TEXTBOLD
	jr nz, print_chk_norm
	ld a, (v_pr_ops)
	set 0, a
	ld (v_pr_ops), a
	jp print_nextchar

;	Check for NORM (restores normal text) control code

print_chk_norm

	cp TEXTNORM
	jr nz, print_chk_inverse
	ld a, (v_pr_ops)
	res 0, a
	ld (v_pr_ops), a
	jp print_nextchar

print_chk_inverse

	cp INVERSE
	jr nz, print_chk_width
	ld a, (hl)
	inc hl
	cp 0
	jr z, print_chk_inverse_on
	ld a, (v_pr_ops)
	set 1, a
	ld (v_pr_ops), a
	jp print_nextchar

print_chk_inverse_on

	ld a, (v_pr_ops)
	res 1, a
	ld (v_pr_ops), a

	jp print_nextchar

print_chk_width

	cp WIDTH
	jr nz, print_char
	ld a, (hl)
	inc hl
	ld (v_width), a
	jp print_nextchar

;	Print a single character to screen

print_char

	ld b, a

	call putchar

;	Update the print position, wrapping around
;	to screen start if necessary

	ld a, (v_width)

	cp 0
	jr z, do_proportional

	ld b, a
	ld a, (v_column)
	add b

	jr print_wrap

do_proportional

	push hl
	ld hl, proportional_data
	ld e, b
	ld d, 0
	add hl, de
	ld b, (hl)
	pop hl
	ld a, (v_column)
	add b

print_wrap

	ld (v_column), a
	cp 0
	jp nz, print_nextchar
	ld a, 0
	ld (v_column), a
	ld a, (v_row)
	inc a
	ld (v_row), a

;	Wrap text from bottom to top
	cp 24
	jp nz, print_nextchar
	ld a, 0
	ld (v_row), a
	jp print_nextchar

;	Return without printing the rest if we overflowed the bottom
;	of the screen.

print_done

;	Done, restore registers before returning

	pop af
	pop bc
	pop de
	pop hl
	ret

;
;	Puts a single character on screen.
;	Inputs: A=character to print, HL=y,x coordinates to print at.
;	This routine drops directly into the putchar routine.
;

putchar_at

	push af
	ld a, h
	ld (v_row), a
	ld a, l
	ld (v_column), a
	pop af

;
;	Puts a single character on screen at the location in the
;	v_col and v_row variables, with v_attr colours.
;	Inputs: A=character to print.
;

putchar

	push hl
	push bc
	push de
	push ix

; Get the charset location

	ld hl, (v_charset)
	ld bc, hl

;	Find the address of the character in the bitmap table

	sub 32      ; space = offset 0
	ld hl, 0
	ld l, a

;	Multiply by 8 to get the byte offset

	add hl, hl
	add hl, hl
	add hl, hl

;	Add the charset offset

	add hl, bc

;	Store result in de for later use

	ex de, hl

;	Now find the address in the frame buffer to be written.
;	Take main/shadow screen into account

	ld a, (v_screen_bitmap)
	ld b, a
	ld a, (v_row)
	and 0x18
	add b
	ld h, a
	ld a, (v_row)
	and 0x7
	rla
	rla
	rla
	rla
	rla
	ld l, a
	ld a, (v_column)
	and 0x7
	ld ixl, a
	ld a, (v_column)
	srl a
	srl a
	srl a
	add a, l
	ld l, a

;	DE contains the address of the char bitmap
;	HL contains address in the frame buffer

;	Calculate mask for printing partial characters

	push hl
	push de

;	Offset goes in IXL for the duration

	ld a, ixl
	ld hl, mask_bits
	ld e, a
	xor a
	ld d, a
	add hl, de
	ld a, (hl)

;	Mask value goes in IXH

	ld ixh, a
	pop de
	pop hl

	ld b, 8

.putchar.loop

;	Move character bitmap into the frame buffer

	ld a, (de)
	push de

;	Store bitmap row in d, and mask in e for the duration

	ld d, a
	ld e, ixh

;	Do we need to print the character in bold?

	ld a, (v_pr_ops)
	bit 0, a
	jr z, .putchar.afterbold

;	Bold character, grab byte, rotate it right then
;	OR it with the original value

	ld a, d
	ld c, a
	rl c
	ld a, d
	or c
	ld d, a

.putchar.afterbold

	ld a, (v_pr_ops)
	bit 1, a
	jr z, .putchar.afterinverse

	ld a, d
	xor 0xff
	ld d, a

.putchar.afterinverse

	push bc

;	Apply mask to first byte

	ld a, e
	ld b, (hl)
	and b
	ld (hl), a

	ld a, ixl
	cp 0
	jr z, .putchar.norot
	ld b, a
	ld a, d

.putchar.rot1

	srl a
	djnz .putchar.rot1
	jr .putchar.byte1

.putchar.norot

	ld a, d

.putchar.byte1

	ld b, (hl)
	or b
	ld (hl), a
	pop bc

;	Check if we need to do second byte

	ld a, ixl
	cp 0
	jr z, .putchar.nextbmpline
	inc hl

	push bc

;	Apply mask to second byte

	ld a, e
	cpl
	ld b, (hl)
	and b
	ld (hl), a

	ld a, ixl
	ld b, a
	ld a, 8
	sub b
	ld b, a

	ld a, d

.putchar.rot2

	sla a
	djnz .putchar.rot2

	ld b, (hl)
	or b
	ld (hl), a

	pop bc
	dec hl

.putchar.nextbmpline

	pop de
	inc de            ; next line of bitmap
	inc h             ; next line of frame buffer

.putchar.next

	djnz .putchar.loop

.putchar.attr

;	Now calculate attribute address

	ld a, (v_screen_attr)
	ld b, a
	ld a, (v_attr)
	cp ATTR_TRANS
	jr z, .putchar.end

	ld a, (v_row)
	srl a
	srl a
	srl a
	and 3
	add b
	ld h, a
	ld a, (v_row)
	sla a
	sla a
	sla a
	sla a
	sla a
	ld l, a
	ld a, (v_column)
	srl a
	srl a
	srl a
	add a, l
	ld l, a

;	Write the current colour values in the v_attr
;	sysvar to the just printed character

	ld a, (v_attr)
	ld (hl), a

	ld a, ixl
	cp 0
	jr z, .putchar.end

;	Do adjacent character if it straddles two characters

	ld a, (v_attr)
	inc hl
	ld (hl), a

;	Done, restore registers and return

.putchar.end
	pop ix
	pop de
	pop bc
	pop hl
	ret




	;
	;	Puts a single character on screen at the location in the
	;	v_col and v_row variables, with v_attr colours. Works only with
	; standard 8-pixel font spacing in a 32x24 grid spacing.
	;	Inputs: A=character to print.
	;

putchar_8

	push hl
	push bc
	push de
	push ix

; Get the charset location

	ld hl, (v_charset)
	ld bc, hl

;	Find the address of the character in the bitmap table

	sub 32      ; space = offset 0
	ld hl, 0
	ld l, a

;	Multiply by 8 to get the byte offset

	add hl, hl
	add hl, hl
	add hl, hl

;	Add the charset offset

	add hl, bc

;	Store result in de for later use

	ex de, hl

;	Now find the address in the frame buffer to be written.

	ld a, (v_screen_bitmap)
	ld b, a
	ld a, (v_row)
	and 0x18
	add b
	ld h, a
	ld a, (v_row)
	and 0x7
	rla
	rla
	rla
	rla
	rla
	ld l, a
	ld a, (v_column)
	and 0x7
	ld ixl, a
	ld a, (v_column)
	add a, l
	ld l, a

;	DE contains the address of the char bitmap
;	HL contains address in the frame buffer

	ld b, 8

.putchar_8.loop

;	Move character bitmap into the frame buffer

	ld a, (de)
	ld (hl), a
	inc h
	inc de

.putchar_8.next

	djnz .putchar_8.loop

.putchar_8.attr

;	Now calculate attribute address

	ld a, (v_screen_attr)
	ld b, a
	ld a, (v_row)
	srl a
	srl a
	srl a
	and 3
	add b
	ld h, a
	ld a, (v_row)
	sla a
	sla a
	sla a
	sla a
	sla a
	ld l, a
	ld a, (v_column)
	add a, l
	ld l, a

;	Write the current colour values in the v_attr
;	sysvar to the just printed character
;	Ignore if transparent attributes are selected

	ld a, (v_attr)
	cp ATTR_TRANS
	jr z, .putchar_8.end
	ld (hl), a

.putchar_8.end

	pop ix
	pop de
	pop bc
	pop hl
	ret


;
;	Puts a single character on screen at the location in the
;	v_col and v_row variables, with pixel accuracy. attributes
; are ignored and treated as transparent.
; Always draws to main screen - shadow screen not supported.
;	Inputs: A=character to print.
;

putchar_pixel

	push hl
	push bc
	push de
	push ix

; Get the charset location

	ld hl, (v_charset)
	ld bc, hl

;	Find the address of the character in the bitmap table

	sub 32      ; space = offset 0
	ld hl, 0
	ld l, a

;	Multiply by 8 to get the byte offset

	add hl, hl
	add hl, hl
	add hl, hl

;	Add the charset offset

	add hl, bc

;	Store result in de for later use

	ex de, hl

;	DE contains the address of the char bitmap
;	Calculate mask for printing partial characters

	push de
	ld a, (v_column)
	and 0x7
	ld ixl, a

;	Offset goes in IXL for the duration

	ld hl, mask_bits
	ld e, a
	xor a
	ld d, a
	add hl, de
	ld a, (hl)

;	Mask value goes in IXH

	ld ixh, a
	pop de

	ld b, 8

.putchar_pixel.loop

; Calculate HL address of row/column

	push de
	push ix

	ld ix, pixel_row_buffer
	xor a
	ld d, a
	ld a, (v_row)
	ld e, a
	sla e
	bit 7, a
	jr z, .putchar_pixel.loop_2

	set 0, d

.putchar_pixel.loop_2

	and a				; Clear carry flag
	add ix, de
	ld hl, (ix)

; Now row position is in HL, add in column

	ld a, (v_column)
	srl a
	srl a
	srl a
	or l
	ld l, a

	pop ix
	pop de

;	Move character bitmap into the frame buffer

	ld a, (de)
	push de

;	Store bitmap row in d, and mask in e for the duration

	ld d, a
	ld e, ixh

	push bc

;	Apply mask to first byte

	ld a, e
	ld b, (hl)
	and b
	ld (hl), a

	ld a, ixl
	cp 0
	jr z, .putchar_pixel.norot
	ld b, a
	ld a, d

.putchar_pixel.rot1

	srl a
	djnz .putchar_pixel.rot1
	jr .putchar_pixel.byte1

.putchar_pixel.norot

	ld a, d

.putchar_pixel.byte1

	ld b, (hl)
	or b
	ld (hl), a
	pop bc

;	Check if we need to do second byte

	ld a, ixl
	cp 0
	jr z, .putchar_pixel.nextbmpline
	inc hl

	push bc

;	Apply mask to second byte

	ld a, e
	cpl
	ld b, (hl)
	and b
	ld (hl), a

	ld a, ixl
	ld b, a
	ld a, 8
	sub b
	ld b, a

	ld a, d

.putchar_pixel.rot2

	sla a
	djnz .putchar_pixel.rot2

	ld b, (hl)
	or b
	ld (hl), a

	pop bc
	dec hl

.putchar_pixel.nextbmpline

	pop de
	inc de            ; next line of bitmap

.putchar_pixel.next

	ld a, (v_row)
	inc a
	ld (v_row), a

	djnz .putchar_pixel.loop

	ld b, 8
	sub b
	ld (v_row), a

;	Done, restore registers and return

.putchar_pixel.end
	pop ix
	pop de
	pop bc
	pop hl
	ret

;
;	Sets the current print position.
;	Inputs: HL=desired print position y,x.
;

set_print_pos

	ld a, h
	ld (v_row), a
	ld a, l
	ld (v_column), a
	ret

;
;	Prints a 16-bit hex number to the buffer pointed to by DE.
;	Inputs: HL=number to print.
;

Num2Hex

	ld	a,h
	call	Num1
	ld	a,h
	call	Num2

;	Call here for a single byte conversion to hex

Byte2Hex

	ld	a,l
	call	Num1
	ld	a,l
	jr	Num2

Num1

	rra
	rra
	rra
	rra

Num2

	or	0xF0
	daa
	add	a,#A0
	adc	a,#40

	ld	(de),a
	inc	de
	ret

;
;	Prints a 16-bit decimal number to the buffer pointed to by DE.
;	Inputs: HL=number to print.
;
Num2Dec

	ld	bc, -10000
	call	Num1D
	ld	bc, -1000
	call	Num1D
	ld	bc, -100
	call	Num1D
	ld	c, -10
	call	Num1D
	ld	c, b

Num1D

	ld	a, '0'-1

Num2D

	inc	a
	add	hl,bc
	jr	c, Num2D
	sbc	hl,bc

	ld	(de),a
	inc	de
	ret

;
;	Prints a 16-bit decimal number to the buffer pointed to by DE,
; with no trailing zeroes.
; Inputs: HL=number to print
;
Num2Dec_NoTrail

	push de
	call Num2Dec
	pop de

;	Assume return is of the form 00000, terminate in buffer with 0x00

	ld ix, de
	xor a
	ld (ix+5), a

; Start truncating zeroes

Num2Dec_Truncate

; Check if what follows this digit is a null terminator. If so,
; we're on the last digit and shouldn't truncate further.

	ld a, (ix+1)
	cp 0
	jr z, Num2Dec_End

;	Check if the current character is an ASCII zero

	ld a, (ix)
	cp '0'
	jr nz, Num2Dec_End

; Leading zero, truncate

	ld hl, ix
	ld de, hl
	inc hl
	ld bc, 5
	ldir
	jr Num2Dec_Truncate

Num2Dec_End

	ret

;
;	Checks to see if printing a string will overwrite the end of the line;
;	if so, it will advance the print position to the start of the next line.
;	Inputs: A=length of string to be printed in pixels.
;

check_end_of_line

	push bc
	ld b, a
	ld a, (v_column)
	add b
	pop bc
	ret nc
	xor a
	ld (v_column), a
	ld a, (v_row)
	inc a
	ld (v_row), a
	cp 24
	ret nz
	xor a
	ld (v_row), a
	ret

;
;	Clear the screen.
;

cls

	push hl
	push de
	push bc
	push af

;	Clear the bitmap locations

	ld a, (v_screen_bitmap)
	ld h, a
	xor a
	ld l, a
	ld (hl), a
	push hl
	pop de
	inc de
	ld bc, 0x1aff
	ldir

;	Clear the attribute area. Use the attribute
;	value in v_attr for this.

	ld a, (v_screen_attr)
	ld h, a
	xor a
	ld l, a
	push hl
	pop de
	inc de
	ld a, (v_attr)
	ld (hl), a
	ld bc, 0x2ff
	ldir
	pop af
	pop bc
	pop de
	pop hl
	ret


;
;	Moves print position to a new line.
;

newline

	push af
	push bc

	xor a
	ld (v_column), a
	ld a, (v_row)
	inc a
	ld (v_row), a

;	Wrap text from bottom to top
	cp 24
	jr nz, newline_done
	ld a, 0
	ld (v_row), a

newline_done

	pop bc
	pop af
	ret

;
;	Progressively wipes screen from the line given in H, to the line
; given in L. Shows a dotted line indicating the line being wiped.
;
screen_wipe

	push hl

	;	Now find the address in the frame buffer to be written.

	ld a, h
	call get_pixel_address_line
	push hl
	pop de
	inc de
	xor a
	ld (hl), a
	ld bc, 0x1f
	ldir

	pop hl
	push hl

	ld a, h
	cp l
	jr z, screen_wipe_done

	ld a, h
	inc a
	call get_pixel_address_line
	push hl
	pop de
	inc de
	ld a, 0xAA
	ld (hl), a
	ld bc, 0x1f
	ldir

	pop hl
	bit 0, h
	jr nz, screen_wipe_2

	halt

screen_wipe_2

	inc h
	jr screen_wipe

screen_wipe_done

	pop hl
	ret


;
;	Given a row pixel index in A, returns the screen address
; of the start of that line. Only considers main screen.
;

get_pixel_address_line

	push bc
	ld b, a
	and 0x07
	or 0x40
	ld h, a
	ld a, b
	rra
	rra
	rra
	and 0x18
	or h
	ld h, a
	ld a, b
	rla
	rla
	and 0xe0
	ld l, a
	pop bc
	ret

mask_bits

	defb 0, 128, 192, 224, 240, 248, 252, 254

proportional_data

	defb 0,0,0,0,0,0,0,0
	defb 0,0,0,0,0,0,0,0
	defb 0,0,0,0,0,0,0,0
	defb 0,0,0,0,0,0,0,0
	defb 4, 3, 6, 8, 7, 7, 8 ,3	; Space - '
	defb 4, 4, 8, 7, 3, 7, 3, 7	; ( - /
	defb 7, 5, 7, 7, 7, 7, 7, 7	; 0 - 7
	defb 7, 7, 3, 3, 5, 6, 5, 7	; 8 - ?
	defb 7, 7, 7, 7, 7, 7, 7, 7	; @ - G
	defb 7, 3, 7, 7, 7, 8, 7, 7 	; H - O
	defb 7, 7, 7, 7, 7, 7, 7, 8	; P - W
	defb 7, 7, 7, 5, 7, 5, 8, 8	; X - _
	defb 7, 7, 7, 7, 7, 7, 5, 7	; � - g
	defb 7, 3, 3, 7, 3, 8, 7, 7	; h - o
	defb 7, 7, 6, 7, 5, 7, 7, 8	; p - w
	defb 7, 7, 7, 5, 7, 5, 7, 8	; x - (C)
