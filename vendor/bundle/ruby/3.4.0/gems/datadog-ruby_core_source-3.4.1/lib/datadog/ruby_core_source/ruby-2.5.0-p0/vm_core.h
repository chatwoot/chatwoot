/**********************************************************************

  vm_core.h -

  $Author: mame $
  created at: 04/01/01 19:41:38 JST

  Copyright (C) 2004-2007 Koichi Sasada

**********************************************************************/

#ifndef RUBY_VM_CORE_H
#define RUBY_VM_CORE_H

/*
 * Enable check mode.
 *   1: enable local assertions.
 */
#ifndef VM_CHECK_MODE
#define VM_CHECK_MODE 0
#endif

/**
 * VM Debug Level
 *
 * debug level:
 *  0: no debug output
 *  1: show instruction name
 *  2: show stack frame when control stack frame is changed
 *  3: show stack status
 *  4: show register
 *  5:
 * 10: gc check
 */

#ifndef VMDEBUG
#define VMDEBUG 0
#endif

#if 0
#undef  VMDEBUG
#define VMDEBUG 3
#endif

#include "ruby_assert.h"

#if VM_CHECK_MODE > 0
#define VM_ASSERT(expr) RUBY_ASSERT_MESG_WHEN(VM_CHECK_MODE > 0, expr, #expr)

#define VM_UNREACHABLE(func) rb_bug(#func ": unreachable")

#else
#define VM_ASSERT(expr) ((void)0)
#define VM_UNREACHABLE(func) UNREACHABLE
#endif

#define RUBY_VM_THREAD_MODEL 2

#include "ruby/ruby.h"
#include "ruby/st.h"

#include "node.h"
#include "vm_debug.h"
#include "vm_opts.h"
#include "id.h"
#include "method.h"
#include "ruby_atomic.h"
#include "ccan/list/list.h"

#include "ruby/thread_native.h"
#if   defined(_WIN32)
#include "thread_win32.h"
#elif defined(HAVE_PTHREAD_H)
#include "thread_pthread.h"
#endif

#include <setjmp.h>
#include <signal.h>

#ifndef NSIG
# define NSIG (_SIGMAX + 1)      /* For QNX */
#endif

#define RUBY_NSIG NSIG

#ifdef HAVE_STDARG_PROTOTYPES
#include <stdarg.h>
#define va_init_list(a,b) va_start((a),(b))
#else
#include <varargs.h>
#define va_init_list(a,b) va_start((a))
#endif

#if defined(SIGSEGV) && defined(HAVE_SIGALTSTACK) && defined(SA_SIGINFO) && !defined(__NetBSD__)
#define USE_SIGALTSTACK
#endif

/*****************/
/* configuration */
/*****************/

/* gcc ver. check */
#if defined(__GNUC__) && __GNUC__ >= 2

#if OPT_TOKEN_THREADED_CODE
#if OPT_DIRECT_THREADED_CODE
#undef OPT_DIRECT_THREADED_CODE
#endif
#endif

#else /* defined(__GNUC__) && __GNUC__ >= 2 */

/* disable threaded code options */
#if OPT_DIRECT_THREADED_CODE
#undef OPT_DIRECT_THREADED_CODE
#endif
#if OPT_TOKEN_THREADED_CODE
#undef OPT_TOKEN_THREADED_CODE
#endif
#endif

/* call threaded code */
#if    OPT_CALL_THREADED_CODE
#if    OPT_DIRECT_THREADED_CODE
#undef OPT_DIRECT_THREADED_CODE
#endif /* OPT_DIRECT_THREADED_CODE */
#if    OPT_STACK_CACHING
#undef OPT_STACK_CACHING
#endif /* OPT_STACK_CACHING */
#endif /* OPT_CALL_THREADED_CODE */

typedef unsigned long rb_num_t;

enum ruby_tag_type {
    RUBY_TAG_NONE	= 0x0,
    RUBY_TAG_RETURN	= 0x1,
    RUBY_TAG_BREAK	= 0x2,
    RUBY_TAG_NEXT	= 0x3,
    RUBY_TAG_RETRY	= 0x4,
    RUBY_TAG_REDO	= 0x5,
    RUBY_TAG_RAISE	= 0x6,
    RUBY_TAG_THROW	= 0x7,
    RUBY_TAG_FATAL	= 0x8,
    RUBY_TAG_MASK	= 0xf
};

#define TAG_NONE	RUBY_TAG_NONE
#define TAG_RETURN	RUBY_TAG_RETURN
#define TAG_BREAK	RUBY_TAG_BREAK
#define TAG_NEXT	RUBY_TAG_NEXT
#define TAG_RETRY	RUBY_TAG_RETRY
#define TAG_REDO	RUBY_TAG_REDO
#define TAG_RAISE	RUBY_TAG_RAISE
#define TAG_THROW	RUBY_TAG_THROW
#define TAG_FATAL	RUBY_TAG_FATAL
#define TAG_MASK	RUBY_TAG_MASK

enum ruby_vm_throw_flags {
    VM_THROW_NO_ESCAPE_FLAG = 0x8000,
    VM_THROW_LEVEL_SHIFT = 16,
    VM_THROW_STATE_MASK = 0xff
};

/* forward declarations */
struct rb_thread_struct;
struct rb_control_frame_struct;

/* iseq data type */
typedef struct rb_compile_option_struct rb_compile_option_t;

struct iseq_inline_cache_entry {
    rb_serial_t ic_serial;
    const rb_cref_t *ic_cref;
    union {
	size_t index;
	VALUE value;
    } ic_value;
};

union iseq_inline_storage_entry {
    struct {
	struct rb_thread_struct *running_thread;
	VALUE value;
    } once;
    struct iseq_inline_cache_entry cache;
};

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

struct rb_call_info {
    /* fixed at compile time */
    ID mid;
    unsigned int flag;
    int orig_argc;
};

struct rb_call_info_kw_arg {
    int keyword_len;
    VALUE keywords[1];
};

struct rb_call_info_with_kwarg {
    struct rb_call_info ci;
    struct rb_call_info_kw_arg *kw_arg;
};

struct rb_calling_info {
    VALUE block_handler;
    VALUE recv;
    int argc;
};

struct rb_call_cache;
struct rb_execution_context_struct;
typedef VALUE (*vm_call_handler)(struct rb_execution_context_struct *ec, struct rb_control_frame_struct *cfp, struct rb_calling_info *calling, const struct rb_call_info *ci, struct rb_call_cache *cc);

struct rb_call_cache {
    /* inline cache: keys */
    rb_serial_t method_state;
    rb_serial_t class_serial;

    /* inline cache: values */
    const rb_callable_method_entry_t *me;

    vm_call_handler call;

    union {
	unsigned int index; /* used by ivar */
	enum method_missing_reason method_missing_reason; /* used by method_missing */
	int inc_sp; /* used by cfunc */
    } aux;
};

#if 1
#define CoreDataFromValue(obj, type) (type*)DATA_PTR(obj)
#else
#define CoreDataFromValue(obj, type) (type*)rb_data_object_get(obj)
#endif
#define GetCoreDataFromValue(obj, type, ptr) ((ptr) = CoreDataFromValue((obj), type))

typedef struct rb_iseq_location_struct {
    VALUE pathobj;      /* String (path) or Array [path, realpath]. Frozen. */
    VALUE base_label;   /* String */
    VALUE label;        /* String */
    VALUE first_lineno; /* TODO: may be unsigned short */
    rb_code_range_t code_range;
} rb_iseq_location_t;

#define PATHOBJ_PATH     0
#define PATHOBJ_REALPATH 1

static inline VALUE
pathobj_path(VALUE pathobj)
{
    if (RB_TYPE_P(pathobj, T_STRING)) {
	return pathobj;
    }
    else {
	VM_ASSERT(RB_TYPE_P(pathobj, T_ARRAY));
	return RARRAY_AREF(pathobj, PATHOBJ_PATH);
    }
}

static inline VALUE
pathobj_realpath(VALUE pathobj)
{
    if (RB_TYPE_P(pathobj, T_STRING)) {
	return pathobj;
    }
    else {
	VM_ASSERT(RB_TYPE_P(pathobj, T_ARRAY));
	return RARRAY_AREF(pathobj, PATHOBJ_REALPATH);
    }
}

struct rb_iseq_constant_body {
    enum iseq_type {
	ISEQ_TYPE_TOP,
	ISEQ_TYPE_METHOD,
	ISEQ_TYPE_BLOCK,
	ISEQ_TYPE_CLASS,
	ISEQ_TYPE_RESCUE,
	ISEQ_TYPE_ENSURE,
	ISEQ_TYPE_EVAL,
	ISEQ_TYPE_MAIN,
	ISEQ_TYPE_DEFINED_GUARD
    } type;              /* instruction sequence type */

    unsigned int iseq_size;
    const VALUE *iseq_encoded; /* encoded iseq (insn addr and operands) */

    /**
     * parameter information
     *
     *  def m(a1, a2, ..., aM,                    # mandatory
     *        b1=(...), b2=(...), ..., bN=(...),  # optional
     *        *c,                                 # rest
     *        d1, d2, ..., dO,                    # post
     *        e1:(...), e2:(...), ..., eK:(...),  # keyword
     *        **f,                                # keyword_rest
     *        &g)                                 # block
     * =>
     *
     *  lead_num     = M
     *  opt_num      = N
     *  rest_start   = M+N
     *  post_start   = M+N+(*1)
     *  post_num     = O
     *  keyword_num  = K
     *  block_start  = M+N+(*1)+O+K
     *  keyword_bits = M+N+(*1)+O+K+(&1)
     *  size         = M+N+O+(*1)+K+(&1)+(**1) // parameter size.
     */

    struct {
	struct {
	    unsigned int has_lead   : 1;
	    unsigned int has_opt    : 1;
	    unsigned int has_rest   : 1;
	    unsigned int has_post   : 1;
	    unsigned int has_kw     : 1;
	    unsigned int has_kwrest : 1;
	    unsigned int has_block  : 1;

	    unsigned int ambiguous_param0 : 1; /* {|a|} */
	} flags;

	unsigned int size;

	int lead_num;
	int opt_num;
	int rest_start;
	int post_start;
	int post_num;
	int block_start;

	const VALUE *opt_table; /* (opt_num + 1) entries. */
	/* opt_num and opt_table:
	 *
	 * def foo o1=e1, o2=e2, ..., oN=eN
	 * #=>
	 *   # prologue code
	 *   A1: e1
	 *   A2: e2
	 *   ...
	 *   AN: eN
	 *   AL: body
	 * opt_num = N
	 * opt_table = [A1, A2, ..., AN, AL]
	 */

	const struct rb_iseq_param_keyword {
	    int num;
	    int required_num;
	    int bits_start;
	    int rest_start;
	    const ID *table;
	    const VALUE *default_values;
	} *keyword;
    } param;

    rb_iseq_location_t location;

    /* insn info, must be freed */
    const struct iseq_insn_info_entry *insns_info;

    const ID *local_table;		/* must free */

    /* catch table */
    const struct iseq_catch_table *catch_table;

    /* for child iseq */
    const struct rb_iseq_struct *parent_iseq;
    struct rb_iseq_struct *local_iseq; /* local_iseq->flip_cnt can be modified */

    union iseq_inline_storage_entry *is_entries;
    struct rb_call_info *ci_entries; /* struct rb_call_info ci_entries[ci_size];
				      * struct rb_call_info_with_kwarg cikw_entries[ci_kw_size];
				      * So that:
				      * struct rb_call_info_with_kwarg *cikw_entries = &body->ci_entries[ci_size];
				      */
    struct rb_call_cache *cc_entries; /* size is ci_size = ci_kw_size */

    VALUE mark_ary;     /* Array: includes operands which should be GC marked */

    unsigned int local_table_size;
    unsigned int is_size;
    unsigned int ci_size;
    unsigned int ci_kw_size;
    unsigned int insns_info_size;
    unsigned int stack_max; /* for stack overflow check */
};

/* T_IMEMO/iseq */
/* typedef rb_iseq_t is in method.h */
struct rb_iseq_struct {
    VALUE flags;
    VALUE reserved1;
    struct rb_iseq_constant_body *body;

    union { /* 4, 5 words */
	struct iseq_compile_data *compile_data; /* used at compile time */

	struct {
	    VALUE obj;
	    int index;
	} loader;

	rb_event_flag_t trace_events;
    } aux;
};

#ifndef USE_LAZY_LOAD
#define USE_LAZY_LOAD 0
#endif

#if USE_LAZY_LOAD
const rb_iseq_t *rb_iseq_complete(const rb_iseq_t *iseq);
#endif

static inline const rb_iseq_t *
rb_iseq_check(const rb_iseq_t *iseq)
{
#if USE_LAZY_LOAD
    if (iseq->body == NULL) {
	rb_iseq_complete((rb_iseq_t *)iseq);
    }
#endif
    return iseq;
}

enum ruby_special_exceptions {
    ruby_error_reenter,
    ruby_error_nomemory,
    ruby_error_sysstack,
    ruby_error_stackfatal,
    ruby_error_stream_closed,
    ruby_special_error_count
};

enum ruby_basic_operators {
    BOP_PLUS,
    BOP_MINUS,
    BOP_MULT,
    BOP_DIV,
    BOP_MOD,
    BOP_EQ,
    BOP_EQQ,
    BOP_LT,
    BOP_LE,
    BOP_LTLT,
    BOP_AREF,
    BOP_ASET,
    BOP_LENGTH,
    BOP_SIZE,
    BOP_EMPTY_P,
    BOP_SUCC,
    BOP_GT,
    BOP_GE,
    BOP_NOT,
    BOP_NEQ,
    BOP_MATCH,
    BOP_FREEZE,
    BOP_UMINUS,
    BOP_MAX,
    BOP_MIN,

    BOP_LAST_
};

#define GetVMPtr(obj, ptr) \
  GetCoreDataFromValue((obj), rb_vm_t, (ptr))

struct rb_vm_struct;
typedef void rb_vm_at_exit_func(struct rb_vm_struct*);

typedef struct rb_at_exit_list {
    rb_vm_at_exit_func *func;
    struct rb_at_exit_list *next;
} rb_at_exit_list;

struct rb_objspace;
struct rb_objspace *rb_objspace_alloc(void);
void rb_objspace_free(struct rb_objspace *);

typedef struct rb_hook_list_struct {
    struct rb_event_hook_struct *hooks;
    rb_event_flag_t events;
    int need_clean;
} rb_hook_list_t;

typedef struct rb_vm_struct {
    VALUE self;

    rb_global_vm_lock_t gvl;
    rb_nativethread_lock_t    thread_destruct_lock;

    struct rb_thread_struct *main_thread;
    struct rb_thread_struct *running_thread;

    struct list_head waiting_fds; /* <=> struct waiting_fd */
    struct list_head living_threads;
    size_t living_thread_num;
    VALUE thgroup_default;

    unsigned int running: 1;
    unsigned int thread_abort_on_exception: 1;
    unsigned int thread_report_on_exception: 1;
    int trace_running;
    volatile int sleeper;

    /* object management */
    VALUE mark_object_ary;
    const VALUE special_exceptions[ruby_special_error_count];

    /* load */
    VALUE top_self;
    VALUE load_path;
    VALUE load_path_snapshot;
    VALUE load_path_check_cache;
    VALUE expanded_load_path;
    VALUE loaded_features;
    VALUE loaded_features_snapshot;
    struct st_table *loaded_features_index;
    struct st_table *loading_table;

    /* signal */
    struct {
	VALUE cmd[RUBY_NSIG];
	unsigned char safe[RUBY_NSIG];
    } trap_list;

    /* hook */
    rb_hook_list_t event_hooks;

    /* relation table of ensure - rollback for callcc */
    struct st_table *ensure_rollback_table;

    /* postponed_job */
    struct rb_postponed_job_struct *postponed_job_buffer;
    int postponed_job_index;

    int src_encoding_index;

    VALUE verbose, debug, orig_progname, progname;
    VALUE coverages;
    int coverage_mode;

    VALUE defined_module_hash;

    struct rb_objspace *objspace;

    rb_at_exit_list *at_exit;

    VALUE *defined_strings;
    st_table *frozen_strings;

    /* params */
    struct { /* size in byte */
	size_t thread_vm_stack_size;
	size_t thread_machine_stack_size;
	size_t fiber_vm_stack_size;
	size_t fiber_machine_stack_size;
    } default_params;

    short redefined_flag[BOP_LAST_];
} rb_vm_t;

/* default values */

#define RUBY_VM_SIZE_ALIGN 4096

#define RUBY_VM_THREAD_VM_STACK_SIZE          ( 128 * 1024 * sizeof(VALUE)) /*  512 KB or 1024 KB */
#define RUBY_VM_THREAD_VM_STACK_SIZE_MIN      (   2 * 1024 * sizeof(VALUE)) /*    8 KB or   16 KB */
#define RUBY_VM_THREAD_MACHINE_STACK_SIZE     ( 128 * 1024 * sizeof(VALUE)) /*  512 KB or 1024 KB */
#define RUBY_VM_THREAD_MACHINE_STACK_SIZE_MIN (  16 * 1024 * sizeof(VALUE)) /*   64 KB or  128 KB */

#define RUBY_VM_FIBER_VM_STACK_SIZE           (  16 * 1024 * sizeof(VALUE)) /*   64 KB or  128 KB */
#define RUBY_VM_FIBER_VM_STACK_SIZE_MIN       (   2 * 1024 * sizeof(VALUE)) /*    8 KB or   16 KB */
#define RUBY_VM_FIBER_MACHINE_STACK_SIZE      (  64 * 1024 * sizeof(VALUE)) /*  256 KB or  512 KB */
#if defined(__powerpc64__)
#define RUBY_VM_FIBER_MACHINE_STACK_SIZE_MIN  (  32 * 1024 * sizeof(VALUE)) /*   128 KB or  256 KB */
#else
#define RUBY_VM_FIBER_MACHINE_STACK_SIZE_MIN  (  16 * 1024 * sizeof(VALUE)) /*   64 KB or  128 KB */
#endif

/* optimize insn */
#define INTEGER_REDEFINED_OP_FLAG (1 << 0)
#define FLOAT_REDEFINED_OP_FLAG  (1 << 1)
#define STRING_REDEFINED_OP_FLAG (1 << 2)
#define ARRAY_REDEFINED_OP_FLAG  (1 << 3)
#define HASH_REDEFINED_OP_FLAG   (1 << 4)
/* #define BIGNUM_REDEFINED_OP_FLAG (1 << 5) */
#define SYMBOL_REDEFINED_OP_FLAG (1 << 6)
#define TIME_REDEFINED_OP_FLAG   (1 << 7)
#define REGEXP_REDEFINED_OP_FLAG (1 << 8)
#define NIL_REDEFINED_OP_FLAG    (1 << 9)
#define TRUE_REDEFINED_OP_FLAG   (1 << 10)
#define FALSE_REDEFINED_OP_FLAG  (1 << 11)

#define BASIC_OP_UNREDEFINED_P(op, klass) (LIKELY((GET_VM()->redefined_flag[(op)]&(klass)) == 0))

#ifndef VM_DEBUG_BP_CHECK
#define VM_DEBUG_BP_CHECK 0
#endif

#ifndef VM_DEBUG_VERIFY_METHOD_CACHE
#define VM_DEBUG_VERIFY_METHOD_CACHE (VM_DEBUG_MODE != 0)
#endif

struct rb_captured_block {
    VALUE self;
    const VALUE *ep;
    union {
	const rb_iseq_t *iseq;
	const struct vm_ifunc *ifunc;
	VALUE val;
    } code;
};

enum rb_block_handler_type {
    block_handler_type_iseq,
    block_handler_type_ifunc,
    block_handler_type_symbol,
    block_handler_type_proc
};

enum rb_block_type {
    block_type_iseq,
    block_type_ifunc,
    block_type_symbol,
    block_type_proc
};

struct rb_block {
    union {
	struct rb_captured_block captured;
	VALUE symbol;
	VALUE proc;
    } as;
    enum rb_block_type type;
};

typedef struct rb_control_frame_struct {
    const VALUE *pc;		/* cfp[0] */
    VALUE *sp;			/* cfp[1] */
    const rb_iseq_t *iseq;	/* cfp[2] */
    VALUE self;			/* cfp[3] / block[0] */
    const VALUE *ep;		/* cfp[4] / block[1] */
    const void *block_code;     /* cfp[5] / block[2] */ /* iseq or ifunc */

#if VM_DEBUG_BP_CHECK
    VALUE *bp_check;		/* cfp[6] */
#endif
} rb_control_frame_t;

extern const rb_data_type_t ruby_threadptr_data_type;

static inline struct rb_thread_struct *
rb_thread_ptr(VALUE thval)
{
    return (struct rb_thread_struct *)rb_check_typeddata(thval, &ruby_threadptr_data_type);
}

enum rb_thread_status {
    THREAD_RUNNABLE,
    THREAD_STOPPED,
    THREAD_STOPPED_FOREVER,
    THREAD_KILLED
};

typedef RUBY_JMP_BUF rb_jmpbuf_t;

/*
  the members which are written in EC_PUSH_TAG() should be placed at
  the beginning and the end, so that entire region is accessible.
*/
struct rb_vm_tag {
    VALUE tag;
    VALUE retval;
    rb_jmpbuf_t buf;
    struct rb_vm_tag *prev;
    enum ruby_tag_type state;
};

STATIC_ASSERT(rb_vm_tag_buf_offset, offsetof(struct rb_vm_tag, buf) > 0);
STATIC_ASSERT(rb_vm_tag_buf_end,
	      offsetof(struct rb_vm_tag, buf) + sizeof(rb_jmpbuf_t) <
	      sizeof(struct rb_vm_tag));

struct rb_vm_protect_tag {
    struct rb_vm_protect_tag *prev;
};

struct rb_unblock_callback {
    rb_unblock_function_t *func;
    void *arg;
};

struct rb_mutex_struct;

typedef struct rb_thread_list_struct{
    struct rb_thread_list_struct *next;
    struct rb_thread_struct *th;
} rb_thread_list_t;

typedef struct rb_ensure_entry {
    VALUE marker;
    VALUE (*e_proc)(ANYARGS);
    VALUE data2;
} rb_ensure_entry_t;

typedef struct rb_ensure_list {
    struct rb_ensure_list *next;
    struct rb_ensure_entry entry;
} rb_ensure_list_t;

typedef char rb_thread_id_string_t[sizeof(rb_nativethread_id_t) * 2 + 3];

typedef struct rb_fiber_struct rb_fiber_t;

typedef struct rb_execution_context_struct {
    /* execution information */
    VALUE *vm_stack;		/* must free, must mark */
    size_t vm_stack_size;       /* size in word (byte size / sizeof(VALUE)) */
    rb_control_frame_t *cfp;

    struct rb_vm_tag *tag;
    struct rb_vm_protect_tag *protect_tag;
    int safe_level;
    int raised_flag;

    /* interrupt flags */
    rb_atomic_t interrupt_flag;
    unsigned long interrupt_mask;

    rb_fiber_t *fiber_ptr;
    struct rb_thread_struct *thread_ptr;

    /* storage (ec (fiber) local) */
    st_table *local_storage;
    VALUE local_storage_recursive_hash;
    VALUE local_storage_recursive_hash_for_trace;

    /* eval env */
    const VALUE *root_lep;
    VALUE root_svar;

    /* ensure & callcc */
    rb_ensure_list_t *ensure_list;

    /* trace information */
    struct rb_trace_arg_struct *trace_arg;

    /* temporary places */
    VALUE errinfo;
    VALUE passed_block_handler; /* for rb_iterate */
    const rb_callable_method_entry_t *passed_bmethod_me; /* for bmethod */
    enum method_missing_reason method_missing_reason;

    /* for GC */
    struct {
	VALUE *stack_start;
	VALUE *stack_end;
	size_t stack_maxsize;
#ifdef __ia64
	VALUE *register_stack_start;
	VALUE *register_stack_end;
	size_t register_stack_maxsize;
#endif
	jmp_buf regs;
    } machine;
} rb_execution_context_t;

void ec_set_vm_stack(rb_execution_context_t *ec, VALUE *stack, size_t size);

typedef struct rb_thread_struct {
    struct list_node vmlt_node;
    VALUE self;
    rb_vm_t *vm;

    rb_execution_context_t *ec;

    VALUE last_status; /* $? */

    /* for cfunc */
    struct rb_calling_info *calling;

    /* for load(true) */
    VALUE top_self;
    VALUE top_wrapper;

    /* thread control */
    rb_nativethread_id_t thread_id;
#ifdef NON_SCALAR_THREAD_ID
    rb_thread_id_string_t thread_id_string;
#endif
    enum rb_thread_status status;
    int to_kill;
    int priority;

    native_thread_data_t native_thread_data;
    void *blocking_region_buffer;

    VALUE thgroup;
    VALUE value;

    /* temporary place of retval on OPT_CALL_THREADED_CODE */
#if OPT_CALL_THREADED_CODE
    VALUE retval;
#endif

    /* async errinfo queue */
    VALUE pending_interrupt_queue;
    VALUE pending_interrupt_mask_stack;
    int pending_interrupt_queue_checked;

    /* interrupt management */
    rb_nativethread_lock_t interrupt_lock;
    struct rb_unblock_callback unblock;
    VALUE locking_mutex;
    struct rb_mutex_struct *keeping_mutexes;

    rb_thread_list_t *join_list;

    VALUE first_proc;
    VALUE first_args;
    VALUE (*first_func)(ANYARGS);

    /* statistics data for profiler */
    VALUE stat_insn_usage;

    /* fiber */
    rb_fiber_t *root_fiber;
    rb_jmpbuf_t root_jmpbuf;

    /* misc */
    unsigned int abort_on_exception: 1;
    unsigned int report_on_exception: 1;
#ifdef USE_SIGALTSTACK
    void *altstack;
#endif
    uint32_t running_time_us; /* 12500..800000 */
    VALUE name;
} rb_thread_t;

typedef enum {
    VM_DEFINECLASS_TYPE_CLASS           = 0x00,
    VM_DEFINECLASS_TYPE_SINGLETON_CLASS = 0x01,
    VM_DEFINECLASS_TYPE_MODULE          = 0x02,
    /* 0x03..0x06 is reserved */
    VM_DEFINECLASS_TYPE_MASK            = 0x07
} rb_vm_defineclass_type_t;

#define VM_DEFINECLASS_TYPE(x) ((rb_vm_defineclass_type_t)(x) & VM_DEFINECLASS_TYPE_MASK)
#define VM_DEFINECLASS_FLAG_SCOPED         0x08
#define VM_DEFINECLASS_FLAG_HAS_SUPERCLASS 0x10
#define VM_DEFINECLASS_SCOPED_P(x) ((x) & VM_DEFINECLASS_FLAG_SCOPED)
#define VM_DEFINECLASS_HAS_SUPERCLASS_P(x) \
    ((x) & VM_DEFINECLASS_FLAG_HAS_SUPERCLASS)

/* iseq.c */
RUBY_SYMBOL_EXPORT_BEGIN

/* node -> iseq */
rb_iseq_t *rb_iseq_new         (const NODE *node, VALUE name, VALUE path, VALUE realpath, const rb_iseq_t *parent, enum iseq_type);
rb_iseq_t *rb_iseq_new_top     (const NODE *node, VALUE name, VALUE path, VALUE realpath, const rb_iseq_t *parent);
rb_iseq_t *rb_iseq_new_main    (const NODE *node,             VALUE path, VALUE realpath, const rb_iseq_t *parent);
rb_iseq_t *rb_iseq_new_with_opt(const NODE *node, VALUE name, VALUE path, VALUE realpath, VALUE first_lineno,
				const rb_iseq_t *parent, enum iseq_type, const rb_compile_option_t*);

/* src -> iseq */
rb_iseq_t *rb_iseq_compile(VALUE src, VALUE file, VALUE line);
rb_iseq_t *rb_iseq_compile_on_base(VALUE src, VALUE file, VALUE line, const struct rb_block *base_block);
rb_iseq_t *rb_iseq_compile_with_option(VALUE src, VALUE file, VALUE realpath, VALUE line, const struct rb_block *base_block, VALUE opt);

VALUE rb_iseq_disasm(const rb_iseq_t *iseq);
int rb_iseq_disasm_insn(VALUE str, const VALUE *iseqval, size_t pos, const rb_iseq_t *iseq, VALUE child);
const char *ruby_node_name(int node);

VALUE rb_iseq_coverage(const rb_iseq_t *iseq);

RUBY_EXTERN VALUE rb_cISeq;
RUBY_EXTERN VALUE rb_cRubyVM;
RUBY_EXTERN VALUE rb_mRubyVMFrozenCore;
RUBY_SYMBOL_EXPORT_END

#define GetProcPtr(obj, ptr) \
  GetCoreDataFromValue((obj), rb_proc_t, (ptr))

typedef struct {
    const struct rb_block block;
    int8_t safe_level;		/* 0..1 */
    int8_t is_from_method;	/* bool */
    int8_t is_lambda;		/* bool */
} rb_proc_t;

typedef struct {
    VALUE flags; /* imemo header */
    const rb_iseq_t *iseq;
    const VALUE *ep;
    const VALUE *env;
    unsigned int env_size;
} rb_env_t;

extern const rb_data_type_t ruby_binding_data_type;

#define GetBindingPtr(obj, ptr) \
  GetCoreDataFromValue((obj), rb_binding_t, (ptr))

typedef struct {
    const struct rb_block block;
    const VALUE pathobj;
    unsigned short first_lineno;
} rb_binding_t;

/* used by compile time and send insn */

enum vm_check_match_type {
    VM_CHECKMATCH_TYPE_WHEN = 1,
    VM_CHECKMATCH_TYPE_CASE = 2,
    VM_CHECKMATCH_TYPE_RESCUE = 3
};

#define VM_CHECKMATCH_TYPE_MASK   0x03
#define VM_CHECKMATCH_ARRAY       0x04

enum vm_call_flag_bits {
    VM_CALL_ARGS_SPLAT_bit,     /* m(*args) */
    VM_CALL_ARGS_BLOCKARG_bit,  /* m(&block) */
    VM_CALL_ARGS_BLOCKARG_BLOCKPARAM_bit,  /* m(&block) and block is a passed block parameter */
    VM_CALL_FCALL_bit,          /* m(...) */
    VM_CALL_VCALL_bit,          /* m */
    VM_CALL_ARGS_SIMPLE_bit,    /* (ci->flag & (SPLAT|BLOCKARG)) && blockiseq == NULL && ci->kw_arg == NULL */
    VM_CALL_BLOCKISEQ_bit,      /* has blockiseq */
    VM_CALL_KWARG_bit,          /* has kwarg */
    VM_CALL_KW_SPLAT_bit,       /* m(**opts) */
    VM_CALL_TAILCALL_bit,       /* located at tail position */
    VM_CALL_SUPER_bit,          /* super */
    VM_CALL_OPT_SEND_bit,       /* internal flag */
    VM_CALL__END
};

#define VM_CALL_ARGS_SPLAT      (0x01 << VM_CALL_ARGS_SPLAT_bit)
#define VM_CALL_ARGS_BLOCKARG   (0x01 << VM_CALL_ARGS_BLOCKARG_bit)
#define VM_CALL_ARGS_BLOCKARG_BLOCKPARAM (0x01 << VM_CALL_ARGS_BLOCKARG_BLOCKPARAM_bit)
#define VM_CALL_FCALL           (0x01 << VM_CALL_FCALL_bit)
#define VM_CALL_VCALL           (0x01 << VM_CALL_VCALL_bit)
#define VM_CALL_ARGS_SIMPLE     (0x01 << VM_CALL_ARGS_SIMPLE_bit)
#define VM_CALL_BLOCKISEQ       (0x01 << VM_CALL_BLOCKISEQ_bit)
#define VM_CALL_KWARG           (0x01 << VM_CALL_KWARG_bit)
#define VM_CALL_KW_SPLAT        (0x01 << VM_CALL_KW_SPLAT_bit)
#define VM_CALL_TAILCALL        (0x01 << VM_CALL_TAILCALL_bit)
#define VM_CALL_SUPER           (0x01 << VM_CALL_SUPER_bit)
#define VM_CALL_OPT_SEND        (0x01 << VM_CALL_OPT_SEND_bit)

enum vm_special_object_type {
    VM_SPECIAL_OBJECT_VMCORE = 1,
    VM_SPECIAL_OBJECT_CBASE,
    VM_SPECIAL_OBJECT_CONST_BASE
};

enum vm_svar_index {
    VM_SVAR_LASTLINE = 0,      /* $_ */
    VM_SVAR_BACKREF = 1,       /* $~ */

    VM_SVAR_EXTRA_START = 2,
    VM_SVAR_FLIPFLOP_START = 2 /* flipflop */
};

/* inline cache */
typedef struct iseq_inline_cache_entry *IC;
typedef struct rb_call_info *CALL_INFO;
typedef struct rb_call_cache *CALL_CACHE;

void rb_vm_change_state(void);

typedef VALUE CDHASH;

#ifndef FUNC_FASTCALL
#define FUNC_FASTCALL(x) x
#endif

typedef rb_control_frame_t *
  (FUNC_FASTCALL(*rb_insn_func_t))(rb_execution_context_t *, rb_control_frame_t *);

#define VM_TAGGED_PTR_SET(p, tag)  ((VALUE)(p) | (tag))
#define VM_TAGGED_PTR_REF(v, mask) ((void *)((v) & ~mask))

#define GC_GUARDED_PTR(p)     VM_TAGGED_PTR_SET((p), 0x01)
#define GC_GUARDED_PTR_REF(p) VM_TAGGED_PTR_REF((p), 0x03)
#define GC_GUARDED_PTR_P(p)   (((VALUE)(p)) & 0x01)

enum {
    /* Frame/Environment flag bits:
     *   MMMM MMMM MMMM MMMM ____ __FF FFFF EEEX (LSB)
     *
     * X   : tag for GC marking (It seems as Fixnum)
     * EEE : 3 bits Env flags
     * FF..: 6 bits Frame flags
     * MM..: 16 bits frame magic (to check frame corruption)
     */

    /* frame types */
    VM_FRAME_MAGIC_METHOD = 0x11110001,
    VM_FRAME_MAGIC_BLOCK  = 0x22220001,
    VM_FRAME_MAGIC_CLASS  = 0x33330001,
    VM_FRAME_MAGIC_TOP    = 0x44440001,
    VM_FRAME_MAGIC_CFUNC  = 0x55550001,
    VM_FRAME_MAGIC_IFUNC  = 0x66660001,
    VM_FRAME_MAGIC_EVAL   = 0x77770001,
    VM_FRAME_MAGIC_RESCUE = 0x88880001,
    VM_FRAME_MAGIC_DUMMY  = 0x99990001,

    VM_FRAME_MAGIC_MASK   = 0xffff0001,

    /* frame flag */
    VM_FRAME_FLAG_PASSED    = 0x0010,
    VM_FRAME_FLAG_FINISH    = 0x0020,
    VM_FRAME_FLAG_BMETHOD   = 0x0040,
    VM_FRAME_FLAG_CFRAME    = 0x0080,
    VM_FRAME_FLAG_LAMBDA    = 0x0100,
    VM_FRAME_FLAG_MODIFIED_BLOCK_PARAM = 0x0200,

    /* env flag */
    VM_ENV_FLAG_LOCAL       = 0x0002,
    VM_ENV_FLAG_ESCAPED     = 0x0004,
    VM_ENV_FLAG_WB_REQUIRED = 0x0008
};

#define VM_ENV_DATA_SIZE             ( 3)

#define VM_ENV_DATA_INDEX_ME_CREF    (-2) /* ep[-2] */
#define VM_ENV_DATA_INDEX_SPECVAL    (-1) /* ep[-1] */
#define VM_ENV_DATA_INDEX_FLAGS      ( 0) /* ep[ 0] */
#define VM_ENV_DATA_INDEX_ENV        ( 1) /* ep[ 1] */
#define VM_ENV_DATA_INDEX_ENV_PROC   ( 2) /* ep[ 2] */

#define VM_ENV_INDEX_LAST_LVAR              (-VM_ENV_DATA_SIZE)

static inline void VM_FORCE_WRITE_SPECIAL_CONST(const VALUE *ptr, VALUE special_const_value);

static inline void
VM_ENV_FLAGS_SET(const VALUE *ep, VALUE flag)
{
    VALUE flags = ep[VM_ENV_DATA_INDEX_FLAGS];
    VM_ASSERT(FIXNUM_P(flags));
    VM_FORCE_WRITE_SPECIAL_CONST(&ep[VM_ENV_DATA_INDEX_FLAGS], flags | flag);
}

static inline void
VM_ENV_FLAGS_UNSET(const VALUE *ep, VALUE flag)
{
    VALUE flags = ep[VM_ENV_DATA_INDEX_FLAGS];
    VM_ASSERT(FIXNUM_P(flags));
    VM_FORCE_WRITE_SPECIAL_CONST(&ep[VM_ENV_DATA_INDEX_FLAGS], flags & ~flag);
}

static inline unsigned long
VM_ENV_FLAGS(const VALUE *ep, long flag)
{
    VALUE flags = ep[VM_ENV_DATA_INDEX_FLAGS];
    VM_ASSERT(FIXNUM_P(flags));
    return flags & flag;
}

static inline unsigned long
VM_FRAME_TYPE(const rb_control_frame_t *cfp)
{
    return VM_ENV_FLAGS(cfp->ep, VM_FRAME_MAGIC_MASK);
}

static inline int
VM_FRAME_LAMBDA_P(const rb_control_frame_t *cfp)
{
    return VM_ENV_FLAGS(cfp->ep, VM_FRAME_FLAG_LAMBDA) != 0;
}

static inline int
VM_FRAME_FINISHED_P(const rb_control_frame_t *cfp)
{
    return VM_ENV_FLAGS(cfp->ep, VM_FRAME_FLAG_FINISH) != 0;
}

static inline int
VM_FRAME_BMETHOD_P(const rb_control_frame_t *cfp)
{
    return VM_ENV_FLAGS(cfp->ep, VM_FRAME_FLAG_BMETHOD) != 0;
}

static inline int
rb_obj_is_iseq(VALUE iseq)
{
    return imemo_type_p(iseq, imemo_iseq);
}

#if VM_CHECK_MODE > 0
#define RUBY_VM_NORMAL_ISEQ_P(iseq)  rb_obj_is_iseq((VALUE)iseq)
#endif

static inline int
VM_FRAME_CFRAME_P(const rb_control_frame_t *cfp)
{
    int cframe_p = VM_ENV_FLAGS(cfp->ep, VM_FRAME_FLAG_CFRAME) != 0;
    VM_ASSERT(RUBY_VM_NORMAL_ISEQ_P(cfp->iseq) != cframe_p);
    return cframe_p;
}

static inline int
VM_FRAME_RUBYFRAME_P(const rb_control_frame_t *cfp)
{
    return !VM_FRAME_CFRAME_P(cfp);
}

#define RUBYVM_CFUNC_FRAME_P(cfp) \
  (VM_FRAME_TYPE(cfp) == VM_FRAME_MAGIC_CFUNC)

#define VM_GUARDED_PREV_EP(ep)         GC_GUARDED_PTR(ep)
#define VM_BLOCK_HANDLER_NONE 0

static inline int
VM_ENV_LOCAL_P(const VALUE *ep)
{
    return VM_ENV_FLAGS(ep, VM_ENV_FLAG_LOCAL) ? 1 : 0;
}

static inline const VALUE *
VM_ENV_PREV_EP(const VALUE *ep)
{
    VM_ASSERT(VM_ENV_LOCAL_P(ep) == 0);
    return GC_GUARDED_PTR_REF(ep[VM_ENV_DATA_INDEX_SPECVAL]);
}

static inline VALUE
VM_ENV_BLOCK_HANDLER(const VALUE *ep)
{
    VM_ASSERT(VM_ENV_LOCAL_P(ep));
    return ep[VM_ENV_DATA_INDEX_SPECVAL];
}

#if VM_CHECK_MODE > 0
int rb_vm_ep_in_heap_p(const VALUE *ep);
#endif

static inline int
VM_ENV_ESCAPED_P(const VALUE *ep)
{
    VM_ASSERT(rb_vm_ep_in_heap_p(ep) == !!VM_ENV_FLAGS(ep, VM_ENV_FLAG_ESCAPED));
    return VM_ENV_FLAGS(ep, VM_ENV_FLAG_ESCAPED) ? 1 : 0;
}

#if VM_CHECK_MODE > 0
static inline int
vm_assert_env(VALUE obj)
{
    VM_ASSERT(imemo_type_p(obj, imemo_env));
    return 1;
}
#endif

static inline VALUE
VM_ENV_ENVVAL(const VALUE *ep)
{
    VALUE envval = ep[VM_ENV_DATA_INDEX_ENV];
    VM_ASSERT(VM_ENV_ESCAPED_P(ep));
    VM_ASSERT(vm_assert_env(envval));
    return envval;
}

static inline const rb_env_t *
VM_ENV_ENVVAL_PTR(const VALUE *ep)
{
    return (const rb_env_t *)VM_ENV_ENVVAL(ep);
}

static inline VALUE
VM_ENV_PROCVAL(const VALUE *ep)
{
    VM_ASSERT(VM_ENV_ESCAPED_P(ep));
    VM_ASSERT(VM_ENV_LOCAL_P(ep));
    VM_ASSERT(VM_ENV_BLOCK_HANDLER(ep) != VM_BLOCK_HANDLER_NONE);

    return ep[VM_ENV_DATA_INDEX_ENV_PROC];
}

static inline const rb_env_t *
vm_env_new(VALUE *env_ep, VALUE *env_body, unsigned int env_size, const rb_iseq_t *iseq)
{
    rb_env_t *env = (rb_env_t *)rb_imemo_new(imemo_env, (VALUE)env_ep, (VALUE)env_body, 0, (VALUE)iseq);
    env->env_size = env_size;
    env_ep[VM_ENV_DATA_INDEX_ENV] = (VALUE)env;
    return env;
}

static inline void
VM_FORCE_WRITE(const VALUE *ptr, VALUE v)
{
    *((VALUE *)ptr) = v;
}

static inline void
VM_FORCE_WRITE_SPECIAL_CONST(const VALUE *ptr, VALUE special_const_value)
{
    VM_ASSERT(RB_SPECIAL_CONST_P(special_const_value));
    VM_FORCE_WRITE(ptr, special_const_value);
}

static inline void
VM_STACK_ENV_WRITE(const VALUE *ep, int index, VALUE v)
{
    VM_ASSERT(VM_ENV_FLAGS(ep, VM_ENV_FLAG_WB_REQUIRED) == 0);
    VM_FORCE_WRITE(&ep[index], v);
}

const VALUE *rb_vm_ep_local_ep(const VALUE *ep);
const VALUE *rb_vm_proc_local_ep(VALUE proc);
void rb_vm_block_ep_update(VALUE obj, const struct rb_block *dst, const VALUE *ep);
void rb_vm_block_copy(VALUE obj, const struct rb_block *dst, const struct rb_block *src);

VALUE rb_vm_frame_block_handler(const rb_control_frame_t *cfp);

#define RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp) ((cfp)+1)
#define RUBY_VM_NEXT_CONTROL_FRAME(cfp) ((cfp)-1)

#define RUBY_VM_VALID_CONTROL_FRAME_P(cfp, ecfp) \
  ((void *)(ecfp) > (void *)(cfp))

static inline const rb_control_frame_t *
RUBY_VM_END_CONTROL_FRAME(const rb_execution_context_t *ec)
{
    return (rb_control_frame_t *)(ec->vm_stack + ec->vm_stack_size);
}

static inline int
RUBY_VM_CONTROL_FRAME_STACK_OVERFLOW_P(const rb_execution_context_t *ec, const rb_control_frame_t *cfp)
{
    return !RUBY_VM_VALID_CONTROL_FRAME_P(cfp, RUBY_VM_END_CONTROL_FRAME(ec));
}

static inline int
VM_BH_ISEQ_BLOCK_P(VALUE block_handler)
{
    if ((block_handler & 0x03) == 0x01) {
#if VM_CHECK_MODE > 0
	struct rb_captured_block *captured = VM_TAGGED_PTR_REF(block_handler, 0x03);
	VM_ASSERT(imemo_type_p(captured->code.val, imemo_iseq));
#endif
	return 1;
    }
    else {
	return 0;
    }
}

static inline VALUE
VM_BH_FROM_ISEQ_BLOCK(const struct rb_captured_block *captured)
{
    VALUE block_handler = VM_TAGGED_PTR_SET(captured, 0x01);
    VM_ASSERT(VM_BH_ISEQ_BLOCK_P(block_handler));
    return block_handler;
}

static inline const struct rb_captured_block *
VM_BH_TO_ISEQ_BLOCK(VALUE block_handler)
{
    struct rb_captured_block *captured = VM_TAGGED_PTR_REF(block_handler, 0x03);
    VM_ASSERT(VM_BH_ISEQ_BLOCK_P(block_handler));
    return captured;
}

static inline int
VM_BH_IFUNC_P(VALUE block_handler)
{
    if ((block_handler & 0x03) == 0x03) {
#if VM_CHECK_MODE > 0
	struct rb_captured_block *captured = (void *)(block_handler & ~0x03);
	VM_ASSERT(imemo_type_p(captured->code.val, imemo_ifunc));
#endif
	return 1;
    }
    else {
	return 0;
    }
}

static inline VALUE
VM_BH_FROM_IFUNC_BLOCK(const struct rb_captured_block *captured)
{
    VALUE block_handler = VM_TAGGED_PTR_SET(captured, 0x03);
    VM_ASSERT(VM_BH_IFUNC_P(block_handler));
    return block_handler;
}

static inline const struct rb_captured_block *
VM_BH_TO_IFUNC_BLOCK(VALUE block_handler)
{
    struct rb_captured_block *captured = VM_TAGGED_PTR_REF(block_handler, 0x03);
    VM_ASSERT(VM_BH_IFUNC_P(block_handler));
    return captured;
}

static inline const struct rb_captured_block *
VM_BH_TO_CAPT_BLOCK(VALUE block_handler)
{
    struct rb_captured_block *captured = VM_TAGGED_PTR_REF(block_handler, 0x03);
    VM_ASSERT(VM_BH_IFUNC_P(block_handler) || VM_BH_ISEQ_BLOCK_P(block_handler));
    return captured;
}

static inline enum rb_block_handler_type
vm_block_handler_type(VALUE block_handler)
{
    if (VM_BH_ISEQ_BLOCK_P(block_handler)) {
	return block_handler_type_iseq;
    }
    else if (VM_BH_IFUNC_P(block_handler)) {
	return block_handler_type_ifunc;
    }
    else if (SYMBOL_P(block_handler)) {
	return block_handler_type_symbol;
    }
    else {
	VM_ASSERT(rb_obj_is_proc(block_handler));
	return block_handler_type_proc;
    }
}

static inline void
vm_block_handler_verify(MAYBE_UNUSED(VALUE block_handler))
{
    VM_ASSERT(block_handler == VM_BLOCK_HANDLER_NONE ||
	      (vm_block_handler_type(block_handler), 1));
}

static inline enum rb_block_type
vm_block_type(const struct rb_block *block)
{
#if VM_CHECK_MODE > 0
    switch (block->type) {
      case block_type_iseq:
	VM_ASSERT(imemo_type_p(block->as.captured.code.val, imemo_iseq));
	break;
      case block_type_ifunc:
	VM_ASSERT(imemo_type_p(block->as.captured.code.val, imemo_ifunc));
	break;
      case block_type_symbol:
	VM_ASSERT(SYMBOL_P(block->as.symbol));
	break;
      case block_type_proc:
	VM_ASSERT(rb_obj_is_proc(block->as.proc));
	break;
    }
#endif
    return block->type;
}

static inline void
vm_block_type_set(const struct rb_block *block, enum rb_block_type type)
{
    struct rb_block *mb = (struct rb_block *)block;
    mb->type = type;
}

static inline const struct rb_block *
vm_proc_block(VALUE procval)
{
    VM_ASSERT(rb_obj_is_proc(procval));
    return &((rb_proc_t *)RTYPEDDATA_DATA(procval))->block;
}

static inline const rb_iseq_t *vm_block_iseq(const struct rb_block *block);
static inline const VALUE *vm_block_ep(const struct rb_block *block);

static inline const rb_iseq_t *
vm_proc_iseq(VALUE procval)
{
    return vm_block_iseq(vm_proc_block(procval));
}

static inline const VALUE *
vm_proc_ep(VALUE procval)
{
    return vm_block_ep(vm_proc_block(procval));
}

static inline const rb_iseq_t *
vm_block_iseq(const struct rb_block *block)
{
    switch (vm_block_type(block)) {
      case block_type_iseq: return rb_iseq_check(block->as.captured.code.iseq);
      case block_type_proc: return vm_proc_iseq(block->as.proc);
      case block_type_ifunc:
      case block_type_symbol: return NULL;
    }
    VM_UNREACHABLE(vm_block_iseq);
    return NULL;
}

static inline const VALUE *
vm_block_ep(const struct rb_block *block)
{
    switch (vm_block_type(block)) {
      case block_type_iseq:
      case block_type_ifunc:  return block->as.captured.ep;
      case block_type_proc:   return vm_proc_ep(block->as.proc);
      case block_type_symbol: return NULL;
    }
    VM_UNREACHABLE(vm_block_ep);
    return NULL;
}

static inline VALUE
vm_block_self(const struct rb_block *block)
{
    switch (vm_block_type(block)) {
      case block_type_iseq:
      case block_type_ifunc:
	return block->as.captured.self;
      case block_type_proc:
	return vm_block_self(vm_proc_block(block->as.proc));
      case block_type_symbol:
	return Qundef;
    }
    VM_UNREACHABLE(vm_block_self);
    return Qundef;
}

static inline VALUE
VM_BH_TO_SYMBOL(VALUE block_handler)
{
    VM_ASSERT(SYMBOL_P(block_handler));
    return block_handler;
}

static inline VALUE
VM_BH_FROM_SYMBOL(VALUE symbol)
{
    VM_ASSERT(SYMBOL_P(symbol));
    return symbol;
}

static inline VALUE
VM_BH_TO_PROC(VALUE block_handler)
{
    VM_ASSERT(rb_obj_is_proc(block_handler));
    return block_handler;
}

static inline VALUE
VM_BH_FROM_PROC(VALUE procval)
{
    VM_ASSERT(rb_obj_is_proc(procval));
    return procval;
}

/* VM related object allocate functions */
VALUE rb_thread_alloc(VALUE klass);
VALUE rb_proc_alloc(VALUE klass);
VALUE rb_binding_alloc(VALUE klass);

/* for debug */
extern void rb_vmdebug_stack_dump_raw(const rb_execution_context_t *ec, const rb_control_frame_t *cfp);
extern void rb_vmdebug_debug_print_pre(const rb_execution_context_t *ec, const rb_control_frame_t *cfp, const VALUE *_pc);
extern void rb_vmdebug_debug_print_post(const rb_execution_context_t *ec, const rb_control_frame_t *cfp);

#define SDR() rb_vmdebug_stack_dump_raw(GET_EC(), GET_EC()->cfp)
#define SDR2(cfp) rb_vmdebug_stack_dump_raw(GET_EC(), (cfp))
void rb_vm_bugreport(const void *);
NORETURN(void rb_bug_context(const void *, const char *fmt, ...));

/* functions about thread/vm execution */
RUBY_SYMBOL_EXPORT_BEGIN
VALUE rb_iseq_eval(const rb_iseq_t *iseq);
VALUE rb_iseq_eval_main(const rb_iseq_t *iseq);
VALUE rb_iseq_path(const rb_iseq_t *iseq);
VALUE rb_iseq_realpath(const rb_iseq_t *iseq);
RUBY_SYMBOL_EXPORT_END

VALUE rb_iseq_pathobj_new(VALUE path, VALUE realpath);
void rb_iseq_pathobj_set(const rb_iseq_t *iseq, VALUE path, VALUE realpath);

int rb_ec_frame_method_id_and_class(const rb_execution_context_t *ec, ID *idp, ID *called_idp, VALUE *klassp);
void rb_ec_setup_exception(const rb_execution_context_t *ec, VALUE mesg, VALUE cause);

VALUE rb_vm_invoke_proc(rb_execution_context_t *ec, rb_proc_t *proc, int argc, const VALUE *argv, VALUE block_handler);

VALUE rb_vm_make_proc_lambda(const rb_execution_context_t *ec, const struct rb_captured_block *captured, VALUE klass, int8_t is_lambda);
static inline VALUE
rb_vm_make_proc(const rb_execution_context_t *ec, const struct rb_captured_block *captured, VALUE klass)
{
    return rb_vm_make_proc_lambda(ec, captured, klass, 0);
}

static inline VALUE
rb_vm_make_lambda(const rb_execution_context_t *ec, const struct rb_captured_block *captured, VALUE klass)
{
    return rb_vm_make_proc_lambda(ec, captured, klass, 1);
}

VALUE rb_vm_make_binding(const rb_execution_context_t *ec, const rb_control_frame_t *src_cfp);
VALUE rb_vm_env_local_variables(const rb_env_t *env);
const rb_env_t *rb_vm_env_prev_env(const rb_env_t *env);
const VALUE *rb_binding_add_dynavars(VALUE bindval, rb_binding_t *bind, int dyncount, const ID *dynvars);
void rb_vm_inc_const_missing_count(void);
void rb_vm_gvl_destroy(rb_vm_t *vm);
VALUE rb_vm_call(rb_execution_context_t *ec, VALUE recv, VALUE id, int argc,
		 const VALUE *argv, const rb_callable_method_entry_t *me);
void rb_vm_pop_frame(rb_execution_context_t *ec);

void rb_thread_start_timer_thread(void);
void rb_thread_stop_timer_thread(void);
void rb_thread_reset_timer_thread(void);
void rb_thread_wakeup_timer_thread(void);

static inline void
rb_vm_living_threads_init(rb_vm_t *vm)
{
    list_head_init(&vm->waiting_fds);
    list_head_init(&vm->living_threads);
    vm->living_thread_num = 0;
}

static inline void
rb_vm_living_threads_insert(rb_vm_t *vm, rb_thread_t *th)
{
    list_add_tail(&vm->living_threads, &th->vmlt_node);
    vm->living_thread_num++;
}

static inline void
rb_vm_living_threads_remove(rb_vm_t *vm, rb_thread_t *th)
{
    list_del(&th->vmlt_node);
    vm->living_thread_num--;
}

typedef int rb_backtrace_iter_func(void *, VALUE, int, VALUE);
rb_control_frame_t *rb_vm_get_ruby_level_next_cfp(const rb_execution_context_t *ec, const rb_control_frame_t *cfp);
rb_control_frame_t *rb_vm_get_binding_creatable_next_cfp(const rb_execution_context_t *ec, const rb_control_frame_t *cfp);
int rb_vm_get_sourceline(const rb_control_frame_t *);
VALUE rb_name_err_mesg_new(VALUE mesg, VALUE recv, VALUE method);
void rb_vm_stack_to_heap(rb_execution_context_t *ec);
void ruby_thread_init_stack(rb_thread_t *th);
int rb_vm_control_frame_id_and_class(const rb_control_frame_t *cfp, ID *idp, ID *called_idp, VALUE *klassp);
void rb_vm_rewind_cfp(rb_execution_context_t *ec, rb_control_frame_t *cfp);
VALUE rb_vm_bh_to_procval(const rb_execution_context_t *ec, VALUE block_handler);

void rb_vm_register_special_exception_str(enum ruby_special_exceptions sp, VALUE exception_class, VALUE mesg);

#define rb_vm_register_special_exception(sp, e, m) \
    rb_vm_register_special_exception_str(sp, e, rb_usascii_str_new_static((m), (long)rb_strlen_lit(m)))

void rb_gc_mark_machine_stack(const rb_execution_context_t *ec);

int rb_autoloading_value(VALUE mod, ID id, VALUE* value);

void rb_vm_rewrite_cref(rb_cref_t *node, VALUE old_klass, VALUE new_klass, rb_cref_t **new_cref_ptr);

const rb_callable_method_entry_t *rb_vm_frame_method_entry(const rb_control_frame_t *cfp);

#define sysstack_error GET_VM()->special_exceptions[ruby_error_sysstack]

#define RUBY_CONST_ASSERT(expr) (1/!!(expr)) /* expr must be a compile-time constant */
#define VM_STACK_OVERFLOWED_P(cfp, sp, margin) \
    (!RUBY_CONST_ASSERT(sizeof(*(sp)) == sizeof(VALUE)) || \
     !RUBY_CONST_ASSERT(sizeof(*(cfp)) == sizeof(rb_control_frame_t)) || \
     ((rb_control_frame_t *)((sp) + (margin)) + 1) >= (cfp))
#define WHEN_VM_STACK_OVERFLOWED(cfp, sp, margin) \
    if (LIKELY(!VM_STACK_OVERFLOWED_P(cfp, sp, margin))) {(void)0;} else /* overflowed */
#define CHECK_VM_STACK_OVERFLOW0(cfp, sp, margin) \
    WHEN_VM_STACK_OVERFLOWED(cfp, sp, margin) vm_stackoverflow()
#define CHECK_VM_STACK_OVERFLOW(cfp, margin) \
    WHEN_VM_STACK_OVERFLOWED(cfp, (cfp)->sp, margin) vm_stackoverflow()

VALUE rb_catch_protect(VALUE t, rb_block_call_func *func, VALUE data, enum ruby_tag_type *stateptr);

/* for thread */

#if RUBY_VM_THREAD_MODEL == 2
RUBY_SYMBOL_EXPORT_BEGIN

extern rb_vm_t *ruby_current_vm_ptr;
extern rb_execution_context_t *ruby_current_execution_context_ptr;
extern rb_event_flag_t ruby_vm_event_flags;
extern rb_event_flag_t ruby_vm_event_enabled_flags;

RUBY_SYMBOL_EXPORT_END

#define GET_VM()     rb_current_vm()
#define GET_THREAD() rb_current_thread()
#define GET_EC()     rb_current_execution_context()

static inline rb_thread_t *
rb_ec_thread_ptr(const rb_execution_context_t *ec)
{
    return ec->thread_ptr;
}

static inline rb_vm_t *
rb_ec_vm_ptr(const rb_execution_context_t *ec)
{
    const rb_thread_t *th = rb_ec_thread_ptr(ec);
    if (th) {
	return th->vm;
    }
    else {
	return NULL;
    }
}

static inline rb_execution_context_t *
rb_current_execution_context(void)
{
    return ruby_current_execution_context_ptr;
}

static inline rb_thread_t *
rb_current_thread(void)
{
    const rb_execution_context_t *ec = GET_EC();
    return rb_ec_thread_ptr(ec);
}

static inline rb_vm_t *
rb_current_vm(void)
{
    VM_ASSERT(ruby_current_vm_ptr == NULL ||
	      ruby_current_execution_context_ptr == NULL ||
	      rb_ec_thread_ptr(GET_EC()) == NULL ||
	      rb_ec_vm_ptr(GET_EC()) == ruby_current_vm_ptr);
    return ruby_current_vm_ptr;
}

#define rb_thread_set_current_raw(th) (void)(ruby_current_execution_context_ptr = (th)->ec)
#define rb_thread_set_current(th) do { \
    if ((th)->vm->running_thread != (th)) { \
	(th)->running_time_us = 0; \
    } \
    rb_thread_set_current_raw(th); \
    (th)->vm->running_thread = (th); \
} while (0)

#else
#error "unsupported thread model"
#endif

enum {
    TIMER_INTERRUPT_MASK         = 0x01,
    PENDING_INTERRUPT_MASK       = 0x02,
    POSTPONED_JOB_INTERRUPT_MASK = 0x04,
    TRAP_INTERRUPT_MASK	         = 0x08
};

#define RUBY_VM_SET_TIMER_INTERRUPT(ec)		ATOMIC_OR((ec)->interrupt_flag, TIMER_INTERRUPT_MASK)
#define RUBY_VM_SET_INTERRUPT(ec)		ATOMIC_OR((ec)->interrupt_flag, PENDING_INTERRUPT_MASK)
#define RUBY_VM_SET_POSTPONED_JOB_INTERRUPT(ec)	ATOMIC_OR((ec)->interrupt_flag, POSTPONED_JOB_INTERRUPT_MASK)
#define RUBY_VM_SET_TRAP_INTERRUPT(ec)		ATOMIC_OR((ec)->interrupt_flag, TRAP_INTERRUPT_MASK)
#define RUBY_VM_INTERRUPTED(ec)			((ec)->interrupt_flag & ~(ec)->interrupt_mask & \
						 (PENDING_INTERRUPT_MASK|TRAP_INTERRUPT_MASK))
#define RUBY_VM_INTERRUPTED_ANY(ec)		((ec)->interrupt_flag & ~(ec)->interrupt_mask)

VALUE rb_exc_set_backtrace(VALUE exc, VALUE bt);
int rb_signal_buff_size(void);
void rb_signal_exec(rb_thread_t *th, int sig);
void rb_threadptr_check_signal(rb_thread_t *mth);
void rb_threadptr_signal_raise(rb_thread_t *th, int sig);
void rb_threadptr_signal_exit(rb_thread_t *th);
void rb_threadptr_execute_interrupts(rb_thread_t *, int);
void rb_threadptr_interrupt(rb_thread_t *th);
void rb_threadptr_unlock_all_locking_mutexes(rb_thread_t *th);
void rb_threadptr_pending_interrupt_clear(rb_thread_t *th);
void rb_threadptr_pending_interrupt_enque(rb_thread_t *th, VALUE v);
void rb_ec_error_print(rb_execution_context_t * volatile ec, volatile VALUE errinfo);
void rb_execution_context_mark(const rb_execution_context_t *ec);
void rb_fiber_close(rb_fiber_t *fib);
void Init_native_thread(rb_thread_t *th);

#define RUBY_VM_CHECK_INTS(ec) rb_vm_check_ints(ec)
static inline void
rb_vm_check_ints(rb_execution_context_t *ec)
{
    VM_ASSERT(ec == GET_EC());
    if (UNLIKELY(RUBY_VM_INTERRUPTED_ANY(ec))) {
	rb_threadptr_execute_interrupts(rb_ec_thread_ptr(ec), 0);
    }
}

/* tracer */
struct rb_trace_arg_struct {
    rb_event_flag_t event;
    rb_execution_context_t *ec;
    const rb_control_frame_t *cfp;
    VALUE self;
    ID id;
    ID called_id;
    VALUE klass;
    VALUE data;

    int klass_solved;

    /* calc from cfp */
    int lineno;
    VALUE path;
};

void rb_exec_event_hooks(struct rb_trace_arg_struct *trace_arg, int pop_p);

#define EXEC_EVENT_HOOK_ORIG(ec_, flag_, vm_flags_, self_, id_, called_id_, klass_, data_, pop_p_) do { \
    const rb_event_flag_t flag_arg_ = (flag_); \
    if (UNLIKELY(vm_flags_ & (flag_arg_))) { \
	/* defer evaluating the other arguments */ \
	rb_exec_event_hook_orig(ec_, flag_arg_, self_, id_, called_id_, klass_, data_, pop_p_); \
    } \
} while (0)

static inline void
rb_exec_event_hook_orig(rb_execution_context_t *ec, const rb_event_flag_t flag,
			VALUE self, ID id, ID called_id, VALUE klass, VALUE data, int pop_p)
{
    struct rb_trace_arg_struct trace_arg;

    VM_ASSERT(rb_ec_vm_ptr(ec)->event_hooks.events == ruby_vm_event_flags);
    VM_ASSERT(rb_ec_vm_ptr(ec)->event_hooks.events & flag);

    trace_arg.event = flag;
    trace_arg.ec = ec;
    trace_arg.cfp = ec->cfp;
    trace_arg.self = self;
    trace_arg.id = id;
    trace_arg.called_id = called_id;
    trace_arg.klass = klass;
    trace_arg.data = data;
    trace_arg.path = Qundef;
    trace_arg.klass_solved = 0;
    rb_exec_event_hooks(&trace_arg, pop_p);
}

#define EXEC_EVENT_HOOK(ec_, flag_, self_, id_, called_id_, klass_, data_) \
  EXEC_EVENT_HOOK_ORIG(ec_, flag_, ruby_vm_event_flags, self_, id_, called_id_, klass_, data_, 0)

#define EXEC_EVENT_HOOK_AND_POP_FRAME(ec_, flag_, self_, id_, called_id_, klass_, data_) \
  EXEC_EVENT_HOOK_ORIG(ec_, flag_, ruby_vm_event_flags, self_, id_, called_id_, klass_, data_, 1)

RUBY_SYMBOL_EXPORT_BEGIN

int rb_thread_check_trap_pending(void);

/* #define RUBY_EVENT_RESERVED_FOR_INTERNAL_USE 0x030000 */ /* from vm_core.h */
#define RUBY_EVENT_COVERAGE_LINE                0x010000
#define RUBY_EVENT_COVERAGE_BRANCH              0x020000

extern VALUE rb_get_coverages(void);
extern void rb_set_coverages(VALUE, int, VALUE);
extern void rb_reset_coverages(void);

void rb_postponed_job_flush(rb_vm_t *vm);

RUBY_SYMBOL_EXPORT_END

#endif /* RUBY_VM_CORE_H */
