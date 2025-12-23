// Copyright (c) 2021, Peter Ohler, All rights reserved.

#include "saj2.h"

#include "cache.h"
#include "mem.h"
#include "oj.h"
#include "parser.h"

static VALUE get_key(ojParser p) {
    Saj            d   = (Saj)p->ctx;
    const char    *key = buf_str(&p->key);
    size_t         len = buf_len(&p->key);
    volatile VALUE rkey;

    if (d->cache_keys) {
        rkey = cache_intern(d->str_cache, key, len);
    } else {
        rkey = rb_utf8_str_new(key, len);
    }
    return rkey;
}

static void push_key(Saj d, VALUE key) {
    if (d->klen <= (size_t)(d->tail - d->keys)) {
        size_t off = d->tail - d->keys;

        d->klen += d->klen / 2;
        OJ_R_REALLOC_N(d->keys, VALUE, d->klen);
        d->tail = d->keys + off;
    }
    *d->tail = key;
    d->tail++;
}

static void noop(ojParser p) {
}

static void open_object(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_hash_start_id, 1, Qnil);
}

static void open_object_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_hash_start_id, 3, Qnil, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void open_object_key(ojParser p) {
    Saj            d   = (Saj)p->ctx;
    volatile VALUE key = get_key(p);

    push_key(d, key);
    rb_funcall(d->handler, oj_hash_start_id, 1, key);
}

static void open_object_loc_key(ojParser p) {
    Saj            d   = (Saj)p->ctx;
    volatile VALUE key = get_key(p);

    push_key(d, key);
    rb_funcall(d->handler, oj_hash_start_id, 3, key, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void open_array(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_array_start_id, 1, Qnil);
}

static void open_array_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_array_start_id, 3, Qnil, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void open_array_key(ojParser p) {
    Saj            d   = (Saj)p->ctx;
    volatile VALUE key = get_key(p);

    push_key(d, key);
    rb_funcall(d->handler, oj_array_start_id, 1, key);
}

static void open_array_loc_key(ojParser p) {
    Saj            d   = (Saj)p->ctx;
    volatile VALUE key = get_key(p);

    push_key(d, key);
    rb_funcall(d->handler, oj_array_start_id, 3, key, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void close_object(ojParser p) {
    Saj   d   = (Saj)p->ctx;
    VALUE key = Qnil;

    if (OBJECT_FUN == p->stack[p->depth]) {
        d->tail--;
        if (d->tail < d->keys) {
            rb_raise(rb_eIndexError, "accessing key stack");
        }
        key = *d->tail;
    }
    rb_funcall(d->handler, oj_hash_end_id, 1, key);
}

static void close_object_loc(ojParser p) {
    Saj   d   = (Saj)p->ctx;
    VALUE key = Qnil;

    if (OBJECT_FUN == p->stack[p->depth]) {
        d->tail--;
        if (d->tail < d->keys) {
            rb_raise(rb_eIndexError, "accessing key stack");
        }
        key = *d->tail;
    }
    rb_funcall(d->handler, oj_hash_end_id, 3, key, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void close_array(ojParser p) {
    Saj   d   = (Saj)p->ctx;
    VALUE key = Qnil;

    if (OBJECT_FUN == p->stack[p->depth]) {
        d->tail--;
        if (d->tail < d->keys) {
            rb_raise(rb_eIndexError, "accessing key stack");
        }
        key = *d->tail;
    }
    rb_funcall(d->handler, oj_array_end_id, 1, key);
}

static void close_array_loc(ojParser p) {
    Saj   d   = (Saj)p->ctx;
    VALUE key = Qnil;

    if (OBJECT_FUN == p->stack[p->depth]) {
        d->tail--;
        if (d->tail < d->keys) {
            rb_raise(rb_eIndexError, "accessing key stack");
        }
        key = *d->tail;
    }
    rb_funcall(d->handler, oj_array_end_id, 3, key, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void add_null(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, Qnil, Qnil);
}

static void add_null_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 4, Qnil, Qnil, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void add_null_key(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, Qnil, get_key(p));
}

static void add_null_key_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               Qnil,
               get_key(p),
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_true(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, Qtrue, Qnil);
}

static void add_true_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 4, Qtrue, Qnil, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void add_true_key(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, Qtrue, get_key(p));
}

static void add_true_key_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               Qtrue,
               get_key(p),
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_false(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, Qfalse, Qnil);
}

static void add_false_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 4, Qfalse, Qnil, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void add_false_key(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, Qfalse, get_key(p));
}

static void add_false_key_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               Qfalse,
               get_key(p),
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_int(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, LONG2NUM(p->num.fixnum), Qnil);
}

static void add_int_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               LONG2NUM(p->num.fixnum),
               Qnil,
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_int_key(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, LONG2NUM(p->num.fixnum), get_key(p));
}

static void add_int_key_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               LONG2NUM(p->num.fixnum),
               get_key(p),
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_float(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, rb_float_new(p->num.dub), Qnil);
}

static void add_float_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               rb_float_new(p->num.dub),
               Qnil,
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_float_key(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler, oj_add_value_id, 2, rb_float_new(p->num.dub), get_key(p));
}

static void add_float_key_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               rb_float_new(p->num.dub),
               get_key(p),
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_big(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               2,
               rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf))),
               Qnil);
}

static void add_big_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf))),
               Qnil,
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_big_key(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               2,
               rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf))),
               get_key(p));
}

static void add_big_key_loc(ojParser p) {
    rb_funcall(((Saj)p->ctx)->handler,
               oj_add_value_id,
               4,
               rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf))),
               get_key(p),
               LONG2FIX(p->line),
               LONG2FIX(p->cur - p->col));
}

static void add_str(ojParser p) {
    Saj            d = (Saj)p->ctx;
    volatile VALUE rstr;
    const char    *str = buf_str(&p->buf);
    size_t         len = buf_len(&p->buf);

    if (d->cache_str < len) {
        rstr = cache_intern(d->str_cache, str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    rb_funcall(d->handler, oj_add_value_id, 2, rstr, Qnil);
}

static void add_str_loc(ojParser p) {
    Saj            d = (Saj)p->ctx;
    volatile VALUE rstr;
    const char    *str = buf_str(&p->buf);
    size_t         len = buf_len(&p->buf);

    if (d->cache_str < len) {
        rstr = cache_intern(d->str_cache, str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    rb_funcall(d->handler, oj_add_value_id, 4, rstr, Qnil, LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void add_str_key(ojParser p) {
    Saj            d = (Saj)p->ctx;
    volatile VALUE rstr;
    const char    *str = buf_str(&p->buf);
    size_t         len = buf_len(&p->buf);

    if (d->cache_str < len) {
        rstr = cache_intern(d->str_cache, str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    rb_funcall(d->handler, oj_add_value_id, 2, rstr, get_key(p));
}

static void add_str_key_loc(ojParser p) {
    Saj            d = (Saj)p->ctx;
    volatile VALUE rstr;
    const char    *str = buf_str(&p->buf);
    size_t         len = buf_len(&p->buf);

    if (d->cache_str < len) {
        rstr = cache_intern(d->str_cache, str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    rb_funcall(d->handler, oj_add_value_id, 4, rstr, get_key(p), LONG2FIX(p->line), LONG2FIX(p->cur - p->col));
}

static void reset(ojParser p) {
    Funcs end = p->funcs + 3;
    Funcs f;

    for (f = p->funcs; f < end; f++) {
        f->add_null     = noop;
        f->add_true     = noop;
        f->add_false    = noop;
        f->add_int      = noop;
        f->add_float    = noop;
        f->add_big      = noop;
        f->add_str      = noop;
        f->open_array   = noop;
        f->close_array  = noop;
        f->open_object  = noop;
        f->close_object = noop;
    }
}

static VALUE option(ojParser p, const char *key, VALUE value) {
    Saj d = (Saj)p->ctx;

    if (0 == strcmp(key, "handler")) {
        return d->handler;
    }
    if (0 == strcmp(key, "handler=")) {
        d->tail    = d->keys;
        d->handler = value;
        reset(p);
        if (rb_respond_to(value, oj_hash_start_id)) {
            if (1 == rb_obj_method_arity(value, oj_hash_start_id)) {
                p->funcs[TOP_FUN].open_object    = open_object;
                p->funcs[ARRAY_FUN].open_object  = open_object;
                p->funcs[OBJECT_FUN].open_object = open_object_key;
            } else {
                p->funcs[TOP_FUN].open_object    = open_object_loc;
                p->funcs[ARRAY_FUN].open_object  = open_object_loc;
                p->funcs[OBJECT_FUN].open_object = open_object_loc_key;
            }
        }
        if (rb_respond_to(value, oj_array_start_id)) {
            if (1 == rb_obj_method_arity(value, oj_array_start_id)) {
                p->funcs[TOP_FUN].open_array    = open_array;
                p->funcs[ARRAY_FUN].open_array  = open_array;
                p->funcs[OBJECT_FUN].open_array = open_array_key;
            } else {
                p->funcs[TOP_FUN].open_array    = open_array_loc;
                p->funcs[ARRAY_FUN].open_array  = open_array_loc;
                p->funcs[OBJECT_FUN].open_array = open_array_loc_key;
            }
        }
        if (rb_respond_to(value, oj_hash_end_id)) {
            if (1 == rb_obj_method_arity(value, oj_hash_end_id)) {
                p->funcs[TOP_FUN].close_object    = close_object;
                p->funcs[ARRAY_FUN].close_object  = close_object;
                p->funcs[OBJECT_FUN].close_object = close_object;
            } else {
                p->funcs[TOP_FUN].close_object    = close_object_loc;
                p->funcs[ARRAY_FUN].close_object  = close_object_loc;
                p->funcs[OBJECT_FUN].close_object = close_object_loc;
            }
        }
        if (rb_respond_to(value, oj_array_end_id)) {
            if (1 == rb_obj_method_arity(value, oj_array_end_id)) {
                p->funcs[TOP_FUN].close_array    = close_array;
                p->funcs[ARRAY_FUN].close_array  = close_array;
                p->funcs[OBJECT_FUN].close_array = close_array;
            } else {
                p->funcs[TOP_FUN].close_array    = close_array_loc;
                p->funcs[ARRAY_FUN].close_array  = close_array_loc;
                p->funcs[OBJECT_FUN].close_array = close_array_loc;
            }
        }
        if (rb_respond_to(value, oj_add_value_id)) {
            if (2 == rb_obj_method_arity(value, oj_add_value_id)) {
                p->funcs[TOP_FUN].add_null    = add_null;
                p->funcs[ARRAY_FUN].add_null  = add_null;
                p->funcs[OBJECT_FUN].add_null = add_null_key;

                p->funcs[TOP_FUN].add_true    = add_true;
                p->funcs[ARRAY_FUN].add_true  = add_true;
                p->funcs[OBJECT_FUN].add_true = add_true_key;

                p->funcs[TOP_FUN].add_false    = add_false;
                p->funcs[ARRAY_FUN].add_false  = add_false;
                p->funcs[OBJECT_FUN].add_false = add_false_key;

                p->funcs[TOP_FUN].add_int    = add_int;
                p->funcs[ARRAY_FUN].add_int  = add_int;
                p->funcs[OBJECT_FUN].add_int = add_int_key;

                p->funcs[TOP_FUN].add_float    = add_float;
                p->funcs[ARRAY_FUN].add_float  = add_float;
                p->funcs[OBJECT_FUN].add_float = add_float_key;

                p->funcs[TOP_FUN].add_big    = add_big;
                p->funcs[ARRAY_FUN].add_big  = add_big;
                p->funcs[OBJECT_FUN].add_big = add_big_key;

                p->funcs[TOP_FUN].add_str    = add_str;
                p->funcs[ARRAY_FUN].add_str  = add_str;
                p->funcs[OBJECT_FUN].add_str = add_str_key;
            } else {
                p->funcs[TOP_FUN].add_null    = add_null_loc;
                p->funcs[ARRAY_FUN].add_null  = add_null_loc;
                p->funcs[OBJECT_FUN].add_null = add_null_key_loc;

                p->funcs[TOP_FUN].add_true    = add_true_loc;
                p->funcs[ARRAY_FUN].add_true  = add_true_loc;
                p->funcs[OBJECT_FUN].add_true = add_true_key_loc;

                p->funcs[TOP_FUN].add_false    = add_false_loc;
                p->funcs[ARRAY_FUN].add_false  = add_false_loc;
                p->funcs[OBJECT_FUN].add_false = add_false_key_loc;

                p->funcs[TOP_FUN].add_int    = add_int_loc;
                p->funcs[ARRAY_FUN].add_int  = add_int_loc;
                p->funcs[OBJECT_FUN].add_int = add_int_key_loc;

                p->funcs[TOP_FUN].add_float    = add_float_loc;
                p->funcs[ARRAY_FUN].add_float  = add_float_loc;
                p->funcs[OBJECT_FUN].add_float = add_float_key_loc;

                p->funcs[TOP_FUN].add_big    = add_big_loc;
                p->funcs[ARRAY_FUN].add_big  = add_big_loc;
                p->funcs[OBJECT_FUN].add_big = add_big_key_loc;

                p->funcs[TOP_FUN].add_str    = add_str_loc;
                p->funcs[ARRAY_FUN].add_str  = add_str_loc;
                p->funcs[OBJECT_FUN].add_str = add_str_key_loc;
            }
        }
        return Qnil;
    }
    if (0 == strcmp(key, "cache_keys")) {
        return d->cache_keys ? Qtrue : Qfalse;
    }
    if (0 == strcmp(key, "cache_keys=")) {
        d->cache_keys = (Qtrue == value);

        return d->cache_keys ? Qtrue : Qfalse;
    }
    if (0 == strcmp(key, "cache_strings")) {
        return INT2NUM((int)d->cache_str);
    }
    if (0 == strcmp(key, "cache_strings=")) {
        int limit = NUM2INT(value);

        if (CACHE_MAX_KEY < limit) {
            limit = CACHE_MAX_KEY;
        } else if (limit < 0) {
            limit = 0;
        }
        d->cache_str = limit;

        return INT2NUM((int)d->cache_str);
    }
    rb_raise(rb_eArgError, "%s is not an option for the SAJ (Simple API for JSON) saj", key);

    return Qnil;  // Never reached due to the raise but required by the compiler.
}

static VALUE result(ojParser p) {
    return Qnil;
}

static void start(ojParser p) {
    Saj d = (Saj)p->ctx;

    d->tail = d->keys;
}

static void dfree(ojParser p) {
    Saj d = (Saj)p->ctx;

    if (NULL != d->keys) {
        OJ_R_FREE(d->keys);
    }
    cache_free(d->str_cache);
    OJ_R_FREE(p->ctx);
}

static void mark(ojParser p) {
    if (NULL == p || NULL == p->ctx) {
        return;
    }
    Saj    d = (Saj)p->ctx;
    VALUE *kp;

    cache_mark(d->str_cache);
    if (Qnil != d->handler) {
        rb_gc_mark(d->handler);
    }
    if (!d->cache_keys) {
        for (kp = d->keys; kp < d->tail; kp++) {
            rb_gc_mark(*kp);
        }
    }
}

static VALUE form_str(const char *str, size_t len) {
    return rb_str_freeze(rb_utf8_str_new(str, len));
}

void oj_init_saj(ojParser p, Saj d) {
    d->klen        = 256;
    d->keys        = OJ_R_ALLOC_N(VALUE, d->klen);
    d->tail        = d->keys;
    d->handler     = Qnil;
    d->str_cache   = cache_create(0, form_str, true, false);
    d->cache_str   = 16;
    d->cache_keys  = true;
    d->thread_safe = false;

    p->ctx = (void *)d;
    reset(p);
    p->option = option;
    p->result = result;
    p->free   = dfree;
    p->mark   = mark;
    p->start  = start;
}

void oj_set_parser_saj(ojParser p) {
    Saj d = OJ_R_ALLOC(struct _saj);

    oj_init_saj(p, d);
}
