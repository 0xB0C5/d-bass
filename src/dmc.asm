
DmcNotes:
	.byte 8,8,0,8,8,0,8,0,1,0,1,0,3,0,3,0,8,8,0,8,8,0,8,0,11,0,11,0,13,0,15,0

SR_UpdateDmc:
	
	dec song_counter
	bpl @End

	lda #6
	sta song_counter

	lda song_index
	tax
	clc
	adc #1
	and #$1f
	sta song_index

	lda DmcNotes, x
	
	bne :+
	lda #0
	sei
	sta dmc_volumes+0
	sta dmc_volumes+1
	sta dmc_counters_hi+0
	sta dmc_counters_hi+1
	
	jmp @End
:
	
	clc
	adc #10
	tay
	
	lda PeriodsLo, y
	sei
	sta dmc_periods_lo+0
	
	lda PeriodsHi, y
	sta dmc_periods_hi+0

	tya
	clc
	adc #16
	tay

	lda PeriodsLo, y
	sta dmc_periods_lo+1

	lda PeriodsHi, y
	sta dmc_periods_hi+1

	lda #12
	sta dmc_volumes+0
	lda #2
	sta dmc_volumes+1
@End:
	
	cli
	rts
