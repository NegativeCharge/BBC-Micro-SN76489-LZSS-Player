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

IF USE_SWRAM
    INCLUDE ".\lib\swr.h.asm"
ENDIF

ORG     BASE
GUARD   SCREEN

.start
    INCLUDE ".\lib\io.s.asm"
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

IF USE_SWRAM
    INCLUDE ".\lib\swr.s.asm"
ENDIF

INCLUDE LZSS_PLAYER_S

.init

IF SHOW_UI
    ldx #MODE
    jsr set_mode
    jsr disable_cursor

    lda #>MODE7_base_addr
    ldx #<screen_filename
    ldy #>screen_filename
    jsr disksys_load_direct

IF USE_SWRAM
    jsr swr_init
    beq no_swram

IF SHOW_UI
    ldx #0
.swr_ui_update_loop
    lda swr_ram_banks,x

    ; Update UI
    txa
    asl a
    tay
    lda #ttxt_gfx_blue
    sta swr_bank_0,y

    inx
    cpx swr_ram_banks_count
    bne swr_ui_update_loop
ENDIF

.no_swram
ENDIF

IF EMBED_TRACK_INLINE = FALSE
    lda #>song_data
    ldx #<track_filenames
    ldy #>track_filenames
    jsr disksys_load_direct

    IF USE_SWRAM
        jsr load_swram_banks
    ENDIF
ENDIF

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

IF EMBED_TRACK_INLINE = FALSE
    .track_filenames
        FOR n, 0, TRACK_PARTS - 1
            equs TRACK_DST_DRIVE_PREFIX + TRACK_DST_FILENAME_PREFIX + RIGHT$("00" + STR$(n), 2), 13
        NEXT
ENDIF

align $100
.song_data

IF EMBED_TRACK_INLINE
    INCBIN TRACK_SRC_FILENAME_PREFIX + TRACK_SRC_FILENAME_SUFFIX
    IF CHECK_EOF = FALSE
        .song_end
    ENDIF
ENDIF

.end

SAVE "PLAY",start,end,init

\ ******************************************************************
\ *    Memory Info
\ ******************************************************************

PRINT "------------------------------"
PRINT "          LZSS Player         "
PRINT "------------------------------"
PRINT "TRACK START            = ", ~song_data
IF CHECK_EOF = FALSE
PRINT "TRACK END              = ", ~song_end
ENDIF
PRINT "HIGH WATERMARK         = ", ~P%
PRINT "FREE                   = ", ~start+end
PRINT "------------------------------"

\ ******************************************************************
\ * Supporting Files
\ ******************************************************************

PUTBASIC "loader.bas","LOADER"
PUTFILE  "BOOT","!BOOT",&FFFF
IF SHOW_UI
    PUTFILE PLAYER_BKGND, "UI", &7C00
ENDIF

IF EMBED_TRACK_INLINE = FALSE AND USE_SWRAM = FALSE
    PUTFILE TRACK_SRC_FILENAME_PREFIX + TRACK_SRC_FILENAME_SUFFIX, TRACK_DST_FILENAME_PREFIX + "00", song_data
ENDIF

IF EMBED_TRACK_INLINE = FALSE AND USE_SWRAM
    FOR n, 0, TRACK_PARTS - 1
        PUTFILE TRACK_SRC_FILENAME_PREFIX + RIGHT$("00" + STR$(n), 2), TRACK_DST_FILENAME_PREFIX + RIGHT$("00" + STR$(n), 2), song_data
    NEXT
ENDIF