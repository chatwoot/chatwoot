#ifndef INTERNAL_GC_H                                    /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_GC_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for GC.
 */
#include "ruby/internal/config.h"

#include <stddef.h>             /* for size_t */

#include "internal/compilers.h" /* for __has_attribute */
#include "ruby/ruby.h"          /* for rb_event_flag_t */
#include "vm_core.h"            /* for GET_EC() */

#if defined(__x86_64__) && !defined(_ILP32) && defined(__GNUC__)
#define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("movq\t%%rsp, %0" : "=r" (*(p)))
#elif defined(__i386) && defined(__GNUC__)
#define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("movl\t%%esp, %0" : "=r" (*(p)))
#elif (defined(__powerpc__) || defined(__powerpc64__)) && defined(__GNUC__) && !defined(_AIX) && !defined(__APPLE__) // Not Apple is NEEDED to unbreak ppc64 build on Darwin. Don't ask.
#define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("mr\t%0, %%r1" : "=r" (*(p)))
#elif (defined(__powerpc__) || defined(__powerpc64__)) && defined(__GNUC__) && defined(_AIX)
#define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("mr %0,1" : "=r" (*(p)))
#elif defined(__POWERPC__) && defined(__APPLE__) // Darwin ppc and ppc64
#define SET_MACHINE_STACK_END(p) __asm__ volatile("mr %0, r1" : "=r" (*(p)))
#elif defined(__aarch64__) && defined(__GNUC__)
#define SET_MACHINE_STACK_END(p) __asm__ __volatile__ ("mov\t%0, sp" : "=r" (*(p)))
#else
NOINLINE(void rb_gc_set_stack_end(VALUE **stack_end_p));
#define SET_MACHINE_STACK_END(p) rb_gc_set_stack_end(p)
#define USE_CONSERVATIVE_STACK_END
#endif

/* for GC debug */

#ifndef RUBY_MARK_FREE_DEBUG
#define RUBY_MARK_FREE_DEBUG 0
#endif

#if RUBY_MARK_FREE_DEBUG
extern int ruby_gc_debug_indent;

static inline void
rb_gc_debug_indent(void)
{
    ruby_debug_printf("%*s", ruby_gc_debug_indent, "");
}

static inline void
rb_gc_debug_body(const char *mode, const char *msg, int st, void *ptr)
{
    if (st == 0) {
        ruby_gc_debug_indent--;
    }
    rb_gc_debug_indent();
    ruby_debug_printf("%s: %s %s (%p)\n", mode, st ? "->" : "<-", msg, ptr);

    if (st) {
        ruby_gc_debug_indent++;
    }

    fflush(stdout);
}

#define RUBY_MARK_ENTER(msg) rb_gc_debug_body("mark", (msg), 1, ptr)
#define RUBY_MARK_LEAVE(msg) rb_gc_debug_body("mark", (msg), 0, ptr)
#define RUBY_FREE_ENTER(msg) rb_gc_debug_body("free", (msg), 1, ptr)
#define RUBY_FREE_LEAVE(msg) rb_gc_debug_body("free", (msg), 0, ptr)
#define RUBY_GC_INFO         rb_gc_debug_indent(), ruby_debug_printf

#else
#define RUBY_MARK_ENTER(msg)
#define RUBY_MARK_LEAVE(msg)
#define RUBY_FREE_ENTER(msg)
#define RUBY_FREE_LEAVE(msg)
#define RUBY_GC_INFO if(0)printf
#endif

#define RUBY_MARK_MOVABLE_UNLESS_NULL(ptr) do { \
    VALUE markobj = (ptr); \
    if (RTEST(markobj)) {rb_gc_mark_movable(markobj);} \
} while (0)
#define RUBY_MARK_UNLESS_NULL(ptr) do { \
    VALUE markobj = (ptr); \
    if (RTEST(markobj)) {rb_gc_mark(markobj);} \
} while (0)
#define RUBY_FREE_UNLESS_NULL(ptr) if(ptr){ruby_xfree(ptr);(ptr)=NULL;}

#if STACK_GROW_DIRECTION > 0
# define STACK_UPPER(x, a, b) (a)
#elif STACK_GROW_DIRECTION < 0
# define STACK_UPPER(x, a, b) (b)
#else
RUBY_EXTERN int ruby_stack_grow_direction;
int ruby_get_stack_grow_direction(volatile VALUE *addr);
# define stack_growup_p(x) (			\
        (ruby_stack_grow_direction ?		\
         ruby_stack_grow_direction :		\
         ruby_get_stack_grow_direction(x)) > 0)
# define STACK_UPPER(x, a, b) (stack_growup_p(x) ? (a) : (b))
#endif

/*
  STACK_GROW_DIR_DETECTION is used with STACK_DIR_UPPER.

  On most normal systems, stacks grow from high address to lower address. In
  this case, STACK_DIR_UPPER(a, b) will return (b), but on exotic systems where
  the stack grows UP (from low address to high address), it will return (a).
*/

#if STACK_GROW_DIRECTION
#define STACK_GROW_DIR_DETECTION
#define STACK_DIR_UPPER(a,b) STACK_UPPER(0, (a), (b))
#else
#define STACK_GROW_DIR_DETECTION VALUE stack_grow_dir_detection
#define STACK_DIR_UPPER(a,b) STACK_UPPER(&stack_grow_dir_detection, (a), (b))
#endif
#define IS_STACK_DIR_UPPER() STACK_DIR_UPPER(1,0)

const char *rb_obj_info(VALUE obj);
const char *rb_raw_obj_info(char *const buff, const size_t buff_size, VALUE obj);

size_t rb_size_pool_slot_size(unsigned char pool_id);

struct rb_execution_context_struct; /* in vm_core.h */
struct rb_objspace; /* in vm_core.h */

#ifdef NEWOBJ_OF
# undef NEWOBJ_OF
# undef RB_NEWOBJ_OF
#endif

#define NEWOBJ_OF_0(var, T, c, f, s, ec) \
    T *(var) = (T *)(((f) & FL_WB_PROTECTED) ? \
            rb_wb_protected_newobj_of(GET_EC(), (c), (f) & ~FL_WB_PROTECTED, s) : \
            rb_wb_unprotected_newobj_of((c), (f), s))
#define NEWOBJ_OF_ec(var, T, c, f, s, ec) \
    T *(var) = (T *)(((f) & FL_WB_PROTECTED) ? \
            rb_wb_protected_newobj_of((ec), (c), (f) & ~FL_WB_PROTECTED, s) : \
            rb_wb_unprotected_newobj_of((c), (f), s))

#define NEWOBJ_OF(var, T, c, f, s, ec) \
        NEWOBJ_OF_HELPER(ec)(var, T, c, f, s, ec)

#define NEWOBJ_OF_HELPER(ec) NEWOBJ_OF_ ## ec

#define RB_OBJ_GC_FLAGS_MAX 6   /* used in ext/objspace */

#ifndef USE_UNALIGNED_MEMBER_ACCESS
# define UNALIGNED_MEMBER_ACCESS(expr) (expr)
#elif ! USE_UNALIGNED_MEMBER_ACCESS
# define UNALIGNED_MEMBER_ACCESS(expr) (expr)
#elif ! (__has_warning("-Waddress-of-packed-member") || GCC_VERSION_SINCE(9, 0, 0))
# define UNALIGNED_MEMBER_ACCESS(expr) (expr)
#else
# include "internal/warnings.h"
# define UNALIGNED_MEMBER_ACCESS(expr) __extension__({ \
    COMPILER_WARNING_PUSH; \
    COMPILER_WARNING_IGNORED(-Waddress-of-packed-member); \
    __typeof__(expr) unaligned_member_access_result = (expr); \
    COMPILER_WARNING_POP; \
    unaligned_member_access_result; \
})

# define UNALIGNED_MEMBER_PTR(ptr, mem) __extension__({ \
    COMPILER_WARNING_PUSH; \
    COMPILER_WARNING_IGNORED(-Waddress-of-packed-member); \
    const volatile void *unaligned_member_ptr_result = &(ptr)->mem; \
    COMPILER_WARNING_POP; \
    (__typeof__((ptr)->mem) *)unaligned_member_ptr_result; \
})
#endif

#ifndef UNALIGNED_MEMBER_PTR
# define UNALIGNED_MEMBER_PTR(ptr, mem) UNALIGNED_MEMBER_ACCESS(&(ptr)->mem)
#endif

#define RB_OBJ_WRITE_UNALIGNED(old, slot, young) do { \
    VALUE *_slot = UNALIGNED_MEMBER_ACCESS(slot); \
    RB_OBJ_WRITE(old, _slot, young); \
} while (0)

// We use SIZE_POOL_COUNT number of shape IDs for transitions out of different size pools
// The next available shape ID will be the SPECIAL_CONST_SHAPE_ID
#ifndef SIZE_POOL_COUNT
# define SIZE_POOL_COUNT 5
#endif

/* Used in places that could malloc during, which can cause the GC to run. We
 * need to temporarily disable the GC to allow the malloc to happen.
 * Allocating memory during GC is a bad idea, so use this only when absolutely
 * necessary. */
#define DURING_GC_COULD_MALLOC_REGION_START() \
    assert(rb_during_gc()); \
    VALUE _already_disabled = rb_gc_disable_no_rest()

#define DURING_GC_COULD_MALLOC_REGION_END() \
    if (_already_disabled == Qfalse) rb_gc_enable()

typedef struct ractor_newobj_size_pool_cache {
    struct RVALUE *freelist;
    struct heap_page *using_page;
} rb_ractor_newobj_size_pool_cache_t;

typedef struct ractor_newobj_cache {
    size_t incremental_mark_step_allocated_slots;
    rb_ractor_newobj_size_pool_cache_t size_pool_caches[SIZE_POOL_COUNT];
} rb_ractor_newobj_cache_t;

/* gc.c */
extern VALUE *ruby_initial_gc_stress_ptr;
extern int ruby_disable_gc;
RUBY_ATTR_MALLOC void *ruby_mimmalloc(size_t size);
void ruby_mimfree(void *ptr);
void rb_gc_prepare_heap(void);
void rb_objspace_set_event_hook(const rb_event_flag_t event);
VALUE rb_objspace_gc_enable(struct rb_objspace *);
VALUE rb_objspace_gc_disable(struct rb_objspace *);
void ruby_gc_set_params(void);
void rb_copy_wb_protected_attribute(VALUE dest, VALUE obj);
#if __has_attribute(alloc_align)
__attribute__((__alloc_align__(1)))
#endif
RUBY_ATTR_MALLOC void *rb_aligned_malloc(size_t, size_t) RUBY_ATTR_ALLOC_SIZE((2));
size_t rb_size_mul_or_raise(size_t, size_t, VALUE); /* used in compile.c */
size_t rb_size_mul_add_or_raise(size_t, size_t, size_t, VALUE); /* used in iseq.h */
size_t rb_malloc_grow_capa(size_t current_capacity, size_t type_size);
RUBY_ATTR_MALLOC void *rb_xmalloc_mul_add(size_t, size_t, size_t);
RUBY_ATTR_MALLOC void *rb_xcalloc_mul_add(size_t, size_t, size_t);
void *rb_xrealloc_mul_add(const void *, size_t, size_t, size_t);
RUBY_ATTR_MALLOC void *rb_xmalloc_mul_add_mul(size_t, size_t, size_t, size_t);
RUBY_ATTR_MALLOC void *rb_xcalloc_mul_add_mul(size_t, size_t, size_t, size_t);
static inline void *ruby_sized_xrealloc_inlined(void *ptr, size_t new_size, size_t old_size) RUBY_ATTR_RETURNS_NONNULL RUBY_ATTR_ALLOC_SIZE((2));
static inline void *ruby_sized_xrealloc2_inlined(void *ptr, size_t new_count, size_t elemsiz, size_t old_count) RUBY_ATTR_RETURNS_NONNULL RUBY_ATTR_ALLOC_SIZE((2, 3));
static inline void ruby_sized_xfree_inlined(void *ptr, size_t size);
VALUE rb_class_allocate_instance(VALUE klass);
void rb_gc_ractor_newobj_cache_clear(rb_ractor_newobj_cache_t *newobj_cache);
size_t rb_gc_obj_slot_size(VALUE obj);
bool rb_gc_size_allocatable_p(size_t size);
int rb_objspace_garbage_object_p(VALUE obj);
bool rb_gc_is_ptr_to_obj(void *ptr);
VALUE rb_gc_id2ref_obj_tbl(VALUE objid);
VALUE rb_define_finalizer_no_check(VALUE obj, VALUE block);

void rb_gc_mark_and_move(VALUE *ptr);

void rb_gc_mark_weak(VALUE *ptr);
void rb_gc_remove_weak(VALUE parent_obj, VALUE *ptr);

void rb_gc_ref_update_table_values_only(st_table *tbl);

#define rb_gc_mark_and_move_ptr(ptr) do { \
    VALUE _obj = (VALUE)*(ptr); \
    rb_gc_mark_and_move(&_obj); \
    if (_obj != (VALUE)*(ptr)) *(ptr) = (void *)_obj; \
} while (0)

RUBY_SYMBOL_EXPORT_BEGIN
/* exports for objspace module */
size_t rb_objspace_data_type_memsize(VALUE obj);
void rb_objspace_reachable_objects_from(VALUE obj, void (func)(VALUE, void *), void *data);
void rb_objspace_reachable_objects_from_root(void (func)(const char *category, VALUE, void *), void *data);
int rb_objspace_markable_object_p(VALUE obj);
int rb_objspace_internal_object_p(VALUE obj);
int rb_objspace_marked_object_p(VALUE obj);

void rb_objspace_each_objects(
    int (*callback)(void *start, void *end, size_t stride, void *data),
    void *data);

void rb_objspace_each_objects_without_setup(
    int (*callback)(void *, void *, size_t, void *),
    void *data);

size_t rb_gc_obj_slot_size(VALUE obj);

VALUE rb_gc_disable_no_rest(void);


/* gc.c (export) */
const char *rb_objspace_data_type_name(VALUE obj);
VALUE rb_wb_protected_newobj_of(struct rb_execution_context_struct *, VALUE, VALUE, size_t);
VALUE rb_wb_unprotected_newobj_of(VALUE, VALUE, size_t);
size_t rb_obj_memsize_of(VALUE);
void rb_gc_verify_internal_consistency(void);
size_t rb_obj_gc_flags(VALUE, ID[], size_t);
void rb_gc_mark_values(long n, const VALUE *values);
void rb_gc_mark_vm_stack_values(long n, const VALUE *values);
void rb_gc_update_values(long n, VALUE *values);
void *ruby_sized_xrealloc(void *ptr, size_t new_size, size_t old_size) RUBY_ATTR_RETURNS_NONNULL RUBY_ATTR_ALLOC_SIZE((2));
void *ruby_sized_xrealloc2(void *ptr, size_t new_count, size_t element_size, size_t old_count) RUBY_ATTR_RETURNS_NONNULL RUBY_ATTR_ALLOC_SIZE((2, 3));
void ruby_sized_xfree(void *x, size_t size);
RUBY_SYMBOL_EXPORT_END

int rb_ec_stack_check(struct rb_execution_context_struct *ec);
void rb_gc_writebarrier_remember(VALUE obj);
const char *rb_obj_info(VALUE obj);

#if defined(HAVE_MALLOC_USABLE_SIZE) || defined(HAVE_MALLOC_SIZE) || defined(_WIN32)

static inline void *
ruby_sized_xrealloc_inlined(void *ptr, size_t new_size, size_t old_size)
{
    return ruby_xrealloc(ptr, new_size);
}

static inline void *
ruby_sized_xrealloc2_inlined(void *ptr, size_t new_count, size_t elemsiz, size_t old_count)
{
    return ruby_xrealloc2(ptr, new_count, elemsiz);
}

static inline void
ruby_sized_xfree_inlined(void *ptr, size_t size)
{
    ruby_xfree(ptr);
}

# define SIZED_REALLOC_N(x, y, z, w) REALLOC_N(x, y, z)

static inline void *
ruby_sized_realloc_n(void *ptr, size_t new_count, size_t element_size, size_t old_count)
{
    return ruby_xrealloc2(ptr, new_count, element_size);
}

#else

static inline void *
ruby_sized_xrealloc_inlined(void *ptr, size_t new_size, size_t old_size)
{
    return ruby_sized_xrealloc(ptr, new_size, old_size);
}

static inline void *
ruby_sized_xrealloc2_inlined(void *ptr, size_t new_count, size_t elemsiz, size_t old_count)
{
    return ruby_sized_xrealloc2(ptr, new_count, elemsiz, old_count);
}

static inline void
ruby_sized_xfree_inlined(void *ptr, size_t size)
{
    ruby_sized_xfree(ptr, size);
}

# define SIZED_REALLOC_N(v, T, m, n) \
    ((v) = (T *)ruby_sized_xrealloc2((void *)(v), (m), sizeof(T), (n)))

static inline void *
ruby_sized_realloc_n(void *ptr, size_t new_count, size_t element_size, size_t old_count)
{
    return ruby_sized_xrealloc2(ptr, new_count, element_size, old_count);
}

#endif /* HAVE_MALLOC_USABLE_SIZE */

#define ruby_sized_xrealloc ruby_sized_xrealloc_inlined
#define ruby_sized_xrealloc2 ruby_sized_xrealloc2_inlined
#define ruby_sized_xfree ruby_sized_xfree_inlined
#endif /* INTERNAL_GC_H */
