\\ MODE 7
MODE7_base_addr = &7C00
MODE7_char_width = 40
MODE7_char_height = 25

IF DISPLAY_METADATA
clock_addr = MODE7_base_addr + 1 * MODE7_char_width + 28
ELSE
clock_addr = MODE7_base_addr + 1 * MODE7_char_width + 34
ENDIF

row_counter_addr = MODE7_base_addr + 21 * MODE7_char_width + 3

swr_bank_0 = MODE7_base_addr + 24 * MODE7_char_width + 0
selected_swr_bank = MODE7_base_addr + 18 * MODE7_char_width + 1

ttxt_gfx_red     = 145
ttxt_gfx_green   = 146
ttxt_gfx_yellow  = 147
ttxt_gfx_blue    = 148
ttxt_gfx_magenta = 149
ttxt_gfx_cyan    = 150
ttxt_gfx_white   = 151


track_title_addr = MODE7_base_addr + 5 * MODE7_char_width + 10
track_artist_addr = MODE7_base_addr + 6 * MODE7_char_width + 10
track_year_addr = MODE7_base_addr + 7 * MODE7_char_width + 10
track_speed_addr = MODE7_base_addr + 8 * MODE7_char_width + 10
track_length_min_addr = MODE7_base_addr + 1 * MODE7_char_width + 34
track_length_sec_addr = MODE7_base_addr + 1 * MODE7_char_width + 37

.readptr         SKIP 2
.writeptr        SKIP 2

.clock_ticks     SKIP 1
.clock_secs      SKIP 1
.clock_mins      SKIP 1

.row_counter     SKIP 2