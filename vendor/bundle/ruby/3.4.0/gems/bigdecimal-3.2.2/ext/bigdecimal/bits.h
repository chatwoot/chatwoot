#ifndef BIGDECIMAL_BITS_H
#define BIGDECIMAL_BITS_H

#include "feature.h"
#include "static_assert.h"

#if defined(__x86_64__) && defined(HAVE_X86INTRIN_H)
# include <x86intrin.h>         /* for _lzcnt_u64, etc. */
#elif defined(_MSC_VER) && defined(HAVE_INTRIN_H)
# include <intrin.h>            /* for the following intrinsics */
#endif

#if defined(_MSC_VER) && defined(__AVX2__)
# pragma intrinsic(__lzcnt)
# pragma intrinsic(__lzcnt64)
#endif

#define numberof(array) ((int)(sizeof(array) / sizeof((array)[0])))
#define roomof(x, y) (((x) + (y) - 1) / (y))
#define type_roomof(x, y) roomof(sizeof(x), sizeof(y))

#define MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, min, max) ( \
    (a) == 0 ? 0 : \
    (a) == -1 ? (b) < -(max) : \
    (a) > 0 ? \
      ((b) > 0 ? (max) / (a) < (b) : (min) / (a) > (b)) : \
      ((b) > 0 ? (min) / (a) < (b) : (max) / (a) > (b)))

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

static inline unsigned nlz_int32(uint32_t x);
static inline unsigned nlz_int64(uint64_t x);
#ifdef HAVE_UINT128_T
static inline unsigned nlz_int128(uint128_t x);
#endif

static inline unsigned int
nlz_int32(uint32_t x)
{
#if defined(_MSC_VER) && defined(__AVX2__) && defined(HAVE___LZCNT)
    /* Note: It seems there is no such thing like __LZCNT__ predefined in MSVC.
     * AMD  CPUs have  had this  instruction for  decades (since  K10) but  for
     * Intel, Haswell is  the oldest one.  We need to  use __AVX2__ for maximum
     * safety. */
    return (unsigned int)__lzcnt(x);

#elif defined(__x86_64__) && defined(__LZCNT__) && defined(HAVE__LZCNT_U32)
    return (unsigned int)_lzcnt_u32(x);

#elif defined(_MSC_VER) && defined(HAVE__BITSCANREVERSE)
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
#if defined(_MSC_VER) && defined(__AVX2__) && defined(HAVE___LZCNT64)
    return (unsigned int)__lzcnt64(x);

#elif defined(__x86_64__) && defined(__LZCNT__) && defined(HAVE__LZCNT_U64)
    return (unsigned int)_lzcnt_u64(x);

#elif defined(_WIN64) && defined(_MSC_VER) && defined(HAVE__BITSCANREVERSE64)
    unsigned long r;
    return _BitScanReverse64(&r, x) ? (63u - (unsigned int)r) : 64;

#elif __has_builtin(__builtin_clzl) && __has_builtin(__builtin_clzll) && !(defined(__sun) && defined(__sparc))
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
        __builtin_unreachable();
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

#endif /* BIGDECIMAL_BITS_H */
