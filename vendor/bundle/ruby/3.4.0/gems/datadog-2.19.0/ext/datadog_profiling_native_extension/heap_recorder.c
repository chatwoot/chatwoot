#include "heap_recorder.h"
#include "ruby/st.h"
#include "ruby_helpers.h"
#include "collectors_stack.h"
#include "libdatadog_helpers.h"
#include "time_helpers.h"

// Note on calloc vs ruby_xcalloc use:
// * Whenever we're allocating memory after being called by the Ruby VM in a "regular" situation (e.g. initializer)
//   we should use `ruby_xcalloc` to give the VM visibility into what we're doing + give it a chance to manage GC
// * BUT, when we're being called during a sample, being in the middle of an object allocation is a very special
//   situation for the VM to be in, and we've found the hard way (e.g. https://bugs.ruby-lang.org/issues/20629 and
//   https://github.com/DataDog/dd-trace-rb/pull/4240 ) that it can be easy to do things the VM didn't expect.
// * Thus, out of caution and to avoid future potential issues such as the ones above, whenever we allocate memory
//   during **sampling** we use `calloc` instead of `ruby_xcalloc`. Note that we've never seen issues from using
//   `ruby_xcalloc` at any time, so this is a **precaution** not a "we've seen it break". But it seems a harmless
//   one to use.
// This applies to both heap_recorder.c and collectors_thread_context.c

// Minimum age (in GC generations) of heap objects we want to include in heap
// recorder iterations. Object with age 0 represent objects that have yet to undergo
// a GC and, thus, may just be noise/trash at instant of iteration and are usually not
// relevant for heap profiles as the great majority should be trivially reclaimed
// during the next GC.
#define ITERATION_MIN_AGE 1
// Copied from https://github.com/ruby/ruby/blob/15135030e5808d527325feaaaf04caeb1b44f8b5/gc/default.c#L725C1-L725C27
// to align with Ruby's GC definition of what constitutes an old object which are only
// supposed to be reclaimed in major GCs.
#define OLD_AGE 3
// Wait at least 2 seconds before asking heap recorder to explicitly update itself. Heap recorder
// data will only materialize at profile serialization time but updating often helps keep our
// heap tracking data small since every GC should get rid of a bunch of temporary objects. The
// more we clean up before profile flush, the less work we'll have to do all-at-once when preparing
// to flush heap data and holding the GVL which should hopefully help with reducing latency impact.
#define MIN_TIME_BETWEEN_HEAP_RECORDER_UPDATES_NS SECONDS_AS_NS(2)

// A compact representation of a stacktrace frame for a heap allocation.
typedef struct {
  ddog_prof_ManagedStringId name;
  ddog_prof_ManagedStringId filename;
  int32_t line;
} heap_frame;

// We use memcmp/st_hash below to compare/hash an entire array of heap_frames, so want to make sure no padding is added
// We could define the structure to be packed, but that seems even weirder across compilers, and this seems more portable?
_Static_assert(
    sizeof(heap_frame) == sizeof(ddog_prof_ManagedStringId) * 2 + sizeof(int32_t),
    "Size of heap_frame does not match the sum of its members. Padding detected."
);

// A compact representation of a stacktrace for a heap allocation.
// Used to dedup heap allocation stacktraces across multiple objects sharing the same allocation location.
typedef struct {
  // How many objects are currently tracked in object_records recorder for this heap record.
  uint32_t num_tracked_objects;

  uint16_t frames_len;
  heap_frame frames[];
} heap_record;
static heap_record* heap_record_new(heap_recorder*, ddog_prof_Slice_Location);
static void heap_record_free(heap_recorder*, heap_record*);

#if MAX_FRAMES_LIMIT > UINT16_MAX
  #error Frames len type not compatible with MAX_FRAMES_LIMIT
#endif

static int heap_record_cmp_st(st_data_t, st_data_t);
static st_index_t heap_record_hash_st(st_data_t);
static const struct st_hash_type st_hash_type_heap_record = { .compare = heap_record_cmp_st, .hash = heap_record_hash_st };

// An object record is used for storing data about currently tracked live objects
typedef struct {
  long obj_id;
  heap_record *heap_record;
  live_object_data object_data;
} object_record;
static object_record* object_record_new(long, heap_record*, live_object_data);
static void object_record_free(heap_recorder*, object_record*);
static VALUE object_record_inspect(heap_recorder*, object_record*);
static object_record SKIPPED_RECORD = {0};

struct heap_recorder {
  // Config
  // Whether the recorder should try to determine approximate sizes for tracked objects.
  bool size_enabled;
  uint sample_rate;

  // Map[key: heap_record*, record: nothing] (This is a set, basically)
  // NOTE: This table is currently only protected by the GVL since we never interact with it
  // outside the GVL.
  // NOTE: This table has ownership of its heap_records.
  //
  // This is a cpu/memory trade-off: Maintaining the "heap_records" map means we spend extra CPU when sampling as we need
  // to do de-duplication, but we reduce the memory footprint of the heap profiler.
  // In the future, it may be worth revisiting if we can move this inside libdatadog: if libdatadog was able to track
  // entire stacks for us, then we wouldn't need to do it on the Ruby side.
  st_table *heap_records;

  // Map[obj_id: long, record: object_record*]
  // NOTE: This table is currently only protected by the GVL since we never interact with it
  // outside the GVL.
  // NOTE: This table has ownership of its object_records. The keys are longs and so are
  // passed as values.
  //
  // TODO: @ivoanjo We've evolved to actually never need to look up on object_records (we only insert and iterate),
  // so right now this seems to be just a really really fancy self-resizing list/set.
  // If we replace this with a list, we could record the latest id and compare it when inserting to make sure our
  // assumption of ids never reused + always increasing always holds. (This as an alternative to checking for duplicates)
  st_table *object_records;

  // Map[obj_id: long, record: object_record*]
  // NOTE: This is a snapshot of object_records built ahead of a iteration. Outside of an
  // iteration context, this table will be NULL. During an iteration, there will be no
  // mutation of the data so iteration can occur without acquiring a lock.
  // NOTE: Contrary to object_records, this table has no ownership of its data.
  st_table *object_records_snapshot;
  // Are we currently updating or not?
  bool updating;
  // The GC gen/epoch/count in which we are updating (or last updated if not currently updating).
  //
  // This enables us to calculate the age of objects considered in the update by comparing it
  // against an object's alloc_gen.
  size_t update_gen;
  // Whether the current update (or last update if not currently updating) is including old
  // objects or not.
  bool update_include_old;
  // When did we do the last update of heap recorder?
  long last_update_ns;

  // Data for a heap recording that was started but not yet ended
  object_record *active_recording;

  // Reusable arrays, implementing a flyweight pattern for things like iteration
  #define REUSABLE_LOCATIONS_SIZE MAX_FRAMES_LIMIT
  ddog_prof_Location *reusable_locations;

  #define REUSABLE_FRAME_DETAILS_SIZE (2 * MAX_FRAMES_LIMIT) // because it'll be used for both function names AND file names)
  ddog_prof_ManagedStringId *reusable_ids;
  ddog_CharSlice *reusable_char_slices;

  // Sampling state
  uint num_recordings_skipped;

  ddog_prof_ManagedStringStorage string_storage;

  struct stats_last_update {
    size_t objects_alive;
    size_t objects_dead;
    size_t objects_skipped;
    size_t objects_frozen;
  } stats_last_update;

  struct stats_lifetime {
    unsigned long updates_successful;
    unsigned long updates_skipped_concurrent;
    unsigned long updates_skipped_gcgen;
    unsigned long updates_skipped_time;

    double ewma_young_objects_alive;
    double ewma_young_objects_dead;
    double ewma_young_objects_skipped; // Note: Here "young" refers to the young update; objects skipped includes non-young objects

    double ewma_objects_alive;
    double ewma_objects_dead;
    double ewma_objects_skipped;
  } stats_lifetime;
};

typedef struct {
  heap_recorder *heap_recorder;
  ddog_prof_Slice_Location locations;
} end_heap_allocation_args;

static heap_record* get_or_create_heap_record(heap_recorder*, ddog_prof_Slice_Location);
static void cleanup_heap_record_if_unused(heap_recorder*, heap_record*);
static void on_committed_object_record_cleanup(heap_recorder *heap_recorder, object_record *record);
static int st_heap_record_entry_free(st_data_t, st_data_t, st_data_t);
static int st_object_record_entry_free(st_data_t, st_data_t, st_data_t);
static int st_object_record_update(st_data_t, st_data_t, st_data_t);
static int st_object_records_iterate(st_data_t, st_data_t, st_data_t);
static int st_object_records_debug(st_data_t key, st_data_t value, st_data_t extra);
static int update_object_record_entry(st_data_t*, st_data_t*, st_data_t, int);
static void commit_recording(heap_recorder *, heap_record *, object_record *active_recording);
static VALUE end_heap_allocation_recording(VALUE end_heap_allocation_args);
static void heap_recorder_update(heap_recorder *heap_recorder, bool full_update);
static inline double ewma_stat(double previous, double current);
static void unintern_or_raise(heap_recorder *, ddog_prof_ManagedStringId);
static void unintern_all_or_raise(heap_recorder *recorder, ddog_prof_Slice_ManagedStringId ids);
static VALUE get_ruby_string_or_raise(heap_recorder*, ddog_prof_ManagedStringId);

// ==========================
// Heap Recorder External API
//
// WARN: All these APIs should support receiving a NULL heap_recorder, resulting in a noop.
//
// WARN: Except for ::heap_recorder_for_each_live_object, we always assume interaction with these APIs
// happens under the GVL.
//
// ==========================
heap_recorder* heap_recorder_new(ddog_prof_ManagedStringStorage string_storage) {
  heap_recorder *recorder = ruby_xcalloc(1, sizeof(heap_recorder));

  recorder->heap_records = st_init_table(&st_hash_type_heap_record);
  recorder->object_records = st_init_numtable();
  recorder->object_records_snapshot = NULL;
  recorder->reusable_locations = ruby_xcalloc(REUSABLE_LOCATIONS_SIZE, sizeof(ddog_prof_Location));
  recorder->reusable_ids = ruby_xcalloc(REUSABLE_FRAME_DETAILS_SIZE, sizeof(ddog_prof_ManagedStringId));
  recorder->reusable_char_slices = ruby_xcalloc(REUSABLE_FRAME_DETAILS_SIZE, sizeof(ddog_CharSlice));
  recorder->active_recording = NULL;
  recorder->size_enabled = true;
  recorder->sample_rate = 1; // By default do no sampling on top of what allocation profiling already does
  recorder->string_storage = string_storage;

  return recorder;
}

void heap_recorder_free(heap_recorder *heap_recorder) {
  if (heap_recorder == NULL) {
    return;
  }

  if (heap_recorder->object_records_snapshot != NULL) {
    // if there's an unfinished iteration, clean it up now
    // before we clean up any other state it might depend on
    heap_recorder_finish_iteration(heap_recorder);
  }

  // Clean-up all object records
  st_foreach(heap_recorder->object_records, st_object_record_entry_free, (st_data_t) heap_recorder);
  st_free_table(heap_recorder->object_records);

  // Clean-up all heap records (this includes those only referred to by queued_samples)
  st_foreach(heap_recorder->heap_records, st_heap_record_entry_free, (st_data_t) heap_recorder);
  st_free_table(heap_recorder->heap_records);

  if (heap_recorder->active_recording != NULL && heap_recorder->active_recording != &SKIPPED_RECORD) {
    // If there's a partial object record, clean it up as well
    object_record_free(heap_recorder, heap_recorder->active_recording);
  }

  ruby_xfree(heap_recorder->reusable_locations);
  ruby_xfree(heap_recorder->reusable_ids);
  ruby_xfree(heap_recorder->reusable_char_slices);

  ruby_xfree(heap_recorder);
}

void heap_recorder_set_size_enabled(heap_recorder *heap_recorder, bool size_enabled) {
  if (heap_recorder == NULL) {
    return;
  }

  heap_recorder->size_enabled = size_enabled;
}

void heap_recorder_set_sample_rate(heap_recorder *heap_recorder, int sample_rate) {
  if (heap_recorder == NULL) {
    return;
  }

  if (sample_rate <= 0) {
    rb_raise(rb_eArgError, "Heap sample rate must be a positive integer value but was %d", sample_rate);
  }

  heap_recorder->sample_rate = sample_rate;
  heap_recorder->num_recordings_skipped = 0;
}

// WARN: Assumes this gets called before profiler is reinitialized on the fork
void heap_recorder_after_fork(heap_recorder *heap_recorder) {
  if (heap_recorder == NULL) {
    return;
  }

  // When forking, the child process gets a copy of the entire state of the parent process, minus
  // threads.
  //
  // This means anything the heap recorder is tracking will still be alive after the fork and
  // should thus be kept. Because this heap recorder implementation does not rely on free
  // tracepoints to track liveness, any frees that happen until we fully reinitialize, will
  // simply be noticed on next heap_recorder_prepare_iteration.
  //
  // There is one small caveat though: fork only preserves one thread and in a Ruby app, that
  // will be the thread holding on to the GVL. Since we support iteration on the heap recorder
  // outside of the GVL, any state specific to that interaction may be inconsistent after fork
  // (e.g. an acquired lock for thread safety). Iteration operates on object_records_snapshot
  // though and that one will be updated on next heap_recorder_prepare_iteration so we really
  // only need to finish any iteration that might have been left unfinished.
  if (heap_recorder->object_records_snapshot != NULL) {
    heap_recorder_finish_iteration(heap_recorder);
  }

  // Clear lifetime stats since this is essentially a new heap recorder
  heap_recorder->stats_lifetime = (struct stats_lifetime) {0};
}

void start_heap_allocation_recording(heap_recorder *heap_recorder, VALUE new_obj, unsigned int weight, ddog_CharSlice alloc_class) {
  if (heap_recorder == NULL) {
    return;
  }

  if (heap_recorder->active_recording != NULL) {
    rb_raise(rb_eRuntimeError, "Detected consecutive heap allocation recording starts without end.");
  }

  if (++heap_recorder->num_recordings_skipped < heap_recorder->sample_rate ||
      #ifdef NO_IMEMO_OBJECT_ID
        // On Ruby 3.5, we can't ask the object_id from IMEMOs (https://github.com/ruby/ruby/pull/13347)
        RB_BUILTIN_TYPE(new_obj) == RUBY_T_IMEMO
      #else
        false
      #endif
      // If we got really unlucky and an allocation showed up during an update (because it triggered an allocation
      // directly OR because the GVL got released in the middle of an update), let's skip this sample as well.
      // See notes on `heap_recorder_update` for details.
      || heap_recorder->updating
    ) {
    heap_recorder->active_recording = &SKIPPED_RECORD;
    return;
  }

  heap_recorder->num_recordings_skipped = 0;

  VALUE ruby_obj_id = rb_obj_id(new_obj);
  if (!FIXNUM_P(ruby_obj_id)) {
    rb_raise(rb_eRuntimeError, "Detected a bignum object id. These are not supported by heap profiling.");
  }

  heap_recorder->active_recording = object_record_new(
    FIX2LONG(ruby_obj_id),
    NULL,
    (live_object_data) {
      .weight = weight * heap_recorder->sample_rate,
      .class = intern_or_raise(heap_recorder->string_storage, alloc_class),
      .alloc_gen = rb_gc_count(),
    }
  );
}

// end_heap_allocation_recording_with_rb_protect gets called while the stack_recorder is holding one of the profile
// locks. To enable us to correctly unlock the profile on exception, we wrap the call to end_heap_allocation_recording
// with an rb_protect.
__attribute__((warn_unused_result))
int end_heap_allocation_recording_with_rb_protect(heap_recorder *heap_recorder, ddog_prof_Slice_Location locations) {
  if (heap_recorder == NULL) {
    return 0;
  }
  if (heap_recorder->active_recording == &SKIPPED_RECORD) {
    // Short circuit, in this case there's nothing to be done
    heap_recorder->active_recording = NULL;
    return 0;
  }


  int exception_state;
  end_heap_allocation_args args = {
    .heap_recorder = heap_recorder,
    .locations = locations,
  };
  rb_protect(end_heap_allocation_recording, (VALUE) &args, &exception_state);
  return exception_state;
}

static VALUE end_heap_allocation_recording(VALUE protect_args) {
  end_heap_allocation_args *args = (end_heap_allocation_args *) protect_args;

  heap_recorder *heap_recorder = args->heap_recorder;
  ddog_prof_Slice_Location locations = args->locations;

  object_record *active_recording = heap_recorder->active_recording;

  if (active_recording == NULL) {
    // Recording ended without having been started?
    rb_raise(rb_eRuntimeError, "Ended a heap recording that was not started");
  }
  // From now on, mark the global active recording as invalid so we can short-circuit at any point
  // and not end up with a still active recording. the local active_recording still holds the
  // data required for committing though.
  heap_recorder->active_recording = NULL;

  if (active_recording == &SKIPPED_RECORD) { // special marker when we decided to skip due to sampling
    // Note: Remember to update the short circuit in end_heap_allocation_recording_with_rb_protect if this logic changes
    return Qnil;
  }

  heap_record *heap_record = get_or_create_heap_record(heap_recorder, locations);

  // And then commit the new allocation.
  commit_recording(heap_recorder, heap_record, active_recording);

  return Qnil;
}

void heap_recorder_update_young_objects(heap_recorder *heap_recorder) {
  if (heap_recorder == NULL) {
    return;
  }

  heap_recorder_update(heap_recorder, /* full_update: */ false);
}

// NOTE: This function needs and assumes it gets called with the GVL being held.
//       But importantly **some of the operations inside `st_object_record_update` may cause a thread switch**,
//       so we can't assume a single update happens in a single "atomic" step -- other threads may get some running time
//       in the meanwhile.
static void heap_recorder_update(heap_recorder *heap_recorder, bool full_update) {
  if (heap_recorder->updating) {
    if (full_update) {
      // There's another thread that's already doing an update :(
      //
      // Because there's a lock on the `StackRecorder` (see @no_concurrent_serialize_mutex) then it's not possible that
      // the other update is a full update.
      // Thus we expect is happening is that the GVL got released by the other thread in the middle of a non-full update
      // and the scheduler thread decided now was a great time to serialize the profile.
      //
      // So, let's yield the time on the current thread until Ruby goes back to the other thread doing the update and
      // it finishes cleanly.
      while (heap_recorder->updating) { rb_thread_schedule(); }
    } else {
      // Non-full updates are optional, so let's walk away
      heap_recorder->stats_lifetime.updates_skipped_concurrent++;
      return;
    }
  }

  if (heap_recorder->object_records_snapshot != NULL) {
    // While serialization is happening, it runs without the GVL and uses the object_records_snapshot.
    // Although we iterate on a snapshot of object_records, these records point to other data that has not been
    // snapshotted for efficiency reasons (e.g. heap_records). Since updating may invalidate
    // some of that non-snapshotted data, let's refrain from doing updates during iteration. This also enforces the
    // semantic that iteration will operate as a point-in-time snapshot.
    return;
  }

  size_t current_gc_gen = rb_gc_count();
  long now_ns = monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE);

  if (!full_update) {
    if (current_gc_gen == heap_recorder->update_gen) {
      // Are we still in the same GC gen as last update? If so, skip updating since things should not have
      // changed significantly since last time.
      // NOTE: This is mostly a performance decision. I suppose some objects may be cleaned up in intermediate
      // GC steps and sizes may change. But because we have to iterate through all our tracked
      // object records to do an update, let's wait until all steps for a particular GC generation
      // have finished to do so. We may revisit this once we have a better liveness checking mechanism.
      heap_recorder->stats_lifetime.updates_skipped_gcgen++;
      return;
    }

    if (now_ns > 0 && (now_ns - heap_recorder->last_update_ns) < MIN_TIME_BETWEEN_HEAP_RECORDER_UPDATES_NS) {
      // We did an update not too long ago. Let's skip this one to avoid over-taxing the system.
      heap_recorder->stats_lifetime.updates_skipped_time++;
      return;
    }
  }

  heap_recorder->updating = true;
  // Reset last update stats, we'll be building them from scratch during the st_foreach call below
  heap_recorder->stats_last_update = (struct stats_last_update) {0};

  heap_recorder->update_gen = current_gc_gen;
  heap_recorder->update_include_old = full_update;

  st_foreach(heap_recorder->object_records, st_object_record_update, (st_data_t) heap_recorder);

  heap_recorder->last_update_ns = now_ns;
  heap_recorder->stats_lifetime.updates_successful++;

  // Lifetime stats updating
  if (!full_update) {
    heap_recorder->stats_lifetime.ewma_young_objects_alive = ewma_stat(heap_recorder->stats_lifetime.ewma_young_objects_alive, heap_recorder->stats_last_update.objects_alive);
    heap_recorder->stats_lifetime.ewma_young_objects_dead = ewma_stat(heap_recorder->stats_lifetime.ewma_young_objects_dead, heap_recorder->stats_last_update.objects_dead);
    heap_recorder->stats_lifetime.ewma_young_objects_skipped = ewma_stat(heap_recorder->stats_lifetime.ewma_young_objects_skipped, heap_recorder->stats_last_update.objects_skipped);
  } else {
    heap_recorder->stats_lifetime.ewma_objects_alive = ewma_stat(heap_recorder->stats_lifetime.ewma_objects_alive, heap_recorder->stats_last_update.objects_alive);
    heap_recorder->stats_lifetime.ewma_objects_dead = ewma_stat(heap_recorder->stats_lifetime.ewma_objects_dead, heap_recorder->stats_last_update.objects_dead);
    heap_recorder->stats_lifetime.ewma_objects_skipped = ewma_stat(heap_recorder->stats_lifetime.ewma_objects_skipped, heap_recorder->stats_last_update.objects_skipped);
  }

  heap_recorder->updating = false;
}

void heap_recorder_prepare_iteration(heap_recorder *heap_recorder) {
  if (heap_recorder == NULL) {
    return;
  }

  if (heap_recorder->object_records_snapshot != NULL) {
    // we could trivially handle this but we raise to highlight and catch unexpected usages.
    rb_raise(rb_eRuntimeError, "New heap recorder iteration prepared without the previous one having been finished.");
  }

  heap_recorder_update(heap_recorder, /* full_update: */ true);

  heap_recorder->object_records_snapshot = st_copy(heap_recorder->object_records);
  if (heap_recorder->object_records_snapshot == NULL) {
    rb_raise(rb_eRuntimeError, "Failed to create heap snapshot.");
  }
}

void heap_recorder_finish_iteration(heap_recorder *heap_recorder) {
  if (heap_recorder == NULL) {
    return;
  }

  if (heap_recorder->object_records_snapshot == NULL) {
    // we could trivially handle this but we raise to highlight and catch unexpected usages.
    rb_raise(rb_eRuntimeError, "Heap recorder iteration finished without having been prepared.");
  }

  st_free_table(heap_recorder->object_records_snapshot);
  heap_recorder->object_records_snapshot = NULL;
}

// Internal data we need while performing iteration over live objects.
typedef struct {
  // The callback we need to call for each object.
  bool (*for_each_callback)(heap_recorder_iteration_data stack_data, void *extra_arg);
  // The extra arg to pass as the second parameter to the callback.
  void *for_each_callback_extra_arg;
  // A reference to the heap recorder so we can access extra stuff like reusable_locations.
  heap_recorder *heap_recorder;
} iteration_context;

// WARN: Assume iterations can run without the GVL for performance reasons. Do not raise, allocate or
// do NoGVL-unsafe interactions with the Ruby runtime. Any such interactions should be done during
// heap_recorder_prepare_iteration or heap_recorder_finish_iteration.
bool heap_recorder_for_each_live_object(
    heap_recorder *heap_recorder,
    bool (*for_each_callback)(heap_recorder_iteration_data stack_data, void *extra_arg),
    void *for_each_callback_extra_arg) {
  if (heap_recorder == NULL) {
    return true;
  }

  if (heap_recorder->object_records_snapshot == NULL) {
    return false;
  }

  iteration_context context;
  context.for_each_callback = for_each_callback;
  context.for_each_callback_extra_arg = for_each_callback_extra_arg;
  context.heap_recorder = heap_recorder;
  st_foreach(heap_recorder->object_records_snapshot, st_object_records_iterate, (st_data_t) &context);
  return true;
}

VALUE heap_recorder_state_snapshot(heap_recorder *heap_recorder) {
  VALUE arguments[] = {
    ID2SYM(rb_intern("num_object_records")), /* => */ LONG2NUM(heap_recorder->object_records->num_entries),
    ID2SYM(rb_intern("num_heap_records")),   /* => */ LONG2NUM(heap_recorder->heap_records->num_entries),

    // Stats as of last update
    ID2SYM(rb_intern("last_update_objects_alive")), /* => */ LONG2NUM(heap_recorder->stats_last_update.objects_alive),
    ID2SYM(rb_intern("last_update_objects_dead")), /* => */ LONG2NUM(heap_recorder->stats_last_update.objects_dead),
    ID2SYM(rb_intern("last_update_objects_skipped")), /* => */ LONG2NUM(heap_recorder->stats_last_update.objects_skipped),
    ID2SYM(rb_intern("last_update_objects_frozen")), /* => */ LONG2NUM(heap_recorder->stats_last_update.objects_frozen),

    // Lifetime stats
    ID2SYM(rb_intern("lifetime_updates_successful")), /* => */ LONG2NUM(heap_recorder->stats_lifetime.updates_successful),
    ID2SYM(rb_intern("lifetime_updates_skipped_concurrent")), /* => */ LONG2NUM(heap_recorder->stats_lifetime.updates_skipped_concurrent),
    ID2SYM(rb_intern("lifetime_updates_skipped_gcgen")), /* => */ LONG2NUM(heap_recorder->stats_lifetime.updates_skipped_gcgen),
    ID2SYM(rb_intern("lifetime_updates_skipped_time")), /* => */ LONG2NUM(heap_recorder->stats_lifetime.updates_skipped_time),
    ID2SYM(rb_intern("lifetime_ewma_young_objects_alive")), /* => */ DBL2NUM(heap_recorder->stats_lifetime.ewma_young_objects_alive),
    ID2SYM(rb_intern("lifetime_ewma_young_objects_dead")), /* => */ DBL2NUM(heap_recorder->stats_lifetime.ewma_young_objects_dead),
      // Note: Here "young" refers to the young update; objects skipped includes non-young objects
    ID2SYM(rb_intern("lifetime_ewma_young_objects_skipped")), /* => */ DBL2NUM(heap_recorder->stats_lifetime.ewma_young_objects_skipped),
    ID2SYM(rb_intern("lifetime_ewma_objects_alive")), /* => */ DBL2NUM(heap_recorder->stats_lifetime.ewma_objects_alive),
    ID2SYM(rb_intern("lifetime_ewma_objects_dead")), /* => */ DBL2NUM(heap_recorder->stats_lifetime.ewma_objects_dead),
    ID2SYM(rb_intern("lifetime_ewma_objects_skipped")), /* => */ DBL2NUM(heap_recorder->stats_lifetime.ewma_objects_skipped),
  };
  VALUE hash = rb_hash_new();
  for (long unsigned int i = 0; i < VALUE_COUNT(arguments); i += 2) rb_hash_aset(hash, arguments[i], arguments[i+1]);
  return hash;
}

typedef struct {
  heap_recorder *recorder;
  VALUE debug_str;
} debug_context;

VALUE heap_recorder_testonly_debug(heap_recorder *heap_recorder) {
  if (heap_recorder == NULL) {
    rb_raise(rb_eArgError, "heap_recorder is NULL");
  }

  VALUE debug_str = rb_str_new2("object records:\n");
  debug_context context = (debug_context) {.recorder = heap_recorder, .debug_str = debug_str};
  st_foreach(heap_recorder->object_records, st_object_records_debug, (st_data_t) &context);

  rb_str_catf(debug_str, "state snapshot: %"PRIsVALUE"\n------\n", heap_recorder_state_snapshot(heap_recorder));

  return debug_str;
}

// ==========================
// Heap Recorder Internal API
// ==========================
static int st_heap_record_entry_free(st_data_t key, DDTRACE_UNUSED st_data_t value, st_data_t extra_arg) {
  heap_recorder *recorder = (heap_recorder *) extra_arg;
  heap_record_free(recorder, (heap_record *) key);
  return ST_DELETE;
}

static int st_object_record_entry_free(DDTRACE_UNUSED st_data_t key, st_data_t value, st_data_t extra_arg) {
  heap_recorder *recorder = (heap_recorder *) extra_arg;
  object_record_free(recorder, (object_record *) value);
  return ST_DELETE;
}

// NOTE: Some operations inside this function can cause the GVL to be released! Plan accordingly.
static int st_object_record_update(st_data_t key, st_data_t value, st_data_t extra_arg) {
  long obj_id = (long) key;
  object_record *record = (object_record*) value;
  heap_recorder *recorder = (heap_recorder*) extra_arg;

  VALUE ref;

  size_t update_gen = recorder->update_gen;
  size_t alloc_gen = record->object_data.alloc_gen;
  // Guard against potential overflows given unsigned types here.
  record->object_data.gen_age = alloc_gen < update_gen ? update_gen - alloc_gen : 0;

  if (record->object_data.gen_age == 0) {
    // Objects that belong to the current GC gen have not had a chance to be cleaned up yet
    // and won't show up in the iteration anyway so no point in checking their liveness/sizes.
    recorder->stats_last_update.objects_skipped++;
    return ST_CONTINUE;
  }

  if (!recorder->update_include_old && record->object_data.gen_age >= OLD_AGE) {
    // The current update is not including old objects but this record is for an old object, skip its update.
    recorder->stats_last_update.objects_skipped++;
    return ST_CONTINUE;
  }

  if (!ruby_ref_from_id(LONG2NUM(obj_id), &ref)) { // Note: This function call can cause the GVL to be released
    // Id no longer associated with a valid ref. Need to delete this object record!
    on_committed_object_record_cleanup(recorder, record);
    recorder->stats_last_update.objects_dead++;
    return ST_DELETE;
  }

  // If we got this far, then we found a valid live object for the tracked id.

  if (
    recorder->size_enabled &&
    recorder->update_include_old && // We only update sizes when doing a full update
    !record->object_data.is_frozen
  ) {
    // if we were asked to update sizes and this object was not already seen as being frozen,
    // update size again.
    record->object_data.size = ruby_obj_memsize_of(ref); // Note: This function call can cause the GVL to be released... maybe?
                                                         //       (With T_DATA for instance, since it can be a custom method supplied by extensions)
    // Check if it's now frozen so we skip a size update next time
    record->object_data.is_frozen = RB_OBJ_FROZEN(ref);
  }

  // Ensure that ref is kept on the stack so the Ruby garbage collector does not try to clean up the object before this
  // point.
  RB_GC_GUARD(ref);

  recorder->stats_last_update.objects_alive++;
  if (record->object_data.is_frozen) {
    recorder->stats_last_update.objects_frozen++;
  }

  return ST_CONTINUE;
}

// WARN: This can get called outside the GVL. NO HEAP ALLOCATIONS OR EXCEPTIONS ARE ALLOWED.
static int st_object_records_iterate(DDTRACE_UNUSED st_data_t key, st_data_t value, st_data_t extra) {
  object_record *record = (object_record*) value;
  const heap_record *stack = record->heap_record;
  iteration_context *context = (iteration_context*) extra;

  const heap_recorder *recorder = context->heap_recorder;

  if (record->object_data.gen_age < ITERATION_MIN_AGE) {
    // Skip objects that should not be included in iteration
    return ST_CONTINUE;
  }

  ddog_prof_Location *locations = recorder->reusable_locations;
  for (uint16_t i = 0; i < stack->frames_len; i++) {
    const heap_frame *frame = &stack->frames[i];
    locations[i] = (ddog_prof_Location) {
      .mapping = {.filename = DDOG_CHARSLICE_C(""), .build_id = DDOG_CHARSLICE_C(""), .build_id_id = {}},
      .function = {
        .name = DDOG_CHARSLICE_C(""),
        .name_id = frame->name,
        .filename = DDOG_CHARSLICE_C(""),
        .filename_id = frame->filename,
      },
      .line = frame->line,
    };
  }

  heap_recorder_iteration_data iteration_data;
  iteration_data.object_data = record->object_data;
  iteration_data.locations = (ddog_prof_Slice_Location) {.ptr = locations, .len = stack->frames_len};

  // This is expected to be StackRecorder's add_heap_sample_to_active_profile_without_gvl
  if (!context->for_each_callback(iteration_data, context->for_each_callback_extra_arg)) {
    return ST_STOP;
  }

  return ST_CONTINUE;
}

static int st_object_records_debug(DDTRACE_UNUSED st_data_t key, st_data_t value, st_data_t extra) {
  debug_context *context = (debug_context*) extra;
  VALUE debug_str = context->debug_str;

  object_record *record = (object_record*) value;

  rb_str_catf(debug_str, "%"PRIsVALUE"\n", object_record_inspect(context->recorder, record));

  return ST_CONTINUE;
}

static int update_object_record_entry(DDTRACE_UNUSED st_data_t *key, st_data_t *value, st_data_t new_object_record, int existing) {
  if (!existing) {
    (*value) = (st_data_t) new_object_record; // Expected to be a `object_record *`
  } else {
    // If key already existed, we don't touch the existing value, so it can be used for diagnostics
  }
  return ST_CONTINUE;
}

static void commit_recording(heap_recorder *heap_recorder, heap_record *heap_record, object_record *active_recording) {
  // Link the object record with the corresponding heap record. This was the last remaining thing we
  // needed to fully build the object_record.
  active_recording->heap_record = heap_record;
  if (heap_record->num_tracked_objects == UINT32_MAX) {
    rb_raise(rb_eRuntimeError, "Reached maximum number of tracked objects for heap record");
  }
  heap_record->num_tracked_objects++;

  int existing_error = st_update(heap_recorder->object_records, active_recording->obj_id, update_object_record_entry, (st_data_t) active_recording);
  if (existing_error) {
    object_record *existing_record = NULL;
    st_lookup(heap_recorder->object_records, active_recording->obj_id, (st_data_t *) &existing_record);
    if (existing_record == NULL) rb_raise(rb_eRuntimeError, "Unexpected NULL when reading existing record");

    VALUE existing_inspect = object_record_inspect(heap_recorder, existing_record);
    VALUE new_inspect = object_record_inspect(heap_recorder, active_recording);
    rb_raise(rb_eRuntimeError, "Object ids are supposed to be unique. We got 2 allocation recordings with "
      "the same id. previous={%"PRIsVALUE"} new={%"PRIsVALUE"}", existing_inspect, new_inspect);
  }
}

static int update_heap_record_entry_with_new_allocation(st_data_t *key, st_data_t *value, st_data_t data, int existing) {
  heap_record **new_or_existing_record = (heap_record **) data;
  (*new_or_existing_record) = (heap_record *) (*key);

  if (!existing) {
    (*value) = (st_data_t) true; // We're only using this hash as a set
  }

  return ST_CONTINUE;
}

static heap_record* get_or_create_heap_record(heap_recorder *heap_recorder, ddog_prof_Slice_Location locations) {
  // See note on "heap_records" definition for why we keep this map.
  heap_record *stack = heap_record_new(heap_recorder, locations);

  heap_record *new_or_existing_record = NULL; // Will be set inside update_heap_record_entry_with_new_allocation
  bool existing = st_update(heap_recorder->heap_records, (st_data_t) stack, update_heap_record_entry_with_new_allocation, (st_data_t) &new_or_existing_record);
  if (existing) {
    heap_record_free(heap_recorder, stack);
  }

  return new_or_existing_record;
}

static void cleanup_heap_record_if_unused(heap_recorder *heap_recorder, heap_record *heap_record) {
  if (heap_record->num_tracked_objects > 0) {
    // still being used! do nothing...
    return;
  }

  if (!st_delete(heap_recorder->heap_records, (st_data_t*) &heap_record, NULL)) {
    rb_raise(rb_eRuntimeError, "Attempted to cleanup an untracked heap_record");
  };
  heap_record_free(heap_recorder, heap_record);
}

static void on_committed_object_record_cleanup(heap_recorder *heap_recorder, object_record *record) {
  // @ivoanjo: We've seen a segfault crash in the field in this function (October 2024) which we're still trying to investigate.
  // (See PROF-10656 Datadog-internal for details). Just in case, I've sprinkled a bunch of NULL tests in this function for now.
  // Once we figure out the issue we can get rid of them again.

  if (heap_recorder == NULL) rb_raise(rb_eRuntimeError, "heap_recorder was NULL in on_committed_object_record_cleanup");
  if (heap_recorder->heap_records == NULL) rb_raise(rb_eRuntimeError, "heap_recorder->heap_records was NULL in on_committed_object_record_cleanup");
  if (record == NULL) rb_raise(rb_eRuntimeError, "record was NULL in on_committed_object_record_cleanup");

  // Starting with the associated heap record. There will now be one less tracked object pointing to it
  heap_record *heap_record = record->heap_record;

  if (heap_record == NULL) rb_raise(rb_eRuntimeError, "heap_record was NULL in on_committed_object_record_cleanup");

  heap_record->num_tracked_objects--;

  // One less object using this heap record, it may have become unused...
  cleanup_heap_record_if_unused(heap_recorder, heap_record);

  object_record_free(heap_recorder, record);
}

// =================
// Object Record API
// =================
object_record* object_record_new(long obj_id, heap_record *heap_record, live_object_data object_data) {
  object_record *record = calloc(1, sizeof(object_record)); // See "note on calloc vs ruby_xcalloc use" above
  record->obj_id = obj_id;
  record->heap_record = heap_record;
  record->object_data = object_data;
  return record;
}

void object_record_free(heap_recorder *recorder, object_record *record) {
  unintern_or_raise(recorder, record->object_data.class);
  free(record); // See "note on calloc vs ruby_xcalloc use" above
}

VALUE object_record_inspect(heap_recorder *recorder, object_record *record) {
  heap_frame top_frame = record->heap_record->frames[0];
  VALUE filename = get_ruby_string_or_raise(recorder, top_frame.filename);
  live_object_data object_data = record->object_data;

  VALUE inspect = rb_sprintf("obj_id=%ld weight=%d size=%zu location=%"PRIsVALUE":%d alloc_gen=%zu gen_age=%zu frozen=%d ",
      record->obj_id, object_data.weight, object_data.size, filename,
      (int) top_frame.line, object_data.alloc_gen, object_data.gen_age, object_data.is_frozen);

  if (record->object_data.class.value > 0) {
    VALUE class = get_ruby_string_or_raise(recorder, record->object_data.class);

    rb_str_catf(inspect, "class=%"PRIsVALUE" ", class);
  }
  VALUE ref;

  if (!ruby_ref_from_id(LONG2NUM(record->obj_id), &ref)) {
    rb_str_catf(inspect, "object=<invalid>");
  } else {
    rb_str_catf(inspect, "value=%p ", (void *) ref);
    VALUE ruby_inspect = ruby_safe_inspect(ref);
    if (ruby_inspect != Qnil) {
      rb_str_catf(inspect, "object=%"PRIsVALUE, ruby_inspect);
    } else {
      rb_str_catf(inspect, "object=%s", ruby_value_type_to_string(rb_type(ref)));
    }
  }

  return inspect;
}

// ==============
// Heap Record API
// ==============
heap_record* heap_record_new(heap_recorder *recorder, ddog_prof_Slice_Location locations) {
  uint16_t frames_len = locations.len;
  if (frames_len > MAX_FRAMES_LIMIT) {
    // This is not expected as MAX_FRAMES_LIMIT is shared with the stacktrace construction mechanism
    rb_raise(rb_eRuntimeError, "Found stack with more than %d frames (%d)", MAX_FRAMES_LIMIT, frames_len);
  }
  heap_record *stack = calloc(1, sizeof(heap_record) + frames_len * sizeof(heap_frame)); // See "note on calloc vs ruby_xcalloc use" above
  stack->num_tracked_objects = 0;
  stack->frames_len = frames_len;

  // Intern all these strings...
  ddog_CharSlice *strings = recorder->reusable_char_slices;
  // Put all the char slices in the same array; we'll pull them out in the same order from the ids array
  for (uint16_t i = 0; i < stack->frames_len; i++) {
    const ddog_prof_Location *location = &locations.ptr[i];
    strings[i] = location->function.filename;
    strings[i + stack->frames_len] = location->function.name;
  }
  intern_all_or_raise(recorder->string_storage, (ddog_prof_Slice_CharSlice) { .ptr = strings, .len = stack->frames_len * 2 }, recorder->reusable_ids, stack->frames_len * 2);

  // ...and record them for later use
  for (uint16_t i = 0; i < stack->frames_len; i++) {
    stack->frames[i] = (heap_frame) {
      .filename = recorder->reusable_ids[i],
      .name = recorder->reusable_ids[i + stack->frames_len],
      // ddog_prof_Location is a int64_t. We don't expect to have to profile files with more than
      // 2M lines so this cast should be fairly safe?
      .line = (int32_t) locations.ptr[i].line,
    };
  }

  return stack;
}

void heap_record_free(heap_recorder *recorder, heap_record *stack) {
  ddog_prof_ManagedStringId *ids = recorder->reusable_ids;

  // Put all the ids in the same array; doesn't really matter the order
  for (u_int16_t i = 0; i < stack->frames_len; i++) {
    ids[i] = stack->frames[i].filename;
    ids[i + stack->frames_len] = stack->frames[i].name;
  }
  unintern_all_or_raise(recorder, (ddog_prof_Slice_ManagedStringId) { .ptr = ids, .len = stack->frames_len * 2 });

  free(stack); // See "note on calloc vs ruby_xcalloc use" above
}

// The entire stack is represented by ids (name, filename) and lines (integers) so we can treat is as just
// a big string of bytes and compare it all in one go.
int heap_record_cmp_st(st_data_t key1, st_data_t key2) {
  heap_record *stack1 = (heap_record*) key1;
  heap_record *stack2 = (heap_record*) key2;

  if (stack1->frames_len != stack2->frames_len) {
    return ((int) stack1->frames_len) - ((int) stack2->frames_len);
  } else {
    return memcmp(stack1->frames, stack2->frames, stack1->frames_len * sizeof(heap_frame));
  }
}

// Initial seed for hash function, same as Ruby uses
#define FNV1_32A_INIT 0x811c9dc5

// The entire stack is represented by ids (name, filename) and lines (integers) so we can treat is as just
// a big string of bytes and hash it all in one go.
st_index_t heap_record_hash_st(st_data_t key) {
  heap_record *stack = (heap_record*) key;
  return st_hash(stack->frames, stack->frames_len * sizeof(heap_frame), FNV1_32A_INIT);
}

static void unintern_or_raise(heap_recorder *recorder, ddog_prof_ManagedStringId id) {
  if (id.value == 0) return; // Empty string, nothing to do

  ddog_prof_MaybeError result = ddog_prof_ManagedStringStorage_unintern(recorder->string_storage, id);
  if (result.tag == DDOG_PROF_OPTION_ERROR_SOME_ERROR) {
    rb_raise(rb_eRuntimeError, "Failed to unintern id: %"PRIsVALUE, get_error_details_and_drop(&result.some));
  }
}

static void unintern_all_or_raise(heap_recorder *recorder, ddog_prof_Slice_ManagedStringId ids) {
  ddog_prof_MaybeError result = ddog_prof_ManagedStringStorage_unintern_all(recorder->string_storage, ids);
  if (result.tag == DDOG_PROF_OPTION_ERROR_SOME_ERROR) {
    rb_raise(rb_eRuntimeError, "Failed to unintern_all: %"PRIsVALUE, get_error_details_and_drop(&result.some));
  }
}

static VALUE get_ruby_string_or_raise(heap_recorder *recorder, ddog_prof_ManagedStringId id) {
  ddog_StringWrapperResult get_string_result = ddog_prof_ManagedStringStorage_get_string(recorder->string_storage, id);
  if (get_string_result.tag == DDOG_STRING_WRAPPER_RESULT_ERR) {
    rb_raise(rb_eRuntimeError, "Failed to get string: %"PRIsVALUE, get_error_details_and_drop(&get_string_result.err));
  }
  VALUE ruby_string = ruby_string_from_vec_u8(get_string_result.ok.message);
  ddog_StringWrapper_drop((ddog_StringWrapper *) &get_string_result.ok);

  return ruby_string;
}

static inline double ewma_stat(double previous, double current) {
  double alpha = 0.3;
  return (1 - alpha) * previous + alpha * current;
}

VALUE heap_recorder_testonly_is_object_recorded(heap_recorder *heap_recorder, VALUE obj_id) {
  if (heap_recorder == NULL) {
    rb_raise(rb_eArgError, "heap_recorder is NULL");
  }

  // Check if object records contains an object with this object_id
  return st_is_member(heap_recorder->object_records, FIX2LONG(obj_id)) ? Qtrue : Qfalse;
}

void heap_recorder_testonly_reset_last_update(heap_recorder *heap_recorder) {
  if (heap_recorder == NULL) {
    rb_raise(rb_eArgError, "heap_recorder is NULL");
  }

  heap_recorder->last_update_ns = 0;
}

void heap_recorder_testonly_benchmark_intern(heap_recorder *heap_recorder, ddog_CharSlice string, int times, bool use_all) {
  if (heap_recorder == NULL) rb_raise(rb_eArgError, "heap profiling must be enabled");
  if (times > REUSABLE_FRAME_DETAILS_SIZE) rb_raise(rb_eArgError, "times cannot be > than REUSABLE_FRAME_DETAILS_SIZE");

  if (use_all) {
    ddog_CharSlice *strings = heap_recorder->reusable_char_slices;

    for (int i = 0; i < times; i++) strings[i] = string;

    intern_all_or_raise(
      heap_recorder->string_storage,
      (ddog_prof_Slice_CharSlice) { .ptr = strings, .len = times },
      heap_recorder->reusable_ids,
      times
    );
  } else {
    for (int i = 0; i < times; i++) intern_or_raise(heap_recorder->string_storage, string);
  }
}
