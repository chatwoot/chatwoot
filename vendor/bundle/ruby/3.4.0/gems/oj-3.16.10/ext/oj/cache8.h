// Copyright (c) 2011 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_CACHE8_H
#define OJ_CACHE8_H

#include "ruby.h"
#include "stdint.h"

typedef struct _cache8 *Cache8;
typedef uint64_t        slot_t;
typedef uint64_t        sid_t;

extern void oj_cache8_new(Cache8 *cache);
extern void oj_cache8_delete(Cache8 cache);

extern slot_t oj_cache8_get(Cache8 cache, sid_t key, slot_t **slot);

extern void oj_cache8_print(Cache8 cache);

#endif /* OJ_CACHE8_H */
