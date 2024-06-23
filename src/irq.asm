
.segment "CODE"

IRQ_M:
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



_UserIrq:
	jmp (user_irq)

IRQ:
	pha

	lda irq_pending_sample
	sta $4012

	lda #$10
	sta $4015

	dec irq_user_counter
	beq _UserIrq
IRQ_Continue:
	dec irq_counter_hi

	beq :+
	
	lda irq_idx
	sta irq_pending_sample
	
	pla
	rti
:

	lda irq_idx
	bne @Idx1

	lda irq_durations+1
	sta irq_counter_hi
	
	lda #1
	sta irq_idx

	bit irq_counter_lo
	bpl :+
	ora #2
:
	sta irq_pending_sample

	pla
	rti

@Idx1:

	lda #0
	sta irq_idx

	bit irq_counter_lo
	bpl :+
	ora #2
:

	sta irq_pending_sample

	clc
	lda irq_counter_lo
	adc dmc_period_lo
	sta irq_counter_lo

	lda #0
	adc irq_durations+0
	sta irq_counter_hi

	pla
	rti

UserIRQ:
	; Delay by 8*(user_sync_ticks) cpu cycles.
	lda user_sync_ticks ; carry is set - sync is never above 71
	sec
@DelayLoop:
	bit $00        ; 3
	sbc #1         ; 2
	bcs @DelayLoop ; 3

	lda pending_ppu_mask
	sta PPUMASK
	eor #1
	sta pending_ppu_mask

	jmp IRQ_Continue
