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
    EQUB 0,0,0,0,0,0,0,0,0,0,0

.bit_data    EQUB   1

.get_byte {
    lda song_data+1
    inc song_ptr
    bne skip
    inc song_ptr+1
.skip
    rts
}
song_ptr = get_byte + 1

align $100
.buffers SKIP 256 * 9

.play

    lda #<DEFAULT_TRACK_SPEED
    sta SHEILA_SYS_VIA_R4_T1C_L
    lda #>DEFAULT_TRACK_SPEED
    sta SHEILA_SYS_VIA_R5_T1C_H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Song Initialization - this runs in the first tick:
;
.init_song

    ; Example: here initializes song pointer:
    ; sta song_ptr
    ; stx song_ptr + 1

    ; Init all channels:
    ldx #8
    ldy #0
    sty last_noise_byte
    sty last_atten_byte
    
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

    lda song_data
    sta chn_bits
    ldx #8

    ; Loop through all "channels", one for each SN76489 register
.chn_loop
    lsr chn_bits
    bcs skip_chn       ; C=1 : skip this channel

    lda chn_copy, x    ; Get status of this stream
    bne do_copy_byte   ; If > 0 we are copying bytes

    ; We are decoding a new match/literal
    lsr bit_data       ; Get next bit
    bne got_bit
    jsr get_byte       ; Not enough bits, refill!
    ror a              ; Extract a new bit and add a 1 at the high bit (from C set above)
    sta bit_data       ;
.got_bit
    jsr get_byte       ; Always read a byte, it could mean "match size/offset" or "literal byte"
    bcs store          ; Bit = 1 is "literal", bit = 0 is "match"

    sta chn_pos, x     ; Store in "copy pos"

    jsr get_byte
    sta chn_copy, x    ; Store in "copy length"

                        ; And start copying first byte
.do_copy_byte
    dec chn_copy, x     ; Decrease match length, increase match position
    inc chn_pos, x
    ldy chn_pos, x

    ; Now, read old data, jump to data store
    lda (bptr), y

.store
    ldy cur_pos
    sta registers, x        ; Store to output and buffer
    sta (bptr), y

.skip_chn

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
{
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
    jmp sn_chip_write               ; Channel 3 (Noise)
}

.sn_chip_write
{
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
}

.output {
    ldy #7
    ldx #0
.reg_loop
    lda registers,x
    cpx #6
    bne write_to_sn
    cmp last_noise_byte
    beq write_noise_vol

    sta last_noise_byte
.write_to_sn
    jsr sn_chip_write

.vol_check_1
    cpx #1
    bne vol_check_2

    ldx #7
    lda registers,x
    lsr a:lsr a:lsr a:lsr a
    ora #CH0VOL
    jsr sn_chip_write
    ldx #1

    jmp cont

.vol_check_2
    cpx #3
    bne vol_check_3

    ldx #7
    lda registers,x
    and #&0f
    ora #CH1VOL
    jsr sn_chip_write
    ldx #3

    jmp cont

.vol_check_3
    cpx #5
    bne vol_check_4

    ldx #8
    lda registers,x
    lsr a:lsr a:lsr a:lsr a
    ora #CH2VOL
    jsr sn_chip_write
    ldx #5

    jmp cont

.vol_check_4
    cpx #6
    bne cont

.write_noise_vol
    ldx #8
    ldy #1
    lda registers,x
    cmp last_atten_byte
    beq cont
 
    sta last_atten_byte
    and #&0f
    ora #CH3VOL
    jsr sn_chip_write

.cont
    inx
    dey
    bne reg_loop

    rts
}