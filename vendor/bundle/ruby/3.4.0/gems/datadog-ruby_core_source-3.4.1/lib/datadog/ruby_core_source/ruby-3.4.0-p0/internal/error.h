#ifndef INTERNAL_ERROR_H                                 /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_ERROR_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Exception.
 */
#include "ruby/internal/config.h"
#include <stdarg.h>             /* for va_list */
#include "internal/string.h"    /* for rb_fstring_cstr */
#include "ruby/internal/stdbool.h"     /* for bool */
#include "ruby/encoding.h"      /* for rb_encoding */
#include "ruby/intern.h"        /* for rb_exc_raise */
#include "ruby/ruby.h"          /* for enum ruby_value_type */

#ifdef Check_Type
# undef Check_Type               /* in ruby/ruby.h */
#endif

#ifdef rb_raise_static
# undef rb_raise_static
# undef rb_sys_fail_path
# undef rb_syserr_fail_path
#endif

#define rb_raise_static(e, m) \
    rb_raise_cstr_i((e), rb_str_new_static((m), rb_strlen_lit(m)))
#ifdef RUBY_FUNCTION_NAME_STRING
# define rb_syserr_fail_path(err, path) rb_syserr_fail_path_in(RUBY_FUNCTION_NAME_STRING, (err), (path))
# define rb_syserr_new_path(err, path) rb_syserr_new_path_in(RUBY_FUNCTION_NAME_STRING, (err), (path))
#else
# define rb_syserr_fail_path(err, path) rb_syserr_fail_str((err), (path))
# define rb_syserr_new_path(err, path) rb_syserr_new_str((err), (path))
#endif

#define rb_sys_fail(mesg) \
do { \
    int errno_to_fail = errno; \
    rb_syserr_fail(errno_to_fail, (mesg)); \
} while (0)

#define rb_sys_fail_str(mesg) \
do { \
    int errno_to_fail = errno; \
    rb_syserr_fail_str(errno_to_fail, (mesg)); \
} while (0)

#define rb_sys_fail_path(path) \
do { \
    int errno_to_fail = errno; \
    rb_syserr_fail_path(errno_to_fail, (path)); \
} while (0)

#define rb_sys_fail_sprintf(...) \
do { \
    int errno_to_fail = errno; \
    rb_syserr_fail_str(errno_to_fail, rb_sprintf("" __VA_ARGS__)); \
} while (0)

/* error.c */
extern long rb_backtrace_length_limit;
extern VALUE rb_eEAGAIN;
extern VALUE rb_eEWOULDBLOCK;
extern VALUE rb_eEINPROGRESS;
RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 3, 0)
void rb_report_bug_valist(VALUE file, int line, const char *fmt, va_list args);
NORETURN(void rb_async_bug_errno(const char *,int));
const char *rb_builtin_type_name(int t);
const char *rb_builtin_class_name(VALUE x);
PRINTF_ARGS(void rb_warn_deprecated(const char *fmt, const char *suggest, ...), 1, 3);
PRINTF_ARGS(void rb_warn_deprecated_to_remove(const char *removal, const char *fmt, const char *suggest, ...), 2, 4);
PRINTF_ARGS(void rb_warn_reserved_name(const char *removal, const char *fmt, ...), 2, 3);
#if RUBY_DEBUG
# include "ruby/version.h"
# define RUBY_VERSION_SINCE(major, minor) (RUBY_API_VERSION_CODE >= (major * 10000) + (minor) * 100)
# define RUBY_VERSION_BEFORE(major, minor) (RUBY_API_VERSION_CODE < (major * 10000) + (minor) * 100)
# if defined(RBIMPL_WARNING_PRAGMA0)
#   define RBIMPL_TODO0(x) RBIMPL_WARNING_PRAGMA0(message(x))
# elif RBIMPL_COMPILER_SINCE(MSVC, 12, 0, 0)
#   define RBIMPL_TODO0(x) __pragma(message(x))
# endif

# if RBIMPL_HAS_ATTRIBUTE(diagnose_if) || defined(__OPTIMIZE__)

#define RUBY_VERSION_isdigit(c) ('0'<=(c)&&(c)<='9')
// upto 99
#define RUBY_VERSION__number_len(v, ofs) \
    (!RUBY_VERSION_isdigit((v)[ofs]) ? \
     0 : !RUBY_VERSION_isdigit((v)[(ofs) + 1]) ? 1 : 2)
#define RUBY_VERSION__to_number(v, ofs) \
    (!RUBY_VERSION_isdigit((v)[ofs]) ? \
     0 : !RUBY_VERSION_isdigit((v)[(ofs) + 1]) ? \
     ((v)[ofs]-'0') : \
     (((v)[ofs]-'0')*10+(v)[(ofs)+1]-'0'))

#define RUBY_VERSION_CODE_FROM_MAJOR_MINOR_STRING(v) \
    (RUBY_VERSION__to_number(v, 0) * 10000 + \
     ((v)[RUBY_VERSION__number_len(v, 0)] == '.' ? \
      RUBY_VERSION__to_number(v, RUBY_VERSION__number_len(v, 0)+1) * 100 : 0))
#define RUBY_VERSION_STRING_SINCE(v) (RUBY_API_VERSION_CODE >= RUBY_VERSION_CODE_FROM_MAJOR_MINOR_STRING(v))
#define RUBY_VERSION_STRING_BEFORE(v) (RUBY_API_VERSION_CODE < RUBY_VERSION_CODE_FROM_MAJOR_MINOR_STRING(v))

# if RBIMPL_HAS_ATTRIBUTE(diagnose_if)
RBIMPL_ATTR_FORCEINLINE()
static void
rb_deprecated_method_to_be_removed(const char *removal)
    RBIMPL_ATTR_DIAGNOSE_IF(!RUBY_VERSION_isdigit(removal[0]), "malformed version number", "error")
    RBIMPL_ATTR_DIAGNOSE_IF(RUBY_VERSION_STRING_SINCE(removal), "deprecated method to be removed", "error")
{
}

RBIMPL_ATTR_FORCEINLINE()
static void
rb_diagnose_reserved_name_at(const char *coming)
    RBIMPL_ATTR_DIAGNOSE_IF(!RUBY_VERSION_isdigit(coming[0]), "malformed version number", "error")
    RBIMPL_ATTR_DIAGNOSE_IF(RUBY_VERSION_STRING_SINCE(coming), "reserved name already in use", "error")
{
}
# else
RBIMPL_ATTR_ERROR(("deprecated"))
void rb_deprecated_method_to_be_removed(const char *);
#   define rb_deprecated_method_to_be_removed(removal) \
    (sizeof(char[1-2*(!RUBY_VERSION_isdigit(removal[0]) || RUBY_VERSION_STRING_SINCE(removal))])!=1 ? \
     rb_deprecated_method_to_be_removed(removal) : \
     RBIMPL_ASSERT_NOTHING)

RBIMPL_ATTR_ERROR(("deprecated"))
void rb_diagnose_reserved_name_at(const char *);
#   define rb_diagnose_reserved_name_at(coming) \
    (sizeof(char[1-2*(!RUBY_VERSION_isdigit(coming[0]) || RUBY_VERSION_STRING_SINCE(coming))])!=1 ? \
     rb_diagnose_reserved_name_at(coming) : \
     RBIMPL_ASSERT_NOTHING)

# endif
# define rb_warn_deprecated_to_remove_at(removal, ...) \
    (rb_deprecated_method_to_be_removed(#removal), \
     rb_warn_deprecated_to_remove(#removal, __VA_ARGS__))

# define rb_warn_reserved_name_at(coming, ...) \
    (rb_diagnose_reserved_name_at(#coming), \
     rb_warn_reserved_name(#coming, __VA_ARGS__))
# endif
#endif
#ifndef rb_warn_deprecated_to_remove_at
# define rb_warn_deprecated_to_remove_at(removal, ...) \
        rb_warn_deprecated_to_remove(#removal, __VA_ARGS__)
#endif
#ifndef rb_warn_reserved_name_at
# define rb_warn_reserved_name_at(removal, ...) \
        rb_warn_reserved_name(#removal, __VA_ARGS__)
#endif
#ifndef RUBY_VERSION_SINCE
# define RUBY_VERSION_SINCE(major, minor) 0
#endif
#ifndef RUBY_VERSION_BEFORE
# define RUBY_VERSION_BEFORE(major, minor) 0
#endif
#ifndef RBIMPL_TODO0
# define RBIMPL_TODO0(x)
#endif
#define RBIMPL_TODO(message) RBIMPL_TODO0("TODO: " message)
RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 6, 0)
VALUE rb_syntax_error_append(VALUE, VALUE, int, int, rb_encoding*, const char*, va_list);
PRINTF_ARGS(void rb_enc_warn(rb_encoding *enc, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_sys_enc_warning(rb_encoding *enc, const char *fmt, ...), 2, 3);
PRINTF_ARGS(void rb_syserr_enc_warning(int err, rb_encoding *enc, const char *fmt, ...), 3, 4);
PRINTF_ARGS(void rb_enc_compile_warning(rb_encoding *enc, const char *file, int line, const char *fmt, ...), 4, 5);
PRINTF_ARGS(void rb_enc_compile_warn(rb_encoding *enc, const char *file, int line, const char *fmt, ...), 4, 5);
rb_warning_category_t rb_warning_category_from_name(VALUE category);
bool rb_warning_category_enabled_p(rb_warning_category_t category);
VALUE rb_name_err_new(VALUE mesg, VALUE recv, VALUE method);
VALUE rb_nomethod_err_new(VALUE mesg, VALUE recv, VALUE method, VALUE args, int priv);
VALUE rb_key_err_new(VALUE mesg, VALUE recv, VALUE name);
PRINTF_ARGS(VALUE rb_warning_string(const char *fmt, ...), 1, 2);
RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 2, 0)
NORETURN(void rb_vraise(VALUE, const char *, va_list));
NORETURN(static inline void rb_raise_cstr(VALUE etype, const char *mesg));
NORETURN(static inline void rb_raise_cstr_i(VALUE etype, VALUE mesg));
NORETURN(static inline void rb_name_err_raise_str(VALUE mesg, VALUE recv, VALUE name));
NORETURN(static inline void rb_name_err_raise(const char *mesg, VALUE recv, VALUE name));
NORETURN(static inline void rb_key_err_raise(VALUE mesg, VALUE recv, VALUE name));
static inline void Check_Type(VALUE v, enum ruby_value_type t);
static inline bool rb_typeddata_is_instance_of_inline(VALUE obj, const rb_data_type_t *data_type);
#define rb_typeddata_is_instance_of rb_typeddata_is_instance_of_inline
void rb_bug_without_die(const char *fmt, ...);

RUBY_SYMBOL_EXPORT_BEGIN
/* error.c (export) */
int rb_bug_reporter_add(void (*func)(FILE *, void *), void *data);
#ifdef RUBY_FUNCTION_NAME_STRING
NORETURN(void rb_sys_fail_path_in(const char *func_name, VALUE path));
NORETURN(void rb_syserr_fail_path_in(const char *func_name, int err, VALUE path));
VALUE rb_syserr_new_path_in(const char *func_name, int n, VALUE path);
#endif
RUBY_SYMBOL_EXPORT_END

/* vm.c */
void rb_free_warning(void);

static inline void
rb_raise_cstr_i(VALUE etype, VALUE mesg)
{
    VALUE exc = rb_exc_new_str(etype, mesg);
    rb_exc_raise(exc);
}

static inline void
rb_raise_cstr(VALUE etype, const char *mesg)
{
    VALUE str = rb_str_new_cstr(mesg);
    rb_raise_cstr_i(etype, str);
}

static inline void
rb_name_err_raise_str(VALUE mesg, VALUE recv, VALUE name)
{
    VALUE exc = rb_name_err_new(mesg, recv, name);
    rb_exc_raise(exc);
}

static inline void
rb_name_err_raise(const char *mesg, VALUE recv, VALUE name)
{
    VALUE str = rb_fstring_cstr(mesg);
    rb_name_err_raise_str(str, recv, name);
}

static inline void
rb_key_err_raise(VALUE mesg, VALUE recv, VALUE name)
{
    VALUE exc = rb_key_err_new(mesg, recv, name);
    rb_exc_raise(exc);
}

static inline bool
rb_typeddata_is_instance_of_inline(VALUE obj, const rb_data_type_t *data_type)
{
    return RB_TYPE_P(obj, T_DATA) && RTYPEDDATA_P(obj) && (RTYPEDDATA_TYPE(obj) == data_type);
}

#endif /* INTERNAL_ERROR_H */
