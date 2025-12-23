// Copyright (c) 2012 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license details.

#if !IS_WINDOWS
#include <sys/resource.h>  // for getrlimit() on linux
#endif
#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dump.h"
#include "encode.h"
#include "mem.h"
#include "oj.h"

// maximum to allocate on the stack, arbitrary limit
#define SMALL_JSON 65536
#define MAX_STACK 100
// #define BATCH_SIZE	(4096 / sizeof(struct _leaf) - 1)
#define BATCH_SIZE 100

// Support for compaction
#ifdef HAVE_RB_GC_MARK_MOVABLE
#define mark rb_gc_mark_movable
#else
#define mark rb_gc_mark
#endif

typedef struct _batch {
    struct _batch *next;
    int            next_avail;
    struct _leaf   leaves[BATCH_SIZE];
} *Batch;

typedef struct _doc {
    Leaf          data;
    Leaf         *where;                  // points to current location
    Leaf          where_path[MAX_STACK];  // points to head of path
    char         *json;
    unsigned long size;  // number of leaves/branches in the doc
    VALUE         self;
    Batch         batches;
    struct _batch batch0;
} *Doc;

typedef struct _parseInfo {
    char *str;  // buffer being read from
    char *s;    // current position in buffer
    Doc   doc;
    void *stack_min;
} *ParseInfo;

static void  leaf_init(Leaf leaf, int type);
static Leaf  leaf_new(Doc doc, int type);
static void  leaf_append_element(Leaf parent, Leaf element);
static VALUE leaf_value(Doc doc, Leaf leaf);
static void  leaf_fixnum_value(Leaf leaf);
static void  leaf_float_value(Leaf leaf);
static VALUE leaf_array_value(Doc doc, Leaf leaf);
static VALUE leaf_hash_value(Doc doc, Leaf leaf);

static Leaf  read_next(ParseInfo pi);
static Leaf  read_obj(ParseInfo pi);
static Leaf  read_array(ParseInfo pi);
static Leaf  read_str(ParseInfo pi);
static Leaf  read_num(ParseInfo pi);
static Leaf  read_true(ParseInfo pi);
static Leaf  read_false(ParseInfo pi);
static Leaf  read_nil(ParseInfo pi);
static void  next_non_white(ParseInfo pi);
static char *read_quoted_value(ParseInfo pi);
static void  skip_comment(ParseInfo pi);

static VALUE protect_open_proc(VALUE x);
static VALUE parse_json(VALUE clas, char *json, bool given);
static void  each_leaf(Doc doc, VALUE self);
static int   move_step(Doc doc, const char *path, int loc);
static Leaf  get_doc_leaf(Doc doc, const char *path);
static Leaf  get_leaf(Leaf *stack, Leaf *lp, const char *path);
static void  each_value(Doc doc, Leaf leaf);

VALUE oj_doc_class = Qundef;

// This is only for CentOS 5.4 with Ruby 1.9.3-p0.
#ifndef HAVE_STPCPY
char *stpcpy(char *dest, const char *src) {
    size_t cnt = strlen(src);

    strcpy(dest, src);

    return dest + cnt;
}
#endif

inline static void next_non_white(ParseInfo pi) {
    for (; 1; pi->s++) {
        switch (*pi->s) {
        case ' ':
        case '\t':
        case '\f':
        case '\n':
        case '\r': break;
        case '/': skip_comment(pi); break;
        default: return;
        }
    }
}

inline static char *ulong_fill(char *s, size_t num) {
    char  buf[32];
    char *b = buf + sizeof(buf) - 1;

    *b-- = '\0';
    b    = oj_longlong_to_string((long long)num, false, b);
    if ('\0' == *b) {
        b--;
        *b = '0';
    }
    for (; '\0' != *b; b++, s++) {
        *s = *b;
    }
    return s;
}

inline static void leaf_init(Leaf leaf, int type) {
    leaf->next        = 0;
    leaf->rtype       = type;
    leaf->parent_type = T_NONE;
    switch (type) {
    case T_ARRAY:
    case T_HASH:
        leaf->elements   = 0;
        leaf->value_type = COL_VAL;
        break;
    case T_NIL:
        leaf->value      = Qnil;
        leaf->value_type = RUBY_VAL;
        break;
    case T_TRUE:
        leaf->value      = Qtrue;
        leaf->value_type = RUBY_VAL;
        break;
    case T_FALSE:
        leaf->value      = Qfalse;
        leaf->value_type = RUBY_VAL;
        break;
    case T_FIXNUM:
    case T_FLOAT:
    case T_STRING:
    default: leaf->value_type = STR_VAL; break;
    }
}

inline static Leaf leaf_new(Doc doc, int type) {
    Leaf leaf;

    if (0 == doc->batches || BATCH_SIZE == doc->batches->next_avail) {
        Batch b = OJ_R_ALLOC(struct _batch);

        // Initializes all leaves with a NO_VAL value_type
        memset(b, 0, sizeof(struct _batch));
        b->next       = doc->batches;
        doc->batches  = b;
        b->next_avail = 0;
    }
    leaf = &doc->batches->leaves[doc->batches->next_avail];
    doc->batches->next_avail++;
    leaf_init(leaf, type);

    return leaf;
}

inline static void leaf_append_element(Leaf parent, Leaf element) {
    if (0 == parent->elements) {
        parent->elements = element;
        element->next    = element;
    } else {
        element->next          = parent->elements->next;
        parent->elements->next = element;
        parent->elements       = element;
    }
}

static VALUE leaf_value(Doc doc, Leaf leaf) {
    if (RUBY_VAL != leaf->value_type) {
        switch (leaf->rtype) {
        case T_NIL: leaf->value = Qnil; break;
        case T_TRUE: leaf->value = Qtrue; break;
        case T_FALSE: leaf->value = Qfalse; break;
        case T_FIXNUM: leaf_fixnum_value(leaf); break;
        case T_FLOAT: leaf_float_value(leaf); break;
        case T_STRING:
            leaf->value      = rb_utf8_str_new_cstr(leaf->str);
            leaf->value_type = RUBY_VAL;
            break;
        case T_ARRAY: return leaf_array_value(doc, leaf); break;
        case T_HASH: return leaf_hash_value(doc, leaf); break;
        default: rb_raise(rb_const_get_at(Oj, rb_intern("Error")), "Unexpected type %02x.", leaf->rtype); break;
        }
    }
    return leaf->value;
}

inline static Doc self_doc(VALUE self) {
    Doc doc = DATA_PTR(self);

    if (0 == doc) {
        rb_raise(rb_eIOError, "Document already closed or not open.");
    }
    return doc;
}

static void skip_comment(ParseInfo pi) {
    pi->s++;  // skip first /
    if ('*' == *pi->s) {
        pi->s++;
        for (; '\0' != *pi->s; pi->s++) {
            if ('*' == *pi->s && '/' == *(pi->s + 1)) {
                pi->s++;
                return;
            } else if ('\0' == *pi->s) {
                raise_error("comment not terminated", pi->str, pi->s);
            }
        }
    } else if ('/' == *pi->s) {
        for (; 1; pi->s++) {
            switch (*pi->s) {
            case '\n':
            case '\r':
            case '\f':
            case '\0': return;
            default: break;
            }
        }
    } else {
        raise_error("invalid comment", pi->str, pi->s);
    }
}

#ifdef RUBINIUS_RUBY
#define NUM_MAX 0x07FFFFFF
#else
#define NUM_MAX (FIXNUM_MAX >> 8)
#endif

static void leaf_fixnum_value(Leaf leaf) {
    char   *s   = leaf->str;
    int64_t n   = 0;
    int     neg = 0;
    int     big = 0;

    if ('-' == *s) {
        s++;
        neg = 1;
    } else if ('+' == *s) {
        s++;
    }
    for (; '0' <= *s && *s <= '9'; s++) {
        n = n * 10 + (*s - '0');
        if (NUM_MAX <= n) {
            big = 1;
        }
    }
    if (big) {
        char c = *s;

        *s          = '\0';
        leaf->value = rb_cstr_to_inum(leaf->str, 10, 0);
        *s          = c;
    } else {
        if (neg) {
            n = -n;
        }
        leaf->value = rb_ll2inum(n);
    }
    leaf->value_type = RUBY_VAL;
}

static void leaf_float_value(Leaf leaf) {
    leaf->value      = rb_float_new(rb_cstr_to_dbl(leaf->str, 1));
    leaf->value_type = RUBY_VAL;
}

static VALUE leaf_array_value(Doc doc, Leaf leaf) {
    volatile VALUE a = rb_ary_new();

    if (0 != leaf->elements) {
        Leaf first = leaf->elements->next;
        Leaf e     = first;

        do {
            rb_ary_push(a, leaf_value(doc, e));
            e = e->next;
        } while (e != first);
    }
    return a;
}

static VALUE leaf_hash_value(Doc doc, Leaf leaf) {
    volatile VALUE h = rb_hash_new();

    if (0 != leaf->elements) {
        Leaf           first = leaf->elements->next;
        Leaf           e     = first;
        volatile VALUE key;

        do {
            key = rb_utf8_str_new_cstr(e->key);
            rb_hash_aset(h, key, leaf_value(doc, e));
            e = e->next;
        } while (e != first);
    }
    return h;
}

static Leaf read_next(ParseInfo pi) {
    Leaf leaf = 0;

    if ((void *)&leaf < pi->stack_min) {
        rb_raise(rb_eSysStackError, "JSON is too deeply nested");
    }
    next_non_white(pi);  // skip white space
    switch (*pi->s) {
    case '{': leaf = read_obj(pi); break;
    case '[': leaf = read_array(pi); break;
    case '"': leaf = read_str(pi); break;
    case '+':
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
    case '9': leaf = read_num(pi); break;
    case 't': leaf = read_true(pi); break;
    case 'f': leaf = read_false(pi); break;
    case 'n': leaf = read_nil(pi); break;
    case '\0':
    default: break;  // returns 0
    }
    pi->doc->size++;

    return leaf;
}

static Leaf read_obj(ParseInfo pi) {
    Leaf        h = leaf_new(pi->doc, T_HASH);
    char       *end;
    const char *key = 0;
    Leaf        val = 0;

    pi->s++;
    next_non_white(pi);
    if ('}' == *pi->s) {
        pi->s++;
        return h;
    }
    while (1) {
        next_non_white(pi);
        key = 0;
        val = 0;
        if ('"' != *pi->s || 0 == (key = read_quoted_value(pi))) {
            raise_error("unexpected character", pi->str, pi->s);
        }
        next_non_white(pi);
        if (':' == *pi->s) {
            pi->s++;
        } else {
            raise_error("invalid format, expected :", pi->str, pi->s);
        }
        if (0 == (val = read_next(pi))) {
            // printf("*** '%s'\n", pi->s);
            raise_error("unexpected character", pi->str, pi->s);
        }
        end              = pi->s;
        val->key         = key;
        val->parent_type = T_HASH;
        leaf_append_element(h, val);
        next_non_white(pi);
        if ('}' == *pi->s) {
            pi->s++;
            *end = '\0';
            break;
        } else if (',' == *pi->s) {
            pi->s++;
        } else {
            // printf("*** '%s'\n", pi->s);
            raise_error("invalid format, expected , or } while in an object", pi->str, pi->s);
        }
        *end = '\0';
    }
    return h;
}

static Leaf read_array(ParseInfo pi) {
    Leaf  a = leaf_new(pi->doc, T_ARRAY);
    Leaf  e;
    char *end;
    int   cnt = 0;

    pi->s++;
    next_non_white(pi);
    if (']' == *pi->s) {
        pi->s++;
        return a;
    }
    while (1) {
        next_non_white(pi);
        if (0 == (e = read_next(pi))) {
            raise_error("unexpected character", pi->str, pi->s);
        }
        cnt++;
        e->index       = cnt;
        e->parent_type = T_ARRAY;
        leaf_append_element(a, e);
        end = pi->s;
        next_non_white(pi);
        if (',' == *pi->s) {
            pi->s++;
        } else if (']' == *pi->s) {
            pi->s++;
            *end = '\0';
            break;
        } else {
            raise_error("invalid format, expected , or ] while in an array", pi->str, pi->s);
        }
        *end = '\0';
    }
    return a;
}

static Leaf read_str(ParseInfo pi) {
    Leaf leaf = leaf_new(pi->doc, T_STRING);

    leaf->str = read_quoted_value(pi);

    return leaf;
}

static Leaf read_num(ParseInfo pi) {
    char *start = pi->s;
    int   type  = T_FIXNUM;
    Leaf  leaf;

    if ('-' == *pi->s) {
        pi->s++;
    }
    // digits
    for (; '0' <= *pi->s && *pi->s <= '9'; pi->s++) {
    }
    if ('.' == *pi->s) {
        type = T_FLOAT;
        pi->s++;
        for (; '0' <= *pi->s && *pi->s <= '9'; pi->s++) {
        }
    }
    if ('e' == *pi->s || 'E' == *pi->s) {
        pi->s++;
        if ('-' == *pi->s || '+' == *pi->s) {
            pi->s++;
        }
        for (; '0' <= *pi->s && *pi->s <= '9'; pi->s++) {
        }
    }
    leaf      = leaf_new(pi->doc, type);
    leaf->str = start;

    return leaf;
}

static Leaf read_true(ParseInfo pi) {
    Leaf leaf = leaf_new(pi->doc, T_TRUE);

    pi->s++;
    if ('r' != *pi->s || 'u' != *(pi->s + 1) || 'e' != *(pi->s + 2)) {
        raise_error("invalid format, expected 'true'", pi->str, pi->s);
    }
    pi->s += 3;

    return leaf;
}

static Leaf read_false(ParseInfo pi) {
    Leaf leaf = leaf_new(pi->doc, T_FALSE);

    pi->s++;
    if ('a' != *pi->s || 'l' != *(pi->s + 1) || 's' != *(pi->s + 2) || 'e' != *(pi->s + 3)) {
        raise_error("invalid format, expected 'false'", pi->str, pi->s);
    }
    pi->s += 4;

    return leaf;
}

static Leaf read_nil(ParseInfo pi) {
    Leaf leaf = leaf_new(pi->doc, T_NIL);

    pi->s++;
    if ('u' != *pi->s || 'l' != *(pi->s + 1) || 'l' != *(pi->s + 2)) {
        raise_error("invalid format, expected 'nil'", pi->str, pi->s);
    }
    pi->s += 3;

    return leaf;
}

static uint32_t read_4hex(ParseInfo pi, const char *h) {
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
            raise_error("invalid hex character", pi->str, pi->s);
        }
    }
    return b;
}

static char *unicode_to_chars(ParseInfo pi, char *t, uint32_t code) {
    if (0x0000007F >= code) {
        *t++ = (char)code;
    } else if (0x000007FF >= code) {
        *t++ = 0xC0 | (code >> 6);
        *t++ = 0x80 | (0x3F & code);
    } else if (0x0000FFFF >= code) {
        *t++ = 0xE0 | (code >> 12);
        *t++ = 0x80 | ((code >> 6) & 0x3F);
        *t++ = 0x80 | (0x3F & code);
    } else if (0x001FFFFF >= code) {
        *t++ = 0xF0 | (code >> 18);
        *t++ = 0x80 | ((code >> 12) & 0x3F);
        *t++ = 0x80 | ((code >> 6) & 0x3F);
        *t++ = 0x80 | (0x3F & code);
    } else if (0x03FFFFFF >= code) {
        *t++ = 0xF8 | (code >> 24);
        *t++ = 0x80 | ((code >> 18) & 0x3F);
        *t++ = 0x80 | ((code >> 12) & 0x3F);
        *t++ = 0x80 | ((code >> 6) & 0x3F);
        *t++ = 0x80 | (0x3F & code);
    } else if (0x7FFFFFFF >= code) {
        *t++ = 0xFC | (code >> 30);
        *t++ = 0x80 | ((code >> 24) & 0x3F);
        *t++ = 0x80 | ((code >> 18) & 0x3F);
        *t++ = 0x80 | ((code >> 12) & 0x3F);
        *t++ = 0x80 | ((code >> 6) & 0x3F);
        *t++ = 0x80 | (0x3F & code);
    } else {
        raise_error("invalid Unicode character", pi->str, pi->s);
    }
    return t;
}

// Assume the value starts immediately and goes until the quote character is
// reached again. Do not read the character after the terminating quote.
static char *read_quoted_value(ParseInfo pi) {
    char *value = 0;
    char *h     = pi->s;  // head
    char *t     = h;      // tail

    h++;  // skip quote character
    t++;
    value = h;
    for (; '"' != *h; h++, t++) {
        if ('\0' == *h) {
            pi->s = h;
            raise_error("quoted string not terminated", pi->str, pi->s);
        } else if ('\\' == *h) {
            h++;
            switch (*h) {
            case 'n': *t = '\n'; break;
            case 'r': *t = '\r'; break;
            case 't': *t = '\t'; break;
            case 'f': *t = '\f'; break;
            case 'b': *t = '\b'; break;
            case '"': *t = '"'; break;
            case '/': *t = '/'; break;
            case '\\': *t = '\\'; break;
            case 'u': {
                uint32_t code;

                h++;
                code = read_4hex(pi, h);
                h += 3;
                if (0x0000D800 <= code && code <= 0x0000DFFF) {
                    uint32_t c1 = (code - 0x0000D800) & 0x000003FF;
                    uint32_t c2;

                    h++;
                    if ('\\' != *h || 'u' != *(h + 1)) {
                        pi->s = h;
                        raise_error("invalid escaped character", pi->str, pi->s);
                    }
                    h += 2;
                    c2 = read_4hex(pi, h);
                    h += 3;
                    c2   = (c2 - 0x0000DC00) & 0x000003FF;
                    code = ((c1 << 10) | c2) + 0x00010000;
                }
                t = unicode_to_chars(pi, t, code);
                t--;
                break;
            }
            default:
                pi->s = h;
                raise_error("invalid escaped character", pi->str, pi->s);
                break;
            }
        } else if (t != h) {
            *t = *h;
        }
    }
    *t    = '\0';  // terminate value
    pi->s = h + 1;

    return value;
}

// doc support functions
inline static void doc_init(Doc doc) {
    memset(doc, 0, sizeof(struct _doc));
    doc->where   = doc->where_path;
    doc->self    = Qundef;
    doc->batches = &doc->batch0;
}

static void doc_free(Doc doc) {
    if (0 != doc) {
        Batch b;

        while (0 != (b = doc->batches)) {
            doc->batches = doc->batches->next;
            if (&doc->batch0 != b) {
                OJ_R_FREE(b);
            }
        }
        OJ_R_FREE(doc->json);
        OJ_R_FREE(doc);
    }
}

static VALUE protect_open_proc(VALUE x) {
    ParseInfo pi = (ParseInfo)x;

    pi->doc->data   = read_next(pi);  // parse
    *pi->doc->where = pi->doc->data;
    pi->doc->where  = pi->doc->where_path;
    if (rb_block_given_p()) {
        return rb_yield(pi->doc->self);  // caller processing
    }
    return Qnil;
}

static void free_doc_cb(void *x) {
    Doc doc = (Doc)x;

    if (0 != doc) {
        doc_free(doc);
    }
}

static void mark_leaf(Leaf leaf) {
    if (NULL != leaf) {
        switch (leaf->value_type) {
        case COL_VAL:
            if (NULL != leaf->elements) {
                Leaf first = leaf->elements->next;
                Leaf e     = first;

                do {
                    mark_leaf(e);
                    e = e->next;
                } while (e != first);
            }
            break;
        case RUBY_VAL: mark(leaf->value); break;

        default: break;
        }
    }
}

static void mark_doc(void *ptr) {
    if (NULL != ptr) {
        Doc doc = (Doc)ptr;

        mark(doc->self);
        mark_leaf(doc->data);
    }
}
#ifdef HAVE_RB_GC_MARK_MOVABLE
static void compact_leaf(Leaf leaf) {
    switch (leaf->value_type) {
    case COL_VAL:
        if (NULL != leaf->elements) {
            Leaf first = leaf->elements->next;
            Leaf e     = first;

            do {
                compact_leaf(e);
                e = e->next;
            } while (e != first);
        }
        break;
    case RUBY_VAL: leaf->value = rb_gc_location(leaf->value); break;

    default: break;
    }
}

static void compact_doc(void *ptr) {
    Doc doc = (Doc)ptr;

    if (doc) {
        doc->self = rb_gc_location(doc->self);
        compact_leaf(doc->data);
    }
}
#endif

static const rb_data_type_t oj_doc_type = {
    "Oj/doc",
    {
        mark_doc,
        free_doc_cb,
        NULL,
#ifdef HAVE_RB_GC_MARK_MOVABLE
        compact_doc,
#endif
    },
    0,
    0,
};

static VALUE parse_json(VALUE clas, char *json, bool given) {
    struct _parseInfo pi;
    volatile VALUE    result = Qnil;
    Doc               doc;
    int               ex = 0;
    volatile VALUE    self;

    doc = OJ_R_ALLOC_N(struct _doc, 1);

    // skip UTF-8 BOM if present
    if (0xEF == (uint8_t)*json && 0xBB == (uint8_t)json[1] && 0xBF == (uint8_t)json[2]) {
        pi.str = json + 3;
    } else {
        pi.str = json;
    }
    pi.s = pi.str;
    doc_init(doc);
    pi.doc = doc;
#if IS_WINDOWS || !defined(HAVE_GETRLIMIT)
    // assume a 1M stack and give half to ruby
    pi.stack_min = (void *)((char *)&pi - (512L * 1024L));
#else
    {
        struct rlimit lim;

        if (0 == getrlimit(RLIMIT_STACK, &lim) && RLIM_INFINITY != lim.rlim_cur) {
            // let 3/4ths of the stack be used only
            pi.stack_min = (void *)((char *)&lim - (lim.rlim_cur / 4 * 3));
        } else {
            pi.stack_min = 0;  // indicates not to check stack limit
        }
    }
#endif
    doc->json = json;
    self      = TypedData_Wrap_Struct(clas, &oj_doc_type, doc);
    doc->self = self;
    result    = rb_protect(protect_open_proc, (VALUE)&pi, &ex);
    if (given || 0 != ex) {
        DATA_PTR(doc->self) = NULL;
        // TBD is this needed?
        /*
        doc_free(pi.doc);
        if (0 != ex) {  // will jump so caller will not free
            OJ_R_FREE(json);
        }
        */
    } else {
        result = doc->self;
    }
    if (0 != ex) {
        rb_jump_tag(ex);
    }
    return result;
}

static Leaf get_doc_leaf(Doc doc, const char *path) {
    Leaf leaf = *doc->where;

    if (0 != doc->data && 0 != path) {
        Leaf  stack[MAX_STACK];
        Leaf *lp;

        if ('/' == *path) {
            path++;
            *stack = doc->data;
            lp     = stack;
        } else if (doc->where == doc->where_path) {
            *stack = doc->data;
            lp     = stack;
        } else {
            size_t cnt = doc->where - doc->where_path;

            if (MAX_STACK <= cnt) {
                rb_raise(rb_const_get_at(Oj, rb_intern("DepthError")), "Path too deep. Limit is %d levels.", MAX_STACK);
            }
            memcpy(stack, doc->where_path, sizeof(Leaf) * (cnt + 1));
            lp = stack + cnt;
        }
        return get_leaf(stack, lp, path);
    }
    return leaf;
}

static const char *next_slash(const char *s) {
    for (; '\0' != *s; s++) {
        if ('\\' == *s) {
            s++;
            if ('\0' == *s) {
                break;
            }
        } else if ('/' == *s) {
            return s;
        }
    }
    return NULL;
}

static bool key_match(const char *pat, const char *key, int plen) {
    for (; 0 < plen; plen--, pat++, key++) {
        if ('\\' == *pat) {
            plen--;
            pat++;
        }
        if (*pat != *key) {
            return false;
        }
    }
    return '\0' == *key;
}

static Leaf get_leaf(Leaf *stack, Leaf *lp, const char *path) {
    Leaf leaf = *lp;

    if (MAX_STACK <= lp - stack) {
        rb_raise(rb_const_get_at(Oj, rb_intern("DepthError")), "Path too deep. Limit is %d levels.", MAX_STACK);
    }
    if ('\0' != *path) {
        if ('.' == *path && '.' == *(path + 1)) {
            path += 2;
            if ('/' == *path) {
                path++;
            }
            if (stack < lp) {
                leaf = get_leaf(stack, lp - 1, path);
            } else {
                return 0;
            }
        } else if (NULL == leaf->elements) {
            leaf = NULL;
        } else if (STR_VAL == leaf->value_type || RUBY_VAL == leaf->value_type) {
            // We are trying to get a children of a leaf, which
            // doesn't exist.
            leaf = NULL;
        } else if (COL_VAL == leaf->value_type) {
            Leaf first = leaf->elements->next;
            Leaf e     = first;
            int  type  = leaf->rtype;

            leaf = NULL;
            if (T_ARRAY == type) {
                int cnt = 0;

                for (; '0' <= *path && *path <= '9'; path++) {
                    cnt = cnt * 10 + (*path - '0');
                }
                if ('/' == *path) {
                    path++;
                }
                do {
                    if (1 >= cnt) {
                        lp++;
                        *lp  = e;
                        leaf = get_leaf(stack, lp, path);
                        break;
                    }
                    cnt--;
                    e = e->next;
                } while (e != first);
            } else if (T_HASH == type) {
                const char *key   = path;
                const char *slash = next_slash(path);
                int         klen;

                leaf = NULL;
                if (0 == slash) {
                    klen = (int)strlen(key);
                    path += klen;
                } else {
                    klen = (int)(slash - key);
                    path += klen + 1;
                }
                do {
                    if (key_match(key, e->key, klen)) {
                        lp++;
                        *lp  = e;
                        leaf = get_leaf(stack, lp, path);
                        break;
                    }
                    e = e->next;
                } while (e != first);
            }
        }
    }
    return leaf;
}

static void each_leaf(Doc doc, VALUE self) {
    if (COL_VAL == (*doc->where)->value_type) {
        if (0 != (*doc->where)->elements) {
            Leaf first = (*doc->where)->elements->next;
            Leaf e     = first;

            doc->where++;
            if (MAX_STACK <= doc->where - doc->where_path) {
                rb_raise(rb_const_get_at(Oj, rb_intern("DepthError")), "Path too deep. Limit is %d levels.", MAX_STACK);
            }
            do {
                *doc->where = e;
                each_leaf(doc, self);
                e = e->next;
            } while (e != first);
            doc->where--;
        }
    } else {
        rb_yield(self);
    }
}

static int move_step(Doc doc, const char *path, int loc) {
    if (MAX_STACK <= doc->where - doc->where_path) {
        rb_raise(rb_const_get_at(Oj, rb_intern("DepthError")), "Path too deep. Limit is %d levels.", MAX_STACK);
    }
    if ('\0' == *path) {
        loc = 0;
    } else {
        Leaf leaf;

        if (0 == doc->where || 0 == (leaf = *doc->where)) {
            printf("*** Internal error at %s\n", path);
            return loc;
        }
        if ('.' == *path && '.' == *(path + 1)) {
            Leaf init = *doc->where;

            path += 2;
            if (doc->where == doc->where_path) {
                return loc;
            }
            if ('/' == *path) {
                path++;
            }
            *doc->where = 0;
            doc->where--;
            loc = move_step(doc, path, loc + 1);
            if (0 != loc) {
                *doc->where = init;
                doc->where++;
            }
        } else if (COL_VAL == leaf->value_type && 0 != leaf->elements) {
            Leaf first = leaf->elements->next;
            Leaf e     = first;

            if (T_ARRAY == leaf->rtype) {
                int cnt = 0;

                for (; '0' <= *path && *path <= '9'; path++) {
                    cnt = cnt * 10 + (*path - '0');
                }
                if ('/' == *path) {
                    path++;
                } else if ('\0' != *path) {
                    return loc;
                }
                do {
                    if (1 >= cnt) {
                        doc->where++;
                        *doc->where = e;
                        loc         = move_step(doc, path, loc + 1);
                        if (0 != loc) {
                            *doc->where = 0;
                            doc->where--;
                        }
                        break;
                    }
                    cnt--;
                    e = e->next;
                } while (e != first);
            } else if (T_HASH == leaf->rtype) {
                const char *key   = path;
                const char *slash = next_slash(path);
                int         klen;

                if (0 == slash) {
                    klen = (int)strlen(key);
                    path += klen;
                } else {
                    klen = (int)(slash - key);
                    path += klen + 1;
                }
                do {
                    if (key_match(key, e->key, klen)) {
                        doc->where++;
                        *doc->where = e;
                        loc         = move_step(doc, path, loc + 1);
                        if (0 != loc) {
                            *doc->where = 0;
                            doc->where--;
                        }
                        break;
                    }
                    e = e->next;
                } while (e != first);
            }
        }
    }
    return loc;
}

static void each_value(Doc doc, Leaf leaf) {
    if (COL_VAL == leaf->value_type) {
        if (0 != leaf->elements) {
            Leaf first = leaf->elements->next;
            Leaf e     = first;

            do {
                each_value(doc, e);
                e = e->next;
            } while (e != first);
        }
    } else {
        rb_yield(leaf_value(doc, leaf));
    }
}

// doc functions

/* @overload open(json) { |doc| ... } => Object
 *
 * Parses a JSON document String and then yields to the provided block if one
 * is given with an instance of the Oj::Doc as the single yield parameter. If
 * a block is not given then an Oj::Doc instance is returned and must be
 * closed with a call to the #close() method when no longer needed.
 *
 *   @param [String] json JSON document string
 * @yieldparam [Oj::Doc] doc parsed JSON document
 * @yieldreturn [Object] returns the result of the yield as the result of the
 * method call
 * @example
 *   Oj::Doc.open('[1,2,3]') { |doc| doc.size() }  #=> 4
 *   # or as an alternative
 *   doc = Oj::Doc.open('[1,2,3]')
 *   doc.size()  #=> 4
 *   doc.close()
 */
static VALUE doc_open(VALUE clas, VALUE str) {
    char          *json;
    size_t         len;
    volatile VALUE obj;
    int            given = rb_block_given_p();

    Check_Type(str, T_STRING);
    len  = (int)RSTRING_LEN(str) + 1;
    json = OJ_R_ALLOC_N(char, len);

    memcpy(json, StringValuePtr(str), len);
    obj = parse_json(clas, json, given);
    // TBD is this needed
    /*
    if (given) {
        OJ_R_FREE(json);
    }
    */
    return obj;
}

/* @overload open_file(filename) { |doc| ... } => Object
 *
 * Parses a JSON document from a file and then yields to the provided block if
 * one is given with an instance of the Oj::Doc as the single yield
 * parameter. If a block is not given then an Oj::Doc instance is returned and
 * must be closed with a call to the #close() method when no longer needed.
 *
 *   @param [String] filename name of file that contains a JSON document
 * @yieldparam [Oj::Doc] doc parsed JSON document
 * @yieldreturn [Object] returns the result of the yield as the result of the
 * method call
 * @example
 *   File.open('array.json', 'w') { |f| f.write('[1,2,3]') }
 *   Oj::Doc.open_file(filename) { |doc| doc.size() }  #=> 4
 *   # or as an alternative
 *   doc = Oj::Doc.open_file(filename)
 *   doc.size()  #=> 4
 *   doc.close()
 */
static VALUE doc_open_file(VALUE clas, VALUE filename) {
    char          *path;
    char          *json;
    FILE          *f;
    size_t         len;
    volatile VALUE obj;
    int            given = rb_block_given_p();

    path = StringValuePtr(filename);
    if (0 == (f = fopen(path, "r"))) {
        rb_raise(rb_eIOError, "%s", strerror(errno));
    }
    fseek(f, 0, SEEK_END);
    len  = ftell(f);
    json = OJ_R_ALLOC_N(char, len + 1);

    fseek(f, 0, SEEK_SET);
    if (len != fread(json, 1, len, f)) {
        fclose(f);
        rb_raise(rb_const_get_at(Oj, rb_intern("LoadError")),
                 "Failed to read %lu bytes from %s.",
                 (unsigned long)len,
                 path);
    }
    fclose(f);
    json[len] = '\0';
    obj       = parse_json(clas, json, given);
    // TBD is this needed
    /*
    if (given) {
        OJ_R_FREE(json);
    }
    */
    return obj;
}

static int esc_strlen(const char *s) {
    int cnt = 0;

    for (; '\0' != *s; s++, cnt++) {
        if ('/' == *s) {
            cnt++;
        }
    }
    return cnt;
}

static char *append_key(char *p, const char *key) {
    for (; '\0' != *key; p++, key++) {
        if ('/' == *key) {
            *p++ = '\\';
        }
        *p = *key;
    }
    return p;
}

/* Document-method: parse
 * @see Oj::Doc.open
 */

/* @overload where() => String
 *
 * Returns a String that describes the absolute path to the current location
 * in the JSON document.
 */
static VALUE doc_where(VALUE self) {
    Doc doc = self_doc(self);

    if (0 == *doc->where_path || doc->where == doc->where_path) {
        return oj_slash_string;
    } else {
        Leaf  *lp;
        Leaf   leaf;
        size_t size = 3;  // leading / and terminating \0
        char  *path;
        char  *p;

        for (lp = doc->where_path; lp <= doc->where; lp++) {
            leaf = *lp;
            if (T_HASH == leaf->parent_type) {
                size += esc_strlen((*lp)->key) + 1;
            } else if (T_ARRAY == leaf->parent_type) {
                size += ((*lp)->index < 100) ? 3 : 11;
            }
        }
        path = ALLOCA_N(char, size);
        p    = path;
        for (lp = doc->where_path; lp <= doc->where; lp++) {
            leaf = *lp;
            if (T_HASH == leaf->parent_type) {
                p = append_key(p, (*lp)->key);
            } else if (T_ARRAY == leaf->parent_type) {
                p = ulong_fill(p, (*lp)->index);
            }
            *p++ = '/';
        }
        *--p = '\0';

        return rb_str_new(path, p - path);
    }
}

/* @overload where?() => String
 * @deprecated
 * Returns a String that describes the absolute path to the current location
 * in the JSON document.
 */
static VALUE doc_where_q(VALUE self) {
    return doc_where(self);
}

/* @overload path() => String
 *
 * Returns a String that describes the absolute path to the current location
 * in the JSON document.
 */
static VALUE doc_path(VALUE self) {
    return doc_where(self);
}

/* @overload local_key() => String, Fixnum, nil
 *
 * Returns the final key to the current location.
 * @example
 *   Oj::Doc.open('[1,2,3]') { |doc| doc.move('/2'); doc.local_key() } #=> 2
 *   Oj::Doc.open('{"one":3}') { |doc| doc.move('/one'); doc.local_key() }  #=>
 * "one" Oj::Doc.open('[1,2,3]') { |doc| doc.local_key() }
 * #=> nil
 */
static VALUE doc_local_key(VALUE self) {
    Doc            doc  = self_doc(self);
    Leaf           leaf = *doc->where;
    volatile VALUE key  = Qnil;

    if (T_HASH == leaf->parent_type) {
        key = rb_utf8_str_new_cstr(leaf->key);
    } else if (T_ARRAY == leaf->parent_type) {
        key = LONG2NUM(leaf->index);
    }
    return key;
}

/* @overload home() => nil
 *
 * Moves the document marker or location to the hoot or home position. The
 * same operation can be performed with a Oj::Doc.move('/').
 * @example
 *   Oj::Doc.open('[1,2,3]') { |doc| doc.move('/2'); doc.home(); doc.where? }
 * #=> '/'
 */
static VALUE doc_home(VALUE self) {
    Doc doc = self_doc(self);

    *doc->where_path = doc->data;
    doc->where       = doc->where_path;

    return oj_slash_string;
}

/* @overload type(path=nil) => Class
 *
 * Returns the Class of the data value at the location identified by the path
 * or the current location if the path is nil or not provided. This method
 * does not create the Ruby Object at the location specified so the overhead
 * is low.
 *   @param [String] path path to the location to get the type of if provided
 * @example
 *   Oj::Doc.open('[1,2]') { |doc| doc.type() }	     #=> Array
 *   Oj::Doc.open('[1,2]') { |doc| doc.type('/1') }  #=> Fixnum
 */
static VALUE doc_type(int argc, VALUE *argv, VALUE self) {
    Doc         doc = self_doc(self);
    Leaf        leaf;
    const char *path = 0;
    VALUE       type = Qnil;

    if (1 <= argc) {
        path = StringValuePtr(*argv);
    }
    if (0 != (leaf = get_doc_leaf(doc, path))) {
        switch (leaf->rtype) {
        case T_NIL: type = rb_cNilClass; break;
        case T_TRUE: type = rb_cTrueClass; break;
        case T_FALSE: type = rb_cFalseClass; break;
        case T_STRING: type = rb_cString; break;
        case T_FIXNUM: type = rb_cInteger; break;
        case T_FLOAT: type = rb_cFloat; break;
        case T_ARRAY: type = rb_cArray; break;
        case T_HASH: type = rb_cHash; break;
        default: break;
        }
    }
    return type;
}

/* @overload fetch(path=nil,default=nil) => nil, true, false, Fixnum, Float, String, Array,
 * Hash
 *
 * Returns the value at the location identified by the path or the current
 * location if the path is nil or not provided. This method will create and
 * return an Array or Hash if that is the type of Object at the location
 * specified. This is more expensive than navigating to the leaves of the JSON
 * document. If a default is provided that is used if no value if found.
 *   @param [String] path path to the location to get the type of if provided
 * @example
 *   Oj::Doc.open('[1,2]') { |doc| doc.fetch() }      #=> [1, 2]
 *   Oj::Doc.open('[1,2]') { |doc| doc.fetch('/1') }  #=> 1
 */
static VALUE doc_fetch(int argc, VALUE *argv, VALUE self) {
    Doc            doc;
    Leaf           leaf;
    volatile VALUE val  = Qnil;
    const char    *path = 0;

    doc = self_doc(self);
    if (1 <= argc) {
        path = StringValuePtr(*argv);
        if (2 == argc) {
            val = argv[1];
        }
    }
    if (0 != (leaf = get_doc_leaf(doc, path))) {
        val = leaf_value(doc, leaf);
    }
    return val;
}

/* @overload exists?(path) => true, false
 *
 * Returns true if the value at the location identified by the path exists.
 *   @param [String] path path to the location
 * @example
 *   Oj::Doc.open('[1,2]') { |doc| doc.exists?('/1') }  #=> true
 *   Oj::Doc.open('[1,2]') { |doc| doc.exists?('/3') }  #=> false
 */
static VALUE doc_exists(VALUE self, VALUE str) {
    Doc  doc;
    Leaf leaf;

    doc = self_doc(self);
    if (0 != (leaf = get_doc_leaf(doc, StringValuePtr(str)))) {
        if (NULL != leaf) {
            return Qtrue;
        }
    }
    return Qfalse;
}

/* @overload each_leaf(path=nil) => nil
 *
 * Yields to the provided block for each leaf node with the identified
 * location of the JSON document as the root. The parameter passed to the
 * block on yield is the Doc instance after moving to the child location.
 *   @param [String] path if provided it identified the top of the branch to
 * process the leaves of
 * @yieldparam [Doc] Doc at the child location
 * @example
 *   Oj::Doc.open('[3,[2,1]]') { |doc|
 *       result = {}
 *       doc.each_leaf() { |d| result[d.where?] = d.fetch() }
 *       result
 *   }
 *   #=> ["/1" => 3, "/2/1" => 2, "/2/2" => 1]
 */
static VALUE doc_each_leaf(int argc, VALUE *argv, VALUE self) {
    if (rb_block_given_p()) {
        Leaf        save_path[MAX_STACK];
        Doc         doc  = self_doc(self);
        const char *path = 0;
        size_t      wlen;

        wlen = doc->where - doc->where_path;
        if (0 < wlen) {
            memcpy(save_path, doc->where_path, sizeof(Leaf) * (wlen + 1));
        }
        if (1 <= argc) {
            path = StringValuePtr(*argv);
            if ('/' == *path) {
                doc->where = doc->where_path;
                path++;
            }
            if (0 != move_step(doc, path, 1)) {
                if (0 < wlen) {
                    memcpy(doc->where_path, save_path, sizeof(Leaf) * (wlen + 1));
                }
                return Qnil;
            }
        }
        each_leaf(doc, self);
        if (0 < wlen) {
            memcpy(doc->where_path, save_path, sizeof(Leaf) * (wlen + 1));
        }
    }
    return Qnil;
}

/* @overload move(path) => nil
 *
 * Moves the document marker to the path specified. The path can an absolute
 * path or a relative path.
 *   @param [String] path path to the location to move to
 * @example
 *   Oj::Doc.open('{"one":[1,2]') { |doc| doc.move('/one/2'); doc.where? }  #=>
 * "/one/2"
 */
static VALUE doc_move(VALUE self, VALUE str) {
    Doc         doc = self_doc(self);
    const char *path;
    int         loc;

    path = StringValuePtr(str);
    if ('/' == *path) {
        doc->where = doc->where_path;
        path++;
    }
    if (0 != (loc = move_step(doc, path, 1))) {
        rb_raise(rb_eArgError, "Failed to locate element %d of the path %s.", loc, path);
    }
    return Qnil;
}

/* @overload each_child(path=nil) { |doc| ... } => nil
 *
 * Yields to the provided block for each immediate child node with the
 * identified location of the JSON document as the root. The parameter passed
 * to the block on yield is the Doc instance after moving to the child
 * location.
 *   @param [String] path if provided it identified the top of the branch to
 * process the children of
 * @yieldparam [Doc] Doc at the child location
 * @example
 *   Oj::Doc.open('[3,[2,1]]') { |doc|
 *       result = []
 *       doc.each_value('/2') { |doc| result << doc.where? }
 *       result
 *   }
 *   #=> ["/2/1", "/2/2"]
 */
static VALUE doc_each_child(int argc, VALUE *argv, VALUE self) {
    if (rb_block_given_p()) {
        Leaf        save_path[MAX_STACK];
        Doc         doc  = self_doc(self);
        const char *path = 0;
        size_t      wlen;
        Leaf       *where_orig = doc->where;

        wlen = doc->where - doc->where_path;
        if (0 < wlen) {
            memcpy(save_path, doc->where_path, sizeof(Leaf) * (wlen + 1));
        }
        if (1 <= argc) {
            path = StringValuePtr(*argv);
            if ('/' == *path) {
                doc->where = doc->where_path;
                path++;
            }
            if (0 != move_step(doc, path, 1)) {
                if (0 < wlen) {
                    memcpy(doc->where_path, save_path, sizeof(Leaf) * (wlen + 1));
                }
                doc->where = where_orig;
                return Qnil;
            }
        }
        if (NULL == doc->where || NULL == *doc->where) {
            return Qnil;
        }
        if (COL_VAL == (*doc->where)->value_type && 0 != (*doc->where)->elements) {
            Leaf first = (*doc->where)->elements->next;
            Leaf e     = first;

            doc->where++;
            do {
                *doc->where = e;
                rb_yield(self);
                e = e->next;
            } while (e != first);
        }
        if (0 < wlen) {
            memcpy(doc->where_path, save_path, sizeof(Leaf) * (wlen + 1));
        }
        doc->where = where_orig;
    }
    return Qnil;
}

/* @overload each_value(path=nil) { |val| ... } => nil
 *
 * Yields to the provided block for each leaf value in the identified location
 * of the JSON document. The parameter passed to the block on yield is the
 * value of the leaf. Only those leaves below the element specified by the
 * path parameter are processed.
 *   @param [String] path if provided it identified the top of the branch to
 * process the leaf values of
 * @yieldparam [Object] val each leaf value
 * @example
 *   Oj::Doc.open('[3,[2,1]]') { |doc|
 *       result = []
 *       doc.each_value() { |v| result << v }
 *       result
 *   }
 *   #=> [3, 2, 1]
 *
 *   Oj::Doc.open('[3,[2,1]]') { |doc|
 *       result = []
 *       doc.each_value('/2') { |v| result << v }
 *       result
 *   }
 *   #=> [2, 1]
 */
static VALUE doc_each_value(int argc, VALUE *argv, VALUE self) {
    if (rb_block_given_p()) {
        Doc         doc  = self_doc(self);
        const char *path = 0;
        Leaf        leaf;

        if (1 <= argc) {
            path = StringValuePtr(*argv);
        }
        if (0 != (leaf = get_doc_leaf(doc, path))) {
            each_value(doc, leaf);
        }
    }
    return Qnil;
}

/* @overload dump(path, filename)
 *
 * Dumps the document or nodes to a new JSON document. It uses the default
 * options for generating the JSON.
 *   @param path [String] if provided it identified the top of the branch to
 * dump to JSON
 *   @param filename [String] if provided it is the filename to write the output
 * to
 * @example
 *   Oj::Doc.open('[3,[2,1]]') { |doc|
 *       doc.dump('/2')
 *   }
 *   #=> "[2,1]"
 */
static VALUE doc_dump(int argc, VALUE *argv, VALUE self) {
    Doc         doc = self_doc(self);
    Leaf        leaf;
    const char *path     = 0;
    const char *filename = 0;

    if (1 <= argc) {
        if (Qnil != *argv) {
            path = StringValuePtr(*argv);
        }
        if (2 <= argc) {
            filename = StringValuePtr(argv[1]);
        }
    }
    if (0 != (leaf = get_doc_leaf(doc, path))) {
        volatile VALUE rjson;

        if (0 == filename) {
            struct _out out;

            oj_out_init(&out);

            out.omit_nil = oj_default_options.dump_opts.omit_nil;
            oj_dump_leaf_to_json(leaf, &oj_default_options, &out);
            rjson = rb_str_new2(out.buf);

            oj_out_free(&out);
        } else {
            oj_write_leaf_to_file(leaf, filename, &oj_default_options);
            rjson = Qnil;
        }
        return rjson;
    }
    return Qnil;
}

/* @overload size() => Fixnum
 *
 * Returns the number of nodes in the JSON document where a node is any one of
 * the basic JSON components.
 * @return Returns the size of the JSON document.
 * @example
 *   Oj::Doc.open('[1,2,3]') { |doc| doc.size() }  #=> 4
 */
static VALUE doc_size(VALUE self) {
    Doc d;
    TypedData_Get_Struct(self, struct _doc, &oj_doc_type, d);
    return ULONG2NUM(d->size);
}

/* @overload close() => nil
 *
 * Closes an open document. No further calls to the document will be valid
 * after closing.
 * @example
 *   doc = Oj::Doc.open('[1,2,3]')
 *   doc.size()  #=> 4
 *   doc.close()
 */
static VALUE doc_close(VALUE self) {
    Doc doc = self_doc(self);

    rb_gc_unregister_address(&doc->self);
    DATA_PTR(doc->self) = NULL;
    if (0 != doc) {
        doc_free(doc);
    }
    return Qnil;
}
#if 0
// hack to keep the doc generator happy
Oj = rb_define_module("Oj");
#endif

static VALUE doc_not_implemented(VALUE self) {
    rb_raise(rb_eNotImpError, "Not implemented.");
    return Qnil;
}

/* Document-class: Oj::Doc
 *
 * The Doc class is used to parse and navigate a JSON document. The model it
 * employs is that of a document that while open can be navigated and values
 * extracted. Once the document is closed the document can not longer be
 * accessed. This allows the parsing and data extraction to be extremely fast
 * compared to other JSON parses.
 *
 * An Oj::Doc class is not created directly but the _open()_ class method is
 * used to open a document and the yield parameter to the block of the #open()
 * call is the Doc instance. The Doc instance can be moved across, up, and
 * down the JSON document. At each element the data associated with the
 * element can be extracted. It is also possible to just provide a path to the
 * data to be extracted and retrieve the data in that manner.
 *
 * For many of the methods a path is used to describe the location of an
 * element. Paths follow a subset of the XPath syntax. The slash ('/')
 * character is the separator. Each step in the path identifies the next
 * branch to take through the document. A JSON object will expect a key string
 * while an array will expect a positive index. A .. step indicates a move up
 * the JSON document.
 *
 * @example
 *   json = %{[
 *     {
 *       "one"   : 1,
 *       "two"   : 2
 *     },
 *     {
 *       "three" : 3,
 *       "four"  : 4
 *     }
 *   ]}
 *   # move and get value
 *   Oj::Doc.open(json) do |doc|
 *     doc.move('/1/two')
 *     # doc location is now at the 'two' element of the hash that is the first
 * element of the array. doc.fetch() end
 *   #=> 2
 *
 *   # Now try again using a path to Oj::Doc.fetch() directly and not using a
 * block. doc = Oj::Doc.open(json) doc.fetch('/2/three')  #=> 3 doc.close()
 */
void oj_init_doc(void) {
    oj_doc_class = rb_define_class_under(Oj, "Doc", rb_cObject);
    rb_gc_register_address(&oj_doc_class);
    rb_undef_alloc_func(oj_doc_class);
    rb_define_singleton_method(oj_doc_class, "open", doc_open, 1);
    rb_define_singleton_method(oj_doc_class, "open_file", doc_open_file, 1);
    rb_define_singleton_method(oj_doc_class, "parse", doc_open, 1);
    rb_define_method(oj_doc_class, "where?", doc_where_q, 0);
    rb_define_method(oj_doc_class, "where", doc_where, 0);
    rb_define_method(oj_doc_class, "path", doc_path, 0);
    rb_define_method(oj_doc_class, "local_key", doc_local_key, 0);
    rb_define_method(oj_doc_class, "home", doc_home, 0);
    rb_define_method(oj_doc_class, "type", doc_type, -1);
    rb_define_method(oj_doc_class, "fetch", doc_fetch, -1);
    rb_define_method(oj_doc_class, "exists?", doc_exists, 1);
    rb_define_method(oj_doc_class, "each_leaf", doc_each_leaf, -1);
    rb_define_method(oj_doc_class, "move", doc_move, 1);
    rb_define_method(oj_doc_class, "each_child", doc_each_child, -1);
    rb_define_method(oj_doc_class, "each_value", doc_each_value, -1);
    rb_define_method(oj_doc_class, "dump", doc_dump, -1);
    rb_define_method(oj_doc_class, "size", doc_size, 0);
    rb_define_method(oj_doc_class, "close", doc_close, 0);

    rb_define_method(oj_doc_class, "clone", doc_not_implemented, 0);
    rb_define_method(oj_doc_class, "dup", doc_not_implemented, 0);
}
