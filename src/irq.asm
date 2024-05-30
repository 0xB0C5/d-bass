
.segment "CODE"

IRQ:
	pha

	lda #$10
	sta $4015

	dec irq_counter_hi

	bne @End

	clc
	lda irq_idx
	and #1
	sta $4012
	lda irq_idx
	beq @Idx0
	cmp #1
	beq @Idx1
	cmp #2
	beq @Idx2
	
	lda irq_durations+3
	sta irq_counter_hi
	
	lda #0
	sta irq_idx
	
@End:
	pla
	rti

@Idx2:
	lda irq_durations+2
	sta irq_counter_hi

	lda #3
	sta irq_idx

	pla
	rti
@Idx1:
	lda irq_durations+1
	sta irq_counter_hi
	
	lda irq_next1
	sta irq_idx

	pla
	rti
@Idx0:
	lda irq_counter_lo
	adc dmc_period_lo
	sta irq_counter_lo

	lda #0
	adc irq_durations+0
	sta irq_counter_hi

	lda #1
	sta irq_idx

	pla
	rti

