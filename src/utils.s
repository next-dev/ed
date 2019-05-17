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

