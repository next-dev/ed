;;----------------------------------------------------------------------------------------------------------------------
;; Various utilities required throughout all the source code
;;----------------------------------------------------------------------------------------------------------------------

;;----------------------------------------------------------------------------------------------------------------------
;; Cursor management

VirtToReal:
        ; Convert a virtual mark to a real mark.  Virtual marks represent an offset into the document.
        ; Real marks are actual offsets into the memory the document resides and respects the buffer gap.
        ;
        ; Input:
        ;   HL = virtual mark
        ; Output:
        ;   HL = real mark
        ret

;;----------------------------------------------------------------------------------------------------------------------
;; Circular buffer - uses the print buffer at $5b00

PRead   db      0       ; Offset in buffer of read point (should be <= PWrite)
PWrite  db      1       ; Offset in buffer of write point

; Empty buffer:
;
;       +-------------------------------------------+
;                       ^^
;                       RW
;
;       R points to just before read point
;       W points at new place to write
;       R should never meet W while reading
;
; Full buffer
;       +XXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXX+
;                       ^
;                       R
;                       W

BufferInsert:
                ; Input
                ;       B = Buffer page
                ;       C = Value to insert
                push    hl
                push    af

                ld      a,(PRead)
                ld      hl,PWrite
                cp      (hl)            ; Has PWrite reached PRead yet?
                ret     z               ; Return without error (buffer is full)

                push    hl
                ld      l,(hl)
                ld      h,b             ; HL = write address
                ld      (hl),c          ; write value in buffer
                pop     hl
                inc     (hl)
                pop     af
                pop     hl
                ret

BufferRead:     ; Output
                ;       A = Value
                ;       B = Buffer page
                ;       ZF = 1 if nothing to read
                push    hl
                ld      a,(PWrite)
                dec     a
                ld      hl,PRead
                cp      (hl)            ; Buffer is empty?
                jr      z,.finish

                inc     (hl)            ; Advance read pointer
                ld      l,(hl)
                ld      h,b             ; HL = buffer pointer
                ld      a,(hl)          ; Read data
                and     a               ; Clear ZF
.finish         pop     hl
                ret


