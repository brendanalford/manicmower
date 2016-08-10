;
;	input.asm
;

	define CAPS_SHIFT	0x01
	define SYMBOL_SHIFT	0x02

	define KEY_LEFT		0x05
	define KEY_RIGHT	0x06
	define KEY_UP		0x07
	define KEY_DOWN		0x08
	define BREAK		0x09
	define DELETE		0x10
	define ENTER		0x13


keylookup_norm

	defb " ", SYMBOL_SHIFT, "MNB", ENTER ,"LKJHPOIUY09876"
	defb "12345QWERTASDFG", CAPS_SHIFT, "ZXCV"

keylookup_lower

	defb " ", SYMBOL_SHIFT, "mnb", ENTER ,"lkjhpoiuy09876"
	defb "12345qwertasdfg", CAPS_SHIFT, "zxcv"

keylookup_caps

	defb BREAK, SYMBOL_SHIFT, "MNB", ENTER ,"LKJHPOIUY"
	defb DELETE, "9", KEY_RIGHT, KEY_UP, KEY_DOWN
	defb "1234", KEY_LEFT, "QWERTASDFG", CAPS_SHIFT, "ZXCV"

keylookup_symshift

	defb " ", SYMBOL_SHIFT, ".,*", ENTER ,"=+-^", 0x22, ";i][_)('&"
	defb "!@#$%qwe<>~|\\{}", CAPS_SHIFT, ":", 0x60, "?/"


;
;	Scans the keyboard for a single keypress.
; Accumulator contains flags as follows:
;	Bit 0 : Allow mixed case.
; Bit 1 : Treat CS/SS as standalone keys, not modifiers
;	Returns with carry flag set and key in accumulator if
;	found, or carry flag clear if no key pressed.
;

scan_keys

	push ix
	push hl
  push de
	push bc
	push af

	ld bc, 0x7ffe
	ld ix, v_keybuffer

key_row_read

	in a, (c)
	and 0x1f
	ld (ix), a
	inc ix

	rrc b
	ld a, b
	cp 0x7f
	jr nz, key_row_read

; 	Rows read into bitmap

	pop af

 	ld ix, v_keybuffer
	ld hl, keylookup_lower

; Store keyboard read flags in D

  ld d, a

; Are we forcing upper case?

	bit 0, d
	jr nz, no_force_upcase

; Yes we are

	ld hl, keylookup_norm

no_force_upcase

; Treat CS/SS as modifiers?

  bit 1, d
  jr nz, no_sym_pressed

; Yes, alter key lookup tables on this basis.

	bit 0, (ix+7)
	jr nz, no_caps_pressed

	ld hl, keylookup_caps

no_caps_pressed

	bit 1, (ix)
	jr nz, no_sym_pressed

	ld hl, keylookup_symshift

no_sym_pressed

	ld b, 8

map_row_read

	ld a, 0xff
	ld c, b
	ld b, 5

key_loop

	bit 0, (ix)
	jr nz, key_next

;	Key found, lookup from table

	ld a, (hl)

; Exit if we are treating modifier keys as standalone

  bit 1, d
  jr nz, key_return

;	We're treating CS/SS as modifiers, so if these are pressed, continue
; scanning

  cp CAPS_SHIFT
	jr z, key_next
  cp SYMBOL_SHIFT
  jr z, key_next

;	Else return with key in A

key_return

	pop bc
  pop de
	pop hl
	pop ix
	scf
	ret

key_next

  ld a, 0xff
	inc hl
	srl (ix)
	djnz key_loop

map_row_next

	inc ix
	ld b, c
	djnz map_row_read

	pop bc
	cp 0xff
	jr z, no_key
  pop de
  pop hl
	pop ix
	scf
	ret

no_key

  pop de
	pop hl
	pop ix
	and a 	; reset carry flag
	ret

;
;	Waits for a key press (and release)
;	Returns the key pressed in A
;

get_key

	push bc
  ld b, a

get_key_scan

  ld a, b
	call scan_keys
	jr nc, get_key_scan
	ld b, a

debounce_key
	xor a
	in a, (0xfe)
	and 0x1f
	cp 0x1f
	jr nz, debounce_key
	ld a, b
	pop bc
	ret
