#ifndef INTERNAL_RANDOM_H                                /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_RANDOM_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Random.
 */
#include <stddef.h>             /* for size_t */

/* random.c */
int ruby_fill_random_bytes(void *, size_t, int);
void rb_free_default_rand_key(void);

#endif /* INTERNAL_RANDOM_H */
