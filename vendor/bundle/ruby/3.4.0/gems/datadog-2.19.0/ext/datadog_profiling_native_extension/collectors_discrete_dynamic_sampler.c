#include "collectors_discrete_dynamic_sampler.h"

#include <ruby.h>
#include "helpers.h"
#include "time_helpers.h"
#include "ruby_helpers.h"

#define BASE_OVERHEAD_PCT 1.0
#define BASE_SAMPLING_INTERVAL 50

#define ADJUSTMENT_WINDOW_NS SECONDS_AS_NS(1)
#define ADJUSTMENT_WINDOW_SAMPLES 100
// Any average sampling times above this value will be clamped to this value.
// In practice, this limits the budget consumption of a single sample to that of an adjustment window,
// thus aiming for a minimum sample rate of once per adjustment window (dependent on actual event rate).
// NOTE: This is our main strategy to deal with timing hiccups such as those that can be caused by
//       suspensions, system overloads and other things that could lead to arbitrarily big sampling
//       time measurements.
#define MAX_ALLOWED_SAMPLING_NS(target_overhead) (long) (ADJUSTMENT_WINDOW_NS * target_overhead / 100.)

#define EMA_SMOOTHING_FACTOR 0.6

static void maybe_readjust(discrete_dynamic_sampler *sampler, long now_ns);
static inline bool should_readjust(discrete_dynamic_sampler *sampler, coarse_instant now);

void discrete_dynamic_sampler_init(discrete_dynamic_sampler *sampler, const char *debug_name, long now_ns) {
  sampler->debug_name = debug_name;
  discrete_dynamic_sampler_set_overhead_target_percentage(sampler, BASE_OVERHEAD_PCT, now_ns);
}

void discrete_dynamic_sampler_reset(discrete_dynamic_sampler *sampler, long now_ns) {
  const char *debug_name = sampler->debug_name;
  double target_overhead = sampler->target_overhead;
  (*sampler) = (discrete_dynamic_sampler) {
    .debug_name = debug_name,
    .target_overhead = target_overhead,
    // Act as if a reset is a readjustment (it kinda is!) and wait for a full adjustment window
    // to compute stats. Otherwise, we'd readjust on the next event that comes and thus be operating
    // with very incomplete information
    .last_readjust_time_ns = now_ns,
    // This fake readjustment will use a hardcoded sampling interval
    .sampling_interval = BASE_SAMPLING_INTERVAL,
    .sampling_probability = 1.0 / BASE_SAMPLING_INTERVAL,
    .max_sampling_time_ns = MAX_ALLOWED_SAMPLING_NS(target_overhead),
    // But we want to make sure we sample at least once in the next window so that our first
    // real readjustment has some notion of how heavy sampling is. Therefore, we'll make it so that
    // the next event is automatically sampled by artificially locating it in the interval threshold.
    .events_since_last_sample = BASE_SAMPLING_INTERVAL - 1,
  };
}

void discrete_dynamic_sampler_set_overhead_target_percentage(discrete_dynamic_sampler *sampler, double target_overhead, long now_ns) {
  if (target_overhead <= 0 || target_overhead > 100) {
    rb_raise(rb_eArgError, "Target overhead must be a double between ]0,100] was %f", target_overhead);
  }
  sampler->target_overhead = target_overhead;
  return discrete_dynamic_sampler_reset(sampler, now_ns);
}

// NOTE: See header for an explanation of when this should get used
__attribute__((warn_unused_result))
bool discrete_dynamic_sampler_should_sample(discrete_dynamic_sampler *sampler) {
  // For efficiency reasons we don't do true random sampling but rather systematic
  // sampling following a sample interval/skip. This can be biased and hide patterns
  // but the dynamic interval and rather nondeterministic pattern of allocations in
  // most real applications should help reduce the bias impact.
  sampler->events_since_last_sample++;
  sampler->events_since_last_readjustment++;

  return sampler->sampling_interval > 0 && sampler->events_since_last_sample >= sampler->sampling_interval;
}

// NOTE: See header for an explanation of when this should get used
void discrete_dynamic_sampler_before_sample(discrete_dynamic_sampler *sampler, long now_ns) {
  sampler->sample_start_time_ns = now_ns;
}

// NOTE: See header for an explanation of when this should get used
long discrete_dynamic_sampler_after_sample(discrete_dynamic_sampler *sampler, long now_ns) {
  long last_sampling_time_ns = sampler->sample_start_time_ns == 0 ? 0 : long_max_of(0, now_ns - sampler->sample_start_time_ns);
  sampler->samples_since_last_readjustment++;
  sampler->sampling_time_since_last_readjustment_ns += last_sampling_time_ns;
  sampler->events_since_last_sample = 0;

  // check if we should readjust our sampler after this sample
  maybe_readjust(sampler, now_ns);

  return last_sampling_time_ns;
}

double discrete_dynamic_sampler_probability(discrete_dynamic_sampler *sampler) {
  return sampler->sampling_probability * 100.;
}

unsigned long discrete_dynamic_sampler_events_since_last_sample(discrete_dynamic_sampler *sampler) {
  return sampler->events_since_last_sample;
}

// NOTE: See header for an explanation of when this should get used
bool discrete_dynamic_sampler_skipped_sample(discrete_dynamic_sampler *sampler, coarse_instant now) {
  return should_readjust(sampler, now);
}

static double ewma_adj_window(double latest_value, double avg, long current_window_time_ns, bool is_first) {
  if (is_first) {
    return latest_value;
  }

  // We don't want samples coming from partial adjustment windows (e.g. preempted due to number of samples)
  // to lead to quick "forgetting" of the past. Thus, we'll tweak the weight of this new value based on the
  // size of the time window from which we gathered it in relation to our standard adjustment window time.
  double fraction_of_full_window = double_min_of((double) current_window_time_ns / ADJUSTMENT_WINDOW_NS, 1);
  double alpha = EMA_SMOOTHING_FACTOR * fraction_of_full_window;

  return (1-alpha) * avg + alpha * latest_value;
}

static void maybe_readjust(discrete_dynamic_sampler *sampler, long now_ns) {
  if (should_readjust(sampler, to_coarse_instant(now_ns))) discrete_dynamic_sampler_readjust(sampler, now_ns);
}

static inline bool should_readjust(discrete_dynamic_sampler *sampler, coarse_instant now) {
  long this_window_time_ns =
    sampler->last_readjust_time_ns == 0 ? ADJUSTMENT_WINDOW_NS : now.timestamp_ns - sampler->last_readjust_time_ns;

  bool should_readjust_based_on_time = this_window_time_ns >= ADJUSTMENT_WINDOW_NS;
  bool should_readjust_based_on_samples = sampler->samples_since_last_readjustment >= ADJUSTMENT_WINDOW_SAMPLES;

  return should_readjust_based_on_time || should_readjust_based_on_samples;
}

// NOTE: This method ASSUMES should_readjust == true
// NOTE: See header for an explanation of when this should get used
void discrete_dynamic_sampler_readjust(discrete_dynamic_sampler *sampler, long now_ns) {
  long this_window_time_ns = sampler->last_readjust_time_ns == 0 ? ADJUSTMENT_WINDOW_NS : now_ns - sampler->last_readjust_time_ns;

  if (this_window_time_ns <= 0) {
    // should not be possible given should_readjust but lets protect against div by 0 below.
    return;
  }

  // If we got this far, lets recalculate our sampling params based on new observations
  bool first_readjustment = !sampler->has_completed_full_adjustment_window;

  // Update our running average of events/sec with latest observation.
  sampler->events_per_ns = ewma_adj_window(
    (double) sampler->events_since_last_readjustment / this_window_time_ns,
    sampler->events_per_ns,
    this_window_time_ns,
    first_readjustment
  );

  // Update our running average of sampling time for a specific event
  if (sampler->samples_since_last_readjustment > 0) {
    // We can only update sampling-related stats if we actually sampled on the last window...

    // Lets update our average sampling time per event
    long avg_sampling_time_in_window_ns = sampler->samples_since_last_readjustment == 0 ? 0 : sampler->sampling_time_since_last_readjustment_ns / sampler->samples_since_last_readjustment;
    if (avg_sampling_time_in_window_ns > sampler->max_sampling_time_ns) {
      // If the average sampling time in the previous window was deemed unacceptable, clamp it to the
      // maximum acceptable value and register this operation in our counter.
      // NOTE: This is important so that events like suspensions or system overloads do not lead us to
      //       learn arbitrarily big sampling times which may then result in us not sampling anything
      //       for very long periods of time.
      avg_sampling_time_in_window_ns = sampler->max_sampling_time_ns;
      sampler->sampling_time_clamps++;
    }
    sampler->sampling_time_ns = ewma_adj_window(
      avg_sampling_time_in_window_ns,
      sampler->sampling_time_ns,
      this_window_time_ns,
      first_readjustment
    );
  }

  // Are we meeting our target in practice? If we're consistently overshooting our estimate due to non-uniform allocation patterns lets
  // adjust our overhead target.
  // NOTE: Updating this even when no samples occur is a conscious choice which enables us to cooldown extreme adjustments over time.
  //       If we didn't do this, whenever a big spike caused target_overhead_adjustment to equal target_overhead, we'd get stuck
  //       in a "probability = 0" state.
  long this_window_sampling_target_time_ns = this_window_time_ns * (sampler->target_overhead / 100.);
  // Overshoot by definition is always >= 0. < 0 would be undershooting!
  long this_window_sampling_overshoot_time_ns = long_max_of(0, sampler->sampling_time_since_last_readjustment_ns - this_window_sampling_target_time_ns);
  // Our overhead adjustment should always be between [-target_overhead, 0]. Higher adjustments would lead to negative overhead targets
  // which don't make much sense.
  double last_target_overhead_adjustment = -double_min_of(sampler->target_overhead, this_window_sampling_overshoot_time_ns * 100. / this_window_time_ns);
  sampler->target_overhead_adjustment = ewma_adj_window(
    last_target_overhead_adjustment,
    sampler->target_overhead_adjustment,
    this_window_time_ns,
    first_readjustment
  );

  // Apply our overhead adjustment to figure out our real targets for this readjustment.
  double target_overhead = double_max_of(0, sampler->target_overhead + sampler->target_overhead_adjustment);

  // Recalculate target sampling probability so that the following 2 hold:
  // * window_time_ns = working_window_time_ns + sampling_window_time_ns
  //       │                     │                        │
  //       │                     │                        └ how much time is spent sampling
  //       │                     └── how much time is spent doing actual app stuff
  //       └── total (wall) time in this adjustment window
  // * sampling_window_time_ns <= window_time_ns * target_overhead / 100
  //
  // Note that
  //
  //   sampling_window_time_ns = samples_in_window * sampling_time_ns =
  //                                                ┌─ assuming no events will be emitted during sampling
  //                                                │
  //                           = events_per_ns * working_window_time_ns * sampling_probability * sampling_time_ns
  //                           = events_per_ns * (window_time_ns - sampling_window_time_ns) * sampling_probability * sampling_time_ns
  //
  // Re-ordering for sampling_probability and solving for the upper-bound of sampling_window_time_ns:
  //
  //   sampling_window_time_ns = window_time_ns * target_overhead / 100
  //   sampling_probability = (sampling_window_time_ns) / (events_per_ns * sampling_time_ns * (window_time_ns - sampling_window_time_ns))
  //                        = (window_time_ns * target_overhead / 100) / (events_per_ns * sampling_time_ns * window_time_ns * (1 - target_overhead / 100))
  //
  // Which you can intuitively understand as:
  //
  //   sampling_probability = max_allowed_time_for_sampling_ns / time_to_sample_all_events_ns
  //
  // As a quick sanity check:
  // * If app is eventing very little or we're sampling very fast, so that time_to_sample_all_events_ns < max_allowed_time_for_sampling_ns
  //   then probability will be > 1 (but we should clamp to 1 since probabilities higher than 1 don't make sense).
  // * If app is eventing a lot or our sampling overhead is big, then as time_to_sample_all_events_ns grows, sampling_probability will
  //   tend to 0.
  //
  // In fact, we can simplify the equation further since the `window_time_ns` components cancel each other out:
  //
  //   sampling_probability = (target_overhead / 100) / (events_per_ns * sampling_time_ns * (1 - target_overhead / 100))
  //                        = max_sampling_overhead / avg_sampling_overhead

  double max_sampling_overhead = target_overhead / 100.;
  double avg_sampling_overhead = sampler->events_per_ns * sampler->sampling_time_ns * (1 - max_sampling_overhead);

  if (max_sampling_overhead == 0) {
    // if we aren't allowed any sampling overhead at all, probability has to be 0
    sampler->sampling_probability = 0;
  } else {
    // otherwise apply the formula described above (protecting against div by 0)
    sampler->sampling_probability = avg_sampling_overhead == 0 ? 1. :
      double_min_of(1., max_sampling_overhead / avg_sampling_overhead);
  }

  // Doing true random selection would involve "tossing a coin" on every allocation. Lets do systematic sampling instead so that our
  // sampling decision can rely solely on a sampling skip/interval (i.e. more efficient).
  //
  //   sampling_interval = events / samples =
  //                     = event_rate * working_window_time_ns / (event_rate * working_window_time_ns * sampling_probability)
  //                     = 1 / sampling_probability
  //
  // NOTE: The sampling interval has to be an integer since we're dealing with discrete events here. This means that there'll be
  //       a loss of precision (and thus control) when adjusting between probabilities that lead to non-integer granularity
  //       changes (e.g. probabilities in the range of ]50%, 100%[ which map to intervals in the range of ]1, 2[). Our approach
  //       when the sampling interval is a non-integer is to ceil it (i.e. we'll always choose to sample less often).
  // NOTE: Overhead target adjustments or very big sampling times can in theory bring probability so close to 0 as to effectively
  //       round down to full 0. This means we have to be careful to handle div-by-0 as well as resulting double intervals that
  //       are so big they don't fit into the sampling_interval. In both cases lets just disable sampling until next readjustment
  //       by setting interval to 0.
  double sampling_interval = sampler->sampling_probability == 0 ? 0 : ceil(1.0 / sampler->sampling_probability);
  // NOTE: We use UINT32_MAX instead of ULONG_MAX here to avoid clang warnings; in practice, we shouldn't ever hit
  // such high sampling intervals.
  sampler->sampling_interval = sampling_interval > UINT32_MAX ? 0 : sampling_interval;

  #ifdef DD_DEBUG
    double allocs_in_60s = sampler->events_per_ns * 1e9 * 60;
    double samples_in_60s = allocs_in_60s * sampler->sampling_probability;
    double expected_total_sampling_time_in_60s =
      samples_in_60s * sampler->sampling_time_ns / 1e9;
    double num_this_windows_in_60s = 60 * 1e9 / this_window_time_ns;
    double real_total_sampling_time_in_60s = sampler->sampling_time_since_last_readjustment_ns * num_this_windows_in_60s / 1e9;

    fprintf(stderr, "[dds.%s] readjusting...\n", sampler->debug_name);
    fprintf(stderr, "events_since_last_readjustment=%ld\n", sampler->events_since_last_readjustment);
    fprintf(stderr, "samples_since_last_readjustment=%ld\n", sampler->samples_since_last_readjustment);
    fprintf(stderr, "this_window_time=%ld\n", this_window_time_ns);
    fprintf(stderr, "this_window_sampling_time=%ld\n", sampler->sampling_time_since_last_readjustment_ns);
    fprintf(stderr, "this_working_window_time=%ld\n", this_window_time_ns - sampler->sampling_time_since_last_readjustment_ns);
    fprintf(stderr, "this_window_sampling_target_time=%ld\n", this_window_sampling_target_time_ns);
    fprintf(stderr, "this_window_sampling_overshoot_time=%ld\n", this_window_sampling_overshoot_time_ns);
    fprintf(stderr, "\n");
    fprintf(stderr, "target_overhead=%f\n", sampler->target_overhead);
    fprintf(stderr, "target_overhead_adjustment=%f\n", sampler->target_overhead_adjustment);
    fprintf(stderr, "events_per_sec=%f\n", sampler->events_per_ns * 1e9);
    fprintf(stderr, "sampling_time=%ld\n", sampler->sampling_time_ns);
    fprintf(stderr, "avg_sampling_overhead=%f\n", avg_sampling_overhead * 100);
    fprintf(stderr, "sampling_interval=%zu\n", sampler->sampling_interval);
    fprintf(stderr, "sampling_probability=%f\n", sampler->sampling_probability * 100);
    fprintf(stderr, "\n");
    fprintf(stderr, "expected allocs in 60s=%f\n", allocs_in_60s);
    fprintf(stderr, "expected samples in 60s=%f\n", samples_in_60s);
    fprintf(stderr, "expected sampling time in 60s=%f (previous real=%f)\n", expected_total_sampling_time_in_60s, real_total_sampling_time_in_60s);
    fprintf(stderr, "expected max overhead in 60s=%f\n", target_overhead / 100.0 * 60);
    fprintf(stderr, "\n");
    fprintf(stderr, "sampling_time_clamps=%zu\n", sampler->sampling_time_clamps);
    fprintf(stderr, "-------\n");
  #endif

  sampler->events_since_last_readjustment = 0;
  sampler->samples_since_last_readjustment = 0;
  sampler->sampling_time_since_last_readjustment_ns = 0;
  sampler->last_readjust_time_ns = now_ns;
  sampler->has_completed_full_adjustment_window = true;
}

VALUE discrete_dynamic_sampler_state_snapshot(discrete_dynamic_sampler *sampler) {
  VALUE arguments[] = {
    ID2SYM(rb_intern("target_overhead")),                 /* => */ DBL2NUM(sampler->target_overhead),
    ID2SYM(rb_intern("target_overhead_adjustment")),      /* => */ DBL2NUM(sampler->target_overhead_adjustment),
    ID2SYM(rb_intern("events_per_sec")),                  /* => */ DBL2NUM(sampler->events_per_ns * 1e9),
    ID2SYM(rb_intern("sampling_time_ns")),                /* => */ LONG2NUM(sampler->sampling_time_ns),
    ID2SYM(rb_intern("sampling_interval")),               /* => */ ULONG2NUM(sampler->sampling_interval),
    ID2SYM(rb_intern("sampling_probability")),            /* => */ DBL2NUM(sampler->sampling_probability * 100),
    ID2SYM(rb_intern("events_since_last_readjustment")),  /* => */ ULONG2NUM(sampler->events_since_last_readjustment),
    ID2SYM(rb_intern("samples_since_last_readjustment")), /* => */ ULONG2NUM(sampler->samples_since_last_readjustment),
    ID2SYM(rb_intern("max_sampling_time_ns")),            /* => */ LONG2NUM(sampler->max_sampling_time_ns),
    ID2SYM(rb_intern("sampling_time_clamps")),            /* => */ ULONG2NUM(sampler->sampling_time_clamps),
  };
  VALUE hash = rb_hash_new();
  for (long unsigned int i = 0; i < VALUE_COUNT(arguments); i += 2) rb_hash_aset(hash, arguments[i], arguments[i+1]);
  return hash;
}

// ---
// Below here is boilerplate to expose the above code to Ruby so that we can test it with RSpec as usual.

static VALUE _native_new(VALUE klass);
static VALUE _native_initialize(VALUE self, VALUE now);
static VALUE _native_reset(VALUE self, VALUE now);
static VALUE _native_set_overhead_target_percentage(VALUE self, VALUE target_overhead, VALUE now);
static VALUE _native_should_sample(VALUE self, VALUE now);
static VALUE _native_after_sample(VALUE self, VALUE now);
static VALUE _native_state_snapshot(VALUE self);

typedef struct {
  discrete_dynamic_sampler sampler;
} sampler_state;

void collectors_discrete_dynamic_sampler_init(VALUE profiling_module) {
  VALUE collectors_module = rb_define_module_under(profiling_module, "Collectors");
  VALUE discrete_sampler_module = rb_define_module_under(collectors_module, "DiscreteDynamicSampler");
  VALUE testing_module = rb_define_module_under(discrete_sampler_module, "Testing");
  VALUE sampler_class = rb_define_class_under(testing_module, "Sampler", rb_cObject);

  rb_define_alloc_func(sampler_class, _native_new);
  // NOTE: Despite being native, we're using the normal ruby keyword to prevent having to write a whole
  //       new ruby file to simply proxy the initialization call.
  rb_define_method(sampler_class, "initialize", _native_initialize, 1);

  rb_define_method(sampler_class, "_native_reset", _native_reset, 1);
  rb_define_method(sampler_class, "_native_set_overhead_target_percentage", _native_set_overhead_target_percentage, 2);
  rb_define_method(sampler_class, "_native_should_sample", _native_should_sample, 1);
  rb_define_method(sampler_class, "_native_after_sample", _native_after_sample, 1);
  rb_define_method(sampler_class, "_native_state_snapshot", _native_state_snapshot, 0);
}

static const rb_data_type_t sampler_typed_data = {
  .wrap_struct_name = "Datadog::Profiling::DiscreteDynamicSampler::Testing::Sampler",
  .function = {
    .dfree = RUBY_DEFAULT_FREE,
    .dsize = NULL,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE _native_new(VALUE klass) {
  sampler_state *state = ruby_xcalloc(sizeof(sampler_state), 1);

  long now_ns = monotonic_wall_time_now_ns(DO_NOT_RAISE_ON_FAILURE);
  if (now_ns == 0) {
    rb_raise(rb_eRuntimeError, "failed to get clock time");
  }
  discrete_dynamic_sampler_init(&state->sampler, "test sampler", now_ns);

  // Note: As of this writing, no new Ruby objects get created and stored in the state. If that ever changes, remember
  // to keep them on the stack and mark them with RB_GC_GUARD -- otherwise it's possible for a GC to run and
  // since the instance representing the state does not yet exist, such objects will not get marked.

  return TypedData_Wrap_Struct(klass, &sampler_typed_data, state);
}

static VALUE _native_initialize(VALUE self, VALUE now_ns) {
  ENFORCE_TYPE(now_ns, T_FIXNUM);

  sampler_state *state;
  TypedData_Get_Struct(self, sampler_state, &sampler_typed_data, state);

  discrete_dynamic_sampler_init(&state->sampler, "test sampler", NUM2LONG(now_ns));

  return Qtrue;
}

static VALUE _native_reset(VALUE self, VALUE now_ns) {
  ENFORCE_TYPE(now_ns, T_FIXNUM);

  sampler_state *state;
  TypedData_Get_Struct(self, sampler_state, &sampler_typed_data, state);

  discrete_dynamic_sampler_reset(&state->sampler, NUM2LONG(now_ns));

  return Qnil;
}

static VALUE _native_set_overhead_target_percentage(VALUE self, VALUE target_overhead, VALUE now_ns) {
  ENFORCE_TYPE(target_overhead, T_FLOAT);
  ENFORCE_TYPE(now_ns, T_FIXNUM);

  sampler_state *state;
  TypedData_Get_Struct(self, sampler_state, &sampler_typed_data, state);

  discrete_dynamic_sampler_set_overhead_target_percentage(&state->sampler, NUM2DBL(target_overhead), NUM2LONG(now_ns));

  return Qnil;
}

VALUE _native_should_sample(VALUE self, VALUE now_ns) {
  ENFORCE_TYPE(now_ns, T_FIXNUM);

  sampler_state *state;
  TypedData_Get_Struct(self, sampler_state, &sampler_typed_data, state);

  if (discrete_dynamic_sampler_should_sample(&state->sampler)) {
    discrete_dynamic_sampler_before_sample(&state->sampler, NUM2LONG(now_ns));
    return Qtrue;
  } else {
    bool needs_readjust = discrete_dynamic_sampler_skipped_sample(&state->sampler, to_coarse_instant(NUM2LONG(now_ns)));
    if (needs_readjust) discrete_dynamic_sampler_readjust(&state->sampler, NUM2LONG(now_ns));
    return Qfalse;
  }
}

VALUE _native_after_sample(VALUE self, VALUE now_ns) {
  ENFORCE_TYPE(now_ns, T_FIXNUM);

  sampler_state *state;
  TypedData_Get_Struct(self, sampler_state, &sampler_typed_data, state);

  return LONG2NUM(discrete_dynamic_sampler_after_sample(&state->sampler, NUM2LONG(now_ns)));
}

VALUE _native_state_snapshot(VALUE self) {
  sampler_state *state;
  TypedData_Get_Struct(self, sampler_state, &sampler_typed_data, state);

  return discrete_dynamic_sampler_state_snapshot(&state->sampler);
}
