// Copyright (c) 2013 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include "parse.h"

#include <math.h>
#include <ruby/util.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "buf.h"
#include "encode.h"
#include "mem.h"
#include "oj.h"
#include "rxclass.h"
#include "val_stack.h"

#ifdef OJ_USE_SSE4_2
#include <nmmintrin.h>
#endif

// Workaround in case INFINITY is not defined in math.h or if the OS is CentOS
#define OJ_INFINITY (1.0 / 0.0)

// #define EXP_MAX		1023
#define EXP_MAX 100000
#define DEC_MAX 15

static void next_non_white(ParseInfo pi) {
    for (; 1; pi->cur++) {
        switch (*pi->cur) {
        case ' ':
        case '\t':
        case '\f':
        case '\n':
        case '\r': break;
        default: return;
        }
    }
}

static void skip_comment(ParseInfo pi) {
    if ('*' == *pi->cur) {
        pi->cur++;
        for (; pi->cur < pi->end; pi->cur++) {
            if ('*' == *pi->cur && '/' == *(pi->cur + 1)) {
                pi->cur += 2;
                return;
            } else if (pi->end <= pi->cur) {
                oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "comment not terminated");
                return;
            }
        }
    } else if ('/' == *pi->cur) {
        for (; 1; pi->cur++) {
            switch (*pi->cur) {
            case '\n':
            case '\r':
            case '\f':
            case '\0': return;
            default: break;
            }
        }
    } else {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "invalid comment format");
    }
}

static void add_value(ParseInfo pi, VALUE rval) {
    Val parent = stack_peek(&pi->stack);

    if (0 == parent) {  // simple add
        pi->add_value(pi, rval);
    } else {
        switch (parent->next) {
        case NEXT_ARRAY_NEW:
        case NEXT_ARRAY_ELEMENT:
            pi->array_append_value(pi, rval);
            parent->next = NEXT_ARRAY_COMMA;
            break;
        case NEXT_HASH_VALUE:
            pi->hash_set_value(pi, parent, rval);
            if (0 != parent->key && 0 < parent->klen && (parent->key < pi->json || pi->cur < parent->key)) {
                OJ_R_FREE((char *)parent->key);
                parent->key = 0;
            }
            parent->next = NEXT_HASH_COMMA;
            break;
        case NEXT_HASH_NEW:
        case NEXT_HASH_KEY:
        case NEXT_HASH_COMMA:
        case NEXT_NONE:
        case NEXT_ARRAY_COMMA:
        case NEXT_HASH_COLON:
        default:
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "expected %s",
                            oj_stack_next_string(parent->next));
            break;
        }
    }
}

static void read_null(ParseInfo pi) {
    if ('u' == *pi->cur++ && 'l' == *pi->cur++ && 'l' == *pi->cur++) {
        add_value(pi, Qnil);
    } else {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "expected null");
    }
}

static void read_true(ParseInfo pi) {
    if ('r' == *pi->cur++ && 'u' == *pi->cur++ && 'e' == *pi->cur++) {
        add_value(pi, Qtrue);
    } else {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "expected true");
    }
}

static void read_false(ParseInfo pi) {
    if ('a' == *pi->cur++ && 'l' == *pi->cur++ && 's' == *pi->cur++ && 'e' == *pi->cur++) {
        add_value(pi, Qfalse);
    } else {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "expected false");
    }
}

static uint32_t read_hex(ParseInfo pi, const char *h) {
    uint32_t b = 0;
    int      i;

    for (i = 0; i < 4; i++, h++) {
        b = b << 4;
        if ('0' <= *h && *h <= '9') {
            b += *h - '0';
        } else if ('A' <= *h && *h <= 'F') {
            b += *h - 'A' + 10;
        } else if ('a' <= *h && *h <= 'f') {
            b += *h - 'a' + 10;
        } else {
            oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "invalid hex character");
            return 0;
        }
    }
    return b;
}

static void unicode_to_chars(ParseInfo pi, Buf buf, uint32_t code) {
    if (0x0000007F >= code) {
        buf_append(buf, (char)code);
    } else if (0x000007FF >= code) {
        buf_append(buf, 0xC0 | (code >> 6));
        buf_append(buf, 0x80 | (0x3F & code));
    } else if (0x0000FFFF >= code) {
        buf_append(buf, 0xE0 | (code >> 12));
        buf_append(buf, 0x80 | ((code >> 6) & 0x3F));
        buf_append(buf, 0x80 | (0x3F & code));
    } else if (0x001FFFFF >= code) {
        buf_append(buf, 0xF0 | (code >> 18));
        buf_append(buf, 0x80 | ((code >> 12) & 0x3F));
        buf_append(buf, 0x80 | ((code >> 6) & 0x3F));
        buf_append(buf, 0x80 | (0x3F & code));
    } else if (0x03FFFFFF >= code) {
        buf_append(buf, 0xF8 | (code >> 24));
        buf_append(buf, 0x80 | ((code >> 18) & 0x3F));
        buf_append(buf, 0x80 | ((code >> 12) & 0x3F));
        buf_append(buf, 0x80 | ((code >> 6) & 0x3F));
        buf_append(buf, 0x80 | (0x3F & code));
    } else if (0x7FFFFFFF >= code) {
        buf_append(buf, 0xFC | (code >> 30));
        buf_append(buf, 0x80 | ((code >> 24) & 0x3F));
        buf_append(buf, 0x80 | ((code >> 18) & 0x3F));
        buf_append(buf, 0x80 | ((code >> 12) & 0x3F));
        buf_append(buf, 0x80 | ((code >> 6) & 0x3F));
        buf_append(buf, 0x80 | (0x3F & code));
    } else {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "invalid Unicode character");
    }
}

static const unsigned char end_of_scan_string[] = {
    // Filled 1 at the positions of '\0', '\\', and '"'
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};
static inline const char *scan_string_noSIMD(const char *str, const char *end) {
    for (; str < end; str++) {
        if (end_of_scan_string[(unsigned char)*str]) {
            break;
        }
    }
    return str;
}

#ifdef OJ_USE_SSE4_2
static inline const char *scan_string_SIMD(const char *str, const char *end) {
    static const char chars[16] = "\x00\\\"";
    const __m128i     terminate = _mm_loadu_si128((const __m128i *)&chars[0]);
    const char       *_end      = (const char *)(end - 16);

    for (; str <= _end; str += 16) {
        const __m128i string = _mm_loadu_si128((const __m128i *)str);
        const int     r      = _mm_cmpestri(terminate,
                                   3,
                                   string,
                                   16,
                                   _SIDD_UBYTE_OPS | _SIDD_CMP_EQUAL_ANY | _SIDD_LEAST_SIGNIFICANT);
        if (r != 16) {
            str = (char *)(str + r);
            return str;
        }
    }

    return scan_string_noSIMD(str, end);
}
#endif

static const char *(*scan_func)(const char *str, const char *end) = scan_string_noSIMD;

void oj_scanner_init(void) {
#ifdef OJ_USE_SSE4_2
    scan_func = scan_string_SIMD;
#endif
}

// entered at /
static void read_escaped_str(ParseInfo pi, const char *start) {
    struct _buf buf;
    const char *s;
    int         cnt = (int)(pi->cur - start);
    uint32_t    code;
    Val         parent = stack_peek(&pi->stack);

    buf_init(&buf);
    buf_append_string(&buf, start, cnt);

    for (s = pi->cur; '"' != *s;) {
        const char *scanned = scan_func(s, pi->end);
        if (scanned >= pi->end || '\0' == *scanned) {
            // if (scanned >= pi->end) {
            oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "quoted string not terminated");
            buf_cleanup(&buf);
            return;
        }
        buf_append_string(&buf, s, (size_t)(scanned - s));
        s = scanned;

        if ('\\' == *s) {
            s++;
            switch (*s) {
            case 'n': buf_append(&buf, '\n'); break;
            case 'r': buf_append(&buf, '\r'); break;
            case 't': buf_append(&buf, '\t'); break;
            case 'f': buf_append(&buf, '\f'); break;
            case 'b': buf_append(&buf, '\b'); break;
            case '"': buf_append(&buf, '"'); break;
            case '/': buf_append(&buf, '/'); break;
            case '\\': buf_append(&buf, '\\'); break;
            case 'u':
                s++;
                if (0 == (code = read_hex(pi, s)) && err_has(&pi->err)) {
                    buf_cleanup(&buf);
                    return;
                }
                s += 3;
                if (0x0000D800 <= code && code <= 0x0000DFFF) {
                    uint32_t c1 = (code - 0x0000D800) & 0x000003FF;
                    uint32_t c2;

                    s++;
                    if ('\\' != *s || 'u' != *(s + 1)) {
                        if (Yes == pi->options.allow_invalid) {
                            s--;
                            unicode_to_chars(pi, &buf, code);
                            break;
                        }
                        pi->cur = s;
                        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "invalid escaped character");
                        buf_cleanup(&buf);
                        return;
                    }
                    s += 2;
                    if (0 == (c2 = read_hex(pi, s)) && err_has(&pi->err)) {
                        buf_cleanup(&buf);
                        return;
                    }
                    s += 3;
                    c2   = (c2 - 0x0000DC00) & 0x000003FF;
                    code = ((c1 << 10) | c2) + 0x00010000;
                }
                unicode_to_chars(pi, &buf, code);
                if (err_has(&pi->err)) {
                    buf_cleanup(&buf);
                    return;
                }
                break;
            default:
                // The json gem claims this is not an error despite the
                // ECMA-404 indicating it is not valid.
                if (CompatMode == pi->options.mode) {
                    buf_append(&buf, *s);
                    break;
                }
                pi->cur = s;
                oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "invalid escaped character");
                buf_cleanup(&buf);
                return;
            }
            s++;
        }
    }
    if (0 == parent) {
        pi->add_cstr(pi, buf.head, buf_len(&buf), start);
    } else {
        switch (parent->next) {
        case NEXT_ARRAY_NEW:
        case NEXT_ARRAY_ELEMENT:
            pi->array_append_cstr(pi, buf.head, buf_len(&buf), start);
            parent->next = NEXT_ARRAY_COMMA;
            break;
        case NEXT_HASH_NEW:
        case NEXT_HASH_KEY:
            if (Qundef == (parent->key_val = pi->hash_key(pi, buf.head, buf_len(&buf)))) {
                parent->klen = buf_len(&buf);
                parent->key  = OJ_MALLOC(parent->klen + 1);
                memcpy((char *)parent->key, buf.head, parent->klen);
                *(char *)(parent->key + parent->klen) = '\0';
            } else {
                parent->key  = "";
                parent->klen = 0;
            }
            parent->k1   = *start;
            parent->next = NEXT_HASH_COLON;
            break;
        case NEXT_HASH_VALUE:
            pi->hash_set_cstr(pi, parent, buf.head, buf_len(&buf), start);
            if (0 != parent->key && 0 < parent->klen && (parent->key < pi->json || pi->cur < parent->key)) {
                OJ_R_FREE((char *)parent->key);
                parent->key = 0;
            }
            parent->next = NEXT_HASH_COMMA;
            break;
        case NEXT_HASH_COMMA:
        case NEXT_NONE:
        case NEXT_ARRAY_COMMA:
        case NEXT_HASH_COLON:
        default:
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "expected %s, not a string",
                            oj_stack_next_string(parent->next));
            break;
        }
    }
    pi->cur = s + 1;
    buf_cleanup(&buf);
}

static void read_str(ParseInfo pi) {
    const char *str    = pi->cur;
    Val         parent = stack_peek(&pi->stack);

    pi->cur = scan_func(pi->cur, pi->end);
    if (RB_UNLIKELY(pi->end <= pi->cur)) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "quoted string not terminated");
        return;
    }
    if (RB_UNLIKELY('\0' == *pi->cur)) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "NULL byte in string");
        return;
    }
    if ('\\' == *pi->cur) {
        read_escaped_str(pi, str);
        return;
    }

    if (0 == parent) {  // simple add
        pi->add_cstr(pi, str, pi->cur - str, str);
    } else {
        switch (parent->next) {
        case NEXT_ARRAY_NEW:
        case NEXT_ARRAY_ELEMENT:
            pi->array_append_cstr(pi, str, pi->cur - str, str);
            parent->next = NEXT_ARRAY_COMMA;
            break;
        case NEXT_HASH_NEW:
        case NEXT_HASH_KEY:
            if (Qundef == (parent->key_val = pi->hash_key(pi, str, pi->cur - str))) {
                parent->key  = str;
                parent->klen = pi->cur - str;
            } else {
                parent->key  = "";
                parent->klen = 0;
            }
            parent->k1   = *str;
            parent->next = NEXT_HASH_COLON;
            break;
        case NEXT_HASH_VALUE:
            pi->hash_set_cstr(pi, parent, str, pi->cur - str, str);
            if (0 != parent->key && 0 < parent->klen && (parent->key < pi->json || pi->cur < parent->key)) {
                OJ_R_FREE((char *)parent->key);
                parent->key = 0;
            }
            parent->next = NEXT_HASH_COMMA;
            break;
        case NEXT_HASH_COMMA:
        case NEXT_NONE:
        case NEXT_ARRAY_COMMA:
        case NEXT_HASH_COLON:
        default:
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "expected %s, not a string",
                            oj_stack_next_string(parent->next));
            break;
        }
    }
    pi->cur++;  // move past "
}

static void read_num(ParseInfo pi) {
    struct _numInfo ni;
    Val             parent = stack_peek(&pi->stack);

    ni.pi       = pi;
    ni.str      = pi->cur;
    ni.i        = 0;
    ni.num      = 0;
    ni.div      = 1;
    ni.di       = 0;
    ni.len      = 0;
    ni.exp      = 0;
    ni.big      = 0;
    ni.infinity = 0;
    ni.nan      = 0;
    ni.neg      = 0;
    ni.has_exp  = 0;
    if (CompatMode == pi->options.mode) {
        ni.no_big      = !pi->options.compat_bigdec;
        ni.bigdec_load = pi->options.compat_bigdec;
    } else {
        ni.no_big      = (FloatDec == pi->options.bigdec_load || FastDec == pi->options.bigdec_load ||
                     RubyDec == pi->options.bigdec_load);
        ni.bigdec_load = pi->options.bigdec_load;
    }

    if ('-' == *pi->cur) {
        pi->cur++;
        ni.neg = 1;
    } else if ('+' == *pi->cur) {
        if (StrictMode == pi->options.mode) {
            oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
            return;
        }
        pi->cur++;
    }
    if ('I' == *pi->cur) {
        if (No == pi->options.allow_nan || 0 != strncmp("Infinity", pi->cur, 8)) {
            oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
            return;
        }
        pi->cur += 8;
        ni.infinity = 1;
    } else if ('N' == *pi->cur || 'n' == *pi->cur) {
        if ('a' != pi->cur[1] || ('N' != pi->cur[2] && 'n' != pi->cur[2])) {
            oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
            return;
        }
        pi->cur += 3;
        ni.nan = 1;
    } else {
        int  dec_cnt = 0;
        bool zero1   = false;

        // Skip leading zeros.
        for (; '0' == *pi->cur; pi->cur++) {
            zero1 = true;
        }

        for (; '0' <= *pi->cur && *pi->cur <= '9'; pi->cur++) {
            int d = (*pi->cur - '0');

            if (RB_LIKELY(0 != ni.i)) {
                dec_cnt++;
            }
            ni.i = ni.i * 10 + d;
        }
        if (RB_UNLIKELY(0 != ni.i && zero1 && CompatMode == pi->options.mode)) {
            oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number");
            return;
        }
        if (INT64_MAX <= ni.i || DEC_MAX < dec_cnt) {
            ni.big = true;
        }

        if ('.' == *pi->cur) {
            pi->cur++;
            // A trailing . is not a valid decimal but if encountered allow it
            // except when mimicking the JSON gem or in strict mode.
            if (StrictMode == pi->options.mode || CompatMode == pi->options.mode) {
                int pos = (int)(pi->cur - ni.str);

                if (1 == pos || (2 == pos && ni.neg)) {
                    oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number");
                    return;
                }
                if (*pi->cur < '0' || '9' < *pi->cur) {
                    oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number");
                    return;
                }
            }
            for (; '0' <= *pi->cur && *pi->cur <= '9'; pi->cur++) {
                int d = (*pi->cur - '0');

                if (RB_LIKELY(0 != ni.num || 0 != ni.i)) {
                    dec_cnt++;
                }
                ni.num = ni.num * 10 + d;
                ni.div *= 10;
                ni.di++;
            }
        }
        if (INT64_MAX <= ni.div || DEC_MAX < dec_cnt) {
            if (!ni.no_big) {
                ni.big = true;
            }
        }

        if ('e' == *pi->cur || 'E' == *pi->cur) {
            int eneg = 0;

            ni.has_exp = 1;
            pi->cur++;
            if ('-' == *pi->cur) {
                pi->cur++;
                eneg = 1;
            } else if ('+' == *pi->cur) {
                pi->cur++;
            }
            for (; '0' <= *pi->cur && *pi->cur <= '9'; pi->cur++) {
                ni.exp = ni.exp * 10 + (*pi->cur - '0');
                if (EXP_MAX <= ni.exp) {
                    ni.big = true;
                }
            }
            if (eneg) {
                ni.exp = -ni.exp;
            }
        }
        ni.len = pi->cur - ni.str;
    }
    // Check for special reserved values for Infinity and NaN.
    if (ni.big) {
        if (0 == strcasecmp(INF_VAL, ni.str)) {
            ni.infinity = 1;
        } else if (0 == strcasecmp(NINF_VAL, ni.str)) {
            ni.infinity = 1;
            ni.neg      = 1;
        } else if (0 == strcasecmp(NAN_VAL, ni.str)) {
            ni.nan = 1;
        }
    }
    if (CompatMode == pi->options.mode) {
        if (pi->options.compat_bigdec) {
            ni.big = 1;
        }
    } else if (BigDec == pi->options.bigdec_load) {
        ni.big = 1;
    }
    if (0 == parent) {
        pi->add_num(pi, &ni);
    } else {
        switch (parent->next) {
        case NEXT_ARRAY_NEW:
        case NEXT_ARRAY_ELEMENT:
            pi->array_append_num(pi, &ni);
            parent->next = NEXT_ARRAY_COMMA;
            break;
        case NEXT_HASH_VALUE:
            pi->hash_set_num(pi, parent, &ni);
            if (0 != parent->key && 0 < parent->klen && (parent->key < pi->json || pi->cur < parent->key)) {
                OJ_R_FREE((char *)parent->key);
                parent->key = 0;
            }
            parent->next = NEXT_HASH_COMMA;
            break;
        default:
            oj_set_error_at(pi,
                            oj_parse_error_class,
                            __FILE__,
                            __LINE__,
                            "expected %s",
                            oj_stack_next_string(parent->next));
            break;
        }
    }
}

static void array_start(ParseInfo pi) {
    VALUE v = pi->start_array(pi);

    stack_push(&pi->stack, v, NEXT_ARRAY_NEW);
}

static void array_end(ParseInfo pi) {
    Val array = stack_pop(&pi->stack);

    if (0 == array) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected array close");
    } else if (NEXT_ARRAY_COMMA != array->next && NEXT_ARRAY_NEW != array->next) {
        oj_set_error_at(pi,
                        oj_parse_error_class,
                        __FILE__,
                        __LINE__,
                        "expected %s, not an array close",
                        oj_stack_next_string(array->next));
    } else {
        pi->end_array(pi);
        add_value(pi, array->val);
    }
}

static void hash_start(ParseInfo pi) {
    VALUE v = pi->start_hash(pi);

    stack_push(&pi->stack, v, NEXT_HASH_NEW);
}

static void hash_end(ParseInfo pi) {
    Val hash = stack_peek(&pi->stack);

    // leave hash on stack until just before
    if (0 == hash) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected hash close");
    } else if (NEXT_HASH_COMMA != hash->next && NEXT_HASH_NEW != hash->next) {
        oj_set_error_at(pi,
                        oj_parse_error_class,
                        __FILE__,
                        __LINE__,
                        "expected %s, not a hash close",
                        oj_stack_next_string(hash->next));
    } else {
        pi->end_hash(pi);
        stack_pop(&pi->stack);
        add_value(pi, hash->val);
    }
}

static void comma(ParseInfo pi) {
    Val parent = stack_peek(&pi->stack);

    if (0 == parent) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected comma");
    } else if (NEXT_ARRAY_COMMA == parent->next) {
        parent->next = NEXT_ARRAY_ELEMENT;
    } else if (NEXT_HASH_COMMA == parent->next) {
        parent->next = NEXT_HASH_KEY;
    } else {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected comma");
    }
}

static void colon(ParseInfo pi) {
    Val parent = stack_peek(&pi->stack);

    if (0 != parent && NEXT_HASH_COLON == parent->next) {
        parent->next = NEXT_HASH_VALUE;
    } else {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected colon");
    }
}

void oj_parse2(ParseInfo pi) {
    int  first = 1;
    long start = 0;

    pi->cur = pi->json;
    err_init(&pi->err);
    while (1) {
        if (RB_UNLIKELY(0 < pi->max_depth && pi->max_depth <= pi->stack.tail - pi->stack.head - 1)) {
            VALUE err_clas = oj_get_json_err_class("NestingError");

            oj_set_error_at(pi, err_clas, __FILE__, __LINE__, "Too deeply nested.");
            pi->err_class = err_clas;
            return;
        }
        next_non_white(pi);
        if (first) {
            // If no tokens are consumed (i.e. empty string), throw a parse error
            // this is the behavior of JSON.parse in both Ruby and JS.
            if (RB_UNLIKELY('\0' == *pi->cur && No == pi->options.empty_string)) {
                oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected character");
            }
        } else {
            if (RB_UNLIKELY('\0' != *pi->cur)) {
                oj_set_error_at(pi,
                                oj_parse_error_class,
                                __FILE__,
                                __LINE__,
                                "unexpected characters after the JSON document");
            }
        }

        switch (*pi->cur++) {
        case '{': hash_start(pi); break;
        case '}': hash_end(pi); break;
        case ':': colon(pi); break;
        case '[': array_start(pi); break;
        case ']': array_end(pi); break;
        case ',': comma(pi); break;
        case '"': read_str(pi); break;
        case '+':
            if (CompatMode == pi->options.mode) {
                oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected character");
                return;
            }
            pi->cur--;
            read_num(pi);
            break;
        case '-':
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            pi->cur--;
            read_num(pi);
            break;
        case 'I':
        case 'N':
            if (Yes == pi->options.allow_nan) {
                pi->cur--;
                read_num(pi);
            } else {
                oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected character");
            }
            break;
        case 't': read_true(pi); break;
        case 'f': read_false(pi); break;
        case 'n':
            if ('u' == *pi->cur) {
                read_null(pi);
            } else {
                pi->cur--;
                read_num(pi);
            }
            break;
        case '/':
            skip_comment(pi);
            if (first) {
                continue;
            }
            break;
        case '\0': pi->cur--; return;
        default: oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "unexpected character"); return;
        }
        if (RB_UNLIKELY(err_has(&pi->err))) {
            return;
        }
        if (stack_empty(&pi->stack)) {
            if (Qundef != pi->proc) {
                VALUE args[3];
                long  len = (pi->cur - pi->json) - start;

                *args   = stack_head_val(&pi->stack);
                args[1] = LONG2NUM(start);
                args[2] = LONG2NUM(len);

                if (Qnil == pi->proc) {
                    rb_yield_values2(3, args);
                } else {
                    rb_proc_call_with_block(pi->proc, 3, args, Qnil);
                }
            } else if (!pi->has_callbacks) {
                first = 0;
            }
            start = pi->cur - pi->json;
        }
    }
}

static VALUE rescue_big_decimal(VALUE str, VALUE ignore) {
    rb_raise(oj_parse_error_class, "Invalid value for BigDecimal()");
    return Qnil;
}

static VALUE parse_big_decimal(VALUE str) {
    return rb_funcall(rb_cObject, oj_bigdecimal_id, 1, str);
}

static long double exp_plus[] = {
    1.0,    1.0e1,  1.0e2,  1.0e3,  1.0e4,  1.0e5,  1.0e6,  1.0e7,  1.0e8,  1.0e9,  1.0e10, 1.0e11, 1.0e12,
    1.0e13, 1.0e14, 1.0e15, 1.0e16, 1.0e17, 1.0e18, 1.0e19, 1.0e20, 1.0e21, 1.0e22, 1.0e23, 1.0e24, 1.0e25,
    1.0e26, 1.0e27, 1.0e28, 1.0e29, 1.0e30, 1.0e31, 1.0e32, 1.0e33, 1.0e34, 1.0e35, 1.0e36, 1.0e37, 1.0e38,
    1.0e39, 1.0e40, 1.0e41, 1.0e42, 1.0e43, 1.0e44, 1.0e45, 1.0e46, 1.0e47, 1.0e48, 1.0e49,
};

VALUE
oj_num_as_value(NumInfo ni) {
    VALUE rnum = Qnil;

    if (ni->infinity) {
        if (ni->neg) {
            rnum = rb_float_new(-OJ_INFINITY);
        } else {
            rnum = rb_float_new(OJ_INFINITY);
        }
    } else if (ni->nan) {
        rnum = rb_float_new(0.0 / 0.0);
    } else if (1 == ni->div && 0 == ni->exp && !ni->has_exp) {  // fixnum
        if (ni->big) {
            if (256 > ni->len) {
                char buf[256];

                memcpy(buf, ni->str, ni->len);
                buf[ni->len] = '\0';
                rnum         = rb_cstr_to_inum(buf, 10, 0);
            } else {
                char *buf = OJ_R_ALLOC_N(char, ni->len + 1);

                memcpy(buf, ni->str, ni->len);
                buf[ni->len] = '\0';
                rnum         = rb_cstr_to_inum(buf, 10, 0);
                OJ_R_FREE(buf);
            }
        } else {
            if (ni->neg) {
                rnum = rb_ll2inum(-ni->i);
            } else {
                rnum = rb_ll2inum(ni->i);
            }
        }
    } else {  // decimal
        if (ni->big) {
            VALUE bd = rb_str_new(ni->str, ni->len);

            rnum = rb_rescue2(parse_big_decimal, bd, rescue_big_decimal, bd, rb_eException, 0);
            if (ni->no_big) {
                rnum = rb_funcall(rnum, rb_intern("to_f"), 0);
            }
        } else if (FastDec == ni->bigdec_load) {
            long double ld = (long double)ni->i * (long double)ni->div + (long double)ni->num;
            int         x  = (int)((int64_t)ni->exp - ni->di);

            if (0 < x) {
                if (x < (int)(sizeof(exp_plus) / sizeof(*exp_plus))) {
                    ld *= exp_plus[x];
                } else {
                    ld *= powl(10.0, x);
                }
            } else if (x < 0) {
                if (-x < (int)(sizeof(exp_plus) / sizeof(*exp_plus))) {
                    ld /= exp_plus[-x];
                } else {
                    ld /= powl(10.0, -x);
                }
            }
            if (ni->neg) {
                ld = -ld;
            }
            rnum = rb_float_new((double)ld);
        } else if (RubyDec == ni->bigdec_load) {
            VALUE sv = rb_str_new(ni->str, ni->len);

            rnum = rb_funcall(sv, rb_intern("to_f"), 0);
        } else {
            char  *end;
            double d = strtod(ni->str, &end);

            if ((long)ni->len != (long)(end - ni->str)) {
                if (Qnil == ni->pi->err_class) {
                    rb_raise(oj_parse_error_class, "Invalid float");
                } else {
                    rb_raise(ni->pi->err_class, "Invalid float");
                }
            }
            rnum = rb_float_new(d);
        }
    }
    return rnum;
}

void oj_set_error_at(ParseInfo pi, VALUE err_clas, const char *file, int line, const char *format, ...) {
    va_list ap;
    char    msg[256];
    char   *p   = msg;
    char   *end = p + sizeof(msg) - 2;
    char   *start;
    Val     vp;
    int     mlen;

    va_start(ap, format);
    mlen = vsnprintf(msg, sizeof(msg) - 1, format, ap);
    if (0 < mlen) {
        if (sizeof(msg) - 2 < (size_t)mlen) {
            p = end - 2;
        } else {
            p += mlen;
        }
    }
    va_end(ap);
    pi->err.clas = err_clas;
    if (p + 3 < end) {
        *p++  = ' ';
        *p++  = '(';
        *p++  = 'a';
        *p++  = 'f';
        *p++  = 't';
        *p++  = 'e';
        *p++  = 'r';
        *p++  = ' ';
        start = p;
        for (vp = pi->stack.head; vp < pi->stack.tail; vp++) {
            if (end <= p + 1 + vp->klen) {
                break;
            }
            if (NULL != vp->key) {
                if (start < p) {
                    *p++ = '.';
                }
                memcpy(p, vp->key, vp->klen);
                p += vp->klen;
            } else {
                if (RUBY_T_ARRAY == rb_type(vp->val)) {
                    if (end <= p + 12) {
                        break;
                    }
                    p += snprintf(p, end - p, "[%ld]", RARRAY_LEN(vp->val));
                }
            }
        }
        *p++ = ')';
    }
    *p = '\0';
    if (0 == pi->json) {
        oj_err_set(&pi->err, err_clas, "%s at line %d, column %d [%s:%d]", msg, pi->rd.line, pi->rd.col, file, line);
    } else {
        _oj_err_set_with_location(&pi->err, err_clas, msg, pi->json, pi->cur - 1, file, line);
    }
}

static VALUE protect_parse(VALUE pip) {
    oj_parse2((ParseInfo)pip);

    return Qnil;
}

extern int oj_utf8_index;

static void oj_pi_set_input_str(ParseInfo pi, VALUE *inputp) {
    int idx = RB_ENCODING_GET(*inputp);

    if (oj_utf8_encoding_index != idx) {
        rb_encoding *enc = rb_enc_from_index(idx);
        *inputp          = rb_str_conv_enc(*inputp, enc, oj_utf8_encoding);
    }
    pi->json = RSTRING_PTR(*inputp);
    pi->end  = pi->json + RSTRING_LEN(*inputp);
}

VALUE
oj_pi_parse(int argc, VALUE *argv, ParseInfo pi, char *json, size_t len, int yieldOk) {
    char *buf = 0;
    VALUE input;
    VALUE wrapped_stack;
    VALUE result    = Qnil;
    int   line      = 0;
    int   free_json = 0;

    if (argc < 1) {
        rb_raise(rb_eArgError, "Wrong number of arguments to parse.");
    }
    input = argv[0];
    if (2 <= argc) {
        if (T_HASH == rb_type(argv[1])) {
            oj_parse_options(argv[1], &pi->options);
        } else if (3 <= argc && T_HASH == rb_type(argv[2])) {
            oj_parse_options(argv[2], &pi->options);
        }
    }
    if (yieldOk && rb_block_given_p()) {
        pi->proc = Qnil;
    } else {
        pi->proc = Qundef;
    }
    if (0 != json) {
        pi->json  = json;
        pi->end   = json + len;
        free_json = 1;
    } else if (T_STRING == rb_type(input)) {
        if (CompatMode == pi->options.mode) {
            if (No == pi->options.nilnil && 0 == RSTRING_LEN(input)) {
                rb_raise(oj_json_parser_error_class, "An empty string is not a valid JSON string.");
            }
        }
        oj_pi_set_input_str(pi, &input);
    } else if (Qnil == input) {
        if (Yes == pi->options.nilnil) {
            return Qnil;
        } else {
            rb_raise(rb_eTypeError, "Nil is not a valid JSON source.");
        }
    } else {
        VALUE clas = rb_obj_class(input);
        VALUE s;

        if (oj_stringio_class == clas) {
            s = rb_funcall2(input, oj_string_id, 0, 0);
            oj_pi_set_input_str(pi, &s);
#if !IS_WINDOWS
        } else if (rb_cFile == clas && 0 == FIX2INT(rb_funcall(input, oj_pos_id, 0))) {
            int     fd = FIX2INT(rb_funcall(input, oj_fileno_id, 0));
            ssize_t cnt;
            size_t  len = lseek(fd, 0, SEEK_END);

            lseek(fd, 0, SEEK_SET);
            buf      = OJ_R_ALLOC_N(char, len + 1);
            pi->json = buf;
            pi->end  = buf + len;
            if (0 >= (cnt = read(fd, (char *)pi->json, len)) || cnt != (ssize_t)len) {
                if (0 != buf) {
                    OJ_R_FREE(buf);
                }
                rb_raise(rb_eIOError, "failed to read from IO Object.");
            }
            ((char *)pi->json)[len] = '\0';
            /* skip UTF-8 BOM if present */
            if (0xEF == (uint8_t)*pi->json && 0xBB == (uint8_t)pi->json[1] && 0xBF == (uint8_t)pi->json[2]) {
                pi->cur += 3;
            }
#endif
        } else if (rb_respond_to(input, oj_read_id)) {
            // use stream parser instead
            return oj_pi_sparse(argc, argv, pi, 0);
        } else {
            rb_raise(rb_eArgError, "parse() expected a String or IO Object.");
        }
    }
    if (Yes == pi->options.circular) {
        pi->circ_array = oj_circ_array_new();
    } else {
        pi->circ_array = 0;
    }
    if (No == pi->options.allow_gc) {
        rb_gc_disable();
    }
    // GC can run at any time. When it runs any Object created by C will be
    // freed. We protect against this by wrapping the value stack in a ruby
    // data object and poviding a mark function for ruby objects on the
    // value stack (while it is in scope).
    wrapped_stack = oj_stack_init(&pi->stack);
    rb_protect(protect_parse, (VALUE)pi, &line);
    if (Qundef == pi->stack.head->val && !empty_ok(&pi->options)) {
        if (No == pi->options.nilnil || (CompatMode == pi->options.mode && 0 < pi->cur - pi->json)) {
            oj_set_error_at(pi, oj_json_parser_error_class, __FILE__, __LINE__, "Empty input");
        }
    }
    result                  = stack_head_val(&pi->stack);
    DATA_PTR(wrapped_stack) = 0;
    if (No == pi->options.allow_gc) {
        rb_gc_enable();
    }
    if (!err_has(&pi->err)) {
        // If the stack is not empty then the JSON terminated early.
        Val   v;
        VALUE err_class = oj_parse_error_class;

        if (0 != line) {
            VALUE ec = rb_obj_class(rb_errinfo());

            if (rb_eArgError != ec && 0 != ec) {
                err_class = ec;
            }
            if (rb_eIOError != ec) {
                goto CLEANUP;
            }
        }
        if (NULL != (v = stack_peek(&pi->stack))) {
            switch (v->next) {
            case NEXT_ARRAY_NEW:
            case NEXT_ARRAY_ELEMENT:
            case NEXT_ARRAY_COMMA: oj_set_error_at(pi, err_class, __FILE__, __LINE__, "Array not terminated"); break;
            case NEXT_HASH_NEW:
            case NEXT_HASH_KEY:
            case NEXT_HASH_COLON:
            case NEXT_HASH_VALUE:
            case NEXT_HASH_COMMA:
                oj_set_error_at(pi, err_class, __FILE__, __LINE__, "Hash/Object not terminated");
                break;
            default: oj_set_error_at(pi, err_class, __FILE__, __LINE__, "not terminated");
            }
        }
    }
CLEANUP:
    // proceed with cleanup
    if (0 != pi->circ_array) {
        oj_circ_array_free(pi->circ_array);
    }
    if (0 != buf) {
        OJ_R_FREE(buf);
    } else if (free_json) {
        OJ_R_FREE(json);
    }
    stack_cleanup(&pi->stack);
    if (pi->str_rx.head != oj_default_options.str_rx.head) {
        oj_rxclass_cleanup(&pi->str_rx);
    }
    if (err_has(&pi->err)) {
        rb_set_errinfo(Qnil);
        if (Qnil != pi->err_class) {
            pi->err.clas = pi->err_class;
        }
        if ((CompatMode == pi->options.mode || RailsMode == pi->options.mode) && Yes != pi->options.safe) {
            // The json gem requires the error message be UTF-8 encoded. In
            // additional the complete JSON source must be returned. There
            // does not seem to be a size limit.
            VALUE msg = rb_utf8_str_new_cstr(pi->err.msg);
            VALUE args[1];

            if (NULL != pi->json) {
                msg = rb_str_append(msg, rb_utf8_str_new_cstr(" in '"));
                msg = rb_str_append(msg, rb_utf8_str_new_cstr(pi->json));
            }
            args[0] = msg;
            if (pi->err.clas == oj_parse_error_class) {
                // The error was an Oj::ParseError so change to a JSON::ParserError.
                pi->err.clas = oj_json_parser_error_class;
            }
            rb_exc_raise(rb_class_new_instance(1, args, pi->err.clas));
        } else {
            oj_err_raise(&pi->err);
        }
    } else if (0 != line) {
        rb_jump_tag(line);
    }
    if (pi->options.quirks_mode == No) {
        switch (rb_type(result)) {
        case T_NIL:
        case T_TRUE:
        case T_FALSE:
        case T_FIXNUM:
        case T_FLOAT:
        case T_CLASS:
        case T_STRING:
        case T_SYMBOL: {
            struct _err err;

            if (Qnil == pi->err_class) {
                err.clas = oj_parse_error_class;
            } else {
                err.clas = pi->err_class;
            }
            snprintf(err.msg, sizeof(err.msg), "unexpected non-document value");
            oj_err_raise(&err);
            break;
        }
        default:
            // okay
            break;
        }
    }
    return result;
}
