.updateTicks
{
    inc clock_ticks
    lda clock_ticks
    cmp #50
    bne not_sec_yet

    \\ Reset counter
    lda #0
    sta clock_ticks

    \\ Update 1 second
    inc clock_secs
    lda clock_secs
    cmp #60
    bne not_min_yet

    \\ Update 1 min
    inc clock_mins
    lda #0
    sta clock_secs

.not_min_yet

    \\ Display clock
	lda #LO(clock_addr)
	sta writeptr
	lda #HI(clock_addr)
	sta writeptr+1

	ldx clock_mins
	ldy clock_secs
	jmp write_clock_at_writeptr

.not_sec_yet
    rts
}

.write_clock_at_writeptr			; X=mins, Y=secs
{
	tya:pha
	ldy #0

	clc
	txa
	
    ldx #0
.loop_min_10
	cmp #10
	bcc done_min_10
	sec
	sbc #10
	inx
	jmp loop_min_10
.done_min_10
	pha

	\\ Write tens
	clc
	txa
	adc #'0'
	sta (writeptr),y
	iny

	\\ Write units
	pla
	adc #'0'
	sta (writeptr),y
	iny

	lda #':'
	sta (writeptr),y
	iny

	\\ Count tens
	pla
	ldx #0
.loop_10
	cmp #10
	bcc done_10
	sec
	sbc #10
	inx
	jmp loop_10
.done_10
	pha

	\\ Write tens
	clc
	txa
	adc #'0'
	sta (writeptr),y
	iny

	\\ Write units
	pla
	adc #'0'
	sta (writeptr),y
	iny

.return
	rts
}

.set_mode
{    
    \\ Set MODE
	lda #22
    jsr OSWRCH
	txa
    jmp OSWRCH
}

.disable_cursor
{
    \\ Disable cursor
	lda #$0a
    sta $fe00
	lda #$20
    sta $fe01

    rts
}

.load_screen
{
	lda #LO(screen_filename)
	sta file_params + 0
	lda #HI(screen_filename)
	sta file_params + 1

    lda #LO(MODE7_base_addr)
    sta file_params + 2
    lda #HI(MODE7_base_addr)
    sta file_params + 3

    lda #0
    sta file_params + 6

    ldx #LO(file_params)
    ldy #HI(file_params)
    lda #&FF
    jmp OSFILE
}

.file_params		SKIP 18

.screen_filename
    equs "UI", 13