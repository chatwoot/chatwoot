#include <ruby/ruby.h>

#ifdef HAVE_RUBY_ATOMIC_H
# include <ruby/atomic.h>
#endif

#ifdef RUBY_ATOMIC_PTR_CAS
# define ATOMIC_PTR_CAS(var, old, new) RUBY_ATOMIC_PTR_CAS(var, old, new)
#endif

#if defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 6))
/* GCC warns about unknown sanitizer, which is annoying. */
# undef NO_SANITIZE
# define NO_SANITIZE(x, y) \
    _Pragma("GCC diagnostic push") \
    _Pragma("GCC diagnostic ignored \"-Wattributes\"") \
    __attribute__((__no_sanitize__(x))) y; \
    _Pragma("GCC diagnostic pop") \
    y
#endif

#undef strtod
#define strtod BigDecimal_strtod
#undef dtoa
#define dtoa BigDecimal_dtoa
#undef hdtoa
#define hdtoa BigDecimal_hdtoa
#include "missing/dtoa.c"
