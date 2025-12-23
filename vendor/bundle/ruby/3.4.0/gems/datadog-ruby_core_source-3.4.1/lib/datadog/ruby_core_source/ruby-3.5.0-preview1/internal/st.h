#ifndef INTERNAL_ST_H
#define INTERNAL_ST_H

#include "include/ruby/st.h"

st_table *rb_st_replace(st_table *new_tab, st_table *old_tab);
#define st_replace rb_st_replace
st_table *rb_st_init_existing_table_with_size(st_table *tab, const struct st_hash_type *type, st_index_t size);
#define st_init_existing_table_with_size rb_st_init_existing_table_with_size

#endif
