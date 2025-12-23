#ifndef INTERNAL_INITS_H                                 /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_INITS_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header aggregating init functions.
 */

/* class.c */
void Init_class_hierarchy(void);

/* dmyext.c */
void Init_enc(void);
void Init_ext(void);

/* file.c */
void Init_File(void);

/* gc.c */
void Init_heap(void);

/* localeinit.c */
int Init_enc_set_filesystem_encoding(void);

/* newline.c */
void Init_newline(void);

/* vm.c */
void Init_BareVM(void);
void Init_vm_objects(void);

/* vm_backtrace.c */
void Init_vm_backtrace(void);

/* vm_eval.c */
void Init_vm_eval(void);

/* vm_insnhelper.c */
void Init_vm_stack_canary(void);

/* vm_method.c */
void Init_eval_method(void);

/* inits.c */
void rb_call_inits(void);

#endif /* INTERNAL_INITS_H */
