#ifndef INTERNAL_ENCODING_H                              /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_ENCODING_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Encoding.
 */
#include "ruby/ruby.h"          /* for ID */
#include "ruby/encoding.h"      /* for rb_encoding */

#define rb_enc_autoload_p(enc) (!rb_enc_mbmaxlen(enc))
#define rb_is_usascii_enc(enc) ((enc) == rb_usascii_encoding())
#define rb_is_ascii8bit_enc(enc) ((enc) == rb_ascii8bit_encoding())
#define rb_is_locale_enc(enc) ((enc) == rb_locale_encoding())

/* encoding.c */
ID rb_id_encoding(void);
rb_encoding *rb_enc_get_from_index(int index);
rb_encoding *rb_enc_check_str(VALUE str1, VALUE str2);
int rb_encdb_replicate(const char *alias, const char *orig);
int rb_encdb_alias(const char *alias, const char *orig);
int rb_enc_autoload(rb_encoding *enc);
int rb_encdb_dummy(const char *name);
void rb_encdb_declare(const char *name);
void rb_enc_set_base(const char *name, const char *orig);
int rb_enc_set_dummy(int index);
PUREFUNC(int rb_data_is_encoding(VALUE obj));

/* vm.c */
void rb_free_global_enc_table(void);

#endif /* INTERNAL_ENCODING_H */
