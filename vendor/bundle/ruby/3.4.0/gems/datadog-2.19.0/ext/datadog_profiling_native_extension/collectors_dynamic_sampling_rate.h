#pragma once

#include <stdatomic.h>
#include <stdbool.h>

typedef struct {
  // This is the wall-time overhead we're targeting. E.g. by default, we target to spend no more than 2%, or 1.2 seconds
  // per minute, taking profiling samples.
  double overhead_target_percentage;
  atomic_long next_sample_after_monotonic_wall_time_ns;
} dynamic_sampling_rate_state;

void dynamic_sampling_rate_init(dynamic_sampling_rate_state *state);
void dynamic_sampling_rate_set_overhead_target_percentage(dynamic_sampling_rate_state *state, double overhead_target_percentage);
void dynamic_sampling_rate_reset(dynamic_sampling_rate_state *state);
uint64_t dynamic_sampling_rate_get_sleep(dynamic_sampling_rate_state *state, long current_monotonic_wall_time_ns);
bool dynamic_sampling_rate_should_sample(dynamic_sampling_rate_state *state, long wall_time_ns_before_sample);
void dynamic_sampling_rate_after_sample(dynamic_sampling_rate_state *state, long wall_time_ns_after_sample, uint64_t sampling_time_ns);
