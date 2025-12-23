#ifndef INTERNAL_TRANSCODE_H                             /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_TRANSCODE_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Encoding::Converter.
 */
#include "ruby/internal/config.h"
#include <stddef.h>             /* for size_t */
#include "ruby/ruby.h"          /* for VALUE */
#include "ruby/encoding.h"      /* for rb_econv_t */

/* transcode.c */
extern VALUE rb_cEncodingConverter;
size_t rb_econv_memsize(rb_econv_t *);

/* vm.c */
void rb_free_transcoder_table(void);

#endif /* INTERNAL_TRANSCODE_H */
