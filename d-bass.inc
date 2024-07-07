
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

.define DBASS_USER_IRQ_HANDLER user_irq_handler
.define DBASS_MAX_USER_IRQ_COUNT 4
.define DBASS_SPRITES sprites
