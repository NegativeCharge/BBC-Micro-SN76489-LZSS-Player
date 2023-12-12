INCLUDE "constants.h.asm"

ORG     ZERO_PAGE_START
GUARD   ZERO_PAGE_END

INCLUDE LZSS_PLAYER_H

IF SHOW_UI
    INCLUDE ".\lib\ui.h.asm"
ENDIF

IF SHOW_FX
    INCLUDE ".\lib\fx.h.asm"
ENDIF

ORG     BASE
GUARD   SCREEN

.start
    INCLUDE ".\lib\irq.s.asm"

IF DEBUG
    INCLUDE ".\debug.s.asm"
ENDIF

IF SHOW_UI
    INCLUDE ".\lib\ui.s.asm"
ENDIF

IF SHOW_FX
    INCLUDE ".\lib\fx.s.asm"
ENDIF

INCLUDE LZSS_PLAYER_S

.init

IF SHOW_UI
    ldx #MODE
    jsr set_mode
    jsr disable_cursor
    jsr load_screen

IF SHOW_FX
    jsr init_fx
ENDIF

.reinit
    lda #0
    sta clock_ticks
    sta clock_mins
    sta clock_secs
    
    sta row_counter+0
    sta row_counter+1

    sta pad
ENDIF

    jsr sn_chip_reset

    sei                         ; Disable interrupts
    jsr play
    cli                         ; Enable interrupts

IF LOOP
    lda song_ptr_init+0
    sta song_ptr+0

    lda song_ptr_init+1
    sta song_ptr+1

    lda cbuf_init+0
    sta cbuf+1

    lda cbuf_init+1
    sta cbuf+2

    jmp reinit
ELSE
    jmp *
ENDIF

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
    PUTFILE  PLAYER_BKGND, "UI", &7C00
ENDIF