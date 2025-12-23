typedef enum {
    SIMD_NONE,
    SIMD_NEON,
    SIMD_SSE2
} SIMD_Implementation;

#ifdef JSON_ENABLE_SIMD

#ifdef __clang__
# if __has_builtin(__builtin_ctzll)
#   define HAVE_BUILTIN_CTZLL 1
# else
#   define HAVE_BUILTIN_CTZLL 0
# endif
#elif defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
# define HAVE_BUILTIN_CTZLL 1
#else
# define HAVE_BUILTIN_CTZLL 0
#endif

static inline uint32_t trailing_zeros64(uint64_t input)
{
#if HAVE_BUILTIN_CTZLL
    return __builtin_ctzll(input);
#else
    uint32_t trailing_zeros = 0;
    uint64_t temp = input;
    while ((temp & 1) == 0 && temp > 0) {
        trailing_zeros++;
        temp >>= 1;
    }
    return trailing_zeros;
#endif
}

static inline int trailing_zeros(int input)
{
#if HAVE_BUILTIN_CTZLL
    return __builtin_ctz(input);
#else
    int trailing_zeros = 0;
    int temp = input;
    while ((temp & 1) == 0 && temp > 0) {
        trailing_zeros++;
        temp >>= 1;
    }
    return trailing_zeros;
#endif
}

#if (defined(__GNUC__ ) || defined(__clang__))
#define FORCE_INLINE __attribute__((always_inline))
#else
#define FORCE_INLINE
#endif


#define SIMD_MINIMUM_THRESHOLD 6

#if defined(__ARM_NEON) || defined(__ARM_NEON__) || defined(__aarch64__) || defined(_M_ARM64)
#include <arm_neon.h>

#define FIND_SIMD_IMPLEMENTATION_DEFINED 1
static inline SIMD_Implementation find_simd_implementation(void)
{
    return SIMD_NEON;
}

#define HAVE_SIMD 1
#define HAVE_SIMD_NEON 1

// See: https://community.arm.com/arm-community-blogs/b/servers-and-cloud-computing-blog/posts/porting-x86-vector-bitmask-optimizations-to-arm-neon
static inline FORCE_INLINE uint64_t neon_match_mask(uint8x16_t matches)
{
    const uint8x8_t res = vshrn_n_u16(vreinterpretq_u16_u8(matches), 4);
    const uint64_t mask = vget_lane_u64(vreinterpret_u64_u8(res), 0);
    return mask & 0x8888888888888888ull;
}

static inline FORCE_INLINE uint64_t compute_chunk_mask_neon(const char *ptr)
{
    uint8x16_t chunk = vld1q_u8((const unsigned char *)ptr);

    // Trick: c < 32 || c == 34 can be factored as c ^ 2 < 33
    // https://lemire.me/blog/2025/04/13/detect-control-characters-quotes-and-backslashes-efficiently-using-swar/
    const uint8x16_t too_low_or_dbl_quote = vcltq_u8(veorq_u8(chunk, vdupq_n_u8(2)), vdupq_n_u8(33));

    uint8x16_t has_backslash = vceqq_u8(chunk, vdupq_n_u8('\\'));
    uint8x16_t needs_escape  = vorrq_u8(too_low_or_dbl_quote, has_backslash);
    return neon_match_mask(needs_escape);
}

static inline FORCE_INLINE int string_scan_simd_neon(const char **ptr, const char *end, uint64_t *mask)
{
    while (*ptr + sizeof(uint8x16_t) <= end) {
        uint64_t chunk_mask = compute_chunk_mask_neon(*ptr);
        if (chunk_mask) {
            *mask = chunk_mask;
            return 1;
        }
        *ptr += sizeof(uint8x16_t);
    }
    return 0;
}

static inline uint8x16x4_t load_uint8x16_4(const unsigned char *table)
{
    uint8x16x4_t tab;
    tab.val[0] = vld1q_u8(table);
    tab.val[1] = vld1q_u8(table+16);
    tab.val[2] = vld1q_u8(table+32);
    tab.val[3] = vld1q_u8(table+48);
    return tab;
}

#endif /* ARM Neon Support.*/

#if defined(__amd64__) || defined(__amd64) || defined(__x86_64__) || defined(__x86_64) || defined(_M_X64) || defined(_M_AMD64)

#ifdef HAVE_X86INTRIN_H
#include <x86intrin.h>

#define HAVE_SIMD 1
#define HAVE_SIMD_SSE2 1

#ifdef HAVE_CPUID_H
#define FIND_SIMD_IMPLEMENTATION_DEFINED 1

#if defined(__clang__) || defined(__GNUC__)
#define TARGET_SSE2 __attribute__((target("sse2")))
#else
#define TARGET_SSE2
#endif

#define _mm_cmpge_epu8(a, b) _mm_cmpeq_epi8(_mm_max_epu8(a, b), a)
#define _mm_cmple_epu8(a, b) _mm_cmpge_epu8(b, a)
#define _mm_cmpgt_epu8(a, b) _mm_xor_si128(_mm_cmple_epu8(a, b), _mm_set1_epi8(-1))
#define _mm_cmplt_epu8(a, b) _mm_cmpgt_epu8(b, a)

static inline TARGET_SSE2 FORCE_INLINE int compute_chunk_mask_sse2(const char *ptr)
{
    __m128i chunk         = _mm_loadu_si128((__m128i const*)ptr);
    // Trick: c < 32 || c == 34 can be factored as c ^ 2 < 33
    // https://lemire.me/blog/2025/04/13/detect-control-characters-quotes-and-backslashes-efficiently-using-swar/
    __m128i too_low_or_dbl_quote = _mm_cmplt_epu8(_mm_xor_si128(chunk, _mm_set1_epi8(2)), _mm_set1_epi8(33));
    __m128i has_backslash = _mm_cmpeq_epi8(chunk, _mm_set1_epi8('\\'));
    __m128i needs_escape  = _mm_or_si128(too_low_or_dbl_quote, has_backslash);
    return _mm_movemask_epi8(needs_escape);
}

static inline TARGET_SSE2 FORCE_INLINE int string_scan_simd_sse2(const char **ptr, const char *end, int *mask)
{
    while (*ptr + sizeof(__m128i) <= end) {
        int chunk_mask = compute_chunk_mask_sse2(*ptr);
        if (chunk_mask) {
            *mask = chunk_mask;
            return 1;
        }
        *ptr += sizeof(__m128i);
    }

    return 0;
}

#include <cpuid.h>
#endif /* HAVE_CPUID_H */

static inline SIMD_Implementation find_simd_implementation(void)
{
    // TODO Revisit. I think the SSE version now only uses SSE2 instructions.
    if (__builtin_cpu_supports("sse2")) {
        return SIMD_SSE2;
    }

    return SIMD_NONE;
}

#endif /* HAVE_X86INTRIN_H */
#endif /* X86_64 Support */

#endif /* JSON_ENABLE_SIMD */

#ifndef FIND_SIMD_IMPLEMENTATION_DEFINED
static inline SIMD_Implementation find_simd_implementation(void)
{
    return SIMD_NONE;
}
#endif
