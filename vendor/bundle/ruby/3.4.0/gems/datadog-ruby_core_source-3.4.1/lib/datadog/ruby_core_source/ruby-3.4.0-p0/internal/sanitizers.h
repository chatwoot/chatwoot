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
# if __has_feature(address_sanitizer) || defined(__SANITIZE_ADDRESS__)
#  define RUBY_ASAN_ENABLED
#  include <sanitizer/asan_interface.h>
# endif
#endif

#ifdef HAVE_SANITIZER_MSAN_INTERFACE_H
# if __has_feature(memory_sanitizer)
#  define RUBY_MSAN_ENABLED
#  include <sanitizer/msan_interface.h>
# endif
#endif

#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/ruby.h"          /* for VALUE */

#if 0
#elif defined(RUBY_ASAN_ENABLED) && defined(RUBY_MSAN_ENABLED)
# define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) \
    __attribute__((__no_sanitize__("memory, address"), __noinline__)) x
#elif defined(RUBY_ASAN_ENABLED)
# define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) \
    __attribute__((__no_sanitize__("address"), __noinline__)) x
#elif defined(RUBY_MSAN_ENABLED)
    # define ATTRIBUTE_NO_ADDRESS_SAFETY_ANALYSIS(x) \
    __attribute__((__no_sanitize__("memory"), __noinline__)) x
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
    COMPILER_WARNING_PUSH \
    COMPILER_WARNING_IGNORED(-Wattributes) \
    __attribute__((__no_sanitize__(x))) y; \
    COMPILER_WARNING_POP \
    y
#endif

#ifndef NO_SANITIZE
# define NO_SANITIZE(x, y) y
#endif

#ifndef RUBY_ASAN_ENABLED
# define __asan_poison_memory_region(x, y)
# define __asan_unpoison_memory_region(x, y)
# define __asan_region_is_poisoned(x, y) 0
# define __asan_get_current_fake_stack() NULL
# define __asan_addr_is_in_fake_stack(fake_stack, slot, start, end) NULL
#endif

#ifndef RUBY_MSAN_ENABLED
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

/**
 * This function asserts that a (continuous) memory region from ptr to size
 * being "poisoned".  Both read / write access to such memory region are
 * prohibited until properly unpoisoned.  The region must be previously
 * allocated (do not pass a freed pointer here), but not necessarily be an
 * entire object that the malloc returns.  You can punch hole a part of a
 * gigantic heap arena.  This is handy when you do not free an allocated memory
 * region to reuse later: poison when you keep it unused, and unpoison when you
 * reuse.
 *
 * @param[in]  ptr   pointer to the beginning of the memory region to poison.
 * @param[in]  size  the length of the memory region to poison.
 */
static inline void
asan_poison_memory_region(const volatile void *ptr, size_t size)
{
    __msan_poison(ptr, size);
    __asan_poison_memory_region(ptr, size);
}

#ifdef RUBY_ASAN_ENABLED
#define asan_poison_object_if(ptr, obj) do { \
        if (ptr) rb_asan_poison_object(obj); \
    } while (0)
#else
#define asan_poison_object_if(ptr, obj) ((void)(ptr), (void)(obj))
#endif

RUBY_SYMBOL_EXPORT_BEGIN
/**
 * This is a variant of asan_poison_memory_region that takes a VALUE.
 *
 * @param[in]  obj   target object.
 */
void rb_asan_poison_object(VALUE obj);

/**
 * This function predicates if the given object is fully addressable or not.
 *
 * @param[in]  obj        target object.
 * @retval     0          the given object is fully addressable.
 * @retval     otherwise  pointer to first such byte who is poisoned.
 */
void *rb_asan_poisoned_object_p(VALUE obj);

/**
 * This is a variant of asan_unpoison_memory_region that takes a VALUE.
 *
 * @param[in]  obj       target object.
 * @param[in]  malloc_p  if the memory region is like a malloc's return value or not.
 */
void rb_asan_unpoison_object(VALUE obj, bool newobj_p);

RUBY_SYMBOL_EXPORT_END

/**
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
 * @param[in]  ptr       pointer to the beginning of the memory region to unpoison.
 * @param[in]  size      the length of the memory region.
 * @param[in]  malloc_p  if the memory region is like a malloc's return value or not.
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

static inline void *
asan_unpoison_object_temporary(VALUE obj)
{
    void *ptr = rb_asan_poisoned_object_p(obj);
    rb_asan_unpoison_object(obj, false);
    return ptr;
}

static inline void *
asan_poison_object_restore(VALUE obj, void *ptr)
{
    if (ptr) {
        rb_asan_poison_object(obj);
    }
    return NULL;
}

#define asan_unpoisoning_object(obj) \
    for (void *poisoned = asan_unpoison_object_temporary(obj), \
              *unpoisoning = &poisoned; /* flag to loop just once */ \
         unpoisoning; \
         unpoisoning = asan_poison_object_restore(obj, poisoned))


static inline void *
asan_unpoison_memory_region_temporary(void *ptr, size_t len)
{
    void *poisoned_ptr = __asan_region_is_poisoned(ptr, len);
    asan_unpoison_memory_region(ptr, len, false);
    return poisoned_ptr;
}

static inline void *
asan_poison_memory_region_restore(void *ptr, size_t len, void *poisoned_ptr)
{
    if (poisoned_ptr) {
        asan_poison_memory_region(ptr, len);
    }
    return NULL;
}

#define asan_unpoisoning_memory_region(ptr, len) \
    for (void *poisoned = asan_unpoison_memory_region_temporary(ptr, len), \
              *unpoisoning = &poisoned; /* flag to loop just once */ \
         unpoisoning; \
         unpoisoning = asan_poison_memory_region_restore(ptr, len, poisoned))

/**
 * Checks if the given pointer is on an ASAN fake stack. If so, it returns the
 * address this variable has on the real frame; if not, it returns the origin
 * address unmodified.
 *
 * n.b. - _dereferencing_ the returned address is meaningless and should not
 * be done; even though ASAN reserves space for the variable in both the real and
 * fake stacks, the _value_ of that variable is only in the fake stack.
 *
 * n.b. - this only works for addresses passed in from local variables on the same
 * thread, because the ASAN fake stacks are threadlocal.
 *
 * @param[in] slot  the address of some local variable
 * @retval          a pointer to something from that frame on the _real_ machine stack
 */
static inline void *
asan_get_real_stack_addr(void* slot)
{
    VALUE *addr;
    addr = __asan_addr_is_in_fake_stack(__asan_get_current_fake_stack(), slot, NULL, NULL);
    return addr ? addr : slot;
}

/**
 * Gets the current thread's fake stack handle, which can be passed into get_fake_stack_extents
 *
 * @retval An opaque value which can be passed to asan_get_fake_stack_extents
 */
static inline void *
asan_get_thread_fake_stack_handle(void)
{
    return __asan_get_current_fake_stack();
}

/**
 * Checks if the given VALUE _actually_ represents a pointer to an ASAN fake stack.
 *
 * If the given slot _is_ actually a reference to an ASAN fake stack, and that fake stack
 * contains the real values for the passed-in range of machine stack addresses, returns true
 * and the range of the fake stack through the outparams.
 *
 * Otherwise, returns false, and sets the outparams to NULL.
 *
 * Note that this function expects "start" to be > "end" on downward-growing stack architectures;
 *
 * @param[in]  thread_fake_stack_handle  The asan fake stack reference for the thread we're scanning
 * @param[in]  slot                      The value on the machine stack we want to inspect
 * @param[in]  machine_stack_start       The extents of the real machine stack on which slot lives
 * @param[in]  machine_stack_end         The extents of the real machine stack on which slot lives
 * @param[out] fake_stack_start_out      The extents of the fake stack which contains real VALUEs
 * @param[out] fake_stack_end_out        The extents of the fake stack which contains real VALUEs
 * @return                               Whether slot is a pointer to a fake stack for the given machine stack range
*/

static inline bool
asan_get_fake_stack_extents(void *thread_fake_stack_handle, VALUE slot,
                            void *machine_stack_start, void *machine_stack_end,
                            void **fake_stack_start_out, void **fake_stack_end_out)
{
    /* the ifdef is needed here to suppress a warning about fake_frame_{start/end} being
       uninitialized if __asan_addr_is_in_fake_stack is an empty macro */
#ifdef RUBY_ASAN_ENABLED
    void *fake_frame_start;
    void *fake_frame_end;
    void *real_stack_frame = __asan_addr_is_in_fake_stack(
        thread_fake_stack_handle, (void *)slot, &fake_frame_start, &fake_frame_end
    );
    if (real_stack_frame) {
        bool in_range;
#if STACK_GROW_DIRECTION < 0
        in_range = machine_stack_start >= real_stack_frame && real_stack_frame >= machine_stack_end;
#else
        in_range = machine_stack_start <= real_stack_frame && real_stack_frame <= machine_stack_end;
#endif
        if (in_range) {
            *fake_stack_start_out = fake_frame_start;
            *fake_stack_end_out = fake_frame_end;
            return true;
        }
    }
#endif
    *fake_stack_start_out = 0;
    *fake_stack_end_out = 0;
    return false;
}


#endif /* INTERNAL_SANITIZERS_H */
