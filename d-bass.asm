
.include "d-bass.inc"

.import DBASS_USER_IRQ_HANDLER
.import DBASS_USER_NMI_HANDLER

.segment DBASS_ZP_SEGMENT

dbass_period: .res 2
dbass_volume: .res 1

wave_counter_lo: .res 1
wave_counter_hi: .res 1

wave_durations: .res 2

wave_sample: .res 1

user_irq_counter: .res 1
user_irq_index: .res 1

sync_ticks: .res 1
sync_ticks_lo: .res 1

expected_nmi_user_irq_counter: .res 1
nmi_user_irq_counter: .res 1

nmi_temp: .res 2

irq_temp: .res 1

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

.align 256

dbass_irq_handler:
	sta irq_temp

	lda wave_sample
	sta $4012

	lda #$1f
	sta $4015

	dec user_irq_counter
	beq run_user_irq
irq_continue:
	dec wave_counter_hi

	beq :+
	
	lda irq_temp
	rti
:

	lda wave_sample
	cmp #sample0

	bne @odd_update

	; even update
	lda #sample0 + 1
	sta wave_sample

	lda wave_durations+1
	sta wave_counter_hi
	
	lda irq_temp
	rti

@odd_update:
	lda #sample0
	sta wave_sample

	clc
	lda wave_counter_lo
	adc dbass_period+0
	sta wave_counter_lo

	lda #0
	adc wave_durations+0
	sta wave_counter_hi

	lda irq_temp
	rti

dbass_irq_handler_end:

run_user_irq:
	txa
	pha
	tya
	pha

	ldy user_irq_index

	; Update counter for next user IRQ
	lda user_irq_counters, y
	sta user_irq_counter

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

dbass_start:
	; Ensure user IRQs won't run until after dmc_update is called.
	lda #0
	sta user_irq_counter 

	; Ensure audio update will run on first IRQ.
	lda #1
	stx wave_counter_hi

	; Sample length = 1 byte.
	lda #0
	sta $4013

	; Sample address.
	lda #sample0
	sta $4012

	; Generate IRQs at rate $e.
	lda #$8e
	sta $4010

	; Enable DMC.
	lda #$1f
	sta $4015

	rts

dbass_stop:
	; Stop generating IRQs.
	lda #$0e
	sta $4015

	; Disable DMC.
	lda #$0f
	sta $4015

	rts

dbass_update:
	; Update user IRQs.

	lda #0
	sta user_irq_index

	; Update sync based on expected_nmi_user_irq_counter
	lda nmi_user_irq_counter
	cmp expected_nmi_user_irq_counter
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

	; Compute expected_nmi_user_irq_counter:
	;   expected_nmi_user_irq_counter = user_irq_counters[-1] - frame_time_irqs
	lda user_irq_counters+DBASS_USER_IRQ_COUNT-1
	sec
	sbc #51 ; Whole IRQs per frame
	sta expected_nmi_user_irq_counter

	; Compute user_irq_counter:
	;   irqs_so_far = nmi_user_irq_counter - user_irq_counter
	;   user_irq_counter = user_irq_counters[0] - irqs_so_far
	;         = user_irq_counters[0] + user_irq_counter - nmi_user_irq_counter
	lda user_irq_counters+0
	clc
	adc user_irq_counter
	sec
	sbc nmi_user_irq_counter
	sta user_irq_counter

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
	dec expected_nmi_user_irq_counter
:
	sta sync_ticks

	; Update audio
	sei

	lda dbass_volume
	bne :+
	; Silence: set the pending DMC sample to the all-zero sample.
	; Set irq counter so no updates will occur this frame.
	lda #sample0
	sta wave_sample
	; TODO : a more forgiving way of doing this?
	lda #60 ; Give a little extra time of silence in case this subroutine isn't called at the same time each frame.
	sta wave_counter_hi

	cli
	rts
:
	sta wave_durations+1

	; Volume/wave_durations+1 can be at most half the period
	lda dbass_period+1
	lsr
	cmp wave_durations+1
	bcs :+
	sta wave_durations+1
:

	; remaining duration goes to wave_durations+0
	lda dbass_period+1
	sec
	sbc wave_durations+1
	sta wave_durations+0

	cli

	rts

dbass_nmi_handler:
	sta nmi_temp
	lda user_irq_counter
	sta nmi_user_irq_counter

	stx nmi_temp+1
	; check if we're in an IRQ.
	tsx
	lda $103, x ; high byte of return address
	cmp #>dbass_irq_handler
	bne @no_irq
	lda $102, x ; low byte of return address
	cmp #<dbass_irq_handler_end
	bcs @no_irq

	; There's an IRQ happening.
	; Sneak in a new return address onto the stack for the IRQ handler.
	; stack: (sp) [flags] [<return] [>return]
	lda $103, x
	pha
	; stack: (sp) [>return] [flags] [<return] [>return]
	lda $102, x
	pha
	; stack: (sp) [<return] [>return] [flags] [<return] [>return]
	lda $101, x
	pha
	; stack: (sp) [flags] [<return] [>return] [flags] [<return] [>return]
	lda #<@continue
	sta $102, x
	; stack: (sp) [flags] [<return] [>return] [flags] [<@continue] [>return]
	lda #>@continue
	sta $103, x
	; stack: (sp) [flags] [<return] [>return] [flags] [<@continue] [>@continue]
	; restore registers and return to IRQ handler.
	lda nmi_temp
	ldx nmi_temp+1
	rti

@continue:
	sta nmi_temp
	stx nmi_temp+1

@no_irq:
	cli
	tya
	pha
	jsr DBASS_USER_NMI_HANDLER
	pla
	tay
	lda nmi_temp
	ldx nmi_temp+1

	rti
