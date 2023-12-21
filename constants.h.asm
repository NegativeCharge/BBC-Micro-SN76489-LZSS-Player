OSBYTE                  = $fff4 
OSFILE                  = $ffdd
OSWRCH                  = $ffee
OSNEWL                  = $ffe7
OSRDCH                  = $ffe0

SHEILA_SYS_VIA_PORT_B   = $fe40 
SHEILA_SYS_VIA_R3_DDRA  = $fe43
SHEILA_SYS_VIA_R4_T1C_L = $fe44
SHEILA_SYS_VIA_R5_T1C_H = $fe45
SHEILA_SYS_VIA_R13_IFR  = $fe4d
SHEILA_SYS_VIA_PORT_A   = $fe4f

ZERO_PAGE_START         = $00
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
TRACK_SPEED             = $4e1e     \\ 50Hz = $4e1e, 60Hz = $4119, 200Hz = $1386, 882Hz = $046c, 2000Hz = $01f2 (1000000/x - 2)

DEBUG                   = FALSE
DEBUG_RASTER            = FALSE
SHOW_UI                 = TRUE
SHOW_FX                 = TRUE
DISPLAY_METADATA        = TRUE
USE_SWRAM               = TRUE
CHECK_EOF               = TRUE
EMBED_TRACK_INLINE      = FALSE

IF USE_SWRAM
    PLAYER_BKGND        = ".\ui\player5.bin"
ELSE
    PLAYER_BKGND        = ".\ui\player4.bin"
ENDIF

TRACK_PARTS                 = 2
TRACK_SRC_FILENAME_PREFIX   = ".\tracks\7chs\nearly_there"
TRACK_SRC_FILENAME_SUFFIX   = ".lzc"
TRACK_DST_DRIVE_PREFIX      = ":0."
TRACK_DST_FILENAME_PREFIX   = "$."

IF USE_SWRAM
    LZSS_PLAYER_H           = ".\lib\lzss-7chs.h.asm"
    LZSS_PLAYER_S           = ".\lib\lzss-7chs.s.asm"
ELSE
    LZSS_PLAYER_H           = ".\lib\lzss-7ch.h.asm"
    LZSS_PLAYER_S           = ".\lib\lzss-7ch.s.asm"
ENDIF

LOOP                    = TRUE

DISKSYS_LOADTO_ADDR     = $3C00