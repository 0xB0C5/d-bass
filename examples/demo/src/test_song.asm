PeriodsLo: .byte 167,51,56,175,147,221,135,141,232,148,141,206,84,25,28,88,202,110,68,70,116,202,71,231,170,141,142,172,229,55,162,35,186,101,35,244,213,198,199,214,242,28,81,146,221,51,146,250,106,227,99
PeriodsHi: .byte 150,142,134,126,119,112,106,100,94,89,84,79,75,71,67,63,59,56,53,50,47,44,42,39,37,35,33,31,29,28,26,25,23,22,21,19,18,17,16,15,14,14,13,12,11,11,10,9,9,8,8

Volumes:
DrumArpVolume:
	.byte 99,99,99,99,3,3,3
	.byte 3,3,3,3,3,3,3
	.byte 3,3,3,3,0,0,0

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
	.byte $80 | 36, $80 | 35, $80 | 34, $80 | 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
KickBassPitch:
	.byte $80 | 35, $80 | 25, $80 | 15, $80 | 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SnareArpMinPitches:
	.byte $80 | 36, $80 | 35, $80 | 34, $80 | 33
	.byte 0, 0, 3, 3, 7, 7, 0, 0, 3, 3, 7, 7
	.byte 0, 0, 3, 3, 7, 7, 0, 0, 3, 3, 7, 7
SnareArpMajPitches:
	.byte $80 | 36, $80 | 35, $80 | 34, $80 | 33
	.byte 0, 0, 4, 4, 7, 7, 0, 0, 4, 4, 7, 7
	.byte 0, 0, 4, 4, 7, 7, 0, 0, 4, 4, 7, 7

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
	sta dbass_volume
	inc song_volume_idx
	
	ldx song_pitch_idx
	lda Pitches, x
	bmi :+
	clc
	adc song_pitch
:
	and #$7f
	clc
	adc #5
	tay
	lda PeriodsLo, y
	sta dbass_period+0
	lda PeriodsHi, y
	sta dbass_period+1

	inc song_pitch_idx

	rts

