#ifndef INTERNAL_COMPLEX_H                               /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_COMPLEX_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for Complex.
 */
#include "ruby/internal/value.h"          /* for struct RBasic */

struct RComplex {
    struct RBasic basic;
    VALUE real;
    VALUE imag;
};

#define RCOMPLEX(obj) ((struct RComplex *)(obj))

/* shortcut macro for internal only */
#define RCOMPLEX_SET_REAL(cmp, r) RB_OBJ_WRITE((cmp), &RCOMPLEX(cmp)->real, (r))
#define RCOMPLEX_SET_IMAG(cmp, i) RB_OBJ_WRITE((cmp), &RCOMPLEX(cmp)->imag, (i))

/* complex.c */
VALUE rb_dbl_complex_new_polar_pi(double abs, double ang);
st_index_t rb_complex_hash(VALUE comp);

#endif /* INTERNAL_COMPLEX_H */
