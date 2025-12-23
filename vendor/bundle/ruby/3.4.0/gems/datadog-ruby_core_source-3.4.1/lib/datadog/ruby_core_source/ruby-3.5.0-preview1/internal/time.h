#ifndef INTERNAL_TIME_H                                  /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_TIME_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Time.
 */
#include "ruby/internal/config.h"      /* for SIGNEDNESS_OF_TIME_T */
#include "internal/bits.h"      /* for SIGNED_INTEGER_MAX */
#include "ruby/ruby.h"          /* for VALUE */

#if SIGNEDNESS_OF_TIME_T < 0    /* signed */
# define TIMET_MAX SIGNED_INTEGER_MAX(time_t)
# define TIMET_MIN SIGNED_INTEGER_MIN(time_t)
#elif SIGNEDNESS_OF_TIME_T > 0  /* unsigned */
# define TIMET_MAX UNSIGNED_INTEGER_MAX(time_t)
# define TIMET_MIN ((time_t)0)
#endif

struct timeval; /* <- in <sys/time.h> or <winsock2.h> */

/* time.c */
struct timeval rb_time_timeval(VALUE);

RUBY_SYMBOL_EXPORT_BEGIN
/* time.c (export) */
void ruby_reset_leap_second_info(void);
#ifdef RBIMPL_ATTR_DEPRECATED_INTERNAL_ONLY
RBIMPL_ATTR_DEPRECATED_INTERNAL_ONLY()
#endif
void ruby_reset_timezone(const char *);
RUBY_SYMBOL_EXPORT_END

#endif /* INTERNAL_TIME_H */
