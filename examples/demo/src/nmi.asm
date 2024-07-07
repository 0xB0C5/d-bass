
SR_AdvanceFrame:
	; Wait for d-bass to increment dbass_nmi_counter.
	lda #0
	tax
	sta dbass_nmi_counter
	clc
@WaitForVBlank:
	cpx #$ff              ; 2  2
	inx                   ; 2  4
	adc #0                ; 2  6
	nop                   ; 2  8
	nop                   ; 2 10
	ldy dbass_nmi_counter ; 3 13
	beq @WaitForVBlank    ; 3 16
@EndWaitForVBlank:

	stx cpu_counter+0
	sta cpu_counter+1

	tsx
	stx nmi_temp

	bit PPUSTATUS
	lda ppu_text_addr+1
	sta PPUADDR
	lda ppu_text_addr+0
	sta PPUADDR

	ldx #0
@TextLoop:
	lda ppu_pending_text, x
	beq @EndText
	sta PPUDATA
	inx
	cpx #32
	bne @TextLoop
@EndText:

	lda #0
:
	sta PPUDATA
	inx
	cpx #32
	bne :-

	; Set the scroll.
	bit PPUSTATUS
	lda ppu_pending_scroll_x
	sta PPUSCROLL
	lda ppu_pending_scroll_y
	sta PPUSCROLL
	lda ppu_pending_control
    sta PPUCTRL
    lda pending_ppu_mask
    sta PPUMASK

	rts


SR_EnablePPU:
; wait for vblank
@WaitVBlank:
    bit PPUSTATUS
    bpl @WaitVBlank

	lda #>sprites
	sta OAMDMA

    lda ppu_pending_control
	ora #$80
    sta PPUCTRL
	sta ppu_pending_control

    lda pending_ppu_mask
    sta PPUMASK

	rts


SR_DisablePPU:
	lda #$00
	sta dbass_nmi_counter
@WaitForVBlank:
	lda dbass_nmi_counter
	beq @WaitForVBlank

	lda #$00
	sta PPUCTRL
	sta PPUMASK

	rts
