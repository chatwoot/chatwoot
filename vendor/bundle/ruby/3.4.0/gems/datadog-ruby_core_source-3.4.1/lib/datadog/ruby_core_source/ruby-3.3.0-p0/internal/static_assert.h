#ifndef INTERNAL_STATIC_ASSERT_H                         /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_STATIC_ASSERT_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      C11 shim for _Static_assert.
 */
#include "ruby/internal/static_assert.h"
#ifndef STATIC_ASSERT
# define STATIC_ASSERT RBIMPL_STATIC_ASSERT
#endif

#endif /* INTERNAL_STATIC_ASSERT_H */
