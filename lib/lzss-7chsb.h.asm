;
; LZSS Compressed SN76489 player for 16 match bits
; --------------------------------------------
;
; (c) 2020 DMSC
; Code under MIT license, see LICENSE file.
;
; This player uses:
;  Match length: 8 bits  (1 to 256)
;  Match offset: 8 bits  (1 to 256)
;  Min length: 2
;  Total match bits: 16 bits
;
; Compress using:
;  lzss -b 16 -o 8 -m 1 input.bin test.lz16
;
; Assemble this file with BeebAsm assembler, the compressed song is expected in
; the `test.lz16` file at assembly time.
;
; The plater needs 256 bytes of buffer for each SN76489 register stored, for a
; full SN 7-stream compressed register file this is 1,792 bytes.
;
; BBC Micro / BeebAsm by Negative Charge, November 2023

.chn_copy           SKIP     7
.chn_pos            SKIP     7
.bptr               SKIP     2
.cur_pos            SKIP     1
.chn_bits           SKIP     1

.current_reg        SKIP     1
.temp_a             SKIP     1
.temp_x             SKIP     1
.temp_y             SKIP     1

.bit_data           EQUB     1

.registers
    EQUB 0,0,0,0,0,0,0

.decoded_registers   
    EQUB 0,0,0,0,0,0,0,0,0,0,0