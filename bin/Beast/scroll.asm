
; ************************************************************************
;
;	Function:	Init the map. Load files and reset the scroll
;
; ************************************************************************
InitMap:
        ld  hl,0
        ld  (ForeX),hl
        ld  (BackX),hl
        ld  (ForeY),hl
        ld  (BackY),hl

        xor a
        NREG    23
        NREG    22
        NREG    50
        NREG    51


        ld      a,128
        NREG    21

        LoadFile    Background,$c000        ; get the background in first
        ld      hl,$c000
        ld      de,$4000
        ld      bc,$1800
        ldir    
        ld      hl,$d800        ; second half of screen
        ld      de,$6000
        ld      bc,$1800
        ldir    

        ld      hl,Foreground
        call    Load256

;        ld      a,$e3
;        ld      (palette+($e3*2)),a
;        ld      a,0
;        ld      (palette+($e3*2)+1),a


        ; set palette 
;        ld      a,%00010100     ; Layer 2 palette 0
;        NREG    67              ; 
;        ld      a,0             ; start at index 0
;        NREG    64              ;
;        ld      hl,Palette
;        ld      b,0
;@SetAll2:
;        ld      a,(hl)          ; RRRGGGBB
;        inc     hl
;        NREG    $44
;        ld      a,(hl)          ; lower B
;        inc     hl
;        NREG    $44
;        djnz    @SetAll2





        ld      a,0
        NREG    67              ; write to the ULA palette
        ld      a,0
        NREG    64              ; write to the ULA palette
@SetAll:
        NREG    65
        inc     a
        cp      0
        jr      nz,@SetAll

        ld      a,1
        NREG    67              ; write to the ULA palette


        ld      a,128
        NREG    64              ; write to the ULA palette
        ld      a,0
        NREG    65
        ;
        ; Update copper
        ;
UpdateCopper:
        ld      hl,GameCopper
        ld      de,CopperSize
        call    UploadCopper


        ld      a,0             ; make border black
        NREG    $61
        ld      a,%11000000
        NREG    $62
        ret

; ******************************************************************************
; Function:	Load a 256 colour bitmap directly into the screen
;		Once loaded, enable and display it
; In:		hl = file data pointer
; ******************************************************************************
Load256:
		; ignore file length... it's set for this (should be 256*192)
		inc	hl
		inc	hl

		push	hl
        pop	ix
        ld      b,FA_READ
        call    fOpen
        jr	c,@error_opening	; error opening?
        cp	0
        jr	z,@error_opening	; error opening?
        ld	(LoadHandle),a		; store handle


        ld	e,3			; number of blocks
        ld	a,1			; first bank...
        ld	(Loadbank),a
@LoadAll:                
        ld	a,(LoadHandle)		; load block into $c000
        ld	bc,64*256
        ld	ix,$c000
        call	fread

        ld      bc, $123b		; enable $0000 write
        ld	a,(Loadbank)
        out	(c),a			; bank in first bank


        ld	bc,$4000
        ld	hl,$c000
        ld	de,0
        ldir	

        ld      bc, $123b		; disable RAM in lower $0000
        ld	a,0
        out	(c),a			; bank in first bank

        ld	a,(Loadbank)
        add	a,$40
        ld	(Loadbank),a
        cp	$c1
        jr	nz,@LoadAll


        ld	a,(LoadHandle)
        call	fClose

        ld      bc, $123b		; enable screen
        ld	a,2
        out	(c),a                               
       	ret
@error_opening:
		ld      a,5
        	out     ($fe),a
@SkipError
		ret




; ******************************************************************************
; Function: Load a 256 colour bitmap directly into the screen
;           Once loaded, enable and display it
; In:       hl = file data pointer
; ******************************************************************************
Load256_pal:
        ; ignore file length... it's set for this (should be 256*192)
        inc hl
        inc hl

        push    hl
        pop ix
        ld      b,FA_READ
        call    fOpen
        jr  c,@error_opening    ; error opening?
        cp  0
        jr  z,@error_opening    ; error opening?
        ld  (LoadHandle),a      ; store handle


        ; Load palette first
        ld      a,(LoadHandle)      ; load block into $c000
        ld      bc,256*2
        ld      ix,Palette
        call    fread


        ld  e,3         ; number of blocks
        ld  a,1         ; first bank...
        ld  (Loadbank),a
@LoadAll:                
        ld  a,(LoadHandle)      ; load block into $c000
        ld  bc,64*256
        ld  ix,$c000
        call    fread

        ld      bc, $123b       ; enable $0000 write
        ld  a,(Loadbank)
        out (c),a           ; bank in first bank


        ld  bc,$4000
        ld  hl,$c000
        ld  de,0
        ldir    

        ld      bc, $123b       ; disable RAM in lower $0000
        ld  a,0
        out (c),a           ; bank in first bank

        ld  a,(Loadbank)
        add a,$40
        ld  (Loadbank),a
        cp  $c1
        jr  nz,@LoadAll


        ld  a,(LoadHandle)
        call    fClose

        ld      bc, $123b       ; enable screen
        ld  a,2
        out (c),a                               
        ret
@error_opening:
        ld      a,5
            out     ($fe),a
@SkipError
        ret

Loadbank    db  0
Palette     ds  256*2

