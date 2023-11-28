\\ MODE 7
MODE7_base_addr = &7C00
MODE7_char_width = 40
MODE7_char_height = 25

IF DISPLAY_METADATA
clock_addr = MODE7_base_addr + 1 * MODE7_char_width + 28
ELSE
clock_addr = MODE7_base_addr + 1 * MODE7_char_width + 34
ENDIF

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