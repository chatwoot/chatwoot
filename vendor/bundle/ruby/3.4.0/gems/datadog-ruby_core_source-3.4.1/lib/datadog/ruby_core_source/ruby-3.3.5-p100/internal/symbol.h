#ifndef INTERNAL_SYMBOL_H                                /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_SYMBOL_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Symbol.
 */
#include "ruby/ruby.h"          /* for VALUE */
#include "ruby/encoding.h"      /* for rb_encoding */
#include "internal/compilers.h" /* for __has_builtin */

#ifdef rb_sym_intern_ascii_cstr
# undef rb_sym_intern_ascii_cstr
#endif

/* symbol.c */
VALUE rb_to_symbol_type(VALUE obj);
VALUE rb_sym_intern(const char *ptr, long len, rb_encoding *enc);
VALUE rb_sym_intern_ascii(const char *ptr, long len);
VALUE rb_sym_intern_ascii_cstr(const char *ptr);
int rb_is_const_name(VALUE name);
int rb_is_class_name(VALUE name);
int rb_is_instance_name(VALUE name);
int rb_is_local_name(VALUE name);
PUREFUNC(int rb_is_const_sym(VALUE sym));
PUREFUNC(int rb_is_attrset_sym(VALUE sym));
ID rb_make_internal_id(void);
ID rb_make_temporary_id(size_t n);
void rb_gc_free_dsymbol(VALUE);
int rb_static_id_valid_p(ID id);

/* vm.c */
void rb_free_static_symid_str(void);

#if __has_builtin(__builtin_constant_p)
#define rb_sym_intern_ascii_cstr(ptr) \
    (__builtin_constant_p(ptr) ? \
        rb_sym_intern_ascii((ptr), (long)strlen(ptr)) : \
        rb_sym_intern_ascii_cstr(ptr))
#endif

#endif /* INTERNAL_SYMBOL_H */
