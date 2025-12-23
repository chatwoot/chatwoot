#include <ruby.h>
#include <ruby/thread.h>
#include <pthread.h>
#include <stdbool.h>

#include "helpers.h"
#include "ruby_helpers.h"
#include "collectors_idle_sampling_helper.h"

// Used by the Collectors::CpuAndWallTimeWorker to gather samples when the Ruby process is idle.
//
// Specifically, the IdleSamplingHelper is expected to be triggered by the CpuAndWallTimeWorker whenever it needs to
// trigger a sample, but the VM is otherwise idle. See implementation of CpuAndWallTimeWorker for details.
//
// The IdleSamplingHelper keeps a background thread that waits for functions to run on a single-element "queue".
// Other threads communicate with it by asking it to ACTION_RUN a `requested_action` or ACTION_STOP to terminate.
//
// The state is protected by the `wakeup_mutex`, and the background thread is woken up after changes using the
// `wakeup` condition variable.

typedef enum { ACTION_WAIT, ACTION_RUN, ACTION_STOP } action;

// Contains state for a single CpuAndWallTimeWorker instance
typedef struct {
  pthread_mutex_t wakeup_mutex;
  pthread_cond_t wakeup;
  action requested_action;
  void (*run_action_function)(void);
} idle_sampling_loop_state;

static VALUE _native_new(VALUE klass);
static void reset_state(idle_sampling_loop_state *state);
static VALUE _native_idle_sampling_loop(DDTRACE_UNUSED VALUE self, VALUE self_instance);
static VALUE _native_stop(DDTRACE_UNUSED VALUE self, VALUE self_instance);
static void *run_idle_sampling_loop(void *state_ptr);
static void interrupt_idle_sampling_loop(void *state_ptr);
static VALUE _native_reset(DDTRACE_UNUSED VALUE self, VALUE self_instance);
static VALUE _native_idle_sampling_helper_request_action(DDTRACE_UNUSED VALUE self, VALUE self_instance);
static void *request_testing_action(void *self_instance_ptr);
static void grab_gvl_and_run_testing_action(void);
static void *run_testing_action(DDTRACE_UNUSED void *unused);

void collectors_idle_sampling_helper_init(VALUE profiling_module) {
  VALUE collectors_module = rb_define_module_under(profiling_module, "Collectors");
  VALUE collectors_idle_sampling_helper_class = rb_define_class_under(collectors_module, "IdleSamplingHelper", rb_cObject);
  // Hosts methods used for testing the native code using RSpec
  VALUE testing_module = rb_define_module_under(collectors_idle_sampling_helper_class, "Testing");

  // Instances of the IdleSamplingHelper class are "TypedData" objects.
  // "TypedData" objects are special objects in the Ruby VM that can wrap C structs.
  // In this case, it wraps the idle_sampling_loop_state.
  //
  // Because Ruby doesn't know how to initialize native-level structs, we MUST override the allocation function for objects
  // of this class so that we can manage this part. Not overriding or disabling the allocation function is a common
  // gotcha for "TypedData" objects that can very easily lead to VM crashes, see for instance
  // https://bugs.ruby-lang.org/issues/18007 for a discussion around this.
  rb_define_alloc_func(collectors_idle_sampling_helper_class, _native_new);

  rb_define_singleton_method(collectors_idle_sampling_helper_class, "_native_idle_sampling_loop", _native_idle_sampling_loop, 1);
  rb_define_singleton_method(collectors_idle_sampling_helper_class, "_native_stop", _native_stop, 1);
  rb_define_singleton_method(collectors_idle_sampling_helper_class, "_native_reset", _native_reset, 1);
  rb_define_singleton_method(testing_module, "_native_idle_sampling_helper_request_action", _native_idle_sampling_helper_request_action, 1);
}

// This structure is used to define a Ruby object that stores a pointer to a idle_sampling_loop_state
// See also https://github.com/ruby/ruby/blob/master/doc/extension.rdoc for how this works
static const rb_data_type_t idle_sampling_helper_typed_data = {
  .wrap_struct_name = "Datadog::Profiling::Collectors::IdleSamplingHelper",
  .function = {
    .dmark = NULL, // We don't store references to Ruby objects so we don't need to mark any of them
    .dfree = RUBY_DEFAULT_FREE,
    .dsize = NULL, // We don't track memory usage (although it'd be cool if we did!)
    //.dcompact = NULL, // Not needed -- we don't store references to Ruby objects
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE _native_new(VALUE klass) {
  idle_sampling_loop_state *state = ruby_xcalloc(1, sizeof(idle_sampling_loop_state));

  // Note: Any exceptions raised from this note until the TypedData_Wrap_Struct call will lead to the state memory
  // being leaked.

  reset_state(state);

  // Note: As of this writing, no new Ruby objects get created and stored in the state. If that ever changes, remember
  // to keep them on the stack and mark them with RB_GC_GUARD -- otherwise it's possible for a GC to run and
  // since the instance representing the state does not yet exist, such objects will not get marked.

  return TypedData_Wrap_Struct(klass, &idle_sampling_helper_typed_data, state);
}

static void reset_state(idle_sampling_loop_state *state) {
  state->wakeup_mutex = (pthread_mutex_t) PTHREAD_MUTEX_INITIALIZER;
  state->wakeup = (pthread_cond_t) PTHREAD_COND_INITIALIZER;
  state->requested_action = ACTION_WAIT;
  state->run_action_function = NULL;
}

// The same instance of the IdleSamplingHelper can be reused multiple times, and this resets it back to
// a pristine state before recreating the worker thread (this includes resetting the mutex in case it was left
// locked halfway through the VM forking)
static VALUE _native_reset(DDTRACE_UNUSED VALUE self, VALUE self_instance) {
  idle_sampling_loop_state *state;
  TypedData_Get_Struct(self_instance, idle_sampling_loop_state, &idle_sampling_helper_typed_data, state);

  reset_state(state);

  return Qtrue;
}

static VALUE _native_idle_sampling_loop(DDTRACE_UNUSED VALUE self, VALUE self_instance) {
  idle_sampling_loop_state *state;
  TypedData_Get_Struct(self_instance, idle_sampling_loop_state, &idle_sampling_helper_typed_data, state);

  // Release GVL and run the loop waiting for requests
  rb_thread_call_without_gvl(run_idle_sampling_loop, state, interrupt_idle_sampling_loop, state);

  return Qtrue;
}

static void *run_idle_sampling_loop(void *state_ptr) {
  idle_sampling_loop_state *state = (idle_sampling_loop_state *) state_ptr;
  int error = 0;

  while (true) {
    ENFORCE_SUCCESS_NO_GVL(pthread_mutex_lock(&state->wakeup_mutex));

    action next_action;
    void (*run_action_function)(void);

    // Await for an action
    while ((next_action = state->requested_action) == ACTION_WAIT) {
      error = pthread_cond_wait(&state->wakeup, &state->wakeup_mutex);
      if (error) {
        // If something went wrong, try to leave the mutex unlocked at least
        pthread_mutex_unlock(&state->wakeup_mutex);
        ENFORCE_SUCCESS_NO_GVL(error);
      }
    }

    // There's an action to be taken!

    // Record function, if any
    run_action_function = state->run_action_function;

    // Reset buffer for next request
    state->requested_action = ACTION_WAIT;

    // Unlock the mutex immediately so other threads can continue to request actions without blocking
    ENFORCE_SUCCESS_NO_GVL(pthread_mutex_unlock(&state->wakeup_mutex));

    // Process pending action
    if (next_action == ACTION_RUN) {
      if (run_action_function == NULL) {
        grab_gvl_and_raise(rb_eRuntimeError, "Unexpected NULL run_action_function in run_idle_sampling_loop");
      }

      run_action_function();
    } else { // ACTION_STOP
      return NULL;
    }
  }
}

static void interrupt_idle_sampling_loop(void *state_ptr) {
  idle_sampling_loop_state *state = (idle_sampling_loop_state *) state_ptr;
  int error = 0;

  // Note about the error handling in this situation: Something bad happening at this stage is really really awkward to
  // handle because we get called by the VM in a situation where we can't really raise exceptions, and the VM really really
  // just wants us to stop what we're doing and return control of the thread to it.
  //
  // So if we return immediately on error, we may leave the VM hanging because we didn't actually interrupt the thread.
  // We're also not at a great location to flag errors.
  // That's why: a) I chose to log to stderr, as a last-ditch effort; b) even if something goes wrong we still try to
  // ask the thread to stop, instead of exiting early.

  error = pthread_mutex_lock(&state->wakeup_mutex);
  if (error) { fprintf(stderr, "[ddtrace] Error during pthread_mutex_lock in interrupt_idle_sampling_loop (%s)\n", strerror(error)); }

  state->requested_action = ACTION_STOP;

  error = pthread_mutex_unlock(&state->wakeup_mutex);
  if (error) { fprintf(stderr, "[ddtrace] Error during pthread_mutex_unlock in interrupt_idle_sampling_loop (%s)\n", strerror(error)); }

  error = pthread_cond_broadcast(&state->wakeup);
  if (error) { fprintf(stderr, "[ddtrace] Error during pthread_cond_broadcast in interrupt_idle_sampling_loop (%s)\n", strerror(error)); }
}

static VALUE _native_stop(DDTRACE_UNUSED VALUE self, VALUE self_instance) {
  idle_sampling_loop_state *state;
  TypedData_Get_Struct(self_instance, idle_sampling_loop_state, &idle_sampling_helper_typed_data, state);

  ENFORCE_SUCCESS_GVL(pthread_mutex_lock(&state->wakeup_mutex));
  state->requested_action = ACTION_STOP;
  ENFORCE_SUCCESS_GVL(pthread_mutex_unlock(&state->wakeup_mutex));

  // Wake up worker thread, if needed; It's OK to call broadcast after releasing the mutex
  ENFORCE_SUCCESS_GVL(pthread_cond_broadcast(&state->wakeup));

  return Qtrue;
}

// Assumption: Function gets called without the global VM lock
void idle_sampling_helper_request_action(VALUE self_instance, void (*run_action_function)(void)) {
  idle_sampling_loop_state *state;
  if (!rb_typeddata_is_kind_of(self_instance, &idle_sampling_helper_typed_data)) {
    grab_gvl_and_raise(rb_eTypeError, "Wrong argument for idle_sampling_helper_request_action");
  }
  // This should never fail the the above check passes
  TypedData_Get_Struct(self_instance, idle_sampling_loop_state, &idle_sampling_helper_typed_data, state);

  ENFORCE_SUCCESS_NO_GVL(pthread_mutex_lock(&state->wakeup_mutex));
  if (state->requested_action == ACTION_WAIT) {
    state->requested_action = ACTION_RUN;
    state->run_action_function = run_action_function;
  }
  ENFORCE_SUCCESS_NO_GVL(pthread_mutex_unlock(&state->wakeup_mutex));

  // Wake up worker thread, if needed; It's OK to call broadcast after releasing the mutex
  ENFORCE_SUCCESS_NO_GVL(pthread_cond_broadcast(&state->wakeup));
}

// Because the idle_sampling_helper_request_action is built to be called without the global VM lock, here we release it
// to be able to call that API.
static VALUE _native_idle_sampling_helper_request_action(DDTRACE_UNUSED VALUE self, VALUE self_instance) {
  rb_thread_call_without_gvl(request_testing_action, (void *) self_instance, NULL, NULL);
  return Qtrue;
}

static void *request_testing_action(void *self_instance_ptr) {
  VALUE self_instance = (VALUE) self_instance_ptr;
  idle_sampling_helper_request_action(self_instance, grab_gvl_and_run_testing_action);
  return NULL;
}

// This gets called by the worker thread, which is not holding the global VM lock. To be able to actually run the action,
// we need to acquire it
static void grab_gvl_and_run_testing_action(void) {
  rb_thread_call_with_gvl(run_testing_action, NULL);
}

static void *run_testing_action(DDTRACE_UNUSED void *unused) {
  VALUE idle_sampling_helper_testing_action = rb_gv_get("$idle_sampling_helper_testing_action");
  rb_funcall(idle_sampling_helper_testing_action, rb_intern("call"), 0);
  return NULL;
}
