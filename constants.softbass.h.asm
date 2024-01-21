ROMSEL                  = $fe30
OSBYTE                  = $fff4 
OSFILE                  = $ffdd
OSWRCH                  = $ffee
OSNEWL                  = $ffe7
OSRDCH                  = $ffe0

ZERO_PAGE_START         = $2c
ZERO_PAGE_END           = $8f

; %1cctdddd
;   |||````-- Data
;   ||`------ Type         determines whether to latch volume (1) or tone/noise (0) data 
;   ``------- Channel      00, 01, 10, 11

; %0-DDDDDD
;   |``````-- Data
;   `-------- Unused

CH0TONELATCH            = %10000000
CH0VOL                  = %10010000
CH1TONELATCH            = %10100000
CH1VOL                  = %10110000
CH2TONELATCH            = %11000000
CH2VOL                  = %11010000
CH3TONELATCH            = %11100000
CH3VOL                  = %11110000

MODE                    = 7
BASE                    = $1100
SCREEN                  = $7c00

\\ Not needed for 7ch format - included in header
DEFAULT_TRACK_SPEED         = $4e1e     \\ 50Hz = $4e1e, 60Hz = $4119, 200Hz = $1386, 882Hz = $046c, 2000Hz = $01f2 (1000000/x - 2)

DEBUG                       = FALSE
DEBUG_RASTER                = FALSE
SHOW_UI                     = TRUE
SHOW_FX                     = TRUE
DISPLAY_METADATA            = TRUE
USE_SWRAM                   = TRUE
SOFTBASS_ENABLED            = TRUE
CHECK_EOF                   = TRUE
EMBED_TRACK_INLINE          = FALSE
HEADER_CONTAINS_FRAME_COUNT = TRUE

IF USE_SWRAM
    PLAYER_BKGND            = ".\ui\player6b.bin"
ELSE
    PLAYER_BKGND            = ".\ui\player4.bin"
ENDIF

DISK0_PARTS                 = 4
DISK2_PARTS                 = 0
TRACK_PARTS                 = DISK0_PARTS + DISK2_PARTS
TRACK_SRC_FILENAME_PREFIX   = ".\tracks\lzc1\prehistoric_tale_softbass"
TRACK_SRC_FILENAME_SUFFIX   = ".lzc"
TRACK_DST_DRIVE0_PREFIX     = ":0."
TRACK_DST_DRIVE2_PREFIX     = ":2."
TRACK_DST_FILENAME_PREFIX   = "$."

IF USE_SWRAM
    If SOFTBASS_ENABLED
        IRQ_H                   = ".\lib\irq-sb.h.asm"
        IRQ_S                   = ".\lib\irq-sb.s.asm"
        LZSS_PLAYER_H           = ".\lib\lzss-7chsb.h.asm"
        LZSS_PLAYER_S           = ".\lib\lzss-7chsb.s.asm"
    ELSE
        IRQ_H                   = ".\lib\irq.h.asm"
        IRQ_S                   = ".\lib\irq.s.asm"
        LZSS_PLAYER_H           = ".\lib\lzss-7chs.h.asm"
        LZSS_PLAYER_S           = ".\lib\lzss-7chs.s.asm"
    ENDIF
ELSE 
    IRQ_H                   = ".\lib\irq.h.asm"
    IRQ_S                   = ".\lib\irq.s.asm"
    LZSS_PLAYER_H           = ".\lib\lzss-7ch.h.asm"
    LZSS_PLAYER_S           = ".\lib\lzss-7ch.s.asm"
ENDIF

LOOP                        = TRUE

DISKSYS_LOADTO_ADDR         = $3c00