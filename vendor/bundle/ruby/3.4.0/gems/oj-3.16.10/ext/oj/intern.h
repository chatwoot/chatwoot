// Copyright (c) 2011, 2021 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_INTERN_H
#define OJ_INTERN_H

#include <ruby.h>
#include <stdbool.h>

struct _parseInfo;

extern void oj_hash_init(void);

extern VALUE oj_str_intern(const char *key, size_t len);
extern VALUE oj_sym_intern(const char *key, size_t len);
extern ID    oj_attr_intern(const char *key, size_t len);
extern VALUE
oj_class_intern(const char *key, size_t len, bool safe, struct _parseInfo *pi, int auto_define, VALUE error_class);

extern char *oj_strndup(const char *s, size_t len);

#endif /* OJ_INTERN_H */
