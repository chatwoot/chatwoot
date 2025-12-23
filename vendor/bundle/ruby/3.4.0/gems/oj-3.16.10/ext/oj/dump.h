// Copyright (c) 2011 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_DUMP_H
#define OJ_DUMP_H

#include <ruby.h>

#include "oj.h"

#define MAX_DEPTH 1000

// Extra padding at end of buffer.
#define BUFFER_EXTRA 64

extern void oj_dump_nil(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_true(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_false(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_fixnum(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_bignum(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_float(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_str(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_sym(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_class(VALUE obj, int depth, Out out, bool as_ok);

extern void oj_dump_raw(const char *str, size_t cnt, Out out);
extern void oj_dump_cstr(const char *str, size_t cnt, bool is_sym, bool escape1, Out out);
extern void oj_dump_ruby_time(VALUE obj, Out out);
extern void oj_dump_xml_time(VALUE obj, Out out);
extern void oj_dump_time(VALUE obj, Out out, int withZone);
extern void oj_dump_obj_to_s(VALUE obj, Out out);

extern const char *oj_nan_str(VALUE obj, int opt, int mode, bool plus, int *lenp);

// initialize an out buffer with the provided stack allocated memory
extern void oj_out_init(Out out);
// clean up the out buffer if it uses heap allocated memory
extern void oj_out_free(Out out);

extern void oj_grow_out(Out out, size_t len);
extern long oj_check_circular(VALUE obj, Out out);

extern void oj_dump_strict_val(VALUE obj, int depth, Out out);
extern void oj_dump_null_val(VALUE obj, int depth, Out out);
extern void oj_dump_obj_val(VALUE obj, int depth, Out out);
extern void oj_dump_compat_val(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_rails_val(VALUE obj, int depth, Out out);
extern void oj_dump_custom_val(VALUE obj, int depth, Out out, bool as_ok);
extern void oj_dump_wab_val(VALUE obj, int depth, Out out);

extern void oj_dump_raw_json(VALUE obj, int depth, Out out);

extern VALUE oj_add_to_json(int argc, VALUE *argv, VALUE self);
extern VALUE oj_remove_to_json(int argc, VALUE *argv, VALUE self);

extern int oj_dump_float_printf(char *buf, size_t blen, VALUE obj, double d, const char *format);

extern time_t oj_sec_from_time_hard_way(VALUE obj);

inline static void assure_size(Out out, size_t len) {
    if (out->end - out->cur <= (long)len) {
        oj_grow_out(out, len);
    }
}

inline static void fill_indent(Out out, int cnt) {
    if (0 < out->indent) {
        cnt *= out->indent;
        *out->cur++ = '\n';
        memset(out->cur, ' ', cnt);
        out->cur += cnt;
    }
}

inline static bool dump_ignore(Options opts, VALUE obj) {
    if (NULL != opts->ignore && (ObjectMode == opts->mode || CustomMode == opts->mode)) {
        VALUE *vp   = opts->ignore;
        VALUE  clas = rb_obj_class(obj);

        for (; Qnil != *vp; vp++) {
            if (clas == *vp) {
                return true;
            }
        }
    }
    return false;
}

inline static void dump_ulong(unsigned long num, Out out) {
    char   buf[32];
    char  *b   = buf + sizeof(buf) - 1;
    size_t cnt = 0;

    *b-- = '\0';
    if (0 < num) {
        b = oj_longlong_to_string((long long)num, false, b);
    } else {
        *b = '0';
    }
    cnt = sizeof(buf) - (b - buf) - 1;
    APPEND_CHARS(out->cur, b, cnt);
    *out->cur = '\0';
}

#endif /* OJ_DUMP_H */
