#ifndef BIGDECIMAL_HAS_FEATURE_H
#define BIGDECIMAL_HAS_FEATURE_H

/* ======== __has_feature ======== */

#ifndef __has_feature
# define __has_feature(_) 0
#endif

/* ======== __has_extension ======== */

#ifndef __has_extension
# define __has_extension __has_feature
#endif

/* ======== __has_builtin ======== */

#ifdef HAVE_RUBY_INTERNAL_HAS_BUILTIN_H
# include <ruby/internal/has/builtin.h>
#endif

#ifdef RBIMPL_HAS_BUILTIN
# define BIGDECIMAL_HAS_BUILTIN(...) RBIMPL_HAS_BUILTIN(__VA_ARGS__)

#else
# /* The following section is copied from CRuby's builtin.h */
#
# ifdef __has_builtin
#  if defined(__INTEL_COMPILER)
#  /* :TODO: Intel  C Compiler  has __has_builtin (since  19.1 maybe?),  and is
#   * reportedly  broken.  We  have to  skip them.   However the  situation can
#   * change.  They might improve someday.  We need to revisit here later. */
#  elif defined(__GNUC__) && ! __has_builtin(__builtin_alloca)
#  /* FreeBSD's   <sys/cdefs.h>   defines   its   own   *broken*   version   of
#   * __has_builtin.   Cygwin  copied  that  content  to be  a  victim  of  the
#   * broken-ness.  We don't take them into account. */
#  else
#   define HAVE___HAS_BUILTIN 1
#  endif
# endif
#
# if defined(HAVE___HAS_BUILTIN)
#  define BIGDECIMAL_HAS_BUILTIN(_) __has_builtin(_)
#
# elif defined(__GNUC__)
#  define BIGDECIMAL_HAS_BUILTIN(_) BIGDECIMAL_HAS_BUILTIN_ ## _
#  if defined(__GNUC__) && (__GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 6))
#   define BIGDECIMAL_HAS_BUILTIN___builtin_clz  1
#   define BIGDECIMAL_HAS_BUILTIN___builtin_clzl 1
#  else
#   define BIGDECIMAL_HAS_BUILTIN___builtin_clz  0
#   define BIGDECIMAL_HAS_BUILTIN___builtin_clzl 0
#  endif
# elif defined(_MSC_VER)
#  define BIGDECIMAL_HAS_BUILTIN(_) 0
#
# else
#  define BIGDECIMAL_HAS_BUILTIN(_) BIGDECIMAL_HAS_BUILTIN_ ## _
#  define BIGDECIMAL_HAS_BUILTIN___builtin_clz   HAVE_BUILTIN___BUILTIN_CLZ
#  define BIGDECIMAL_HAS_BUILTIN___builtin_clzl  HAVE_BUILTIN___BUILTIN_CLZL
# endif
#endif /* RBIMPL_HAS_BUILTIN */

#ifndef __has_builtin
# define __has_builtin(...) BIGDECIMAL_HAS_BUILTIN(__VA_ARGS__)
#endif

#endif /* BIGDECIMAL_HAS_FEATURE_H */
