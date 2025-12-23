#pragma once

#include <datadog/profiling.h>
#include <ruby.h>

typedef struct {
  int64_t cpu_time_ns;
  int64_t wall_time_ns;
  uint32_t cpu_or_wall_samples;
  uint32_t alloc_samples;
  uint32_t alloc_samples_unscaled;
  bool heap_sample;
  int64_t timeline_wall_time_ns;
} sample_values;

typedef struct {
  ddog_prof_Slice_Label labels;

  // This is used to allow the `Collectors::Stack` to modify the existing label, if any. This MUST be NULL or point
  // somewhere inside the labels slice above.
  ddog_prof_Label *state_label;
  bool is_gvl_waiting_state;

  int64_t end_timestamp_ns;
} sample_labels;

void record_sample(VALUE recorder_instance, ddog_prof_Slice_Location locations, sample_values values, sample_labels labels);
void record_endpoint(VALUE recorder_instance, uint64_t local_root_span_id, ddog_CharSlice endpoint);
void track_object(VALUE recorder_instance, VALUE new_object, unsigned int sample_weight, ddog_CharSlice alloc_class);
void recorder_after_gc_step(VALUE recorder_instance);
VALUE enforce_recorder_instance(VALUE object);
