#include "extconf.h"

// This file is only compiled on systems where pthread_getcpuclockid() is available;
// Otherwise we compile clock_id_noop.c
#ifdef HAVE_PTHREAD_GETCPUCLOCKID

#include <pthread.h>
#include <time.h>
#include <errno.h>

#include "clock_id.h"
#include "helpers.h"
#include "private_vm_api_access.h"
#include "time_helpers.h"

// Validate that our home-cooked pthread_id_for() matches pthread_self() for the current thread
void self_test_clock_id(void) {
  rb_nativethread_id_t expected_pthread_id = pthread_self();
  rb_nativethread_id_t actual_pthread_id = pthread_id_for(rb_thread_current());

  if (expected_pthread_id != actual_pthread_id) rb_raise(rb_eRuntimeError, "pthread_id_for() self-test failed");
}

// Safety: This function is assumed never to raise exceptions by callers
thread_cpu_time_id thread_cpu_time_id_for(VALUE thread) {
  rb_nativethread_id_t thread_id = pthread_id_for(thread);

  if (thread_id == 0) return (thread_cpu_time_id) {.valid = false};

  clockid_t clock_id;

  int error = pthread_getcpuclockid(thread_id, &clock_id);

  if (error == 0) {
    return (thread_cpu_time_id) {.valid = true, .clock_id = clock_id};
  } else {
    // TODO: Include the error code in some way in the output?
    return (thread_cpu_time_id) {.valid = false};
  }
}

thread_cpu_time thread_cpu_time_for(thread_cpu_time_id time_id) {
  thread_cpu_time error = (thread_cpu_time) {.valid = false};

  if (!time_id.valid) { return error; }

  struct timespec current_cpu;

  // TODO: Include the error code in some way in the output?
  if (clock_gettime(time_id.clock_id, &current_cpu) != 0) return error;

  return (thread_cpu_time) {.valid = true, .result_ns = current_cpu.tv_nsec + SECONDS_AS_NS(current_cpu.tv_sec)};
}

#endif
