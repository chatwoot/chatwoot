// Copyright (c) 2011 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_RESOLVE_H
#define OJ_RESOLVE_H

#include "ruby.h"

extern VALUE oj_name2class(ParseInfo pi, const char *name, size_t len, int auto_define, VALUE error_class);
extern VALUE oj_name2struct(ParseInfo pi, VALUE nameVal, VALUE error_class);

#endif /* OJ_RESOLVE_H */
