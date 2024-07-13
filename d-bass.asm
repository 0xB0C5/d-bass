
.include "d-bass.inc"

.import DBASS_USER_IRQ_HANDLER
.import DBASS_SPRITES

.segment DBASS_ZP_SEGMENT

dbass_nmi_counter: .res 1

dbass_period: .res 2
dbass_volume: .res 1

irq_counter_lo: .res 1
irq_counter_hi: .res 1

irq_durations: .res 2

dmc_sample: .res 1

irq_user_counter: .res 1

user_irq_index: .res 1

sync_ticks: .res 1
sync_ticks_lo: .res 1

expected_nmi_user_counter: .res 1
nmi_user_counter: .res 1

.segment DBASS_BSS_SEGMENT

dbass_user_times_irqs: .res DBASS_USER_IRQ_COUNT
dbass_user_times_ticks: .res DBASS_USER_IRQ_COUNT

user_syncs_ticks: .res DBASS_USER_IRQ_COUNT

user_irq_counters: .res DBASS_USER_IRQ_COUNT

.segment DBASS_SAMPLES_SEGMENT

.align 64

samples:
	.byte $00
.align 64
	.byte $ff

sample0 = <((samples - $c000) / 64)

.segment DBASS_CODE_SEGMENT

dbass_irq_handler:
	pha

	lda dmc_sample
	sta $4012

	lda #$1f
	sta $4015

	dec irq_user_counter
	beq run_user_irq
irq_continue:
	dec irq_counter_hi

	beq :+
	
	pla
	rti
:

	lda dmc_sample
	cmp #sample0

	bne @odd_update

	; even update
	lda #sample0 + 1
	sta dmc_sample

	lda irq_durations+1
	sta irq_counter_hi
	
	pla
	rti

@odd_update:
	lda #sample0
	sta dmc_sample

	clc
	lda irq_counter_lo
	adc dbass_period+0
	sta irq_counter_lo

	lda #0
	adc irq_durations+0
	sta irq_counter_hi

	pla
	rti

run_user_irq:
	txa
	pha
	tya
	pha

	ldy user_irq_index
	
	; Update counter for next user IRQ
	lda user_irq_counters, y
	sta irq_user_counter

	; Delay by 8*(user_sync_ticks) cpu cycles.
	lda user_syncs_ticks, y ; carry is set - sync is never above 71
	sec
@delay_loop:
	bit $00         ; 3
	sbc #1          ; 2
	bcs @delay_loop ; 3
	jsr DBASS_USER_IRQ_HANDLER
	pla
	tay
	pla
	tax
	inc user_irq_index

	jmp irq_continue

dbass_init:
	lda #1
	sta irq_counter_hi
	rts

dbass_update:
	; Update user IRQs.

	lda #0
	sta user_irq_index

	; Update sync based on expected_nmi_user_counter
	lda nmi_user_counter
	cmp expected_nmi_user_counter
	beq @end_sync_reset

	lda #0
	sta sync_ticks
	sta sync_ticks_lo

@end_sync_reset:

	sei

	; Compute user times with sync.
	; Store in user_irq_counters.
	ldx #DBASS_USER_IRQ_COUNT-1
@user_time_loop:
	lda dbass_user_times_ticks, x
	clc
	adc sync_ticks
	cmp #72
	bcc :+
	sbc #72
:
	sta user_syncs_ticks, x

	lda dbass_user_times_irqs, x
	adc #0
	sta user_irq_counters, x
	dex
	bpl @user_time_loop

	; Compute expected_nmi_user_counter:
	;   expected_nmi_user_counter = user_irq_counters[-1] - frame_time_irqs
	lda user_irq_counters+DBASS_USER_IRQ_COUNT-1
	sec
	sbc #51 ; Whole IRQs per frame
	sta expected_nmi_user_counter

	; Compute irq_user_counter:
	;   irqs_so_far = nmi_user_counter - irq_user_counter
	;   irq_user_counter = user_irq_counters[0] - irqs_so_far
	;         = user_irq_counters[0] + irq_user_counter - nmi_user_counter
	lda user_irq_counters+0
	clc
	adc irq_user_counter
	sec
	sbc nmi_user_counter
	sta irq_user_counter

	; Update user_irq_counters to be relative.
	ldx #0
@user_irq_counters_loop:
	
	lda user_irq_counters+1, x
	sec
	sbc user_irq_counters, x
	sta user_irq_counters, x

	inx
	cpx #DBASS_USER_IRQ_COUNT
	bne @user_irq_counters_loop

	lda #0
	sta user_irq_counters+DBASS_USER_IRQ_COUNT-1

	cli

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

	; Update audio
	sei

	lda dbass_volume
	bne :+
	; Silence: set the pending DMC sample to the all-zero sample.
	; Set irq counter so no updates will occur this frame.
	lda #sample0
	sta dmc_sample
	; TODO : a more forgiving way of doing this?
	lda #60 ; Give a little extra time of silence in case this subroutine isn't called at the same time each frame.
	sta irq_counter_hi

	cli
	rts
:
	sta irq_durations+1

	; Volume/irq_durations+1 can be at most half the period
	lda dbass_period+1
	lsr
	cmp irq_durations+1
	bcs :+
	sta irq_durations+1
:

	; remaining duration goes to irq_durations+0
	lda dbass_period+1
	sec
	sbc irq_durations+1
	sta irq_durations+0

	cli

	rts

dbass_nmi_handler:
	pha
	lda irq_user_counter
	sta nmi_user_counter

	lda #>DBASS_SPRITES
    sta $4014

	inc dbass_nmi_counter
	pla

	rti
