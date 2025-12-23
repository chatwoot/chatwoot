#include "byebug.h"

#ifdef _WIN32
#include <ctype.h>
#endif

#if defined DOSISH
#define isdirsep(x) ((x) == '/' || (x) == '\\')
#else
#define isdirsep(x) ((x) == '/')
#endif

static VALUE cBreakpoint;
static int breakpoint_max;

static ID idEval;

static VALUE
eval_expression(VALUE args)
{
  return rb_funcall2(rb_mKernel, idEval, 2, RARRAY_PTR(args));
}

/*
 *  call-seq:
 *    breakpoint.enabled? -> bool
 *
 *  Returns +true+ if breakpoint is enabled, false otherwise.
 */
static VALUE
brkpt_enabled(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return breakpoint->enabled;
}

/*
 *  call-seq:
 *    breakpoint.enabled = true | false
 *
 *  Enables or disables breakpoint.
 */
static VALUE
brkpt_set_enabled(VALUE self, VALUE enabled)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return breakpoint->enabled = enabled;
}

/*
 *  call-seq:
 *    breakpoint.expr -> string
 *
 *  Returns a conditional expression which indicates when this breakpoint should
 *  be activated.
 */
static VALUE
brkpt_expr(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return breakpoint->expr;
}

/*
 *  call-seq:
 *    breakpoint.expr = string | nil
 *
 *  Sets or unsets the conditional expression which indicates when this
 *  breakpoint should be activated.
 */
static VALUE
brkpt_set_expr(VALUE self, VALUE expr)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  breakpoint->expr = NIL_P(expr) ? expr : StringValue(expr);
  return expr;
}

/*
 *  call-seq:
 *    breakpoint.hit_condition -> symbol
 *
 *   Returns the hit condition of the breakpoint: +nil+ if it is an
 *   unconditional breakpoint, or :greater_or_equal, :equal or :modulo otherwise
 */
static VALUE
brkpt_hit_condition(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  switch (breakpoint->hit_condition)
  {
    case HIT_COND_GE:
      return ID2SYM(rb_intern("greater_or_equal"));
    case HIT_COND_EQ:
      return ID2SYM(rb_intern("equal"));
    case HIT_COND_MOD:
      return ID2SYM(rb_intern("modulo"));
    case HIT_COND_NONE:
    default:
      return Qnil;
  }
}

/*
 *  call-seq:
 *    breakpoint.hit_condition = symbol
 *
 *  Sets the hit condition of the breakpoint which must be one of the following
 *  values:
 *
 *  +nil+ if it is an unconditional breakpoint, or
 *  :greater_or_equal(:ge), :equal(:eq), :modulo(:mod)
 */
static VALUE
brkpt_set_hit_condition(VALUE self, VALUE value)
{
  breakpoint_t *breakpoint;
  ID id_value;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  id_value = rb_to_id(value);

  if (rb_intern("greater_or_equal") == id_value || rb_intern("ge") == id_value)
    breakpoint->hit_condition = HIT_COND_GE;
  else if (rb_intern("equal") == id_value || rb_intern("eq") == id_value)
    breakpoint->hit_condition = HIT_COND_EQ;
  else if (rb_intern("modulo") == id_value || rb_intern("mod") == id_value)
    breakpoint->hit_condition = HIT_COND_MOD;
  else
    rb_raise(rb_eArgError, "Invalid condition parameter");
  return value;
}

/*
 *  call-seq:
 *    breakpoint.hit_count -> int
 *
 *  Returns the number of times this breakpoint has been hit.
 */
static VALUE
brkpt_hit_count(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return INT2FIX(breakpoint->hit_count);
}

/*
 *  call-seq:
 *    breakpoint.hit_value -> int
 *
 *  Returns the hit value of the breakpoint, namely, a value to build a
 *  condition on the number of hits of the breakpoint.
 */
static VALUE
brkpt_hit_value(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return INT2FIX(breakpoint->hit_value);
}

/*
 *  call-seq:
 *    breakpoint.hit_value = int
 *
 *  Sets the hit value of the breakpoint. This allows the user to set conditions
 *  on the number of hits to enable/disable the breakpoint.
 */
static VALUE
brkpt_set_hit_value(VALUE self, VALUE value)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  breakpoint->hit_value = FIX2INT(value);
  return value;
}

/*
 *  call-seq:
 *    breakpoint.id -> int
 *
 *  Returns the id of the breakpoint.
 */
static VALUE
brkpt_id(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return INT2FIX(breakpoint->id);
}

/*
 *  call-seq:
 *    breakpoint.pos -> string or int
 *
 *   Returns the position of this breakpoint, either a method name or a line
 *   number.
 */
static VALUE
brkpt_pos(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  if (breakpoint->type == BP_METHOD_TYPE)
    return rb_str_new2(rb_id2name(breakpoint->pos.mid));
  else
    return INT2FIX(breakpoint->pos.line);
}

/*
 *  call-seq:
 *    breakpoint.source -> string
 *
 *  Returns the source file of the breakpoint.
 */
static VALUE
brkpt_source(VALUE self)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);
  return breakpoint->source;
}

static void
mark_breakpoint(breakpoint_t *breakpoint)
{
  rb_gc_mark(breakpoint->source);
  rb_gc_mark(breakpoint->expr);
}

static VALUE
brkpt_create(VALUE klass)
{
  breakpoint_t *breakpoint = ALLOC(breakpoint_t);

  return Data_Wrap_Struct(klass, mark_breakpoint, xfree, breakpoint);
}

static VALUE
brkpt_initialize(VALUE self, VALUE source, VALUE pos, VALUE expr)
{
  breakpoint_t *breakpoint;

  Data_Get_Struct(self, breakpoint_t, breakpoint);

  breakpoint->type = FIXNUM_P(pos) ? BP_POS_TYPE : BP_METHOD_TYPE;
  if (breakpoint->type == BP_POS_TYPE)
    breakpoint->pos.line = FIX2INT(pos);
  else
    breakpoint->pos.mid = SYM2ID(pos);

  breakpoint->id = ++breakpoint_max;
  breakpoint->source = StringValue(source);
  breakpoint->enabled = Qtrue;
  breakpoint->expr = NIL_P(expr) ? expr : StringValue(expr);
  breakpoint->hit_count = 0;
  breakpoint->hit_value = 0;
  breakpoint->hit_condition = HIT_COND_NONE;

  return Qnil;
}

static int
filename_cmp_impl(VALUE source, char *file)
{
  char *source_ptr, *file_ptr;
  long s_len, f_len, min_len;
  long s, f;
  int dirsep_flag = 0;

  s_len = RSTRING_LEN(source);
  f_len = strlen(file);
  min_len = s_len < f_len ? s_len : f_len;

  source_ptr = RSTRING_PTR(source);
  file_ptr = file;

  for (s = s_len - 1, f = f_len - 1;
       s >= s_len - min_len && f >= f_len - min_len; s--, f--)
  {
    if ((source_ptr[s] == '.' || file_ptr[f] == '.') && dirsep_flag)
      return 1;
    if (isdirsep(source_ptr[s]) && isdirsep(file_ptr[f]))
      dirsep_flag = 1;
#ifdef DOSISH_DRIVE_LETTER
    else if (s == 0)
      return (toupper(source_ptr[s]) == toupper(file_ptr[f]));
#endif
    else if (source_ptr[s] != file_ptr[f])
      return 0;
  }
  return 1;
}

static int
filename_cmp(VALUE source, char *file)
{
#ifdef _WIN32
  return filename_cmp_impl(source, file);
#else
#ifdef PATH_MAX
  char path[PATH_MAX + 1];

  path[PATH_MAX] = 0;
  return filename_cmp_impl(source, realpath(file, path) != NULL ? path : file);
#else
  char *path;
  int result;

  path = realpath(file, NULL);
  result = filename_cmp_impl(source, path == NULL ? file : path);
  free(path);
  return result;
#endif
#endif
}

static int
classname_cmp(VALUE name, VALUE klass)
{
  VALUE mod_name;
  VALUE class_name = NIL_P(name) ? rb_str_new2("main") : name;

  if (NIL_P(klass))
    return 0;

  mod_name = rb_mod_name(klass);
  return (!NIL_P(mod_name) && rb_str_cmp(class_name, mod_name) == 0);
}

static int
check_breakpoint_by_hit_condition(VALUE rb_breakpoint)
{
  breakpoint_t *breakpoint;

  if (NIL_P(rb_breakpoint))
    return 0;

  Data_Get_Struct(rb_breakpoint, breakpoint_t, breakpoint);
  breakpoint->hit_count++;

  if (Qtrue != breakpoint->enabled)
    return 0;

  switch (breakpoint->hit_condition)
  {
    case HIT_COND_NONE:
      return 1;
    case HIT_COND_GE:
    {
      if (breakpoint->hit_count >= breakpoint->hit_value)
        return 1;
      break;
    }
    case HIT_COND_EQ:
    {
      if (breakpoint->hit_count == breakpoint->hit_value)
        return 1;
      break;
    }
    case HIT_COND_MOD:
    {
      if (breakpoint->hit_count % breakpoint->hit_value == 0)
        return 1;
      break;
    }
  }
  return 0;
}

static int
check_breakpoint_by_pos(VALUE rb_breakpoint, char *file, int line)
{
  breakpoint_t *breakpoint;

  if (NIL_P(rb_breakpoint))
    return 0;

  Data_Get_Struct(rb_breakpoint, breakpoint_t, breakpoint);

  if (Qfalse == breakpoint->enabled || breakpoint->type != BP_POS_TYPE
      || breakpoint->pos.line != line)
    return 0;

  return filename_cmp(breakpoint->source, file);
}

static int
check_breakpoint_by_method(VALUE rb_breakpoint, VALUE klass, ID mid, VALUE self)
{
  breakpoint_t *breakpoint;

  if (NIL_P(rb_breakpoint))
    return 0;

  Data_Get_Struct(rb_breakpoint, breakpoint_t, breakpoint);

  if (Qfalse == breakpoint->enabled || breakpoint->type != BP_METHOD_TYPE
      || breakpoint->pos.mid != mid)
    return 0;

  if (classname_cmp(breakpoint->source, klass)
      || ((rb_type(self) == T_CLASS || rb_type(self) == T_MODULE)
          && classname_cmp(breakpoint->source, self)))
    return 1;

  return 0;
}

static int
check_breakpoint_by_expr(VALUE rb_breakpoint, VALUE bind)
{
  breakpoint_t *breakpoint;
  VALUE args, expr_result;

  if (NIL_P(rb_breakpoint))
    return 0;

  Data_Get_Struct(rb_breakpoint, breakpoint_t, breakpoint);

  if (Qfalse == breakpoint->enabled)
    return 0;

  if (NIL_P(breakpoint->expr))
    return 1;

  args = rb_ary_new3(2, breakpoint->expr, bind);
  expr_result = rb_protect(eval_expression, args, 0);

  return RTEST(expr_result);
}

extern VALUE
find_breakpoint_by_pos(VALUE breakpoints, VALUE source, VALUE pos, VALUE bind)
{
  VALUE breakpoint;
  char *file;
  int line;
  int i;

  file = RSTRING_PTR(source);
  line = FIX2INT(pos);
  for (i = 0; i < RARRAY_LENINT(breakpoints); i++)
  {
    breakpoint = rb_ary_entry(breakpoints, i);
    if (check_breakpoint_by_pos(breakpoint, file, line)
        && check_breakpoint_by_expr(breakpoint, bind)
        && check_breakpoint_by_hit_condition(breakpoint))
    {
      return breakpoint;
    }
  }
  return Qnil;
}

extern VALUE
find_breakpoint_by_method(VALUE breakpoints, VALUE klass, ID mid, VALUE bind,
                          VALUE self)
{
  VALUE breakpoint;
  int i;

  for (i = 0; i < RARRAY_LENINT(breakpoints); i++)
  {
    breakpoint = rb_ary_entry(breakpoints, i);
    if (check_breakpoint_by_method(breakpoint, klass, mid, self)
        && check_breakpoint_by_expr(breakpoint, bind)
        && check_breakpoint_by_hit_condition(breakpoint))
    {
      return breakpoint;
    }
  }
  return Qnil;
}

void
Init_byebug_breakpoint(VALUE mByebug)
{
  breakpoint_max = 0;

  cBreakpoint = rb_define_class_under(mByebug, "Breakpoint", rb_cObject);

  rb_define_alloc_func(cBreakpoint, brkpt_create);
  rb_define_method(cBreakpoint, "initialize", brkpt_initialize, 3);

  rb_define_method(cBreakpoint, "enabled?", brkpt_enabled, 0);
  rb_define_method(cBreakpoint, "enabled=", brkpt_set_enabled, 1);
  rb_define_method(cBreakpoint, "expr", brkpt_expr, 0);
  rb_define_method(cBreakpoint, "expr=", brkpt_set_expr, 1);
  rb_define_method(cBreakpoint, "hit_count", brkpt_hit_count, 0);
  rb_define_method(cBreakpoint, "hit_condition", brkpt_hit_condition, 0);
  rb_define_method(cBreakpoint, "hit_condition=", brkpt_set_hit_condition, 1);
  rb_define_method(cBreakpoint, "hit_value", brkpt_hit_value, 0);
  rb_define_method(cBreakpoint, "hit_value=", brkpt_set_hit_value, 1);
  rb_define_method(cBreakpoint, "id", brkpt_id, 0);
  rb_define_method(cBreakpoint, "pos", brkpt_pos, 0);
  rb_define_method(cBreakpoint, "source", brkpt_source, 0);

  idEval = rb_intern("eval");
}
