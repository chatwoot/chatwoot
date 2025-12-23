// Copyright (c) 2012 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "encode.h"
#include "err.h"
#include "intern.h"
#include "oj.h"
#include "parse.h"
#include "trace.h"

VALUE oj_cstr_to_value(const char *str, size_t len, size_t cache_str) {
    volatile VALUE rstr = Qnil;

    if (len < cache_str) {
        rstr = oj_str_intern(str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    return rstr;
}

VALUE oj_calc_hash_key(ParseInfo pi, Val parent) {
    volatile VALUE rkey = parent->key_val;

    if (Qundef != rkey) {
        return rkey;
    }
    if (Yes != pi->options.cache_keys) {
        if (Yes == pi->options.sym_key) {
            rkey = ID2SYM(rb_intern3(parent->key, parent->klen, oj_utf8_encoding));
        } else {
            rkey = rb_utf8_str_new(parent->key, parent->klen);
            OBJ_FREEZE(rkey);  // frozen when used as a Hash key anyway
        }
        return rkey;
    }
    if (Yes == pi->options.sym_key) {
        rkey = oj_sym_intern(parent->key, parent->klen);
    } else {
        rkey = oj_str_intern(parent->key, parent->klen);
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

static void add_cstr(ParseInfo pi, const char *str, size_t len, const char *orig) {
    volatile VALUE rstr = oj_cstr_to_value(str, len, (size_t)pi->options.cache_str);

    pi->stack.head->val = rstr;
    TRACE_PARSE_CALL(pi->options.trace, "add_string", pi, rstr);
}

static void add_num(ParseInfo pi, NumInfo ni) {
    if (ni->infinity || ni->nan) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
    }
    pi->stack.head->val = oj_num_as_value(ni);
    TRACE_PARSE_CALL(pi->options.trace, "add_number", pi, pi->stack.head->val);
}

static VALUE start_hash(ParseInfo pi) {
    if (Qnil != pi->options.hash_class) {
        return rb_class_new_instance(0, NULL, pi->options.hash_class);
    }
    TRACE_PARSE_IN(pi->options.trace, "start_hash", pi);
    return rb_hash_new();
}

static void hash_set_cstr(ParseInfo pi, Val parent, const char *str, size_t len, const char *orig) {
    volatile VALUE rstr = oj_cstr_to_value(str, len, (size_t)pi->options.cache_str);

    rb_hash_aset(stack_peek(&pi->stack)->val, oj_calc_hash_key(pi, parent), rstr);
    TRACE_PARSE_CALL(pi->options.trace, "set_string", pi, rstr);
}

static void hash_set_num(ParseInfo pi, Val parent, NumInfo ni) {
    volatile VALUE v;

    if (ni->infinity || ni->nan) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
    }
    v = oj_num_as_value(ni);
    rb_hash_aset(stack_peek(&pi->stack)->val, oj_calc_hash_key(pi, parent), v);
    TRACE_PARSE_CALL(pi->options.trace, "set_number", pi, v);
}

static void hash_set_value(ParseInfo pi, Val parent, VALUE value) {
    rb_hash_aset(stack_peek(&pi->stack)->val, oj_calc_hash_key(pi, parent), value);
    TRACE_PARSE_CALL(pi->options.trace, "set_value", pi, value);
}

static VALUE start_array(ParseInfo pi) {
    TRACE_PARSE_IN(pi->options.trace, "start_array", pi);
    return rb_ary_new();
}

static void array_append_cstr(ParseInfo pi, const char *str, size_t len, const char *orig) {
    volatile VALUE rstr = oj_cstr_to_value(str, len, (size_t)pi->options.cache_str);

    rb_ary_push(stack_peek(&pi->stack)->val, rstr);
    TRACE_PARSE_CALL(pi->options.trace, "append_string", pi, rstr);
}

static void array_append_num(ParseInfo pi, NumInfo ni) {
    volatile VALUE v;

    if (ni->infinity || ni->nan) {
        oj_set_error_at(pi, oj_parse_error_class, __FILE__, __LINE__, "not a number or other value");
    }
    v = oj_num_as_value(ni);
    rb_ary_push(stack_peek(&pi->stack)->val, v);
    TRACE_PARSE_CALL(pi->options.trace, "append_number", pi, v);
}

static void array_append_value(ParseInfo pi, VALUE value) {
    rb_ary_push(stack_peek(&pi->stack)->val, value);
    TRACE_PARSE_CALL(pi->options.trace, "append_value", pi, value);
}

void oj_set_strict_callbacks(ParseInfo pi) {
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
oj_strict_parse(int argc, VALUE *argv, VALUE self) {
    struct _parseInfo pi;

    parse_info_init(&pi);
    pi.options   = oj_default_options;
    pi.handler   = Qnil;
    pi.err_class = Qnil;
    oj_set_strict_callbacks(&pi);

    if (T_STRING == rb_type(*argv)) {
        return oj_pi_parse(argc, argv, &pi, 0, 0, true);
    } else {
        return oj_pi_sparse(argc, argv, &pi, 0);
    }
}

VALUE
oj_strict_parse_cstr(int argc, VALUE *argv, char *json, size_t len) {
    struct _parseInfo pi;

    parse_info_init(&pi);
    pi.options   = oj_default_options;
    pi.handler   = Qnil;
    pi.err_class = Qnil;
    oj_set_strict_callbacks(&pi);

    return oj_pi_parse(argc, argv, &pi, json, len, true);
}
