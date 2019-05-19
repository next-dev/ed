;;----------------------------------------------------------------------------------------------------------------------
;; Editor's command tables
;; This is a vector of routine addresses linked to each key press
;;----------------------------------------------------------------------------------------------------------------------

DoNothing:
        ret

CallHL:
        jp      (hl)

ModeTable:
        dw      NormalCmdTable                  ; Mode 0 - Normal
        dw      NormalCmdTable                  ; Mode 0 - Insert
        dw      NormalCmdTable                  ; Mode 0 - Select
        dw      NormalCmdTable                  ; Mode 0 - Line select

;;----------------------------------------------------------------------------------------------------------------------
;; Normal mode commands table
;;----------------------------------------------------------------------------------------------------------------------

NormalCmdTable:
        dw      DoNothing                       ; 00
        dw      DoNothing                       ; 01 - Edit
        dw      DoNothing                       ; 02 - Caps Lock
        dw      DoNothing                       ; 03 - True Video
        dw      DoNothing                       ; 04 - Inv Video
        dw      Cmd_CursorLeft                  ; 05 - Left
        dw      Cmd_CursorDown                  ; 06 - Down
        dw      Cmd_CursorUp                    ; 07 - Up
        dw      Cmd_CursorRight                 ; 08 - Right
        dw      DoNothing                       ; 09 - Graph/TAB
        dw      DoNothing                       ; 0a - Delete
        dw      DoNothing                       ; 0b
        dw      DoNothing                       ; 0c
        dw      DoNothing                       ; 0d - Enter
        dw      DoNothing                       ; 0e
        dw      DoNothing                       ; 0f - Extended Mode

        dw      DoNothing                       ; 10 - Sym+W
        dw      DoNothing                       ; 11 - Sym+I
        dw      DoNothing                       ; 12 - Sym+E
        dw      DoNothing                       ; 13
        dw      DoNothing                       ; 14
        dw      DoNothing                       ; 15
        dw      DoNothing                       ; 16
        dw      DoNothing                       ; 17
        dw      DoNothing                       ; 18
        dw      DoNothing                       ; 19
        dw      DoNothing                       ; 1a
        dw      DoNothing                       ; 1b - Break
        dw      DoNothing                       ; 1c - Sym+Space
        dw      DoNothing                       ; 1d - Shift+Enter
        dw      DoNothing                       ; 1e - Sym+Enter
        dw      DoNothing                       ; 1f - Ext+Enter

        dw      DoNothing                       ; 20 - Space
        dw      DoNothing                       ; 21 - !
        dw      DoNothing                       ; 22 - "
        dw      DoNothing                       ; 23 - #
        dw      DoNothing                       ; 24 - $
        dw      DoNothing                       ; 25 - %
        dw      DoNothing                       ; 26 - &
        dw      DoNothing                       ; 27 - '
        dw      DoNothing                       ; 28 - (
        dw      DoNothing                       ; 29 - )
        dw      DoNothing                       ; 2a - *
        dw      DoNothing                       ; 2b - +
        dw      DoNothing                       ; 2c - ,
        dw      DoNothing                       ; 2d - -
        dw      DoNothing                       ; 2e - .
        dw      DoNothing                       ; 2f - /

        dw      DoNothing                       ; 30 - 0
        dw      DoNothing                       ; 31 - 1
        dw      DoNothing                       ; 32 - 2
        dw      DoNothing                       ; 33 - 3
        dw      DoNothing                       ; 34 - 4
        dw      DoNothing                       ; 35 - 5
        dw      DoNothing                       ; 36 - 6
        dw      DoNothing                       ; 37 - 7
        dw      DoNothing                       ; 38 - 8
        dw      DoNothing                       ; 39 - 9
        dw      DoNothing                       ; 3a - :
        dw      DoNothing                       ; 3b - ;
        dw      DoNothing                       ; 3c - <
        dw      DoNothing                       ; 3d - =
        dw      DoNothing                       ; 3e - >
        dw      DoNothing                       ; 3f - ?

        dw      DoNothing                       ; 40 - @
        dw      DoNothing                       ; 41 - A
        dw      DoNothing                       ; 42 - B
        dw      DoNothing                       ; 43 - C
        dw      DoNothing                       ; 44 - D
        dw      DoNothing                       ; 45 - E
        dw      DoNothing                       ; 46 - F
        dw      DoNothing                       ; 47 - G
        dw      DoNothing                       ; 48 - H
        dw      DoNothing                       ; 49 - I
        dw      DoNothing                       ; 4a - J
        dw      DoNothing                       ; 4b - K
        dw      DoNothing                       ; 4c - L
        dw      DoNothing                       ; 4d - M
        dw      DoNothing                       ; 4e - N
        dw      DoNothing                       ; 4f - O

        dw      DoNothing                       ; 50 - P
        dw      DoNothing                       ; 51 - Q
        dw      DoNothing                       ; 52 - R
        dw      DoNothing                       ; 53 - S
        dw      DoNothing                       ; 54 - T
        dw      DoNothing                       ; 55 - U
        dw      DoNothing                       ; 56 - V
        dw      DoNothing                       ; 57 - W
        dw      DoNothing                       ; 58 - X
        dw      DoNothing                       ; 59 - Y
        dw      DoNothing                       ; 5a - Z
        dw      DoNothing                       ; 5b - [
        dw      DoNothing                       ; 5c - \
        dw      DoNothing                       ; 5d - ]
        dw      DoNothing                       ; 5e - ^
        dw      DoNothing                       ; 5f - _

        dw      DoNothing                       ; 60 - Pound sign
        dw      DoNothing                       ; 61 - a
        dw      DoNothing                       ; 62 - b
        dw      DoNothing                       ; 63 - c
        dw      DoNothing                       ; 64 - d
        dw      DoNothing                       ; 65 - e
        dw      DoNothing                       ; 66 - f
        dw      DoNothing                       ; 67 - g
        dw      BufferInsert                    ; 68 - h
        dw      DoNothing                       ; 69 - i
        dw      BufferInsert                    ; 6a - j
        dw      BufferInsert                    ; 6b - k
        dw      BufferInsert                    ; 6c - l
        dw      DoNothing                       ; 6d - m
        dw      DoNothing                       ; 6e - n
        dw      DoNothing                       ; 6f - o

        dw      DoNothing                       ; 70 - p
        dw      DoNothing                       ; 71 - q
        dw      DoNothing                       ; 72 - r
        dw      DoNothing                       ; 73 - s
        dw      DoNothing                       ; 74 - t
        dw      DoNothing                       ; 75 - u
        dw      DoNothing                       ; 76 - v
        dw      DoNothing                       ; 77 - w
        dw      DoNothing                       ; 78 - x
        dw      DoNothing                       ; 79 - y
        dw      DoNothing                       ; 7a - z
        dw      DoNothing                       ; 7b - {
        dw      DoNothing                       ; 7c - |
        dw      DoNothing                       ; 7d - }
        dw      DoNothing                       ; 7e - ~
        dw      DoNothing                       ; 7f - (C)

        dw      DoNothing                       ; 80
        dw      DoNothing                       ; 81
        dw      DoNothing                       ; 82
        dw      DoNothing                       ; 83
        dw      DoNothing                       ; 84
        dw      DoNothing                       ; 85
        dw      DoNothing                       ; 86
        dw      DoNothing                       ; 87
        dw      DoNothing                       ; 88
        dw      DoNothing                       ; 89
        dw      DoNothing                       ; 8a
        dw      DoNothing                       ; 8b
        dw      DoNothing                       ; 8c
        dw      DoNothing                       ; 8d
        dw      DoNothing                       ; 8e
        dw      DoNothing                       ; 8f

        dw      DoNothing                       ; 90
        dw      DoNothing                       ; 91
        dw      DoNothing                       ; 92
        dw      DoNothing                       ; 93
        dw      DoNothing                       ; 94
        dw      DoNothing                       ; 95
        dw      DoNothing                       ; 96
        dw      DoNothing                       ; 97
        dw      DoNothing                       ; 98
        dw      DoNothing                       ; 99
        dw      DoNothing                       ; 9a
        dw      DoNothing                       ; 9b
        dw      DoNothing                       ; 9c
        dw      DoNothing                       ; 9d
        dw      DoNothing                       ; 9e
        dw      DoNothing                       ; 9f

        dw      DoNothing                       ; a0
        dw      DoNothing                       ; a1
        dw      DoNothing                       ; a2
        dw      DoNothing                       ; a3
        dw      DoNothing                       ; a4
        dw      DoNothing                       ; a5
        dw      DoNothing                       ; a6
        dw      DoNothing                       ; a7
        dw      DoNothing                       ; a8
        dw      DoNothing                       ; a9
        dw      DoNothing                       ; aa
        dw      DoNothing                       ; ab
        dw      DoNothing                       ; ac
        dw      DoNothing                       ; ad
        dw      DoNothing                       ; ae
        dw      DoNothing                       ; af

        dw      DoNothing                       ; b0 - Ext+0
        dw      DoNothing                       ; b1 - Ext+1
        dw      DoNothing                       ; b2 - Ext+2
        dw      DoNothing                       ; b3 - Ext+3
        dw      DoNothing                       ; b4 - Ext+4
        dw      DoNothing                       ; b5 - Ext+5
        dw      DoNothing                       ; b6 - Ext+6
        dw      DoNothing                       ; b7 - Ext+7
        dw      DoNothing                       ; b8 - Ext+8
        dw      DoNothing                       ; b9 - Ext+9
        dw      DoNothing                       ; ba
        dw      DoNothing                       ; bb
        dw      DoNothing                       ; bc
        dw      DoNothing                       ; bd
        dw      DoNothing                       ; be
        dw      DoNothing                       ; bf

        dw      DoNothing                       ; c0
        dw      DoNothing                       ; c1
        dw      DoNothing                       ; c2
        dw      DoNothing                       ; c3
        dw      DoNothing                       ; c4
        dw      DoNothing                       ; c5
        dw      DoNothing                       ; c6
        dw      DoNothing                       ; c7
        dw      DoNothing                       ; c8
        dw      DoNothing                       ; c9
        dw      DoNothing                       ; ca
        dw      DoNothing                       ; cb
        dw      DoNothing                       ; cc
        dw      DoNothing                       ; cd
        dw      DoNothing                       ; ce
        dw      DoNothing                       ; cf

        dw      DoNothing                       ; d0
        dw      DoNothing                       ; d1
        dw      DoNothing                       ; d2
        dw      DoNothing                       ; d3
        dw      DoNothing                       ; d4
        dw      DoNothing                       ; d5
        dw      DoNothing                       ; d6
        dw      DoNothing                       ; d7
        dw      DoNothing                       ; d8
        dw      DoNothing                       ; d9
        dw      DoNothing                       ; da
        dw      DoNothing                       ; db
        dw      DoNothing                       ; dc
        dw      DoNothing                       ; dd
        dw      DoNothing                       ; de
        dw      DoNothing                       ; df

        dw      DoNothing                       ; e0
        dw      DoNothing                       ; e1 - Ext+a
        dw      DoNothing                       ; e2 - Ext+b
        dw      DoNothing                       ; e3 - Ext+c
        dw      DoNothing                       ; e4 - Ext+d
        dw      DoNothing                       ; e5 - Ext+e
        dw      DoNothing                       ; e6 - Ext+f
        dw      DoNothing                       ; e7 - Ext+g
        dw      DoNothing                       ; e8 - Ext+h
        dw      DoNothing                       ; e9 - Ext+i
        dw      DoNothing                       ; ea - Ext+j
        dw      DoNothing                       ; eb - Ext+k
        dw      DoNothing                       ; ec - Ext+l
        dw      DoNothing                       ; ed - Ext+m
        dw      DoNothing                       ; ee - Ext+n
        dw      DoNothing                       ; ef - Ext+o

        dw      DoNothing                       ; f0 - Ext+p
        dw      DoNothing                       ; f1 - Ext+q
        dw      DoNothing                       ; f2 - Ext+r
        dw      DoNothing                       ; f3 - Ext+s
        dw      DoNothing                       ; f4 - Ext+t
        dw      DoNothing                       ; f5 - Ext+u
        dw      DoNothing                       ; f6 - Ext+v
        dw      DoNothing                       ; f7 - Ext+w
        dw      DoNothing                       ; f8 - Ext+x
        dw      DoNothing                       ; f9 - Ext+y
        dw      DoNothing                       ; fa - Ext+z
        dw      DoNothing                       ; fb
        dw      DoNothing                       ; fc
        dw      DoNothing                       ; fd
        dw      DoNothing                       ; fe
        dw      DoNothing                       ; ff

;;----------------------------------------------------------------------------------------------------------------------
;; Interpreter command table
;;----------------------------------------------------------------------------------------------------------------------

MainCmdTable:
        dw      DoNothing                       ; 20 - Space
        dw      DoNothing                       ; 21 - !
        dw      DoNothing                       ; 22 - "
        dw      DoNothing                       ; 23 - #
        dw      DoNothing                       ; 24 - $
        dw      DoNothing                       ; 25 - %
        dw      DoNothing                       ; 26 - &
        dw      DoNothing                       ; 27 - '
        dw      DoNothing                       ; 28 - (
        dw      DoNothing                       ; 29 - )
        dw      DoNothing                       ; 2a - *
        dw      DoNothing                       ; 2b - +
        dw      DoNothing                       ; 2c - ,
        dw      DoNothing                       ; 2d - -
        dw      DoNothing                       ; 2e - .
        dw      DoNothing                       ; 2f - /

        dw      DoNothing                       ; 30 - 0
        dw      DoNothing                       ; 31 - 1
        dw      DoNothing                       ; 32 - 2
        dw      DoNothing                       ; 33 - 3
        dw      DoNothing                       ; 34 - 4
        dw      DoNothing                       ; 35 - 5
        dw      DoNothing                       ; 36 - 6
        dw      DoNothing                       ; 37 - 7
        dw      DoNothing                       ; 38 - 8
        dw      DoNothing                       ; 39 - 9
        dw      DoNothing                       ; 3a - :
        dw      DoNothing                       ; 3b - ;
        dw      DoNothing                       ; 3c - <
        dw      DoNothing                       ; 3d - =
        dw      DoNothing                       ; 3e - >
        dw      DoNothing                       ; 3f - ?

        dw      DoNothing                       ; 40 - @
        dw      DoNothing                       ; 41 - A
        dw      DoNothing                       ; 42 - B
        dw      DoNothing                       ; 43 - C
        dw      DoNothing                       ; 44 - D
        dw      DoNothing                       ; 45 - E
        dw      DoNothing                       ; 46 - F
        dw      DoNothing                       ; 47 - G
        dw      DoNothing                       ; 48 - H
        dw      DoNothing                       ; 49 - I
        dw      DoNothing                       ; 4a - J
        dw      DoNothing                       ; 4b - K
        dw      DoNothing                       ; 4c - L
        dw      DoNothing                       ; 4d - M
        dw      DoNothing                       ; 4e - N
        dw      DoNothing                       ; 4f - O

        dw      DoNothing                       ; 50 - P
        dw      DoNothing                       ; 51 - Q
        dw      DoNothing                       ; 52 - R
        dw      DoNothing                       ; 53 - S
        dw      DoNothing                       ; 54 - T
        dw      DoNothing                       ; 55 - U
        dw      DoNothing                       ; 56 - V
        dw      DoNothing                       ; 57 - W
        dw      DoNothing                       ; 58 - X
        dw      DoNothing                       ; 59 - Y
        dw      DoNothing                       ; 5a - Z
        dw      DoNothing                       ; 5b - [
        dw      DoNothing                       ; 5c - \
        dw      DoNothing                       ; 5d - ]
        dw      DoNothing                       ; 5e - ^
        dw      DoNothing                       ; 5f - _

        dw      DoNothing                       ; 60 - Pound sign
        dw      DoNothing                       ; 61 - a
        dw      DoNothing                       ; 62 - b
        dw      DoNothing                       ; 63 - c
        dw      DoNothing                       ; 64 - d
        dw      DoNothing                       ; 65 - e
        dw      DoNothing                       ; 66 - f
        dw      DoNothing                       ; 67 - g
        dw      MoveLeft                        ; 68 - h
        dw      DoNothing                       ; 69 - i
        dw      MoveDown                        ; 6a - j
        dw      MoveUp                          ; 6b - k
        dw      MoveRight                       ; 6c - l
        dw      DoNothing                       ; 6d - m
        dw      DoNothing                       ; 6e - n
        dw      DoNothing                       ; 6f - o

        dw      DoNothing                       ; 70 - p
        dw      DoNothing                       ; 71 - q
        dw      DoNothing                       ; 72 - r
        dw      DoNothing                       ; 73 - s
        dw      DoNothing                       ; 74 - t
        dw      DoNothing                       ; 75 - u
        dw      DoNothing                       ; 76 - v
        dw      DoNothing                       ; 77 - w
        dw      DoNothing                       ; 78 - x
        dw      DoNothing                       ; 79 - y
        dw      DoNothing                       ; 7a - z
        dw      DoNothing                       ; 7b - {
        dw      DoNothing                       ; 7c - |
        dw      DoNothing                       ; 7d - }
        dw      DoNothing                       ; 7e - ~
        dw      DoNothing                       ; 7f - (C)
