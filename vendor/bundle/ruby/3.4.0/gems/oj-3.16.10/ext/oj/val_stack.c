// Copyright (c) 2011 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include "val_stack.h"

#include <string.h>

#include "odd.h"
#include "oj.h"

static void stack_mark(void *ptr) {
    ValStack stack = (ValStack)ptr;
    Val      v;

    if (NULL == ptr) {
        return;
    }
#ifdef HAVE_PTHREAD_MUTEX_INIT
    pthread_mutex_lock(&stack->mutex);
#else
    rb_mutex_lock(stack->mutex);
    rb_gc_mark(stack->mutex);
#endif
    for (v = stack->head; v < stack->tail; v++) {
        if (Qnil != v->val && Qundef != v->val) {
            rb_gc_mark(v->val);
        }
        if (Qnil != v->key_val && Qundef != v->key_val) {
            rb_gc_mark(v->key_val);
        }
        if (NULL != v->odd_args) {
            VALUE *a;
            int    i;

            for (i = v->odd_args->odd->attr_cnt, a = v->odd_args->args; 0 < i; i--, a++) {
                if (Qnil != *a) {
                    rb_gc_mark(*a);
                }
            }
        }
    }
#ifdef HAVE_PTHREAD_MUTEX_INIT
    pthread_mutex_unlock(&stack->mutex);
#else
    rb_mutex_unlock(stack->mutex);
#endif
}

static const rb_data_type_t oj_stack_type = {
    "Oj/stack",
    {
        stack_mark,
        NULL,
        NULL,
    },
    0,
    0,
};

VALUE
oj_stack_init(ValStack stack) {
#ifdef HAVE_PTHREAD_MUTEX_INIT
    int err;

    if (0 != (err = pthread_mutex_init(&stack->mutex, 0))) {
        rb_raise(rb_eException, "failed to initialize a mutex. %s", strerror(err));
    }
#else
    stack->mutex = rb_mutex_new();
#endif
    stack->head            = stack->base;
    stack->end             = stack->base + sizeof(stack->base) / sizeof(struct _val);
    stack->tail            = stack->head;
    stack->head->val       = Qundef;
    stack->head->key       = NULL;
    stack->head->key_val   = Qundef;
    stack->head->classname = NULL;
    stack->head->odd_args  = NULL;
    stack->head->clas      = Qundef;
    stack->head->klen      = 0;
    stack->head->clen      = 0;
    stack->head->next      = NEXT_NONE;

    return TypedData_Wrap_Struct(oj_cstack_class, &oj_stack_type, stack);
}

const char *oj_stack_next_string(ValNext n) {
    switch (n) {
    case NEXT_ARRAY_NEW: return "array element or close";
    case NEXT_ARRAY_ELEMENT: return "array element";
    case NEXT_ARRAY_COMMA: return "comma";
    case NEXT_HASH_NEW: return "hash pair or close";
    case NEXT_HASH_KEY: return "hash key";
    case NEXT_HASH_COLON: return "colon";
    case NEXT_HASH_VALUE: return "hash value";
    case NEXT_HASH_COMMA: return "comma";
    case NEXT_NONE: break;
    default: break;
    }
    return "nothing";
}
