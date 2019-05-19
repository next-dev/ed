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
        ;
        ;#todo
                push    af
                ld      a,$c0
                add     a,h
                ld      h,a
                pop     af
                ret

RealToVirt:
        ; Convert a real address to a virtual mark.
        ;
        ; Input:
        ;       HL = real address
        ; Output:
        ;       HL = virtual mark
        ;
        ;#todo
                push    af
                ld      a,h
                sub     $c0
                ld      h,a
                pop     af
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Circular buffer

BUFFER_START    equ     $0100

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
                ; Input:
                ;       B = Buffer page
                ;       C = Value to insert
                ;       IX = Pointer to read/write pointers
                ; Note:
                ;       The value that IX points to must be a 16-bit value initialised to BUFFER_START
                ;
                push    hl
                push    af

                ld      a,(ix+0)
                cp      (ix+1)          ; Has PWrite reached PRead yet?
                ret     z               ; Return without error (buffer is full)

                ld      l,(ix+1)
                ld      h,b             ; HL = write address
                ld      (hl),c          ; write value in buffer
                inc     (ix+1)
                pop     af
                pop     hl
                ret

BufferRead:     ; Input:
                ;       B = Buffer page
                ;       IX = Pointer to read/write pointers
                ; Output
                ;       A = Value
                ;       B = Buffer page
                ;       ZF = 1 if nothing to read
                ; Note:
                ;       The value that IX points to must be a 16-bit value initialised to BUFFER_START
                ;
                push    hl
                ld      a,(ix+1)
                dec     a
                cp      (ix+0)            ; Buffer is empty?
                jr      z,.finish

                inc     (ix+0)            ; Advance read pointer
                ld      l,(ix+0)
                ld      h,b             ; HL = buffer pointer
                ld      a,(hl)          ; Read data
                and     a               ; Clear ZF
.finish         pop     hl
                ret


