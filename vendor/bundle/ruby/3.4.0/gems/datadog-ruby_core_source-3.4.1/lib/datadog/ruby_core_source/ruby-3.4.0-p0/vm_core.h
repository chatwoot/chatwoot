#ifndef RUBY_VM_CORE_H
#define RUBY_VM_CORE_H
/**********************************************************************

  vm_core.h -

  $Author$
  created at: 04/01/01 19:41:38 JST

  Copyright (C) 2004-2007 Koichi Sasada

**********************************************************************/

/*
 * Enable check mode.
 *   1: enable local assertions.
 */
#ifndef VM_CHECK_MODE

// respect RUBY_DUBUG: if given n is 0, then use RUBY_DEBUG
#define N_OR_RUBY_DEBUG(n) (((n) > 0) ? (n) : RUBY_DEBUG)

#define VM_CHECK_MODE N_OR_RUBY_DEBUG(0)
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

#include "ruby/internal/config.h"

#include <stddef.h>
#include <signal.h>
#include <stdarg.h>

#include "ruby_assert.h"

#define RVALUE_SIZE (sizeof(struct RBasic) + sizeof(VALUE[RBIMPL_RVALUE_EMBED_LEN_MAX]))

#if VM_CHECK_MODE > 0
#define VM_ASSERT(expr, ...) \
    RUBY_ASSERT_MESG_WHEN(VM_CHECK_MODE > 0, expr, #expr RBIMPL_VA_OPT_ARGS(__VA_ARGS__))
#define VM_UNREACHABLE(func) rb_bug(#func ": unreachable")
#define RUBY_ASSERT_CRITICAL_SECTION
#define RUBY_DEBUG_THREAD_SCHEDULE() rb_thread_schedule()
#else
#define VM_ASSERT(/*expr, */...) ((void)0)
#define VM_UNREACHABLE(func) UNREACHABLE
#define RUBY_DEBUG_THREAD_SCHEDULE()
#endif

#define RUBY_ASSERT_MUTEX_OWNED(mutex) VM_ASSERT(rb_mutex_owned_p(mutex))

#if defined(RUBY_ASSERT_CRITICAL_SECTION)
/*
# Critical Section Assertions

These assertions are used to ensure that context switching does not occur between two points in the code. In theory,
such code should already be protected by a mutex, but these assertions are used to ensure that the mutex is held.

The specific case where it can be useful is where a mutex is held further up the call stack, and the code in question
may not directly hold the mutex. In this case, the critical section assertions can be used to ensure that the mutex is
held by someone else.

These assertions are only enabled when RUBY_ASSERT_CRITICAL_SECTION is defined, which is only defined if VM_CHECK_MODE
is set.

## Example Usage

```c
RUBY_ASSERT_CRITICAL_SECTION_ENTER();
// ... some code which does not invoke rb_vm_check_ints() ...
RUBY_ASSERT_CRITICAL_SECTION_LEAVE();
```

If `rb_vm_check_ints()` is called between the `RUBY_ASSERT_CRITICAL_SECTION_ENTER()` and
`RUBY_ASSERT_CRITICAL_SECTION_LEAVE()`, a failed assertion will result.
*/
extern int ruby_assert_critical_section_entered;
#define RUBY_ASSERT_CRITICAL_SECTION_ENTER() do{ruby_assert_critical_section_entered += 1;}while(false)
#define RUBY_ASSERT_CRITICAL_SECTION_LEAVE() do{VM_ASSERT(ruby_assert_critical_section_entered > 0);ruby_assert_critical_section_entered -= 1;}while(false)
#else
#define RUBY_ASSERT_CRITICAL_SECTION_ENTER()
#define RUBY_ASSERT_CRITICAL_SECTION_LEAVE()
#endif

#if defined(__wasm__) && !defined(__EMSCRIPTEN__)
# include "wasm/setjmp.h"
#else
# include <setjmp.h>
#endif

#if defined(__linux__) || defined(__FreeBSD__)
# define RB_THREAD_T_HAS_NATIVE_ID
#endif

#include "ruby/internal/stdbool.h"
#include "ccan/list/list.h"
#include "id.h"
#include "internal.h"
#include "internal/array.h"
#include "internal/basic_operators.h"
#include "internal/sanitizers.h"
#include "internal/serial.h"
#include "internal/vm.h"
#include "method.h"
#include "node.h"
#include "ruby/ruby.h"
#include "ruby/st.h"
#include "ruby_atomic.h"
#include "vm_opts.h"

#include "ruby/thread_native.h"
/*
 * implementation selector of get_insn_info algorithm
 *   0: linear search
 *   1: binary search
 *   2: succinct bitvector
 */
#ifndef VM_INSN_INFO_TABLE_IMPL
# define VM_INSN_INFO_TABLE_IMPL 2
#endif

#if defined(NSIG_MAX)           /* POSIX issue 8 */
# undef NSIG
# define NSIG NSIG_MAX
#elif defined(_SIG_MAXSIG)      /* FreeBSD */
# undef NSIG
# define NSIG _SIG_MAXSIG
#elif defined(_SIGMAX)          /* QNX */
# define NSIG (_SIGMAX + 1)
#elif defined(NSIG)             /* 99% of everything else */
# /* take it */
#else                           /* Last resort */
# define NSIG (sizeof(sigset_t) * CHAR_BIT + 1)
#endif

#define RUBY_NSIG NSIG

#if defined(SIGCLD)
#  define RUBY_SIGCHLD (SIGCLD)
#elif defined(SIGCHLD)
#  define RUBY_SIGCHLD (SIGCHLD)
#endif

#if defined(SIGSEGV) && defined(HAVE_SIGALTSTACK) && defined(SA_SIGINFO) && !defined(__NetBSD__)
#  define USE_SIGALTSTACK
void *rb_allocate_sigaltstack(void);
void *rb_register_sigaltstack(void *);
#  define RB_ALTSTACK_INIT(var, altstack) var = rb_register_sigaltstack(altstack)
#  define RB_ALTSTACK_FREE(var) free(var)
#  define RB_ALTSTACK(var)  var
#else /* noop */
#  define RB_ALTSTACK_INIT(var, altstack)
#  define RB_ALTSTACK_FREE(var)
#  define RB_ALTSTACK(var) (0)
#endif

#include THREAD_IMPL_H
#define RUBY_VM_THREAD_MODEL 2

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
#endif /* OPT_CALL_THREADED_CODE */

void rb_vm_encoded_insn_data_table_init(void);
typedef unsigned long rb_num_t;
typedef   signed long rb_snum_t;

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
    VM_THROW_STATE_MASK = 0xff
};

/* forward declarations */
struct rb_thread_struct;
struct rb_control_frame_struct;

/* iseq data type */
typedef struct rb_compile_option_struct rb_compile_option_t;

union ic_serial_entry {
    rb_serial_t raw;
    VALUE data[2];
};

#define IMEMO_CONST_CACHE_SHAREABLE IMEMO_FL_USER0

// imemo_constcache
struct iseq_inline_constant_cache_entry {
    VALUE flags;

    VALUE value;              // v0
    VALUE _unused1;           // v1
    VALUE _unused2;           // v2
    const rb_cref_t *ic_cref; // v3
};
STATIC_ASSERT(sizeof_iseq_inline_constant_cache_entry,
              (offsetof(struct iseq_inline_constant_cache_entry, ic_cref) +
               sizeof(const rb_cref_t *)) <= RVALUE_SIZE);

struct iseq_inline_constant_cache {
    struct iseq_inline_constant_cache_entry *entry;

    /**
     * A null-terminated list of ids, used to represent a constant's path
     * idNULL is used to represent the :: prefix, and 0 is used to donate the end
     * of the list.
     *
     * For example
     *   FOO        {rb_intern("FOO"), 0}
     *   FOO::BAR   {rb_intern("FOO"), rb_intern("BAR"), 0}
     *   ::FOO      {idNULL, rb_intern("FOO"), 0}
     *   ::FOO::BAR {idNULL, rb_intern("FOO"), rb_intern("BAR"), 0}
     */
    const ID *segments;
};

struct iseq_inline_iv_cache_entry {
    uintptr_t value; // attr_index in lower bits, dest_shape_id in upper bits
    ID iv_set_name;
};

struct iseq_inline_cvar_cache_entry {
    struct rb_cvar_class_tbl_entry *entry;
};

union iseq_inline_storage_entry {
    struct {
        struct rb_thread_struct *running_thread;
        VALUE value;
    } once;
    struct iseq_inline_constant_cache ic_cache;
    struct iseq_inline_iv_cache_entry iv_cache;
};

struct rb_calling_info {
    const struct rb_call_data *cd;
    const struct rb_callcache *cc;
    VALUE block_handler;
    VALUE recv;
    int argc;
    bool kw_splat;
    VALUE heap_argv;
};

#ifndef VM_ARGC_STACK_MAX
#define VM_ARGC_STACK_MAX 128
#endif

# define CALLING_ARGC(calling) ((calling)->heap_argv ? RARRAY_LENINT((calling)->heap_argv) : (calling)->argc)

struct rb_execution_context_struct;

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
    int first_lineno;
    int node_id;
    rb_code_location_t code_location;
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

/* Forward declarations */
struct rb_rjit_unit;

typedef uintptr_t iseq_bits_t;

#define ISEQ_IS_SIZE(body) (body->ic_size + body->ivc_size + body->ise_size + body->icvarc_size)

/* [ TS_IVC | TS_ICVARC | TS_ISE | TS_IC ] */
#define ISEQ_IS_IC_ENTRY(body, idx) (body->is_entries[(idx) + body->ise_size + body->icvarc_size + body->ivc_size].ic_cache);

/* instruction sequence type */
enum rb_iseq_type {
    ISEQ_TYPE_TOP,
    ISEQ_TYPE_METHOD,
    ISEQ_TYPE_BLOCK,
    ISEQ_TYPE_CLASS,
    ISEQ_TYPE_RESCUE,
    ISEQ_TYPE_ENSURE,
    ISEQ_TYPE_EVAL,
    ISEQ_TYPE_MAIN,
    ISEQ_TYPE_PLAIN
};

// Attributes specified by Primitive.attr!
enum rb_builtin_attr {
    // The iseq does not call methods.
    BUILTIN_ATTR_LEAF = 0x01,
    // This iseq only contains single `opt_invokebuiltin_delegate_leave` instruction with 0 arguments.
    BUILTIN_ATTR_SINGLE_NOARG_LEAF = 0x02,
    // This attribute signals JIT to duplicate the iseq for each block iseq so that its `yield` will be monomorphic.
    BUILTIN_ATTR_INLINE_BLOCK = 0x04,
    // The iseq acts like a C method in backtraces.
    BUILTIN_ATTR_C_TRACE = 0x08,
};

typedef VALUE (*rb_jit_func_t)(struct rb_execution_context_struct *, struct rb_control_frame_struct *);

struct rb_iseq_constant_body {
    enum rb_iseq_type type;

    unsigned int iseq_size;
    VALUE *iseq_encoded; /* encoded iseq (insn addr and operands) */

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
            unsigned int accepts_no_kwarg : 1;
            unsigned int ruby2_keywords: 1;
            unsigned int anon_rest: 1;
            unsigned int anon_kwrest: 1;
            unsigned int use_block: 1;
            unsigned int forwardable: 1;
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
            VALUE *default_values;
        } *keyword;
    } param;

    rb_iseq_location_t location;

    /* insn info, must be freed */
    struct iseq_insn_info {
        const struct iseq_insn_info_entry *body;
        unsigned int *positions;
        unsigned int size;
#if VM_INSN_INFO_TABLE_IMPL == 2
        struct succ_index_table *succ_index_table;
#endif
    } insns_info;

    const ID *local_table;		/* must free */

    /* catch table */
    struct iseq_catch_table *catch_table;

    /* for child iseq */
    const struct rb_iseq_struct *parent_iseq;
    struct rb_iseq_struct *local_iseq; /* local_iseq->flip_cnt can be modified */

    union iseq_inline_storage_entry *is_entries; /* [ TS_IVC | TS_ICVARC | TS_ISE | TS_IC ] */
    struct rb_call_data *call_data; //struct rb_call_data calls[ci_size];

    struct {
        rb_snum_t flip_count;
        VALUE script_lines;
        VALUE coverage;
        VALUE pc2branchindex;
        VALUE *original_iseq;
    } variable;

    unsigned int local_table_size;
    unsigned int ic_size;     // Number of IC caches
    unsigned int ise_size;    // Number of ISE caches
    unsigned int ivc_size;    // Number of IVC caches
    unsigned int icvarc_size; // Number of ICVARC caches
    unsigned int ci_size;
    unsigned int stack_max; /* for stack overflow check */

    unsigned int builtin_attrs; // Union of rb_builtin_attr

    bool prism; // ISEQ was generated from prism compiler

    union {
        iseq_bits_t * list; /* Find references for GC */
        iseq_bits_t single;
    } mark_bits;

    struct rb_id_table *outer_variables;

    const rb_iseq_t *mandatory_only_iseq;

#if USE_RJIT || USE_YJIT
    // Function pointer for JIT code on jit_exec()
    rb_jit_func_t jit_entry;
    // Number of calls on jit_exec()
    long unsigned jit_entry_calls;
#endif

#if USE_YJIT
    // Function pointer for JIT code on jit_exec_exception()
    rb_jit_func_t jit_exception;
    // Number of calls on jit_exec_exception()
    long unsigned jit_exception_calls;
#endif

#if USE_RJIT
    // RJIT stores some data on each iseq.
    VALUE rjit_blocks;
#endif

#if USE_YJIT
    // YJIT stores some data on each iseq.
    void *yjit_payload;
    // Used to estimate how frequently this ISEQ gets called
    uint64_t yjit_calls_at_interv;
#endif
};

/* T_IMEMO/iseq */
/* typedef rb_iseq_t is in method.h */
struct rb_iseq_struct {
    VALUE flags; /* 1 */
    VALUE wrapper; /* 2 */

    struct rb_iseq_constant_body *body;  /* 3 */

    union { /* 4, 5 words */
        struct iseq_compile_data *compile_data; /* used at compile time */

        struct {
            VALUE obj;
            int index;
        } loader;

        struct {
            struct rb_hook_list_struct *local_hooks;
            rb_event_flag_t global_trace_events;
        } exec;
    } aux;
};

#define ISEQ_BODY(iseq) ((iseq)->body)

#if !defined(USE_LAZY_LOAD) || !(USE_LAZY_LOAD+0)
#define USE_LAZY_LOAD 0
#endif

#if !USE_LAZY_LOAD
static inline const rb_iseq_t *rb_iseq_complete(const rb_iseq_t *iseq) {return 0;}
#endif
const rb_iseq_t *rb_iseq_complete(const rb_iseq_t *iseq);

static inline const rb_iseq_t *
rb_iseq_check(const rb_iseq_t *iseq)
{
    if (USE_LAZY_LOAD && ISEQ_BODY(iseq) == NULL) {
        rb_iseq_complete((rb_iseq_t *)iseq);
    }
    return iseq;
}

static inline bool
rb_iseq_attr_p(const rb_iseq_t *iseq, enum rb_builtin_attr attr)
{
    return (ISEQ_BODY(iseq)->builtin_attrs & attr) == attr;
}

static inline const rb_iseq_t *
def_iseq_ptr(rb_method_definition_t *def)
{
//TODO: re-visit. to check the bug, enable this assertion.
#if VM_CHECK_MODE > 0
    if (def->type != VM_METHOD_TYPE_ISEQ) rb_bug("def_iseq_ptr: not iseq (%d)", def->type);
#endif
    return rb_iseq_check(def->body.iseq.iseqptr);
}

enum ruby_special_exceptions {
    ruby_error_reenter,
    ruby_error_nomemory,
    ruby_error_sysstack,
    ruby_error_stackfatal,
    ruby_error_stream_closed,
    ruby_special_error_count
};

#define GetVMPtr(obj, ptr) \
  GetCoreDataFromValue((obj), rb_vm_t, (ptr))

struct rb_vm_struct;
typedef void rb_vm_at_exit_func(struct rb_vm_struct*);

typedef struct rb_at_exit_list {
    rb_vm_at_exit_func *func;
    struct rb_at_exit_list *next;
} rb_at_exit_list;

void *rb_objspace_alloc(void);
void rb_objspace_free(void *objspace);
void rb_objspace_call_finalizer(void);

typedef struct rb_hook_list_struct {
    struct rb_event_hook_struct *hooks;
    rb_event_flag_t events;
    unsigned int running;
    bool need_clean;
    bool is_local;
} rb_hook_list_t;


// see builtin.h for definition
typedef const struct rb_builtin_function *RB_BUILTIN;

struct global_object_list {
    VALUE *varptr;
    struct global_object_list *next;
};

typedef struct rb_vm_struct {
    VALUE self;

    struct {
        struct ccan_list_head set;
        unsigned int cnt;
        unsigned int blocking_cnt;

        struct rb_ractor_struct *main_ractor;
        struct rb_thread_struct *main_thread; // == vm->ractor.main_ractor->threads.main

        struct {
            // monitor
            rb_nativethread_lock_t lock;
            struct rb_ractor_struct *lock_owner;
            unsigned int lock_rec;

            // join at exit
            rb_nativethread_cond_t terminate_cond;
            bool terminate_waiting;

#ifndef RUBY_THREAD_PTHREAD_H
            bool barrier_waiting;
            unsigned int barrier_cnt;
            rb_nativethread_cond_t barrier_cond;
#endif
        } sync;

        // ractor scheduling
        struct {
            rb_nativethread_lock_t lock;
            struct rb_ractor_struct *lock_owner;
            bool locked;

            rb_nativethread_cond_t cond; // GRQ
            unsigned int snt_cnt; // count of shared NTs
            unsigned int dnt_cnt; // count of dedicated NTs

            unsigned int running_cnt;

            unsigned int max_cpu;
            struct ccan_list_head grq; // // Global Ready Queue
            unsigned int grq_cnt;

            // running threads
            struct ccan_list_head running_threads;

            // threads which switch context by timeslice
            struct ccan_list_head timeslice_threads;

            struct ccan_list_head zombie_threads;

            // true if timeslice timer is not enable
            bool timeslice_wait_inf;

            // barrier
            rb_nativethread_cond_t barrier_complete_cond;
            rb_nativethread_cond_t barrier_release_cond;
            bool barrier_waiting;
            unsigned int barrier_waiting_cnt;
            unsigned int barrier_serial;
        } sched;
    } ractor;

#ifdef USE_SIGALTSTACK
    void *main_altstack;
#endif

    rb_serial_t fork_gen;
    struct ccan_list_head waiting_fds; /* <=> struct waiting_fd */

    /* set in single-threaded processes only: */
    volatile int ubf_async_safe;

    unsigned int running: 1;
    unsigned int thread_abort_on_exception: 1;
    unsigned int thread_report_on_exception: 1;
    unsigned int thread_ignore_deadlock: 1;

    /* object management */
    VALUE mark_object_ary;
    struct global_object_list *global_object_list;
    const VALUE special_exceptions[ruby_special_error_count];

    /* load */
    VALUE top_self;
    VALUE load_path;
    VALUE load_path_snapshot;
    VALUE load_path_check_cache;
    VALUE expanded_load_path;
    VALUE loaded_features;
    VALUE loaded_features_snapshot;
    VALUE loaded_features_realpaths;
    VALUE loaded_features_realpath_map;
    struct st_table *loaded_features_index;
    struct st_table *loading_table;
    // For running the init function of statically linked
    // extensions when they are loaded
    struct st_table *static_ext_inits;

    /* signal */
    struct {
        VALUE cmd[RUBY_NSIG];
    } trap_list;

    /* postponed_job (async-signal-safe, and thread-safe) */
    struct rb_postponed_job_queue *postponed_job_queue;

    int src_encoding_index;

    /* workqueue (thread-safe, NOT async-signal-safe) */
    struct ccan_list_head workqueue; /* <=> rb_workqueue_job.jnode */
    rb_nativethread_lock_t workqueue_lock;

    VALUE orig_progname, progname;
    VALUE coverages, me2counter;
    int coverage_mode;

    struct {
        struct rb_objspace *objspace;
        struct gc_mark_func_data_struct {
            void *data;
            void (*mark_func)(VALUE v, void *data);
        } *mark_func_data;
    } gc;

    rb_at_exit_list *at_exit;

    st_table *frozen_strings;

    const struct rb_builtin_function *builtin_function_table;

    st_table *ci_table;
    struct rb_id_table *negative_cme_table;
    st_table *overloaded_cme_table; // cme -> overloaded_cme
    st_table *unused_block_warning_table;

    // This id table contains a mapping from ID to ICs. It does this with ID
    // keys and nested st_tables as values. The nested tables have ICs as keys
    // and Qtrue as values. It is used when inline constant caches need to be
    // invalidated or ISEQs are being freed.
    struct rb_id_table *constant_cache;
    ID inserting_constant_cache_id;

#ifndef VM_GLOBAL_CC_CACHE_TABLE_SIZE
#define VM_GLOBAL_CC_CACHE_TABLE_SIZE 1023
#endif
    const struct rb_callcache *global_cc_cache_table[VM_GLOBAL_CC_CACHE_TABLE_SIZE]; // vm_eval.c

#if defined(USE_VM_CLOCK) && USE_VM_CLOCK
    uint32_t clock;
#endif

    /* params */
    struct { /* size in byte */
        size_t thread_vm_stack_size;
        size_t thread_machine_stack_size;
        size_t fiber_vm_stack_size;
        size_t fiber_machine_stack_size;
    } default_params;

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
#if defined(__powerpc64__) || defined(__ppc64__) // macOS has __ppc64__
#define RUBY_VM_FIBER_MACHINE_STACK_SIZE_MIN  (  32 * 1024 * sizeof(VALUE)) /*  128 KB or  256 KB */
#else
#define RUBY_VM_FIBER_MACHINE_STACK_SIZE_MIN  (  16 * 1024 * sizeof(VALUE)) /*   64 KB or  128 KB */
#endif

#if __has_feature(memory_sanitizer) || __has_feature(address_sanitizer)
/* It seems sanitizers consume A LOT of machine stacks */
#undef  RUBY_VM_THREAD_MACHINE_STACK_SIZE
#define RUBY_VM_THREAD_MACHINE_STACK_SIZE     (1024 * 1024 * sizeof(VALUE))
#undef  RUBY_VM_THREAD_MACHINE_STACK_SIZE_MIN
#define RUBY_VM_THREAD_MACHINE_STACK_SIZE_MIN ( 512 * 1024 * sizeof(VALUE))
#undef  RUBY_VM_FIBER_MACHINE_STACK_SIZE
#define RUBY_VM_FIBER_MACHINE_STACK_SIZE      ( 256 * 1024 * sizeof(VALUE))
#undef  RUBY_VM_FIBER_MACHINE_STACK_SIZE_MIN
#define RUBY_VM_FIBER_MACHINE_STACK_SIZE_MIN  ( 128 * 1024 * sizeof(VALUE))
#endif

#ifndef VM_DEBUG_BP_CHECK
#define VM_DEBUG_BP_CHECK 0
#endif

#ifndef VM_DEBUG_VERIFY_METHOD_CACHE
#define VM_DEBUG_VERIFY_METHOD_CACHE (VMDEBUG != 0)
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
    const VALUE *pc;        // cfp[0]
    VALUE *sp;              // cfp[1]
    const rb_iseq_t *iseq;  // cfp[2]
    VALUE self;             // cfp[3] / block[0]
    const VALUE *ep;        // cfp[4] / block[1]
    const void *block_code; // cfp[5] / block[2] -- iseq, ifunc, or forwarded block handler
    void *jit_return;       // cfp[6] -- return address for JIT code
#if VM_DEBUG_BP_CHECK
    VALUE *bp_check;        // cfp[7]
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

#ifdef RUBY_JMP_BUF
typedef RUBY_JMP_BUF rb_jmpbuf_t;
#else
typedef void *rb_jmpbuf_t[5];
#endif

/*
  `rb_vm_tag_jmpbuf_t` type represents a buffer used to
  long jump to a C frame associated with `rb_vm_tag`.

  Use-site of `rb_vm_tag_jmpbuf_t` is responsible for calling the
  following functions:
  - `rb_vm_tag_jmpbuf_init` once `rb_vm_tag_jmpbuf_t` is allocated.
  - `rb_vm_tag_jmpbuf_deinit` once `rb_vm_tag_jmpbuf_t` is no longer necessary.

  `RB_VM_TAG_JMPBUF_GET` transforms a `rb_vm_tag_jmpbuf_t` into a
  `rb_jmpbuf_t` to be passed to `rb_setjmp/rb_longjmp`.
*/
#if defined(__wasm__) && !defined(__EMSCRIPTEN__)
/*
  WebAssembly target with Asyncify-based SJLJ needs
  to capture the execution context by unwind/rewind-ing
  call frames into a jump buffer. The buffer space tends
  to be considerably large unlike other architectures'
  register-based buffers.
  Therefore, we allocates the buffer on the heap on such
  environments.
*/
typedef rb_jmpbuf_t *rb_vm_tag_jmpbuf_t;

#define RB_VM_TAG_JMPBUF_GET(buf) (*buf)

static inline void
rb_vm_tag_jmpbuf_init(rb_vm_tag_jmpbuf_t *jmpbuf)
{
    *jmpbuf = ruby_xmalloc(sizeof(rb_jmpbuf_t));
}

static inline void
rb_vm_tag_jmpbuf_deinit(const rb_vm_tag_jmpbuf_t *jmpbuf)
{
    ruby_xfree(*jmpbuf);
}
#else
typedef rb_jmpbuf_t rb_vm_tag_jmpbuf_t;

#define RB_VM_TAG_JMPBUF_GET(buf) (buf)

static inline void
rb_vm_tag_jmpbuf_init(rb_vm_tag_jmpbuf_t *jmpbuf)
{
    // no-op
}

static inline void
rb_vm_tag_jmpbuf_deinit(const rb_vm_tag_jmpbuf_t *jmpbuf)
{
    // no-op
}
#endif

/*
  the members which are written in EC_PUSH_TAG() should be placed at
  the beginning and the end, so that entire region is accessible.
*/
struct rb_vm_tag {
    VALUE tag;
    VALUE retval;
    rb_vm_tag_jmpbuf_t buf;
    struct rb_vm_tag *prev;
    enum ruby_tag_type state;
    unsigned int lock_rec;
};

STATIC_ASSERT(rb_vm_tag_buf_offset, offsetof(struct rb_vm_tag, buf) > 0);
STATIC_ASSERT(rb_vm_tag_buf_end,
              offsetof(struct rb_vm_tag, buf) + sizeof(rb_vm_tag_jmpbuf_t) <
              sizeof(struct rb_vm_tag));

struct rb_unblock_callback {
    rb_unblock_function_t *func;
    void *arg;
};

struct rb_mutex_struct;

typedef struct rb_fiber_struct rb_fiber_t;

struct rb_waiting_list {
    struct rb_waiting_list *next;
    struct rb_thread_struct *thread;
    struct rb_fiber_struct *fiber;
};

struct rb_execution_context_struct {
    /* execution information */
    VALUE *vm_stack;		/* must free, must mark */
    size_t vm_stack_size;       /* size in word (byte size / sizeof(VALUE)) */
    rb_control_frame_t *cfp;

    struct rb_vm_tag *tag;

    /* interrupt flags */
    rb_atomic_t interrupt_flag;
    rb_atomic_t interrupt_mask; /* size should match flag */
#if defined(USE_VM_CLOCK) && USE_VM_CLOCK
    uint32_t checked_clock;
#endif

    rb_fiber_t *fiber_ptr;
    struct rb_thread_struct *thread_ptr;

    /* storage (ec (fiber) local) */
    struct rb_id_table *local_storage;
    VALUE local_storage_recursive_hash;
    VALUE local_storage_recursive_hash_for_trace;

    /* Inheritable fiber storage. */
    VALUE storage;

    /* eval env */
    const VALUE *root_lep;
    VALUE root_svar;

    /* trace information */
    struct rb_trace_arg_struct *trace_arg;

    /* temporary places */
    VALUE errinfo;
    VALUE passed_block_handler; /* for rb_iterate */

    uint8_t raised_flag; /* only 3 bits needed */

    /* n.b. only 7 bits needed, really: */
    BITFIELD(enum method_missing_reason, method_missing_reason, 8);

    VALUE private_const_reference;

    /* for GC */
    struct {
        VALUE *stack_start;
        VALUE *stack_end;
        size_t stack_maxsize;
        RUBY_ALIGNAS(SIZEOF_VALUE) jmp_buf regs;

#ifdef RUBY_ASAN_ENABLED
        void *asan_fake_stack_handle;
#endif
    } machine;
};

#ifndef rb_execution_context_t
typedef struct rb_execution_context_struct rb_execution_context_t;
#define rb_execution_context_t rb_execution_context_t
#endif

// for builtin.h
#define VM_CORE_H_EC_DEFINED 1

// Set the vm_stack pointer in the execution context.
void rb_ec_set_vm_stack(rb_execution_context_t *ec, VALUE *stack, size_t size);

// Initialize the vm_stack pointer in the execution context and push the initial stack frame.
// @param ec the execution context to update.
// @param stack a pointer to the stack to use.
// @param size the size of the stack, as in `VALUE stack[size]`.
void rb_ec_initialize_vm_stack(rb_execution_context_t *ec, VALUE *stack, size_t size);

// Clear (set to `NULL`) the vm_stack pointer.
// @param ec the execution context to update.
void rb_ec_clear_vm_stack(rb_execution_context_t *ec);

struct rb_ext_config {
    bool ractor_safe;
};

typedef struct rb_ractor_struct rb_ractor_t;

struct rb_native_thread;

typedef struct rb_thread_struct {
    struct ccan_list_node lt_node; // managed by a ractor
    VALUE self;
    rb_ractor_t *ractor;
    rb_vm_t *vm;
    struct rb_native_thread *nt;
    rb_execution_context_t *ec;

    struct rb_thread_sched_item sched;
    bool mn_schedulable;
    rb_atomic_t serial; // only for RUBY_DEBUG_LOG()

    VALUE last_status; /* $? */

    /* for cfunc */
    struct rb_calling_info *calling;

    /* for load(true) */
    VALUE top_self;
    VALUE top_wrapper;

    /* thread control */

    BITFIELD(enum rb_thread_status, status, 2);
    /* bit flags */
    unsigned int has_dedicated_nt : 1;
    unsigned int to_kill : 1;
    unsigned int abort_on_exception: 1;
    unsigned int report_on_exception: 1;
    unsigned int pending_interrupt_queue_checked: 1;
    int8_t priority; /* -3 .. 3 (RUBY_THREAD_PRIORITY_{MIN,MAX}) */
    uint32_t running_time_us; /* 12500..800000 */

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

    /* interrupt management */
    rb_nativethread_lock_t interrupt_lock;
    struct rb_unblock_callback unblock;
    VALUE locking_mutex;
    struct rb_mutex_struct *keeping_mutexes;
    struct ccan_list_head interrupt_exec_tasks;

    struct rb_waiting_list *join_list;

    union {
        struct {
            VALUE proc;
            VALUE args;
            int kw_splat;
        } proc;
        struct {
            VALUE (*func)(void *);
            void *arg;
        } func;
    } invoke_arg;

    enum thread_invoke_type {
        thread_invoke_type_none = 0,
        thread_invoke_type_proc,
        thread_invoke_type_ractor_proc,
        thread_invoke_type_func
    } invoke_type;

    /* statistics data for profiler */
    VALUE stat_insn_usage;

    /* fiber */
    rb_fiber_t *root_fiber;

    VALUE scheduler;
    unsigned int blocking;

    /* misc */
    VALUE name;
    void **specific_storage;

    struct rb_ext_config ext_config;
} rb_thread_t;

static inline unsigned int
rb_th_serial(const rb_thread_t *th)
{
    return th ? (unsigned int)th->serial : 0;
}

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
rb_iseq_t *rb_iseq_new         (const VALUE ast_value, VALUE name, VALUE path, VALUE realpath,                   const rb_iseq_t *parent, enum rb_iseq_type);
rb_iseq_t *rb_iseq_new_top     (const VALUE ast_value, VALUE name, VALUE path, VALUE realpath,                   const rb_iseq_t *parent);
rb_iseq_t *rb_iseq_new_main    (const VALUE ast_value,             VALUE path, VALUE realpath,                   const rb_iseq_t *parent, int opt);
rb_iseq_t *rb_iseq_new_eval    (const VALUE ast_value, VALUE name, VALUE path, VALUE realpath, int first_lineno, const rb_iseq_t *parent, int isolated_depth);
rb_iseq_t *rb_iseq_new_with_opt(      VALUE ast_value, VALUE name, VALUE path, VALUE realpath, int first_lineno, const rb_iseq_t *parent, int isolated_depth,
                                enum rb_iseq_type, const rb_compile_option_t*,
                                VALUE script_lines);

struct iseq_link_anchor;
struct rb_iseq_new_with_callback_callback_func {
    VALUE flags;
    VALUE reserved;
    void (*func)(rb_iseq_t *, struct iseq_link_anchor *, const void *);
    const void *data;
};
static inline struct rb_iseq_new_with_callback_callback_func *
rb_iseq_new_with_callback_new_callback(
    void (*func)(rb_iseq_t *, struct iseq_link_anchor *, const void *), const void *ptr)
{
    struct rb_iseq_new_with_callback_callback_func *memo =
        IMEMO_NEW(struct rb_iseq_new_with_callback_callback_func, imemo_ifunc, Qfalse);
    memo->func = func;
    memo->data = ptr;

    return memo;
}
rb_iseq_t *rb_iseq_new_with_callback(const struct rb_iseq_new_with_callback_callback_func * ifunc,
    VALUE name, VALUE path, VALUE realpath, int first_lineno,
    const rb_iseq_t *parent, enum rb_iseq_type, const rb_compile_option_t*);

VALUE rb_iseq_disasm(const rb_iseq_t *iseq);
int rb_iseq_disasm_insn(VALUE str, const VALUE *iseqval, size_t pos, const rb_iseq_t *iseq, VALUE child);

VALUE rb_iseq_coverage(const rb_iseq_t *iseq);

RUBY_EXTERN VALUE rb_cISeq;
RUBY_EXTERN VALUE rb_cRubyVM;
RUBY_EXTERN VALUE rb_mRubyVMFrozenCore;
RUBY_EXTERN VALUE rb_block_param_proxy;
RUBY_SYMBOL_EXPORT_END

#define GetProcPtr(obj, ptr) \
  GetCoreDataFromValue((obj), rb_proc_t, (ptr))

typedef struct {
    const struct rb_block block;
    unsigned int is_from_method: 1;	/* bool */
    unsigned int is_lambda: 1;		/* bool */
    unsigned int is_isolated: 1;        /* bool */
} rb_proc_t;

RUBY_SYMBOL_EXPORT_BEGIN
VALUE rb_proc_isolate(VALUE self);
VALUE rb_proc_isolate_bang(VALUE self);
VALUE rb_proc_ractor_make_shareable(VALUE self);
RUBY_SYMBOL_EXPORT_END

typedef struct {
    VALUE flags; /* imemo header */
    rb_iseq_t *iseq;
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
    int first_lineno;
} rb_binding_t;

/* used by compile time and send insn */

enum vm_check_match_type {
    VM_CHECKMATCH_TYPE_WHEN = 1,
    VM_CHECKMATCH_TYPE_CASE = 2,
    VM_CHECKMATCH_TYPE_RESCUE = 3
};

#define VM_CHECKMATCH_TYPE_MASK   0x03
#define VM_CHECKMATCH_ARRAY       0x04

enum vm_opt_newarray_send_type {
    VM_OPT_NEWARRAY_SEND_MAX = 1,
    VM_OPT_NEWARRAY_SEND_MIN = 2,
    VM_OPT_NEWARRAY_SEND_HASH = 3,
    VM_OPT_NEWARRAY_SEND_PACK = 4,
    VM_OPT_NEWARRAY_SEND_PACK_BUFFER = 5,
    VM_OPT_NEWARRAY_SEND_INCLUDE_P = 6,
};

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
typedef struct iseq_inline_constant_cache *IC;
typedef struct iseq_inline_iv_cache_entry *IVC;
typedef struct iseq_inline_cvar_cache_entry *ICVARC;
typedef union iseq_inline_storage_entry *ISE;
typedef const struct rb_callinfo *CALL_INFO;
typedef const struct rb_callcache *CALL_CACHE;
typedef struct rb_call_data *CALL_DATA;

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

enum vm_frame_env_flags {
    /* Frame/Environment flag bits:
     *   MMMM MMMM MMMM MMMM ____ FFFF FFFE EEEX (LSB)
     *
     * X   : tag for GC marking (It seems as Fixnum)
     * EEE : 4 bits Env flags
     * FF..: 7 bits Frame flags
     * MM..: 15 bits frame magic (to check frame corruption)
     */

    /* frame types */
    VM_FRAME_MAGIC_METHOD = 0x11110001,
    VM_FRAME_MAGIC_BLOCK  = 0x22220001,
    VM_FRAME_MAGIC_CLASS  = 0x33330001,
    VM_FRAME_MAGIC_TOP    = 0x44440001,
    VM_FRAME_MAGIC_CFUNC  = 0x55550001,
    VM_FRAME_MAGIC_IFUNC  = 0x66660001,
    VM_FRAME_MAGIC_EVAL   = 0x77770001,
    VM_FRAME_MAGIC_RESCUE = 0x78880001,
    VM_FRAME_MAGIC_DUMMY  = 0x79990001,

    VM_FRAME_MAGIC_MASK   = 0x7fff0001,

    /* frame flag */
    VM_FRAME_FLAG_FINISH    = 0x0020,
    VM_FRAME_FLAG_BMETHOD   = 0x0040,
    VM_FRAME_FLAG_CFRAME    = 0x0080,
    VM_FRAME_FLAG_LAMBDA    = 0x0100,
    VM_FRAME_FLAG_MODIFIED_BLOCK_PARAM = 0x0200,
    VM_FRAME_FLAG_CFRAME_KW = 0x0400,
    VM_FRAME_FLAG_PASSED    = 0x0800,

    /* env flag */
    VM_ENV_FLAG_LOCAL       = 0x0002,
    VM_ENV_FLAG_ESCAPED     = 0x0004,
    VM_ENV_FLAG_WB_REQUIRED = 0x0008,
    VM_ENV_FLAG_ISOLATED    = 0x0010,
};

#define VM_ENV_DATA_SIZE             ( 3)

#define VM_ENV_DATA_INDEX_ME_CREF    (-2) /* ep[-2] */
#define VM_ENV_DATA_INDEX_SPECVAL    (-1) /* ep[-1] */
#define VM_ENV_DATA_INDEX_FLAGS      ( 0) /* ep[ 0] */
#define VM_ENV_DATA_INDEX_ENV        ( 1) /* ep[ 1] */

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
VM_FRAME_CFRAME_KW_P(const rb_control_frame_t *cfp)
{
    return VM_ENV_FLAGS(cfp->ep, VM_FRAME_FLAG_CFRAME_KW) != 0;
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
    VM_ASSERT(RUBY_VM_NORMAL_ISEQ_P(cfp->iseq) != cframe_p ||
              (VM_FRAME_TYPE(cfp) & VM_FRAME_MAGIC_MASK) == VM_FRAME_MAGIC_DUMMY);
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

RBIMPL_ATTR_NONNULL((1))
static inline VALUE
VM_ENV_ENVVAL(const VALUE *ep)
{
    VALUE envval = ep[VM_ENV_DATA_INDEX_ENV];
    VM_ASSERT(VM_ENV_ESCAPED_P(ep));
    VM_ASSERT(envval == Qundef || imemo_type_p(envval, imemo_env));
    return envval;
}

RBIMPL_ATTR_NONNULL((1))
static inline const rb_env_t *
VM_ENV_ENVVAL_PTR(const VALUE *ep)
{
    return (const rb_env_t *)VM_ENV_ENVVAL(ep);
}

static inline const rb_env_t *
vm_env_new(VALUE *env_ep, VALUE *env_body, unsigned int env_size, const rb_iseq_t *iseq)
{
    rb_env_t *env = IMEMO_NEW(rb_env_t, imemo_env, (VALUE)iseq);
    env->ep = env_ep;
    env->env = env_body;
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
VALUE rb_binding_alloc(VALUE klass);
VALUE rb_proc_alloc(VALUE klass);
VALUE rb_proc_dup(VALUE self);

/* for debug */
extern bool rb_vmdebug_stack_dump_raw(const rb_execution_context_t *ec, const rb_control_frame_t *cfp, FILE *);
extern bool rb_vmdebug_debug_print_pre(const rb_execution_context_t *ec, const rb_control_frame_t *cfp, const VALUE *_pc, FILE *);
extern bool rb_vmdebug_debug_print_post(const rb_execution_context_t *ec, const rb_control_frame_t *cfp, FILE *);

#define SDR() rb_vmdebug_stack_dump_raw(GET_EC(), GET_EC()->cfp, stderr)
#define SDR2(cfp) rb_vmdebug_stack_dump_raw(GET_EC(), (cfp), stderr)
bool rb_vm_bugreport(const void *, FILE *);
typedef void (*ruby_sighandler_t)(int);
RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 4, 5)
NORETURN(void rb_bug_for_fatal_signal(ruby_sighandler_t default_sighandler, int sig, const void *, const char *fmt, ...));

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

VALUE rb_vm_invoke_proc(rb_execution_context_t *ec, rb_proc_t *proc, int argc, const VALUE *argv, int kw_splat, VALUE block_handler);

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
VALUE rb_vm_call_kw(rb_execution_context_t *ec, VALUE recv, VALUE id, int argc,
                 const VALUE *argv, const rb_callable_method_entry_t *me, int kw_splat);
void rb_vm_pop_frame_no_int(rb_execution_context_t *ec);
void rb_vm_pop_frame(rb_execution_context_t *ec);

void rb_thread_start_timer_thread(void);
void rb_thread_stop_timer_thread(void);
void rb_thread_reset_timer_thread(void);
void rb_thread_wakeup_timer_thread(int);

static inline void
rb_vm_living_threads_init(rb_vm_t *vm)
{
    ccan_list_head_init(&vm->waiting_fds);
    ccan_list_head_init(&vm->workqueue);
    ccan_list_head_init(&vm->ractor.set);
    ccan_list_head_init(&vm->ractor.sched.zombie_threads);
}

typedef int rb_backtrace_iter_func(void *, VALUE, int, VALUE);
rb_control_frame_t *rb_vm_get_ruby_level_next_cfp(const rb_execution_context_t *ec, const rb_control_frame_t *cfp);
rb_control_frame_t *rb_vm_get_binding_creatable_next_cfp(const rb_execution_context_t *ec, const rb_control_frame_t *cfp);
VALUE *rb_vm_svar_lep(const rb_execution_context_t *ec, const rb_control_frame_t *cfp);
int rb_vm_get_sourceline(const rb_control_frame_t *);
void rb_vm_stack_to_heap(rb_execution_context_t *ec);
void ruby_thread_init_stack(rb_thread_t *th, void *local_in_parent_frame);
rb_thread_t * ruby_thread_from_native(void);
int ruby_thread_set_native(rb_thread_t *th);
int rb_vm_control_frame_id_and_class(const rb_control_frame_t *cfp, ID *idp, ID *called_idp, VALUE *klassp);
void rb_vm_rewind_cfp(rb_execution_context_t *ec, rb_control_frame_t *cfp);
void rb_vm_env_write(const VALUE *ep, int index, VALUE v);
VALUE rb_vm_bh_to_procval(const rb_execution_context_t *ec, VALUE block_handler);

void rb_vm_register_special_exception_str(enum ruby_special_exceptions sp, VALUE exception_class, VALUE mesg);

#define rb_vm_register_special_exception(sp, e, m) \
    rb_vm_register_special_exception_str(sp, e, rb_usascii_str_new_static((m), (long)rb_strlen_lit(m)))

void rb_gc_mark_machine_context(const rb_execution_context_t *ec);

void rb_vm_rewrite_cref(rb_cref_t *node, VALUE old_klass, VALUE new_klass, rb_cref_t **new_cref_ptr);

const rb_callable_method_entry_t *rb_vm_frame_method_entry(const rb_control_frame_t *cfp);

#define sysstack_error GET_VM()->special_exceptions[ruby_error_sysstack]

#define CHECK_VM_STACK_OVERFLOW0(cfp, sp, margin) do {                       \
    STATIC_ASSERT(sizeof_sp,  sizeof(*(sp))  == sizeof(VALUE));              \
    STATIC_ASSERT(sizeof_cfp, sizeof(*(cfp)) == sizeof(rb_control_frame_t)); \
    const struct rb_control_frame_struct *bound = (void *)&(sp)[(margin)];   \
    if (UNLIKELY((cfp) <= &bound[1])) {                                      \
        vm_stackoverflow();                                                  \
    }                                                                        \
} while (0)

#define CHECK_VM_STACK_OVERFLOW(cfp, margin) \
    CHECK_VM_STACK_OVERFLOW0((cfp), (cfp)->sp, (margin))

VALUE rb_catch_protect(VALUE t, rb_block_call_func *func, VALUE data, enum ruby_tag_type *stateptr);

rb_execution_context_t *rb_vm_main_ractor_ec(rb_vm_t *vm); // ractor.c

/* for thread */

#if RUBY_VM_THREAD_MODEL == 2

RUBY_EXTERN struct rb_ractor_struct *ruby_single_main_ractor; // ractor.c
RUBY_EXTERN rb_vm_t *ruby_current_vm_ptr;
RUBY_EXTERN rb_event_flag_t ruby_vm_event_flags;
RUBY_EXTERN rb_event_flag_t ruby_vm_event_enabled_global_flags;
RUBY_EXTERN unsigned int    ruby_vm_event_local_num;

#define GET_VM()     rb_current_vm()
#define GET_RACTOR() rb_current_ractor()
#define GET_THREAD() rb_current_thread()
#define GET_EC()     rb_current_execution_context(true)

static inline rb_thread_t *
rb_ec_thread_ptr(const rb_execution_context_t *ec)
{
    return ec->thread_ptr;
}

static inline rb_ractor_t *
rb_ec_ractor_ptr(const rb_execution_context_t *ec)
{
    const rb_thread_t *th = rb_ec_thread_ptr(ec);
    if (th) {
        VM_ASSERT(th->ractor != NULL);
        return th->ractor;
    }
    else {
        return NULL;
    }
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

NOINLINE(struct rb_execution_context_struct *rb_current_ec_noinline(void));

static inline rb_execution_context_t *
rb_current_execution_context(bool expect_ec)
{
#ifdef RB_THREAD_LOCAL_SPECIFIER
  #ifdef __APPLE__
    rb_execution_context_t *ec = rb_current_ec();
  #else
    rb_execution_context_t *ec = ruby_current_ec;
  #endif

    /* On the shared objects, `__tls_get_addr()` is used to access the TLS
     * and the address of the `ruby_current_ec` can be stored on a function
     * frame. However, this address can be mis-used after native thread
     * migration of a coroutine.
     *   1) Get `ptr =&ruby_current_ec` op NT1 and store it on the frame.
     *   2) Context switch and resume it on the NT2.
     *   3) `ptr` is used on NT2 but it accesses to the TLS on NT1.
     * This assertion checks such misusage.
     *
     * To avoid accidents, `GET_EC()` should be called once on the frame.
     * Note that inlining can produce the problem.
     */
    VM_ASSERT(ec == rb_current_ec_noinline());
#else
    rb_execution_context_t *ec = native_tls_get(ruby_current_ec_key);
#endif
    VM_ASSERT(!expect_ec || ec != NULL);
    return ec;
}

static inline rb_thread_t *
rb_current_thread(void)
{
    const rb_execution_context_t *ec = GET_EC();
    return rb_ec_thread_ptr(ec);
}

static inline rb_ractor_t *
rb_current_ractor_raw(bool expect)
{
    if (ruby_single_main_ractor) {
        return ruby_single_main_ractor;
    }
    else {
        const rb_execution_context_t *ec = rb_current_execution_context(expect);
        return (expect || ec) ? rb_ec_ractor_ptr(ec) : NULL;
    }
}

static inline rb_ractor_t *
rb_current_ractor(void)
{
    return rb_current_ractor_raw(true);
}

static inline rb_vm_t *
rb_current_vm(void)
{
#if 0 // TODO: reconsider the assertions
    VM_ASSERT(ruby_current_vm_ptr == NULL ||
              ruby_current_execution_context_ptr == NULL ||
              rb_ec_thread_ptr(GET_EC()) == NULL ||
              rb_ec_thread_ptr(GET_EC())->status == THREAD_KILLED ||
              rb_ec_vm_ptr(GET_EC()) == ruby_current_vm_ptr);
#endif

    return ruby_current_vm_ptr;
}

void rb_ec_vm_lock_rec_release(const rb_execution_context_t *ec,
                               unsigned int recorded_lock_rec,
                               unsigned int current_lock_rec);

static inline unsigned int
rb_ec_vm_lock_rec(const rb_execution_context_t *ec)
{
    rb_vm_t *vm = rb_ec_vm_ptr(ec);

    if (vm->ractor.sync.lock_owner != rb_ec_ractor_ptr(ec)) {
        return 0;
    }
    else {
        return vm->ractor.sync.lock_rec;
    }
}

#else
#error "unsupported thread model"
#endif

enum {
    TIMER_INTERRUPT_MASK         = 0x01,
    PENDING_INTERRUPT_MASK       = 0x02,
    POSTPONED_JOB_INTERRUPT_MASK = 0x04,
    TRAP_INTERRUPT_MASK	         = 0x08,
    TERMINATE_INTERRUPT_MASK     = 0x10,
    VM_BARRIER_INTERRUPT_MASK    = 0x20,
};

#define RUBY_VM_SET_TIMER_INTERRUPT(ec)		ATOMIC_OR((ec)->interrupt_flag, TIMER_INTERRUPT_MASK)
#define RUBY_VM_SET_INTERRUPT(ec)		ATOMIC_OR((ec)->interrupt_flag, PENDING_INTERRUPT_MASK)
#define RUBY_VM_SET_POSTPONED_JOB_INTERRUPT(ec)	ATOMIC_OR((ec)->interrupt_flag, POSTPONED_JOB_INTERRUPT_MASK)
#define RUBY_VM_SET_TRAP_INTERRUPT(ec)		ATOMIC_OR((ec)->interrupt_flag, TRAP_INTERRUPT_MASK)
#define RUBY_VM_SET_TERMINATE_INTERRUPT(ec)     ATOMIC_OR((ec)->interrupt_flag, TERMINATE_INTERRUPT_MASK)
#define RUBY_VM_SET_VM_BARRIER_INTERRUPT(ec)    ATOMIC_OR((ec)->interrupt_flag, VM_BARRIER_INTERRUPT_MASK)
#define RUBY_VM_INTERRUPTED(ec)			((ec)->interrupt_flag & ~(ec)->interrupt_mask & \
                                                 (PENDING_INTERRUPT_MASK|TRAP_INTERRUPT_MASK))

static inline bool
RUBY_VM_INTERRUPTED_ANY(rb_execution_context_t *ec)
{
#if defined(USE_VM_CLOCK) && USE_VM_CLOCK
    uint32_t current_clock = rb_ec_vm_ptr(ec)->clock;

    if (current_clock != ec->checked_clock) {
        ec->checked_clock = current_clock;
        RUBY_VM_SET_TIMER_INTERRUPT(ec);
    }
#endif
    return ec->interrupt_flag & ~(ec)->interrupt_mask;
}

VALUE rb_exc_set_backtrace(VALUE exc, VALUE bt);
int rb_signal_buff_size(void);
int rb_signal_exec(rb_thread_t *th, int sig);
void rb_threadptr_check_signal(rb_thread_t *mth);
void rb_threadptr_signal_raise(rb_thread_t *th, int sig);
void rb_threadptr_signal_exit(rb_thread_t *th);
int rb_threadptr_execute_interrupts(rb_thread_t *, int);
void rb_threadptr_interrupt(rb_thread_t *th);
void rb_threadptr_unlock_all_locking_mutexes(rb_thread_t *th);
void rb_threadptr_pending_interrupt_clear(rb_thread_t *th);
void rb_threadptr_pending_interrupt_enque(rb_thread_t *th, VALUE v);
VALUE rb_ec_get_errinfo(const rb_execution_context_t *ec);
void rb_ec_error_print(rb_execution_context_t * volatile ec, volatile VALUE errinfo);
void rb_execution_context_update(rb_execution_context_t *ec);
void rb_execution_context_mark(const rb_execution_context_t *ec);
void rb_fiber_close(rb_fiber_t *fib);
void Init_native_thread(rb_thread_t *th);
int rb_vm_check_ints_blocking(rb_execution_context_t *ec);

// vm_sync.h
void rb_vm_cond_wait(rb_vm_t *vm, rb_nativethread_cond_t *cond);
void rb_vm_cond_timedwait(rb_vm_t *vm, rb_nativethread_cond_t *cond, unsigned long msec);

#define RUBY_VM_CHECK_INTS(ec) rb_vm_check_ints(ec)
static inline void
rb_vm_check_ints(rb_execution_context_t *ec)
{
#ifdef RUBY_ASSERT_CRITICAL_SECTION
    VM_ASSERT(ruby_assert_critical_section_entered == 0);
#endif

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

void rb_hook_list_mark(rb_hook_list_t *hooks);
void rb_hook_list_mark_and_update(rb_hook_list_t *hooks);
void rb_hook_list_free(rb_hook_list_t *hooks);
void rb_hook_list_connect_tracepoint(VALUE target, rb_hook_list_t *list, VALUE tpval, unsigned int target_line);
void rb_hook_list_remove_tracepoint(rb_hook_list_t *list, VALUE tpval);

void rb_exec_event_hooks(struct rb_trace_arg_struct *trace_arg, rb_hook_list_t *hooks, int pop_p);

#define EXEC_EVENT_HOOK_ORIG(ec_, hooks_, flag_, self_, id_, called_id_, klass_, data_, pop_p_) do { \
    const rb_event_flag_t flag_arg_ = (flag_); \
    rb_hook_list_t *hooks_arg_ = (hooks_); \
    if (UNLIKELY((hooks_arg_)->events & (flag_arg_))) { \
        /* defer evaluating the other arguments */ \
        rb_exec_event_hook_orig(ec_, hooks_arg_, flag_arg_, self_, id_, called_id_, klass_, data_, pop_p_); \
    } \
} while (0)

static inline void
rb_exec_event_hook_orig(rb_execution_context_t *ec, rb_hook_list_t *hooks, rb_event_flag_t flag,
                        VALUE self, ID id, ID called_id, VALUE klass, VALUE data, int pop_p)
{
    struct rb_trace_arg_struct trace_arg;

    VM_ASSERT((hooks->events & flag) != 0);

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

    rb_exec_event_hooks(&trace_arg, hooks, pop_p);
}

struct rb_ractor_pub {
    VALUE self;
    uint32_t id;
    rb_hook_list_t hooks;
};

static inline rb_hook_list_t *
rb_ec_ractor_hooks(const rb_execution_context_t *ec)
{
    struct rb_ractor_pub *cr_pub = (struct rb_ractor_pub *)rb_ec_ractor_ptr(ec);
    return &cr_pub->hooks;
}

#define EXEC_EVENT_HOOK(ec_, flag_, self_, id_, called_id_, klass_, data_) \
  EXEC_EVENT_HOOK_ORIG(ec_, rb_ec_ractor_hooks(ec_), flag_, self_, id_, called_id_, klass_, data_, 0)

#define EXEC_EVENT_HOOK_AND_POP_FRAME(ec_, flag_, self_, id_, called_id_, klass_, data_) \
  EXEC_EVENT_HOOK_ORIG(ec_, rb_ec_ractor_hooks(ec_), flag_, self_, id_, called_id_, klass_, data_, 1)

static inline void
rb_exec_event_hook_script_compiled(rb_execution_context_t *ec, const rb_iseq_t *iseq, VALUE eval_script)
{
    EXEC_EVENT_HOOK(ec, RUBY_EVENT_SCRIPT_COMPILED, ec->cfp->self, 0, 0, 0,
                    NIL_P(eval_script) ? (VALUE)iseq :
                    rb_ary_new_from_args(2, eval_script, (VALUE)iseq));
}

void rb_vm_trap_exit(rb_vm_t *vm);
void rb_vm_postponed_job_atfork(void); /* vm_trace.c */
void rb_vm_postponed_job_free(void); /* vm_trace.c */
size_t rb_vm_memsize_postponed_job_queue(void); /* vm_trace.c */
void rb_vm_postponed_job_queue_init(rb_vm_t *vm); /* vm_trace.c */

RUBY_SYMBOL_EXPORT_BEGIN

int rb_thread_check_trap_pending(void);

/* #define RUBY_EVENT_RESERVED_FOR_INTERNAL_USE 0x030000 */ /* from vm_core.h */
#define RUBY_EVENT_COVERAGE_LINE                0x010000
#define RUBY_EVENT_COVERAGE_BRANCH              0x020000

extern VALUE rb_get_coverages(void);
extern void rb_set_coverages(VALUE, int, VALUE);
extern void rb_clear_coverages(void);
extern void rb_reset_coverages(void);
extern void rb_resume_coverages(void);
extern void rb_suspend_coverages(void);

void rb_postponed_job_flush(rb_vm_t *vm);

// ractor.c
RUBY_EXTERN VALUE rb_eRactorUnsafeError;
RUBY_EXTERN VALUE rb_eRactorIsolationError;

RUBY_SYMBOL_EXPORT_END

#endif /* RUBY_VM_CORE_H */
