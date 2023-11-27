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

ZERO_PAGE_START         = $80
ZERO_PAGE_END           = $ff

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
DISPLAY_METADATA        = TRUE

PLAYER_BKGND            = ".\ui\player2.bin"
FILENAME                = ".\tracks\7ch\test01.lzc"
LZSS_PLAYER_H           = ".\lib\lzss-7ch.h.asm"
LZSS_PLAYER_S           = ".\lib\lzss-7ch.s.asm"