#ifndef RUBY_TOPLEVEL_ASSERT_H                           /*-*-C-*-vi:se ft=c:*/
#define RUBY_TOPLEVEL_ASSERT_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 */
#include "ruby/assert.h"
#undef assert
#define assert RUBY_ASSERT_NDEBUG

#endif /* RUBY_TOPLEVEL_ASSERT_H */
