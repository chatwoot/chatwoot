// Copyright (c) 2022, Peter Ohler, All rights reserved.

#include <ruby.h>
#include <stdbool.h>
#include <stdint.h>

struct _cache;
struct _ojParser;

// Used to mark the start of each Hash, Array, or Object. The members point at
// positions of the start in the value stack and if not an Array into the key
// stack.
typedef struct _col {
    long vi;  // value stack index
    long ki;  // key stack index if an hash else -1 for an array
} *Col;

typedef union _key {
    struct {
        int16_t len;
        char    buf[30];
    };
    struct {
        int16_t xlen;  // should be the same as len
        char   *key;
    };
} *Key;

#define MISS_AUTO 'A'
#define MISS_RAISE 'R'
#define MISS_IGNORE 'I'

typedef struct _usual {
    VALUE *vhead;
    VALUE *vtail;
    VALUE *vend;

    Col chead;
    Col ctail;
    Col cend;

    Key khead;
    Key ktail;
    Key kend;

    VALUE (*get_key)(struct _ojParser *p, Key kp);
    struct _cache *key_cache;  // same as str_cache or sym_cache
    struct _cache *str_cache;
    struct _cache *sym_cache;
    struct _cache *class_cache;
    struct _cache *attr_cache;

    VALUE array_class;
    VALUE hash_class;

    char   *create_id;
    uint8_t create_id_len;
    uint8_t cache_str;
    uint8_t cache_xrate;
    uint8_t miss_class;
    bool    cache_keys;
    bool    ignore_json_create;
    bool    raise_on_empty;
} *Usual;

// Initialize the parser with the usual delegate. If the usual delegate is
// wrapped then this function is called first and then the parser functions
// can be replaced.
extern void oj_init_usual(struct _ojParser *p, Usual d);
