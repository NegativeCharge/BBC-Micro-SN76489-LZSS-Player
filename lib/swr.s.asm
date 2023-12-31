; Scan for SWR banks
; Mark swr_rom_banks as 0 if SWR or non-zero if ROM
; On exit A contains number of SWR banks, Z=1 if no SWR, or Z=0 if SWR

.swr_init
{
    sei
    lda $f4
    pha

    ; scan for roms
    ldx #$0f

.rom_loop
    stx $f4
    stx ROMSEL  ; select rom bank
    ldy #0      ; assume rom
    lda $8008   ; read byte
    eor #$aa    ; invert, so that we are know we are writing a different value 
    sta $8008   ; write byte
    cmp $8008   ; check that byte was written by comparing what we wrote with what we read back
    bne no_ram
    eor #$aa
    sta $8008
    ldy #1      ; is ram
.no_ram
    tya
    sta swr_rom_banks,x ; 0 if ram, non-zero if rom
    dex
    bpl rom_loop

    ; reset swr_ram_banks array
    lda #$ff
FOR n, 0, TRACK_PARTS-2
    sta swr_ram_banks+n
NEXT

    ; put available ram bank id's into swr_ram_banks
    ldx #0
    ldy #0
.ram_loop
    lda swr_rom_banks,x
    beq next
    txa
    sta swr_ram_banks,y
    iny
    cpy #TRACK_PARTS-1
    beq finished
.next
    inx
    cpx #16
    bne ram_loop

.finished
    sty swr_ram_banks_count

    ; restore previous bank
    pla
    sta $f4
    sta ROMSEL
    cli

    lda swr_ram_banks_count
    rts
}

; Select the rom bank associated with the slot id given in A (0-3) 
; swr_init must have been called previously
;
; A BBC Master will have four 16Kb SWR banks
;
; On entry A contains slot id to be selected (0-3)
; On exit A contains bank ID, N=0 if success, N=1 if failed
;   $f4 is updated with the selected ROM bank
;   swr_slot_selected contains the selected slot ID
;   does not preserve previously selected bank
; Clobbers A,X

.swr_select_slot
{
    cmp #8
    bcs bad_socket ; >= 8
    and #%00000111
    tax
    lda swr_ram_banks,X
    bmi bad_socket
    sta $f4
    sta ROMSEL
    sta swr_slot_selected

.bad_socket
    rts
}
