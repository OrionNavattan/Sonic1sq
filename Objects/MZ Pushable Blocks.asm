; ---------------------------------------------------------------------------
; Object 33 - pushable blocks (MZ)

; spawned by:
;	ObjPos_MZ1, ObjPos_MZ2, ObjPos_MZ3 - subtypes 0/$81
; ---------------------------------------------------------------------------

PushBlock:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	PushB_Index(pc,d0.w),d1
		jmp	PushB_Index(pc,d1.w)
; ===========================================================================
PushB_Index:	index *,,2
		ptr PushB_Main
		ptr PushB_Action
		ptr PushB_ChkVisible

PushB_Var:
PushB_Var_0:	dc.b $10, id_frame_pblock_single		; object width,	frame number
PushB_Var_1:	dc.b $40, id_frame_pblock_four

sizeof_PushB_Var:	equ PushB_Var_1-PushB_Var

		rsobj PushBlock
ost_pblock_x_start:	rs.w 1					; original x position
ost_pblock_y_start:	rs.w 1					; original y position
ost_pblock_time:	rs.w 1					; event timer
ost_pblock_lava_speed:	rs.w 1					; x axis speed when block is on lava (2 bytes)
ost_pblock_lava_flag:	rs.b 1					; 1 = block is on lava
		rsobjend
; ===========================================================================

PushB_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto PushB_Action next
		move.b	#16,ost_height(a0)
		move.l	#Map_Push,ost_mappings(a0)
		move.w	#tile_Kos_MzBlock+tile_pal3,ost_tile(a0)
		move.b	#render_rel,ost_render(a0)
		move.b	#3,ost_priority(a0)
		move.w	ost_x_pos(a0),ost_pblock_x_start(a0)
		move.w	ost_y_pos(a0),ost_pblock_y_start(a0)
		moveq	#0,d0
		move.b	ost_subtype(a0),d0			; get subtype
		beq.s	.type0					; branch if 0
		bset	#tile_hi_bit,ost_tile(a0)		; make sprite appear in foreground
		
	.type0:
		andi.w	#$F,d0					; read low nybble
		add.w	d0,d0
		lea	PushB_Var(pc,d0.w),a2			; get width & frame values from array
		move.b	(a2),ost_width(a0)
		move.b	(a2)+,ost_displaywidth(a0)
		move.b	(a2)+,ost_frame(a0)
		move.w	#2,ost_pblock_time(a0)
		bsr.w	PreventDupe				; flag object as loaded & prevent the same object loading again

PushB_Action:	; Routine 2
		tst.w	ost_parent(a0)
		bne.s	.stomper_skip				; branch if chain stomper was found
		move.b	(v_frame_counter_low).w,d0
		andi.b	#$1F,d0
		bne.s	.stomper_skip				; branch except every 32 frames (approx 0.5 seconds)
		move.l	#ChainStomp,d0
		moveq	#id_CStom_Block,d1
		bsr.w	FindNearestObj				; find nearest chain stomper & save to ost_parent
		
	.stomper_skip:
		bsr.w	SolidObject
		bsr.s	PushB_Pushing
		bsr.w	PushB_ChkFloor
		
		move.w	ost_x_pos(a0),d0
		bsr.w	CheckActive
		beq.w	DisplaySprite
		bsr.w	SaveState
		beq.w	DeleteObject				; branch if not in respawn table
		bclr	#0,(a2)					; allow object to load again later
		bra.w	DeleteObject

; ---------------------------------------------------------------------------
; Subroutine to move block when pushed
; ---------------------------------------------------------------------------

PushB_Pushing:
		subq.w	#1,ost_pblock_time(a0)			; decrement timer
		bpl.s	.exit					; branch if time remains
		btst	#status_pushing_bit,ost_status(a1)
		beq.s	.push_reset				; branch if Sonic isn't pushing anything
		cmpi.b	#id_Walk,ost_anim(a1)
		bne.s	.push_reset				; branch if Sonic isn't trying to move
		btst	#status_pushing_bit,ost_status(a0)
		beq.s	.push_other				; branch if Sonic isn't pushing the block
		andi.b	#solid_right,d1
		beq.s	.push_left				; branch if pushing left side
		
	.push_right:
		bsr.w	FindWallLeftObj
		tst.w	d1
		beq.s	.exit					; branch if block is against wall
		subq.w	#1,ost_x_pos(a1)			; Sonic moves left
	.push_right2:
		subq.w	#1,ost_x_pos(a0)			; block moves left
		play.w	1, jsr, sfx_Push			; play pushing sound
		bra.s	.push_reset
		
	.push_left:
		bsr.w	FindWallRightObj
		tst.w	d1
		beq.s	.exit					; branch if block is against wall
		addq.w	#1,ost_x_pos(a1)			; Sonic moves right
	.push_left2:
		addq.w	#1,ost_x_pos(a0)			; block moves right
		play.w	1, jsr, sfx_Push			; play pushing sound
		
	.push_reset:
		move.w	#2,ost_pblock_time(a0)			; 3 frame delay between movements
	
	.exit:
		rts
		
	.push_other:
		andi.b	#solid_top,d1
		beq.s	.exit					; branch if Sonic isn't on top
		btst	#status_xflip_bit,ost_status(a1)
		beq.s	.push_right2				; branch if Sonic is facing right
		bra.s	.push_left2
		
; ---------------------------------------------------------------------------
; Subroutine to check if block is on the floor or nearest chain stomper
; ---------------------------------------------------------------------------

PushB_ChkFloor:
		tst.w	ost_parent(a0)
		beq.s	.use_gravity				; branch if no chain stomper was found
		bsr.w	GetParent				; a1 = OST of chain stomper
		move.w	ost_y_pos(a1),d0
		sub.w	ost_y_pos(a0),d0
		bcs.s	.use_gravity				; branch if block is below stomper
		moveq	#0,d2
		move.b	ost_height(a1),d2
		add.b	ost_height(a0),d2
		cmp.w	d0,d2
		blt.s	.use_gravity				; branch if block is above stomper (and not touching)
		move.w	ost_x_pos(a1),d0
		sub.w	ost_x_pos(a0),d0
		abs.w	d0					; d0 = x dist between block & stomper
		moveq	#0,d1
		move.b	ost_width(a1),d1
		cmp.w	d0,d1
		bcs.s	.use_gravity				; branch if block is outside width
		move.w	ost_y_pos(a1),d0
		sub.w	d2,d0
		move.w	d0,ost_y_pos(a0)			; match block y pos with stomper
		rts
		
	.use_gravity:
		rts


; ===========================================================================
		
		
		tst.b	ost_pblock_lava_flag(a0)		; is block on lava?
		bne.w	PushB_OnLava				; if yes, branch
		moveq	#0,d1
		move.b	ost_displaywidth(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	ost_x_pos(a0),d4
		bsr.w	PushB_Solid				; make block solid & update its position
		cmpi.w	#id_MZ_act1,(v_zone).w			; is the level MZ act 1?
		bne.s	PushB_Display				; if not, branch
		bclr	#7,ost_subtype(a0)
		move.w	ost_x_pos(a0),d0
		cmpi.w	#$A20,d0
		bcs.s	PushB_Display
		cmpi.w	#$AA1,d0				; is block between $A20 and $AA1 on x axis?
		bcc.s	PushB_Display				; if not, branch
		
		move.w	(v_cstomp_y_pos).w,d0			; get y pos of nearby chain stomper
		subi.w	#$1C,d0
		move.w	d0,ost_y_pos(a0)			; set y pos of block so it's resting on the stomper
		bset	#7,(v_cstomp_y_pos).w			; set high bit of high byte of stomper y pos
		bset	#7,ost_subtype(a0)			; set flag to disable gravity for block

	PushB_Display:
		move.w	ost_x_pos(a0),d0
		bsr.w	CheckActive
		bne.s	PushB_ChkDel
		bra.w	DisplaySprite
; ===========================================================================

PushB_ChkDel:
		move.w	ost_pblock_x_start(a0),d0
		bsr.w	CheckActive
		bne.s	PushB_ChkDel2
		move.w	ost_pblock_x_start(a0),ost_x_pos(a0)
		move.w	ost_pblock_y_start(a0),ost_y_pos(a0)
		move.b	#id_PushB_ChkVisible,ost_routine(a0)
		bra.s	PushB_ChkVisible
; ===========================================================================

PushB_ChkDel2:
		lea	(v_respawn_list).w,a2
		moveq	#0,d0
		move.b	ost_respawn(a0),d0
		beq.s	.del
		bclr	#0,2(a2,d0.w)

	.del:
		bra.w	DeleteObject
; ===========================================================================

PushB_ChkVisible:
		; Routine 4
		bsr.w	CheckOffScreen_Wide			; is block still on screen?
		beq.s	.visible				; if yes, branch
		move.b	#id_PushB_Action,ost_routine(a0)
		clr.b	ost_pblock_lava_flag(a0)
		clr.w	ost_x_vel(a0)
		clr.w	ost_y_vel(a0)

	.visible:
		rts	
; ===========================================================================

PushB_OnLava:
		move.w	ost_x_pos(a0),-(sp)
		cmpi.b	#4,ost_routine2(a0)
		bcc.s	.pushing				; branch if ost_routine2 = 4 or 6 (PushB_Solid_Lava/PushB_Solid_Push)
		bsr.w	SpeedToPos				; update position

	.pushing:
		btst	#status_air_bit,ost_status(a0)		; has block been thrown into the air?
		beq.s	PushB_OnLava_ChkWall			; if not, branch
		addi.w	#$18,ost_y_vel(a0)			; apply gravity
		jsr	(FindFloorObj).l
		tst.w	d1					; has block hit the floor?
		bpl.w	.goto_solid				; if not, branch
		add.w	d1,ost_y_pos(a0)			; align to floor
		clr.w	ost_y_vel(a0)				; stop falling
		bclr	#status_air_bit,ost_status(a0)
		move.w	(a1),d0					; get 16x16 tile the block is on
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0				; is it block $16A+ (lava)?
		bcs.s	.goto_solid				; if not, branch
		move.w	ost_pblock_lava_speed(a0),d0
		asr.w	#3,d0
		move.w	d0,ost_x_vel(a0)			; make block float horizontally
		move.b	#1,ost_pblock_lava_flag(a0)
		clr.w	ost_y_sub(a0)

	.goto_solid:
		bra.s	PushB_OnLava_Solid
; ===========================================================================

PushB_OnLava_ChkWall:
		tst.w	ost_x_vel(a0)
		beq.w	PushB_OnLava_Sink			; branch if block isn't moving
		bmi.s	.wall_left				; branch if moving left
	
	.wall_right:
		moveq	#0,d3
		move.b	ost_displaywidth(a0),d3
		jsr	(FindWallRightObj).l
		tst.w	d1					; has block touched a wall?
		bmi.s	PushB_Stop				; if yes, branch
		bra.s	PushB_OnLava_Solid
; ===========================================================================

	.wall_left:
		moveq	#0,d3
		move.b	ost_displaywidth(a0),d3
		not.w	d3
		jsr	(FindWallLeftObj).l
		tst.w	d1					; has block touched a wall?
		bmi.s	PushB_Stop				; if yes, branch
		bra.s	PushB_OnLava_Solid
; ===========================================================================

PushB_Stop:
		clr.w	ost_x_vel(a0)				; stop block moving
		bra.s	PushB_OnLava_Solid
; ===========================================================================

PushB_OnLava_Sink:
		addi.l	#$2001,ost_y_pos(a0)			; sink in lava, $2001 subpixels each frame
		cmpi.b	#$A0,ost_y_sub+1(a0)			; has block been sinking for 160 frames?
		bcc.s	PushB_OnLava_Sunk			; if yes, branch

PushB_OnLava_Solid:
		moveq	#0,d1
		move.b	ost_displaywidth(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	(sp)+,d4
		bsr.w	PushB_Solid				; make block solid & update its position
		bsr.s	PushB_ChkGeyser
		bra.w	PushB_Display
; ===========================================================================

PushB_OnLava_Sunk:
		move.w	(sp)+,d4
		lea	(v_ost_player).w,a1
		bclr	#status_platform_bit,ost_status(a1)
		bclr	#status_platform_bit,ost_status(a0)
		bra.w	PushB_ChkDel

; ---------------------------------------------------------------------------
; Subroutine to load lava geysers when the block reaches specific x pos
; ---------------------------------------------------------------------------

PushB_ChkGeyser:
		cmpi.w	#id_MZ_act2,(v_zone).w			; is the level MZ act 2?
		bne.s	.not_mz2				; if not, branch
		move.w	#-$20,d2
		cmpi.w	#$DD0,ost_x_pos(a0)
		beq.s	PushB_LoadLava
		cmpi.w	#$CC0,ost_x_pos(a0)
		beq.s	PushB_LoadLava
		cmpi.w	#$BA0,ost_x_pos(a0)
		beq.s	PushB_LoadLava
		rts

.not_mz2:
		cmpi.w	#id_MZ_act3,(v_zone).w			; is the level MZ act 3?
		bne.s	.not_mz3				; if not, branch
		move.w	#$20,d2
		cmpi.w	#$560,ost_x_pos(a0)
		beq.s	PushB_LoadLava
		cmpi.w	#$5C0,ost_x_pos(a0)
		beq.s	PushB_LoadLava

	.not_mz3:
		rts	
; ===========================================================================

PushB_LoadLava:
		bsr.w	FindFreeObj				; find free OST slot
		bne.s	.fail					; branch if not found
		move.l	#GeyserMaker,ost_id(a1)			; load lava geyser object
		move.w	ost_x_pos(a0),ost_x_pos(a1)
		add.w	d2,ost_x_pos(a1)
		move.w	ost_y_pos(a0),ost_y_pos(a1)
		addi.w	#$10,ost_y_pos(a1)
		move.l	a0,ost_gmake_parent(a1)			; record block OST address as geyser's parent

	.fail:
		rts

; ---------------------------------------------------------------------------
; Subroutine to make the block solid, update its speed/position when pushed
; or on lava
;
; input:
;	d1 = width
;	d2 = height / 2 (when jumping)
;	d3 = height / 2 (when walking)
;	d4 = x-axis position
; ---------------------------------------------------------------------------

PushB_Solid:
		rts
		move.b	ost_routine2(a0),d0
		beq.w	PushB_Solid_Detect			; branch if ost_routine2 = 0
		subq.b	#2,d0
		bne.s	PushB_Solid_Lava			; branch if ost_routine2 > 2

		bsr.w	ExitPlatform
		btst	#status_platform_bit,ost_status(a1)
		bne.s	.on_block				; branch if Sonic is on the block
		clr.b	ost_routine2(a0)
		rts

	.on_block:
		move.w	d4,d2
		bra.w	MoveWithPlatform
; ===========================================================================

PushB_Solid_Lava:
		subq.b	#2,d0
		bne.s	PushB_Solid_Push			; branch if ost_routine2 = 6
		bsr.w	SpeedToPos				; update position
		addi.w	#$18,ost_y_vel(a0)			; apply gravity
		jsr	(FindFloorObj).l
		tst.w	d1					; has object hit the floor?
		bpl.w	.exit					; if not, branch
		add.w	d1,ost_y_pos(a0)			; align to floor
		clr.w	ost_y_vel(a0)				; stop falling
		clr.b	ost_routine2(a0)			; goto PushB_Solid next
		move.w	(a1),d0					; get 16x16 tile the block is on
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0				; is it block $16A+ (lava)?
		bcs.s	.exit					; if not, branch
		move.w	ost_pblock_lava_speed(a0),d0
		asr.w	#3,d0
		move.w	d0,ost_x_vel(a0)			; make block float horizontally
		move.b	#1,ost_pblock_lava_flag(a0)
		clr.w	ost_y_sub(a0)

	.exit:
		rts	
; ===========================================================================

PushB_Solid_Push:
		bsr.w	SpeedToPos				; update position
		move.w	ost_x_pos(a0),d0
		andi.w	#$C,d0
		bne.w	PushB_Solid_Exit			; branch if bits 2 or 3 of x pos are set
		andi.w	#$FFF0,ost_x_pos(a0)			; snap to grid
		move.w	ost_x_vel(a0),ost_pblock_lava_speed(a0)	; set speed to move on lava
		clr.w	ost_x_vel(a0)
		subq.b	#2,ost_routine2(a0)			; goto PushB_Solid_Lava next
		rts	
; ===========================================================================

PushB_Solid_Detect:
		;bsr.w	Solid_ChkCollision			; make block solid & update flags for interaction
		tst.w	d4
		beq.w	PushB_Solid_Exit			; branch if no collision
		bmi.w	PushB_Solid_Exit			; branch if top/bottom collision
		tst.b	ost_pblock_lava_flag(a0)
		beq.s	PushB_Solid_Side			; branch if not on lava
		bra.w	PushB_Solid_Exit
; ===========================================================================

PushB_Solid_Side:
		tst.w	d0					; where is Sonic?
		beq.w	PushB_Solid_Exit			; if inside the object, branch
		bmi.s	PushB_Solid_Left			; if left of the object, branch
		btst	#status_xflip_bit,ost_status(a1)	; is Sonic facing left?
		bne.w	PushB_Solid_Exit			; if yes, branch
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	ost_displaywidth(a0),d3
		jsr	(FindWallRightObj).l
		move.w	(sp)+,d0
		tst.w	d1					; has object hit right wall?
		bmi.w	PushB_Solid_Exit			; if not, branch
		addi.l	#$10000,ost_x_pos(a0)			; move 1px right and clear subpixels
		moveq	#1,d0
		move.w	#$40,d1
		bra.s	PushB_Solid_Side_Sonic
; ===========================================================================

PushB_Solid_Left:
		btst	#status_xflip_bit,ost_status(a1)	; is Sonic facing right?
		beq.s	PushB_Solid_Exit			; if yes, branch
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	ost_displaywidth(a0),d3
		not.w	d3
		jsr	(FindWallLeftObj).l
		move.w	(sp)+,d0
		tst.w	d1					; has object hit left wall?
		bmi.s	PushB_Solid_Exit			; if not, branch
		subi.l	#$10000,ost_x_pos(a0)			; move 1px left and clear subpixels
		moveq	#-1,d0
		move.w	#-$40,d1

PushB_Solid_Side_Sonic:
		lea	(v_ost_player).w,a1
		add.w	d0,ost_x_pos(a1)			; + or - 1 to Sonic's x position
		move.w	d1,ost_inertia(a1)			; + or - $40 to Sonic's inertia
		move.w	#0,ost_x_vel(a1)
		move.w	d0,-(sp)
		play.w	1, jsr, sfx_Push			; play pushing sound
		move.w	(sp)+,d0
		tst.b	ost_subtype(a0)				; is bit 7 of subtype set? (no gravity flag)
		bmi.s	PushB_Solid_Exit			; if yes, branch
		move.w	d0,-(sp)
		jsr	(FindFloorObj).l
		move.w	(sp)+,d0
		cmpi.w	#4,d1
		ble.s	.align_floor				; branch if object is within 4px of floor
		move.w	#$400,ost_x_vel(a0)
		tst.w	d0
		bpl.s	.moving_right				; branch if moving right
		neg.w	ost_x_vel(a0)				; move left

	.moving_right:
		move.b	#6,ost_routine2(a0)			; goto PushB_Solid_Push next
		bra.s	PushB_Solid_Exit
; ===========================================================================

	.align_floor:
		add.w	d1,ost_y_pos(a0)

PushB_Solid_Exit:
		rts	