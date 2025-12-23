#ifndef INTERNAL_COMPILERS_H                             /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_COMPILERS_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header absorbing C compiler differences.
 */
#include "ruby/internal/compiler_since.h"
#include "ruby/internal/has/attribute.h"
#include "ruby/internal/has/builtin.h"
#include "ruby/internal/has/c_attribute.h"
#include "ruby/internal/has/declspec_attribute.h"
#include "ruby/internal/has/extension.h"
#include "ruby/internal/has/feature.h"
#include "ruby/internal/has/warning.h"
#include "ruby/backward/2/gcc_version_since.h"

#define MSC_VERSION_SINCE(_)   RBIMPL_COMPILER_SINCE(MSVC, (_) / 100, (_) % 100, 0)
#define MSC_VERSION_BEFORE(_)  RBIMPL_COMPILER_BEFORE(MSVC, (_) / 100, (_) % 100, 0)

#ifndef __has_attribute
# define __has_attribute(...) RBIMPL_HAS_ATTRIBUTE(__VA_ARGS__)
#endif

#ifndef __has_c_attribute
# /* As  of writing  everything  that lacks  __has_c_attribute also  completely
#  * lacks C2x attributes as well.  Might change in future? */
# define __has_c_attribute(...) 0
#endif

#ifndef __has_declspec_attribute
# define __has_declspec_attribute(...) RBIMPL_HAS_DECLSPEC_ATTRIBUTE(__VA_ARGS__)
#endif

#ifndef __has_builtin
# define __has_builtin(...) RBIMPL_HAS_BUILTIN(__VA_ARGS__)
#endif

#ifndef __has_feature
# define __has_feature(...) RBIMPL_HAS_FEATURE(__VA_ARGS__)
#endif

#ifndef __has_extension
# define __has_extension(...) RBIMPL_HAS_EXTENSION(__VA_ARGS__)
#endif

#ifndef __has_warning
# define __has_warning(...) RBIMPL_HAS_WARNING(__VA_ARGS__)
#endif

#ifndef __GNUC__
# define __extension__ /* void */
#endif

#ifndef MAYBE_UNUSED
# define MAYBE_UNUSED(x) x
#endif

#ifndef WARN_UNUSED_RESULT
# define WARN_UNUSED_RESULT(x) x
#endif

#define RB_OBJ_BUILTIN_TYPE(obj) rb_obj_builtin_type(obj)
#define OBJ_BUILTIN_TYPE(obj) RB_OBJ_BUILTIN_TYPE(obj)
#ifdef __GNUC__
#define rb_obj_builtin_type(obj) \
__extension__({ \
    VALUE arg_obj = (obj); \
    RB_SPECIAL_CONST_P(arg_obj) ? -1 : \
        (int)RB_BUILTIN_TYPE(arg_obj);    \
    })
#else
# include "ruby/ruby.h"
static inline int
rb_obj_builtin_type(VALUE obj)
{
    return RB_SPECIAL_CONST_P(obj) ? -1 :
        (int)RB_BUILTIN_TYPE(obj);
}
#endif

/* A macro for defining a flexible array, like: VALUE ary[FLEX_ARY_LEN]; */
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L)
# define FLEX_ARY_LEN   /* VALUE ary[]; */
#elif defined(__GNUC__) && !defined(__STRICT_ANSI__)
# define FLEX_ARY_LEN 0 /* VALUE ary[0]; */
#else
# define FLEX_ARY_LEN 1 /* VALUE ary[1]; */
#endif

/*
 * For declaring bitfields out of non-unsigned int types:
 *   struct date {
 *      BITFIELD(enum months, month, 4);
 *      ...
 *   };
 */
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L)
# define BITFIELD(type, name, size) type name : size
#else
# define BITFIELD(type, name, size) unsigned int name : size
#endif

#endif /* INTERNAL_COMPILERS_H */
