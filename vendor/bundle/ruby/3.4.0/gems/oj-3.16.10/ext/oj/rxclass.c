// Copyright (c) 2017 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#if !IS_WINDOWS
#include <regex.h>
#endif

#include "mem.h"
#include "rxclass.h"

typedef struct _rxC {
    struct _rxC *next;
    VALUE        rrx;
#if !IS_WINDOWS
    regex_t rx;
#endif
    VALUE clas;
    char  src[256];
} *RxC;

void oj_rxclass_init(RxClass rc) {
    *rc->err = '\0';
    rc->head = NULL;
    rc->tail = NULL;
}

void oj_rxclass_cleanup(RxClass rc) {
    RxC rxc;

    while (NULL != (rxc = rc->head)) {
        rc->head = rc->head->next;
#if !IS_WINDOWS
        if (Qnil == rxc->rrx) {
            regfree(&rxc->rx);
        }
        OJ_R_FREE(rxc);
#endif
    }
}

void oj_rxclass_rappend(RxClass rc, VALUE rx, VALUE clas) {
    RxC rxc = OJ_R_ALLOC_N(struct _rxC, 1);

    memset(rxc, 0, sizeof(struct _rxC));
    rxc->rrx  = rx;
    rxc->clas = clas;
    if (NULL == rc->tail) {
        rc->head = rxc;
    } else {
        rc->tail->next = rxc;
    }
    rc->tail = rxc;
}

// Attempt to compile the expression. If it fails populate the error code..
int oj_rxclass_append(RxClass rc, const char *expr, VALUE clas) {
    RxC rxc;
#if !IS_WINDOWS
    int err;
    int flags = 0;
#endif
    if (sizeof(rxc->src) <= strlen(expr)) {
        snprintf(rc->err,
                 sizeof(rc->err),
                 "expressions must be less than %lu characters",
                 (unsigned long)sizeof(rxc->src));
        return EINVAL;
    }
    rxc       = OJ_R_ALLOC_N(struct _rxC, 1);
    rxc->next = 0;
    rxc->clas = clas;

#if IS_WINDOWS
    rxc->rrx = rb_funcall(rb_cRegexp, rb_intern("new"), 1, rb_str_new2(expr));
#else
    rxc->rrx = Qnil;
    if (0 != (err = regcomp(&rxc->rx, expr, flags))) {
        regerror(err, &rxc->rx, rc->err, sizeof(rc->err));
        OJ_FREE(rxc);
        return err;
    }
#endif
    if (NULL == rc->tail) {
        rc->head = rxc;
    } else {
        rc->tail->next = rxc;
    }
    rc->tail = rxc;

    return 0;
}

VALUE
oj_rxclass_match(RxClass rc, const char *str, int len) {
    RxC  rxc;
    char buf[4096];

    for (rxc = rc->head; NULL != rxc; rxc = rxc->next) {
        if (Qnil != rxc->rrx) {
            // Must use a valiabel for this to work.
            volatile VALUE rstr = rb_str_new(str, len);

            // if (Qtrue == rb_funcall(rxc->rrx, rb_intern("match?"), 1, rstr)) {
            if (Qnil != rb_funcall(rxc->rrx, rb_intern("match"), 1, rstr)) {
                return rxc->clas;
            }
        } else if (len < (int)sizeof(buf)) {
#if !IS_WINDOWS
            // string is not \0 terminated so copy and attempt a match
            memcpy(buf, str, len);
            buf[len] = '\0';
            if (0 == regexec(&rxc->rx, buf, 0, NULL, 0)) {  // match
                return rxc->clas;
            }
#endif
        } else {
            // TBD allocate a larger buffer and attempt
        }
    }
    return Qnil;
}

void oj_rxclass_copy(RxClass src, RxClass dest) {
    dest->head = NULL;
    dest->tail = NULL;
    if (NULL != src->head) {
        RxC rxc;

        for (rxc = src->head; NULL != rxc; rxc = rxc->next) {
            if (Qnil != rxc->rrx) {
                oj_rxclass_rappend(dest, rxc->rrx, rxc->clas);
            } else {
#if !IS_WINDOWS
                oj_rxclass_append(dest, rxc->src, rxc->clas);
#endif
            }
        }
    }
}
