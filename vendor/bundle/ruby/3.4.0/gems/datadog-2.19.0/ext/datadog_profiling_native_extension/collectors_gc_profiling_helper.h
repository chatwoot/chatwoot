#pragma once

void gc_profiling_init(void);
bool gc_profiling_has_major_gc_finished(void);
uint8_t gc_profiling_set_metadata(ddog_prof_Label *labels, int labels_length);
