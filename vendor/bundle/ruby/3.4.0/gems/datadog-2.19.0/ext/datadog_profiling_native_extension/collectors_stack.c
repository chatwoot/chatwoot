#include <ruby.h>
#include <ruby/debug.h>
#include <ruby/st.h>
#include <stdatomic.h>

#include "extconf.h" // This is needed for the HAVE_DLADDR and friends below

#if (defined(HAVE_DLADDR1) && HAVE_DLADDR1) || (defined(HAVE_DLADDR) && HAVE_DLADDR)
  #ifndef _GNU_SOURCE
    #define _GNU_SOURCE
  #endif
  #include <dlfcn.h>
  #if defined(HAVE_DLADDR1) && HAVE_DLADDR1
    #include <link.h>
  #endif
#endif

#include "datadog_ruby_common.h"
#include "private_vm_api_access.h"
#include "stack_recorder.h"
#include "collectors_stack.h"

// Gathers stack traces from running threads, storing them in a StackRecorder instance
// This file implements the native bits of the Datadog::Profiling::Collectors::Stack class

static VALUE _native_filenames_available(DDTRACE_UNUSED VALUE self);
static VALUE _native_ruby_native_filename(DDTRACE_UNUSED VALUE self);
static VALUE _native_sample(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self);
static VALUE native_sample_do(VALUE args);
static VALUE native_sample_ensure(VALUE args);
static void set_file_info_for_cfunc(
  ddog_CharSlice *filename_slice,
  int *line,
  ddog_CharSlice last_ruby_frame_filename,
  int last_ruby_line,
  void *function,
  bool top_of_the_stack,
  bool native_filenames_enabled,
  st_table *native_filenames_cache
);
static const char *get_or_compute_native_filename(void *function, st_table *native_filenames_cache);
static void add_truncated_frames_placeholder(sampling_buffer* buffer);
static void record_placeholder_stack_in_native_code(VALUE recorder_instance, sample_values values, sample_labels labels);
static void maybe_trim_template_random_ids(ddog_CharSlice *name_slice, ddog_CharSlice *filename_slice);

// These two functions are exposed as symbols by the VM but are not in any header.
// Their signatures actually take a `const rb_iseq_t *iseq` but it gets casted back and forth between VALUE.
extern VALUE rb_iseq_path(const VALUE);
extern VALUE rb_iseq_base_label(const VALUE);

// NULL if dladdr is not available or we weren't able to get the native filename for the Ruby VM
static const char *ruby_native_filename = NULL;

void collectors_stack_init(VALUE profiling_module) {
  VALUE collectors_module = rb_define_module_under(profiling_module, "Collectors");
  VALUE collectors_stack_class = rb_define_class_under(collectors_module, "Stack", rb_cObject);

  rb_define_singleton_method(collectors_stack_class, "_native_filenames_available?", _native_filenames_available, 0);
  rb_define_singleton_method(collectors_stack_class, "_native_ruby_native_filename", _native_ruby_native_filename, 0);

  // Hosts methods used for testing the native code using RSpec
  VALUE testing_module = rb_define_module_under(collectors_stack_class, "Testing");

  rb_define_singleton_method(testing_module, "_native_sample", _native_sample, -1);

  #if (defined(HAVE_DLADDR1) && HAVE_DLADDR1) || (defined(HAVE_DLADDR) && HAVE_DLADDR)
    // To be able to detect when a frame is coming from Ruby, we record here its filename as returned by dladdr.
    // We expect this same pointer to be returned by dladdr for all frames coming from Ruby.
    //
    // Small note: Creating/deleting the cache is a bit awkward here, but it seems like a bigger footgun to allow
    // `get_or_compute_native_filename` to run without a cache, since we never expect that to happen during sampling. So it seems
    // like a reasonable trade-off to force callers to always figure that out.
    st_table *temporary_cache = st_init_numtable();
    const char *native_filename = get_or_compute_native_filename(rb_ary_new, temporary_cache);
    if (native_filename != NULL && native_filename[0] != '\0') {
      ruby_native_filename = native_filename;
    }
    st_free_table(temporary_cache);
  #endif
}

static VALUE _native_filenames_available(DDTRACE_UNUSED VALUE self) {
  #if (defined(HAVE_DLADDR1) && HAVE_DLADDR1) || (defined(HAVE_DLADDR) && HAVE_DLADDR)
    return ruby_native_filename != NULL ? Qtrue : Qfalse;
  #else
    return Qfalse;
  #endif
}

static VALUE _native_ruby_native_filename(DDTRACE_UNUSED VALUE self) {
  return ruby_native_filename != NULL ? rb_utf8_str_new_cstr(ruby_native_filename) : Qnil;
}

typedef struct {
  VALUE in_gc;
  VALUE recorder_instance;
  sample_values values;
  sample_labels labels;
  VALUE thread;
  ddog_prof_Location *locations;
  sampling_buffer *buffer;
  bool native_filenames_enabled;
  st_table *native_filenames_cache;
} native_sample_args;

// This method exists only to enable testing Datadog::Profiling::Collectors::Stack behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_sample(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self) {
  // Positional args
  VALUE thread;
  VALUE recorder_instance;
  VALUE metric_values_hash;
  VALUE labels_array;
  VALUE numeric_labels_array;
  VALUE options;

  rb_scan_args(argc, argv, "5:", &thread, &recorder_instance, &metric_values_hash, &labels_array, &numeric_labels_array, &options);

  if (options == Qnil) options = rb_hash_new();

  // Optional keyword args
  VALUE max_frames = rb_hash_lookup2(options, ID2SYM(rb_intern("max_frames")), INT2NUM(400));
  VALUE in_gc = rb_hash_lookup2(options, ID2SYM(rb_intern("in_gc")), Qfalse);
  VALUE is_gvl_waiting_state = rb_hash_lookup2(options, ID2SYM(rb_intern("is_gvl_waiting_state")), Qfalse);
  VALUE native_filenames_enabled = rb_hash_lookup2(options, ID2SYM(rb_intern("native_filenames_enabled")), Qfalse);

  ENFORCE_TYPE(metric_values_hash, T_HASH);
  ENFORCE_TYPE(labels_array, T_ARRAY);
  ENFORCE_TYPE(numeric_labels_array, T_ARRAY);
  ENFORCE_TYPE(max_frames, T_FIXNUM);
  ENFORCE_BOOLEAN(in_gc);
  ENFORCE_BOOLEAN(is_gvl_waiting_state);
  ENFORCE_BOOLEAN(native_filenames_enabled);

  VALUE zero = INT2NUM(0);
  VALUE heap_sample = rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("heap_sample"), Qfalse);
  ENFORCE_BOOLEAN(heap_sample);
  sample_values values = {
    .cpu_time_ns   = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("cpu-time"),      zero)),
    .cpu_or_wall_samples = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("cpu-samples"), zero)),
    .wall_time_ns  = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("wall-time"),     zero)),
    .alloc_samples = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("alloc-samples"), zero)),
    .alloc_samples_unscaled = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("alloc-samples-unscaled"), zero)),
    .timeline_wall_time_ns = NUM2UINT(rb_hash_lookup2(metric_values_hash, rb_str_new_cstr("timeline"), zero)),
    .heap_sample = heap_sample == Qtrue,
  };

  long labels_count = RARRAY_LEN(labels_array) + RARRAY_LEN(numeric_labels_array);
  ddog_prof_Label labels[labels_count];
  ddog_prof_Label *state_label = NULL;

  for (int i = 0; i < RARRAY_LEN(labels_array); i++) {
    VALUE key_str_pair = rb_ary_entry(labels_array, i);

    labels[i] = (ddog_prof_Label) {
      .key = char_slice_from_ruby_string(rb_ary_entry(key_str_pair, 0)),
      .str = char_slice_from_ruby_string(rb_ary_entry(key_str_pair, 1))
    };

    if (rb_str_equal(rb_ary_entry(key_str_pair, 0), rb_str_new_cstr("state"))) {
      state_label = &labels[i];
    }
  }
  for (int i = 0; i < RARRAY_LEN(numeric_labels_array); i++) {
    VALUE key_str_pair = rb_ary_entry(numeric_labels_array, i);

    labels[i + RARRAY_LEN(labels_array)] = (ddog_prof_Label) {
      .key = char_slice_from_ruby_string(rb_ary_entry(key_str_pair, 0)),
      .num = NUM2ULL(rb_ary_entry(key_str_pair, 1))
    };
  }

  int max_frames_requested = sampling_buffer_check_max_frames(NUM2INT(max_frames));

  ddog_prof_Location *locations = ruby_xcalloc(max_frames_requested, sizeof(ddog_prof_Location));
  sampling_buffer buffer;
  sampling_buffer_initialize(&buffer, max_frames_requested, locations);

  ddog_prof_Slice_Label slice_labels = {.ptr = labels, .len = labels_count};

  native_sample_args args_struct = {
    .in_gc = in_gc,
    .recorder_instance = recorder_instance,
    .values = values,
    .labels = (sample_labels) {.labels = slice_labels, .state_label = state_label, .is_gvl_waiting_state = is_gvl_waiting_state == Qtrue},
    .thread = thread,
    .locations = locations,
    .buffer = &buffer,
    .native_filenames_enabled = native_filenames_enabled == Qtrue,
    .native_filenames_cache = st_init_numtable(),
  };

  return rb_ensure(native_sample_do, (VALUE) &args_struct, native_sample_ensure, (VALUE) &args_struct);
}

static VALUE native_sample_do(VALUE args) {
  native_sample_args *args_struct = (native_sample_args *) args;

  if (args_struct->in_gc == Qtrue) {
    record_placeholder_stack(
      args_struct->recorder_instance,
      args_struct->values,
      args_struct->labels,
      DDOG_CHARSLICE_C("Garbage Collection")
    );
  } else {
    sample_thread(
      args_struct->thread,
      args_struct->buffer,
      args_struct->recorder_instance,
      args_struct->values,
      args_struct->labels,
      args_struct->native_filenames_enabled,
      args_struct->native_filenames_cache
    );
  }

  return Qtrue;
}

static VALUE native_sample_ensure(VALUE args) {
  native_sample_args *args_struct = (native_sample_args *) args;

  ruby_xfree(args_struct->locations);
  sampling_buffer_free(args_struct->buffer);
  st_free_table(args_struct->native_filenames_cache);

  return Qtrue;
}

#define CHARSLICE_EQUALS(must_be_a_literal, charslice) (strlen("" must_be_a_literal) == charslice.len && strncmp(must_be_a_literal, charslice.ptr, charslice.len) == 0)

// Idea: Should we release the global vm lock (GVL) after we get the data from `rb_profile_frames`? That way other Ruby threads
// could continue making progress while the sample was ingested into the profile.
//
// Other things to take into consideration if we go in that direction:
// * Is it safe to call `rb_profile_frame_...` methods on things from the `stack_buffer` without the GVL acquired?
// * We need to make `VALUE` references in the `stack_buffer` visible to the Ruby GC
// * Should we move this into a different thread entirely?
// * If we don't move it into a different thread, does releasing the GVL on a Ruby thread mean that we're introducing
//   a new thread switch point where there previously was none?
void sample_thread(
  VALUE thread,
  sampling_buffer* buffer,
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  bool native_filenames_enabled,
  st_table *native_filenames_cache
) {
  // If we already prepared a sample, we use it below; if not, we prepare it now.
  if (!buffer->pending_sample) prepare_sample_thread(thread, buffer);

  buffer->pending_sample = false;
  int captured_frames = buffer->pending_sample_result;

  if (captured_frames == PLACEHOLDER_STACK_IN_NATIVE_CODE) {
    record_placeholder_stack_in_native_code(recorder_instance, values, labels);
    return;
  }

  // if (captured_frames > 0) {
  //   int cache_hits = 0;
  //   for (int i = 0; i < captured_frames; i++) {
  //     if (buffer->stack_buffer[i].same_frame) cache_hits++;
  //   }
  //   fprintf(stderr, "Sampling cache hits: %f\n", ((double) cache_hits / captured_frames) * 100);
  // }

  // Ruby does not give us path and line number for methods implemented using native code.
  // The convention in Kernel#caller_locations is to instead use the path and line number of the first Ruby frame
  // on the stack that is below (e.g. directly or indirectly has called) the native method.
  // Thus, we keep that frame here to able to replicate that behavior.
  // (This is why we also iterate the sampling buffers backwards from what libdatadog uses below -- so that it's easier
  // to keep the last_ruby_frame_filename)
  ddog_CharSlice last_ruby_frame_filename = DDOG_CHARSLICE_C("");
  int last_ruby_line = 0;

  ddog_prof_Label *state_label = labels.state_label;
  bool cpu_or_wall_sample = values.cpu_or_wall_samples > 0;
  bool has_cpu_time = cpu_or_wall_sample && values.cpu_time_ns > 0;
  // Note: In theory, a cpu_or_wall_sample should always have some wall-time. In practice, the first sample for a thread
  // will be zero, as well as if the system clock does something weird. Thus, at some point we had values.wall_time_ns > 0
  // here, but >= 0 makes this easier to understand/debug.
  bool only_wall_time = cpu_or_wall_sample && values.cpu_time_ns == 0 && values.wall_time_ns >= 0;

  if (cpu_or_wall_sample && state_label == NULL) rb_raise(rb_eRuntimeError, "BUG: Unexpected missing state_label");

  if (has_cpu_time) {
    state_label->str = DDOG_CHARSLICE_C("had cpu");
    if (labels.is_gvl_waiting_state) rb_raise(rb_eRuntimeError, "BUG: Unexpected combination of cpu-time with is_gvl_waiting");
  }

  int top_of_stack_position = captured_frames - 1;

  for (int i = 0; i <= top_of_stack_position; i++) {
    ddog_CharSlice name_slice, filename_slice;
    int line;
    bool top_of_the_stack = i == top_of_stack_position;

    if (buffer->stack_buffer[i].is_ruby_frame) {
      VALUE name = rb_iseq_base_label(buffer->stack_buffer[i].as.ruby_frame.iseq);
      VALUE filename = rb_iseq_path(buffer->stack_buffer[i].as.ruby_frame.iseq);

      name_slice = NIL_P(name) ? DDOG_CHARSLICE_C("") : char_slice_from_ruby_string(name);
      filename_slice = NIL_P(filename) ? DDOG_CHARSLICE_C("") : char_slice_from_ruby_string(filename);
      line = buffer->stack_buffer[i].as.ruby_frame.line;

      last_ruby_frame_filename = filename_slice;
      last_ruby_line = line;
    } else {
      VALUE name = rb_id2str(buffer->stack_buffer[i].as.native_frame.method_id);

      name_slice = NIL_P(name) ? DDOG_CHARSLICE_C("") : char_slice_from_ruby_string(name);

      set_file_info_for_cfunc(
        &filename_slice,
        &line,
        last_ruby_frame_filename,
        last_ruby_line,
        buffer->stack_buffer[i].as.native_frame.function,
        top_of_the_stack,
        native_filenames_enabled,
        native_filenames_cache
      );
    }

    maybe_trim_template_random_ids(&name_slice, &filename_slice);

    // When there's only wall-time in a sample, this means that the thread was not active in the sampled period.
    if (top_of_the_stack && only_wall_time) {
      // Did the caller already provide the state?
      if (labels.is_gvl_waiting_state) {
        state_label->str = DDOG_CHARSLICE_C("waiting for gvl");

      // Otherwise, we try to categorize what the thread was doing based on what we observe at the top of the stack. This is a very rough
      // approximation, and in the future we hope to replace this with a more accurate approach (such as using the
      // GVL instrumentation API.)
      } else if (!buffer->stack_buffer[i].is_ruby_frame) {
        // We know that known versions of Ruby implement these using native code; thus if we find a method with the
        // same name that is not native code, we ignore it, as it's probably a user method that coincidentally
        // has the same name. Thus, even though "matching just by method name" is kinda weak,
        // "matching by method name" + is native code seems actually to be good enough for a lot of cases.

        if (CHARSLICE_EQUALS("sleep", name_slice)) { // Expected to be Kernel.sleep
          state_label->str  = DDOG_CHARSLICE_C("sleeping");
        } else if (CHARSLICE_EQUALS("select", name_slice)) { // Expected to be Kernel.select
          state_label->str  = DDOG_CHARSLICE_C("waiting");
        } else if (
            CHARSLICE_EQUALS("synchronize", name_slice) || // Expected to be Monitor/Mutex#synchronize
            CHARSLICE_EQUALS("lock", name_slice) ||        // Expected to be Mutex#lock
            CHARSLICE_EQUALS("join", name_slice)           // Expected to be Thread#join
        ) {
          state_label->str  = DDOG_CHARSLICE_C("blocked");
        } else if (CHARSLICE_EQUALS("wait_readable", name_slice)) { // Expected to be IO#wait_readable
          state_label->str  = DDOG_CHARSLICE_C("network");
        }
        #ifdef NO_PRIMITIVE_POP // Ruby < 3.2
          else if (CHARSLICE_EQUALS("pop", name_slice)) { // Expected to be Queue/SizedQueue#pop
            state_label->str  = DDOG_CHARSLICE_C("waiting");
          }
        #endif
      } else {
        #ifndef NO_PRIMITIVE_POP // Ruby >= 3.2
          // Unlike the above, Ruby actually treats this one specially and gives it a nice file name we can match on!
          if (CHARSLICE_EQUALS("pop", name_slice) && CHARSLICE_EQUALS("<internal:thread_sync>", filename_slice)) { // Expected to be Queue/SizedQueue#pop
            state_label->str  = DDOG_CHARSLICE_C("waiting");
          }
        #endif
      }
    }

    int libdatadog_stores_stacks_flipped_from_rb_profile_frames_index = top_of_stack_position - i;

    buffer->locations[libdatadog_stores_stacks_flipped_from_rb_profile_frames_index] = (ddog_prof_Location) {
      .mapping = {.filename = DDOG_CHARSLICE_C(""), .build_id = DDOG_CHARSLICE_C(""), .build_id_id = {}},
      .function = (ddog_prof_Function) {.name = name_slice, .filename = filename_slice},
      .line = line,
    };
  }

  // If we filled up the buffer, some frames may have been omitted. In that case, we'll add a placeholder frame
  // with that info.
  if (captured_frames == (long) buffer->max_frames) {
    add_truncated_frames_placeholder(buffer);
  }

  record_sample(
    recorder_instance,
    (ddog_prof_Slice_Location) {.ptr = buffer->locations, .len = captured_frames},
    values,
    labels
  );
}

#if (defined(HAVE_DLADDR1) && HAVE_DLADDR1) || (defined(HAVE_DLADDR) && HAVE_DLADDR)
  static void set_file_info_for_cfunc(
    ddog_CharSlice *filename_slice,
    int *line,
    ddog_CharSlice last_ruby_frame_filename,
    int last_ruby_line,
    void *function,
    bool top_of_the_stack,
    bool native_filenames_enabled,
    st_table *native_filenames_cache
  ) {
    if (native_filenames_enabled) {
      const char *native_filename = get_or_compute_native_filename(function, native_filenames_cache);
      if (native_filename && native_filename[0] != '\0' &&
        // Using the ruby_native_filename at the top of the stack has a weird effect on the "top methods" table because
        // e.g. we don't have classnames for methods. This is especially visible in the allocations profile, e.g.
        // what a surprise, you're telling me "libruby.so:new" is the top method always?
        //
        // Until we have a better way of dealing with that, we don't do this replacement for the top frame.
        //
        // Also, dladdr is expected to always return the same pointer to the ruby_native_filename, so that's why we're
        // comparing only pointer values and not the string contents.
        (native_filename != ruby_native_filename || !top_of_the_stack)
      ) {
        *filename_slice = (ddog_CharSlice) {.ptr = native_filename, .len = strlen(native_filename)};
        // Explicitly set the line to 0 as it has no meaning on a native library (e.g. an .so is built of many source files)
        // and anyway often that debug info is not available.
        *line = 0;
        return;
      }
    }

    *filename_slice = last_ruby_frame_filename;
    *line = last_ruby_line;
  }

  // `native_filenames_cache` is used to cache native filename lookup results (Map[void *function_pointer, char *filename])
  //
  // Caching this information is safe because there's no API in Ruby to "unrequire" a native extension. Thus, if we see a
  // frame on the **Ruby** stack with a given `function`, then that `function` was registered with the Ruby VM and
  // belongs to a Ruby extension, so a lot of other bad things would happen if it was dlclosed.
  static const char *get_or_compute_native_filename(void *function, st_table *native_filenames_cache) {
    const char *cached_filename = NULL;
    st_lookup(native_filenames_cache, (st_data_t) function, (st_data_t *) &cached_filename);
    if (cached_filename != NULL) return cached_filename;

    Dl_info info;
    const char *native_filename = NULL;
    #if defined(HAVE_DLADDR1) && HAVE_DLADDR1
      struct link_map *extra_info = NULL;
      if (dladdr1(function, &info, (void **) &extra_info, RTLD_DL_LINKMAP) != 0 && extra_info != NULL) {
        native_filename = extra_info->l_name != NULL ? extra_info->l_name : info.dli_fname;
      }
    #elif defined(HAVE_DLADDR) && HAVE_DLADDR
      if (dladdr(function, &info) != 0) {
        native_filename = info.dli_fname;
      }
    #endif

    // We explicitly use an empty string here so as to cache lookups that somehow "failed". Otherwise we would keep trying them every time.
    if (native_filename == NULL) native_filename = "";

    // An st_table is what Ruby uses for its own hashtables. This allows us to get an easy estimate of the size of the cache:
    // `ObjectSpace.memsize_of((0..100000).map { |it| [it, nil] }.to_h)` => 4194400 bytes as of Ruby 3.2 so that seems reasonable?
    // Note: `st_table_size()` is available from Ruby 3.2+ but not before
    if (native_filenames_cache->num_entries >= 100000) {
      st_clear(native_filenames_cache);
    }

    st_insert(native_filenames_cache, (st_data_t) function, (st_data_t) native_filename);
    return native_filename;
  }
#else
  static void set_file_info_for_cfunc(
    ddog_CharSlice *filename_slice,
    int *line,
    ddog_CharSlice last_ruby_frame_filename,
    int last_ruby_line,
    DDTRACE_UNUSED void *function,
    DDTRACE_UNUSED bool top_of_the_stack,
    DDTRACE_UNUSED bool native_filenames_enabled,
    DDTRACE_UNUSED st_table *native_filenames_cache
  ) {
    *filename_slice = last_ruby_frame_filename;
    *line = last_ruby_line;
  }
#endif

// Rails's ActionView likes to dynamically generate method names with suffixed hashes/ids, resulting in methods with
// names such as:
// * "_app_views_layouts_explore_html_haml__2304485752546535910_211320" (__number_number suffix -- two underscores)
// * "_app_views_articles_index_html_erb___2022809201779434309_12900" (___number_number suffix -- three underscores)
// This makes these stacks not aggregate well, as well as being not-very-useful data.
// (Reference:
//  https://github.com/rails/rails/blob/4fa56814f18fd3da49c83931fa773caa727d8096/actionview/lib/action_view/template.rb#L389
//  The two vs three underscores happen when @identifier.hash is negative in that method: the "-" gets replaced with
//  the extra "_".)
//
// This method trims these suffixes, so that we keep less data + the names correctly aggregate together.
static void maybe_trim_template_random_ids(ddog_CharSlice *name_slice, ddog_CharSlice *filename_slice) {
  // Check filename doesn't end with ".rb"; templates are usually along the lines of .html.erb/.html.haml/...
  if (filename_slice->len < 3 || memcmp(filename_slice->ptr + filename_slice->len - 3, ".rb", 3) == 0) return;

  if (name_slice->len > 1024) return;
  if (name_slice->len == 0) return;

  int pos = ((int) name_slice->len) - 1;

  // Let's match on something__number_number:
  // Find start of id suffix from the end...
  if (name_slice->ptr[pos] < '0' || name_slice->ptr[pos] > '9') return;

  // ...now match a bunch of numbers and interspersed underscores
  for (int underscores = 0; pos >= 0 && underscores < 2; pos--) {
    if (name_slice->ptr[pos] == '_') underscores++;
    else if (name_slice->ptr[pos] < '0' || name_slice->ptr[pos] > '9') return;
  }

  // Make sure there's something left before the underscores (hence the <= instead of <) + match the last underscore
  if (pos <= 0 || name_slice->ptr[pos] != '_') return;

  // Does it have the optional third underscore? If so, remove it as well
  if (pos > 1 && name_slice->ptr[pos-1] == '_') pos--;

  // If we got here, we matched on our pattern. Let's slice the length of the string to exclude it.
  name_slice->len = pos;
}

static void add_truncated_frames_placeholder(sampling_buffer* buffer) {
  // Important note: The strings below are static so we don't need to worry about their lifetime. If we ever want to change
  // this to non-static strings, don't forget to check that lifetimes are properly respected.
  buffer->locations[0] = (ddog_prof_Location) {
    .mapping = {.filename = DDOG_CHARSLICE_C(""), .build_id = DDOG_CHARSLICE_C(""), .build_id_id = {}},
    .function = {.name = DDOG_CHARSLICE_C("Truncated Frames"), .filename = DDOG_CHARSLICE_C(""), .filename_id = {}},
    .line = 0,
  };
}

// Our custom rb_profile_frames returning PLACEHOLDER_STACK_IN_NATIVE_CODE is equivalent to when the
// Ruby `Thread#backtrace` API returns an empty array: we know that a thread is alive but we don't know what it's doing:
//
// 1. It can be starting up
//    ```
//    > Thread.new { sleep }.backtrace
//    => [] # <-- note the thread hasn't actually started running sleep yet, we got there first
//    ```
// 2. It can be running native code
//    ```
//    > t = Process.detach(fork { sleep })
//    => #<Process::Waiter:0x00007ffe7285f7a0 run>
//    > t.backtrace
//    => [] # <-- this can happen even minutes later, e.g. it's not a race as in 1.
//    ```
//    This effect has been observed in threads created by the Iodine web server and the ffi gem,
//    see for instance https://github.com/ffi/ffi/pull/883 and https://github.com/DataDog/dd-trace-rb/pull/1719 .
//
// To give customers visibility into these threads, rather than reporting an empty stack, we replace the empty stack
// with one containing a placeholder frame, so that these threads are properly represented in the UX.

static void record_placeholder_stack_in_native_code(
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels
) {
  record_placeholder_stack(
    recorder_instance,
    values,
    labels,
    DDOG_CHARSLICE_C("In native code")
  );
}

void record_placeholder_stack(
  VALUE recorder_instance,
  sample_values values,
  sample_labels labels,
  ddog_CharSlice placeholder_stack
) {
  ddog_prof_Location placeholder_location = {
    .mapping = {.filename = DDOG_CHARSLICE_C(""), .build_id = DDOG_CHARSLICE_C(""), .build_id_id = {}},
    .function = {.name = DDOG_CHARSLICE_C(""), .filename = placeholder_stack},
    .line = 0,
  };

  record_sample(
    recorder_instance,
    (ddog_prof_Slice_Location) {.ptr = &placeholder_location, .len = 1},
    values,
    labels
  );
}

bool prepare_sample_thread(VALUE thread, sampling_buffer *buffer) {
  // Since this can get called from inside a signal handler, we don't want to touch the buffer if
  // the thread was actually in the middle of marking it.
  if (buffer->is_marking) return false;

  buffer->pending_sample = true;
  buffer->pending_sample_result = ddtrace_rb_profile_frames(thread, 0, buffer->max_frames, buffer->stack_buffer);
  return true;
}

uint16_t sampling_buffer_check_max_frames(int max_frames) {
  if (max_frames < 5) rb_raise(rb_eArgError, "Invalid max_frames: value must be >= 5");
  if (max_frames > MAX_FRAMES_LIMIT) rb_raise(rb_eArgError, "Invalid max_frames: value must be <= " MAX_FRAMES_LIMIT_AS_STRING);
  return max_frames;
}

void sampling_buffer_initialize(sampling_buffer *buffer, uint16_t max_frames, ddog_prof_Location *locations) {
  sampling_buffer_check_max_frames(max_frames);

  buffer->max_frames = max_frames;
  buffer->locations = locations;
  buffer->stack_buffer = ruby_xcalloc(max_frames, sizeof(frame_info));
  buffer->pending_sample = false;
  buffer->is_marking = false;
  buffer->pending_sample_result = 0;
}

void sampling_buffer_free(sampling_buffer *buffer) {
  if (buffer->max_frames == 0 || buffer->locations == NULL || buffer->stack_buffer == NULL) {
    rb_raise(rb_eArgError, "sampling_buffer_free called with invalid buffer");
  }

  ruby_xfree(buffer->stack_buffer);
  // Note: buffer->locations are owned by whoever called sampling_buffer_initialize, not by the buffer itself

  buffer->max_frames = 0;
  buffer->locations = NULL;
  buffer->stack_buffer = NULL;
  buffer->pending_sample = false;
  buffer->is_marking = false;
  buffer->pending_sample_result = 0;
}

void sampling_buffer_mark(sampling_buffer *buffer) {
  if (!sampling_buffer_needs_marking(buffer)) {
    rb_bug("sampling_buffer_mark called with no pending sample. `sampling_buffer_needs_marking` should be used before calling mark.");
  }

  buffer->is_marking = true;
  // Tell the compiler it's not allowed to reorder the `is_marking` flag with the iteration below.
  //
  // Specifically, in the middle of `sampling_buffer_mark` a signal handler may execute and call
  // `prepare_sample_thread` to add a new sample to the buffer. This flag is here to prevent that BUT we need to
  // make sure the signal handler actually sees the flag being set.
  //
  // See https://github.com/ruby/ruby/pull/11036 for a similar change made to the Ruby VM with more context.
  atomic_signal_fence(memory_order_seq_cst);

  for (int i = 0; i < buffer->pending_sample_result; i++) {
    if (buffer->stack_buffer[i].is_ruby_frame) {
      rb_gc_mark(buffer->stack_buffer[i].as.ruby_frame.iseq);
    }
  }

  // Make sure iteration completes before `is_marking` is unset...
  atomic_signal_fence(memory_order_seq_cst);
  buffer->is_marking = false;
}
