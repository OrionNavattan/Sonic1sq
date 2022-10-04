; ---------------------------------------------------------------------------
; Sprite mappings - blocks (LZ)
; ---------------------------------------------------------------------------
Map_LBlock:	index *
		ptr frame_lblock_sinkblock
		ptr frame_lblock_riseplatform
		ptr frame_lblock_block
		
frame_lblock_sinkblock:
		spritemap					; block, sinks when stood on
		piece	-$10, -$10, 4x4, 0
		endsprite
		
frame_lblock_riseplatform:
		spritemap					; platform, rises when stood on
		piece	-$20, -$C, 4x3, 0
		piece	0, -$C, 4x3, $C
		endsprite
		
frame_lblock_block:
		spritemap					; block
		piece	-$10, -$10, 4x4, 0
		endsprite
		even
