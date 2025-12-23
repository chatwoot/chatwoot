// Copyright (c) 2018 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_TRACE_H
#define OJ_TRACE_H

#include <ruby.h>
#include <stdbool.h>

typedef enum {
    TraceIn      = '}',
    TraceOut     = '{',
    TraceCall    = '-',
    TraceRubyIn  = '>',
    TraceRubyOut = '<',
} TraceWhere;

struct _parseInfo;

extern void oj_trace(const char *func, VALUE obj, const char *file, int line, int depth, TraceWhere where);
extern void oj_trace_parse_in(const char *func, struct _parseInfo *pi, const char *file, int line);
extern void oj_trace_parse_call(const char *func, struct _parseInfo *pi, const char *file, int line, VALUE obj);
extern void oj_trace_parse_hash_end(struct _parseInfo *pi, const char *file, int line);
extern void oj_trace_parse_array_end(struct _parseInfo *pi, const char *file, int line);

#ifdef OJ_ENABLE_TRACE_LOG
#define TRACE(option, func, obj, depth, where)                 \
    if (RB_UNLIKELY(Yes == option)) {                          \
        oj_trace(func, obj, __FILE__, __LINE__, depth, where); \
    }
#define TRACE_PARSE_IN(option, func, pi)                 \
    if (RB_UNLIKELY(Yes == option)) {                    \
        oj_trace_parse_in(func, pi, __FILE__, __LINE__); \
    }
#define TRACE_PARSE_CALL(option, func, pi, obj)                 \
    if (RB_UNLIKELY(Yes == option)) {                           \
        oj_trace_parse_call(func, pi, __FILE__, __LINE__, obj); \
    }
#define TRACE_PARSE_HASH_END(option, pi)                 \
    if (RB_UNLIKELY(Yes == option)) {                    \
        oj_trace_parse_hash_end(pi, __FILE__, __LINE__); \
    }
#define TRACE_PARSE_ARRAY_END(option, pi)                 \
    if (RB_UNLIKELY(Yes == option)) {                     \
        oj_trace_parse_array_end(pi, __FILE__, __LINE__); \
    }
#else
#define TRACE(option, func, obj, depth, where)
#define TRACE_PARSE_IN(option, func, pi)
#define TRACE_PARSE_CALL(option, func, pi, obj)
#define TRACE_PARSE_HASH_END(option, pi)
#define TRACE_PARSE_ARRAY_END(option, pi)
#endif

#endif /* OJ_TRACE_H */
