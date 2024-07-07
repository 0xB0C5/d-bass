
.global dbass_irq_handler
.global dbass_nmi_handler
.global dbass_init
.global dbass_update

.global dbass_user_times_irqs
.global dbass_user_times_ticks

.globalzp dbass_period
.globalzp dbass_volume
.globalzp dbass_nmi_counter

; ###################
; # D-Bass Settings #
; ###################

; Your custom IRQ handler.
.define DBASS_USER_IRQ_HANDLER user_irq_handler

; The number of times per frame your custom IRQ handler will be called.
.define DBASS_USER_IRQ_COUNT 4

; The address of OAM data to be copied via OAM DMA, e.g. $200.
.define DBASS_SPRITES sprites
