#pragma once

#include <datadog/profiling.h>
#include <ruby.h>

// A heap recorder keeps track of a collection of live heap objects.
//
// All allocations observed by this recorder for which a corresponding free was
// not yet observed are deemed as alive and can be iterated on to produce a
// live heap profile.
//
// NOTE: All public APIs of heap_recorder support receiving a NULL heap_recorder
//       in which case the behaviour will be a noop.
//
// WARN: Unless otherwise stated the heap recorder APIs assume calls are done
// under the GVL.
typedef struct heap_recorder heap_recorder;

// Extra data associated with each live object being tracked.
typedef struct {
  // The weight of this object from a sampling perspective.
  //
  // A notion of weight is preserved for each tracked object to allow for an approximate
  // extrapolation to an unsampled view.
  //
  // Example: If we were sampling every 50 objects, then each sampled object
  //          could be seen as being representative of 50 objects.
  unsigned int weight;

  // Size of this object in memory.
  // NOTE: This only gets updated during heap_recorder_prepare_iteration and only
  //       for those objects that meet the minimum iteration age requirements.
  size_t size;

  // The class of the object that we're tracking.
  // NOTE: This is optional and will be set to NULL if not set.
  ddog_prof_ManagedStringId class;

  // The GC allocation gen in which we saw this object being allocated.
  //
  // This enables us to calculate the age of this object in terms of GC executions.
  size_t alloc_gen;

  // The age of this object in terms of GC generations.
  // NOTE: This only gets updated during heap_recorder_prepare_iteration
  size_t gen_age;

  // Whether this object was previously seen as being frozen. If this is the case,
  // we'll skip any further size updates since frozen objects are supposed to be
  // immutable.
  bool is_frozen;
} live_object_data;

// Data that is made available to iterators of heap recorder data for each live object
// tracked therein.
typedef struct {
  ddog_prof_Slice_Location locations;
  live_object_data object_data;
} heap_recorder_iteration_data;

// Initialize a new heap recorder.
heap_recorder* heap_recorder_new(ddog_prof_ManagedStringStorage string_storage);

// Free a previously initialized heap recorder.
void heap_recorder_free(heap_recorder *heap_recorder);

// Sets whether this heap recorder should keep track of sizes or not.
//
// If set to true, the heap recorder will attempt to determine the approximate sizes of
// tracked objects and wield them during iteration.
// If set to false, sizes returned during iteration should not be used/relied on (they
// may be 0 or the last determined size before disabling the tracking of sizes).
//
// NOTE: Default is true, i.e., it will attempt to determine approximate sizes of tracked
// objects.
void heap_recorder_set_size_enabled(heap_recorder *heap_recorder, bool size_enabled);

// Set sample rate used by this heap recorder.
//
// Controls how many recordings will be ignored before committing a heap allocation and
// the weight of the committed heap allocation.
//
// A value of 1 will effectively track all objects that are passed through
// start/end_heap_allocation_recording pairs. A value of 10 will only track every 10th
// object passed through such calls and its effective weight for the purposes of heap
// profiling will be multiplied by 10.
//
// NOTE: Default is 1, i.e., track all heap allocation recordings.
//
// WARN: Non-positive values will lead to an exception being thrown.
void heap_recorder_set_sample_rate(heap_recorder *heap_recorder, int sample_rate);

// Do any cleanup needed after forking.
// WARN: Assumes this gets called before profiler is reinitialized on the fork
void heap_recorder_after_fork(heap_recorder *heap_recorder);

// Start a heap allocation recording on the heap recorder for a new object.
//
// This heap allocation recording needs to be ended via ::end_heap_allocation_recording
// before it will become fully committed and able to be iterated on.
//
// @param new_obj
//   The newly allocated Ruby object/value.
// @param weight
//   The sampling weight of this object.
//
// WARN: It needs to be paired with a ::end_heap_allocation_recording call.
void start_heap_allocation_recording(heap_recorder *heap_recorder, VALUE new_obj, unsigned int weight, ddog_CharSlice alloc_class);

// End a previously started heap allocation recording on the heap recorder.
//
// It is at this point that an allocated object will become fully tracked and able to be iterated on.
//
// @param locations The stacktrace representing the location of the allocation.
//
// WARN: It is illegal to call this without previously having called ::start_heap_allocation_recording.
// WARN: This method rescues exceptions with `rb_protect`, returning the exception state integer for the caller to handle.
__attribute__((warn_unused_result))
int end_heap_allocation_recording_with_rb_protect(heap_recorder *heap_recorder, ddog_prof_Slice_Location locations);

// Update the heap recorder, **checking young objects only**. The idea here is to align with GC: most young objects never
// survive enough GC generations, and thus periodically running this method reduces memory usage (we get rid of
// these objects quicker) and hopefully reduces tail latency (because there's less objects at serialization time to check).
void heap_recorder_update_young_objects(heap_recorder *heap_recorder);

// Update the heap recorder to reflect the latest state of the VM and prepare internal structures
// for efficient iteration.
//
// WARN: This must be called strictly before iteration. Failing to do so will result in exceptions.
void heap_recorder_prepare_iteration(heap_recorder *heap_recorder);

// Optimize the heap recorder by cleaning up any data that might have been prepared specifically
// for the purpose of iterating over the heap recorder data.
//
// WARN: This must be called strictly after iteration to ensure proper cleanup and to keep the memory
// profile of the heap recorder low.
void heap_recorder_finish_iteration(heap_recorder *heap_recorder);

// Iterate over each live object being tracked by the heap recorder.
//
// NOTE: Iteration can be called without holding the Ruby Global VM lock.
// WARN: This must be called strictly after heap_recorder_prepare_iteration and before
// heap_recorder_finish_iteration.
//
// @param for_each_callback
//   A callback function that shall be called for each live object being tracked
//   by the heap recorder. Alongside the iteration_data for each live object,
//   a second argument will be forwarded with the contents of the optional
//   for_each_callback_extra_arg. Iteration will continue until the callback
//   returns false or we run out of objects.
// @param for_each_callback_extra_arg
//   Optional (NULL if empty) extra data that should be passed to the
//   callback function alongside the data for each live tracked object.
// @return true if iteration ran, false if something prevented it from running.
bool heap_recorder_for_each_live_object(
    heap_recorder *heap_recorder,
    bool (*for_each_callback)(heap_recorder_iteration_data data, void* extra_arg),
    void *for_each_callback_extra_arg);

// Return a Ruby hash containing a snapshot of this recorder's interesting state at calling time.
// WARN: This allocates in the Ruby VM and therefore should not be called without the
//       VM lock or during GC.
VALUE heap_recorder_state_snapshot(heap_recorder *heap_recorder);

// v--- TEST-ONLY APIs ---v

// Returns a Ruby string with a representation of internal data helpful to
// troubleshoot issues such as unexpected test failures.
VALUE heap_recorder_testonly_debug(heap_recorder *heap_recorder);

// Check if a given object_id is being tracked or not
VALUE heap_recorder_testonly_is_object_recorded(heap_recorder *heap_recorder, VALUE obj_id);

// Used to ensure that a GC actually triggers an update of the objects
void heap_recorder_testonly_reset_last_update(heap_recorder *heap_recorder);

void heap_recorder_testonly_benchmark_intern(heap_recorder *heap_recorder, ddog_CharSlice string, int times, bool use_all);
