

SR_UpdateDmc:
	lda #0
	sta user_irq_index

	; Update sync based on expected_nmi_user_counter
	lda nmi_user_counter
	cmp expected_nmi_user_counter
	beq @EndSyncUpdate

	lda #0
	sta sync_ticks
	sta sync_ticks_lo

@EndSyncUpdate:

	; TODO : figure out best way to handle sei/cli
	sei

	; Compute user times.
	; Store in user_irq_counters.
	ldx #MAX_USER_IRQ_COUNT-1
@UserTimeLoop:
	lda user_times_ticks, x
	clc
	adc sync_ticks
	cmp #72
	bcc :+
	sbc #72
:
	sta user_syncs_ticks, x

	lda user_times_irqs, x
	adc #0
	sta user_irq_counters, x
	dex
	bpl @UserTimeLoop

	; Compute expected_nmi_user_counter:
	;   expected_nmi_user_counter = user_time_irqs[-1] - frame_time_irqs
	lda user_irq_counters+MAX_USER_IRQ_COUNT-1
	sec
	sbc #51 ; Whole IRQs per frame
	sta expected_nmi_user_counter

	; Compute irq_user_counter:
	;   irqs_so_far = nmi_user_counter - irq_user_counter
	;   irq_user_counter = user_time_irqs - irqs_so_far
	;         = user_time_irqs + irq_user_counter - nmi_user_counter
	lda user_irq_counters+0
	clc
	adc irq_user_counter
	sec
	sbc nmi_user_counter
	sta irq_user_counter

	; Update user_irq_counters to be relative.
	ldx #0 ; inx?
@UserIrqCountersLoop:
	
	lda user_irq_counters+1, x
	sec
	sbc user_irq_counters, x
	sta user_irq_counters, x
	
	inx
	cpx #MAX_USER_IRQ_COUNT-1
	bcc @UserIrqCountersLoop
	
	lda #0
	sta user_irq_counters+MAX_USER_IRQ_COUNT-1

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

	; TODO : figure out sei/cli

	cli
	nop
	sei

	lda dmc_volume
	bne :+
	; Silence: clear irq_idx so the samples we write are 0s.
	; set irq counter so no updates will occur this frame.
	sta irq_idx
	; TODO : a more forgiving way of doing this?
	lda #60 ; Give a little extra time of silence in case this subroutine isn't called at the same time each frame.
	sta irq_counter_hi

	cli
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
