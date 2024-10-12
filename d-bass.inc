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
; .define DBASS_USER_FIXED_UPDATE fixed_update

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
