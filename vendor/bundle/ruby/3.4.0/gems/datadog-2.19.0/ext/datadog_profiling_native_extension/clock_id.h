#pragma once

#include <stdbool.h>
#include <time.h>
#include <ruby.h>

// Contains the operating-system specific identifier needed to fetch CPU-time, and a flag to indicate if we failed to fetch it
typedef struct {
  bool valid;
  clockid_t clock_id;
} thread_cpu_time_id;

// Contains the current cpu time, and a flag to indicate if we failed to fetch it
typedef struct {
  bool valid;
  long result_ns;
} thread_cpu_time;

void self_test_clock_id(void);

// Safety: This function is assumed never to raise exceptions by callers
thread_cpu_time_id thread_cpu_time_id_for(VALUE thread);
thread_cpu_time thread_cpu_time_for(thread_cpu_time_id time_id);
