#ifndef INTERNAL_FIXNUM_H                                /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_FIXNUM_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Fixnums.
 */
#include "ruby/internal/config.h"      /* for HAVE_LONG_LONG */
#include <limits.h>             /* for CHAR_BIT */
#include "internal/compilers.h" /* for __has_builtin */
#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/intern.h"        /* for rb_big_mul */
#include "ruby/ruby.h"          /* for RB_FIXABLE */

#if HAVE_LONG_LONG && SIZEOF_LONG * 2 <= SIZEOF_LONG_LONG
# define DLONG LONG_LONG
# define DL2NUM(x) LL2NUM(x)
#elif defined(HAVE_INT128_T) && !(defined(__OpenBSD__) && defined(__mips64__))
# define DLONG int128_t
# define DL2NUM(x) (RB_FIXABLE(x) ? LONG2FIX(x) : rb_int128t2big(x))
VALUE rb_int128t2big(int128_t n); /* in bignum.c */
#endif

static inline long rb_overflowed_fix_to_int(long x);
static inline VALUE rb_fix_plus_fix(VALUE x, VALUE y);
static inline VALUE rb_fix_minus_fix(VALUE x, VALUE y);
static inline VALUE rb_fix_mul_fix(VALUE x, VALUE y);
static inline void rb_fix_divmod_fix(VALUE x, VALUE y, VALUE *divp, VALUE *modp);
static inline VALUE rb_fix_div_fix(VALUE x, VALUE y);
static inline VALUE rb_fix_mod_fix(VALUE x, VALUE y);
static inline bool FIXNUM_POSITIVE_P(VALUE num);
static inline bool FIXNUM_NEGATIVE_P(VALUE num);
static inline bool FIXNUM_ZERO_P(VALUE num);

static inline long
rb_overflowed_fix_to_int(long x)
{
    return (long)((unsigned long)(x >> 1) ^ (1LU << (SIZEOF_LONG * CHAR_BIT - 1)));
}

static inline VALUE
rb_fix_plus_fix(VALUE x, VALUE y)
{
#if !__has_builtin(__builtin_add_overflow)
    long lz = FIX2LONG(x) + FIX2LONG(y);
    return LONG2NUM(lz);
#else
    long lz;
    /* NOTE
     * (1) `LONG2FIX(FIX2LONG(x)+FIX2LONG(y))`
     +     = `((lx*2+1)/2 + (ly*2+1)/2)*2+1`
     +     = `lx*2 + ly*2 + 1`
     +     = `(lx*2+1) + (ly*2+1) - 1`
     +     = `x + y - 1`
     * (2) Fixnum's LSB is always 1.
     *     It means you can always run `x - 1` without overflow.
     * (3) Of course `z = x + (y-1)` may overflow.
     *     At that time true value is
     *     * positive: 0b0 1xxx...1, and z = 0b1xxx...1
     *     * negative: 0b1 0xxx...1, and z = 0b0xxx...1
     *     To convert this true value to long,
     *     (a) Use arithmetic shift
     *         * positive: 0b11xxx...
     *         * negative: 0b00xxx...
     *     (b) invert MSB
     *         * positive: 0b01xxx...
     *         * negative: 0b10xxx...
     */
    if (__builtin_add_overflow((long)x, (long)y-1, &lz)) {
        return rb_int2big(rb_overflowed_fix_to_int(lz));
    }
    else {
        return (VALUE)lz;
    }
#endif
}

static inline VALUE
rb_fix_minus_fix(VALUE x, VALUE y)
{
#if !__has_builtin(__builtin_sub_overflow)
    long lz = FIX2LONG(x) - FIX2LONG(y);
    return LONG2NUM(lz);
#else
    long lz;
    if (__builtin_sub_overflow((long)x, (long)y-1, &lz)) {
        return rb_int2big(rb_overflowed_fix_to_int(lz));
    }
    else {
        return (VALUE)lz;
    }
#endif
}

/* arguments must be Fixnum */
static inline VALUE
rb_fix_mul_fix(VALUE x, VALUE y)
{
    long lx = FIX2LONG(x);
    long ly = FIX2LONG(y);
#ifdef DLONG
    return DL2NUM((DLONG)lx * (DLONG)ly);
#else
    if (MUL_OVERFLOW_FIXNUM_P(lx, ly)) {
        return rb_big_mul(rb_int2big(lx), rb_int2big(ly));
    }
    else {
        return LONG2FIX(lx * ly);
    }
#endif
}

/*
 * This behaves different from C99 for negative arguments.
 * Note that div may overflow fixnum.
 */
static inline void
rb_fix_divmod_fix(VALUE a, VALUE b, VALUE *divp, VALUE *modp)
{
    /* assume / and % comply C99.
     * ldiv(3) won't be inlined by GCC and clang.
     * I expect / and % are compiled as single idiv.
     */
    long x = FIX2LONG(a);
    long y = FIX2LONG(b);
    long div, mod;
    if (x == FIXNUM_MIN && y == -1) {
        if (divp) *divp = LONG2NUM(-FIXNUM_MIN);
        if (modp) *modp = LONG2FIX(0);
        return;
    }
    div = x / y;
    mod = x % y;
    if (y > 0 ? mod < 0 : mod > 0) {
        mod += y;
        div -= 1;
    }
    if (divp) *divp = LONG2FIX(div);
    if (modp) *modp = LONG2FIX(mod);
}

/* div() for Ruby
 * This behaves different from C99 for negative arguments.
 */
static inline VALUE
rb_fix_div_fix(VALUE x, VALUE y)
{
    VALUE div;
    rb_fix_divmod_fix(x, y, &div, NULL);
    return div;
}

/* mod() for Ruby
 * This behaves different from C99 for negative arguments.
 */
static inline VALUE
rb_fix_mod_fix(VALUE x, VALUE y)
{
    VALUE mod;
    rb_fix_divmod_fix(x, y, NULL, &mod);
    return mod;
}

static inline bool
FIXNUM_POSITIVE_P(VALUE num)
{
    return (SIGNED_VALUE)num > (SIGNED_VALUE)INT2FIX(0);
}

static inline bool
FIXNUM_NEGATIVE_P(VALUE num)
{
    return (SIGNED_VALUE)num < 0;
}

static inline bool
FIXNUM_ZERO_P(VALUE num)
{
    return num == INT2FIX(0);
}
#endif /* INTERNAL_FIXNUM_H */
