; FX code borrowed and adapted from @bitshifters - https://github.com/bitshifters/beeb-tracker/
.init_fx {
    ldy #(FX_num_freqs + FX_num_channels) - 1
	lda #0
.loop
	sta freq_array,y
	dey
	bpl loop

    ldx #0
	lda #32
	sta FX_address_row0-1, X
	sta FX_address_row1-1, X
	sta FX_address_row2-1, X
	sta FX_address_row3-1, X
	sta FX_address_row4-1, X
	sta FX_address_row4-1, X

	ldx #FX_chr_w+1
	sta FX_address_row0-1, X
	sta FX_address_row1-1, X
	sta FX_address_row2-1, X
	sta FX_address_row3-1, X
	sta FX_address_row4-1, X
	sta FX_address_row4-1, X

    rts
}

.poll_fx {
    ldx #0
	
	.fx_column_loop
	
	\\ Get frequency level
	txa
	tay
	lda freq_array, Y
	
	clc
	adc #1			; This hack forces levels to be a minimum of 1
					; which means there's always a blue bar showing
					; fx_table lookup has a duplicated extra entry to prevent overread
	
	\\ Mult*5 and lookup teletext bar graphic
	sta tmp_fx_y
	asl a
	asl a
	clc
	adc tmp_fx_y
	tay
	
	\\ Render the 5 byte bar column, 1 chr per bar
	lda fx_table + 4, Y
	and #$b5
	sta FX_address_row0+0, X
	lda fx_table + 3, Y
	and #$b5
	sta FX_address_row1+0, X
	lda fx_table + 2, Y
	and #$b5
	sta FX_address_row2+0, X
	lda fx_table + 1, Y
	and #$b5
	sta FX_address_row3+0, X
	lda fx_table + 0, Y
	and #$b5
	sta FX_address_row4+0, X

	\\ Advance to next column
	inx
	txa
	cmp #FX_num_freqs

	bne fx_column_loop

    \\ Let VU meter values fall to zero
	ldy #(FX_num_freqs) - 1
.loop
	lda freq_array,Y
	beq zero
	sec
	sbc #1
	sta freq_array,Y
.zero
	dey
	bpl loop

    rts
}

.update_fx_array {

    ldy #4
    ldx #1
    stx temp_x

.loop
    lda decoded_registers,x         ; Data bytes for tone channel / latch/data byte for noise
    cpx #9
    bne skip_adjust
    and #3                          ; Noise - lowest two bits hold low, medium or high, unless tuned
.skip_adjust
    sta temp_a
    inx
    lda decoded_registers,X         ; Ensure channel isn't silent
    cmp #$0f
    beq skip_update

    lda temp_a
	and #FX_num_freqs-1
	sta tmp_var
	lda #FX_num_freqs-1
	sec
	sbc tmp_var
	tax
	lda #$0f
	sta freq_array,X

.skip_update
    ldx temp_x
    inx:inx
    cpx #9
    beq skip
    inx
.skip
    stx temp_x
    dey
    bne loop

    rts
}

\\ 16 Arrangements of 5 teletext character bytes to render a vertical equalizer bar
.fx_table
EQUB 160, 160, 160, 160, 160
EQUB 160+80, 160, 160, 160, 160
EQUB 160+92, 160, 160, 160, 160
EQUB 160+95, 160, 160, 160, 160
EQUB 160+95, 160+80, 160, 160, 160
EQUB 160+95, 160+92, 160, 160, 160
EQUB 160+95, 160+95, 160, 160, 160
EQUB 160+95, 160+95, 160+80, 160, 160
EQUB 160+95, 160+95, 160+92, 160, 160
EQUB 160+95, 160+95, 160+95, 160, 160
EQUB 160+95, 160+95, 160+95, 160+80, 160
EQUB 160+95, 160+95, 160+95, 160+92, 160
EQUB 160+95, 160+95, 160+95, 160+95, 160
EQUB 160+95, 160+95, 160+95, 160+95, 160+80
EQUB 160+95, 160+95, 160+95, 160+95, 160+92
EQUB 160+95, 160+95, 160+95, 160+95, 160+95
EQUB 160+95, 160+95, 160+95, 160+95, 160+95	; last row copied to enable fixed bar effect