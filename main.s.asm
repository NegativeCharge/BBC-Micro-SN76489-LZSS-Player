INCLUDE "constants.h.asm"

ORG     ZERO_PAGE_START
GUARD   ZERO_PAGE_END

INCLUDE LZSS_PLAYER_H

IF SHOW_UI
    INCLUDE ".\lib\ui.h.asm"
ENDIF

ORG     BASE
;GUARD   SCREEN

.start

IF DEBUG
    INCLUDE ".\debug.s.asm"
ENDIF

IF SHOW_UI
    INCLUDE ".\lib\ui.s.asm"
ENDIF

INCLUDE LZSS_PLAYER_S

.init

IF SHOW_UI
    ldx #MODE
    jsr set_mode
    jsr disable_cursor
    jsr load_screen
ENDIF

    lda #<TRACK_SPEED
    sta SHEILA_SYS_VIA_R4_T1C_L
    lda #>TRACK_SPEED
    sta SHEILA_SYS_VIA_R5_T1C_H

    jsr sn_chip_reset

    sei                         ; Disable interrupts
    jsr play
    cli                         ; Enable interrupts

    jmp *

align $100
.song_data
    INCBIN FILENAME
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
IF SHOW_UI
    PUTFILE  "ui\player.bin", "UI", &7C00
ENDIF