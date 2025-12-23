#include <ruby.h>
#include <ruby/thread.h>
#include <pthread.h>
#include <errno.h>
#include "helpers.h"
#include "stack_recorder.h"
#include "libdatadog_helpers.h"
#include "ruby_helpers.h"
#include "time_helpers.h"
#include "heap_recorder.h"
#include "encoded_profile.h"

// Used to wrap a ddog_prof_Profile in a Ruby object and expose Ruby-level serialization APIs
// This file implements the native bits of the Datadog::Profiling::StackRecorder class

// ---
// ## Synchronization mechanism for safe parallel access design notes
//
// The state of the StackRecorder is managed using a set of locks to avoid concurrency issues.
//
// This is needed because the state is expected to be accessed, in parallel, by two different threads.
//
// 1. The thread that is taking a stack sample and that called `record_sample`, let's call it the **sampler thread**.
// In the current implementation of the profiler, there can only exist one **sampler thread** at a time; if this
// constraint changes, we should revise the design of the StackRecorder.
//
// 2. The thread that serializes and reports profiles, let's call it the **serializer thread**. We enforce that there
// cannot be more than one thread attempting to serialize profiles at a time.
//
// If both the sampler and serializer threads are trying to access the same `ddog_prof_Profile` in parallel, we will
// have a concurrency issue. Thus, the StackRecorder has an added mechanism to avoid this.
//
// As an additional constraint, the **sampler thread** has absolute priority and must never block while
// recording a sample.
//
// ### The solution: Keep two profiles at the same time
//
// To solve for the constraints above, the StackRecorder keeps two `ddog_prof_Profile` profile instances inside itself.
// They are called the `slot_one_profile` and `slot_two_profile`.
//
// Each profile is paired with its own mutex. `slot_one_profile` is protected by `slot_one_mutex` and `slot_two_profile`
// is protected by `slot_two_mutex`.
//
// We additionally introduce the concept of **active** and **inactive** profile slots. At any point, the sampler thread
// can probe the mutexes to discover which of the profiles corresponds to the active slot, and then records samples in it.
// When the serializer thread is ready to serialize data, it flips the active and inactive slots; it reports the data
// on the previously-active profile slot, and the sampler thread can continue to record in the previously-inactive
// profile slot.
//
// Thus, the sampler and serializer threads never cross paths, avoiding concurrency issues. The sampler thread writes to
// the active profile slot, and the serializer thread reads from the inactive profile slot.
//
// ### Locking protocol, high-level
//
// The active profile slot is the slot for which its corresponding mutex **is unlocked**. That is, if the sampler
// thread can grab a lock for a profile slot, then that slot is the active one. (Here you see where the constraint
// stated above that only one sampler thread can exist kicks in -- this part would need to be more complex if multiple
// sampler threads were in play.)
//
// As a counterpart, the inactive profile slot mutex is **kept locked** until such time the serializer
// thread is ready to work and decides to flip the slots.
//
// When a new StackRecorder is initialized, the `slot_one_mutex` is unlocked, and the `slot_two_mutex` is kept locked,
// that is, a new instance always starts with slot one active.
//
// Additionally, an `active_slot` field is kept, containing a `1` or `2`; this is only kept for the serializer thread
// to use as a simplification, as well as for testing and debugging; the **sampler thread must never use the `active_slot`
// field**.
//
// ### Locking protocol, from the sampler thread side
//
// When the sampler thread wants to record a sample, it goes through the following steps to discover which is the
// active profile slot:
//
// 1. `pthread_mutex_trylock(slot_one_mutex)`. If it succeeds to grab the lock, this means the active profile slot is
// slot one. If it fails, we move to the next step.
//
// 2. `pthread_mutex_trylock(slot_two_mutex)`. If it succeeds to grab the lock, this means the active profile slot is
// slot two. If it fails, we move to the next step.
//
// 3. What does it mean for the sampler thread to have observed both `slot_one_mutex` as well as `slot_two_mutex` as
// being locked? There are two options:
//   a. The sampler thread got really unlucky. When it tried to grab the `slot_one_mutex`, the active profile slot was
//     the second one BUT then the serializer thread flipped the slots, and by the time the sampler thread probed the
//     `slot_two_mutex`, that one was taken. Since the serializer thread is expected only to work once a minute,
//     we retry steps 1. and 2. and should be able to find an active slot.
//   b. Something is incorrect in the StackRecorder state. In this situation, the sampler thread should give up on
//     sampling and enter an error state.
//
// Note that in the steps above, and because the sampler thread uses `trylock` to probe the mutexes, that the
// sampler thread never blocks. It either is able to find an active profile slot in a bounded amount of steps or it
// enters an error state.
//
// This guarantees that sampler performance is never constrained by serializer performance.
//
// ### Locking protocol, from the serializer thread side
//
// When the serializer thread wants to serialize a profile, it first flips the active and inactive profile slots.
//
// The flipping action is described below. Consider previously-inactive and previously-active as the state of the slots
// before the flipping happens.
//
// The flipping steps are the following:
//
// 1. Release the mutex for the previously-inactive profile slot. That slot, as seen by the sampler thread, is now
// active.
//
// 2. Grab the mutex for the previously-active profile slot. Note that this can lead to the serializer thread blocking,
// if the sampler thread is holding this mutex. After the mutex is grabbed, the previously-active slot becomes inactive,
// as seen by the sampler thread.
//
// 3. Update `active_slot`.
//
// After flipping the profile slots, the serializer thread is now free to serialize the inactive profile slot. The slot
// is kept inactive until the next time the serializer thread wants to serialize data.
//
// Note there can be a brief period between steps 1 and 2 where the serializer thread holds no lock, which means that
// the sampler thread can pick either slot. This is OK: if the sampler thread picks the previously-inactive slot, the
// samples will be reported on the next serialization; if the sampler thread picks the previously-active slot, the
// samples are still included in the current serialization. Either option is correct.
//
// ### Additional notes
//
// Q: Can the sampler thread and the serializer thread ever be the same thread? (E.g. sampling in interrupt handler)
// A: No; the current profiler design requires that sampling happens only on the thread that is holding the Global VM
// Lock (GVL). The serializer thread flipping occurs after the serializer thread releases the GVL, and thus the
// serializer thread will not be able to host the sampling process.
//
// ---

static VALUE ok_symbol = Qnil; // :ok in Ruby
static VALUE error_symbol = Qnil; // :error in Ruby

// Note: Please DO NOT use `VALUE_STRING` anywhere else, instead use `DDOG_CHARSLICE_C`.
// `VALUE_STRING` is only needed because older versions of gcc (4.9.2, used in our Ruby 2.2 CI test images)
// tripped when compiling `enabled_value_types` using `-std=gnu99` due to the extra cast that is included in
// `DDOG_CHARSLICE_C` with the following error:
//
// ```
// compiling ../../../../ext/ddtrace_profiling_native_extension/stack_recorder.c
// ../../../../ext/ddtrace_profiling_native_extension/stack_recorder.c:23:1: error: initializer element is not constant
// static const ddog_prof_ValueType enabled_value_types[] = {CPU_TIME_VALUE, CPU_SAMPLES_VALUE, WALL_TIME_VALUE};
// ^
// ```
#define VALUE_STRING(string) {.ptr = "" string, .len = sizeof(string) - 1}

#define CPU_TIME_VALUE          {.type_ = VALUE_STRING("cpu-time"),          .unit = VALUE_STRING("nanoseconds")}
#define CPU_TIME_VALUE_ID 0
#define CPU_SAMPLES_VALUE       {.type_ = VALUE_STRING("cpu-samples"),       .unit = VALUE_STRING("count")}
#define CPU_SAMPLES_VALUE_ID 1
#define WALL_TIME_VALUE         {.type_ = VALUE_STRING("wall-time"),         .unit = VALUE_STRING("nanoseconds")}
#define WALL_TIME_VALUE_ID 2
#define ALLOC_SAMPLES_VALUE     {.type_ = VALUE_STRING("alloc-samples"),     .unit = VALUE_STRING("count")}
#define ALLOC_SAMPLES_VALUE_ID 3
#define ALLOC_SAMPLES_UNSCALED_VALUE {.type_ = VALUE_STRING("alloc-samples-unscaled"), .unit = VALUE_STRING("count")}
#define ALLOC_SAMPLES_UNSCALED_VALUE_ID 4
#define HEAP_SAMPLES_VALUE      {.type_ = VALUE_STRING("heap-live-samples"), .unit = VALUE_STRING("count")}
#define HEAP_SAMPLES_VALUE_ID 5
#define HEAP_SIZE_VALUE         {.type_ = VALUE_STRING("heap-live-size"),    .unit = VALUE_STRING("bytes")}
#define HEAP_SIZE_VALUE_ID 6
#define TIMELINE_VALUE          {.type_ = VALUE_STRING("timeline"),          .unit = VALUE_STRING("nanoseconds")}
#define TIMELINE_VALUE_ID 7

static const ddog_prof_ValueType all_value_types[] =
  {CPU_TIME_VALUE, CPU_SAMPLES_VALUE, WALL_TIME_VALUE, ALLOC_SAMPLES_VALUE, ALLOC_SAMPLES_UNSCALED_VALUE, HEAP_SAMPLES_VALUE, HEAP_SIZE_VALUE, TIMELINE_VALUE};

// This array MUST be kept in sync with all_value_types above and is intended to act as a "hashmap" between VALUE_ID and the position it
// occupies on the all_value_types array.
// E.g. all_value_types_positions[CPU_TIME_VALUE_ID] => 0, means that CPU_TIME_VALUE was declared at position 0 of all_value_types.
static const uint8_t all_value_types_positions[] =
  {CPU_TIME_VALUE_ID, CPU_SAMPLES_VALUE_ID, WALL_TIME_VALUE_ID, ALLOC_SAMPLES_VALUE_ID, ALLOC_SAMPLES_UNSCALED_VALUE_ID, HEAP_SAMPLES_VALUE_ID, HEAP_SIZE_VALUE_ID, TIMELINE_VALUE_ID};

#define ALL_VALUE_TYPES_COUNT (sizeof(all_value_types) / sizeof(ddog_prof_ValueType))

// Struct for storing stats related to a profile in a particular slot.
// These stats will share the same lifetime as the data in that profile slot.
typedef struct {
  // How many individual samples were recorded into this slot (un-weighted)
  uint64_t recorded_samples;
} stats_slot;

typedef struct {
  ddog_prof_Profile profile;
  stats_slot stats;
  ddog_Timespec start_timestamp;
} profile_slot;

// Contains native state for each instance
typedef struct {
  // Heap recorder instance
  heap_recorder *heap_recorder;
  bool heap_clean_after_gc_enabled;

  pthread_mutex_t mutex_slot_one;
  profile_slot profile_slot_one;
  pthread_mutex_t mutex_slot_two;
  profile_slot profile_slot_two;

  ddog_prof_ManagedStringStorage string_storage;
  ddog_prof_ManagedStringId label_key_allocation_class;
  ddog_prof_ManagedStringId label_key_gc_gen_age;

  short active_slot; // MUST NEVER BE ACCESSED FROM record_sample; this is NOT for the sampler thread to use.

  uint8_t position_for[ALL_VALUE_TYPES_COUNT];
  uint8_t enabled_values_count;

  // Struct for storing stats related to behaviour of a stack recorder instance during its entire lifetime.
  struct lifetime_stats {
    // How many profiles have we serialized successfully so far
    uint64_t serialization_successes;
    // How many profiles have we serialized unsuccessfully so far
    uint64_t serialization_failures;
    // Stats on profile serialization time
    long serialization_time_ns_min;
    long serialization_time_ns_max;
    uint64_t serialization_time_ns_total;
  } stats_lifetime;
} stack_recorder_state;

// Used to group mutex and the corresponding profile slot for easy unlocking after work is done.
typedef struct {
  pthread_mutex_t *mutex;
  profile_slot *data;
} locked_profile_slot;

typedef struct {
  // Set by caller
  stack_recorder_state *state;
  ddog_Timespec finish_timestamp;

  // Set by callee
  profile_slot *slot;
  ddog_prof_Profile_SerializeResult result;
  long heap_profile_build_time_ns;
  long serialize_no_gvl_time_ns;
  ddog_prof_MaybeError advance_gen_result;

  // Set by both
  bool serialize_ran;
} call_serialize_without_gvl_arguments;

static VALUE _native_new(VALUE klass);
static void initialize_slot_concurrency_control(stack_recorder_state *state);
static void initialize_profiles(stack_recorder_state *state, ddog_prof_Slice_ValueType sample_types);
static void stack_recorder_typed_data_free(void *data);
static VALUE _native_initialize(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self);
static VALUE _native_serialize(VALUE self, VALUE recorder_instance);
static VALUE ruby_time_from(ddog_Timespec ddprof_time);
static void *call_serialize_without_gvl(void *call_args);
static locked_profile_slot sampler_lock_active_profile(stack_recorder_state *state);
static void sampler_unlock_active_profile(locked_profile_slot active_slot);
static profile_slot* serializer_flip_active_and_inactive_slots(stack_recorder_state *state);
static VALUE _native_active_slot(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE _native_is_slot_one_mutex_locked(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE _native_is_slot_two_mutex_locked(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE test_slot_mutex_state(VALUE recorder_instance, int slot);
static ddog_Timespec system_epoch_now_timespec(void);
static VALUE _native_reset_after_fork(DDTRACE_UNUSED VALUE self, VALUE recorder_instance);
static void serializer_set_start_timestamp_for_next_profile(stack_recorder_state *state, ddog_Timespec start_time);
static VALUE _native_record_endpoint(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE local_root_span_id, VALUE endpoint);
static void reset_profile_slot(profile_slot *slot, ddog_Timespec start_timestamp);
static VALUE _native_track_object(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE new_obj, VALUE weight, VALUE alloc_class);
static VALUE _native_start_fake_slow_heap_serialization(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE _native_end_fake_slow_heap_serialization(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE _native_debug_heap_recorder(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE _native_stats(DDTRACE_UNUSED VALUE self, VALUE instance);
static VALUE build_profile_stats(profile_slot *slot, long serialization_time_ns, long heap_iteration_prep_time_ns, long heap_profile_build_time_ns);
static VALUE _native_is_object_recorded(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE object_id);
static VALUE _native_heap_recorder_reset_last_update(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE _native_recorder_after_gc_step(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance);
static VALUE _native_benchmark_intern(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE string, VALUE times, VALUE use_all);
static VALUE _native_test_managed_string_storage_produces_valid_profiles(DDTRACE_UNUSED VALUE _self);

void stack_recorder_init(VALUE profiling_module) {
  VALUE stack_recorder_class = rb_define_class_under(profiling_module, "StackRecorder", rb_cObject);
  // Hosts methods used for testing the native code using RSpec
  VALUE testing_module = rb_define_module_under(stack_recorder_class, "Testing");

  // Instances of the StackRecorder class are "TypedData" objects.
  // "TypedData" objects are special objects in the Ruby VM that can wrap C structs.
  // In this case, it wraps the stack_recorder_state.
  //
  // Because Ruby doesn't know how to initialize native-level structs, we MUST override the allocation function for objects
  // of this class so that we can manage this part. Not overriding or disabling the allocation function is a common
  // gotcha for "TypedData" objects that can very easily lead to VM crashes, see for instance
  // https://bugs.ruby-lang.org/issues/18007 for a discussion around this.
  rb_define_alloc_func(stack_recorder_class, _native_new);

  rb_define_singleton_method(stack_recorder_class, "_native_initialize", _native_initialize, -1);
  rb_define_singleton_method(stack_recorder_class, "_native_serialize",  _native_serialize, 1);
  rb_define_singleton_method(stack_recorder_class, "_native_reset_after_fork", _native_reset_after_fork, 1);
  rb_define_singleton_method(stack_recorder_class, "_native_stats", _native_stats, 1);
  rb_define_singleton_method(testing_module, "_native_active_slot", _native_active_slot, 1);
  rb_define_singleton_method(testing_module, "_native_slot_one_mutex_locked?", _native_is_slot_one_mutex_locked, 1);
  rb_define_singleton_method(testing_module, "_native_slot_two_mutex_locked?", _native_is_slot_two_mutex_locked, 1);
  rb_define_singleton_method(testing_module, "_native_record_endpoint", _native_record_endpoint, 3);
  rb_define_singleton_method(testing_module, "_native_track_object", _native_track_object, 4);
  rb_define_singleton_method(testing_module, "_native_start_fake_slow_heap_serialization",
      _native_start_fake_slow_heap_serialization, 1);
  rb_define_singleton_method(testing_module, "_native_end_fake_slow_heap_serialization",
      _native_end_fake_slow_heap_serialization, 1);
  rb_define_singleton_method(testing_module, "_native_debug_heap_recorder",
      _native_debug_heap_recorder, 1);
  rb_define_singleton_method(testing_module, "_native_is_object_recorded?", _native_is_object_recorded, 2);
  rb_define_singleton_method(testing_module, "_native_heap_recorder_reset_last_update", _native_heap_recorder_reset_last_update, 1);
  rb_define_singleton_method(testing_module, "_native_recorder_after_gc_step", _native_recorder_after_gc_step, 1);
  rb_define_singleton_method(testing_module, "_native_benchmark_intern", _native_benchmark_intern, 4);
  rb_define_singleton_method(testing_module, "_native_test_managed_string_storage_produces_valid_profiles", _native_test_managed_string_storage_produces_valid_profiles, 0);

  ok_symbol = ID2SYM(rb_intern_const("ok"));
  error_symbol = ID2SYM(rb_intern_const("error"));
}

// This structure is used to define a Ruby object that stores a pointer to a ddog_prof_Profile instance
// See also https://github.com/ruby/ruby/blob/master/doc/extension.rdoc for how this works
static const rb_data_type_t stack_recorder_typed_data = {
  .wrap_struct_name = "Datadog::Profiling::StackRecorder",
  .function = {
    .dfree = stack_recorder_typed_data_free,
    .dsize = NULL, // We don't track profile memory usage (although it'd be cool if we did!)
    // No need to provide dmark nor dcompact because we don't directly reference Ruby VALUEs from inside this object
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE _native_new(VALUE klass) {
  stack_recorder_state *state = ruby_xcalloc(1, sizeof(stack_recorder_state));

  // Note: Any exceptions raised from this note until the TypedData_Wrap_Struct call will lead to the state memory
  // being leaked.

  state->heap_clean_after_gc_enabled = false;

  ddog_prof_Slice_ValueType sample_types = {.ptr = all_value_types, .len = ALL_VALUE_TYPES_COUNT};

  initialize_slot_concurrency_control(state);
  for (uint8_t i = 0; i < ALL_VALUE_TYPES_COUNT; i++) { state->position_for[i] = all_value_types_positions[i]; }
  state->enabled_values_count = ALL_VALUE_TYPES_COUNT;
  state->stats_lifetime = (struct lifetime_stats) {
    .serialization_time_ns_min = INT64_MAX,
  };

  // Note: At this point, slot_one_profile/slot_two_profile/string_storage contain null pointers. Libdatadog validates pointers
  // before using them so it's ok for us to go ahead and create the StackRecorder object.

  VALUE stack_recorder = TypedData_Wrap_Struct(klass, &stack_recorder_typed_data, state);

  ddog_prof_ManagedStringStorageNewResult string_storage = ddog_prof_ManagedStringStorage_new();

  if (string_storage.tag == DDOG_PROF_MANAGED_STRING_STORAGE_NEW_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to initialize string storage: %"PRIsVALUE, get_error_details_and_drop(&string_storage.err));
  }

  state->string_storage = string_storage.ok;
  state->label_key_allocation_class = intern_or_raise(state->string_storage, DDOG_CHARSLICE_C("allocation class"));
  state->label_key_gc_gen_age = intern_or_raise(state->string_storage, DDOG_CHARSLICE_C("gc gen age"));

  initialize_profiles(state, sample_types);

  // NOTE: We initialize this because we want a new recorder to be operational even before #initialize runs and our
  //       default is everything enabled. However, if during recording initialization it turns out we don't want
  //       heap samples, we will free and reset heap_recorder back to NULL.
  state->heap_recorder = heap_recorder_new(state->string_storage);

  return stack_recorder;
}

static void initialize_slot_concurrency_control(stack_recorder_state *state) {
  state->mutex_slot_one = (pthread_mutex_t) PTHREAD_MUTEX_INITIALIZER;
  state->mutex_slot_two = (pthread_mutex_t) PTHREAD_MUTEX_INITIALIZER;

  // A newly-created StackRecorder starts with slot one being active for samples, so let's lock slot two
  ENFORCE_SUCCESS_GVL(pthread_mutex_lock(&state->mutex_slot_two));

  state->active_slot = 1;
}

static void initialize_profiles(stack_recorder_state *state, ddog_prof_Slice_ValueType sample_types) {
  ddog_Timespec start_timestamp = system_epoch_now_timespec();

  ddog_prof_Profile_NewResult slot_one_profile_result =
    ddog_prof_Profile_with_string_storage(sample_types, NULL /* period is optional */, state->string_storage);

  if (slot_one_profile_result.tag == DDOG_PROF_PROFILE_NEW_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to initialize slot one profile: %"PRIsVALUE, get_error_details_and_drop(&slot_one_profile_result.err));
  }

  state->profile_slot_one = (profile_slot) { .profile = slot_one_profile_result.ok, .start_timestamp = start_timestamp };

  ddog_prof_Profile_NewResult slot_two_profile_result =
    ddog_prof_Profile_with_string_storage(sample_types, NULL /* period is optional */, state->string_storage);

  if (slot_two_profile_result.tag == DDOG_PROF_PROFILE_NEW_RESULT_ERR) {
    // Note: No need to take any special care of slot one, it'll get cleaned up by stack_recorder_typed_data_free
    rb_raise(rb_eRuntimeError, "Failed to initialize slot two profile: %"PRIsVALUE, get_error_details_and_drop(&slot_two_profile_result.err));
  }

  state->profile_slot_two = (profile_slot) { .profile = slot_two_profile_result.ok, .start_timestamp = start_timestamp };
}

static void stack_recorder_typed_data_free(void *state_ptr) {
  stack_recorder_state *state = (stack_recorder_state *) state_ptr;

  pthread_mutex_destroy(&state->mutex_slot_one);
  ddog_prof_Profile_drop(&state->profile_slot_one.profile);

  pthread_mutex_destroy(&state->mutex_slot_two);
  ddog_prof_Profile_drop(&state->profile_slot_two.profile);

  heap_recorder_free(state->heap_recorder);

  ddog_prof_ManagedStringStorage_drop(state->string_storage);

  ruby_xfree(state);
}

static VALUE _native_initialize(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self) {
  VALUE options;
  rb_scan_args(argc, argv, "0:", &options);
  if (options == Qnil) options = rb_hash_new();

  VALUE recorder_instance = rb_hash_fetch(options, ID2SYM(rb_intern("self_instance")));
  VALUE cpu_time_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("cpu_time_enabled")));
  VALUE alloc_samples_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("alloc_samples_enabled")));
  VALUE heap_samples_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("heap_samples_enabled")));
  VALUE heap_size_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("heap_size_enabled")));
  VALUE heap_sample_every = rb_hash_fetch(options, ID2SYM(rb_intern("heap_sample_every")));
  VALUE timeline_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("timeline_enabled")));
  VALUE heap_clean_after_gc_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("heap_clean_after_gc_enabled")));

  ENFORCE_BOOLEAN(cpu_time_enabled);
  ENFORCE_BOOLEAN(alloc_samples_enabled);
  ENFORCE_BOOLEAN(heap_samples_enabled);
  ENFORCE_BOOLEAN(heap_size_enabled);
  ENFORCE_TYPE(heap_sample_every, T_FIXNUM);
  ENFORCE_BOOLEAN(timeline_enabled);
  ENFORCE_BOOLEAN(heap_clean_after_gc_enabled);

  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  state->heap_clean_after_gc_enabled = (heap_clean_after_gc_enabled == Qtrue);

  heap_recorder_set_sample_rate(state->heap_recorder, NUM2INT(heap_sample_every));

  uint8_t requested_values_count = ALL_VALUE_TYPES_COUNT -
    (cpu_time_enabled == Qtrue ? 0 : 1) -
    (alloc_samples_enabled == Qtrue? 0 : 2) -
    (heap_samples_enabled == Qtrue ? 0 : 1) -
    (heap_size_enabled == Qtrue ? 0 : 1) -
    (timeline_enabled == Qtrue ? 0 : 1);

  if (requested_values_count == ALL_VALUE_TYPES_COUNT) return Qtrue; // Nothing to do, this is the default

  // When some sample types are disabled, we need to reconfigure libdatadog to record less types,
  // as well as reconfigure the position_for array to push the disabled types to the end so they don't get recorded.
  // See record_sample for details on the use of position_for.

  state->enabled_values_count = requested_values_count;

  ddog_prof_ValueType enabled_value_types[ALL_VALUE_TYPES_COUNT];
  uint8_t next_enabled_pos = 0;
  uint8_t next_disabled_pos = requested_values_count;

  // CPU_SAMPLES_VALUE is always enabled
  enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) CPU_SAMPLES_VALUE;
  state->position_for[CPU_SAMPLES_VALUE_ID] = next_enabled_pos++;

  // WALL_TIME_VALUE is always enabled
  enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) WALL_TIME_VALUE;
  state->position_for[WALL_TIME_VALUE_ID] = next_enabled_pos++;

  if (cpu_time_enabled == Qtrue) {
    enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) CPU_TIME_VALUE;
    state->position_for[CPU_TIME_VALUE_ID] = next_enabled_pos++;
  } else {
    state->position_for[CPU_TIME_VALUE_ID] = next_disabled_pos++;
  }

  if (alloc_samples_enabled == Qtrue) {
    enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) ALLOC_SAMPLES_VALUE;
    state->position_for[ALLOC_SAMPLES_VALUE_ID] = next_enabled_pos++;

    enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) ALLOC_SAMPLES_UNSCALED_VALUE;
    state->position_for[ALLOC_SAMPLES_UNSCALED_VALUE_ID] = next_enabled_pos++;
  } else {
    state->position_for[ALLOC_SAMPLES_VALUE_ID] = next_disabled_pos++;
    state->position_for[ALLOC_SAMPLES_UNSCALED_VALUE_ID] = next_disabled_pos++;
  }

  if (heap_samples_enabled == Qtrue) {
    enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) HEAP_SAMPLES_VALUE;
    state->position_for[HEAP_SAMPLES_VALUE_ID] = next_enabled_pos++;
  } else {
    state->position_for[HEAP_SAMPLES_VALUE_ID] = next_disabled_pos++;
  }

  if (heap_size_enabled == Qtrue) {
    enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) HEAP_SIZE_VALUE;
    state->position_for[HEAP_SIZE_VALUE_ID] = next_enabled_pos++;
  } else {
    state->position_for[HEAP_SIZE_VALUE_ID] = next_disabled_pos++;
  }
  heap_recorder_set_size_enabled(state->heap_recorder, heap_size_enabled);

  if (heap_samples_enabled == Qfalse && heap_size_enabled == Qfalse) {
    // Turns out heap sampling is disabled but we initialized everything in _native_new
    // assuming all samples were enabled. We need to deinitialize the heap recorder.
    heap_recorder_free(state->heap_recorder);
    state->heap_recorder = NULL;
  }

  if (timeline_enabled == Qtrue) {
    enabled_value_types[next_enabled_pos] = (ddog_prof_ValueType) TIMELINE_VALUE;
    state->position_for[TIMELINE_VALUE_ID] = next_enabled_pos++;
  } else {
    state->position_for[TIMELINE_VALUE_ID] = next_disabled_pos++;
  }

  ddog_prof_Profile_drop(&state->profile_slot_one.profile);
  ddog_prof_Profile_drop(&state->profile_slot_two.profile);

  ddog_prof_Slice_ValueType sample_types = {.ptr = enabled_value_types, .len = state->enabled_values_count};
  initialize_profiles(state, sample_types);

  return Qtrue;
}

static VALUE _native_serialize(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  ddog_Timespec finish_timestamp = system_epoch_now_timespec();
  // Need to do this while still holding on to the Global VM Lock; see comments on method for why
  serializer_set_start_timestamp_for_next_profile(state, finish_timestamp);

  long heap_iteration_prep_start_time_ns = monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE);
  // Prepare the iteration on heap recorder we'll be doing outside the GVL. The preparation needs to
  // happen while holding on to the GVL.
  // NOTE: While rare, it's possible for the GVL to be released inside this function (see comments on `heap_recorder_update`)
  // and thus don't assume this is an "atomic" step -- other threads may get some running time in the meanwhile.
  heap_recorder_prepare_iteration(state->heap_recorder);
  long heap_iteration_prep_time_ns = monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE) - heap_iteration_prep_start_time_ns;

  // We'll release the Global VM Lock while we're calling serialize, so that the Ruby VM can continue to work while this
  // is pending
  call_serialize_without_gvl_arguments args = {
    .state = state,
    .finish_timestamp = finish_timestamp,
    .serialize_ran = false,
  };

  while (!args.serialize_ran) {
    // Give the Ruby VM an opportunity to process any pending interruptions (including raising exceptions).
    // Note that it's OK to do this BEFORE call_serialize_without_gvl runs BUT NOT AFTER because afterwards
    // there's heap-allocated memory that MUST be cleaned before raising any exception.
    //
    // Note that we run this in a loop because `rb_thread_call_without_gvl2` may return multiple times due to
    // pending interrupts until it actually runs our code.
    process_pending_interruptions(Qnil);

    // We use rb_thread_call_without_gvl2 here because unlike the regular _gvl variant, gvl2 does not process
    // interruptions and thus does not raise exceptions after running our code.
    rb_thread_call_without_gvl2(call_serialize_without_gvl, &args, NULL /* No interruption function needed in this case */, NULL /* Not needed */);
  }

  // Cleanup after heap recorder iteration. This needs to happen while holding on to the GVL.
  heap_recorder_finish_iteration(state->heap_recorder);

  // NOTE: We are focusing on the serialization time outside of the GVL in this stat here. This doesn't
  //       really cover the full serialization process but it gives a more useful number since it bypasses
  //       the noise of acquiring GVLs and dealing with interruptions which is highly specific to runtime
  //       conditions and over which we really have no control about.
  state->stats_lifetime.serialization_time_ns_max = long_max_of(state->stats_lifetime.serialization_time_ns_max, args.serialize_no_gvl_time_ns);
  state->stats_lifetime.serialization_time_ns_min = long_min_of(state->stats_lifetime.serialization_time_ns_min, args.serialize_no_gvl_time_ns);
  state->stats_lifetime.serialization_time_ns_total += args.serialize_no_gvl_time_ns;

  ddog_prof_Profile_SerializeResult serialized_profile = args.result;

  if (serialized_profile.tag == DDOG_PROF_PROFILE_SERIALIZE_RESULT_ERR) {
    state->stats_lifetime.serialization_failures++;
    return rb_ary_new_from_args(2, error_symbol, get_error_details_and_drop(&serialized_profile.err));
  }

  // Note: If we got here, the profile serialized correctly.
  // Once we wrap this into a Ruby object, our `EncodedProfile` class will automatically manage memory for it and we
  // can raise exceptions without worrying about leaking the profile.
  state->stats_lifetime.serialization_successes++;
  VALUE encoded_profile = from_ddog_prof_EncodedProfile(serialized_profile.ok);

  ddog_prof_MaybeError result = args.advance_gen_result;
  if (result.tag == DDOG_PROF_OPTION_ERROR_SOME_ERROR) {
    rb_raise(rb_eRuntimeError, "Failed to advance string storage gen: %"PRIsVALUE, get_error_details_and_drop(&result.some));
  }

  VALUE start = ruby_time_from(args.slot->start_timestamp);
  VALUE finish = ruby_time_from(finish_timestamp);
  VALUE profile_stats = build_profile_stats(args.slot, args.serialize_no_gvl_time_ns, heap_iteration_prep_time_ns, args.heap_profile_build_time_ns);

  return rb_ary_new_from_args(2, ok_symbol, rb_ary_new_from_args(4, start, finish, encoded_profile, profile_stats));
}

static VALUE ruby_time_from(ddog_Timespec ddprof_time) {
  const int utc = INT_MAX - 1; // From Ruby sources
  struct timespec time = {.tv_sec = ddprof_time.seconds, .tv_nsec = ddprof_time.nanoseconds};
  return rb_time_timespec_new(&time, utc);
}

void record_sample(VALUE recorder_instance, ddog_prof_Slice_Location locations, sample_values values, sample_labels labels) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  locked_profile_slot active_slot = sampler_lock_active_profile(state);

  // Note: We initialize this array to have ALL_VALUE_TYPES_COUNT but only tell libdatadog to use the first
  // state->enabled_values_count values. This simplifies handling disabled value types -- we still put them on the
  // array, but in _native_initialize we arrange so their position starts from state->enabled_values_count and thus
  // libdatadog doesn't touch them.
  int64_t metric_values[ALL_VALUE_TYPES_COUNT] = {0};
  uint8_t *position_for = state->position_for;

  metric_values[position_for[CPU_TIME_VALUE_ID]]      = values.cpu_time_ns;
  metric_values[position_for[CPU_SAMPLES_VALUE_ID]]   = values.cpu_or_wall_samples;
  metric_values[position_for[WALL_TIME_VALUE_ID]]     = values.wall_time_ns;
  metric_values[position_for[ALLOC_SAMPLES_VALUE_ID]] = values.alloc_samples;
  metric_values[position_for[ALLOC_SAMPLES_UNSCALED_VALUE_ID]] = values.alloc_samples_unscaled;
  metric_values[position_for[TIMELINE_VALUE_ID]]      = values.timeline_wall_time_ns;

  if (values.heap_sample) {
    // If we got an allocation sample end the heap allocation recording to commit the heap sample.
    // FIXME: Heap sampling currently has to be done in 2 parts because the construction of locations is happening
    //        very late in the allocation-sampling path (which is shared with the cpu sampling path). This can
    //        be fixed with some refactoring but for now this leads to a less impactful change.
    //
    // NOTE: The heap recorder is allowed to raise exceptions if something's wrong. But we also need to handle it
    // on this side to make sure we properly unlock the active slot mutex on our way out. Otherwise, this would
    // later lead to deadlocks (since the active slot mutex is not expected to be locked forever).
    int exception_state = end_heap_allocation_recording_with_rb_protect(state->heap_recorder, locations);
    if (exception_state) {
      sampler_unlock_active_profile(active_slot);
      rb_jump_tag(exception_state);
    }
  }

  ddog_prof_Profile_Result result = ddog_prof_Profile_add(
    &active_slot.data->profile,
    (ddog_prof_Sample) {
      .locations = locations,
      .values = (ddog_Slice_I64) {.ptr = metric_values, .len = state->enabled_values_count},
      .labels = labels.labels
    },
    labels.end_timestamp_ns
  );

  active_slot.data->stats.recorded_samples++;

  sampler_unlock_active_profile(active_slot);

  if (result.tag == DDOG_PROF_PROFILE_RESULT_ERR) {
    rb_raise(rb_eArgError, "Failed to record sample: %"PRIsVALUE, get_error_details_and_drop(&result.err));
  }
}

void track_object(VALUE recorder_instance, VALUE new_object, unsigned int sample_weight, ddog_CharSlice alloc_class) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);
  // FIXME: Heap sampling currently has to be done in 2 parts because the construction of locations is happening
  //        very late in the allocation-sampling path (which is shared with the cpu sampling path). This can
  //        be fixed with some refactoring but for now this leads to a less impactful change.
  start_heap_allocation_recording(state->heap_recorder, new_object, sample_weight, alloc_class);
}

void record_endpoint(VALUE recorder_instance, uint64_t local_root_span_id, ddog_CharSlice endpoint) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  locked_profile_slot active_slot = sampler_lock_active_profile(state);

  ddog_prof_Profile_Result result = ddog_prof_Profile_set_endpoint(&active_slot.data->profile, local_root_span_id, endpoint);

  sampler_unlock_active_profile(active_slot);

  if (result.tag == DDOG_PROF_PROFILE_RESULT_ERR) {
    rb_raise(rb_eArgError, "Failed to record endpoint: %"PRIsVALUE, get_error_details_and_drop(&result.err));
  }
}

void recorder_after_gc_step(VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  if (state->heap_clean_after_gc_enabled) heap_recorder_update_young_objects(state->heap_recorder);
}

#define MAX_LEN_HEAP_ITERATION_ERROR_MSG 256

// Heap recorder iteration context allows us access to stack recorder state and profile being serialized
// during iteration of heap recorder live objects.
typedef struct heap_recorder_iteration_context {
  stack_recorder_state *state;
  profile_slot *slot;

  bool error;
  char error_msg[MAX_LEN_HEAP_ITERATION_ERROR_MSG];
} heap_recorder_iteration_context;

static bool add_heap_sample_to_active_profile_without_gvl(heap_recorder_iteration_data iteration_data, void *extra_arg) {
  heap_recorder_iteration_context *context = (heap_recorder_iteration_context*) extra_arg;

  live_object_data *object_data = &iteration_data.object_data;

  int64_t metric_values[ALL_VALUE_TYPES_COUNT] = {0};
  uint8_t *position_for = context->state->position_for;

  metric_values[position_for[HEAP_SAMPLES_VALUE_ID]] = object_data->weight;
  metric_values[position_for[HEAP_SIZE_VALUE_ID]] = object_data->size * object_data->weight;

  ddog_prof_Label labels[2];
  size_t label_offset = 0;

  if (object_data->class.value > 0) {
    labels[label_offset++] = (ddog_prof_Label) {
      .key_id = context->state->label_key_allocation_class,
      .str_id = object_data->class,
      .num = 0, // This shouldn't be needed but the tracer-2.7 docker image ships a buggy gcc that complains about this
    };
  }
  labels[label_offset++] = (ddog_prof_Label) {
    .key_id = context->state->label_key_gc_gen_age,
    .num = object_data->gen_age,
  };

  ddog_prof_Profile_Result result = ddog_prof_Profile_add(
    &context->slot->profile,
    (ddog_prof_Sample) {
      .locations = iteration_data.locations,
      .values = (ddog_Slice_I64) {.ptr = metric_values, .len = context->state->enabled_values_count},
      .labels = (ddog_prof_Slice_Label) {
        .ptr = labels,
        .len = label_offset,
      }
    },
    0
  );

  context->slot->stats.recorded_samples++;

  if (result.tag == DDOG_PROF_PROFILE_RESULT_ERR) {
    read_ddogerr_string_and_drop(&result.err, context->error_msg, MAX_LEN_HEAP_ITERATION_ERROR_MSG);
    context->error = true;
    // By returning false we cancel the iteration
    return false;
  }

  // Keep on iterating to next item!
  return true;
}

static void build_heap_profile_without_gvl(stack_recorder_state *state, profile_slot *slot) {
  heap_recorder_iteration_context iteration_context = {
    .state = state,
    .slot = slot,
    .error = false,
    .error_msg = {0},
  };
  bool iterated = heap_recorder_for_each_live_object(state->heap_recorder, add_heap_sample_to_active_profile_without_gvl, (void*) &iteration_context);
  // We wait until we're out of the iteration to grab the gvl and raise. This is important because during
  // iteration we may potentially acquire locks in the heap recorder and we could reach a deadlock if the
  // same locks are acquired by the heap recorder while holding the gvl (since we'd be operating on the
  // same locks but acquiring them in different order).
  if (!iterated) {
    grab_gvl_and_raise(rb_eRuntimeError, "Failure during heap profile building: iteration cancelled");
  }
  else if (iteration_context.error) {
    grab_gvl_and_raise(rb_eRuntimeError, "Failure during heap profile building: %s", iteration_context.error_msg);
  }
}

static void *call_serialize_without_gvl(void *call_args) {
  call_serialize_without_gvl_arguments *args = (call_serialize_without_gvl_arguments *) call_args;

  long serialize_no_gvl_start_time_ns = monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE);

  profile_slot *slot_now_inactive = serializer_flip_active_and_inactive_slots(args->state);
  args->slot = slot_now_inactive;

  // Now that we have the inactive profile with all but heap samples, lets fill it with heap data
  // without needing to race with the active sampler
  build_heap_profile_without_gvl(args->state, args->slot);
  args->heap_profile_build_time_ns = monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE) - serialize_no_gvl_start_time_ns;

  // Note: The profile gets reset by the serialize call
  args->result = ddog_prof_Profile_serialize(&args->slot->profile, &args->slot->start_timestamp, &args->finish_timestamp);
  args->advance_gen_result = ddog_prof_ManagedStringStorage_advance_gen(args->state->string_storage);
  args->serialize_ran = true;
  args->serialize_no_gvl_time_ns = long_max_of(0, monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE) - serialize_no_gvl_start_time_ns);

  return NULL; // Unused
}

VALUE enforce_recorder_instance(VALUE object) {
  ENFORCE_TYPED_DATA(object, &stack_recorder_typed_data);
  return object;
}

static locked_profile_slot sampler_lock_active_profile(stack_recorder_state *state) {
  int error;

  for (int attempts = 0; attempts < 2; attempts++) {
    error = pthread_mutex_trylock(&state->mutex_slot_one);
    if (error && error != EBUSY) ENFORCE_SUCCESS_GVL(error);

    // Slot one is active
    if (!error) return (locked_profile_slot) {.mutex = &state->mutex_slot_one, .data = &state->profile_slot_one};

    // If we got here, slot one was not active, let's try slot two

    error = pthread_mutex_trylock(&state->mutex_slot_two);
    if (error && error != EBUSY) ENFORCE_SUCCESS_GVL(error);

    // Slot two is active
    if (!error) return (locked_profile_slot) {.mutex = &state->mutex_slot_two, .data = &state->profile_slot_two};
  }

  // We already tried both multiple times, and we did not succeed. This is not expected to happen. Let's stop sampling.
  rb_raise(rb_eRuntimeError, "Failed to grab either mutex in sampler_lock_active_profile");
}

static void sampler_unlock_active_profile(locked_profile_slot active_slot) {
  ENFORCE_SUCCESS_GVL(pthread_mutex_unlock(active_slot.mutex));
}

static profile_slot* serializer_flip_active_and_inactive_slots(stack_recorder_state *state) {
  int previously_active_slot = state->active_slot;

  if (previously_active_slot != 1 && previously_active_slot != 2) {
    grab_gvl_and_raise(rb_eRuntimeError, "Unexpected active_slot state %d in serializer_flip_active_and_inactive_slots", previously_active_slot);
  }

  pthread_mutex_t *previously_active = (previously_active_slot == 1) ? &state->mutex_slot_one : &state->mutex_slot_two;
  pthread_mutex_t *previously_inactive = (previously_active_slot == 1) ? &state->mutex_slot_two : &state->mutex_slot_one;

  // Release the lock, thus making this slot active
  ENFORCE_SUCCESS_NO_GVL(pthread_mutex_unlock(previously_inactive));

  // Grab the lock, thus making this slot inactive
  ENFORCE_SUCCESS_NO_GVL(pthread_mutex_lock(previously_active));

  // Update active_slot
  state->active_slot = (previously_active_slot == 1) ? 2 : 1;

  // Return pointer to previously active slot (now inactive)
  return (previously_active_slot == 1) ? &state->profile_slot_one : &state->profile_slot_two;
}

// This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_active_slot(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  return INT2NUM(state->active_slot);
}

// This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_is_slot_one_mutex_locked(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) { return test_slot_mutex_state(recorder_instance, 1); }

// This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_is_slot_two_mutex_locked(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) { return test_slot_mutex_state(recorder_instance, 2); }

static VALUE test_slot_mutex_state(VALUE recorder_instance, int slot) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  pthread_mutex_t *slot_mutex = (slot == 1) ? &state->mutex_slot_one : &state->mutex_slot_two;

  // Like Heisenberg's uncertainty principle, we can't observe without affecting...
  int error = pthread_mutex_trylock(slot_mutex);

  if (error == 0) {
    // Mutex was unlocked
    ENFORCE_SUCCESS_GVL(pthread_mutex_unlock(slot_mutex));
    return Qfalse;
  } else if (error == EBUSY) {
    // Mutex was locked
    return Qtrue;
  } else {
    ENFORCE_SUCCESS_GVL(error);
    rb_raise(rb_eRuntimeError, "Failed to raise exception in test_slot_mutex_state; this should never happen");
  }
}

static ddog_Timespec system_epoch_now_timespec(void) {
  long now_ns = system_epoch_time_now_ns(RAISE_ON_FAILURE);
  return (ddog_Timespec) {.seconds = now_ns / SECONDS_AS_NS(1), .nanoseconds = now_ns % SECONDS_AS_NS(1)};
}

// After the Ruby VM forks, this method gets called in the child process to clean up any leftover state from the parent.
//
// Assumption: This method gets called BEFORE restarting profiling -- e.g. there are no components attempting to
// trigger samples at the same time.
static VALUE _native_reset_after_fork(DDTRACE_UNUSED VALUE self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  // In case the fork happened halfway through `serializer_flip_active_and_inactive_slots` execution and the
  // resulting state is inconsistent, we make sure to reset it back to the initial state.
  initialize_slot_concurrency_control(state);
  ddog_Timespec start_timestamp = system_epoch_now_timespec();
  reset_profile_slot(&state->profile_slot_one, start_timestamp);
  reset_profile_slot(&state->profile_slot_two, start_timestamp);

  heap_recorder_after_fork(state->heap_recorder);

  return Qtrue;
}

// Assumption 1: This method is called with the GVL being held, because `ddog_prof_Profile_reset` mutates the profile and must
// not be interrupted part-way through by a VM fork.
static void serializer_set_start_timestamp_for_next_profile(stack_recorder_state *state, ddog_Timespec start_time) {
  // Before making this profile active, we reset it so that it uses the correct start_time for its start
  profile_slot *next_profile_slot = (state->active_slot == 1) ? &state->profile_slot_two : &state->profile_slot_one;
  reset_profile_slot(next_profile_slot, start_time);
}

static VALUE _native_record_endpoint(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE local_root_span_id, VALUE endpoint) {
  ENFORCE_TYPE(local_root_span_id, T_FIXNUM);
  record_endpoint(recorder_instance, NUM2ULL(local_root_span_id), char_slice_from_ruby_string(endpoint));
  return Qtrue;
}

static VALUE _native_track_object(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE new_obj, VALUE weight, VALUE alloc_class) {
  ENFORCE_TYPE(weight, T_FIXNUM);
  track_object(recorder_instance, new_obj, NUM2UINT(weight), char_slice_from_ruby_string(alloc_class));
  return Qtrue;
}

static void reset_profile_slot(profile_slot *slot, ddog_Timespec start_timestamp) {
  ddog_prof_Profile_Result reset_result = ddog_prof_Profile_reset(&slot->profile);
  if (reset_result.tag == DDOG_PROF_PROFILE_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to reset profile: %"PRIsVALUE, get_error_details_and_drop(&reset_result.err));
  }
  slot->start_timestamp = start_timestamp;
  slot->stats = (stats_slot) {};
}

// This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_start_fake_slow_heap_serialization(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  heap_recorder_prepare_iteration(state->heap_recorder);

  return Qnil;
}

// This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_end_fake_slow_heap_serialization(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  heap_recorder_finish_iteration(state->heap_recorder);

  return Qnil;
}

// This method exists only to enable testing Datadog::Profiling::StackRecorder behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_debug_heap_recorder(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  return heap_recorder_testonly_debug(state->heap_recorder);
}

static VALUE _native_stats(DDTRACE_UNUSED VALUE self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  uint64_t total_serializations = state->stats_lifetime.serialization_successes + state->stats_lifetime.serialization_failures;

  VALUE heap_recorder_snapshot = state->heap_recorder ?
    heap_recorder_state_snapshot(state->heap_recorder) : Qnil;

  VALUE stats_as_hash = rb_hash_new();
  VALUE arguments[] = {
    ID2SYM(rb_intern("serialization_successes")), /* => */ ULL2NUM(state->stats_lifetime.serialization_successes),
    ID2SYM(rb_intern("serialization_failures")),  /* => */ ULL2NUM(state->stats_lifetime.serialization_failures),

    ID2SYM(rb_intern("serialization_time_ns_min")),   /* => */ RUBY_NUM_OR_NIL(state->stats_lifetime.serialization_time_ns_min, != INT64_MAX, LONG2NUM),
    ID2SYM(rb_intern("serialization_time_ns_max")),   /* => */ RUBY_NUM_OR_NIL(state->stats_lifetime.serialization_time_ns_max, > 0, LONG2NUM),
    ID2SYM(rb_intern("serialization_time_ns_total")), /* => */ RUBY_NUM_OR_NIL(state->stats_lifetime.serialization_time_ns_total, > 0, LONG2NUM),
    ID2SYM(rb_intern("serialization_time_ns_avg")),   /* => */ RUBY_AVG_OR_NIL(state->stats_lifetime.serialization_time_ns_total, total_serializations),

    ID2SYM(rb_intern("heap_recorder_snapshot")), /* => */ heap_recorder_snapshot,
  };
  for (long unsigned int i = 0; i < VALUE_COUNT(arguments); i += 2) rb_hash_aset(stats_as_hash, arguments[i], arguments[i+1]);
  return stats_as_hash;
}

static VALUE build_profile_stats(profile_slot *slot, long serialization_time_ns, long heap_iteration_prep_time_ns, long heap_profile_build_time_ns) {
  VALUE stats_as_hash = rb_hash_new();
  VALUE arguments[] = {
    ID2SYM(rb_intern("recorded_samples")), /* => */ ULL2NUM(slot->stats.recorded_samples),
    ID2SYM(rb_intern("serialization_time_ns")), /* => */ LONG2NUM(serialization_time_ns),
    ID2SYM(rb_intern("heap_iteration_prep_time_ns")), /* => */ LONG2NUM(heap_iteration_prep_time_ns),
    ID2SYM(rb_intern("heap_profile_build_time_ns")), /* => */ LONG2NUM(heap_profile_build_time_ns),
  };
  for (long unsigned int i = 0; i < VALUE_COUNT(arguments); i += 2) rb_hash_aset(stats_as_hash, arguments[i], arguments[i+1]);
  return stats_as_hash;
}

static VALUE _native_is_object_recorded(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE obj_id) {
  ENFORCE_TYPE(obj_id, T_FIXNUM);

  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  return heap_recorder_testonly_is_object_recorded(state->heap_recorder, obj_id);
}

static VALUE _native_heap_recorder_reset_last_update(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) {
  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  heap_recorder_testonly_reset_last_update(state->heap_recorder);

  return Qtrue;
}

static VALUE _native_recorder_after_gc_step(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance) {
  recorder_after_gc_step(recorder_instance);
  return Qtrue;
}

static VALUE _native_benchmark_intern(DDTRACE_UNUSED VALUE _self, VALUE recorder_instance, VALUE string, VALUE times, VALUE use_all) {
  ENFORCE_TYPE(string, T_STRING);
  ENFORCE_TYPE(times, T_FIXNUM);
  ENFORCE_BOOLEAN(use_all);

  stack_recorder_state *state;
  TypedData_Get_Struct(recorder_instance, stack_recorder_state, &stack_recorder_typed_data, state);

  heap_recorder_testonly_benchmark_intern(state->heap_recorder, char_slice_from_ruby_string(string), FIX2INT(times), use_all == Qtrue);

  return Qtrue;
}

// See comments in rspec test for details on what we're testing here.
static VALUE _native_test_managed_string_storage_produces_valid_profiles(DDTRACE_UNUSED VALUE _self) {
  ddog_prof_ManagedStringStorageNewResult string_storage = ddog_prof_ManagedStringStorage_new();

  if (string_storage.tag == DDOG_PROF_MANAGED_STRING_STORAGE_NEW_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to initialize string storage: %"PRIsVALUE, get_error_details_and_drop(&string_storage.err));
  }

  ddog_prof_Slice_ValueType sample_types = {.ptr = all_value_types, .len = ALL_VALUE_TYPES_COUNT};
  ddog_prof_Profile_NewResult profile = ddog_prof_Profile_with_string_storage(sample_types, NULL, string_storage.ok);

  if (profile.tag == DDOG_PROF_PROFILE_NEW_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to initialize profile: %"PRIsVALUE, get_error_details_and_drop(&profile.err));
  }

  ddog_prof_ManagedStringId hello = intern_or_raise(string_storage.ok, DDOG_CHARSLICE_C("hello"));
  ddog_prof_ManagedStringId world = intern_or_raise(string_storage.ok, DDOG_CHARSLICE_C("world"));
  ddog_prof_ManagedStringId key   = intern_or_raise(string_storage.ok, DDOG_CHARSLICE_C("key"));

  int64_t metric_values[] = {1, 2, 3, 4, 5, 6, 7, 8};
  ddog_prof_Label labels[] = {{.key_id = key, .str_id = key}};

  ddog_prof_Location locations[] = {
    (ddog_prof_Location) {
      .mapping = {.filename = DDOG_CHARSLICE_C(""), .build_id = DDOG_CHARSLICE_C(""), .build_id_id = {}},
      .function = {
        .name = DDOG_CHARSLICE_C(""),
        .name_id = hello,
        .filename = DDOG_CHARSLICE_C(""),
        .filename_id = world,
      },
      .line = 1,
    }
  };

  ddog_prof_Profile_Result result = ddog_prof_Profile_add(
    &profile.ok,
    (ddog_prof_Sample) {
      .locations = (ddog_prof_Slice_Location) { .ptr = locations, .len = 1},
      .values = (ddog_Slice_I64) {.ptr = metric_values, .len = 8},
      .labels = (ddog_prof_Slice_Label) { .ptr = labels, .len = 1 }
    },
    0
  );

  if (result.tag == DDOG_PROF_PROFILE_RESULT_ERR) {
    rb_raise(rb_eArgError, "Failed to record sample: %"PRIsVALUE, get_error_details_and_drop(&result.err));
  }

  ddog_Timespec finish_timestamp = system_epoch_now_timespec();
  ddog_Timespec start_timestamp = {.seconds = finish_timestamp.seconds - 60};
  ddog_prof_Profile_SerializeResult serialize_result = ddog_prof_Profile_serialize(&profile.ok, &start_timestamp, &finish_timestamp);

  if (serialize_result.tag == DDOG_PROF_PROFILE_SERIALIZE_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to serialize: %"PRIsVALUE, get_error_details_and_drop(&serialize_result.err));
  }

  ddog_prof_MaybeError advance_gen_result = ddog_prof_ManagedStringStorage_advance_gen(string_storage.ok);

  if (advance_gen_result.tag == DDOG_PROF_OPTION_ERROR_SOME_ERROR) {
    rb_raise(rb_eRuntimeError, "Failed to advance string storage gen: %"PRIsVALUE, get_error_details_and_drop(&advance_gen_result.some));
  }

  VALUE encoded_pprof_1 = from_ddog_prof_EncodedProfile(serialize_result.ok);

  result = ddog_prof_Profile_add(
    &profile.ok,
    (ddog_prof_Sample) {
      .locations = (ddog_prof_Slice_Location) { .ptr = locations, .len = 1},
      .values = (ddog_Slice_I64) {.ptr = metric_values, .len = 8},
      .labels = (ddog_prof_Slice_Label) { .ptr = labels, .len = 1 }
    },
    0
  );

  if (result.tag == DDOG_PROF_PROFILE_RESULT_ERR) {
    rb_raise(rb_eArgError, "Failed to record sample: %"PRIsVALUE, get_error_details_and_drop(&result.err));
  }

  serialize_result = ddog_prof_Profile_serialize(&profile.ok, &start_timestamp, &finish_timestamp);

  if (serialize_result.tag == DDOG_PROF_PROFILE_SERIALIZE_RESULT_ERR) {
    rb_raise(rb_eArgError, "Failed to serialize: %"PRIsVALUE, get_error_details_and_drop(&serialize_result.err));
  }

  VALUE encoded_pprof_2 = from_ddog_prof_EncodedProfile(serialize_result.ok);

  ddog_prof_Profile_drop(&profile.ok);
  ddog_prof_ManagedStringStorage_drop(string_storage.ok);

  return rb_ary_new_from_args(2, encoded_pprof_1, encoded_pprof_2);
}
