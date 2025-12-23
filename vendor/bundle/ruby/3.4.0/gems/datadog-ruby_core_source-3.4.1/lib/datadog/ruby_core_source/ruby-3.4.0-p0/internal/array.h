#ifndef INTERNAL_ARRAY_H                                 /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_ARRAY_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Array.
 */
#include "ruby/internal/config.h"
#include <stddef.h>                 /* for size_t */
#include "internal/static_assert.h" /* for STATIC_ASSERT */
#include "ruby/internal/stdbool.h"         /* for bool */
#include "ruby/ruby.h"              /* for RARRAY_LEN */

#ifndef ARRAY_DEBUG
# define ARRAY_DEBUG (0+RUBY_DEBUG)
#endif

#define RARRAY_SHARED_FLAG      ELTS_SHARED
#define RARRAY_SHARED_ROOT_FLAG FL_USER12
#define RARRAY_PTR_IN_USE_FLAG  FL_USER14

/* array.c */
VALUE rb_ary_hash_values(long len, const VALUE *elements);
VALUE rb_ary_last(int, const VALUE *, VALUE);
void rb_ary_set_len(VALUE, long);
void rb_ary_delete_same(VALUE, VALUE);
VALUE rb_ary_hidden_new_fill(long capa);
VALUE rb_ary_at(VALUE, VALUE);
size_t rb_ary_memsize(VALUE);
VALUE rb_to_array_type(VALUE obj);
VALUE rb_to_array(VALUE obj);
void rb_ary_cancel_sharing(VALUE ary);
size_t rb_ary_size_as_embedded(VALUE ary);
void rb_ary_make_embedded(VALUE ary);
bool rb_ary_embeddable_p(VALUE ary);
VALUE rb_ary_diff(VALUE ary1, VALUE ary2);
RUBY_EXTERN VALUE rb_cArray_empty_frozen;

static inline VALUE rb_ary_entry_internal(VALUE ary, long offset);
static inline bool ARY_PTR_USING_P(VALUE ary);

VALUE rb_ary_tmp_new_from_values(VALUE, long, const VALUE *);
VALUE rb_check_to_array(VALUE ary);
VALUE rb_ary_behead(VALUE, long);
VALUE rb_ary_aref1(VALUE ary, VALUE i);

struct rb_execution_context_struct;
VALUE rb_ec_ary_new_from_values(struct rb_execution_context_struct *ec, long n, const VALUE *elts);

// YJIT needs this function to never allocate and never raise
static inline VALUE
rb_ary_entry_internal(VALUE ary, long offset)
{
    long len = RARRAY_LEN(ary);
    const VALUE *ptr = RARRAY_CONST_PTR(ary);
    if (len == 0) return Qnil;
    if (offset < 0) {
        offset += len;
        if (offset < 0) return Qnil;
    }
    else if (len <= offset) {
        return Qnil;
    }
    return ptr[offset];
}

static inline bool
ARY_PTR_USING_P(VALUE ary)
{
    return FL_TEST_RAW(ary, RARRAY_PTR_IN_USE_FLAG);
}

RBIMPL_ATTR_MAYBE_UNUSED()
static inline int
ary_should_not_be_shared_and_embedded(VALUE ary)
{
    return !FL_ALL_RAW(ary, RARRAY_SHARED_FLAG|RARRAY_EMBED_FLAG);
}

static inline bool
ARY_SHARED_P(VALUE ary)
{
    assert(RB_TYPE_P(ary, T_ARRAY));
    assert(ary_should_not_be_shared_and_embedded(ary));
    return FL_TEST_RAW(ary, RARRAY_SHARED_FLAG);
}

static inline bool
ARY_EMBED_P(VALUE ary)
{
    assert(RB_TYPE_P(ary, T_ARRAY));
    assert(ary_should_not_be_shared_and_embedded(ary));
    return FL_TEST_RAW(ary, RARRAY_EMBED_FLAG);
}

static inline VALUE
ARY_SHARED_ROOT(VALUE ary)
{
    assert(ARY_SHARED_P(ary));
    return RARRAY(ary)->as.heap.aux.shared_root;
}

static inline bool
ARY_SHARED_ROOT_P(VALUE ary)
{
    assert(RB_TYPE_P(ary, T_ARRAY));
    return FL_TEST_RAW(ary, RARRAY_SHARED_ROOT_FLAG);
}

static inline long
ARY_SHARED_ROOT_REFCNT(VALUE ary)
{
    assert(ARY_SHARED_ROOT_P(ary));
    return RARRAY(ary)->as.heap.aux.capa;
}

#undef rb_ary_new_from_args
#if RBIMPL_HAS_WARNING("-Wgnu-zero-variadic-macro-arguments")
# /* Skip it; clang -pedantic doesn't like the following */
#elif defined(__GNUC__) && defined(HAVE_VA_ARGS_MACRO)
#define rb_ary_new_from_args(n, ...) \
    __extension__ ({ \
        const VALUE args_to_new_ary[] = {__VA_ARGS__}; \
        if (__builtin_constant_p(n)) { \
            STATIC_ASSERT(rb_ary_new_from_args, numberof(args_to_new_ary) == (n)); \
        } \
        rb_ary_new_from_values(numberof(args_to_new_ary), args_to_new_ary); \
    })
#endif

#undef RARRAY_AREF
RBIMPL_ATTR_PURE_UNLESS_DEBUG()
RBIMPL_ATTR_ARTIFICIAL()
static inline VALUE
RARRAY_AREF(VALUE ary, long i)
{
    VALUE val;
    RBIMPL_ASSERT_TYPE(ary, RUBY_T_ARRAY);

    RBIMPL_WARNING_PUSH();
#if defined(__GNUC__) && !defined(__clang__) && __GNUC__ == 13
    RBIMPL_WARNING_IGNORED(-Warray-bounds);
#endif
    val = RARRAY_CONST_PTR(ary)[i];
    RBIMPL_WARNING_POP();
    return val;
}

#endif /* INTERNAL_ARRAY_H */
