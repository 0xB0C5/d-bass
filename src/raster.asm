
SUBTICKS_PER_LINE = 3637
TICKS_PER_IRQ = 72

LINE_COUNT = 224

; TODO : make this actually match the start line!
START_LINE_SUBTICKS = (4 * TICKS_PER_IRQ * 256 + 1000) + 10*SUBTICKS_PER_LINE

LineIrqs:
.repeat LINE_COUNT, I
	.byte ((START_LINE_SUBTICKS + I*SUBTICKS_PER_LINE) / 256) / TICKS_PER_IRQ
.endrepeat

LineTicks:
.repeat LINE_COUNT, I
	.byte ((START_LINE_SUBTICKS + I*SUBTICKS_PER_LINE) / 256) .MOD TICKS_PER_IRQ
.endrepeat


SR_UpdateRasterFX:
	lda pending_ppu_mask
	and #%11011110
	sta pending_ppu_mask

	lda raster_direction
	bne @RasterDecrement
	
	inc raster_lines+0
	bpl @EndLine0
	inc raster_direction
	jmp @EndLine0
@RasterDecrement:
	dec raster_lines+0
	bne @EndLine0
	dec raster_direction
@EndLine0:

	lda raster_lines+0
	ldx #1
@FillLoop:
	clc
	adc #16
	sta raster_lines, x
	inx
	cpx #MAX_USER_IRQ_COUNT
	bne @FillLoop

	ldx #MAX_USER_IRQ_COUNT-1
@Line2TimeLoop:
	ldy raster_lines, x
	lda LineIrqs, y
	sta user_times_irqs, x
	lda LineTicks, y
	sta user_times_ticks, x
	dex
	bpl @Line2TimeLoop

	rts

