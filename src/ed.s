;;----------------------------------------------------------------------------------------------------------------------
;; Next Editor
;;----------------------------------------------------------------------------------------------------------------------

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

        ;org     $6000

        ;incbin  "data/font.bin"

;;----------------------------------------------------------------------------------------------------------------------
;; Sample text

        ;org     $c000

        ;incbin  "data/test.txt"
        ;db      EOF

textlen equ * - $c000


;;----------------------------------------------------------------------------------------------------------------------
;; This ORGs at $7f00

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
        include "src/memory.s"

;;----------------------------------------------------------------------------------------------------------------------
;; Main
;; The main loop

Main:
                call    ClearScreen

        ;;--------------------------------------------------------------------------------------------------------------
        ;; Test code
        ;;--------------------------------------------------------------------------------------------------------------
                
                BREAK
                call    arena_new

                call    arena_done

        ;;--------------------------------------------------------------------------------------------------------------
        ;;--------------------------------------------------------------------------------------------------------------
        

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
        ; Output:
        ;       A = character under cursor
                push    hl
                ld      hl,(pos)
                call    VirtToReal
                ld      a,(hl)
                pop     hl
                ret

Doc_AtStartDoc:
        ; Output:
        ;       ZF = 1 if at start of doc
        ; Uses:
        ;       A
        ;
                push    hl
                ld      hl,(pos)
                ld      a,h
                or      l
                pop     hl
                ret

Doc_AtEndDoc:
        ; Output:
        ;       ZF = 1 if at end of doc
        ;       A = current character
        ;
                call    Doc_FetchChar
                cp      EOF
                ret

Doc_LineOffset:
        ; Output:
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
        ; Output:
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
        ; Output:
        ;       ZF = 1 if at end of line
        ;       CF = 0
        ;       A = Current character under cursor
        ;
                call    Doc_FetchChar
                cp      EOL
                ret

Doc_MoveBack:
        ; Will not move past start of document
        ; Input:
        ;       DE = number of places to move
        ;
                ; Check the trivial case of not moving any places
                push    af
                ld      a,d
                or      e
                jr      nz,.not0        ; Return if DE == 0
                pop     af
                ret

                ; Check to see if moving back doesn't go past beginning of document.  If so,
                ; clamp it at the beginning.
.not0           push    de
                push    hl
                ld      hl,(pos)
                and     a
                sbc     hl,de
                jr      nc,.ok          ; Jump if there was room to move back that amount
                ld      hl,0
                ld      (linepos),hl
                jr      UpdatePos

                ; We can move back DE number of places
.ok             ld      hl,(pos)        ; HL = current position

.l1             dec     hl
                ld      (pos),hl
                call    Doc_FetchChar   ; Get the current character under pos
                cp      EOL             ; Reached end of line?
                jr      z,.eol          ; Yes, we need to update linepos and cursor

.cont           dec     de
                ld      a,d
                or      e
                jr      nz,.l1          ; Keep moving DE places
                jr      UpdatePos

.eol            ; We've passed a $0d character, and so we need to adjust linepos and cursor
                push    hl              ; Store current position

.l2             ld      a,h
                or      l               ; HL = beginning of document?
                jr      nz,.search

.update         ld      (linepos),hl    ; Update beginning of line position
                ld      hl,(cursorLine)
                dec     hl
                ld      (cursorLine),hl
                pop     hl
                jr      .cont           ; Keep moving back

.search         dec     hl
                ld      (pos),hl
                call    Doc_FetchChar
                cp      EOL
                jr      nz,.l2          ; Keep searching back
                inc     hl              ; Go back to beginning of next line
                jr      .update

                ; Update the position and clean up
UpdatePos:      ld      (pos),hl
                pop     hl
                pop     de
                pop     af
                ret

                
Doc_MoveForward:
        ; Move forward DE places in document.  Will not move past end of document.
        ; Input:
        ;       DE = number of places to move
        ;
                ; Check the trivial case of not moving any places
                push    af
                ld      a,d
                or      e
                jr      nz,.not0        ; Return if DE == 0
                pop     af
                ret

.not0           ; Lets try to move forward.
                push    de
                push    hl
                ld      hl,(pos)

.l1             ld      (pos),hl
                call    Doc_FetchChar
                cp      EOF             ; End of file before we even begin?
                jr      z,UpdatePos

                inc     hl              ; Move to next position
                cp      EOL             ; If EOL, update linepos and cursorLine
                jr      nz,.no_eol

                push    hl
                ld      (linepos),hl
                ld      hl,(cursorLine)
                inc     hl
                ld      (cursorLine),hl
                pop     hl

.no_eol         dec     de
                ld      a,d
                or      e
                jr      nz,.l1

                jr      UpdatePos

;;----------------------------------------------------------------------------------------------------------------------
;; CursorVisible
;; Manipulates top, dx, cursorX, cursorY to ensure cursor is on screen.  Only does something if the cursor is currently
;; off-screen

StartPoint      dw      0       ; Start range of screen on axis
EndPoint        dw      0       ; End range of screen on axis
CursorPoint     dw      0       ; Current cursor position

OutOffset       dw      0       ; Offset required to keep cursor on screen
OutCursor       dw      0       ; Cursor position from top of screen

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
                ld      (OutOffset),hl          ; New offset

                ex      de,hl                   ; DE = offset
                ld      hl,(CursorPoint)        ; HL = cursor point
                and     a
                sbc     hl,de                   ; HL = relative cursor position
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

                ; Scroll up or scroll down?
                ld      hl,(topLine)
                ld      de,(OutOffset)
                ld      (topLine),de
                and     a
                sbc     hl,de                   ; topLine < OutOffset
                jr      c,.scroll_down          ; Yes, need to scroll downwards from topLine to OutOffset
                jr      z,.no_scroll            ; No scrolling required

                ; topLine > OutOffset, which means we have to scroll upwards
                ; HL = number of lines to scroll
                ld      c,l
                ld      b,h
                ld      hl,(pos)
                push    hl                      ; Store position
                ld      hl,(linepos)
                push    hl
                ld      hl,(cursorLine)
                push    hl
                ld      hl,(top)
                ld      (pos),hl

.l1             ld      hl,(pos)
                dec     hl                      ; Move to end of previous line
                ld      (pos),hl
                call    Doc_LineOffset          ; HL = number of characters in line
                ex      de,hl
                call    Doc_MoveBack            ; Move to beginning of line
                dec     bc
                ld      a,b
                or      c
                jr      nz,.l1

.update_top     ld      hl,(pos)
                ld      (top),hl
                pop     hl
                ld      (cursorLine),hl
                pop     hl
                ld      (linepos),hl
                pop     hl
                ld      (pos),hl                ; Restore position
                jr      .no_scroll

.scroll_down    ; topLine < OutOffset, which means we have to scroll downwards
                ld      c,l
                ld      b,h

                ; Store current position, since we're going to move the cursor to the top of the
                ; screen to do the adjustments
                ld      hl,(pos)
                push    hl
                ld      hl,(linepos)
                push    hl
                ld      hl,(cursorLine)
                push    hl
                ld      hl,(top)
                ld      (pos),hl

.l2             push    bc
                call    Doc_ToNextLine          ; BC = length of line
                ld      e,c
                ld      d,b
                inc     de
                call    Doc_MoveForward         ; Move to beginning of next line
                pop     bc
                inc     bc
                ld      a,b
                or      c
                jr      nz,.l2
                jr      .update_top

.no_scroll:     ; topLine is now in the right place
                ld      hl,(OutCursor)
                inc     hl                      ; HL = Cursor Y position, +1 to skip title
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
                call    Doc_AtStartDoc
                jp      z,CursorVisible         ; At beginning of document

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

                ld      de,1
                call    Doc_MoveForward
                jp      CursorVisible           ; Make it visible again

;;----------------------------------------------------------------------------------------------------------------------

LastX           dw      0

MoveUp:
                ;#todo - Make the cursor return to original horizontal position if possible
                call    Doc_LineOffset          ; HL = horizontal position
                ld      (LastX),hl              ; Store it

                ; Move to beginning of line
                ex      de,hl
                inc     de
                call    Doc_MoveBack            ; Move back to end of previous line
                call    Doc_AtStartDoc          ; At beginning of doc?
                jp      z, CursorVisible        ; Yes, move no more!

                call    Doc_LineOffset          ; HL = size of previous line
                ld      de,(LastX)
                and     a
                sbc     hl,de                   ; HL >= DE is good!  HL = distance to move back
                jr      c,.done

                ex      de,hl
                call    Doc_MoveBack
.done           jp      CursorVisible

;;----------------------------------------------------------------------------------------------------------------------

MoveDown:
                ;#todo - Make the cursor return to original horizontal position if possible
                call    Doc_LineOffset
                ld      (LastX),hl              ; Store the horizontal position
                call    Doc_ToNextLine
                ld      d,b
                ld      e,c
                call    Doc_MoveForward         ; Jump to the end of the line
                call    Doc_FetchChar           ; Is it an EOF?
                cp      EOF
                jp      z,CursorVisible         ; Yes, go no further

                ld      de,1
                call    Doc_MoveForward         ; Move to beginning of next line
                call    Doc_ToNextLine          ; BC = length of line
                ld      hl,(LastX)              ; HL = intended position
                ld      d,b
                ld      e,c                     ; DE = line length
                call    Max                     ; DE = actual position
                call    Doc_MoveForward

                jp      CursorVisible

;;----------------------------------------------------------------------------------------------------------------------

MoveHome:
                call    Doc_LineOffset
                ex      de,hl
                call    Doc_MoveBack
                jp      CursorVisible

;;----------------------------------------------------------------------------------------------------------------------

MoveEnd:        
                call    Doc_ToNextLine
                ld      d,b
                ld      e,c
                call    Doc_MoveForward
                jp      CursorVisible

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------

        message "Final address: ",PC

        savenex "ed.nex",Start,$c000
