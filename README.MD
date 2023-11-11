# BBC Micro SN76489 LZSS Compressed Music Player

This app plays back an LZSS compressed stream of sequential SN76489 register writes which is essentially the register data stored as 11 bytes x N frames.

This is based on the Atari SAP LZSS Player/Compressor by DMSC : https://github.com/dmsc/lzss-sap

#Lempel–Ziv–Storer–Szymanski

Lempel–Ziv–Storer–Szymanski (LZSS) is a lossless data compression algorithm, a derivative of LZ77, that was created in 1982 by James A. Storer and Thomas Szymanski.

LZSS is a dictionary coding technique. It attempts to replace a string of symbols with a reference to a dictionary location of the same string.

The main difference between LZ77 and LZSS is that in LZ77 the dictionary reference could actually be longer than the string it was replacing. In LZSS, such references are omitted if the length is less than the "break even" point. Furthermore, LZSS uses one-bit flags to indicate whether the next chunk of data is a literal (byte) or a reference to an offset/length pair.