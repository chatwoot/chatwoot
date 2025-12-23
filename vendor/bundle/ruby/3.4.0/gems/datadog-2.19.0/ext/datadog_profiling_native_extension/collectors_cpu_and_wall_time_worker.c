#include <ruby.h>
#include <ruby/thread.h>
#include <ruby/thread_native.h>
#include <ruby/debug.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <signal.h>
#include <errno.h>

#include "helpers.h"
#include "ruby_helpers.h"
#include "collectors_thread_context.h"
#include "collectors_dynamic_sampling_rate.h"
#include "collectors_idle_sampling_helper.h"
#include "collectors_discrete_dynamic_sampler.h"
#include "private_vm_api_access.h"
#include "setup_signal_handler.h"
#include "time_helpers.h"

// Used to trigger the execution of Collectors::ThreadContext, which implements all of the sampling logic
// itself; this class only implements the "when to do it" part.
//
// This file implements the native bits of the Datadog::Profiling::Collectors::CpuAndWallTimeWorker class

// ---
// Here be dragons: This component is quite fiddly and probably one of the more complex in the profiler as it deals with
// multiple threads, signal handlers, global state, etc.
//
// ## Design notes for this class:
//
// ### Constraints
//
// Currently, sampling Ruby threads requires calling Ruby VM APIs that are only safe to call while holding on to the
// global VM lock (and are not async-signal safe -- cannot be called from a signal handler).
//
// @ivoanjo: As a note, I don't think we should think of this constraint as set in stone. Since we can reach inside the Ruby
// internals, we may be able to figure out a way of overcoming it. But it's definitely going to be hard so for now
// we're considering it as a given.
//
// ### Flow for triggering CPU/Wall-time samples
//
// The flow for triggering samples is as follows:
//
// 1. Inside the `run_sampling_trigger_loop` function (running in the `CpuAndWallTimeWorker` background thread),
// a `SIGPROF` signal gets sent to the current process.
//
// 2. The `handle_sampling_signal` signal handler function gets called to handle the `SIGPROF` signal.
//
//   Which thread the signal handler function gets called on by the operating system is quite important. We need to perform
// an operation -- calling the `rb_postponed_job_register_one` API -- that can only be called from the thread that
// is holding on to the global VM lock. So this is the thread we're "hoping" our signal lands on.
//
//   The signal never lands on the `CpuAndWallTimeWorker` background thread because we explicitly block it off from that
// thread in `block_sigprof_signal_handler_from_running_in_current_thread`.
//
//   If the signal lands on a thread that is not holding onto the global VM lock, we can't proceed to the next step,
// and we need to restart the sampling flow from step 1. (There's still quite a few improvements we can make here,
// but this is the current state of the implementation).
//
// 3. Inside `handle_sampling_signal`, if it's getting executed by the Ruby thread that is holding the global VM lock,
// we can call `rb_postponed_job_register_one` to ask the Ruby VM to call our `sample_from_postponed_job` function
// "as soon as it can".
//
// 4. The Ruby VM calls our `sample_from_postponed_job` from a thread holding the global VM lock. A sample is recorded by
// calling `thread_context_collector_sample`.
//
// ### TracePoints and Forking
//
// When the Ruby VM forks, the CPU/Wall-time profiling stops naturally because it's triggered by a background thread
// that doesn't get automatically restarted by the VM on the child process. (The profiler does trigger its restart at
// some point -- see `Profiling::Tasks::Setup` for details).
//
// But this doesn't apply to any `TracePoint`s this class may use, which will continue to be active. Thus, we need to
// always remember consider this case of -- the worker thread may not be alive but the `TracePoint`s can continue to
// trigger samples.
//
// ---

#define ERR_CLOCK_FAIL "failed to get clock time"

// Maximum allowed value for an allocation weight. Attempts to use higher values will result in clamping.
// See https://docs.google.com/document/d/1lWLB714wlLBBq6T4xZyAc4a5wtWhSmr4-hgiPKeErlA/edit#heading=h.ugp0zxcj5iqh
// (Datadog-only link) for research backing the choice of this value.
unsigned int MAX_ALLOC_WEIGHT = 10000;

#ifndef NO_POSTPONED_TRIGGER
  // Used to call the rb_postponed_job_trigger from Ruby 3.3+. These get initialized in
  // `collectors_cpu_and_wall_time_worker_init` below and always get reused after that.
  static rb_postponed_job_handle_t sample_from_postponed_job_handle;
  static rb_postponed_job_handle_t after_gc_from_postponed_job_handle;
  static rb_postponed_job_handle_t after_gvl_running_from_postponed_job_handle;
#endif

// Contains state for a single CpuAndWallTimeWorker instance
typedef struct {
  // These are immutable after initialization

  bool gc_profiling_enabled;
  bool no_signals_workaround_enabled;
  bool dynamic_sampling_rate_enabled;
  bool allocation_profiling_enabled;
  bool allocation_counting_enabled;
  bool gvl_profiling_enabled;
  bool skip_idle_samples_for_testing;
  bool sighandler_sampling_enabled;
  VALUE self_instance;
  VALUE thread_context_collector_instance;
  VALUE idle_sampling_helper_instance;
  VALUE owner_thread;
  dynamic_sampling_rate_state cpu_dynamic_sampling_rate;
  discrete_dynamic_sampler allocation_sampler;
  VALUE gc_tracepoint; // Used to get gc start/finish information

  // These are mutable and used to signal things between the worker thread and other threads

  atomic_bool should_run;
  // When something goes wrong during sampling, we record the Ruby exception here, so that it can be "re-raised" on
  // the CpuAndWallTimeWorker thread
  VALUE failure_exception;
  // Used by `_native_stop` to flag the worker thread to start (see comment on `_native_sampling_loop`)
  VALUE stop_thread;

  // Others

  // Used to detect/avoid nested sampling, e.g. when on_newobj_event gets triggered by a memory allocation
  // that happens during another sample, or when the signal handler gets triggered while we're already in the middle of
  // sampling.
  //
  // @ivoanjo: Right now we always sample inside `safely_call`; if that ever changes, this flag may need to become
  // volatile/atomic/have some barriers to ensure it's visible during e.g. signal handlers.
  bool during_sample;

  #ifndef NO_GVL_INSTRUMENTATION
  // Only set when sampling is active (gets created at start and cleaned on stop)
  rb_internal_thread_event_hook_t *gvl_profiling_hook;
  #endif

  struct stats {
    // # Generic stats
    // How many times we tried to trigger a sample
    unsigned int trigger_sample_attempts;
    // How many times we tried to simulate signal delivery
    unsigned int trigger_simulated_signal_delivery_attempts;
    // How many times we actually simulated signal delivery
    unsigned int simulated_signal_delivery;
    // How many times we actually called rb_postponed_job_register_one from the signal handler
    unsigned int signal_handler_enqueued_sample;
    // How many times we prepared a sample (sampled directly) from the signal handler
    unsigned int signal_handler_prepared_sample;
    // How many times the signal handler was called from the wrong thread
    unsigned int signal_handler_wrong_thread;
    // How many times we actually tried to interrupt a thread for sampling
    unsigned int interrupt_thread_attempts;

    // # CPU/Walltime sampling stats
    // How many times we actually CPU/wall sampled
    unsigned int cpu_sampled;
    // How many times we skipped a CPU/wall sample because of the dynamic sampling rate mechanism
    unsigned int cpu_skipped;
    // Min/max/total wall-time spent on CPU/wall sampling
    uint64_t cpu_sampling_time_ns_min;
    uint64_t cpu_sampling_time_ns_max;
    uint64_t cpu_sampling_time_ns_total;

    // # Allocation sampling stats
    // How many times we actually allocation sampled
    uint64_t allocation_sampled;
    // How many times we skipped an allocation sample because of the dynamic sampling rate mechanism
    uint64_t allocation_skipped;
    // Min/max/total wall-time spent on allocation sampling
    uint64_t allocation_sampling_time_ns_min;
    uint64_t allocation_sampling_time_ns_max;
    uint64_t allocation_sampling_time_ns_total;
    // How many times we saw allocations being done inside a sample
    unsigned int allocations_during_sample;

    // # GVL profiling stats
    // How many times we triggered the after_gvl_running sampling
    unsigned int after_gvl_running;
    // How many times we skipped the after_gvl_running sampling
    unsigned int gvl_dont_sample;
    // Min/max/total wall-time spent on gvl sampling
    uint64_t gvl_sampling_time_ns_min;
    uint64_t gvl_sampling_time_ns_max;
    uint64_t gvl_sampling_time_ns_total;
  } stats;
} cpu_and_wall_time_worker_state;

static VALUE _native_new(VALUE klass);
static VALUE _native_initialize(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self);
static void cpu_and_wall_time_worker_typed_data_mark(void *state_ptr);
static VALUE _native_sampling_loop(VALUE self, VALUE instance);
static VALUE _native_stop(DDTRACE_UNUSED VALUE _self, VALUE self_instance, VALUE worker_thread);
static VALUE stop(VALUE self_instance, VALUE optional_exception);
static void stop_state(cpu_and_wall_time_worker_state *state, VALUE optional_exception);
static void handle_sampling_signal(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext);
static void *run_sampling_trigger_loop(void *state_ptr);
static void interrupt_sampling_trigger_loop(void *state_ptr);
static void sample_from_postponed_job(DDTRACE_UNUSED void *_unused);
static VALUE rescued_sample_from_postponed_job(VALUE self_instance);
static VALUE handle_sampling_failure(VALUE self_instance, VALUE exception);
static VALUE _native_current_sigprof_signal_handler(DDTRACE_UNUSED VALUE self);
static VALUE release_gvl_and_run_sampling_trigger_loop(VALUE instance);
static VALUE _native_is_running(DDTRACE_UNUSED VALUE self, VALUE instance);
static void testing_signal_handler(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext);
static VALUE _native_install_testing_signal_handler(DDTRACE_UNUSED VALUE self);
static VALUE _native_remove_testing_signal_handler(DDTRACE_UNUSED VALUE self);
static VALUE _native_trigger_sample(DDTRACE_UNUSED VALUE self);
static VALUE _native_gc_tracepoint(DDTRACE_UNUSED VALUE self, VALUE instance);
static void on_gc_event(VALUE tracepoint_data, DDTRACE_UNUSED void *unused);
static void after_gc_from_postponed_job(DDTRACE_UNUSED void *_unused);
static VALUE safely_call(VALUE (*function_to_call_safely)(VALUE), VALUE function_to_call_safely_arg, VALUE instance);
static VALUE _native_simulate_handle_sampling_signal(DDTRACE_UNUSED VALUE self);
static VALUE _native_simulate_sample_from_postponed_job(DDTRACE_UNUSED VALUE self);
static VALUE _native_reset_after_fork(DDTRACE_UNUSED VALUE self, VALUE instance);
static VALUE _native_is_sigprof_blocked_in_current_thread(DDTRACE_UNUSED VALUE self);
static VALUE _native_stats(DDTRACE_UNUSED VALUE self, VALUE instance);
static VALUE _native_stats_reset_not_thread_safe(DDTRACE_UNUSED VALUE self, VALUE instance);
void *simulate_sampling_signal_delivery(DDTRACE_UNUSED void *_unused);
static void grab_gvl_and_sample(void);
static void reset_stats_not_thread_safe(cpu_and_wall_time_worker_state *state);
static void sleep_for(uint64_t time_ns);
static VALUE _native_allocation_count(DDTRACE_UNUSED VALUE self);
static void on_newobj_event(DDTRACE_UNUSED VALUE unused1, DDTRACE_UNUSED void *unused2);
static void disable_tracepoints(cpu_and_wall_time_worker_state *state);
static VALUE _native_with_blocked_sigprof(DDTRACE_UNUSED VALUE self);
static VALUE rescued_sample_allocation(VALUE tracepoint_data);
static void delayed_error(cpu_and_wall_time_worker_state *state, const char *error);
static VALUE _native_delayed_error(DDTRACE_UNUSED VALUE self, VALUE instance, VALUE error_msg);
static VALUE _native_hold_signals(DDTRACE_UNUSED VALUE self);
static VALUE _native_resume_signals(DDTRACE_UNUSED VALUE self);
#ifndef NO_GVL_INSTRUMENTATION
static void on_gvl_event(rb_event_flag_t event_id, const rb_internal_thread_event_data_t *event_data, DDTRACE_UNUSED void *_unused);
static void after_gvl_running_from_postponed_job(DDTRACE_UNUSED void *_unused);
#endif
static VALUE rescued_after_gvl_running_from_postponed_job(VALUE self_instance);
static VALUE _native_gvl_profiling_hook_active(DDTRACE_UNUSED VALUE self, VALUE instance);
static inline void during_sample_enter(cpu_and_wall_time_worker_state* state);
static inline void during_sample_exit(cpu_and_wall_time_worker_state* state);

// We're using `on_newobj_event` function with `rb_add_event_hook2`, which requires in its public signature a function
// with signature `rb_event_hook_func_t` which doesn't match `on_newobj_event`.
//
// But in practice, because we pass the `RUBY_EVENT_HOOK_FLAG_RAW_ARG` flag to  `rb_add_event_hook2`, it casts the
// expected signature into a `rb_event_hook_raw_arg_func_t`:
// > typedef void (*rb_event_hook_raw_arg_func_t)(VALUE data, const rb_trace_arg_t *arg); (from vm_trace.c)
// which does match `on_newobj_event`.
//
// So TL;DR we're just doing this here to avoid the warning and explain why the apparent mismatch in function signatures.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcast-function-type"
  static const rb_event_hook_func_t on_newobj_event_as_hook = (rb_event_hook_func_t) on_newobj_event;
#pragma GCC diagnostic pop

// Note on sampler global state safety:
//
// Both `active_sampler_instance` and `active_sampler_instance_state` are **GLOBAL** state. Be careful when accessing
// or modifying them.
// In particular, it's important to only mutate them while holding the global VM lock, to ensure correctness.
//
// This global state is needed because a bunch of functions on this file need to access it from situations
// (e.g. signal handler) where it's impossible or just awkward to pass it as an argument.
static VALUE active_sampler_instance = Qnil;
static cpu_and_wall_time_worker_state *active_sampler_instance_state = NULL;

// See handle_sampling_signal for details on what this does
#ifdef NO_POSTPONED_TRIGGER
  static void *gc_finalize_deferred_workaround;
#endif

// Used to implement CpuAndWallTimeWorker._native_allocation_count . To be able to use cheap thread-local variables
// (here with `__thread`, see https://gcc.gnu.org/onlinedocs/gcc/Thread-Local.html), this needs to be global.
//
// Carryover of state between profiler instances can happen and is not considered to be a problem -- see expectations for this
// API documented in profiling.rb .
__thread uint64_t allocation_count = 0;

void collectors_cpu_and_wall_time_worker_init(VALUE profiling_module) {
  rb_global_variable(&active_sampler_instance);

  #ifndef NO_POSTPONED_TRIGGER
    int unused_flags = 0;
    sample_from_postponed_job_handle = rb_postponed_job_preregister(unused_flags, sample_from_postponed_job, NULL);
    after_gc_from_postponed_job_handle = rb_postponed_job_preregister(unused_flags, after_gc_from_postponed_job, NULL);
    after_gvl_running_from_postponed_job_handle = rb_postponed_job_preregister(unused_flags, after_gvl_running_from_postponed_job, NULL);

    if (
      sample_from_postponed_job_handle == POSTPONED_JOB_HANDLE_INVALID ||
      after_gc_from_postponed_job_handle == POSTPONED_JOB_HANDLE_INVALID ||
      after_gvl_running_from_postponed_job_handle == POSTPONED_JOB_HANDLE_INVALID
    ) {
      rb_raise(rb_eRuntimeError, "Failed to register profiler postponed jobs (got POSTPONED_JOB_HANDLE_INVALID)");
    }
  #else
    gc_finalize_deferred_workaround = objspace_ptr_for_gc_finalize_deferred_workaround();
  #endif

  VALUE collectors_module = rb_define_module_under(profiling_module, "Collectors");
  VALUE collectors_cpu_and_wall_time_worker_class = rb_define_class_under(collectors_module, "CpuAndWallTimeWorker", rb_cObject);
  // Hosts methods used for testing the native code using RSpec
  VALUE testing_module = rb_define_module_under(collectors_cpu_and_wall_time_worker_class, "Testing");

  // Instances of the CpuAndWallTimeWorker class are "TypedData" objects.
  // "TypedData" objects are special objects in the Ruby VM that can wrap C structs.
  // In this case, it wraps the cpu_and_wall_time_worker_state.
  //
  // Because Ruby doesn't know how to initialize native-level structs, we MUST override the allocation function for objects
  // of this class so that we can manage this part. Not overriding or disabling the allocation function is a common
  // gotcha for "TypedData" objects that can very easily lead to VM crashes, see for instance
  // https://bugs.ruby-lang.org/issues/18007 for a discussion around this.
  rb_define_alloc_func(collectors_cpu_and_wall_time_worker_class, _native_new);

  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_initialize", _native_initialize, -1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_sampling_loop", _native_sampling_loop, 1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_stop", _native_stop, 2);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_reset_after_fork", _native_reset_after_fork, 1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_stats", _native_stats, 1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_stats_reset_not_thread_safe", _native_stats_reset_not_thread_safe, 1);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_allocation_count", _native_allocation_count, 0);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_is_running?", _native_is_running, 1);
  rb_define_singleton_method(testing_module, "_native_current_sigprof_signal_handler", _native_current_sigprof_signal_handler, 0);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_hold_signals", _native_hold_signals, 0);
  rb_define_singleton_method(collectors_cpu_and_wall_time_worker_class, "_native_resume_signals", _native_resume_signals, 0);
  rb_define_singleton_method(testing_module, "_native_install_testing_signal_handler", _native_install_testing_signal_handler, 0);
  rb_define_singleton_method(testing_module, "_native_remove_testing_signal_handler", _native_remove_testing_signal_handler, 0);
  rb_define_singleton_method(testing_module, "_native_trigger_sample", _native_trigger_sample, 0);
  rb_define_singleton_method(testing_module, "_native_gc_tracepoint", _native_gc_tracepoint, 1);
  rb_define_singleton_method(testing_module, "_native_simulate_handle_sampling_signal", _native_simulate_handle_sampling_signal, 0);
  rb_define_singleton_method(testing_module, "_native_simulate_sample_from_postponed_job", _native_simulate_sample_from_postponed_job, 0);
  rb_define_singleton_method(testing_module, "_native_is_sigprof_blocked_in_current_thread", _native_is_sigprof_blocked_in_current_thread, 0);
  rb_define_singleton_method(testing_module, "_native_with_blocked_sigprof", _native_with_blocked_sigprof, 0);
  rb_define_singleton_method(testing_module, "_native_delayed_error", _native_delayed_error, 2);
  rb_define_singleton_method(testing_module, "_native_gvl_profiling_hook_active", _native_gvl_profiling_hook_active, 1);
}

// This structure is used to define a Ruby object that stores a pointer to a cpu_and_wall_time_worker_state
// See also https://github.com/ruby/ruby/blob/master/doc/extension.rdoc for how this works
static const rb_data_type_t cpu_and_wall_time_worker_typed_data = {
  .wrap_struct_name = "Datadog::Profiling::Collectors::CpuAndWallTimeWorker",
  .function = {
    .dmark = cpu_and_wall_time_worker_typed_data_mark,
    .dfree = RUBY_DEFAULT_FREE,
    .dsize = NULL, // We don't track memory usage (although it'd be cool if we did!)
    //.dcompact = NULL, // FIXME: Add support for compaction
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE _native_new(VALUE klass) {
  long now = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);

  cpu_and_wall_time_worker_state *state = ruby_xcalloc(1, sizeof(cpu_and_wall_time_worker_state));

  // Note: Any exceptions raised from this note until the TypedData_Wrap_Struct call will lead to the state memory
  // being leaked.

  state->gc_profiling_enabled = false;
  state->no_signals_workaround_enabled = false;
  state->dynamic_sampling_rate_enabled = true;
  state->allocation_profiling_enabled = false;
  state->allocation_counting_enabled = false;
  state->gvl_profiling_enabled = false;
  state->skip_idle_samples_for_testing = false;
  state->sighandler_sampling_enabled = false;
  state->thread_context_collector_instance = Qnil;
  state->idle_sampling_helper_instance = Qnil;
  state->owner_thread = Qnil;
  dynamic_sampling_rate_init(&state->cpu_dynamic_sampling_rate);
  state->gc_tracepoint = Qnil;

  atomic_init(&state->should_run, false);
  state->failure_exception = Qnil;
  state->stop_thread = Qnil;

  during_sample_exit(state);

  #ifndef NO_GVL_INSTRUMENTATION
    state->gvl_profiling_hook = NULL;
  #endif

  reset_stats_not_thread_safe(state);
  discrete_dynamic_sampler_init(&state->allocation_sampler, "allocation", now);

  // Note: As of this writing, no new Ruby objects get created and stored in the state. If that ever changes, remember
  // to keep them on the stack and mark them with RB_GC_GUARD -- otherwise it's possible for a GC to run and
  // since the instance representing the state does not yet exist, such objects will not get marked.

  return state->self_instance = TypedData_Wrap_Struct(klass, &cpu_and_wall_time_worker_typed_data, state);
}

static VALUE _native_initialize(int argc, VALUE *argv, DDTRACE_UNUSED VALUE _self) {
  VALUE options;
  rb_scan_args(argc, argv, "0:", &options);
  if (options == Qnil) options = rb_hash_new();

  VALUE self_instance = rb_hash_fetch(options, ID2SYM(rb_intern("self_instance")));
  VALUE thread_context_collector_instance = rb_hash_fetch(options, ID2SYM(rb_intern("thread_context_collector")));
  VALUE gc_profiling_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("gc_profiling_enabled")));
  VALUE idle_sampling_helper_instance = rb_hash_fetch(options, ID2SYM(rb_intern("idle_sampling_helper")));
  VALUE no_signals_workaround_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("no_signals_workaround_enabled")));
  VALUE dynamic_sampling_rate_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("dynamic_sampling_rate_enabled")));
  VALUE dynamic_sampling_rate_overhead_target_percentage = rb_hash_fetch(options, ID2SYM(rb_intern("dynamic_sampling_rate_overhead_target_percentage")));
  VALUE allocation_profiling_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("allocation_profiling_enabled")));
  VALUE allocation_counting_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("allocation_counting_enabled")));
  VALUE gvl_profiling_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("gvl_profiling_enabled")));
  VALUE skip_idle_samples_for_testing = rb_hash_fetch(options, ID2SYM(rb_intern("skip_idle_samples_for_testing")));
  VALUE sighandler_sampling_enabled = rb_hash_fetch(options, ID2SYM(rb_intern("sighandler_sampling_enabled")));

  ENFORCE_BOOLEAN(gc_profiling_enabled);
  ENFORCE_BOOLEAN(no_signals_workaround_enabled);
  ENFORCE_BOOLEAN(dynamic_sampling_rate_enabled);
  ENFORCE_TYPE(dynamic_sampling_rate_overhead_target_percentage, T_FLOAT);
  ENFORCE_BOOLEAN(allocation_profiling_enabled);
  ENFORCE_BOOLEAN(allocation_counting_enabled);
  ENFORCE_BOOLEAN(gvl_profiling_enabled);
  ENFORCE_BOOLEAN(skip_idle_samples_for_testing)
  ENFORCE_BOOLEAN(sighandler_sampling_enabled)

  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  state->gc_profiling_enabled = (gc_profiling_enabled == Qtrue);
  state->no_signals_workaround_enabled = (no_signals_workaround_enabled == Qtrue);
  state->dynamic_sampling_rate_enabled = (dynamic_sampling_rate_enabled == Qtrue);
  state->allocation_profiling_enabled = (allocation_profiling_enabled == Qtrue);
  state->allocation_counting_enabled = (allocation_counting_enabled == Qtrue);
  state->gvl_profiling_enabled = (gvl_profiling_enabled == Qtrue);
  state->skip_idle_samples_for_testing = (skip_idle_samples_for_testing == Qtrue);
  state->sighandler_sampling_enabled = (sighandler_sampling_enabled == Qtrue);

  double total_overhead_target_percentage = NUM2DBL(dynamic_sampling_rate_overhead_target_percentage);
  if (!state->allocation_profiling_enabled) {
    dynamic_sampling_rate_set_overhead_target_percentage(&state->cpu_dynamic_sampling_rate, total_overhead_target_percentage);
  } else {
    // TODO: May be nice to offer customization here? Distribute available "overhead" margin with a bias towards one or the other
    // sampler.
    dynamic_sampling_rate_set_overhead_target_percentage(&state->cpu_dynamic_sampling_rate, total_overhead_target_percentage / 2);
    long now = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);
    discrete_dynamic_sampler_set_overhead_target_percentage(&state->allocation_sampler, total_overhead_target_percentage / 2, now);
  }

  state->thread_context_collector_instance = enforce_thread_context_collector_instance(thread_context_collector_instance);
  state->idle_sampling_helper_instance = idle_sampling_helper_instance;
  state->gc_tracepoint = rb_tracepoint_new(Qnil, RUBY_INTERNAL_EVENT_GC_ENTER | RUBY_INTERNAL_EVENT_GC_EXIT, on_gc_event, NULL /* unused */);

  return Qtrue;
}

// Since our state contains references to Ruby objects, we need to tell the Ruby GC about them
static void cpu_and_wall_time_worker_typed_data_mark(void *state_ptr) {
  cpu_and_wall_time_worker_state *state = (cpu_and_wall_time_worker_state *) state_ptr;

  rb_gc_mark(state->thread_context_collector_instance);
  rb_gc_mark(state->idle_sampling_helper_instance);
  rb_gc_mark(state->owner_thread);
  rb_gc_mark(state->failure_exception);
  rb_gc_mark(state->stop_thread);
  rb_gc_mark(state->gc_tracepoint);
}

// Called in a background thread created in CpuAndWallTimeWorker#start
static VALUE _native_sampling_loop(DDTRACE_UNUSED VALUE _self, VALUE instance) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  // If we already got a delayed exception registered even before starting, raise before starting
  if (state->failure_exception != Qnil) {
    disable_tracepoints(state);
    rb_exc_raise(state->failure_exception);
  }

  cpu_and_wall_time_worker_state *old_state = active_sampler_instance_state;
  if (old_state != NULL) {
    if (is_thread_alive(old_state->owner_thread)) {
      rb_raise(
        rb_eRuntimeError,
        "Could not start CpuAndWallTimeWorker: There's already another instance of CpuAndWallTimeWorker active in a different thread"
      );
    } else {
      // The previously active thread seems to have died without cleaning up after itself.
      // In this case, we can still go ahead and start the profiler BUT we make sure to disable any existing tracepoint
      // first as:
      // a) If this is a new instance of the CpuAndWallTimeWorker, we don't want the tracepoint from the old instance
      //    being kept around
      // b) If this is the same instance of the CpuAndWallTimeWorker if we call enable on a tracepoint that is already
      //    enabled, it will start firing more than once, see https://bugs.ruby-lang.org/issues/19114 for details.
      disable_tracepoints(old_state);
    }
  }

  // We use `stop_thread` to distinguish when `_native_stop` was called before we actually had a chance to start. In this
  // situation we stop immediately and never even start the sampling trigger loop.
  if (state->stop_thread == rb_thread_current()) return Qnil;

  // Reset the dynamic sampling rate state, if any (reminder: the monotonic clock reference may change after a fork)
  dynamic_sampling_rate_reset(&state->cpu_dynamic_sampling_rate);
  long now = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);
  discrete_dynamic_sampler_reset(&state->allocation_sampler, now);

  // This write to a global is thread-safe BECAUSE we're still holding on to the global VM lock at this point
  active_sampler_instance_state = state;
  active_sampler_instance = instance;
  state->owner_thread = rb_thread_current();

  atomic_store(&state->should_run, true);

  block_sigprof_signal_handler_from_running_in_current_thread(); // We want to interrupt the thread with the global VM lock, never this one

  // Release GVL, get to the actual work!
  int exception_state;
  rb_protect(release_gvl_and_run_sampling_trigger_loop, instance, &exception_state);

  // The sample trigger loop finished (either cleanly or with an error); let's clean up

  disable_tracepoints(state);

  active_sampler_instance_state = NULL;
  active_sampler_instance = Qnil;
  state->owner_thread = Qnil;

  // If this `Thread` is about to die, why is this important? It's because Ruby caches native threads for a period after
  // the `Thread` dies, and reuses them if a new Ruby `Thread` gets created. This means that while conceptually the
  // worker background `Thread` is about to die, the low-level native OS thread can be reused for something else in the Ruby app.
  // Then, the reused thread would "inherit" the SIGPROF blocking, which is... really unexpected.
  // This actually caused a flaky test -- the `native_extension_spec.rb` creates a `Thread` and tries to specifically
  // send SIGPROF signals to it, and oops it could fail if it got the reused native thread from the worker which still
  // had SIGPROF delivery blocked. :hide_the_pain_harold:
  unblock_sigprof_signal_handler_from_running_in_current_thread();

  // Why replace and not use remove the signal handler? We do this because when a process receives a SIGPROF without
  // having an explicit signal handler set up, the process will instantly terminate with a confusing
  // "Profiling timer expired" message left behind. (This message doesn't come from us -- it's the default message for
  // an unhandled SIGPROF. Pretty confusing UNIX/POSIX behavior...)
  //
  // Unfortunately, because signal delivery is asynchronous, there's no way to guarantee that there are no pending
  // profiler-sent signals by the time we get here and want to clean up.
  // @ivoanjo: I suspect this will never happen, but the cost of getting it wrong is really high (VM terminates) so this
  // is a just-in-case situation.
  //
  // Note 2: This can raise exceptions as well, so make sure that all cleanups are done by the time we get here.
  replace_sigprof_signal_handler_with_empty_handler(handle_sampling_signal);

  // Ensure that instance is not garbage collected while the native sampling loop is running; this is probably not needed, but just in case
  RB_GC_GUARD(instance);

  if (exception_state) rb_jump_tag(exception_state); // Re-raise any exception that happened

  return Qnil;
}

static VALUE _native_stop(DDTRACE_UNUSED VALUE _self, VALUE self_instance, VALUE worker_thread) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  state->stop_thread = worker_thread;

  return stop(self_instance, /* optional_exception: */ Qnil);
}

static void stop_state(cpu_and_wall_time_worker_state *state, VALUE optional_exception) {
  atomic_store(&state->should_run, false);
  state->failure_exception = optional_exception;

  // Disable the tracepoints as soon as possible, so the VM doesn't keep on calling them
  disable_tracepoints(state);
}

static VALUE stop(VALUE self_instance, VALUE optional_exception) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  stop_state(state, optional_exception);

  return Qtrue;
}

// NOTE: Remember that this will run in the thread and within the scope of user code, including user C code.
// We need to be careful not to change any state that may be observed OR to restore it if we do. For instance, if anything
// we do here can set `errno`, then we must be careful to restore the old `errno` after the fact.
static void handle_sampling_signal(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the signal delivery was happening; nothing to do
  if (state == NULL) return;

  if (
    !ruby_native_thread_p() || // Not a Ruby thread
    !is_current_thread_holding_the_gvl() || // Not safe to enqueue a sample from this thread
    !ddtrace_rb_ractor_main_p() // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  ) {
    state->stats.signal_handler_wrong_thread++;
    return;
  }

  // We assume there can be no concurrent nor nested calls to handle_sampling_signal because
  // a) we get triggered using SIGPROF, and the docs state a second SIGPROF will not interrupt an existing one (see sigaction docs on sa_mask)
  // b) we validate we are in the thread that has the global VM lock; if a different thread gets a signal, it will return early
  //    because it will not have the global VM lock

  state->stats.signal_handler_enqueued_sample++;

  bool sample_from_signal_handler =
    state->sighandler_sampling_enabled &&
    // Don't sample if we're already in the middle of processing a sample
    !state->during_sample;

  if (sample_from_signal_handler) {
    // Buffer current stack trace. Note that this will not actually record the sample, for that we still need to wait
    // until the postponed job below gets run.
    bool prepared = thread_context_collector_prepare_sample_inside_signal_handler(state->thread_context_collector_instance);

    if (prepared) state->stats.signal_handler_prepared_sample++;
  }

  #ifndef NO_POSTPONED_TRIGGER // Ruby 3.3+
    rb_postponed_job_trigger(sample_from_postponed_job_handle);
  #else
    // Passing in `gc_finalize_deferred_workaround` is a workaround for https://bugs.ruby-lang.org/issues/19991 (for Ruby < 3.3)
    //
    // TL;DR the `rb_postponed_job_register_one` API is not atomic (which is why it got replaced by `rb_postponed_job_trigger`)
    // and in rare cases can cause VM crashes.
    //
    // Specifically, if we're interrupting `rb_postponed_job_flush` (the function that processes postponed jobs), the way
    // that this function reads the jobs is not atomic, and can cause our call to
    // `rb_postponed_job_register(function, arg)` to clobber an existing job that is getting dequeued.
    // Clobbering an existing job is somewhat annoying, but the worst part is that it can happen that we clobber only
    // the existing job's arguments.
    // As surveyed in https://github.com/ruby/ruby/pull/8949#issuecomment-1821441370 clobbering the arguments turns out
    // to not matter in many cases as usually `rb_postponed_job_register` calls in the VM and ecosystem ignore the argument.
    //
    // https://bugs.ruby-lang.org/issues/19991 is the exception: inside Ruby's `gc.c`, when dealing with object
    // finalizers, Ruby calls `gc_finalize_deferred_register` which internally calls
    // `rb_postponed_job_register_one(gc_finalize_deferred, objspace)`.
    // Clobbering this call means that `gc_finalize_deferred` would get called with `NULL`, causing a segmentation fault.
    //
    // Note that this is quite rare: our signal needs to land at exactly the point where the VM has read the function
    // to execute, but has yet to read the arguments. @ivoanjo: I could only reproduce it by manually changing the VM
    // code to simulate this happening.
    //
    // Thus, our workaround is simple: we pass in objspace as our argument, just in case the clobbering happens.
    // In the happy path, we never use this argument so it makes no difference. In the buggy path, we avoid crashing the VM.
    rb_postponed_job_register(0, sample_from_postponed_job, gc_finalize_deferred_workaround /* instead of NULL */);
  #endif
}

// The actual sampling trigger loop always runs **without** the global vm lock.
static void *run_sampling_trigger_loop(void *state_ptr) {
  cpu_and_wall_time_worker_state *state = (cpu_and_wall_time_worker_state *) state_ptr;

  uint64_t minimum_time_between_signals = MILLIS_AS_NS(10);

  while (atomic_load(&state->should_run)) {
    state->stats.trigger_sample_attempts++;

    if (state->no_signals_workaround_enabled) {
      // In the no_signals_workaround_enabled mode, the profiler never sends SIGPROF signals.
      //
      // This is a fallback for a few incompatibilities and limitations -- see the code that decides when to enable
      // `no_signals_workaround_enabled` in `Profiling::Component` for details.
      //
      // Thus, we instead pretty please ask Ruby to let us run. This means profiling data can be biased by when the Ruby
      // scheduler chooses to schedule us.
      state->stats.trigger_simulated_signal_delivery_attempts++;
      grab_gvl_and_sample(); // Note: Can raise exceptions
    } else {
      current_gvl_owner owner = gvl_owner();
      if (owner.valid) {
        // Note that reading the GVL owner and sending them a signal is a race -- the Ruby VM keeps on executing while
        // we're doing this, so we may still not signal the correct thread from time to time, but our signal handler
        // includes a check to see if it got called in the right thread
        state->stats.interrupt_thread_attempts++;
        pthread_kill(owner.owner, SIGPROF);
      } else {
        if (state->skip_idle_samples_for_testing) {
          // This was added to make sure our tests don't accidentally pass due to idle samples. Specifically, if we
          // comment out the thread interruption code inside `if (owner.valid)` above, our tests should not pass!
        } else {
          // If no thread owns the Global VM Lock, the application is probably idle at the moment. We still want to sample
          // so we "ask a friend" (the IdleSamplingHelper component) to grab the GVL and simulate getting a SIGPROF.
          //
          // In a previous version of the code, we called `grab_gvl_and_sample` directly BUT this was problematic because
          // Ruby may concurrently get busy and so the CpuAndWallTimeWorker would be blocked in line to acquire the GVL
          // for an uncontrolled amount of time. (This can still happen to the IdleSamplingHelper, but the
          // CpuAndWallTimeWorker will still be free to interrupt the Ruby VM and keep sampling for the entire blocking period).
          state->stats.trigger_simulated_signal_delivery_attempts++;
          idle_sampling_helper_request_action(state->idle_sampling_helper_instance, grab_gvl_and_sample);
        }
      }
    }

    sleep_for(minimum_time_between_signals);

    // The dynamic sampling rate module keeps track of how long samples are taking, and in here we extend our sleep time
    // to take that into account.
    // Note that we deliberately should NOT combine this sleep_for with the one above because the result of
    // `dynamic_sampling_rate_get_sleep` may have changed while the above sleep was ongoing.
    uint64_t extra_sleep =
      dynamic_sampling_rate_get_sleep(&state->cpu_dynamic_sampling_rate, monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE));
    if (state->dynamic_sampling_rate_enabled && extra_sleep > 0) sleep_for(extra_sleep);
  }

  return NULL; // Unused
}

// This is called by the Ruby VM when it wants to shut down the background thread
static void interrupt_sampling_trigger_loop(void *state_ptr) {
  cpu_and_wall_time_worker_state *state = (cpu_and_wall_time_worker_state *) state_ptr;

  atomic_store(&state->should_run, false);
}

  // Note: If we ever want to get rid of the postponed job execution, remember not to clobber Ruby exceptions, as
  // this function does this helpful job for us now -- https://github.com/ruby/ruby/commit/a98e343d39c4d7bf1e2190b076720f32d9f298b3.
static void sample_from_postponed_job(DDTRACE_UNUSED void *_unused) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the postponed job was waiting to be executed; nothing to do
  if (state == NULL) return;

  // @ivoanjo: I'm not sure this can ever happen because `handle_sampling_signal` only enqueues this callback if
  // it's running on the main Ractor, but just in case...
  if (!ddtrace_rb_ractor_main_p()) {
    return; // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  }

  during_sample_enter(state);

  // Rescue against any exceptions that happen during sampling
  safely_call(rescued_sample_from_postponed_job, state->self_instance, state->self_instance);

  during_sample_exit(state);
}

static VALUE rescued_sample_from_postponed_job(VALUE self_instance) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(self_instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  long wall_time_ns_before_sample = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);

  if (state->dynamic_sampling_rate_enabled && !dynamic_sampling_rate_should_sample(&state->cpu_dynamic_sampling_rate, wall_time_ns_before_sample)) {
    state->stats.cpu_skipped++;
    return Qnil;
  }

  state->stats.cpu_sampled++;

  VALUE profiler_overhead_stack_thread = state->owner_thread; // Used to attribute profiler overhead to a different stack
  thread_context_collector_sample(state->thread_context_collector_instance, wall_time_ns_before_sample, profiler_overhead_stack_thread);

  long wall_time_ns_after_sample = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);
  long delta_ns = wall_time_ns_after_sample - wall_time_ns_before_sample;

  // Guard against wall-time going backwards, see https://github.com/DataDog/dd-trace-rb/pull/2336 for discussion.
  uint64_t sampling_time_ns = delta_ns < 0 ? 0 : delta_ns;

  state->stats.cpu_sampling_time_ns_min = uint64_min_of(sampling_time_ns, state->stats.cpu_sampling_time_ns_min);
  state->stats.cpu_sampling_time_ns_max = uint64_max_of(sampling_time_ns, state->stats.cpu_sampling_time_ns_max);
  state->stats.cpu_sampling_time_ns_total += sampling_time_ns;

  dynamic_sampling_rate_after_sample(&state->cpu_dynamic_sampling_rate, wall_time_ns_after_sample, sampling_time_ns);

  // Return a dummy VALUE because we're called from rb_rescue2 which requires it
  return Qnil;
}

static VALUE handle_sampling_failure(VALUE self_instance, VALUE exception) {
  stop(self_instance, exception);
  return Qnil;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_current_sigprof_signal_handler(DDTRACE_UNUSED VALUE self) {
  struct sigaction existing_signal_handler_config = {.sa_sigaction = NULL};
  if (sigaction(SIGPROF, NULL, &existing_signal_handler_config) != 0) {
    rb_sys_fail("Failed to probe existing handler");
  }

  if (existing_signal_handler_config.sa_sigaction == handle_sampling_signal) {
    return ID2SYM(rb_intern("profiling"));
  } else if (existing_signal_handler_config.sa_sigaction == empty_signal_handler) {
    return ID2SYM(rb_intern("empty"));
  } else if (existing_signal_handler_config.sa_sigaction != NULL) {
    return ID2SYM(rb_intern("other"));
  } else {
    return Qnil;
  }
}

static VALUE release_gvl_and_run_sampling_trigger_loop(VALUE instance) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  // Final preparations: Setup signal handler and enable tracepoints. We run these here and not in `_native_sampling_loop`
  // because they may raise exceptions.
  install_sigprof_signal_handler(handle_sampling_signal, "handle_sampling_signal");
  if (state->gc_profiling_enabled) rb_tracepoint_enable(state->gc_tracepoint);
  if (state->allocation_profiling_enabled) {
    rb_add_event_hook2(
      on_newobj_event_as_hook,
      RUBY_INTERNAL_EVENT_NEWOBJ,
      state->self_instance,
      RUBY_EVENT_HOOK_FLAG_SAFE | RUBY_EVENT_HOOK_FLAG_RAW_ARG)
    ;
  }

  if (state->gvl_profiling_enabled) {
    #ifndef NO_GVL_INSTRUMENTATION
      #ifdef USE_GVL_PROFILING_3_2_WORKAROUNDS
        gvl_profiling_state_thread_tracking_workaround();
      #endif

      state->gvl_profiling_hook = rb_internal_thread_add_event_hook(
        on_gvl_event,
        (
          // For now we're only asking for these events, even though there's more
          // (e.g. check docs or gvl-tracing gem)
          RUBY_INTERNAL_THREAD_EVENT_READY /* waiting for gvl */ |
          RUBY_INTERNAL_THREAD_EVENT_RESUMED /* running/runnable */
        ),
        NULL
      );
    #else
      rb_raise(rb_eArgError, "GVL profiling is not supported in this Ruby version");
    #endif
  }

  // Flag the profiler as running before we release the GVL, in case anyone's waiting to know about it
  rb_funcall(instance, rb_intern("signal_running"), 0);

  rb_thread_call_without_gvl(run_sampling_trigger_loop, state, interrupt_sampling_trigger_loop, state);

  // If we stopped sampling due to an exception, re-raise it (now in the worker thread)
  if (state->failure_exception != Qnil) rb_exc_raise(state->failure_exception);

  return Qnil;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_is_running(DDTRACE_UNUSED VALUE self, VALUE instance) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  return (state != NULL && is_thread_alive(state->owner_thread) && state->self_instance == instance) ? Qtrue : Qfalse;
}

static void testing_signal_handler(DDTRACE_UNUSED int _signal, DDTRACE_UNUSED siginfo_t *_info, DDTRACE_UNUSED void *_ucontext) {
  /* Does nothing on purpose */
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_install_testing_signal_handler(DDTRACE_UNUSED VALUE self) {
  install_sigprof_signal_handler(testing_signal_handler, "testing_signal_handler");
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_remove_testing_signal_handler(DDTRACE_UNUSED VALUE self) {
  remove_sigprof_signal_handler();
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_trigger_sample(DDTRACE_UNUSED VALUE self) {
  sample_from_postponed_job(NULL);
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_gc_tracepoint(DDTRACE_UNUSED VALUE self, VALUE instance) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  return state->gc_tracepoint;
}

// Implements tracking of cpu-time and wall-time spent doing GC. This function is called by Ruby from the `gc_tracepoint`
// when the RUBY_INTERNAL_EVENT_GC_ENTER and RUBY_INTERNAL_EVENT_GC_EXIT events are triggered.
//
// See the comments on
// * thread_context_collector_on_gc_start
// * thread_context_collector_on_gc_finish
// * thread_context_collector_sample_after_gc
//
// For the expected times in which to call them, and their assumptions.
//
// Safety: This function gets called while Ruby is doing garbage collection. While Ruby is doing garbage collection,
// *NO ALLOCATION* is allowed. This function, and any it calls must never trigger memory or object allocation.
// This includes exceptions and use of ruby_xcalloc (because xcalloc can trigger GC)!
static void on_gc_event(VALUE tracepoint_data, DDTRACE_UNUSED void *unused) {
  if (!ddtrace_rb_ractor_main_p()) {
    return; // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  }

  int event = rb_tracearg_event_flag(rb_tracearg_from_tracepoint(tracepoint_data));
  if (event != RUBY_INTERNAL_EVENT_GC_ENTER && event != RUBY_INTERNAL_EVENT_GC_EXIT) return; // Unknown event

  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This should not happen in a normal situation because the tracepoint is always enabled after the instance is set
  // and disabled before it is cleared, but just in case...
  if (state == NULL) return;

  if (event == RUBY_INTERNAL_EVENT_GC_ENTER) {
    thread_context_collector_on_gc_start(state->thread_context_collector_instance);
  } else if (event == RUBY_INTERNAL_EVENT_GC_EXIT) {
    bool should_flush = thread_context_collector_on_gc_finish(state->thread_context_collector_instance);

    // We use rb_postponed_job_register_one to ask Ruby to run thread_context_collector_sample_after_gc when the
    // thread collector flags it's time to flush.
    if (should_flush) {
      #ifndef NO_POSTPONED_TRIGGER // Ruby 3.3+
        rb_postponed_job_trigger(after_gc_from_postponed_job_handle);
      #else
        rb_postponed_job_register_one(0, after_gc_from_postponed_job, NULL);
      #endif
    }
  }
}

static void after_gc_from_postponed_job(DDTRACE_UNUSED void *_unused) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the postponed job was waiting to be executed; nothing to do
  if (state == NULL) return;

  // @ivoanjo: I'm not sure this can ever happen because `on_gc_event` only enqueues this callback if
  // it's running on the main Ractor, but just in case...
  if (!ddtrace_rb_ractor_main_p()) {
    return; // We're not on the main Ractor; we currently don't support profiling non-main Ractors
  }

  during_sample_enter(state);

  safely_call(thread_context_collector_sample_after_gc, state->thread_context_collector_instance, state->self_instance);

  during_sample_exit(state);
}

// Equivalent to Ruby begin/rescue call, where we call a C function and jump to the exception handler if an
// exception gets raised within
static VALUE safely_call(VALUE (*function_to_call_safely)(VALUE), VALUE function_to_call_safely_arg, VALUE instance) {
  VALUE exception_handler_function_arg = instance;
  return rb_rescue2(
    function_to_call_safely,
    function_to_call_safely_arg,
    handle_sampling_failure,
    exception_handler_function_arg,
    rb_eException, // rb_eException is the base class of all Ruby exceptions
    0 // Required by API to be the last argument
  );
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_simulate_handle_sampling_signal(DDTRACE_UNUSED VALUE self) {
  handle_sampling_signal(0, NULL, NULL);
  return Qtrue;
}

// This method exists only to enable testing Datadog::Profiling::Collectors::CpuAndWallTimeWorker behavior using RSpec.
// It SHOULD NOT be used for other purposes.
static VALUE _native_simulate_sample_from_postponed_job(DDTRACE_UNUSED VALUE self) {
  sample_from_postponed_job(NULL);
  return Qtrue;
}

// After the Ruby VM forks, this method gets called in the child process to clean up any leftover state from the parent.
//
// Assumption: This method gets called BEFORE restarting profiling. Note that profiling-related tracepoints may still
// be active, so we make sure to disable them before calling into anything else, so that there are no components
// attempting to trigger samples at the same time as the reset is done.
//
// In the future, if we add more other components with tracepoints, we will need to coordinate stopping all such
// tracepoints before doing the other cleaning steps.
static VALUE _native_reset_after_fork(DDTRACE_UNUSED VALUE self, VALUE instance) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  // Disable all tracepoints, so that there are no more attempts to mutate the profile
  disable_tracepoints(state);

  reset_stats_not_thread_safe(state);

  // Remove all state from the `Collectors::ThreadState` and connected downstream components
  rb_funcall(state->thread_context_collector_instance, rb_intern("reset_after_fork"), 0);

  return Qtrue;
}

static VALUE _native_is_sigprof_blocked_in_current_thread(DDTRACE_UNUSED VALUE self) {
  return is_sigprof_blocked_in_current_thread();
}

static VALUE _native_stats(DDTRACE_UNUSED VALUE self, VALUE instance) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  unsigned long total_cpu_samples_attempted = state->stats.cpu_sampled + state->stats.cpu_skipped;
  VALUE effective_cpu_sample_rate =
    total_cpu_samples_attempted == 0 ? Qnil : DBL2NUM(((double) state->stats.cpu_sampled) / total_cpu_samples_attempted);
  unsigned long total_allocation_samples_attempted = state->stats.allocation_sampled + state->stats.allocation_skipped;
  VALUE effective_allocation_sample_rate =
    total_allocation_samples_attempted == 0 ? Qnil : DBL2NUM(((double) state->stats.allocation_sampled) / total_allocation_samples_attempted);

  VALUE allocation_sampler_snapshot = state->allocation_profiling_enabled && state->dynamic_sampling_rate_enabled ?
    discrete_dynamic_sampler_state_snapshot(&state->allocation_sampler) : Qnil;

  VALUE stats_as_hash = rb_hash_new();
  VALUE arguments[] = {
    ID2SYM(rb_intern("trigger_sample_attempts")),                    /* => */ UINT2NUM(state->stats.trigger_sample_attempts),
    ID2SYM(rb_intern("trigger_simulated_signal_delivery_attempts")), /* => */ UINT2NUM(state->stats.trigger_simulated_signal_delivery_attempts),
    ID2SYM(rb_intern("simulated_signal_delivery")),                  /* => */ UINT2NUM(state->stats.simulated_signal_delivery),
    ID2SYM(rb_intern("signal_handler_enqueued_sample")),             /* => */ UINT2NUM(state->stats.signal_handler_enqueued_sample),
    ID2SYM(rb_intern("signal_handler_prepared_sample")),             /* => */ UINT2NUM(state->stats.signal_handler_prepared_sample),
    ID2SYM(rb_intern("signal_handler_wrong_thread")),                /* => */ UINT2NUM(state->stats.signal_handler_wrong_thread),
    ID2SYM(rb_intern("interrupt_thread_attempts")),                  /* => */ UINT2NUM(state->stats.interrupt_thread_attempts),

    // CPU Stats
    ID2SYM(rb_intern("cpu_sampled")),                /* => */ UINT2NUM(state->stats.cpu_sampled),
    ID2SYM(rb_intern("cpu_skipped")),                /* => */ UINT2NUM(state->stats.cpu_skipped),
    ID2SYM(rb_intern("cpu_effective_sample_rate")),  /* => */ effective_cpu_sample_rate,
    ID2SYM(rb_intern("cpu_sampling_time_ns_min")),   /* => */ RUBY_NUM_OR_NIL(state->stats.cpu_sampling_time_ns_min, != UINT64_MAX, ULL2NUM),
    ID2SYM(rb_intern("cpu_sampling_time_ns_max")),   /* => */ RUBY_NUM_OR_NIL(state->stats.cpu_sampling_time_ns_max, > 0, ULL2NUM),
    ID2SYM(rb_intern("cpu_sampling_time_ns_total")), /* => */ RUBY_NUM_OR_NIL(state->stats.cpu_sampling_time_ns_total, > 0, ULL2NUM),
    ID2SYM(rb_intern("cpu_sampling_time_ns_avg")),   /* => */ RUBY_AVG_OR_NIL(state->stats.cpu_sampling_time_ns_total, state->stats.cpu_sampled),

    // Allocation stats
    ID2SYM(rb_intern("allocation_sampled")),                /* => */ state->allocation_profiling_enabled ? ULONG2NUM(state->stats.allocation_sampled) : Qnil,
    ID2SYM(rb_intern("allocation_skipped")),                /* => */ state->allocation_profiling_enabled ? ULONG2NUM(state->stats.allocation_skipped) : Qnil,
    ID2SYM(rb_intern("allocation_effective_sample_rate")),  /* => */ effective_allocation_sample_rate,
    ID2SYM(rb_intern("allocation_sampling_time_ns_min")),   /* => */ RUBY_NUM_OR_NIL(state->stats.allocation_sampling_time_ns_min, != UINT64_MAX, ULL2NUM),
    ID2SYM(rb_intern("allocation_sampling_time_ns_max")),   /* => */ RUBY_NUM_OR_NIL(state->stats.allocation_sampling_time_ns_max, > 0, ULL2NUM),
    ID2SYM(rb_intern("allocation_sampling_time_ns_total")), /* => */ RUBY_NUM_OR_NIL(state->stats.allocation_sampling_time_ns_total, > 0, ULL2NUM),
    ID2SYM(rb_intern("allocation_sampling_time_ns_avg")),   /* => */ RUBY_AVG_OR_NIL(state->stats.allocation_sampling_time_ns_total, state->stats.allocation_sampled),
    ID2SYM(rb_intern("allocation_sampler_snapshot")),       /* => */ allocation_sampler_snapshot,
    ID2SYM(rb_intern("allocations_during_sample")),         /* => */ state->allocation_profiling_enabled ? UINT2NUM(state->stats.allocations_during_sample) : Qnil,

    // GVL profiling stats
    ID2SYM(rb_intern("after_gvl_running")),          /* => */ UINT2NUM(state->stats.after_gvl_running),
    ID2SYM(rb_intern("gvl_dont_sample")),            /* => */ UINT2NUM(state->stats.gvl_dont_sample),
    ID2SYM(rb_intern("gvl_sampling_time_ns_min")),   /* => */ RUBY_NUM_OR_NIL(state->stats.gvl_sampling_time_ns_min, != UINT64_MAX, ULL2NUM),
    ID2SYM(rb_intern("gvl_sampling_time_ns_max")),   /* => */ RUBY_NUM_OR_NIL(state->stats.gvl_sampling_time_ns_max, > 0, ULL2NUM),
    ID2SYM(rb_intern("gvl_sampling_time_ns_total")), /* => */ RUBY_NUM_OR_NIL(state->stats.gvl_sampling_time_ns_total, > 0, ULL2NUM),
    ID2SYM(rb_intern("gvl_sampling_time_ns_avg")),   /* => */ RUBY_AVG_OR_NIL(state->stats.gvl_sampling_time_ns_total, state->stats.after_gvl_running),
  };
  for (long unsigned int i = 0; i < VALUE_COUNT(arguments); i += 2) rb_hash_aset(stats_as_hash, arguments[i], arguments[i+1]);
  return stats_as_hash;
}

static VALUE _native_stats_reset_not_thread_safe(DDTRACE_UNUSED VALUE self, VALUE instance) {
  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);
  reset_stats_not_thread_safe(state);
  return Qnil;
}

void *simulate_sampling_signal_delivery(DDTRACE_UNUSED void *_unused) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This can potentially happen if the CpuAndWallTimeWorker was stopped while the IdleSamplingHelper was trying to execute this action
  if (state == NULL) return NULL;

  state->stats.simulated_signal_delivery++;

  // `handle_sampling_signal` does a few things extra on top of `sample_from_postponed_job` so that's why we don't shortcut here
  handle_sampling_signal(0, NULL, NULL);

  return NULL; // Unused
}

static void grab_gvl_and_sample(void) { rb_thread_call_with_gvl(simulate_sampling_signal_delivery, NULL); }

static void reset_stats_not_thread_safe(cpu_and_wall_time_worker_state *state) {
  // NOTE: This is not really thread safe so ongoing sampling operations that are concurrent with a reset can have their stats:
  //       * Lost (writes after stats retrieval but before reset).
  //       * Included in the previous stats window (writes before stats retrieval and reset).
  //       * Included in the following stats window (writes after stats retrieval and reset).
  //       Given the expected infrequency of resetting (~once per 60s profile) and the auxiliary/non-critical nature of these stats
  //       this momentary loss of accuracy is deemed acceptable to keep overhead to a minimum.
  state->stats = (struct stats) {
    // All these values are initialized to their highest value possible since we always take the min between existing and latest sample
    .cpu_sampling_time_ns_min        = UINT64_MAX,
    .allocation_sampling_time_ns_min = UINT64_MAX,
    .gvl_sampling_time_ns_min        = UINT64_MAX,
  };
}

static void sleep_for(uint64_t time_ns) {
  // As a simplification, we currently only support setting .tv_nsec
  if (time_ns >= SECONDS_AS_NS(1)) {
    grab_gvl_and_raise(rb_eArgError, "sleep_for can only sleep for less than 1 second, time_ns: %"PRIu64, time_ns);
  }

  struct timespec time_to_sleep = {.tv_nsec = time_ns};

  while (nanosleep(&time_to_sleep, &time_to_sleep) != 0) {
    if (errno == EINTR) {
      // We were interrupted. nanosleep updates "time_to_sleep" to contain only the remaining time, so we just let the
      // loop keep going.
    } else {
      ENFORCE_SUCCESS_NO_GVL(errno);
    }
  }
}

static VALUE _native_allocation_count(DDTRACE_UNUSED VALUE self) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state;

  bool are_allocations_being_tracked = state != NULL && state->allocation_profiling_enabled && state->allocation_counting_enabled;

  return are_allocations_being_tracked ? ULL2NUM(allocation_count) : Qnil;
}

#define HANDLE_CLOCK_FAILURE(call) ({ \
    long _result = (call); \
    if (_result == 0) { \
        delayed_error(state, ERR_CLOCK_FAIL); \
        return; \
    } \
    _result; \
})

// Implements memory-related profiling events. This function is called by Ruby via the `rb_add_event_hook2`
// when the RUBY_INTERNAL_EVENT_NEWOBJ event is triggered.
//
// When allocation sampling is enabled, this function gets called for almost all* objects allocated by the Ruby VM.
// (*In some weird cases the VM may skip this tracepoint.)
//
// At a high level, there's two paths through this function:
// 1. should_sample == false -> return
// 2. should_sample == true -> sample
//
// On big applications, path 1. is the hottest, since we don't sample every object. So it's quite important for it to
// be as fast as possible.
//
// NOTE: You may be wondering why we don't use any of the arguments to this function. It turns out it's possible to just
// call `rb_tracearg_from_tracepoint(anything)` anywhere during this function or its callees to get the data, so that's
// why it's not being passed as an argument.
static void on_newobj_event(DDTRACE_UNUSED VALUE unused1, DDTRACE_UNUSED void *unused2) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This should not happen in a normal situation because the tracepoint is always enabled after the instance is set
  // and disabled before it is cleared, but just in case...
  if (state == NULL) return;

  if (RB_UNLIKELY(state->allocation_counting_enabled)) {
    // Update thread-local allocation count
    if (RB_UNLIKELY(allocation_count == UINT64_MAX)) {
      allocation_count = 0;
    } else {
      allocation_count++;
    }
  }

  // In rare cases, we may actually be allocating an object as part of profiler sampling. We don't want to recursively
  // sample, so we just return early
  if (state->during_sample) {
    state->stats.allocations_during_sample++;
    return;
  }

  // If Ruby is in the middle of raising an exception, we don't want to try to sample. This is because if we accidentally
  // trigger an exception inside the profiler code, bad things will happen (specifically, Ruby will try to kill off the
  // thread even though we may try to catch the exception).
  //
  // Note that "in the middle of raising an exception" means the exception itself has already been allocated.
  // What's getting allocated now is probably the backtrace objects (@ivoanjo or at least that's what I've observed)
  if (is_raised_flag_set(rb_thread_current())) {
    return;
  }

  // Hot path: Dynamic sampling rate is usually enabled and the sampling decision is usually false
  if (RB_LIKELY(state->dynamic_sampling_rate_enabled && !discrete_dynamic_sampler_should_sample(&state->allocation_sampler))) {
    state->stats.allocation_skipped++;

    coarse_instant now = monotonic_coarse_wall_time_now_ns();
    HANDLE_CLOCK_FAILURE(now.timestamp_ns);

    bool needs_readjust = discrete_dynamic_sampler_skipped_sample(&state->allocation_sampler, now);
    if (RB_UNLIKELY(needs_readjust)) {
      // We rarely readjust, so this is a cold path
      // Also, while above we used the cheaper monotonic_coarse, for this call we want the regular monotonic call,
      // which is why we end up getting time "again".
      discrete_dynamic_sampler_readjust(
        &state->allocation_sampler, HANDLE_CLOCK_FAILURE(monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE))
      );
    }

    return;
  }

  // From here on, we've decided to go ahead with the sample, which is way less common than skipping it

  discrete_dynamic_sampler_before_sample(
    &state->allocation_sampler, HANDLE_CLOCK_FAILURE(monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE))
  );

  during_sample_enter(state);

  // Rescue against any exceptions that happen during sampling
  safely_call(rescued_sample_allocation, Qnil, state->self_instance);

  if (state->dynamic_sampling_rate_enabled) {
    long now = monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE);
    if (now == 0) {
      delayed_error(state, ERR_CLOCK_FAIL);
      // NOTE: Not short-circuiting here to make sure cleanup happens
    }
    uint64_t sampling_time_ns = discrete_dynamic_sampler_after_sample(&state->allocation_sampler, now);
    // NOTE: To keep things lean when dynamic sampling rate is disabled we skip clock interactions which is
    //       why we're fine with having this inside this conditional.
    state->stats.allocation_sampling_time_ns_min = uint64_min_of(sampling_time_ns, state->stats.allocation_sampling_time_ns_min);
    state->stats.allocation_sampling_time_ns_max = uint64_max_of(sampling_time_ns, state->stats.allocation_sampling_time_ns_max);
    state->stats.allocation_sampling_time_ns_total += sampling_time_ns;
  }

  state->stats.allocation_sampled++;

  during_sample_exit(state);
}

static void disable_tracepoints(cpu_and_wall_time_worker_state *state) {
  if (state->gc_tracepoint != Qnil) {
    rb_tracepoint_disable(state->gc_tracepoint);
  }

  rb_remove_event_hook_with_data(on_newobj_event_as_hook, state->self_instance);

  #ifndef NO_GVL_INSTRUMENTATION
    if (state->gvl_profiling_hook) {
      rb_internal_thread_remove_event_hook(state->gvl_profiling_hook);
      state->gvl_profiling_hook = NULL;
    }
  #endif
}

static VALUE _native_with_blocked_sigprof(DDTRACE_UNUSED VALUE self) {
  block_sigprof_signal_handler_from_running_in_current_thread();
  int exception_state;
  VALUE result = rb_protect(rb_yield, Qundef, &exception_state);
  unblock_sigprof_signal_handler_from_running_in_current_thread();

  if (exception_state) {
    rb_jump_tag(exception_state);
  } else {
    return result;
  }
}

static VALUE rescued_sample_allocation(DDTRACE_UNUSED VALUE unused) {
  cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

  // This should not happen in a normal situation because on_newobj_event already checked for this, but just in case...
  if (state == NULL) return Qnil;

  // If we're getting called from inside a tracepoint/event hook, Ruby exposes the data using this function.
  rb_trace_arg_t *data = rb_tracearg_from_tracepoint(Qnil);
  VALUE new_object = rb_tracearg_object(data);

  unsigned long allocations_since_last_sample = state->dynamic_sampling_rate_enabled ?
    // if we're doing dynamic sampling, ask the sampler how many events since last sample
    discrete_dynamic_sampler_events_since_last_sample(&state->allocation_sampler) :
    // if we aren't, then we're sampling every event
    1;

  // To control bias from sampling, we clamp the maximum weight attributed to a single allocation sample. This avoids
  // assigning a very large number to a sample, if for instance the dynamic sampling mechanism chose a really big interval.
  unsigned int weight = allocations_since_last_sample > MAX_ALLOC_WEIGHT ? MAX_ALLOC_WEIGHT : (unsigned int) allocations_since_last_sample;
  thread_context_collector_sample_allocation(state->thread_context_collector_instance, weight, new_object);
  // ...but we still represent the skipped samples in the profile, thus the data will account for all allocations.
  if (weight < allocations_since_last_sample) {
    uint32_t skipped_samples = (uint32_t) uint64_min_of(allocations_since_last_sample - weight, UINT32_MAX);
    thread_context_collector_sample_skipped_allocation_samples(state->thread_context_collector_instance, skipped_samples);
  }

  // Return a dummy VALUE because we're called from rb_rescue2 which requires it
  return Qnil;
}

static void delayed_error(cpu_and_wall_time_worker_state *state, const char *error) {
  // If we can't raise an immediate exception at the calling site, use the asynchronous flow through the main worker loop.
  stop_state(state, rb_exc_new_cstr(rb_eRuntimeError, error));
}

static VALUE _native_delayed_error(DDTRACE_UNUSED VALUE self, VALUE instance, VALUE error_msg) {
  ENFORCE_TYPE(error_msg, T_STRING);

  cpu_and_wall_time_worker_state *state;
  TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

  delayed_error(state, rb_string_value_cstr(&error_msg));

  return Qnil;
}

// Masks SIGPROF interruptions for the current thread. Please don't use this -- you may end up with incomplete
// profiling data.
static VALUE _native_hold_signals(DDTRACE_UNUSED VALUE self) {
  block_sigprof_signal_handler_from_running_in_current_thread();
  return Qtrue;
}

// Unmasks SIGPROF interruptions for the current thread. If there's a pending sample, it'll be triggered inside this
// method.
static VALUE _native_resume_signals(DDTRACE_UNUSED VALUE self) {
  unblock_sigprof_signal_handler_from_running_in_current_thread();
  return Qtrue;
}

#ifndef NO_GVL_INSTRUMENTATION
  static void on_gvl_event(rb_event_flag_t event_id, const rb_internal_thread_event_data_t *event_data, DDTRACE_UNUSED void *_unused) {
    // Be very careful about touching the `state` here or doing anything at all:
    // This function gets called without the GVL, and potentially from background Ractors!
    //
    // In fact, the `target_thread` that this event is about may not even be the current thread. (So be careful with thread locals that
    // are not directly tied to the `target_thread` object and the like)
    gvl_profiling_thread target_thread = thread_from_event(event_data);

    if (event_id == RUBY_INTERNAL_THREAD_EVENT_READY) { /* waiting for gvl */
      thread_context_collector_on_gvl_waiting(target_thread);
    } else if (event_id == RUBY_INTERNAL_THREAD_EVENT_RESUMED) { /* running/runnable */
      // Interesting note: A RUBY_INTERNAL_THREAD_EVENT_RESUMED is guaranteed to be called with the GVL being acquired.
      // (And... I think target_thread will be == rb_thread_current()?)
      //
      // But we're not sure if we're on the main Ractor yet. The thread context collector actually can actually help here:
      // it tags threads it's tracking, so if a thread is tagged then by definition we know that thread belongs to the main
      // Ractor. Thus, if we get a ON_GVL_RUNNING_UNKNOWN result we shouldn't touch any state, but otherwise we're good to go.

      #ifdef USE_GVL_PROFILING_3_2_WORKAROUNDS
        target_thread = gvl_profiling_state_maybe_initialize();
      #endif

      on_gvl_running_result result = thread_context_collector_on_gvl_running(target_thread);

      if (result == ON_GVL_RUNNING_SAMPLE) {
        #ifndef NO_POSTPONED_TRIGGER
          rb_postponed_job_trigger(after_gvl_running_from_postponed_job_handle);
        #else
          rb_postponed_job_register_one(0, after_gvl_running_from_postponed_job, NULL);
        #endif
      } else if (result == ON_GVL_RUNNING_DONT_SAMPLE) {
        cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

        if (state == NULL) return; // This should not happen, but just in case...

        state->stats.gvl_dont_sample++;
      }
    } else {
      // This is a very delicate time and it's hard for us to raise an exception so let's at least complain to stderr
      fprintf(stderr, "[ddtrace] Unexpected value in on_gvl_event (%d)\n", event_id);
    }
  }

  static void after_gvl_running_from_postponed_job(DDTRACE_UNUSED void *_unused) {
    cpu_and_wall_time_worker_state *state = active_sampler_instance_state; // Read from global variable, see "sampler global state safety" note above

    // This can potentially happen if the CpuAndWallTimeWorker was stopped while the postponed job was waiting to be executed; nothing to do
    if (state == NULL) return;

    during_sample_enter(state);

    // Rescue against any exceptions that happen during sampling
    safely_call(rescued_after_gvl_running_from_postponed_job, state->self_instance, state->self_instance);

    during_sample_exit(state);
  }

  static VALUE rescued_after_gvl_running_from_postponed_job(VALUE self_instance) {
    cpu_and_wall_time_worker_state *state;
    TypedData_Get_Struct(self_instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

    long wall_time_ns_before_sample = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);
    thread_context_collector_sample_after_gvl_running(state->thread_context_collector_instance, rb_thread_current(), wall_time_ns_before_sample);
    long wall_time_ns_after_sample = monotonic_wall_time_now_ns(RAISE_ON_FAILURE);

    long delta_ns = wall_time_ns_after_sample - wall_time_ns_before_sample;

    // Guard against wall-time going backwards, see https://github.com/DataDog/dd-trace-rb/pull/2336 for discussion.
    uint64_t sampling_time_ns = delta_ns < 0 ? 0 : delta_ns;

    state->stats.gvl_sampling_time_ns_min = uint64_min_of(sampling_time_ns, state->stats.gvl_sampling_time_ns_min);
    state->stats.gvl_sampling_time_ns_max = uint64_max_of(sampling_time_ns, state->stats.gvl_sampling_time_ns_max);
    state->stats.gvl_sampling_time_ns_total += sampling_time_ns;

    state->stats.after_gvl_running++;

    return Qnil;
  }

  static VALUE _native_gvl_profiling_hook_active(DDTRACE_UNUSED VALUE self, VALUE instance) {
    cpu_and_wall_time_worker_state *state;
    TypedData_Get_Struct(instance, cpu_and_wall_time_worker_state, &cpu_and_wall_time_worker_typed_data, state);

    return state->gvl_profiling_hook != NULL ? Qtrue : Qfalse;
  }
#else
  static VALUE _native_gvl_profiling_hook_active(DDTRACE_UNUSED VALUE self, DDTRACE_UNUSED VALUE instance) {
    return Qfalse;
  }
#endif

static inline void during_sample_enter(cpu_and_wall_time_worker_state* state) {
  // Tell the compiler it's not allowed to reorder the `during_sample` flag with anything that happens after.
  //
  // In a few cases, we may be checking this flag from a signal handler, so we need to make sure the compiler didn't
  // get clever and reordered things in such a way that makes us miss the flag update.
  //
  // See https://github.com/ruby/ruby/pull/11036 for a similar change made to the Ruby VM with more context.
  state->during_sample = true;
  atomic_signal_fence(memory_order_seq_cst);
}

static inline void during_sample_exit(cpu_and_wall_time_worker_state* state) {
  // See `during_sample_enter` for more context; in this case we set the fence before to make sure anything that
  // happens before the fence is not reordered with the flag update.
  atomic_signal_fence(memory_order_seq_cst);
  state->during_sample = false;
}
