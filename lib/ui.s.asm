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