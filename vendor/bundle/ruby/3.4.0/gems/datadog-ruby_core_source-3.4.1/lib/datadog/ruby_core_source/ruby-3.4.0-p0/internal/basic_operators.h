#ifndef INTERNAL_BOP_H                                /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_BOP_H

#include "internal.h"
#include "ruby/internal/dllexport.h"

enum ruby_basic_operators {
    BOP_PLUS,
    BOP_MINUS,
    BOP_MULT,
    BOP_DIV,
    BOP_MOD,
    BOP_EQ,
    BOP_EQQ,
    BOP_LT,
    BOP_LE,
    BOP_LTLT,
    BOP_AREF,
    BOP_ASET,
    BOP_LENGTH,
    BOP_SIZE,
    BOP_EMPTY_P,
    BOP_NIL_P,
    BOP_SUCC,
    BOP_GT,
    BOP_GE,
    BOP_NOT,
    BOP_NEQ,
    BOP_MATCH,
    BOP_FREEZE,
    BOP_UMINUS,
    BOP_MAX,
    BOP_MIN,
    BOP_HASH,
    BOP_CALL,
    BOP_AND,
    BOP_OR,
    BOP_CMP,
    BOP_DEFAULT,
    BOP_PACK,
    BOP_INCLUDE_P,

    BOP_LAST_
};

RUBY_EXTERN short ruby_vm_redefined_flag[BOP_LAST_];

/* optimize insn */
#define INTEGER_REDEFINED_OP_FLAG (1 << 0)
#define FLOAT_REDEFINED_OP_FLAG  (1 << 1)
#define STRING_REDEFINED_OP_FLAG (1 << 2)
#define ARRAY_REDEFINED_OP_FLAG  (1 << 3)
#define HASH_REDEFINED_OP_FLAG   (1 << 4)
/* #define BIGNUM_REDEFINED_OP_FLAG (1 << 5) */
#define SYMBOL_REDEFINED_OP_FLAG (1 << 6)
#define TIME_REDEFINED_OP_FLAG   (1 << 7)
#define REGEXP_REDEFINED_OP_FLAG (1 << 8)
#define NIL_REDEFINED_OP_FLAG    (1 << 9)
#define TRUE_REDEFINED_OP_FLAG   (1 << 10)
#define FALSE_REDEFINED_OP_FLAG  (1 << 11)
#define PROC_REDEFINED_OP_FLAG   (1 << 12)

#define BASIC_OP_UNREDEFINED_P(op, klass) (LIKELY((ruby_vm_redefined_flag[(op)]&(klass)) == 0))

#endif
