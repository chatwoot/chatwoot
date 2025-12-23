#ifndef INTERNAL_PROCESS_H                               /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_PROCESS_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Process.
 */
#include "ruby/internal/config.h"      /* for rb_pid_t */
#include <stddef.h>             /* for size_t */

#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>         /* for mode_t */
#endif

#ifdef _WIN32
# include "ruby/win32.h"        /* for mode_t */
#endif

#include "ruby/ruby.h"          /* for VALUE */
#include "internal/compilers.h" /* for __has_warning */
#include "internal/imemo.h"     /* for RB_IMEMO_TMPBUF_PTR */

#define RB_MAX_GROUPS (65536)

struct waitpid_state;
struct rb_process_status;
struct rb_execarg {
    union {
        struct {
            VALUE shell_script;
        } sh;
        struct {
            VALUE command_name;
            VALUE command_abspath; /* full path string or nil */
            VALUE argv_str;
            VALUE argv_buf;
        } cmd;
    } invoke;
    VALUE redirect_fds;
    VALUE envp_str;
    VALUE envp_buf;
    VALUE dup2_tmpbuf;
    unsigned use_shell : 1;
    unsigned pgroup_given : 1;
    unsigned umask_given : 1;
    unsigned unsetenv_others_given : 1;
    unsigned unsetenv_others_do : 1;
    unsigned close_others_given : 1;
    unsigned close_others_do : 1;
    unsigned chdir_given : 1;
    unsigned new_pgroup_given : 1;
    unsigned new_pgroup_flag : 1;
    unsigned uid_given : 1;
    unsigned gid_given : 1;
    unsigned exception : 1;
    unsigned exception_given : 1;
    struct rb_process_status *status;
    struct waitpid_state *waitpid_state; /* for async process management */
    rb_pid_t pgroup_pgid; /* asis(-1), new pgroup(0), specified pgroup (0<V). */
    VALUE rlimit_limits; /* Qfalse or [[rtype, softlim, hardlim], ...] */
    mode_t umask_mask;
    rb_uid_t uid;
    rb_gid_t gid;
    int close_others_maxhint;
    VALUE fd_dup2;
    VALUE fd_close;
    VALUE fd_open;
    VALUE fd_dup2_child;
    VALUE env_modification; /* Qfalse or [[k1,v1], ...] */
    VALUE path_env;
    VALUE chdir_dir;
};

/* process.c */
rb_pid_t rb_call_proc__fork(void);
void rb_last_status_clear(void);
static inline char **ARGVSTR2ARGV(VALUE argv_str);
static inline size_t ARGVSTR2ARGC(VALUE argv_str);

#ifdef HAVE_PWD_H
VALUE rb_getlogin(void);
VALUE rb_getpwdirnam_for_login(VALUE login);  /* read as: "get pwd db home dir by username for login" */
VALUE rb_getpwdiruid(void);                   /* read as: "get pwd db home dir for getuid()" */
#endif

RUBY_SYMBOL_EXPORT_BEGIN
/* process.c (export) */
int rb_exec_async_signal_safe(const struct rb_execarg *e, char *errmsg, size_t errmsg_buflen);
rb_pid_t rb_fork_async_signal_safe(int *status, int (*chfunc)(void*, char *, size_t), void *charg, VALUE fds, char *errmsg, size_t errmsg_buflen);
VALUE rb_execarg_new(int argc, const VALUE *argv, int accept_shell, int allow_exc_opt);
struct rb_execarg *rb_execarg_get(VALUE execarg_obj); /* dangerous.  needs GC guard. */
int rb_execarg_addopt(VALUE execarg_obj, VALUE key, VALUE val);
void rb_execarg_parent_start(VALUE execarg_obj);
void rb_execarg_parent_end(VALUE execarg_obj);
int rb_execarg_run_options(const struct rb_execarg *e, struct rb_execarg *s, char* errmsg, size_t errmsg_buflen);
VALUE rb_execarg_extract_options(VALUE execarg_obj, VALUE opthash);
void rb_execarg_setenv(VALUE execarg_obj, VALUE env);
RUBY_SYMBOL_EXPORT_END

/* argv_str contains extra two elements.
 * The beginning one is for /bin/sh used by exec_with_sh.
 * The last one for terminating NULL used by execve.
 * See rb_exec_fillarg() in process.c. */
static inline char **
ARGVSTR2ARGV(VALUE argv_str)
{
    char **buf = RB_IMEMO_TMPBUF_PTR(argv_str);
    return &buf[1];
}

static inline size_t
ARGVSTR2ARGC(VALUE argv_str)
{
    size_t i = 0;
    char *const *p = ARGVSTR2ARGV(argv_str);
    while (p[i++])
        ;
    return i - 1;
}

#endif /* INTERNAL_PROCESS_H */
