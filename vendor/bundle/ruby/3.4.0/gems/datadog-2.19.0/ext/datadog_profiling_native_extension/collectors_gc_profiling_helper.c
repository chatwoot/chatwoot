#include <ruby.h>
#include <datadog/profiling.h>

#include "collectors_gc_profiling_helper.h"

// This helper is used by the Datadog::Profiling::Collectors::ThreadContext to profile garbage collection.
// It's tested through that class' interfaces.
// ---

// Used when retrieving GC information from the VM.
//  All these are symbols, but we don't need to mark them since we ask for them to be interned (and thus live forever)
static VALUE state_sym;
static VALUE marking_sym;
static VALUE sweeping_sym;
static VALUE none_sym;
static VALUE gc_by_sym;
static VALUE newobj_sym;
static VALUE malloc_sym;
static VALUE method_sym;
static VALUE capi_sym;
static VALUE stress_sym;
static VALUE major_by_sym;
static VALUE nofree_sym;
static VALUE oldgen_sym;
static VALUE shady_sym;
static VALUE force_sym;
static VALUE oldmalloc_sym;

static ddog_CharSlice major_gc_reason_pretty(VALUE major_gc_reason);
static ddog_CharSlice gc_cause_pretty(VALUE gc_cause);
static ddog_CharSlice gc_type_pretty(VALUE major_gc_reason, VALUE gc_state);

void gc_profiling_init(void) {
  // This function lazy-interns a few constants, which may trigger allocations. Since we want to call it during GC as
  // well, when allocations are not allowed, we call it once here so that the constants get defined ahead of time.
  rb_gc_latest_gc_info(rb_hash_new());

  // Used to query and look up the results of GC information
  state_sym     = ID2SYM(rb_intern_const("state"));
  marking_sym   = ID2SYM(rb_intern_const("marking"));
  sweeping_sym  = ID2SYM(rb_intern_const("sweeping"));
  none_sym      = ID2SYM(rb_intern_const("none"));
  gc_by_sym     = ID2SYM(rb_intern_const("gc_by"));
  newobj_sym    = ID2SYM(rb_intern_const("newobj"));
  malloc_sym    = ID2SYM(rb_intern_const("malloc"));
  method_sym    = ID2SYM(rb_intern_const("method"));
  capi_sym      = ID2SYM(rb_intern_const("capi"));
  stress_sym    = ID2SYM(rb_intern_const("stress"));
  major_by_sym  = ID2SYM(rb_intern_const("major_by"));
  nofree_sym    = ID2SYM(rb_intern_const("nofree"));
  oldgen_sym    = ID2SYM(rb_intern_const("oldgen"));
  shady_sym     = ID2SYM(rb_intern_const("shady"));
  force_sym     = ID2SYM(rb_intern_const("force"));
  oldmalloc_sym = ID2SYM(rb_intern_const("oldmalloc"));
  state_sym     = ID2SYM(rb_intern_const("state"));
  none_sym      = ID2SYM(rb_intern_const("none"));
}

bool gc_profiling_has_major_gc_finished(void) {
  return rb_gc_latest_gc_info(state_sym) == none_sym && rb_gc_latest_gc_info(major_by_sym) != Qnil;
}

uint8_t gc_profiling_set_metadata(ddog_prof_Label *labels, int labels_length) {
  uint8_t max_label_count =
    1 + // thread id
    1 + // thread name
    1 + // state
    1 + // event
    1 + // gc reason
    1 + // gc cause
    1;  // gc type

  if (max_label_count > labels_length) {
    rb_raise(rb_eArgError, "BUG: gc_profiling_set_metadata invalid labels_length (%d) < max_label_count (%d)", labels_length, max_label_count);
  }

  uint8_t label_pos = 0;

  labels[label_pos++] = (ddog_prof_Label) {
    .key = DDOG_CHARSLICE_C("thread id"),
    .str = DDOG_CHARSLICE_C("GC"),
    .num = 0, // This shouldn't be needed but the tracer-2.7 docker image ships a buggy gcc that complains about this
  };

  labels[label_pos++] = (ddog_prof_Label) {
    .key = DDOG_CHARSLICE_C("thread name"),
    .str = DDOG_CHARSLICE_C("Garbage Collection"),
    .num = 0, // Workaround, same as above
  };

  labels[label_pos++] = (ddog_prof_Label) {
    .key = DDOG_CHARSLICE_C("state"),
    .str = DDOG_CHARSLICE_C("had cpu"),
    .num = 0, // Workaround, same as above
  };

  labels[label_pos++] = (ddog_prof_Label) {
    .key = DDOG_CHARSLICE_C("event"),
    .str = DDOG_CHARSLICE_C("gc"),
    .num = 0, // Workaround, same as above
  };

  VALUE major_by = rb_gc_latest_gc_info(major_by_sym);
  if (major_by != Qnil) {
    labels[label_pos++] = (ddog_prof_Label) {
      .key = DDOG_CHARSLICE_C("gc reason"),
      .str = major_gc_reason_pretty(major_by),
    };
  }

  labels[label_pos++] = (ddog_prof_Label) {
    .key = DDOG_CHARSLICE_C("gc cause"),
    .str = gc_cause_pretty(rb_gc_latest_gc_info(gc_by_sym)),
  };

  labels[label_pos++] = (ddog_prof_Label) {
    .key = DDOG_CHARSLICE_C("gc type"),
    .str = gc_type_pretty(major_by, rb_gc_latest_gc_info(state_sym)),
  };

  if (label_pos > max_label_count) {
    rb_raise(rb_eRuntimeError, "BUG: gc_profiling_set_metadata unexpected label_pos (%d) > max_label_count (%d)", label_pos, max_label_count);
  }

  return label_pos;
}

static ddog_CharSlice major_gc_reason_pretty(VALUE major_gc_reason) {
  if (major_gc_reason == nofree_sym   ) return DDOG_CHARSLICE_C("not enough free slots (NOFREE)");
  if (major_gc_reason == oldgen_sym   ) return DDOG_CHARSLICE_C("old generation full (OLDGEN)");
  if (major_gc_reason == shady_sym    ) return DDOG_CHARSLICE_C("too many objects without write barriers (SHADY)");
  if (major_gc_reason == force_sym    ) return DDOG_CHARSLICE_C("requested (FORCE)");
  if (major_gc_reason == oldmalloc_sym) return DDOG_CHARSLICE_C("heap bytes allocated threshold (OLDMALLOC)");
  return DDOG_CHARSLICE_C("unknown");
}

static ddog_CharSlice gc_cause_pretty(VALUE gc_cause) {
  if (gc_cause == newobj_sym) return DDOG_CHARSLICE_C("object allocation");
  if (gc_cause == malloc_sym) return DDOG_CHARSLICE_C("malloc()");
  if (gc_cause == method_sym) return DDOG_CHARSLICE_C("GC.start()");
  if (gc_cause == capi_sym  ) return DDOG_CHARSLICE_C("rb_gc()");
  if (gc_cause == stress_sym) return DDOG_CHARSLICE_C("stress");
  return DDOG_CHARSLICE_C("unknown");
}

static ddog_CharSlice gc_type_pretty(VALUE major_gc_reason, VALUE gc_state) {
  if (major_gc_reason != Qnil) {
    if (gc_state == marking_sym ) return DDOG_CHARSLICE_C("major (ongoing, marking)");
    if (gc_state == sweeping_sym) return DDOG_CHARSLICE_C("major (ongoing, sweeping)");
    return DDOG_CHARSLICE_C("major");
  } else {
    // As we delay flushing events when a minor GC finishes, it's not relevant to include the observed state of the
    // minor GC, as we often won't record a marking -> sweeping -> done cycle, as it happens too quickly.
    return DDOG_CHARSLICE_C("minor");
  }
}
