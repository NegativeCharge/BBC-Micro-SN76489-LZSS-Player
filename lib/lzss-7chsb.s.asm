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

.masks
    EQUB CH0TONELATCH, 0, CH0VOL, CH1TONELATCH, 0, CH1VOL, CH2TONELATCH, 0, CH2VOL, CH3TONELATCH, CH3VOL

; In: A has second byte. Out: A has timer lo, Y has timer hi
MACRO SET_UP_TIMER_VALUES
{
    ; Mask out bit 6 of data byte
    and #%00111111
    tay
    lda first_byte
    asl a
    asl a
    asl a
    asl a
    ora #%00000110
}
ENDMACRO

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
    jsr sn_chip_reset

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
    sty last_register_values+0
    sty last_register_values+1
    sty last_register_values+2
    sty last_register_values+3
    sty last_register_values+4
    sty last_register_values+5
    sty last_register_values+6
    sty last_register_values+7
    sty last_register_values+8
    sty last_register_values+9
    sty last_register_values+10
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

    jsr irq_init
    jsr output

.play_loop
    
IF CHECK_EOF
    lda eof_flag
    beq continue_play
ELSE
    lda song_ptr + 1
    cmp #>song_end
    bne continue_play
    lda song_ptr + 0
    cmp #<song_end
    bne continue_play
ENDIF

	jmp reset

.continue_play
    jmp play_loop

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
    lda chn_copy, x                 ; Get status of this stream
    bne do_copy_byte                ; If > 0 we are copying bytes

    ; We are decoding a new match/literal
    lsr bit_data                    ; Get next bit
    bne got_bit
    jsr get_byte                    ; Not enough bits, refill!
    ror a                           ; Extract a new bit and add a 1 at the high bit (from C set above)
    sta bit_data       
.got_bit
    jsr get_byte                    ; Always read a byte, it could mean "match size/offset" or "literal byte"
    bcs store                       ; Bit = 1 is "literal", bit = 0 is "match"

    sta chn_pos, x                  ; Store in "copy pos"

    jsr get_byte
    sta chn_copy, x                 ; Store in "copy length"

                                    ; And start copying first byte
.do_copy_byte
    dec chn_copy, x                 ; Decrease match length, increase match position
    inc chn_pos, x
    ldy chn_pos, x

    ; Now, read old data, jump to data store
    lda (bptr), y

.store
    ldy cur_pos
    sta registers, x                ; Store to output and buffer
    sta (bptr), y

    ; Increment channel buffer pointer
    inc bptr+1

    dex
    bpl chn_loop                    ; Next channel

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
{
    ; Silence channels 0, 1, 2, 3
    lda #%10011111
    jsr sn_chip_write               ; Channel 0
    lda #%10111111
    jsr sn_chip_write               ; Channel 1
    lda #%11011111
    jsr sn_chip_write               ; Channel 2
    lda #%11111111
    jmp sn_chip_write               ; Channel 3 (Noise)
}

.sn_chip_write_with_attenuation
{
    tax
    and #%11110000                  ; %xrrr0000
    sta remask+1
    txa                             ; %xrrrvvvv
    and #%00001111                  ; %0000vvvv
    tax
    lda sn_volume_table,x
.remask 
    ora #%11111111
}

.sn_chip_write
{
    php
    sei

    ; Check if volume control needs applying
    ; First check if bit 7 is set, 0=DATA 1=LATCH

	bit psg_latch_bit
	beq no_volume

    ; This is a latch register write
    ; and check bit 4 to see if it is a volume register write, 1=VOLUME, 0=PITCH
	bit psg_volume_bit
	beq no_volume		            ; Not a volume register write

	tay				
	and #$f0		
	sta psg_register
	tya				
	and #$0f		

	tay				
	lda volume_table, y
	and #$0f			
	ora volume_mask		        ; All bits set to mask audio, or clear to leave as is
	ora psg_register

.no_volume
    ldx #%11111111
    stx SHEILA_SYS_VIA_R3_DDRA
    sta SHEILA_SYS_VIA_PORT_A
    inx
    stx SHEILA_SYS_VIA_PORT_B
    nop
    nop
    nop
    lda #%00001000
    sta SHEILA_SYS_VIA_PORT_B
    cli
    plp
    
    rts
}

; Set volume mask
; X contains volume flag (1=on,0=off)
; 
.set_volume_mask
{
	lda volume_mask_t,x
	sta volume_mask
	rts
}

IF CHECK_EOF
.eof
    lda #$01
    sta eof_flag
    rts
ENDIF

.output {

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
    
.case_0
    stx temp_x
    sta temp_a
    and #%00001111
    ldx current_reg
    sta decoded_registers, x        \\ Tone - Latch      (0)
    
    lda temp_a
    lsr a
    lsr a
    lsr a
    lsr a

    inc current_reg
    cpx #9
    beq skip
    inc current_reg

.skip
    ldx current_reg
    sta decoded_registers, x        \\ Attenuation       (2)

    cpx #9
    beq decode_continue
    dec current_reg
    jmp decode_continue

.case_1                             ; Compressed registers 1, 3, or 5 => Registers 1, 4, 7
    stx temp_x

    ldx current_reg
    sta decoded_registers, x        \\ Tone - Data       (1)
    inc current_reg
    inc current_reg

.decode_continue
    ldx temp_x
    inx
    dey
    bne reg_loop

    ; Check register 9 (CH3 Noise) for eof marker
    ldx #9                      ; Tone 3
    lda decoded_registers,x
IF CHECK_EOF
    cmp #%00001000
    beq eof
ENDIF
    ora masks, x
    cmp last_register_values+9
    beq no_tone_3
    sta last_register_values+9
    jsr sn_chip_write

.no_tone_3
    ldx #10                     ; Volume 3
    lda decoded_registers,x
    ora masks, x
    cmp last_register_values+10
    beq no_vol_3

    sta last_register_values+10
    jsr sn_chip_write_with_attenuation

.no_vol_3
    ldx #0
    lda decoded_registers,x
    ora masks, x
    sta first_byte
    ldx #1                      ; Tone 0
    lda decoded_registers,x
    ora masks, x
    jsr do_tone_0

.no_tone_0
    ldx #3
    lda decoded_registers,x
    ora masks, x
    sta first_byte
    ldx #4                      ; Tone 1
    lda decoded_registers,x
    ora masks, x
    jsr do_tone_1
 
 .no_tone_1
    ldx #6
    lda decoded_registers,x
    ora masks, x
    sta first_byte
    ldx #7                      ; Tone 2
    lda decoded_registers,x
    ora masks, x
    jsr do_tone_2
 
 .no_tone_2
    ldx #2                      ; Volume 0
    lda decoded_registers,x
    
    and #$0f		
	tay				
	lda volume_table, y
	and #$0f			
	ora volume_mask

    ora masks, x

    sta u1writeval
    cmp last_register_values+0
    beq no_vol_0

    sta last_register_values+0
    bit bass_flag+0
    bmi no_vol_0
IF DEBUG AND SOFTBASS_ENABLED
    jsr debug_bass_flags
ENDIF
    jsr sn_chip_write_with_attenuation

.no_vol_0
    ldx #5                      ; Volume 1
    lda decoded_registers,x
    
    and #$0f		
	tay				
	lda volume_table, y
	and #$0f			
	ora volume_mask
    
    ora masks, x
    sta u2writeval
    cmp last_register_values+5
    beq no_vol_1

    sta last_register_values+5
    bit bass_flag+1
    bmi no_vol_1
IF DEBUG AND SOFTBASS_ENABLED
    jsr debug_bass_flags
ENDIF
    jsr sn_chip_write_with_attenuation

.no_vol_1
    ldx #8                      ; Volume 2
    lda decoded_registers,x

    and #$0f		
	tay				
	lda volume_table, y
	and #$0f			
	ora volume_mask
    
    ora masks, x
    sta s2writeval
    cmp last_register_values+8
    beq no_vol_2

    sta last_register_values+8
    bit bass_flag+2
    bmi no_vol_2
IF DEBUG AND SOFTBASS_ENABLED
    jsr debug_bass_flags
ENDIF
    jmp sn_chip_write_with_attenuation

.no_vol_2

    rts
}

; A is pitch register: $81, $a1, $c1
.set_bitbang_pitch
{
    jsr sn_chip_write
    lda #$00
    jmp sn_chip_write
}

;in: A has second byte
.do_tone_0
{
    cmp #%01000000                  ; Bit 7 is always clear
    bcs do_bass

    ; Bass is now off. Was it previously on?
    bit bass_flag+0
    bpl do_normal_tone

    ; Turn off IRQ, reset flag
    sta temp_a
    lda #%01000000
    sta SHEILA_USER_VIA_R14_IER
    sta SHEILA_USER_VIA_R13_IFR     ; Clear
    lda #0
    sta bass_flag+0
    lda u1writeval                  ; Restore volume
    jsr sn_chip_write_with_attenuation
    lda temp_a
    jmp do_normal_tone

.do_bass
IF DEBUG AND SOFTBASS_ENABLED
    jsr debug_bass
ENDIF
    SET_UP_TIMER_VALUES
    sta SHEILA_USER_VIA_R6_T1L_L    ; Tone 0 bass timer_lo
    sty SHEILA_USER_VIA_R7_T1L_H    ; Tone 0 bass timer hi

    ; Is bass already on?
    bit bass_flag+0
    bmi alreadyon
    
    ; Enable timer
    lda #%11000000                  ; USER_VIA_T1
    sta SHEILA_USER_VIA_R14_IER
    sta bass_flag+0                 ; Has top bit set
    lda #%10000001                  ; Set period to 1
    jmp set_bitbang_pitch
.alreadyon
    rts
}

; in: A has second byte
.do_normal_tone
{
    tay
    lda first_byte
    jsr sn_chip_write
    tya
    jmp sn_chip_write
}

;in: A has second byte
.do_tone_1
{
    cmp #%01000000                  ; Bit 7 is always clear
    bcs do_bass

    ; Bass is now off. Was it previously on?
    bit bass_flag+1
    bpl do_normal_tone
    
    ; Turn off IRQ, reset flag
    sta temp_a
    lda #%00100000
    sta SHEILA_USER_VIA_R14_IER
    sta SHEILA_USER_VIA_R13_IFR     ; clear
    lda #0
    sta bass_flag+1
    lda u2writeval                  ; restore vol
    jsr sn_chip_write_with_attenuation
    lda temp_a
    jmp do_normal_tone

.do_bass
IF DEBUG AND SOFTBASS_ENABLED
    jsr debug_bass
ENDIF
    SET_UP_TIMER_VALUES
    sta u2latchlo                   ; Tone 1 bass timer lo
    sty u2latchhi                   ; Tone 1 bass timer hi
    
    ; Is bass already on?
    bit bass_flag+1
    bmi alreadyon

    ; Enable timer
    sta SHEILA_USER_VIA_R4_T2C_L    ; Tone 1 bass timer lo
    sty SHEILA_USER_VIA_R5_T2C_H    ; Tone 1 bass timer hi
    lda #%10100000                  ; USER_VIA_T2
    sta SHEILA_USER_VIA_R14_IER
    sta SHEILA_USER_VIA_R13_IFR     ; Force IRQ
    sta bass_flag+1                 ; Has top bit set
    lda #%10100001                  ; Set period to 1
    jmp set_bitbang_pitch

.alreadyon
    rts
}

;in: A has second byte
.do_tone_2
{
    cmp #%01000000                  ; Bit 7 is always clear
    bcs do_bass

    ; Bass is now off. Was it previously on?
    bit bass_flag+2
    bpl do_normal_tone
    
    ; Turn off IRQ, reset flag
    sta temp_a
    lda #%00100000
    sta SHEILA_SYS_VIA_R14_IER
    sta SHEILA_SYS_VIA_R13_IFR      ; Clear
    lda #0
    sta bass_flag+2
    lda s2writeval                  ; Restore vol
    jsr sn_chip_write_with_attenuation
    lda temp_a
    jmp do_normal_tone

.do_bass
IF DEBUG AND SOFTBASS_ENABLED
    jsr debug_bass
ENDIF
    SET_UP_TIMER_VALUES
    sta s2latchlo                   ; Tone 2 bass timer lo
    sty s2latchhi                   ; Tone 2 bass timer hi

    ; Is bass already on?
    bit bass_flag+2
    bmi alreadyon

    ; Enable timer
    sta SHEILA_SYS_VIA_R4_T2C_L     ; Tone 2 bass timer lo
    sty SHEILA_SYS_VIA_R5_T2C_H     ; Tone 2 bass timer hi

    lda #%10100000                  ; SYS_VIA_T2
    sta SHEILA_SYS_VIA_R14_IER
    sta SHEILA_SYS_VIA_R13_IFR      ; Force IRQ
    sta bass_flag+2                 ; Has top bit set

    lda #%11000001                  ; Set period to 1
    jmp set_bitbang_pitch
.alreadyon
    rts
}

IF DEBUG AND SOFTBASS_ENABLED
.debug_bass_flags
{
    sta temp_a
    sty temp_y

    lda #LO(debug_footer+7)
	sta writeptr+0
	lda #HI(debug_footer+7)
	sta writeptr+1

    ldy #0

    lda bass_flag+0
    jsr write_hex_byte

    iny:iny
    lda bass_flag+1
    jsr write_hex_byte

    iny:iny
    lda bass_flag+2
    jsr write_hex_byte

    ldy temp_y
    lda temp_a

    rts
}
ENDIF

IF DEBUG AND SOFTBASS_ENABLED
.debug_bass {
    sta temp_a
    sty temp_y

    lda #LO(debug_footer)
	sta writeptr+0
	lda #HI(debug_footer)
	sta writeptr+1

    ldy #0
    inc bass_count+0
    bne skip_hi
    inc bass_count+1
    
.skip_hi
    lda bass_count+1
    jsr write_hex_byte
    iny
    lda bass_count+0
    jsr write_hex_byte

    ldy temp_y
    lda temp_a

    rts
}
ENDIF

.track_title        SKIP 30
.track_artist       SKIP 30
.track_year         SKIP 30
.track_speed        SKIP 2
.track_length       SKIP 2
.irq_rate           SKIP 2

.last_register_values
    EQUB 0,0,0,0,0,0,0,0,0,0,0

.first_byte 
    EQUB 0

.bass_flag
    EQUB 0, 0, 0

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

.sn_volume_table
    EQUB 3,4,5,6,7,8,9,10,11,12,13,14,15,15,15,15

IF DEBUG AND SOFTBASS_ENABLED
.bass_count
    EQUW 0
ENDIF