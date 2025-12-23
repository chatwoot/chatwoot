#include "byebug.h"

/* Threads table class */
static VALUE cThreadsTable;

/* If not Qnil, holds the next thread that must be run */
VALUE next_thread = Qnil;

/* To allow thread syncronization, we must stop threads when debugging */
static VALUE locker = Qnil;

static int
t_tbl_mark_keyvalue(st_data_t key, st_data_t value, st_data_t tbl)
{
  UNUSED(tbl);

  rb_gc_mark((VALUE)key);

  if (!value)
    return ST_CONTINUE;

  rb_gc_mark((VALUE)value);

  return ST_CONTINUE;
}

static void
t_tbl_mark(void *data)
{
  threads_table_t *t_tbl = (threads_table_t *)data;
  st_table *tbl = t_tbl->tbl;

  st_foreach(tbl, t_tbl_mark_keyvalue, (st_data_t)tbl);
}

static void
t_tbl_free(void *data)
{
  threads_table_t *t_tbl = (threads_table_t *)data;

  st_free_table(t_tbl->tbl);
  xfree(t_tbl);
}

/*
 *  Creates a numeric hash whose keys are the currently active threads and
 *  whose values are their associated contexts.
 */
VALUE
create_threads_table(void)
{
  threads_table_t *t_tbl;

  t_tbl = ALLOC(threads_table_t);
  t_tbl->tbl = st_init_numtable();
  return Data_Wrap_Struct(cThreadsTable, t_tbl_mark, t_tbl_free, t_tbl);
}

/*
 *  Checks a single entry in the threads table.
 *
 *  If it has no associated context or the key doesn't correspond to a living
 *  thread, the entry is removed from the thread's list.
 */
static int
check_thread_i(st_data_t key, st_data_t value, st_data_t data)
{
  UNUSED(data);

  if (!value)
    return ST_DELETE;

  if (!is_living_thread((VALUE)key))
    return ST_DELETE;

  return ST_CONTINUE;
}

/*
 *  Checks whether a thread is either in the running or sleeping state.
 */
int
is_living_thread(VALUE thread)
{
  VALUE status = rb_funcall(thread, rb_intern("status"), 0);

  if (NIL_P(status) || status == Qfalse)
    return 0;

  if (rb_str_cmp(status, rb_str_new2("run")) == 0
      || rb_str_cmp(status, rb_str_new2("sleep")) == 0)
    return 1;

  return 0;
}

/*
 *  Checks threads table for dead/finished threads.
 */
static void
cleanup_dead_threads(void)
{
  threads_table_t *t_tbl;

  Data_Get_Struct(threads, threads_table_t, t_tbl);
  st_foreach(t_tbl->tbl, check_thread_i, 0);
}

/*
 * Looks up a context in the threads table. If not present, it creates it.
 */
void
thread_context_lookup(VALUE thread, VALUE *context)
{
  threads_table_t *t_tbl;

  Data_Get_Struct(threads, threads_table_t, t_tbl);

  if (!st_lookup(t_tbl->tbl, thread, context) || !*context)
  {
    *context = byebug_context_create(thread);
    st_insert(t_tbl->tbl, thread, *context);
  }
}

/*
 * Holds thread execution while another thread is active.
 *
 * Thanks to this, all threads are "frozen" while the user is typing commands.
 */
void
acquire_lock(debug_context_t *dc)
{
  while ((!NIL_P(locker) && locker != rb_thread_current())
         || CTX_FL_TEST(dc, CTX_FL_SUSPEND))
  {
    byebug_add_to_locked(rb_thread_current());
    rb_thread_stop();

    if (CTX_FL_TEST(dc, CTX_FL_SUSPEND))
      CTX_FL_SET(dc, CTX_FL_WAS_RUNNING);
  }

  locker = rb_thread_current();
}

/*
 * Releases our global lock and passes execution on to another thread, either
 * the thread specified by +next_thread+ or any other thread if +next_thread+
 * is nil.
 */
void
release_lock(void)
{
  VALUE thread;

  cleanup_dead_threads();

  locker = Qnil;

  if (NIL_P(next_thread))
    thread = byebug_pop_from_locked();
  else
  {
    byebug_remove_from_locked(next_thread);
    thread = next_thread;
    next_thread = Qnil;
  }

  if (!NIL_P(thread) && is_living_thread(thread))
    rb_thread_run(thread);
}

/*
 *  call-seq:
 *    Byebug.unlock -> nil
 *
 *  Unlocks global switch so other threads can run.
 */
static VALUE
Unlock(VALUE self)
{
  UNUSED(self);

  release_lock();

  return locker;
}

/*
 *  call-seq:
 *    Byebug.lock -> Thread.current
 *
 *  Locks global switch to reserve execution to current thread exclusively.
 */
static VALUE
Lock(VALUE self)
{
  debug_context_t *dc;
  VALUE context;

  UNUSED(self);

  if (!is_living_thread(rb_thread_current()))
    rb_raise(rb_eRuntimeError, "Current thread is dead!");

  thread_context_lookup(rb_thread_current(), &context);
  Data_Get_Struct(context, debug_context_t, dc);

  acquire_lock(dc);

  return locker;
}

/*
 *
 *    Document-class: ThreadsTable
 *
 *    == Sumary
 *
 *    Hash table holding currently active threads and their associated contexts
 */
void
Init_threads_table(VALUE mByebug)
{
  cThreadsTable = rb_define_class_under(mByebug, "ThreadsTable", rb_cObject);

  rb_define_module_function(mByebug, "unlock", Unlock, 0);
  rb_define_module_function(mByebug, "lock", Lock, 0);
}
