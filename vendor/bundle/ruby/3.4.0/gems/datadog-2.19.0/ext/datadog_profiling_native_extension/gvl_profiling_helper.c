#include <ruby.h>
#include <ruby/thread.h>

#include "datadog_ruby_common.h"
#include "gvl_profiling_helper.h"

#if !defined(NO_GVL_INSTRUMENTATION) && !defined(USE_GVL_PROFILING_3_2_WORKAROUNDS) // Ruby 3.3+
  rb_internal_thread_specific_key_t gvl_waiting_tls_key;

  void gvl_profiling_init(void) {
    gvl_waiting_tls_key = rb_internal_thread_specific_key_create();
  }

#endif

#ifdef USE_GVL_PROFILING_3_2_WORKAROUNDS // Ruby 3.2
  __thread gvl_profiling_thread gvl_waiting_tls;
  static bool gvl_profiling_state_thread_tracking_workaround_installed = false;

  static void on_thread_start(
    DDTRACE_UNUSED rb_event_flag_t _unused1,
    DDTRACE_UNUSED const rb_internal_thread_event_data_t *_unused2,
    DDTRACE_UNUSED void *_unused3
  ) {
    gvl_waiting_tls = (gvl_profiling_thread) {.thread = NULL};
  }

  // Hack: We're using the gvl_waiting_tls native thread-local to store per-thread information. Unfortunately, Ruby puts a big hole
  // in our plan because it reuses native threads -- specifically, in Ruby 3.2, native threads are still 1:1 to Ruby
  // threads (M:N wasn't a thing yet) BUT once a Ruby thread dies, the VM will keep the native thread around for a
  // bit, and if another Ruby thread starts right after, Ruby will reuse the native thread, rather than create a new one.
  //
  // This will mean that the new Ruby thread will still have the same native thread-local data that we set on the
  // old thread. For the purposes of our tracking, where we're keeping a pointer to the current thread object in
  // thread-local storage **this is disastrous** since it means we'll be pointing at the wrong thread (and its
  // memory may have been freed or reused since!)
  //
  // To work around this issue, once GVL profiling is enabled, we install an event hook on thread start
  // events that clears the thread-local data. This guarantees that there will be no stale data -- any existing
  // data will be cleared at thread start.
  //
  // Note that once installed, this event hook becomes permanent -- stopping the profiler does not stop this event
  // hook, unlike all others. This is because we can't afford to miss any thread start events while the
  // profiler is stopped (e.g. during reconfiguration) as that would mean stale data once the profiler starts again.
  void gvl_profiling_state_thread_tracking_workaround(void) {
    if (gvl_profiling_state_thread_tracking_workaround_installed) return;

    rb_internal_thread_add_event_hook(on_thread_start, RUBY_INTERNAL_THREAD_EVENT_STARTED, NULL);

    gvl_profiling_state_thread_tracking_workaround_installed = true;
  }
#endif
