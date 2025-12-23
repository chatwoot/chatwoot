#ifndef INTERNAL_SANITIZERS_H                            /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_SANITIZERS_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for ASAN / MSAN / etc.
 */
#include "ruby/internal/config.h"
#include "internal/compilers.h" /* for __has_feature */

#ifdef HAVE_VALGRIND_MEMCHECK_H
# include <valgrind/memcheck.h>
#endif

#ifdef HAVE_SANITIZER_ASAN_INTERFACE_H
# include <sanitizer/asan_interface.h>
#endif

#ifdef HAVE_SANITIZER_MSAN_INTERFACE_H
# if __has_feature(memory_sanitizer)
#  include <sanitizer/msan_interface.h>
# endif
#endif

#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/ruby.h"          /* for VALUE */

#if 0
#elif __has_feature(memory_sanitizer) && __has_feature(address_sanitizer)
# define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) \
    __attribute__((__no_sanitize__("memory, address"), __noinline__)) x
#elif __has_feature(address_sanitizer)
# define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) \
    __attribute__((__no_sanitize__("address"), __noinline__)) x
#elif defined(NO_SANITIZE_ADDRESS)
# define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) \
    NO_SANITIZE_ADDRESS(NOINLINE(x))
#elif defined(NO_ADDRESS_SAFETY_ANALYSIS)
# define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) \
    NO_ADDRESS_SAFETY_ANALYSIS(NOINLINE(x))
#else
# define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) x
#endif

#if defined(NO_SANITIZE) && RBIMPL_COMPILER_IS(GCC)
/* GCC warns about unknown sanitizer, which is annoying. */
# include "internal/warnings.h"
# undef NO_SANITIZE
# define NO_SANITIZE(x, y) \
    COMPILER_WARNING_PUSH; \
    COMPILER_WARNING_IGNORED(-Wattributes); \
    __attribute__((__no_sanitize__(x))) y; \
    COMPILER_WARNING_POP
#endif

#ifndef NO_SANITIZE
# define NO_SANITIZE(x, y) y
#endif

#if !__has_feature(address_sanitizer)
# define __asan_poison_memory_region(x, y)
# define __asan_unpoison_memory_region(x, y)
# define __asan_region_is_poisoned(x, y) 0
#endif

#if !__has_feature(memory_sanitizer)
# define __msan_allocated_memory(x, y) ((void)(x), (void)(y))
# define __msan_poison(x, y) ((void)(x), (void)(y))
# define __msan_unpoison(x, y) ((void)(x), (void)(y))
# define __msan_unpoison_string(x) ((void)(x))
#endif

#ifdef VALGRIND_MAKE_READABLE
# define VALGRIND_MAKE_MEM_DEFINED(p, n) VALGRIND_MAKE_READABLE((p), (n))
#endif

#ifdef VALGRIND_MAKE_WRITABLE
# define VALGRIND_MAKE_MEM_UNDEFINED(p, n) VALGRIND_MAKE_WRITABLE((p), (n))
#endif

#ifndef VALGRIND_MAKE_MEM_DEFINED
# define VALGRIND_MAKE_MEM_DEFINED(p, n) 0
#endif

#ifndef VALGRIND_MAKE_MEM_UNDEFINED
# define VALGRIND_MAKE_MEM_UNDEFINED(p, n) 0
#endif

/*!
 * This function asserts that a (continuous) memory region from ptr to size
 * being "poisoned".  Both read / write access to such memory region are
 * prohibited until properly unpoisoned.  The region must be previously
 * allocated (do not pass a freed pointer here), but not necessarily be an
 * entire object that the malloc returns.  You can punch hole a part of a
 * gigantic heap arena.  This is handy when you do not free an allocated memory
 * region to reuse later: poison when you keep it unused, and unpoison when you
 * reuse.
 *
 * \param[in]  ptr   pointer to the beginning of the memory region to poison.
 * \param[in]  size  the length of the memory region to poison.
 */
static inline void
asan_poison_memory_region(const volatile void *ptr, size_t size)
{
    __msan_poison(ptr, size);
    __asan_poison_memory_region(ptr, size);
}

/*!
 * This is a variant of asan_poison_memory_region that takes a VALUE.
 *
 * \param[in]  obj   target object.
 */
static inline void
asan_poison_object(VALUE obj)
{
    MAYBE_UNUSED(struct RVALUE *) ptr = (void *)obj;
    asan_poison_memory_region(ptr, SIZEOF_VALUE);
}

#if !__has_feature(address_sanitizer)
#define asan_poison_object_if(ptr, obj) ((void)(ptr), (void)(obj))
#else
#define asan_poison_object_if(ptr, obj) do { \
        if (ptr) asan_poison_object(obj); \
    } while (0)
#endif

/*!
 * This function predicates if the given object is fully addressable or not.
 *
 * \param[in]  obj        target object.
 * \retval     0          the given object is fully addressable.
 * \retval     otherwise  pointer to first such byte who is poisoned.
 */
static inline void *
asan_poisoned_object_p(VALUE obj)
{
    MAYBE_UNUSED(struct RVALUE *) ptr = (void *)obj;
    return __asan_region_is_poisoned(ptr, SIZEOF_VALUE);
}

/*!
 * This function asserts that a (formally poisoned) memory region from ptr to
 * size is now addressable.  Write access to such memory region gets allowed.
 * However read access might or might not be possible depending on situations,
 * because the region can have contents of previous usages.  That information
 * should be passed by the malloc_p flag.  If that is true, the contents of the
 * region is _not_ fully defined (like the return value of malloc behaves).
 * Reading from there is NG; write something first.  If malloc_p is false on
 * the other hand, that memory region is fully defined and can be read
 * immediately.
 *
 * \param[in]  ptr       pointer to the beginning of the memory region to unpoison.
 * \param[in]  size      the length of the memory region.
 * \param[in]  malloc_p  if the memory region is like a malloc's return value or not.
 */
static inline void
asan_unpoison_memory_region(const volatile void *ptr, size_t size, bool malloc_p)
{
    __asan_unpoison_memory_region(ptr, size);
    if (malloc_p) {
        __msan_allocated_memory(ptr, size);
    }
    else {
        __msan_unpoison(ptr, size);
    }
}

/*!
 * This is a variant of asan_unpoison_memory_region that takes a VALUE.
 *
 * \param[in]  obj       target object.
 * \param[in]  malloc_p  if the memory region is like a malloc's return value or not.
 */
static inline void
asan_unpoison_object(VALUE obj, bool newobj_p)
{
    MAYBE_UNUSED(struct RVALUE *) ptr = (void *)obj;
    asan_unpoison_memory_region(ptr, SIZEOF_VALUE, newobj_p);
}

#endif /* INTERNAL_SANITIZERS_H */
