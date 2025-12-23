#ifndef INTERNAL_SIGNAL_H                                /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_SIGNAL_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for SignalException.
 */

/* signal.c */
extern int ruby_enable_coredump;
int rb_get_next_signal(void);

#ifdef POSIX_SIGNAL
void (*ruby_posix_signal(int, void (*)(int)))(int);
#endif

RUBY_SYMBOL_EXPORT_BEGIN
/* signal.c (export) */
RUBY_SYMBOL_EXPORT_END

#endif /* INTERNAL_SIGNAL_H */
