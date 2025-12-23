#include <ruby.h>

#include "collectors_dynamic_sampling_rate.h"
#include "helpers.h"
#include "ruby_helpers.h"
#include "time_helpers.h"

// Used to pace the rate of profiling samples based on the last observed time for a sample.
//
// This file implements the native bits of the Datadog::Profiling::Collectors::DynamicSamplingRate module, and is
// only exposed to Ruby for testing (it's always and only invoked by other C code in production).

// ---
// ## Dynamic Sampling Rate
//
// Our profilers get deployed in quite unpredictable situations in terms of system resources. While they can provide key
// information to help customers solve their performance problems, the profilers must always be careful not to make
// performance problems worse. This is where the idea of a dynamic sampling rate comes in.
//
// Instead of sampling at a fixed sample rate, the actual sampling rate should be decided by also observing the impact
// that running the profiler is having. This protects against issues such as the profiler being deployed in very busy
// machines or containers with unrealistic CPU restrictions.
//
// ### Implementation
//
// The APIs exposed by this file are used by the `CpuAndWallTimeWorker`.
//
// The main idea of the implementation below is the following: whenever the profiler takes a sample, the time we spent
// sampling and the current wall-time are recorded by calling `dynamic_sampling_rate_after_sample()`.
//
// Inside `dynamic_sampling_rate_after_sample()`, both values are combined to decide a future wall-time before which
// we should not sample. That is, we may decide that the next sample should happen no less than 200ms from now.
//
// Before taking a sample, the profiler checks using `dynamic_sampling_rate_should_sample()`, if it's time or not to
// sample. If it's not, it will skip sampling.
//
// Finally, as an additional optimization, there's a `dynamic_sampling_rate_get_sleep()` which, given the current
// wall-time, will return the time remaining (*there's an exception, check function) until the next sample.
//
// ---

// This is the wall-time overhead we're targeting. E.g. we target to spend no more than 2%, or 1.2 seconds per minute,
// taking profiling samples by default.
#define DEFAULT_WALL_TIME_OVERHEAD_TARGET_PERCENTAGE 2.0 // %
// See `dynamic_sampling_rate_get_sleep()` for details
#define MAX_SLEEP_TIME_NS MILLIS_AS_NS(100)
// See `dynamic_sampling_rate_after_sample()` for details
#define MAX_TIME_UNTIL_NEXT_SAMPLE_NS SECONDS_AS_NS(10)

void dynamic_sampling_rate_init(dynamic_sampling_rate_state *state) {
  atomic_init(&state->next_sample_after_monotonic_wall_time_ns, 0);
  dynamic_sampling_rate_set_overhead_target_percentage(state, DEFAULT_WALL_TIME_OVERHEAD_TARGET_PERCENTAGE);
}

void dynamic_sampling_rate_set_overhead_target_percentage(dynamic_sampling_rate_state *state, double overhead_target_percentage) {
  state->overhead_target_percentage = overhead_target_percentage;
}

void dynamic_sampling_rate_reset(dynamic_sampling_rate_state *state) {
  atomic_store(&state->next_sample_after_monotonic_wall_time_ns, 0);
}

uint64_t dynamic_sampling_rate_get_sleep(dynamic_sampling_rate_state *state, long current_monotonic_wall_time_ns) {
  long next_sample_after_ns = atomic_load(&state->next_sample_after_monotonic_wall_time_ns);
  long delta_ns = next_sample_after_ns - current_monotonic_wall_time_ns;

  if (delta_ns > 0 && next_sample_after_ns > 0) {
    // We don't want to sleep for too long as the profiler may be trying to stop.
    //
    // Instead, here we sleep for at most this time. Worst case, the profiler will still try to sample before
    // `next_sample_after_monotonic_wall_time_ns`, BUT `dynamic_sampling_rate_should_sample()` will still be false
    // so we still get the intended behavior.
    return uint64_min_of(delta_ns, MAX_SLEEP_TIME_NS);
  } else {
    return 0;
  }
}

bool dynamic_sampling_rate_should_sample(dynamic_sampling_rate_state *state, long wall_time_ns_before_sample) {
  return wall_time_ns_before_sample >= atomic_load(&state->next_sample_after_monotonic_wall_time_ns);
}

void dynamic_sampling_rate_after_sample(dynamic_sampling_rate_state *state, long wall_time_ns_after_sample, uint64_t sampling_time_ns) {
  double overhead_target = state->overhead_target_percentage;

  // The idea here is that we're targeting a maximum % of wall-time spent sampling.
  // So for instance, if sampling_time_ns is 2% of the time we spend working, how much is the 98% we should spend
  // sleeping? As an example, if the last sample took 1ms and the target overhead is 2%, we should sleep for 49ms.
  uint64_t time_to_sleep_ns = sampling_time_ns * ((100.0 - overhead_target)/overhead_target);

  // In case a sample took an unexpected long time (e.g. maybe a VM was paused, or a laptop was suspended), we clamp the
  // value so it doesn't get too crazy
  time_to_sleep_ns = uint64_min_of(time_to_sleep_ns, MAX_TIME_UNTIL_NEXT_SAMPLE_NS);

  atomic_store(&state->next_sample_after_monotonic_wall_time_ns, wall_time_ns_after_sample + time_to_sleep_ns);
}

// ---
// Below here is boilerplate to expose the above code to Ruby so that we can test it with RSpec as usual.

VALUE _native_get_sleep(DDTRACE_UNUSED VALUE self, VALUE overhead_target_percentage, VALUE simulated_next_sample_after_monotonic_wall_time_ns, VALUE current_monotonic_wall_time_ns);
VALUE _native_should_sample(DDTRACE_UNUSED VALUE self, VALUE overhead_target_percentage, VALUE simulated_next_sample_after_monotonic_wall_time_ns, VALUE wall_time_ns_before_sample);
VALUE _native_after_sample(DDTRACE_UNUSED VALUE self, VALUE overhead_target_percentage, VALUE wall_time_ns_after_sample, VALUE sampling_time_ns);

void collectors_dynamic_sampling_rate_init(VALUE profiling_module) {
  VALUE collectors_module = rb_define_module_under(profiling_module, "Collectors");
  VALUE dynamic_sampling_rate_module = rb_define_module_under(collectors_module, "DynamicSamplingRate");
  VALUE testing_module = rb_define_module_under(dynamic_sampling_rate_module, "Testing");

  rb_define_singleton_method(testing_module, "_native_get_sleep", _native_get_sleep, 3);
  rb_define_singleton_method(testing_module, "_native_should_sample", _native_should_sample, 3);
  rb_define_singleton_method(testing_module, "_native_after_sample", _native_after_sample, 3);
}

VALUE _native_get_sleep(DDTRACE_UNUSED VALUE self, VALUE overhead_target_percentage, VALUE simulated_next_sample_after_monotonic_wall_time_ns, VALUE current_monotonic_wall_time_ns) {
  ENFORCE_TYPE(simulated_next_sample_after_monotonic_wall_time_ns, T_FIXNUM);
  ENFORCE_TYPE(current_monotonic_wall_time_ns, T_FIXNUM);

  dynamic_sampling_rate_state state;
  dynamic_sampling_rate_init(&state);
  dynamic_sampling_rate_set_overhead_target_percentage(&state, NUM2DBL(overhead_target_percentage));
  atomic_store(&state.next_sample_after_monotonic_wall_time_ns, NUM2LONG(simulated_next_sample_after_monotonic_wall_time_ns));

  return ULL2NUM(dynamic_sampling_rate_get_sleep(&state, NUM2LONG(current_monotonic_wall_time_ns)));
}

VALUE _native_should_sample(DDTRACE_UNUSED VALUE self, VALUE overhead_target_percentage, VALUE simulated_next_sample_after_monotonic_wall_time_ns, VALUE wall_time_ns_before_sample) {
  ENFORCE_TYPE(simulated_next_sample_after_monotonic_wall_time_ns, T_FIXNUM);
  ENFORCE_TYPE(wall_time_ns_before_sample, T_FIXNUM);

  dynamic_sampling_rate_state state;
  dynamic_sampling_rate_init(&state);
  dynamic_sampling_rate_set_overhead_target_percentage(&state, NUM2DBL(overhead_target_percentage));
  atomic_store(&state.next_sample_after_monotonic_wall_time_ns, NUM2LONG(simulated_next_sample_after_monotonic_wall_time_ns));

  return dynamic_sampling_rate_should_sample(&state, NUM2LONG(wall_time_ns_before_sample)) ? Qtrue : Qfalse;
}

VALUE _native_after_sample(DDTRACE_UNUSED VALUE self, VALUE overhead_target_percentage, VALUE wall_time_ns_after_sample, VALUE sampling_time_ns) {
  ENFORCE_TYPE(wall_time_ns_after_sample, T_FIXNUM);
  ENFORCE_TYPE(sampling_time_ns, T_FIXNUM);

  dynamic_sampling_rate_state state;
  dynamic_sampling_rate_init(&state);
  dynamic_sampling_rate_set_overhead_target_percentage(&state, NUM2DBL(overhead_target_percentage));

  dynamic_sampling_rate_after_sample(&state, NUM2LONG(wall_time_ns_after_sample), NUM2ULL(sampling_time_ns));

  return ULL2NUM(atomic_load(&state.next_sample_after_monotonic_wall_time_ns));
}
