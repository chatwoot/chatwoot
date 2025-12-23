#include "ruby.h"
#include "../fbuffer/fbuffer.h"
#include "../vendor/fpconv.c"

#include <math.h>
#include <ctype.h>

#include "../simd/simd.h"

/* ruby api and some helpers */

typedef struct JSON_Generator_StateStruct {
    VALUE indent;
    VALUE space;
    VALUE space_before;
    VALUE object_nl;
    VALUE array_nl;
    VALUE as_json;

    long max_nesting;
    long depth;
    long buffer_initial_length;

    bool allow_nan;
    bool ascii_only;
    bool script_safe;
    bool strict;
} JSON_Generator_State;

#ifndef RB_UNLIKELY
#define RB_UNLIKELY(cond) (cond)
#endif

static VALUE mJSON, cState, cFragment, mString_Extend, eGeneratorError, eNestingError, Encoding_UTF_8;

static ID i_to_s, i_to_json, i_new, i_pack, i_unpack, i_create_id, i_extend, i_encode;
static VALUE sym_indent, sym_space, sym_space_before, sym_object_nl, sym_array_nl, sym_max_nesting, sym_allow_nan,
             sym_ascii_only, sym_depth, sym_buffer_initial_length, sym_script_safe, sym_escape_slash, sym_strict, sym_as_json;


#define GET_STATE_TO(self, state) \
    TypedData_Get_Struct(self, JSON_Generator_State, &JSON_Generator_State_type, state)

#define GET_STATE(self)                       \
    JSON_Generator_State *state;              \
    GET_STATE_TO(self, state)

struct generate_json_data;

typedef void (*generator_func)(FBuffer *buffer, struct generate_json_data *data, VALUE obj);

struct generate_json_data {
    FBuffer *buffer;
    VALUE vstate;
    JSON_Generator_State *state;
    VALUE obj;
    generator_func func;
};

static VALUE cState_from_state_s(VALUE self, VALUE opts);
static VALUE cState_partial_generate(VALUE self, VALUE obj, generator_func, VALUE io);
static void generate_json(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_object(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_array(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_string(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_null(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_false(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_true(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
#ifdef RUBY_INTEGER_UNIFICATION
static void generate_json_integer(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
#endif
static void generate_json_fixnum(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_bignum(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_float(FBuffer *buffer, struct generate_json_data *data, VALUE obj);
static void generate_json_fragment(FBuffer *buffer, struct generate_json_data *data, VALUE obj);

static int usascii_encindex, utf8_encindex, binary_encindex;

#ifdef RBIMPL_ATTR_NORETURN
RBIMPL_ATTR_NORETURN()
#endif
static void raise_generator_error_str(VALUE invalid_object, VALUE str)
{
    VALUE exc = rb_exc_new_str(eGeneratorError, str);
    rb_ivar_set(exc, rb_intern("@invalid_object"), invalid_object);
    rb_exc_raise(exc);
}

#ifdef RBIMPL_ATTR_NORETURN
RBIMPL_ATTR_NORETURN()
#endif
#ifdef RBIMPL_ATTR_FORMAT
RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 2, 3)
#endif
static void raise_generator_error(VALUE invalid_object, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    VALUE str = rb_vsprintf(fmt, args);
    va_end(args);
    raise_generator_error_str(invalid_object, str);
}

// 0 - single byte char that don't need to be escaped.
// (x | 8) - char that needs to be escaped.
static const unsigned char CHAR_LENGTH_MASK = 7;
static const unsigned char ESCAPE_MASK = 8;

typedef struct _search_state {
    const char *ptr;
    const char *end;
    const char *cursor;
    FBuffer *buffer;

#ifdef HAVE_SIMD
    const char *chunk_base;
    const char *chunk_end;
    bool has_matches;

#if defined(HAVE_SIMD_NEON)
    uint64_t matches_mask;
#elif defined(HAVE_SIMD_SSE2)
    int matches_mask;
#else
#error "Unknown SIMD Implementation."
#endif /* HAVE_SIMD_NEON */
#endif /* HAVE_SIMD */
} search_state;

#if (defined(__GNUC__ ) || defined(__clang__))
#define FORCE_INLINE __attribute__((always_inline))
#else
#define FORCE_INLINE
#endif

static inline FORCE_INLINE void search_flush(search_state *search)
{
    // Do not remove this conditional without profiling, specifically escape-heavy text.
    // escape_UTF8_char_basic will advance search->ptr and search->cursor (effectively a search_flush).
    // For back-to-back characters that need to be escaped, specifcally for the SIMD code paths, this method
    // will be called just before calling escape_UTF8_char_basic. There will be no characers to append for the
    // consecutive characters that need to be escaped. While the fbuffer_append is a no-op if
    // nothing needs to be flushed, we can save a few memory references with this conditional.
    if (search->ptr > search->cursor) {
        fbuffer_append(search->buffer, search->cursor, search->ptr - search->cursor);
        search->cursor = search->ptr;
    }
}

static const unsigned char escape_table_basic[256] = {
    // ASCII Control Characters
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    // ASCII Characters
     0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // '"'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, // '\\'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

static unsigned char (*search_escape_basic_impl)(search_state *);

static inline unsigned char search_escape_basic(search_state *search)
{
    while (search->ptr < search->end) {
        if (RB_UNLIKELY(escape_table_basic[(const unsigned char)*search->ptr])) {
            search_flush(search);
            return 1;
        } else {
            search->ptr++;
        }
    }
    search_flush(search);
    return 0;
}

static inline FORCE_INLINE void escape_UTF8_char_basic(search_state *search)
{
    const unsigned char ch = (unsigned char)*search->ptr;
    switch (ch) {
        case '"':  fbuffer_append(search->buffer, "\\\"", 2); break;
        case '\\': fbuffer_append(search->buffer, "\\\\", 2); break;
        case '/':  fbuffer_append(search->buffer, "\\/", 2);  break;
        case '\b': fbuffer_append(search->buffer, "\\b", 2);  break;
        case '\f': fbuffer_append(search->buffer, "\\f", 2);  break;
        case '\n': fbuffer_append(search->buffer, "\\n", 2);  break;
        case '\r': fbuffer_append(search->buffer, "\\r", 2);  break;
        case '\t': fbuffer_append(search->buffer, "\\t", 2);  break;
        default: {
            const char *hexdig = "0123456789abcdef";
            char scratch[6] = { '\\', 'u', '0', '0', 0, 0 };
            scratch[4] = hexdig[(ch >> 4) & 0xf];
            scratch[5] = hexdig[ch & 0xf];
            fbuffer_append(search->buffer, scratch, 6);
            break;
        }
    }
    search->ptr++;
    search->cursor = search->ptr;
}

/* Converts in_string to a JSON string (without the wrapping '"'
 * characters) in FBuffer out_buffer.
 *
 * Character are JSON-escaped according to:
 *
 * - Always: ASCII control characters (0x00-0x1F), dquote, and
 *   backslash.
 *
 * - If out_ascii_only: non-ASCII characters (>0x7F)
 *
 * - If script_safe: forwardslash (/), line separator (U+2028), and
 *   paragraph separator (U+2029)
 *
 * Everything else (should be UTF-8) is just passed through and
 * appended to the result.
 */
static inline void convert_UTF8_to_JSON(search_state *search)
{
    while (search_escape_basic_impl(search)) {
        escape_UTF8_char_basic(search);
    }
}

static inline void escape_UTF8_char(search_state *search, unsigned char ch_len)
{
    const unsigned char ch = (unsigned char)*search->ptr;
    switch (ch_len) {
        case 1: {
            switch (ch) {
                case '"':  fbuffer_append(search->buffer, "\\\"", 2); break;
                case '\\': fbuffer_append(search->buffer, "\\\\", 2); break;
                case '/':  fbuffer_append(search->buffer, "\\/", 2);  break;
                case '\b': fbuffer_append(search->buffer, "\\b", 2);  break;
                case '\f': fbuffer_append(search->buffer, "\\f", 2);  break;
                case '\n': fbuffer_append(search->buffer, "\\n", 2);  break;
                case '\r': fbuffer_append(search->buffer, "\\r", 2);  break;
                case '\t': fbuffer_append(search->buffer, "\\t", 2);  break;
                default: {
                    const char *hexdig = "0123456789abcdef";
                    char scratch[6] = { '\\', 'u', '0', '0', 0, 0 };
                    scratch[4] = hexdig[(ch >> 4) & 0xf];
                    scratch[5] = hexdig[ch & 0xf];
                    fbuffer_append(search->buffer, scratch, 6);
                    break;
                }
            }
            break;
        }
        case 3: {
            if (search->ptr[2] & 1) {
                fbuffer_append(search->buffer, "\\u2029", 6);
            } else {
                fbuffer_append(search->buffer, "\\u2028", 6);
            }
            break;
        }
    }
    search->cursor = (search->ptr += ch_len);
}

#ifdef HAVE_SIMD

static inline FORCE_INLINE char *copy_remaining_bytes(search_state *search, unsigned long vec_len, unsigned long len)
{
    // Flush the buffer so everything up until the last 'len' characters are unflushed.
    search_flush(search);

    FBuffer *buf = search->buffer;
    fbuffer_inc_capa(buf, vec_len);

    char *s = (buf->ptr + buf->len);

    // Pad the buffer with dummy characters that won't need escaping.
    // This seem wateful at first sight, but memset of vector length is very fast.
    memset(s, 'X', vec_len);

    // Optimistically copy the remaining 'len' characters to the output FBuffer. If there are no characters
    // to escape, then everything ends up in the correct spot. Otherwise it was convenient temporary storage.
    MEMCPY(s, search->ptr, char, len);

    return s;
}

#ifdef HAVE_SIMD_NEON

static inline FORCE_INLINE unsigned char neon_next_match(search_state *search)
{
    uint64_t mask = search->matches_mask;
    uint32_t index = trailing_zeros64(mask) >> 2;

    // It is assumed escape_UTF8_char_basic will only ever increase search->ptr by at most one character.
    // If we want to use a similar approach for full escaping we'll need to ensure:
    //     search->chunk_base + index >= search->ptr
    // However, since we know escape_UTF8_char_basic only increases search->ptr by one, if the next match
    // is one byte after the previous match then:
    //     search->chunk_base + index == search->ptr
    search->ptr = search->chunk_base + index;
    mask &= mask - 1;
    search->matches_mask = mask;
    search_flush(search);
    return 1;
}

static inline unsigned char search_escape_basic_neon(search_state *search)
{
    if (RB_UNLIKELY(search->has_matches)) {
        // There are more matches if search->matches_mask > 0.
        if (search->matches_mask > 0) {
            return neon_next_match(search);
        } else {
            // neon_next_match will only advance search->ptr up to the last matching character.
            // Skip over any characters in the last chunk that occur after the last match.
            search->has_matches = false;
            search->ptr = search->chunk_end;
        }
    }

    /*
    * The code below implements an SIMD-based algorithm to determine if N bytes at a time
    * need to be escaped.
    *
    * Assume the ptr = "Te\sting!" (the double quotes are included in the string)
    *
    * The explanation will be limited to the first 8 bytes of the string for simplicity. However
    * the vector insructions may work on larger vectors.
    *
    * First, we load three constants 'lower_bound', 'backslash' and 'dblquote" in vector registers.
    *
    * lower_bound: [20 20 20 20 20 20 20 20]
    * backslash:   [5C 5C 5C 5C 5C 5C 5C 5C]
    * dblquote:    [22 22 22 22 22 22 22 22]
    *
    * Next we load the first chunk of the ptr:
    * [22 54 65 5C 73 74 69 6E] ("  T  e  \  s  t  i  n)
    *
    * First we check if any byte in chunk is less than 32 (0x20). This returns the following vector
    * as no bytes are less than 32 (0x20):
    * [0 0 0 0 0 0 0 0]
    *
    * Next, we check if any byte in chunk is equal to a backslash:
    * [0 0 0 FF 0 0 0 0]
    *
    * Finally we check if any byte in chunk is equal to a double quote:
    * [FF 0 0 0 0 0 0 0]
    *
    * Now we have three vectors where each byte indicates if the corresponding byte in chunk
    * needs to be escaped. We combine these vectors with a series of logical OR instructions.
    * This is the needs_escape vector and it is equal to:
    * [FF 0 0 FF 0 0 0 0]
    *
    * Next we compute the bitwise AND between each byte and 0x1 and compute the horizontal sum of
    * the values in the vector. This computes how many bytes need to be escaped within this chunk.
    *
    * Finally we compute a mask that indicates which bytes need to be escaped. If the mask is 0 then,
    * no bytes need to be escaped and we can continue to the next chunk. If the mask is not 0 then we
    * have at least one byte that needs to be escaped.
    */

    if (string_scan_simd_neon(&search->ptr, search->end, &search->matches_mask)) {
        search->has_matches = true;
        search->chunk_base = search->ptr;
        search->chunk_end = search->ptr + sizeof(uint8x16_t);
        return neon_next_match(search);
    }

    // There are fewer than 16 bytes left.
    unsigned long remaining = (search->end - search->ptr);
    if (remaining >= SIMD_MINIMUM_THRESHOLD) {
        char *s = copy_remaining_bytes(search, sizeof(uint8x16_t), remaining);

        uint64_t mask = compute_chunk_mask_neon(s);

        if (!mask) {
            // Nothing to escape, ensure search_flush doesn't do anything by setting
            // search->cursor to search->ptr.
            fbuffer_consumed(search->buffer, remaining);
            search->ptr = search->end;
            search->cursor = search->end;
            return 0;
        }

        search->matches_mask = mask;
        search->has_matches = true;
        search->chunk_end = search->end;
        search->chunk_base = search->ptr;
        return neon_next_match(search);
    }

    if (search->ptr < search->end) {
        return search_escape_basic(search);
    }

    search_flush(search);
    return 0;
}
#endif /* HAVE_SIMD_NEON */

#ifdef HAVE_SIMD_SSE2

static inline FORCE_INLINE unsigned char sse2_next_match(search_state *search)
{
    int mask = search->matches_mask;
    int index = trailing_zeros(mask);

    // It is assumed escape_UTF8_char_basic will only ever increase search->ptr by at most one character.
    // If we want to use a similar approach for full escaping we'll need to ensure:
    //     search->chunk_base + index >= search->ptr
    // However, since we know escape_UTF8_char_basic only increases search->ptr by one, if the next match
    // is one byte after the previous match then:
    //     search->chunk_base + index == search->ptr
    search->ptr = search->chunk_base + index;
    mask &= mask - 1;
    search->matches_mask = mask;
    search_flush(search);
    return 1;
}

#if defined(__clang__) || defined(__GNUC__)
#define TARGET_SSE2 __attribute__((target("sse2")))
#else
#define TARGET_SSE2
#endif

static inline TARGET_SSE2 FORCE_INLINE unsigned char search_escape_basic_sse2(search_state *search)
{
    if (RB_UNLIKELY(search->has_matches)) {
        // There are more matches if search->matches_mask > 0.
        if (search->matches_mask > 0) {
            return sse2_next_match(search);
        } else {
            // sse2_next_match will only advance search->ptr up to the last matching character.
            // Skip over any characters in the last chunk that occur after the last match.
            search->has_matches = false;
            if (RB_UNLIKELY(search->chunk_base + sizeof(__m128i) >= search->end)) {
                search->ptr = search->end;
            } else {
                search->ptr = search->chunk_base + sizeof(__m128i);
            }
        }
    }

    if (string_scan_simd_sse2(&search->ptr, search->end, &search->matches_mask)) {
        search->has_matches = true;
        search->chunk_base = search->ptr;
        search->chunk_end = search->ptr + sizeof(__m128i);
        return sse2_next_match(search);
    }

    // There are fewer than 16 bytes left.
    unsigned long remaining = (search->end - search->ptr);
    if (remaining >= SIMD_MINIMUM_THRESHOLD) {
        char *s = copy_remaining_bytes(search, sizeof(__m128i), remaining);

        int needs_escape_mask = compute_chunk_mask_sse2(s);

        if (needs_escape_mask == 0) {
            // Nothing to escape, ensure search_flush doesn't do anything by setting
            // search->cursor to search->ptr.
            fbuffer_consumed(search->buffer, remaining);
            search->ptr = search->end;
            search->cursor = search->end;
            return 0;
        }

        search->has_matches = true;
        search->matches_mask = needs_escape_mask;
        search->chunk_base = search->ptr;
        return sse2_next_match(search);
    }

    if (search->ptr < search->end) {
        return search_escape_basic(search);
    }

    search_flush(search);
    return 0;
}

#endif /* HAVE_SIMD_SSE2 */

#endif /* HAVE_SIMD */

static const unsigned char script_safe_escape_table[256] = {
    // ASCII Control Characters
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    // ASCII Characters
     0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, // '"' and '/'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, // '\\'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    // Continuation byte
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    // First byte of a 2-byte code point
     2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
     2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    // First byte of a 3-byte code point
     3, 3,11, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 0xE2 is the start of \u2028 and \u2029
    //First byte of a 4+ byte code point
     4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 9, 9,
};

static inline unsigned char search_script_safe_escape(search_state *search)
{
    while (search->ptr < search->end) {
        unsigned char ch = (unsigned char)*search->ptr;
        unsigned char ch_len = script_safe_escape_table[ch];

        if (RB_UNLIKELY(ch_len)) {
            if (ch_len & ESCAPE_MASK) {
                if (RB_UNLIKELY(ch_len == 11)) {
                    const unsigned char *uptr = (const unsigned char *)search->ptr;
                    if (!(uptr[1] == 0x80 && (uptr[2] >> 1) == 0x54)) {
                        search->ptr += 3;
                        continue;
                    }
                }
                search_flush(search);
                return ch_len & CHAR_LENGTH_MASK;
            } else {
                search->ptr += ch_len;
            }
        } else {
            search->ptr++;
        }
    }
    search_flush(search);
    return 0;
}

static void convert_UTF8_to_script_safe_JSON(search_state *search)
{
    unsigned char ch_len;
    while ((ch_len = search_script_safe_escape(search))) {
        escape_UTF8_char(search, ch_len);
    }
}

static const unsigned char ascii_only_escape_table[256] = {
    // ASCII Control Characters
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    // ASCII Characters
     0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // '"'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, // '\\'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    // Continuation byte
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    // First byte of a  2-byte code point
     2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
     2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    // First byte of a 3-byte code point
     3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    //First byte of a 4+ byte code point
     4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 9, 9,
};

static inline unsigned char search_ascii_only_escape(search_state *search, const unsigned char escape_table[256])
{
    while (search->ptr < search->end) {
        unsigned char ch = (unsigned char)*search->ptr;
        unsigned char ch_len = escape_table[ch];

        if (RB_UNLIKELY(ch_len)) {
            search_flush(search);
            return ch_len & CHAR_LENGTH_MASK;
        } else {
            search->ptr++;
        }
    }
    search_flush(search);
    return 0;
}

static inline void full_escape_UTF8_char(search_state *search, unsigned char ch_len)
{
    const unsigned char ch = (unsigned char)*search->ptr;
    switch (ch_len) {
        case 1: {
            switch (ch) {
                case '"':  fbuffer_append(search->buffer, "\\\"", 2); break;
                case '\\': fbuffer_append(search->buffer, "\\\\", 2); break;
                case '/':  fbuffer_append(search->buffer, "\\/", 2);  break;
                case '\b': fbuffer_append(search->buffer, "\\b", 2);  break;
                case '\f': fbuffer_append(search->buffer, "\\f", 2);  break;
                case '\n': fbuffer_append(search->buffer, "\\n", 2);  break;
                case '\r': fbuffer_append(search->buffer, "\\r", 2);  break;
                case '\t': fbuffer_append(search->buffer, "\\t", 2);  break;
                default: {
                    const char *hexdig = "0123456789abcdef";
                    char scratch[6] = { '\\', 'u', '0', '0', 0, 0 };
                    scratch[4] = hexdig[(ch >> 4) & 0xf];
                    scratch[5] = hexdig[ch & 0xf];
                    fbuffer_append(search->buffer, scratch, 6);
                    break;
                }
            }
            break;
        }
        default: {
            const char *hexdig = "0123456789abcdef";
            char scratch[12] = { '\\', 'u', 0, 0, 0, 0, '\\', 'u' };

            uint32_t wchar = 0;

            switch (ch_len) {
                case 2:
                    wchar = ch & 0x1F;
                    break;
                case 3:
                    wchar = ch & 0x0F;
                    break;
                case 4:
                    wchar = ch & 0x07;
                    break;
            }

            for (short i = 1; i < ch_len; i++) {
                wchar = (wchar << 6) | (search->ptr[i] & 0x3F);
            }

            if (wchar <= 0xFFFF) {
                scratch[2] = hexdig[wchar >> 12];
                scratch[3] = hexdig[(wchar >> 8) & 0xf];
                scratch[4] = hexdig[(wchar >> 4) & 0xf];
                scratch[5] = hexdig[wchar & 0xf];
                fbuffer_append(search->buffer, scratch, 6);
            } else {
                uint16_t hi, lo;
                wchar -= 0x10000;
                hi = 0xD800 + (uint16_t)(wchar >> 10);
                lo = 0xDC00 + (uint16_t)(wchar & 0x3FF);

                scratch[2] = hexdig[hi >> 12];
                scratch[3] = hexdig[(hi >> 8) & 0xf];
                scratch[4] = hexdig[(hi >> 4) & 0xf];
                scratch[5] = hexdig[hi & 0xf];

                scratch[8] = hexdig[lo >> 12];
                scratch[9] = hexdig[(lo >> 8) & 0xf];
                scratch[10] = hexdig[(lo >> 4) & 0xf];
                scratch[11] = hexdig[lo & 0xf];

                fbuffer_append(search->buffer, scratch, 12);
            }

            break;
        }
    }
    search->cursor = (search->ptr += ch_len);
}

static void convert_UTF8_to_ASCII_only_JSON(search_state *search, const unsigned char escape_table[256])
{
    unsigned char ch_len;
    while ((ch_len = search_ascii_only_escape(search, escape_table))) {
        full_escape_UTF8_char(search, ch_len);
    }
}

/*
 * Document-module: JSON::Ext::Generator
 *
 * This is the JSON generator implemented as a C extension. It can be
 * configured to be used by setting
 *
 *  JSON.generator = JSON::Ext::Generator
 *
 * with the method generator= in JSON.
 *
 */

/* Explanation of the following: that's the only way to not pollute
 * standard library's docs with GeneratorMethods::<ClassName> which
 * are uninformative and take a large place in a list of classes
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::Array
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::Bignum
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::FalseClass
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::Fixnum
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::Float
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::Hash
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::Integer
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::NilClass
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::Object
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::String
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::String::Extend
 * :nodoc:
 */

/*
 * Document-module: JSON::Ext::Generator::GeneratorMethods::TrueClass
 * :nodoc:
 */

/*
 * call-seq: to_json(state = nil)
 *
 * Returns a JSON string containing a JSON object, that is generated from
 * this Hash instance.
 * _state_ is a JSON::State object, that can also be used to configure the
 * produced JSON string output further.
 */
static VALUE mHash_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    VALUE Vstate = cState_from_state_s(cState, argc == 1 ? argv[0] : Qnil);
    return cState_partial_generate(Vstate, self, generate_json_object, Qfalse);
}

/*
 * call-seq: to_json(state = nil)
 *
 * Returns a JSON string containing a JSON array, that is generated from
 * this Array instance.
 * _state_ is a JSON::State object, that can also be used to configure the
 * produced JSON string output further.
 */
static VALUE mArray_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    VALUE Vstate = cState_from_state_s(cState, argc == 1 ? argv[0] : Qnil);
    return cState_partial_generate(Vstate, self, generate_json_array, Qfalse);
}

#ifdef RUBY_INTEGER_UNIFICATION
/*
 * call-seq: to_json(*)
 *
 * Returns a JSON string representation for this Integer number.
 */
static VALUE mInteger_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    VALUE Vstate = cState_from_state_s(cState, argc == 1 ? argv[0] : Qnil);
    return cState_partial_generate(Vstate, self, generate_json_integer, Qfalse);
}

#else
/*
 * call-seq: to_json(*)
 *
 * Returns a JSON string representation for this Integer number.
 */
static VALUE mFixnum_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    VALUE Vstate = cState_from_state_s(cState, argc == 1 ? argv[0] : Qnil);
    return cState_partial_generate(Vstate, self, generate_json_fixnum, Qfalse);
}

/*
 * call-seq: to_json(*)
 *
 * Returns a JSON string representation for this Integer number.
 */
static VALUE mBignum_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    VALUE Vstate = cState_from_state_s(cState, argc == 1 ? argv[0] : Qnil);
    return cState_partial_generate(Vstate, self, generate_json_bignum, Qfalse);
}
#endif

/*
 * call-seq: to_json(*)
 *
 * Returns a JSON string representation for this Float number.
 */
static VALUE mFloat_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    VALUE Vstate = cState_from_state_s(cState, argc == 1 ? argv[0] : Qnil);
    return cState_partial_generate(Vstate, self, generate_json_float, Qfalse);
}

/*
 * call-seq: String.included(modul)
 *
 * Extends _modul_ with the String::Extend module.
 */
static VALUE mString_included_s(VALUE self, VALUE modul)
{
    VALUE result = rb_funcall(modul, i_extend, 1, mString_Extend);
    rb_call_super(1, &modul);
    return result;
}

/*
 * call-seq: to_json(*)
 *
 * This string should be encoded with UTF-8 A call to this method
 * returns a JSON string encoded with UTF16 big endian characters as
 * \u????.
 */
static VALUE mString_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    VALUE Vstate = cState_from_state_s(cState, argc == 1 ? argv[0] : Qnil);
    return cState_partial_generate(Vstate, self, generate_json_string, Qfalse);
}

/*
 * call-seq: to_json_raw_object()
 *
 * This method creates a raw object hash, that can be nested into
 * other data structures and will be generated as a raw string. This
 * method should be used, if you want to convert raw strings to JSON
 * instead of UTF-8 strings, e. g. binary data.
 */
static VALUE mString_to_json_raw_object(VALUE self)
{
    VALUE ary;
    VALUE result = rb_hash_new();
    rb_hash_aset(result, rb_funcall(mJSON, i_create_id, 0), rb_class_name(rb_obj_class(self)));
    ary = rb_funcall(self, i_unpack, 1, rb_str_new2("C*"));
    rb_hash_aset(result, rb_utf8_str_new_lit("raw"), ary);
    return result;
}

/*
 * call-seq: to_json_raw(*args)
 *
 * This method creates a JSON text from the result of a call to
 * to_json_raw_object of this String.
 */
static VALUE mString_to_json_raw(int argc, VALUE *argv, VALUE self)
{
    VALUE obj = mString_to_json_raw_object(self);
    Check_Type(obj, T_HASH);
    return mHash_to_json(argc, argv, obj);
}

/*
 * call-seq: json_create(o)
 *
 * Raw Strings are JSON Objects (the raw bytes are stored in an array for the
 * key "raw"). The Ruby String can be created by this module method.
 */
static VALUE mString_Extend_json_create(VALUE self, VALUE o)
{
    VALUE ary;
    Check_Type(o, T_HASH);
    ary = rb_hash_aref(o, rb_str_new2("raw"));
    return rb_funcall(ary, i_pack, 1, rb_str_new2("C*"));
}

/*
 * call-seq: to_json(*)
 *
 * Returns a JSON string for true: 'true'.
 */
static VALUE mTrueClass_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    return rb_utf8_str_new("true", 4);
}

/*
 * call-seq: to_json(*)
 *
 * Returns a JSON string for false: 'false'.
 */
static VALUE mFalseClass_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    return rb_utf8_str_new("false", 5);
}

/*
 * call-seq: to_json(*)
 *
 * Returns a JSON string for nil: 'null'.
 */
static VALUE mNilClass_to_json(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 0, 1);
    return rb_utf8_str_new("null", 4);
}

/*
 * call-seq: to_json(*)
 *
 * Converts this object to a string (calling #to_s), converts
 * it to a JSON string, and returns the result. This is a fallback, if no
 * special method #to_json was defined for some object.
 */
static VALUE mObject_to_json(int argc, VALUE *argv, VALUE self)
{
    VALUE state;
    VALUE string = rb_funcall(self, i_to_s, 0);
    rb_scan_args(argc, argv, "01", &state);
    Check_Type(string, T_STRING);
    state = cState_from_state_s(cState, state);
    return cState_partial_generate(state, string, generate_json_string, Qfalse);
}

static void State_mark(void *ptr)
{
    JSON_Generator_State *state = ptr;
    rb_gc_mark_movable(state->indent);
    rb_gc_mark_movable(state->space);
    rb_gc_mark_movable(state->space_before);
    rb_gc_mark_movable(state->object_nl);
    rb_gc_mark_movable(state->array_nl);
    rb_gc_mark_movable(state->as_json);
}

static void State_compact(void *ptr)
{
    JSON_Generator_State *state = ptr;
    state->indent = rb_gc_location(state->indent);
    state->space = rb_gc_location(state->space);
    state->space_before = rb_gc_location(state->space_before);
    state->object_nl = rb_gc_location(state->object_nl);
    state->array_nl = rb_gc_location(state->array_nl);
    state->as_json = rb_gc_location(state->as_json);
}

static void State_free(void *ptr)
{
    JSON_Generator_State *state = ptr;
    ruby_xfree(state);
}

static size_t State_memsize(const void *ptr)
{
    return sizeof(JSON_Generator_State);
}

#ifndef HAVE_RB_EXT_RACTOR_SAFE
#   undef RUBY_TYPED_FROZEN_SHAREABLE
#   define RUBY_TYPED_FROZEN_SHAREABLE 0
#endif

static const rb_data_type_t JSON_Generator_State_type = {
    "JSON/Generator/State",
    {
        .dmark = State_mark,
        .dfree = State_free,
        .dsize = State_memsize,
        .dcompact = State_compact,
    },
    0, 0,
    RUBY_TYPED_WB_PROTECTED | RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_FROZEN_SHAREABLE,
};

static void state_init(JSON_Generator_State *state)
{
    state->max_nesting = 100;
    state->buffer_initial_length = FBUFFER_INITIAL_LENGTH_DEFAULT;
}

static VALUE cState_s_allocate(VALUE klass)
{
    JSON_Generator_State *state;
    VALUE obj = TypedData_Make_Struct(klass, JSON_Generator_State, &JSON_Generator_State_type, state);
    state_init(state);
    return obj;
}

static void vstate_spill(struct generate_json_data *data)
{
    VALUE vstate = cState_s_allocate(cState);
    GET_STATE(vstate);
    MEMCPY(state, data->state, JSON_Generator_State, 1);
    data->state = state;
    data->vstate = vstate;
    RB_OBJ_WRITTEN(vstate, Qundef, state->indent);
    RB_OBJ_WRITTEN(vstate, Qundef, state->space);
    RB_OBJ_WRITTEN(vstate, Qundef, state->space_before);
    RB_OBJ_WRITTEN(vstate, Qundef, state->object_nl);
    RB_OBJ_WRITTEN(vstate, Qundef, state->array_nl);
    RB_OBJ_WRITTEN(vstate, Qundef, state->as_json);
}

static inline VALUE vstate_get(struct generate_json_data *data)
{
    if (RB_UNLIKELY(!data->vstate)) {
        vstate_spill(data);
    }
    return data->vstate;
}

struct hash_foreach_arg {
    struct generate_json_data *data;
    int iter;
};

static VALUE
convert_string_subclass(VALUE key)
{
    VALUE key_to_s = rb_funcall(key, i_to_s, 0);

    if (RB_UNLIKELY(!RB_TYPE_P(key_to_s, T_STRING))) {
        VALUE cname = rb_obj_class(key);
        rb_raise(rb_eTypeError,
                 "can't convert %"PRIsVALUE" to %s (%"PRIsVALUE"#%s gives %"PRIsVALUE")",
                 cname, "String", cname, "to_s", rb_obj_class(key_to_s));
    }

    return key_to_s;
}

static int
json_object_i(VALUE key, VALUE val, VALUE _arg)
{
    struct hash_foreach_arg *arg = (struct hash_foreach_arg *)_arg;
    struct generate_json_data *data = arg->data;

    FBuffer *buffer = data->buffer;
    JSON_Generator_State *state = data->state;

    long depth = state->depth;
    int j;

    if (arg->iter > 0) fbuffer_append_char(buffer, ',');
    if (RB_UNLIKELY(data->state->object_nl)) {
        fbuffer_append_str(buffer, data->state->object_nl);
    }
    if (RB_UNLIKELY(data->state->indent)) {
        for (j = 0; j < depth; j++) {
            fbuffer_append_str(buffer, data->state->indent);
        }
    }

    VALUE key_to_s;
    switch (rb_type(key)) {
        case T_STRING:
            if (RB_LIKELY(RBASIC_CLASS(key) == rb_cString)) {
                key_to_s = key;
            } else {
                key_to_s = convert_string_subclass(key);
            }
            break;
        case T_SYMBOL:
            key_to_s = rb_sym2str(key);
            break;
        default:
            key_to_s = rb_convert_type(key, T_STRING, "String", "to_s");
            break;
    }

    if (RB_LIKELY(RBASIC_CLASS(key_to_s) == rb_cString)) {
        generate_json_string(buffer, data, key_to_s);
    } else {
        generate_json(buffer, data, key_to_s);
    }
    if (RB_UNLIKELY(state->space_before)) fbuffer_append_str(buffer, data->state->space_before);
    fbuffer_append_char(buffer, ':');
    if (RB_UNLIKELY(state->space)) fbuffer_append_str(buffer, data->state->space);
    generate_json(buffer, data, val);

    arg->iter++;
    return ST_CONTINUE;
}

static inline long increase_depth(struct generate_json_data *data)
{
    JSON_Generator_State *state = data->state;
    long depth = ++state->depth;
    if (RB_UNLIKELY(depth > state->max_nesting && state->max_nesting)) {
        rb_raise(eNestingError, "nesting of %ld is too deep", --state->depth);
    }
    return depth;
}

static void generate_json_object(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    int j;
    long depth = increase_depth(data);

    if (RHASH_SIZE(obj) == 0) {
        fbuffer_append(buffer, "{}", 2);
        --data->state->depth;
        return;
    }

    fbuffer_append_char(buffer, '{');

    struct hash_foreach_arg arg = {
        .data = data,
        .iter = 0,
    };
    rb_hash_foreach(obj, json_object_i, (VALUE)&arg);

    depth = --data->state->depth;
    if (RB_UNLIKELY(data->state->object_nl)) {
        fbuffer_append_str(buffer, data->state->object_nl);
        if (RB_UNLIKELY(data->state->indent)) {
            for (j = 0; j < depth; j++) {
                fbuffer_append_str(buffer, data->state->indent);
            }
        }
    }
    fbuffer_append_char(buffer, '}');
}

static void generate_json_array(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    int i, j;
    long depth = increase_depth(data);

    if (RARRAY_LEN(obj) == 0) {
        fbuffer_append(buffer, "[]", 2);
        --data->state->depth;
        return;
    }

    fbuffer_append_char(buffer, '[');
    if (RB_UNLIKELY(data->state->array_nl)) fbuffer_append_str(buffer, data->state->array_nl);
    for (i = 0; i < RARRAY_LEN(obj); i++) {
        if (i > 0) {
            fbuffer_append_char(buffer, ',');
            if (RB_UNLIKELY(data->state->array_nl)) fbuffer_append_str(buffer, data->state->array_nl);
        }
        if (RB_UNLIKELY(data->state->indent)) {
            for (j = 0; j < depth; j++) {
                fbuffer_append_str(buffer, data->state->indent);
            }
        }
        generate_json(buffer, data, RARRAY_AREF(obj, i));
    }
    data->state->depth = --depth;
    if (RB_UNLIKELY(data->state->array_nl)) {
        fbuffer_append_str(buffer, data->state->array_nl);
        if (RB_UNLIKELY(data->state->indent)) {
            for (j = 0; j < depth; j++) {
                fbuffer_append_str(buffer, data->state->indent);
            }
        }
    }
    fbuffer_append_char(buffer, ']');
}

static inline int enc_utf8_compatible_p(int enc_idx)
{
    if (enc_idx == usascii_encindex) return 1;
    if (enc_idx == utf8_encindex) return 1;
    return 0;
}

static VALUE encode_json_string_try(VALUE str)
{
    return rb_funcall(str, i_encode, 1, Encoding_UTF_8);
}

static VALUE encode_json_string_rescue(VALUE str, VALUE exception)
{
    raise_generator_error_str(str, rb_funcall(exception, rb_intern("message"), 0));
    return Qundef;
}

static inline VALUE ensure_valid_encoding(VALUE str)
{
    int encindex = RB_ENCODING_GET(str);
    VALUE utf8_string;
    if (RB_UNLIKELY(!enc_utf8_compatible_p(encindex))) {
        if (encindex == binary_encindex) {
            utf8_string = rb_enc_associate_index(rb_str_dup(str), utf8_encindex);
            switch (rb_enc_str_coderange(utf8_string)) {
                case ENC_CODERANGE_7BIT:
                    return utf8_string;
                case ENC_CODERANGE_VALID:
                    // For historical reason, we silently reinterpret binary strings as UTF-8 if it would work.
                    // TODO: Raise in 3.0.0
                    rb_warn("JSON.generate: UTF-8 string passed as BINARY, this will raise an encoding error in json 3.0");
                    return utf8_string;
                    break;
            }
        }

        str = rb_rescue(encode_json_string_try, str, encode_json_string_rescue, str);
    }
    return str;
}

static void generate_json_string(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    obj = ensure_valid_encoding(obj);

    fbuffer_append_char(buffer, '"');

    long len;
    search_state search;
    search.buffer = buffer;
    RSTRING_GETMEM(obj, search.ptr, len);
    search.cursor = search.ptr;
    search.end = search.ptr + len;

#ifdef HAVE_SIMD
    search.matches_mask = 0;
    search.has_matches = false;
    search.chunk_base = NULL;
#endif /* HAVE_SIMD */

    switch (rb_enc_str_coderange(obj)) {
        case ENC_CODERANGE_7BIT:
        case ENC_CODERANGE_VALID:
            if (RB_UNLIKELY(data->state->ascii_only)) {
                convert_UTF8_to_ASCII_only_JSON(&search, data->state->script_safe ? script_safe_escape_table : ascii_only_escape_table);
            } else if (RB_UNLIKELY(data->state->script_safe)) {
                convert_UTF8_to_script_safe_JSON(&search);
            } else {
                convert_UTF8_to_JSON(&search);
            }
            break;
        default:
            raise_generator_error(obj, "source sequence is illegal/malformed utf-8");
            break;
    }
    fbuffer_append_char(buffer, '"');
}

static void generate_json_fallback(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    VALUE tmp;
    if (rb_respond_to(obj, i_to_json)) {
        tmp = rb_funcall(obj, i_to_json, 1, vstate_get(data));
        Check_Type(tmp, T_STRING);
        fbuffer_append_str(buffer, tmp);
    } else {
        tmp = rb_funcall(obj, i_to_s, 0);
        Check_Type(tmp, T_STRING);
        generate_json_string(buffer, data, tmp);
    }
}

static inline void generate_json_symbol(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    if (data->state->strict) {
        generate_json_string(buffer, data, rb_sym2str(obj));
    } else {
        generate_json_fallback(buffer, data, obj);
    }
}

static void generate_json_null(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    fbuffer_append(buffer, "null", 4);
}

static void generate_json_false(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    fbuffer_append(buffer, "false", 5);
}

static void generate_json_true(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    fbuffer_append(buffer, "true", 4);
}

static void generate_json_fixnum(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    fbuffer_append_long(buffer, FIX2LONG(obj));
}

static void generate_json_bignum(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    VALUE tmp = rb_funcall(obj, i_to_s, 0);
    fbuffer_append_str(buffer, tmp);
}

#ifdef RUBY_INTEGER_UNIFICATION
static void generate_json_integer(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    if (FIXNUM_P(obj))
        generate_json_fixnum(buffer, data, obj);
    else
        generate_json_bignum(buffer, data, obj);
}
#endif

static void generate_json_float(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    double value = RFLOAT_VALUE(obj);
    char allow_nan = data->state->allow_nan;
    if (isinf(value) || isnan(value)) {
        /* for NaN and Infinity values we either raise an error or rely on Float#to_s. */
        if (!allow_nan) {
            if (data->state->strict && data->state->as_json) {
                VALUE casted_obj = rb_proc_call_with_block(data->state->as_json, 1, &obj, Qnil);
                if (casted_obj != obj) {
                    increase_depth(data);
                    generate_json(buffer, data, casted_obj);
                    data->state->depth--;
                    return;
                }
            }
            raise_generator_error(obj, "%"PRIsVALUE" not allowed in JSON", rb_funcall(obj, i_to_s, 0));
        }

        VALUE tmp = rb_funcall(obj, i_to_s, 0);
        fbuffer_append_str(buffer, tmp);
        return;
    }

    /* This implementation writes directly into the buffer. We reserve
     * the 28 characters that fpconv_dtoa states as its maximum.
     */
    fbuffer_inc_capa(buffer, 28);
    char* d = buffer->ptr + buffer->len;
    int len = fpconv_dtoa(value, d);

    /* fpconv_dtoa converts a float to its shortest string representation,
     * but it adds a ".0" if this is a plain integer.
     */
    fbuffer_consumed(buffer, len);
}

static void generate_json_fragment(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    VALUE fragment = RSTRUCT_GET(obj, 0);
    Check_Type(fragment, T_STRING);
    fbuffer_append_str(buffer, fragment);
}

static void generate_json(FBuffer *buffer, struct generate_json_data *data, VALUE obj)
{
    bool as_json_called = false;
start:
    if (obj == Qnil) {
        generate_json_null(buffer, data, obj);
    } else if (obj == Qfalse) {
        generate_json_false(buffer, data, obj);
    } else if (obj == Qtrue) {
        generate_json_true(buffer, data, obj);
    } else if (RB_SPECIAL_CONST_P(obj)) {
        if (RB_FIXNUM_P(obj)) {
            generate_json_fixnum(buffer, data, obj);
        } else if (RB_FLONUM_P(obj)) {
            generate_json_float(buffer, data, obj);
        } else if (RB_STATIC_SYM_P(obj)) {
            generate_json_symbol(buffer, data, obj);
        } else {
            goto general;
        }
    } else {
        VALUE klass = RBASIC_CLASS(obj);
        switch (RB_BUILTIN_TYPE(obj)) {
            case T_BIGNUM:
                generate_json_bignum(buffer, data, obj);
                break;
            case T_HASH:
                if (klass != rb_cHash) goto general;
                generate_json_object(buffer, data, obj);
                break;
            case T_ARRAY:
                if (klass != rb_cArray) goto general;
                generate_json_array(buffer, data, obj);
                break;
            case T_STRING:
                if (klass != rb_cString) goto general;
                generate_json_string(buffer, data, obj);
                break;
            case T_SYMBOL:
                generate_json_symbol(buffer, data, obj);
                break;
            case T_FLOAT:
                if (klass != rb_cFloat) goto general;
                generate_json_float(buffer, data, obj);
                break;
            case T_STRUCT:
                if (klass != cFragment) goto general;
                generate_json_fragment(buffer, data, obj);
                break;
            default:
            general:
                if (data->state->strict) {
                    if (RTEST(data->state->as_json) && !as_json_called) {
                        obj = rb_proc_call_with_block(data->state->as_json, 1, &obj, Qnil);
                        as_json_called = true;
                        goto start;
                    } else {
                        raise_generator_error(obj, "%"PRIsVALUE" not allowed in JSON", CLASS_OF(obj));
                    }
                } else {
                    generate_json_fallback(buffer, data, obj);
                }
        }
    }
}

static VALUE generate_json_try(VALUE d)
{
    struct generate_json_data *data = (struct generate_json_data *)d;

    data->func(data->buffer, data, data->obj);

    return Qnil;
}

static VALUE generate_json_rescue(VALUE d, VALUE exc)
{
    struct generate_json_data *data = (struct generate_json_data *)d;
    fbuffer_free(data->buffer);

    rb_exc_raise(exc);

    return Qundef;
}

static VALUE cState_partial_generate(VALUE self, VALUE obj, generator_func func, VALUE io)
{
    GET_STATE(self);

    char stack_buffer[FBUFFER_STACK_SIZE];
    FBuffer buffer = {
        .io = RTEST(io) ? io : Qfalse,
    };
    fbuffer_stack_init(&buffer, state->buffer_initial_length, stack_buffer, FBUFFER_STACK_SIZE);

    struct generate_json_data data = {
        .buffer = &buffer,
        .vstate = self,
        .state = state,
        .obj = obj,
        .func = func
    };
    rb_rescue(generate_json_try, (VALUE)&data, generate_json_rescue, (VALUE)&data);

    return fbuffer_finalize(&buffer);
}

/* call-seq:
 *   generate(obj) -> String
 *   generate(obj, anIO) -> anIO
 *
 * Generates a valid JSON document from object +obj+ and returns the
 * result. If no valid JSON document can be created this method raises a
 * GeneratorError exception.
 */
static VALUE cState_generate(int argc, VALUE *argv, VALUE self)
{
    rb_check_arity(argc, 1, 2);
    VALUE obj = argv[0];
    VALUE io = argc > 1 ? argv[1] : Qnil;
    VALUE result = cState_partial_generate(self, obj, generate_json, io);
    GET_STATE(self);
    (void)state;
    return result;
}

static VALUE cState_initialize(int argc, VALUE *argv, VALUE self)
{
    rb_warn("The json gem extension was loaded with the stdlib ruby code. You should upgrade rubygems with `gem update --system`");
    return self;
}

/*
 * call-seq: initialize_copy(orig)
 *
 * Initializes this object from orig if it can be duplicated/cloned and returns
 * it.
*/
static VALUE cState_init_copy(VALUE obj, VALUE orig)
{
    JSON_Generator_State *objState, *origState;

    if (obj == orig) return obj;
    GET_STATE_TO(obj, objState);
    GET_STATE_TO(orig, origState);
    if (!objState) rb_raise(rb_eArgError, "unallocated JSON::State");

    MEMCPY(objState, origState, JSON_Generator_State, 1);
    objState->indent = origState->indent;
    objState->space = origState->space;
    objState->space_before = origState->space_before;
    objState->object_nl = origState->object_nl;
    objState->array_nl = origState->array_nl;
    objState->as_json = origState->as_json;
    return obj;
}

/*
 * call-seq: from_state(opts)
 *
 * Creates a State object from _opts_, which ought to be Hash to create a
 * new State instance configured by _opts_, something else to create an
 * unconfigured instance. If _opts_ is a State object, it is just returned.
 */
static VALUE cState_from_state_s(VALUE self, VALUE opts)
{
    if (rb_obj_is_kind_of(opts, self)) {
        return opts;
    } else if (rb_obj_is_kind_of(opts, rb_cHash)) {
        return rb_funcall(self, i_new, 1, opts);
    } else {
        return rb_class_new_instance(0, NULL, cState);
    }
}

/*
 * call-seq: indent()
 *
 * Returns the string that is used to indent levels in the JSON text.
 */
static VALUE cState_indent(VALUE self)
{
    GET_STATE(self);
    return state->indent ? state->indent : rb_str_freeze(rb_utf8_str_new("", 0));
}

static VALUE string_config(VALUE config)
{
    if (RTEST(config)) {
        Check_Type(config, T_STRING);
        if (RSTRING_LEN(config)) {
            return rb_str_new_frozen(config);
        }
    }
    return Qfalse;
}

/*
 * call-seq: indent=(indent)
 *
 * Sets the string that is used to indent levels in the JSON text.
 */
static VALUE cState_indent_set(VALUE self, VALUE indent)
{
    GET_STATE(self);
    RB_OBJ_WRITE(self, &state->indent, string_config(indent));
    return Qnil;
}

/*
 * call-seq: space()
 *
 * Returns the string that is used to insert a space between the tokens in a JSON
 * string.
 */
static VALUE cState_space(VALUE self)
{
    GET_STATE(self);
    return state->space ? state->space : rb_str_freeze(rb_utf8_str_new("", 0));
}

/*
 * call-seq: space=(space)
 *
 * Sets _space_ to the string that is used to insert a space between the tokens in a JSON
 * string.
 */
static VALUE cState_space_set(VALUE self, VALUE space)
{
    GET_STATE(self);
    RB_OBJ_WRITE(self, &state->space, string_config(space));
    return Qnil;
}

/*
 * call-seq: space_before()
 *
 * Returns the string that is used to insert a space before the ':' in JSON objects.
 */
static VALUE cState_space_before(VALUE self)
{
    GET_STATE(self);
    return state->space_before ? state->space_before : rb_str_freeze(rb_utf8_str_new("", 0));
}

/*
 * call-seq: space_before=(space_before)
 *
 * Sets the string that is used to insert a space before the ':' in JSON objects.
 */
static VALUE cState_space_before_set(VALUE self, VALUE space_before)
{
    GET_STATE(self);
    RB_OBJ_WRITE(self, &state->space_before, string_config(space_before));
    return Qnil;
}

/*
 * call-seq: object_nl()
 *
 * This string is put at the end of a line that holds a JSON object (or
 * Hash).
 */
static VALUE cState_object_nl(VALUE self)
{
    GET_STATE(self);
    return state->object_nl ? state->object_nl : rb_str_freeze(rb_utf8_str_new("", 0));
}

/*
 * call-seq: object_nl=(object_nl)
 *
 * This string is put at the end of a line that holds a JSON object (or
 * Hash).
 */
static VALUE cState_object_nl_set(VALUE self, VALUE object_nl)
{
    GET_STATE(self);
    RB_OBJ_WRITE(self, &state->object_nl, string_config(object_nl));
    return Qnil;
}

/*
 * call-seq: array_nl()
 *
 * This string is put at the end of a line that holds a JSON array.
 */
static VALUE cState_array_nl(VALUE self)
{
    GET_STATE(self);
    return state->array_nl ? state->array_nl : rb_str_freeze(rb_utf8_str_new("", 0));
}

/*
 * call-seq: array_nl=(array_nl)
 *
 * This string is put at the end of a line that holds a JSON array.
 */
static VALUE cState_array_nl_set(VALUE self, VALUE array_nl)
{
    GET_STATE(self);
    RB_OBJ_WRITE(self, &state->array_nl, string_config(array_nl));
    return Qnil;
}

/*
 * call-seq: as_json()
 *
 * This string is put at the end of a line that holds a JSON array.
 */
static VALUE cState_as_json(VALUE self)
{
    GET_STATE(self);
    return state->as_json;
}

/*
 * call-seq: as_json=(as_json)
 *
 * This string is put at the end of a line that holds a JSON array.
 */
static VALUE cState_as_json_set(VALUE self, VALUE as_json)
{
    GET_STATE(self);
    RB_OBJ_WRITE(self, &state->as_json, rb_convert_type(as_json, T_DATA, "Proc", "to_proc"));
    return Qnil;
}

/*
* call-seq: check_circular?
*
* Returns true, if circular data structures should be checked,
* otherwise returns false.
*/
static VALUE cState_check_circular_p(VALUE self)
{
    GET_STATE(self);
    return state->max_nesting ? Qtrue : Qfalse;
}

/*
 * call-seq: max_nesting
 *
 * This integer returns the maximum level of data structure nesting in
 * the generated JSON, max_nesting = 0 if no maximum is checked.
 */
static VALUE cState_max_nesting(VALUE self)
{
    GET_STATE(self);
    return LONG2FIX(state->max_nesting);
}

static long long_config(VALUE num)
{
    return RTEST(num) ? FIX2LONG(num) : 0;
}

/*
 * call-seq: max_nesting=(depth)
 *
 * This sets the maximum level of data structure nesting in the generated JSON
 * to the integer depth, max_nesting = 0 if no maximum should be checked.
 */
static VALUE cState_max_nesting_set(VALUE self, VALUE depth)
{
    GET_STATE(self);
    state->max_nesting = long_config(depth);
    return Qnil;
}

/*
 * call-seq: script_safe
 *
 * If this boolean is true, the forward slashes will be escaped in
 * the json output.
 */
static VALUE cState_script_safe(VALUE self)
{
    GET_STATE(self);
    return state->script_safe ? Qtrue : Qfalse;
}

/*
 * call-seq: script_safe=(enable)
 *
 * This sets whether or not the forward slashes will be escaped in
 * the json output.
 */
static VALUE cState_script_safe_set(VALUE self, VALUE enable)
{
    GET_STATE(self);
    state->script_safe = RTEST(enable);
    return Qnil;
}

/*
 * call-seq: strict
 *
 * If this boolean is false, types unsupported by the JSON format will
 * be serialized as strings.
 * If this boolean is true, types unsupported by the JSON format will
 * raise a JSON::GeneratorError.
 */
static VALUE cState_strict(VALUE self)
{
    GET_STATE(self);
    return state->strict ? Qtrue : Qfalse;
}

/*
 * call-seq: strict=(enable)
 *
 * This sets whether or not to serialize types unsupported by the
 * JSON format as strings.
 * If this boolean is false, types unsupported by the JSON format will
 * be serialized as strings.
 * If this boolean is true, types unsupported by the JSON format will
 * raise a JSON::GeneratorError.
 */
static VALUE cState_strict_set(VALUE self, VALUE enable)
{
    GET_STATE(self);
    state->strict = RTEST(enable);
    return Qnil;
}

/*
 * call-seq: allow_nan?
 *
 * Returns true, if NaN, Infinity, and -Infinity should be generated, otherwise
 * returns false.
 */
static VALUE cState_allow_nan_p(VALUE self)
{
    GET_STATE(self);
    return state->allow_nan ? Qtrue : Qfalse;
}

/*
 * call-seq: allow_nan=(enable)
 *
 * This sets whether or not to serialize NaN, Infinity, and -Infinity
 */
static VALUE cState_allow_nan_set(VALUE self, VALUE enable)
{
    GET_STATE(self);
    state->allow_nan = RTEST(enable);
    return Qnil;
}

/*
 * call-seq: ascii_only?
 *
 * Returns true, if only ASCII characters should be generated. Otherwise
 * returns false.
 */
static VALUE cState_ascii_only_p(VALUE self)
{
    GET_STATE(self);
    return state->ascii_only ? Qtrue : Qfalse;
}

/*
 * call-seq: ascii_only=(enable)
 *
 * This sets whether only ASCII characters should be generated.
 */
static VALUE cState_ascii_only_set(VALUE self, VALUE enable)
{
    GET_STATE(self);
    state->ascii_only = RTEST(enable);
    return Qnil;
}

/*
 * call-seq: depth
 *
 * This integer returns the current depth of data structure nesting.
 */
static VALUE cState_depth(VALUE self)
{
    GET_STATE(self);
    return LONG2FIX(state->depth);
}

/*
 * call-seq: depth=(depth)
 *
 * This sets the maximum level of data structure nesting in the generated JSON
 * to the integer depth, max_nesting = 0 if no maximum should be checked.
 */
static VALUE cState_depth_set(VALUE self, VALUE depth)
{
    GET_STATE(self);
    state->depth = long_config(depth);
    return Qnil;
}

/*
 * call-seq: buffer_initial_length
 *
 * This integer returns the current initial length of the buffer.
 */
static VALUE cState_buffer_initial_length(VALUE self)
{
    GET_STATE(self);
    return LONG2FIX(state->buffer_initial_length);
}

static void buffer_initial_length_set(JSON_Generator_State *state, VALUE buffer_initial_length)
{
    Check_Type(buffer_initial_length, T_FIXNUM);
    long initial_length = FIX2LONG(buffer_initial_length);
    if (initial_length > 0) {
        state->buffer_initial_length = initial_length;
    }
}

/*
 * call-seq: buffer_initial_length=(length)
 *
 * This sets the initial length of the buffer to +length+, if +length+ > 0,
 * otherwise its value isn't changed.
 */
static VALUE cState_buffer_initial_length_set(VALUE self, VALUE buffer_initial_length)
{
    GET_STATE(self);
    buffer_initial_length_set(state, buffer_initial_length);
    return Qnil;
}

struct configure_state_data {
    JSON_Generator_State *state;
    VALUE vstate;  // Ruby object that owns the state, or Qfalse if stack-allocated
};

static inline void state_write_value(struct configure_state_data *data, VALUE *field, VALUE value)
{
    if (RTEST(data->vstate)) {
        RB_OBJ_WRITE(data->vstate, field, value);
    } else {
        *field = value;
    }
}

static int configure_state_i(VALUE key, VALUE val, VALUE _arg)
{
    struct configure_state_data *data = (struct configure_state_data *)_arg;
    JSON_Generator_State *state = data->state;

         if (key == sym_indent)                { state_write_value(data, &state->indent, string_config(val)); }
    else if (key == sym_space)                 { state_write_value(data, &state->space, string_config(val)); }
    else if (key == sym_space_before)          { state_write_value(data, &state->space_before, string_config(val)); }
    else if (key == sym_object_nl)             { state_write_value(data, &state->object_nl, string_config(val)); }
    else if (key == sym_array_nl)              { state_write_value(data, &state->array_nl, string_config(val)); }
    else if (key == sym_max_nesting)           { state->max_nesting = long_config(val); }
    else if (key == sym_allow_nan)             { state->allow_nan = RTEST(val); }
    else if (key == sym_ascii_only)            { state->ascii_only = RTEST(val); }
    else if (key == sym_depth)                 { state->depth = long_config(val); }
    else if (key == sym_buffer_initial_length) { buffer_initial_length_set(state, val); }
    else if (key == sym_script_safe)           { state->script_safe = RTEST(val); }
    else if (key == sym_escape_slash)          { state->script_safe = RTEST(val); }
    else if (key == sym_strict)                { state->strict = RTEST(val); }
    else if (key == sym_as_json)               {
        VALUE proc = RTEST(val) ? rb_convert_type(val, T_DATA, "Proc", "to_proc") : Qfalse;
        state_write_value(data, &state->as_json, proc);
    }
    return ST_CONTINUE;
}

static void configure_state(JSON_Generator_State *state, VALUE vstate, VALUE config)
{
    if (!RTEST(config)) return;

    Check_Type(config, T_HASH);

    if (!RHASH_SIZE(config)) return;

    struct configure_state_data data = {
        .state = state,
        .vstate = vstate
    };

    // We assume in most cases few keys are set so it's faster to go over
    // the provided keys than to check all possible keys.
    rb_hash_foreach(config, configure_state_i, (VALUE)&data);
}

static VALUE cState_configure(VALUE self, VALUE opts)
{
    GET_STATE(self);
    configure_state(state, self, opts);
    return self;
}

static VALUE cState_m_generate(VALUE klass, VALUE obj, VALUE opts, VALUE io)
{
    JSON_Generator_State state = {0};
    state_init(&state);
    configure_state(&state, Qfalse, opts);

    char stack_buffer[FBUFFER_STACK_SIZE];
    FBuffer buffer = {
        .io = RTEST(io) ? io : Qfalse,
    };
    fbuffer_stack_init(&buffer, state.buffer_initial_length, stack_buffer, FBUFFER_STACK_SIZE);

    struct generate_json_data data = {
        .buffer = &buffer,
        .vstate = Qfalse,
        .state = &state,
        .obj = obj,
        .func = generate_json,
    };
    rb_rescue(generate_json_try, (VALUE)&data, generate_json_rescue, (VALUE)&data);

    return fbuffer_finalize(&buffer);
}

/*
 *
 */
void Init_generator(void)
{
#ifdef HAVE_RB_EXT_RACTOR_SAFE
    rb_ext_ractor_safe(true);
#endif

#undef rb_intern
    rb_require("json/common");

    mJSON = rb_define_module("JSON");

    rb_global_variable(&cFragment);
    cFragment = rb_const_get(mJSON, rb_intern("Fragment"));

    VALUE mExt = rb_define_module_under(mJSON, "Ext");
    VALUE mGenerator = rb_define_module_under(mExt, "Generator");

    rb_global_variable(&eGeneratorError);
    eGeneratorError = rb_path2class("JSON::GeneratorError");

    rb_global_variable(&eNestingError);
    eNestingError = rb_path2class("JSON::NestingError");

    cState = rb_define_class_under(mGenerator, "State", rb_cObject);
    rb_define_alloc_func(cState, cState_s_allocate);
    rb_define_singleton_method(cState, "from_state", cState_from_state_s, 1);
    rb_define_method(cState, "initialize", cState_initialize, -1);
    rb_define_alias(cState, "initialize", "initialize"); // avoid method redefinition warnings
    rb_define_private_method(cState, "_configure", cState_configure, 1);

    rb_define_method(cState, "initialize_copy", cState_init_copy, 1);
    rb_define_method(cState, "indent", cState_indent, 0);
    rb_define_method(cState, "indent=", cState_indent_set, 1);
    rb_define_method(cState, "space", cState_space, 0);
    rb_define_method(cState, "space=", cState_space_set, 1);
    rb_define_method(cState, "space_before", cState_space_before, 0);
    rb_define_method(cState, "space_before=", cState_space_before_set, 1);
    rb_define_method(cState, "object_nl", cState_object_nl, 0);
    rb_define_method(cState, "object_nl=", cState_object_nl_set, 1);
    rb_define_method(cState, "array_nl", cState_array_nl, 0);
    rb_define_method(cState, "array_nl=", cState_array_nl_set, 1);
    rb_define_method(cState, "as_json", cState_as_json, 0);
    rb_define_method(cState, "as_json=", cState_as_json_set, 1);
    rb_define_method(cState, "max_nesting", cState_max_nesting, 0);
    rb_define_method(cState, "max_nesting=", cState_max_nesting_set, 1);
    rb_define_method(cState, "script_safe", cState_script_safe, 0);
    rb_define_method(cState, "script_safe?", cState_script_safe, 0);
    rb_define_method(cState, "script_safe=", cState_script_safe_set, 1);
    rb_define_alias(cState, "escape_slash", "script_safe");
    rb_define_alias(cState, "escape_slash?", "script_safe?");
    rb_define_alias(cState, "escape_slash=", "script_safe=");
    rb_define_method(cState, "strict", cState_strict, 0);
    rb_define_method(cState, "strict?", cState_strict, 0);
    rb_define_method(cState, "strict=", cState_strict_set, 1);
    rb_define_method(cState, "check_circular?", cState_check_circular_p, 0);
    rb_define_method(cState, "allow_nan?", cState_allow_nan_p, 0);
    rb_define_method(cState, "allow_nan=", cState_allow_nan_set, 1);
    rb_define_method(cState, "ascii_only?", cState_ascii_only_p, 0);
    rb_define_method(cState, "ascii_only=", cState_ascii_only_set, 1);
    rb_define_method(cState, "depth", cState_depth, 0);
    rb_define_method(cState, "depth=", cState_depth_set, 1);
    rb_define_method(cState, "buffer_initial_length", cState_buffer_initial_length, 0);
    rb_define_method(cState, "buffer_initial_length=", cState_buffer_initial_length_set, 1);
    rb_define_method(cState, "generate", cState_generate, -1);
    rb_define_alias(cState, "generate_new", "generate"); // :nodoc:

    rb_define_singleton_method(cState, "generate", cState_m_generate, 3);

    VALUE mGeneratorMethods = rb_define_module_under(mGenerator, "GeneratorMethods");

    VALUE mObject = rb_define_module_under(mGeneratorMethods, "Object");
    rb_define_method(mObject, "to_json", mObject_to_json, -1);

    VALUE mHash = rb_define_module_under(mGeneratorMethods, "Hash");
    rb_define_method(mHash, "to_json", mHash_to_json, -1);

    VALUE mArray = rb_define_module_under(mGeneratorMethods, "Array");
    rb_define_method(mArray, "to_json", mArray_to_json, -1);

#ifdef RUBY_INTEGER_UNIFICATION
    VALUE mInteger = rb_define_module_under(mGeneratorMethods, "Integer");
    rb_define_method(mInteger, "to_json", mInteger_to_json, -1);
#else
    VALUE mFixnum = rb_define_module_under(mGeneratorMethods, "Fixnum");
    rb_define_method(mFixnum, "to_json", mFixnum_to_json, -1);

    VALUE mBignum = rb_define_module_under(mGeneratorMethods, "Bignum");
    rb_define_method(mBignum, "to_json", mBignum_to_json, -1);
#endif
    VALUE mFloat = rb_define_module_under(mGeneratorMethods, "Float");
    rb_define_method(mFloat, "to_json", mFloat_to_json, -1);

    VALUE mString = rb_define_module_under(mGeneratorMethods, "String");
    rb_define_singleton_method(mString, "included", mString_included_s, 1);
    rb_define_method(mString, "to_json", mString_to_json, -1);
    rb_define_method(mString, "to_json_raw", mString_to_json_raw, -1);
    rb_define_method(mString, "to_json_raw_object", mString_to_json_raw_object, 0);

    mString_Extend = rb_define_module_under(mString, "Extend");
    rb_define_method(mString_Extend, "json_create", mString_Extend_json_create, 1);

    VALUE mTrueClass = rb_define_module_under(mGeneratorMethods, "TrueClass");
    rb_define_method(mTrueClass, "to_json", mTrueClass_to_json, -1);

    VALUE mFalseClass = rb_define_module_under(mGeneratorMethods, "FalseClass");
    rb_define_method(mFalseClass, "to_json", mFalseClass_to_json, -1);

    VALUE mNilClass = rb_define_module_under(mGeneratorMethods, "NilClass");
    rb_define_method(mNilClass, "to_json", mNilClass_to_json, -1);

    rb_global_variable(&Encoding_UTF_8);
    Encoding_UTF_8 = rb_const_get(rb_path2class("Encoding"), rb_intern("UTF_8"));

    i_to_s = rb_intern("to_s");
    i_to_json = rb_intern("to_json");
    i_new = rb_intern("new");
    i_pack = rb_intern("pack");
    i_unpack = rb_intern("unpack");
    i_create_id = rb_intern("create_id");
    i_extend = rb_intern("extend");
    i_encode = rb_intern("encode");

    sym_indent = ID2SYM(rb_intern("indent"));
    sym_space = ID2SYM(rb_intern("space"));
    sym_space_before = ID2SYM(rb_intern("space_before"));
    sym_object_nl = ID2SYM(rb_intern("object_nl"));
    sym_array_nl = ID2SYM(rb_intern("array_nl"));
    sym_max_nesting = ID2SYM(rb_intern("max_nesting"));
    sym_allow_nan = ID2SYM(rb_intern("allow_nan"));
    sym_ascii_only = ID2SYM(rb_intern("ascii_only"));
    sym_depth = ID2SYM(rb_intern("depth"));
    sym_buffer_initial_length = ID2SYM(rb_intern("buffer_initial_length"));
    sym_script_safe = ID2SYM(rb_intern("script_safe"));
    sym_escape_slash = ID2SYM(rb_intern("escape_slash"));
    sym_strict = ID2SYM(rb_intern("strict"));
    sym_as_json = ID2SYM(rb_intern("as_json"));

    usascii_encindex = rb_usascii_encindex();
    utf8_encindex = rb_utf8_encindex();
    binary_encindex = rb_ascii8bit_encindex();

    rb_require("json/ext/generator/state");


    switch (find_simd_implementation()) {
#ifdef HAVE_SIMD
#ifdef HAVE_SIMD_NEON
        case SIMD_NEON:
            search_escape_basic_impl = search_escape_basic_neon;
            break;
#endif /* HAVE_SIMD_NEON */
#ifdef HAVE_SIMD_SSE2
        case SIMD_SSE2:
            search_escape_basic_impl = search_escape_basic_sse2;
            break;
#endif /* HAVE_SIMD_SSE2 */
#endif /* HAVE_SIMD */
        default:
            search_escape_basic_impl = search_escape_basic;
            break;
    }
}
