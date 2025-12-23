#ifndef INTERNAL_CONT_H                                  /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_CONT_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Fiber.
 */
#include "ruby/ruby.h"          /* for VALUE */
#include "iseq.h"

struct rb_thread_struct;        /* in vm_core.h */
struct rb_fiber_struct;         /* in cont.c */
struct rb_execution_context_struct; /* in vm_core.c */

/* cont.c */
void rb_fiber_reset_root_local_storage(struct rb_thread_struct *);
void ruby_register_rollback_func_for_ensure(VALUE (*ensure_func)(VALUE), VALUE (*rollback_func)(VALUE));
void rb_jit_cont_init(void);
void rb_jit_cont_each_iseq(rb_iseq_callback callback, void *data);
void rb_jit_cont_finish(void);

/* vm.c */
void rb_free_shared_fiber_pool(void);

// Copy locals from the current execution to the specified fiber.
VALUE rb_fiber_inherit_storage(struct rb_execution_context_struct *ec, struct rb_fiber_struct *fiber);

VALUE rb_fiberptr_self(struct rb_fiber_struct *fiber);
unsigned int rb_fiberptr_blocking(struct rb_fiber_struct *fiber);
struct rb_execution_context_struct * rb_fiberptr_get_ec(struct rb_fiber_struct *fiber);

#endif /* INTERNAL_CONT_H */
