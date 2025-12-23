#include <ruby.h>
#include <ruby/debug.h>
#include <stdbool.h>

#include "datadog_ruby_common.h"
#include "unsafe_api_calls_check.h"
#include "extconf.h"

static bool inside_unsafe_context = false;

#ifndef NO_POSTPONED_TRIGGER
  static rb_postponed_job_handle_t check_for_unsafe_api_calls_handle;
#endif

static void check_for_unsafe_api_calls(DDTRACE_UNUSED void *_unused);

void unsafe_api_calls_check_init(void) {
  #ifndef NO_POSTPONED_TRIGGER
    int unused_flags = 0;

    check_for_unsafe_api_calls_handle = rb_postponed_job_preregister(unused_flags, check_for_unsafe_api_calls, NULL);

   if (check_for_unsafe_api_calls_handle == POSTPONED_JOB_HANDLE_INVALID) {
     rb_raise(rb_eRuntimeError, "Failed to register check_for_unsafe_api_calls_handle postponed job (got POSTPONED_JOB_HANDLE_INVALID)");
   }
  #endif
}

void debug_enter_unsafe_context(void) {
  inside_unsafe_context = true;

  #ifndef NO_POSTPONED_TRIGGER
    rb_postponed_job_trigger(check_for_unsafe_api_calls_handle);
  #else
    rb_postponed_job_register(0, check_for_unsafe_api_calls, NULL);
  #endif
}

void debug_leave_unsafe_context(void) {
  inside_unsafe_context = false;
}

static void check_for_unsafe_api_calls(DDTRACE_UNUSED void *_unused) {
  if (inside_unsafe_context) rb_bug(
    "Datadog Ruby profiler detected callback nested inside sample. Please report this at https://github.com/datadog/dd-trace-rb/blob/master/CONTRIBUTING.md#found-a-bug"
  );
}
