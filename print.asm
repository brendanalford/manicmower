

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
	define  ATTR_TRANS	0xff

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

	ld a, (v_row)
	and 0x18
	or 0x40
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

	ld a, (v_attr)
	cp ATTR_TRANS
	jr z, .putchar.end

	ld a, (v_row)
	srl a
	srl a
	srl a
	and 3
	or 0x58
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

	ld a, (v_row)
	and 0x18
	or 0x40
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

	ld a, (v_row)
	srl a
	srl a
	srl a
	and 3
	or 0x58
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

	ld a, (v_attr)
	ld (hl), a

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

	ld a, 0
	ld hl, 16384
	ld (hl), a
	ld de, 16385
	ld bc, 6144
	ldir

;	Clear the attribute area. Use the attribute
;	value in v_attr for this.

	ld a, (v_attr)
	ld (hl), a
	ld bc, 768
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
