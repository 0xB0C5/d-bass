
Reset:
    sei ; Disables all interrupts
    cld ; disable decimal mode

    ; Disable sound IRQ
    ldx #$40
    stx $4017

    ; Initialize the stack register
    ldx #$FF
    txs

    inx ; #$FF + 1 => #$00

    ; Zero out the PPU registers
    stx $2000
    stx $2001

    stx $4010

:
    bit $2002
    bpl :-

    txa

ClearMem:
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$FF
    sta $0200, x
    lda #$00
    inx
    bne ClearMem

	; Test palette
	bit PPUSTATUS
	lda #>PPU_PALETTE
	sta PPUADDR
	lda #<PPU_PALETTE
	sta PPUADDR
	ldx #0
@PaletteLoop:
	lda TestPalette, x
	sta PPUDATA
	inx
	cpx #$10
	bne @PaletteLoop

	ldx #0
@PaletteLoop2:
	lda TestPalette, x
	sta PPUDATA
	inx
	cpx #$10
	bne @PaletteLoop2

	lda #%00010000
	sta ppu_pending_control

	lda #$20
	sta ppu_text_addr+1
	lda #$80
	sta ppu_text_addr+0

	lda #$00
	sta ppu_pending_scroll_x
	sta ppu_pending_scroll_y

	lda #$00
	sta $4013
	sta $4012

	lda #%10001111
	sta $4010

	lda #$10
	sta $4015

	lda #1
	sta irq_counter_hi

	lda #14
	sta dmc_period_hi
	lda #0
	sta dmc_period_lo
	lda #1
	sta dmc_volume
	sta dmc_width
	
	jsr SR_EnablePPU

@Forever:
	jsr SR_UpdateTestSong
	jsr SR_UpdateDmc

	ldx #0
@MessageLoop:
	lda TestMessage, x
	beq @EndMessage
	sta ppu_pending_text, x
	inx
	bne @MessageLoop
@EndMessage:

	lda cpu_counter+1
	lsr
	lsr
	lsr
	lsr
	ora #$10
	sta ppu_pending_text, x
	lda cpu_counter+1
	and #$0f
	ora #$10
	sta ppu_pending_text+1, x

	lda cpu_counter+0
	lsr
	lsr
	lsr
	lsr
	ora #$10
	sta ppu_pending_text+2, x
	lda cpu_counter+0
	and #$0f
	ora #$10
	sta ppu_pending_text+3, x

	lda #0
	sta ppu_pending_text+4, x

	inc frame_counter

	jsr SR_AdvanceFrame

	jmp @Forever

TestMessage:
	.byte "Idle:"


TestPalette:
	.byte $0f, $00, $10, $20
	.byte $0f, $01, $11, $21
	.byte $0f, $05, $15, $25
	.byte $0f, $09, $19, $29
