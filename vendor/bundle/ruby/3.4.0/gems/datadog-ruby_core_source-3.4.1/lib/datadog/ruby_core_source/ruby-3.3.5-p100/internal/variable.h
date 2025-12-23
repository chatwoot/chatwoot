#ifndef INTERNAL_VARIABLE_H                              /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_VARIABLE_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for variables.
 */
#include "ruby/internal/config.h"
#include <stddef.h>             /* for size_t */
#include "constant.h"           /* for rb_const_entry_t */
#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/ruby.h"          /* for VALUE */
#include "shape.h"              /* for rb_shape_t */

/* variable.c */
void rb_gc_mark_global_tbl(void);
void rb_gc_update_global_tbl(void);
size_t rb_generic_ivar_memsize(VALUE);
VALUE rb_search_class_path(VALUE);
VALUE rb_attr_delete(VALUE, ID);
void rb_autoload_str(VALUE mod, ID id, VALUE file);
VALUE rb_autoload_at_p(VALUE, ID, int);
NORETURN(VALUE rb_mod_const_missing(VALUE,VALUE));
rb_gvar_getter_t *rb_gvar_getter_function_of(ID);
rb_gvar_setter_t *rb_gvar_setter_function_of(ID);
void rb_gvar_readonly_setter(VALUE v, ID id, VALUE *_);
void rb_gvar_ractor_local(const char *name);

/**
 * Sets the name of a module.
 *
 * Non-permanently named classes can have a temporary name assigned (or
 * cleared). In that case the name will be used for `#inspect` and `#to_s`, and
 * nested classes/modules will be named with the temporary name as a prefix.
 *
 * After the module is assigned to a constant, the temporary name will be
 * discarded, and the name will be computed based on the nesting.
 *
 * @param[in]  mod        An instance of ::rb_cModule.
 * @param[in]  name       An instance of ::rb_cString.
 * @retval     mod
 */
VALUE rb_mod_set_temporary_name(VALUE, VALUE);

struct gen_ivtbl;
int rb_gen_ivtbl_get(VALUE obj, ID id, struct gen_ivtbl **ivtbl);
void rb_obj_copy_ivs_to_hash_table(VALUE obj, st_table *table);
void rb_obj_convert_to_too_complex(VALUE obj, st_table *table);
void rb_evict_ivars_to_hash(VALUE obj);

RUBY_SYMBOL_EXPORT_BEGIN
/* variable.c (export) */
void rb_mark_generic_ivar(VALUE obj);
void rb_ref_update_generic_ivar(VALUE);
void rb_mv_generic_ivar(VALUE src, VALUE dst);
VALUE rb_const_missing(VALUE klass, VALUE name);
int rb_class_ivar_set(VALUE klass, ID vid, VALUE value);
void rb_iv_tbl_copy(VALUE dst, VALUE src);
RUBY_SYMBOL_EXPORT_END

VALUE rb_ivar_lookup(VALUE obj, ID id, VALUE undef);
VALUE rb_gvar_get(ID);
VALUE rb_gvar_set(ID, VALUE);
VALUE rb_gvar_defined(ID);
void rb_const_warn_if_deprecated(const rb_const_entry_t *, VALUE, ID);
void rb_ensure_iv_list_size(VALUE obj, uint32_t len, uint32_t newsize);
attr_index_t rb_obj_ivar_set(VALUE obj, ID id, VALUE val);

#endif /* INTERNAL_VARIABLE_H */
