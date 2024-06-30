NMI:
	pha
	lda irq_user_counter
	sta nmi_user_counter
	lda #>sprites
    sta OAMDMA
	inc nmi_done
	pla
	rti

SR_AdvanceFrame:
	; Wait for NMI thread to increment nmi_done.
	lda #0
	tax
	sta nmi_done
	clc
@WaitForVBlank:
	cpx #$ff              ; 2  2
	inx                   ; 2  4
	adc #0                ; 2  6
	nop                   ; 2  8
	nop                   ; 2 10
	ldy nmi_done          ; 3 13
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


	; If nmi_done is 0, then we're in RenderImmediate
	lda nmi_done
	bne :+
	rts
:

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
	sta nmi_done
@WaitForVBlank:
	lda nmi_done
	beq @WaitForVBlank

	lda #$00
	sta PPUCTRL
	sta PPUMASK

	rts
