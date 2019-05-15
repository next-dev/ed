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
;; Initialise
;; Initialise the screen and video modes

Initialise:
        xor     a
        out     (254),a

        ; Initialise palette                RRR GGG BB
        ;       $01 = black                 000 000 00
        ;       $11 = blue                  000 000 10
        ;       $21 = red                   100 000 00
        ;       $31 = magenta               100 000 10
        ;       $41 = green                 000 100 00
        ;       $51 = cyan                  000 100 10
        ;       $61 = yellow                100 100 00
        ;       $71 = light grey            100 100 10
        ;       $81 = dark grey             011 011 01
        ;       $91 = bright blue           000 000 11
        ;       $a1 = bright red            111 000 00
        ;       $b1 = bright magenta        111 000 11
        ;       $c1 = bright green          000 111 00
        ;       $d1 = bright cyan           000 111 11
        ;       $e1 = bright yellow         111 111 00
        ;       $f1 = white                 111 111 11
        ; 
        nextreg $43,%00110000   ; Set tilemap palette
        nextreg $40,$00
        nextreg $41,%00000000
        nextreg $41,%00000000
        nextreg $40,$10
        nextreg $41,%00000000
        nextreg $41,%00000010
        nextreg $40,$20
        nextreg $41,%00000000
        nextreg $41,%10000000
        nextreg $40,$30
        nextreg $41,%00000000
        nextreg $41,%10000010
        nextreg $40,$40
        nextreg $41,%00000000
        nextreg $41,%00010000
        nextreg $40,$50
        nextreg $41,%00000000
        nextreg $41,%00010010
        nextreg $40,$60
        nextreg $41,%00000000
        nextreg $41,%10010000
        nextreg $40,$70
        nextreg $41,%00000000
        nextreg $41,%10010010
        nextreg $40,$80
        nextreg $41,%00000000
        nextreg $41,%01101101
        nextreg $40,$90
        nextreg $41,%00000000
        nextreg $41,%00000011
        nextreg $40,$a0
        nextreg $41,%00000000
        nextreg $41,%11100000
        nextreg $40,$b0
        nextreg $41,%00000000
        nextreg $41,%11100011
        nextreg $40,$c0
        nextreg $41,%00000000
        nextreg $41,%00011100
        nextreg $40,$d0
        nextreg $41,%00000000
        nextreg $41,%00011111
        nextreg $40,$e0
        nextreg $41,%00000000
        nextreg $41,%11111100
        nextreg $40,$f0
        nextreg $41,%00000000
        nextreg $41,%11111111


        ; Clear screen
        ld      bc,2560
        ld      hl,$4000
.l1     ld      a,' '
        ld      (hl),a
        inc     hl
        ld      a,%00100000
        ld      (hl),a
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      nz,.l1

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
        ld      c,a
        sla     c
        sla     c
        sla     c
        sla     c           ; Move colour to bits 7-3
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


;;----------------------------------------------------------------------------------------------------------------------
;; Main
;; The main loop

Hello
        db      "Hello,",0
        db      "World!",0

Main:
        ld      bc,$0101
        ld      de,Hello
        ld      a,6+8
        call    Print
        ld      bc,$0108
        ld      a,2+8
        call    Print
        jp      Main

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------


