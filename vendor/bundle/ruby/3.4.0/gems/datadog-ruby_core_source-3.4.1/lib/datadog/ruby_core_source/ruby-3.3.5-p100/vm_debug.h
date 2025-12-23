#ifndef RUBY_DEBUG_H
#define RUBY_DEBUG_H
/**********************************************************************

  vm_debug.h - YARV Debug function interface

  $Author$
  created at: 04/08/25 02:33:49 JST

  Copyright (C) 2004-2007 Koichi Sasada

**********************************************************************/

#include "ruby/ruby.h"

RUBY_SYMBOL_EXPORT_BEGIN

#define dpv(h,v) ruby_debug_print_value(-1, 0, (h), (v))
#define dp(v)    ruby_debug_print_value(-1, 0, "", (v))
#define dpi(i)   ruby_debug_print_id(-1, 0, "", (i))
#define dpn(n)   ruby_debug_print_node(-1, 0, "", (n))

struct RNode;

VALUE ruby_debug_print_value(int level, int debug_level, const char *header, VALUE v);
ID    ruby_debug_print_id(int level, int debug_level, const char *header, ID id);
struct RNode *ruby_debug_print_node(int level, int debug_level, const char *header, const struct RNode *node);
int   ruby_debug_print_indent(int level, int debug_level, int indent_level);
void  ruby_debug_gc_check_func(void);
void ruby_set_debug_option(const char *str);

RUBY_SYMBOL_EXPORT_END

#ifndef USE_RUBY_DEBUG_LOG
#define USE_RUBY_DEBUG_LOG 0
#endif

/* RUBY_DEBUG_LOG: Logging debug information mechanism
 *
 * This feature provides a mechanism to store logging information
 * to a file, stderr or memory space with simple macros.
 *
 * The following information will be stored.
 *   * (1) __FILE__, __LINE__ in C
 *   * (2) __FILE__, __LINE__ in Ruby
 *   * (3) __func__ in C (message title)
 *   * (4) given string with sprintf format
 *   * (5) Thread number (if multiple threads are running)
 *
 * This feature is enabled only USE_RUBY_DEBUG_LOG is enabled.
 * Release version should not enable it.
 *
 * Running with the `RUBY_DEBUG_LOG` environment variable enables
 * this feature.
 *
 *   # logging into a file
 *   RUBY_DEBUG_LOG=/path/to/file STDERR
 *
 *   # logging into STDERR
 *   RUBY_DEBUG_LOG=stderr
 *
 *   # logging into memory space (check with a debugger)
 *   # It will help if the timing is important.
 *   RUBY_DEBUG_LOG=mem
 *
 * RUBY_DEBUG_LOG_FILTER environment variable can specify the filter string.
 * If "(3) __func__ in C (message title)" contains the specified string, the
 * information will be stored (example: RUBY_DEBUG_LOG_FILTER=str will enable
 * only on str related information).
 *
 * In a MRI source code, you can use the following macros:
 *   * RUBY_DEBUG_LOG(fmt, ...): Above (1) to (4) will be logged.
 *   * RUBY_DEBUG_LOG2(file, line, fmt, ...):
 *     Same as RUBY_DEBUG_LOG(), but (1) will be replaced with given file, line.
 */

extern enum ruby_debug_log_mode {
    ruby_debug_log_disabled = 0x00,
    ruby_debug_log_memory   = 0x01,
    ruby_debug_log_stderr   = 0x02,
    ruby_debug_log_file     = 0x04,
} ruby_debug_log_mode;

RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 4, 5)
void ruby_debug_log(const char *file, int line, const char *func_name, const char *fmt, ...);
void ruby_debug_log_print(unsigned int n);
bool ruby_debug_log_filter(const char *func_name, const char *file_name);

#if RBIMPL_COMPILER_IS(GCC) && defined(__OPTIMIZE__)
# define ruby_debug_log(...) \
    RB_GNUC_EXTENSION_BLOCK( \
        RBIMPL_WARNING_PUSH(); \
        RBIMPL_WARNING_IGNORED(-Wformat-zero-length); \
        ruby_debug_log(__VA_ARGS__); \
        RBIMPL_WARNING_POP())
#endif

// convenient macro to log even if the USE_RUBY_DEBUG_LOG macro is not specified.
// You can use this macro for temporary usage (you should not commit it).
#define _RUBY_DEBUG_LOG(...) ruby_debug_log(__FILE__, __LINE__, RUBY_FUNCTION_NAME_STRING, "" __VA_ARGS__)

#if USE_RUBY_DEBUG_LOG
# define RUBY_DEBUG_LOG_ENABLED(func_name, file_name)                     \
    (ruby_debug_log_mode && ruby_debug_log_filter(func_name, file_name))

#define RUBY_DEBUG_LOG(...) do { \
    if (RUBY_DEBUG_LOG_ENABLED(RUBY_FUNCTION_NAME_STRING, __FILE__)) \
        ruby_debug_log(__FILE__, __LINE__, RUBY_FUNCTION_NAME_STRING, "" __VA_ARGS__); \
} while (0)

#define RUBY_DEBUG_LOG2(file, line, ...) do { \
    if (RUBY_DEBUG_LOG_ENABLED(RUBY_FUNCTION_NAME_STRING, file)) \
        ruby_debug_log(file, line, RUBY_FUNCTION_NAME_STRING, "" __VA_ARGS__); \
} while (0)

#else // USE_RUBY_DEBUG_LOG
// do nothing
#define RUBY_DEBUG_LOG(...)
#define RUBY_DEBUG_LOG2(file, line, ...)
#endif // USE_RUBY_DEBUG_LOG

#endif /* RUBY_DEBUG_H */
