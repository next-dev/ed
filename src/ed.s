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

;;----------------------------------------------------------------------------------------------------------------------
;; Constants
;;

EOL             equ     $0d
EOF             equ     $1a
CMDBUFFER       equ     $bd

;;----------------------------------------------------------------------------------------------------------------------
;; Memory map

; $0000         ROM
; $2000         ROM
; $4000         Tilemap
; $5b00         256 circular buffer
; $6000         Tiles
; $7fff         Code
; $bd00         Commandbuffer
; $be00         Keyboard buffer
; $bf00         Stack
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
;; This ORGs at $7fff

        include "src/keyboard.s"

;;----------------------------------------------------------------------------------------------------------------------

MODE_NORMAL     equ     0
MODE_INSERT     equ     1
MODE_SELECT     equ     2
MODE_LINESELECT equ     3

;;----------------------------------------------------------------------------------------------------------------------
;; Start

Start:
                ld      sp,$c000
                call    Initialise
                call    InitKeys
                jp      Main

;;----------------------------------------------------------------------------------------------------------------------
;; Initialise
;; Initialise the screen and video modes

Initialise:
                call    InitVideo
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Modules

        include "src/utils.s"
        include "src/screen.s"
        include "src/display.s"
        include "src/cmdtable.s"
        include "src/state.s"

;;----------------------------------------------------------------------------------------------------------------------
;; Main
;; The main loop

Main:
                call    ClearScreen
                halt

MainLoop:
                halt
                call    DisplayScreen
.l1             ld      a,(cursorY)
                ld      b,a
                ld      a,(cursorX)
                ld      c,a
                ld      a,2
                call    DisplayCursor
                call    DisplayDebugger

        ; Read keyboard and insert commands into the command buffer
                ld      hl,KFlags
                bit     0,(hl)
                jr      z,.l1           ; Still waiting for a key
                ld      a,(Key)
                res     0,(hl)          ; Consume key
                ld      e,a             ; E = key code
                ld      c,a             ; C = key code


ProcessKey:
                ld      hl,ModeTable
                ld      a,(Mode)
                add     a,a
                add     hl,a
                add     hl,a
                ld      a,(hl)
                inc     hl
                ld      h,(hl)
                ld      l,a             ; HL = mode table to look up

                ld      a,e
                add     hl,a
                add     hl,a            ; HL = address of routine address

                ld      a,(hl)
                inc     hl
                ld      h,(hl)
                ld      l,a             ; HL = Routine to run
                ld      b,CMDBUFFER
                ld      ix,CmdBufferState
                ld      a,c
                call    CallHL          ; Run command (with A = key code)

                call    FlushCommands   ; Interpret commands

                jr      MainLoop

;;----------------------------------------------------------------------------------------------------------------------
;; Command control

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
;; COMMANDS
;;
;; The command routine job is to insert a command into the command buffer for later flushing.  Three registers will help
;; with that.  Firstly, B is already loaded with the CMDBUFFER value so that a call to BufferInsert will insert a value
;; into the correct buffer.  Secondly, A (and C) are loaded with the key-code.  Finally, IX is set to the correct buffer
;; state variables.
;;
;; Because of this, inserting BufferInsert into the command table will just insert the actual key-code into the command
;; buffer if they are the same.  For example, the key 'h' for cursor left is also 'h' as a command.
;;----------------------------------------------------------------------------------------------------------------------

;;----------------------------------------------------------------------------------------------------------------------
;; Cursor commands

Cmd_CursorLeft:
                ld      c,'h'
                jp      BufferInsert

Cmd_CursorRight:
                ld      c,'l'
                jp      BufferInsert

Cmd_CursorUp:
                ld      c,'k'
                jp      BufferInsert

Cmd_CursorDown:
                ld      c,'j'
                jp      BufferInsert

Cmd_Home:
                ld      c,'^'
                jp      BufferInsert

Cmd_End:
                ld      c,'$'
                jp      BufferInsert

;;----------------------------------------------------------------------------------------------------------------------
;; Command interpreter

FlushCommands:
        ; Keep pulling commands off the buffer until done.  It's a simple state machine.
        ;
                ld      b,CMDBUFFER
                ld      ix,CmdBufferState
                call    BufferRead              ; A = next command
                ret     z

                sub     32
                ld      hl,MainCmdTable
                add     hl,a
                add     hl,a
                ld      a,(hl)
                inc     hl
                ld      h,(hl)
                ld      l,a                     ; HL = Address of command implementor
                call    CallHL

                jr      FlushCommands

;;----------------------------------------------------------------------------------------------------------------------

AdvanceReal:
        ; Input
        ;       HL = real address of buffer
        ;
                call    RealToVirt
                inc     hl
                call    VirtToReal
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Document access functions
;; All access to the document must be via these functions so they can be refactored later.  For example, I would like
;; to add virtual access and 24-bit file sizes.

Doc_FetchChar:
        ; Output
        ;       A = character under cursor
                push    hl
                ld      hl,(pos)
                call    VirtToReal
                ld      a,(hl)
                pop     hl
                ret

Doc_AtStartDoc:
        ; Output
        ;       ZF = 1 if at start of doc
        ;
                push    af
                push    hl
                ld      hl,(pos)
                ld      a,h
                or      l
                pop     hl
                pop     af
                ret

Doc_AtEndDoc:
        ; Output
        ;       ZF = 1 if at end of doc
        ;
                push    af
                call    Doc_FetchChar
                cp      EOF
                pop     af
                ret

Doc_LineOffset:
        ; Output
        ;       HL = position in line
        ;       ZF = 1 if at start of line
        ;       CF = 0
        ;
                push    de
                ld      hl,(linepos)
                ex      de,hl           ; DE = start of line position
                and     a
                ld      hl,(pos)        ; HL = position in document
                sbc     hl,de
                pop     de
                ret

Doc_ToNextLine:
        ; Output
        ;       BC = number of characters to end of line
        ;
                push    af
                push    de
                push    hl
                ld      hl,(pos)
                call    VirtToReal

                ld      bc,0
.l1             ld      a,(hl)          ; Get next character
                cp      EOF             ; End of file?
                jr      z,.done
                cp      EOL             ; End of line?
                jr      z,.done
                inc     bc
                call    AdvanceReal
                jr      .l1
.done           pop     hl
                pop     de
                pop     af
                ret

Doc_AtEndLine:
        ; Output
        ;       ZF = 1 if at end of line
        ;       CF = 0
        ;
                push    af
                call    Doc_FetchChar
                cp      EOL
                pop     af
                ret

Doc_MoveBack:
        ; Will not move past start of document
        ; Input
        ;       DE = number of places to move
        ;
                push    de
                push    hl
                ld      hl,(pos)
                and     a
                sbc     hl,de
                jr      nc,.ok          ; Jump if there was room to move back that amount
                ld      hl,0
                ld      (linepos),hl
                ld      (pos),hl
                ret

.ok             call    VirtToReal
                ld      e,l
                ld      d,h             ; DE = new position
                ld      hl,(pos)        ; HL = old address
                call    VirtToReal

                ; We need to update linepos and cursorLine.  So loop through the characters updating state
                ; as we go
.l1             and     a
                sbc     hl,de
                jr      z,.done         ; We've reached out end point
                add     hl,de

                dec     hl              ; Move back and test
                ld      a,(hl)
                cp      EOL
                jr      nz,.l1

                inc     hl
                ld      (linepos),hl    ; Update new linepos
                dec     hl
                push    hl
                ld      hl,(cursorLine)
                dec     hl
                ld      (cursorLine),hl
                pop     hl
                jr      .l1


.done           add     hl,de
                call    RealToVirt
                ld      (pos),hl
                pop     hl
                pop     de
                ret
                
Doc_MoveForward:
        ; Will not move past end of document
        ; Input
        ;       DE = number of places to move
        ;
                push    de
                push    hl
                ld      hl,(pos)
                call    VirtToReal

.l1             ld      a,(hl)
                cp      EOF
                jr      z,.done
                cp      EOL
                jr      nz,.no_eol

                push    hl
                inc     hl
                ld      (linepos),hl
                ld      hl,(cursorLine)
                inc     hl
                ld      (cursorLine),hl
                pop     hl

.no_eol         inc     hl
                dec     de
                ld      a,e
                or      d
                jr      nz,.l1

.done           call    RealToVirt
                ld      (pos),hl
                pop     hl
                pop     de
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; CursorVisible
;; Manipulates top, dx, cursorX, cursorY to ensure cursor is on screen.  Only does something if the cursor is currently
;; off-screen

StartPoint      dw      0       ; Start range of screen on axis
EndPoint        dw      0       ; End range of screen on axis
CursorPoint     dw      0       ; Current cursor position

OutOffset       dw      0       ; Offset required to keep cursor on screen
OutCursor       dw      0       ; Cursor position

ProcessAxis:
                ld      hl,(CursorPoint)
                ld      de,(StartPoint)
                call    Compare16               ; X < S?
                jr      c,.to_left
                ld      de,(EndPoint)
                call    Compare16               ; X < E?
                jr      c,.centre

                ; Here the cursor is past the endpoint
                ; HL = Cursor
                ld      de,(EndPoint)
                dec     de
                and     a
                sbc     hl,de                   ; HL = difference between cursor and end point
                ex      de,hl
                ld      hl,(StartPoint)
                add     hl,de
                ld      (OutOffset),hl
                ld      hl,(EndPoint)
                ld      de,(StartPoint)
                and     a
                sbc     hl,de
                dec     hl
                ld      (OutCursor),hl
                ret

.to_left        ; Here the cursor is before the start point
                ld      (OutOffset),hl
                ld      hl,0
                ld      (OutCursor),hl
                ret

.centre         ; Everything is just fine
                ld      de,(StartPoint)
                and     a
                sbc     hl,de                   ; HL = position from left of screen
                ld      (OutCursor),hl
                ld      (OutOffset),de
                ret

CursorVisible:
                ; Remove cursor
                ld      bc,(cursorX)
                xor     a
                call    DisplayCursor

                ;;
                ;; X cursor
                ;;

                call    Doc_LineOffset          ; HL = offset into current line
                ld      (CursorPoint),hl
                ld      hl,(dx)
                ld      (StartPoint),hl
                ld      a,80
                add     hl,a
                ld      (EndPoint),hl
                call    ProcessAxis

                ld      hl,(OutOffset)
                ld      (dx),hl
                ld      hl,(OutCursor)
                ld      a,l
                ld      (cursorX),a

                ;;
                ;; Y Cursor
                ;;

                ld      hl,(cursorLine)
                ld      (CursorPoint),hl
                ld      hl,(topLine)
                ld      (StartPoint),hl
                ld      a,30
                add     hl,a
                ld      (EndPoint),hl
                call    ProcessAxis

                ;#todo - Adjust top and topline to meet OutOffset
                ld      hl,(OutCursor)
                inc     l
                ld      a,l
                ld      (cursorY),a

                ;;
                ;; End
                ;;
                ld      hl,0
                ld      (Counter),hl            ; Ensure the cursor is visible
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Commands

MoveLeft:
                call    Doc_LineOffset
                jp      z,CursorVisible         ; At beginning of document

                call    Doc_LineOffset
                jr      z,.at_edge              ; Left side of line?

                ld      de,1
                call    Doc_MoveBack
                jp      CursorVisible

.at_edge:
                ;#todo
                ;Move cursor up and to the end
                ret

;;----------------------------------------------------------------------------------------------------------------------

MoveRight:
                call    Doc_FetchChar
                cp      EOF                     ; End of file?
                ret     z                       ; Yes, no cursor movement

                cp      EOL                     ; End of line?
                jr      nz,.move_cursor

                ;#todo
                ;Move cursor down and to the beginning of the line
                ret

.move_cursor    ld      de,1
                call    Doc_MoveForward
                jp      CursorVisible           ; Make it visible again

;;----------------------------------------------------------------------------------------------------------------------

MoveUp:
                ret

;;----------------------------------------------------------------------------------------------------------------------

MoveDown:
                ret

;;----------------------------------------------------------------------------------------------------------------------

MoveHome:
                call    Doc_LineOffset
                ex      de,hl
                call    Doc_MoveBack
                jp      CursorVisible

;;----------------------------------------------------------------------------------------------------------------------

MoveEnd:        call    Doc_ToNextLine
                ld      d,b
                ld      e,c
                call    Doc_MoveForward
                jp      CursorVisible

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------

        message "Final address: ",PC
