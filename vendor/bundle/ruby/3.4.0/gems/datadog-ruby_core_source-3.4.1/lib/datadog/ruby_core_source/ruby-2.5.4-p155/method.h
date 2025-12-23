/**********************************************************************

  method.h -

  $Author: mame $
  created at: Wed Jul 15 20:02:33 2009

  Copyright (C) 2009 Koichi Sasada

**********************************************************************/
#ifndef RUBY_METHOD_H
#define RUBY_METHOD_H 1

#include "internal.h"

#ifndef END_OF_ENUMERATION
# if defined(__GNUC__) &&! defined(__STRICT_ANSI__)
#   define END_OF_ENUMERATION(key)
# else
#   define END_OF_ENUMERATION(key) END_OF_##key##_PLACEHOLDER = 0
# endif
#endif

/* cref */

typedef enum {
    METHOD_VISI_UNDEF     = 0x00,
    METHOD_VISI_PUBLIC    = 0x01,
    METHOD_VISI_PRIVATE   = 0x02,
    METHOD_VISI_PROTECTED = 0x03,

    METHOD_VISI_MASK = 0x03
} rb_method_visibility_t;

typedef struct rb_scope_visi_struct {
    rb_method_visibility_t method_visi : 3;
    unsigned int module_func : 1;
} rb_scope_visibility_t;

/*! CREF (Class REFerence) */
typedef struct rb_cref_struct {
    VALUE flags;
    const VALUE refinements;
    const VALUE klass;
    struct rb_cref_struct * const next;
    const rb_scope_visibility_t scope_visi;
} rb_cref_t;

/* method data type */

typedef struct rb_method_entry_struct {
    VALUE flags;
    const VALUE defined_class;
    struct rb_method_definition_struct * const def;
    ID called_id;
    const VALUE owner;
} rb_method_entry_t;

typedef struct rb_callable_method_entry_struct { /* same fields with rb_method_entry_t */
    VALUE flags;
    const VALUE defined_class;
    struct rb_method_definition_struct * const def;
    ID called_id;
    const VALUE owner;
} rb_callable_method_entry_t;

#define METHOD_ENTRY_VISI(me)  (rb_method_visibility_t)(((me)->flags & (IMEMO_FL_USER0 | IMEMO_FL_USER1)) >> (IMEMO_FL_USHIFT+0))
#define METHOD_ENTRY_BASIC(me) (int)                   (((me)->flags & (IMEMO_FL_USER2                 )) >> (IMEMO_FL_USHIFT+2))
#define METHOD_ENTRY_COMPLEMENTED(me)     ((me)->flags & IMEMO_FL_USER3)
#define METHOD_ENTRY_COMPLEMENTED_SET(me) ((me)->flags = (me)->flags | IMEMO_FL_USER3)

static inline void
METHOD_ENTRY_VISI_SET(rb_method_entry_t *me, rb_method_visibility_t visi)
{
    VM_ASSERT((int)visi >= 0 && visi <= 3);
    me->flags = (me->flags & ~(IMEMO_FL_USER0 | IMEMO_FL_USER1)) | (visi << (IMEMO_FL_USHIFT+0));
}
static inline void
METHOD_ENTRY_BASIC_SET(rb_method_entry_t *me, unsigned int basic)
{
    VM_ASSERT(basic <= 1);
    me->flags = (me->flags & ~(IMEMO_FL_USER2                 )) | (basic << (IMEMO_FL_USHIFT+2));
}
static inline void
METHOD_ENTRY_FLAGS_SET(rb_method_entry_t *me, rb_method_visibility_t visi, unsigned int basic)
{
    VM_ASSERT((int)visi >= 0 && visi <= 3);
    VM_ASSERT(basic <= 1);
    me->flags =
      (me->flags & ~(IMEMO_FL_USER0|IMEMO_FL_USER1|IMEMO_FL_USER2)) |
	((visi << (IMEMO_FL_USHIFT+0)) | (basic << (IMEMO_FL_USHIFT+2)));
}
static inline void
METHOD_ENTRY_FLAGS_COPY(rb_method_entry_t *dst, const rb_method_entry_t *src)
{
    dst->flags =
      (dst->flags & ~(IMEMO_FL_USER0|IMEMO_FL_USER1|IMEMO_FL_USER2)) |
	(src->flags & (IMEMO_FL_USER0|IMEMO_FL_USER1|IMEMO_FL_USER2));
}

typedef enum {
    VM_METHOD_TYPE_ISEQ,      /*!< Ruby method */
    VM_METHOD_TYPE_CFUNC,     /*!< C method */
    VM_METHOD_TYPE_ATTRSET,   /*!< attr_writer or attr_accessor */
    VM_METHOD_TYPE_IVAR,      /*!< attr_reader or attr_accessor */
    VM_METHOD_TYPE_BMETHOD,
    VM_METHOD_TYPE_ZSUPER,
    VM_METHOD_TYPE_ALIAS,
    VM_METHOD_TYPE_UNDEF,
    VM_METHOD_TYPE_NOTIMPLEMENTED,
    VM_METHOD_TYPE_OPTIMIZED, /*!< Kernel#send, Proc#call, etc */
    VM_METHOD_TYPE_MISSING,   /*!< wrapper for method_missing(id) */
    VM_METHOD_TYPE_REFINED,   /*!< refinement */

    END_OF_ENUMERATION(VM_METHOD_TYPE)
} rb_method_type_t;

#ifndef rb_iseq_t
typedef struct rb_iseq_struct rb_iseq_t;
#define rb_iseq_t rb_iseq_t
#endif

typedef struct rb_method_iseq_struct {
    const rb_iseq_t * const iseqptr; /*!< iseq pointer, should be separated from iseqval */
    rb_cref_t * const cref;          /*!< class reference, should be marked */
} rb_method_iseq_t; /* check rb_add_method_iseq() when modify the fields */

typedef struct rb_method_cfunc_struct {
    VALUE (*func)(ANYARGS);
    VALUE (*invoker)(VALUE (*func)(ANYARGS), VALUE recv, int argc, const VALUE *argv);
    int argc;
} rb_method_cfunc_t;

typedef struct rb_method_attr_struct {
    ID id;
    const VALUE location; /* should be marked */
} rb_method_attr_t;

typedef struct rb_method_alias_struct {
    const struct rb_method_entry_struct * const original_me; /* original_me->klass is original owner */
} rb_method_alias_t;

typedef struct rb_method_refined_struct {
    const struct rb_method_entry_struct * const orig_me;
    const VALUE owner;
} rb_method_refined_t;

enum method_optimized_type {
    OPTIMIZED_METHOD_TYPE_SEND,
    OPTIMIZED_METHOD_TYPE_CALL,
    OPTIMIZED_METHOD_TYPE__MAX
};

PACKED_STRUCT_UNALIGNED(struct rb_method_definition_struct {
    unsigned int type :  4; /* method type */
    int alias_count : 28;
    int complemented_count : 28;

    union {
	rb_method_iseq_t iseq;
	rb_method_cfunc_t cfunc;
	rb_method_attr_t attr;
	rb_method_alias_t alias;
	rb_method_refined_t refined;

	const VALUE proc;                 /* should be marked */
	enum method_optimized_type optimize_type;
    } body;

    ID original_id;
});

typedef struct rb_method_definition_struct rb_method_definition_t;

#define UNDEFINED_METHOD_ENTRY_P(me) (!(me) || !(me)->def || (me)->def->type == VM_METHOD_TYPE_UNDEF)
#define UNDEFINED_REFINED_METHOD_P(def) \
    ((def)->type == VM_METHOD_TYPE_REFINED && \
     UNDEFINED_METHOD_ENTRY_P((def)->body.refined.orig_me))

void rb_add_method_cfunc(VALUE klass, ID mid, VALUE (*func)(ANYARGS), int argc, rb_method_visibility_t visi);
void rb_add_method_iseq(VALUE klass, ID mid, const rb_iseq_t *iseq, rb_cref_t *cref, rb_method_visibility_t visi);
void rb_add_refined_method_entry(VALUE refined_class, ID mid);

rb_method_entry_t *rb_add_method(VALUE klass, ID mid, rb_method_type_t type, void *option, rb_method_visibility_t visi);
rb_method_entry_t *rb_method_entry_set(VALUE klass, ID mid, const rb_method_entry_t *, rb_method_visibility_t noex);
rb_method_entry_t *rb_method_entry_create(ID called_id, VALUE klass, rb_method_visibility_t visi, const rb_method_definition_t *def);

const rb_method_entry_t *rb_method_entry_at(VALUE obj, ID id);

const rb_method_entry_t *rb_method_entry(VALUE klass, ID id);
const rb_method_entry_t *rb_method_entry_without_refinements(VALUE klass, ID id, VALUE *defined_class);
const rb_method_entry_t *rb_resolve_refined_method(VALUE refinements, const rb_method_entry_t *me);
RUBY_SYMBOL_EXPORT_BEGIN
const rb_method_entry_t *rb_resolve_me_location(const rb_method_entry_t *, VALUE[5]);
RUBY_SYMBOL_EXPORT_END

const rb_callable_method_entry_t *rb_callable_method_entry(VALUE klass, ID id);
const rb_callable_method_entry_t *rb_callable_method_entry_with_refinements(VALUE klass, ID id, VALUE *defined_class);
const rb_callable_method_entry_t *rb_callable_method_entry_without_refinements(VALUE klass, ID id, VALUE *defined_class);

int rb_method_entry_arity(const rb_method_entry_t *me);
int rb_method_entry_eq(const rb_method_entry_t *m1, const rb_method_entry_t *m2);
st_index_t rb_hash_method_entry(st_index_t hash, const rb_method_entry_t *me);

VALUE rb_method_entry_location(const rb_method_entry_t *me);
VALUE rb_mod_method_location(VALUE mod, ID id);
VALUE rb_obj_method_location(VALUE obj, ID id);

void rb_free_method_entry(const rb_method_entry_t *me);
void rb_sweep_method_entry(void *vm);

const rb_method_entry_t *rb_method_entry_clone(const rb_method_entry_t *me);
const rb_callable_method_entry_t *rb_method_entry_complement_defined_class(const rb_method_entry_t *src_me, ID called_id, VALUE defined_class);
void rb_method_entry_copy(rb_method_entry_t *dst, const rb_method_entry_t *src);

void rb_scope_visibility_set(rb_method_visibility_t);

#endif /* RUBY_METHOD_H */
