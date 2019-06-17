;;----------------------------------------------------------------------------------------------------------------------
;; Memory management
;;
;; This will manage 8K arenas
;;----------------------------------------------------------------------------------------------------------------------
;;
;; Arenas are allocate-only memory areas.  Because of the ZX Spectrum Next page size, 8K is the limit for any single
;; allocation.  An arena starts out as a single 8K block of memory whose first 228 bytes contains meta-data describing
;; the arena.  The initial bytes are as follows:
;;
;;      Offset  Size    Description
;;      0       224     The page indicies that comprise this arena.
;;      224     1       The number of pages in the arena
;;      225     3       The current 24-bit address offset into the arena of the next allocation.
;;      228             First free byte of arena
;;
;; Each page is reserved via NextZXOS, which will allocate the last physical page first and then the one before that,
;; and so on.  When an allocation is made, a check is made to see if it will fit on the latest page.  If not, a new
;; page is allocated to make room for it.  Allocations can NEVER cross page boundaries.  Any memory unused on the
;; previous page is wasted, so you have to be careful how you allocate.  What you will get in return is a 24-bit
;; address.  Bits 0-12 will be the offset into the page the allocation resides on (0-8191), and bits 16-23 will be
;; the page index of the allocation.  Alternatively, you can ask the memory manager to start allocating immediately
;; on the next page.
;;
;; When using the memory that has been allocated, it has to be prepared first.  This process pages in the correct page
;; so that it sits in the $c000-$dfff memory area ready for you to read or write to it.
;;
;; Finally, you can deallocating everything you've allocated in that arena by destroying the arena.
;;
;;----------------------------------------------------------------------------------------------------------------------
;; The interface:
;;
;;      arena_new       Creates a new arena and returns a handle to that arena for use in other functions.
;;      arena_done      Destroy an arena, giving back all allocated pages back to the OS.
;;      arena_align     Make sure the next allocation starts at the beginning of a new page and return its index.
;;      arena_alloc     Allocate up to 8K bytes and return a 24-bit reference to that memory.
;;      arena_prepare   Ensure that allocated memory is paged in so it is visible by the CPU.  Returns a real address.
;;
;;----------------------------------------------------------------------------------------------------------------------


IDE_BANK        equ     $01bd           ; NextZXOS function to manage memory
M_P3DOS         equ     $94             ; +3 DOS function call

; Arena meta-data addresses
; Pages are always paged into $c000-$dfff
ARENAHDR_PAGES          equ     $c000   ; Array of pages used in arena
ARENAHDR_NUMPAGES       equ     $c0e0   ; Number of pages allocated so far
ARENAHDR_NEXTOFFSET     equ     $c0e1   ; 16-bit offset (< 8K) where next allocation will be placed
ARENAHDR_NEXTPAGE       equ     $c0e3   ; 8-bit page # where next allocation will be

;;----------------------------------------------------------------------------------------------------------------------
;; Internal routine to allocate a single page from the OS.
;;
;; Output:
;;      A = page # (or 0 if failed)
;;
;;----------------------------------------------------------------------------------------------------------------------

allocPage:      push    ix
                push    bc
                push    de
                push    hl

                ; Allocate a page by using the OS function IDE_BANK.
                ld      hl,$0001        ; Select allocate function and allocate from normal memory.
                exx                     ; Function parameters are switched to alternative registers.
                ld      de,IDE_BANK     ; Choose the function.
                ld      c,7             ; We want RAM 7 swapped in when we run this function (so that the OS can run).
                rst     8
                db      M_P3DOS         ; Call the function, new page # is in E
                jr      c,.success

                ; We failed here
                xor     a
                ld      e,a             ; Page # is 0 (i.e. error)

.success        ld      a,e
                pop     hl
                pop     de
                pop     bc
                pop     ix
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Internal routine to return a previously allocated page back to the OS.
;;
;; Input:
;;      A = page #
;;
;;----------------------------------------------------------------------------------------------------------------------

freePage:       push    af
                push    ix
                push    bc
                push    de
                push    hl

                ld      e,a             ; E = page #
                ld      hl,$0003        ; Deallocate function from normal memory
                exx                     ; Function parameters are switched to alternative registers.
                ld      de,IDE_BANK     ; Choose the function.
                ld      c,7
                rst     8
                db      M_P3DOS

                pop     hl
                pop     de
                pop     bc
                pop     ix
                pop     af
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Create a new arena.
;;
;; Ouput:
;;      A = handle to arena.  Use this when calling other routines.
;;      ZF = 1 if allocation failed, 0 otherwise.
;;
;;----------------------------------------------------------------------------------------------------------------------

arena_new:
                push    de
                push    hl
                call    allocPage                       ; Allocate a page to hold the meta-data and the first allocations
                and     a                               ; Did we fail?
                jr      z,.fail
                ld      e,a                             ; Save the page #

                nextreg $56,a                           ; Page it in to MMU 6 ($c000-$dfff)
                ld      a,1
                ld      (ARENAHDR_NUMPAGES),a           ; Store # of pages
                ld      hl,228
                ld      (ARENAHDR_NEXTOFFSET),hl        ; Initial offset for first allocation
                ld      a,e
                ld      (ARENAHDR_PAGES),a              ; Store first page # in chain
                ld      (ARENAHDR_NEXTPAGE),a           ; Store MSB of first allocation reference (its page #)

.fail           pop     hl
                pop     de
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Destroy an arena and return all allocated pages back to the OS.
;;
;; Input:
;;      A = handle
;;
;; Output:
;;      A = handle
;;      ZF = 0
;;      CF = 0
;;
;;----------------------------------------------------------------------------------------------------------------------

arena_done:
                push    bc
                push    hl

                ; Page in the first page of the chain to get access to meta-data
                nextreg $56,a
                ld      a,(ARENAHDR_NUMPAGES)
                ld      b,a             ; # of pages in chain
                ld      h,$c0
                ld      l,a             ; HL = address of next page # location in array
                dec     l               ; HL now points to last entry in array

.l1             ld      a,(hl)          ; A = next page to free
                call    freePage        ; We assume that the NextZXOS function doesn't change paging
                dec     hl              ; Next page index location in array
                djnz    .l1

                pop     hl
                pop     bc
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Ensure the next allocation starts at the beginning of a page.
;;
;; Input:
;;      A = handle
;;
;; Output:
;;      A = new page #
;;
;;----------------------------------------------------------------------------------------------------------------------

arena_align:
                push    de
                push    hl

                nextreg $56,a           ; Page in first page of arena (with meta-data)
                ld      h,$c0           ; H = MMU 6
                call    allocPage       ; A = new page # or 0
                and     a
                jr      z,.no_mem

                ld      e,a             ; E = new page #
                ld      a,(ARENAHDR_NUMPAGES)
                ld      l,a             ; HL = new entry in page table
                ld      (hl),e          ; Add new page in page table
                inc     a               ; We have one more page!
                ld      (ARENAHDR_NUMPAGES),a
                ld      l,LO(ARENAHDR_NEXTOFFSET)
                xor     a
                ld      (hl),a          ; Next free address is at beginning of page (offset 0)
                inc     hl
                ld      (hl),a
                inc     hl
                ld      (hl),e          ; Write 24-bit address for next allocation

.no_mem         pop     hl
                pop     de
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Allocate memory.
;;
;; Input:
;;      A = arena handle
;;      BC = size
;;
;; Output:
;;      A = page
;;      HL = offset into page
;;      CF = 1 if error (and EHL == 0)
;;
;;----------------------------------------------------------------------------------------------------------------------
;;
;; Test cases:
;;      1)      Allocate 0 bytes (expected to return same address of current next pointer)
;;      2)      Allocate 5000 bytes (expected to return same address of current next pointer and advance pointer)
;;      3)      Allocate 8000 bytes (expected to allocate new page)
;;      4)      Allocate 8192 bytes (expected to allocate new page, fill page)
;;      5)      Allocate 9000 bytes (expect return address of 0)
;;      6)      Allocate 8192 bytes, then 100 bytes (expected to allocate in new page, fill page, then allocate 100)
;;      7)      Allocate 8192 bytes, then 8192 bytes (expected to allocate 2 pages and fill them)
;;
;;----------------------------------------------------------------------------------------------------------------------

arena_alloc:
                push    bc
                push    de

                ld      e,a                             ; E = handle
                nextreg $56,a                           ; Page in first page of arena (with meta-data)

                ; Check to see if the size is <= 8K ($2000)
                ld      hl,(ARENAHDR_NEXTOFFSET)        ; HL = number of bytes used in latest page and LSW of allocation
                dec     bc                              ; BC = size - 1
                jr      c,.zero                         ; Size == 0?  Yes, deal with trivial case
                ld      a,b
                and     $e0                             ; Top 3 bits should be 0 if <= 8K
                jr      nz,.too_large

                ; Obtain how much space on the current page
                push    hl                              ; Store allocation address
                add     hl,bc                           ; HL = number of bytes + size - 1
                ld      a,h
                and     $e0                             ; Final size <= 8K (final size - 1 < 8K)?
                jr      z,.alloc                        ; Yes, go ahead and allocate

                ; No? We need to allocate another page
                ld      a,e                             ; A = handle
                call    arena_align                     ; A = new page #
                pop     hl                              ; Throw away allocation address
                push    0                               ; New allocation address (beginning of page)
                ld      h,b
                ld      l,c                             ; HL = new offset - 1

.alloc          ; At this point:
                ;       HL = new offset - 1
                ;       Stack has old offset
                inc     hl                              ; CF = 0 after this.
                ld      (ARENAHDR_NEXTOFFSET),hl        ; Store new offset
                ld      a,(ARENAHDR_NEXTPAGE)
                pop     hl                              ; HL = LSW of allocation

                ; At this point, AHL = allocation address
.finish         pop     de
                pop     bc
                ret                                     ; AHL = allocation address

                ; This handles an allocation size that is too large (> 8K).  We can't allocate this much as it
                ; won't fit on a single page.  Return address of 0
.too_large      xor     a
                ld      h,a
                ld      l,a                             ; AHL = 0
                scf
                jr      .finish

                ; This handles size of zero.  HL is already the LSW of the allocation address.  Just need to fetch
                ; the MSB of the allocation address.
.zero           ld      a,(ARENAHDR_NEXTPAGE)
                and     a                               ; Clear carry flag (since it will be 1 at this point)
                jr      .finish

;;----------------------------------------------------------------------------------------------------------------------
;; Prepare a 24-bit address, by paging in the correct page at MMU 6.
;;
;; Input:
;;      AHL = 24-bit address (A = page, HL = offset into page)
;;
;; Output:
;;      HL = real address inside MMU 6 for data.
;;
;; Affected:
;;      A
;;
;;----------------------------------------------------------------------------------------------------------------------

arena_prepare:
                nextreg $56,a           ; Page in data
                ld      a,h
                add     a,$c0
                ld      h,a             ; HL = $C000 + offset
                ret

;;----------------------------------------------------------------------------------------------------------------------
;;----------------------------------------------------------------------------------------------------------------------
