;
; Turboloader.asm
; This is *heavily* borrowed from the ROM loader :)
; Comments to keep me sane as I didn't write the code!
;


load_bytes

  inc d
  ex af, af' ; Keep formatting'
  dec c
  di

  ld a, 0x00      ; Border black and mic off
  out (0xfe), a

  in a, (0xfe)    ; Get initial EAR bit state
  rra
  and 0x20
  or 0x02
  ld c, a
  cp a

load_break

; Insert favourite freak-out routine here.

  ret nz

load_start

  call load_edge_1
  jr nc, load_break

  ld hl, 0x20  ; Was 0x0415 for 1 sec delay in ROM loader

load_wait

  djnz load_wait  ; self loop to LD-WAIT (for 256 times)

  dec hl
  ld a, h
  or l
  jr nz, load_wait

;   continue after delay with H holding zero and B also.
;   sample 256 edges to check that we are in the middle of a lead-in section.

  call load_edge_2
  jr nc, load_break ; No edges at all

load_leader

  ld b, 0x9c
  call load_edge_2
  jr nc, load_break ; time out detected

  ld a, 0xc6
  cp b
  jr nc, load_start ; Too close for lead in

  inc h             ; proceed to test 256 edged sample
  jr nz, load_leader  ; back to LD-LEADER while more to do.

;   sample indicates we are in the middle of a two or five second lead-in.
;   Now test every edge looking for the terminal sync signal.

load_sync

  ld b, 0xc9
  call load_edge_1
  jr nc, load_break ; Timeout

  ld a, b
  cp 0xd4
  jr nc, load_sync  ; Gap too big

;   but a short gap will be the sync pulse.
;   in which case another edge should appear before B rises to $FF

  call load_edge_1
  ret nc            ; timeout

; proceed when the sync at the end of the lead-in is found.
; We are about to load data so change the border colours.

  ld a, c       ; fetch long-term mask from C
  xor 0x03      ; and make blue/yellow.
  ld c, a       ; store the new long-term byte.

  ld h, 0       ; Parity byte = 0
  ld b, 0xb0    ; timing
  jr load_marker  ;forward to LD-MARKER
                ; the loop mid entry point with the alternate
                ; zero flag reset to indicate first byte
                ; is discarded.

; --------------
;   the loading loop loads each byte and is entered at the mid point.

load_loop

  ex af, af'        ; 'restore entry flags and type in A.
  jr nz, load_flag  ; forward to LD-FLAG if awaiting initial flag
                    ; which is to be discarded.
  ld (ix), l        ; Loaded byte at memory location
  jr load_next      ; Forward to ld-next

; ---

;; LD-FLAG
load_flag

  rl c        ; preserve carry (verify) flag in long-term
              ; state byte. Bit 7 can be lost.
  xor l       ; compare type in A with first byte in L.
  ret nz      ; return if no match e.g. CODE vs. DATA.

;   continue when data type matches.

  ld a, c     ; fetch byte with stored carry
  rra         ; rotate it to carry flag again
  ld c, a     ; restore long-term port state.
  inc de      ; increment length ??
  jr load_dec ; forward to LOAD-DEC.
              ; but why not to location after ?

load_next

  inc ix      ; Increment byte pointer

load_dec

  dec de      ; Decrement length
  ex af, af'  ; 'flags
  ld b, 0x02  ; Timing

;   when starting to read 8 bits the receiving byte is marked with bit at right.
;   when this is rotated out again then 8 bits have been read.

;; LD-MARKER
load_marker

  ld l, 0x01  ; Initialise as %00000001

load_8_bits

  call load_edge_2  ; routine LD-EDGE-2 increments B relative to
                    ; gap between 2 edges.
  ret nc            ; Time out
  ld a, 0xcb        ; Comparison byte - XXX CHANGE FOR TURBO
  cp b              ; compare to incremented value of B.
                    ; if B is higher then bit on tape was set.
                    ; if <= then bit on tape is reset.
  rl l              ; rotate the carry bit into L.
  ld b, 0xb0        ; reset the B timer byte.
  jp nc, load_8_bits
                    ; Back to ld-8-bits

;   when carry set then marker bit has been passed out and byte is complete.

  ld a, h           ; Fetch running parity byte
  xor l             ; Include the new byte
  ld h, a           ; and store back in parity register.

  ld a, d           ; Any bytes left to load?
  or e
  jr nz, load_loop  ; yes

;   when all bytes loaded then parity byte should be zero.

  ld a, h           ; Fetch parity byte
  cp 0x1            ; Set carry if 0
  ret               ; return
                    ; in no carry then error as checksum disagrees.

; -------------------------
; Check signal being loaded
; -------------------------
;   An edge is a transition from one mic state to another.
;   More specifically a change in bit 6 of value input from port $FE.
;   Graphically it is a change of border colour, say, blue to yellow.
;   The first entry point looks for two adjacent edges. The second entry point
;   is used to find a single edge.
;   The B register holds a count, up to 256, within which the edge (or edges)
;   must be found. The gap between two edges will be more for a '1' than a '0'
;   so the value of B denotes the state of the bit (two edges) read from tape.

; ->

load_edge_2

  call load_edge_1
  ret nc                        ; Space or time out

; ->
;   this entry point is used to find a single edge from above but also
;   when detecting a read-in signal on the tape.

load_edge_1

  ld a, 0x16      ; Delay value of 22

load_delay

  dec a
  jr nz, load_delay
  and a           ; Clear carry

load_sample

  inc b           ; Increment time out counter
  ret z           ; Return with failure if FF passsed.

  ld a, 0x7f
  in a, (0xfe)    ; Read keyboard/ear port 0x7ffe
  rra
  ret nc          ; Return if space pressed

  xor c           ; Compare with long term state
  and 0x20        ; Isolate bit 5
  jr z, load_sample
                  ; Back if no edge

;   but an edge, a transition of the EAR bit, has been found so switch the
;   long-term comparison byte containing both border colour and EAR bit.

  ld a, c         ; Fetch comparison value
  cpl             ; Switch the bits
  ld c, a         ; Place back in C for long-term

  ld a, (load_stripe_val)
  inc a
  ld (load_stripe_val), a

  and 0x7         ; Isolate new colour bits
  or 0x8          ; Set bit 3 - MIC off
  out (0xfe), a   ; Set border colour

  scf          ; Set carry flag - edge found
  ret

load_stripe_val

  defb 0