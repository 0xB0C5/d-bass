

SR_UpdateDmc:
	lda pending_ppu_mask
	and #%11011110
	sta pending_ppu_mask

	; Uhhh this doesn't go here.
	dec user_time_ticks
	bpl @EndUserTimeUpdate
	lda #71
	sta user_time_ticks
	ldx user_time_irqs
	dex
	cpx #10
	bcs :+
	ldx #40
:
	stx user_time_irqs

@EndUserTimeUpdate:
	
	sei

	; Update sync based on expected_nmi_user_counter
	lda nmi_user_counter
	cmp expected_nmi_user_counter
	bpl @EndSyncUpdate

	lda #0
	sta sync_ticks
	sta sync_ticks_lo

	lda pending_ppu_mask
	ora #%00100000
	sta pending_ppu_mask

@EndSyncUpdate:

	; Compute expected_nmi_user_counter:
	;   expected_nmi_user_counter = user_time_irqs - frame_time_irqs
	lda user_time_irqs
	sec
	sbc #51 ; Whole IRQs per frame
	sta expected_nmi_user_counter

	; Compute irq_user_counter:
	;   irqs_so_far = nmi_user_counter - irq_user_counter
	;   irq_user_counter = user_time_irqs - irqs_so_far
	;         = user_time_irqs + irq_user_counter - nmi_user_counter
	lda user_time_irqs
	clc
	adc irq_user_counter
	sec
	sbc nmi_user_counter
	sta irq_user_counter

	lda sync_ticks
	clc
	adc user_time_ticks
	cmp #72
	bcc :+
	sbc #72
	inc irq_user_counter
	inc expected_nmi_user_counter
:
	sta user_sync_ticks

	; Update sync to next frame.
	lda sync_ticks_lo
	clc
	adc #143 ; Very slightly underestimate sync change, because we only correct in one direction.
	sta sync_ticks_lo
	
	lda sync_ticks
	adc #50
	cmp #72
	bcc :+
	sbc #72
	; If the sync wraps, there is 1 extra IRQ that frame.
	dec expected_nmi_user_counter
:
	sta sync_ticks

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
