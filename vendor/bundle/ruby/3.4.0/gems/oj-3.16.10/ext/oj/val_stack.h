// Copyright (c) 2011 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_VAL_STACK_H
#define OJ_VAL_STACK_H

#include <stdint.h>

#include "mem.h"
#include "odd.h"
#include "ruby.h"
#ifdef HAVE_PTHREAD_MUTEX_INIT
#include <pthread.h>
#endif

#define STACK_INC 64

typedef enum {
    NEXT_NONE          = 0,
    NEXT_ARRAY_NEW     = 'a',
    NEXT_ARRAY_ELEMENT = 'e',
    NEXT_ARRAY_COMMA   = ',',
    NEXT_HASH_NEW      = 'h',
    NEXT_HASH_KEY      = 'k',
    NEXT_HASH_COLON    = ':',
    NEXT_HASH_VALUE    = 'v',
    NEXT_HASH_COMMA    = 'n',
} ValNext;

typedef struct _val {
    volatile VALUE val;
    const char    *key;
    char           karray[32];
    volatile VALUE key_val;
    const char    *classname;
    VALUE          clas;
    OddArgs        odd_args;
    uint16_t       klen;
    uint16_t       clen;
    char           next;  // ValNext
    char           k1;    // first original character in the key
    char           kalloc;
} *Val;

typedef struct _valStack {
    struct _val base[STACK_INC];
    Val         head;  // current stack
    Val         end;   // stack end
    Val         tail;  // pointer to one past last element name on stack
#ifdef HAVE_PTHREAD_MUTEX_INIT
    pthread_mutex_t mutex;
#else
    VALUE mutex;
#endif

} *ValStack;

extern VALUE oj_stack_init(ValStack stack);

inline static int stack_empty(ValStack stack) {
    return (stack->head == stack->tail);
}

inline static void stack_cleanup(ValStack stack) {
    if (stack->base != stack->head) {
        OJ_R_FREE(stack->head);
        stack->head = NULL;
    }
}

inline static void stack_push(ValStack stack, VALUE val, ValNext next) {
    if (stack->end <= stack->tail) {
        size_t len  = stack->end - stack->head;
        size_t toff = stack->tail - stack->head;
        Val    head = stack->head;

        // A realloc can trigger a GC so make sure it happens outside the lock
        // but lock before changing pointers.
        if (stack->base == stack->head) {
            head = OJ_R_ALLOC_N(struct _val, len + STACK_INC);
            memcpy(head, stack->base, sizeof(struct _val) * len);
        } else {
            OJ_R_REALLOC_N(head, struct _val, len + STACK_INC);
        }
#ifdef HAVE_PTHREAD_MUTEX_INIT
        pthread_mutex_lock(&stack->mutex);
#else
        rb_mutex_lock(stack->mutex);
#endif
        stack->head = head;
        stack->tail = stack->head + toff;
        stack->end  = stack->head + len + STACK_INC;
#ifdef HAVE_PTHREAD_MUTEX_INIT
        pthread_mutex_unlock(&stack->mutex);
#else
        rb_mutex_unlock(stack->mutex);
#endif
    }
    stack->tail->val       = val;
    stack->tail->next      = next;
    stack->tail->classname = NULL;
    stack->tail->clas      = Qundef;
    stack->tail->odd_args  = NULL;
    stack->tail->key       = 0;
    stack->tail->key_val   = Qundef;
    stack->tail->clen      = 0;
    stack->tail->klen      = 0;
    stack->tail->kalloc    = 0;
    stack->tail++;
}

inline static size_t stack_size(ValStack stack) {
    return stack->tail - stack->head;
}

inline static Val stack_peek(ValStack stack) {
    if (stack->head < stack->tail) {
        return stack->tail - 1;
    }
    return 0;
}

inline static Val stack_peek_up(ValStack stack) {
    if (stack->head < stack->tail - 1) {
        return stack->tail - 2;
    }
    return 0;
}

inline static Val stack_prev(ValStack stack) {
    return stack->tail;
}

inline static VALUE stack_head_val(ValStack stack) {
    if (Qundef != stack->head->val) {
        return stack->head->val;
    }
    return Qnil;
}

inline static Val stack_pop(ValStack stack) {
    if (stack->head < stack->tail) {
        stack->tail--;
        return stack->tail;
    }
    return 0;
}

extern const char *oj_stack_next_string(ValNext n);

#endif /* OJ_VAL_STACK_H */
