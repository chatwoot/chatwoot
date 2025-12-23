/**********************************************************************

  internal.h -

  $Author$
  created at: Tue May 17 11:42:20 JST 2011

  Copyright (C) 2011 Yukihiro Matsumoto

**********************************************************************/

#ifndef RUBY_INTERNAL_H
#define RUBY_INTERNAL_H 1

#include "ruby.h"
#include "ruby/encoding.h"
#include "ruby/io.h"

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

#ifdef HAVE_STDBOOL_H
# include <stdbool.h>
#endif

#ifndef __bool_true_false_are_defined
# ifndef __cplusplus
#  undef bool
#  undef false
#  undef true
#  define bool signed char
#  define false 0
#  define true 1
#  define __bool_true_false_are_defined 1
# endif
#endif

/* The most significant bit of the lower part of half-long integer.
 * If sizeof(long) == 4, this is 0x8000.
 * If sizeof(long) == 8, this is 0x80000000.
 */
#define HALF_LONG_MSB ((SIGNED_VALUE)1<<((SIZEOF_LONG*CHAR_BIT-1)/2))

#define LIKELY(x) RB_LIKELY(x)
#define UNLIKELY(x) RB_UNLIKELY(x)

#ifndef MAYBE_UNUSED
# define MAYBE_UNUSED(x) x
#endif

#ifndef WARN_UNUSED_RESULT
# define WARN_UNUSED_RESULT(x) x
#endif

#ifdef HAVE_VALGRIND_MEMCHECK_H
# include <valgrind/memcheck.h>
# ifndef VALGRIND_MAKE_MEM_DEFINED
#  define VALGRIND_MAKE_MEM_DEFINED(p, n) VALGRIND_MAKE_READABLE((p), (n))
# endif
# ifndef VALGRIND_MAKE_MEM_UNDEFINED
#  define VALGRIND_MAKE_MEM_UNDEFINED(p, n) VALGRIND_MAKE_WRITABLE((p), (n))
# endif
#else
# define VALGRIND_MAKE_MEM_DEFINED(p, n) 0
# define VALGRIND_MAKE_MEM_UNDEFINED(p, n) 0
#endif

#define numberof(array) ((int)(sizeof(array) / sizeof((array)[0])))

#ifndef __has_feature
# define __has_feature(x) 0
#endif

#ifndef __has_extension
# define __has_extension __has_feature
#endif

#if GCC_VERSION_SINCE(4, 6, 0) || __has_extension(c_static_assert)
# define STATIC_ASSERT(name, expr) _Static_assert(expr, #name ": " #expr)
#else
# define STATIC_ASSERT(name, expr) typedef int static_assert_##name##_check[1 - 2*!(expr)]
#endif

#define SIGNED_INTEGER_TYPE_P(int_type) (0 > ((int_type)0)-1)
#define SIGNED_INTEGER_MAX(sint_type) \
  (sint_type) \
  ((((sint_type)1) << (sizeof(sint_type) * CHAR_BIT - 2)) | \
  ((((sint_type)1) << (sizeof(sint_type) * CHAR_BIT - 2)) - 1))
#define SIGNED_INTEGER_MIN(sint_type) (-SIGNED_INTEGER_MAX(sint_type)-1)
#define UNSIGNED_INTEGER_MAX(uint_type) (~(uint_type)0)

#if SIGNEDNESS_OF_TIME_T < 0	/* signed */
# define TIMET_MAX SIGNED_INTEGER_MAX(time_t)
# define TIMET_MIN SIGNED_INTEGER_MIN(time_t)
#elif SIGNEDNESS_OF_TIME_T > 0	/* unsigned */
# define TIMET_MAX UNSIGNED_INTEGER_MAX(time_t)
# define TIMET_MIN ((time_t)0)
#endif
#define TIMET_MAX_PLUS_ONE (2*(double)(TIMET_MAX/2+1))

#ifdef HAVE_BUILTIN___BUILTIN_MUL_OVERFLOW_P
#define MUL_OVERFLOW_P(a, b) \
    __builtin_mul_overflow_p((a), (b), (__typeof__(a * b))0)
#elif defined HAVE_BUILTIN___BUILTIN_MUL_OVERFLOW
#define MUL_OVERFLOW_P(a, b) \
    ({__typeof__(a) c; __builtin_mul_overflow((a), (b), &c);})
#endif

#define MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, min, max) ( \
    (a) == 0 ? 0 : \
    (a) == -1 ? (b) < -(max) : \
    (a) > 0 ? \
      ((b) > 0 ? (max) / (a) < (b) : (min) / (a) > (b)) : \
      ((b) > 0 ? (min) / (a) < (b) : (max) / (a) > (b)))

#ifdef HAVE_BUILTIN___BUILTIN_MUL_OVERFLOW_P
/* __builtin_mul_overflow_p can take bitfield */
/* and GCC permits bitfields for integers other than int */
#define MUL_OVERFLOW_FIXNUM_P(a, b) ({ \
    struct { long fixnum : SIZEOF_LONG * CHAR_BIT - 1; } c; \
    __builtin_mul_overflow_p((a), (b), c.fixnum); \
})
#else
#define MUL_OVERFLOW_FIXNUM_P(a, b) MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, FIXNUM_MIN, FIXNUM_MAX)
#endif

#ifdef MUL_OVERFLOW_P
#define MUL_OVERFLOW_LONG_LONG_P(a, b) MUL_OVERFLOW_P(a, b)
#define MUL_OVERFLOW_LONG_P(a, b)      MUL_OVERFLOW_P(a, b)
#define MUL_OVERFLOW_INT_P(a, b)       MUL_OVERFLOW_P(a, b)
#else
#define MUL_OVERFLOW_LONG_LONG_P(a, b) MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, LLONG_MIN, LLONG_MAX)
#define MUL_OVERFLOW_LONG_P(a, b)      MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, LONG_MIN, LONG_MAX)
#define MUL_OVERFLOW_INT_P(a, b)       MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, INT_MIN, INT_MAX)
#endif

#ifndef swap16
# ifdef HAVE_BUILTIN___BUILTIN_BSWAP16
#  define swap16(x) __builtin_bswap16(x)
# endif
#endif

#ifndef swap16
# define swap16(x)      ((uint16_t)((((x)&0xFF)<<8) | (((x)>>8)&0xFF)))
#endif

#ifndef swap32
# ifdef HAVE_BUILTIN___BUILTIN_BSWAP32
#  define swap32(x) __builtin_bswap32(x)
# endif
#endif

#ifndef swap32
# define swap32(x)      ((uint32_t)((((x)&0xFF)<<24)    \
                        |(((x)>>24)&0xFF)       \
                        |(((x)&0x0000FF00)<<8)  \
                        |(((x)&0x00FF0000)>>8)  ))
#endif

#ifndef swap64
# ifdef HAVE_BUILTIN___BUILTIN_BSWAP64
#  define swap64(x) __builtin_bswap64(x)
# endif
#endif

#ifndef swap64
# ifdef HAVE_INT64_T
#  define byte_in_64bit(n) ((uint64_t)0xff << (n))
#  define swap64(x)       ((uint64_t)((((x)&byte_in_64bit(0))<<56)      \
                           |(((x)>>56)&0xFF)                    \
                           |(((x)&byte_in_64bit(8))<<40)        \
                           |(((x)&byte_in_64bit(48))>>40)       \
                           |(((x)&byte_in_64bit(16))<<24)       \
                           |(((x)&byte_in_64bit(40))>>24)       \
                           |(((x)&byte_in_64bit(24))<<8)        \
                           |(((x)&byte_in_64bit(32))>>8)))
# endif
#endif

static inline unsigned int
nlz_int(unsigned int x)
{
#if defined(HAVE_BUILTIN___BUILTIN_CLZ)
    if (x == 0) return SIZEOF_INT * CHAR_BIT;
    return (unsigned int)__builtin_clz(x);
#else
    unsigned int y;
# if 64 < SIZEOF_INT * CHAR_BIT
    unsigned int n = 128;
# elif 32 < SIZEOF_INT * CHAR_BIT
    unsigned int n = 64;
# else
    unsigned int n = 32;
# endif
# if 64 < SIZEOF_INT * CHAR_BIT
    y = x >> 64; if (y) {n -= 64; x = y;}
# endif
# if 32 < SIZEOF_INT * CHAR_BIT
    y = x >> 32; if (y) {n -= 32; x = y;}
# endif
    y = x >> 16; if (y) {n -= 16; x = y;}
    y = x >>  8; if (y) {n -=  8; x = y;}
    y = x >>  4; if (y) {n -=  4; x = y;}
    y = x >>  2; if (y) {n -=  2; x = y;}
    y = x >>  1; if (y) {return n - 2;}
    return (unsigned int)(n - x);
#endif
}

static inline unsigned int
nlz_long(unsigned long x)
{
#if defined(HAVE_BUILTIN___BUILTIN_CLZL)
    if (x == 0) return SIZEOF_LONG * CHAR_BIT;
    return (unsigned int)__builtin_clzl(x);
#else
    unsigned long y;
# if 64 < SIZEOF_LONG * CHAR_BIT
    unsigned int n = 128;
# elif 32 < SIZEOF_LONG * CHAR_BIT
    unsigned int n = 64;
# else
    unsigned int n = 32;
# endif
# if 64 < SIZEOF_LONG * CHAR_BIT
    y = x >> 64; if (y) {n -= 64; x = y;}
# endif
# if 32 < SIZEOF_LONG * CHAR_BIT
    y = x >> 32; if (y) {n -= 32; x = y;}
# endif
    y = x >> 16; if (y) {n -= 16; x = y;}
    y = x >>  8; if (y) {n -=  8; x = y;}
    y = x >>  4; if (y) {n -=  4; x = y;}
    y = x >>  2; if (y) {n -=  2; x = y;}
    y = x >>  1; if (y) {return n - 2;}
    return (unsigned int)(n - x);
#endif
}

#ifdef HAVE_LONG_LONG
static inline unsigned int
nlz_long_long(unsigned LONG_LONG x)
{
#if defined(HAVE_BUILTIN___BUILTIN_CLZLL)
    if (x == 0) return SIZEOF_LONG_LONG * CHAR_BIT;
    return (unsigned int)__builtin_clzll(x);
#else
    unsigned LONG_LONG y;
# if 64 < SIZEOF_LONG_LONG * CHAR_BIT
    unsigned int n = 128;
# elif 32 < SIZEOF_LONG_LONG * CHAR_BIT
    unsigned int n = 64;
# else
    unsigned int n = 32;
# endif
# if 64 < SIZEOF_LONG_LONG * CHAR_BIT
    y = x >> 64; if (y) {n -= 64; x = y;}
# endif
# if 32 < SIZEOF_LONG_LONG * CHAR_BIT
    y = x >> 32; if (y) {n -= 32; x = y;}
# endif
    y = x >> 16; if (y) {n -= 16; x = y;}
    y = x >>  8; if (y) {n -=  8; x = y;}
    y = x >>  4; if (y) {n -=  4; x = y;}
    y = x >>  2; if (y) {n -=  2; x = y;}
    y = x >>  1; if (y) {return n - 2;}
    return (unsigned int)(n - x);
#endif
}
#endif

#ifdef HAVE_UINT128_T
static inline unsigned int
nlz_int128(uint128_t x)
{
    uint128_t y;
    unsigned int n = 128;
    y = x >> 64; if (y) {n -= 64; x = y;}
    y = x >> 32; if (y) {n -= 32; x = y;}
    y = x >> 16; if (y) {n -= 16; x = y;}
    y = x >>  8; if (y) {n -=  8; x = y;}
    y = x >>  4; if (y) {n -=  4; x = y;}
    y = x >>  2; if (y) {n -=  2; x = y;}
    y = x >>  1; if (y) {return n - 2;}
    return (unsigned int)(n - x);
}
#endif

static inline unsigned int
nlz_intptr(uintptr_t x)
{
#if SIZEOF_VOIDP == 8
    return nlz_long_long(x);
#elif SIZEOF_VOIDP == 4
    return nlz_int(x);
#endif
}

static inline unsigned int
rb_popcount32(uint32_t x)
{
#ifdef HAVE_BUILTIN___BUILTIN_POPCOUNT
    return (unsigned int)__builtin_popcount(x);
#else
    x = (x & 0x55555555) + (x >> 1 & 0x55555555);
    x = (x & 0x33333333) + (x >> 2 & 0x33333333);
    x = (x & 0x0f0f0f0f) + (x >> 4 & 0x0f0f0f0f);
    x = (x & 0x001f001f) + (x >> 8 & 0x001f001f);
    return (x & 0x0000003f) + (x >>16 & 0x0000003f);
#endif
}

static inline int
rb_popcount64(uint64_t x)
{
#ifdef HAVE_BUILTIN___BUILTIN_POPCOUNT
    return __builtin_popcountll(x);
#else
    x = (x & 0x5555555555555555) + (x >> 1 & 0x5555555555555555);
    x = (x & 0x3333333333333333) + (x >> 2 & 0x3333333333333333);
    x = (x & 0x0707070707070707) + (x >> 4 & 0x0707070707070707);
    x = (x & 0x001f001f001f001f) + (x >> 8 & 0x001f001f001f001f);
    x = (x & 0x0000003f0000003f) + (x >>16 & 0x0000003f0000003f);
    return (x & 0x7f) + (x >>32 & 0x7f);
#endif
}

static inline int
rb_popcount_intptr(uintptr_t x)
{
#if SIZEOF_VOIDP == 8
    return rb_popcount64(x);
#elif SIZEOF_VOIDP == 4
    return rb_popcount32(x);
#endif
}

static inline int
ntz_int32(uint32_t x)
{
#ifdef HAVE_BUILTIN___BUILTIN_CTZ
    return __builtin_ctz(x);
#else
    return rb_popcount32((~x) & (x-1));
#endif
}

static inline int
ntz_int64(uint64_t x)
{
#ifdef HAVE_BUILTIN___BUILTIN_CTZLL
    return __builtin_ctzll(x);
#else
    return rb_popcount64((~x) & (x-1));
#endif
}

static inline int
ntz_intptr(uintptr_t x)
{
#if SIZEOF_VOIDP == 8
    return ntz_int64(x);
#elif SIZEOF_VOIDP == 4
    return ntz_int32(x);
#endif
}

#if HAVE_LONG_LONG && SIZEOF_LONG * 2 <= SIZEOF_LONG_LONG
# define DLONG LONG_LONG
# define DL2NUM(x) LL2NUM(x)
#elif defined(HAVE_INT128_T)
# define DLONG int128_t
# define DL2NUM(x) (RB_FIXABLE(x) ? LONG2FIX(x) : rb_int128t2big(x))
VALUE rb_int128t2big(int128_t n);
#endif

static inline long
rb_overflowed_fix_to_int(long x)
{
    return (long)((unsigned long)(x >> 1) ^ (1LU << (SIZEOF_LONG * CHAR_BIT - 1)));
}

static inline VALUE
rb_fix_plus_fix(VALUE x, VALUE y)
{
#ifdef HAVE_BUILTIN___BUILTIN_ADD_OVERFLOW
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
     *     * nevative: 0b1 0xxx...1, and z = 0b0xxx...1
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
#else
    long lz = FIX2LONG(x) + FIX2LONG(y);
    return LONG2NUM(lz);
#endif
}

static inline VALUE
rb_fix_minus_fix(VALUE x, VALUE y)
{
#ifdef HAVE_BUILTIN___BUILTIN_SUB_OVERFLOW
    long lz;
    if (__builtin_sub_overflow((long)x, (long)y-1, &lz)) {
	return rb_int2big(rb_overflowed_fix_to_int(lz));
    }
    else {
	return (VALUE)lz;
    }
#else
    long lz = FIX2LONG(x) - FIX2LONG(y);
    return LONG2NUM(lz);
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

#if defined(HAVE_UINT128_T)
#   define bit_length(x) \
    (unsigned int) \
    (sizeof(x) <= SIZEOF_INT ? SIZEOF_INT * CHAR_BIT - nlz_int((unsigned int)(x)) : \
     sizeof(x) <= SIZEOF_LONG ? SIZEOF_LONG * CHAR_BIT - nlz_long((unsigned long)(x)) : \
     sizeof(x) <= SIZEOF_LONG_LONG ? SIZEOF_LONG_LONG * CHAR_BIT - nlz_long_long((unsigned LONG_LONG)(x)) : \
     SIZEOF_INT128_T * CHAR_BIT - nlz_int128((uint128_t)(x)))
#elif defined(HAVE_LONG_LONG)
#   define bit_length(x) \
    (unsigned int) \
    (sizeof(x) <= SIZEOF_INT ? SIZEOF_INT * CHAR_BIT - nlz_int((unsigned int)(x)) : \
     sizeof(x) <= SIZEOF_LONG ? SIZEOF_LONG * CHAR_BIT - nlz_long((unsigned long)(x)) : \
     SIZEOF_LONG_LONG * CHAR_BIT - nlz_long_long((unsigned LONG_LONG)(x)))
#else
#   define bit_length(x) \
    (unsigned int) \
    (sizeof(x) <= SIZEOF_INT ? SIZEOF_INT * CHAR_BIT - nlz_int((unsigned int)(x)) : \
     SIZEOF_LONG * CHAR_BIT - nlz_long((unsigned long)(x)))
#endif

#ifndef BDIGIT
# if SIZEOF_INT*2 <= SIZEOF_LONG_LONG
#  define BDIGIT unsigned int
#  define SIZEOF_BDIGIT SIZEOF_INT
#  define BDIGIT_DBL unsigned LONG_LONG
#  define BDIGIT_DBL_SIGNED LONG_LONG
#  define PRI_BDIGIT_PREFIX ""
#  define PRI_BDIGIT_DBL_PREFIX PRI_LL_PREFIX
# elif SIZEOF_INT*2 <= SIZEOF_LONG
#  define BDIGIT unsigned int
#  define SIZEOF_BDIGIT SIZEOF_INT
#  define BDIGIT_DBL unsigned long
#  define BDIGIT_DBL_SIGNED long
#  define PRI_BDIGIT_PREFIX ""
#  define PRI_BDIGIT_DBL_PREFIX "l"
# elif SIZEOF_SHORT*2 <= SIZEOF_LONG
#  define BDIGIT unsigned short
#  define SIZEOF_BDIGIT SIZEOF_SHORT
#  define BDIGIT_DBL unsigned long
#  define BDIGIT_DBL_SIGNED long
#  define PRI_BDIGIT_PREFIX "h"
#  define PRI_BDIGIT_DBL_PREFIX "l"
# else
#  define BDIGIT unsigned short
#  define SIZEOF_BDIGIT (SIZEOF_LONG/2)
#  define SIZEOF_ACTUAL_BDIGIT SIZEOF_LONG
#  define BDIGIT_DBL unsigned long
#  define BDIGIT_DBL_SIGNED long
#  define PRI_BDIGIT_PREFIX "h"
#  define PRI_BDIGIT_DBL_PREFIX "l"
# endif
#endif
#ifndef SIZEOF_ACTUAL_BDIGIT
# define SIZEOF_ACTUAL_BDIGIT SIZEOF_BDIGIT
#endif

#ifdef PRI_BDIGIT_PREFIX
# define PRIdBDIGIT PRI_BDIGIT_PREFIX"d"
# define PRIiBDIGIT PRI_BDIGIT_PREFIX"i"
# define PRIoBDIGIT PRI_BDIGIT_PREFIX"o"
# define PRIuBDIGIT PRI_BDIGIT_PREFIX"u"
# define PRIxBDIGIT PRI_BDIGIT_PREFIX"x"
# define PRIXBDIGIT PRI_BDIGIT_PREFIX"X"
#endif

#ifdef PRI_BDIGIT_DBL_PREFIX
# define PRIdBDIGIT_DBL PRI_BDIGIT_DBL_PREFIX"d"
# define PRIiBDIGIT_DBL PRI_BDIGIT_DBL_PREFIX"i"
# define PRIoBDIGIT_DBL PRI_BDIGIT_DBL_PREFIX"o"
# define PRIuBDIGIT_DBL PRI_BDIGIT_DBL_PREFIX"u"
# define PRIxBDIGIT_DBL PRI_BDIGIT_DBL_PREFIX"x"
# define PRIXBDIGIT_DBL PRI_BDIGIT_DBL_PREFIX"X"
#endif

#define BIGNUM_EMBED_LEN_NUMBITS 3
#ifndef BIGNUM_EMBED_LEN_MAX
# if (SIZEOF_VALUE*3/SIZEOF_ACTUAL_BDIGIT) < (1 << BIGNUM_EMBED_LEN_NUMBITS)-1
#   define BIGNUM_EMBED_LEN_MAX (SIZEOF_VALUE*3/SIZEOF_ACTUAL_BDIGIT)
# else
#   define BIGNUM_EMBED_LEN_MAX ((1 << BIGNUM_EMBED_LEN_NUMBITS)-1)
# endif
#endif

struct RBignum {
    struct RBasic basic;
    union {
        struct {
            size_t len;
            BDIGIT *digits;
        } heap;
        BDIGIT ary[BIGNUM_EMBED_LEN_MAX];
    } as;
};
#define BIGNUM_SIGN_BIT ((VALUE)FL_USER1)
/* sign: positive:1, negative:0 */
#define BIGNUM_SIGN(b) ((RBASIC(b)->flags & BIGNUM_SIGN_BIT) != 0)
#define BIGNUM_SET_SIGN(b,sign) \
  ((sign) ? (RBASIC(b)->flags |= BIGNUM_SIGN_BIT) \
          : (RBASIC(b)->flags &= ~BIGNUM_SIGN_BIT))
#define BIGNUM_POSITIVE_P(b) BIGNUM_SIGN(b)
#define BIGNUM_NEGATIVE_P(b) (!BIGNUM_SIGN(b))
#define BIGNUM_NEGATE(b) (RBASIC(b)->flags ^= BIGNUM_SIGN_BIT)

#define BIGNUM_EMBED_FLAG ((VALUE)FL_USER2)
#define BIGNUM_EMBED_LEN_MASK ((VALUE)(FL_USER5|FL_USER4|FL_USER3))
#define BIGNUM_EMBED_LEN_SHIFT (FL_USHIFT+BIGNUM_EMBED_LEN_NUMBITS)
#define BIGNUM_LEN(b) \
    ((RBASIC(b)->flags & BIGNUM_EMBED_FLAG) ? \
     (size_t)((RBASIC(b)->flags >> BIGNUM_EMBED_LEN_SHIFT) & \
	      (BIGNUM_EMBED_LEN_MASK >> BIGNUM_EMBED_LEN_SHIFT)) : \
     RBIGNUM(b)->as.heap.len)
/* LSB:BIGNUM_DIGITS(b)[0], MSB:BIGNUM_DIGITS(b)[BIGNUM_LEN(b)-1] */
#define BIGNUM_DIGITS(b) \
    ((RBASIC(b)->flags & BIGNUM_EMBED_FLAG) ? \
     RBIGNUM(b)->as.ary : \
     RBIGNUM(b)->as.heap.digits)
#define BIGNUM_LENINT(b) rb_long2int(BIGNUM_LEN(b))

#define RBIGNUM(obj) (R_CAST(RBignum)(obj))

struct RRational {
    struct RBasic basic;
    const VALUE num;
    const VALUE den;
};

#define RRATIONAL(obj) (R_CAST(RRational)(obj))
#define RRATIONAL_SET_NUM(rat, n) RB_OBJ_WRITE((rat), &((struct RRational *)(rat))->num,(n))
#define RRATIONAL_SET_DEN(rat, d) RB_OBJ_WRITE((rat), &((struct RRational *)(rat))->den,(d))

struct RFloat {
    struct RBasic basic;
    double float_value;
};

#define RFLOAT(obj)  (R_CAST(RFloat)(obj))

struct RComplex {
    struct RBasic basic;
    const VALUE real;
    const VALUE imag;
};

#define RCOMPLEX(obj) (R_CAST(RComplex)(obj))

#ifdef RCOMPLEX_SET_REAL        /* shortcut macro for internal only */
#undef RCOMPLEX_SET_REAL
#undef RCOMPLEX_SET_IMAG
#define RCOMPLEX_SET_REAL(cmp, r) RB_OBJ_WRITE((cmp), &((struct RComplex *)(cmp))->real,(r))
#define RCOMPLEX_SET_IMAG(cmp, i) RB_OBJ_WRITE((cmp), &((struct RComplex *)(cmp))->imag,(i))
#endif

struct RHash {
    struct RBasic basic;
    struct st_table *ntbl;      /* possibly 0 */
    int iter_lev;
    const VALUE ifnone;
};

#define RHASH(obj)   (R_CAST(RHash)(obj))

#ifdef RHASH_ITER_LEV
#undef RHASH_ITER_LEV
#undef RHASH_IFNONE
#undef RHASH_SIZE
#define RHASH_ITER_LEV(h) (RHASH(h)->iter_lev)
#define RHASH_IFNONE(h) (RHASH(h)->ifnone)
#define RHASH_SIZE(h) (RHASH(h)->ntbl ? RHASH(h)->ntbl->num_entries : (st_index_t)0)
#endif

/* missing/setproctitle.c */
#ifndef HAVE_SETPROCTITLE
extern void ruby_init_setproctitle(int argc, char *argv[]);
#endif

#define RSTRUCT_EMBED_LEN_MAX RSTRUCT_EMBED_LEN_MAX
#define RSTRUCT_EMBED_LEN_MASK RSTRUCT_EMBED_LEN_MASK
#define RSTRUCT_EMBED_LEN_SHIFT RSTRUCT_EMBED_LEN_SHIFT
enum {
    RSTRUCT_EMBED_LEN_MAX = 3,
    RSTRUCT_EMBED_LEN_MASK = (RUBY_FL_USER2|RUBY_FL_USER1),
    RSTRUCT_EMBED_LEN_SHIFT = (RUBY_FL_USHIFT+1),

    RSTRUCT_ENUM_END
};

struct RStruct {
    struct RBasic basic;
    union {
	struct {
	    long len;
	    const VALUE *ptr;
	} heap;
	const VALUE ary[RSTRUCT_EMBED_LEN_MAX];
    } as;
};

#undef RSTRUCT_LEN
#undef RSTRUCT_PTR
#undef RSTRUCT_SET
#undef RSTRUCT_GET
#define RSTRUCT_EMBED_LEN(st)                               \
    (long)((RBASIC(st)->flags >> RSTRUCT_EMBED_LEN_SHIFT) & \
	   (RSTRUCT_EMBED_LEN_MASK >> RSTRUCT_EMBED_LEN_SHIFT))
#define RSTRUCT_LEN(st) rb_struct_len(st)
#define RSTRUCT_LENINT(st) rb_long2int(RSTRUCT_LEN(st))
#define RSTRUCT_CONST_PTR(st) rb_struct_const_ptr(st)
#define RSTRUCT_PTR(st) ((VALUE *)RSTRUCT_CONST_PTR(RB_OBJ_WB_UNPROTECT_FOR(STRUCT, st)))
#define RSTRUCT_SET(st, idx, v) RB_OBJ_WRITE(st, &RSTRUCT_CONST_PTR(st)[idx], (v))
#define RSTRUCT_GET(st, idx)    (RSTRUCT_CONST_PTR(st)[idx])
#define RSTRUCT(obj) (R_CAST(RStruct)(obj))

static inline long
rb_struct_len(VALUE st)
{
    return (RBASIC(st)->flags & RSTRUCT_EMBED_LEN_MASK) ?
	RSTRUCT_EMBED_LEN(st) : RSTRUCT(st)->as.heap.len;
}

static inline const VALUE *
rb_struct_const_ptr(VALUE st)
{
    return FIX_CONST_VALUE_PTR((RBASIC(st)->flags & RSTRUCT_EMBED_LEN_MASK) ?
	RSTRUCT(st)->as.ary : RSTRUCT(st)->as.heap.ptr);
}

/* class.c */

struct rb_deprecated_classext_struct {
    char conflict[sizeof(VALUE) * 3];
};

struct rb_subclass_entry;
typedef struct rb_subclass_entry rb_subclass_entry_t;

struct rb_subclass_entry {
    VALUE klass;
    rb_subclass_entry_t *next;
};

#if defined(HAVE_LONG_LONG)
typedef unsigned LONG_LONG rb_serial_t;
#define SERIALT2NUM ULL2NUM
#elif defined(HAVE_UINT64_T)
typedef uint64_t rb_serial_t;
#define SERIALT2NUM SIZET2NUM
#else
typedef unsigned long rb_serial_t;
#define SERIALT2NUM ULONG2NUM
#endif

struct rb_classext_struct {
    struct st_table *iv_index_tbl;
    struct st_table *iv_tbl;
    struct rb_id_table *const_tbl;
    struct rb_id_table *callable_m_tbl;
    rb_subclass_entry_t *subclasses;
    rb_subclass_entry_t **parent_subclasses;
    /**
     * In the case that this is an `ICLASS`, `module_subclasses` points to the link
     * in the module's `subclasses` list that indicates that the klass has been
     * included. Hopefully that makes sense.
     */
    rb_subclass_entry_t **module_subclasses;
    rb_serial_t class_serial;
    const VALUE origin_;
    VALUE refined_class;
    rb_alloc_func_t allocator;
};

typedef struct rb_classext_struct rb_classext_t;

#undef RClass
struct RClass {
    struct RBasic basic;
    VALUE super;
    rb_classext_t *ptr;
    struct rb_id_table *m_tbl;
};

void rb_class_subclass_add(VALUE super, VALUE klass);
void rb_class_remove_from_super_subclasses(VALUE);
int rb_singleton_class_internal_p(VALUE sklass);

#define RCLASS_EXT(c) (RCLASS(c)->ptr)
#define RCLASS_IV_TBL(c) (RCLASS_EXT(c)->iv_tbl)
#define RCLASS_CONST_TBL(c) (RCLASS_EXT(c)->const_tbl)
#define RCLASS_M_TBL(c) (RCLASS(c)->m_tbl)
#define RCLASS_CALLABLE_M_TBL(c) (RCLASS_EXT(c)->callable_m_tbl)
#define RCLASS_IV_INDEX_TBL(c) (RCLASS_EXT(c)->iv_index_tbl)
#define RCLASS_ORIGIN(c) (RCLASS_EXT(c)->origin_)
#define RCLASS_REFINED_CLASS(c) (RCLASS_EXT(c)->refined_class)
#define RCLASS_SERIAL(c) (RCLASS_EXT(c)->class_serial)

#define RICLASS_IS_ORIGIN FL_USER5

static inline void
RCLASS_SET_ORIGIN(VALUE klass, VALUE origin)
{
    RB_OBJ_WRITE(klass, &RCLASS_ORIGIN(klass), origin);
    if (klass != origin) FL_SET(origin, RICLASS_IS_ORIGIN);
}

#undef RCLASS_SUPER
static inline VALUE
RCLASS_SUPER(VALUE klass)
{
    return RCLASS(klass)->super;
}

static inline VALUE
RCLASS_SET_SUPER(VALUE klass, VALUE super)
{
    if (super) {
	rb_class_remove_from_super_subclasses(klass);
	rb_class_subclass_add(super, klass);
    }
    RB_OBJ_WRITE(klass, &RCLASS(klass)->super, super);
    return super;
}
/* IMEMO: Internal memo object */

#ifndef IMEMO_DEBUG
#define IMEMO_DEBUG 0
#endif

struct RIMemo {
    VALUE flags;
    VALUE v0;
    VALUE v1;
    VALUE v2;
    VALUE v3;
};

enum imemo_type {
    imemo_env            =  0,
    imemo_cref           =  1, /*!< class reference */
    imemo_svar           =  2, /*!< special variable */
    imemo_throw_data     =  3,
    imemo_ifunc          =  4, /*!< iterator function */
    imemo_memo           =  5,
    imemo_ment           =  6,
    imemo_iseq           =  7,
    imemo_alloc          =  8,
    imemo_ast            =  9,
    imemo_parser_strterm = 10
};
#define IMEMO_MASK   0x0f

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

/* FL_USER0 to FL_USER3 is for type */
#define IMEMO_FL_USHIFT (FL_USHIFT + 4)
#define IMEMO_FL_USER0 FL_USER4
#define IMEMO_FL_USER1 FL_USER5
#define IMEMO_FL_USER2 FL_USER6
#define IMEMO_FL_USER3 FL_USER7
#define IMEMO_FL_USER4 FL_USER8

/* CREF (Class REFerence) is defined in method.h */

/*! SVAR (Special VARiable) */
struct vm_svar {
    VALUE flags;
    const VALUE cref_or_me; /*!< class reference or rb_method_entry_t */
    const VALUE lastline;
    const VALUE backref;
    const VALUE others;
};


#define THROW_DATA_CONSUMED IMEMO_FL_USER0

/*! THROW_DATA */
struct vm_throw_data {
    VALUE flags;
    VALUE reserved;
    const VALUE throw_obj;
    const struct rb_control_frame_struct *catch_frame;
    VALUE throw_state;
};

#define THROW_DATA_P(err) RB_TYPE_P((VALUE)(err), T_IMEMO)

/* IFUNC (Internal FUNCtion) */

struct vm_ifunc_argc {
#if SIZEOF_INT * 2 > SIZEOF_VALUE
    int min: (SIZEOF_VALUE * CHAR_BIT) / 2;
    int max: (SIZEOF_VALUE * CHAR_BIT) / 2;
#else
    int min, max;
#endif
};

/*! IFUNC (Internal FUNCtion) */
struct vm_ifunc {
    VALUE flags;
    VALUE reserved;
    VALUE (*func)(ANYARGS);
    const void *data;
    struct vm_ifunc_argc argc;
};

#define IFUNC_NEW(a, b, c) ((struct vm_ifunc *)rb_imemo_new(imemo_ifunc, (VALUE)(a), (VALUE)(b), (VALUE)(c), 0))
struct vm_ifunc *rb_vm_ifunc_new(VALUE (*func)(ANYARGS), const void *data, int min_argc, int max_argc);
static inline struct vm_ifunc *
rb_vm_ifunc_proc_new(VALUE (*func)(ANYARGS), const void *data)
{
    return rb_vm_ifunc_new(func, data, 0, UNLIMITED_ARGUMENTS);
}

typedef struct rb_imemo_alloc_struct {
    VALUE flags;
    VALUE reserved;
    VALUE *ptr; /* malloc'ed buffer */
    struct rb_imemo_alloc_struct *next; /* next imemo */
    size_t cnt; /* buffer size in VALUE */
} rb_imemo_alloc_t;

rb_imemo_alloc_t *rb_imemo_alloc_new(VALUE, VALUE, VALUE, VALUE);

void rb_strterm_mark(VALUE obj);

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
	VALUE (*func)(ANYARGS);
    } u3;
};

#define MEMO_V1_SET(m, v) RB_OBJ_WRITE((m), &(m)->v1, (v))
#define MEMO_V2_SET(m, v) RB_OBJ_WRITE((m), &(m)->v2, (v))

#define MEMO_CAST(m) ((struct MEMO *)m)

#define MEMO_NEW(a, b, c) ((struct MEMO *)rb_imemo_new(imemo_memo, (VALUE)(a), (VALUE)(b), (VALUE)(c), 0))

#define roomof(x, y) (((x) + (y) - 1) / (y))
#define type_roomof(x, y) roomof(sizeof(x), sizeof(y))
#define MEMO_FOR(type, value) ((type *)RARRAY_PTR(value))
#define NEW_MEMO_FOR(type, value) \
  ((value) = rb_ary_tmp_new_fill(type_roomof(type, VALUE)), MEMO_FOR(type, value))
#define NEW_PARTIAL_MEMO_FOR(type, value, member) \
  ((value) = rb_ary_tmp_new_fill(type_roomof(type, VALUE)), \
   rb_ary_set_len((value), offsetof(type, member) / sizeof(VALUE)), \
   MEMO_FOR(type, value))

#define STRING_P(s) (RB_TYPE_P((s), T_STRING) && CLASS_OF(s) == rb_cString)

#ifdef RUBY_INTEGER_UNIFICATION
# define rb_cFixnum rb_cInteger
# define rb_cBignum rb_cInteger
#endif

enum {
    cmp_opt_Fixnum,
    cmp_opt_String,
    cmp_opt_Float,
    cmp_optimizable_count
};

struct cmp_opt_data {
    unsigned int opt_methods;
    unsigned int opt_inited;
};

#define NEW_CMP_OPT_MEMO(type, value) \
    NEW_PARTIAL_MEMO_FOR(type, value, cmp_opt)
#define CMP_OPTIMIZABLE_BIT(type) (1U << TOKEN_PASTE(cmp_opt_,type))
#define CMP_OPTIMIZABLE(data, type) \
    (((data).opt_inited & CMP_OPTIMIZABLE_BIT(type)) ? \
     ((data).opt_methods & CMP_OPTIMIZABLE_BIT(type)) : \
     (((data).opt_inited |= CMP_OPTIMIZABLE_BIT(type)), \
      rb_method_basic_definition_p(TOKEN_PASTE(rb_c,type), id_cmp) && \
      ((data).opt_methods |= CMP_OPTIMIZABLE_BIT(type))))

#define OPTIMIZED_CMP(a, b, data) \
    ((FIXNUM_P(a) && FIXNUM_P(b) && CMP_OPTIMIZABLE(data, Fixnum)) ? \
     (((long)a > (long)b) ? 1 : ((long)a < (long)b) ? -1 : 0) : \
     (STRING_P(a) && STRING_P(b) && CMP_OPTIMIZABLE(data, String)) ? \
     rb_str_cmp(a, b) : \
     (RB_FLOAT_TYPE_P(a) && RB_FLOAT_TYPE_P(b) && CMP_OPTIMIZABLE(data, Float)) ? \
     rb_float_cmp(a, b) : \
     rb_cmpint(rb_funcallv(a, id_cmp, 1, &b), a, b))

/* ment is in method.h */

/* global variable */

struct rb_global_entry {
    struct rb_global_variable *var;
    ID id;
};

struct rb_global_entry *rb_global_entry(ID);
VALUE rb_gvar_get(struct rb_global_entry *);
VALUE rb_gvar_set(struct rb_global_entry *, VALUE);
VALUE rb_gvar_defined(struct rb_global_entry *);

struct vtm; /* defined by timev.h */

/* array.c */
VALUE rb_ary_last(int, const VALUE *, VALUE);
void rb_ary_set_len(VALUE, long);
void rb_ary_delete_same(VALUE, VALUE);
VALUE rb_ary_tmp_new_fill(long capa);
VALUE rb_ary_at(VALUE, VALUE);
VALUE rb_ary_aref1(VALUE ary, VALUE i);
VALUE rb_ary_aref2(VALUE ary, VALUE b, VALUE e);
size_t rb_ary_memsize(VALUE);
VALUE rb_to_array_type(VALUE obj);
#ifdef __GNUC__
#define rb_ary_new_from_args(n, ...) \
    __extension__ ({ \
	const VALUE args_to_new_ary[] = {__VA_ARGS__}; \
	if (__builtin_constant_p(n)) { \
	    STATIC_ASSERT(rb_ary_new_from_args, numberof(args_to_new_ary) == (n)); \
	} \
	rb_ary_new_from_values(numberof(args_to_new_ary), args_to_new_ary); \
    })
#endif

/* bignum.c */
extern const char ruby_digitmap[];
double rb_big_fdiv_double(VALUE x, VALUE y);
VALUE rb_big_uminus(VALUE x);
VALUE rb_big_hash(VALUE);
VALUE rb_big_odd_p(VALUE);
VALUE rb_big_even_p(VALUE);
size_t rb_big_size(VALUE);
VALUE rb_integer_float_cmp(VALUE x, VALUE y);
VALUE rb_integer_float_eq(VALUE x, VALUE y);
VALUE rb_cstr_parse_inum(const char *str, ssize_t len, char **endp, int base);
VALUE rb_big_comp(VALUE x);
VALUE rb_big_aref(VALUE x, VALUE y);
VALUE rb_big_abs(VALUE x);
VALUE rb_big_size_m(VALUE big);
VALUE rb_big_bit_length(VALUE big);
VALUE rb_big_remainder(VALUE x, VALUE y);
VALUE rb_big_gt(VALUE x, VALUE y);
VALUE rb_big_ge(VALUE x, VALUE y);
VALUE rb_big_lt(VALUE x, VALUE y);
VALUE rb_big_le(VALUE x, VALUE y);
VALUE rb_int_powm(int const argc, VALUE * const argv, VALUE const num);

/* class.c */
VALUE rb_class_boot(VALUE);
VALUE rb_class_inherited(VALUE, VALUE);
VALUE rb_make_metaclass(VALUE, VALUE);
VALUE rb_include_class_new(VALUE, VALUE);
void rb_class_foreach_subclass(VALUE klass, void (*f)(VALUE, VALUE), VALUE);
void rb_class_detach_subclasses(VALUE);
void rb_class_detach_module_subclasses(VALUE);
void rb_class_remove_from_module_subclasses(VALUE);
VALUE rb_obj_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_obj_protected_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_obj_private_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_obj_public_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_special_singleton_class(VALUE);
VALUE rb_singleton_class_clone_and_attach(VALUE obj, VALUE attach);
VALUE rb_singleton_class_get(VALUE obj);
void Init_class_hierarchy(void);

int rb_class_has_methods(VALUE c);
void rb_undef_methods_from(VALUE klass, VALUE super);

/* compar.c */
VALUE rb_invcmp(VALUE, VALUE);

/* compile.c */
struct rb_block;
int rb_dvar_defined(ID, const struct rb_block *);
int rb_local_defined(ID, const struct rb_block *);
const char * rb_insns_name(int i);
VALUE rb_insns_name_array(void);

/* complex.c */
VALUE rb_complex_plus(VALUE, VALUE);
VALUE rb_complex_mul(VALUE, VALUE);
VALUE rb_complex_abs(VALUE x);
VALUE rb_complex_sqrt(VALUE x);

/* cont.c */
VALUE rb_obj_is_fiber(VALUE);
void rb_fiber_reset_root_local_storage(VALUE);
void ruby_register_rollback_func_for_ensure(VALUE (*ensure_func)(ANYARGS), VALUE (*rollback_func)(ANYARGS));

/* debug.c */
PRINTF_ARGS(void ruby_debug_printf(const char*, ...), 1, 2);

/* dir.c */
VALUE rb_dir_getwd_ospath(void);

/* dmyext.c */
void Init_enc(void);
void Init_ext(void);

/* encoding.c */
ID rb_id_encoding(void);
void rb_gc_mark_encodings(void);
rb_encoding *rb_enc_get_from_index(int index);
rb_encoding *rb_enc_check_str(VALUE str1, VALUE str2);
int rb_encdb_replicate(const char *alias, const char *orig);
int rb_encdb_alias(const char *alias, const char *orig);
int rb_encdb_dummy(const char *name);
void rb_encdb_declare(const char *name);
void rb_enc_set_base(const char *name, const char *orig);
int rb_enc_set_dummy(int index);
void rb_encdb_set_unicode(int index);
PUREFUNC(int rb_data_is_encoding(VALUE obj));

/* enum.c */
VALUE rb_f_send(int argc, VALUE *argv, VALUE recv);
VALUE rb_nmin_run(VALUE obj, VALUE num, int by, int rev, int ary);

/* error.c */
extern VALUE rb_eEAGAIN;
extern VALUE rb_eEWOULDBLOCK;
extern VALUE rb_eEINPROGRESS;
void rb_report_bug_valist(VALUE file, int line, const char *fmt, va_list args);
VALUE rb_syntax_error_append(VALUE, VALUE, int, int, rb_encoding*, const char*, va_list);
VALUE rb_check_backtrace(VALUE);
NORETURN(void rb_async_bug_errno(const char *,int));
const char *rb_builtin_type_name(int t);
const char *rb_builtin_class_name(VALUE x);
PRINTF_ARGS(void rb_sys_warn(const char *fmt, ...), 1, 2);
PRINTF_ARGS(void rb_syserr_warn(int err, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_enc_warn(rb_encoding *enc, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_sys_enc_warn(rb_encoding *enc, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_syserr_enc_warn(int err, rb_encoding *enc, const char *fmt, ...), 3, 4);
PRINTF_ARGS(void rb_sys_warning(const char *fmt, ...), 1, 2);
PRINTF_ARGS(void rb_syserr_warning(int err, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_enc_warning(rb_encoding *enc, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_sys_enc_warning(rb_encoding *enc, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_syserr_enc_warning(int err, rb_encoding *enc, const char *fmt, ...), 3, 4);

#define rb_raise_cstr(etype, mesg) \
    rb_exc_raise(rb_exc_new_str(etype, rb_str_new_cstr(mesg)))
#define rb_raise_static(etype, mesg) \
    rb_exc_raise(rb_exc_new_str(etype, rb_str_new_static(mesg, rb_strlen_lit(mesg))))

VALUE rb_name_err_new(VALUE mesg, VALUE recv, VALUE method);
#define rb_name_err_raise_str(mesg, recv, name) \
    rb_exc_raise(rb_name_err_new(mesg, recv, name))
#define rb_name_err_raise(mesg, recv, name) \
    rb_name_err_raise_str(rb_fstring_cstr(mesg), (recv), (name))
VALUE rb_key_err_new(VALUE mesg, VALUE recv, VALUE name);
#define rb_key_err_raise(mesg, recv, name) \
    rb_exc_raise(rb_key_err_new(mesg, recv, name))
NORETURN(void ruby_deprecated_internal_feature(const char *));
#define DEPRECATED_INTERNAL_FEATURE(func) \
    (ruby_deprecated_internal_feature(func), UNREACHABLE)
VALUE rb_warning_warn(VALUE mod, VALUE str);
VALUE rb_warning_string(const char *fmt, ...);

/* eval.c */
VALUE rb_refinement_module_get_refined_class(VALUE module);

/* eval_error.c */
VALUE rb_get_backtrace(VALUE info);

/* eval_jump.c */
void rb_call_end_proc(VALUE data);
void rb_mark_end_proc(void);

/* file.c */
VALUE rb_home_dir_of(VALUE user, VALUE result);
VALUE rb_default_home_dir(VALUE result);
VALUE rb_realpath_internal(VALUE basedir, VALUE path, int strict);
VALUE rb_check_realpath(VALUE basedir, VALUE path);
void rb_file_const(const char*, VALUE);
int rb_file_load_ok(const char *);
VALUE rb_file_expand_path_fast(VALUE, VALUE);
VALUE rb_file_expand_path_internal(VALUE, VALUE, int, int, VALUE);
VALUE rb_get_path_check_to_string(VALUE, int);
VALUE rb_get_path_check_convert(VALUE, VALUE, int);
VALUE rb_get_path_check(VALUE, int);
void Init_File(void);
int ruby_is_fd_loadable(int fd);

#ifdef RUBY_FUNCTION_NAME_STRING
# if defined __GNUC__ && __GNUC__ >= 4
#   pragma GCC visibility push(default)
# endif
NORETURN(void rb_sys_fail_path_in(const char *func_name, VALUE path));
NORETURN(void rb_syserr_fail_path_in(const char *func_name, int err, VALUE path));
# if defined __GNUC__ && __GNUC__ >= 4
#   pragma GCC visibility pop
# endif
# define rb_sys_fail_path(path) rb_sys_fail_path_in(RUBY_FUNCTION_NAME_STRING, path)
# define rb_syserr_fail_path(err, path) rb_syserr_fail_path_in(RUBY_FUNCTION_NAME_STRING, (err), (path))
#else
# define rb_sys_fail_path(path) rb_sys_fail_str(path)
# define rb_syserr_fail_path(err, path) rb_syserr_fail_str((err), (path))
#endif

/* gc.c */
extern VALUE *ruby_initial_gc_stress_ptr;
extern int ruby_disable_gc;
void Init_heap(void);
void *ruby_mimmalloc(size_t size);
void ruby_mimfree(void *ptr);
void rb_objspace_set_event_hook(const rb_event_flag_t event);
#if USE_RGENGC
void rb_gc_writebarrier_remember(VALUE obj);
#else
#define rb_gc_writebarrier_remember(obj) 0
#endif
void ruby_gc_set_params(int safe_level);
void rb_copy_wb_protected_attribute(VALUE dest, VALUE obj);

#if defined(HAVE_MALLOC_USABLE_SIZE) || defined(HAVE_MALLOC_SIZE) || defined(_WIN32)
#define ruby_sized_xrealloc(ptr, new_size, old_size) ruby_xrealloc(ptr, new_size)
#define ruby_sized_xrealloc2(ptr, new_count, element_size, old_count) ruby_xrealloc(ptr, new_count, element_size)
#define ruby_sized_xfree(ptr, size) ruby_xfree(ptr)
#define SIZED_REALLOC_N(var,type,n,old_n) REALLOC_N(var, type, n)
#else
void *ruby_sized_xrealloc(void *ptr, size_t new_size, size_t old_size) RUBY_ATTR_ALLOC_SIZE((2));
void *ruby_sized_xrealloc2(void *ptr, size_t new_count, size_t element_size, size_t old_count) RUBY_ATTR_ALLOC_SIZE((2, 3));
void ruby_sized_xfree(void *x, size_t size);
#define SIZED_REALLOC_N(var,type,n,old_n) ((var)=(type*)ruby_sized_xrealloc((char*)(var), (n) * sizeof(type), (old_n) * sizeof(type)))
#endif

/* optimized version of NEWOBJ() */
#undef NEWOBJF_OF
#undef RB_NEWOBJ_OF
#define RB_NEWOBJ_OF(obj,type,klass,flags) \
  type *(obj) = (type*)(((flags) & FL_WB_PROTECTED) ? \
			rb_wb_protected_newobj_of(klass, (flags) & ~FL_WB_PROTECTED) : \
			rb_wb_unprotected_newobj_of(klass, flags))
#define NEWOBJ_OF(obj,type,klass,flags) RB_NEWOBJ_OF(obj,type,klass,flags)

/* hash.c */
struct st_table *rb_hash_tbl_raw(VALUE hash);
VALUE rb_hash_new_with_size(st_index_t size);
RUBY_SYMBOL_EXPORT_BEGIN
VALUE rb_hash_new_compare_by_id(void);
RUBY_SYMBOL_EXPORT_END
VALUE rb_hash_has_key(VALUE hash, VALUE key);
VALUE rb_hash_default_value(VALUE hash, VALUE key);
VALUE rb_hash_set_default_proc(VALUE hash, VALUE proc);
long rb_objid_hash(st_index_t index);
long rb_dbl_long_hash(double d);
st_table *rb_init_identtable(void);
st_table *rb_init_identtable_with_size(st_index_t size);
VALUE rb_hash_compare_by_id_p(VALUE hash);
VALUE rb_to_hash_type(VALUE obj);

#define RHASH_TBL_RAW(h) rb_hash_tbl_raw(h)
VALUE rb_hash_keys(VALUE hash);
VALUE rb_hash_values(VALUE hash);
VALUE rb_hash_rehash(VALUE hash);
int rb_hash_add_new_element(VALUE hash, VALUE key, VALUE val);
#define HASH_PROC_DEFAULT FL_USER2

/* inits.c */
void rb_call_inits(void);

/* io.c */
const char *ruby_get_inplace_mode(void);
void ruby_set_inplace_mode(const char *);
ssize_t rb_io_bufread(VALUE io, void *buf, size_t size);
void rb_stdio_set_default_encoding(void);
VALUE rb_io_flush_raw(VALUE, int);
size_t rb_io_memsize(const rb_io_t *);
int rb_stderr_tty_p(void);

/* load.c */
VALUE rb_get_load_path(void);
VALUE rb_get_expanded_load_path(void);
int rb_require_internal(VALUE fname, int safe);
NORETURN(void rb_load_fail(VALUE, const char*));

/* loadpath.c */
extern const char ruby_exec_prefix[];
extern const char ruby_initial_load_paths[];

/* localeinit.c */
int Init_enc_set_filesystem_encoding(void);

/* math.c */
VALUE rb_math_atan2(VALUE, VALUE);
VALUE rb_math_cos(VALUE);
VALUE rb_math_cosh(VALUE);
VALUE rb_math_exp(VALUE);
VALUE rb_math_hypot(VALUE, VALUE);
VALUE rb_math_log(int argc, const VALUE *argv);
VALUE rb_math_sin(VALUE);
VALUE rb_math_sinh(VALUE);
VALUE rb_math_sqrt(VALUE);

/* newline.c */
void Init_newline(void);

/* numeric.c */

#define FIXNUM_POSITIVE_P(num) ((SIGNED_VALUE)(num) > (SIGNED_VALUE)INT2FIX(0))
#define FIXNUM_NEGATIVE_P(num) ((SIGNED_VALUE)(num) < 0)
#define FIXNUM_ZERO_P(num) ((num) == INT2FIX(0))

#define INT_NEGATIVE_P(x) (FIXNUM_P(x) ? FIXNUM_NEGATIVE_P(x) : BIGNUM_NEGATIVE_P(x))

#ifndef ROUND_DEFAULT
# define ROUND_DEFAULT RUBY_NUM_ROUND_HALF_UP
#endif
enum ruby_num_rounding_mode {
    RUBY_NUM_ROUND_HALF_UP,
    RUBY_NUM_ROUND_HALF_EVEN,
    RUBY_NUM_ROUND_HALF_DOWN,
    RUBY_NUM_ROUND_DEFAULT = ROUND_DEFAULT
};
#define ROUND_TO(mode, even, up, down) \
    ((mode) == RUBY_NUM_ROUND_HALF_EVEN ? even : \
     (mode) == RUBY_NUM_ROUND_HALF_UP ? up : down)
#define ROUND_FUNC(mode, name) \
    ROUND_TO(mode, name##_half_even, name##_half_up, name##_half_down)
#define ROUND_CALL(mode, name, args) \
    ROUND_TO(mode, name##_half_even args, \
	     name##_half_up args, name##_half_down args)

int rb_num_to_uint(VALUE val, unsigned int *ret);
VALUE ruby_num_interval_step_size(VALUE from, VALUE to, VALUE step, int excl);
int ruby_float_step(VALUE from, VALUE to, VALUE step, int excl);
double ruby_float_mod(double x, double y);
int rb_num_negative_p(VALUE);
VALUE rb_int_succ(VALUE num);
VALUE rb_int_pred(VALUE num);
VALUE rb_int_uminus(VALUE num);
VALUE rb_float_uminus(VALUE num);
VALUE rb_int_plus(VALUE x, VALUE y);
VALUE rb_int_minus(VALUE x, VALUE y);
VALUE rb_int_mul(VALUE x, VALUE y);
VALUE rb_int_idiv(VALUE x, VALUE y);
VALUE rb_int_modulo(VALUE x, VALUE y);
VALUE rb_int_round(VALUE num, int ndigits, enum ruby_num_rounding_mode mode);
VALUE rb_int2str(VALUE num, int base);
VALUE rb_dbl_hash(double d);
VALUE rb_fix_plus(VALUE x, VALUE y);
VALUE rb_int_gt(VALUE x, VALUE y);
int rb_float_cmp(VALUE x, VALUE y);
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
VALUE rb_int_abs(VALUE num);
VALUE rb_int_odd_p(VALUE num);

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


VALUE rb_float_abs(VALUE flt);
VALUE rb_float_equal(VALUE x, VALUE y);
VALUE rb_float_eql(VALUE x, VALUE y);

#if USE_FLONUM
#define RUBY_BIT_ROTL(v, n) (((v) << (n)) | ((v) >> ((sizeof(v) * 8) - n)))
#define RUBY_BIT_ROTR(v, n) (((v) >> (n)) | ((v) << ((sizeof(v) * 8) - n)))
#endif

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
    return ((struct RFloat *)v)->float_value;
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

#define rb_float_value(v) rb_float_value_inline(v)
#define rb_float_new(d)   rb_float_new_inline(d)

/* object.c */
void rb_obj_copy_ivar(VALUE dest, VALUE obj);
CONSTFUNC(VALUE rb_obj_equal(VALUE obj1, VALUE obj2));
CONSTFUNC(VALUE rb_obj_not(VALUE obj));
VALUE rb_class_search_ancestor(VALUE klass, VALUE super);
NORETURN(void rb_undefined_alloc(VALUE klass));
double rb_num_to_dbl(VALUE val);
VALUE rb_obj_dig(int argc, VALUE *argv, VALUE self, VALUE notfound);
VALUE rb_immutable_obj_clone(int, VALUE *, VALUE);
VALUE rb_obj_not_equal(VALUE obj1, VALUE obj2);
VALUE rb_convert_type_with_id(VALUE,int,const char*,ID);
VALUE rb_check_convert_type_with_id(VALUE,int,const char*,ID);

struct RBasicRaw {
    VALUE flags;
    VALUE klass;
};

#define RBASIC_CLEAR_CLASS(obj)        memset(&(((struct RBasicRaw *)((VALUE)(obj)))->klass), 0, sizeof(VALUE))
#define RBASIC_SET_CLASS_RAW(obj, cls) memcpy(&((struct RBasicRaw *)((VALUE)(obj)))->klass, &(cls), sizeof(VALUE))
#define RBASIC_SET_CLASS(obj, cls)     do { \
    VALUE _obj_ = (obj); \
    RB_OBJ_WRITE(_obj_, &((struct RBasicRaw *)(_obj_))->klass, cls); \
} while (0)

/* parse.y */
#ifndef USE_SYMBOL_GC
#define USE_SYMBOL_GC 1
#endif
VALUE rb_parser_get_yydebug(VALUE);
VALUE rb_parser_set_yydebug(VALUE, VALUE);
VALUE rb_parser_set_context(VALUE, const struct rb_block *, int);
void *rb_parser_load_file(VALUE parser, VALUE name);
int rb_is_const_name(VALUE name);
int rb_is_class_name(VALUE name);
int rb_is_global_name(VALUE name);
int rb_is_instance_name(VALUE name);
int rb_is_attrset_name(VALUE name);
int rb_is_local_name(VALUE name);
int rb_is_method_name(VALUE name);
int rb_is_junk_name(VALUE name);
PUREFUNC(int rb_is_const_sym(VALUE sym));
PUREFUNC(int rb_is_class_sym(VALUE sym));
PUREFUNC(int rb_is_global_sym(VALUE sym));
PUREFUNC(int rb_is_instance_sym(VALUE sym));
PUREFUNC(int rb_is_attrset_sym(VALUE sym));
PUREFUNC(int rb_is_local_sym(VALUE sym));
PUREFUNC(int rb_is_method_sym(VALUE sym));
PUREFUNC(int rb_is_junk_sym(VALUE sym));
ID rb_make_internal_id(void);
void rb_gc_free_dsymbol(VALUE);
ID rb_id_attrget(ID id);

/* proc.c */
VALUE rb_proc_location(VALUE self);
st_index_t rb_hash_proc(st_index_t hash, VALUE proc);
int rb_block_arity(void);
int rb_block_min_max_arity(int *max);
VALUE rb_func_proc_new(rb_block_call_func_t func, VALUE val);
VALUE rb_func_lambda_new(rb_block_call_func_t func, VALUE val, int min_argc, int max_argc);
VALUE rb_block_to_s(VALUE self, const struct rb_block *block, const char *additional_info);

/* process.c */
#define RB_MAX_GROUPS (65536)

struct rb_execarg {
    union {
        struct {
            VALUE shell_script;
        } sh;
        struct {
            VALUE command_name;
            VALUE command_abspath; /* full path string or nil */
            VALUE argv_str;
            VALUE argv_buf;
        } cmd;
    } invoke;
    VALUE redirect_fds;
    VALUE envp_str;
    VALUE envp_buf;
    VALUE dup2_tmpbuf;
    unsigned use_shell : 1;
    unsigned pgroup_given : 1;
    unsigned umask_given : 1;
    unsigned unsetenv_others_given : 1;
    unsigned unsetenv_others_do : 1;
    unsigned close_others_given : 1;
    unsigned close_others_do : 1;
    unsigned chdir_given : 1;
    unsigned new_pgroup_given : 1;
    unsigned new_pgroup_flag : 1;
    unsigned uid_given : 1;
    unsigned gid_given : 1;
    rb_pid_t pgroup_pgid; /* asis(-1), new pgroup(0), specified pgroup (0<V). */
    VALUE rlimit_limits; /* Qfalse or [[rtype, softlim, hardlim], ...] */
    mode_t umask_mask;
    rb_uid_t uid;
    rb_gid_t gid;
    int close_others_maxhint;
    VALUE fd_dup2;
    VALUE fd_close;
    VALUE fd_open;
    VALUE fd_dup2_child;
    VALUE env_modification; /* Qfalse or [[k1,v1], ...] */
    VALUE path_env;
    VALUE chdir_dir;
};

/* argv_str contains extra two elements.
 * The beginning one is for /bin/sh used by exec_with_sh.
 * The last one for terminating NULL used by execve.
 * See rb_exec_fillarg() in process.c. */
#define ARGVSTR2ARGC(argv_str) (RSTRING_LEN(argv_str) / sizeof(char *) - 2)
#define ARGVSTR2ARGV(argv_str) ((char **)RSTRING_PTR(argv_str) + 1)

rb_pid_t rb_fork_ruby(int *status);
void rb_last_status_clear(void);

/* rational.c */
VALUE rb_rational_uminus(VALUE self);
VALUE rb_rational_plus(VALUE self, VALUE other);
VALUE rb_lcm(VALUE x, VALUE y);
VALUE rb_rational_reciprocal(VALUE x);
VALUE rb_cstr_to_rat(const char *, int);
VALUE rb_rational_abs(VALUE self);
VALUE rb_rational_cmp(VALUE self, VALUE other);
VALUE rb_numeric_quo(VALUE x, VALUE y);

/* re.c */
VALUE rb_reg_compile(VALUE str, int options, const char *sourcefile, int sourceline);
VALUE rb_reg_check_preprocess(VALUE);
long rb_reg_search0(VALUE, VALUE, long, int, int);
VALUE rb_reg_match_p(VALUE re, VALUE str, long pos);
bool rb_reg_start_with_p(VALUE re, VALUE str);
void rb_backref_set_string(VALUE string, long pos, long len);
int rb_match_count(VALUE match);
int rb_match_nth_defined(int nth, VALUE match);

/* signal.c */
extern int ruby_enable_coredump;
int rb_get_next_signal(void);
int rb_sigaltstack_size(void);

/* st.c */
extern void rb_hash_bulk_insert(long, const VALUE *, VALUE);

/* strftime.c */
#ifdef RUBY_ENCODING_H
VALUE rb_strftime_timespec(const char *format, size_t format_len, rb_encoding *enc,
			   const struct vtm *vtm, struct timespec *ts, int gmt);
VALUE rb_strftime(const char *format, size_t format_len, rb_encoding *enc,
		  const struct vtm *vtm, VALUE timev, int gmt);
#endif

/* string.c */
VALUE rb_fstring(VALUE);
VALUE rb_fstring_new(const char *ptr, long len);
#define rb_fstring_lit(str) rb_fstring_new((str), rb_strlen_lit(str))
#define rb_fstring_literal(str) rb_fstring_lit(str)
VALUE rb_fstring_cstr(const char *str);
#ifdef HAVE_BUILTIN___BUILTIN_CONSTANT_P
# define rb_fstring_cstr(str) RB_GNUC_EXTENSION_BLOCK(	\
    (__builtin_constant_p(str)) ?		\
	rb_fstring_new((str), (long)strlen(str)) : \
	rb_fstring_cstr(str) \
)
#endif
#ifdef RUBY_ENCODING_H
VALUE rb_fstring_enc_new(const char *ptr, long len, rb_encoding *enc);
#define rb_fstring_enc_lit(str, enc) rb_fstring_enc_new((str), rb_strlen_lit(str), (enc))
#define rb_fstring_enc_literal(str, enc) rb_fstring_enc_lit(str, enc)
VALUE rb_fstring_enc_cstr(const char *ptr, rb_encoding *enc);
# ifdef HAVE_BUILTIN___BUILTIN_CONSTANT_P
#  define rb_fstring_enc_cstr(str, enc) RB_GNUC_EXTENSION_BLOCK( \
    (__builtin_constant_p(str)) ?		\
	rb_fstring_enc_new((str), (long)strlen(str), (enc)) : \
	rb_fstring_enc_cstr(str, enc) \
)
# endif
#endif
int rb_str_buf_cat_escaped_char(VALUE result, unsigned int c, int unicode_p);
int rb_str_symname_p(VALUE);
VALUE rb_str_quote_unprintable(VALUE);
VALUE rb_id_quote_unprintable(ID);
#define QUOTE(str) rb_str_quote_unprintable(str)
#define QUOTE_ID(id) rb_id_quote_unprintable(id)
char *rb_str_fill_terminator(VALUE str, const int termlen);
void rb_str_change_terminator_length(VALUE str, const int oldtermlen, const int termlen);
VALUE rb_str_locktmp_ensure(VALUE str, VALUE (*func)(VALUE), VALUE arg);
VALUE rb_str_tmp_frozen_acquire(VALUE str);
void rb_str_tmp_frozen_release(VALUE str, VALUE tmp);
VALUE rb_str_chomp_string(VALUE str, VALUE chomp);
#ifdef RUBY_ENCODING_H
VALUE rb_external_str_with_enc(VALUE str, rb_encoding *eenc);
VALUE rb_str_cat_conv_enc_opts(VALUE newstr, long ofs, const char *ptr, long len,
			       rb_encoding *from, int ecflags, VALUE ecopts);
VALUE rb_enc_str_scrub(rb_encoding *enc, VALUE str, VALUE repl);
VALUE rb_str_initialize(VALUE str, const char *ptr, long len, rb_encoding *enc);
#endif
#define STR_NOEMBED      FL_USER1
#define STR_SHARED       FL_USER2 /* = ELTS_SHARED */
#define STR_EMBED_P(str) (!FL_TEST_RAW((str), STR_NOEMBED))
#define STR_SHARED_P(s)  FL_ALL_RAW((s), STR_NOEMBED|ELTS_SHARED)
#define is_ascii_string(str) (rb_enc_str_coderange(str) == ENC_CODERANGE_7BIT)
#define is_broken_string(str) (rb_enc_str_coderange(str) == ENC_CODERANGE_BROKEN)
size_t rb_str_memsize(VALUE);
VALUE rb_sym_proc_call(ID mid, int argc, const VALUE *argv, VALUE passed_proc);
VALUE rb_sym_to_proc(VALUE sym);
char *rb_str_to_cstr(VALUE str);
VALUE rb_str_eql(VALUE str1, VALUE str2);

/* symbol.c */
#ifdef RUBY_ENCODING_H
VALUE rb_sym_intern(const char *ptr, long len, rb_encoding *enc);
VALUE rb_sym_intern_cstr(const char *ptr, rb_encoding *enc);
#ifdef __GNUC__
#define rb_sym_intern_cstr(ptr, enc) __extension__ ( \
{						\
    (__builtin_constant_p(ptr)) ?		\
	rb_sym_intern((ptr), (long)strlen(ptr), (enc)) : \
	rb_sym_intern_cstr((ptr), (enc)); \
})
#endif
#endif
VALUE rb_sym_intern_ascii(const char *ptr, long len);
VALUE rb_sym_intern_ascii_cstr(const char *ptr);
#ifdef __GNUC__
#define rb_sym_intern_ascii_cstr(ptr) __extension__ ( \
{						\
    (__builtin_constant_p(ptr)) ?		\
	rb_sym_intern_ascii((ptr), (long)strlen(ptr)) : \
	rb_sym_intern_ascii_cstr(ptr); \
})
#endif
VALUE rb_to_symbol_type(VALUE obj);

/* struct.c */
VALUE rb_struct_init_copy(VALUE copy, VALUE s);
VALUE rb_struct_lookup(VALUE s, VALUE idx);

/* time.c */
struct timeval rb_time_timeval(VALUE);

/* thread.c */
#define COVERAGE_INDEX_LINES    0
#define COVERAGE_INDEX_BRANCHES 1
#define COVERAGE_TARGET_LINES    1
#define COVERAGE_TARGET_BRANCHES 2
#define COVERAGE_TARGET_METHODS  4

VALUE rb_obj_is_mutex(VALUE obj);
VALUE rb_suppress_tracing(VALUE (*func)(VALUE), VALUE arg);
void rb_thread_execute_interrupts(VALUE th);
void rb_clear_trace_func(void);
VALUE rb_get_coverages(void);
VALUE rb_default_coverage(int);
VALUE rb_thread_shield_new(void);
VALUE rb_thread_shield_wait(VALUE self);
VALUE rb_thread_shield_release(VALUE self);
VALUE rb_thread_shield_destroy(VALUE self);
int rb_thread_to_be_killed(VALUE thread);
void rb_mutex_allow_trap(VALUE self, int val);
VALUE rb_uninterruptible(VALUE (*b_proc)(ANYARGS), VALUE data);
VALUE rb_mutex_owned_p(VALUE self);

/* thread_pthread.c, thread_win32.c */
int rb_divert_reserved_fd(int fd);

/* transcode.c */
extern VALUE rb_cEncodingConverter;
size_t rb_econv_memsize(rb_econv_t *);

/* us_ascii.c */
extern rb_encoding OnigEncodingUS_ASCII;

/* util.c */
char *ruby_dtoa(double d_, int mode, int ndigits, int *decpt, int *sign, char **rve);
char *ruby_hdtoa(double d, const char *xdigs, int ndigits, int *decpt, int *sign, char **rve);

/* utf_8.c */
extern rb_encoding OnigEncodingUTF_8;

/* variable.c */
void rb_gc_mark_global_tbl(void);
size_t rb_generic_ivar_memsize(VALUE);
VALUE rb_search_class_path(VALUE);
VALUE rb_attr_delete(VALUE, ID);
VALUE rb_ivar_lookup(VALUE obj, ID id, VALUE undef);
void rb_autoload_str(VALUE mod, ID id, VALUE file);
void rb_deprecate_constant(VALUE mod, const char *name);

/* version.c */
extern const char ruby_engine[];

/* vm_insnhelper.h */
rb_serial_t rb_next_class_serial(void);

/* vm.c */
VALUE rb_obj_is_thread(VALUE obj);
void rb_vm_mark(void *ptr);
void Init_BareVM(void);
void Init_vm_objects(void);
PUREFUNC(VALUE rb_vm_top_self(void));
void rb_thread_recycle_stack_release(VALUE *);
void rb_vm_change_state(void);
void rb_vm_inc_const_missing_count(void);
const void **rb_vm_get_insns_address_table(void);
VALUE rb_source_location(int *pline);
const char *rb_source_location_cstr(int *pline);
void rb_vm_pop_cfunc_frame(void);
int rb_vm_add_root_module(ID id, VALUE module);
void rb_vm_check_redefinition_by_prepend(VALUE klass);
VALUE rb_yield_refine_block(VALUE refinement, VALUE refinements);
VALUE ruby_vm_special_exception_copy(VALUE);
PUREFUNC(st_table *rb_vm_fstring_table(void));


/* vm_dump.c */
void rb_print_backtrace(void);

/* vm_eval.c */
void Init_vm_eval(void);
VALUE rb_current_realfilepath(void);
VALUE rb_check_block_call(VALUE, ID, int, const VALUE *, rb_block_call_func_t, VALUE);
typedef void rb_check_funcall_hook(int, VALUE, ID, int, const VALUE *, VALUE);
VALUE rb_check_funcall_with_hook(VALUE recv, ID mid, int argc, const VALUE *argv,
				 rb_check_funcall_hook *hook, VALUE arg);
const char *rb_type_str(enum ruby_value_type type);
VALUE rb_check_funcall_default(VALUE, ID, int, const VALUE *, VALUE);
VALUE rb_yield_1(VALUE val);
VALUE rb_yield_force_blockarg(VALUE values);
VALUE rb_lambda_call(VALUE obj, ID mid, int argc, const VALUE *argv,
		     rb_block_call_func_t bl_proc, int min_argc, int max_argc,
		     VALUE data2);

/* vm_insnhelper.c */
VALUE rb_equal_opt(VALUE obj1, VALUE obj2);
VALUE rb_eql_opt(VALUE obj1, VALUE obj2);

/* vm_method.c */
void Init_eval_method(void);
int rb_method_defined_by(VALUE obj, ID mid, VALUE (*cfunc)(ANYARGS));

/* miniprelude.c, prelude.c */
void Init_prelude(void);

/* vm_backtrace.c */
void Init_vm_backtrace(void);
VALUE rb_vm_thread_backtrace(int argc, const VALUE *argv, VALUE thval);
VALUE rb_vm_thread_backtrace_locations(int argc, const VALUE *argv, VALUE thval);

VALUE rb_make_backtrace(void);
void rb_backtrace_print_as_bugreport(void);
int rb_backtrace_p(VALUE obj);
VALUE rb_backtrace_to_str_ary(VALUE obj);
VALUE rb_backtrace_to_location_ary(VALUE obj);
void rb_backtrace_each(VALUE (*iter)(VALUE recv, VALUE str), VALUE output);

RUBY_SYMBOL_EXPORT_BEGIN
const char *rb_objspace_data_type_name(VALUE obj);

/* Temporary.  This API will be removed (renamed). */
VALUE rb_thread_io_blocking_region(rb_blocking_function_t *func, void *data1, int fd);

/* bignum.c (export) */
VALUE rb_big_mul_normal(VALUE x, VALUE y);
VALUE rb_big_mul_balance(VALUE x, VALUE y);
VALUE rb_big_mul_karatsuba(VALUE x, VALUE y);
VALUE rb_big_mul_toom3(VALUE x, VALUE y);
VALUE rb_big_sq_fast(VALUE x);
VALUE rb_big_divrem_normal(VALUE x, VALUE y);
VALUE rb_big2str_poweroftwo(VALUE x, int base);
VALUE rb_big2str_generic(VALUE x, int base);
VALUE rb_str2big_poweroftwo(VALUE arg, int base, int badcheck);
VALUE rb_str2big_normal(VALUE arg, int base, int badcheck);
VALUE rb_str2big_karatsuba(VALUE arg, int base, int badcheck);
#if defined(HAVE_LIBGMP) && defined(HAVE_GMP_H)
VALUE rb_big_mul_gmp(VALUE x, VALUE y);
VALUE rb_big_divrem_gmp(VALUE x, VALUE y);
VALUE rb_big2str_gmp(VALUE x, int base);
VALUE rb_str2big_gmp(VALUE arg, int base, int badcheck);
#endif
enum rb_int_parse_flags {
    RB_INT_PARSE_SIGN       = 0x01,
    RB_INT_PARSE_UNDERSCORE = 0x02,
    RB_INT_PARSE_PREFIX     = 0x04,
    RB_INT_PARSE_ALL        = 0x07,
    RB_INT_PARSE_DEFAULT    = 0x07
};
VALUE rb_int_parse_cstr(const char *str, ssize_t len, char **endp, size_t *ndigits, int base, int flags);

/* error.c (export) */
int rb_bug_reporter_add(void (*func)(FILE *, void *), void *data);
NORETURN(void rb_unexpected_type(VALUE,int));
#undef Check_Type
#define Check_Type(v, t) \
    (!RB_TYPE_P((VALUE)(v), (t)) || \
     ((t) == RUBY_T_DATA && RTYPEDDATA_P(v)) ? \
     rb_unexpected_type((VALUE)(v), (t)) : (void)0)

/* file.c (export) */
#ifdef HAVE_READLINK
VALUE rb_readlink(VALUE path, rb_encoding *enc);
#endif
#ifdef __APPLE__
VALUE rb_str_normalize_ospath(const char *ptr, long len);
#endif

/* hash.c (export) */
VALUE rb_hash_delete_entry(VALUE hash, VALUE key);
VALUE rb_ident_hash_new(void);

/* io.c (export) */
void rb_maygvl_fd_fix_cloexec(int fd);
int rb_gc_for_fd(int err);
void rb_write_error_str(VALUE mesg);

/* numeric.c (export) */
VALUE rb_int_positive_pow(long x, unsigned long y);

/* process.c (export) */
int rb_exec_async_signal_safe(const struct rb_execarg *e, char *errmsg, size_t errmsg_buflen);
rb_pid_t rb_fork_async_signal_safe(int *status, int (*chfunc)(void*, char *, size_t), void *charg, VALUE fds, char *errmsg, size_t errmsg_buflen);
VALUE rb_execarg_new(int argc, const VALUE *argv, int accept_shell);
struct rb_execarg *rb_execarg_get(VALUE execarg_obj); /* dangerous.  needs GC guard. */
VALUE rb_execarg_init(int argc, const VALUE *argv, int accept_shell, VALUE execarg_obj);
int rb_execarg_addopt(VALUE execarg_obj, VALUE key, VALUE val);
void rb_execarg_parent_start(VALUE execarg_obj);
void rb_execarg_parent_end(VALUE execarg_obj);
int rb_execarg_run_options(const struct rb_execarg *e, struct rb_execarg *s, char* errmsg, size_t errmsg_buflen);
VALUE rb_execarg_extract_options(VALUE execarg_obj, VALUE opthash);
void rb_execarg_setenv(VALUE execarg_obj, VALUE env);

/* rational.c (export) */
VALUE rb_gcd(VALUE x, VALUE y);
VALUE rb_gcd_normal(VALUE self, VALUE other);
#if defined(HAVE_LIBGMP) && defined(HAVE_GMP_H)
VALUE rb_gcd_gmp(VALUE x, VALUE y);
#endif

/* string.c (export) */
#ifdef RUBY_ENCODING_H
/* internal use */
VALUE rb_setup_fake_str(struct RString *fake_str, const char *name, long len, rb_encoding *enc);
#endif

/* thread.c (export) */
int ruby_thread_has_gvl_p(void); /* for ext/fiddle/closure.c */

/* util.c (export) */
extern const signed char ruby_digit36_to_number_table[];
extern const char ruby_hexdigits[];
extern unsigned long ruby_scan_digits(const char *str, ssize_t len, int base, size_t *retlen, int *overflow);

/* variable.c (export) */
void rb_mark_generic_ivar(VALUE);
VALUE rb_const_missing(VALUE klass, VALUE name);
int rb_class_ivar_set(VALUE klass, ID vid, VALUE value);
st_table *rb_st_copy(VALUE obj, struct st_table *orig_tbl);

/* gc.c (export) */
VALUE rb_wb_protected_newobj_of(VALUE, VALUE);
VALUE rb_wb_unprotected_newobj_of(VALUE, VALUE);

size_t rb_obj_memsize_of(VALUE);
void rb_gc_verify_internal_consistency(void);

#define RB_OBJ_GC_FLAGS_MAX 5
size_t rb_obj_gc_flags(VALUE, ID[], size_t);
void rb_gc_mark_values(long n, const VALUE *values);

#if IMEMO_DEBUG
VALUE rb_imemo_new_debug(enum imemo_type type, VALUE v1, VALUE v2, VALUE v3, VALUE v0, const char *file, int line);
#define rb_imemo_new(type, v1, v2, v3, v0) rb_imemo_new_debug(type, v1, v2, v3, v0, __FILE__, __LINE__)
#else
VALUE rb_imemo_new(enum imemo_type type, VALUE v1, VALUE v2, VALUE v3, VALUE v0);
#endif

RUBY_SYMBOL_EXPORT_END

#define RUBY_DTRACE_CREATE_HOOK(name, arg) \
    RUBY_DTRACE_HOOK(name##_CREATE, arg)
#define RUBY_DTRACE_HOOK(name, arg) \
do { \
    if (UNLIKELY(RUBY_DTRACE_##name##_ENABLED())) { \
	int dtrace_line; \
	const char *dtrace_file = rb_source_location_cstr(&dtrace_line); \
	if (!dtrace_file) dtrace_file = ""; \
	RUBY_DTRACE_##name(arg, dtrace_file, dtrace_line); \
    } \
} while (0)

#define RB_OBJ_BUILTIN_TYPE(obj) rb_obj_builtin_type(obj)
#define OBJ_BUILTIN_TYPE(obj) RB_OBJ_BUILTIN_TYPE(obj)
#ifdef __GNUC__
#define rb_obj_builtin_type(obj) \
__extension__({ \
    VALUE arg_obj = (obj); \
    RB_SPECIAL_CONST_P(arg_obj) ? -1 : \
	RB_BUILTIN_TYPE(arg_obj); \
    })
#else
static inline int
rb_obj_builtin_type(VALUE obj)
{
    return RB_SPECIAL_CONST_P(obj) ? -1 :
	RB_BUILTIN_TYPE(obj);
}
#endif

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
}  /* extern "C" { */
#endif

#endif /* RUBY_INTERNAL_H */
