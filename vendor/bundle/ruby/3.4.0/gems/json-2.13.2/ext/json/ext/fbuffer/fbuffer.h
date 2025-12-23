#ifndef _FBUFFER_H_
#define _FBUFFER_H_

#include "ruby.h"
#include "ruby/encoding.h"
#include "../vendor/jeaiii-ltoa.h"

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

#ifndef RB_UNLIKELY
#define RB_UNLIKELY(expr) expr
#endif

#ifndef RB_LIKELY
#define RB_LIKELY(expr) expr
#endif

#ifndef MAYBE_UNUSED
# define MAYBE_UNUSED(x) x
#endif

#ifdef RUBY_DEBUG
#ifndef JSON_DEBUG
#define JSON_DEBUG RUBY_DEBUG
#endif
#endif

enum fbuffer_type {
    FBUFFER_HEAP_ALLOCATED = 0,
    FBUFFER_STACK_ALLOCATED = 1,
};

typedef struct FBufferStruct {
    enum fbuffer_type type;
    unsigned long initial_length;
    unsigned long len;
    unsigned long capa;
#ifdef JSON_DEBUG
    unsigned long requested;
#endif
    char *ptr;
    VALUE io;
} FBuffer;

#define FBUFFER_STACK_SIZE 512
#define FBUFFER_IO_BUFFER_SIZE (16384 - 1)
#define FBUFFER_INITIAL_LENGTH_DEFAULT 1024

#define FBUFFER_PTR(fb) ((fb)->ptr)
#define FBUFFER_LEN(fb) ((fb)->len)
#define FBUFFER_CAPA(fb) ((fb)->capa)
#define FBUFFER_PAIR(fb) FBUFFER_PTR(fb), FBUFFER_LEN(fb)

static void fbuffer_free(FBuffer *fb);
static void fbuffer_clear(FBuffer *fb);
static void fbuffer_append(FBuffer *fb, const char *newstr, unsigned long len);
static void fbuffer_append_long(FBuffer *fb, long number);
static inline void fbuffer_append_char(FBuffer *fb, char newchr);
static VALUE fbuffer_finalize(FBuffer *fb);

static void fbuffer_stack_init(FBuffer *fb, unsigned long initial_length, char *stack_buffer, long stack_buffer_size)
{
    fb->initial_length = (initial_length > 0) ? initial_length : FBUFFER_INITIAL_LENGTH_DEFAULT;
    if (stack_buffer) {
        fb->type = FBUFFER_STACK_ALLOCATED;
        fb->ptr = stack_buffer;
        fb->capa = stack_buffer_size;
    }
#ifdef JSON_DEBUG
    fb->requested = 0;
#endif
}

static inline void fbuffer_consumed(FBuffer *fb, unsigned long consumed)
{
#ifdef JSON_DEBUG
    if (consumed > fb->requested) {
        rb_bug("fbuffer: Out of bound write");
    }
    fb->requested = 0;
#endif
    fb->len += consumed;
}

static void fbuffer_free(FBuffer *fb)
{
    if (fb->ptr && fb->type == FBUFFER_HEAP_ALLOCATED) {
        ruby_xfree(fb->ptr);
    }
}

static void fbuffer_clear(FBuffer *fb)
{
    fb->len = 0;
}

static void fbuffer_flush(FBuffer *fb)
{
    rb_io_write(fb->io, rb_utf8_str_new(fb->ptr, fb->len));
    fbuffer_clear(fb);
}

static void fbuffer_realloc(FBuffer *fb, unsigned long required)
{
    if (required > fb->capa) {
        if (fb->type == FBUFFER_STACK_ALLOCATED) {
            const char *old_buffer = fb->ptr;
            fb->ptr = ALLOC_N(char, required);
            fb->type = FBUFFER_HEAP_ALLOCATED;
            MEMCPY(fb->ptr, old_buffer, char, fb->len);
        } else {
            REALLOC_N(fb->ptr, char, required);
        }
        fb->capa = required;
    }
}

static void fbuffer_do_inc_capa(FBuffer *fb, unsigned long requested)
{
    if (RB_UNLIKELY(fb->io)) {
        if (fb->capa < FBUFFER_IO_BUFFER_SIZE) {
            fbuffer_realloc(fb, FBUFFER_IO_BUFFER_SIZE);
        } else {
            fbuffer_flush(fb);
        }

        if (RB_LIKELY(requested < fb->capa)) {
            return;
        }
    }

    unsigned long required;

    if (RB_UNLIKELY(!fb->ptr)) {
        fb->ptr = ALLOC_N(char, fb->initial_length);
        fb->capa = fb->initial_length;
    }

    for (required = fb->capa; requested > required - fb->len; required <<= 1);

    fbuffer_realloc(fb, required);
}

static inline void fbuffer_inc_capa(FBuffer *fb, unsigned long requested)
{
#ifdef JSON_DEBUG
    fb->requested = requested;
#endif

    if (RB_UNLIKELY(requested > fb->capa - fb->len)) {
        fbuffer_do_inc_capa(fb, requested);
    }
}

static void fbuffer_append(FBuffer *fb, const char *newstr, unsigned long len)
{
    if (len > 0) {
        fbuffer_inc_capa(fb, len);
        MEMCPY(fb->ptr + fb->len, newstr, char, len);
        fbuffer_consumed(fb, len);
    }
}

/* Appends a character into a buffer. The buffer needs to have sufficient capacity, via fbuffer_inc_capa(...). */
static inline void fbuffer_append_reserved_char(FBuffer *fb, char chr)
{
#ifdef JSON_DEBUG
    if (fb->requested < 1) {
        rb_bug("fbuffer: unreserved write");
    }
    fb->requested--;
#endif

    fb->ptr[fb->len] = chr;
    fb->len++;
}

static void fbuffer_append_str(FBuffer *fb, VALUE str)
{
    const char *newstr = StringValuePtr(str);
    unsigned long len = RSTRING_LEN(str);

    RB_GC_GUARD(str);

    fbuffer_append(fb, newstr, len);
}

static inline void fbuffer_append_char(FBuffer *fb, char newchr)
{
    fbuffer_inc_capa(fb, 1);
    *(fb->ptr + fb->len) = newchr;
    fbuffer_consumed(fb, 1);
}

static inline char *fbuffer_cursor(FBuffer *fb)
{
    return fb->ptr + fb->len;
}

static inline void fbuffer_advance_to(FBuffer *fb, char *end)
{
    fbuffer_consumed(fb, (end - fb->ptr) - fb->len);
}

/*
 * Appends the decimal string representation of \a number into the buffer.
 */
static void fbuffer_append_long(FBuffer *fb, long number)
{
    /*
     * The jeaiii_ultoa() function produces digits left-to-right,
     * allowing us to write directly into the buffer, but we don't know
     * the number of resulting characters.
     *
     * We do know, however, that the `number` argument is always in the
     * range 0xc000000000000000 to 0x3fffffffffffffff, or, in decimal,
     * -4611686018427387904 to 4611686018427387903. The max number of chars
     * generated is therefore 20 (including a potential sign character).
     */

    static const int MAX_CHARS_FOR_LONG = 20;

    fbuffer_inc_capa(fb, MAX_CHARS_FOR_LONG);

    if (number < 0) {
        fbuffer_append_reserved_char(fb, '-');

        /*
         * Since number is always > LONG_MIN, `-number` will not overflow
         * and is always the positive abs() value.
         */
        number = -number;
    }

    char *end = jeaiii_ultoa(fbuffer_cursor(fb), number);
    fbuffer_advance_to(fb, end);
}

static VALUE fbuffer_finalize(FBuffer *fb)
{
    if (fb->io) {
        fbuffer_flush(fb);
        fbuffer_free(fb);
        rb_io_flush(fb->io);
        return fb->io;
    } else {
        VALUE result = rb_utf8_str_new(FBUFFER_PTR(fb), FBUFFER_LEN(fb));
        fbuffer_free(fb);
        return result;
    }
}

#endif
