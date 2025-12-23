/* This is a public domain general purpose hash table package
   originally written by Peter Moore @ UCB.

   The hash table data structures were redesigned and the package was
   rewritten by Vladimir Makarov <vmakarov@redhat.com>.  */

#ifndef RUBY_ST2_H
#define RUBY_ST2_H 1

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

#include <stddef.h>
#include <stdint.h>
#include "ruby/config.h"
#include "ruby/backward/2/long_long.h"
#include "ruby/defines.h"

RUBY_SYMBOL_EXPORT_BEGIN

#if SIZEOF_LONG == SIZEOF_VOIDP
typedef unsigned long parser_st_data_t;
#elif SIZEOF_LONG_LONG == SIZEOF_VOIDP
typedef unsigned LONG_LONG parser_st_data_t;
#else
# error ---->> parser_st.c requires sizeof(void*) == sizeof(long) or sizeof(LONG_LONG) to be compiled. <<----
#endif
#define ST2_DATA_T_DEFINED

#ifndef CHAR_BIT
# ifdef HAVE_LIMITS_H
#  include <limits.h>
# else
#  define CHAR_BIT 8
# endif
#endif
#ifndef _
# define _(args) args
#endif
#ifndef ANYARGS
# ifdef __cplusplus
#   define ANYARGS ...
# else
#   define ANYARGS
# endif
#endif

typedef struct parser_st_table parser_st_table;

typedef parser_st_data_t parser_st_index_t;

/* Maximal value of unsigned integer type parser_st_index_t.  */
#define MAX_ST2_INDEX_VAL (~(parser_st_index_t) 0)

typedef int parser_st_compare_func(parser_st_data_t, parser_st_data_t);
typedef parser_st_index_t parser_st_hash_func(parser_st_data_t);

typedef char st_check_for_sizeof_parser_st_index_t[SIZEOF_VOIDP == (int)sizeof(parser_st_index_t) ? 1 : -1];
#define SIZEOF_ST_INDEX_T SIZEOF_VOIDP

struct parser_st_hash_type {
    int (*compare)(parser_st_data_t, parser_st_data_t); /* parser_st_compare_func* */
    parser_st_index_t (*hash)(parser_st_data_t);        /* parser_st_hash_func* */
};

#define ST_INDEX_BITS (SIZEOF_ST_INDEX_T * CHAR_BIT)

#if defined(HAVE_BUILTIN___BUILTIN_CHOOSE_EXPR) && defined(HAVE_BUILTIN___BUILTIN_TYPES_COMPATIBLE_P)
# define ST2_DATA_COMPATIBLE_P(type) \
   __builtin_choose_expr(__builtin_types_compatible_p(type, parser_st_data_t), 1, 0)
#else
# define ST2_DATA_COMPATIBLE_P(type) 0
#endif

typedef struct parser_st_table_entry parser_st_table_entry;

struct parser_st_table_entry; /* defined in parser_st.c */

struct parser_st_table {
    /* Cached features of the table -- see st.c for more details.  */
    unsigned char entry_power, bin_power, size_ind;
    /* How many times the table was rebuilt.  */
    unsigned int rebuilds_num;
    const struct parser_st_hash_type *type;
    /* Number of entries currently in the table.  */
    parser_st_index_t num_entries;
    /* Array of bins used for access by keys.  */
    parser_st_index_t *bins;
    /* Start and bound index of entries in array entries.
       entries_starts and entries_bound are in interval
       [0,allocated_entries].  */
    parser_st_index_t entries_start, entries_bound;
    /* Array of size 2^entry_power.  */
    parser_st_table_entry *entries;
};

#define parser_st_is_member(table,key) rb_parser_st_lookup((table),(key),(parser_st_data_t *)0)

enum parser_st_retval {ST2_CONTINUE, ST2_STOP, ST2_DELETE, ST2_CHECK, ST2_REPLACE};

size_t rb_parser_st_table_size(const struct parser_st_table *tbl);
parser_st_table *rb_parser_st_init_table(const struct parser_st_hash_type *);
parser_st_table *rb_parser_st_init_table_with_size(const struct parser_st_hash_type *, parser_st_index_t);
parser_st_table *rb_parser_st_init_existing_table_with_size(parser_st_table *, const struct parser_st_hash_type *, parser_st_index_t);
parser_st_table *rb_parser_st_init_numtable(void);
parser_st_table *rb_parser_st_init_numtable_with_size(parser_st_index_t);
parser_st_table *rb_parser_st_init_strtable(void);
parser_st_table *rb_parser_st_init_strtable_with_size(parser_st_index_t);
parser_st_table *rb_parser_st_init_strcasetable(void);
parser_st_table *rb_parser_st_init_strcasetable_with_size(parser_st_index_t);
int rb_parser_st_delete(parser_st_table *, parser_st_data_t *, parser_st_data_t *); /* returns 0:notfound 1:deleted */
int rb_parser_st_delete_safe(parser_st_table *, parser_st_data_t *, parser_st_data_t *, parser_st_data_t);
int rb_parser_st_shift(parser_st_table *, parser_st_data_t *, parser_st_data_t *); /* returns 0:notfound 1:deleted */
int rb_parser_st_insert(parser_st_table *, parser_st_data_t, parser_st_data_t);
int rb_parser_st_insert2(parser_st_table *, parser_st_data_t, parser_st_data_t, parser_st_data_t (*)(parser_st_data_t));
int rb_parser_st_lookup(parser_st_table *, parser_st_data_t, parser_st_data_t *);
int rb_parser_st_get_key(parser_st_table *, parser_st_data_t, parser_st_data_t *);
typedef int parser_st_update_callback_func(parser_st_data_t *key, parser_st_data_t *value, parser_st_data_t arg, int existing);
/* *key may be altered, but must equal to the old key, i.e., the
 * results of hash() are same and compare() returns 0, otherwise the
 * behavior is undefined */
int rb_parser_st_update(parser_st_table *table, parser_st_data_t key, parser_st_update_callback_func *func, parser_st_data_t arg);
typedef int parser_st_foreach_callback_func(parser_st_data_t, parser_st_data_t, parser_st_data_t);
typedef int parser_st_foreach_check_callback_func(parser_st_data_t, parser_st_data_t, parser_st_data_t, int);
int rb_parser_st_foreach_with_replace(parser_st_table *tab, parser_st_foreach_check_callback_func *func, parser_st_update_callback_func *replace, parser_st_data_t arg);
int rb_parser_st_foreach(parser_st_table *, parser_st_foreach_callback_func *, parser_st_data_t);
int rb_parser_st_foreach_check(parser_st_table *, parser_st_foreach_check_callback_func *, parser_st_data_t, parser_st_data_t);
parser_st_index_t rb_parser_st_keys(parser_st_table *table, parser_st_data_t *keys, parser_st_index_t size);
parser_st_index_t rb_parser_st_keys_check(parser_st_table *table, parser_st_data_t *keys, parser_st_index_t size, parser_st_data_t never);
parser_st_index_t rb_parser_st_values(parser_st_table *table, parser_st_data_t *values, parser_st_index_t size);
parser_st_index_t rb_parser_st_values_check(parser_st_table *table, parser_st_data_t *values, parser_st_index_t size, parser_st_data_t never);
void rb_parser_st_add_direct(parser_st_table *, parser_st_data_t, parser_st_data_t);
void rb_parser_st_free_table(parser_st_table *);
void rb_parser_st_cleanup_safe(parser_st_table *, parser_st_data_t);
void rb_parser_st_clear(parser_st_table *);
parser_st_table *rb_parser_st_replace(parser_st_table *, parser_st_table *);
parser_st_table *rb_parser_st_copy(parser_st_table *);
CONSTFUNC(int rb_parser_st_numcmp(parser_st_data_t, parser_st_data_t));
CONSTFUNC(parser_st_index_t rb_parser_st_numhash(parser_st_data_t));
PUREFUNC(int rb_parser_st_locale_insensitive_strcasecmp(const char *s1, const char *s2));
PUREFUNC(int rb_parser_st_locale_insensitive_strncasecmp(const char *s1, const char *s2, size_t n));
PUREFUNC(size_t rb_parser_st_memsize(const parser_st_table *));
PUREFUNC(parser_st_index_t rb_parser_st_hash(const void *ptr, size_t len, parser_st_index_t h));
CONSTFUNC(parser_st_index_t rb_parser_st_hash_uint32(parser_st_index_t h, uint32_t i));
CONSTFUNC(parser_st_index_t rb_parser_st_hash_uint(parser_st_index_t h, parser_st_index_t i));
CONSTFUNC(parser_st_index_t rb_parser_st_hash_end(parser_st_index_t h));
CONSTFUNC(parser_st_index_t rb_parser_st_hash_start(parser_st_index_t h));

RUBY_SYMBOL_EXPORT_END

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
}  /* extern "C" { */
#endif

#endif /* RUBY_ST2_H */
