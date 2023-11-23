\\ MODE 7
MODE7_base_addr = &7C00
MODE7_char_width = 40
MODE7_char_height = 25
clock_addr = MODE7_base_addr + 1 * MODE7_char_width + 34

.readptr         SKIP 2
.writeptr        SKIP 2

.clock_ticks     SKIP 1
.clock_secs      SKIP 1
.clock_mins      SKIP 1