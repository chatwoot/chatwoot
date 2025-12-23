#ifndef BIGDECIMAL_STATIC_ASSERT_H
#define BIGDECIMAL_STATIC_ASSERT_H

#include "feature.h"

#ifdef HAVE_RUBY_INTERNAL_STATIC_ASSERT_H
# include <ruby/internal/static_assert.h>
#endif

#ifdef RBIMPL_STATIC_ASSERT
# define STATIC_ASSERT RBIMPL_STATIC_ASSERT
#endif

#ifndef STATIC_ASSERT
# /* The following section is copied from CRuby's static_assert.h */

# if defined(__cplusplus) && defined(__cpp_static_assert)
#  /* https://isocpp.org/std/standing-documents/sd-6-sg10-feature-test-recommendations */
#  define BIGDECIMAL_STATIC_ASSERT0 static_assert

# elif defined(__cplusplus) && defined(_MSC_VER) && _MSC_VER >= 1600
#  define BIGDECIMAL_STATIC_ASSERT0 static_assert

# elif defined(__INTEL_CXX11_MODE__)
#  define BIGDECIMAL_STATIC_ASSERT0 static_assert

# elif defined(__cplusplus) && __cplusplus >= 201103L
#  define BIGDECIMAL_STATIC_ASSERT0 static_assert

# elif defined(__cplusplus) && __has_extension(cxx_static_assert)
#  define BIGDECIMAL_STATIC_ASSERT0 __extension__ static_assert

# elif defined(__STDC_VERSION__) && __has_extension(c_static_assert)
#  define BIGDECIMAL_STATIC_ASSERT0 __extension__ _Static_assert

# elif defined(__STDC_VERSION__) && defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 6))
#  define BIGDECIMAL_STATIC_ASSERT0 __extension__ _Static_assert
#endif

# if defined(__DOXYGEN__)
#  define STATIC_ASSERT static_assert

# elif defined(BIGDECIMAL_STATIC_ASSERT0)
#  define STATIC_ASSERT(name, expr) \
    BIGDECIMAL_STATIC_ASSERT0(expr, #name ": " #expr)

# else
#  define STATIC_ASSERT(name, expr) \
    typedef int static_assert_ ## name ## _check[1 - 2 * !(expr)]
# endif
#endif /* STATIC_ASSERT */


#endif /* BIGDECIMAL_STATIC_ASSERT_H */
