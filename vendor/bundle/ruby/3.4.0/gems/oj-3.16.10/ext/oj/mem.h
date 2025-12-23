// Copyright (c) 2018, Peter Ohler, All rights reserved.

#ifndef OJ_MEM_H
#define OJ_MEM_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef MEM_DEBUG

#define OJ_MALLOC(size) oj_malloc(size, __FILE__, __LINE__)
#define OJ_REALLOC(ptr, size) oj_realloc(ptr, size, __FILE__, __LINE__)
#define OJ_CALLOC(count, size) oj_calloc(count, size, __FILE__, __LINE__)
#define OJ_FREE(ptr) oj_free(ptr, __FILE__, __LINE__)

#define OJ_R_ALLOC(type) oj_r_alloc(sizeof(type), __FILE__, __LINE__)
#define OJ_R_ALLOC_N(type, n) (type *)oj_r_alloc(sizeof(type) * (n), __FILE__, __LINE__)
#define OJ_R_REALLOC_N(ptr, type, n) ((ptr) = (type *)oj_r_realloc(ptr, (sizeof(type) * (n)), __FILE__, __LINE__))
#define OJ_R_FREE(ptr) oj_r_free(ptr, __FILE__, __LINE__)

#define OJ_STRDUP(str) oj_mem_strdup(str, __FILE__, __LINE__)

extern void *oj_malloc(size_t size, const char *file, int line);
extern void *oj_realloc(void *ptr, size_t size, const char *file, int line);
extern void *oj_calloc(size_t count, size_t size, const char *file, int line);
extern void  oj_free(void *ptr, const char *file, int line);

extern void *oj_r_alloc(size_t size, const char *file, int line);
extern void *oj_r_realloc(void *ptr, size_t size, const char *file, int line);
extern void  oj_r_free(void *ptr, const char *file, int line);

extern char *oj_mem_strdup(const char *str, const char *file, int line);

#else

#define OJ_MALLOC(size) malloc(size)
#define OJ_REALLOC(ptr, size) realloc(ptr, size)
#define OJ_CALLOC(count, size) calloc(count, size)
#define OJ_FREE(ptr) free(ptr)

#define OJ_R_ALLOC(type) RB_ALLOC(type)
#define OJ_R_ALLOC_N(type, n) RB_ALLOC_N(type, n)
#define OJ_R_REALLOC_N(ptr, type, n) RB_REALLOC_N(ptr, type, n)
#define OJ_R_FREE(ptr) xfree(ptr)

#define OJ_STRDUP(str) strdup(str)

#endif

extern void oj_mem_report();

#endif /* OJ_MEM_H */
