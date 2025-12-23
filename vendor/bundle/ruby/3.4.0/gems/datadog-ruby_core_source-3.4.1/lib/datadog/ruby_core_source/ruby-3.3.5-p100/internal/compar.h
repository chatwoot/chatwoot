#ifndef INTERNAL_COMPAR_H                                /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_COMPAR_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Comparable.
 */
#include "internal/basic_operators.h"

#define STRING_P(s) (RB_TYPE_P((s), T_STRING) && CLASS_OF(s) == rb_cString)

#define CMP_OPTIMIZABLE(type) BASIC_OP_UNREDEFINED_P(BOP_CMP, type##_REDEFINED_OP_FLAG)

#define OPTIMIZED_CMP(a, b) \
    ((FIXNUM_P(a) && FIXNUM_P(b) && CMP_OPTIMIZABLE(INTEGER)) ? \
     (((long)a > (long)b) ? 1 : ((long)a < (long)b) ? -1 : 0) : \
     (STRING_P(a) && STRING_P(b) && CMP_OPTIMIZABLE(STRING)) ? \
     rb_str_cmp(a, b) : \
     (RB_FLOAT_TYPE_P(a) && RB_FLOAT_TYPE_P(b) && CMP_OPTIMIZABLE(FLOAT)) ? \
     rb_float_cmp(a, b) : \
     rb_cmpint(rb_funcallv(a, id_cmp, 1, &b), a, b))

/* compar.c */
VALUE rb_invcmp(VALUE, VALUE);

#endif /* INTERNAL_COMPAR_H */
