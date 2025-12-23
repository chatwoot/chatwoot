#ifndef INTERNAL_IMEMO_H                                 /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_IMEMO_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      IMEMO: Internal memo object.
 */
#include "ruby/internal/config.h"
#include <stddef.h>             /* for size_t */
#include "internal/array.h"     /* for rb_ary_hidden_new_fill */
#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/ruby.h"          /* for rb_block_call_func_t */

#ifndef IMEMO_DEBUG
# define IMEMO_DEBUG 0
#endif

#define IMEMO_MASK   0x0f

/* FL_USER0 to FL_USER3 is for type */
#define IMEMO_FL_USHIFT (FL_USHIFT + 4)
#define IMEMO_FL_USER0 FL_USER4
#define IMEMO_FL_USER1 FL_USER5
#define IMEMO_FL_USER2 FL_USER6
#define IMEMO_FL_USER3 FL_USER7
#define IMEMO_FL_USER4 FL_USER8
#define IMEMO_FL_USER5 FL_USER9

enum imemo_type {
    imemo_env            =  0,
    imemo_cref           =  1, /*!< class reference */
    imemo_svar           =  2, /*!< special variable */
    imemo_throw_data     =  3,
    imemo_ifunc          =  4, /*!< iterator function */
    imemo_memo           =  5,
    imemo_ment           =  6,
    imemo_iseq           =  7,
    imemo_tmpbuf         =  8,
    imemo_ast            =  9, // Obsolete due to the universal parser
    imemo_parser_strterm = 10,
    imemo_callinfo       = 11,
    imemo_callcache      = 12,
    imemo_constcache     = 13,
};

/* CREF (Class REFerence) is defined in method.h */

/*! SVAR (Special VARiable) */
struct vm_svar {
    VALUE flags;
    const VALUE cref_or_me; /*!< class reference or rb_method_entry_t */
    const VALUE lastline;
    const VALUE backref;
    const VALUE others;
};

/*! THROW_DATA */
struct vm_throw_data {
    VALUE flags;
    VALUE reserved;
    const VALUE throw_obj;
    const struct rb_control_frame_struct *catch_frame;
    int throw_state;
};

#define THROW_DATA_CONSUMED IMEMO_FL_USER0

/* IFUNC (Internal FUNCtion) */

struct vm_ifunc_argc {
#if SIZEOF_INT * 2 > SIZEOF_VALUE
    signed int min: (SIZEOF_VALUE * CHAR_BIT) / 2;
    signed int max: (SIZEOF_VALUE * CHAR_BIT) / 2;
#else
    int min, max;
#endif
};

/*! IFUNC (Internal FUNCtion)
 *
 * Bookkeeping for converting a C function and some closed-over data into a
 * block passable to methods. Like Ruby Proc, but not directly accessible at
 * Ruby level since this is an imemo. See rb_block_call() and friends.
 */
struct vm_ifunc {
    VALUE flags;
    VALUE *svar_lep;
    rb_block_call_func_t func;
    const void *data;
    struct vm_ifunc_argc argc;
};
#define IFUNC_YIELD_OPTIMIZABLE IMEMO_FL_USER0

struct rb_imemo_tmpbuf_struct {
    VALUE flags;
    VALUE reserved;
    VALUE *ptr; /* malloc'ed buffer */
    struct rb_imemo_tmpbuf_struct *next; /* next imemo */
    size_t cnt; /* buffer size in VALUE */
};

/*! MEMO
 *
 * @see imemo_type
 * */
struct MEMO {
    VALUE flags;
    VALUE reserved;
    const VALUE v1;
    const VALUE v2;
    union {
        long cnt;
        long state;
        const VALUE value;
        void (*func)(void);
    } u3;
};

#define IMEMO_NEW(T, type, v0) ((T *)rb_imemo_new((type), (v0)))

/* ment is in method.h */

#define THROW_DATA_P(err) imemo_throw_data_p((VALUE)err)
#define MEMO_CAST(m) ((struct MEMO *)(m))
#define MEMO_FOR(type, value) ((type *)RARRAY_PTR(value))
#define NEW_MEMO_FOR(type, value) \
  ((value) = rb_ary_hidden_new_fill(type_roomof(type, VALUE)), MEMO_FOR(type, value))
#define NEW_PARTIAL_MEMO_FOR(type, value, member) \
  ((value) = rb_ary_hidden_new_fill(type_roomof(type, VALUE)), \
   rb_ary_set_len((value), offsetof(type, member) / sizeof(VALUE)), \
   MEMO_FOR(type, value))

#ifndef RUBY_RUBYPARSER_H
typedef struct rb_imemo_tmpbuf_struct rb_imemo_tmpbuf_t;
#endif
rb_imemo_tmpbuf_t *rb_imemo_tmpbuf_parser_heap(void *buf, rb_imemo_tmpbuf_t *old_heap, size_t cnt);
struct vm_ifunc *rb_vm_ifunc_new(rb_block_call_func_t func, const void *data, int min_argc, int max_argc);
static inline enum imemo_type imemo_type(VALUE imemo);
static inline int imemo_type_p(VALUE imemo, enum imemo_type imemo_type);
static inline bool imemo_throw_data_p(VALUE imemo);
static inline struct vm_ifunc *rb_vm_ifunc_proc_new(rb_block_call_func_t func, const void *data);
static inline VALUE rb_imemo_tmpbuf_auto_free_pointer(void);
static inline void *RB_IMEMO_TMPBUF_PTR(VALUE v);
static inline void *rb_imemo_tmpbuf_set_ptr(VALUE v, void *ptr);
static inline VALUE rb_imemo_tmpbuf_auto_free_pointer_new_from_an_RString(VALUE str);
static inline void MEMO_V1_SET(struct MEMO *m, VALUE v);
static inline void MEMO_V2_SET(struct MEMO *m, VALUE v);

size_t rb_imemo_memsize(VALUE obj);
void rb_cc_table_mark(VALUE klass);
void rb_imemo_mark_and_move(VALUE obj, bool reference_updating);
void rb_cc_table_free(VALUE klass);
void rb_imemo_free(VALUE obj);

RUBY_SYMBOL_EXPORT_BEGIN
#if IMEMO_DEBUG
VALUE rb_imemo_new_debug(enum imemo_type type, VALUE v0, const char *file, int line);
#define rb_imemo_new(type, v1, v2, v3, v0) rb_imemo_new_debug(type, v1, v2, v3, v0, __FILE__, __LINE__)
#else
VALUE rb_imemo_new(enum imemo_type type, VALUE v0);
#endif
const char *rb_imemo_name(enum imemo_type type);
RUBY_SYMBOL_EXPORT_END

static inline struct MEMO *
MEMO_NEW(VALUE a, VALUE b, VALUE c)
{
    struct MEMO *memo = IMEMO_NEW(struct MEMO, imemo_memo, 0);
    *((VALUE *)&memo->v1) = a;
    *((VALUE *)&memo->v2) = b;
    *((VALUE *)&memo->u3.value) = c;

    return memo;
}

static inline enum imemo_type
imemo_type(VALUE imemo)
{
    return (RBASIC(imemo)->flags >> FL_USHIFT) & IMEMO_MASK;
}

static inline int
imemo_type_p(VALUE imemo, enum imemo_type imemo_type)
{
    if (LIKELY(!RB_SPECIAL_CONST_P(imemo))) {
        /* fixed at compile time if imemo_type is given. */
        const VALUE mask = (IMEMO_MASK << FL_USHIFT) | RUBY_T_MASK;
        const VALUE expected_type = (imemo_type << FL_USHIFT) | T_IMEMO;
        /* fixed at runtime. */
        return expected_type == (RBASIC(imemo)->flags & mask);
    }
    else {
        return 0;
    }
}

#define IMEMO_TYPE_P(v, t) imemo_type_p((VALUE)(v), t)

static inline bool
imemo_throw_data_p(VALUE imemo)
{
    return RB_TYPE_P(imemo, T_IMEMO);
}

static inline struct vm_ifunc *
rb_vm_ifunc_proc_new(rb_block_call_func_t func, const void *data)
{
    return rb_vm_ifunc_new(func, data, 0, UNLIMITED_ARGUMENTS);
}

static inline VALUE
rb_imemo_tmpbuf_auto_free_pointer(void)
{
    return rb_imemo_new(imemo_tmpbuf, 0);
}

static inline void *
RB_IMEMO_TMPBUF_PTR(VALUE v)
{
    const struct rb_imemo_tmpbuf_struct *p = (const void *)v;
    return p->ptr;
}

static inline void *
rb_imemo_tmpbuf_set_ptr(VALUE v, void *ptr)
{
    return ((rb_imemo_tmpbuf_t *)v)->ptr = ptr;
}

static inline VALUE
rb_imemo_tmpbuf_auto_free_pointer_new_from_an_RString(VALUE str)
{
    const void *src;
    VALUE imemo;
    rb_imemo_tmpbuf_t *tmpbuf;
    void *dst;
    size_t len;

    StringValue(str);
    /* create tmpbuf to keep the pointer before xmalloc */
    imemo = rb_imemo_tmpbuf_auto_free_pointer();
    tmpbuf = (rb_imemo_tmpbuf_t *)imemo;
    len = RSTRING_LEN(str);
    src = RSTRING_PTR(str);
    dst = ruby_xmalloc(len);
    memcpy(dst, src, len);
    tmpbuf->ptr = dst;
    return imemo;
}

static inline void
MEMO_V1_SET(struct MEMO *m, VALUE v)
{
    RB_OBJ_WRITE(m, &m->v1, v);
}

static inline void
MEMO_V2_SET(struct MEMO *m, VALUE v)
{
    RB_OBJ_WRITE(m, &m->v2, v);
}

#endif /* INTERNAL_IMEMO_H */
