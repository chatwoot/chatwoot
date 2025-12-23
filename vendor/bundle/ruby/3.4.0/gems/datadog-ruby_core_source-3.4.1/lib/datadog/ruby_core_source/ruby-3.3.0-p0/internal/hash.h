#ifndef INTERNAL_HASH_H                                  /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_HASH_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Hash.
 */
#include "ruby/internal/config.h"
#include <stddef.h>             /* for size_t */
#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/ruby.h"          /* for struct RBasic */
#include "ruby/st.h"            /* for struct st_table */

#define RHASH_AR_TABLE_MAX_SIZE SIZEOF_VALUE

struct ar_table_struct;
typedef unsigned char ar_hint_t;

enum ruby_rhash_flags {
    RHASH_PASS_AS_KEYWORDS = FL_USER1,                                   /* FL 1 */
    RHASH_PROC_DEFAULT = FL_USER2,                                       /* FL 2 */
    RHASH_ST_TABLE_FLAG = FL_USER3,                                      /* FL 3 */
    RHASH_AR_TABLE_SIZE_MASK = (FL_USER4|FL_USER5|FL_USER6|FL_USER7),    /* FL 4..7 */
    RHASH_AR_TABLE_SIZE_SHIFT = (FL_USHIFT+4),
    RHASH_AR_TABLE_BOUND_MASK = (FL_USER8|FL_USER9|FL_USER10|FL_USER11), /* FL 8..11 */
    RHASH_AR_TABLE_BOUND_SHIFT = (FL_USHIFT+8),

    // we can not put it in "enum" because it can exceed "int" range.
#define RHASH_LEV_MASK (FL_USER13 | FL_USER14 | FL_USER15 |                /* FL 13..19 */ \
                        FL_USER16 | FL_USER17 | FL_USER18 | FL_USER19)

    RHASH_LEV_SHIFT = (FL_USHIFT + 13),
    RHASH_LEV_MAX = 127, /* 7 bits */
};

typedef struct ar_table_pair_struct {
    VALUE key;
    VALUE val;
} ar_table_pair;

typedef struct ar_table_struct {
    union {
        ar_hint_t ary[RHASH_AR_TABLE_MAX_SIZE];
        VALUE word;
    } ar_hint;
    /* 64bit CPU: 8B * 2 * 8 = 128B */
    ar_table_pair pairs[RHASH_AR_TABLE_MAX_SIZE];
} ar_table;

struct RHash {
    struct RBasic basic;
    const VALUE ifnone;
};

#define RHASH(obj) ((struct RHash *)(obj))

#ifdef RHASH_IFNONE
# undef RHASH_IFNONE
#endif

#ifdef RHASH_SIZE
# undef RHASH_SIZE
#endif

#ifdef RHASH_EMPTY_P
# undef RHASH_EMPTY_P
#endif

/* hash.c */
void rb_hash_st_table_set(VALUE hash, st_table *st);
VALUE rb_hash_default_value(VALUE hash, VALUE key);
VALUE rb_hash_set_default_proc(VALUE hash, VALUE proc);
long rb_dbl_long_hash(double d);
st_table *rb_init_identtable(void);
st_index_t rb_any_hash(VALUE a);
int rb_any_cmp(VALUE a, VALUE b);
VALUE rb_to_hash_type(VALUE obj);
VALUE rb_hash_key_str(VALUE);
VALUE rb_hash_values(VALUE hash);
VALUE rb_hash_rehash(VALUE hash);
int rb_hash_add_new_element(VALUE hash, VALUE key, VALUE val);
VALUE rb_hash_set_pair(VALUE hash, VALUE pair);
int rb_hash_stlike_delete(VALUE hash, st_data_t *pkey, st_data_t *pval);
int rb_hash_stlike_foreach_with_replace(VALUE hash, st_foreach_check_callback_func *func, st_update_callback_func *replace, st_data_t arg);
int rb_hash_stlike_update(VALUE hash, st_data_t key, st_update_callback_func *func, st_data_t arg);
VALUE rb_ident_hash_new_with_size(st_index_t size);
void rb_hash_free(VALUE hash);

static inline unsigned RHASH_AR_TABLE_SIZE_RAW(VALUE h);
static inline VALUE RHASH_IFNONE(VALUE h);
static inline size_t RHASH_SIZE(VALUE h);
static inline bool RHASH_EMPTY_P(VALUE h);
static inline bool RHASH_AR_TABLE_P(VALUE h);
static inline bool RHASH_ST_TABLE_P(VALUE h);
static inline struct ar_table_struct *RHASH_AR_TABLE(VALUE h);
static inline st_table *RHASH_ST_TABLE(VALUE h);
static inline size_t RHASH_ST_SIZE(VALUE h);
static inline void RHASH_ST_CLEAR(VALUE h);

RUBY_SYMBOL_EXPORT_BEGIN
/* hash.c (export) */
VALUE rb_hash_delete_entry(VALUE hash, VALUE key);
VALUE rb_ident_hash_new(void);
int rb_hash_stlike_foreach(VALUE hash, st_foreach_callback_func *func, st_data_t arg);
RUBY_SYMBOL_EXPORT_END

VALUE rb_hash_new_with_size(st_index_t size);
VALUE rb_hash_resurrect(VALUE hash);
int rb_hash_stlike_lookup(VALUE hash, st_data_t key, st_data_t *pval);
VALUE rb_hash_keys(VALUE hash);
VALUE rb_hash_has_key(VALUE hash, VALUE key);
VALUE rb_hash_compare_by_id_p(VALUE hash);

st_table *rb_hash_tbl_raw(VALUE hash, const char *file, int line);
#define RHASH_TBL_RAW(h) rb_hash_tbl_raw(h, __FILE__, __LINE__)

VALUE rb_hash_compare_by_id(VALUE hash);

static inline bool
RHASH_AR_TABLE_P(VALUE h)
{
    return ! FL_TEST_RAW(h, RHASH_ST_TABLE_FLAG);
}

RBIMPL_ATTR_RETURNS_NONNULL()
static inline struct ar_table_struct *
RHASH_AR_TABLE(VALUE h)
{
    return (struct ar_table_struct *)((uintptr_t)h + sizeof(struct RHash));
}

RBIMPL_ATTR_RETURNS_NONNULL()
static inline st_table *
RHASH_ST_TABLE(VALUE h)
{
    return (st_table *)((uintptr_t)h + sizeof(struct RHash));
}

static inline VALUE
RHASH_IFNONE(VALUE h)
{
    return RHASH(h)->ifnone;
}

static inline size_t
RHASH_SIZE(VALUE h)
{
    if (RHASH_AR_TABLE_P(h)) {
        return RHASH_AR_TABLE_SIZE_RAW(h);
    }
    else {
        return RHASH_ST_SIZE(h);
    }
}

static inline bool
RHASH_EMPTY_P(VALUE h)
{
    return RHASH_SIZE(h) == 0;
}

static inline bool
RHASH_ST_TABLE_P(VALUE h)
{
    return ! RHASH_AR_TABLE_P(h);
}

static inline size_t
RHASH_ST_SIZE(VALUE h)
{
    return RHASH_ST_TABLE(h)->num_entries;
}

static inline void
RHASH_ST_CLEAR(VALUE h)
{
    memset(RHASH_ST_TABLE(h), 0, sizeof(st_table));
}

static inline unsigned
RHASH_AR_TABLE_SIZE_RAW(VALUE h)
{
    VALUE ret = FL_TEST_RAW(h, RHASH_AR_TABLE_SIZE_MASK);
    ret >>= RHASH_AR_TABLE_SIZE_SHIFT;
    return (unsigned)ret;
}

#endif /* INTERNAL_HASH_H */
