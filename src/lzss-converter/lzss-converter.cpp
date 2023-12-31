/*
 * BBC Micro SN76489 Raw Register File Compressor
 * ----------------------------------------------
 *
 * This implementa an optimal LZSS compressor for the SAP-R music files.
 * The compressed files can be played on a BBC Micro using the included
 * assembly programs, depending on the specific parameters.
 *
 * (c) 2020 DMSC
 * Code under MIT license, see LICENSE file.
 * 
 * BBC Micro modification: Negative Charge, 2023
 * 
 * For lzss-9 player, input should be in format [BYTE Tone 1 Latch][BYTE Tone 1 Data][BYTE Vol 1][BYTE Tone 2 Latch][BYTE Tone 2 Data][BYTE Vol 2][BYTE Tone 3 Latch][BYTE Tone 3 Data][BYTE Vol 3][BYTE Noise Latch][BYTE Noise Vol]
 * For lzss-9c player, input should be in format [BYTE Tone 1 Latch][BYTE Tone 1 Data][BYTE Tone 2 Latch][BYTE Tone 2 Data][BYTE Tone 3 Latch][BYTE Tone 3 Data][BYTE Noise Latch][BYTE Vol 0|Vol 1][BYTE Vol 2|Vol Noise]
 * 
 * Compress with lzss-converter.exe -b 16 -o 8 -m 1 .\uncompressed\input.bin output.lz16-9
 */

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <io.h>
#include <fcntl.h>
#include "getopt.h"
void set_binary(void)
{
    setmode(fileno(stdout), O_BINARY);
    setmode(fileno(stdin), O_BINARY);
}
#else
void set_binary(void)
{
}
#endif


///////////////////////////////////////////////////////
// Bit encoding functions
struct bf
{
    int len;
    uint8_t buf[65536];
    int bnum;
    int bpos;
    int hpos;
    int total;
    FILE* out;
};

static void init(struct bf* x)
{
    x->total = 0;
    x->len = 0;
    x->bnum = 0;
    x->bpos = -1;
    x->hpos = -1;
}

static void bflush(struct bf* x)
{
    if (x->len)
        fwrite(x->buf, x->len, 1, x->out);
    x->total += x->len;
    x->len = 0;
    x->bnum = 0;
    x->bpos = -1;
    x->hpos = -1;
}


static void add_bit(struct bf* x, int bit)
{
    if (x->bpos < 0)
    {
        // Adds a new byte holding bits
        x->bpos = x->len;
        x->bnum = 0;
        x->len++;
        x->buf[x->bpos] = 0;
    }
    if (bit)
        x->buf[x->bpos] |= 1 << x->bnum;
    x->bnum++;
    if (x->bnum == 8)
    {
        x->bpos = -1;
        x->bnum = 0;
    }
}

static void add_byte(struct bf* x, int byte)
{
    x->buf[x->len] = byte;
    x->len++;
}

static void add_hbyte(struct bf* x, int hbyte)
{
    if (x->hpos < 0)
    {
        // Adds a new byte holding half-bytes
        x->hpos = x->len;
        x->len++;
        x->buf[x->hpos] = hbyte & 0x0F;
    }
    else
    {
        // Fixes last h-byte
        x->buf[x->hpos] |= hbyte << 4;
        x->hpos = -1;
    }
}

///////////////////////////////////////////////////////
// LZSS compression functions
static int maximum(int a, int b)
{
    return a > b ? a : b;
}

static int get_mlen(const uint8_t* a, const uint8_t* b, int max)
{
    for (int i = 0; i < max; i++)
        if (a[i] != b[i])
            return i;
    return max;
}

int hsh(const uint8_t* p)
{
    size_t x = (size_t)p;
    return 0xFF & (x ^ (x >> 8) ^ (x >> 16) ^ (x >> 24));
}

static int bits_moff = 4;       // Number of bits used for OFFSET
static int bits_mlen = 4;       // Number of bits used for MATCH
static int min_mlen = 2;        // Minimum match length
static int fmt_literal_first = 0; // Always include first literal in the output
static int fmt_pos_start_zero = 0; // Match positions start at 0, else start at max

#define bits_literal (1+8)      // Number of bits for encoding a literal
#define bits_match (1 + bits_moff + bits_mlen)  // Bits for encoding a match

#define max_mlen (min_mlen + (1<<bits_mlen) -1) // Maximum match length
#define max_off (1<<bits_moff)  // Maximum offset

// Statistics
static int* stat_len;
static int* stat_off;


// Struct for LZ optimal parsing
struct lzop
{
    const uint8_t* data;// The data to compress
    int size;           // Data size
    int* bits;          // Number of bits needed to code from position
    int* mlen;          // Best match length at position (0 == no match);
    int* mpos;          // Best match offset at position
};

static void lzop_init(struct lzop* lz, const uint8_t* data, int size)
{
    lz->data = data;
    lz->size = size;
    lz->bits = (int*)calloc(sizeof(int), size);
    lz->mlen = (int*)calloc(sizeof(int), size);
    lz->mpos = (int*)calloc(sizeof(int), size);
}

static void lzop_free(struct lzop* lz)
{
    free(lz->bits);
    free(lz->mlen);
    free(lz->mpos);
}

// Returns maximal match length (and match position) at pos.
static int match(const uint8_t* data, int pos, int size, int* mpos)
{
    int mxlen = -maximum(-max_mlen, pos - size);
    int mlen = 0;
    for (int i = maximum(pos - max_off, 0); i < pos; i++)
    {
        int ml = get_mlen(data + pos, data + i, mxlen);
        if (ml > mlen)
        {
            mlen = ml;
            *mpos = pos - i;
        }
    }
    return mlen;
}

// Calculate optimal encoding from the end of stream.
// if last_literal is 1, we force the last byte to be encoded as a literal.
static void lzop_backfill(struct lzop* lz, int last_literal)
{
    // If no bytes, nothing to do
    if (!lz->size)
        return;

    if (last_literal)
    {
        // Forced last literal - process one byte less
        lz->mlen[lz->size - 1] = 0;
        lz->size--;
        if (!lz->size)
            return;
    }

    // Init last bits
    lz->bits[lz->size - 1] = bits_literal;

    // Go backwards in file storing best parsing
    for (int pos = lz->size - 2; pos >= 0; pos--)
    {
        // Get best match at this position
        int mp = 0;
        int ml = match(lz->data, pos, lz->size, &mp);

        // Init "no-match" case
        int best = lz->bits[pos + 1] + bits_literal;

        // Check all posible match lengths, store best
        lz->bits[pos] = best;
        lz->mpos[pos] = mp;
        for (int l = ml; l >= min_mlen; l--)
        {
            int b;
            if (pos + l < lz->size)
                b = lz->bits[pos + l] + bits_match;
            else
                b = 0;
            if (b < best)
            {
                best = b;
                lz->bits[pos] = best;
                lz->mlen[pos] = l;
                lz->mpos[pos] = mp;
            }
        }
    }
    // Fixup size again
    if (last_literal)
        lz->size++;
}

// Returns 1 if the coded stream would end in a match
static int lzop_last_is_match(const struct lzop* lz)
{
    int last = 0;
    for (int pos = 0; pos < lz->size; )
    {
        int mlen = lz->mlen[pos];
        if (mlen < min_mlen)
        {
            // Skip over one literal byte
            last = 0;
            pos++;
        }
        else
        {
            // Skip over one match
            pos = pos + mlen;
            last = 1;
        }
    }
    return last;
}

static int lzop_encode(struct bf* b, const struct lzop* lz, int pos, int lpos)
{
    if (pos <= lpos)
        return lpos;

    int mlen = lz->mlen[pos];
    int mpos = lz->mpos[pos];

    // Encode best from filled table
    if (mlen < min_mlen)
    {
        // No match, just encode the byte
//        fprintf(stderr,"L: %02x\n", lz->data[pos]);
        add_bit(b, 1);
        add_byte(b, lz->data[pos]);
        stat_len[0]++;
        return pos;
    }
    else
    {
        int code_pos = (pos - mpos - (fmt_pos_start_zero ? 1 : 2)) & (max_off - 1);
        int code_len = mlen - min_mlen;
        //        fprintf(stderr,"M: %02x : %02x  [%04x]\n", code_pos, code_len,
        //                       (code_pos << bits_mlen) + code_len);
        add_bit(b, 0);
        if (bits_mlen + bits_moff <= 8)
            add_byte(b, (code_pos << bits_mlen) + code_len);
        else if (bits_mlen + bits_moff <= 12)
        {
            add_byte(b, (code_pos << (8 - bits_moff)) + (code_len & ((1 << (8 - bits_moff)) - 1)));
            add_hbyte(b, code_len >> (8 - bits_moff));
        }
        else
        {
            int mb = ((code_len + 1) << bits_moff) + code_pos;
            add_byte(b, mb & 0xFF);
            add_byte(b, mb >> 8);
        }

        stat_len[mlen]++;
        stat_off[mpos]++;
        return pos + mlen - 1;
    }
}


///////////////////////////////////////////////////////
static const char* prog_name;
static void cmd_error(const char* msg)
{
    fprintf(stderr, "%s: error, %s\n"
        "Try '%s -h' for help.\n", prog_name, msg, prog_name);
    exit(1);
}

///////////////////////////////////////////////////////
int main(int argc, char** argv)
{
    struct bf b;
    uint8_t buf[9], * data[9];
    char header_line[128];
    int lpos[9];
    int do_trim = 0;
    int show_stats = 1;
    int bits_mtotal = bits_moff + bits_mlen;
    int bits_set = 0;
    int force_last_literal = 1;
    int format_version = 0;  // LZSS format version - 0 means last version

    prog_name = argv[0];
    int opt;
    while (-1 != (opt = getopt(argc, argv, "hqvo:l:m:b:826ext")))
    {
        switch (opt)
        {
        case '2':
            bits_moff = 7;
            bits_mlen = 5;
            bits_mtotal = 12;
            bits_set |= 8;
            break;
        case '8':
            bits_moff = 4;
            bits_mlen = 4;
            bits_mtotal = 8;
            bits_set |= 8;
            break;
        case '6':
            bits_moff = 8;
            bits_mlen = 8;
            bits_mtotal = 16;
            min_mlen = 1;
            bits_set |= 8;
            break;
        case 'o':
            bits_moff = atoi(optarg);
            bits_set |= 1;
            break;
        case 'l':
            bits_mlen = atoi(optarg);
            bits_set |= 2;
            break;
        case 'b':
            bits_mtotal = atoi(optarg);
            bits_set |= 4;
            break;
        case 'm':
            min_mlen = atoi(optarg);
            break;
        case 'v':
            show_stats = 2;
            break;
        case 'q':
            show_stats = 0;
            break;
        case 'e':
            force_last_literal = 0;
            break;
        case 'x':
            format_version = 1;
            break;
        case 'h':
        default:
            fprintf(stderr,
                "LZSS SN76489 Raw Register Compressor - by Negative Charge.\n"
                "\n"
                "Usage: %s [options] <input_file> <output_file>\n"
                "\n"
                "If output_file is omitted, write to standard output, and if\n"
                "input_file is also omitted, read from standard input.\n"
                "\n"
                "Options:\n"
                "  -8       Sets default 8 bit match size.\n"
                "  -2       Sets default 12 bit match size.\n"
                "  -6       Sets default 16 bit match size.\n"
                "  -o BITS  Sets match offset bits (default = %d).\n"
                "  -l BITS  Sets match length bits (default = %d).\n"
                "  -b BITS  Sets match total bits (=offset+length) (default = %d).\n"
                "  -m NUM   Sets minimum match length (default = %d).\n"
                "  -e       Don't force a literal at end of stream.\n"
                "  -x       Old format with initial data only for skipped channels.\n"
                "  -v       Shows match length/offset statistics.\n"
                "  -q       Don't show per stream compression.\n"
                "  -h       Shows this help.\n",
                prog_name, bits_moff, bits_mlen, bits_mtotal, min_mlen);
            exit(EXIT_FAILURE);
        }
    }

    // Set format flags:
    switch (format_version)
    {
    case 1:
        fmt_literal_first = 0;
        fmt_pos_start_zero = 1;
        break;
    default:
        fmt_literal_first = 1;
        fmt_pos_start_zero = 0;
        break;
    }

    if (bits_mtotal < 8 || bits_mtotal > 16)
        cmd_error("total match bits should be from 8 to 16");

    // Calculate bits
    switch (bits_set)
    {
    case 0:
    case 1:
    case 4:
    case 5:
        bits_mlen = bits_mtotal - bits_moff;
        break;
    case 2:
    case 6:
        bits_moff = bits_mtotal - bits_mlen;
        break;
    case 3:
    case 8:
        // OK
        break;
    default:
        cmd_error("only two of OFFSET, LENGTH and TOTAL bits should be given");
        break;
    }
    // Check option values
    if (bits_moff < 0 || bits_moff > 12)
        cmd_error("match offset bits should be from 0 to 12");
    if (bits_mlen < 2 || bits_moff > 16)
        cmd_error("match length bits should be from 2 to 16");
    if (min_mlen < 1 || min_mlen > 16)
        cmd_error("minimum match length should be from 1 to 16");

    if (optind < argc - 2)
        cmd_error("too many arguments: one input file and one output file expected");
    FILE* input_file = stdin;
    if (optind < argc)
    {
        input_file = fopen(argv[optind], "rb");
        if (!input_file)
        {
            fprintf(stderr, "%s: can't open input file '%s': %s\n",
                prog_name, argv[optind], strerror(errno));
            exit(EXIT_FAILURE);
        }
    }
    // Set stdin and stdout as binary files
    set_binary();

    // Alloc statistic arrays
    stat_len = (int*)calloc(sizeof(int), max_mlen + 1);
    stat_off = (int*)calloc(sizeof(int), max_off + 1);

    // Max size of each bufer: 128k
    for (int i = 0; i < 9; i++)
    {
        data[i] = (uint8_t*)malloc(128 * 1024); // calloc(128,1024);
        lpos[i] = -1;
    }

    
    // Read all data
    int sz;
    for (sz = 0; 1 == fread(buf, 9, 1, input_file) && sz < (128 * 1024); sz++)
    {
        for (int i = 0; i < 9; i++)
        {
            data[i][sz] = buf[i];
        }

        // Temporary hack: converter currently only supports 9 streams, so drop noise channel & volume
        fseek(input_file, 2, SEEK_CUR);
    }
    // Close file
    if (input_file != stdin)
        fclose(input_file);

    // Open output file if needed
    FILE* output_file = stdout;
    if (optind < argc - 1)
    {
        output_file = fopen(argv[optind + 1], "wb");
        if (!output_file)
        {
            fprintf(stderr, "%s: can't open output file '%s': %s\n",
                prog_name, argv[optind + 1], strerror(errno));
            exit(EXIT_FAILURE);
        }
    }
    b.out = output_file;
    // Check for empty streams and warn
    int chn_skip[9];;
    init(&b);
    for (int i = 8; i >= 0; i--)
    {
        const uint8_t* p = data[i], s = *p;
        int n = 0;
        for (int j = 0; j < sz; j++)
            if (*p++ != s)
                n++;
        if (i != 0 && !n)
        {
            if (show_stats)
                fprintf(stderr, "Skipping channel #%d, set with $%02x.\n", i, s);
            add_bit(&b, 1);
            chn_skip[i] = 1;
        }
        else
        {
            if (i)
                add_bit(&b, 0);
            chn_skip[i] = 0;
            if (!n)
            {
                fprintf(stderr, "WARNING: stream #%d ", i);
                if (s == 0)
                    fprintf(stderr, "is empty");
                else
                    fprintf(stderr, "contains only $%02X", s);
                fprintf(stderr, ", should not be included in output!\n");
            }
        }
    }
    bflush(&b);
    // Now, we store initial values for all chanels:
    for (int i = 8; i >= 0; i--)
    {
        // In version 1 we only store init byte for the skipped channels
        if (fmt_literal_first || chn_skip[i])
            add_byte(&b, *data[i]);
    }
    bflush(&b);

    // Init LZ states
    struct lzop lz[9];
    for (int i = 0; i < 9; i++)
        if (!chn_skip[i])
        {
            lzop_init(&lz[i], data[i], sz);
            lzop_backfill(&lz[i], 0);
        }

    // Detect if at least one of the streams end in a match:
    int end_not_ok = 1;
    for (int i = 0; i < 9; i++)
        if (!chn_skip[i])
            end_not_ok &= lzop_last_is_match(&lz[i]);

    // If all streams end in a match, we need to fix at least one to end in
    // a literal - just fix stream 0, as this is always encoded:
    if (force_last_literal && end_not_ok)
    {
        fprintf(stderr, "LZSS: fixing up stream #0 to end in a literal\n");
        lzop_backfill(&lz[0], 1);
    }
    else if (end_not_ok)
    {
        fprintf(stderr, "WARNING: stream does not end in a literal.\n");
        fprintf(stderr, "WARNING: this can produce errors at the end of decoding.\n");
    }

    // Compress
    for (int pos = fmt_literal_first ? 1 : 0; pos < sz; pos++)
        for (int i = 8; i >= 0; i--)
            if (!chn_skip[i])
                lpos[i] = lzop_encode(&b, &lz[i], pos, lpos[i]);
    bflush(&b);
    // Close file
    if (output_file != stdout)
        fclose(output_file);
    else
        fflush(stdout);

    // Show stats
    fprintf(stderr, "LZSS: max offset= %d,\tmax len= %d,\tmatch bits= %d,\t",
        max_off, max_mlen, bits_match - 1);
    fprintf(stderr, "ratio: %5d / %d = %5.2f%%\n", b.total, 9 * sz, (100.0 * b.total) / (9.0 * sz));
    if (show_stats)
        for (int i = 0; i < 9; i++)
            if (!chn_skip[i])
                fprintf(stderr, " Stream #%d: %d bits,\t%5.2f%%,\t%5.2f%% of output\n", i,
                    lz[i].bits[0], (100.0 * lz[i].bits[0]) / (8.0 * sz),
                    (100.0 * lz[i].bits[0]) / (8.0 * b.total));

    if (show_stats > 1)
    {
        fprintf(stderr, "\nvalue\t  POS\t  LEN\n");
        for (int i = 0; i <= maximum(max_mlen, max_off); i++)
        {
            fprintf(stderr, "%2d\t%5d\t%5d\n", i,
                (i <= max_off) ? stat_off[i] : 0,
                (i <= max_mlen) ? stat_len[i] : 0);
        }
    }

    // Free memory
    for (int i = 0; i < 9; i++)
    {
        free(data[i]);
        if (!chn_skip[i])
            lzop_free(&lz[i]);
    }
    free(stat_len);
    free(stat_off);
    return 0;
}
