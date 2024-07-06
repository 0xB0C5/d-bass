SPRITE_COUNT = 8

SpritePattern:
	.byte 0, 1, 2, 3, 3, 2, 1, 0

SpriteStartXs:
	.byte 12, 44, 76, 108, 140, 156, 204, 236

SpriteStartYs:
	.byte 0, 130, 36, 150, 72, 202, 108, 238

SR_InitSprites:

	ldx #(SPRITE_COUNT-1)*4
	ldy #SPRITE_COUNT-1
	
@Loop:
	lda SpriteStartXs, y
	sta sprites+3, x
	lda SpriteStartYs, y
	sta sprites+0, x

	lda #$21
	sta sprites+2, x

	dex
	dex
	dex
	dex
	dey
	bpl @Loop

	rts

SR_UpdateSprites:

	ldx #(SPRITE_COUNT-1)*4
@Loop:

	;inc sprites+3, x

	lda sprites+0, x
	clc
	adc #2
	sta sprites+0, x

	lsr
	lsr
	and #$07
	tay
	lda SpritePattern, y
	sta sprites+1, x
	
	dex
	dex
	dex
	dex
	bpl @Loop
	
	rts
