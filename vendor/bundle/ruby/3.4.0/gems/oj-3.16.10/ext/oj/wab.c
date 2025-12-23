// Copyright (c) 2012 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "dump.h"
#include "encode.h"
#include "err.h"
#include "intern.h"
#include "oj.h"
#include "parse.h"
#include "trace.h"
#include "util.h"

// Workaround in case INFINITY is not defined in math.h or if the OS is CentOS
#define OJ_INFINITY (1.0 / 0.0)

static char hex_chars[256] = "\
................................\
................xxxxxxxxxx......\
.xxxxxx.........................\
.xxxxxx.........................\
................................\
................................\
................................\
................................";

static VALUE wab_uuid_clas = Qundef;
static VALUE uri_clas      = Qundef;
static VALUE uri_http_clas = Qundef;

///// dump functions /////

static VALUE resolve_wab_uuid_class(void) {
    if (Qundef == wab_uuid_clas) {
        volatile VALUE wab_module;

        wab_uuid_clas = Qnil;
        if (rb_const_defined_at(rb_cObject, rb_intern("WAB"))) {
            wab_module = rb_const_get_at(rb_cObject, rb_intern("WAB"));
            if (rb_const_defined_at(wab_module, rb_intern("UUID"))) {
                wab_uuid_clas = rb_const_get(wab_module, rb_intern("UUID"));
            }
        }
    }
    return wab_uuid_clas;
}

static VALUE resolve_uri_class(void) {
    if (Qundef == uri_clas) {
        uri_clas = Qnil;
        if (rb_const_defined_at(rb_cObject, rb_intern("URI"))) {
            uri_clas = rb_const_get_at(rb_cObject, rb_intern("URI"));
        }
    }
    return uri_clas;
}

static VALUE resolve_uri_http_class(void) {
    if (Qundef == uri_http_clas) {
        volatile VALUE uri_module;

        uri_http_clas = Qnil;
        if (rb_const_defined_at(rb_cObject, rb_intern("URI"))) {
            uri_module = rb_const_get_at(rb_cObject, rb_intern("URI"));
            if (rb_const_defined_at(uri_module, rb_intern("HTTP"))) {
                uri_http_clas = rb_const_get(uri_module, rb_intern("HTTP"));
            }
        }
    }
    return uri_http_clas;
}

static void raise_wab(VALUE obj) {
    rb_raise(rb_eTypeError, "Failed to dump %s Object to JSON in wab mode.\n", rb_class2name(rb_obj_class(obj)));
}

// Removed dependencies on math due to problems with CentOS 5.4.
static void dump_float(VALUE obj, int depth, Out out, bool as_ok) {
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
    } else {
        if (OJ_INFINITY == d || -OJ_INFINITY == d || isnan(d)) {
            raise_wab(obj);
        } else if (d == (double)(long long int)d) {
            cnt = snprintf(buf, sizeof(buf), "%.1f", d);
        } else {
            cnt = snprintf(buf, sizeof(buf), "%0.16g", d);
        }
    }
    assure_size(out, cnt);
    for (b = buf; '\0' != *b; b++) {
        *out->cur++ = *b;
    }
    *out->cur = '\0';
}

static void dump_array(VALUE a, int depth, Out out, bool as_ok) {
    size_t size;
    int    i, cnt;
    int    d2 = depth + 1;

    cnt         = (int)RARRAY_LEN(a);
    *out->cur++ = '[';
    size        = 2;
    assure_size(out, size);
    if (0 == cnt) {
        *out->cur++ = ']';
    } else {
        size = d2 * out->indent + 2;
        assure_size(out, size * cnt);
        cnt--;
        for (i = 0; i <= cnt; i++) {
            fill_indent(out, d2);
            oj_dump_wab_val(RARRAY_AREF(a, i), d2, out);
            if (i < cnt) {
                *out->cur++ = ',';
            }
        }
        size = depth * out->indent + 1;
        assure_size(out, size);
        fill_indent(out, depth);
        *out->cur++ = ']';
    }
    *out->cur = '\0';
}

static int hash_cb(VALUE key, VALUE value, VALUE ov) {
    Out  out   = (Out)ov;
    int  depth = out->depth;
    long size;
    int  rtype = rb_type(key);

    if (rtype != T_SYMBOL) {
        rb_raise(rb_eTypeError,
                 "In :wab mode all Hash keys must be Symbols, not %s.\n",
                 rb_class2name(rb_obj_class(key)));
    }
    size = depth * out->indent + 1;
    assure_size(out, size);
    fill_indent(out, depth);
    oj_dump_sym(key, 0, out, false);
    *out->cur++ = ':';
    oj_dump_wab_val(value, depth, out);
    out->depth  = depth;
    *out->cur++ = ',';

    return ST_CONTINUE;
}

static void dump_hash(VALUE obj, int depth, Out out, bool as_ok) {
    int    cnt;
    size_t size;

    cnt  = (int)RHASH_SIZE(obj);
    size = depth * out->indent + 2;
    assure_size(out, 2);
    *out->cur++ = '{';
    if (0 == cnt) {
        *out->cur++ = '}';
    } else {
        out->depth = depth + 1;
        rb_hash_foreach(obj, hash_cb, (VALUE)out);
        if (',' == *(out->cur - 1)) {
            out->cur--;  // backup to overwrite last comma
        }
        assure_size(out, size);
        fill_indent(out, depth);
        *out->cur++ = '}';
    }
    *out->cur = '\0';
}

static void dump_time(VALUE obj, Out out) {
    char             buf[64];
    struct _timeInfo ti;
    int              len;
    time_t           sec;
    long long        nsec;

    if (16 <= sizeof(struct timespec)) {
        struct timespec ts = rb_time_timespec(obj);

        sec  = ts.tv_sec;
        nsec = ts.tv_nsec;
    } else {
        sec  = NUM2LL(rb_funcall2(obj, oj_tv_sec_id, 0, 0));
        nsec = NUM2LL(rb_funcall2(obj, oj_tv_nsec_id, 0, 0));
    }

    assure_size(out, 36);
    // 2012-01-05T23:58:07.123456000Z
    sec_as_time(sec, &ti);

    len = sprintf(buf,
                  "%04d-%02d-%02dT%02d:%02d:%02d.%09ldZ",
                  ti.year,
                  ti.mon,
                  ti.day,
                  ti.hour,
                  ti.min,
                  ti.sec,
                  (long)nsec);
    oj_dump_cstr(buf, len, 0, 0, out);
}

static void dump_obj(VALUE obj, int depth, Out out, bool as_ok) {
    volatile VALUE clas = rb_obj_class(obj);

    if (rb_cTime == clas) {
        dump_time(obj, out);
    } else if (oj_bigdecimal_class == clas) {
        volatile VALUE rstr = oj_safe_string_convert(obj);

        oj_dump_raw(RSTRING_PTR(rstr), (int)RSTRING_LEN(rstr), out);
    } else if (resolve_wab_uuid_class() == clas) {
        oj_dump_str(oj_safe_string_convert(obj), depth, out, false);
    } else if (resolve_uri_http_class() == clas) {
        oj_dump_str(oj_safe_string_convert(obj), depth, out, false);
    } else {
        raise_wab(obj);
    }
}

static DumpFunc wab_funcs[] = {
    NULL,            // RUBY_T_NONE   = 0x00,
    dump_obj,        // RUBY_T_OBJECT = 0x01,
    NULL,            // RUBY_T_CLASS  = 0x02,
    NULL,            // RUBY_T_MODULE = 0x03,
    dump_float,      // RUBY_T_FLOAT  = 0x04,
    oj_dump_str,     // RUBY_T_STRING = 0x05,
    NULL,            // RUBY_T_REGEXP = 0x06,
    dump_array,      // RUBY_T_ARRAY  = 0x07,
    dump_hash,       // RUBY_T_HASH   = 0x08,
    NULL,            // RUBY_T_STRUCT = 0x09,
    oj_dump_bignum,  // RUBY_T_BIGNUM = 0x0a,
    NULL,            // RUBY_T_FILE   = 0x0b,
    dump_obj,        // RUBY_T_DATA   = 0x0c,
    NULL,            // RUBY_T_MATCH  = 0x0d,
    NULL,            // RUBY_T_COMPLEX  = 0x0e,
    NULL,            // RUBY_T_RATIONAL = 0x0f,
    NULL,            // 0x10
    oj_dump_nil,     // RUBY_T_NIL    = 0x11,
    oj_dump_true,    // RUBY_T_TRUE   = 0x12,
    oj_dump_false,   // RUBY_T_FALSE  = 0x13,
    oj_dump_sym,     // RUBY_T_SYMBOL = 0x14,
    oj_dump_fixnum,  // RUBY_T_FIXNUM = 0x15,
};

void oj_dump_wab_val(VALUE obj, int depth, Out out) {
    int type = rb_type(obj);

    TRACE(out->opts->trace, "dump", obj, depth, TraceIn);
    if (MAX_DEPTH < depth) {
        rb_raise(rb_eNoMemError, "Too deeply nested.\n");
    }
    if (0 < type && type <= RUBY_T_FIXNUM) {
        DumpFunc f = wab_funcs[type];

        if (NULL != f) {
            f(obj, depth, out, false);
            TRACE(out->opts->trace, "dump", obj, depth, TraceOut);
            return;
        }
    }
    raise_wab(obj);
}

///// load functions /////

static VALUE calc_hash_key(ParseInfo pi, Val parent) {
    volatile VALUE rkey = parent->key_val;

    if (Qundef != rkey) {
        rkey = oj_encode(rkey);
        rkey = rb_str_intern(rkey);

        return rkey;
    }
    if (Yes == pi->options.cache_keys) {
        rkey = oj_sym_intern(parent->key, parent->klen);
    } else {
#if HAVE_RB_ENC_INTERNED_STR
        rkey = rb_enc_interned_str(parent->key, parent->klen, oj_utf8_encoding);
#else
        rkey = rb_utf8_str_new(parent->key, parent->klen);
        rkey = rb_str_intern(rkey);
        OBJ_FREEZE(rkey);
#endif
    }
    return rkey;
}

static void hash_end(ParseInfo pi) {
    TRACE_PARSE_HASH_END(pi->options.trace, pi);
}

static void array_end(ParseInfo pi) {
    TRACE_PARSE_ARRAY_END(pi->options.trace, pi);
}

static VALUE noop_hash_key(ParseInfo pi, const char *key, size_t klen) {
    return Qundef;
}

static void add_value(ParseInfo pi, VALUE val) {
    TRACE_PARSE_CALL(pi->options.trace, "add_value", pi, val);
    pi->stack.head->val = val;
}

// 123e4567-e89b-12d3-a456-426655440000
static bool uuid_check(const char *str, int len) {
    int i;

    for (i = 0; i < 8; i++, str++) {
        if ('x' != hex_chars[*(uint8_t *)str]) {
            return false;
        }
    }
    str++;
    for (i = 0; i < 4; i++, str++) {
        if ('x' != hex_chars[*(uint8_t *)str]) {
            return false;
        }
    }
    str++;
    for (i = 0; i < 4; i++, str++) {
        if ('x' != hex_chars[*(uint8_t *)str]) {
            return false;
        }
    }
    str++;
    for (i = 0; i < 4; i++, str++) {
        if ('x' != hex_chars[*(uint8_t *)str]) {
            return false;
        }
    }
    str++;
    for (i = 0; i < 12; i++, str++) {
        if ('x' != hex_chars[*(uint8_t *)str]) {
            return false;
        }
    }
    return true;
}

static const char *read_num(const char *s, int len, int *vp) {
    uint32_t v = 0;

    for (; 0 < len; len--, s++) {
        if ('0' <= *s && *s <= '9') {
            v = v * 10 + *s - '0';
        } else {
            return NULL;
        }
    }
    *vp = (int)v;

    return s;
}

static VALUE time_parse(const char *s, int len) {
    struct tm tm;
    bool      neg   = false;
    long      nsecs = 0;
    int       i;
    time_t    secs;

    memset(&tm, 0, sizeof(tm));
    if ('-' == *s) {
        s++;
        neg = true;
    }
    if (NULL == (s = read_num(s, 4, &tm.tm_year))) {
        return Qnil;
    }
    if (neg) {
        tm.tm_year = -tm.tm_year;
        neg        = false;
    }
    tm.tm_year -= 1900;
    s++;
    if (NULL == (s = read_num(s, 2, &tm.tm_mon))) {
        return Qnil;
    }
    tm.tm_mon--;
    s++;
    if (NULL == (s = read_num(s, 2, &tm.tm_mday))) {
        return Qnil;
    }
    s++;
    if (NULL == (s = read_num(s, 2, &tm.tm_hour))) {
        return Qnil;
    }
    s++;
    if (NULL == (s = read_num(s, 2, &tm.tm_min))) {
        return Qnil;
    }
    s++;
    if (NULL == (s = read_num(s, 2, &tm.tm_sec))) {
        return Qnil;
    }
    s++;

    for (i = 9; 0 < i; i--, s++) {
        if ('0' <= *s && *s <= '9') {
            nsecs = nsecs * 10 + *s - '0';
        } else {
            return Qnil;
        }
    }
#if IS_WINDOWS
    secs = (time_t)mktime(&tm);
    memset(&tm, 0, sizeof(tm));
    tm.tm_year = 70;
    tm.tm_mday = 1;
    secs -= (time_t)mktime(&tm);
#else
    secs = (time_t)timegm(&tm);
#endif
    return rb_funcall(rb_time_nano_new(secs, nsecs), oj_utc_id, 0);
}

static VALUE protect_uri(VALUE rstr) {
    return rb_funcall(resolve_uri_class(), oj_parse_id, 1, rstr);
}

static VALUE cstr_to_rstr(ParseInfo pi, const char *str, size_t len) {
    volatile VALUE v = Qnil;

    if (30 == len && '-' == str[4] && '-' == str[7] && 'T' == str[10] && ':' == str[13] && ':' == str[16] &&
        '.' == str[19] && 'Z' == str[29]) {
        if (Qnil != (v = time_parse(str, (int)len))) {
            return v;
        }
    }
    if (36 == len && '-' == str[8] && '-' == str[13] && '-' == str[18] && '-' == str[23] && uuid_check(str, (int)len) &&
        Qnil != resolve_wab_uuid_class()) {
        return rb_funcall(wab_uuid_clas, oj_new_id, 1, rb_str_new(str, len));
    }
    if (7 < len && 0 == strncasecmp("http://", str, 7)) {
        int err            = 0;
        v                  = rb_str_new(str, len);
        volatile VALUE uri = rb_protect(protect_uri, v, &err);

        if (0 == err) {
            return uri;
        }
    }
    return oj_cstr_to_value(str, len, (size_t)pi->options.cache_str);
}

static void add_cstr(ParseInfo pi, const char *str, size_t len, const char *orig) {
    pi->stack.head->val = cstr_to_rstr(pi, str, len);
    TRACE_PARSE_CALL(pi->options.trace, "add_string", pi, pi->stack.head->val);
}

static void add_num(ParseInfo pi, NumInfo ni) {
    if (ni->infinity || ni->nan) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
    }
    pi->stack.head->val = oj_num_as_value(ni);
    TRACE_PARSE_CALL(pi->options.trace, "add_number", pi, pi->stack.head->val);
}

static VALUE start_hash(ParseInfo pi) {
    TRACE_PARSE_IN(pi->options.trace, "start_hash", pi);
    if (Qnil != pi->options.hash_class) {
        return rb_class_new_instance(0, NULL, pi->options.hash_class);
    }
    return rb_hash_new();
}

static void hash_set_cstr(ParseInfo pi, Val parent, const char *str, size_t len, const char *orig) {
    volatile VALUE rval = cstr_to_rstr(pi, str, len);

    rb_hash_aset(stack_peek(&pi->stack)->val, calc_hash_key(pi, parent), rval);
    TRACE_PARSE_CALL(pi->options.trace, "set_string", pi, rval);
}

static void hash_set_num(ParseInfo pi, Val parent, NumInfo ni) {
    volatile VALUE rval = Qnil;

    if (ni->infinity || ni->nan) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
    }
    rval = oj_num_as_value(ni);
    rb_hash_aset(stack_peek(&pi->stack)->val, calc_hash_key(pi, parent), rval);
    TRACE_PARSE_CALL(pi->options.trace, "set_number", pi, rval);
}

static void hash_set_value(ParseInfo pi, Val parent, VALUE value) {
    rb_hash_aset(stack_peek(&pi->stack)->val, calc_hash_key(pi, parent), value);
    TRACE_PARSE_CALL(pi->options.trace, "set_value", pi, value);
}

static VALUE start_array(ParseInfo pi) {
    TRACE_PARSE_IN(pi->options.trace, "start_array", pi);
    return rb_ary_new();
}

static void array_append_cstr(ParseInfo pi, const char *str, size_t len, const char *orig) {
    volatile VALUE rval = cstr_to_rstr(pi, str, len);

    rb_ary_push(stack_peek(&pi->stack)->val, rval);
    TRACE_PARSE_CALL(pi->options.trace, "set_value", pi, rval);
}

static void array_append_num(ParseInfo pi, NumInfo ni) {
    volatile VALUE rval = Qnil;

    if (ni->infinity || ni->nan) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
    }
    rval = oj_num_as_value(ni);
    rb_ary_push(stack_peek(&pi->stack)->val, rval);
    TRACE_PARSE_CALL(pi->options.trace, "append_number", pi, rval);
}

static void array_append_value(ParseInfo pi, VALUE value) {
    rb_ary_push(stack_peek(&pi->stack)->val, value);
    TRACE_PARSE_CALL(pi->options.trace, "append_value", pi, value);
}

void oj_set_wab_callbacks(ParseInfo pi) {
    pi->start_hash         = start_hash;
    pi->end_hash           = hash_end;
    pi->hash_key           = noop_hash_key;
    pi->hash_set_cstr      = hash_set_cstr;
    pi->hash_set_num       = hash_set_num;
    pi->hash_set_value     = hash_set_value;
    pi->start_array        = start_array;
    pi->end_array          = array_end;
    pi->array_append_cstr  = array_append_cstr;
    pi->array_append_num   = array_append_num;
    pi->array_append_value = array_append_value;
    pi->add_cstr           = add_cstr;
    pi->add_num            = add_num;
    pi->add_value          = add_value;
    pi->expect_value       = 1;
}

VALUE
oj_wab_parse(int argc, VALUE *argv, VALUE self) {
    struct _parseInfo pi;

    parse_info_init(&pi);
    pi.options   = oj_default_options;
    pi.handler   = Qnil;
    pi.err_class = Qnil;
    oj_set_wab_callbacks(&pi);

    if (T_STRING == rb_type(*argv)) {
        return oj_pi_parse(argc, argv, &pi, 0, 0, true);
    } else {
        return oj_pi_sparse(argc, argv, &pi, 0);
    }
}

VALUE
oj_wab_parse_cstr(int argc, VALUE *argv, char *json, size_t len) {
    struct _parseInfo pi;

    parse_info_init(&pi);
    pi.options   = oj_default_options;
    pi.handler   = Qnil;
    pi.err_class = Qnil;
    oj_set_wab_callbacks(&pi);

    return oj_pi_parse(argc, argv, &pi, json, len, true);
}
