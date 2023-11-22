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