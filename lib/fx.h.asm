FX_chr_x = 4
FX_chr_y = 12
FX_chr_w = 32
FX_chr_h = 5

FX_address = MODE7_base_addr + FX_chr_y*40 + FX_chr_x
FX_address_row0 = FX_address
FX_address_row1 = FX_address_row0 + 40
FX_address_row2 = FX_address_row1 + 40
FX_address_row3 = FX_address_row2 + 40
FX_address_row4 = FX_address_row3 + 40

FX_num_freqs = 32
FX_num_channels = 4

.tmp_fx_y               SKIP 1
.tmp_var                SKIP 1
.freq_array				SKIP FX_num_freqs