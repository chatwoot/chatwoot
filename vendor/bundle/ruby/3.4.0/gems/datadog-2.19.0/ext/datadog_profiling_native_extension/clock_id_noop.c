#include "extconf.h"

// This file is the dual of clock_id_from_pthread.c for systems where that info
// is not available.
#ifndef HAVE_PTHREAD_GETCPUCLOCKID

#include "clock_id.h"
#include "helpers.h"
#include "datadog_ruby_common.h"

void self_test_clock_id(void) { } // Nothing to check

thread_cpu_time_id thread_cpu_time_id_for(DDTRACE_UNUSED VALUE _thread) {
  return (thread_cpu_time_id) {.valid = false};
}

thread_cpu_time thread_cpu_time_for(DDTRACE_UNUSED thread_cpu_time_id _time_id) {
  return (thread_cpu_time) {.valid = false};
}

#endif
