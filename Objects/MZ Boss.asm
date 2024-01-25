; ---------------------------------------------------------------------------
; Object 73 - Eggman (MZ)

; spawned by:
;	DynamicLevelEvents
; ---------------------------------------------------------------------------

BossMarble:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	BMZ_Index(pc,d0.w),d1
		jmp	BMZ_Index(pc,d1.w)
; ===========================================================================
BMZ_Index:	index *,,2
		ptr BMZ_Main
		ptr BMZ_ShipMain

ost_boss_fireball_time:	equ ost_boss_mode			; time between fireballs coming out of lava - parent only
; ===========================================================================

BMZ_Main:	; Routine 0
		move.w	ost_x_pos(a0),ost_boss_parent_x_pos(a0)
		move.w	ost_y_pos(a0),ost_boss_parent_y_pos(a0)
		move.b	#id_React_Boss,ost_col_type(a0)
		move.b	#24,ost_col_width(a0)
		move.b	#24,ost_col_height(a0)
		move.b	#hitcount_mz,ost_col_property(a0)	; set number of hits to 8
		bclr	#status_xflip_bit,ost_status(a0)
		clr.b	ost_mode(a0)
		move.b	#id_BMZ_ShipMain,ost_routine(a0)	; goto BMZ_ShipMain
		move.b	#id_ani_boss_ship,ost_anim(a0)
		move.b	#priority_4,ost_priority(a0)
		move.l	#Map_Bosses,ost_mappings(a0)
		move.w	#tile_Art_Eggman,ost_tile(a0)
		move.b	#render_rel,ost_render(a0)
		move.b	#$20,ost_displaywidth(a0)
		
		moveq	#id_UPLC_Boss,d0
		jsr	UncPLC
		
		jsr	(FindNextFreeObj).l			; find free OST slot
		bne.s	BMZ_ShipMain				; branch if not found
		move.l	#Exhaust,ost_id(a1)
		move.w	#$500,ost_exhaust_escape(a1)		; set speed at which ship escapes
		move.l	a0,ost_exhaust_parent(a1)		; save address of OST of parent
		
		jsr	(FindNextFreeObj).l			; find free OST slot
		bne.s	BMZ_ShipMain				; branch if not found
		move.l	#BossFace,ost_id(a1)
		move.w	#$500,ost_face_escape(a1)		; set speed at which ship escapes
		move.b	#id_BMZ_Explode,ost_face_defeat(a1)	; boss defeat routine number
		move.l	a0,ost_face_parent(a1)			; save address of OST of parent
		
		jsr	(FindNextFreeObj).l			; find free OST slot
		bne.s	BMZ_ShipMain				; branch if not found
		move.l	#BossWeapon,ost_id(a1)
		move.b	#0,ost_subtype(a1)
		move.l	a0,ost_weapon_parent(a1)		; save address of OST of parent

BMZ_ShipMain:	; Routine 2
		moveq	#0,d0
		move.b	ost_mode(a0),d0
		move.w	BMZ_ShipIndex(pc,d0.w),d1
		jsr	BMZ_ShipIndex(pc,d1.w)
		lea	Ani_Bosses(pc),a1
		jsr	(AnimateSprite).l
		moveq	#status_xflip+status_yflip,d0
		and.b	ost_status(a0),d0
		andi.b	#$FF-render_xflip-render_yflip,ost_render(a0) ; ignore x/yflip bits
		or.b	d0,ost_render(a0)			; combine x/yflip bits from status instead
		jmp	(DisplaySprite).l
; ===========================================================================
BMZ_ShipIndex:index *,,2
		ptr BMZ_ShipStart
		ptr BMZ_ShipMove
		ptr BMZ_Explode
		ptr BMZ_Recover
		ptr BMZ_Escape
; ===========================================================================

BMZ_ShipStart:
		move.b	ost_boss_wobble(a0),d0			; get wobble byte
		addq.b	#2,ost_boss_wobble(a0)			; increment wobble (wraps to 0 after $FE)
		jsr	(CalcSine).w				; convert to sine
		asr.w	#2,d0					; divide by 4
		move.w	d0,ost_y_vel(a0)			; set as y speed
		move.w	#-$100,ost_x_vel(a0)			; move ship left
		bsr.w	BossMove				; update parent position
		cmpi.w	#$1910,ost_boss_parent_x_pos(a0)	; has boss reached target position?
		bne.s	.not_at_pos				; if not, branch
		addq.b	#2,ost_mode(a0)				; goto BMZ_ShipMove next
		clr.b	ost_subtype(a0)
		clr.l	ost_x_vel(a0)				; stop moving

	.not_at_pos:
		jsr	(RandomNumber).w
		move.b	d0,ost_boss_fireball_time(a0)		; set fireball timer to random value

BMZ_Update:
		move.w	ost_boss_parent_y_pos(a0),ost_y_pos(a0)	; update actual position
		move.w	ost_boss_parent_x_pos(a0),ost_x_pos(a0)
		cmpi.b	#id_BMZ_Explode,ost_mode(a0)
		bcc.s	.exit
		tst.b	ost_status(a0)				; has boss been beaten?
		bmi.s	.beaten					; if yes, branch
		tst.b	ost_col_type(a0)			; is ship collision clear?
		bne.s	.exit					; if not, branch
		tst.b	ost_boss_flash_num(a0)			; is ship flashing?
		bne.s	.flash					; if yes, branch
		move.b	#$28,ost_boss_flash_num(a0)		; set ship to flash 40 times
		play.w	1, jsr, sfx_BossHit			; play boss damage sound

	.flash:
		lea	(v_pal_dry_line2+2).w,a1		; load 2nd palette, 2nd entry
		moveq	#0,d0					; move 0 (black) to d0
		tst.w	(a1)					; is colour white?
		bne.s	.is_white				; if yes, branch
		move.w	#cWhite,d0				; move $EEE (white) to d0

	.is_white:
		move.w	d0,(a1)					; load colour stored in	d0
		subq.b	#1,ost_boss_flash_num(a0)		; decrement flash counter
		bne.s	.exit					; branch if not 0
		move.b	#id_React_Boss,ost_col_type(a0)		; enable boss collision again

	.exit:
		rts	
; ===========================================================================

.beaten:
		moveq	#100,d0
		jsr	(AddPoints).w				; give Sonic 1000 points
		move.b	#id_BMZ_Explode,ost_mode(a0)
		move.w	#180,ost_boss_wait_time(a0)		; set timer to 3 seconds
		clr.w	ost_x_vel(a0)				; stop boss moving
		rts	
; ===========================================================================

BMZ_ShipMove:
		moveq	#0,d0
		move.b	ost_subtype(a0),d0
		move.w	BMZ_ShipMove_Index(pc,d0.w),d0
		jsr	BMZ_ShipMove_Index(pc,d0.w)		; jump to subroutine based on subtype
		andi.b	#6,ost_subtype(a0)			; clear bits except bits 1-2
		bra.w	BMZ_Update				; update actual position, check for hits
; ===========================================================================
BMZ_ShipMove_Index:
		index *,,2
		ptr BMZ_ChgDir
		ptr BMZ_DropFire
		ptr BMZ_ChgDir
		ptr BMZ_DropFire
; ===========================================================================

BMZ_ChgDir:
		tst.w	ost_x_vel(a0)				; is ship moving horizontally?
		bne.s	.is_moving_h				; if yes, branch
		moveq	#$40,d0					; ship should move down
		cmpi.w	#$22C,ost_boss_parent_y_pos(a0)		; is ship at its highest? (i.e. above platform)
		beq.s	.at_peak				; if yes, branch
		bcs.s	.above_max				; branch if ship goes above max
		neg.w	d0					; ship should move up

	.above_max:
		move.w	d0,ost_y_vel(a0)			; set y speed
		bra.w	BossMove				; update parent position
; ===========================================================================

.at_peak:
		move.w	#$200,ost_x_vel(a0)			; move ship right
		move.w	#$100,ost_y_vel(a0)			; move ship down
		btst	#status_xflip_bit,ost_status(a0)	; is ship facing left?
		bne.s	.face_right				; if not, branch
		neg.w	ost_x_vel(a0)				; move left instead

.is_moving_h:
	.face_right:
		cmpi.b	#$18,ost_boss_flash_num(a0)		; has boss recently been hit?
		bcc.s	.skip_movement				; if yes, branch
		bsr.w	BossMove
		subq.w	#4,ost_y_vel(a0)

	.skip_movement:
		subq.b	#1,ost_boss_fireball_time(a0)		; decrement fireball timer
		bcc.s	.skip_fireball				; branch if time remains

		jsr	(FindFreeObj).l				; find free OST slot
		bne.s	.fail					; branch if not found
		move.l	#FireBall,ost_id(a1)			; load fireball object that comes from lava
		move.w	#$2E8,ost_y_pos(a1)			; set y position as beneath lava
		move.b	#type_fire_gravity+4,ost_subtype(a1)
		jsr	(RandomNumber).w
		andi.l	#$FFFF,d0
		divu.w	#$50,d0
		swap	d0
		addi.w	#$1878,d0
		move.w	d0,ost_x_pos(a1)			; randomise x pos
		lsr.b	#7,d1
		move.b	#$FF,ost_fireball_mz_boss(a1)		; flag fireball as being spawned by boss

	.fail:
		jsr	(RandomNumber).w
		andi.b	#$1F,d0
		addi.b	#$40,d0
		move.b	d0,ost_boss_fireball_time(a0)		; reset fireball timer as random

	.skip_fireball:
		btst	#status_xflip_bit,ost_status(a0)	; is ship facing right?
		beq.s	.chk_left				; if yes, branch
		cmpi.w	#$1910,ost_boss_parent_x_pos(a0)	; is boss on far right of screen?
		blt.s	.exit					; if not, branch
		move.w	#$1910,ost_boss_parent_x_pos(a0)	; keep from moving further
		bra.s	.stop_moving_h
; ===========================================================================

.chk_left:
		cmpi.w	#$1830,ost_boss_parent_x_pos(a0)	; is boss on far left of screen?
		bgt.s	.exit					; if not, branch
		move.w	#$1830,ost_boss_parent_x_pos(a0)	; keep from moving further

.stop_moving_h:
		clr.w	ost_x_vel(a0)				; stop moving horizontally
		move.w	#-$180,ost_y_vel(a0)			; move straight up
		cmpi.w	#$22C,ost_boss_parent_y_pos(a0)		; is ship at its highest?
		bcc.s	.drop_fire				; if not, branch
		neg.w	ost_y_vel(a0)				; start moving down

	.drop_fire:
		addq.b	#2,ost_subtype(a0)			; goto BMZ_DropFire next

.exit:
		rts	
; ===========================================================================

BMZ_DropFire:
		bsr.w	BossMove				; update parent position
		move.w	ost_boss_parent_y_pos(a0),d0
		subi.w	#$22C,d0
		bgt.s	.exit					; branch if ship is below highest
		move.w	#$22C,d0
		tst.w	ost_y_vel(a0)
		beq.s	.skip_fireball				; branch if ship already stopped moving up
		clr.w	ost_y_vel(a0)				; stop ship moving up
		move.w	#80,ost_boss_wait_time(a0)		; set timer to 1.3 seconds
		bchg	#status_xflip_bit,ost_status(a0)	; turn ship around
		jsr	(FindFreeObj).l				; find free OST slot
		bne.s	.skip_fireball				; branch if not found
		move.w	ost_boss_parent_x_pos(a0),ost_x_pos(a1)
		move.w	ost_boss_parent_y_pos(a0),ost_y_pos(a1)
		addi.w	#$18,ost_y_pos(a1)
		move.l	#BossFire,ost_id(a1)			; load fireball object that comes from ship
		move.b	#1,ost_subtype(a1)			; set type to vertical

	.skip_fireball:
		subq.w	#1,ost_boss_wait_time(a0)		; decrement timer
		bne.s	.exit					; branch if time remains
		addq.b	#2,ost_subtype(a0)			; goto BMZ_ChgDir next

	.exit:
		rts	
; ===========================================================================

BMZ_Explode:
		subq.w	#1,ost_boss_wait_time(a0)		; decrement timer
		bmi.s	.stop_exploding				; branch if below 0
		bra.w	BossExplode				; load explosion object
; ===========================================================================

.stop_exploding:
		bset	#status_xflip_bit,ost_status(a0)	; ship face right
		bclr	#status_broken_bit,ost_status(a0)
		clr.w	ost_x_vel(a0)				; stop moving
		addq.b	#2,ost_mode(a0)				; goto BMZ_Recover next
		move.w	#-$26,ost_boss_wait_time(a0)		; set timer (counts up)
		tst.b	(v_boss_status).w
		bne.s	.exit
		move.b	#1,(v_boss_status).w			; set boss beaten flag
		clr.w	ost_y_vel(a0)

	.exit:
		rts	
; ===========================================================================

BMZ_Recover:
		addq.w	#1,ost_boss_wait_time(a0)		; increment timer
		beq.s	.stop_falling				; branch if 0
		bpl.s	.ship_recovers				; branch if 1 or more
		cmpi.w	#$270,ost_boss_parent_y_pos(a0)
		bcc.s	.stop_falling				; branch if ship drops below $270 on y axis
		addi.w	#$18,ost_y_vel(a0)			; apply gravity (falls)
		bra.s	.update
; ===========================================================================

.stop_falling:
		clr.w	ost_y_vel(a0)				; stop falling
		clr.w	ost_boss_wait_time(a0)
		bra.s	.update
; ===========================================================================

.ship_recovers:
		cmpi.w	#$30,ost_boss_wait_time(a0)		; have 48 frames passed since ship stopped falling?
		bcs.s	.ship_rises				; if not, branch
		beq.s	.stop_rising				; if exactly 48, branch
		cmpi.w	#$38,ost_boss_wait_time(a0)		; have 56 frames passed since ship stopped rising?
		bcs.s	.update					; if not, branch
		addq.b	#2,ost_mode(a0)				; if yes, goto BMZ_Escape next
		bra.s	.update
; ===========================================================================

.ship_rises:
		subq.w	#8,ost_y_vel(a0)			; move ship upwards
		bra.s	.update
; ===========================================================================

.stop_rising:
		clr.w	ost_y_vel(a0)				; stop ship rising
		play.w	0, jsr, mus_MZ				; play MZ music

.update:
		bsr.w	BossMove				; update parent position
		bra.w	BMZ_Update				; update actual position
; ===========================================================================

BMZ_Escape:
		move.w	#$500,ost_x_vel(a0)			; move ship right
		move.w	#-$40,ost_y_vel(a0)			; move ship upwards
		cmpi.w	#$1960,(v_boundary_right).w		; check for new boundary
		bcc.s	.chkdel
		addq.w	#2,(v_boundary_right).w			; expand right edge of level boundary
		bra.s	.update
; ===========================================================================

.chkdel:
		tst.b	ost_render(a0)				; is ship on-screen?
		bpl.s	.delete					; if not, branch

.update:
		bsr.w	BossMove				; update parent position
		bra.w	BMZ_Update				; update actual position
; ===========================================================================

.delete:
		addq.l	#4,sp
		jmp	(DeleteObject).l
