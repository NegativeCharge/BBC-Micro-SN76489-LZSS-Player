;
; LZSS Compressed SAP player for 16 match bits
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
; full SN raw register file this is 2816 bytes.
;

.chn_copy    SKIP     9
.chn_pos     SKIP     9
.bptr        SKIP     2
.cur_pos     SKIP     1
.chn_bits    SKIP     1