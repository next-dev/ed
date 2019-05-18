;;----------------------------------------------------------------------------------------------------------------------
;; Keyboard routines
;; Lifted and adapated from:
;;
;; https://github.com/z88dk/z88dk/blob/master/libsrc/_DEVELOPMENT/input/zx/z80/asm_in_inkey.asm
;; https://github.com/z88dk/z88dk/blob/master/libsrc/_DEVELOPMENT/input/zx/z80/in_key_translation_table.asm
;;
;;----------------------------------------------------------------------------------------------------------------------


; Scans the keyboard and returns button code
;
; Output:
;   HL = ASCII code or 0 on no keys, or invalid
;   CF = 1 on error
; Destroys:
;   BC, DE, HL, A
;
; Rows are:
;   Bits:   0       1       2       3       4
;   ----------------------------------------------
;   $FE     Caps    Z       X       C       V
;   $FD     A       S       D       F       G
;   $FB     Q       W       E       R       T
;   $F7     1       2       3       4       5
;   $EF     0       9       8       7       6
;   $DF     P       O       I       U       Y
;   $BF     Enter   L       K       J       H
;   $7F     Space   Sym     M       N       B
;
; Keyboard ASCII codes (00-1F)
;
;   00                      10  Sym+W X
;   01  Edit                11  Sym+E X
;   02  Capslock            12  Sym+I X
;   03  True Video          13  
;   04  Inv Video           14  
;   05  Left                15  
;   06  Down                16  
;   07  Up                  17  
;   08  Right               18  
;   09  Graph/TAB           19  
;   0A  Delete              1A  
;   0B                      1B  Break (Caps & Space)
;   0C                      1C  (Sym & Space)
;   0D  Enter               1D  Shift+Enter
;   0E                      1E  Sym+Enter
;   0F  Ext X               1F  Ext+Enter X
;
; Keyboard ASCII codes (80-FF)
;
;   B0-B9 - Ext+Number
;   E1-FA - Ext+Letter

Keys:           ds      16      ; Double-buffered interleaved space to store the key presses
                                ; NEW OLD NEW OLD NEW OLD...
                                ; Thought about having a dynamic pointer to switch buffers but it turns out
                                ; that having fixed buffers makes things easier later on

KeyScan:
                ; Output:
                ;   HL = pointer to keyscan
                ; Destroys
                ;   BC, DE, A

                ld      hl,Keys

                ; Scan the keyboard
                ld      bc,$fdfe        ; Keyboard ports (start here to make sure shift rows are last)
                push    hl
                ld      e,8             ; Checksum to know when to end loop

.l1             ld      d,(hl)          ; Get old state
                in      a,(c)
                cpl
                and     $1f
                ld      (hl),a          ; Store new state
                inc     hl
                ld      (hl),d          ; Store old state
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

.l1             ld      a,(hl)
                inc     hl
                inc     hl
                push    hl
                ld      l,5
.l2             srl     a
                ld      d,a
                push    de          ; Save outer loop counter
                jr      c,.pressed
                ld      de,$0000
                jr      .cont
.pressed
                ld      de,$0100
.cont           push    bc          ; Save coords
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

Key:            db      0               ; Latest ASCII character
KFlags:         db      0               ; Bit 0 = character available, reset when test

ImRoutine:
                push    af
                push    bc
                push    de
                push    hl
                push    ix
                call    KeyScan         ; HL = Keyboard table

                ; Update shift statuses
                push    hl
                pop     ix
                xor     a
                bit     0,(ix+14)       ; Test for Caps (row 7 * 2 bytes)
                jr      z,.no_caps
                or      40
.no_caps        bit     1,(ix+12)       ; Test for symbol shift (row 6 * 2 bytes)
                jr      z,.no_sym
                or      80
.no_sym         ex      de,hl           ; DE = keyboard snapshot
                add     hl,KeyTrans
                add     hl,a            ; HL = Key translation table

.cont:
                ; Now we scan our keyboard snapshot, and any keys that are detected to be pressed are added to
                ; the circular buffer
                ld      b,8
.row            ld      a,(de)          ; A = keyboard state for current row
                inc     de
                ld      c,a             ; C = keyboard state for current row
                ld      a,(de)          ; A = last keyboard state
                inc     de
                xor     $ff
                and     c               ; A = edge detected key state (!A + C)
                push    hl              ; Store the current key translation table position

.col            and     a               ; Any keys pressed on entire row?
                jr      z,.end_row

                srl     a               ; Key pressed?
                jr      nc,.not_pressed

                ld      c,(hl)          ; C = ASCII character
                inc     c               ; C == $ff?
                jr      z,.ignore
                dec     c
                call    BufferInsert    ; Insert into circular buffer
.ignore         inc     hl              ; Next entry into table
                jr      .col

.end_row        ld      a,5
                pop     hl
                add     hl,n            ; Next row of table
                djnz    .row

                ; Fetch a character
                ld      hl,KFlags
                bit     0,(hl)
                jr      nz,.finish      ; Still haven't processed last key yet

                call    BufferRead
                jr      z,.no_chars
                ld      (Key),a         ; Next key available
                set     0,(hl)          ; Key ready!
                jr      .finish

.no_chars       xor     a
                ld      (Key),a

.finish
                pop     ix
                pop     hl
                pop     de
                pop     bc
                pop     af
                reti

;;----------------------------------------------------------------------------------------------------------------------

KeyTrans:
        ; Unshifted
        db      $ff,'z','x','c','v'
        db      'a','s','d','f','g'
        db      'q','w','e','r','t'
        db      '1','2','3','4','5'
        db      '0','9','8','7','6'
        db      'p','o','i','u','y'
        db      $0d,'l','k','j','h'
        db      ' ',$ff,'m','n','b'

        ; CAPS shifted
        db      $ff,'Z','X','C','V'
        db      'A','S','D','F','G'
        db      'Q','W','E','R','T'
        db      $01,$02,$03,$04,$05
        db      $0a,$09,$08,$07,$06
        db      'P','O','I','U','Y'
        db      $1d,'L','K','J','H'
        db      $1b,$ff,'M','N','B'

        ; SYM shifted
        db      $ff,':','`','?','/'
        db      '~','|','\','{','}'
        db      $7f,'w','e','<','>'
        db      '!','@','#','$','%'
        db      '_',')','(',$27,'&'
        db      $22,';','i',']','['
        db      $1e,'=','+','-','^'
        db      $1c,$ff,'.',',','*'

        ; EXT shifted
        db      $ff,    'z'+$80,'x'+$80,'c'+$80,'v'+$80
        db      'a'+$80,'s'+$80,'d'+$80,'f'+$80,'g'+$80
        db      'q'+$80,'w'+$80,'e'+$80,'r'+$80,'t'+$80
        db      '1'+$80,'2'+$80,'3'+$80,'4'+$80,'5'+$80
        db      '0'+$80,'9'+$80,'8'+$80,'7'+$80,'6'+$80
        db      'p'+$80,'o'+$80,'i'+$80,'u'+$80,'y'+$80
        db      $0d,    'l'+$80,'k'+$80,'j'+$80,'h'+$80
        db      ' ',    $ff,    'm'+$80,'n'+$80,'b'+$80

;;----------------------------------------------------------------------------------------------------------------------
;; Inkey
;; Uses the KeyScan routine to get raw input but ensures that a button is released before the next one is registerd

LastKey db      0

Inkey:
        ; Output:
        ;       A = ASCII character or 0 if no key pressed/error
        ;       CF = Key pressed
        push    hl
        push    de
        push    bc
        call    KeyScan
        jr      c,.no_key               ; Error occurred!
        ld      a,l
        cp      h                       ; Key pressed?
        jr      z,.no_key               ; Nope!
        ld      a,(LastKey)
        cp      l                       ; Same as last key?
        jr      z,.same_key

        ; New key pressed
        ld      a,l
        scf
        jr      .set_key

.no_key:
        xor     a
.set_key:
        ld     (LastKey),a
.same_key:
        pop     bc
        pop     de
        pop     hl
        ret
