#ifndef INTERNAL_WARNINGS_H                              /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_WARNINGS_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header to suppress / mandate warnings.
 */
#include "ruby/internal/warning_push.h"
#define COMPILER_WARNING_PUSH          RBIMPL_WARNING_PUSH()
#define COMPILER_WARNING_POP           RBIMPL_WARNING_POP()
#define COMPILER_WARNING_ERROR(flag)   RBIMPL_WARNING_ERROR(flag)
#define COMPILER_WARNING_IGNORED(flag) RBIMPL_WARNING_IGNORED(flag)
#endif /* INTERNAL_WARNINGS_H */
