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

MODE                    = 5
BASE                    = $1100
SCREEN                  = $5800

TRACK_SPEED             = $4e1e     \\ 50Hz = $4e1e, 2000Hz = $01f2 (1000000/x - 2)
DEBUG                   = FALSE