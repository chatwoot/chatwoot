#ifndef INTERNAL_CMDLINEOPT_H                               /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_CMDLINEOPT_H

#include "rjit.h"
#include "yjit.h"

typedef struct {
    unsigned int mask;
    unsigned int set;
} ruby_features_t;

typedef struct ruby_cmdline_options {
    const char *script;
    VALUE script_name;
    VALUE e_script;
    struct {
        struct {
            VALUE name;
            int index;
        } enc;
    } src, ext, intern;
    VALUE req_list;
    ruby_features_t features;
    ruby_features_t warn;
    unsigned int dump;
    long backtrace_length_limit;
#if USE_RJIT
    struct rb_rjit_options rjit;
#endif

    const char *crash_report;

    signed int sflag: 2;
    unsigned int xflag: 1;
    unsigned int warning: 1;
    unsigned int verbose: 1;
    unsigned int do_loop: 1;
    unsigned int do_print: 1;
    unsigned int do_line: 1;
    unsigned int do_split: 1;
    unsigned int do_search: 1;
    unsigned int setids: 2;
#if USE_YJIT
    unsigned int yjit: 1;
#endif
} ruby_cmdline_options_t;

struct ruby_opt_message {
    const char *str;
    unsigned short namelen, secondlen;
};

#define RUBY_OPT_MESSAGE(shortopt, longopt, desc) { \
    shortopt " " longopt " " desc, \
    (unsigned short)sizeof(shortopt), \
    (unsigned short)sizeof(longopt), \
}

#define opt_match(s, l, name) \
    ((((l) > rb_strlen_lit(name)) ? (s)[rb_strlen_lit(name)] == '=' : \
      (l) == rb_strlen_lit(name)) && \
     memcmp((s), name, rb_strlen_lit(name)) == 0 && \
     (((s) += rb_strlen_lit(name)), 1))

#endif
