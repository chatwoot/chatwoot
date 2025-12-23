#pragma once

#include <stdbool.h>

// The private_vm_api_access.c includes the RUBY_MJIT_HEADER which replaces and conflicts with any other Ruby headers;
// so we use PRIVATE_VM_API_ACCESS_SKIP_RUBY_INCLUDES to be able to include private_vm_api_access.h on that file
// without also dragging the incompatible includes
#ifndef PRIVATE_VM_API_ACCESS_SKIP_RUBY_INCLUDES
  #include <ruby/thread_native.h>
  #include <ruby/vm.h>
#endif

#include "extconf.h"

// Contains the current gvl owner, and a flag to indicate if it is valid
typedef struct {
  bool valid;
  rb_nativethread_id_t owner;
} current_gvl_owner;

// If a sample is kept around for later use, some of its fields need marking. Remember to
// update the marking code in `sampling_buffer_mark` if new fields are added.
typedef struct {
  union {
    struct {
      VALUE iseq; // Needs marking if kept around
      void *caching_pc; // For caching validation/invalidation only (does not need marking)
      int line;
    } ruby_frame;
    struct {
      VALUE caching_cme; // For caching validation/invalidation only (does not need marking)
      ID method_id;
      void *function;
    } native_frame;
  } as;
  bool is_ruby_frame : 1;
  bool same_frame : 1;
} frame_info;

rb_nativethread_id_t pthread_id_for(VALUE thread);
bool is_current_thread_holding_the_gvl(void);
current_gvl_owner gvl_owner(void);
uint64_t native_thread_id_for(VALUE thread);
void ddtrace_thread_list(VALUE result_array);
bool is_thread_alive(VALUE thread);
VALUE thread_name_for(VALUE thread);

int ddtrace_rb_profile_frames(VALUE thread, int start, int limit, frame_info *stack_buffer);

// Returns true if the current thread belongs to the main Ractor or if Ruby has no Ractor support
bool ddtrace_rb_ractor_main_p(void);

// See comment on `record_placeholder_stack_in_native_code` for a full explanation of what this means (and why we don't just return 0)
#define PLACEHOLDER_STACK_IN_NATIVE_CODE -1

// This method provides the file and line of the "invoke location" of a thread (first file:line of the block used to
// start the thread), if any.
// This is what Ruby shows in `Thread#to_s`.
// The file is returned directly, and the line is recorded onto *line_location.
VALUE invoke_location_for(VALUE thread, int *line_location);

// Check if RUBY_MN_THREADS is enabled (aka main Ractor is not doing 1:1 threads)
void self_test_mn_enabled(void);

// Provides more specific information on what kind an imemo is
const char *imemo_kind(VALUE imemo);

#ifdef NO_POSTPONED_TRIGGER
  void *objspace_ptr_for_gc_finalize_deferred_workaround(void);
#endif

#define ENFORCE_THREAD(value) \
  { if (RB_UNLIKELY(!rb_typeddata_is_kind_of(value, RTYPEDDATA_TYPE(rb_thread_current())))) raise_unexpected_type(value, ADD_QUOTES(value), "Thread", __FILE__, __LINE__, __func__); }

bool is_raised_flag_set(VALUE thread);

// Can be nil if `rb_fiber_current()` or similar has not been called (gets allocated lazily)
// Only implemented for Ruby 3.1+
VALUE current_fiber_for(VALUE thread);

void self_test_current_fiber_for(void);
