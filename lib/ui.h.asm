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
progress_bar_addr = MODE7_base_addr + 11 * MODE7_char_width + 4

swr_title = MODE7_base_addr + 9 * MODE7_char_width + 2
swr_bank = MODE7_base_addr + 9 * MODE7_char_width + 10
debug_selected_swr_bank = MODE7_base_addr + 12 * MODE7_char_width + 5
debug_frame_count = MODE7_base_addr + 12 * MODE7_char_width + 22
debug_progress_interval = debug_frame_count + 7
debug_footer = MODE7_base_addr + 24 * MODE7_char_width + 1

ttxt_gfx_red      = 145
ttxt_gfx_green    = 146
ttxt_gfx_yellow   = 147
ttxt_gfx_blue     = 148
ttxt_gfx_magenta  = 149
ttxt_gfx_cyan     = 150
ttxt_gfx_white    = 151

ttxt_gfx_square   = $7c
ttxt_gfx_progress = ttxt_gfx_white

track_title_addr = MODE7_base_addr + 5 * MODE7_char_width + 11
track_artist_addr = MODE7_base_addr + 6 * MODE7_char_width + 11
track_year_addr = MODE7_base_addr + 7 * MODE7_char_width + 11
track_speed_addr = MODE7_base_addr + 8 * MODE7_char_width + 11
track_length_min_addr = MODE7_base_addr + 1 * MODE7_char_width + 34
track_length_sec_addr = MODE7_base_addr + 1 * MODE7_char_width + 37

.readptr         SKIP 2
.writeptr        SKIP 2

.clock_ticks     SKIP 1
.clock_secs      SKIP 1
.clock_mins      SKIP 1

.row_counter     SKIP 2