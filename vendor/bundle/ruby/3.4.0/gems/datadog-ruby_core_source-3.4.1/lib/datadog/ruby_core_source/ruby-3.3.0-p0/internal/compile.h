#ifndef INTERNAL_COMPILE_H                               /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_COMPILE_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for the compiler.
 */
#include "ruby/internal/config.h"
#include <stddef.h>             /* for size_t */
#include "ruby/ruby.h"          /* for rb_event_flag_t */

struct rb_iseq_struct;          /* in vm_core.h */

/* compile.c */
int rb_dvar_defined(ID, const struct rb_iseq_struct *);
int rb_local_defined(ID, const struct rb_iseq_struct *);
int rb_insn_len(VALUE insn);
const char *rb_insns_name(int i);
VALUE rb_insns_name_array(void);
int rb_iseq_cdhash_cmp(VALUE val, VALUE lit);
st_index_t rb_iseq_cdhash_hash(VALUE a);

/* iseq.c */
int rb_vm_insn_addr2insn(const void *);
int rb_vm_insn_decode(const VALUE encoded);
extern bool ruby_vm_keep_script_lines;

/* iseq.c (export) */
rb_event_flag_t rb_iseq_event_flags(const struct rb_iseq_struct *iseq, size_t pos);

#endif /* INTERNAL_COMPILE_H */
