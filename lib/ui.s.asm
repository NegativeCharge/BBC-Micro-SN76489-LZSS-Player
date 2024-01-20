.updateRowData
{
    ldy #0
    
    lda #LO(row_counter_addr)
	sta writeptr+0
	lda #HI(row_counter_addr)
	sta writeptr+1

    tya:pha

    lda row_counter+0
    sta num+0
    lda row_counter+1
    sta num+1

    jsr print_decimal_16bit
    pla:tay

    iny:iny:iny:iny:iny:iny:iny

    lda decoded_registers+2
    cmp #$0f
    beq tone0_muted

    lda decoded_registers+1     ; Upper 6 bits - 00111111
    pha
    lsr a:lsr a:lsr a:lsr a
    jsr write_hex_nybble
    pla
    asl a:asl a:asl a:asl a
    ora decoded_registers+0     ; Low 4 bits   - 00001111

    iny           
    jsr write_hex_byte

    iny:iny
    lda decoded_registers+2
    jsr write_hex_byte
    iny:iny
    jmp tone1

.tone0_muted
    jsr printString
    equs "--- --",0
    iny

.tone1
    lda decoded_registers+5
    cmp #$0f
    beq tone1_muted

    lda decoded_registers+4     ; Upper 6 bytes - 00111111
    pha
    lsr a:lsr a:lsr a:lsr a
    jsr write_hex_nybble
    pla
    asl a:asl a:asl a:asl a
    ora decoded_registers+3     ; Low 4 bytes   - 00001111

    iny           
    jsr write_hex_byte

    iny:iny
    lda decoded_registers+5
    jsr write_hex_byte
    iny:iny
    jmp tone2

.tone1_muted
    jsr printString
    equs "--- --",0
    iny

.tone2
    lda decoded_registers+8
    cmp #$0f
    beq tone2_muted

    lda decoded_registers+7     ; Upper 6 bytes - 00111111
    pha
    lsr a:lsr a:lsr a:lsr a
    jsr write_hex_nybble
    pla
    asl a:asl a:asl a:asl a
    ora decoded_registers+6     ; Low 4 bytes   - 00001111

    iny           
    jsr write_hex_byte

    iny:iny
    lda decoded_registers+8
    jsr write_hex_byte

    iny:iny
    jmp tone3

.tone2_muted
    jsr printString
    equs "--- --",0
    iny

.tone3
    lda decoded_registers+10
    cmp #$0f
    beq tone3_muted

    lda decoded_registers+9
    and #%00000100
    beq noise_periodic

    lda #'W'					; White Noise
    equb &2C					; = BIT noise_periodic => skip next two bytes

.noise_periodic
    lda #'P'					; Periodic Noise
    sta (writeptr),y
    iny

    lda registers+9
    and #%00000011
    asl a					
    tax
    lda noise_note_0,X
    sta (writeptr),y
    iny
    lda noise_note_0+1,X
    sta (writeptr),y
    iny:iny

    lda decoded_registers+10
    jmp write_hex_byte

.tone3_muted
    jsr printString
    equs "--- --",0
    rts
}

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

.updateProgressBar
{
    lda progress_index
    cmp #64
    bcs not_yet

    ; Update progress bar
    inc progress_counter+0
    bne skip
    inc progress_counter+1
    bne skip
    inc progress_counter+2
.skip
    lda progress_counter+0
    cmp progress_interval+0
    bne not_yet
    lda progress_counter+1
    cmp progress_interval+1
    bne not_yet
    lda progress_counter+2
    cmp progress_interval+2
    bne not_yet

    ; Reset counter
    lda #0
    sta progress_counter+0
    sta progress_counter+1
    sta progress_counter+2

    ; Clear current graphic at offset
    lda progress_index
    beq skip_initial
    lsr a
    tax
    lda #172
    sta progress_bar_addr, x

.skip_initial
    ; Get the index, find chr X (index>>1, since 2 pixels per chr)
    lda progress_index
    tay
    lsr a
    tax
    tya
    and #1                          ; Odd or even
    tay
    lda playtime_table, Y
    sta progress_bar_addr, X

    ; Increment progress offset and render new bar graphic
    inc progress_index

.not_yet
    rts
}

.erase_row
{
    ldx #32
    txa
.loop
    sta progress_bar_addr-1, x
    dex
    bne loop

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

.incrementRowCounter
{  
    lda row_counter+0
    clc
    adc #1
    sta row_counter+0
    lda row_counter+1
    adc #0
    sta row_counter+1

    rts
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

    ldy #0
    lda #LO(track_speed_addr)
	sta writeptr+0
	lda #HI(track_speed_addr)
	sta writeptr+1

    jsr print_decimal_16bit

    ldy temp_y
    jsr printString
    equs "Hz", 0

    ldy #0
    lda #LO(track_length_min_addr)
	sta writeptr+0
	lda #HI(track_length_min_addr)
	sta writeptr+1

    LDA track_length+1
    STA bin
    JSR convert_to_bcd
    LDA bcd+0
    JSR print_decimal

    ldy #0
    lda #LO(track_length_sec_addr)
	sta writeptr+0
	lda #HI(track_length_sec_addr)
	sta writeptr+1

    LDA track_length+0
    STA bin
    JSR convert_to_bcd
    LDA bcd+0
    JSR print_decimal

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
    pla
    sta str+1
    pla
    sta str+2

.strOut
    inc str+1
    bne str
    inc str+2

.str
    lda &ffff           ; Self-Modified
    beq strEnd
    sta (writeptr),y
    iny
    jmp strOut

.strEnd
    lda str+2
    pha
    lda str+1
    pha

    rts
}

.write_hex_byte
    pha                        :\ Save A
    lsr A:lsr A:lsr A:lsr A    :\ Move top nybble to bottom nybble
    jsr write_hex_nybble
    pla
    iny
    and #$0f                    :\ Mask out original bottom nybble
.write_hex_nybble
    sed
    clc
    adc #$90                   :\ Produce &90-&99 or &00-&05
    adc #$40                   :\ Produce &30-&39 or &41-&46
    cld
    sta (writeptr),y           :\ Print it
    rts

\ ---------------------------
\ Print 16-bit decimal number
\ ---------------------------
\ On entry, num=number to print
\           pad=0 or pad character (eg '0' or ' ')
\ On entry at print_decimal_16bit_lp1,
\           Y=(number of digits)*2-2, eg 8 for 5 digits
\ On exit,  A,X,Y,num,pad corrupted
\ Size      69 bytes
\ -----------------------------------------------------------------
.print_decimal_16bit
   sty temp_y
   ldy #8                                   \ Offset to powers of ten

.print_decimal_16bit_lp1
   ldx #$ff
   sec                                      \ Start with digit=-1

.print_decimal_16bit_lp2
   lda num+0
   sbc print_decimal_16bit_tens+0,y
   sta num+0                                \ Subtract current tens
   lda num+1
   sbc print_decimal_16bit_tens+1,y
   sta num+1
   inx
   bcs print_decimal_16bit_lp2              \ Loop until <0
   lda num+0
   adc print_decimal_16bit_tens+0,y
   sta num+0                                \ Add current tens back in
   lda num+1
   adc print_decimal_16bit_tens+1,y
   sta num+1
   txa
   bne print_decimal_16bit_digit                         \ Not zero, print it
   lda pad
   bne print_decimal_16bit_print
   beq print_decimal_16bit_next                          \ pad<>0, use it

.print_decimal_16bit_digit
   ldx #'0'
   stx pad                                  \ No more zero padding
   ora #'0'                                 \ Print this digit

.print_decimal_16bit_print
   sta temp_a
   tya
   pha
   ldy temp_y
   lda temp_a
   sta (writeptr),y
   iny
   sty temp_y
   pla
   tay

.print_decimal_16bit_next
   dey
   dey
   bpl print_decimal_16bit_lp1                           \ Loop for next digit
   rts

.print_decimal_16bit_tens
   equw 1
   equw 10
   equw 100
   equw 1000
   equw 10000

.convert_to_bcd
{
    sed		    ; Switch to decimal mode
    lda #0		; Ensure the result is clear
    sta bcd+0
    sta bcd+1
    ldx #8		; The number of source bits

.cnv_bit		
    asl bin		; Shift out one bit
    lda bcd+0	; And add into result
    adc bcd+0
    sta bcd+0
    lda bcd+1	; propagating any carry
    adc bcd+1
    sta bcd+1
    dex		    ; And repeat for next bit
    bne cnv_bit
    cld		    ; Back to binary

    rts
}

.print_decimal
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

.screen_filename
    equs "UI", 13

.noise_note_0 EQUS "Lo"
.noise_note_1 EQUS "Md"
.noise_note_2 EQUS "Hi"
.noise_note_3 EQUS "T2"

.playtime_table
    EQUB 164, 172