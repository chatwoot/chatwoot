// Copyright (c) 2011 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_BUF_H
#define OJ_BUF_H

#include "mem.h"
#include "ruby.h"

typedef struct _buf {
    char *head;
    char *end;
    char *tail;
    char  base[1024];
} *Buf;

inline static void buf_init(Buf buf) {
    buf->head = buf->base;
    buf->end  = buf->base + sizeof(buf->base) - 1;
    buf->tail = buf->head;
}

inline static void buf_reset(Buf buf) {
    buf->tail = buf->head;
}

inline static void buf_cleanup(Buf buf) {
    if (buf->base != buf->head) {
        OJ_R_FREE(buf->head);
    }
}

inline static size_t buf_len(Buf buf) {
    return buf->tail - buf->head;
}

inline static const char *buf_str(Buf buf) {
    *buf->tail = '\0';
    return buf->head;
}

inline static void buf_append_string(Buf buf, const char *s, size_t slen) {
    if (0 == slen) {
        return;
    }

    if (buf->end <= buf->tail + slen) {
        size_t len     = buf->end - buf->head;
        size_t toff    = buf->tail - buf->head;
        size_t new_len = len + slen + len / 2;

        if (buf->base == buf->head) {
            buf->head = OJ_R_ALLOC_N(char, new_len);
            memcpy(buf->head, buf->base, len);
        } else {
            OJ_R_REALLOC_N(buf->head, char, new_len);
        }
        buf->tail = buf->head + toff;
        buf->end  = buf->head + new_len - 1;
    }
    memcpy(buf->tail, s, slen);
    buf->tail += slen;
}

inline static void buf_append(Buf buf, char c) {
    if (buf->end <= buf->tail) {
        size_t len     = buf->end - buf->head;
        size_t toff    = buf->tail - buf->head;
        size_t new_len = len + len / 2;

        if (buf->base == buf->head) {
            buf->head = OJ_R_ALLOC_N(char, new_len);
            memcpy(buf->head, buf->base, len);
        } else {
            OJ_R_REALLOC_N(buf->head, char, new_len);
        }
        buf->tail = buf->head + toff;
        buf->end  = buf->head + new_len - 1;
    }
    *buf->tail = c;
    buf->tail++;
    //*buf->tail = '\0'; // for debugging
}

#endif /* OJ_BUF_H */
