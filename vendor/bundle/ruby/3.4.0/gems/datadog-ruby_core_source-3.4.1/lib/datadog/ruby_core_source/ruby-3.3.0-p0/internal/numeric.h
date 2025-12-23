#ifndef INTERNAL_NUMERIC_H                               /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_NUMERIC_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Numeric.
 */
#include "internal/bignum.h"    /* for BIGNUM_POSITIVE_P */
#include "internal/bits.h"      /* for RUBY_BIT_ROTL */
#include "internal/fixnum.h"    /* for FIXNUM_POSITIVE_P */
#include "internal/vm.h"        /* for rb_method_basic_definition_p */
#include "ruby/intern.h"        /* for rb_cmperr */
#include "ruby/ruby.h"          /* for USE_FLONUM */

#define ROUND_TO(mode, even, up, down) \
    ((mode) == RUBY_NUM_ROUND_HALF_EVEN ? even : \
     (mode) == RUBY_NUM_ROUND_HALF_UP ? up : down)
#define ROUND_FUNC(mode, name) \
    ROUND_TO(mode, name##_half_even, name##_half_up, name##_half_down)
#define ROUND_CALL(mode, name, args) \
    ROUND_TO(mode, name##_half_even args, \
             name##_half_up args, name##_half_down args)

#ifndef ROUND_DEFAULT
# define ROUND_DEFAULT RUBY_NUM_ROUND_HALF_UP
#endif

enum ruby_num_rounding_mode {
    RUBY_NUM_ROUND_HALF_UP,
    RUBY_NUM_ROUND_HALF_EVEN,
    RUBY_NUM_ROUND_HALF_DOWN,
    RUBY_NUM_ROUND_DEFAULT = ROUND_DEFAULT,
};

/* same as internal.h */
#define numberof(array) ((int)(sizeof(array) / sizeof((array)[0])))
#define roomof(x, y) (((x) + (y) - 1) / (y))
#define type_roomof(x, y) roomof(sizeof(x), sizeof(y))

#if SIZEOF_DOUBLE <= SIZEOF_VALUE
typedef double rb_float_value_type;
#else
typedef struct {
    VALUE values[roomof(SIZEOF_DOUBLE, SIZEOF_VALUE)];
} rb_float_value_type;
#endif

struct RFloat {
    struct RBasic basic;
    rb_float_value_type float_value;
};

#define RFLOAT(obj)  ((struct RFloat *)(obj))

/* numeric.c */
int rb_num_to_uint(VALUE val, unsigned int *ret);
VALUE ruby_num_interval_step_size(VALUE from, VALUE to, VALUE step, int excl);
double ruby_float_step_size(double beg, double end, double unit, int excl);
int ruby_float_step(VALUE from, VALUE to, VALUE step, int excl, int allow_endless);
int rb_num_negative_p(VALUE);
VALUE rb_int_succ(VALUE num);
VALUE rb_float_uminus(VALUE num);
VALUE rb_int_plus(VALUE x, VALUE y);
VALUE rb_float_plus(VALUE x, VALUE y);
VALUE rb_int_minus(VALUE x, VALUE y);
VALUE rb_float_minus(VALUE x, VALUE y);
VALUE rb_int_mul(VALUE x, VALUE y);
VALUE rb_float_mul(VALUE x, VALUE y);
VALUE rb_float_div(VALUE x, VALUE y);
VALUE rb_int_idiv(VALUE x, VALUE y);
VALUE rb_int_modulo(VALUE x, VALUE y);
VALUE rb_int2str(VALUE num, int base);
VALUE rb_fix_plus(VALUE x, VALUE y);
VALUE rb_int_gt(VALUE x, VALUE y);
VALUE rb_float_gt(VALUE x, VALUE y);
VALUE rb_int_ge(VALUE x, VALUE y);
enum ruby_num_rounding_mode rb_num_get_rounding_option(VALUE opts);
double rb_int_fdiv_double(VALUE x, VALUE y);
VALUE rb_int_pow(VALUE x, VALUE y);
VALUE rb_float_pow(VALUE x, VALUE y);
VALUE rb_int_cmp(VALUE x, VALUE y);
VALUE rb_int_equal(VALUE x, VALUE y);
VALUE rb_int_divmod(VALUE x, VALUE y);
VALUE rb_int_and(VALUE x, VALUE y);
VALUE rb_int_lshift(VALUE x, VALUE y);
VALUE rb_int_div(VALUE x, VALUE y);
int rb_int_positive_p(VALUE num);
int rb_int_negative_p(VALUE num);
VALUE rb_check_integer_type(VALUE);
VALUE rb_num_pow(VALUE x, VALUE y);
VALUE rb_float_ceil(VALUE num, int ndigits);
VALUE rb_float_floor(VALUE x, int ndigits);
VALUE rb_float_abs(VALUE flt);
static inline VALUE rb_num_compare_with_zero(VALUE num, ID mid);
static inline int rb_num_positive_int_p(VALUE num);
static inline int rb_num_negative_int_p(VALUE num);
static inline double rb_float_flonum_value(VALUE v);
static inline double rb_float_noflonum_value(VALUE v);
static inline double rb_float_value_inline(VALUE v);
static inline VALUE rb_float_new_inline(double d);
static inline bool INT_POSITIVE_P(VALUE num);
static inline bool INT_NEGATIVE_P(VALUE num);
static inline bool FLOAT_ZERO_P(VALUE num);
#define rb_float_value rb_float_value_inline
#define rb_float_new   rb_float_new_inline

RUBY_SYMBOL_EXPORT_BEGIN
/* numeric.c (export) */
RUBY_SYMBOL_EXPORT_END

VALUE rb_flo_div_flo(VALUE x, VALUE y);
double ruby_float_mod(double x, double y);
VALUE rb_float_equal(VALUE x, VALUE y);
int rb_float_cmp(VALUE x, VALUE y);
VALUE rb_float_eql(VALUE x, VALUE y);
VALUE rb_fix_aref(VALUE fix, VALUE idx);
VALUE rb_int_zero_p(VALUE num);
VALUE rb_int_even_p(VALUE num);
VALUE rb_int_odd_p(VALUE num);
VALUE rb_int_abs(VALUE num);
VALUE rb_int_bit_length(VALUE num);
VALUE rb_int_uminus(VALUE num);
VALUE rb_int_comp(VALUE num);

static inline bool
INT_POSITIVE_P(VALUE num)
{
    if (FIXNUM_P(num)) {
        return FIXNUM_POSITIVE_P(num);
    }
    else {
        return BIGNUM_POSITIVE_P(num);
    }
}

static inline bool
INT_NEGATIVE_P(VALUE num)
{
    if (FIXNUM_P(num)) {
        return FIXNUM_NEGATIVE_P(num);
    }
    else {
        return BIGNUM_NEGATIVE_P(num);
    }
}

static inline bool
FLOAT_ZERO_P(VALUE num)
{
    return RFLOAT_VALUE(num) == 0.0;
}

static inline VALUE
rb_num_compare_with_zero(VALUE num, ID mid)
{
    VALUE zero = INT2FIX(0);
    VALUE r = rb_check_funcall(num, mid, 1, &zero);
    if (r == Qundef) {
        rb_cmperr(num, zero);
    }
    return r;
}

static inline int
rb_num_positive_int_p(VALUE num)
{
    const ID mid = '>';

    if (FIXNUM_P(num)) {
        if (rb_method_basic_definition_p(rb_cInteger, mid))
            return FIXNUM_POSITIVE_P(num);
    }
    else if (RB_TYPE_P(num, T_BIGNUM)) {
        if (rb_method_basic_definition_p(rb_cInteger, mid))
            return BIGNUM_POSITIVE_P(num);
    }
    return RTEST(rb_num_compare_with_zero(num, mid));
}

static inline int
rb_num_negative_int_p(VALUE num)
{
    const ID mid = '<';

    if (FIXNUM_P(num)) {
        if (rb_method_basic_definition_p(rb_cInteger, mid))
            return FIXNUM_NEGATIVE_P(num);
    }
    else if (RB_TYPE_P(num, T_BIGNUM)) {
        if (rb_method_basic_definition_p(rb_cInteger, mid))
            return BIGNUM_NEGATIVE_P(num);
    }
    return RTEST(rb_num_compare_with_zero(num, mid));
}

static inline double
rb_float_flonum_value(VALUE v)
{
#if USE_FLONUM
    if (v != (VALUE)0x8000000000000002) { /* LIKELY */
        union {
            double d;
            VALUE v;
        } t;

        VALUE b63 = (v >> 63);
        /* e: xx1... -> 011... */
        /*    xx0... -> 100... */
        /*      ^b63           */
        t.v = RUBY_BIT_ROTR((2 - b63) | (v & ~(VALUE)0x03), 3);
        return t.d;
    }
#endif
    return 0.0;
}

static inline double
rb_float_noflonum_value(VALUE v)
{
#if SIZEOF_DOUBLE <= SIZEOF_VALUE
    return RFLOAT(v)->float_value;
#else
    union {
        rb_float_value_type v;
        double d;
    } u = {RFLOAT(v)->float_value};
    return u.d;
#endif
}

static inline double
rb_float_value_inline(VALUE v)
{
    if (FLONUM_P(v)) {
        return rb_float_flonum_value(v);
    }
    return rb_float_noflonum_value(v);
}

static inline VALUE
rb_float_new_inline(double d)
{
#if USE_FLONUM
    union {
        double d;
        VALUE v;
    } t;
    int bits;

    t.d = d;
    bits = (int)((VALUE)(t.v >> 60) & 0x7);
    /* bits contains 3 bits of b62..b60. */
    /* bits - 3 = */
    /*   b011 -> b000 */
    /*   b100 -> b001 */

    if (t.v != 0x3000000000000000 /* 1.72723e-77 */ &&
        !((bits-3) & ~0x01)) {
        return (RUBY_BIT_ROTL(t.v, 3) & ~(VALUE)0x01) | 0x02;
    }
    else if (t.v == (VALUE)0) {
        /* +0.0 */
        return 0x8000000000000002;
    }
    /* out of range */
#endif
    return rb_float_new_in_heap(d);
}

#endif /* INTERNAL_NUMERIC_H */
