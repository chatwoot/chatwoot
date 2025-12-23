#include "byebug.h"

/**
 * A simple linked list containing locked threads, FIFO style.
 */

typedef struct locked_thread_t
{
  VALUE thread;
  struct locked_thread_t *next;
} locked_thread_t;

static locked_thread_t *locked_head = NULL;
static locked_thread_t *locked_tail = NULL;

static int
is_in_locked(VALUE thread)
{
  locked_thread_t *node;

  if (!locked_head)
    return 0;

  for (node = locked_head; node != locked_tail; node = node->next)
    if (node->thread == thread)
      return 1;

  return 0;
}

extern void
byebug_add_to_locked(VALUE thread)
{
  locked_thread_t *node;

  if (is_in_locked(thread))
    return;

  node = ALLOC(locked_thread_t);
  node->thread = thread;
  node->next = NULL;

  if (locked_tail)
    locked_tail->next = node;

  locked_tail = node;

  if (!locked_head)
    locked_head = node;
}

extern VALUE
byebug_pop_from_locked()
{
  VALUE thread;
  locked_thread_t *node;

  if (!locked_head)
    return Qnil;

  node = locked_head;
  locked_head = locked_head->next;

  if (locked_tail == node)
    locked_tail = NULL;

  thread = node->thread;
  xfree(node);

  return thread;
}

extern void
byebug_remove_from_locked(VALUE thread)
{
  locked_thread_t *node;
  locked_thread_t *next_node;

  if (NIL_P(thread) || !locked_head || !is_in_locked(thread))
    return;

  if (locked_head->thread == thread)
  {
    byebug_pop_from_locked();
    return;
  }

  for (node = locked_head; node != locked_tail; node = node->next)
    if (node->next && node->next->thread == thread)
    {
      next_node = node->next;
      node->next = next_node->next;
      xfree(next_node);
      return;
    }
}
