// Copyright (c) 2020, 2021, Peter Ohler, All rights reserved.

#include "parser.h"

#include <fcntl.h>

#include "oj.h"

#define DEBUG 0

#define USE_THREAD_LIMIT 0
// #define USE_THREAD_LIMIT 100000
#define MAX_EXP 4932
// max in the pow_map which is the limit for double
#define MAX_POW 308

#define MIN_SLEEP (1000000000LL / (double)CLOCKS_PER_SEC)
// 9,223,372,036,854,775,807
#define BIG_LIMIT LLONG_MAX / 10
#define FRAC_LIMIT 10000000000000000ULL

// Give better performance with indented JSON but worse with unindented.
// #define SPACE_JUMP

enum {
    SKIP_CHAR        = 'a',
    SKIP_NEWLINE     = 'b',
    VAL_NULL         = 'c',
    VAL_TRUE         = 'd',
    VAL_FALSE        = 'e',
    VAL_NEG          = 'f',
    VAL0             = 'g',
    VAL_DIGIT        = 'h',
    VAL_QUOTE        = 'i',
    OPEN_ARRAY       = 'k',
    OPEN_OBJECT      = 'l',
    CLOSE_ARRAY      = 'm',
    CLOSE_OBJECT     = 'n',
    AFTER_COMMA      = 'o',
    KEY_QUOTE        = 'p',
    COLON_COLON      = 'q',
    NUM_SPC          = 'r',
    NUM_NEWLINE      = 's',
    NUM_DOT          = 't',
    NUM_COMMA        = 'u',
    NUM_FRAC         = 'v',
    FRAC_E           = 'w',
    EXP_SIGN         = 'x',
    EXP_DIGIT        = 'y',
    STR_QUOTE        = 'z',
    NEG_DIGIT        = '-',
    STR_SLASH        = 'A',
    ESC_OK           = 'B',
    BIG_DIGIT        = 'C',
    BIG_DOT          = 'D',
    U_OK             = 'E',
    TOKEN_OK         = 'F',
    NUM_CLOSE_OBJECT = 'G',
    NUM_CLOSE_ARRAY  = 'H',
    BIG_FRAC         = 'I',
    BIG_E            = 'J',
    BIG_EXP_SIGN     = 'K',
    BIG_EXP          = 'L',
    UTF1             = 'M',  // expect 1 more follow byte
    NUM_DIGIT        = 'N',
    NUM_ZERO         = 'O',
    UTF2             = 'P',  // expect 2 more follow byte
    UTF3             = 'Q',  // expect 3 more follow byte
    STR_OK           = 'R',
    UTFX             = 'S',  // following bytes
    ESC_U            = 'U',
    CHAR_ERR         = '.',
    DONE             = 'X',
};

/*
0123456789abcdef0123456789abcdef */
static const char value_map[257] = "\
X........ab..a..................\
a.i..........f..ghhhhhhhhh......\
...........................k.m..\
......e.......c.....d......l.n..\
................................\
................................\
................................\
................................v";

static const char null_map[257] = "\
................................\
............o...................\
................................\
............F........F..........\
................................\
................................\
................................\
................................N";

static const char true_map[257] = "\
................................\
............o...................\
................................\
.....F............F..F..........\
................................\
................................\
................................\
................................T";

static const char false_map[257] = "\
................................\
............o...................\
................................\
.F...F......F......F............\
................................\
................................\
................................\
................................F";

static const char comma_map[257] = "\
.........ab..a..................\
a.i..........f..ghhhhhhhhh......\
...........................k....\
......e.......c.....d......l....\
................................\
................................\
................................\
................................,";

static const char after_map[257] = "\
X........ab..a..................\
a...........o...................\
.............................m..\
.............................n..\
................................\
................................\
................................\
................................a";

static const char key1_map[257] = "\
.........ab..a..................\
a.p.............................\
................................\
.............................n..\
................................\
................................\
................................\
................................K";

static const char key_map[257] = "\
.........ab..a..................\
a.p.............................\
................................\
................................\
................................\
................................\
................................\
................................k";

static const char colon_map[257] = "\
.........ab..a..................\
a.........................q.....\
................................\
................................\
................................\
................................\
................................\
................................:";

static const char neg_map[257] = "\
................................\
................O---------......\
................................\
................................\
................................\
................................\
................................\
................................-";

static const char zero_map[257] = "\
.........rs..r..................\
r...........u.t.................\
.............................H..\
.............................G..\
................................\
................................\
................................\
................................0";

static const char digit_map[257] = "\
.........rs..r..................\
r...........u.t.NNNNNNNNNN......\
.....w.......................H..\
.....w.......................G..\
................................\
................................\
................................\
................................d";

static const char dot_map[257] = "\
................................\
................vvvvvvvvvv......\
................................\
................................\
................................\
................................\
................................\
.................................";

static const char frac_map[257] = "\
.........rs..r..................\
r...........u...vvvvvvvvvv......\
.....w.......................H..\
.....w.......................G..\
................................\
................................\
................................\
................................f";

static const char exp_sign_map[257] = "\
................................\
...........x.x..yyyyyyyyyy......\
................................\
................................\
................................\
................................\
................................\
................................x";

static const char exp_zero_map[257] = "\
................................\
................yyyyyyyyyy......\
................................\
................................\
................................\
................................\
................................\
................................z";

static const char exp_map[257] = "\
.........rs..r..................\
r...........u...yyyyyyyyyy......\
.............................H..\
.............................G..\
................................\
................................\
................................\
................................X";

static const char big_digit_map[257] = "\
.........rs..r..................\
r...........u.D.CCCCCCCCCC......\
.....J.......................H..\
.....J.......................G..\
................................\
................................\
................................\
................................D";

static const char big_dot_map[257] = "\
................................\
................IIIIIIIIII......\
................................\
................................\
................................\
................................\
................................\
................................o";

static const char big_frac_map[257] = "\
.........rs..r..................\
r...........u...IIIIIIIIII......\
.....J.......................H..\
.....J.......................G..\
................................\
................................\
................................\
................................g";

static const char big_exp_sign_map[257] = "\
................................\
...........K.K..LLLLLLLLLL......\
................................\
................................\
................................\
................................\
................................\
................................B";

static const char big_exp_zero_map[257] = "\
................................\
................LLLLLLLLLL......\
................................\
................................\
................................\
................................\
................................\
................................Z";

static const char big_exp_map[257] = "\
.........rs..r..................\
r...........u...LLLLLLLLLL......\
.............................H..\
.............................G..\
................................\
................................\
................................\
................................Y";

static const char string_map[257] = "\
................................\
RRzRRRRRRRRRRRRRRRRRRRRRRRRRRRRR\
RRRRRRRRRRRRRRRRRRRRRRRRRRRRARRR\
RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR\
................................\
................................\
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\
PPPPPPPPPPPPPPPPQQQQQQQQ........s";

static const char esc_map[257] = "\
................................\
..B............B................\
............................B...\
..B...B.......B...B.BU..........\
................................\
................................\
................................\
................................~";

static const char esc_byte_map[257] = "\
................................\
..\"............/................\
............................\\...\
..\b...\f.......\n...\r.\t..........\
................................\
................................\
................................\
................................b";

static const char u_map[257] = "\
................................\
................EEEEEEEEEE......\
.EEEEEE.........................\
.EEEEEE.........................\
................................\
................................\
................................\
................................u";

static const char utf_map[257] = "\
................................\
................................\
................................\
................................\
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS\
SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS\
................................\
................................8";

static const char space_map[257] = "\
.........ab..a..................\
a...............................\
................................\
................................\
................................\
................................\
................................\
................................S";

static const char trail_map[257] = "\
.........ab..a..................\
a...............................\
................................\
................................\
................................\
................................\
................................\
................................R";

static const byte hex_map[256] = "\
................................\
................\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09......\
.\x0a\x0b\x0c\x0d\x0e\x0f.........................\
.\x0a\x0b\x0c\x0d\x0e\x0f.........................\
................................\
................................\
................................\
................................";

static long double pow_map[309] = {
    1.0L,     1.0e1L,   1.0e2L,   1.0e3L,   1.0e4L,   1.0e5L,   1.0e6L,   1.0e7L,   1.0e8L,   1.0e9L,   1.0e10L,
    1.0e11L,  1.0e12L,  1.0e13L,  1.0e14L,  1.0e15L,  1.0e16L,  1.0e17L,  1.0e18L,  1.0e19L,  1.0e20L,  1.0e21L,
    1.0e22L,  1.0e23L,  1.0e24L,  1.0e25L,  1.0e26L,  1.0e27L,  1.0e28L,  1.0e29L,  1.0e30L,  1.0e31L,  1.0e32L,
    1.0e33L,  1.0e34L,  1.0e35L,  1.0e36L,  1.0e37L,  1.0e38L,  1.0e39L,  1.0e40L,  1.0e41L,  1.0e42L,  1.0e43L,
    1.0e44L,  1.0e45L,  1.0e46L,  1.0e47L,  1.0e48L,  1.0e49L,  1.0e50L,  1.0e51L,  1.0e52L,  1.0e53L,  1.0e54L,
    1.0e55L,  1.0e56L,  1.0e57L,  1.0e58L,  1.0e59L,  1.0e60L,  1.0e61L,  1.0e62L,  1.0e63L,  1.0e64L,  1.0e65L,
    1.0e66L,  1.0e67L,  1.0e68L,  1.0e69L,  1.0e70L,  1.0e71L,  1.0e72L,  1.0e73L,  1.0e74L,  1.0e75L,  1.0e76L,
    1.0e77L,  1.0e78L,  1.0e79L,  1.0e80L,  1.0e81L,  1.0e82L,  1.0e83L,  1.0e84L,  1.0e85L,  1.0e86L,  1.0e87L,
    1.0e88L,  1.0e89L,  1.0e90L,  1.0e91L,  1.0e92L,  1.0e93L,  1.0e94L,  1.0e95L,  1.0e96L,  1.0e97L,  1.0e98L,
    1.0e99L,  1.0e100L, 1.0e101L, 1.0e102L, 1.0e103L, 1.0e104L, 1.0e105L, 1.0e106L, 1.0e107L, 1.0e108L, 1.0e109L,
    1.0e110L, 1.0e111L, 1.0e112L, 1.0e113L, 1.0e114L, 1.0e115L, 1.0e116L, 1.0e117L, 1.0e118L, 1.0e119L, 1.0e120L,
    1.0e121L, 1.0e122L, 1.0e123L, 1.0e124L, 1.0e125L, 1.0e126L, 1.0e127L, 1.0e128L, 1.0e129L, 1.0e130L, 1.0e131L,
    1.0e132L, 1.0e133L, 1.0e134L, 1.0e135L, 1.0e136L, 1.0e137L, 1.0e138L, 1.0e139L, 1.0e140L, 1.0e141L, 1.0e142L,
    1.0e143L, 1.0e144L, 1.0e145L, 1.0e146L, 1.0e147L, 1.0e148L, 1.0e149L, 1.0e150L, 1.0e151L, 1.0e152L, 1.0e153L,
    1.0e154L, 1.0e155L, 1.0e156L, 1.0e157L, 1.0e158L, 1.0e159L, 1.0e160L, 1.0e161L, 1.0e162L, 1.0e163L, 1.0e164L,
    1.0e165L, 1.0e166L, 1.0e167L, 1.0e168L, 1.0e169L, 1.0e170L, 1.0e171L, 1.0e172L, 1.0e173L, 1.0e174L, 1.0e175L,
    1.0e176L, 1.0e177L, 1.0e178L, 1.0e179L, 1.0e180L, 1.0e181L, 1.0e182L, 1.0e183L, 1.0e184L, 1.0e185L, 1.0e186L,
    1.0e187L, 1.0e188L, 1.0e189L, 1.0e190L, 1.0e191L, 1.0e192L, 1.0e193L, 1.0e194L, 1.0e195L, 1.0e196L, 1.0e197L,
    1.0e198L, 1.0e199L, 1.0e200L, 1.0e201L, 1.0e202L, 1.0e203L, 1.0e204L, 1.0e205L, 1.0e206L, 1.0e207L, 1.0e208L,
    1.0e209L, 1.0e210L, 1.0e211L, 1.0e212L, 1.0e213L, 1.0e214L, 1.0e215L, 1.0e216L, 1.0e217L, 1.0e218L, 1.0e219L,
    1.0e220L, 1.0e221L, 1.0e222L, 1.0e223L, 1.0e224L, 1.0e225L, 1.0e226L, 1.0e227L, 1.0e228L, 1.0e229L, 1.0e230L,
    1.0e231L, 1.0e232L, 1.0e233L, 1.0e234L, 1.0e235L, 1.0e236L, 1.0e237L, 1.0e238L, 1.0e239L, 1.0e240L, 1.0e241L,
    1.0e242L, 1.0e243L, 1.0e244L, 1.0e245L, 1.0e246L, 1.0e247L, 1.0e248L, 1.0e249L, 1.0e250L, 1.0e251L, 1.0e252L,
    1.0e253L, 1.0e254L, 1.0e255L, 1.0e256L, 1.0e257L, 1.0e258L, 1.0e259L, 1.0e260L, 1.0e261L, 1.0e262L, 1.0e263L,
    1.0e264L, 1.0e265L, 1.0e266L, 1.0e267L, 1.0e268L, 1.0e269L, 1.0e270L, 1.0e271L, 1.0e272L, 1.0e273L, 1.0e274L,
    1.0e275L, 1.0e276L, 1.0e277L, 1.0e278L, 1.0e279L, 1.0e280L, 1.0e281L, 1.0e282L, 1.0e283L, 1.0e284L, 1.0e285L,
    1.0e286L, 1.0e287L, 1.0e288L, 1.0e289L, 1.0e290L, 1.0e291L, 1.0e292L, 1.0e293L, 1.0e294L, 1.0e295L, 1.0e296L,
    1.0e297L, 1.0e298L, 1.0e299L, 1.0e300L, 1.0e301L, 1.0e302L, 1.0e303L, 1.0e304L, 1.0e305L, 1.0e306L, 1.0e307L,
    1.0e308L};

static VALUE parser_class;

// Works with extended unicode as well. \Uffffffff if support is desired in
// the future.
static size_t unicodeToUtf8(uint32_t code, byte *buf) {
    byte *start = buf;

    if (0x0000007F >= code) {
        *buf++ = (byte)code;
    } else if (0x000007FF >= code) {
        *buf++ = 0xC0 | (code >> 6);
        *buf++ = 0x80 | (0x3F & code);
    } else if (0x0000FFFF >= code) {
        *buf++ = 0xE0 | (code >> 12);
        *buf++ = 0x80 | ((code >> 6) & 0x3F);
        *buf++ = 0x80 | (0x3F & code);
    } else if (0x001FFFFF >= code) {
        *buf++ = 0xF0 | (code >> 18);
        *buf++ = 0x80 | ((code >> 12) & 0x3F);
        *buf++ = 0x80 | ((code >> 6) & 0x3F);
        *buf++ = 0x80 | (0x3F & code);
    } else if (0x03FFFFFF >= code) {
        *buf++ = 0xF8 | (code >> 24);
        *buf++ = 0x80 | ((code >> 18) & 0x3F);
        *buf++ = 0x80 | ((code >> 12) & 0x3F);
        *buf++ = 0x80 | ((code >> 6) & 0x3F);
        *buf++ = 0x80 | (0x3F & code);
    } else if (0x7FFFFFFF >= code) {
        *buf++ = 0xFC | (code >> 30);
        *buf++ = 0x80 | ((code >> 24) & 0x3F);
        *buf++ = 0x80 | ((code >> 18) & 0x3F);
        *buf++ = 0x80 | ((code >> 12) & 0x3F);
        *buf++ = 0x80 | ((code >> 6) & 0x3F);
        *buf++ = 0x80 | (0x3F & code);
    }
    return buf - start;
}

static void parser_reset(ojParser p) {
    p->reader = 0;
    memset(&p->num, 0, sizeof(p->num));
    buf_reset(&p->key);
    buf_reset(&p->buf);
    p->map      = value_map;
    p->next_map = NULL;
    p->depth    = 0;
}

static void parse_error(ojParser p, const char *fmt, ...) {
    va_list ap;
    char    buf[256];

    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    rb_raise(oj_json_parser_error_class, "%s at %ld:%ld", buf, p->line, p->col);
}

static void byte_error(ojParser p, byte b) {
    switch (p->map[256]) {
    case 'N':  // null_map
        parse_error(p, "expected null");
        break;
    case 'T':  // true_map
        parse_error(p, "expected true");
        break;
    case 'F':  // false_map
        parse_error(p, "expected false");
        break;
    case 's':  // string_map
        parse_error(p, "invalid JSON character 0x%02x", b);
        break;
    default: parse_error(p, "unexpected character '%c' in '%c' mode", b, p->map[256]); break;
    }
}

static void calc_num(ojParser p) {
    switch (p->type) {
    case OJ_INT:
        if (p->num.neg) {
            p->num.fixnum = -p->num.fixnum;
            p->num.neg    = false;
        }
        p->funcs[p->stack[p->depth]].add_int(p);
        break;
    case OJ_DECIMAL: {
        long double d = (long double)p->num.fixnum;

        if (p->num.neg) {
            d = -d;
        }
        if (0 < p->num.shift) {
            d /= pow_map[p->num.shift];
        }
        if (0 < p->num.exp) {
            long double x;

            if (MAX_POW < p->num.exp) {
                x = powl(10.0L, (long double)p->num.exp);
            } else {
                x = pow_map[p->num.exp];
            }
            if (p->num.exp_neg) {
                d /= x;
            } else {
                d *= x;
            }
        }
        p->num.dub = d;
        p->funcs[p->stack[p->depth]].add_float(p);
        break;
    }
    case OJ_BIG: p->funcs[p->stack[p->depth]].add_big(p);
    default:
        // nothing to do
        break;
    }
    p->type = OJ_NONE;
}

static void big_change(ojParser p) {
    char    buf[32];
    int64_t i   = p->num.fixnum;
    int     len = 0;

    buf[sizeof(buf) - 1] = '\0';
    p->buf.tail          = p->buf.head;
    switch (p->type) {
    case OJ_INT:
        // If an int then it will fit in the num.raw so no need to check length;
        for (len = sizeof(buf) - 1; 0 < i; len--, i /= 10) {
            buf[len] = '0' + (i % 10);
        }
        if (p->num.neg) {
            buf[len] = '-';
            len--;
        }
        buf_append_string(&p->buf, buf + len + 1, sizeof(buf) - len - 1);
        p->type = OJ_BIG;
        break;
    case OJ_DECIMAL: {
        int shift = p->num.shift;

        for (len = sizeof(buf) - 1; 0 < i; len--, i /= 10, shift--) {
            if (0 == shift) {
                buf[len] = '.';
                len--;
            }
            buf[len] = '0' + (i % 10);
        }
        if (p->num.neg) {
            buf[len] = '-';
            len--;
        }
        buf_append_string(&p->buf, buf + len + 1, sizeof(buf) - len - 1);
        if (0 < p->num.exp) {
            int  x = p->num.exp;
            int  d, div;
            bool started = false;

            buf_append(&p->buf, 'e');
            if (0 < p->num.exp_neg) {
                buf_append(&p->buf, '-');
            }
            for (div = 1000; 0 < div; div /= 10) {
                d = x / div % 10;
                if (started || 0 < d) {
                    buf_append(&p->buf, '0' + d);
                }
            }
        }
        p->type = OJ_BIG;
        break;
    }
    default: break;
    }
}

static void parse(ojParser p, const byte *json) {
    const byte *start;
    const byte *b = json;
    int         i;

    p->line = 1;
    p->col  = -1;
#if DEBUG
    printf("*** parse - mode: %c %s\n", p->map[256], (const char *)json);
#endif
    for (; '\0' != *b; b++) {
#if DEBUG
        printf("*** parse - mode: %c %02x %s => %c\n", p->map[256], *b, b, p->map[*b]);
#endif
        switch (p->map[*b]) {
        case SKIP_NEWLINE:
            p->line++;
            p->col = b - json;
            b++;
#ifdef SPACE_JUMP
            // for (uint32_t *sj = (uint32_t*)b; 0x20202020 == *sj; sj++) { b += 4; }
            for (uint16_t *sj = (uint16_t *)b; 0x2020 == *sj; sj++) {
                b += 2;
            }
#endif
            for (; SKIP_CHAR == space_map[*b]; b++) {
            }
            b--;
            break;
        case COLON_COLON: p->map = value_map; break;
        case SKIP_CHAR: break;
        case KEY_QUOTE:
            b++;
            p->key.tail = p->key.head;
            start       = b;
            for (; STR_OK == string_map[*b]; b++) {
            }
            buf_append_string(&p->key, (const char *)start, b - start);
            if ('"' == *b) {
                p->map = colon_map;
                break;
            }
            b--;
            p->map      = string_map;
            p->next_map = colon_map;
            break;
        case AFTER_COMMA:
            if (0 < p->depth && OBJECT_FUN == p->stack[p->depth]) {
                p->map = key_map;
            } else {
                p->map = comma_map;
            }
            break;
        case VAL_QUOTE:
            b++;
            start       = b;
            p->buf.tail = p->buf.head;
            for (; STR_OK == string_map[*b]; b++) {
            }
            buf_append_string(&p->buf, (const char *)start, b - start);
            if ('"' == *b) {
                p->cur = b - json;
                p->funcs[p->stack[p->depth]].add_str(p);
                p->map = (0 == p->depth) ? value_map : after_map;
                break;
            }
            b--;
            p->map      = string_map;
            p->next_map = (0 == p->depth) ? value_map : after_map;
            break;
        case OPEN_OBJECT:
            p->cur = b - json;
            p->funcs[p->stack[p->depth]].open_object(p);
            p->depth++;
            p->stack[p->depth] = OBJECT_FUN;
            p->map             = key1_map;
            break;
        case NUM_CLOSE_OBJECT:
            p->cur = b - json;
            calc_num(p);
            // flow through
        case CLOSE_OBJECT:
            p->map = (1 == p->depth) ? value_map : after_map;
            if (p->depth <= 0 || OBJECT_FUN != p->stack[p->depth]) {
                p->col = b - json - p->col + 1;
                parse_error(p, "unexpected object close");
                return;
            }
            p->depth--;
            p->cur = b - json;
            p->funcs[p->stack[p->depth]].close_object(p);
            break;
        case OPEN_ARRAY:
            p->cur = b - json;
            p->funcs[p->stack[p->depth]].open_array(p);
            p->depth++;
            p->stack[p->depth] = ARRAY_FUN;
            p->map             = value_map;
            break;
        case NUM_CLOSE_ARRAY:
            p->cur = b - json;
            calc_num(p);
            // flow through
        case CLOSE_ARRAY:
            p->map = (1 == p->depth) ? value_map : after_map;
            if (p->depth <= 0 || ARRAY_FUN != p->stack[p->depth]) {
                p->col = b - json - p->col + 1;
                parse_error(p, "unexpected array close");
                return;
            }
            p->depth--;
            p->cur = b - json;
            p->funcs[p->stack[p->depth]].close_array(p);
            break;
        case NUM_COMMA:
            p->cur = b - json;
            calc_num(p);
            if (0 < p->depth && OBJECT_FUN == p->stack[p->depth]) {
                p->map = key_map;
            } else {
                p->map = comma_map;
            }
            break;
        case VAL0:
            p->type        = OJ_INT;
            p->num.fixnum  = 0;
            p->num.neg     = false;
            p->num.shift   = 0;
            p->num.len     = 0;
            p->num.exp     = 0;
            p->num.exp_neg = false;
            p->map         = zero_map;
            break;
        case VAL_NEG:
            p->type        = OJ_INT;
            p->num.fixnum  = 0;
            p->num.neg     = true;
            p->num.shift   = 0;
            p->num.len     = 0;
            p->num.exp     = 0;
            p->num.exp_neg = false;
            p->map         = neg_map;
            break;
            ;
        case VAL_DIGIT:
            p->type        = OJ_INT;
            p->num.fixnum  = 0;
            p->num.neg     = false;
            p->num.shift   = 0;
            p->num.exp     = 0;
            p->num.exp_neg = false;
            p->num.len     = 0;
            p->map         = digit_map;
            for (; NUM_DIGIT == digit_map[*b]; b++) {
                uint64_t x = (uint64_t)p->num.fixnum * 10 + (uint64_t)(*b - '0');

                // Tried just checking for an int less than zero but that
                // fails when optimization is on for some reason with the
                // clang compiler so us a bit mask instead.
                if (x < BIG_LIMIT) {
                    p->num.fixnum = (int64_t)x;
                } else {
                    big_change(p);
                    p->map = big_digit_map;
                    break;
                }
            }
            b--;
            break;
        case NUM_DIGIT:
            for (; NUM_DIGIT == digit_map[*b]; b++) {
                uint64_t x = p->num.fixnum * 10 + (uint64_t)(*b - '0');

                if (x < BIG_LIMIT) {
                    p->num.fixnum = (int64_t)x;
                } else {
                    big_change(p);
                    p->map = big_digit_map;
                    break;
                }
            }
            b--;
            break;
        case NUM_DOT:
            p->type = OJ_DECIMAL;
            p->map  = dot_map;
            break;
        case NUM_FRAC:
            p->map = frac_map;
            for (; NUM_FRAC == frac_map[*b]; b++) {
                uint64_t x = p->num.fixnum * 10 + (uint64_t)(*b - '0');

                if (x < FRAC_LIMIT) {
                    p->num.fixnum = (int64_t)x;
                    p->num.shift++;
                } else {
                    big_change(p);
                    p->map = big_frac_map;
                    break;
                }
            }
            b--;
            break;
        case FRAC_E:
            p->type = OJ_DECIMAL;
            p->map  = exp_sign_map;
            break;
        case NUM_ZERO: p->map = zero_map; break;
        case NEG_DIGIT:
            for (; NUM_DIGIT == digit_map[*b]; b++) {
                uint64_t x = p->num.fixnum * 10 + (uint64_t)(*b - '0');

                if (x < BIG_LIMIT) {
                    p->num.fixnum = (int64_t)x;
                } else {
                    big_change(p);
                    p->map = big_digit_map;
                    break;
                }
            }
            b--;
            p->map = digit_map;
            break;
        case EXP_SIGN:
            p->num.exp_neg = ('-' == *b);
            p->map         = exp_zero_map;
            break;
        case EXP_DIGIT:
            p->map = exp_map;
            for (; NUM_DIGIT == digit_map[*b]; b++) {
                int16_t x = p->num.exp * 10 + (int16_t)(*b - '0');

                if (x <= MAX_EXP) {
                    p->num.exp = x;
                } else {
                    big_change(p);
                    p->map = big_exp_map;
                    break;
                }
            }
            b--;
            break;
        case BIG_DIGIT:
            start = b;
            for (; NUM_DIGIT == digit_map[*b]; b++) {
            }
            buf_append_string(&p->buf, (const char *)start, b - start);
            b--;
            break;
        case BIG_DOT:
            buf_append(&p->buf, '.');
            p->map = big_dot_map;
            break;
        case BIG_FRAC:
            p->map = big_frac_map;
            start  = b;
            for (; NUM_FRAC == frac_map[*b]; b++) {
            }
            buf_append_string(&p->buf, (const char *)start, b - start);
            b--;
            break;
        case BIG_E:
            buf_append(&p->buf, *b);
            p->map = big_exp_sign_map;
            break;
        case BIG_EXP_SIGN:
            buf_append(&p->buf, *b);
            p->map = big_exp_zero_map;
            break;
        case BIG_EXP:
            start = b;
            for (; NUM_DIGIT == digit_map[*b]; b++) {
            }
            buf_append_string(&p->buf, (const char *)start, b - start);
            b--;
            p->map = big_exp_map;
            break;
        case NUM_SPC:
            p->cur = b - json;
            calc_num(p);
            break;
        case NUM_NEWLINE:
            p->cur = b - json;
            calc_num(p);
            b++;
#ifdef SPACE_JUMP
            // for (uint32_t *sj = (uint32_t*)b; 0x20202020 == *sj; sj++) { b += 4; }
            for (uint16_t *sj = (uint16_t *)b; 0x2020 == *sj; sj++) {
                b += 2;
            }
#endif
            for (; SKIP_CHAR == space_map[*b]; b++) {
            }
            b--;
            break;
        case STR_OK:
            start = b;
            for (; STR_OK == string_map[*b]; b++) {
            }
            if (':' == p->next_map[256]) {
                buf_append_string(&p->key, (const char *)start, b - start);
            } else {
                buf_append_string(&p->buf, (const char *)start, b - start);
            }
            if ('"' == *b) {
                p->cur = b - json;
                p->funcs[p->stack[p->depth]].add_str(p);
                p->map = p->next_map;
                break;
            }
            b--;
            break;
        case STR_SLASH: p->map = esc_map; break;
        case STR_QUOTE:
            p->cur = b - json;
            p->funcs[p->stack[p->depth]].add_str(p);
            p->map = p->next_map;
            break;
        case ESC_U:
            p->map   = u_map;
            p->ri    = 0;
            p->ucode = 0;
            break;
        case U_OK:
            p->ri++;
            p->ucode = p->ucode << 4 | (uint32_t)hex_map[*b];
            if (4 <= p->ri) {
                byte   utf8[8];
                size_t ulen = unicodeToUtf8(p->ucode, utf8);

                if (0 < ulen) {
                    if (':' == p->next_map[256]) {
                        buf_append_string(&p->key, (const char *)utf8, ulen);
                    } else {
                        buf_append_string(&p->buf, (const char *)utf8, ulen);
                    }
                } else {
                    parse_error(p, "invalid unicode");
                    return;
                }
                p->map = string_map;
            }
            break;
        case ESC_OK:
            if (':' == p->next_map[256]) {
                buf_append(&p->key, esc_byte_map[*b]);
            } else {
                buf_append(&p->buf, esc_byte_map[*b]);
            }
            p->map = string_map;
            break;
        case UTF1:
            p->ri  = 1;
            p->map = utf_map;
            if (':' == p->next_map[256]) {
                buf_append(&p->key, *b);
            } else {
                buf_append(&p->buf, *b);
            }
            break;
        case UTF2:
            p->ri  = 2;
            p->map = utf_map;
            if (':' == p->next_map[256]) {
                buf_append(&p->key, *b);
            } else {
                buf_append(&p->buf, *b);
            }
            break;
        case UTF3:
            p->ri  = 3;
            p->map = utf_map;
            if (':' == p->next_map[256]) {
                buf_append(&p->key, *b);
            } else {
                buf_append(&p->buf, *b);
            }
            break;
        case UTFX:
            p->ri--;
            if (':' == p->next_map[256]) {
                buf_append(&p->key, *b);
            } else {
                buf_append(&p->buf, *b);
            }
            if (p->ri <= 0) {
                p->map = string_map;
            }
            break;
        case VAL_NULL:
            if ('u' == b[1] && 'l' == b[2] && 'l' == b[3]) {
                b += 3;
                p->cur = b - json;
                p->funcs[p->stack[p->depth]].add_null(p);
                p->map = (0 == p->depth) ? value_map : after_map;
                break;
            }
            p->ri     = 0;
            *p->token = *b++;
            for (i = 1; i < 4; i++) {
                if ('\0' == *b) {
                    p->ri = i;
                    break;
                } else {
                    p->token[i] = *b++;
                }
            }
            if (0 < p->ri) {
                p->map = null_map;
                b--;
                break;
            }
            p->col = b - json - p->col;
            parse_error(p, "expected null");
            return;
        case VAL_TRUE:
            if ('r' == b[1] && 'u' == b[2] && 'e' == b[3]) {
                b += 3;
                p->cur = b - json;
                p->funcs[p->stack[p->depth]].add_true(p);
                p->map = (0 == p->depth) ? value_map : after_map;
                break;
            }
            p->ri     = 0;
            *p->token = *b++;
            for (i = 1; i < 4; i++) {
                if ('\0' == *b) {
                    p->ri = i;
                    break;
                } else {
                    p->token[i] = *b++;
                }
            }
            if (0 < p->ri) {
                p->map = true_map;
                b--;
                break;
            }
            p->col = b - json - p->col;
            parse_error(p, "expected true");
            return;
        case VAL_FALSE:
            if ('a' == b[1] && 'l' == b[2] && 's' == b[3] && 'e' == b[4]) {
                b += 4;
                p->cur = b - json;
                p->funcs[p->stack[p->depth]].add_false(p);
                p->map = (0 == p->depth) ? value_map : after_map;
                break;
            }
            p->ri     = 0;
            *p->token = *b++;
            for (i = 1; i < 5; i++) {
                if ('\0' == *b) {
                    p->ri = i;
                    break;
                } else {
                    p->token[i] = *b++;
                }
            }
            if (0 < p->ri) {
                p->map = false_map;
                b--;
                break;
            }
            p->col = b - json - p->col;
            parse_error(p, "expected false");
            return;
        case TOKEN_OK:
            p->token[p->ri] = *b;
            p->ri++;
            switch (p->map[256]) {
            case 'N':
                if (4 == p->ri) {
                    if (0 != strncmp("null", p->token, 4)) {
                        p->col = b - json - p->col;
                        parse_error(p, "expected null");
                        return;
                    }
                    p->cur = b - json;
                    p->funcs[p->stack[p->depth]].add_null(p);
                    p->map = (0 == p->depth) ? value_map : after_map;
                }
                break;
            case 'F':
                if (5 == p->ri) {
                    if (0 != strncmp("false", p->token, 5)) {
                        p->col = b - json - p->col;
                        parse_error(p, "expected false");
                        return;
                    }
                    p->cur = b - json;
                    p->funcs[p->stack[p->depth]].add_false(p);
                    p->map = (0 == p->depth) ? value_map : after_map;
                }
                break;
            case 'T':
                if (4 == p->ri) {
                    if (0 != strncmp("true", p->token, 4)) {
                        p->col = b - json - p->col;
                        parse_error(p, "expected true");
                        return;
                    }
                    p->cur = b - json;
                    p->funcs[p->stack[p->depth]].add_true(p);
                    p->map = (0 == p->depth) ? value_map : after_map;
                }
                break;
            default:
                p->col = b - json - p->col;
                parse_error(p, "parse error");
                return;
            }
            break;
        case CHAR_ERR: byte_error(p, *b); return;
        default: break;
        }
        if (0 == p->depth && 'v' == p->map[256] && p->just_one) {
            p->map = trail_map;
        }
    }
    if (0 == p->depth) {
        switch (p->map[256]) {
        case '0':
        case 'd':
        case 'f':
        case 'z':
        case 'X':
        case 'D':
        case 'g':
        case 'B':
        case 'Y':
            p->cur = b - json;
            calc_num(p);
            break;
        }
    }
    return;
}

static void parser_free(void *ptr) {
    ojParser p;

    if (0 == ptr) {
        return;
    }
    p = (ojParser)ptr;
    buf_cleanup(&p->key);
    buf_cleanup(&p->buf);
    if (NULL != p->free) {
        p->free(p);
    }
    OJ_R_FREE(ptr);
}

static void parser_mark(void *ptr) {
    if (NULL != ptr) {
        ojParser p = (ojParser)ptr;

        if (0 != p->reader) {
            rb_gc_mark(p->reader);
        }
        if (NULL != p->mark) {
            p->mark(p);
        }
    }
}

const rb_data_type_t oj_parser_type = {
    "Oj/parser",
    {
        parser_mark,
        parser_free,
        NULL,
    },
    0,
    0,
};

extern void oj_set_parser_validator(ojParser p);
extern void oj_set_parser_saj(ojParser p);
extern void oj_set_parser_usual(ojParser p);
extern void oj_set_parser_debug(ojParser p);

static int opt_cb(VALUE rkey, VALUE value, VALUE ptr) {
    ojParser    p   = (ojParser)ptr;
    const char *key = NULL;
    char        set_key[64];
    long        klen;

    switch (rb_type(rkey)) {
    case RUBY_T_SYMBOL:
        rkey = rb_sym2str(rkey);
        // fall through
    case RUBY_T_STRING:
        key  = StringValuePtr(rkey);
        klen = RSTRING_LEN(rkey);
        break;
    default: rb_raise(rb_eArgError, "option keys must be a symbol or string");
    }
    if ((long)sizeof(set_key) - 1 <= klen) {
        return ST_CONTINUE;
    }
    memcpy(set_key, key, klen);
    set_key[klen]     = '=';
    set_key[klen + 1] = '\0';
    p->option(p, set_key, value);

    return ST_CONTINUE;
}

/* Document-method: new
 * call-seq: new(mode=nil)
 *
 * Creates a new Parser with the specified mode. If no mode is provided
 * validation is assumed. Optional arguments can be provided that match the
 * mode. For example with the :usual mode the call might look like
 * Oj::Parser.new(:usual, cache_keys: true).
 */
static VALUE parser_new(int argc, VALUE *argv, VALUE self) {
    ojParser p = OJ_R_ALLOC(struct _ojParser);

#if HAVE_RB_EXT_RACTOR_SAFE
    // This doesn't seem to do anything.
    rb_ext_ractor_safe(true);
#endif
    memset(p, 0, sizeof(struct _ojParser));
    buf_init(&p->key);
    buf_init(&p->buf);
    p->map = value_map;

    if (argc < 1) {
        oj_set_parser_validator(p);
    } else {
        VALUE mode = argv[0];

        if (Qnil == mode) {
            oj_set_parser_validator(p);
        } else {
            const char *ms = NULL;

            switch (rb_type(mode)) {
            case RUBY_T_SYMBOL:
                mode = rb_sym2str(mode);
                // fall through
            case RUBY_T_STRING: ms = RSTRING_PTR(mode); break;
            default: rb_raise(rb_eArgError, "mode must be :validate, :usual, :saj, or :object");
            }
            if (0 == strcmp("usual", ms) || 0 == strcmp("standard", ms) || 0 == strcmp("strict", ms) ||
                0 == strcmp("compat", ms)) {
                oj_set_parser_usual(p);
            } else if (0 == strcmp("object", ms)) {
                // TBD
            } else if (0 == strcmp("saj", ms)) {
                oj_set_parser_saj(p);
            } else if (0 == strcmp("validate", ms)) {
                oj_set_parser_validator(p);
            } else if (0 == strcmp("debug", ms)) {
                oj_set_parser_debug(p);
            } else {
                rb_raise(rb_eArgError, "mode must be :validate, :usual, :saj, or :object");
            }
        }
        if (1 < argc) {
            VALUE ropts = argv[1];

            Check_Type(ropts, T_HASH);
            rb_hash_foreach(ropts, opt_cb, (VALUE)p);
        }
    }
    return TypedData_Wrap_Struct(parser_class, &oj_parser_type, p);
}

// Create a new parser without setting the delegate. The parser is
// wrapped. The parser is (ojParser)DATA_PTR(value) where value is the return
// from this function. A delegate must be added before the parser can be
// used. Optionally oj_parser_set_options can be called if the options are not
// set directly.
VALUE oj_parser_new(void) {
    ojParser p = OJ_R_ALLOC(struct _ojParser);

#if HAVE_RB_EXT_RACTOR_SAFE
    // This doesn't seem to do anything.
    rb_ext_ractor_safe(true);
#endif
    memset(p, 0, sizeof(struct _ojParser));
    buf_init(&p->key);
    buf_init(&p->buf);
    p->map = value_map;

    return TypedData_Wrap_Struct(parser_class, &oj_parser_type, p);
}

// Set set the options from a hash (ropts).
void oj_parser_set_option(ojParser p, VALUE ropts) {
    Check_Type(ropts, T_HASH);
    rb_hash_foreach(ropts, opt_cb, (VALUE)p);
}

/* Document-method: method_missing(value)
 * call-seq: method_missing(value)
 *
 * Methods not handled by the parser are passed to the delegate. The methods
 * supported by delegate are:
 *
 * - *:validate*
 *   - no options
 *
 * - *:saj*
 *   - _cache_keys_ is a flag indicating hash keys should be cached.
 *   - _cache_strings_ is a positive integer less than 35. Strings shorter than that length are cached.
 *   - _handler_ is the SAJ handler
 *
 * - *:usual*
 *   - _cache_keys_ is a flag indicating hash keys should be cached.
 *   - _cache_strings_ is a positive integer less than 35. Strings shorter than that length are cached.
 *   - _cache_expunge_ dictates when the cache will be expunged where 0 never expunges,
 *     1 expunges slowly, 2 expunges faster, and 3 or higher expunges agressively.
 *   - _capacity_ is the capacity of the parser's internal stack. The parser grows automatically
 *     but can be updated directly with this call.
 *   - _create_id_ if non-nil is the key that is used to specify the type of object to create
 *     when parsing. Parsed JSON objects that include the specified element use the element
 *     value as the name of the class to create an object from instead of a Hash.
 *   - _decimal_ is the approach to how decimals are parsed. If _:auto_ then
 *     the decimals with significant digits are 16 or less are Floats and long
 *     ones are BigDecimal. _:ruby_ uses a call to Ruby to convert a string to a Float.
 *     _:float_ always generates a Float. _:bigdecimal_ always results in a BigDecimal.
 *   - _ignore_json_create_ is a flag that when set the class json_create method is
 *     ignored on parsing in favor of creating an instance and populating directly.
 *   - _missing_class_ is an indicator that determines how unknown class names are handled.
 *     Valid values are _:auto_ which creates any missing classes on parse, :ignore which ignores
 *     and continues as a Hash (default), and :raise which raises an exception if the class is not found.
 *   - _omit_null_ is a flag that if true then null values in a map or object are omitted
 *     from the resulting Hash or Object.
 *   - _symbol_keys_ is a flag that indicates Hash keys should be parsed to Symbols versus Strings.
 */
static VALUE parser_missing(int argc, VALUE *argv, VALUE self) {
    ojParser       p;
    const char    *key  = NULL;
    volatile VALUE rkey = *argv;
    volatile VALUE rv   = Qnil;

    TypedData_Get_Struct(self, struct _ojParser, &oj_parser_type, p);

#if HAVE_RB_EXT_RACTOR_SAFE
    // This doesn't seem to do anything.
    rb_ext_ractor_safe(true);
#endif
    switch (rb_type(rkey)) {
    case RUBY_T_SYMBOL:
        rkey = rb_sym2str(rkey);
        // fall through
    case RUBY_T_STRING: key = StringValuePtr(rkey); break;
    default: rb_raise(rb_eArgError, "option method must be a symbol or string");
    }
    if (1 < argc) {
        rv = argv[1];
    }
    return p->option(p, key, rv);
}

/* Document-method: parse(json)
 * call-seq: parse(json)
 *
 * Parse a JSON string.
 *
 * Returns the result according to the delegate of the parser.
 */
static VALUE parser_parse(VALUE self, VALUE json) {
    ojParser    p;
    const byte *ptr = (const byte *)StringValuePtr(json);

    TypedData_Get_Struct(self, struct _ojParser, &oj_parser_type, p);

    parser_reset(p);
    p->start(p);
    parse(p, ptr);

    return p->result(p);
}

static VALUE load_rescue(VALUE self, VALUE x) {
    // Normal EOF. No action needed other than to stop loading.
    return Qfalse;
}

static VALUE load(VALUE self) {
    ojParser       p;
    volatile VALUE rbuf = rb_str_new2("");

    TypedData_Get_Struct(self, struct _ojParser, &oj_parser_type, p);

    p->start(p);
    while (true) {
        rb_funcall(p->reader, oj_readpartial_id, 2, INT2NUM(16385), rbuf);
        if (0 < RSTRING_LEN(rbuf)) {
            parse(p, (byte *)StringValuePtr(rbuf));
        }
        if (Qtrue == rb_funcall(p->reader, oj_eofq_id, 0)) {
            if (0 < p->depth) {
                parse_error(p, "parse error, not closed");
            }
            break;
        }
    }
    return Qtrue;
}

/* Document-method: load(reader)
 * call-seq: load(reader)
 *
 * Parse a JSON stream.
 *
 * Returns the result according to the delegate of the parser.
 */
static VALUE parser_load(VALUE self, VALUE reader) {
    ojParser p;

    TypedData_Get_Struct(self, struct _ojParser, &oj_parser_type, p);

    parser_reset(p);
    p->reader = reader;
    rb_rescue2(load, self, load_rescue, Qnil, rb_eEOFError, 0);

    return p->result(p);
}

/* Document-method: file(filename)
 * call-seq: file(filename)
 *
 * Parse a JSON file.
 *
 * Returns the result according to the delegate of the parser.
 */
static VALUE parser_file(VALUE self, VALUE filename) {
    ojParser    p;
    const char *path;
    int         fd;

    TypedData_Get_Struct(self, struct _ojParser, &oj_parser_type, p);

    path = StringValuePtr(filename);

    parser_reset(p);
    p->start(p);

    if (0 > (fd = open(path, O_RDONLY))) {
        rb_raise(rb_eIOError, "error opening %s", path);
    }
#if USE_THREAD_LIMIT
    struct stat info;
    // st_size will be 0 if not a file
    if (0 == fstat(fd, &info) && USE_THREAD_LIMIT < info.st_size) {
        // Use threaded version.
        // TBD only if has pthreads
        // TBD parse_large(p, fd);
        return p->result(p);
    }
#endif
    byte   buf[16385];
    size_t size = sizeof(buf) - 1;
    size_t rsize;

    while (true) {
        if (0 < (rsize = read(fd, buf, size))) {
            buf[rsize] = '\0';
            parse(p, buf);
        }
        if (rsize <= 0) {
            if (0 != rsize) {
                rb_raise(rb_eIOError, "error reading from %s", path);
            }
            break;
        }
    }
    return p->result(p);
}

/* Document-method: just_one
 * call-seq: just_one
 *
 * Returns the current state of the just_one [_Boolean_] option.
 */
static VALUE parser_just_one(VALUE self) {
    ojParser p;

    TypedData_Get_Struct(self, struct _ojParser, &oj_parser_type, p);

    return p->just_one ? Qtrue : Qfalse;
}

/* Document-method: just_one=
 * call-seq: just_one=(value)
 *
 * Sets the *just_one* option which limits the parsing of a string or or
 * stream to a single JSON element.
 *
 * Returns the current state of the just_one [_Boolean_] option.
 */
static VALUE parser_just_one_set(VALUE self, VALUE v) {
    ojParser p;

    TypedData_Get_Struct(self, struct _ojParser, &oj_parser_type, p);

    p->just_one = (Qtrue == v);

    return p->just_one ? Qtrue : Qfalse;
}

static VALUE usual_parser = Qundef;

/* Document-method: usual
 * call-seq: usual
 *
 * Returns the default usual parser. Note the default usual parser can not be
 * used concurrently in more than one thread.
 */
static VALUE parser_usual(VALUE self) {
    if (Qundef == usual_parser) {
        ojParser p = OJ_R_ALLOC(struct _ojParser);

        memset(p, 0, sizeof(struct _ojParser));
        buf_init(&p->key);
        buf_init(&p->buf);
        p->map = value_map;
        oj_set_parser_usual(p);
        usual_parser = TypedData_Wrap_Struct(parser_class, &oj_parser_type, p);
        rb_gc_register_address(&usual_parser);
    }
    return usual_parser;
}

static VALUE saj_parser = Qundef;

/* Document-method: saj
 * call-seq: saj
 *
 * Returns the default SAJ parser. Note the default SAJ parser can not be used
 * concurrently in more than one thread.
 */
static VALUE parser_saj(VALUE self) {
    if (Qundef == saj_parser) {
        ojParser p = OJ_R_ALLOC(struct _ojParser);

        memset(p, 0, sizeof(struct _ojParser));
        buf_init(&p->key);
        buf_init(&p->buf);
        p->map = value_map;
        oj_set_parser_saj(p);
        saj_parser = TypedData_Wrap_Struct(parser_class, &oj_parser_type, p);
        rb_gc_register_address(&saj_parser);
    }
    return saj_parser;
}

static VALUE validate_parser = Qundef;

/* Document-method: validate
 * call-seq: validate
 *
 * Returns the default validate parser.
 */
static VALUE parser_validate(VALUE self) {
    if (Qundef == validate_parser) {
        ojParser p = OJ_R_ALLOC(struct _ojParser);

        memset(p, 0, sizeof(struct _ojParser));
        buf_init(&p->key);
        buf_init(&p->buf);
        p->map = value_map;
        oj_set_parser_validator(p);
        validate_parser = TypedData_Wrap_Struct(parser_class, &oj_parser_type, p);
        rb_gc_register_address(&validate_parser);
    }
    return validate_parser;
}

/* Document-class: Oj::Parser
 *
 * A reusable parser that makes use of named delegates to determine the
 * handling of parsed data. Delegates are available for validation, a callback
 * parser (SAJ), and a usual delegate that builds Ruby objects as parsing
 * proceeds.
 *
 * This parser is considerably faster than the older Oj.parse call and
 * isolates options to just the parser so that other parts of the code are not
 * forced to use the same options.
 */
void oj_parser_init(void) {
    parser_class = rb_define_class_under(Oj, "Parser", rb_cObject);
    rb_gc_register_address(&parser_class);
    rb_undef_alloc_func(parser_class);

    rb_define_module_function(parser_class, "new", parser_new, -1);
    rb_define_method(parser_class, "parse", parser_parse, 1);
    rb_define_method(parser_class, "load", parser_load, 1);
    rb_define_method(parser_class, "file", parser_file, 1);
    rb_define_method(parser_class, "just_one", parser_just_one, 0);
    rb_define_method(parser_class, "just_one=", parser_just_one_set, 1);
    rb_define_method(parser_class, "method_missing", parser_missing, -1);

    rb_define_module_function(parser_class, "usual", parser_usual, 0);
    rb_define_module_function(parser_class, "saj", parser_saj, 0);
    rb_define_module_function(parser_class, "validate", parser_validate, 0);
}
