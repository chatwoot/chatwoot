#include "ruby.h"
#include "ruby/encoding.h"

/* shims */
/* This is the fallback definition from Ruby 3.4 */

#ifndef RBIMPL_STDBOOL_H
#if defined(__cplusplus)
# if defined(HAVE_STDBOOL_H) && (__cplusplus >= 201103L)
#  include <cstdbool>
# endif
#elif defined(HAVE_STDBOOL_H)
# include <stdbool.h>
#elif !defined(HAVE__BOOL)
typedef unsigned char _Bool;
# define bool  _Bool
# define true  ((_Bool)+1)
# define false ((_Bool)+0)
# define __bool_true_false_are_defined
#endif
#endif

#include "../simd/simd.h"

#ifndef RB_UNLIKELY
#define RB_UNLIKELY(expr) expr
#endif

#ifndef RB_LIKELY
#define RB_LIKELY(expr) expr
#endif

static VALUE mJSON, eNestingError, Encoding_UTF_8;
static VALUE CNaN, CInfinity, CMinusInfinity;

static ID i_chr, i_aset, i_aref,
          i_leftshift, i_new, i_try_convert, i_uminus, i_encode;

static VALUE sym_max_nesting, sym_allow_nan, sym_allow_trailing_comma, sym_symbolize_names, sym_freeze,
             sym_decimal_class, sym_on_load, sym_allow_duplicate_key;

static int binary_encindex;
static int utf8_encindex;

#ifndef HAVE_RB_HASH_BULK_INSERT
// For TruffleRuby
void
rb_hash_bulk_insert(long count, const VALUE *pairs, VALUE hash)
{
    long index = 0;
    while (index < count) {
        VALUE name = pairs[index++];
        VALUE value = pairs[index++];
        rb_hash_aset(hash, name, value);
    }
    RB_GC_GUARD(hash);
}
#endif

#ifndef HAVE_RB_HASH_NEW_CAPA
#define rb_hash_new_capa(n) rb_hash_new()
#endif


/* name cache */

#include <string.h>
#include <ctype.h>

// Object names are likely to be repeated, and are frozen.
// As such we can re-use them if we keep a cache of the ones we've seen so far,
// and save much more expensive lookups into the global fstring table.
// This cache implementation is deliberately simple, as we're optimizing for compactness,
// to be able to fit safely on the stack.
// As such, binary search into a sorted array gives a good tradeoff between compactness and
// performance.
#define JSON_RVALUE_CACHE_CAPA 63
typedef struct rvalue_cache_struct {
    int length;
    VALUE entries[JSON_RVALUE_CACHE_CAPA];
} rvalue_cache;

static rb_encoding *enc_utf8;

#define JSON_RVALUE_CACHE_MAX_ENTRY_LENGTH 55

static inline VALUE build_interned_string(const char *str, const long length)
{
# ifdef HAVE_RB_ENC_INTERNED_STR
    return rb_enc_interned_str(str, length, enc_utf8);
# else
    VALUE rstring = rb_utf8_str_new(str, length);
    return rb_funcall(rb_str_freeze(rstring), i_uminus, 0);
# endif
}

static inline VALUE build_symbol(const char *str, const long length)
{
    return rb_str_intern(build_interned_string(str, length));
}

static void rvalue_cache_insert_at(rvalue_cache *cache, int index, VALUE rstring)
{
    MEMMOVE(&cache->entries[index + 1], &cache->entries[index], VALUE, cache->length - index);
    cache->length++;
    cache->entries[index] = rstring;
}

static inline int rstring_cache_cmp(const char *str, const long length, VALUE rstring)
{
    long rstring_length = RSTRING_LEN(rstring);
    if (length == rstring_length) {
        return memcmp(str, RSTRING_PTR(rstring), length);
    } else {
        return (int)(length - rstring_length);
    }
}

static VALUE rstring_cache_fetch(rvalue_cache *cache, const char *str, const long length)
{
    if (RB_UNLIKELY(length > JSON_RVALUE_CACHE_MAX_ENTRY_LENGTH)) {
        // Common names aren't likely to be very long. So we just don't
        // cache names above an arbitrary threshold.
        return Qfalse;
    }

    if (RB_UNLIKELY(!isalpha((unsigned char)str[0]))) {
        // Simple heuristic, if the first character isn't a letter,
        // we're much less likely to see this string again.
        // We mostly want to cache strings that are likely to be repeated.
        return Qfalse;
    }

    int low = 0;
    int high = cache->length - 1;
    int mid = 0;
    int last_cmp = 0;

    while (low <= high) {
        mid = (high + low) >> 1;
        VALUE entry = cache->entries[mid];
        last_cmp = rstring_cache_cmp(str, length, entry);

        if (last_cmp == 0) {
            return entry;
        } else if (last_cmp > 0) {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }

    if (RB_UNLIKELY(memchr(str, '\\', length))) {
        // We assume the overwhelming majority of names don't need to be escaped.
        // But if they do, we have to fallback to the slow path.
        return Qfalse;
    }

    VALUE rstring = build_interned_string(str, length);

    if (cache->length < JSON_RVALUE_CACHE_CAPA) {
        if (last_cmp > 0) {
            mid += 1;
        }

        rvalue_cache_insert_at(cache, mid, rstring);
    }
    return rstring;
}

static VALUE rsymbol_cache_fetch(rvalue_cache *cache, const char *str, const long length)
{
    if (RB_UNLIKELY(length > JSON_RVALUE_CACHE_MAX_ENTRY_LENGTH)) {
        // Common names aren't likely to be very long. So we just don't
        // cache names above an arbitrary threshold.
        return Qfalse;
    }

    if (RB_UNLIKELY(!isalpha((unsigned char)str[0]))) {
        // Simple heuristic, if the first character isn't a letter,
        // we're much less likely to see this string again.
        // We mostly want to cache strings that are likely to be repeated.
        return Qfalse;
    }

    int low = 0;
    int high = cache->length - 1;
    int mid = 0;
    int last_cmp = 0;

    while (low <= high) {
        mid = (high + low) >> 1;
        VALUE entry = cache->entries[mid];
        last_cmp = rstring_cache_cmp(str, length, rb_sym2str(entry));

        if (last_cmp == 0) {
            return entry;
        } else if (last_cmp > 0) {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }

    if (RB_UNLIKELY(memchr(str, '\\', length))) {
        // We assume the overwhelming majority of names don't need to be escaped.
        // But if they do, we have to fallback to the slow path.
        return Qfalse;
    }

    VALUE rsymbol = build_symbol(str, length);

    if (cache->length < JSON_RVALUE_CACHE_CAPA) {
        if (last_cmp > 0) {
            mid += 1;
        }

        rvalue_cache_insert_at(cache, mid, rsymbol);
    }
    return rsymbol;
}

/* rvalue stack */

#define RVALUE_STACK_INITIAL_CAPA 128

enum rvalue_stack_type {
    RVALUE_STACK_HEAP_ALLOCATED = 0,
    RVALUE_STACK_STACK_ALLOCATED = 1,
};

typedef struct rvalue_stack_struct {
    enum rvalue_stack_type type;
    long capa;
    long head;
    VALUE *ptr;
} rvalue_stack;

static rvalue_stack *rvalue_stack_spill(rvalue_stack *old_stack, VALUE *handle, rvalue_stack **stack_ref);

static rvalue_stack *rvalue_stack_grow(rvalue_stack *stack, VALUE *handle, rvalue_stack **stack_ref)
{
    long required = stack->capa * 2;

    if (stack->type == RVALUE_STACK_STACK_ALLOCATED) {
        stack = rvalue_stack_spill(stack, handle, stack_ref);
    } else {
        REALLOC_N(stack->ptr, VALUE, required);
        stack->capa = required;
    }
    return stack;
}

static VALUE rvalue_stack_push(rvalue_stack *stack, VALUE value, VALUE *handle, rvalue_stack **stack_ref)
{
    if (RB_UNLIKELY(stack->head >= stack->capa)) {
        stack = rvalue_stack_grow(stack, handle, stack_ref);
    }
    stack->ptr[stack->head] = value;
    stack->head++;
    return value;
}

static inline VALUE *rvalue_stack_peek(rvalue_stack *stack, long count)
{
    return stack->ptr + (stack->head - count);
}

static inline void rvalue_stack_pop(rvalue_stack *stack, long count)
{
    stack->head -= count;
}

static void rvalue_stack_mark(void *ptr)
{
    rvalue_stack *stack = (rvalue_stack *)ptr;
    long index;
    for (index = 0; index < stack->head; index++) {
        rb_gc_mark(stack->ptr[index]);
    }
}

static void rvalue_stack_free(void *ptr)
{
    rvalue_stack *stack = (rvalue_stack *)ptr;
    if (stack) {
        ruby_xfree(stack->ptr);
        ruby_xfree(stack);
    }
}

static size_t rvalue_stack_memsize(const void *ptr)
{
    const rvalue_stack *stack = (const rvalue_stack *)ptr;
    return sizeof(rvalue_stack) + sizeof(VALUE) * stack->capa;
}

static const rb_data_type_t JSON_Parser_rvalue_stack_type = {
    "JSON::Ext::Parser/rvalue_stack",
    {
        .dmark = rvalue_stack_mark,
        .dfree = rvalue_stack_free,
        .dsize = rvalue_stack_memsize,
    },
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY,
};

static rvalue_stack *rvalue_stack_spill(rvalue_stack *old_stack, VALUE *handle, rvalue_stack **stack_ref)
{
    rvalue_stack *stack;
    *handle = TypedData_Make_Struct(0, rvalue_stack, &JSON_Parser_rvalue_stack_type, stack);
    *stack_ref = stack;
    MEMCPY(stack, old_stack, rvalue_stack, 1);

    stack->capa = old_stack->capa << 1;
    stack->ptr = ALLOC_N(VALUE, stack->capa);
    stack->type = RVALUE_STACK_HEAP_ALLOCATED;
    MEMCPY(stack->ptr, old_stack->ptr, VALUE, old_stack->head);
    return stack;
}

static void rvalue_stack_eagerly_release(VALUE handle)
{
    if (handle) {
        rvalue_stack *stack;
        TypedData_Get_Struct(handle, rvalue_stack, &JSON_Parser_rvalue_stack_type, stack);
        RTYPEDDATA_DATA(handle) = NULL;
        rvalue_stack_free(stack);
    }
}


#ifndef HAVE_STRNLEN
static size_t strnlen(const char *s, size_t maxlen)
{
    char *p;
    return ((p = memchr(s, '\0', maxlen)) ? p - s : maxlen);
}
#endif

static int convert_UTF32_to_UTF8(char *buf, uint32_t ch)
{
    int len = 1;
    if (ch <= 0x7F) {
        buf[0] = (char) ch;
    } else if (ch <= 0x07FF) {
        buf[0] = (char) ((ch >> 6) | 0xC0);
        buf[1] = (char) ((ch & 0x3F) | 0x80);
        len++;
    } else if (ch <= 0xFFFF) {
        buf[0] = (char) ((ch >> 12) | 0xE0);
        buf[1] = (char) (((ch >> 6) & 0x3F) | 0x80);
        buf[2] = (char) ((ch & 0x3F) | 0x80);
        len += 2;
    } else if (ch <= 0x1fffff) {
        buf[0] =(char) ((ch >> 18) | 0xF0);
        buf[1] =(char) (((ch >> 12) & 0x3F) | 0x80);
        buf[2] =(char) (((ch >> 6) & 0x3F) | 0x80);
        buf[3] =(char) ((ch & 0x3F) | 0x80);
        len += 3;
    } else {
        buf[0] = '?';
    }
    return len;
}

enum duplicate_key_action {
    JSON_DEPRECATED = 0,
    JSON_IGNORE,
    JSON_RAISE,
};

typedef struct JSON_ParserStruct {
    VALUE on_load_proc;
    VALUE decimal_class;
    ID decimal_method_id;
    enum duplicate_key_action on_duplicate_key;
    int max_nesting;
    bool allow_nan;
    bool allow_trailing_comma;
    bool parsing_name;
    bool symbolize_names;
    bool freeze;
} JSON_ParserConfig;

typedef struct JSON_ParserStateStruct {
    VALUE stack_handle;
    const char *start;
    const char *cursor;
    const char *end;
    rvalue_stack *stack;
    rvalue_cache name_cache;
    int in_array;
    int current_nesting;
} JSON_ParserState;

static void cursor_position(JSON_ParserState *state, long *line_out, long *column_out)
{
    const char *cursor = state->cursor;
    long column = 0;
    long line = 1;

    while (cursor >= state->start) {
        if (*cursor-- == '\n') {
            break;
        }
        column++;
    }

    while (cursor >= state->start) {
        if (*cursor-- == '\n') {
            line++;
        }
    }
    *line_out = line;
    *column_out = column;
}

static void emit_parse_warning(const char *message, JSON_ParserState *state)
{
    long line, column;
    cursor_position(state, &line, &column);

    VALUE warning = rb_sprintf("%s at line %ld column %ld", message, line, column);
    rb_funcall(mJSON, rb_intern("deprecation_warning"), 1, warning);
}

#define PARSE_ERROR_FRAGMENT_LEN 32

#ifdef RBIMPL_ATTR_NORETURN
RBIMPL_ATTR_NORETURN()
#endif
static void raise_parse_error(const char *format, JSON_ParserState *state)
{
    unsigned char buffer[PARSE_ERROR_FRAGMENT_LEN + 3];
    long line, column;
    cursor_position(state, &line, &column);

    const char *ptr = "EOF";
    if (state->cursor && state->cursor < state->end) {
        ptr = state->cursor;
        size_t len = 0;
        while (len < PARSE_ERROR_FRAGMENT_LEN) {
            char ch = ptr[len];
            if (!ch || ch == '\n' || ch == ' ' || ch == '\t' || ch == '\r') {
                break;
            }
            len++;
        }

        if (len) {
            buffer[0] = '\'';
            MEMCPY(buffer + 1, ptr, char, len);

            while (buffer[len] >= 0x80 && buffer[len] < 0xC0) { // Is continuation byte
                len--;
            }

            if (buffer[len] >= 0xC0) { // multibyte character start
                len--;
            }

            buffer[len + 1] = '\'';
            buffer[len + 2] = '\0';
            ptr = (const char *)buffer;
        }
    }

    VALUE msg = rb_sprintf(format, ptr);
    VALUE message = rb_enc_sprintf(enc_utf8, "%s at line %ld column %ld", RSTRING_PTR(msg), line, column);
    RB_GC_GUARD(msg);

    VALUE exc = rb_exc_new_str(rb_path2class("JSON::ParserError"), message);
    rb_ivar_set(exc, rb_intern("@line"), LONG2NUM(line));
    rb_ivar_set(exc, rb_intern("@column"), LONG2NUM(column));
    rb_exc_raise(exc);
}

#ifdef RBIMPL_ATTR_NORETURN
RBIMPL_ATTR_NORETURN()
#endif
static void raise_parse_error_at(const char *format, JSON_ParserState *state, const char *at)
{
    state->cursor = at;
    raise_parse_error(format, state);
}

/* unicode */

static const signed char digit_values[256] = {
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1,
    -1, -1, -1, -1, -1, -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1
};

static uint32_t unescape_unicode(JSON_ParserState *state, const unsigned char *p)
{
    signed char b;
    uint32_t result = 0;
    b = digit_values[p[0]];
    if (b < 0) raise_parse_error_at("incomplete unicode character escape sequence at %s", state, (char *)p - 2);
    result = (result << 4) | (unsigned char)b;
    b = digit_values[p[1]];
    if (b < 0) raise_parse_error_at("incomplete unicode character escape sequence at %s", state, (char *)p - 2);
    result = (result << 4) | (unsigned char)b;
    b = digit_values[p[2]];
    if (b < 0) raise_parse_error_at("incomplete unicode character escape sequence at %s", state, (char *)p - 2);
    result = (result << 4) | (unsigned char)b;
    b = digit_values[p[3]];
    if (b < 0) raise_parse_error_at("incomplete unicode character escape sequence at %s", state, (char *)p - 2);
    result = (result << 4) | (unsigned char)b;
    return result;
}

#define GET_PARSER_CONFIG                          \
    JSON_ParserConfig *config;                      \
    TypedData_Get_Struct(self, JSON_ParserConfig, &JSON_ParserConfig_type, config)

static const rb_data_type_t JSON_ParserConfig_type;

static const bool whitespace[256] = {
    [' '] = 1,
    ['\t'] = 1,
    ['\n'] = 1,
    ['\r'] = 1,
    ['/'] = 1,
};

static void
json_eat_comments(JSON_ParserState *state)
{
    if (state->cursor + 1 < state->end) {
        switch (state->cursor[1]) {
            case '/': {
                state->cursor = memchr(state->cursor, '\n', state->end - state->cursor);
                if (!state->cursor) {
                    state->cursor = state->end;
                } else {
                    state->cursor++;
                }
                break;
            }
            case '*': {
                state->cursor += 2;
                while (true) {
                    state->cursor = memchr(state->cursor, '*', state->end - state->cursor);
                    if (!state->cursor) {
                        raise_parse_error_at("unexpected end of input, expected closing '*/'", state, state->end);
                    } else {
                        state->cursor++;
                        if (state->cursor < state->end && *state->cursor == '/') {
                            state->cursor++;
                            break;
                        }
                    }
                }
                break;
            }
            default:
                raise_parse_error("unexpected token %s", state);
                break;
        }
    } else {
        raise_parse_error("unexpected token %s", state);
    }
}

static inline void
json_eat_whitespace(JSON_ParserState *state)
{
    while (state->cursor < state->end && RB_UNLIKELY(whitespace[(unsigned char)*state->cursor])) {
        if (RB_LIKELY(*state->cursor != '/')) {
            state->cursor++;
        } else {
            json_eat_comments(state);
        }
    }
}

static inline VALUE build_string(const char *start, const char *end, bool intern, bool symbolize)
{
    if (symbolize) {
        intern = true;
    }
    VALUE result;
# ifdef HAVE_RB_ENC_INTERNED_STR
    if (intern) {
      result = rb_enc_interned_str(start, (long)(end - start), enc_utf8);
    } else {
      result = rb_utf8_str_new(start, (long)(end - start));
    }
# else
    result = rb_utf8_str_new(start, (long)(end - start));
    if (intern) {
        result = rb_funcall(rb_str_freeze(result), i_uminus, 0);
    }
# endif

    if (symbolize) {
      result = rb_str_intern(result);
    }

    return result;
}

static inline VALUE json_string_fastpath(JSON_ParserState *state, const char *string, const char *stringEnd, bool is_name, bool intern, bool symbolize)
{
    size_t bufferSize = stringEnd - string;

    if (is_name && state->in_array) {
        VALUE cached_key;
        if (RB_UNLIKELY(symbolize)) {
            cached_key = rsymbol_cache_fetch(&state->name_cache, string, bufferSize);
        } else {
            cached_key = rstring_cache_fetch(&state->name_cache, string, bufferSize);
        }

        if (RB_LIKELY(cached_key)) {
            return cached_key;
        }
    }

    return build_string(string, stringEnd, intern, symbolize);
}

static VALUE json_string_unescape(JSON_ParserState *state, const char *string, const char *stringEnd, bool is_name, bool intern, bool symbolize)
{
    size_t bufferSize = stringEnd - string;
    const char *p = string, *pe = string, *unescape, *bufferStart;
    char *buffer;
    int unescape_len;
    char buf[4];

    if (is_name && state->in_array) {
        VALUE cached_key;
        if (RB_UNLIKELY(symbolize)) {
            cached_key = rsymbol_cache_fetch(&state->name_cache, string, bufferSize);
        } else {
            cached_key = rstring_cache_fetch(&state->name_cache, string, bufferSize);
        }

        if (RB_LIKELY(cached_key)) {
            return cached_key;
        }
    }

    VALUE result = rb_str_buf_new(bufferSize);
    rb_enc_associate_index(result, utf8_encindex);
    buffer = RSTRING_PTR(result);
    bufferStart = buffer;

    while (pe < stringEnd && (pe = memchr(pe, '\\', stringEnd - pe))) {
        unescape = (char *) "?";
        unescape_len = 1;
        if (pe > p) {
          MEMCPY(buffer, p, char, pe - p);
          buffer += pe - p;
        }
        switch (*++pe) {
            case 'n':
                unescape = (char *) "\n";
                break;
            case 'r':
                unescape = (char *) "\r";
                break;
            case 't':
                unescape = (char *) "\t";
                break;
            case '"':
                unescape = (char *) "\"";
                break;
            case '\\':
                unescape = (char *) "\\";
                break;
            case 'b':
                unescape = (char *) "\b";
                break;
            case 'f':
                unescape = (char *) "\f";
                break;
            case 'u':
                if (pe > stringEnd - 5) {
                    raise_parse_error_at("incomplete unicode character escape sequence at %s", state, p);
                } else {
                    uint32_t ch = unescape_unicode(state, (unsigned char *) ++pe);
                    pe += 3;
                    /* To handle values above U+FFFF, we take a sequence of
                     * \uXXXX escapes in the U+D800..U+DBFF then
                     * U+DC00..U+DFFF ranges, take the low 10 bits from each
                     * to make a 20-bit number, then add 0x10000 to get the
                     * final codepoint.
                     *
                     * See Unicode 15: 3.8 "Surrogates", 5.3 "Handling
                     * Surrogate Pairs in UTF-16", and 23.6 "Surrogates
                     * Area".
                     */
                    if ((ch & 0xFC00) == 0xD800) {
                        pe++;
                        if (pe > stringEnd - 6) {
                            raise_parse_error_at("incomplete surrogate pair at %s", state, p);
                        }
                        if (pe[0] == '\\' && pe[1] == 'u') {
                            uint32_t sur = unescape_unicode(state, (unsigned char *) pe + 2);
                            ch = (((ch & 0x3F) << 10) | ((((ch >> 6) & 0xF) + 1) << 16)
                                    | (sur & 0x3FF));
                            pe += 5;
                        } else {
                            unescape = (char *) "?";
                            break;
                        }
                    }
                    unescape_len = convert_UTF32_to_UTF8(buf, ch);
                    unescape = buf;
                }
                break;
            default:
                p = pe;
                continue;
        }
        MEMCPY(buffer, unescape, char, unescape_len);
        buffer += unescape_len;
        p = ++pe;
    }

    if (stringEnd > p) {
      MEMCPY(buffer, p, char, stringEnd - p);
      buffer += stringEnd - p;
    }
    rb_str_set_len(result, buffer - bufferStart);

    if (symbolize) {
        result = rb_str_intern(result);
    } else if (intern) {
        result = rb_funcall(rb_str_freeze(result), i_uminus, 0);
    }

    return result;
}

#define MAX_FAST_INTEGER_SIZE 18
static inline VALUE fast_decode_integer(const char *p, const char *pe)
{
    bool negative = false;
    if (*p == '-') {
        negative = true;
        p++;
    }

    long long memo = 0;
    while (p < pe) {
        memo *= 10;
        memo += *p - '0';
        p++;
    }

    if (negative) {
        memo = -memo;
    }
    return LL2NUM(memo);
}

static VALUE json_decode_large_integer(const char *start, long len)
{
    VALUE buffer_v;
    char *buffer = RB_ALLOCV_N(char, buffer_v, len + 1);
    MEMCPY(buffer, start, char, len);
    buffer[len] = '\0';
    VALUE number = rb_cstr2inum(buffer, 10);
    RB_ALLOCV_END(buffer_v);
    return number;
}

static inline VALUE
json_decode_integer(const char *start, const char *end)
{
        long len = end - start;
        if (RB_LIKELY(len < MAX_FAST_INTEGER_SIZE)) {
            return fast_decode_integer(start, end);
        }
        return json_decode_large_integer(start, len);
}

static VALUE json_decode_large_float(const char *start, long len)
{
    VALUE buffer_v;
    char *buffer = RB_ALLOCV_N(char, buffer_v, len + 1);
    MEMCPY(buffer, start, char, len);
    buffer[len] = '\0';
    VALUE number = DBL2NUM(rb_cstr_to_dbl(buffer, 1));
    RB_ALLOCV_END(buffer_v);
    return number;
}

static VALUE json_decode_float(JSON_ParserConfig *config, const char *start, const char *end)
{
    long len = end - start;

    if (RB_UNLIKELY(config->decimal_class)) {
        VALUE text = rb_str_new(start, len);
        return rb_funcallv(config->decimal_class, config->decimal_method_id, 1, &text);
    } else if (RB_LIKELY(len < 64)) {
        char buffer[64];
        MEMCPY(buffer, start, char, len);
        buffer[len] = '\0';
        return DBL2NUM(rb_cstr_to_dbl(buffer, 1));
    } else {
        return json_decode_large_float(start, len);
    }
}

static inline VALUE json_decode_array(JSON_ParserState *state, JSON_ParserConfig *config, long count)
{
    VALUE array = rb_ary_new_from_values(count, rvalue_stack_peek(state->stack, count));
    rvalue_stack_pop(state->stack, count);

    if (config->freeze) {
        RB_OBJ_FREEZE(array);
    }

    return array;
}

static VALUE json_find_duplicated_key(size_t count, const VALUE *pairs)
{
    VALUE set = rb_hash_new_capa(count / 2);
    for (size_t index = 0; index < count; index += 2) {
        size_t before = RHASH_SIZE(set);
        VALUE key = pairs[index];
        rb_hash_aset(set, key, Qtrue);
        if (RHASH_SIZE(set) == before) {
            if (RB_SYMBOL_P(key)) {
                return rb_sym2str(key);
            }
            return key;
        }
    }
    return Qfalse;
}

static void emit_duplicate_key_warning(JSON_ParserState *state, VALUE duplicate_key)
{
    VALUE message = rb_sprintf(
        "detected duplicate key %"PRIsVALUE" in JSON object. This will raise an error in json 3.0 unless enabled via `allow_duplicate_key: true`",
        rb_inspect(duplicate_key)
    );

    emit_parse_warning(RSTRING_PTR(message), state);
    RB_GC_GUARD(message);
}

#ifdef RBIMPL_ATTR_NORETURN
RBIMPL_ATTR_NORETURN()
#endif
static void raise_duplicate_key_error(JSON_ParserState *state, VALUE duplicate_key)
{
    VALUE message = rb_sprintf(
        "duplicate key %"PRIsVALUE,
        rb_inspect(duplicate_key)
    );

    raise_parse_error(RSTRING_PTR(message), state);
    RB_GC_GUARD(message);
}

static inline VALUE json_decode_object(JSON_ParserState *state, JSON_ParserConfig *config, size_t count)
{
    size_t entries_count = count / 2;
    VALUE object = rb_hash_new_capa(entries_count);
    const VALUE *pairs = rvalue_stack_peek(state->stack, count);
    rb_hash_bulk_insert(count, pairs, object);

    if (RB_UNLIKELY(RHASH_SIZE(object) < entries_count)) {
        switch (config->on_duplicate_key) {
            case JSON_IGNORE:
                break;
            case JSON_DEPRECATED:
                emit_duplicate_key_warning(state, json_find_duplicated_key(count, pairs));
                break;
            case JSON_RAISE:
                raise_duplicate_key_error(state, json_find_duplicated_key(count, pairs));
                break;
        }
    }

    rvalue_stack_pop(state->stack, count);

    if (config->freeze) {
        RB_OBJ_FREEZE(object);
    }

    return object;
}

static inline VALUE json_decode_string(JSON_ParserState *state, JSON_ParserConfig *config, const char *start, const char *end, bool escaped, bool is_name)
{
    VALUE string;
    bool intern = is_name || config->freeze;
    bool symbolize = is_name && config->symbolize_names;
    if (escaped) {
        string = json_string_unescape(state, start, end, is_name, intern, symbolize);
    } else {
        string = json_string_fastpath(state, start, end, is_name, intern, symbolize);
    }

    return string;
}

static inline VALUE json_push_value(JSON_ParserState *state, JSON_ParserConfig *config, VALUE value)
{
    if (RB_UNLIKELY(config->on_load_proc)) {
        value = rb_proc_call_with_block(config->on_load_proc, 1, &value, Qnil);
    }
    rvalue_stack_push(state->stack, value, &state->stack_handle, &state->stack);
    return value;
}

static const bool string_scan_table[256] = {
    // ASCII Control Characters
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    // ASCII Characters
     0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // '"'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, // '\\'
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

#if (defined(__GNUC__ ) || defined(__clang__))
#define FORCE_INLINE __attribute__((always_inline))
#else
#define FORCE_INLINE
#endif

#ifdef HAVE_SIMD
static SIMD_Implementation simd_impl = SIMD_NONE;
#endif /* HAVE_SIMD */

static inline bool FORCE_INLINE string_scan(JSON_ParserState *state)
{
#ifdef HAVE_SIMD
#if defined(HAVE_SIMD_NEON)

    uint64_t mask = 0;
    if (string_scan_simd_neon(&state->cursor, state->end, &mask)) {
        state->cursor += trailing_zeros64(mask) >> 2;
        return 1;
    }

#elif defined(HAVE_SIMD_SSE2)
    if (simd_impl == SIMD_SSE2) {
        int mask = 0;
        if (string_scan_simd_sse2(&state->cursor, state->end, &mask)) {
            state->cursor += trailing_zeros(mask);
            return 1;
        }
    }
#endif /* HAVE_SIMD_NEON or HAVE_SIMD_SSE2 */
#endif /* HAVE_SIMD */

    while (state->cursor < state->end) {
        if (RB_UNLIKELY(string_scan_table[(unsigned char)*state->cursor])) {
            return 1;
        }
        *state->cursor++;
    }
    return 0;
}

static inline VALUE json_parse_string(JSON_ParserState *state, JSON_ParserConfig *config, bool is_name)
{
    state->cursor++;
    const char *start = state->cursor;
    bool escaped = false;

    while (RB_UNLIKELY(string_scan(state))) {
        switch (*state->cursor) {
            case '"': {
                VALUE string = json_decode_string(state, config, start, state->cursor, escaped, is_name);
                state->cursor++;
                return json_push_value(state, config, string);
            }
            case '\\': {
                state->cursor++;
                escaped = true;
                if ((unsigned char)*state->cursor < 0x20) {
                    raise_parse_error("invalid ASCII control character in string: %s", state);
                }
                break;
            }
            default:
                raise_parse_error("invalid ASCII control character in string: %s", state);
                break;
        }

        state->cursor++;
    }

    raise_parse_error("unexpected end of input, expected closing \"", state);
    return Qfalse;
}

static VALUE json_parse_any(JSON_ParserState *state, JSON_ParserConfig *config)
{
    json_eat_whitespace(state);
    if (state->cursor >= state->end) {
        raise_parse_error("unexpected end of input", state);
    }

    switch (*state->cursor) {
        case 'n':
            if ((state->end - state->cursor >= 4) && (memcmp(state->cursor, "null", 4) == 0)) {
                state->cursor += 4;
                return json_push_value(state, config, Qnil);
            }

            raise_parse_error("unexpected token %s", state);
            break;
        case 't':
            if ((state->end - state->cursor >= 4) && (memcmp(state->cursor, "true", 4) == 0)) {
                state->cursor += 4;
                return json_push_value(state, config, Qtrue);
            }

            raise_parse_error("unexpected token %s", state);
            break;
        case 'f':
            // Note: memcmp with a small power of two compile to an integer comparison
            if ((state->end - state->cursor >= 5) && (memcmp(state->cursor + 1, "alse", 4) == 0)) {
                state->cursor += 5;
                return json_push_value(state, config, Qfalse);
            }

            raise_parse_error("unexpected token %s", state);
            break;
        case 'N':
            // Note: memcmp with a small power of two compile to an integer comparison
            if (config->allow_nan && (state->end - state->cursor >= 3) && (memcmp(state->cursor + 1, "aN", 2) == 0)) {
                state->cursor += 3;
                return json_push_value(state, config, CNaN);
            }

            raise_parse_error("unexpected token %s", state);
            break;
        case 'I':
            if (config->allow_nan && (state->end - state->cursor >= 8) && (memcmp(state->cursor, "Infinity", 8) == 0)) {
                state->cursor += 8;
                return json_push_value(state, config, CInfinity);
            }

            raise_parse_error("unexpected token %s", state);
            break;
        case '-':
            // Note: memcmp with a small power of two compile to an integer comparison
            if ((state->end - state->cursor >= 9) && (memcmp(state->cursor + 1, "Infinity", 8) == 0)) {
                if (config->allow_nan) {
                    state->cursor += 9;
                    return json_push_value(state, config, CMinusInfinity);
                } else {
                    raise_parse_error("unexpected token %s", state);
                }
            }
            // Fallthrough
        case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9': {
            bool integer = true;

            // /\A-?(0|[1-9]\d*)(\.\d+)?([Ee][-+]?\d+)?/
            const char *start = state->cursor;
            state->cursor++;

            while ((state->cursor < state->end) && (*state->cursor >= '0') && (*state->cursor <= '9')) {
                state->cursor++;
            }

            long integer_length = state->cursor - start;

            if (RB_UNLIKELY(start[0] == '0' && integer_length > 1)) {
                raise_parse_error_at("invalid number: %s", state, start);
            } else if (RB_UNLIKELY(integer_length > 2 && start[0] == '-' && start[1] == '0')) {
                raise_parse_error_at("invalid number: %s", state, start);
            } else if (RB_UNLIKELY(integer_length == 1 && start[0] == '-')) {
                raise_parse_error_at("invalid number: %s", state, start);
            }

            if ((state->cursor < state->end) && (*state->cursor == '.')) {
                integer = false;
                state->cursor++;

                if (state->cursor == state->end || *state->cursor < '0' || *state->cursor > '9') {
                    raise_parse_error("invalid number: %s", state);
                }

                while ((state->cursor < state->end) && (*state->cursor >= '0') && (*state->cursor <= '9')) {
                    state->cursor++;
                }
            }

            if ((state->cursor < state->end) && ((*state->cursor == 'e') || (*state->cursor == 'E'))) {
                integer = false;
                state->cursor++;
                if ((state->cursor < state->end) && ((*state->cursor == '+') || (*state->cursor == '-'))) {
                    state->cursor++;
                }

                if (state->cursor == state->end || *state->cursor < '0' || *state->cursor > '9') {
                    raise_parse_error("invalid number: %s", state);
                }

                while ((state->cursor < state->end) && (*state->cursor >= '0') && (*state->cursor <= '9')) {
                    state->cursor++;
                }
            }

            if (integer) {
                return json_push_value(state, config, json_decode_integer(start, state->cursor));
            }
            return json_push_value(state, config, json_decode_float(config, start, state->cursor));
        }
        case '"': {
            // %r{\A"[^"\\\t\n\x00]*(?:\\[bfnrtu\\/"][^"\\]*)*"}
            return json_parse_string(state, config, false);
            break;
        }
        case '[': {
            state->cursor++;
            json_eat_whitespace(state);
            long stack_head = state->stack->head;

            if ((state->cursor < state->end) && (*state->cursor == ']')) {
                state->cursor++;
                return json_push_value(state, config, json_decode_array(state, config, 0));
            } else {
                state->current_nesting++;
                if (RB_UNLIKELY(config->max_nesting && (config->max_nesting < state->current_nesting))) {
                    rb_raise(eNestingError, "nesting of %d is too deep", state->current_nesting);
                }
                state->in_array++;
                json_parse_any(state, config);
            }

            while (true) {
                json_eat_whitespace(state);

                if (state->cursor < state->end) {
                    if (*state->cursor == ']') {
                        state->cursor++;
                        long count = state->stack->head - stack_head;
                        state->current_nesting--;
                        state->in_array--;
                        return json_push_value(state, config, json_decode_array(state, config, count));
                    }

                    if (*state->cursor == ',') {
                        state->cursor++;
                        if (config->allow_trailing_comma) {
                            json_eat_whitespace(state);
                            if ((state->cursor < state->end) && (*state->cursor == ']')) {
                                continue;
                            }
                        }
                        json_parse_any(state, config);
                        continue;
                    }
                }

                raise_parse_error("expected ',' or ']' after array value", state);
            }
            break;
        }
        case '{': {
            const char *object_start_cursor = state->cursor;

            state->cursor++;
            json_eat_whitespace(state);
            long stack_head = state->stack->head;

            if ((state->cursor < state->end) && (*state->cursor == '}')) {
                state->cursor++;
                return json_push_value(state, config, json_decode_object(state, config, 0));
            } else {
                state->current_nesting++;
                if (RB_UNLIKELY(config->max_nesting && (config->max_nesting < state->current_nesting))) {
                    rb_raise(eNestingError, "nesting of %d is too deep", state->current_nesting);
                }

                if (*state->cursor != '"') {
                    raise_parse_error("expected object key, got %s", state);
                }
                json_parse_string(state, config, true);

                json_eat_whitespace(state);
                if ((state->cursor >= state->end) || (*state->cursor != ':')) {
                    raise_parse_error("expected ':' after object key", state);
                }
                state->cursor++;

                json_parse_any(state, config);
            }

            while (true) {
                json_eat_whitespace(state);

                if (state->cursor < state->end) {
                    if (*state->cursor == '}') {
                        state->cursor++;
                        state->current_nesting--;
                        size_t count = state->stack->head - stack_head;

                        // Temporary rewind cursor in case an error is raised
                        const char *final_cursor = state->cursor;
                        state->cursor = object_start_cursor;
                        VALUE object = json_decode_object(state, config, count);
                        state->cursor = final_cursor;

                        return json_push_value(state, config, object);
                    }

                    if (*state->cursor == ',') {
                        state->cursor++;
                        json_eat_whitespace(state);

                        if (config->allow_trailing_comma) {
                            if ((state->cursor < state->end) && (*state->cursor == '}')) {
                                continue;
                            }
                        }

                        if (*state->cursor != '"') {
                            raise_parse_error("expected object key, got: %s", state);
                        }
                        json_parse_string(state, config, true);

                        json_eat_whitespace(state);
                        if ((state->cursor >= state->end) || (*state->cursor != ':')) {
                            raise_parse_error("expected ':' after object key, got: %s", state);
                        }
                        state->cursor++;

                        json_parse_any(state, config);

                        continue;
                    }
                }

                raise_parse_error("expected ',' or '}' after object value, got: %s", state);
            }
            break;
        }

        default:
            raise_parse_error("unexpected character: %s", state);
            break;
    }

    raise_parse_error("unreacheable: %s", state);
}

static void json_ensure_eof(JSON_ParserState *state)
{
    json_eat_whitespace(state);
    if (state->cursor != state->end) {
        raise_parse_error("unexpected token at end of stream %s", state);
    }
}

/*
 * Document-class: JSON::Ext::Parser
 *
 * This is the JSON parser implemented as a C extension. It can be configured
 * to be used by setting
 *
 *  JSON.parser = JSON::Ext::Parser
 *
 * with the method parser= in JSON.
 *
 */

static VALUE convert_encoding(VALUE source)
{
  int encindex = RB_ENCODING_GET(source);

  if (RB_LIKELY(encindex == utf8_encindex)) {
    return source;
  }

 if (encindex == binary_encindex) {
    // For historical reason, we silently reinterpret binary strings as UTF-8
    return rb_enc_associate_index(rb_str_dup(source), utf8_encindex);
  }

  return rb_funcall(source, i_encode, 1, Encoding_UTF_8);
}

static int parser_config_init_i(VALUE key, VALUE val, VALUE data)
{
    JSON_ParserConfig *config = (JSON_ParserConfig *)data;

         if (key == sym_max_nesting)          { config->max_nesting = RTEST(val) ? FIX2INT(val) : 0; }
    else if (key == sym_allow_nan)            { config->allow_nan = RTEST(val); }
    else if (key == sym_allow_trailing_comma) { config->allow_trailing_comma = RTEST(val); }
    else if (key == sym_symbolize_names)      { config->symbolize_names = RTEST(val); }
    else if (key == sym_freeze)               { config->freeze = RTEST(val); }
    else if (key == sym_on_load)              { config->on_load_proc = RTEST(val) ? val : Qfalse; }
    else if (key == sym_allow_duplicate_key) { config->on_duplicate_key = RTEST(val) ? JSON_IGNORE : JSON_RAISE; }
    else if (key == sym_decimal_class)        {
        if (RTEST(val)) {
            if (rb_respond_to(val, i_try_convert)) {
                config->decimal_class = val;
                config->decimal_method_id = i_try_convert;
            } else if (rb_respond_to(val, i_new)) {
                config->decimal_class = val;
                config->decimal_method_id = i_new;
            } else if (RB_TYPE_P(val, T_CLASS)) {
                VALUE name = rb_class_name(val);
                const char *name_cstr = RSTRING_PTR(name);
                const char *last_colon = strrchr(name_cstr, ':');
                if (last_colon) {
                    const char *mod_path_end = last_colon - 1;
                    VALUE mod_path = rb_str_substr(name, 0, mod_path_end - name_cstr);
                    config->decimal_class = rb_path_to_class(mod_path);

                    const char *method_name_beg = last_colon + 1;
                    long before_len = method_name_beg - name_cstr;
                    long len = RSTRING_LEN(name) - before_len;
                    VALUE method_name = rb_str_substr(name, before_len, len);
                    config->decimal_method_id = SYM2ID(rb_str_intern(method_name));
                } else {
                    config->decimal_class = rb_mKernel;
                    config->decimal_method_id = SYM2ID(rb_str_intern(name));
                }
            }
        }
    }

    return ST_CONTINUE;
}

static void parser_config_init(JSON_ParserConfig *config, VALUE opts)
{
    config->max_nesting = 100;

    if (!NIL_P(opts)) {
        Check_Type(opts, T_HASH);
        if (RHASH_SIZE(opts) > 0) {
            // We assume in most cases few keys are set so it's faster to go over
            // the provided keys than to check all possible keys.
            rb_hash_foreach(opts, parser_config_init_i, (VALUE)config);
        }

    }
}

/*
 * call-seq: new(opts => {})
 *
 * Creates a new JSON::Ext::ParserConfig instance.
 *
 * It will be configured by the _opts_ hash. _opts_ can have the following
 * keys:
 *
 * _opts_ can have the following keys:
 * * *max_nesting*: The maximum depth of nesting allowed in the parsed data
 *   structures. Disable depth checking with :max_nesting => false|nil|0, it
 *   defaults to 100.
 * * *allow_nan*: If set to true, allow NaN, Infinity and -Infinity in
 *   defiance of RFC 4627 to be parsed by the Parser. This option defaults to
 *   false.
 * * *symbolize_names*: If set to true, returns symbols for the names
 *   (keys) in a JSON object. Otherwise strings are returned, which is
 *   also the default. It's not possible to use this option in
 *   conjunction with the *create_additions* option.
 * * *decimal_class*: Specifies which class to use instead of the default
 *    (Float) when parsing decimal numbers. This class must accept a single
 *    string argument in its constructor.
 */
static VALUE cParserConfig_initialize(VALUE self, VALUE opts)
{
    GET_PARSER_CONFIG;

    parser_config_init(config, opts);

    RB_OBJ_WRITTEN(self, Qundef, config->decimal_class);

    return self;
}

static VALUE cParser_parse(JSON_ParserConfig *config, VALUE Vsource)
{
    Vsource = convert_encoding(StringValue(Vsource));
    StringValue(Vsource);

    VALUE rvalue_stack_buffer[RVALUE_STACK_INITIAL_CAPA];
    rvalue_stack stack = {
        .type = RVALUE_STACK_STACK_ALLOCATED,
        .ptr = rvalue_stack_buffer,
        .capa = RVALUE_STACK_INITIAL_CAPA,
    };

    long len;
    const char *start;
    RSTRING_GETMEM(Vsource, start, len);

    JSON_ParserState _state = {
        .start = start,
        .cursor = start,
        .end = start + len,
        .stack = &stack,
    };
    JSON_ParserState *state = &_state;

    VALUE result = json_parse_any(state, config);

    // This may be skipped in case of exception, but
    // it won't cause a leak.
    rvalue_stack_eagerly_release(state->stack_handle);

    json_ensure_eof(state);

    return result;
}

/*
 * call-seq: parse(source)
 *
 *  Parses the current JSON text _source_ and returns the complete data
 *  structure as a result.
 *  It raises JSON::ParserError if fail to parse.
 */
static VALUE cParserConfig_parse(VALUE self, VALUE Vsource)
{
    GET_PARSER_CONFIG;
    return cParser_parse(config, Vsource);
}

static VALUE cParser_m_parse(VALUE klass, VALUE Vsource, VALUE opts)
{
    Vsource = convert_encoding(StringValue(Vsource));
    StringValue(Vsource);

    JSON_ParserConfig _config = {0};
    JSON_ParserConfig *config = &_config;
    parser_config_init(config, opts);

    return cParser_parse(config, Vsource);
}

static void JSON_ParserConfig_mark(void *ptr)
{
    JSON_ParserConfig *config = ptr;
    rb_gc_mark(config->on_load_proc);
    rb_gc_mark(config->decimal_class);
}

static void JSON_ParserConfig_free(void *ptr)
{
    JSON_ParserConfig *config = ptr;
    ruby_xfree(config);
}

static size_t JSON_ParserConfig_memsize(const void *ptr)
{
    return sizeof(JSON_ParserConfig);
}

static const rb_data_type_t JSON_ParserConfig_type = {
    "JSON::Ext::Parser/ParserConfig",
    {
        JSON_ParserConfig_mark,
        JSON_ParserConfig_free,
        JSON_ParserConfig_memsize,
    },
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE cJSON_parser_s_allocate(VALUE klass)
{
    JSON_ParserConfig *config;
    return TypedData_Make_Struct(klass, JSON_ParserConfig, &JSON_ParserConfig_type, config);
}

void Init_parser(void)
{
#ifdef HAVE_RB_EXT_RACTOR_SAFE
    rb_ext_ractor_safe(true);
#endif

#undef rb_intern
    rb_require("json/common");
    mJSON = rb_define_module("JSON");
    VALUE mExt = rb_define_module_under(mJSON, "Ext");
    VALUE cParserConfig = rb_define_class_under(mExt, "ParserConfig", rb_cObject);
    eNestingError = rb_path2class("JSON::NestingError");
    rb_gc_register_mark_object(eNestingError);
    rb_define_alloc_func(cParserConfig, cJSON_parser_s_allocate);
    rb_define_method(cParserConfig, "initialize", cParserConfig_initialize, 1);
    rb_define_method(cParserConfig, "parse", cParserConfig_parse, 1);

    VALUE cParser = rb_define_class_under(mExt, "Parser", rb_cObject);
    rb_define_singleton_method(cParser, "parse", cParser_m_parse, 2);

    CNaN = rb_const_get(mJSON, rb_intern("NaN"));
    rb_gc_register_mark_object(CNaN);

    CInfinity = rb_const_get(mJSON, rb_intern("Infinity"));
    rb_gc_register_mark_object(CInfinity);

    CMinusInfinity = rb_const_get(mJSON, rb_intern("MinusInfinity"));
    rb_gc_register_mark_object(CMinusInfinity);

    rb_global_variable(&Encoding_UTF_8);
    Encoding_UTF_8 = rb_const_get(rb_path2class("Encoding"), rb_intern("UTF_8"));

    sym_max_nesting = ID2SYM(rb_intern("max_nesting"));
    sym_allow_nan = ID2SYM(rb_intern("allow_nan"));
    sym_allow_trailing_comma = ID2SYM(rb_intern("allow_trailing_comma"));
    sym_symbolize_names = ID2SYM(rb_intern("symbolize_names"));
    sym_freeze = ID2SYM(rb_intern("freeze"));
    sym_on_load = ID2SYM(rb_intern("on_load"));
    sym_decimal_class = ID2SYM(rb_intern("decimal_class"));
    sym_allow_duplicate_key = ID2SYM(rb_intern("allow_duplicate_key"));

    i_chr = rb_intern("chr");
    i_aset = rb_intern("[]=");
    i_aref = rb_intern("[]");
    i_leftshift = rb_intern("<<");
    i_new = rb_intern("new");
    i_try_convert = rb_intern("try_convert");
    i_uminus = rb_intern("-@");
    i_encode = rb_intern("encode");

    binary_encindex = rb_ascii8bit_encindex();
    utf8_encindex = rb_utf8_encindex();
    enc_utf8 = rb_utf8_encoding();

#ifdef HAVE_SIMD
    simd_impl = find_simd_implementation();
#endif
}
