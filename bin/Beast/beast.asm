;
; Created on Sunday, 18th of February 2018 at 13:00
; ZX Spectrum Next Framework V0.1 by Mike Dailly, 2018
;
;      Simple  Shadow of the Beast Copper demo
; 
                opt             sna=StartAddress:StackStart                             ; save SNA,Set PC = run point in SNA file and TOP of stack
                opt             Z80                                                                             ; Set z80 mode

                include "includes.asm"


                ; IRQ is at $5c5c to 5e01
                include "irq.asm"       
               
StackEnd:
                ds      127
StackStart:     db      0

                org     $8000


StartAddress:
                di                
                ld      a,VectorTable>>8
                ld      i,a                     
                im      2                       ; Setup IM2 mode
                ei
                ld      a,0
                out     ($fe),a

                call    InitFilesystem                
                call    BitmapOn
                call    InitSprites

                call    InitMap

                ld      a,0                     ; black boarder
                out     ($fe),a



;
;               Main loop
;               
MainLoop:
                halt                            ; wait for vblanks (need to do Raster IRQs at some point)
                ld      a,%10000000             ; Low res behind
                NREG    $15
                call    UpdateCopper
                
                call    ScrollGrass

                ; timing bar
                ld      a,0
                out     ($fe),a

                call    ReadKeyboard
                call    SetPlayer


                ld      a,(GrassScrolls)
                ld      (ForeX),a
                ld      (Trees0+1),a

                ld      a,(GrassScrolls+4)
                ld      (Grass1+1),a
                ld      a,(GrassScrolls+8)
                ld      (Grass2+1),a
                ld      a,(GrassScrolls+12)
                ld      (Grass3+1),a
                ld      a,(GrassScrolls+16)
                ld      (Grass4+1),a
                ld      a,(GrassScrolls+24)
                ld      (Grass5+1),a
                ld      a,(GrassScrolls+28)
                ld      (Wall+1),a




                ld      a,(ForeX)
                inc     a
                ld      (ForeX),a

                ld      hl,(BackX)
                inc     hl
                ld      (BackX),hl
                srl     h
                rr      l
                ld      a,l   
                ld      (Cloud0+1),a
                ld      (Hills+1),a
                srl     h
                rr      l
                ld      a,l
                ld      (Cloud1+1),a
                srl     h
                rr      l
                ld      a,l
                ld      (Cloud2+1),a
                srl     h
                rr      l
                ld      a,l
                ld      (Cloud3+1),a

                jp      MainLoop                ; infinite loop



; ************************************************************
;
; Do the different scrolling grass levels
;
; ************************************************************
ScrollGrass:
                ld      ix,GrassScrolls
                ld      b,8
@doall:         inc     (ix+0)                ; move once
                ld      a,(ix+1)
                dec     a                
                and     a
                jr      nz,@StoreResult
                ld      a,(ix+0)
                adc     a,(ix+3)                ; add on speed
                ld      (ix+0),a
                ld      a,(ix+2)
@StoreResult:
                ld      (ix+1),a
                ld      de,4
                add     ix,de
                djnz    @doall
                ret



GrassScrolls    db      0,1,1,0           ; scroll, curr delay, master delay, speed
                db      0,3,3,1           
                db      0,2,2,1           
                db      0,1,1,1           
                db      0,1,1,2
                db      0,1,1,3
                db      0,1,1,4
                db      0,1,1,5


ForeY           dw      0
BackY           dw      0       ; background
ForeX           dw      0
BackX           dw      0
which           db      0       ; 0 for Mario, 1 for Xenon 2

spSize  equ     4;

                ds      64*spSize
                

; *****************************************************************************************************************************
; includes modules
; *****************************************************************************************************************************
                include "Scroll.asm"
                include "Utils.asm"
                include "SpriteBouncing.asm"
                include "filesys.asm"
                include "copper.asm"


; *****************************************************************************************************************************
; File directory.....
; *****************************************************************************************************************************
Background      File    "game/beastl.256"
;Foreground      File    "game/beastf.pff"
Foreground      File    "game/beastf.256"


                ; wheres our end address?
                message "End of code =",PC
        



