.osfile_params
.osfile_nameaddr
    equw $ffff

; file load address
.osfile_loadaddr
    equd 0

; file exec address
.osfile_execaddr
    equd 0

; start address or length
.osfile_length
    equd 0

; end address of attributes
.osfile_endaddr
    equd 0

;--------------------------------------------------------------
; Load a file from disk to memory (SWR supported)
; Loads in sector granularity so will always write to page aligned address
;--------------------------------------------------------------
; A=memory address MSB (page aligned)
; X=filename address LSB
; Y=filename address MSB
.disksys_load_direct
{
    sta osfile_loadaddr+1

    ; Point to filename
    stx osfile_nameaddr+0
    sty osfile_nameaddr+1

    ; Ask OSFILE to load our file
	ldx #<osfile_params
	ldy #>osfile_params
	lda #$ff
    jmp OSFILE
}

.disksys_load_file
{
    ; Final destination
    sta write_to+1

    ; Where to?
    lda write_to+1
    bpl load_direct

    ; Load to screen if can't load direct
    lda #>DISKSYS_LOADTO_ADDR

    ; Load the file
    .load_direct
    jsr disksys_load_direct

    ; Do we need to copy it anywhere?
    .write_to
    ldx #$ff
    bpl disksys_copy_block_return

    ; Get filesize 
    ldy osfile_length+1
    lda osfile_length+0
    beq no_extra_page

    iny             ; always copy a whole number of pages
.no_extra_page

    ; Read from
    lda #>DISKSYS_LOADTO_ADDR
}

; A=read from PAGE, X=write to page, Y=#pages
.disksys_copy_block
{
    sta read_from+2
    stx write_to+2

    ; We always copy a complete number of pages

    ldx #0
.read_from
    lda $FF00, X
.write_to
    sta $ff00, X
    inx
    bne read_from
    inc read_from+2
    inc write_to+2
    dey
    bne read_from
}

.disksys_copy_block_return
    rts

IF USE_SWRAM
.load_swram_banks
{

IF SHOW_UI AND TRACK_PARTS > 1
    ldy #0
    lda #LO(swr_title)
	sta writeptr+0
	lda #HI(swr_title)
	sta writeptr+1

    jsr printString
    equs 134, "SW RAM:", 0
ENDIF

    ldx #TRACK_PARTS - 1
    beq exit
    stx active_swram_banks
    cpx swr_ram_banks_count
    bcc populate_banks

    ldx swr_ram_banks_count
    stx active_swram_banks      ; reduce active banks to number available
    beq exit

.populate_banks
    ldx #0
    ldy #1

.bank_loop
    stx temp_x
    sty temp_y
IF SHOW_UI
    ; Update UI
    txa
    asl a
    tay
    lda #ttxt_gfx_green
    sta swr_bank,y
    ldy temp_y
ENDIF
    txa
    jsr swr_select_slot

    lda temp_y
    asl a:asl a:asl a
    clc
	adc #LO(track_filenames)
	tax
	lda #HI(track_filenames)
	adc #0
    tay
       
    lda #$80
    jsr disksys_load_file

    ldy temp_y
    ldx temp_x
    iny
    inx
    cpx active_swram_banks
    bne bank_loop

    ; Set to first bank
    lda #0
    sta current_swram_bank
    jmp swr_select_slot
.exit
    rts
}
ENDIF