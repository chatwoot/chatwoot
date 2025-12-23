#pragma once

#include <signal.h>
#include "datadog_ruby_common.h"

void empty_signal_handler(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext);
void install_sigprof_signal_handler(void (*signal_handler_function)(int, siginfo_t *, void *), const char *handler_pretty_name);
void replace_sigprof_signal_handler_with_empty_handler(void (*expected_existing_handler)(int, siginfo_t *, void *));
void remove_sigprof_signal_handler(void);
void block_sigprof_signal_handler_from_running_in_current_thread(void);
void unblock_sigprof_signal_handler_from_running_in_current_thread(void);
VALUE is_sigprof_blocked_in_current_thread(void);
