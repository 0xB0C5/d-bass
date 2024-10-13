; ###################
; # D-Bass Settings #
; ###################

; Whether D-Bass should play audio. 0 to disable.
.define DBASS_AUDIO_ENABLED 1

; Whether D-Bass should generate user IRQs for raster effects. 0 to disable.
.define DBASS_USER_IRQS_ENABLED 1

; Segment for D-Bass zeropage variables.
.define DBASS_ZP_SEGMENT "ZEROPAGE"

; Segment for D-Bass BSS variables.
.define DBASS_BSS_SEGMENT "BSS"

; Segment for D-Bass code.
.define DBASS_CODE_SEGMENT "CODE"

; Segment for D-Bass DMC samples. Must be within $C000 - $ffff.
.define DBASS_SAMPLES_SEGMENT "DATA"

; Your custom NMI handler.
.define DBASS_USER_NMI_HANDLER user_nmi_handler

; Your custom IRQ handler.
.define DBASS_USER_IRQ_HANDLER user_irq_handler

; Optional, a subroutine to run once per frame after the NMI handler.
.define DBASS_USER_FIXED_UPDATE_ENABLED 0
;.define DBASS_USER_FIXED_UPDATE fixed_update

; The number of times per frame your custom IRQ handler will be called.
.define DBASS_USER_IRQ_COUNT 4

; ##################
; # D-Bass Globals #
; ##################

.global dbass_irq_handler
.global dbass_nmi_handler
.global dbass_start
.global dbass_stop

.if DBASS_USER_IRQS_ENABLED
    .globalzp dbass_user_irq_count
    .global dbass_user_times_irqs
    .global dbass_user_times_ticks
.endif

.if DBASS_AUDIO_ENABLED
    .globalzp dbass_period
    .globalzp dbass_volume
.endif


; ##################
; # D-Bass Helpers #
; ##################

; The number of 256ths of a tick, from when D-Bass measures the NMI, to the hblank of the first scanline.
.define DBASS_LINE0_SUBTICKS 74750
; The number of 256ths of a tick per scanline.
.define DBASS_SUBTICKS_PER_LINE 3637

; These 2 macros compute the time for a raster effect to apply during the h-blank before a scanline.
;     line_number: The scanline number, from 0 to 239.
;     cpu_cycles: The number of cpu cycles the user IRQ takes to apply the effect.
; Example: set user IRQ 1, which takes 10 cpu cycles, to apply on scanline 100:
;     lda #dbass_hblank_irqs 100, 10
;     sta dbass_user_times_irqs + 1
;     lda #dbass_hblank_ticks 100, 10
;     sta dbass_user_times_ticks + 1
.define dbass_hblank_irqs (line_number, cpu_cycles) (((DBASS_LINE0_SUBTICKS + DBASS_SUBTICKS_PER_LINE*line_number - 32*cpu_cycles) / 256) / 72)
.define dbass_hblank_ticks (line_number, cpu_cycles) (((DBASS_LINE0_SUBTICKS + DBASS_SUBTICKS_PER_LINE*line_number - 32*cpu_cycles) / 256) .mod 72)
