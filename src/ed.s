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

;;----------------------------------------------------------------------------------------------------------------------
;; Font

        org     $6400

        incbin  "data/font.bin"

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
        ld      bc,$000e        ; Paper/ink combination (bright yellow on black)
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
;; Main
;; The main loop

Title   db      "Ed (V0.1)",0
Footnote:
        db      "Ln 0001  Col 0001",0

Main:
        ; Title
        ld      bc,$0000        ; At (0,0)
        ld      de,$0150        ; 80x1
        ld      a,2             ; Colour 2
        call    WriteSpace
        ld      bc,$0001
        ld      de,Title
        ld      a,2
        call    Print

        ; Footnote
        ld      bc,$1f00
        ld      de,$0150
        ld      a,2
        call    WriteSpace
        ld      bc,$1f01
        ld      de,Footnote
        ld      a,2
        call    Print

EndForever:
        jp      EndForever

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------


