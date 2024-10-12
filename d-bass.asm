
.include "d-bass.inc"

.import DBASS_USER_IRQ_HANDLER
.import DBASS_USER_NMI_HANDLER

.ifdef DBASS_USER_FIXED_UPDATE
	.import DBASS_USER_FIXED_UPDATE
.endif

.segment DBASS_ZP_SEGMENT

.if DBASS_AUDIO_ENABLED
	dbass_period: .res 2
	dbass_volume: .res 1

	wave_counter_lo: .res 1
	wave_counter_hi: .res 1

	wave_durations: .res 2

	wave_sample: .res 1
.endif

.if DBASS_USER_IRQS_ENABLED
	dbass_user_irq_count: .res 1

	active_user_irq_count: .res 1

	user_irq_index: .res 1
	user_irq_counter: .res 1

	sync_ticks: .res 1
	sync_ticks_lo: .res 1

	expected_nmi_user_irq_counter: .res 1
	nmi_user_irq_counter: .res 1
.endif

nmi_temp: .res 2

irq_temp: .res 1

.segment DBASS_BSS_SEGMENT

.if DBASS_USER_IRQS_ENABLED
	dbass_user_times_irqs: .res DBASS_USER_IRQ_COUNT
	dbass_user_times_ticks: .res DBASS_USER_IRQ_COUNT

	user_syncs_ticks: .res DBASS_USER_IRQ_COUNT

	user_irq_counters: .res DBASS_USER_IRQ_COUNT
.endif

.segment DBASS_SAMPLES_SEGMENT

.align 64

samples:
	.byte $00

.if DBASS_AUDIO_ENABLED
	.align 64
		.byte $ff
.endif

sample0 = <((samples - $c000) / 64)

.segment DBASS_CODE_SEGMENT

; Align to a page:
; - to ensure branches don't take an extra cycle.
; - to make stack manipulation done in NMI simpler.
.align 256

dbass_irq_handler:
	sta irq_temp

.if DBASS_AUDIO_ENABLED
	lda wave_sample
.else
	lda #sample0
.endif
	sta $4012

	lda #$1f
	sta $4015

.if DBASS_USER_IRQS_ENABLED
	dec user_irq_counter

	beq run_user_irq
irq_continue:
.endif

.if DBASS_AUDIO_ENABLED
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

.endif

	lda irq_temp
	rti

dbass_irq_handler_end:

.if DBASS_USER_IRQS_ENABLED
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
.endif

dbass_start:
.if DBASS_USER_IRQS_ENABLED
	; Ensure user IRQs won't run until after dmc_update is called.
	lda #0
	sta user_irq_counter
	sta expected_nmi_user_irq_counter
.endif

.if DBASS_AUDIO_ENABLED
	; Ensure audio update will run on first IRQ.
	lda #1
	stx wave_counter_hi
.endif

	; Sample length = 1 byte.
	lda #0
	sta $4013

	; Sample address.
	lda #sample0
	sta $4012

	cli

	; Generate IRQs at rate $e.
	lda #$8e
	sta $4010

	; Enable DMC.
	lda #$1f
	sta $4015

	; wait for vblank
@wait_vblank:
    bit $2002
    bpl @wait_vblank

.if DBASS_USER_IRQS_ENABLED
	; Zero user_irq_counter and wait for it to be decremented,
	; decrementing x every 8 cycles.
	ldx #0
	stx user_irq_counter
@wait_irq:
	dex                   ; 2
	bit user_irq_counter  ; 3
	bpl @wait_irq         ; 3

	; x is now the negative time from NMI to an IRQ, in 8-cycle ticks.
	; In theory, we should add 72 to convert to positive time from IRQ to NMI,
	; and add 50 to get the sync for the *next* frame.
	; In practice, it seems timing differences mean we add 72 + 46.
	; I'm not entirely sure what those differences are, but it seems to work well enough.
	txa
	clc
	adc #72+46
	; Wrap around to 0 if at least 72.
	cmp #72
	bcc :+
	sbc #72
:
	sta sync_ticks

	lda #0
	sta sync_ticks_lo
.endif

	rts

dbass_stop:
	; Stop generating IRQs.
	lda #$0e
	sta $4015

	; Disable DMC.
	lda #$0f
	sta $4015

	rts

dbass_nmi_handler:
	sta nmi_temp

.if DBASS_USER_IRQS_ENABLED
	lda user_irq_counter
	sta nmi_user_irq_counter
.endif

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
	; We need to enable IRQs during NMI or else audio will cut out and user IRQs will desync.
	; But we can't enable IRQs if there's already an IRQ happening, since it can double trigger.
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
	; Now that an IRQ is not happening, we can safely allow more IRQs to be triggered.
	cli
	tya
	pha
	jsr DBASS_USER_NMI_HANDLER

	; Update user IRQs.
.if DBASS_USER_IRQS_ENABLED
	lda #0
	sta user_irq_index

	; Update sync based on expected_nmi_user_irq_counter
	lda expected_nmi_user_irq_counter
	; expected_nmi_user_irq_counter being set to 0 means it wasn't computed, and we shouldn't reset the sync.
	beq @end_sync_reset
	cmp nmi_user_irq_counter
	beq @end_sync_reset

	lda #0
	sta sync_ticks
	sta sync_ticks_lo

@end_sync_reset:

	sei

	; Compute user times with sync.
	; Store in user_irq_counters.
	ldx dbass_user_irq_count
	stx active_user_irq_count
	bne @nonzero_user_irq_count

	; No user IRQs are enabled.
	lda #256-51
	sta expected_nmi_user_irq_counter

	lda user_irq_counter
	sec
	sbc nmi_user_irq_counter
	sta user_irq_counter

	jmp @end_update_counters

@nonzero_user_irq_count:
	dex
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
	ldx active_user_irq_count
	lda user_irq_counters-1, x
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
	cpx active_user_irq_count
	bne @user_irq_counters_loop

	lda #0
	; x is active_user_irq_count.
	sta user_irq_counters-1, x

@end_update_counters:
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
.endif

.ifdef DBASS_USER_FIXED_UPDATE
	jsr DBASS_USER_FIXED_UPDATE
.endif

.if DBASS_AUDIO_ENABLED
	; Update audio
	sei

	lda dbass_volume
	bne :+
	; Silence: set the pending DMC sample to the all-zero sample.
	; Set irq counter so no updates will occur this frame.
	lda #sample0
	sta wave_sample
	; TODO : a more forgiving way of doing this?
	lda #60 ; Give a little extra time of silence in case this isn't run at the same time each frame.
	sta wave_counter_hi
	jmp @end_nmi_update
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

@end_nmi_update:
	cli
.endif

	pla
	tay
	lda nmi_temp
	ldx nmi_temp+1

	rti
