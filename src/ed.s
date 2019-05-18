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

; $0000         ROM
; $2000         ROM
; $4000         Tilemap
; $5b00         256 circular buffer
; $6000         Tiles
; $7fff         Code
; $c000         Data

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

        org     $7fff

        dw      ImRoutine

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
                di
                ld      a,$7f
                ld      i,a
                im      2
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
;; Main
;; The main loop

Main:
        ;call    DisplayScreen

;        call    ClearScreen
        call    DisplayKeys

        jr      Main

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
