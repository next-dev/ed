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

KeyScan:
        ld      bc,$fefe        ; First keyboard port
        ld      de,$0500        ; E = offset into key translation table
        ld      hl,$ffe0        ; Constants used in loop

        ; First row contains Caps-Shift
        in      a,(c)           ; Read first row
        or      %11100001       ; Disable the CAPS-Shift
        cp      h
        jr      nz,.keyhit_0    ; Key is pressed in this row

        ld      e,d
        rlc     b

.row_loop:
        in      a,(c)           ; Read keys
        or      l               ; Complete the 8 bits
        cp      h               ; Key pressed?
        jr      nz,.keyhit_0    ; Yes, jump

        ld      a,e
        add     a,d
        ld      e,a

        rlc     b               ; Next row
        jp      m,.row_loop     ; Do all the rest of the rows, except the last

        ; Last row contains SYM shift
        in      a,(c)
        or      %11100010       ; Disable sym-shift
        cp      h
        ld      c,a
        jr      nz,.keyhit_1    ; Jump if key pressed

        xor     a
        ld      h,a
        ld      l,a             ; ASCII 0, CF = 0
        ret

.keyhit_0:
        ; At least one row is active (ignoring shift keys)
        ; Make sure no other are active
        ;
        ld      c,a             ; C = key result

        ; B = key row containing keypress
        ; E = index into key translation table for row
        ; HL = $ffe0
        ; D = 5

        ld      a,b
        cpl                     ; A has bit which represents row
        or      $81             ; Ignore first and last rows (that contain shift keys)
        in      a,($fe)         ; Look at all the other rows
        or      l
        cp      h               ; Any other keys pressed?
        jp      nz,.error       ; More than one key (other than shift key) is pressed
        ld      a,$7f
        in      a,($fe)         ; Read SYM shift row
        or      %11100010       ; Ignore sym shift
        cp      h
        jr      z,.keyhit_1
.error:
        xor     a
        ld      h,a
        ld      l,a
        scf
        ret

.keyhit_1:
        ; Only one key row is active.  Determine ASCII code from translation table

        ; C = key result
        ; E = index into key translation table for row
        ; D = 5

        ld      b,0
        ld      hl,rowtable - $e0
        add     hl,bc
        ld      a,(hl)          ; One key press will be converted to 0-4
        cp      d
        jp      nc,.error       ; More than one key pressed!
        add     a,e
        ld      e,a             ; E = index into key translation table for key
        ld      hl,KeyTrans
        ld      d,b             ; D = 0
        add     hl,de

        ; Check shift modifiers
        ld      a,$fe
        in      a,($fe)
        and     1
        jr      nz,.check_sym   ; Caps-shift pressed
        ld      e,40
        add     hl,de           ; Look at the 2nd lot of mappings

.check_sym:
        ld      a,$7f
        in      a,($fe)
        and     2               ; Extract sym-shift
        jr      nz,.ascii       ; Not pressed
        ld      e,80
        add     hl,de           ; Look at 3rd or 4th lot of mappings

.ascii:
        ld      l,(hl)          ; L = ascii code
        ld      h,b             ; H = 0
        ret

RowTable:
        ;       11110 = 0
        ;       11101 = 1
        ;       11011 = 2
        ;       10111 = 3
        ;       01111 = 4
        ;       
        db      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff     ; 00xxx
        db      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$04     ; 01xxx
        db      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$03     ; 10xxx
        db      $ff,$ff,$ff,$02,$ff,$01,$00,$ff     ; 11xxx

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
