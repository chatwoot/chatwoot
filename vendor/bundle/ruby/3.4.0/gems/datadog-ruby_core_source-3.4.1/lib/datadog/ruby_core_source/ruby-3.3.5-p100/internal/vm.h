#ifndef INTERNAL_VM_H                                    /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_VM_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for RubyVM.
 */
#include "ruby/internal/stdbool.h"         /* for bool */
#include "internal/serial.h"        /* for rb_serial_t */
#include "internal/static_assert.h" /* for STATIC_ASSERT */
#include "ruby/ruby.h"              /* for ID */
#include "ruby/st.h"                /* for st_table */

#ifdef rb_funcallv
# undef rb_funcallv
#endif

#ifdef rb_method_basic_definition_p
# undef rb_method_basic_definition_p
#endif

struct rb_callable_method_entry_struct; /* in method.h */
struct rb_method_definition_struct;     /* in method.h */
struct rb_execution_context_struct;     /* in vm_core.h */
struct rb_control_frame_struct;         /* in vm_core.h */
struct rb_callinfo;                     /* in vm_core.h */

enum method_missing_reason {
    MISSING_NOENTRY   = 0x00,
    MISSING_PRIVATE   = 0x01,
    MISSING_PROTECTED = 0x02,
    MISSING_FCALL     = 0x04,
    MISSING_VCALL     = 0x08,
    MISSING_SUPER     = 0x10,
    MISSING_MISSING   = 0x20,
    MISSING_NONE      = 0x40
};

/* vm_insnhelper.h */
VALUE rb_vm_push_frame_fname(struct rb_execution_context_struct *ec, VALUE fname);

/* vm.c */
VALUE rb_obj_is_thread(VALUE obj);
void rb_vm_mark(void *ptr);
void rb_vm_each_stack_value(void *ptr, void (*cb)(VALUE, void*), void *ctx);
PUREFUNC(VALUE rb_vm_top_self(void));
const void **rb_vm_get_insns_address_table(void);
VALUE rb_source_location(int *pline);
const char *rb_source_location_cstr(int *pline);
void rb_vm_pop_cfunc_frame(void);
int rb_vm_add_root_module(VALUE module);
void rb_vm_check_redefinition_by_prepend(VALUE klass);
int rb_vm_check_optimizable_mid(VALUE mid);
VALUE rb_yield_refine_block(VALUE refinement, VALUE refinements);
VALUE ruby_vm_special_exception_copy(VALUE);
PUREFUNC(st_table *rb_vm_fstring_table(void));

void rb_lastline_set_up(VALUE val, unsigned int up);

/* vm_eval.c */
VALUE rb_current_realfilepath(void);
VALUE rb_check_block_call(VALUE, ID, int, const VALUE *, rb_block_call_func_t, VALUE);
typedef void rb_check_funcall_hook(int, VALUE, ID, int, const VALUE *, VALUE);
VALUE rb_check_funcall_with_hook(VALUE recv, ID mid, int argc, const VALUE *argv,
                                 rb_check_funcall_hook *hook, VALUE arg);
VALUE rb_check_funcall_with_hook_kw(VALUE recv, ID mid, int argc, const VALUE *argv,
                                 rb_check_funcall_hook *hook, VALUE arg, int kw_splat);
const char *rb_type_str(enum ruby_value_type type);
VALUE rb_check_funcall_default(VALUE, ID, int, const VALUE *, VALUE);
VALUE rb_check_funcall_basic_kw(VALUE, ID, VALUE, int, const VALUE*, int);
VALUE rb_yield_1(VALUE val);
VALUE rb_yield_force_blockarg(VALUE values);
VALUE rb_lambda_call(VALUE obj, ID mid, int argc, const VALUE *argv,
                     rb_block_call_func_t bl_proc, int min_argc, int max_argc,
                     VALUE data2);
void rb_check_stack_overflow(void);

#if USE_YJIT
/* vm_exec.c */
extern uint64_t rb_vm_insns_count;
#endif

extern bool rb_free_at_exit;

/* miniinit.c and builtin.c */
void rb_free_loaded_builtin_table(void);

/* vm_insnhelper.c */
VALUE rb_equal_opt(VALUE obj1, VALUE obj2);
VALUE rb_eql_opt(VALUE obj1, VALUE obj2);

struct rb_iseq_struct;
const struct rb_callcache *rb_vm_search_method_slowpath(const struct rb_callinfo *ci, VALUE klass);

/* vm_method.c */
struct rb_execution_context_struct;
int rb_ec_obj_respond_to(struct rb_execution_context_struct *ec, VALUE obj, ID id, int priv);

void rb_clear_constant_cache(void);

/* vm_dump.c */
void rb_print_backtrace(FILE *);

/* vm_backtrace.c */
VALUE rb_vm_thread_backtrace(int argc, const VALUE *argv, VALUE thval);
VALUE rb_vm_thread_backtrace_locations(int argc, const VALUE *argv, VALUE thval);
VALUE rb_vm_backtrace(int argc, const VALUE * argv, struct rb_execution_context_struct * ec);
VALUE rb_vm_backtrace_locations(int argc, const VALUE * argv, struct rb_execution_context_struct * ec);
VALUE rb_make_backtrace(void);
void rb_backtrace_print_as_bugreport(FILE*);
int rb_backtrace_p(VALUE obj);
VALUE rb_backtrace_to_str_ary(VALUE obj);
VALUE rb_backtrace_to_location_ary(VALUE obj);
void rb_backtrace_each(VALUE (*iter)(VALUE recv, VALUE str), VALUE output);
int rb_frame_info_p(VALUE obj);
int rb_get_node_id_from_frame_info(VALUE obj);
const struct rb_iseq_struct *rb_get_iseq_from_frame_info(VALUE obj);

VALUE rb_ec_backtrace_object(const struct rb_execution_context_struct *ec);
void rb_backtrace_use_iseq_first_lineno_for_last_location(VALUE self);

#define RUBY_DTRACE_CREATE_HOOK(name, arg) \
    RUBY_DTRACE_HOOK(name##_CREATE, arg)
#define RUBY_DTRACE_HOOK(name, arg) \
do { \
    if (UNLIKELY(RUBY_DTRACE_##name##_ENABLED())) { \
        int dtrace_line; \
        const char *dtrace_file = rb_source_location_cstr(&dtrace_line); \
        if (!dtrace_file) dtrace_file = ""; \
        RUBY_DTRACE_##name(arg, dtrace_file, dtrace_line); \
    } \
} while (0)
#endif /* INTERNAL_VM_H */
