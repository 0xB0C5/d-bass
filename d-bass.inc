
.global dbass_irq_handler
.global dbass_nmi_handler
.global dbass_start
.global dbass_stop

.global dbass_user_times_irqs
.global dbass_user_times_ticks

.globalzp dbass_period
.globalzp dbass_volume

; ###################
; # D-Bass Settings #
; ###################

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
