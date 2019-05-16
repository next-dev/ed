;;----------------------------------------------------------------------------------------------------------------------
;; Next Editor
;;----------------------------------------------------------------------------------------------------------------------

opt     sna=Start:$7fff
opt     zxnext
opt     zxnextreg

BREAK   macro
        dw      $01dd
        endm

EXIT    macro
        dw      $00dd
        endm

;;
;; Spectrum ROM system variables
;;

LASTK   equ     $5c08
REPDEL  equ     $5c09
REPPER  equ     $5c0a
FLAGS   equ     $5c3b
MODE    equ     $5c41

;;
;; Constants
;;

EOL     equ     $0a
EOF     equ     $1a

;;----------------------------------------------------------------------------------------------------------------------
;; Memory map

; $0000     ROM
; $2000     ROM
; $

;;----------------------------------------------------------------------------------------------------------------------
;; Font

        org     $6400

        incbin  "data/font.bin"

;;----------------------------------------------------------------------------------------------------------------------
;; Sample text

        org     $c000

        incbin  "data/test.txt"
        db      26

textlen equ * - $c000

;;----------------------------------------------------------------------------------------------------------------------
;; Editor state

        org     $6000

; Presentation state
top             dw      0           ; Offset of character shown at start of top line
dx              dw      0           ; Indent
mark            dw      0           ; Virtual offset into doc where cursor is
cursorX         db      0           ; Screen X coord of cursor
cursorY         db      0           ; Screen Y coord of cursor
cursorLine      dw      0           ; Line which cursor resides

; Buffer state
gapstart        dw      0           ; Offset into buffer of gap start
gapend          dw      0           ; Offset into buffer of gap end


;;----------------------------------------------------------------------------------------------------------------------
;; Start

        org     $8000

Start:
        ld      sp,$c000

        ; Initialise system variables
        ld      hl,FLAGS
        set     3,(hl)
        ld      a,35
        ld      (REPDEL),a
        ld      a,5
        ld      (REPPER),a
        ld      a,$ff
        ld      ($5c00),a        
        ld      ($5c04),a
        ei
        call    Initialise
        jp      Main

;;----------------------------------------------------------------------------------------------------------------------
;; Page

Page:
        ; B = Slot
        ; C = Page

;;----------------------------------------------------------------------------------------------------------------------
;; Editor paletter control

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
        ;   B = Paper
        ;   C = Ink
        ;   A = Slot (0-15)
        ; Destroys:
        ;   HL, DE, BC, A
        nextreg $43,%00110000   ; Set tilemap palette
        sla     a
        sla     a
        sla     a
        sla     a
        nextreg $40,a
        ; Paper colour
        ld      de,Palette
        ld      l,b
        ld      h,0
        add     hl,de
        ld      a,(hl)
        nextreg $41,a
        ; Ink colour
        ld      de,Palette
        ld      l,c
        ld      h,0
        add     hl,de
        ld      a,(hl)
        nextreg $41,a
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Initialise
;; Initialise the screen and video modes

Initialise:
        xor     a
        out     (254),a

        ; Initialise palette
        ;
        ;   0   Normal text
        ;   1   Cursor
        ;   2   Inverse text
        ;
        ld      bc,$0007        ; Paper/ink combination (bright yellow on black)
        xor     a               ; For slot 0
        call    SetColour
        ld      bc,$000a        ; Paper/ink combination (bright red on black)
        ld      a,1             ; For slot 1
        call    SetColour
        ld      bc,$0700        ; Paper/ink combination (black on white)
        ld      a,2
        call    SetColour

        call    ClearScreen

        ; Set up the tilemap
        ; Memory map:
        ;       $4000   80x32x2 tilemap (5120 bytes)
        ;       $6000   128*32 tiles (4K)
        ;
        nextreg $6b,%11000001       ; Tilemap control
        nextreg $6e,$00             ; Tilemap base offset
        nextreg $6f,$20             ; Tiles base offset
        nextreg $4c,8               ; Transparency colour (bright black)
        nextreg $68,%10000000       ; Disable ULA output
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Printing routines

CalcTileAddress:
        ; Input:
        ;   B = Y coord (0-31)
        ;   C = X coord (0-79)
        ; Output:
        ;   HL = Tile address
        ; Destroys:
        ;   BC
        push    de
        ld      e,b
        ld      d,80
        mul                 ; DE = 80Y
        ex      de,hl       ; HL = 80Y
        pop     de
        ld      b,0
        add     hl,bc       ; HL = 80Y+X
        add     hl,hl       ; 2 bytes per tilemap cell
        ld      bc,$4000    ; Base address of tilemap
        add     hl,bc
        ret

Print:
        ; Input
        ;   B = Y coord (0-31)
        ;   C = X coord (0-79)
        ;   DE = string
        ;   A = colour (0-15)
        ; Output:
        ;   DE = points after string
        ; Destroys:
        ;   BC, HL, DE, A

        ; Calculate tilemap address
        call    CalcTileAddress
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        ld      c,a
.l1     ld      a,(de)      ; Write out character
        and     a
        jr      z,.finish
        ld      (hl),a
        inc     hl
        ld      a,c         ; Write out attribute
        ld      (hl),a
        inc     hl
        inc     de
        jr      .l1
.finish inc     de
        ret

PrintChar:
        ; Input:
        ;   B = Y coord (0-31)
        ;   C = X coord (0-79)
        ;   D = Colour (0-15)
        ;   E = character
        ; Output:
        ;   HL = Tilemap address of following position
        ; Destroys:
        ;   BC, A
        call    CalcTileAddress
        ld      a,e
        ld      (hl),a
        inc     hl
        ld      a,d
        swapnib
        ld      (hl),a
        inc     hl
        ret

WriteSpace:
        ; Draw a rectangular area of spaces
        ; Input
        ;   B = Y coord (0-31) of start
        ;   C = X coord (0-79) of start
        ;   D = height
        ;   E = width
        ;   A = colour (0-15)
        ; Destroys
        ;   HL, BC, DE, A
        call    CalcTileAddress     ; HL = start corner
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        ld      c,a                 ; C = colour
        ld      b,e                 ; Save width
.row    ld      e,b                 ; Restore width

        push    hl

.col    ld      a,' '               ; Write space
        ld      (hl),a
        inc     hl
        ld      (hl),c              ; Write colour
        inc     hl
        dec     e
        jr      nz,.col

        ; Move HL to next row
        pop     hl
        ld      e,160
        ld      a,d                 ; Save row counter
        ld      d,0
        add     hl,de               ; HL = next row
        ld      d,a
        dec     d
        jr      nz,.row
        ret

ClearScreen:
        ; Clear screen (write spaces in colour 0 everywhere)
        ; Destroys
        ;   BC, HL, A
        ld      bc,2560
        ld      hl,$4000
.l1     ld      a,' '
        ld      (hl),a
        inc     hl
        xor     a
        ld      (hl),a
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz,.l1
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Cursor management

VirtToReal:
        ; Convert a virtual mark to a real mark.  Virtual marks represent an offset into the document.
        ; Real marks are actual offsets into the memory the document resides and respects the buffer gap.
        ;
        ; Input:
        ;   HL = virtual mark
        ; Output:
        ;   HL = real mark
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Display

Title       db      "Ed (V0.1)",0
Footnote    db      "Ln 0001  Col 0001",0

FindScrollStart:
        ; Scan a line to find the first character that is on the left side of the screen.  If the line is shorter
        ; than the scrolled offset, return the address of the newline
        ;
        ; Input:
        ;   HL = start of line
        ; Output:
        ;   HL = start of line on left side of screen, or pointing to $0a/$1b at end of line
        ; Destroys
        ;   A
        ;
        ld      a,(dx)
        and     a
        ret     z
        push    bc
        ld      b,a
.l1     ld      a,(hl)
        cp      EOL         ; Is it new line?
        jr      z,.finish
        cp      EOF
        jr      z,.finish
        inc     hl
        djnz    .l1
.finish
        pop     bc
        ret

FindNextLine:
        ; Find the address of the next line or address of $1a character if EOF found.
        ;
        ; Input:
        ;   HL = Document address
        ; Output:
        ;   HL = Address of next line
        ; Destroys:
        ;   A
        ;
        ld      a,(hl)
        cp      EOL             ; Test for end of line
        jr      z,.eol_found
        cp      EOF             ; Test for end of file
        ret     z               ; HL stays pointing to EOF
        inc     hl
        jr      FindNextLine
.eol_found:
        inc     hl              ; Move past end of line
        ret


DisplayRow:
        ; Display a single row of text on the screen
        ; 
        ; Input
        ;   HL = beginning of row
        ;   DE = tilemap address
        ; Output
        ;   HL = beginning of next document line
        ;   DE = points to next line on tilemap
        ; Destroys
        ;   A
        ;
        push    bc
        call    FindScrollStart     ; HL = beginning of visible row
        ld      b,80
.l1     ld      a,(hl)
        cp      EOL
        jr      z,.endline
        cp      EOF
        jr      z,.endline
        ld      (de),a          ; Write character
        inc     hl
        inc     de
        xor     a               ; Normal text colours
        ld      (de),a          ; Write attribute
        inc     de
        djnz    .l1

        ; Managed to fill whole row of screen
        call    FindNextLine
        pop     bc
        ret

.endline
        call    FindNextLine    ; Skip to next line, ready for next display row
        ld      c,' '
        xor     a
        ex      de,hl
.l2     ld      (hl),c          ; Write out space
        inc     hl
        ld      (hl),a          ; Write out attribute
        inc     hl
        djnz    .l2
        ex      de,hl
        pop     bc
        ret



DisplayScreen:
        ; Title
        ld      bc,$0000        ; At (0,0)
        ld      de,$0150        ; 80x1
        ld      a,2             ; Colour 2
        call    WriteSpace
        ld      bc,$0001
        ld      de,Title
        ld      a,2
        call    Print

        ; Status bar
        ld      bc,$1f00
        ld      de,$0150
        ld      a,2
        call    WriteSpace
        ld      bc,$1f01
        ld      de,Footnote
        ld      a,2
        call    Print

        ; Write the rows
        ld      bc,$0100
        call    CalcTileAddress
        ex      de,hl           ; DE = Tile address
        push    de
        ld      hl,(top)        ; HL = Pointer to document that is at the top
        ld      de,$c000
        add     hl,de           ; Convert to real address
        pop     de
        ld      b,30
.l1     call    DisplayRow
        djnz    .l1
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Keyboard routines
;; Lifted and adapated from the ROM

; Scans the keyboard and returns button code
;
; Output:
;   D =
;   E = button code of pressed key (0-39) or $ff if no key is pressed
;   A = button code of pressed key (0-39) or $ff if no key is pressed
;   ZF = 0 if nore than two keys are pressed or neither pair of keys is a shift (i.e. invalid)

KeyScan:
        ld      l,$2f           ; Initial preset value
        ld      de,$ffff        ; DE = no key, 2 key cache
        ld      bc,$fefe        ; B = row address, C = port address

.key_line:
        in      a,(c)           ; Read from the keyboard port
        cpl                     ; Make 1 = key down
        and     $1f             ; We only care about the lower 5 bits (since 5 keys per line)
        jr      z,.no_key       ; No keys being pressed?

        ld      h,a             ; H = key state of the 5 keys in this line
        ld      a,l
.three_keys:
        inc     d
        ret     nz              ; More than 1 non-shift key pressed?

.key_bits:
        ; Possible values on first row:
        ;   27, 1f, 17, 0f, 07
        ; Possible values on second row:
        ;   26, 1e, 26, 0e, 06
        ; 
        ; and so on...
        sub     8               ; Continuously subtract 8 from the preset value until a key bit is found
        srl     h
        jr      nc,.key_bits
        ld      d,e             ; Copy an earlier key value to the D register
        ld      e,a             ; E = new key value
        jr      nz,.key_bits    ; If there are more keys, then jump back

.no_key:
        dec     l               ; Next initial preset value for next row
        rlc     b               ; Next line
        jr      c,.key_line     ; The one 0 bit will roll off the end when all 8 rows are done.  If not, CF is set.

        ld      a,d             ; A = earlier key or $ff
        inc     a               ; No second key?
        ret     z               ; Just return

        ; Test for caps shift ($27)
        cp      $28             ; Remember, A was just increased so we test against keycode + 1
        ret     z

        ; Test for sym shift
        cp      $19
        ret     z

        ; Test for sym shift being the most recent key (as it could be stored after 2nd pair)
        ld      a,e             ; A = possible sym shift
        ld      e,d             ; E = other key
        ld      d,a             ; D = possible sym shift
        cp      $18             ; Is sym shift?
        ret                     ; ZF = 0 if neither key is shift


;;----------------------------------------------------------------------------------------------------------------------
;; Main
;; The main loop

Main:
        ;call    DisplayScreen
        call    KeyScan
        inc     e
        jr      z,Main

        dec     e
        ld      b,0
        ld      c,e
        ld      de,$0031
        call    PrintChar

EndForever:
        jp      Main

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------


