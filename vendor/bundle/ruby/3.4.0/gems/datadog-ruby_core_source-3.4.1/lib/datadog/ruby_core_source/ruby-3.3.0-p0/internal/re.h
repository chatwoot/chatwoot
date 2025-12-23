#ifndef INTERNAL_RE_H                                    /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_RE_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Regexp.
 */
#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/ruby.h"          /* for VALUE */

/* re.c */
VALUE rb_reg_compile(VALUE str, int options, const char *sourcefile, int sourceline);
VALUE rb_reg_check_preprocess(VALUE);
long rb_reg_search0(VALUE, VALUE, long, int, int);
VALUE rb_reg_match_p(VALUE re, VALUE str, long pos);
bool rb_reg_start_with_p(VALUE re, VALUE str);
VALUE rb_reg_hash(VALUE re);
VALUE rb_reg_equal(VALUE re1, VALUE re2);
void rb_backref_set_string(VALUE string, long pos, long len);
void rb_match_unbusy(VALUE);
int rb_match_count(VALUE match);
VALUE rb_reg_new_ary(VALUE ary, int options);
VALUE rb_reg_last_defined(VALUE match);

#endif /* INTERNAL_RE_H */
