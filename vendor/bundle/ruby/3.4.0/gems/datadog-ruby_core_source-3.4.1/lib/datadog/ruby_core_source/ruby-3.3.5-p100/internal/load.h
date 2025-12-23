#ifndef INTERNAL_LOAD_H                                  /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_LOAD_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for require.
 */
#include "ruby/ruby.h"          /* for VALUE */

/* load.c */
VALUE rb_get_expanded_load_path(void);
int rb_require_internal(VALUE fname);
NORETURN(void rb_load_fail(VALUE, const char*));

#endif /* INTERNAL_LOAD_H */
