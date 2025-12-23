#ifndef INTERNAL_UTIL_H                                  /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_UTIL_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header corresponding util.c.
 * @warning    DO NOT ADD RANDOM GARBAGE HERE THIS FILE IS FOR util.c
 */
#include "ruby/internal/config.h"
#include <stddef.h>             /* for size_t */

#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>         /* for ssize_t (note: on Windows ssize_t is */
#endif                          /* `#define`d in ruby/config.h) */

/* util.c */
char *ruby_dtoa(double d_, int mode, int ndigits, int *decpt, int *sign, char **rve);
char *ruby_hdtoa(double d, const char *xdigs, int ndigits, int *decpt, int *sign, char **rve);

RUBY_SYMBOL_EXPORT_BEGIN
/* util.c (export) */
RUBY_SYMBOL_EXPORT_END

#endif /* INTERNAL_UTIL_H */
