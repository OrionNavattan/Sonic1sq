; ---------------------------------------------------------------------------
; Subroutine to convert hex byte into decimal (up to 99)

; input:
;	d0.w = hex byte

; output:
;	(a1) = decimal tens digit
;	1(a1) = decimal low digit

;	uses d0.w
; ---------------------------------------------------------------------------

HexToDec:
		lea	HUD_TimeList(pc),a1
		bra.w	HexToDec_Run

		decnum: = 0
HUD_TimeList:	rept 10
		rept 10
		dc.w decnum
		decnum: = decnum+1
		endr
		decnum: = decnum+$100-10
		endr

HexToDec2:
		lea	HUD_TimeList2(pc),a1
		
	HexToDec_Run:
		add.b	d0,d0
		lea	(a1,d0.w),a1
		rts

		decnum: = 0
HUD_TimeList2:	rept 10
		rept 10
		dc.w decnum
		decnum: = decnum+2
		endr
		decnum: = decnum+$200-20
		endr
		
; ---------------------------------------------------------------------------
; Subroutine to count the number of (decimal) digits in a longword

; input:
;	d0.l = longword

; output:
;	d1.l = number of digits (1-6)
; ---------------------------------------------------------------------------

CountDigits:
		cmpi.l	#9,d0
		bhi.s	.more_than_1
		moveq	#1,d1
		rts
	
	.more_than_1:
		cmpi.l	#99,d0
		bhi.s	.more_than_2
		moveq	#2,d1
		rts
	
	.more_than_2:
		cmpi.l	#999,d0
		bhi.s	.more_than_3
		moveq	#3,d1
		rts
	
	.more_than_3:
		cmpi.l	#9999,d0
		bhi.s	.more_than_4
		moveq	#4,d1
		rts
	
	.more_than_4:
		cmpi.l	#99999,d0
		bhi.s	.more_than_5
		moveq	#5,d1
		rts
	
	.more_than_5:
		moveq	#6,d1
		rts
		