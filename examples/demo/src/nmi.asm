
.export user_nmi_handler
.proc user_nmi_handler
	lda #>sprites
	sta $4014

	lda need_nmi
	beq @end
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
	and #%01011110
	sta pending_ppu_mask
    sta PPUMASK

	dec need_nmi

@end:
	; Update song before returning,
	; because D-Bass update applies after we return.
	jmp SR_UpdateTestSong
	; rts
.endproc

SR_AdvanceFrame:
	; Tell the NMI handler to run an update.
	lda #1
	sta need_nmi
	; Wait for the NMI handler to run.
	lda #0
	tax
	clc
@WaitForNMI:
	cpx #$ff              ; 2  2
	inx                   ; 2  4
	adc #0                ; 2  6
	nop                   ; 2  8
	nop                   ; 2 10
	ldy need_nmi          ; 3 13
	bne @WaitForNMI    ; 3 16

	stx cpu_counter+0
	sta cpu_counter+1

	rts


SR_EnablePPU:
    lda ppu_pending_control
	ora #$80
    sta PPUCTRL
	sta ppu_pending_control

	rts
