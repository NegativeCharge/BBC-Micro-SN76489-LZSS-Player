INCLUDE "constants.h.asm"

ORG     ZERO_PAGE_START
GUARD   ZERO_PAGE_END

INCLUDE ".\lib\lzss-9.h.asm"

ORG     BASE
GUARD   SCREEN

.start

INCLUDE ".\lib\lzss-9.s.asm"

.init
    \\ Set MODE 7
	lda #22
    jsr OSWRCH
	lda #7
    jsr OSWRCH

    \\ Disable cursor
	lda #$0a
    sta $fe00
	lda #$20
    sta $fe01

    lda #<TRACK_SPEED
    sta SHEILA_SYS_VIA_R4_T1C_L
    lda #>TRACK_SPEED
    sta SHEILA_SYS_VIA_R5_T1C_H

    jsr sn_chip_reset
    sei                         ; Disable interrupts
    jmp play
    cli                         ; Enable interrupts

    rts

align $100
.song_data
    INCBIN "tracks\gf2-title.lz16-9"
.song_end

.end

SAVE "PLAY",start,end,init

\ ******************************************************************
\ *    Memory Info
\ ******************************************************************

PRINT "------------------------------"
PRINT "          LZSS Player         "
PRINT "------------------------------"
PRINT "TRACK START            = ", ~song_data
PRINT "TRACK END              = ", ~song_end
PRINT "HIGH WATERMARK         = ", ~P%
PRINT "FREE                   = ", ~start+end
PRINT "------------------------------"

\ ******************************************************************
\ * Supporting Files
\ ******************************************************************

PUTBASIC "loader.bas","LOADER"
PUTFILE  "BOOT","!BOOT",&FFFF