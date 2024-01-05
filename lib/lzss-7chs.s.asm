;
; LZSS Compressed SN76489 player for 16 match bits
; --------------------------------------------
;
; (c) 2020 DMSC
; Code under MIT license, see LICENSE file.
;
; This player uses:
;  Match length: 8 bits  (1 to 256)
;  Match offset: 8 bits  (1 to 256)
;  Min length: 2
;  Total match bits: 16 bits
;
; Compress using:
;  lzss -b 16 -o 8 -m 1 input.bin test.lz16-c
;
; Assemble this file with BeebAsm assembler, the compressed song is expected in
; the `test.lz16-c` file at assembly time.
;
; The plater needs 256 bytes of buffer for each SN76489 register stored, for a
; full SN raw register file this is 2816 bytes.
;
; BBC Micro / BeebAsm by Negative Charge, November 2023

.registers
    EQUB 0,0,0,0,0,0,0

.decoded_registers   
    EQUB 0,0,0,0,0,0,0,0,0,0,0

.masks
    EQUB CH0TONELATCH, 0, CH0VOL, CH1TONELATCH, 0, CH1VOL, CH2TONELATCH, 0, CH2VOL, CH3TONELATCH, CH3VOL

.bit_data    EQUB   1

end_ptr = *+1
    lda $ffff

.get_byte {
    lda $ffff
    inc song_ptr+0
    bne skip_hi
    inc song_ptr+1

IF USE_SWRAM
    ; Check if we have any SWRAM banks to play
    php
	pha

    lda end_ptr+1
    cmp song_ptr+1
    bne swram_check_complete
    lda end_ptr+0
    cmp song_ptr+0
    bne swram_check_complete

    txa
    pha
    
IF SHOW_UI AND DEBUG
    lda #LO(debug_selected_swr_bank)
	sta writeptr+0
	lda #HI(debug_selected_swr_bank)
	sta writeptr+1

    ldy #0
    jsr printString
    equs "Bank: ", 0

    lda current_swram_bank
    jsr write_hex_byte
ENDIF

    lda current_swram_bank
	tax
	lda swr_ram_banks,x
    sta $f4
	sta ROMSEL	
	pla
	tax

    inc current_swram_bank

    lda #$00
    sta song_ptr+0

    lda #$80
    sta song_ptr+1

    lda #<swram_song_end
    sta end_ptr+0

    lda #>swram_song_end
    sta end_ptr+1

.swram_check_complete
	pla
	plp
ENDIF

.skip_hi
    rts
}
song_ptr = get_byte + 1

.cbuf_init
    EQUW 0
.song_ptr_init
    EQUW 0
.current_swram_bank
    EQUB 0

align $100
.buffers SKIP 256 * 7

.play
    lda #<song_data
    sta song_ptr+0
    sta song_ptr_init+0
    lda #>song_data
    sta song_ptr+1
    sta song_ptr_init+1

    lda #<song_end
    sta end_ptr+0
    lda #>song_end
    sta end_ptr+1

    lda cbuf+1
    sta cbuf_init+0
    lda cbuf+2
    sta cbuf_init+1

    lda #1
    sta bit_data

    ; Read Header

    \\ Read song speed in hz - 16-bit
    jsr get_byte
    sta track_speed+0

    jsr get_byte
    sta track_speed+1

    \\ Read IRQ rate - 16-bit
    jsr get_byte
    sta irq_rate+0

    jsr get_byte
    sta irq_rate+1

IF HEADER_CONTAINS_FRAME_COUNT
    \\ Read 24-bit frame count value into three bytes
    jsr get_byte
    sta frame_count+0
    sta progress_interval+0

    jsr get_byte
    sta frame_count+1
    sta progress_interval+1

    jsr get_byte
    sta frame_count+2
    sta progress_interval+2

    ; Calculate progress interval
    ldy #6
.divide_by_2
    lsr progress_interval+2
    ror progress_interval+1
    ror progress_interval+0
    dey
    bne divide_by_2

    IF SHOW_UI AND DEBUG

    ldy #0
    lda #LO(debug_frame_count)
	sta writeptr+0
	lda #HI(debug_frame_count)
	sta writeptr+1

    lda frame_count+2
    jsr write_hex_byte

    iny
    lda frame_count+1
    jsr write_hex_byte

    iny
    lda frame_count+0
    jsr write_hex_byte
    
    ldy #0
    lda #LO(debug_progress_interval)
	sta writeptr+0
	lda #HI(debug_progress_interval)
	sta writeptr+1

    lda progress_interval+2
    jsr write_hex_byte

    iny
    lda progress_interval+1
    jsr write_hex_byte

    iny
    lda progress_interval+0
    jsr write_hex_byte
    
    ENDIF
ENDIF

    \\ Read song length - seconds (8-bit), minutes (8-bit)
    jsr get_byte
    sta track_length+0

    jsr get_byte
    sta track_length+1

    \\ Read track title
    ldx #0
IF CHECK_EOF
    stx eof_flag
ENDIF

.title_loop
    jsr get_byte
    cmp #0
    beq process_artist
    sta track_title,x
	inx
    jmp title_loop

    \\ Read track artist
.process_artist
    ldx #0

.artist_loop
    jsr get_byte
    cmp #0
    beq process_year
    sta track_artist,x
	inx
    jmp artist_loop

\\ Read track year
.process_year
    ldx #0

.year_loop
    jsr get_byte
    cmp #0
    beq init_song
    sta track_year,x
	inx
    jmp year_loop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Song Initialization - this runs in the first tick:
;
.init_song

IF SHOW_UI AND DISPLAY_METADATA
    jsr print_track_metadata
ENDIF

    lda irq_rate+0
    sta SHEILA_SYS_VIA_R4_T1C_L
    lda irq_rate+1
    sta SHEILA_SYS_VIA_R5_T1C_H

    ; Init all channels:
    ldx #6
    ldy #0
    sty last_noise_byte
    sty last_atten_byte
    jsr get_byte

.clear

    ; Read just init value and store into buffer and SN76489
    jsr get_byte
    sta registers, x
    sty chn_copy, x
.cbuf
    sta buffers + 255
    inc cbuf + 2
    dex
    bpl clear

    ; Initialize buffer pointer:
    sty bptr
    sty cur_pos

    jsr output

    jmp wait_frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Play one frame of the song
;
.play_frame

IF DEBUG_RASTER
    jsr raster_on
ENDIF

    lda #>buffers
    sta bptr+1

    ldx #6

    ; Loop through all "channels", one for each SN76489 register
.chn_loop
    lda chn_copy, x    ; Get status of this stream
    bne do_copy_byte   ; If > 0 we are copying bytes

    ; We are decoding a new match/literal
    lsr bit_data       ; Get next bit
    bne got_bit
    jsr get_byte       ; Not enough bits, refill!
    ror a              ; Extract a new bit and add a 1 at the high bit (from C set above)
    sta bit_data       
.got_bit
    jsr get_byte       ; Always read a byte, it could mean "match size/offset" or "literal byte"
    bcs store          ; Bit = 1 is "literal", bit = 0 is "match"

    sta chn_pos, x     ; Store in "copy pos"

    jsr get_byte
    sta chn_copy, x    ; Store in "copy length"

                       ; And start copying first byte
.do_copy_byte
    dec chn_copy, x    ; Decrease match length, increase match position
    inc chn_pos, x
    ldy chn_pos, x

    ; Now, read old data, jump to data store
    lda (bptr), y

.store
    ldy cur_pos
    sta registers, x   ; Store to output and buffer
    sta (bptr), y

    ; Increment channel buffer pointer
    inc bptr+1

    dex
    bpl chn_loop        ; Next channel

    inc cur_pos

IF DEBUG_RASTER
    jmp raster_off
ELSE
    jmp output
ENDIF

.reset
    lda #%01000000
    sta SHEILA_SYS_VIA_R13_IFR

.sn_chip_reset
    lda #%11111111
    sta SHEILA_SYS_VIA_R3_DDRA     ; data direction Register A

    ; Silence channels 0, 1, 2, 3
    lda #%10011111
    jsr sn_chip_write               ; Channel 0
    lda #%10111111
    jsr sn_chip_write               ; Channel 1
    lda #%11011111
    jsr sn_chip_write               ; Channel 2
    lda #%11111111
                                    ; Channel 3 (Noise)

.sn_chip_write
    sta SHEILA_SYS_VIA_PORT_A                 ; place psg data on port a slow bus
    lda #%00000000
    sta SHEILA_SYS_VIA_PORT_B
    pha
    pla
    nop
    nop                                       ; 3+4+2+2 + 2(LDA #) = 16 clocks = 8us
    lda #%00001000
    sta SHEILA_SYS_VIA_PORT_B
    rts

.output {

    jsr decode_regs

IF CHECK_EOF
    ; Check register 9 (CH3 Noise) for eof marker
    ldx #9
    lda decoded_registers,x
    cmp #$08
    beq eof
ENDIF

    ldy #11
    ldx #0

.reg_loop
    lda decoded_registers,x

    cpx #9
    bne write_to_sn
    cmp last_noise_byte
    beq cont

    sta last_noise_byte

.write_to_sn
    cpx #10
    bne continue_write
    cmp last_atten_byte
    beq cont

    sta last_atten_byte

.continue_write
    ora masks, x
    jsr sn_chip_write

.cont
    inx
    dey
    bne reg_loop

    rts

IF CHECK_EOF
.eof
    lda #1
    sta eof_flag
    rts
ENDIF
}

.decode_regs
{
    ldy #7
    ldx #0
    stx current_reg

.reg_loop
    lda registers, x
    cpx #0
    beq case_0
    cpx #1
    beq case_1
    cpx #2
    beq case_0
    cpx #3
    beq case_1
    cpx #4
    beq case_0
    cpx #5
    beq case_1
    cpx #6
    beq case_2
    jmp cont

.case_0
    stx temp_x
    sta temp_a
    and #&0f
    ldx current_reg
    sta decoded_registers, x        \\ Tone - Latch      (0)
    
    lda temp_a
    lsr a:lsr a:lsr a:lsr a

    inc current_reg
    inc current_reg
    ldx current_reg
    sta decoded_registers, x        \\ Attenuation       (2)
    dec current_reg

    ldx temp_x
    
    jmp cont

.case_1
    stx temp_x
    and #&3f
    ldx current_reg
    sta decoded_registers, x        \\ Tone - Data       (1)
    inc current_reg
    inc current_reg
    ldx temp_x
    
    jmp cont

.case_2
    stx temp_x
    sta temp_a
    and #&0f
    ldx current_reg
    sta decoded_registers, x        \\ Tone - Latch      (0)
    
    lda temp_a
    lsr a:lsr a:lsr a:lsr a

    inc current_reg
    ldx current_reg
    sta decoded_registers, x        \\ Attenuation       (1)
    
    ldx temp_x
    
.cont
    inx
    dey
    bne reg_loop

    rts
}

.track_title        SKIP 30
.track_artist       SKIP 30
.track_year         SKIP 30
.track_speed        SKIP 2
.track_length       SKIP 2
.irq_rate           SKIP 2


IF HEADER_CONTAINS_FRAME_COUNT
.frame_count
    EQUB 0,0,0
.progress_interval
    EQUB 0,0,0
.progress_counter
    EQUB 0,0,0
.progress_index
    EQUB 0
ENDIF

IF CHECK_EOF
.eof_flag
    EQUB 0
ENDIF