
.segment "CODE"

IRQ:
	pha

	; Output:
	; 	If non-zero, output sample address 1 and decrement dmc_output
	lda dmc_output
	beq :+
	lda #1
	dec dmc_output
:
	sta $4012

	lda #$10
	sta $4015

	; Pseudochannels:
.repeat 2, I
	; Decrement counter.
	; When it hits 0, add period to counter, and add volume to output.
	dec dmc_counters_hi+I
	bne :+
	lda dmc_counters_lo+I
	clc
	adc dmc_periods_lo+I
	sta dmc_counters_lo+I
	
	lda dmc_periods_hi+I
	adc #0
	sta dmc_counters_hi+I

	lda dmc_volumes+I
	cmp dmc_output
	bcc :+
	sta dmc_output
:
.endrepeat

	pla
	rti

