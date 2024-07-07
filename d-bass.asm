
.include "d-bass.inc"

.import DBASS_USER_NMI_HANDLER
.import DBASS_USER_IRQ_HANDLER
.import DBASS_SPRITES

.segment "ZEROPAGE"

dbass_nmi_counter: .res 1

dbass_period: .res 2
dbass_volume: .res 1

irq_counter_lo: .res 1
irq_counter_hi: .res 1

irq_durations: .res 2

irq_idx: .res 1

irq_user_counter: .res 1

user_irq_index: .res 1

sync_ticks: .res 1
sync_ticks_lo: .res 1

expected_nmi_user_counter: .res 1
nmi_user_counter: .res 1

.segment "BSS"

dbass_user_times_irqs: .res DBASS_MAX_USER_IRQ_COUNT
dbass_user_times_ticks: .res DBASS_MAX_USER_IRQ_COUNT

user_syncs_ticks: .res DBASS_MAX_USER_IRQ_COUNT

user_irq_counters: .res DBASS_MAX_USER_IRQ_COUNT

.segment "CODE"

dbass_irq_handler:
	pha

	lda irq_idx
	sta $4012

	lda #$1f
	sta $4015

	dec irq_user_counter
	beq RunUserIRQ
IRQ_Continue:
	dec irq_counter_hi

	beq :+
	
	pla
	rti
:

	lda irq_idx
	bne @Idx1

	lda irq_durations+1
	sta irq_counter_hi
	
	lda #1
	sta irq_idx

	pla
	rti

@Idx1:

	lda #0
	sta irq_idx

	clc
	lda irq_counter_lo
	adc dbass_period+0
	sta irq_counter_lo

	lda #0
	adc irq_durations+0
	sta irq_counter_hi

	pla
	rti

RunUserIRQ:
	tya
	pha

	ldy user_irq_index
	
	; Update counter for next user IRQ
	lda user_irq_counters, y
	sta irq_user_counter

	; Delay by 8*(user_sync_ticks) cpu cycles.
	lda user_syncs_ticks, y ; carry is set - sync is never above 71
	sec
@DelayLoop:
	bit $00        ; 3
	sbc #1         ; 2
	bcs @DelayLoop ; 3
	jsr DBASS_USER_IRQ_HANDLER
	pla
	tay
	inc user_irq_index

	jmp IRQ_Continue

dbass_init:
	lda #1
	sta irq_counter_hi
	rts

dbass_update:
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
	ldx #DBASS_MAX_USER_IRQ_COUNT-1
@UserTimeLoop:
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
	bpl @UserTimeLoop

	; Compute expected_nmi_user_counter:
	;   expected_nmi_user_counter = user_time_irqs[-1] - frame_time_irqs
	lda user_irq_counters+DBASS_MAX_USER_IRQ_COUNT-1
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
	cpx #DBASS_MAX_USER_IRQ_COUNT-1
	bcc @UserIrqCountersLoop
	
	lda #0
	sta user_irq_counters+DBASS_MAX_USER_IRQ_COUNT-1

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

	lda dbass_volume
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

	; volume can be at most half the period minus 1
	lda dbass_period+1
	sec
	sbc #1
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

.segment "DATA"

.repeat 64
	.byte $00
.endrepeat

.byte $ff
