#ifndef INTERNAL_MISSING_H                               /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_MISSING_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header corresponding missing.
 */
#include "ruby/internal/config.h"      /* for HAVE_SETPROCTITLE */

/* missing/setproctitle.c */
#ifndef HAVE_SETPROCTITLE
extern void ruby_init_setproctitle(int argc, char *argv[]);
#endif

#endif /* INTERNAL_MISSING_H */
