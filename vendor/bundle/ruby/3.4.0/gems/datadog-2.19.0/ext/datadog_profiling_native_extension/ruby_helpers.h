#pragma once

#include <stdbool.h>
#include "datadog_ruby_common.h"

// Initialize internal data needed by some ruby helpers. Should be called during start, before any actual
// usage of ruby helpers.
void ruby_helpers_init(void);

// Processes any pending interruptions, including exceptions to be raised.
// If there's an exception to be raised, it raises it. In that case, this function does not return.
static inline VALUE process_pending_interruptions(DDTRACE_UNUSED VALUE _) {
  rb_thread_check_ints();
  return Qnil;
}

// Calls process_pending_interruptions BUT "rescues" any exceptions to be raised, returning them instead as
// a non-zero `pending_exception`.
//
// Thus, if there's a non-zero `pending_exception`, the caller MUST call `rb_jump_tag(pending_exception)` after any
// needed clean-ups.
//
// Usage example:
//
// ```c
// foo = ruby_xcalloc(...);
// pending_exception = check_if_pending_exception();
// if (pending_exception) {
//   ruby_xfree(foo);
//   rb_jump_tag(pending_exception); // Re-raises exception
// }
// ```
__attribute__((warn_unused_result))
static inline int check_if_pending_exception(void) {
  int pending_exception;
  rb_protect(process_pending_interruptions, Qnil, &pending_exception);
  return pending_exception;
}

#define VALUE_COUNT(array) (sizeof(array) / sizeof(VALUE))

NORETURN(
  void grab_gvl_and_raise(VALUE exception_class, const char *format_string, ...)
  __attribute__ ((format (printf, 2, 3)));
);
NORETURN(
  void grab_gvl_and_raise_syserr(int syserr_errno, const char *format_string, ...)
  __attribute__ ((format (printf, 2, 3)));
);

#define ENFORCE_SUCCESS_GVL(expression) ENFORCE_SUCCESS_HELPER(expression, true)
#define ENFORCE_SUCCESS_NO_GVL(expression) ENFORCE_SUCCESS_HELPER(expression, false)

#define ENFORCE_SUCCESS_HELPER(expression, have_gvl) \
  { int result_syserr_errno = expression; if (RB_UNLIKELY(result_syserr_errno)) raise_syserr(result_syserr_errno, have_gvl, ADD_QUOTES(expression), __FILE__, __LINE__, __func__); }

#define RUBY_NUM_OR_NIL(val, condition, conv) ((val condition) ? conv(val) : Qnil)
#define RUBY_AVG_OR_NIL(total, count) ((count == 0) ? Qnil : DBL2NUM(((double) total) / count))

// Called by ENFORCE_SUCCESS_HELPER; should not be used directly
NORETURN(void raise_syserr(
  int syserr_errno,
  bool have_gvl,
  const char *expression,
  const char *file,
  int line,
  const char *function_name
));

// Native wrapper to get an object ref from an id. Returns true on success and
// writes the ref to the value pointer parameter if !NULL. False if id doesn't
// reference a valid object (in which case value is not changed).
//
// Note: GVL can be released and other threads may get to run before this method returns
bool ruby_ref_from_id(VALUE obj_id, VALUE *value);

// Native wrapper to get the approximate/estimated current size of the passed
// object.
size_t ruby_obj_memsize_of(VALUE obj);

// Safely inspect any ruby object. If the object responds to 'inspect',
// return a string with the result of that call. Elsif the object responds to
// 'to_s', return a string with the result of that call. Otherwise, return Qnil.
VALUE ruby_safe_inspect(VALUE obj);

// You probably want ruby_safe_inspect instead; this is a lower-level dependency
// of it, that's being exposed here just to facilitate testing.
const char* safe_object_info(VALUE obj);
