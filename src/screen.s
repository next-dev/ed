;;----------------------------------------------------------------------------------------------------------------------
;; Low-level screen printing routines
;;----------------------------------------------------------------------------------------------------------------------

;;----------------------------------------------------------------------------------------------------------------------
;; Video modes

InitVideo:
                xor     a
                out     (254),a

        ; Initialise palette
        ;
        ;   0   Normal text
        ;   1   Cursor
        ;   2   Inverse text
        ;
                ld      bc,$0007        ; Paper/ink combination (white on black)
                xor     a               ; For slot 0
                call    SetColour
                ld      bc,$0700        ; Paper/ink combination (back on white)
                ld      a,1             ; For slot 1
                call    SetColour
                ld      bc,$0a0f        ; Paper/ink combination (bright white on bright red)
                ld      a,2
                call    SetColour

                call    ClearScreen

        ; Set up the tilemap
        ; Memory map:
        ;       $4000   80x32x2 tilemap (5120 bytes)
        ;       $6000   128*32 tiles (4K)
        ;
                nextreg $07,2                   ; Set speed to 14Mhz
                nextreg $6b,%11000001           ; Tilemap control
                nextreg $6e,$00                 ; Tilemap base offset
                nextreg $6f,$20                 ; Tiles base offset
                nextreg $4c,8                   ; Transparency colour (bright black)
                nextreg $68,%10000000           ; Disable ULA output

DoneVideo:
                ret


;;----------------------------------------------------------------------------------------------------------------------
;; Palette control

Palette:
                db  %00000000
                db  %00000010
                db  %10000000
                db  %10000010
                db  %00010000
                db  %00010010
                db  %10010000
                db  %10010010
                db  %01101101
                db  %00000011
                db  %11100000
                db  %11100011
                db  %00011100
                db  %00011111
                db  %11111100
                db  %11111111

SetColour:
        ; Input:
        ;       B = Paper
        ;       C = Ink
        ;       A = Slot (0-15)
        ; Uses:
        ;       HL, BC, A
                nextreg $43,%00110000   ; Set tilemap palette
                swapnib
                nextreg $40,a
                ld      a,b             ; set Paper colour
                call    .SetColourToA
                ld      a,c             ; set Ink colour
.SetColourToA   ; recursive sub-routine
                ld      hl,Palette
                add     hl,a
                ld      a,(hl)
                nextreg $41,a
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Utitlies

CalcTileAddress:
        ; Input:
        ;       B = Y coord (0-31)
        ;       C = X coord (0-79)
        ; Output:
        ;       HL = Tile address
                push    bc
                push    de
                ld      e,b
                ld      d,80
                mul                 ; DE = 80Y
                ex      de,hl       ; HL = 80Y
                pop     de
                ld      b,$20       ; BC = tilemap base address $4000/2 + X coord
                add     hl,bc
                add     hl,hl       ; 2 bytes per tilemap cell
                pop     bc
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Low-level printing

Print:
        ; Input
        ;       B = Y coord (0-31)
        ;       C = X coord (0-79)
        ;       DE = string
        ;       A = colour (0-15)
        ; Output:
        ;       DE = points after string
        ; Uses:
        ;       BC, HL, DE, A

        ; Calculate tilemap address
                call    CalcTileAddress
                swapnib
                ld      c,a
                jr      .loopEntry
.l1             ld      (hl),a      ; Write out character
                inc     hl
                ld      (hl),c      ; Write out attribute
                inc     hl
.loopEntry      ld      a,(de)      ; Read next string character
                inc     de
                and     a
                jr      nz,.l1
                ret

PrintChar:
        ; Input:
        ;       B = Y coord (0-31)
        ;       C = X coord (0-79)
        ;       D = Colour (0-15)
        ;       E = character
        ; Output:
        ;       HL = Tilemap address of following position
        ; Uses:
        ;       A
                call    CalcTileAddress
                ld      (hl),e
                inc     hl
                ld      a,d
                swapnib
                ld      (hl),a
                inc     hl
                ret

AdvancePos:
        ; Advances position to next position on screen.  This will wrap to next line or back to the top of the screen.
        ; Input:
        ;       B = Y coord (0-31)
        ;       C = X coord (0-79)
        ; Output:
        ;       BC = next position XY.
        ; Uses:
        ;       A
        ;
                inc     c
                cp      80
                ret     nz
                xor     a
                ld      c,a
                inc     b
                cp      32
                ret     nz
                ld      b,a
                ret

WriteSpace:
        ; Draw a rectangular area of spaces
        ; Input
        ;       B = Y coord (0-31) of start
        ;       C = X coord (0-79) of start
        ;       D = height
        ;       E = width
        ;       A = colour (0-15)
        ; Uses:
        ;       HL, BC, DE, A
                call    CalcTileAddress     ; HL = start corner
                swapnib
                ld      c,a                 ; C = colour
                ld      a,160
                sub     e
                sub     e                   ; A = 160 - 2*width = deltaHL
.row            ld      b,e                 ; reset width counter
.col            ld      (hl),' '            ; Write space
                inc     hl
                ld      (hl),c              ; Write colour
                inc     hl
                djnz    .col
                add     hl,a                ; HL = next row
                dec     d
                jr      nz,.row
                ret

ClearScreen:
        ; Clear screen (write spaces in colour 0 everywhere)
        ; Uses:
        ;       BC, HL, A
                ld      bc,2560
                ld      hl,$4000
.l1             ld      (hl),' '
                inc     hl
                ld      (hl),0
                inc     hl
                dec     bc
                ld      a,b
                or      c
                jr      nz,.l1
                ret

