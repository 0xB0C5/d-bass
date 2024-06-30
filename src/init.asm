
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

	bit PPUSTATUS
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	
	ldy #4

@ClearNametableLoopOuter:
	ldx #0
@ClearNametableLoopInner:
	sta PPUDATA
	dex
	bne @ClearNametableLoopInner
	
	dey
	bne @ClearNametableLoopOuter

	; Background.
	ldy #$21
	ldx #$84
	lda #$80
	jsr SR_DrawBigLetter

	ldy #$21
	ldx #$88
	lda #$84
	jsr SR_DrawBigLetter
	
	ldy #$21
	ldx #$8c
	lda #$88
	jsr SR_DrawBigLetter
	
	ldy #$21
	ldx #$90
	lda #$8c
	jsr SR_DrawBigLetter
	
	ldy #$21
	ldx #$94
	lda #$c0
	jsr SR_DrawBigLetter
	
	ldy #$21
	ldx #$98
	lda #$c0
	jsr SR_DrawBigLetter

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

	lda #$23
	sta ppu_text_addr+1
	lda #$01
	sta ppu_text_addr+0

	lda #$00
	sta ppu_pending_scroll_x
	sta ppu_pending_scroll_y

	lda #$00
	sta $4013
	sta $4012

	lda #$8e
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

	lda #<UserIRQ
	sta user_irq
	lda #>UserIRQ
	sta user_irq+1
	
	lda #0
	sta raster_lines+0

	lda #%00011110
	sta pending_ppu_mask
	
	jsr SR_InitSprites
	
	jsr SR_EnablePPU

@Forever:
	jsr SR_UpdateTestSong
	jsr SR_UpdateDmc
	jsr SR_UpdateRasterFX
	jsr SR_UpdateSprites

	ldx #0
@MessageLoop:
	lda TestMessage, x
	beq @EndMessage
	sta ppu_pending_text, x
	inx
	bne @MessageLoop
@EndMessage:

	lda cpu_counter+1
	ora #$10
	sta ppu_pending_text+0, x

	lda cpu_counter+0
	lsr
	lsr
	lsr
	lsr
	ora #$10
	sta ppu_pending_text+1, x
	lda cpu_counter+0
	and #$0f
	ora #$10
	sta ppu_pending_text+2, x

	lda #'0'
	sta ppu_pending_text+3, x

	lda #0
	sta ppu_pending_text+4, x

	inc frame_counter

	jsr SR_AdvanceFrame

	jmp @Forever

; Call with a = letter, x::y = PPU address
SR_DrawBigLetter:
	sta temp+0
	stx temp+1

	; First row.
	bit PPUSTATUS
	sty PPUADDR
	stx PPUADDR

	tax
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	
	; 2nd row
	lda temp+1
	clc
	adc #32
	bcc :+
	iny
:
	bit PPUSTATUS
	sty PPUADDR
	sta PPUADDR
	
	lda temp+0
	clc
	adc #16
	tax
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	
	; 3rd row
	lda temp+1
	clc
	adc #64
	bcc :+
	iny
:
	bit PPUSTATUS
	sty PPUADDR
	sta PPUADDR
	
	lda temp+0
	clc
	adc #32
	tax
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	
	; 4th row
	lda temp+1
	clc
	adc #96
	bcc :+
	iny
:
	bit PPUSTATUS
	sty PPUADDR
	sta PPUADDR
	
	lda temp+0
	clc
	adc #48
	tax
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	inx
	stx PPUDATA
	
	rts

TestMessage:
	.byte "Idle:", 0


TestPalette:
	.byte $0c, $0f, $2c, $30
	.byte $0f, $0f, $11, $21
	.byte $0f, $05, $15, $25
	.byte $0f, $09, $19, $29
