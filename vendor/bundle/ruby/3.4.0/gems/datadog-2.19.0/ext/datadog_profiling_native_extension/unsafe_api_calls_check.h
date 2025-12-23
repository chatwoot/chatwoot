#pragma once

// This checker is used to detect accidental thread scheduling switching points happening during profiling sampling.
//
// Specifically, when the profiler is sampling, we're never supposed to call into Ruby code (e.g. methods
// implemented using Ruby code) or allocate Ruby objects.
// That's because those events introduce thread switch points, and really we don't the VM switching between threads
// in the middle of the profiler sampling.
// This includes raising exceptions, unless we're trying to stop the profiler, and even then we must be careful.
//
// The above is especially true in situations such as GC profiling or allocation/heap profiling, as in those situations
// we can even crash the Ruby VM if we switch away at the wrong time.
//
// The below APIs can be used to detect these situations. They work by relying on the following observation:
// in most (all?) thread switch points, Ruby will check for interrupts and run the postponed jobs.
//
// Thus, if we set a flag while we're sampling (inside_unsafe_context), trigger the postponed job, and then only unset
// the flag after sampling, he correct thing to happen is that the postponed job should never see the flag.
//
// If, however, we have a bug and there's a thread switch point, our postponed job will see the flag and immediately
// stop the Ruby VM before further damage happens (and hopefully giving us a stack trace clearly pointing to the culprit).

void unsafe_api_calls_check_init(void);

// IMPORTANT: This method **MUST** only be called from test code, as it causes an immediate hard-crash on the Ruby VM
// when it detects a potential issue, and that's not something we want for production apps.
//
// In the future we may introduce some kind of setting (off by default) to also allow this to be safely be used
// in production code if needed.
void debug_enter_unsafe_context(void);
void debug_leave_unsafe_context(void);
