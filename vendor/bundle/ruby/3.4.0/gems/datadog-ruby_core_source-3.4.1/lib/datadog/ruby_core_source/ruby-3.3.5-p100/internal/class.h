#ifndef INTERNAL_CLASS_H                                 /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_CLASS_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Class.
 */
#include "id.h"
#include "id_table.h"           /* for struct rb_id_table */
#include "internal/serial.h"    /* for rb_serial_t */
#include "internal/static_assert.h"
#include "internal/variable.h"  /* for rb_class_ivar_set */
#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/intern.h"        /* for rb_alloc_func_t */
#include "ruby/ruby.h"          /* for struct RBasic */
#include "shape.h"
#include "ruby_assert.h"
#include "vm_core.h"
#include "vm_sync.h"
#include "method.h"             /* for rb_cref_t */

#ifdef RCLASS_SUPER
# undef RCLASS_SUPER
#endif

struct rb_subclass_entry {
    VALUE klass;
    struct rb_subclass_entry *next;
    struct rb_subclass_entry *prev;
};
typedef struct rb_subclass_entry rb_subclass_entry_t;

struct rb_cvar_class_tbl_entry {
    uint32_t index;
    rb_serial_t global_cvar_state;
    const rb_cref_t * cref;
    VALUE class_value;
};

struct rb_classext_struct {
    VALUE *iv_ptr;
    struct rb_id_table *const_tbl;
    struct rb_id_table *callable_m_tbl;
    struct rb_id_table *cc_tbl; /* ID -> [[ci1, cc1], [ci2, cc2] ...] */
    struct rb_id_table *cvc_tbl;
    size_t superclass_depth;
    VALUE *superclasses;
    struct rb_subclass_entry *subclasses;
    struct rb_subclass_entry *subclass_entry;
    /**
     * In the case that this is an `ICLASS`, `module_subclasses` points to the link
     * in the module's `subclasses` list that indicates that the klass has been
     * included. Hopefully that makes sense.
     */
    struct rb_subclass_entry *module_subclass_entry;
    const VALUE origin_;
    const VALUE refined_class;
    union {
        struct {
            rb_alloc_func_t allocator;
        } class;
        struct {
            VALUE attached_object;
        } singleton_class;
    } as;
    const VALUE includer;
    attr_index_t max_iv_count;
    unsigned char variation_count;
    bool permanent_classpath : 1;
    bool cloned : 1;
    VALUE classpath;
};
typedef struct rb_classext_struct rb_classext_t;

STATIC_ASSERT(shape_max_variations, SHAPE_MAX_VARIATIONS < (1 << (sizeof(((rb_classext_t *)0)->variation_count) * CHAR_BIT)));

struct RClass {
    struct RBasic basic;
    VALUE super;
    struct rb_id_table *m_tbl;
};

// Assert that classes can be embedded in size_pools[2] (which has 160B slot size)
STATIC_ASSERT(sizeof_rb_classext_t, sizeof(struct RClass) + sizeof(rb_classext_t) <= 4 * RVALUE_SIZE);

struct RClass_and_rb_classext_t {
    struct RClass rclass;
    rb_classext_t classext;
};

#define RCLASS_EXT(c) (&((struct RClass_and_rb_classext_t*)(c))->classext)
#define RCLASS_CONST_TBL(c) (RCLASS_EXT(c)->const_tbl)
#define RCLASS_M_TBL(c) (RCLASS(c)->m_tbl)
#define RCLASS_IVPTR(c) (RCLASS_EXT(c)->iv_ptr)
#define RCLASS_CALLABLE_M_TBL(c) (RCLASS_EXT(c)->callable_m_tbl)
#define RCLASS_CC_TBL(c) (RCLASS_EXT(c)->cc_tbl)
#define RCLASS_CVC_TBL(c) (RCLASS_EXT(c)->cvc_tbl)
#define RCLASS_ORIGIN(c) (RCLASS_EXT(c)->origin_)
#define RCLASS_REFINED_CLASS(c) (RCLASS_EXT(c)->refined_class)
#define RCLASS_INCLUDER(c) (RCLASS_EXT(c)->includer)
#define RCLASS_SUBCLASS_ENTRY(c) (RCLASS_EXT(c)->subclass_entry)
#define RCLASS_MODULE_SUBCLASS_ENTRY(c) (RCLASS_EXT(c)->module_subclass_entry)
#define RCLASS_SUBCLASSES(c) (RCLASS_EXT(c)->subclasses)
#define RCLASS_SUPERCLASS_DEPTH(c) (RCLASS_EXT(c)->superclass_depth)
#define RCLASS_SUPERCLASSES(c) (RCLASS_EXT(c)->superclasses)
#define RCLASS_ATTACHED_OBJECT(c) (RCLASS_EXT(c)->as.singleton_class.attached_object)

#define RICLASS_IS_ORIGIN FL_USER0
#define RCLASS_SUPERCLASSES_INCLUDE_SELF FL_USER2
#define RICLASS_ORIGIN_SHARED_MTBL FL_USER3

static inline st_table *
RCLASS_IV_HASH(VALUE obj)
{
    RUBY_ASSERT(RB_TYPE_P(obj, RUBY_T_CLASS) || RB_TYPE_P(obj, RUBY_T_MODULE));
    RUBY_ASSERT(rb_shape_obj_too_complex(obj));
    return (st_table *)RCLASS_IVPTR(obj);
}

static inline void
RCLASS_SET_IV_HASH(VALUE obj, const st_table *tbl)
{
    RUBY_ASSERT(RB_TYPE_P(obj, RUBY_T_CLASS) || RB_TYPE_P(obj, RUBY_T_MODULE));
    RUBY_ASSERT(rb_shape_obj_too_complex(obj));
    RCLASS_IVPTR(obj) = (VALUE *)tbl;
}

static inline uint32_t
RCLASS_IV_COUNT(VALUE obj)
{
    RUBY_ASSERT(RB_TYPE_P(obj, RUBY_T_CLASS) || RB_TYPE_P(obj, RUBY_T_MODULE));
    if (rb_shape_obj_too_complex(obj)) {
        uint32_t count;

        // "Too complex" classes could have their IV hash mutated in
        // parallel, so lets lock around getting the hash size.
        RB_VM_LOCK_ENTER();
        {
            count = (uint32_t)rb_st_table_size(RCLASS_IV_HASH(obj));
        }
        RB_VM_LOCK_LEAVE();

        return count;
    }
    else {
        return rb_shape_get_shape_by_id(RCLASS_SHAPE_ID(obj))->next_iv_index;
    }
}

static inline void
RCLASS_SET_M_TBL(VALUE klass, struct rb_id_table *table)
{
    RUBY_ASSERT(!RB_OBJ_PROMOTED(klass));
    RCLASS_M_TBL(klass) = table;
}

/* class.c */
void rb_class_subclass_add(VALUE super, VALUE klass);
void rb_class_remove_from_super_subclasses(VALUE);
void rb_class_update_superclasses(VALUE);
size_t rb_class_superclasses_memsize(VALUE);
void rb_class_remove_subclass_head(VALUE);
int rb_singleton_class_internal_p(VALUE sklass);
VALUE rb_class_boot(VALUE);
VALUE rb_class_s_alloc(VALUE klass);
VALUE rb_module_s_alloc(VALUE klass);
void rb_module_set_initialized(VALUE module);
void rb_module_check_initializable(VALUE module);
VALUE rb_make_metaclass(VALUE, VALUE);
VALUE rb_include_class_new(VALUE, VALUE);
void rb_class_foreach_subclass(VALUE klass, void (*f)(VALUE, VALUE), VALUE);
void rb_class_detach_subclasses(VALUE);
void rb_class_detach_module_subclasses(VALUE);
void rb_class_remove_from_module_subclasses(VALUE);
VALUE rb_define_class_id_under_no_pin(VALUE outer, ID id, VALUE super);
VALUE rb_obj_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_obj_protected_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_obj_private_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_obj_public_methods(int argc, const VALUE *argv, VALUE obj);
VALUE rb_class_undefined_instance_methods(VALUE mod);
VALUE rb_special_singleton_class(VALUE);
VALUE rb_singleton_class_clone_and_attach(VALUE obj, VALUE attach);
VALUE rb_singleton_class_get(VALUE obj);
void rb_undef_methods_from(VALUE klass, VALUE super);

static inline void RCLASS_SET_ORIGIN(VALUE klass, VALUE origin);
static inline void RICLASS_SET_ORIGIN_SHARED_MTBL(VALUE iclass);
static inline VALUE RCLASS_SUPER(VALUE klass);
static inline VALUE RCLASS_SET_SUPER(VALUE klass, VALUE super);
static inline void RCLASS_SET_INCLUDER(VALUE iclass, VALUE klass);

VALUE rb_class_inherited(VALUE, VALUE);
VALUE rb_keyword_error_new(const char *, VALUE);

static inline rb_alloc_func_t
RCLASS_ALLOCATOR(VALUE klass)
{
    if (FL_TEST_RAW(klass, FL_SINGLETON)) {
        return 0;
    }
    return RCLASS_EXT(klass)->as.class.allocator;
}

static inline void
RCLASS_SET_ALLOCATOR(VALUE klass, rb_alloc_func_t allocator)
{
    assert(!FL_TEST(klass, FL_SINGLETON));
    RCLASS_EXT(klass)->as.class.allocator = allocator;
}

static inline void
RCLASS_SET_ORIGIN(VALUE klass, VALUE origin)
{
    RB_OBJ_WRITE(klass, &RCLASS_ORIGIN(klass), origin);
    if (klass != origin) FL_SET(origin, RICLASS_IS_ORIGIN);
}

static inline void
RICLASS_SET_ORIGIN_SHARED_MTBL(VALUE iclass)
{
    FL_SET(iclass, RICLASS_ORIGIN_SHARED_MTBL);
}

static inline bool
RICLASS_OWNS_M_TBL_P(VALUE iclass)
{
    return FL_TEST_RAW(iclass, RICLASS_IS_ORIGIN | RICLASS_ORIGIN_SHARED_MTBL) == RICLASS_IS_ORIGIN;
}

static inline void
RCLASS_SET_INCLUDER(VALUE iclass, VALUE klass)
{
    RB_OBJ_WRITE(iclass, &RCLASS_INCLUDER(iclass), klass);
}

static inline VALUE
RCLASS_SUPER(VALUE klass)
{
    return RCLASS(klass)->super;
}

static inline VALUE
RCLASS_SET_SUPER(VALUE klass, VALUE super)
{
    if (super) {
        rb_class_remove_from_super_subclasses(klass);
        rb_class_subclass_add(super, klass);
    }
    RB_OBJ_WRITE(klass, &RCLASS(klass)->super, super);
    rb_class_update_superclasses(klass);
    return super;
}

static inline void
RCLASS_SET_CLASSPATH(VALUE klass, VALUE classpath, bool permanent)
{
    assert(BUILTIN_TYPE(klass) == T_CLASS || BUILTIN_TYPE(klass) == T_MODULE);
    assert(classpath == 0 || BUILTIN_TYPE(classpath) == T_STRING);

    RB_OBJ_WRITE(klass, &(RCLASS_EXT(klass)->classpath), classpath);
    RCLASS_EXT(klass)->permanent_classpath = permanent;
}

static inline VALUE
RCLASS_SET_ATTACHED_OBJECT(VALUE klass, VALUE attached_object)
{
    assert(BUILTIN_TYPE(klass) == T_CLASS);
    assert(FL_TEST_RAW(klass, FL_SINGLETON));

    RB_OBJ_WRITE(klass, &RCLASS_EXT(klass)->as.singleton_class.attached_object, attached_object);
    return attached_object;
}

#endif /* INTERNAL_CLASS_H */
