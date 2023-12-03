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

    lda #0
    sta clock_ticks
    sta clock_mins
    sta clock_secs
    
    sta row_counter+0
    sta row_counter+1
ENDIF

    jsr sn_chip_reset

    sei                         ; Disable interrupts
    jsr play
    cli                         ; Enable interrupts

    jmp *

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wait for next frame
;
.wait_frame
    lda #%01000000              ; Timer 1 mask bit
    bit SHEILA_SYS_VIA_R13_IFR
    bne processSysViaT1

    lda #%00000010              ; V-Sync
    bit SHEILA_SYS_VIA_R13_IFR
    bne vsyncHandler

    jmp wait_frame

.vsyncHandler
    sta SHEILA_SYS_VIA_R13_IFR
    jsr processVsync
    jmp wait_frame

.processSysViaT1
    sta SHEILA_SYS_VIA_R13_IFR
    jsr play_frame
IF SHOW_UI
    jsr incrementRowCounter
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Check for ending of song and jump to the next frame
;
.check_end_song
    lda song_ptr + 1
    cmp #>song_end
    bne wait_frame
    lda song_ptr + 0
    cmp #<song_end
    bne wait_frame

    jmp reset

.processVsync
IF SHOW_UI
IF SHOW_FX
    jsr update_fx_array
    jsr poll_fx
ENDIF
    jsr updateRowData
    jmp updateTicks
ELSE
    rts
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