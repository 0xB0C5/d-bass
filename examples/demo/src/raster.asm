
SUBTICKS_PER_LINE = 3637
TICKS_PER_IRQ = 72

LINE_COUNT = 224

; TODO : make this actually match the start line!
START_LINE_SUBTICKS = (4 * TICKS_PER_IRQ * 256 + 800)

LineIrqs:
.repeat LINE_COUNT, I
	.byte ((START_LINE_SUBTICKS + I*SUBTICKS_PER_LINE) / 256) / TICKS_PER_IRQ
.endrepeat

LineTicks:
.repeat LINE_COUNT, I
	.byte ((START_LINE_SUBTICKS + I*SUBTICKS_PER_LINE) / 256) .MOD TICKS_PER_IRQ
.endrepeat


Wave:
	.byte 11, 12, 13, 14, 14, 15, 16, 16, 17, 17, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20, 20, 21, 21, 21, 21
	.byte 21, 21, 21, 21, 20, 20, 20, 20, 20, 19, 19, 19, 19, 18, 18, 18, 17, 17, 16, 16, 15, 14, 14, 13, 12, 11
	.byte 10,  9,  8,  7,  7,  6,  5,  5,  4,  4,  3,  3,  3,  2,  2,  2,  2,  1,  1,  1,  1,  1,  0,  0,  0,  0
	.byte  0,  0,  0,  0,  1,  1,  1,  1,  1,  2,  2,  2,  2,  3,  3,  3,  4,  4,  5,  5,  6,  7,  7,  8,  9, 10

WAVE_LEN = 4*26

OffsetsY:
	.byte 19, 48+19, 96+19, 144+19

SR_InitRasterFX:
.if DBASS_USER_IRQ_COUNT

	lda #0
	tax
@Loop:
	sta raster_wave_indices, x
	clc
	adc #13
	inx
	cpx #DBASS_USER_IRQ_COUNT
	bne @Loop
.endif
	rts

SR_UpdateRasterFX:
.if DBASS_USER_IRQ_COUNT

	ldx #DBASS_USER_IRQ_COUNT-1
	
@Loop:

	ldy raster_wave_indices, x
	iny
	cpy #WAVE_LEN
	bne :+
	ldy #0
:
	sty raster_wave_indices, x

	lda Wave, y
	asl
	
	clc
	adc OffsetsY, x
	
	tay
	lda LineIrqs, y
	sta dbass_user_times_irqs, x
	lda LineTicks, y
	sta dbass_user_times_ticks, x
	
	dex
	bpl @Loop
.endif

	rts


.proc user_irq_handler
	lda pending_ppu_mask
	eor #%00100001
	sta PPUMASK
	sta pending_ppu_mask
	rts
.endproc
.export user_irq_handler
