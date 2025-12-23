#ifndef RUBY_ID_TABLE_H
#define RUBY_ID_TABLE_H 1
#include "ruby/internal/config.h"
#include <stddef.h>
#include "ruby/ruby.h"

struct rb_id_table;

/* compatible with ST_* */
enum rb_id_table_iterator_result {
    ID_TABLE_CONTINUE = ST_CONTINUE,
    ID_TABLE_STOP     = ST_STOP,
    ID_TABLE_DELETE   = ST_DELETE,
    ID_TABLE_REPLACE  = ST_REPLACE,
    ID_TABLE_ITERATOR_RESULT_END
};

struct rb_id_table *rb_id_table_create(size_t size);
void rb_id_table_free(struct rb_id_table *tbl);
void rb_id_table_clear(struct rb_id_table *tbl);

size_t rb_id_table_memsize(const struct rb_id_table *tbl);

int rb_id_table_insert(struct rb_id_table *tbl, ID id, VALUE val);
int rb_id_table_lookup(struct rb_id_table *tbl, ID id, VALUE *valp);
int rb_id_table_delete(struct rb_id_table *tbl, ID id);

typedef enum rb_id_table_iterator_result rb_id_table_update_value_callback_func_t(VALUE *val, void *data, int existing);
typedef enum rb_id_table_iterator_result rb_id_table_foreach_func_t(ID id, VALUE val, void *data);
typedef enum rb_id_table_iterator_result rb_id_table_foreach_values_func_t(VALUE val, void *data);
void rb_id_table_foreach(struct rb_id_table *tbl, rb_id_table_foreach_func_t *func, void *data);
void rb_id_table_foreach_values(struct rb_id_table *tbl, rb_id_table_foreach_values_func_t *func, void *data);
void rb_id_table_foreach_values_with_replace(struct rb_id_table *tbl, rb_id_table_foreach_values_func_t *func, rb_id_table_update_value_callback_func_t *replace, void *data);

RUBY_SYMBOL_EXPORT_BEGIN
size_t rb_id_table_size(const struct rb_id_table *tbl);
RUBY_SYMBOL_EXPORT_END

#endif	/* RUBY_ID_TABLE_H */
