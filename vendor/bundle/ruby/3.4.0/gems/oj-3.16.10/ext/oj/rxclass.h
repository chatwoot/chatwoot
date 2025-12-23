// Copyright (c) 2017 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_RXCLASS_H
#define OJ_RXCLASS_H

#include <stdbool.h>

#include "ruby.h"

struct _rxC;

typedef struct _rxClass {
    struct _rxC *head;
    struct _rxC *tail;
    char         err[128];
} *RxClass;

extern void  oj_rxclass_init(RxClass rc);
extern void  oj_rxclass_cleanup(RxClass rc);
extern int   oj_rxclass_append(RxClass rc, const char *expr, VALUE clas);
extern VALUE oj_rxclass_match(RxClass rc, const char *str, int len);
extern void  oj_rxclass_copy(RxClass src, RxClass dest);
extern void  oj_rxclass_rappend(RxClass rc, VALUE rx, VALUE clas);

#endif /* OJ_RXCLASS_H */
