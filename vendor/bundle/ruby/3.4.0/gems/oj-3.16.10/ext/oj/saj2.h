// Copyright (c) 2021, Peter Ohler, All rights reserved.

#include <ruby.h>
#include <stdbool.h>

struct _cache;
struct _ojParser;

typedef struct _saj {
    VALUE          handler;
    VALUE         *keys;
    VALUE         *tail;
    size_t         klen;
    struct _cache *str_cache;
    uint8_t        cache_str;
    bool           cache_keys;
    bool           thread_safe;
} *Saj;

// Initialize the parser with the SAJ delegate. If the SAJ delegate is wrapped
// then this function is called first and then the parser functions can be
// replaced.
extern void oj_init_saj(struct _ojParser *p, Saj d);
