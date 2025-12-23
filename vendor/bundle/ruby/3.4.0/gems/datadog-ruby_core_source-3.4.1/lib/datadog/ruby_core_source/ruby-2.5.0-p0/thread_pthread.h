/**********************************************************************

  thread_pthread.h -

  $Author: kosaki $

  Copyright (C) 2004-2007 Koichi Sasada

**********************************************************************/

#ifndef RUBY_THREAD_PTHREAD_H
#define RUBY_THREAD_PTHREAD_H

#ifdef HAVE_PTHREAD_NP_H
#include <pthread_np.h>
#endif

#define RB_NATIVETHREAD_LOCK_INIT PTHREAD_MUTEX_INITIALIZER
#define RB_NATIVETHREAD_COND_INIT { PTHREAD_COND_INITIALIZER, }

typedef struct rb_thread_cond_struct {
    pthread_cond_t cond;
#ifdef HAVE_CLOCKID_T
    clockid_t clockid;
#endif
} rb_nativethread_cond_t;

typedef struct native_thread_data_struct {
    struct list_node ubf_list;
    rb_nativethread_cond_t sleep_cond;
} native_thread_data_t;

#undef except
#undef try
#undef leave
#undef finally

typedef struct rb_global_vm_lock_struct {
    /* fast path */
    unsigned long acquired;
    rb_nativethread_lock_t lock;

    /* slow path */
    volatile unsigned long waiting;
    rb_nativethread_cond_t cond;

    /* yield */
    rb_nativethread_cond_t switch_cond;
    rb_nativethread_cond_t switch_wait_cond;
    int need_yield;
    int wait_yield;
} rb_global_vm_lock_t;

#endif /* RUBY_THREAD_PTHREAD_H */
