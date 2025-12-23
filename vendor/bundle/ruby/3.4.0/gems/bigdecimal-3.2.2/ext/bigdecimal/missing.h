#ifndef MISSING_H
#define MISSING_H 1

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

#ifdef HAVE_STDLIB_H
# include <stdlib.h>
#endif

#ifdef HAVE_MATH_H
# include <math.h>
#endif

#ifndef RB_UNUSED_VAR
# if defined(_MSC_VER) && _MSC_VER >= 1911
#  define RB_UNUSED_VAR(x) x [[maybe_unused]]

# elif defined(__has_cpp_attribute) && __has_cpp_attribute(maybe_unused)
#  define RB_UNUSED_VAR(x) x [[maybe_unused]]

# elif defined(__has_c_attribute) && __has_c_attribute(maybe_unused)
#  define RB_UNUSED_VAR(x) x [[maybe_unused]]

# elif defined(__GNUC__)
#  define RB_UNUSED_VAR(x) x __attribute__ ((unused))

# else
#  define RB_UNUSED_VAR(x) x
# endif
#endif /* RB_UNUSED_VAR */

#if defined(_MSC_VER) && _MSC_VER >= 1310
# define HAVE___ASSUME 1

#elif defined(__INTEL_COMPILER) && __INTEL_COMPILER >= 1300
# define HAVE___ASSUME 1
#endif

#ifndef UNREACHABLE
# if __has_builtin(__builtin_unreachable)
#  define UNREACHABLE __builtin_unreachable()

# elif defined(HAVE___ASSUME)
#  define UNREACHABLE __assume(0)

# else
#  define UNREACHABLE		/* unreachable */
# endif
#endif /* UNREACHABLE */

/* bool */

#if defined(__bool_true_false_are_defined)
# /* Take that. */

#elif defined(HAVE_STDBOOL_H)
# include <stdbool.h>

#else
typedef unsigned char _Bool;
# define bool _Bool
# define true  ((_Bool)+1)
# define false ((_Bool)-1)
# define __bool_true_false_are_defined
#endif

/* abs */

#ifndef HAVE_LABS
static inline long
labs(long const x)
{
    if (x < 0) return -x;
    return x;
}
#endif

#ifndef HAVE_LLABS
static inline LONG_LONG
llabs(LONG_LONG const x)
{
    if (x < 0) return -x;
    return x;
}
#endif

#ifdef vabs
# undef vabs
#endif
#if SIZEOF_VALUE <= SIZEOF_INT
# define vabs abs
#elif SIZEOF_VALUE <= SIZEOF_LONG
# define vabs labs
#elif SIZEOF_VALUE <= SIZEOF_LONG_LONG
# define vabs llabs
#endif

/* finite */

#ifndef HAVE_FINITE
static int
finite(double)
{
    return !isnan(n) && !isinf(n);
}
#endif

#ifndef isfinite
# ifndef HAVE_ISFINITE
#  define HAVE_ISFINITE 1
#  define isfinite(x) finite(x)
# endif
#endif

/* dtoa */
char *BigDecimal_dtoa(double d_, int mode, int ndigits, int *decpt, int *sign, char **rve);

/* rational */

#ifndef HAVE_RB_RATIONAL_NUM
static inline VALUE
rb_rational_num(VALUE rat)
{
#ifdef RRATIONAL
    return RRATIONAL(rat)->num;
#else
    return rb_funcall(rat, rb_intern("numerator"), 0);
#endif
}
#endif

#ifndef HAVE_RB_RATIONAL_DEN
static inline VALUE
rb_rational_den(VALUE rat)
{
#ifdef RRATIONAL
    return RRATIONAL(rat)->den;
#else
    return rb_funcall(rat, rb_intern("denominator"), 0);
#endif
}
#endif

/* complex */

#ifndef HAVE_RB_COMPLEX_REAL
static inline VALUE
rb_complex_real(VALUE cmp)
{
#ifdef RCOMPLEX
  return RCOMPLEX(cmp)->real;
#else
  return rb_funcall(cmp, rb_intern("real"), 0);
#endif
}
#endif

#ifndef HAVE_RB_COMPLEX_IMAG
static inline VALUE
rb_complex_imag(VALUE cmp)
{
# ifdef RCOMPLEX
  return RCOMPLEX(cmp)->imag;
# else
  return rb_funcall(cmp, rb_intern("imag"), 0);
# endif
}
#endif

/* st */

#ifndef ST2FIX
# undef RB_ST2FIX
# define RB_ST2FIX(h) LONG2FIX((long)(h))
# define ST2FIX(h) RB_ST2FIX(h)
#endif

/* warning */

#if !defined(HAVE_RB_CATEGORY_WARN) || !defined(HAVE_CONST_RB_WARN_CATEGORY_DEPRECATED)
#   define rb_category_warn(category, ...) rb_warn(__VA_ARGS__)
#endif

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
}  /* extern "C" { */
#endif

#endif /* MISSING_H */
