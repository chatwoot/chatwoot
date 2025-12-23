// Copyright (c) 2021, Peter Ohler, All rights reserved.

#include "usual.h"

#include "cache.h"
#include "mem.h"
#include "oj.h"
#include "parser.h"

// The Usual delegate builds Ruby objects during parsing. It makes use of
// three stacks. The first is the value stack. This is where parsed values are
// placed. With the value stack the bulk creation and setting can be used
// which is significantly faster than setting Array (15x) or Hash (3x)
// elements one at a time.
//
// The second stack is the collection stack. Each element on the collection
// stack marks the start of a Hash, Array, or Object.
//
// The third stack is the key stack which is used for Hash and Object
// members. The key stack elements store the keys that could be used for
// either a Hash or Object. Since the decision on whether the parent is a Hash
// or Object can not be made until the end of the JSON object the keys remain
// as strings until just before setting the Hash or Object members.
//
// The approach taken with the usual delegate is to configure the delegate for
// the parser up front so that the various options are not checked during
// parsing and thus avoiding conditionals as much as reasonably possible in
// the more time sensitive parsing. Configuration is simply setting the
// function pointers to point to the function to be used for the selected
// option.

#define DEBUG 0

static ID to_f_id = 0;
static ID ltlt_id = 0;
static ID hset_id = 0;

static char *str_dup(const char *s, size_t len) {
    char *d = OJ_R_ALLOC_N(char, len + 1);

    memcpy(d, s, len);
    d[len] = '\0';

    return d;
}

static VALUE form_str(const char *str, size_t len) {
    return rb_str_freeze(rb_utf8_str_new(str, len));
}

static VALUE form_sym(const char *str, size_t len) {
    return rb_str_intern(rb_utf8_str_new(str, len));
}

static VALUE form_attr(const char *str, size_t len) {
    char buf[256];

    if (sizeof(buf) - 2 <= len) {
        char *b = OJ_R_ALLOC_N(char, len + 2);
        ID    id;

        *b = '@';
        memcpy(b + 1, str, len);
        b[len + 1] = '\0';

        id = rb_intern3(buf, len + 1, oj_utf8_encoding);
        OJ_R_FREE(b);
        return id;
    }
    *buf = '@';
    memcpy(buf + 1, str, len);
    buf[len + 1] = '\0';

    return (VALUE)rb_intern3(buf, len + 1, oj_utf8_encoding);
}

static VALUE resolve_classname(VALUE mod, const char *classname, bool auto_define) {
    VALUE clas;
    ID    ci = rb_intern(classname);

    if (rb_const_defined_at(mod, ci)) {
        clas = rb_const_get_at(mod, ci);
    } else if (auto_define) {
        clas = rb_define_class_under(mod, classname, oj_bag_class);
    } else {
        clas = Qundef;
    }
    return clas;
}

static VALUE resolve_classpath(const char *name, size_t len, bool auto_define) {
    char        class_name[1024];
    VALUE       clas;
    char       *end = class_name + sizeof(class_name) - 1;
    char       *s;
    const char *n = name;

    clas = rb_cObject;
    for (s = class_name; 0 < len; n++, len--) {
        if (':' == *n) {
            *s = '\0';
            n++;
            len--;
            if (':' != *n) {
                return Qundef;
            }
            if (Qundef == (clas = resolve_classname(clas, class_name, auto_define))) {
                return Qundef;
            }
            s = class_name;
        } else if (end <= s) {
            return Qundef;
        } else {
            *s++ = *n;
        }
    }
    *s = '\0';
    return resolve_classname(clas, class_name, auto_define);
}

static VALUE form_class(const char *str, size_t len) {
    return resolve_classpath(str, len, false);
}

static VALUE form_class_auto(const char *str, size_t len) {
    return resolve_classpath(str, len, true);
}

static void assure_cstack(Usual d) {
    if (d->cend <= d->ctail + 1) {
        size_t cap = d->cend - d->chead;
        long   pos = d->ctail - d->chead;

        cap *= 2;
        OJ_R_REALLOC_N(d->chead, struct _col, cap);
        d->ctail = d->chead + pos;
        d->cend  = d->chead + cap;
    }
}

static void push(ojParser p, VALUE v) {
    Usual d = (Usual)p->ctx;

    if (d->vend <= d->vtail) {
        size_t cap = d->vend - d->vhead;
        long   pos = d->vtail - d->vhead;

        cap *= 2;
        OJ_R_REALLOC_N(d->vhead, VALUE, cap);
        d->vtail = d->vhead + pos;
        d->vend  = d->vhead + cap;
    }
    *d->vtail = v;
    d->vtail++;
}

static VALUE cache_key(ojParser p, Key kp) {
    Usual d = (Usual)p->ctx;

    if ((size_t)kp->len < sizeof(kp->buf)) {
        return cache_intern(d->key_cache, kp->buf, kp->len);
    }
    return cache_intern(d->key_cache, kp->key, kp->len);
}

static VALUE str_key(ojParser p, Key kp) {
    if ((size_t)kp->len < sizeof(kp->buf)) {
        return rb_str_freeze(rb_utf8_str_new(kp->buf, kp->len));
    }
    return rb_str_freeze(rb_utf8_str_new(kp->key, kp->len));
}

static VALUE sym_key(ojParser p, Key kp) {
    if ((size_t)kp->len < sizeof(kp->buf)) {
        return rb_str_freeze(rb_str_intern(rb_utf8_str_new(kp->buf, kp->len)));
    }
    return rb_str_freeze(rb_str_intern(rb_utf8_str_new(kp->key, kp->len)));
}

static ID get_attr_id(ojParser p, Key kp) {
    Usual d = (Usual)p->ctx;

    if ((size_t)kp->len < sizeof(kp->buf)) {
        return (ID)cache_intern(d->attr_cache, kp->buf, kp->len);
    }
    return (ID)cache_intern(d->attr_cache, kp->key, kp->len);
}

static void push_key(ojParser p) {
    Usual       d    = (Usual)p->ctx;
    size_t      klen = buf_len(&p->key);
    const char *key  = buf_str(&p->key);

    if (d->kend <= d->ktail) {
        size_t cap = d->kend - d->khead;
        long   pos = d->ktail - d->khead;

        cap *= 2;
        OJ_R_REALLOC_N(d->khead, union _key, cap);
        d->ktail = d->khead + pos;
        d->kend  = d->khead + cap;
    }
    d->ktail->len = klen;
    if (klen < sizeof(d->ktail->buf)) {
        memcpy(d->ktail->buf, key, klen);
        d->ktail->buf[klen] = '\0';
    } else {
        d->ktail->key = str_dup(key, klen);
    }
    d->ktail++;
}

static void push2(ojParser p, VALUE v) {
    Usual d = (Usual)p->ctx;

    if (d->vend <= d->vtail + 1) {
        size_t cap = d->vend - d->vhead;
        long   pos = d->vtail - d->vhead;

        cap *= 2;
        OJ_R_REALLOC_N(d->vhead, VALUE, cap);
        d->vtail = d->vhead + pos;
        d->vend  = d->vhead + cap;
    }
    *d->vtail = Qundef;  // key place holder
    d->vtail++;
    *d->vtail = v;
    d->vtail++;
}

static void open_object(ojParser p) {
    Usual d = (Usual)p->ctx;

    assure_cstack(d);
    d->ctail->vi = d->vtail - d->vhead;
    d->ctail->ki = d->ktail - d->khead;
    d->ctail++;
    push(p, Qundef);
}

static void open_object_key(ojParser p) {
    Usual d = (Usual)p->ctx;

    push_key(p);
    assure_cstack(d);
    d->ctail->vi = d->vtail - d->vhead + 1;
    d->ctail->ki = d->ktail - d->khead;
    d->ctail++;
    push2(p, Qundef);
}

static void open_array(ojParser p) {
    Usual d = (Usual)p->ctx;

    assure_cstack(d);
    d->ctail->vi = d->vtail - d->vhead;
    d->ctail->ki = -1;
    d->ctail++;
    push(p, Qundef);
}

static void open_array_key(ojParser p) {
    Usual d = (Usual)p->ctx;

    push_key(p);
    assure_cstack(d);
    d->ctail->vi = d->vtail - d->vhead + 1;
    d->ctail->ki = -1;
    d->ctail++;
    push2(p, Qundef);
}

static void close_object(ojParser p) {
    VALUE *vp;
    Usual  d = (Usual)p->ctx;

    d->ctail--;

    Col            c    = d->ctail;
    Key            kp   = d->khead + c->ki;
    VALUE         *head = d->vhead + c->vi + 1;
    volatile VALUE obj  = rb_hash_new();

    for (vp = head; kp < d->ktail; kp++, vp += 2) {
        *vp = d->get_key(p, kp);
        if (sizeof(kp->buf) <= (size_t)kp->len) {
            OJ_R_FREE(kp->key);
        }
    }
    rb_hash_bulk_insert(d->vtail - head, head, obj);
    d->ktail = d->khead + c->ki;

    d->vtail = head;
    head--;
    *head = obj;
    if (1 == d->vtail - d->vhead && rb_block_given_p()) {
        d->vtail = d->vhead;
        rb_yield(obj);
    }
}

static void close_object_class(ojParser p) {
    VALUE *vp;
    Usual  d = (Usual)p->ctx;

    d->ctail--;

    Col            c    = d->ctail;
    Key            kp   = d->khead + c->ki;
    VALUE         *head = d->vhead + c->vi + 1;
    volatile VALUE obj  = rb_class_new_instance(0, NULL, d->hash_class);

    for (vp = head; kp < d->ktail; kp++, vp += 2) {
        rb_funcall(obj, hset_id, 2, d->get_key(p, kp), *(vp + 1));
        if (sizeof(kp->buf) <= (size_t)kp->len) {
            OJ_R_FREE(kp->key);
        }
    }
    d->ktail = d->khead + c->ki;
    d->vtail = head;
    head--;
    *head = obj;
}

static void close_object_create(ojParser p) {
    VALUE *vp;
    Usual  d = (Usual)p->ctx;

    d->ctail--;

    Col            c    = d->ctail;
    Key            kp   = d->khead + c->ki;
    VALUE         *head = d->vhead + c->vi;
    volatile VALUE obj;

    if (Qundef == *head) {
        head++;
        if (Qnil == d->hash_class) {
            obj = rb_hash_new();
            for (vp = head; kp < d->ktail; kp++, vp += 2) {
                *vp = d->get_key(p, kp);
                if (sizeof(kp->buf) <= (size_t)kp->len) {
                    OJ_R_FREE(kp->key);
                }
            }
            rb_hash_bulk_insert(d->vtail - head, head, obj);
        } else {
            obj = rb_class_new_instance(0, NULL, d->hash_class);
            for (vp = head; kp < d->ktail; kp++, vp += 2) {
                rb_funcall(obj, hset_id, 2, d->get_key(p, kp), *(vp + 1));
                if (sizeof(kp->buf) <= (size_t)kp->len) {
                    OJ_R_FREE(kp->key);
                }
            }
        }
    } else {
        VALUE clas = *head;

        head++;
        if (!d->ignore_json_create && rb_respond_to(clas, oj_json_create_id)) {
            volatile VALUE arg = rb_hash_new();

            for (vp = head; kp < d->ktail; kp++, vp += 2) {
                *vp = d->get_key(p, kp);
                if (sizeof(kp->buf) <= (size_t)kp->len) {
                    OJ_R_FREE(kp->key);
                }
            }
            rb_hash_bulk_insert(d->vtail - head, head, arg);
            obj = rb_funcall(clas, oj_json_create_id, 1, arg);
        } else {
            obj = rb_class_new_instance(0, NULL, clas);
            for (vp = head; kp < d->ktail; kp++, vp += 2) {
                rb_ivar_set(obj, get_attr_id(p, kp), *(vp + 1));
                if (sizeof(kp->buf) <= (size_t)kp->len) {
                    OJ_R_FREE(kp->key);
                }
            }
        }
    }
    d->ktail = d->khead + c->ki;
    d->vtail = head;
    head--;
    *head = obj;
}

static void close_array(ojParser p) {
    Usual d = (Usual)p->ctx;

    d->ctail--;
    VALUE         *head = d->vhead + d->ctail->vi + 1;
    volatile VALUE a    = rb_ary_new_from_values(d->vtail - head, head);

    d->vtail = head;
    head--;
    *head = a;
}

static void close_array_class(ojParser p) {
    VALUE *vp;
    Usual  d = (Usual)p->ctx;

    d->ctail--;
    VALUE         *head = d->vhead + d->ctail->vi + 1;
    volatile VALUE a    = rb_class_new_instance(0, NULL, d->array_class);

    for (vp = head; vp < d->vtail; vp++) {
        rb_funcall(a, ltlt_id, 1, *vp);
    }
    d->vtail = head;
    head--;
    *head = a;
}

static void noop(ojParser p) {
}

static void add_null(ojParser p) {
    push(p, Qnil);
}

static void add_null_key(ojParser p) {
    push_key(p);
    push2(p, Qnil);
}

static void add_true(ojParser p) {
    push(p, Qtrue);
}

static void add_true_key(ojParser p) {
    push_key(p);
    push2(p, Qtrue);
}

static void add_false(ojParser p) {
    push(p, Qfalse);
}

static void add_false_key(ojParser p) {
    push_key(p);
    push2(p, Qfalse);
}

static void add_int(ojParser p) {
    push(p, LONG2NUM(p->num.fixnum));
}

static void add_int_key(ojParser p) {
    push_key(p);
    push2(p, LONG2NUM(p->num.fixnum));
}

static void add_float(ojParser p) {
    push(p, rb_float_new(p->num.dub));
}

static void add_float_key(ojParser p) {
    push_key(p);
    push2(p, rb_float_new(p->num.dub));
}

static void add_float_as_big(ojParser p) {
    char buf[64];

    // snprintf fails on ubuntu and macOS for long double
    // snprintf(buf, sizeof(buf), "%Lg", p->num.dub);
    sprintf(buf, "%Lg", p->num.dub);
    push(p, rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new2(buf)));
}

static void add_float_as_big_key(ojParser p) {
    char buf[64];

    // snprintf fails on ubuntu and macOS for long double
    // snprintf(buf, sizeof(buf), "%Lg", p->num.dub);
    sprintf(buf, "%Lg", p->num.dub);
    push_key(p);
    push2(p, rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new2(buf)));
}

static void add_big(ojParser p) {
    push(p, rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf))));
}

static void add_big_key(ojParser p) {
    push_key(p);
    push2(p, rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf))));
}

static void add_big_as_float(ojParser p) {
    volatile VALUE big = rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf)));

    push(p, rb_funcall(big, to_f_id, 0));
}

static void add_big_as_float_key(ojParser p) {
    volatile VALUE big = rb_funcall(rb_cObject, oj_bigdecimal_id, 1, rb_str_new(buf_str(&p->buf), buf_len(&p->buf)));

    push_key(p);
    push2(p, rb_funcall(big, to_f_id, 0));
}

static void add_big_as_ruby(ojParser p) {
    push(p, rb_funcall(rb_str_new(buf_str(&p->buf), buf_len(&p->buf)), to_f_id, 0));
}

static void add_big_as_ruby_key(ojParser p) {
    push_key(p);
    push2(p, rb_funcall(rb_str_new(buf_str(&p->buf), buf_len(&p->buf)), to_f_id, 0));
}

static void add_str(ojParser p) {
    Usual          d = (Usual)p->ctx;
    volatile VALUE rstr;
    const char    *str = buf_str(&p->buf);
    size_t         len = buf_len(&p->buf);

    if (len < d->cache_str) {
        rstr = cache_intern(d->str_cache, str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    push(p, rstr);
}

static void add_str_key(ojParser p) {
    Usual          d = (Usual)p->ctx;
    volatile VALUE rstr;
    const char    *str = buf_str(&p->buf);
    size_t         len = buf_len(&p->buf);

    if (len < d->cache_str) {
        rstr = cache_intern(d->str_cache, str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    push_key(p);
    push2(p, rstr);
}

static void add_str_key_create(ojParser p) {
    Usual          d = (Usual)p->ctx;
    volatile VALUE rstr;
    const char    *str  = buf_str(&p->buf);
    size_t         len  = buf_len(&p->buf);
    const char    *key  = buf_str(&p->key);
    size_t         klen = buf_len(&p->key);

    if (klen == (size_t)d->create_id_len && 0 == strncmp(d->create_id, key, klen)) {
        Col   c = d->ctail - 1;
        VALUE clas;

        if (NULL != d->class_cache) {
            clas = cache_intern(d->class_cache, str, len);
        } else {
            clas = resolve_classpath(str, len, MISS_AUTO == d->miss_class);
        }
        if (Qundef != clas) {
            *(d->vhead + c->vi) = clas;
            return;
        }
        if (MISS_RAISE == d->miss_class) {
            rb_raise(rb_eLoadError, "%s is not define", str);
        }
    }
    if (len < d->cache_str) {
        rstr = cache_intern(d->str_cache, str, len);
    } else {
        rstr = rb_utf8_str_new(str, len);
    }
    push_key(p);
    push2(p, rstr);
}

static VALUE result(ojParser p) {
    Usual d = (Usual)p->ctx;

    if (d->vhead < d->vtail) {
        long            cnt = d->vtail - d->vhead;
        volatile VALUE  ary;
        volatile VALUE *vp;

        if (1 == cnt) {
            return *d->vhead;
        }
        ary = rb_ary_new();
        for (vp = d->vhead; vp < d->vtail; vp++) {
            rb_ary_push(ary, *vp);
        }
        return ary;
    }
    if (d->raise_on_empty) {
        rb_raise(oj_parse_error_class, "empty string");
    }
    return Qnil;
}

static void start(ojParser p) {
    Usual d = (Usual)p->ctx;

    d->vtail = d->vhead;
    d->ctail = d->chead;
    d->ktail = d->khead;
}

static void dfree(ojParser p) {
    Usual d = (Usual)p->ctx;

    cache_free(d->str_cache);
    cache_free(d->attr_cache);
    if (NULL != d->sym_cache) {
        cache_free(d->sym_cache);
    }
    if (NULL != d->class_cache) {
        cache_free(d->class_cache);
    }
    OJ_R_FREE(d->vhead);
    OJ_R_FREE(d->chead);
    OJ_R_FREE(d->khead);
    OJ_R_FREE(d->create_id);
    OJ_R_FREE(p->ctx);
    p->ctx = NULL;
}

static void mark(ojParser p) {
    if (NULL == p || NULL == p->ctx) {
        return;
    }
    Usual  d = (Usual)p->ctx;
    VALUE *vp;

    if (NULL == d) {
        return;
    }
    cache_mark(d->str_cache);
    if (NULL != d->sym_cache) {
        cache_mark(d->sym_cache);
    }
    if (NULL != d->class_cache) {
        cache_mark(d->class_cache);
    }
    for (vp = d->vhead; vp < d->vtail; vp++) {
        if (Qundef != *vp) {
            rb_gc_mark(*vp);
        }
    }
}

///// options /////////////////////////////////////////////////////////////////

// Each option is handled by a separate function and then added to an assoc
// list (struct opt}. The list is then iterated over until there is a name
// match. This is done primarily to keep each option separate and easier to
// understand instead of placing all in one large function.

struct opt {
    const char *name;
    VALUE (*func)(ojParser p, VALUE value);
};

static VALUE opt_array_class(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return d->array_class;
}

static VALUE opt_array_class_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    if (Qnil == value) {
        p->funcs[TOP_FUN].close_array    = close_array;
        p->funcs[ARRAY_FUN].close_array  = close_array;
        p->funcs[OBJECT_FUN].close_array = close_array;
    } else {
        rb_check_type(value, T_CLASS);
        if (!rb_method_boundp(value, ltlt_id, 1)) {
            rb_raise(rb_eArgError, "An array class must implement the << method.");
        }
        p->funcs[TOP_FUN].close_array    = close_array_class;
        p->funcs[ARRAY_FUN].close_array  = close_array_class;
        p->funcs[OBJECT_FUN].close_array = close_array_class;
    }
    d->array_class = value;

    return d->array_class;
}

static VALUE opt_cache_keys(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return d->cache_keys ? Qtrue : Qfalse;
}

static VALUE opt_cache_keys_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    if (Qtrue == value) {
        d->cache_keys = true;
        d->get_key    = cache_key;
        if (NULL == d->sym_cache) {
            d->key_cache = d->str_cache;
        } else {
            d->key_cache = d->sym_cache;
        }
    } else {
        d->cache_keys = false;
        if (NULL == d->sym_cache) {
            d->get_key = str_key;
        } else {
            d->get_key = sym_key;
        }
    }
    return d->cache_keys ? Qtrue : Qfalse;
}

static VALUE opt_cache_strings(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return INT2NUM((int)d->cache_str);
}

static VALUE opt_cache_strings_set(ojParser p, VALUE value) {
    Usual d     = (Usual)p->ctx;
    int   limit = NUM2INT(value);

    if (CACHE_MAX_KEY < limit) {
        limit = CACHE_MAX_KEY;
    } else if (limit < 0) {
        limit = 0;
    }
    d->cache_str = limit;

    return INT2NUM((int)d->cache_str);
}

static VALUE opt_cache_expunge(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return INT2NUM((int)d->cache_xrate);
}

static VALUE opt_cache_expunge_set(ojParser p, VALUE value) {
    Usual d    = (Usual)p->ctx;
    int   rate = NUM2INT(value);

    if (rate < 0) {
        rate = 0;
    } else if (3 < rate) {
        rate = 3;
    }
    d->cache_xrate = (uint8_t)rate;
    cache_set_expunge_rate(d->str_cache, rate);
    cache_set_expunge_rate(d->attr_cache, rate);
    if (NULL != d->sym_cache) {
        cache_set_expunge_rate(d->sym_cache, rate);
    }
    return INT2NUM((int)rate);
}

static VALUE opt_capacity(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return ULONG2NUM(d->vend - d->vhead);
}

static VALUE opt_capacity_set(ojParser p, VALUE value) {
    Usual d   = (Usual)p->ctx;
    long  cap = NUM2LONG(value);

    if (d->vend - d->vhead < cap) {
        long pos = d->vtail - d->vhead;

        OJ_R_REALLOC_N(d->vhead, VALUE, cap);
        d->vtail = d->vhead + pos;
        d->vend  = d->vhead + cap;
    }
    if (d->kend - d->khead < cap) {
        long pos = d->ktail - d->khead;

        OJ_R_REALLOC_N(d->khead, union _key, cap);
        d->ktail = d->khead + pos;
        d->kend  = d->khead + cap;
    }
    return ULONG2NUM(d->vend - d->vhead);
}

static VALUE opt_class_cache(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return (NULL != d->class_cache) ? Qtrue : Qfalse;
}

static VALUE opt_class_cache_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    if (Qtrue == value) {
        if (NULL == d->class_cache) {
            d->class_cache = cache_create(0, form_class_auto, MISS_AUTO == d->miss_class, false);
        }
    } else if (NULL != d->class_cache) {
        cache_free(d->class_cache);
        d->class_cache = NULL;
    }
    return (NULL != d->class_cache) ? Qtrue : Qfalse;
}

static VALUE opt_create_id(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    if (NULL == d->create_id) {
        return Qnil;
    }
    return rb_utf8_str_new(d->create_id, d->create_id_len);
}

static VALUE opt_create_id_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    if (Qnil == value) {
        d->create_id                 = NULL;
        d->create_id_len             = 0;
        p->funcs[OBJECT_FUN].add_str = add_str_key;
        if (Qnil == d->hash_class) {
            p->funcs[TOP_FUN].close_object    = close_object;
            p->funcs[ARRAY_FUN].close_object  = close_object;
            p->funcs[OBJECT_FUN].close_object = close_object;
        } else {
            p->funcs[TOP_FUN].close_object    = close_object_class;
            p->funcs[ARRAY_FUN].close_object  = close_object_class;
            p->funcs[OBJECT_FUN].close_object = close_object_class;
        }
    } else {
        rb_check_type(value, T_STRING);
        size_t len = RSTRING_LEN(value);

        if (1 << (8 * sizeof(d->create_id_len)) <= len) {
            rb_raise(rb_eArgError, "The create_id values is limited to %d bytes.", 1 << (8 * sizeof(d->create_id_len)));
        }
        d->create_id_len                  = (uint8_t)len;
        d->create_id                      = str_dup(RSTRING_PTR(value), len);
        p->funcs[OBJECT_FUN].add_str      = add_str_key_create;
        p->funcs[TOP_FUN].close_object    = close_object_create;
        p->funcs[ARRAY_FUN].close_object  = close_object_create;
        p->funcs[OBJECT_FUN].close_object = close_object_create;
    }
    return opt_create_id(p, value);
}

static VALUE opt_decimal(ojParser p, VALUE value) {
    if (add_float_as_big == p->funcs[TOP_FUN].add_float) {
        return ID2SYM(rb_intern("bigdecimal"));
    }
    if (add_big == p->funcs[TOP_FUN].add_big) {
        return ID2SYM(rb_intern("auto"));
    }
    if (add_big_as_float == p->funcs[TOP_FUN].add_big) {
        return ID2SYM(rb_intern("float"));
    }
    if (add_big_as_ruby == p->funcs[TOP_FUN].add_big) {
        return ID2SYM(rb_intern("ruby"));
    }
    return Qnil;
}

static VALUE opt_decimal_set(ojParser p, VALUE value) {
    const char    *mode;
    volatile VALUE s;

    switch (rb_type(value)) {
    case T_STRING: mode = RSTRING_PTR(value); break;
    case T_SYMBOL:
        s    = rb_sym2str(value);
        mode = RSTRING_PTR(s);
        break;
    default:
        rb_raise(rb_eTypeError,
                 "the decimal options must be a Symbol or String, not %s.",
                 rb_class2name(rb_obj_class(value)));
        break;
    }
    if (0 == strcmp("auto", mode)) {
        p->funcs[TOP_FUN].add_big      = add_big;
        p->funcs[ARRAY_FUN].add_big    = add_big;
        p->funcs[OBJECT_FUN].add_big   = add_big_key;
        p->funcs[TOP_FUN].add_float    = add_float;
        p->funcs[ARRAY_FUN].add_float  = add_float;
        p->funcs[OBJECT_FUN].add_float = add_float_key;

        return opt_decimal(p, Qnil);
    }
    if (0 == strcmp("bigdecimal", mode)) {
        p->funcs[TOP_FUN].add_big      = add_big;
        p->funcs[ARRAY_FUN].add_big    = add_big;
        p->funcs[OBJECT_FUN].add_big   = add_big_key;
        p->funcs[TOP_FUN].add_float    = add_float_as_big;
        p->funcs[ARRAY_FUN].add_float  = add_float_as_big;
        p->funcs[OBJECT_FUN].add_float = add_float_as_big_key;

        return opt_decimal(p, Qnil);
    }
    if (0 == strcmp("float", mode)) {
        p->funcs[TOP_FUN].add_big      = add_big_as_float;
        p->funcs[ARRAY_FUN].add_big    = add_big_as_float;
        p->funcs[OBJECT_FUN].add_big   = add_big_as_float_key;
        p->funcs[TOP_FUN].add_float    = add_float;
        p->funcs[ARRAY_FUN].add_float  = add_float;
        p->funcs[OBJECT_FUN].add_float = add_float_key;

        return opt_decimal(p, Qnil);
    }
    if (0 == strcmp("ruby", mode)) {
        p->funcs[TOP_FUN].add_big      = add_big_as_ruby;
        p->funcs[ARRAY_FUN].add_big    = add_big_as_ruby;
        p->funcs[OBJECT_FUN].add_big   = add_big_as_ruby_key;
        p->funcs[TOP_FUN].add_float    = add_float;
        p->funcs[ARRAY_FUN].add_float  = add_float;
        p->funcs[OBJECT_FUN].add_float = add_float_key;

        return opt_decimal(p, Qnil);
    }
    rb_raise(rb_eArgError, "%s is not a valid option for the decimal option.", mode);

    return Qnil;
}

static VALUE opt_hash_class(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return d->hash_class;
}

static VALUE opt_hash_class_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    if (Qnil != value) {
        rb_check_type(value, T_CLASS);
        if (!rb_method_boundp(value, hset_id, 1)) {
            rb_raise(rb_eArgError, "A hash class must implement the []= method.");
        }
    }
    d->hash_class = value;
    if (NULL == d->create_id) {
        if (Qnil == value) {
            p->funcs[TOP_FUN].close_object    = close_object;
            p->funcs[ARRAY_FUN].close_object  = close_object;
            p->funcs[OBJECT_FUN].close_object = close_object;
        } else {
            p->funcs[TOP_FUN].close_object    = close_object_class;
            p->funcs[ARRAY_FUN].close_object  = close_object_class;
            p->funcs[OBJECT_FUN].close_object = close_object_class;
        }
    }
    return d->hash_class;
}

static VALUE opt_ignore_json_create(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return d->ignore_json_create ? Qtrue : Qfalse;
}

static VALUE opt_ignore_json_create_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    d->ignore_json_create = (Qtrue == value);

    return d->ignore_json_create ? Qtrue : Qfalse;
}

static VALUE opt_missing_class(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    switch (d->miss_class) {
    case MISS_AUTO: return ID2SYM(rb_intern("auto"));
    case MISS_RAISE: return ID2SYM(rb_intern("raise"));
    case MISS_IGNORE:
    default: return ID2SYM(rb_intern("ignore"));
    }
}

static VALUE opt_missing_class_set(ojParser p, VALUE value) {
    Usual          d = (Usual)p->ctx;
    const char    *mode;
    volatile VALUE s;

    switch (rb_type(value)) {
    case T_STRING: mode = RSTRING_PTR(value); break;
    case T_SYMBOL:
        s    = rb_sym2str(value);
        mode = RSTRING_PTR(s);
        break;
    default:
        rb_raise(rb_eTypeError,
                 "the missing_class options must be a Symbol or String, not %s.",
                 rb_class2name(rb_obj_class(value)));
        break;
    }
    if (0 == strcmp("auto", mode)) {
        d->miss_class = MISS_AUTO;
        if (NULL != d->class_cache) {
            cache_set_form(d->class_cache, form_class_auto);
        }
    } else if (0 == strcmp("ignore", mode)) {
        d->miss_class = MISS_IGNORE;
        if (NULL != d->class_cache) {
            cache_set_form(d->class_cache, form_class);
        }
    } else if (0 == strcmp("raise", mode)) {
        d->miss_class = MISS_RAISE;
        if (NULL != d->class_cache) {
            cache_set_form(d->class_cache, form_class);
        }
    } else {
        rb_raise(rb_eArgError, "%s is not a valid value for the missing_class option.", mode);
    }
    return opt_missing_class(p, value);
}

static VALUE opt_omit_null(ojParser p, VALUE value) {
    return (noop == p->funcs[OBJECT_FUN].add_null) ? Qtrue : Qfalse;
}

static VALUE opt_omit_null_set(ojParser p, VALUE value) {
    if (Qtrue == value) {
        p->funcs[OBJECT_FUN].add_null = noop;
    } else {
        p->funcs[OBJECT_FUN].add_null = add_null_key;
    }
    return (noop == p->funcs[OBJECT_FUN].add_null) ? Qtrue : Qfalse;
}

static VALUE opt_symbol_keys(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return (NULL != d->sym_cache) ? Qtrue : Qfalse;
}

static VALUE opt_symbol_keys_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    if (Qtrue == value) {
        d->sym_cache = cache_create(0, form_sym, true, false);
        cache_set_expunge_rate(d->sym_cache, d->cache_xrate);
        d->key_cache = d->sym_cache;
        if (!d->cache_keys) {
            d->get_key = sym_key;
        }
    } else {
        if (NULL != d->sym_cache) {
            cache_free(d->sym_cache);
            d->sym_cache = NULL;
        }
        if (!d->cache_keys) {
            d->get_key = str_key;
        }
    }
    return (NULL != d->sym_cache) ? Qtrue : Qfalse;
}

static VALUE opt_raise_on_empty(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    return d->raise_on_empty ? Qtrue : Qfalse;
}

static VALUE opt_raise_on_empty_set(ojParser p, VALUE value) {
    Usual d = (Usual)p->ctx;

    d->raise_on_empty = (Qtrue == value);

    return d->raise_on_empty ? Qtrue : Qfalse;
}

static VALUE option(ojParser p, const char *key, VALUE value) {
    struct opt *op;
    struct opt  opts[] = {
        {.name = "array_class", .func = opt_array_class},
        {.name = "array_class=", .func = opt_array_class_set},
        {.name = "cache_keys", .func = opt_cache_keys},
        {.name = "cache_keys=", .func = opt_cache_keys_set},
        {.name = "cache_strings", .func = opt_cache_strings},
        {.name = "cache_strings=", .func = opt_cache_strings_set},
        {.name = "cache_expunge", .func = opt_cache_expunge},
        {.name = "cache_expunge=", .func = opt_cache_expunge_set},
        {.name = "capacity", .func = opt_capacity},
        {.name = "capacity=", .func = opt_capacity_set},
        {.name = "class_cache", .func = opt_class_cache},
        {.name = "class_cache=", .func = opt_class_cache_set},
        {.name = "create_id", .func = opt_create_id},
        {.name = "create_id=", .func = opt_create_id_set},
        {.name = "decimal", .func = opt_decimal},
        {.name = "decimal=", .func = opt_decimal_set},
        {.name = "hash_class", .func = opt_hash_class},
        {.name = "hash_class=", .func = opt_hash_class_set},
        {.name = "ignore_json_create", .func = opt_ignore_json_create},
        {.name = "ignore_json_create=", .func = opt_ignore_json_create_set},
        {.name = "missing_class", .func = opt_missing_class},
        {.name = "missing_class=", .func = opt_missing_class_set},
        {.name = "omit_null", .func = opt_omit_null},
        {.name = "omit_null=", .func = opt_omit_null_set},
        {.name = "symbol_keys", .func = opt_symbol_keys},
        {.name = "symbol_keys=", .func = opt_symbol_keys_set},
        {.name = "raise_on_empty", .func = opt_raise_on_empty},
        {.name = "raise_on_empty=", .func = opt_raise_on_empty_set},
        {.name = NULL},
    };

    for (op = opts; NULL != op->name; op++) {
        if (0 == strcmp(key, op->name)) {
            return op->func(p, value);
        }
    }
    rb_raise(rb_eArgError, "%s is not an option for the Usual delegate", key);

    return Qnil;  // Never reached due to the raise but required by the compiler.
}

///// the set up //////////////////////////////////////////////////////////////

void oj_init_usual(ojParser p, Usual d) {
    int cap = 4096;

    d->vhead = OJ_R_ALLOC_N(VALUE, cap);
    d->vend  = d->vhead + cap;
    d->vtail = d->vhead;

    d->khead = OJ_R_ALLOC_N(union _key, cap);
    d->kend  = d->khead + cap;
    d->ktail = d->khead;

    cap      = 256;
    d->chead = OJ_R_ALLOC_N(struct _col, cap);
    d->cend  = d->chead + cap;
    d->ctail = d->chead;

    d->get_key            = cache_key;
    d->cache_keys         = true;
    d->ignore_json_create = false;
    d->raise_on_empty     = false;
    d->cache_str          = 6;
    d->array_class        = Qnil;
    d->hash_class         = Qnil;
    d->create_id          = NULL;
    d->create_id_len      = 0;
    d->miss_class         = MISS_IGNORE;
    d->cache_xrate        = 1;

    Funcs f         = &p->funcs[TOP_FUN];
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

    f               = &p->funcs[ARRAY_FUN];
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

    f               = &p->funcs[OBJECT_FUN];
    f->add_null     = add_null_key;
    f->add_true     = add_true_key;
    f->add_false    = add_false_key;
    f->add_int      = add_int_key;
    f->add_float    = add_float_key;
    f->add_big      = add_big_key;
    f->add_str      = add_str_key;
    f->open_array   = open_array_key;
    f->close_array  = close_array;
    f->open_object  = open_object_key;
    f->close_object = close_object;

    d->str_cache   = cache_create(0, form_str, true, false);
    d->attr_cache  = cache_create(0, form_attr, false, false);
    d->sym_cache   = NULL;
    d->class_cache = NULL;
    d->key_cache   = d->str_cache;

    // The parser fields are set but the functions can be replaced by a
    // delegate that wraps the usual delegate.
    p->ctx    = (void *)d;
    p->option = option;
    p->result = result;
    p->free   = dfree;
    p->mark   = mark;
    p->start  = start;

    if (0 == to_f_id) {
        to_f_id = rb_intern("to_f");
    }
    if (0 == ltlt_id) {
        ltlt_id = rb_intern("<<");
    }
    if (0 == hset_id) {
        hset_id = rb_intern("[]=");
    }
}

void oj_set_parser_usual(ojParser p) {
    Usual d = OJ_R_ALLOC(struct _usual);

    oj_init_usual(p, d);
}
