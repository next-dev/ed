;;----------------------------------------------------------------------------------------------------------------------
;; Current state of the editor

; Presentation state
mode            db      MODE_NORMAL
top             dw      0           ; Offset of character shown at start of top line
topLine         dw      0           ; Line number of top of screen
dx              dw      0           ; Indent
cursorX         db      0           ; Screen X coord of cursor
cursorY         db      1           ; Screen Y coord of cursor

; Buffer state
gapstart        dw      0           ; Offset into buffer of gap start
gapend          dw      0           ; Offset into buffer of gap end
linepos         dw      0           ; Virtual position in document of current line
pos             dw      0           ; Virtual position in document of cursor
cursorLine      dw      0           ; Line which cursor resides

; Commands
CmdBufferState  dw      BUFFER_START