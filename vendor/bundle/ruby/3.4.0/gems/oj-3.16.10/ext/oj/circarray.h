// Copyright (c) 2012 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for
// license details.

#ifndef OJ_CIRCARRAY_H
#define OJ_CIRCARRAY_H

#include "ruby.h"

typedef struct _circArray {
    VALUE         obj_array[1024];
    VALUE*        objs;
    unsigned long size;  // allocated size or initial array size
    unsigned long cnt;
}* CircArray;

extern CircArray oj_circ_array_new(void);
extern void      oj_circ_array_free(CircArray ca);
extern void      oj_circ_array_set(CircArray ca, VALUE obj, unsigned long id);
extern VALUE     oj_circ_array_get(CircArray ca, unsigned long id);

#endif /* OJ_CIRCARRAY_H */
