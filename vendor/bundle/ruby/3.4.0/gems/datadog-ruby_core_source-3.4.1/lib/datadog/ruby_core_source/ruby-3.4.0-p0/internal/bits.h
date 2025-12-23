#ifndef INTERNAL_BITS_H                                  /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_BITS_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for bitwise integer algorithms.
 * @see        Henry S. Warren Jr., "Hacker's Delight" (2nd ed.), 2013.
 * @see        SEI CERT C Coding Standard  INT32-C.  "Ensure that operations on
 *             signed integers do not result in overflow"
 * @see        https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html
 * @see        https://clang.llvm.org/docs/LanguageExtensions.html#builtin-rotateleft
 * @see        https://clang.llvm.org/docs/LanguageExtensions.html#builtin-rotateright
 * @see        https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/byteswap-uint64-byteswap-ulong-byteswap-ushort
 * @see        https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/rotl-rotl64-rotr-rotr64
 * @see        https://docs.microsoft.com/en-us/cpp/intrinsics/bitscanforward-bitscanforward64
 * @see        https://docs.microsoft.com/en-us/cpp/intrinsics/bitscanreverse-bitscanreverse64
 * @see        https://docs.microsoft.com/en-us/cpp/intrinsics/lzcnt16-lzcnt-lzcnt64
 * @see        https://docs.microsoft.com/en-us/cpp/intrinsics/popcnt16-popcnt-popcnt64
 * @see        https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=_lzcnt_u32
 * @see        https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=_tzcnt_u32
 * @see        https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=_rotl64
 * @see        https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=_rotr64
 * @see        https://stackoverflow.com/a/776523
 */
#include "ruby/internal/config.h"
#include <limits.h>             /* for CHAR_BITS */
#include <stdint.h>             /* for uintptr_t */
#include "internal/compilers.h" /* for MSC_VERSION_SINCE */

#if MSC_VERSION_SINCE(1310)
# include <stdlib.h>            /* for _byteswap_uint64 */
#endif

#if defined(HAVE_X86INTRIN_H)
# include <x86intrin.h>         /* for _lzcnt_u64 */
#elif MSC_VERSION_SINCE(1310)
# include <intrin.h>            /* for the following intrinsics */
#endif

#if defined(_MSC_VER) && defined(__AVX__)
# pragma intrinsic(__popcnt)
# pragma intrinsic(__popcnt64)
#endif

#if defined(_MSC_VER) && defined(__AVX2__)
# pragma intrinsic(__lzcnt)
# pragma intrinsic(__lzcnt64)
#endif

#if MSC_VERSION_SINCE(1310)
# pragma intrinsic(_rotl)
# pragma intrinsic(_rotr)
# ifdef _WIN64
#  pragma intrinsic(_rotl64)
#  pragma intrinsic(_rotr64)
# endif
#endif

#if MSC_VERSION_SINCE(1400)
# pragma intrinsic(_BitScanForward)
# pragma intrinsic(_BitScanReverse)
# ifdef _WIN64
#  pragma intrinsic(_BitScanForward64)
#  pragma intrinsic(_BitScanReverse64)
# endif
#endif

#include "ruby/ruby.h"              /* for VALUE */
#include "internal/static_assert.h" /* for STATIC_ASSERT */

/* The most significant bit of the lower part of half-long integer.
 * If sizeof(long) == 4, this is 0x8000.
 * If sizeof(long) == 8, this is 0x80000000.
 */
#define HALF_LONG_MSB ((SIGNED_VALUE)1<<((SIZEOF_LONG*CHAR_BIT-1)/2))

#define SIGNED_INTEGER_TYPE_P(T) (0 > ((T)0)-1)

#define SIGNED_INTEGER_MIN(T)                           \
    ((sizeof(T) == sizeof(int8_t))  ? ((T)INT8_MIN)  :  \
    ((sizeof(T) == sizeof(int16_t)) ? ((T)INT16_MIN) :  \
    ((sizeof(T) == sizeof(int32_t)) ? ((T)INT32_MIN) :  \
    ((sizeof(T) == sizeof(int64_t)) ? ((T)INT64_MIN) :  \
     0))))

#define SIGNED_INTEGER_MAX(T) ((T)(SIGNED_INTEGER_MIN(T) ^ ((T)~(T)0)))

#define UNSIGNED_INTEGER_MAX(T) ((T)~(T)0)

#ifndef MUL_OVERFLOW_SIGNED_INTEGER_P
#if __has_builtin(__builtin_mul_overflow_p)
# define MUL_OVERFLOW_P(a, b) \
    __builtin_mul_overflow_p((a), (b), (__typeof__(a * b))0)
#elif __has_builtin(__builtin_mul_overflow)
# define MUL_OVERFLOW_P(a, b) \
    __extension__ ({ __typeof__(a) c; __builtin_mul_overflow((a), (b), &c); })
#endif

#define MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, min, max) ( \
    (a) == 0 ? 0 : \
    (a) == -1 ? (b) < -(max) : \
    (a) > 0 ? \
      ((b) > 0 ? (max) / (a) < (b) : (min) / (a) > (b)) : \
      ((b) > 0 ? (min) / (a) < (b) : (max) / (a) > (b)))

#if __has_builtin(__builtin_mul_overflow_p)
/* __builtin_mul_overflow_p can take bitfield */
/* and GCC permits bitfields for integers other than int */
# define MUL_OVERFLOW_FIXNUM_P(a, b) \
    __extension__ ({ \
        struct { long fixnum : sizeof(long) * CHAR_BIT - 1; } c = { 0 }; \
        __builtin_mul_overflow_p((a), (b), c.fixnum); \
    })
#else
# define MUL_OVERFLOW_FIXNUM_P(a, b) \
    MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, FIXNUM_MIN, FIXNUM_MAX)
#endif

#if defined(MUL_OVERFLOW_P) && defined(USE___BUILTIN_MUL_OVERFLOW_LONG_LONG)
# define MUL_OVERFLOW_LONG_LONG_P(a, b) MUL_OVERFLOW_P(a, b)
#else
# define MUL_OVERFLOW_LONG_LONG_P(a, b) MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, LLONG_MIN, LLONG_MAX)
#endif

#ifdef MUL_OVERFLOW_P
# define MUL_OVERFLOW_LONG_P(a, b)      MUL_OVERFLOW_P(a, b)
# define MUL_OVERFLOW_INT_P(a, b)       MUL_OVERFLOW_P(a, b)
#else
# define MUL_OVERFLOW_LONG_P(a, b)      MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, LONG_MIN, LONG_MAX)
# define MUL_OVERFLOW_INT_P(a, b)       MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, INT_MIN, INT_MAX)
#endif
#endif

#ifndef ADD_OVERFLOW_SIGNED_INTEGER_P
#if __has_builtin(__builtin_add_overflow_p)
# define ADD_OVERFLOW_P(a, b) \
    __builtin_add_overflow_p((a), (b), (__typeof__(a * b))0)
#elif __has_builtin(__builtin_add_overflow)
# define ADD_OVERFLOW_P(a, b) \
    __extension__ ({ __typeof__(a) c; __builtin_add_overflow((a), (b), &c); })
#endif

#define ADD_OVERFLOW_SIGNED_INTEGER_P(a, b, min, max) ( \
    (a) > 0 ? (b) > (max) - (a) : (b) < (min) - (a))

#if __has_builtin(__builtin_add_overflow_p)
/* __builtin_add_overflow_p can take bitfield */
/* and GCC permits bitfields for integers other than int */
# define ADD_OVERFLOW_FIXNUM_P(a, b) \
    __extension__ ({ \
        struct { long fixnum : sizeof(long) * CHAR_BIT - 1; } c = { 0 }; \
        __builtin_add_overflow_p((a), (b), c.fixnum); \
    })
#else
# define ADD_OVERFLOW_FIXNUM_P(a, b) \
    ADD_OVERFLOW_SIGNED_INTEGER_P(a, b, FIXNUM_MIN, FIXNUM_MAX)
#endif

#if defined(ADD_OVERFLOW_P) && defined(USE___BUILTIN_ADD_OVERFLOW_LONG_LONG)
# define ADD_OVERFLOW_LONG_LONG_P(a, b) ADD_OVERFLOW_P(a, b)
#else
# define ADD_OVERFLOW_LONG_LONG_P(a, b) ADD_OVERFLOW_SIGNED_INTEGER_P(a, b, LLONG_MIN, LLONG_MAX)
#endif

#ifdef ADD_OVERFLOW_P
# define ADD_OVERFLOW_LONG_P(a, b)      ADD_OVERFLOW_P(a, b)
# define ADD_OVERFLOW_INT_P(a, b)       ADD_OVERFLOW_P(a, b)
#else
# define ADD_OVERFLOW_LONG_P(a, b)      ADD_OVERFLOW_SIGNED_INTEGER_P(a, b, LONG_MIN, LONG_MAX)
# define ADD_OVERFLOW_INT_P(a, b)       ADD_OVERFLOW_SIGNED_INTEGER_P(a, b, INT_MIN, INT_MAX)
#endif
#endif

#ifndef SUB_OVERFLOW_SIGNED_INTEGER_P
#if __has_builtin(__builtin_sub_overflow_p)
# define SUB_OVERFLOW_P(a, b) \
    __builtin_sub_overflow_p((a), (b), (__typeof__(a * b))0)
#elif __has_builtin(__builtin_sub_overflow)
# define SUB_OVERFLOW_P(a, b) \
    __extension__ ({ __typeof__(a) c; __builtin_sub_overflow((a), (b), &c); })
#endif

#define SUB_OVERFLOW_SIGNED_INTEGER_P(a, b, min, max) ( \
        (b) > 0 ? (a) < (min) + (b) : (a) > (max) + (b))

#if __has_builtin(__builtin_sub_overflow_p)
/* __builtin_sub_overflow_p can take bitfield */
/* and GCC permits bitfields for integers other than int */
# define SUB_OVERFLOW_FIXNUM_P(a, b) \
    __extension__ ({ \
        struct { long fixnum : sizeof(long) * CHAR_BIT - 1; } c = { 0 }; \
        __builtin_sub_overflow_p((a), (b), c.fixnum); \
    })
#else
# define SUB_OVERFLOW_FIXNUM_P(a, b) \
    SUB_OVERFLOW_SIGNED_INTEGER_P(a, b, FIXNUM_MIN, FIXNUM_MAX)
#endif

#if defined(SUB_OVERFLOW_P) && defined(USE___BUILTIN_SUB_OVERFLOW_LONG_LONG)
# define SUB_OVERFLOW_LONG_LONG_P(a, b) SUB_OVERFLOW_P(a, b)
#else
# define SUB_OVERFLOW_LONG_LONG_P(a, b) SUB_OVERFLOW_SIGNED_INTEGER_P(a, b, LLONG_MIN, LLONG_MAX)
#endif

#ifdef SUB_OVERFLOW_P
# define SUB_OVERFLOW_LONG_P(a, b)      SUB_OVERFLOW_P(a, b)
# define SUB_OVERFLOW_INT_P(a, b)       SUB_OVERFLOW_P(a, b)
#else
# define SUB_OVERFLOW_LONG_P(a, b)      SUB_OVERFLOW_SIGNED_INTEGER_P(a, b, LONG_MIN, LONG_MAX)
# define SUB_OVERFLOW_INT_P(a, b)       SUB_OVERFLOW_SIGNED_INTEGER_P(a, b, INT_MIN, INT_MAX)
#endif
#endif

#ifdef HAVE_UINT128_T
# define bit_length(x) \
    (unsigned int) \
    (sizeof(x) <= sizeof(int32_t) ? 32 - nlz_int32((uint32_t)(x)) : \
     sizeof(x) <= sizeof(int64_t) ? 64 - nlz_int64((uint64_t)(x)) : \
                                   128 - nlz_int128((uint128_t)(x)))
#else
# define bit_length(x) \
    (unsigned int) \
    (sizeof(x) <= sizeof(int32_t) ? 32 - nlz_int32((uint32_t)(x)) : \
                                    64 - nlz_int64((uint64_t)(x)))
#endif

#ifndef swap16
# define swap16 ruby_swap16
#endif

#ifndef swap32
# define swap32 ruby_swap32
#endif

#ifndef swap64
# define swap64 ruby_swap64
#endif

static inline uint16_t ruby_swap16(uint16_t);
static inline uint32_t ruby_swap32(uint32_t);
static inline uint64_t ruby_swap64(uint64_t);
static inline unsigned nlz_int(unsigned x);
static inline unsigned nlz_long(unsigned long x);
static inline unsigned nlz_long_long(unsigned long long x);
static inline unsigned nlz_intptr(uintptr_t x);
static inline unsigned nlz_int32(uint32_t x);
static inline unsigned nlz_int64(uint64_t x);
#ifdef HAVE_UINT128_T
static inline unsigned nlz_int128(uint128_t x);
#endif
static inline unsigned rb_popcount32(uint32_t x);
static inline unsigned rb_popcount64(uint64_t x);
static inline unsigned rb_popcount_intptr(uintptr_t x);
static inline int ntz_int32(uint32_t x);
static inline int ntz_int64(uint64_t x);
static inline int ntz_intptr(uintptr_t x);
static inline VALUE RUBY_BIT_ROTL(VALUE, int);
static inline VALUE RUBY_BIT_ROTR(VALUE, int);

static inline uint16_t
ruby_swap16(uint16_t x)
{
#if __has_builtin(__builtin_bswap16)
    return __builtin_bswap16(x);

#elif MSC_VERSION_SINCE(1310)
    return _byteswap_ushort(x);

#else
    return (x << 8) | (x >> 8);

#endif
}

static inline uint32_t
ruby_swap32(uint32_t x)
{
#if __has_builtin(__builtin_bswap32)
    return __builtin_bswap32(x);

#elif MSC_VERSION_SINCE(1310)
    return _byteswap_ulong(x);

#else
    x = ((x & 0x0000FFFF) << 16) | ((x & 0xFFFF0000) >> 16);
    x = ((x & 0x00FF00FF) <<  8) | ((x & 0xFF00FF00) >>  8);
    return x;

#endif
}

static inline uint64_t
ruby_swap64(uint64_t x)
{
#if __has_builtin(__builtin_bswap64)
    return __builtin_bswap64(x);

#elif MSC_VERSION_SINCE(1310)
    return _byteswap_uint64(x);

#else
    x = ((x & 0x00000000FFFFFFFFULL) << 32) | ((x & 0xFFFFFFFF00000000ULL) >> 32);
    x = ((x & 0x0000FFFF0000FFFFULL) << 16) | ((x & 0xFFFF0000FFFF0000ULL) >> 16);
    x = ((x & 0x00FF00FF00FF00FFULL) <<  8) | ((x & 0xFF00FF00FF00FF00ULL) >>  8);
    return x;

#endif
}

static inline unsigned int
nlz_int32(uint32_t x)
{
#if defined(_MSC_VER) && defined(__AVX2__)
    /* Note: It seems there is no such thing like __LZCNT__ predefined in MSVC.
     * AMD  CPUs have  had this  instruction for  decades (since  K10) but  for
     * Intel, Haswell is  the oldest one.  We need to  use __AVX2__ for maximum
     * safety. */
    return (unsigned int)__lzcnt(x);

#elif defined(__x86_64__) && defined(__LZCNT__)
    return (unsigned int)_lzcnt_u32(x);

#elif MSC_VERSION_SINCE(1400) /* &&! defined(__AVX2__) */
    unsigned long r;
    return _BitScanReverse(&r, x) ? (31 - (int)r) : 32;

#elif __has_builtin(__builtin_clz)
    STATIC_ASSERT(sizeof_int, sizeof(int) * CHAR_BIT == 32);
    return x ? (unsigned int)__builtin_clz(x) : 32;

#else
    uint32_t y;
    unsigned n = 32;
    y = x >> 16; if (y) {n -= 16; x = y;}
    y = x >>  8; if (y) {n -=  8; x = y;}
    y = x >>  4; if (y) {n -=  4; x = y;}
    y = x >>  2; if (y) {n -=  2; x = y;}
    y = x >>  1; if (y) {return n - 2;}
    return (unsigned int)(n - x);
#endif
}

static inline unsigned int
nlz_int64(uint64_t x)
{
#if defined(_MSC_VER) && defined(__AVX2__)
    return (unsigned int)__lzcnt64(x);

#elif defined(__x86_64__) && defined(__LZCNT__)
    return (unsigned int)_lzcnt_u64(x);

#elif defined(_WIN64) && MSC_VERSION_SINCE(1400) /* &&! defined(__AVX2__) */
    unsigned long r;
    return _BitScanReverse64(&r, x) ? (63u - (unsigned int)r) : 64;

#elif __has_builtin(__builtin_clzl)
    if (x == 0) {
        return 64;
    }
    else if (sizeof(long) * CHAR_BIT == 64) {
        return (unsigned int)__builtin_clzl((unsigned long)x);
    }
    else if (sizeof(long long) * CHAR_BIT == 64) {
        return (unsigned int)__builtin_clzll((unsigned long long)x);
    }
    else {
        /* :FIXME: Is there a way to make this branch a compile-time error? */
        UNREACHABLE_RETURN(~0);
    }

#else
    uint64_t y;
    unsigned int n = 64;
    y = x >> 32; if (y) {n -= 32; x = y;}
    y = x >> 16; if (y) {n -= 16; x = y;}
    y = x >>  8; if (y) {n -=  8; x = y;}
    y = x >>  4; if (y) {n -=  4; x = y;}
    y = x >>  2; if (y) {n -=  2; x = y;}
    y = x >>  1; if (y) {return n - 2;}
    return (unsigned int)(n - x);

#endif
}

#ifdef HAVE_UINT128_T
static inline unsigned int
nlz_int128(uint128_t x)
{
    uint64_t y = (uint64_t)(x >> 64);

    if (x == 0) {
        return 128;
    }
    else if (y == 0) {
        return (unsigned int)nlz_int64(x) + 64;
    }
    else {
        return (unsigned int)nlz_int64(y);
    }
}
#endif

static inline unsigned int
nlz_int(unsigned int x)
{
    if (sizeof(unsigned int) * CHAR_BIT == 32) {
        return nlz_int32((uint32_t)x);
    }
    else if (sizeof(unsigned int) * CHAR_BIT == 64) {
        return nlz_int64((uint64_t)x);
    }
    else {
        UNREACHABLE_RETURN(~0);
    }
}

static inline unsigned int
nlz_long(unsigned long x)
{
    if (sizeof(unsigned long) * CHAR_BIT == 32) {
        return nlz_int32((uint32_t)x);
    }
    else if (sizeof(unsigned long) * CHAR_BIT == 64) {
        return nlz_int64((uint64_t)x);
    }
    else {
        UNREACHABLE_RETURN(~0);
    }
}

static inline unsigned int
nlz_long_long(unsigned long long x)
{
    if (sizeof(unsigned long long) * CHAR_BIT == 64) {
        return nlz_int64((uint64_t)x);
    }
#ifdef HAVE_UINT128_T
    else if (sizeof(unsigned long long) * CHAR_BIT == 128) {
        return nlz_int128((uint128_t)x);
    }
#endif
    else {
        UNREACHABLE_RETURN(~0);
    }
}

static inline unsigned int
nlz_intptr(uintptr_t x)
{
    if (sizeof(uintptr_t) == sizeof(unsigned int)) {
        return nlz_int((unsigned int)x);
    }
    if (sizeof(uintptr_t) == sizeof(unsigned long)) {
        return nlz_long((unsigned long)x);
    }
    if (sizeof(uintptr_t) == sizeof(unsigned long long)) {
        return nlz_long_long((unsigned long long)x);
    }
    else {
        UNREACHABLE_RETURN(~0);
    }
}

static inline unsigned int
rb_popcount32(uint32_t x)
{
#if defined(_MSC_VER) && defined(__AVX__)
    /* Note: CPUs since Nehalem and Barcelona  have had this instruction so SSE
     * 4.2 should suffice, but it seems there is no such thing like __SSE_4_2__
     * predefined macro in MSVC.  They do have __AVX__ so use it instead. */
    return (unsigned int)__popcnt(x);

#elif __has_builtin(__builtin_popcount)
    STATIC_ASSERT(sizeof_int, sizeof(int) * CHAR_BIT >= 32);
    return (unsigned int)__builtin_popcount(x);

#else
    x = (x & 0x55555555) + (x >> 1 & 0x55555555);
    x = (x & 0x33333333) + (x >> 2 & 0x33333333);
    x = (x & 0x07070707) + (x >> 4 & 0x07070707);
    x = (x & 0x000f000f) + (x >> 8 & 0x000f000f);
    x = (x & 0x0000001f) + (x >>16 & 0x0000001f);
    return (unsigned int)x;

#endif
}

static inline unsigned int
rb_popcount64(uint64_t x)
{
#if defined(_MSC_VER) && defined(__AVX__)
    return (unsigned int)__popcnt64(x);

#elif __has_builtin(__builtin_popcount)
    if (sizeof(long) * CHAR_BIT == 64) {
        return (unsigned int)__builtin_popcountl((unsigned long)x);
    }
    else if (sizeof(long long) * CHAR_BIT == 64) {
        return (unsigned int)__builtin_popcountll((unsigned long long)x);
    }
    else {
        /* :FIXME: Is there a way to make this branch a compile-time error? */
        UNREACHABLE_RETURN(~0);
    }

#else
    x = (x & 0x5555555555555555) + (x >> 1 & 0x5555555555555555);
    x = (x & 0x3333333333333333) + (x >> 2 & 0x3333333333333333);
    x = (x & 0x0707070707070707) + (x >> 4 & 0x0707070707070707);
    x = (x & 0x000f000f000f000f) + (x >> 8 & 0x000f000f000f000f);
    x = (x & 0x0000001f0000001f) + (x >>16 & 0x0000001f0000001f);
    x = (x & 0x000000000000003f) + (x >>32 & 0x000000000000003f);
    return (unsigned int)x;

#endif
}

static inline unsigned int
rb_popcount_intptr(uintptr_t x)
{
    if (sizeof(uintptr_t) * CHAR_BIT == 64) {
        return rb_popcount64((uint64_t)x);
    }
    else if (sizeof(uintptr_t) * CHAR_BIT == 32) {
        return rb_popcount32((uint32_t)x);
    }
    else {
        UNREACHABLE_RETURN(~0);
    }
}

static inline int
ntz_int32(uint32_t x)
{
#if defined(__x86_64__) && defined(__BMI__)
    return (unsigned)_tzcnt_u32(x);

#elif MSC_VERSION_SINCE(1400)
    /* :FIXME: Is there any way to issue TZCNT instead of BSF, apart from using
     *         assembly?  Because issuing LZCNT seems possible (see nlz.h). */
    unsigned long r;
    return _BitScanForward(&r, x) ? (int)r : 32;

#elif __has_builtin(__builtin_ctz)
    STATIC_ASSERT(sizeof_int, sizeof(int) * CHAR_BIT == 32);
    return x ? (unsigned)__builtin_ctz(x) : 32;

#else
    return rb_popcount32((~x) & (x-1));

#endif
}

static inline int
ntz_int64(uint64_t x)
{
#if defined(__x86_64__) && defined(__BMI__)
    return (unsigned)_tzcnt_u64(x);

#elif defined(_WIN64) && MSC_VERSION_SINCE(1400)
    unsigned long r;
    return _BitScanForward64(&r, x) ? (int)r : 64;

#elif __has_builtin(__builtin_ctzl)
    if (x == 0) {
        return 64;
    }
    else if (sizeof(long) * CHAR_BIT == 64) {
        return (unsigned)__builtin_ctzl((unsigned long)x);
    }
    else if (sizeof(long long) * CHAR_BIT == 64) {
        return (unsigned)__builtin_ctzll((unsigned long long)x);
    }
    else {
        /* :FIXME: Is there a way to make this branch a compile-time error? */
        UNREACHABLE_RETURN(~0);
    }

#else
    return rb_popcount64((~x) & (x-1));

#endif
}

static inline int
ntz_intptr(uintptr_t x)
{
    if (sizeof(uintptr_t) * CHAR_BIT == 64) {
        return ntz_int64((uint64_t)x);
    }
    else if (sizeof(uintptr_t) * CHAR_BIT == 32) {
        return ntz_int32((uint32_t)x);
    }
    else {
        UNREACHABLE_RETURN(~0);
    }
}

static inline VALUE
RUBY_BIT_ROTL(VALUE v, int n)
{
#if __has_builtin(__builtin_rotateleft32) && (SIZEOF_VALUE * CHAR_BIT == 32)
    return __builtin_rotateleft32(v, n);

#elif __has_builtin(__builtin_rotateleft64) && (SIZEOF_VALUE * CHAR_BIT == 64)
    return __builtin_rotateleft64(v, n);

#elif MSC_VERSION_SINCE(1310) && (SIZEOF_VALUE * CHAR_BIT == 32)
    return _rotl(v, n);

#elif MSC_VERSION_SINCE(1310) && (SIZEOF_VALUE * CHAR_BIT == 64)
    return _rotl64(v, n);

#elif defined(_lrotl) && (SIZEOF_VALUE == SIZEOF_LONG)
    return _lrotl(v, n);

#else
    const int m = (sizeof(VALUE) * CHAR_BIT) - 1;
    return (v << (n & m)) | (v >> (-n & m));
#endif
}

static inline VALUE
RUBY_BIT_ROTR(VALUE v, int n)
{
#if __has_builtin(__builtin_rotateright32) && (SIZEOF_VALUE * CHAR_BIT == 32)
    return __builtin_rotateright32(v, n);

#elif __has_builtin(__builtin_rotateright64) && (SIZEOF_VALUE * CHAR_BIT == 64)
    return __builtin_rotateright64(v, n);

#elif MSC_VERSION_SINCE(1310) && (SIZEOF_VALUE * CHAR_BIT == 32)
    return _rotr(v, n);

#elif MSC_VERSION_SINCE(1310) && (SIZEOF_VALUE * CHAR_BIT == 64)
    return _rotr64(v, n);

#elif defined(_lrotr) && (SIZEOF_VALUE == SIZEOF_LONG)
    return _lrotr(v, n);

#else
    const int m = (sizeof(VALUE) * CHAR_BIT) - 1;
    return (v << (-n & m)) | (v >> (n & m));
#endif
}

#endif /* INTERNAL_BITS_H */
