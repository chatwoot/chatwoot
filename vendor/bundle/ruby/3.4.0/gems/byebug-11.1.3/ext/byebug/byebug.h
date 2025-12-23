#ifndef BYEBUG
#define BYEBUG

#include <ruby.h>
#include <ruby/debug.h>

/* To prevent unused parameter warnings */
#define UNUSED(x) (void)(x)

/* flags */
#define CTX_FL_DEAD (1 << 1)         /* this context belonged to a dead thread */
#define CTX_FL_IGNORE (1 << 2)       /* this context belongs to ignored thread */
#define CTX_FL_SUSPEND (1 << 3)      /* thread currently suspended             */
#define CTX_FL_TRACING (1 << 4)      /* call at_tracing method                 */
#define CTX_FL_WAS_RUNNING (1 << 5)  /* thread was previously running          */
#define CTX_FL_STOP_ON_RET (1 << 6)  /* can stop on method 'end'               */
#define CTX_FL_IGNORE_STEPS (1 << 7) /* doesn't countdown steps to break       */

/* macro functions */
#define CTX_FL_TEST(c, f) ((c)->flags & (f))
#define CTX_FL_SET(c, f) \
  do                     \
  {                      \
    (c)->flags |= (f);   \
  } while (0)
#define CTX_FL_UNSET(c, f) \
  do                       \
  {                        \
    (c)->flags &= ~(f);    \
  } while (0)

/* types */
typedef enum
{
  CTX_STOP_NONE,
  CTX_STOP_STEP,
  CTX_STOP_BREAKPOINT,
  CTX_STOP_CATCHPOINT
} ctx_stop_reason;

typedef struct
{
  int calced_stack_size;
  int flags;
  ctx_stop_reason stop_reason;

  VALUE thread;
  int thnum;

  int dest_frame; /* next stop's frame if stopped by next     */
  int lines;      /* # of lines in dest_frame before stopping */
  int steps;      /* # of steps before stopping               */
  int steps_out;  /* # of returns before stopping             */

  VALUE backtrace; /* [[loc, self, klass, binding], ...] */
} debug_context_t;

typedef enum
{
  LOCATION,
  SELF,
  CLASS,
  BINDING
} frame_part;

struct call_with_inspection_data
{
  debug_context_t *dc;
  VALUE ctx;
  ID id;
  int argc;
  VALUE *argv;
};

typedef struct
{
  st_table *tbl;
} threads_table_t;

enum bp_type
{
  BP_POS_TYPE,
  BP_METHOD_TYPE
};

enum hit_condition
{
  HIT_COND_NONE,
  HIT_COND_GE,
  HIT_COND_EQ,
  HIT_COND_MOD
};

typedef struct
{
  int id;
  enum bp_type type;
  VALUE source;
  union
  {
    int line;
    ID mid;
  } pos;
  VALUE expr;
  VALUE enabled;
  int hit_count;
  int hit_value;
  enum hit_condition hit_condition;
} breakpoint_t;

/* functions from locker.c */
extern void byebug_add_to_locked(VALUE thread);
extern VALUE byebug_pop_from_locked();
extern void byebug_remove_from_locked(VALUE thread);

/* functions from threads.c */
extern void Init_threads_table(VALUE mByebug);
extern VALUE create_threads_table(void);
extern void thread_context_lookup(VALUE thread, VALUE *context);
extern int is_living_thread(VALUE thread);
extern void acquire_lock(debug_context_t *dc);
extern void release_lock(void);

/* global variables */
extern VALUE threads;
extern VALUE next_thread;

/* functions from context.c */
extern void Init_byebug_context(VALUE mByebug);
extern VALUE byebug_context_create(VALUE thread);
extern VALUE context_dup(debug_context_t *context);
extern void byebug_reset_stepping_stop_points(debug_context_t *context);
extern VALUE call_with_debug_inspector(struct call_with_inspection_data *data);
extern VALUE context_backtrace_set(const rb_debug_inspector_t *inspector,
                                   void *data);

/* functions from breakpoint.c */
extern void Init_byebug_breakpoint(VALUE mByebug);
extern VALUE find_breakpoint_by_pos(VALUE breakpoints, VALUE source, VALUE pos,
                                    VALUE bind);

extern VALUE find_breakpoint_by_method(VALUE breakpoints, VALUE klass,
                                       VALUE mid, VALUE bind, VALUE self);

#endif
