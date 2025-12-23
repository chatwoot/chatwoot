#ifndef INTERNAL_ENC_H                                   /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_ENC_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Encoding.
 */
#include "ruby/encoding.h"      /* for rb_encoding */

/* us_ascii.c */
extern rb_encoding OnigEncodingUS_ASCII;

/* utf_8.c */
extern rb_encoding OnigEncodingUTF_8;

#endif /* INTERNAL_ENC_H */
