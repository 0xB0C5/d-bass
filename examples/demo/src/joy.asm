; Mostly taken from nesdev.
; TODO : only 1 player?
SR_UpdateJoypads:
	; negate the previously held buttons and store as presses.
	lda joypad_buttons_p1
	eor #$ff
	sta joypad_presses_p1
	lda joypad_buttons_p2
	eor #$ff
	sta joypad_presses_p2

	; Sample thrice, storing values in temp vars.
	jsr _SR_UpdateButtonsOnce

	lda joypad_buttons_p1
	sta $00
	lda joypad_buttons_p2
	sta $01

	jsr _SR_UpdateButtonsOnce

	lda joypad_buttons_p1
	sta $02
	lda joypad_buttons_p2
	sta $03

	jsr _SR_UpdateButtonsOnce

	; (a and (b or c)) or (b and c)
	; a = a and (b or c)
	lda $00
	ora $02
	and joypad_buttons_p1
	sta joypad_buttons_p1
	; a = (b and c) or a
	lda $00
	and $02
	ora joypad_buttons_p1
	sta joypad_buttons_p1
	and joypad_presses_p1
	sta joypad_presses_p1

	; (a and (b or c)) or (b and c)
	; a = a and (b or c)
	lda $01
	ora $03
	and joypad_buttons_p2
	sta joypad_buttons_p2
	; a = (b and c) or a
	lda $01
	and $03
	ora joypad_buttons_p2
	sta joypad_buttons_p2
	and joypad_presses_p2
	sta joypad_presses_p2

    rts

_SR_UpdateButtonsOnce:
    lda #$01
    sta JOYPAD1
    sta joypad_buttons_p2  ; player 2's buttons double as a ring counter
    lsr a         ; now A is 0
    sta JOYPAD1
@Loop:
    lda JOYPAD1
    and #%00000011  ; ignore bits other than controller
    cmp #$01        ; Set carry if and only if nonzero
    rol joypad_buttons_p1    ; Carry -> bit 0; bit 7 -> Carry
    lda JOYPAD2     ; Repeat
    and #%00000011
    cmp #$01
    rol joypad_buttons_p2    ; Carry -> bit 0; bit 7 -> Carry
    bcc @Loop

	rts
