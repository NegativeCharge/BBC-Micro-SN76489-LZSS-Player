OSBYTE                  = $fff4 
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
BASE                    = $1100
SCREEN                  = $7c00

TRACK_SPEED             = $4e1e     \\ 50Hz = $4e1e, 2000Hz = $01f2 (1000000/x - 2)
DEBUG                   = TRUE

Exo_addr                = $880
Exo_small_buffer_addr   = $440
Exo_large_buffer_addr   = $7400

UNCOMPRESSED_TRACK      = FALSE
EXOMISER_TRACK          = FALSE
HUFFMUNCH_TRACK         = FALSE
LZSS_TRACK              = TRUE