#ifndef RUBY_THREAD_PTHREAD_H
#define RUBY_THREAD_PTHREAD_H
/**********************************************************************

  thread_pthread.h -

  $Author$

  Copyright (C) 2004-2007 Koichi Sasada

**********************************************************************/

#ifdef HAVE_PTHREAD_NP_H
#include <pthread_np.h>
#endif

#define RB_NATIVETHREAD_LOCK_INIT PTHREAD_MUTEX_INITIALIZER
#define RB_NATIVETHREAD_COND_INIT PTHREAD_COND_INITIALIZER

// this data should be protected by timer_th.waiting_lock
struct rb_thread_sched_waiting {
    enum thread_sched_waiting_flag {
        thread_sched_waiting_none     = 0x00,
        thread_sched_waiting_timeout  = 0x01,
        thread_sched_waiting_io_read  = 0x02,
        thread_sched_waiting_io_write = 0x08,
        thread_sched_waiting_io_force = 0x40, // ignore readable
    } flags;

    struct {
        // should be compat with hrtime.h
#ifdef MY_RUBY_BUILD_MAY_TIME_TRAVEL
        int128_t timeout;
#else
        uint64_t timeout;
#endif
        int fd; // -1 for timeout only
        int result;
    } data;

    // connected to timer_th.waiting
    struct ccan_list_node node;
};

// per-Thead scheduler helper data
struct rb_thread_sched_item {
    struct {
        struct ccan_list_node ubf;

        // connected to ractor->threads.sched.reqdyq
        // locked by ractor->threads.sched.lock
        struct ccan_list_node readyq;

        // connected to vm->ractor.sched.timeslice_threads
        // locked by vm->ractor.sched.lock
        struct ccan_list_node timeslice_threads;

        // connected to vm->ractor.sched.running_threads
        // locked by vm->ractor.sched.lock
        struct ccan_list_node running_threads;

        // connected to vm->ractor.sched.zombie_threads
        struct ccan_list_node zombie_threads;
    } node;

    struct rb_thread_sched_waiting waiting_reason;

    bool finished;
    bool malloc_stack;
    void *context_stack;
    struct coroutine_context *context;
};

struct rb_native_thread {
    rb_atomic_t serial;
    struct rb_vm_struct *vm;

    rb_nativethread_id_t thread_id;

#ifdef RB_THREAD_T_HAS_NATIVE_ID
    int tid;
#endif

    struct rb_thread_struct *running_thread;

    // to control native thread
#if defined(__GLIBC__) || defined(__FreeBSD__)
    union
#else
    /*
     * assume the platform condvars are badly implemented and have a
     * "memory" of which mutex they're associated with
     */
    struct
#endif
      {
        rb_nativethread_cond_t intr; /* th->interrupt_lock */
        rb_nativethread_cond_t readyq; /* use sched->lock */
    } cond;

#ifdef USE_SIGALTSTACK
    void *altstack;
#endif

    struct coroutine_context *nt_context;
    int dedicated;

    size_t machine_stack_maxsize;
};

#undef except
#undef try
#undef leave
#undef finally

// per-Ractor
struct rb_thread_sched {
    rb_nativethread_lock_t lock_;
#if VM_CHECK_MODE
    struct rb_thread_struct *lock_owner;
#endif
    struct rb_thread_struct *running; // running thread or NULL
    bool is_running;
    bool is_running_timeslice;
    bool enable_mn_threads;

    struct ccan_list_head readyq;
    int readyq_cnt;
    // ractor scheduling
    struct ccan_list_node grq_node;
};

#ifdef RB_THREAD_LOCAL_SPECIFIER
  NOINLINE(void rb_current_ec_set(struct rb_execution_context_struct *));

  # ifdef __APPLE__
    // on Darwin, TLS can not be accessed across .so
    NOINLINE(struct rb_execution_context_struct *rb_current_ec(void));
  # else
    RUBY_EXTERN RB_THREAD_LOCAL_SPECIFIER struct rb_execution_context_struct *ruby_current_ec;

    // for RUBY_DEBUG_LOG()
    RUBY_EXTERN RB_THREAD_LOCAL_SPECIFIER rb_atomic_t ruby_nt_serial;
    #define RUBY_NT_SERIAL 1
  # endif
#else
typedef pthread_key_t native_tls_key_t;

static inline void *
native_tls_get(native_tls_key_t key)
{
    // return value should be checked by caller
    return pthread_getspecific(key);
}

static inline void
native_tls_set(native_tls_key_t key, void *ptr)
{
    if (UNLIKELY(pthread_setspecific(key, ptr) != 0)) {
        rb_bug("pthread_setspecific error");
    }
}

RUBY_EXTERN native_tls_key_t ruby_current_ec_key;
#endif

#endif /* RUBY_THREAD_PTHREAD_H */
