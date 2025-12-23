// Copyright (c) 2021, Peter Ohler, All rights reserved.

#include "parser.h"

static void add_null(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** add_null at top\n"); break;
    case ARRAY_FUN: printf("*** add_null to array\n"); break;
    case OBJECT_FUN: printf("*** add_null with '%s'\n", buf_str(&p->key)); break;
    }
}

static void add_true(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** add_true at top\n"); break;
    case ARRAY_FUN: printf("*** add_true to array\n"); break;
    case OBJECT_FUN: printf("*** add_true with '%s'\n", buf_str(&p->key)); break;
    }
}

static void add_false(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** add_false at top\n"); break;
    case ARRAY_FUN: printf("*** add_false to array\n"); break;
    case OBJECT_FUN: printf("*** add_false with '%s'\n", buf_str(&p->key)); break;
    }
}

static void add_int(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** add_int %lld at top\n", (long long)p->num.fixnum); break;
    case ARRAY_FUN: printf("*** add_int %lld to array\n", (long long)p->num.fixnum); break;
    case OBJECT_FUN: printf("*** add_int %lld with '%s'\n", (long long)p->num.fixnum, buf_str(&p->key)); break;
    }
}

static void add_float(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** add_float %Lf at top\n", p->num.dub); break;
    case ARRAY_FUN: printf("*** add_float %Lf to array\n", p->num.dub); break;
    case OBJECT_FUN: printf("*** add_float %Lf with '%s'\n", p->num.dub, buf_str(&p->key)); break;
    }
}

static void add_big(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** add_big %s at top\n", buf_str(&p->buf)); break;
    case ARRAY_FUN: printf("*** add_big %s to array\n", buf_str(&p->buf)); break;
    case OBJECT_FUN: printf("*** add_big %s with '%s'\n", buf_str(&p->buf), buf_str(&p->key)); break;
    }
}

static void add_str(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** add_str '%s' at top\n", buf_str(&p->buf)); break;
    case ARRAY_FUN: printf("*** add_str '%s' to array\n", buf_str(&p->buf)); break;
    case OBJECT_FUN: printf("*** add_str '%s' with '%s'\n", buf_str(&p->buf), buf_str(&p->key)); break;
    }
}

static void open_array(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** open_array at top\n"); break;
    case ARRAY_FUN: printf("*** open_array to array\n"); break;
    case OBJECT_FUN: printf("*** open_array with '%s'\n", buf_str(&p->key)); break;
    }
}

static void close_array(struct _ojParser *p) {
    printf("*** close_array\n");
}

static void open_object(struct _ojParser *p) {
    switch (p->stack[p->depth]) {
    case TOP_FUN: printf("*** open_object at top\n"); break;
    case ARRAY_FUN: printf("*** open_object to array\n"); break;
    case OBJECT_FUN: printf("*** open_object with '%s'\n", buf_str(&p->key)); break;
    }
}

static void close_object(struct _ojParser *p) {
    printf("*** close_object\n");
}

static VALUE option(ojParser p, const char *key, VALUE value) {
    rb_raise(rb_eArgError, "%s is not an option for the debug delegate", key);
    return Qnil;
}

static VALUE result(struct _ojParser *p) {
    return Qnil;
}

static void start(struct _ojParser *p) {
    printf("*** start\n");
}

static void dfree(struct _ojParser *p) {
}

static void mark(struct _ojParser *p) {
}

void oj_set_parser_debug(ojParser p) {
    Funcs end = p->funcs + 3;
    Funcs f;

    for (f = p->funcs; f < end; f++) {
        f->add_null     = add_null;
        f->add_true     = add_true;
        f->add_false    = add_false;
        f->add_int      = add_int;
        f->add_float    = add_float;
        f->add_big      = add_big;
        f->add_str      = add_str;
        f->open_array   = open_array;
        f->close_array  = close_array;
        f->open_object  = open_object;
        f->close_object = close_object;
    }
    p->option = option;
    p->result = result;
    p->free   = dfree;
    p->mark   = mark;
    p->start  = start;
}
