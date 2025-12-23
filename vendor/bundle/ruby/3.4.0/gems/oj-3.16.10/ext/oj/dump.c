// Copyright (c) 2012, 2017 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include "dump.h"

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#if !IS_WINDOWS
#include <poll.h>
#endif

#include "cache8.h"
#include "mem.h"
#include "odd.h"
#include "oj.h"
#include "trace.h"
#include "util.h"

// Workaround in case INFINITY is not defined in math.h or if the OS is CentOS
#define OJ_INFINITY (1.0 / 0.0)

#define MAX_DEPTH 1000

static const char inf_val[]  = INF_VAL;
static const char ninf_val[] = NINF_VAL;
static const char nan_val[]  = NAN_VAL;

typedef unsigned long ulong;

static size_t hibit_friendly_size(const uint8_t *str, size_t len);
static size_t slash_friendly_size(const uint8_t *str, size_t len);
static size_t xss_friendly_size(const uint8_t *str, size_t len);
static size_t ascii_friendly_size(const uint8_t *str, size_t len);

static const char hex_chars[17] = "0123456789abcdef";

// JSON standard except newlines are no escaped
static char newline_friendly_chars[256] = "\
66666666221622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

// JSON standard
static char hibit_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

// JSON standard but escape forward slashes `/`
static char slash_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111121111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

// High bit set characters are always encoded as unicode. Worse case is 3
// bytes per character in the output. That makes this conservative.
static char ascii_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111116\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333";

// XSS safe mode
static char xss_friendly_chars[256] = "\
66666666222622666666666666666666\
11211161111111121111111111116161\
11111111111111111111111111112111\
11111111111111111111111111111116\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333\
33333333333333333333333333333333";

// JSON XSS combo
static char hixss_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11611111111111111111111111111111";

// Rails XSS combo
static char rails_xss_friendly_chars[256] = "\
66666666222622666666666666666666\
11211161111111111111111111116161\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11611111111111111111111111111111";

// Rails HTML non-escape
static char rails_friendly_chars[256] = "\
66666666222622666666666666666666\
11211111111111111111111111111111\
11111111111111111111111111112111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111\
11111111111111111111111111111111";

static void raise_strict(VALUE obj) {
    rb_raise(rb_eTypeError, "Failed to dump %s Object to JSON in strict mode.", rb_class2name(rb_obj_class(obj)));
}

inline static size_t calculate_string_size(const uint8_t *str, size_t len, const char *table) {
    size_t size = 0;
    size_t i    = len;

    for (; 3 < i; i -= 4) {
        size += table[*str++];
        size += table[*str++];
        size += table[*str++];
        size += table[*str++];
    }
    for (; 0 < i; i--) {
        size += table[*str++];
    }
    return size - len * (size_t)'0';
}

inline static size_t newline_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, newline_friendly_chars);
}

inline static size_t hibit_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, hibit_friendly_chars);
}

inline static size_t slash_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, slash_friendly_chars);
}

inline static size_t ascii_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, ascii_friendly_chars);
}

inline static size_t xss_friendly_size(const uint8_t *str, size_t len) {
    return calculate_string_size(str, len, xss_friendly_chars);
}

inline static size_t hixss_friendly_size(const uint8_t *str, size_t len) {
    size_t size  = 0;
    size_t i     = len;
    bool   check = false;

    for (; 0 < i; str++, i--) {
        size += hixss_friendly_chars[*str];
        if (0 != (0x80 & *str)) {
            check = true;
        }
    }
    return size - len * (size_t)'0' + check;
}

inline static long rails_xss_friendly_size(const uint8_t *str, size_t len) {
    long    size = 0;
    size_t  i    = len;
    uint8_t hi   = 0;

    for (; 0 < i; str++, i--) {
        size += rails_xss_friendly_chars[*str];
        hi |= *str & 0x80;
    }
    if (0 == hi) {
        return size - len * (size_t)'0';
    }
    return -(size - len * (size_t)'0');
}

inline static size_t rails_friendly_size(const uint8_t *str, size_t len) {
    long    size = 0;
    size_t  i    = len;
    uint8_t hi   = 0;

    for (; 0 < i; str++, i--) {
        size += rails_friendly_chars[*str];
        hi |= *str & 0x80;
    }
    if (0 == hi) {
        return size - len * (size_t)'0';
    }
    return -(size - len * (size_t)'0');
}

const char *oj_nan_str(VALUE obj, int opt, int mode, bool plus, int *lenp) {
    const char *str = NULL;

    if (AutoNan == opt) {
        switch (mode) {
        case CompatMode: opt = WordNan; break;
        case StrictMode: opt = RaiseNan; break;
        default: break;
        }
    }
    switch (opt) {
    case RaiseNan: raise_strict(obj); break;
    case WordNan:
        if (plus) {
            str   = "Infinity";
            *lenp = 8;
        } else {
            str   = "-Infinity";
            *lenp = 9;
        }
        break;
    case NullNan:
        str   = "null";
        *lenp = 4;
        break;
    case HugeNan:
    default:
        if (plus) {
            str   = inf_val;
            *lenp = sizeof(inf_val) - 1;
        } else {
            str   = ninf_val;
            *lenp = sizeof(ninf_val) - 1;
        }
        break;
    }
    return str;
}

inline static void dump_hex(uint8_t c, Out out) {
    uint8_t d = (c >> 4) & 0x0F;

    *out->cur++ = hex_chars[d];
    d           = c & 0x0F;
    *out->cur++ = hex_chars[d];
}

static void raise_invalid_unicode(const char *str, int len, int pos) {
    char    c;
    char    code[32];
    char   *cp = code;
    int     i;
    uint8_t d;

    *cp++ = '[';
    for (i = pos; i < len && i - pos < 5; i++) {
        c     = str[i];
        d     = (c >> 4) & 0x0F;
        *cp++ = hex_chars[d];
        d     = c & 0x0F;
        *cp++ = hex_chars[d];
        *cp++ = ' ';
    }
    cp--;
    *cp++ = ']';
    *cp   = '\0';
    rb_raise(oj_json_generator_error_class, "Invalid Unicode %s at %d", code, pos);
}

static const char *dump_unicode(const char *str, const char *end, Out out, const char *orig) {
    uint32_t code = 0;
    uint8_t  b    = *(uint8_t *)str;
    int      i, cnt;

    if (0xC0 == (0xE0 & b)) {
        cnt  = 1;
        code = b & 0x0000001F;
    } else if (0xE0 == (0xF0 & b)) {
        cnt  = 2;
        code = b & 0x0000000F;
    } else if (0xF0 == (0xF8 & b)) {
        cnt  = 3;
        code = b & 0x00000007;
    } else if (0xF8 == (0xFC & b)) {
        cnt  = 4;
        code = b & 0x00000003;
    } else if (0xFC == (0xFE & b)) {
        cnt  = 5;
        code = b & 0x00000001;
    } else {
        cnt = 0;
        raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
    }
    str++;
    for (; 0 < cnt; cnt--, str++) {
        b = *(uint8_t *)str;
        if (end <= str || 0x80 != (0xC0 & b)) {
            raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
        }
        code = (code << 6) | (b & 0x0000003F);
    }
    if (0x0000FFFF < code) {
        uint32_t c1;

        code -= 0x00010000;
        c1   = ((code >> 10) & 0x000003FF) + 0x0000D800;
        code = (code & 0x000003FF) + 0x0000DC00;
        APPEND_CHARS(out->cur, "\\u", 2);
        for (i = 3; 0 <= i; i--) {
            *out->cur++ = hex_chars[(uint8_t)(c1 >> (i * 4)) & 0x0F];
        }
    }
    APPEND_CHARS(out->cur, "\\u", 2);
    for (i = 3; 0 <= i; i--) {
        *out->cur++ = hex_chars[(uint8_t)(code >> (i * 4)) & 0x0F];
    }
    return str - 1;
}

static const char *check_unicode(const char *str, const char *end, const char *orig) {
    uint8_t b   = *(uint8_t *)str;
    int     cnt = 0;

    if (0xC0 == (0xE0 & b)) {
        cnt = 1;
    } else if (0xE0 == (0xF0 & b)) {
        cnt = 2;
    } else if (0xF0 == (0xF8 & b)) {
        cnt = 3;
    } else if (0xF8 == (0xFC & b)) {
        cnt = 4;
    } else if (0xFC == (0xFE & b)) {
        cnt = 5;
    } else {
        raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
    }
    str++;
    for (; 0 < cnt; cnt--, str++) {
        b = *(uint8_t *)str;
        if (end <= str || 0x80 != (0xC0 & b)) {
            raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
        }
    }
    return str;
}

// Returns 0 if not using circular references, -1 if no further writing is
// needed (duplicate), and a positive value if the object was added to the
// cache.
long oj_check_circular(VALUE obj, Out out) {
    slot_t  id = 0;
    slot_t *slot;

    if (Yes == out->opts->circular) {
        if (0 == (id = oj_cache8_get(out->circ_cache, obj, &slot))) {
            out->circ_cnt++;
            id    = out->circ_cnt;
            *slot = id;
        } else {
            if (ObjectMode == out->opts->mode) {
                assure_size(out, 18);
                APPEND_CHARS(out->cur, "\"^r", 3);
                dump_ulong(id, out);
                *out->cur++ = '"';
            }
            return -1;
        }
    }
    return (long)id;
}

void oj_dump_time(VALUE obj, Out out, int withZone) {
    char      buf[64];
    char     *b = buf + sizeof(buf) - 1;
    long      size;
    char     *dot;
    int       neg = 0;
    long      one = 1000000000;
    long long sec;
    long long nsec;

    // rb_time_timespec as well as rb_time_timeeval have a bug that causes an
    // exception to be raised if a time is before 1970 on 32 bit systems so
    // check the timespec size and use the ruby calls if a 32 bit system.
    if (16 <= sizeof(struct timespec)) {
        struct timespec ts = rb_time_timespec(obj);

        sec  = (long long)ts.tv_sec;
        nsec = ts.tv_nsec;
    } else {
        sec  = NUM2LL(rb_funcall2(obj, oj_tv_sec_id, 0, 0));
        nsec = NUM2LL(rb_funcall2(obj, oj_tv_nsec_id, 0, 0));
    }

    *b-- = '\0';
    if (withZone) {
        long tzsecs = NUM2LONG(rb_funcall2(obj, oj_utc_offset_id, 0, 0));
        int  zneg   = (0 > tzsecs);

        if (0 == tzsecs && rb_funcall2(obj, oj_utcq_id, 0, 0)) {
            tzsecs = 86400;
        }
        if (zneg) {
            tzsecs = -tzsecs;
        }
        if (0 == tzsecs) {
            *b-- = '0';
        } else {
            for (; 0 < tzsecs; b--, tzsecs /= 10) {
                *b = '0' + (tzsecs % 10);
            }
            if (zneg) {
                *b-- = '-';
            }
        }
        *b-- = 'e';
    }
    if (0 > sec) {
        neg = 1;
        sec = -sec;
        if (0 < nsec) {
            nsec = 1000000000 - nsec;
            sec--;
        }
    }
    dot = b - 9;
    if (0 < out->opts->sec_prec) {
        if (9 > out->opts->sec_prec) {
            int i;

            for (i = 9 - out->opts->sec_prec; 0 < i; i--) {
                dot++;
                nsec = (nsec + 5) / 10;
                one /= 10;
            }
        }
        if (one <= nsec) {
            nsec -= one;
            sec++;
        }
        for (; dot < b; b--, nsec /= 10) {
            *b = '0' + (nsec % 10);
        }
        *b-- = '.';
    }
    if (0 == sec) {
        *b-- = '0';
    } else {
        for (; 0 < sec; b--, sec /= 10) {
            *b = '0' + (sec % 10);
        }
    }
    if (neg) {
        *b-- = '-';
    }
    b++;
    size = sizeof(buf) - (b - buf) - 1;
    assure_size(out, size);
    APPEND_CHARS(out->cur, b, size);
    *out->cur = '\0';
}

void oj_dump_ruby_time(VALUE obj, Out out) {
    volatile VALUE rstr = oj_safe_string_convert(obj);

    oj_dump_cstr(RSTRING_PTR(rstr), (int)RSTRING_LEN(rstr), 0, 0, out);
}

void oj_dump_xml_time(VALUE obj, Out out) {
    char             buf[64];
    struct _timeInfo ti;
    long             one = 1000000000;
    int64_t          sec;
    long long        nsec;
    long             tzsecs = NUM2LONG(rb_funcall2(obj, oj_utc_offset_id, 0, 0));
    int              tzhour, tzmin;
    char             tzsign = '+';

    if (16 <= sizeof(struct timespec)) {
        struct timespec ts = rb_time_timespec(obj);

        sec  = ts.tv_sec;
        nsec = ts.tv_nsec;
    } else {
        sec  = NUM2LL(rb_funcall2(obj, oj_tv_sec_id, 0, 0));
        nsec = NUM2LL(rb_funcall2(obj, oj_tv_nsec_id, 0, 0));
    }

    assure_size(out, 36);
    if (9 > out->opts->sec_prec) {
        int i;

        // This is pretty lame but to be compatible with rails and active
        // support rounding is not done but instead a floor is done when
        // second precision is 3 just to be like rails. sigh.
        if (3 == out->opts->sec_prec) {
            nsec /= 1000000;
            one = 1000;
        } else {
            for (i = 9 - out->opts->sec_prec; 0 < i; i--) {
                nsec = (nsec + 5) / 10;
                one /= 10;
            }
            if (one <= nsec) {
                nsec -= one;
                sec++;
            }
        }
    }
    // 2012-01-05T23:58:07.123456000+09:00
    // tm = localtime(&sec);
    sec += tzsecs;
    sec_as_time((int64_t)sec, &ti);
    if (0 > tzsecs) {
        tzsign = '-';
        tzhour = (int)(tzsecs / -3600);
        tzmin  = (int)(tzsecs / -60) - (tzhour * 60);
    } else {
        tzhour = (int)(tzsecs / 3600);
        tzmin  = (int)(tzsecs / 60) - (tzhour * 60);
    }
    if ((0 == nsec && !out->opts->sec_prec_set) || 0 == out->opts->sec_prec) {
        if (0 == tzsecs && rb_funcall2(obj, oj_utcq_id, 0, 0)) {
            int len = sprintf(buf, "%04d-%02d-%02dT%02d:%02d:%02dZ", ti.year, ti.mon, ti.day, ti.hour, ti.min, ti.sec);
            oj_dump_cstr(buf, len, 0, 0, out);
        } else {
            int len = sprintf(buf,
                              "%04d-%02d-%02dT%02d:%02d:%02d%c%02d:%02d",
                              ti.year,
                              ti.mon,
                              ti.day,
                              ti.hour,
                              ti.min,
                              ti.sec,
                              tzsign,
                              tzhour,
                              tzmin);
            oj_dump_cstr(buf, len, 0, 0, out);
        }
    } else if (0 == tzsecs && rb_funcall2(obj, oj_utcq_id, 0, 0)) {
        char format[64] = "%04d-%02d-%02dT%02d:%02d:%02d.%09ldZ";
        int  len;

        if (9 > out->opts->sec_prec) {
            format[32] = '0' + out->opts->sec_prec;
        }
        len = sprintf(buf, format, ti.year, ti.mon, ti.day, ti.hour, ti.min, ti.sec, (long)nsec);
        oj_dump_cstr(buf, len, 0, 0, out);
    } else {
        char format[64] = "%04d-%02d-%02dT%02d:%02d:%02d.%09ld%c%02d:%02d";
        int  len;

        if (9 > out->opts->sec_prec) {
            format[32] = '0' + out->opts->sec_prec;
        }
        len = sprintf(buf, format, ti.year, ti.mon, ti.day, ti.hour, ti.min, ti.sec, (long)nsec, tzsign, tzhour, tzmin);
        oj_dump_cstr(buf, len, 0, 0, out);
    }
}

void oj_dump_obj_to_json(VALUE obj, Options copts, Out out) {
    oj_dump_obj_to_json_using_params(obj, copts, out, 0, 0);
}

void oj_dump_obj_to_json_using_params(VALUE obj, Options copts, Out out, int argc, VALUE *argv) {
    if (0 == out->buf) {
        oj_out_init(out);
    }
    out->circ_cnt = 0;
    out->opts     = copts;
    out->hash_cnt = 0;
    out->indent   = copts->indent;
    out->argc     = argc;
    out->argv     = argv;
    out->ropts    = NULL;
    if (Yes == copts->circular) {
        oj_cache8_new(&out->circ_cache);
    }
    switch (copts->mode) {
    case StrictMode: oj_dump_strict_val(obj, 0, out); break;
    case NullMode: oj_dump_null_val(obj, 0, out); break;
    case ObjectMode: oj_dump_obj_val(obj, 0, out); break;
    case CompatMode: oj_dump_compat_val(obj, 0, out, Yes == copts->to_json); break;
    case RailsMode: oj_dump_rails_val(obj, 0, out); break;
    case CustomMode: oj_dump_custom_val(obj, 0, out, true); break;
    case WabMode: oj_dump_wab_val(obj, 0, out); break;
    default: oj_dump_custom_val(obj, 0, out, true); break;
    }
    if (0 < out->indent) {
        switch (*(out->cur - 1)) {
        case ']':
        case '}': assure_size(out, 1); *out->cur++ = '\n';
        default: break;
        }
    }
    *out->cur = '\0';
    if (Yes == copts->circular) {
        oj_cache8_delete(out->circ_cache);
    }
}

void oj_write_obj_to_file(VALUE obj, const char *path, Options copts) {
    struct _out out;
    size_t      size;
    FILE       *f;
    int         ok;

    oj_out_init(&out);

    out.omit_nil = copts->dump_opts.omit_nil;
    oj_dump_obj_to_json(obj, copts, &out);
    size = out.cur - out.buf;
    if (0 == (f = fopen(path, "w"))) {
        oj_out_free(&out);
        rb_raise(rb_eIOError, "%s", strerror(errno));
    }
    ok = (size == fwrite(out.buf, 1, size, f));

    oj_out_free(&out);

    if (!ok) {
        int err = ferror(f);
        fclose(f);

        rb_raise(rb_eIOError, "Write failed. [%d:%s]", err, strerror(err));
    }
    fclose(f);
}

#if !IS_WINDOWS
static void write_ready(int fd) {
    struct pollfd pp;
    int           i;

    pp.fd      = fd;
    pp.events  = POLLERR | POLLOUT;
    pp.revents = 0;
    if (0 >= (i = poll(&pp, 1, 5000))) {
        if (0 == i || EAGAIN == errno) {
            rb_raise(rb_eIOError, "write timed out");
        }
        rb_raise(rb_eIOError, "write failed. %d %s.", errno, strerror(errno));
    }
}
#endif

void oj_write_obj_to_stream(VALUE obj, VALUE stream, Options copts) {
    struct _out out;
    ssize_t     size;
    VALUE       clas = rb_obj_class(stream);
#if !IS_WINDOWS
    int   fd;
    VALUE s;
#endif

    oj_out_init(&out);

    out.omit_nil = copts->dump_opts.omit_nil;
    oj_dump_obj_to_json(obj, copts, &out);
    size = out.cur - out.buf;
    if (oj_stringio_class == clas) {
        rb_funcall(stream, oj_write_id, 1, rb_str_new(out.buf, size));
#if !IS_WINDOWS
    } else if (rb_respond_to(stream, oj_fileno_id) && Qnil != (s = rb_funcall(stream, oj_fileno_id, 0)) &&
               0 != (fd = FIX2INT(s))) {
        ssize_t cnt;
        ssize_t total = 0;

        while (true) {
            if (0 > (cnt = write(fd, out.buf + total, size - total))) {
                if (EAGAIN != errno) {
                    rb_raise(rb_eIOError, "write failed. %d %s.", errno, strerror(errno));
                    break;
                }
            }
            total += cnt;
            if (size <= total) {
                // Completed
                break;
            }
            write_ready(fd);
        }
#endif
    } else if (rb_respond_to(stream, oj_write_id)) {
        rb_funcall(stream, oj_write_id, 1, rb_str_new(out.buf, size));
    } else {
        oj_out_free(&out);
        rb_raise(rb_eArgError, "to_stream() expected an IO Object.");
    }
    oj_out_free(&out);
}

void oj_dump_str(VALUE obj, int depth, Out out, bool as_ok) {
    int idx = RB_ENCODING_GET(obj);

    if (oj_utf8_encoding_index != idx) {
        rb_encoding *enc = rb_enc_from_index(idx);
        obj              = rb_str_conv_enc(obj, enc, oj_utf8_encoding);
    }
    oj_dump_cstr(RSTRING_PTR(obj), (int)RSTRING_LEN(obj), 0, 0, out);
}

void oj_dump_sym(VALUE obj, int depth, Out out, bool as_ok) {
    volatile VALUE s = rb_sym2str(obj);

    oj_dump_cstr(RSTRING_PTR(s), (int)RSTRING_LEN(s), 0, 0, out);
}

static void debug_raise(const char *orig, size_t cnt, int line) {
    char        buf[1024];
    char       *b     = buf;
    const char *s     = orig;
    const char *s_end = s + cnt;

    if (32 < s_end - s) {
        s_end = s + 32;
    }
    for (; s < s_end; s++) {
        b += sprintf(b, " %02x", *s);
    }
    *b = '\0';
    rb_raise(oj_json_generator_error_class, "Partial character in string. %s @ %d", buf, line);
}

void oj_dump_raw_json(VALUE obj, int depth, Out out) {
    if (oj_string_writer_class == rb_obj_class(obj)) {
        StrWriter sw;
        size_t    len;

        sw  = oj_str_writer_unwrap(obj);
        len = sw->out.cur - sw->out.buf;

        if (0 < len) {
            len--;
        }
        oj_dump_raw(sw->out.buf, len, out);
    } else {
        volatile VALUE jv;

        TRACE(out->opts->trace, "raw_json", obj, depth + 1, TraceRubyIn);
        jv = rb_funcall(obj, oj_raw_json_id, 2, RB_INT2NUM(depth), RB_INT2NUM(out->indent));
        TRACE(out->opts->trace, "raw_json", obj, depth + 1, TraceRubyOut);
        oj_dump_raw(RSTRING_PTR(jv), (size_t)RSTRING_LEN(jv), out);
    }
}

void oj_dump_cstr(const char *str, size_t cnt, bool is_sym, bool escape1, Out out) {
    size_t      size;
    char       *cmap;
    const char *orig                  = str;
    bool        has_hi                = false;
    bool        do_unicode_validation = false;

    switch (out->opts->escape_mode) {
    case NLEsc:
        cmap = newline_friendly_chars;
        size = newline_friendly_size((uint8_t *)str, cnt);
        break;
    case ASCIIEsc:
        cmap = ascii_friendly_chars;
        size = ascii_friendly_size((uint8_t *)str, cnt);
        break;
    case SlashEsc:
        has_hi = true;
        cmap   = slash_friendly_chars;
        size   = slash_friendly_size((uint8_t *)str, cnt);
        break;
    case XSSEsc:
        cmap = xss_friendly_chars;
        size = xss_friendly_size((uint8_t *)str, cnt);
        break;
    case JXEsc:
        cmap                  = hixss_friendly_chars;
        size                  = hixss_friendly_size((uint8_t *)str, cnt);
        do_unicode_validation = true;
        break;
    case RailsXEsc: {
        long sz;

        cmap = rails_xss_friendly_chars;
        sz   = rails_xss_friendly_size((uint8_t *)str, cnt);
        if (sz < 0) {
            has_hi = true;
            size   = (size_t)-sz;
        } else {
            size = (size_t)sz;
        }
        do_unicode_validation = true;
        break;
    }
    case RailsEsc: {
        long sz;
        cmap = rails_friendly_chars;
        sz   = rails_friendly_size((uint8_t *)str, cnt);
        if (sz < 0) {
            has_hi = true;
            size   = (size_t)-sz;
        } else {
            size = (size_t)sz;
        }
        do_unicode_validation = true;
        break;
    }
    case JSONEsc:
    default: cmap = hibit_friendly_chars; size = hibit_friendly_size((uint8_t *)str, cnt);
    }
    assure_size(out, size + BUFFER_EXTRA);
    *out->cur++ = '"';

    if (escape1) {
        APPEND_CHARS(out->cur, "\\u00", 4);
        dump_hex((uint8_t)*str, out);
        cnt--;
        size--;
        str++;
        is_sym = 0;  // just to make sure
    }
    if (cnt == size && !has_hi) {
        if (is_sym) {
            *out->cur++ = ':';
        }
        APPEND_CHARS(out->cur, str, cnt);
        *out->cur++ = '"';
    } else {
        const char *end         = str + cnt;
        const char *check_start = str;

        if (is_sym) {
            *out->cur++ = ':';
        }
        for (; str < end; str++) {
            switch (cmap[(uint8_t)*str]) {
            case '1':
                if (do_unicode_validation && check_start <= str) {
                    if (0 != (0x80 & (uint8_t)*str)) {
                        if (0xC0 == (0xC0 & (uint8_t)*str)) {
                            check_start = check_unicode(str, end, orig);
                        } else {
                            raise_invalid_unicode(orig, (int)(end - orig), (int)(str - orig));
                        }
                    }
                }
                *out->cur++ = *str;
                break;
            case '2':
                *out->cur++ = '\\';
                switch (*str) {
                case '\\': *out->cur++ = '\\'; break;
                case '\b': *out->cur++ = 'b'; break;
                case '\t': *out->cur++ = 't'; break;
                case '\n': *out->cur++ = 'n'; break;
                case '\f': *out->cur++ = 'f'; break;
                case '\r': *out->cur++ = 'r'; break;
                default: *out->cur++ = *str; break;
                }
                break;
            case '3':  // Unicode
                if (0xe2 == (uint8_t)*str && do_unicode_validation && 2 <= end - str) {
                    if (0x80 == (uint8_t)str[1] && (0xa8 == (uint8_t)str[2] || 0xa9 == (uint8_t)str[2])) {
                        str = dump_unicode(str, end, out, orig);
                    } else {
                        check_start = check_unicode(str, end, orig);
                        *out->cur++ = *str;
                    }
                    break;
                }
                str = dump_unicode(str, end, out, orig);
                break;
            case '6':  // control characters
                if (*(uint8_t *)str < 0x80) {
                    if (0 == (uint8_t)*str && out->opts->dump_opts.omit_null_byte) {
                        break;
                    }
                    APPEND_CHARS(out->cur, "\\u00", 4);
                    dump_hex((uint8_t)*str, out);
                } else {
                    if (0xe2 == (uint8_t)*str && do_unicode_validation && 2 <= end - str) {
                        if (0x80 == (uint8_t)str[1] && (0xa8 == (uint8_t)str[2] || 0xa9 == (uint8_t)str[2])) {
                            str = dump_unicode(str, end, out, orig);
                        } else {
                            check_start = check_unicode(str, end, orig);
                            *out->cur++ = *str;
                        }
                        break;
                    }
                    str = dump_unicode(str, end, out, orig);
                }
                break;
            default: break;  // ignore, should never happen if the table is correct
            }
        }
        *out->cur++ = '"';
    }
    if (do_unicode_validation && 0 < str - orig && 0 != (0x80 & *(str - 1))) {
        uint8_t c = (uint8_t) * (str - 1);
        int     i;
        int     scnt = (int)(str - orig);

        // Last utf-8 characters must be 0x10xxxxxx. The start must be
        // 0x110xxxxx for 2 characters, 0x1110xxxx for 3, and 0x11110xxx for
        // 4.
        if (0 != (0x40 & c)) {
            debug_raise(orig, cnt, __LINE__);
        }
        for (i = 1; i < (int)scnt && i < 4; i++) {
            c = str[-1 - i];
            if (0x80 != (0xC0 & c)) {
                switch (i) {
                case 1:
                    if (0xC0 != (0xE0 & c)) {
                        debug_raise(orig, cnt, __LINE__);
                    }
                    break;
                case 2:
                    if (0xE0 != (0xF0 & c)) {
                        debug_raise(orig, cnt, __LINE__);
                    }
                    break;
                case 3:
                    if (0xF0 != (0xF8 & c)) {
                        debug_raise(orig, cnt, __LINE__);
                    }
                    break;
                default:  // can't get here
                    break;
                }
                break;
            }
        }
        if (i == (int)scnt || 4 <= i) {
            debug_raise(orig, cnt, __LINE__);
        }
    }
    *out->cur = '\0';
}

void oj_dump_class(VALUE obj, int depth, Out out, bool as_ok) {
    const char *s = rb_class2name(obj);

    oj_dump_cstr(s, strlen(s), 0, 0, out);
}

void oj_dump_obj_to_s(VALUE obj, Out out) {
    volatile VALUE rstr = oj_safe_string_convert(obj);

    oj_dump_cstr(RSTRING_PTR(rstr), (int)RSTRING_LEN(rstr), 0, 0, out);
}

void oj_dump_raw(const char *str, size_t cnt, Out out) {
    assure_size(out, cnt + 10);
    APPEND_CHARS(out->cur, str, cnt);
    *out->cur = '\0';
}

void oj_out_init(Out out) {
    out->buf       = out->stack_buffer;
    out->cur       = out->buf;
    out->end       = out->buf + sizeof(out->stack_buffer) - BUFFER_EXTRA;
    out->allocated = false;
}

void oj_out_free(Out out) {
    if (out->allocated) {
        OJ_R_FREE(out->buf);  // TBD
    }
}

void oj_grow_out(Out out, size_t len) {
    size_t size = out->end - out->buf;
    long   pos  = out->cur - out->buf;
    char  *buf  = out->buf;

    size *= 2;
    if (size <= len * 2 + pos) {
        size += len;
    }
    if (out->allocated) {
        OJ_R_REALLOC_N(buf, char, (size + BUFFER_EXTRA));
    } else {
        buf            = OJ_R_ALLOC_N(char, (size + BUFFER_EXTRA));
        out->allocated = true;
        memcpy(buf, out->buf, out->end - out->buf + BUFFER_EXTRA);
    }
    if (0 == buf) {
        rb_raise(rb_eNoMemError, "Failed to create string. [%d:%s]", ENOSPC, strerror(ENOSPC));
    }
    out->buf = buf;
    out->end = buf + size;
    out->cur = out->buf + pos;
}

void oj_dump_nil(VALUE obj, int depth, Out out, bool as_ok) {
    assure_size(out, 4);
    APPEND_CHARS(out->cur, "null", 4);
    *out->cur = '\0';
}

void oj_dump_true(VALUE obj, int depth, Out out, bool as_ok) {
    assure_size(out, 4);
    APPEND_CHARS(out->cur, "true", 4);
    *out->cur = '\0';
}

void oj_dump_false(VALUE obj, int depth, Out out, bool as_ok) {
    assure_size(out, 5);
    APPEND_CHARS(out->cur, "false", 5);
    *out->cur = '\0';
}

static const char digits_table[] = "\
00010203040506070809\
10111213141516171819\
20212223242526272829\
30313233343536373839\
40414243444546474849\
50515253545556575859\
60616263646566676869\
70717273747576777879\
80818283848586878889\
90919293949596979899";

char *oj_longlong_to_string(long long num, bool negative, char *buf) {
    while (100 <= num) {
        unsigned idx = num % 100 * 2;
        *buf--       = digits_table[idx + 1];
        *buf--       = digits_table[idx];
        num /= 100;
    }
    if (num < 10) {
        *buf-- = num + '0';
    } else {
        *buf-- = digits_table[num * 2 + 1];
        *buf-- = digits_table[num * 2];
    }

    if (negative) {
        *buf = '-';
    } else {
        buf++;
    }
    return buf;
}

void oj_dump_fixnum(VALUE obj, int depth, Out out, bool as_ok) {
    char      buf[32];
    char     *b              = buf + sizeof(buf) - 1;
    long long num            = NUM2LL(obj);
    bool      neg            = false;
    size_t    cnt            = 0;
    bool      dump_as_string = false;

    if (out->opts->int_range_max != 0 && out->opts->int_range_min != 0 &&
        (out->opts->int_range_max < num || out->opts->int_range_min > num)) {
        dump_as_string = true;
    }
    if (0 > num) {
        neg = true;
        num = -num;
    }
    *b-- = '\0';

    if (dump_as_string) {
        *b-- = '"';
    }
    if (0 < num) {
        b = oj_longlong_to_string(num, neg, b);
    } else {
        *b = '0';
    }
    if (dump_as_string) {
        *--b = '"';
    }
    cnt = sizeof(buf) - (b - buf) - 1;
    assure_size(out, cnt);
    APPEND_CHARS(out->cur, b, cnt);
    *out->cur = '\0';
}

void oj_dump_bignum(VALUE obj, int depth, Out out, bool as_ok) {
    volatile VALUE rs             = rb_big2str(obj, 10);
    int            cnt            = (int)RSTRING_LEN(rs);
    bool           dump_as_string = false;

    if (out->opts->int_range_max != 0 || out->opts->int_range_min != 0) {  // Bignum cannot be inside of Fixnum range
        dump_as_string = true;
        assure_size(out, cnt + 2);
        *out->cur++ = '"';
    } else {
        assure_size(out, cnt);
    }
    APPEND_CHARS(out->cur, RSTRING_PTR(rs), cnt);
    if (dump_as_string) {
        *out->cur++ = '"';
    }
    *out->cur = '\0';
}

// Removed dependencies on math due to problems with CentOS 5.4.
void oj_dump_float(VALUE obj, int depth, Out out, bool as_ok) {
    char   buf[64];
    char  *b;
    double d   = rb_num2dbl(obj);
    int    cnt = 0;

    if (0.0 == d) {
        b    = buf;
        *b++ = '0';
        *b++ = '.';
        *b++ = '0';
        *b++ = '\0';
        cnt  = 3;
    } else if (OJ_INFINITY == d) {
        if (ObjectMode == out->opts->mode) {
            strcpy(buf, inf_val);
            cnt = sizeof(inf_val) - 1;
        } else {
            NanDump nd = out->opts->dump_opts.nan_dump;

            if (AutoNan == nd) {
                switch (out->opts->mode) {
                case CompatMode: nd = WordNan; break;
                case StrictMode: nd = RaiseNan; break;
                case NullMode: nd = NullNan; break;
                case CustomMode: nd = NullNan; break;
                default: break;
                }
            }
            switch (nd) {
            case RaiseNan: raise_strict(obj); break;
            case WordNan:
                strcpy(buf, "Infinity");
                cnt = 8;
                break;
            case NullNan:
                strcpy(buf, "null");
                cnt = 4;
                break;
            case HugeNan:
            default:
                strcpy(buf, inf_val);
                cnt = sizeof(inf_val) - 1;
                break;
            }
        }
    } else if (-OJ_INFINITY == d) {
        if (ObjectMode == out->opts->mode) {
            strcpy(buf, ninf_val);
            cnt = sizeof(ninf_val) - 1;
        } else {
            NanDump nd = out->opts->dump_opts.nan_dump;

            if (AutoNan == nd) {
                switch (out->opts->mode) {
                case CompatMode: nd = WordNan; break;
                case StrictMode: nd = RaiseNan; break;
                case NullMode: nd = NullNan; break;
                default: break;
                }
            }
            switch (nd) {
            case RaiseNan: raise_strict(obj); break;
            case WordNan:
                strcpy(buf, "-Infinity");
                cnt = 9;
                break;
            case NullNan:
                strcpy(buf, "null");
                cnt = 4;
                break;
            case HugeNan:
            default:
                strcpy(buf, ninf_val);
                cnt = sizeof(ninf_val) - 1;
                break;
            }
        }
    } else if (isnan(d)) {
        if (ObjectMode == out->opts->mode) {
            strcpy(buf, nan_val);
            cnt = sizeof(nan_val) - 1;
        } else {
            NanDump nd = out->opts->dump_opts.nan_dump;

            if (AutoNan == nd) {
                switch (out->opts->mode) {
                case ObjectMode: nd = HugeNan; break;
                case StrictMode: nd = RaiseNan; break;
                case NullMode: nd = NullNan; break;
                default: break;
                }
            }
            switch (nd) {
            case RaiseNan: raise_strict(obj); break;
            case WordNan:
                strcpy(buf, "NaN");
                cnt = 3;
                break;
            case NullNan:
                strcpy(buf, "null");
                cnt = 4;
                break;
            case HugeNan:
            default:
                strcpy(buf, nan_val);
                cnt = sizeof(nan_val) - 1;
                break;
            }
        }
    } else if (d == (double)(long long int)d) {
        cnt = snprintf(buf, sizeof(buf), "%.1f", d);
    } else if (0 == out->opts->float_prec) {
        volatile VALUE rstr = oj_safe_string_convert(obj);

        cnt = (int)RSTRING_LEN(rstr);
        if ((int)sizeof(buf) <= cnt) {
            cnt = sizeof(buf) - 1;
        }
        memcpy(buf, RSTRING_PTR(rstr), cnt);
        buf[cnt] = '\0';
    } else {
        cnt = oj_dump_float_printf(buf, sizeof(buf), obj, d, out->opts->float_fmt);
    }
    assure_size(out, cnt);
    APPEND_CHARS(out->cur, buf, cnt);
    *out->cur = '\0';
}

int oj_dump_float_printf(char *buf, size_t blen, VALUE obj, double d, const char *format) {
    int cnt = snprintf(buf, blen, format, d);

    // Round off issues at 16 significant digits so check for obvious ones of
    // 0001 and 9999.
    if (17 <= cnt && (0 == strcmp("0001", buf + cnt - 4) || 0 == strcmp("9999", buf + cnt - 4))) {
        volatile VALUE rstr = oj_safe_string_convert(obj);

        strcpy(buf, RSTRING_PTR(rstr));
        cnt = (int)RSTRING_LEN(rstr);
    }
    return cnt;
}
