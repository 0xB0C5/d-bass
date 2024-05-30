PeriodsLo: .byte 167,51,56,175,147,221,135,141,232,148,141,206,84,25,28,88,202,110,68,70,116,202,71,231,170,141,142,172,229,55,162,35,186,101,35,244,213,198,199,214,242,28,81,146,221,51,146,250,106,227,99
PeriodsHi: .byte 150,142,134,126,119,112,106,100,94,89,84,79,75,71,67,63,59,56,53,50,47,44,42,39,37,35,33,31,29,28,26,25,23,22,21,19,18,17,16,15,14,14,13,12,11,11,10,9,9,8,8

Widths:
DrumArpWidths:
	.byte  0, 0, 0, 0, 7, 7, 6, 6
	.byte  5, 5, 4, 4, 3, 3, 2, 2
	.byte  2, 2, 2, 2, 2, 2, 2, 2
SquareWidths:
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	.byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
BassWidths:
	.byte  3, 5, 9,11,13,15,16,17
	.byte 18,19,21,25,30,35,99,99
DrumBassWidths:
	.byte 99,99,99,99,13,15,16,17
	.byte 18,19,21,17,19,21,22,22

Volumes:
DrumArpVolume:
	.byte 99,99,99,99,1,1,1
	.byte 1,1,1,1,1,1,1
	.byte 1,1,1,1,1,1,1

SusVolume:
.repeat 16
	.byte 3
.endrepeat

BassVolume:
	.byte  4,8,8,8,8,8,8,6,5,4,4,4,3,3

DrumBassVolume:
	.byte 99,99,99,99,8,8,8,6,5,4,4,4,3,3

Pitches:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SnareBassPitch:
	.byte $80 | 40, $80 | 38, $80 | 37, $80 | 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
KickBassPitch:
	.byte $80 | 35, $80 | 25, $80 | 15, $80 | 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SnareArpMinPitches:
	.byte $80 | 40, $80 | 38, $80 | 37, $80 | 36
	.byte 0, 0, 3, 3, 7, 7, 0, 0, 3, 3, 7, 7
	.byte 0, 0, 3, 3, 7, 7, 0, 0, 3, 3, 7, 7
SnareArpMajPitches:
	.byte $80 | 40, $80 | 38, $80 | 37, $80 | 36
	.byte 0, 0, 4, 4, 7, 7, 0, 0, 4, 4, 7, 7
	.byte 0, 0, 4, 4, 7, 7, 0, 0, 4, 4, 7, 7

InstrumentWidthStarts:
	.byte 0
	.byte SquareWidths - Widths
	.byte BassWidths - Widths
	.byte DrumBassWidths - Widths
	.byte DrumBassWidths - Widths
	.byte DrumArpWidths - Widths
	.byte DrumArpWidths - Widths

InstrumentVolumeStarts:
	.byte 0
	.byte SusVolume - Volumes
	.byte BassVolume - Volumes
	.byte DrumBassVolume - Volumes
	.byte DrumBassVolume - Volumes
	.byte DrumArpVolume - Volumes
	.byte DrumArpVolume - Volumes

InstrumentPitchStarts:
	.byte 0
	.byte 0
	.byte 0
	.byte SnareBassPitch - Pitches
	.byte KickBassPitch - Pitches
	.byte SnareArpMinPitches - Pitches
	.byte SnareArpMajPitches - Pitches

NoteInstruments: .byte  4, 0, 1, 2, 5, 0, 0, 4, 0, 1, 4, 0, 5, 0, 2, 0, 4, 0, 1, 2, 6, 0, 0, 4, 0, 1, 4, 0, 6, 0, 2, 0, 4, 0, 1, 2, 6, 0, 0, 4, 0, 1, 4, 0, 6, 0, 2, 0, 4, 0, 1, 2, 5, 0, 0, 4, 0, 1, 4, 0, 5, 0, 2, 0
NotePitches:     .byte 15, 0,15,15,27, 0, 0,15, 0,15,15, 0,27, 0,15, 0,18, 0,18,18,30, 0, 0,18, 0,18,18, 0,30, 0,15, 0,13, 0,13,13,25, 0, 0,13, 0,13,13, 0,25, 0,14, 0,15, 0,15,15,27, 0, 0,15, 0,15,15, 0,27, 0,13, 0

TEST_SONG_LENGTH = NotePitches - NoteInstruments

SR_UpdateTestSong:
	dec song_counter
	bpl @EndSongUpdate

	lda #6
	sta song_counter

	ldx song_index

	ldy NoteInstruments, x
	beq @EndNote

	lda InstrumentVolumeStarts, y
	sta song_volume_idx
	
	lda InstrumentWidthStarts, y
	sta song_width_idx
	
	lda InstrumentPitchStarts, y
	sta song_pitch_idx

	lda NotePitches, x
	sta song_pitch

@EndNote:
	inx
	cpx #TEST_SONG_LENGTH
	bne :+
	ldx #0
:
	stx song_index
@EndSongUpdate:

	ldx song_volume_idx
	lda Volumes, x
	sta dmc_volume
	inc song_volume_idx
	
	ldx song_width_idx
	lda Widths, x
	sta dmc_width
	inc song_width_idx

	ldx song_pitch_idx
	lda Pitches, x
	bmi :+
	clc
	adc song_pitch
:
	and #$7f
	tay
	lda PeriodsLo, y
	sta dmc_period_lo
	lda PeriodsHi, y
	sta dmc_period_hi

	inc song_pitch_idx

	rts

