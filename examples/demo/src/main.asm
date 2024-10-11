
.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02 ; 2 * 16KB PRG ROM
.byte $01 ; 1 * 8KB CHR ROM
.byte %00000000 ; mapper and mirroring
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler bytes

.include "../../../d-bass.inc"

.include "addresses.asm"
.include "nes_addresses.asm"

.segment "DATA"
.segment "EMPTY"
.segment "CODE"

;.include "joy.asm"
.include "raster.asm"
.include "sprites.asm"
.include "nmi.asm"
.include "init.asm"
.include "test_song.asm"

.segment "CHARS"
.incbin "../data/chars.chr"

.segment "VECTORS"
	.word dbass_nmi_handler
	.word Reset
	.word dbass_irq_handler
