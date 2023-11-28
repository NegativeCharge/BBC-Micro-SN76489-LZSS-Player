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
	sta writeptr+0
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

.print_track_metadata {
    ldx #LO(track_title)
    stx readptr+0
    ldy #HI(track_title)
    sty readptr+1

    lda #LO(track_title_addr)
	sta writeptr+0
	lda #HI(track_title_addr)
	sta writeptr+1

    jsr printMetadata

    ldx #LO(track_artist)
    stx readptr+0
    ldy #HI(track_artist)
    sty readptr+1

    lda #LO(track_artist_addr)
	sta writeptr+0
	lda #HI(track_artist_addr)
	sta writeptr+1

    jsr printMetadata

    ldx #LO(track_year)
    stx readptr+0
    ldy #HI(track_year)
    sty readptr+1

    lda #LO(track_year_addr)
	sta writeptr+0
	lda #HI(track_year_addr)
	sta writeptr+1

    jsr printMetadata

    lda track_speed+0
    sta num+0
    lda track_speed+1
    sta num+1

    lda #LO(track_speed_addr)
	sta writeptr+0
	lda #HI(track_speed_addr)
	sta writeptr+1

    jsr PrDec16

    ldy temp_y
    jsr printString
    EQUS "Hz", 0

    ldy #0
    lda #LO(track_length_min_addr)
	sta writeptr+0
	lda #HI(track_length_min_addr)
	sta writeptr+1

    LDA track_length+1
    STA bin
    JSR convert_to_bcd
    LDA bcd+0
    JSR printDec

    ldy #0
    lda #LO(track_length_sec_addr)
	sta writeptr+0
	lda #HI(track_length_sec_addr)
	sta writeptr+1

    LDA track_length+0
    STA bin
    JSR convert_to_bcd
    LDA bcd+0
    JSR printDec

    rts
}

.printMetadata
{
    ldy #0
.printStringLoop
    lda (readptr),y
    sta (writeptr),y
    iny
    cmp #0
    bne printStringLoop

    rts
}

.printString
{
    PLA
    STA str+1
    PLA
    STA str+2

.strOut
    INC str+1
    BNE str
    INC str+2

.str
    LDA &FFFF           ; Self-Modified
    BEQ strEnd
    sta (writeptr),y
    iny
    JMP strOut

.strEnd
    LDA str+2
    PHA
    LDA str+1
    PHA

    RTS
}

\ ---------------------------
\ Print 16-bit decimal number
\ ---------------------------
\ On entry, num=number to print
\           pad=0 or pad character (eg '0' or ' ')
\ On entry at PrDec16Lp1,
\           Y=(number of digits)*2-2, eg 8 for 5 digits
\ On exit,  A,X,Y,num,pad corrupted
\ Size      69 bytes
\ -----------------------------------------------------------------
.PrDec16
   ldy #0
   sty temp_y
   ldy #8                                   \ Offset to powers of ten
.PrDec16Lp1
   ldx #$ff
   sec                                      \ Start with digit=-1
.PrDec16Lp2
   lda num+0
   sbc PrDec16Tens+0,y
   sta num+0                                \ Subtract current tens
   lda num+1
   sbc PrDec16Tens+1,y
   sta num+1
   inx
   bcs PrDec16Lp2                           \ Loop until <0
   lda num+0
   adc PrDec16Tens+0,y
   sta num+0                                \ Add current tens back in
   lda num+1
   adc PrDec16Tens+1,y
   sta num+1
   txa
   bne PrDec16Digit                         \ Not zero, print it
   lda pad
   bne PrDec16Print
   beq PrDec16Next                          \ pad<>0, use it
.PrDec16Digit
   ldx #'0'
   stx pad                                  \ No more zero padding
   ora #'0'                                 \ Print this digit
.PrDec16Print
   sta temp_a
   tya:pha
   ldy temp_y
   lda temp_a
   sta (writeptr),y
   iny
   sty temp_y
   pla:tay
.PrDec16Next
   dey
   dey
   bpl PrDec16Lp1                           \ Loop for next digit
   rts

.PrDec16Tens
   EQUW 1
   EQUW 10
   EQUW 100
   EQUW 1000
   EQUW 10000

.convert_to_bcd
{
    SED		    ; Switch to decimal mode
    LDA #0		; Ensure the result is clear
    STA bcd+0
    STA bcd+1
    LDX #8		; The number of source bits

.cnvbit		
    ASL bin		; Shift out one bit
    LDA bcd+0	; And add into result
    ADC bcd+0
    STA bcd+0
    LDA bcd+1	; propagating any carry
    ADC bcd+1
    STA bcd+1
    DEX		    ; And repeat for next bit
    BNE cnvbit
    CLD		    ; Back to binary

    RTS
}

.printDec
{
    tax
    lsr A
    lsr A
    lsr A
    lsr A
    ora #$30
    sta (writeptr),y
    iny
    txa
    and #$0f
    ora #$30
    sta (writeptr),y

    rts
}

.bin    skip 1
.bcd    skip 2

.num
    EQUW 0
.pad
    EQUB 0

.file_params		SKIP 18

.screen_filename
    equs "UI", 13