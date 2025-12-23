// Copyright (c) 2021, Peter Ohler, All rights reserved.

#include "parser.h"

static void noop(ojParser p) {
}

static VALUE option(ojParser p, const char *key, VALUE value) {
    rb_raise(rb_eArgError, "%s is not an option for the validate delegate", key);
    return Qnil;
}

static VALUE result(ojParser p) {
    return Qnil;
}

static void dfree(ojParser p) {
}

static void mark(ojParser p) {
}

void oj_set_parser_validator(ojParser p) {
    Funcs end = p->funcs + 3;
    Funcs f;
    p->ctx = NULL;

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
    p->option = option;
    p->result = result;
    p->free   = dfree;
    p->mark   = mark;
    p->start  = noop;
}
