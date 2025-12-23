#pragma once

#include <stdbool.h>
#include <errno.h>
#include <time.h>

#include "extconf.h" // Needed for HAVE_CLOCK_MONOTONIC_COARSE
#include "ruby_helpers.h"

#define SECONDS_AS_NS(value) (value * 1000 * 1000 * 1000L)
#define MILLIS_AS_NS(value) (value * 1000 * 1000L)

typedef enum { RAISE_ON_FAILURE, DO_NOT_RAISE_ON_FAILURE } raise_on_failure_setting;

#define INVALID_TIME -1

typedef struct {
  long system_epoch_ns_reference;
  long delta_to_epoch_ns;
} monotonic_to_system_epoch_state;

#define MONOTONIC_TO_SYSTEM_EPOCH_INITIALIZER {.system_epoch_ns_reference = INVALID_TIME, .delta_to_epoch_ns = INVALID_TIME}

static inline long retrieve_clock_as_ns(clockid_t clock_id, raise_on_failure_setting raise_on_failure) {
  struct timespec clock_value;

  if (clock_gettime(clock_id, &clock_value) != 0) {
    if (raise_on_failure == RAISE_ON_FAILURE) ENFORCE_SUCCESS_GVL(errno);
    return 0;
  }

  return clock_value.tv_nsec + SECONDS_AS_NS(clock_value.tv_sec);
}

static inline long monotonic_wall_time_now_ns(raise_on_failure_setting raise_on_failure) { return retrieve_clock_as_ns(CLOCK_MONOTONIC, raise_on_failure); }
static inline long system_epoch_time_now_ns(raise_on_failure_setting raise_on_failure)   { return retrieve_clock_as_ns(CLOCK_REALTIME,  raise_on_failure); }

// Coarse instants use CLOCK_MONOTONIC_COARSE on Linux which is expected to provide resolution in the millisecond range:
// https://docs.redhat.com/en/documentation/red_hat_enterprise_linux_for_real_time/7/html/reference_guide/sect-posix_clocks#Using_clock_getres_to_compare_clock_resolution
// We introduce here a separate type for it, so as to make it harder to misuse/more explicit when these timestamps are used

typedef struct {
  long timestamp_ns;
} coarse_instant;

static inline coarse_instant to_coarse_instant(long timestamp_ns) { return (coarse_instant) {.timestamp_ns = timestamp_ns}; }

static inline coarse_instant monotonic_coarse_wall_time_now_ns(void) {
 #ifdef HAVE_CLOCK_MONOTONIC_COARSE // Linux
    return to_coarse_instant(retrieve_clock_as_ns(CLOCK_MONOTONIC_COARSE, DO_NOT_RAISE_ON_FAILURE));
  #else // macOS
    return to_coarse_instant(retrieve_clock_as_ns(CLOCK_MONOTONIC, DO_NOT_RAISE_ON_FAILURE));
  #endif
}

long monotonic_to_system_epoch_ns(monotonic_to_system_epoch_state *state, long monotonic_wall_time_ns);
