
SR_UpdateRasterFX:
	lda pending_ppu_mask
	and #%11011110
	sta pending_ppu_mask

	lda raster_direction
	bne @RasterDecrement

	lda user_time_ticks_lo
	clc
	adc #53
	sta user_time_ticks_lo
	
	lda user_time_ticks
	adc #14
	cmp #72
	bcc :+
	sbc #72
:
	sta user_time_ticks
	
	lda user_time_irqs
	adc #0
	cmp #40
	bcc :+
	inc raster_direction
:
	sta user_time_irqs
	rts

@RasterDecrement:
	lda user_time_ticks_lo
	sec
	sbc #53
	sta user_time_ticks_lo
	
	lda user_time_ticks
	sbc #14
	bcs :+
	adc #72
	clc
:
	sta user_time_ticks
	
	lda user_time_irqs
	sbc #0
	cmp #9
	bcs :+
	dec raster_direction
:
	sta user_time_irqs
	
	rts

