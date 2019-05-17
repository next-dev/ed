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

EOL     equ     $0d
EOF     equ     $1a

;;----------------------------------------------------------------------------------------------------------------------
;; Memory map

; $0000     ROM
; $2000     ROM
; $

;;----------------------------------------------------------------------------------------------------------------------
;; Font

        org     $6000

        incbin  "data/font.bin"

;;----------------------------------------------------------------------------------------------------------------------
;; Sample text

        org     $c000

        incbin  "data/test.txt"
        db      EOF

textlen equ * - $c000


;;----------------------------------------------------------------------------------------------------------------------

        org     $8000

;;----------------------------------------------------------------------------------------------------------------------
;; Editor state

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
;; Initialise
;; Initialise the screen and video modes

Initialise:
        call    InitVideo
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Modules

        include "src/screen.s"
        include "src/utils.s"
        include "src/display.s"
        include "src/keyboard.s"

;;----------------------------------------------------------------------------------------------------------------------
;; New Keyboard routines

PKeys:  dw      1           ; Current buffer offset into Keys
Keys:   ds      16          ; Double-buffered space to store the key presses
Edges:  ds      8

KeyScan2:
        ; Output:
        ;   HL = pointer to keyscan
        ; Destroys
        ;   BC, DE, A

        ; Toggle the pointer
        ld      hl,(PKeys)
        ld      a,l
        xor     1
        ld      l,a
        ld      (PKeys),hl
        ld      de,Keys
        add     hl,de       ; HL = Key buffer

        ; Scan the keyboard
        ld      bc,$fdfe    ; Keyboard ports (start here to make sure shift rows are last)
        push    hl
        ld      e,8         ; Checksum to know when to end loop

.l1     in      a,(c)
        cpl
        and     $1f
        ld      (hl),a
        inc     hl
        inc     hl
        rlc     b
        dec     e
        jr      nz,.l1
        pop     hl          ; Restore pointer to buffer



        ret

DisplayKeys:
        ; Input
        ;   HL = Keyboard state
        ld      bc,0
        ld      e,8

.l1     ld      a,(hl)
        inc     hl
        inc     hl
        push    hl
        ld      l,5
.l2     srl     a
        ld      d,a
        push    de          ; Save outer loop counter
        jr      c,.pressed
        ld      de,$0000
        jr      .cont
.pressed
        ld      de,$0100
.cont   push    bc          ; Save coords
        push    hl          ; Save inner loop counter
        call    PrintChar
        pop     hl
        pop     bc
        pop     de
        ld      a,d
        inc     c
        dec     l
        jr      nz,.l2
        pop     hl
        ld      c,0
        inc     b
        dec     e
        jr      nz,.l1
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Main
;; The main loop

Main:
        ;call    DisplayScreen

;        call    ClearScreen
        call    KeyScan2
        call    DisplayKeys

        jr      Main

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
