.swr_ram_banks          SKIP 8   ; 8 slots, each containing the rom bank ID of each available SW RAM bank or FF if none 
.swr_ram_banks_count    SKIP 1
.swr_rom_banks          SKIP 16  ; Contains 0 if RAM or non-zero if ROM
.swr_slot_selected      SKIP 1   ; The currently selected slot ID

.active_swram_banks     SKIP 1