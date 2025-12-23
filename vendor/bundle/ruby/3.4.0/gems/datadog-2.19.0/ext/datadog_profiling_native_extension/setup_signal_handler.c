#include <ruby.h>
#include <signal.h>
#include <errno.h>
#include <stdbool.h>

#include "helpers.h"
#include "setup_signal_handler.h"
#include "ruby_helpers.h"

// Used by Collectors::CpuAndWallTimeWorker to setup SIGPROF signal handlers used for cpu/wall-time profiling.

static void install_sigprof_signal_handler_internal(
  void (*signal_handler_function)(int, siginfo_t *, void *),
  const char *handler_pretty_name,
  void (*signal_handler_to_replace)(int, siginfo_t *, void *)
);

void empty_signal_handler(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext) { }

void install_sigprof_signal_handler(void (*signal_handler_function)(int, siginfo_t *, void *), const char *handler_pretty_name) {
  install_sigprof_signal_handler_internal(signal_handler_function, handler_pretty_name, NULL);
}

void replace_sigprof_signal_handler_with_empty_handler(void (*expected_existing_handler)(int, siginfo_t *, void *)) {
  install_sigprof_signal_handler_internal(empty_signal_handler, "empty_signal_handler", expected_existing_handler);
}

static void install_sigprof_signal_handler_internal(
  void (*signal_handler_function)(int, siginfo_t *, void *),
  const char *handler_pretty_name,
  void (*signal_handler_to_replace)(int, siginfo_t *, void *)
) {
  struct sigaction existing_signal_handler_config = {.sa_sigaction = NULL};
  struct sigaction signal_handler_config = {
    .sa_flags = SA_RESTART | SA_SIGINFO,
    .sa_sigaction = signal_handler_function
  };
  sigemptyset(&signal_handler_config.sa_mask);

  if (sigaction(SIGPROF, &signal_handler_config, &existing_signal_handler_config) != 0) {
    rb_exc_raise(rb_syserr_new_str(errno, rb_sprintf("Could not install profiling signal handler (%s)", handler_pretty_name)));
  }

  // Because signal handler functions are global, let's check if we're not stepping on someone else's toes.

  // If the existing signal handler was our empty one, that's ok as well
  if (existing_signal_handler_config.sa_sigaction == empty_signal_handler ||
  // In some corner cases (e.g. after a fork), our signal handler may still be around, and that's ok
    existing_signal_handler_config.sa_sigaction == signal_handler_function ||
  // Are we replacing a known handler with another one?
    (signal_handler_to_replace != NULL && existing_signal_handler_config.sa_sigaction == signal_handler_to_replace)
  ) { return; }

  if (existing_signal_handler_config.sa_handler != NULL || existing_signal_handler_config.sa_sigaction != NULL) {
    // An unexpected/unknown signal handler already existed. Currently we don't support this situation, so let's just back out
    // of the installation.

    if (sigaction(SIGPROF, &existing_signal_handler_config, NULL) != 0) {
      rb_exc_raise(
        rb_syserr_new_str(
          errno,
          rb_sprintf(
            "Failed to install profiling signal handler (%s): " \
            "While installing a SIGPROF signal handler, the profiler detected that another software/library/gem had " \
            "previously installed a different SIGPROF signal handler. " \
            "The profiler tried to restore the previous SIGPROF signal handler, but this failed. " \
            "The other software/library/gem may have been left in a broken state. ",
            handler_pretty_name
          )
        )
      );
    }

    rb_raise(
      rb_eRuntimeError,
      "Could not install profiling signal handler (%s): There's a pre-existing SIGPROF signal handler",
      handler_pretty_name
    );
  }
}

// Note: Be careful when using this; you probably want to use `replace_sigprof_signal_handler_with_empty_handler` instead.
// (See comments on `collectors_cpu_and_wall_time_worker.c` for details)
void remove_sigprof_signal_handler(void) {
  struct sigaction signal_handler_config = {
    .sa_handler = SIG_DFL, // Reset back to default
    .sa_flags = SA_RESTART // TODO: Unclear if this is actually needed/does anything at all
  };
  sigemptyset(&signal_handler_config.sa_mask);

  if (sigaction(SIGPROF, &signal_handler_config, NULL) != 0) rb_sys_fail("Failure while removing the signal handler");
}

static inline void toggle_sigprof_signal_handler_for_current_thread(int action) {
  sigset_t signals_to_toggle;
  sigemptyset(&signals_to_toggle);
  sigaddset(&signals_to_toggle, SIGPROF);
  int error = pthread_sigmask(action, &signals_to_toggle, NULL);
  if (error) rb_exc_raise(rb_syserr_new_str(error, rb_sprintf("Unexpected failure in pthread_sigmask, action=%d", action)));
}

void block_sigprof_signal_handler_from_running_in_current_thread(void) {
  toggle_sigprof_signal_handler_for_current_thread(SIG_BLOCK);
}

void unblock_sigprof_signal_handler_from_running_in_current_thread(void) {
  toggle_sigprof_signal_handler_for_current_thread(SIG_UNBLOCK);
}

VALUE is_sigprof_blocked_in_current_thread(void) {
  sigset_t current_signals;
  sigemptyset(&current_signals);
  ENFORCE_SUCCESS_GVL(pthread_sigmask(0, NULL, &current_signals));
  return sigismember(&current_signals, SIGPROF) ? Qtrue : Qfalse;
}
