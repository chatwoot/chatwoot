// Copyright (c) 2011 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_PARSE_H
#define OJ_PARSE_H

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#include "circarray.h"
#include "oj.h"
#include "reader.h"
#include "ruby.h"
#include "rxclass.h"
#include "val_stack.h"

struct _rxClass;
struct _parseInfo;

typedef struct _numInfo {
    int64_t            i;
    int64_t            num;
    int64_t            div;
    int64_t            di;
    const char        *str;
    size_t             len;
    long               exp;
    struct _parseInfo *pi;
    int                big;
    int                infinity;
    int                nan;
    int                neg;
    int                has_exp;
    int                no_big;
    int                bigdec_load;
} *NumInfo;

typedef struct _parseInfo {
    // used for the string parser
    const char *json;
    const char *cur;
    const char *end;
    // used for the stream parser
    struct _reader rd;

    struct _err      err;
    struct _options  options;
    VALUE            handler;
    struct _valStack stack;
    CircArray        circ_array;
    struct _rxClass  str_rx;
    int              expect_value;
    int              max_depth;  // just for the json gem
    VALUE            proc;
    VALUE (*start_hash)(struct _parseInfo *pi);
    void (*end_hash)(struct _parseInfo *pi);
    VALUE (*hash_key)(struct _parseInfo *pi, const char *key, size_t klen);
    void (*hash_set_cstr)(struct _parseInfo *pi, Val kval, const char *str, size_t len, const char *orig);
    void (*hash_set_num)(struct _parseInfo *pi, Val kval, NumInfo ni);
    void (*hash_set_value)(struct _parseInfo *pi, Val kval, VALUE value);

    VALUE (*start_array)(struct _parseInfo *pi);
    void (*end_array)(struct _parseInfo *pi);
    void (*array_append_cstr)(struct _parseInfo *pi, const char *str, size_t len, const char *orig);
    void (*array_append_num)(struct _parseInfo *pi, NumInfo ni);
    void (*array_append_value)(struct _parseInfo *pi, VALUE value);

    void (*add_cstr)(struct _parseInfo *pi, const char *str, size_t len, const char *orig);
    void (*add_num)(struct _parseInfo *pi, NumInfo ni);
    void (*add_value)(struct _parseInfo *pi, VALUE val);
    VALUE err_class;
    bool  has_callbacks;
} *ParseInfo;

extern void  oj_parse2(ParseInfo pi);
extern void  oj_set_error_at(ParseInfo pi, VALUE err_clas, const char *file, int line, const char *format, ...);
extern VALUE oj_pi_parse(int argc, VALUE *argv, ParseInfo pi, char *json, size_t len, int yieldOk);
extern VALUE oj_num_as_value(NumInfo ni);

extern void oj_set_strict_callbacks(ParseInfo pi);
extern void oj_set_object_callbacks(ParseInfo pi);
extern void oj_set_compat_callbacks(ParseInfo pi);
extern void oj_set_custom_callbacks(ParseInfo pi);
extern void oj_set_wab_callbacks(ParseInfo pi);

extern void  oj_sparse2(ParseInfo pi);
extern VALUE oj_pi_sparse(int argc, VALUE *argv, ParseInfo pi, int fd);

extern VALUE oj_cstr_to_value(const char *str, size_t len, size_t cache_str);
extern VALUE oj_calc_hash_key(ParseInfo pi, Val parent);

static inline void parse_info_init(ParseInfo pi) {
    memset(pi, 0, sizeof(struct _parseInfo));
}

extern void oj_scanner_init(void);

static inline bool empty_ok(Options options) {
    switch (options->mode) {
    case ObjectMode:
    case WabMode: return true;
    case CompatMode:
    case RailsMode: return false;
    case StrictMode:
    case NullMode:
    case CustomMode:
    default: break;
    }
    return Yes == options->empty_string;
}

#endif /* OJ_PARSE_H */
