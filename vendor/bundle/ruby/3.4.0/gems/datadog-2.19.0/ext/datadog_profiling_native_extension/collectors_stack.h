#pragma once

#include <datadog/profiling.h>

#include "private_vm_api_access.h"
#include "stack_recorder.h"

#define MAX_FRAMES_LIMIT            3000
#define MAX_FRAMES_LIMIT_AS_STRING "3000"

// Used as scratch space during sampling
typedef struct {
  uint16_t max_frames;
  ddog_prof_Location *locations;
  frame_info *stack_buffer;
  bool pending_sample;
  bool is_marking; // Used to avoid recording a sample when marking
  int pending_sample_result;
} sampling_buffer;

void sample_thread(
  VALUE thread,
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  bool native_filenames_enabled,
  st_table *native_filenames_cache
);
void record_placeholder_stack(
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  ddog_CharSlice placeholder_stack
);
bool prepare_sample_thread(VALUE thread, sampling_buffer *buffer);

uint16_t sampling_buffer_check_max_frames(int max_frames);
void sampling_buffer_initialize(sampling_buffer *buffer, uint16_t max_frames, ddog_prof_Location *locations);
void sampling_buffer_free(sampling_buffer *buffer);
void sampling_buffer_mark(sampling_buffer *buffer);
static inline bool sampling_buffer_needs_marking(sampling_buffer *buffer) {
  return buffer->pending_sample && buffer->pending_sample_result > 0;
}
