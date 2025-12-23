// Copyright (c) 2021 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef CACHE_H
#define CACHE_H

#include <ruby.h>
#include <stdbool.h>

#define CACHE_MAX_KEY 35

struct _cache;
typedef struct _cache *Cache;

extern struct _cache *cache_create(size_t size, VALUE (*form)(const char *str, size_t len), bool mark, bool locking);
extern void           cache_free(void *data);
extern void           cache_mark(void *data);
extern void           cache_set_form(struct _cache *c, VALUE (*form)(const char *str, size_t len));
extern VALUE          cache_intern(struct _cache *c, const char *key, size_t len);
extern void           cache_set_expunge_rate(struct _cache *c, int rate);

#endif /* CACHE_H */
