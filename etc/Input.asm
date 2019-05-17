	INCLUDE "Defines.asm"
;===========================================================================
; Get all input (call at start of frane)
; code will set joystick to MD 1, then restore to users preference
;===========================================================================
Input
	ld bc,NEXTREG_REGISTER_SELECT_PORT:ld a,PERIPHERAL_1_REGISTER
	out (c),a:inc b
	in a,(c):ld (.reset+1),a:and %00000101:or %01101010:out (c),a
	ld a,(kempstonValue):ld (oldKempstonValue),a:ld l,a
	in a,(KEMPSTON_PORT):cp 255:jr nz,.ok:xor a
.ok	ld h,a:ld (kempstonValue),a:and l:xor h:ld (debKempstonValue),a
	ld a,%01111111
	ld hl,oldkeys:ld de,newkeys:ld bc,debkeys
.lp	push af:ld a,(de):ld (hl),a:pop af
	push af:in a,(254):cpl:ld (de),a:and (hl):ex de,hl:xor (hl):ex de,hl:ld (bc),a:pop af
	inc  hl:inc de:inc bc:rrca:jp c,.lp
	ld bc,NEXTREG_REGISTER_SELECT_PORT:ld a,PERIPHERAL_1_REGISTER
	out (c),a:inc b
.reset	ld a,0:out (c),a
;===========================================================================
	xor a:ld (debAscii),a
	ld hl,(debkeys+0):ld (.debkeyscopy+0),hl:ld hl,(debkeys+2):ld (.debkeyscopy+2),hl
	ld hl,(debkeys+4):ld (.debkeyscopy+4),hl:ld hl,(debkeys+6):ld (.debkeyscopy+6),hl
	ld hl,.keytab
	ld a,$fe:in a,(254):rra:jr c,.ncap:ld hl,.captab
.ncap	ld a,$7f:in a,(254):and 2:jr nz,.nsym:ld hl,.symtab
.nsym	ld ix,.debkeyscopy
	res 1,(ix+0):res 0,(ix+7)	; clear caps and symbol bits.
	ld e,$7f
.lp2	ld a,(ix+0):inc ix
	ld b,5
.blp	rra:jr c,.got
.skp	inc hl:djnz .blp:rrc e:jr c,.lp2
	ret
.got	ld a,(hl):cp 1:jr z,.skp
	ld (debAscii),a
	ret
;===========================================================================
; Key map
;===========================================================================
.debkeyscopy	db	0,0,0,0,0,0,0,0			; need enough for the amount of key indexes
.keytab		db	" ",  1,"M","N","B"	, 13,"L","K","J","H"
		db	"P","O","I","U","Y"	,"0","9","8","7","6"
		db	"1","2","3","4","5"	,"Q","W","E","R","T"
		db	"A","S","D","F","G"	,  1,"Z","X","C","V"

.captab		db	" ",  1,"M","N","B"	, 13,"L","K","J","H"
		db	"P","O","I","U","Y"	, -1,"9",  8,  7,  6
		db	"1","2","3","4",  5	,"Q","W","E","R","T"
		db	"A","S","D","F","G"	,  1,"Z","X","C","V"

.symtab		db	" ",  1,".",",","*"	, 13,"=","+","-","^"
		db	 34,";","I","U","Y"	,"_",")","(","'","&"
		db	"!","@","#","$","%"	,"Q","W","E","<",">"
		db	"A","S","D","F","G"	,  1,":",$60,$3f,"/"
;===========================================================================
; Keys used by default, when editing, also change indexes
;===========================================================================
.joykeys	db KEY_Q,KEYAND_Q,JOYSTICK_UP			;up
		db KEY_A,KEYAND_Q,JOYSTICK_DOWN			;down
		db KEY_O,KEYAND_O,JOYSTICK_LEFT			;left
		db KEY_P,KEYAND_P,JOYSTICK_RIGHT		;right
		db KEY_SPACE,KEYAND_SPACE,BUTTON_FIRE1		;fire
		db KEY_M,KEYAND_M,BUTTON_FIRE2			;fire2
		db KEY_ENTER,KEYAND_ENTER,BUTTON_START		;Pause
;===========================================================================
; Key indexes
;===========================================================================
KEY_INDEX_UP 		= 0
KEY_INDEX_DOWN 		= 1
KEY_INDEX_LEFT 		= 2
KEY_INDEX_RIGHT 	= 3
KEY_INDEX_FIRE 		= 4
KEY_INDEX_FIRE2		= 5
KEY_INDEX_START 	= 6
;===========================================================================
; Checks for input, A = joykeys value
;===========================================================================
IsItPressed
	ld l,a:add a,a:add a,l
	ld hl,Input.joykeys:add hl,a:ld e,(hl):inc hl:ld d,(hl):inc hl:ld c,(hl)
	ld a,(debKempstonValue):and c:jr nz,ItIs
	ld hl,debkeys:ld a,e:add hl,a:ld a,(hl):and d:jr nz,ItIs
ItIsnt	or a:ret
ItIs	scf:ret
;===========================================================================
IsItHeld
	ld l,a:add a,a:add a,l
	ld hl,Input.joykeys:add hl,a:ld e,(hl):inc hl:ld d,(hl):inc hl:ld c,(hl)
	ld a,(kempstonValue):and c:jr nz,ItIs
	ld hl,newkeys:ld a,e:add hl,a:ld a,(hl):and d:jr nz,ItIs
	jr ItIsnt
;===========================================================================
IsItReleased	;entry = joykeys value
	ld l,a:add a,a:add a,l
	ld hl,Input.joykeys:add hl,a:ld e,(hl):inc hl:ld d,(hl):inc hl:ld c,(hl)
	ld a,(oldKempstonValue):and c:jr z,.skip
	ld a,(kempstonValue):and c:jr z,ItIs
.skip	ld hl,oldkeys:ld a,e:add hl,a:ld a,(hl):and d:jr z,ItIsnt
	ld hl,newkeys:ld a,e:add hl,a:ld a,(hl):and d:jr z,ItIs
	jr ItIsnt
;===========================================================================
GetFireReleased		ld a,KEY_INDEX_FIRE:jp IsItReleased
;===========================================================================
GetPauseReleased	ld a,(oldKempstonValue):and BUTTON_FIRE2:jr nz,ItIsnt
			ld a,KEY_INDEX_START:jr IsItReleased
;===========================================================================
GetFirePressed		ld a,KEY_INDEX_FIRE:jr IsItHeld
;===========================================================================
GetFire1stPressed	ld a,KEY_INDEX_FIRE:jp IsItPressed
;===========================================================================
GetFire21stPressed	ld a,KEY_INDEX_FIRE2:jp IsItPressed
;===========================================================================
GetLeft			ld a,KEY_INDEX_LEFT:jp IsItHeld
;===========================================================================
GetRight		ld a,KEY_INDEX_RIGHT:jp IsItHeld
;===========================================================================
GetUp			ld a,KEY_INDEX_UP:jp IsItHeld
;===========================================================================
GetDown			ld a,KEY_INDEX_DOWN:jp IsItHeld
;===========================================================================
GetDownReleasedOnly	ld a,KEY_INDEX_LEFT:call IsItHeld:jp c,ItIsnt
			ld a,KEY_INDEX_RIGHT:call IsItHeld:jp c,ItIsnt
			ld a,KEY_INDEX_DOWN:jp IsItPressed
;===========================================================================
GetBreakReleased
	ld a,(oldkeys+KEY_CAPS):and KEYAND_CAPS:jp z,ItIsnt
	ld a,(newkeys+KEY_SPACE):and KEYAND_SPACE:jp nz,ItIsnt
	ld a,(oldkeys+KEY_SPACE):and KEYAND_SPACE:jp z,ItIsnt
	jp ItIs
;===========================================================================
GetRedefineReleased
	ld a,(newkeys+KEY_R):and KEYAND_R:jp nz,ItIsnt
	ld a,(oldkeys+KEY_R):and KEYAND_R:jp z,ItIsnt
	jp ItIs
;===========================================================================
; Key defines
;===========================================================================
KEYAND_CAPS		equ 	%00000001
KEYAND_Z		equ	%00000010
KEYAND_X		equ	%00000100
KEYAND_C		equ	%00001000
KEYAND_V		equ	%00010000
KEYAND_A		equ	%00000001
KEYAND_S		equ	%00000010
KEYAND_D		equ	%00000100
KEYAND_F		equ	%00001000
KEYAND_G		equ	%00010000
KEYAND_Q		equ 	%00000001
KEYAND_W		equ	%00000010
KEYAND_E		equ	%00000100
KEYAND_R		equ	%00001000
KEYAND_T		equ	%00010000
KEYAND_1		equ 	%00000001
KEYAND_2		equ	%00000010
KEYAND_3		equ	%00000100
KEYAND_4		equ	%00001000
KEYAND_5		equ	%00010000
KEYAND_0		equ 	%00000001
KEYAND_9		equ	%00000010
KEYAND_8		equ	%00000100
KEYAND_7		equ	%00001000
KEYAND_6		equ	%00010000
KEYAND_P		equ 	%00000001
KEYAND_O		equ	%00000010
KEYAND_I		equ	%00000100
KEYAND_U		equ	%00001000
KEYAND_Y		equ	%00010000
KEYAND_ENTER		equ 	%00000001
KEYAND_L		equ	%00000010
KEYAND_K		equ	%00000100
KEYAND_J		equ	%00001000
KEYAND_H		equ	%00010000
KEYAND_SPACE		equ 	%00000001
KEYAND_SYM		equ	%00000010
KEYAND_M		equ	%00000100
KEYAND_N		equ	%00001000
KEYAND_B		equ	%00010000

KEY_CAPS		equ 	7
KEY_Z			equ	7
KEY_X			equ	7
KEY_C			equ	7
KEY_V			equ	7
KEY_A			equ	6
KEY_S			equ	6
KEY_D			equ	6
KEY_F			equ	6
KEY_G			equ	6
KEY_Q			equ 	5
KEY_W			equ	5
KEY_E			equ	5
KEY_R			equ	5
KEY_T			equ	5
KEY_1			equ 	4
KEY_2			equ	4
KEY_3			equ	4
KEY_4			equ	4
KEY_5			equ	4
KEY_0			equ 	3
KEY_9			equ	3
KEY_8			equ	3
KEY_7			equ	3
KEY_6			equ	3
KEY_P			equ 	2
KEY_O			equ	2
KEY_I			equ	2
KEY_U			equ	2
KEY_Y			equ	2
KEY_ENTER		equ 	1
KEY_L			equ	1
KEY_K			equ	1
KEY_J			equ	1
KEY_H			equ	1
KEY_SPACE		equ 	0
KEY_SYM			equ	0
KEY_M			equ	0
KEY_N			equ	0
KEY_B			equ	0
;===========================================================================
; Joy defines
;===========================================================================
KEMPSTON_PORT		equ 	$1f
BUTTON_START		equ 	%10000000
BUTTON_FIRE3		equ 	%01000000
BUTTON_FIRE2		equ 	%00100000
BUTTON_FIRE1		equ 	%00010000
JOYSTICK_UP		equ 	%00001000
JOYSTICK_DOWN		equ 	%00000100
JOYSTICK_LEFT		equ 	%00000010
JOYSTICK_RIGHT		equ 	%00000001
;===========================================================================
; data
;===========================================================================
debAscii		db	0
oldkeys			db	0,0,0,0,0,0,0,0
newkeys			db	0,0,0,0,0,0,0,0
debkeys			db	0,0,0,0,0,0,0,0
kempstonValue		db	0
oldKempstonValue 	db	0
debKempstonValue	db 	0
;===========================================================================
;
;===========================================================================
