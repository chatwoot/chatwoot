#include "byebug.h"

static VALUE cContext;
static VALUE cDebugThread;
static int thnum_max = 0;

/* "Step", "Next" and "Finish" do their work by saving information about where
 * to stop next. byebug_reset_stepping_stop_points removes/resets this information. */
extern void
byebug_reset_stepping_stop_points(debug_context_t *context)
{
  context->dest_frame = -1;
  context->lines = -1;
  context->steps = -1;
  context->steps_out = -1;
}

/*
 *  call-seq:
 *    context.dead? -> bool
 *
 *  Returns +true+ if context doesn't represent a live context and is created
 *  during post-mortem exception handling.
 */
static inline VALUE
Context_dead(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_DEAD) ? Qtrue : Qfalse;
}

static void
context_mark(void *data)
{
  debug_context_t *context = (debug_context_t *)data;

  rb_gc_mark(context->backtrace);
}

static VALUE
dc_backtrace(const debug_context_t *context)
{
  return context->backtrace;
}

static int
dc_stack_size(debug_context_t *context)
{

  if (NIL_P(dc_backtrace(context)))
    return 0;

  return RARRAY_LENINT(dc_backtrace(context));
}

extern VALUE
byebug_context_create(VALUE thread)
{
  debug_context_t *context = ALLOC(debug_context_t);

  context->flags = 0;
  context->thnum = ++thnum_max;
  context->thread = thread;
  byebug_reset_stepping_stop_points(context);
  context->stop_reason = CTX_STOP_NONE;

  rb_debug_inspector_open(context_backtrace_set, (void *)context);
  context->calced_stack_size = dc_stack_size(context) + 1;

  if (rb_obj_class(thread) == cDebugThread)
    CTX_FL_SET(context, CTX_FL_IGNORE);

  return Data_Wrap_Struct(cContext, context_mark, 0, context);
}

extern VALUE
context_dup(debug_context_t *context)
{
  debug_context_t *new_context = ALLOC(debug_context_t);

  memcpy(new_context, context, sizeof(debug_context_t));
  byebug_reset_stepping_stop_points(new_context);
  new_context->backtrace = context->backtrace;
  CTX_FL_SET(new_context, CTX_FL_DEAD);

  return Data_Wrap_Struct(cContext, context_mark, 0, new_context);
}


static VALUE
dc_frame_get(const debug_context_t *context, int frame_index, frame_part type)
{
  VALUE frame;

  if (NIL_P(dc_backtrace(context)))
    rb_raise(rb_eRuntimeError, "Backtrace information is not available");

  if (frame_index >= RARRAY_LENINT(dc_backtrace(context)))
    rb_raise(rb_eRuntimeError, "That frame doesn't exist!");

  frame = rb_ary_entry(dc_backtrace(context), frame_index);
  return rb_ary_entry(frame, type);
}

static VALUE
dc_frame_location(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, LOCATION);
}

static VALUE
dc_frame_self(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, SELF);
}

static VALUE
dc_frame_class(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, CLASS);
}

static VALUE
dc_frame_binding(const debug_context_t *context, int frame_index)
{
  return dc_frame_get(context, frame_index, BINDING);
}

static VALUE
load_backtrace(const rb_debug_inspector_t *inspector)
{
  VALUE backtrace = rb_ary_new();
  VALUE locs = rb_debug_inspector_backtrace_locations(inspector);
  int i;

  for (i = 0; i < RARRAY_LENINT(locs); i++)
  {
    VALUE frame = rb_ary_new();

    rb_ary_push(frame, rb_ary_entry(locs, i));
    rb_ary_push(frame, rb_debug_inspector_frame_self_get(inspector, i));
    rb_ary_push(frame, rb_debug_inspector_frame_class_get(inspector, i));
    rb_ary_push(frame, rb_debug_inspector_frame_binding_get(inspector, i));

    rb_ary_push(backtrace, frame);
  }

  return backtrace;
}

extern VALUE
context_backtrace_set(const rb_debug_inspector_t *inspector, void *data)
{
  debug_context_t *dc = (debug_context_t *)data;

  dc->backtrace = load_backtrace(inspector);

  return Qnil;
}

static VALUE
open_debug_inspector_i(const rb_debug_inspector_t *inspector, void *data)
{
  struct call_with_inspection_data *cwi =
    (struct call_with_inspection_data *)data;

  cwi->dc->backtrace = load_backtrace(inspector);

  return rb_funcall2(cwi->ctx, cwi->id, cwi->argc, cwi->argv);
}

static VALUE
open_debug_inspector(struct call_with_inspection_data *cwi)
{
  return rb_debug_inspector_open(open_debug_inspector_i, cwi);
}

static VALUE
open_debug_inspector_ensure(VALUE v)
{
  return open_debug_inspector((struct call_with_inspection_data *)v);
}


static VALUE
close_debug_inspector(struct call_with_inspection_data *cwi)
{
  cwi->dc->backtrace = Qnil;
  return Qnil;
}

static VALUE
close_debug_inspector_ensure(VALUE v)
{
  return close_debug_inspector((struct call_with_inspection_data *)v);
}

extern VALUE
call_with_debug_inspector(struct call_with_inspection_data *data)
{
  return rb_ensure(open_debug_inspector_ensure, (VALUE)data, close_debug_inspector_ensure,
                   (VALUE)data);
}

#define FRAME_SETUP                                \
  debug_context_t *context;                        \
  VALUE frame_no;                                  \
  int frame_n;                                     \
  Data_Get_Struct(self, debug_context_t, context); \
  if (!rb_scan_args(argc, argv, "01", &frame_no))  \
    frame_n = 0;                                   \
  else                                             \
    frame_n = FIX2INT(frame_no);

/*
 *  call-seq:
 *    context.frame_binding(frame_position = 0) -> binding
 *
 *  Returns frame's binding.
 */
static VALUE
Context_frame_binding(int argc, VALUE *argv, VALUE self)
{
  FRAME_SETUP;

  return dc_frame_binding(context, frame_n);
}

/*
 *  call-seq:
 *    context.frame_class(frame_position = 0) -> class
 *
 *  Returns frame's defined class.
 */
static VALUE
Context_frame_class(int argc, VALUE *argv, VALUE self)
{
  FRAME_SETUP;

  return dc_frame_class(context, frame_n);
}

/*
 *  call-seq:
 *    context.frame_file(frame_position = 0) -> string
 *
 *  Returns the name of the file in the frame.
 */
static VALUE
Context_frame_file(int argc, VALUE *argv, VALUE self)
{
  VALUE loc, absolute_path;

  FRAME_SETUP;

  loc = dc_frame_location(context, frame_n);

  absolute_path = rb_funcall(loc, rb_intern("absolute_path"), 0);

  if (!NIL_P(absolute_path))
    return absolute_path;

  return rb_funcall(loc, rb_intern("path"), 0);
}

/*
 *  call-seq:
 *    context.frame_line(frame_position = 0) -> int
 *
 *  Returns the line number in the file in the frame.
 */
static VALUE
Context_frame_line(int argc, VALUE *argv, VALUE self)
{
  VALUE loc;

  FRAME_SETUP;

  loc = dc_frame_location(context, frame_n);

  return rb_funcall(loc, rb_intern("lineno"), 0);
}

/*
 *  call-seq:
 *    context.frame_method(frame_position = 0) -> sym
 *
 *  Returns the sym of the method in the frame.
 */
static VALUE
Context_frame_method(int argc, VALUE *argv, VALUE self)
{
  VALUE loc;

  FRAME_SETUP;

  loc = dc_frame_location(context, frame_n);

  return rb_str_intern(rb_funcall(loc, rb_intern("label"), 0));
}

/*
 *  call-seq:
 *    context.frame_self(frame_postion = 0) -> obj
 *
 *  Returns self object of the frame.
 */
static VALUE
Context_frame_self(int argc, VALUE *argv, VALUE self)
{
  FRAME_SETUP;

  return dc_frame_self(context, frame_n);
}

/*
 *  call-seq:
 *    context.ignored? -> bool
 *
 *  Returns the ignore flag for the context, which marks whether the associated
 *  thread is ignored while debugging.
 */
static inline VALUE
Context_ignored(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_IGNORE) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *    context.resume -> nil
 *
 *  Resumes thread from the suspended mode.
 */
static VALUE
Context_resume(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  if (!CTX_FL_TEST(context, CTX_FL_SUSPEND))
    return Qnil;

  CTX_FL_UNSET(context, CTX_FL_SUSPEND);

  if (CTX_FL_TEST(context, CTX_FL_WAS_RUNNING))
    rb_thread_wakeup(context->thread);

  return Qnil;
}

/*
 *  call-seq:
 *    context.backtrace-> Array
 *
 *  Returns the frame stack of a context.
 */
static inline VALUE
Context_backtrace(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  return dc_backtrace(context);
}

static VALUE
Context_stop_reason(VALUE self)
{
  debug_context_t *context;
  const char *symbol;

  Data_Get_Struct(self, debug_context_t, context);

  if (CTX_FL_TEST(context, CTX_FL_DEAD))
    symbol = "post-mortem";
  else
    switch (context->stop_reason)
    {
      case CTX_STOP_STEP:
        symbol = "step";
        break;
      case CTX_STOP_BREAKPOINT:
        symbol = "breakpoint";
        break;
      case CTX_STOP_CATCHPOINT:
        symbol = "catchpoint";
        break;
      case CTX_STOP_NONE:
      default:
        symbol = "none";
    }
  return ID2SYM(rb_intern(symbol));
}

/*
 *  call-seq:
 *    context.step_into(steps, frame = 0)
 *
 *  Stops the current context after a number of +steps+ are made from frame
 *  +frame+ (by default the newest one).
 */
static VALUE
Context_step_into(int argc, VALUE *argv, VALUE self)
{
  VALUE steps, v_frame;
  int n_args, from_frame;
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  if (context->calced_stack_size == 0)
    rb_raise(rb_eRuntimeError, "No frames collected.");

  n_args = rb_scan_args(argc, argv, "11", &steps, &v_frame);

  if (FIX2INT(steps) <= 0)
    rb_raise(rb_eRuntimeError, "Steps argument must be positive.");

  from_frame = n_args == 1 ? 0 : FIX2INT(v_frame);

  if (from_frame < 0 || from_frame >= context->calced_stack_size)
    rb_raise(rb_eRuntimeError, "Destination frame (%d) is out of range (%d)",
             from_frame, context->calced_stack_size);
  else if (from_frame > 0)
    CTX_FL_SET(context, CTX_FL_IGNORE_STEPS);

  context->steps = FIX2INT(steps);
  context->dest_frame = context->calced_stack_size - from_frame;

  return steps;
}

/*
 *  call-seq:
 *    context.step_out(n_frames = 1, force = false)
 *
 *  Stops after +n_frames+ frames are finished. +force+ parameter (if true)
 *  ensures that the execution will stop in the specified frame even when there
 *  are no more instructions to run. In that case, it will stop when the return
 *  event for that frame is triggered.
 */
static VALUE
Context_step_out(int argc, VALUE *argv, VALUE self)
{
  int n_args, n_frames;
  VALUE v_frames, force;
  debug_context_t *context;

  n_args = rb_scan_args(argc, argv, "02", &v_frames, &force);
  n_frames = n_args == 0 ? 1 : FIX2INT(v_frames);

  Data_Get_Struct(self, debug_context_t, context);

  if (n_frames < 0 || n_frames > context->calced_stack_size)
    rb_raise(rb_eRuntimeError,
             "You want to finish %d frames, but stack size is only %d",
             n_frames, context->calced_stack_size);

  context->steps_out = n_frames;
  if (n_args == 2 && RTEST(force))
    CTX_FL_SET(context, CTX_FL_STOP_ON_RET);
  else
    CTX_FL_UNSET(context, CTX_FL_STOP_ON_RET);

  return Qnil;
}

/*
 *  call-seq:
 *    context.step_over(lines, frame = 0)
 *
 *  Steps over +lines+ lines in frame +frame+ (by default the newest one) or
 *  higher (if frame +frame+ finishes).
 */
static VALUE
Context_step_over(int argc, VALUE *argv, VALUE self)
{
  int n_args, frame;
  VALUE lines, v_frame;
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  if (context->calced_stack_size == 0)
    rb_raise(rb_eRuntimeError, "No frames collected.");

  n_args = rb_scan_args(argc, argv, "11", &lines, &v_frame);
  frame = n_args == 1 ? 0 : FIX2INT(v_frame);

  if (frame < 0 || frame >= context->calced_stack_size)
    rb_raise(rb_eRuntimeError, "Destination frame (%d) is out of range (%d)",
             frame, context->calced_stack_size);

  context->lines = FIX2INT(lines);
  context->dest_frame = context->calced_stack_size - frame;

  return Qnil;
}

/*
 *  call-seq:
 *    context.suspend -> nil
 *
 *  Suspends the thread when it is running.
 */
static VALUE
Context_suspend(VALUE self)
{
  VALUE status;
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  status = rb_funcall(context->thread, rb_intern("status"), 0);

  if (rb_str_cmp(status, rb_str_new2("run")) == 0)
    CTX_FL_SET(context, CTX_FL_WAS_RUNNING);
  else if (rb_str_cmp(status, rb_str_new2("sleep")) == 0)
    CTX_FL_UNSET(context, CTX_FL_WAS_RUNNING);
  else
    return Qnil;

  CTX_FL_SET(context, CTX_FL_SUSPEND);

  return Qnil;
}

/*
 *  call-seq:
 *    context.switch -> nil
 *
 *  Switches execution to this context.
 */
static VALUE
Context_switch(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  next_thread = context->thread;

  context->steps = 1;
  context->steps_out = 0;
  CTX_FL_SET(context, CTX_FL_STOP_ON_RET);

  return Qnil;
}

/*
 *  call-seq:
 *    context.suspended? -> bool
 *
 *  Returns +true+ if the thread is suspended by debugger.
 */
static VALUE
Context_is_suspended(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  return CTX_FL_TEST(context, CTX_FL_SUSPEND) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *    context.thnum -> int
 *
 *  Returns the context's number.
 */
static inline VALUE
Context_thnum(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  return INT2FIX(context->thnum);
}

/*
 *  call-seq:
 *    context.thread -> thread
 *
 *  Returns the thread this context is associated with.
 */
static inline VALUE
Context_thread(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  return context->thread;
}

/*
 *  call-seq:
 *    context.tracing -> bool
 *
 *  Returns the tracing flag for the current context.
 */
static VALUE
Context_tracing(VALUE self)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);
  return CTX_FL_TEST(context, CTX_FL_TRACING) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *    context.tracing = bool
 *
 *  Controls the tracing for this context.
 */
static VALUE
Context_set_tracing(VALUE self, VALUE value)
{
  debug_context_t *context;

  Data_Get_Struct(self, debug_context_t, context);

  if (RTEST(value))
    CTX_FL_SET(context, CTX_FL_TRACING);
  else
    CTX_FL_UNSET(context, CTX_FL_TRACING);
  return value;
}

/* :nodoc: */
static VALUE
dt_inherited(VALUE klass)
{
  UNUSED(klass);

  rb_raise(rb_eRuntimeError, "Can't inherit Byebug::DebugThread class");

  return Qnil;
}

/*
 *   Document-class: Context
 *
 *   == Summary
 *
 *   Byebug keeps a single instance of this class per thread.
 */
void
Init_byebug_context(VALUE mByebug)
{
  cContext = rb_define_class_under(mByebug, "Context", rb_cObject);

  rb_define_method(cContext, "backtrace", Context_backtrace, 0);
  rb_define_method(cContext, "dead?", Context_dead, 0);
  rb_define_method(cContext, "frame_binding", Context_frame_binding, -1);
  rb_define_method(cContext, "frame_class", Context_frame_class, -1);
  rb_define_method(cContext, "frame_file", Context_frame_file, -1);
  rb_define_method(cContext, "frame_line", Context_frame_line, -1);
  rb_define_method(cContext, "frame_method", Context_frame_method, -1);
  rb_define_method(cContext, "frame_self", Context_frame_self, -1);
  rb_define_method(cContext, "ignored?", Context_ignored, 0);
  rb_define_method(cContext, "resume", Context_resume, 0);
  rb_define_method(cContext, "step_into", Context_step_into, -1);
  rb_define_method(cContext, "step_out", Context_step_out, -1);
  rb_define_method(cContext, "step_over", Context_step_over, -1);
  rb_define_method(cContext, "stop_reason", Context_stop_reason, 0);
  rb_define_method(cContext, "suspend", Context_suspend, 0);
  rb_define_method(cContext, "suspended?", Context_is_suspended, 0);
  rb_define_method(cContext, "switch", Context_switch, 0);
  rb_define_method(cContext, "thnum", Context_thnum, 0);
  rb_define_method(cContext, "thread", Context_thread, 0);
  rb_define_method(cContext, "tracing", Context_tracing, 0);
  rb_define_method(cContext, "tracing=", Context_set_tracing, 1);

  cDebugThread = rb_define_class_under(mByebug, "DebugThread", rb_cThread);
  rb_define_singleton_method(cDebugThread, "inherited", dt_inherited, 0);
}
