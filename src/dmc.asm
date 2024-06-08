

SR_UpdateDmc:
	lda pending_ppu_mask
	and #$fe
	sta pending_ppu_mask

	sei
	
	lda sync_ticks_lo
	clc
	adc #144
	sta sync_ticks_lo

	; Add 50+carry to sync ticks, modulo 72,
	; storing whether we wrapped around in the carry.
	lda sync_ticks
	adc #50
	cmp #72
	bcc :+
	sbc #72
:
	sta sync_ticks

	; Add 51 + carry
	lda irq_user_counter
	adc #51
	sta irq_user_counter

	lda dmc_volume
	bne :+
	rts
:

	sta irq_durations+1

	lda #0 ; dmc_width
	sta irq_durations+2

	; volume can be at most half the period minus 1
	lda dmc_period_hi
	sec
	sbc #1
	lsr
	cmp irq_durations+1
	bcs :+
	sta irq_durations+1
:

	; width can be at most half the remaining duration (period minus 2 * volume)
	lda dmc_period_hi
	lsr
	sec
	sbc irq_durations+1
	cmp irq_durations+2
	bcs :+
	sta irq_durations+2
:

	; irq_next1 is the irq state after state 1.
	; This is 0 when width is 0, 2 otherwise.
	ldx #2
	lda irq_durations+2
	bne :+
	tax
	; Special case: if irq happens to be in state 2, force it into state 0
	lda irq_idx
	cmp #2
	bne :+
	stx irq_idx
:
	stx irq_next1

	; remaining duration goes to irq_durations+0
	lda dmc_period_hi
	sec
	sbc irq_durations+2
	sbc irq_durations+1
	sta irq_durations+0
	
	; OK now convert to new M wave thingy
	lda irq_durations+2
	beq @End
	lsr
	adc #0
	cmp irq_durations+1
	bcc :+
	lda irq_durations+1
:

	sta irq_durations+3

	lda irq_durations+2
	sec
	sbc irq_durations+3
	bne :+
	lda #1
	dec irq_durations+0
:
	sta irq_durations+2
	

@End:
	cli

	rts
