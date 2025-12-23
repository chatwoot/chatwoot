/*
 *
 * Ruby BigDecimal(Variable decimal precision) extension library.
 *
 * Copyright(C) 2002 by Shigeo Kobayashi(shigeo@tinyforest.gr.jp)
 *
 */

/* #define BIGDECIMAL_DEBUG 1 */

#include "bigdecimal.h"
#include "ruby/util.h"

#ifndef BIGDECIMAL_DEBUG
# undef NDEBUG
# define NDEBUG
#endif
#include <assert.h>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <math.h>

#ifdef HAVE_IEEEFP_H
#include <ieeefp.h>
#endif

#include "bits.h"
#include "static_assert.h"

#define BIGDECIMAL_VERSION "3.2.2"

/* #define ENABLE_NUMERIC_STRING */

#define SIGNED_VALUE_MAX INTPTR_MAX
#define SIGNED_VALUE_MIN INTPTR_MIN
#define MUL_OVERFLOW_SIGNED_VALUE_P(a, b) MUL_OVERFLOW_SIGNED_INTEGER_P(a, b, SIGNED_VALUE_MIN, SIGNED_VALUE_MAX)

VALUE rb_cBigDecimal;
VALUE rb_mBigMath;

static ID id_BigDecimal_exception_mode;
static ID id_BigDecimal_rounding_mode;
static ID id_BigDecimal_precision_limit;

static ID id_up;
static ID id_down;
static ID id_truncate;
static ID id_half_up;
static ID id_default;
static ID id_half_down;
static ID id_half_even;
static ID id_banker;
static ID id_ceiling;
static ID id_ceil;
static ID id_floor;
static ID id_to_r;
static ID id_eq;
static ID id_half;

#define RBD_NUM_ROUNDING_MODES 11

static struct {
    ID id;
    uint8_t mode;
} rbd_rounding_modes[RBD_NUM_ROUNDING_MODES];

/* MACRO's to guard objects from GC by keeping them in stack */
#ifdef RBIMPL_ATTR_MAYBE_UNUSED
#define ENTER(n) RBIMPL_ATTR_MAYBE_UNUSED() volatile VALUE vStack[n];int iStack=0
#else
#define ENTER(n) volatile VALUE RB_UNUSED_VAR(vStack[n]);int iStack=0
#endif
#define PUSH(x)  (vStack[iStack++] = (VALUE)(x))
#define SAVE(p)  PUSH((p)->obj)
#define GUARD_OBJ(p,y) ((p)=(y), SAVE(p))

#define BASE_FIG  BIGDECIMAL_COMPONENT_FIGURES
#define BASE      BIGDECIMAL_BASE

#define HALF_BASE (BASE/2)
#define BASE1 (BASE/10)

#define LOG10_2 0.3010299956639812

#ifndef RRATIONAL_ZERO_P
# define RRATIONAL_ZERO_P(x) (FIXNUM_P(rb_rational_num(x)) && \
			      FIX2LONG(rb_rational_num(x)) == 0)
#endif

#ifndef RRATIONAL_NEGATIVE_P
# define RRATIONAL_NEGATIVE_P(x) RTEST(rb_funcall((x), '<', 1, INT2FIX(0)))
#endif

#ifndef DECIMAL_SIZE_OF_BITS
#define DECIMAL_SIZE_OF_BITS(n) (((n) * 3010 + 9998) / 9999)
/* an approximation of ceil(n * log10(2)), upto 65536 at least */
#endif

#ifdef PRIsVALUE
# define RB_OBJ_CLASSNAME(obj) rb_obj_class(obj)
# define RB_OBJ_STRING(obj) (obj)
#else
# define PRIsVALUE "s"
# define RB_OBJ_CLASSNAME(obj) rb_obj_classname(obj)
# define RB_OBJ_STRING(obj) StringValueCStr(obj)
#endif

#ifndef MAYBE_UNUSED
# define MAYBE_UNUSED(x) x
#endif

#define BIGDECIMAL_POSITIVE_P(bd) ((bd)->sign > 0)
#define BIGDECIMAL_NEGATIVE_P(bd) ((bd)->sign < 0)

/*
 * ================== Memory allocation ============================
 */

#ifdef BIGDECIMAL_DEBUG
static size_t rbd_allocation_count = 0;   /* Memory allocation counter */
static inline void
atomic_allocation_count_inc(void)
{
    RUBY_ATOMIC_SIZE_INC(rbd_allocation_count);
}
static inline void
atomic_allocation_count_dec_nounderflow(void)
{
    if (rbd_allocation_count == 0) return;
    RUBY_ATOMIC_SIZE_DEC(rbd_allocation_count);
}
static void
check_allocation_count_nonzero(void)
{
    if (rbd_allocation_count != 0) return;
    rb_bug("[bigdecimal][rbd_free_struct] Too many memory free calls");
}
#else
#   define atomic_allocation_count_inc() /* nothing */
#   define atomic_allocation_count_dec_nounderflow() /* nothing */
#   define check_allocation_count_nonzero() /* nothing */
#endif /* BIGDECIMAL_DEBUG */

PUREFUNC(static inline size_t rbd_struct_size(size_t const));

static inline size_t
rbd_struct_size(size_t const internal_digits)
{
    size_t const frac_len = (internal_digits == 0) ? 1 : internal_digits;
    return offsetof(Real, frac) + frac_len * sizeof(DECDIG);
}

static inline Real *
rbd_allocate_struct(size_t const internal_digits)
{
    size_t const size = rbd_struct_size(internal_digits);
    Real *real = ruby_xcalloc(1, size);
    atomic_allocation_count_inc();
    real->MaxPrec = internal_digits;
    return real;
}

static size_t
rbd_calculate_internal_digits(size_t const digits, bool limit_precision)
{
    size_t const len = roomof(digits, BASE_FIG);
    if (limit_precision) {
        size_t const prec_limit = VpGetPrecLimit();
        if (prec_limit > 0) {
            /* NOTE: 2 more digits for rounding and division */
            size_t const max_len = roomof(prec_limit, BASE_FIG) + 2;
            if (len > max_len)
                return max_len;
        }
    }

    return len;
}

static inline Real *
rbd_allocate_struct_decimal_digits(size_t const decimal_digits, bool limit_precision)
{
    size_t const internal_digits = rbd_calculate_internal_digits(decimal_digits, limit_precision);
    return rbd_allocate_struct(internal_digits);
}

static VALUE BigDecimal_wrap_struct(VALUE obj, Real *vp);

static Real *
rbd_reallocate_struct(Real *real, size_t const internal_digits)
{
    size_t const size = rbd_struct_size(internal_digits);
    VALUE obj = real ? real->obj : 0;
    Real *new_real = (Real *)ruby_xrealloc(real, size);
    new_real->MaxPrec = internal_digits;
    if (obj) {
        new_real->obj = 0;
        BigDecimal_wrap_struct(obj, new_real);
    }
    return new_real;
}

static void
rbd_free_struct(Real *real)
{
    if (real != NULL) {
        check_allocation_count_nonzero();
        ruby_xfree(real);
        atomic_allocation_count_dec_nounderflow();
    }
}

#define NewZero rbd_allocate_struct_zero
static Real *
rbd_allocate_struct_zero(int sign, size_t const digits, bool limit_precision)
{
    Real *real = rbd_allocate_struct_decimal_digits(digits, limit_precision);
    VpSetZero(real, sign);
    return real;
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_zero_limited(int sign, size_t const digits));
#define NewZeroLimited rbd_allocate_struct_zero_limited
static inline Real *
rbd_allocate_struct_zero_limited(int sign, size_t const digits)
{
    return rbd_allocate_struct_zero(sign, digits, true);
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_zero_nolimit(int sign, size_t const digits));
#define NewZeroNolimit rbd_allocate_struct_zero_nolimit
static inline Real *
rbd_allocate_struct_zero_nolimit(int sign, size_t const digits)
{
    return rbd_allocate_struct_zero(sign, digits, false);
}

#define NewOne rbd_allocate_struct_one
static Real *
rbd_allocate_struct_one(int sign, size_t const digits, bool limit_precision)
{
    Real *real = rbd_allocate_struct_decimal_digits(digits, limit_precision);
    VpSetOne(real);
    if (sign < 0)
        VpSetSign(real, VP_SIGN_NEGATIVE_FINITE);
    return real;
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_one_limited(int sign, size_t const digits));
#define NewOneLimited rbd_allocate_struct_one_limited
static inline Real *
rbd_allocate_struct_one_limited(int sign, size_t const digits)
{
    return rbd_allocate_struct_one(sign, digits, true);
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_one_nolimit(int sign, size_t const digits));
#define NewOneNolimit rbd_allocate_struct_one_nolimit
static inline Real *
rbd_allocate_struct_one_nolimit(int sign, size_t const digits)
{
    return rbd_allocate_struct_one(sign, digits, false);
}

/*
 * ================== Ruby Interface part ==========================
 */
#define DoSomeOne(x,y,f) rb_num_coerce_bin(x,y,f)

/*
 *   VP routines used in BigDecimal part
 */
static unsigned short VpGetException(void);
static void  VpSetException(unsigned short f);
static void VpCheckException(Real *p, bool always);
static VALUE VpCheckGetValue(Real *p);
static void  VpInternalRound(Real *c, size_t ixDigit, DECDIG vPrev, DECDIG v);
static int   VpLimitRound(Real *c, size_t ixDigit);
static Real *VpCopy(Real *pv, Real const* const x);
static int VPrint(FILE *fp,const char *cntl_chr,Real *a);

/*
 *  **** BigDecimal part ****
 */

static VALUE BigDecimal_nan(void);
static VALUE BigDecimal_positive_infinity(void);
static VALUE BigDecimal_negative_infinity(void);
static VALUE BigDecimal_positive_zero(void);
static VALUE BigDecimal_negative_zero(void);

static void
BigDecimal_delete(void *pv)
{
    rbd_free_struct(pv);
}

static size_t
BigDecimal_memsize(const void *ptr)
{
    const Real *pv = ptr;
    return (sizeof(*pv) + pv->MaxPrec * sizeof(DECDIG));
}

#ifndef HAVE_RB_EXT_RACTOR_SAFE
#   undef RUBY_TYPED_FROZEN_SHAREABLE
#   define RUBY_TYPED_FROZEN_SHAREABLE 0
#endif

static const rb_data_type_t BigDecimal_data_type = {
    "BigDecimal",
    { 0, BigDecimal_delete, BigDecimal_memsize, },
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_FROZEN_SHAREABLE | RUBY_TYPED_WB_PROTECTED
#endif
};

static Real *
rbd_allocate_struct_zero_wrap_klass(VALUE klass, int sign, size_t const digits, bool limit_precision)
{
    Real *real = rbd_allocate_struct_zero(sign, digits, limit_precision);
    if (real != NULL) {
        VALUE obj = TypedData_Wrap_Struct(klass, &BigDecimal_data_type, 0);
        BigDecimal_wrap_struct(obj, real);
    }
    return real;
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_zero_limited_wrap(int sign, size_t const digits));
#define NewZeroWrapLimited rbd_allocate_struct_zero_limited_wrap
static inline Real *
rbd_allocate_struct_zero_limited_wrap(int sign, size_t const digits)
{
    return rbd_allocate_struct_zero_wrap_klass(rb_cBigDecimal, sign, digits, true);
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_zero_nolimit_wrap(int sign, size_t const digits));
#define NewZeroWrapNolimit rbd_allocate_struct_zero_nolimit_wrap
static inline Real *
rbd_allocate_struct_zero_nolimit_wrap(int sign, size_t const digits)
{
    return rbd_allocate_struct_zero_wrap_klass(rb_cBigDecimal, sign, digits, false);
}

static Real *
rbd_allocate_struct_one_wrap_klass(VALUE klass, int sign, size_t const digits, bool limit_precision)
{
    Real *real = rbd_allocate_struct_one(sign, digits, limit_precision);
    if (real != NULL) {
        VALUE obj = TypedData_Wrap_Struct(klass, &BigDecimal_data_type, 0);
        BigDecimal_wrap_struct(obj, real);
    }
    return real;
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_one_limited_wrap(int sign, size_t const digits));
#define NewOneWrapLimited rbd_allocate_struct_one_limited_wrap
static inline Real *
rbd_allocate_struct_one_limited_wrap(int sign, size_t const digits)
{
    return rbd_allocate_struct_one_wrap_klass(rb_cBigDecimal, sign, digits, true);
}

MAYBE_UNUSED(static inline Real * rbd_allocate_struct_one_nolimit_wrap(int sign, size_t const digits));
#define NewOneWrapNolimit rbd_allocate_struct_one_nolimit_wrap
static inline Real *
rbd_allocate_struct_one_nolimit_wrap(int sign, size_t const digits)
{
    return rbd_allocate_struct_one_wrap_klass(rb_cBigDecimal, sign, digits, false);
}

static inline int
is_kind_of_BigDecimal(VALUE const v)
{
    return rb_typeddata_is_kind_of(v, &BigDecimal_data_type);
}

NORETURN(static void cannot_be_coerced_into_BigDecimal(VALUE, VALUE));

static void
cannot_be_coerced_into_BigDecimal(VALUE exc_class, VALUE v)
{
    VALUE str;

    if (rb_special_const_p(v)) {
	str = rb_inspect(v);
    }
    else {
	str = rb_class_name(rb_obj_class(v));
    }

    str = rb_str_cat2(rb_str_dup(str), " can't be coerced into BigDecimal");
    rb_exc_raise(rb_exc_new3(exc_class, str));
}

static inline VALUE BigDecimal_div2(VALUE, VALUE, VALUE);
static VALUE rb_inum_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception);
static VALUE rb_float_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception);
static VALUE rb_rational_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception);
static VALUE rb_cstr_convert_to_BigDecimal(const char *c_str, size_t digs, int raise_exception);
static VALUE rb_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception);

static Real*
GetVpValueWithPrec(VALUE v, long prec, int must)
{
    const size_t digs = prec < 0 ? SIZE_MAX : (size_t)prec;

    switch(TYPE(v)) {
      case T_FLOAT:
        v = rb_float_convert_to_BigDecimal(v, digs, must);
        break;

      case T_RATIONAL:
        v = rb_rational_convert_to_BigDecimal(v, digs, must);
        break;

      case T_DATA:
        if (!is_kind_of_BigDecimal(v)) {
            goto SomeOneMayDoIt;
        }
        break;

      case T_FIXNUM: {
        char szD[128];
        snprintf(szD, 128, "%ld", FIX2LONG(v));
        v = rb_cstr_convert_to_BigDecimal(szD, VpBaseFig() * 2 + 1, must);
        break;
      }

#ifdef ENABLE_NUMERIC_STRING
      case T_STRING: {
        const char *c_str = StringValueCStr(v);
        v = rb_cstr_convert_to_BigDecimal(c_str, RSTRING_LEN(v) + VpBaseFig() + 1, must);
        break;
      }
#endif /* ENABLE_NUMERIC_STRING */

      case T_BIGNUM: {
	VALUE bg = rb_big2str(v, 10);
        v = rb_cstr_convert_to_BigDecimal(RSTRING_PTR(bg), RSTRING_LEN(bg) + VpBaseFig() + 1, must);
        RB_GC_GUARD(bg);
        break;
      }

      default:
	goto SomeOneMayDoIt;
    }

    Real *vp;
    TypedData_Get_Struct(v, Real, &BigDecimal_data_type, vp);
    return vp;

SomeOneMayDoIt:
    if (must) {
	cannot_be_coerced_into_BigDecimal(rb_eTypeError, v);
    }
    return NULL; /* NULL means to coerce */
}

static inline Real*
GetVpValue(VALUE v, int must)
{
    return GetVpValueWithPrec(v, -1, must);
}

/* call-seq:
 *   BigDecimal.double_fig -> integer
 *
 *  Returns the number of digits a Float object is allowed to have;
 *  the result is system-dependent:
 *
 *    BigDecimal.double_fig # => 16
 *
 */
static inline VALUE
BigDecimal_double_fig(VALUE self)
{
    return INT2FIX(VpDblFig());
}

/*  call-seq:
 *    precs -> array
 *
 *  Returns an Array of two Integer values that represent platform-dependent
 *  internal storage properties.
 *
 *  This method is deprecated and will be removed in the future.
 *  Instead, use BigDecimal#n_significant_digits for obtaining the number of
 *  significant digits in scientific notation, and BigDecimal#precision for
 *  obtaining the number of digits in decimal notation.
 *
 */

static VALUE
BigDecimal_prec(VALUE self)
{
    ENTER(1);
    Real *p;
    VALUE obj;

    rb_category_warn(RB_WARN_CATEGORY_DEPRECATED,
                     "BigDecimal#precs is deprecated and will be removed in the future; "
                     "use BigDecimal#precision instead.");

    GUARD_OBJ(p, GetVpValue(self, 1));
    obj = rb_assoc_new(SIZET2NUM(p->Prec*VpBaseFig()),
		       SIZET2NUM(p->MaxPrec*VpBaseFig()));
    return obj;
}

static void
VpCountPrecisionAndScale(Real *p, ssize_t *out_precision, ssize_t *out_scale)
{
    if (out_precision == NULL && out_scale == NULL)
        return;
    if (VpIsZero(p) || !VpIsDef(p)) {
      zero:
        if (out_precision) *out_precision = 0;
        if (out_scale) *out_scale = 0;
        return;
    }

    DECDIG x;

    ssize_t n = p->Prec; /* The length of frac without zeros. */
    while (n > 0 && p->frac[n-1] == 0) --n;
    if (n == 0) goto zero;

    int nlz = BASE_FIG;
    for (x = p->frac[0]; x > 0; x /= 10) --nlz;

    int ntz = 0;
    for (x = p->frac[n-1]; x > 0 && x % 10 == 0; x /= 10) ++ntz;

    /*
     * Calculate the precision and the scale
     * -------------------------------------
     *
     * The most significant digit is frac[0], and the least significant digit
     * is frac[Prec-1].  When the exponent is zero, the decimal point is
     * located just before frac[0].
     *
     * When the exponent is negative, the decimal point moves to leftward.
     * In this case, the precision can be calculated by
     *
     *   precision = BASE_FIG * (-exponent + n) - ntz,
     *
     * and the scale is the same as precision.
     *
     *       0 . 0000 0000 | frac[0] ... frac[n-1] |
     *         |<----------| exponent == -2        |
     *         |---------------------------------->| precision
     *         |---------------------------------->| scale
     *
     *
     * Conversely, when the exponent is positive, the decimal point moves to
     * rightward.  In this case, the scale equals to
     *
     *   BASE_FIG * (n - exponent) - ntz.
     *
     * the precision equals to
     *
     *   scale + BASE_FIG * exponent - nlz.
     *
     *       | frac[0] frac[1] . frac[2] ... frac[n-1] |
     *       |---------------->| exponent == 2         |
     *       |                 |---------------------->| scale
     *       |---------------------------------------->| precision
     */

    ssize_t ex = p->exponent;

    /* Count the number of decimal digits before frac[1]. */
    ssize_t n_digits_head = BASE_FIG;
    if (ex < 0) {
      n_digits_head += (-ex) * BASE_FIG;  /* The number of leading zeros before frac[0]. */
      ex = 0;
    }
    else if (ex > 0) {
      /* Count the number of decimal digits without the leading zeros in
       * the most significant digit in the integral part.
       */
      n_digits_head -= nlz;  /* Make the number of digits */
    }

    if (out_precision) {
        ssize_t precision = n_digits_head;

        /* Count the number of decimal digits after frac[0]. */
        if (ex > (ssize_t)n) {
          /* In this case the number is an integer with some trailing zeros. */
          precision += (ex - 1) * BASE_FIG;
        }
        else if (n > 0) {
          precision += (n - 1) * BASE_FIG;

          if (ex < (ssize_t)n) {
            precision -= ntz;
          }
        }

        *out_precision = precision;
    }

    if (out_scale) {
        ssize_t scale = 0;

        if (p->exponent < 0) {
            scale = n_digits_head + (n - 1) * BASE_FIG - ntz;
        }
        else if (n > p->exponent) {
            scale = (n - p->exponent) * BASE_FIG - ntz;
        }

        *out_scale = scale;
    }
}

static void
BigDecimal_count_precision_and_scale(VALUE self, ssize_t *out_precision, ssize_t *out_scale)
{
    ENTER(1);
    Real *p;
    GUARD_OBJ(p, GetVpValue(self, 1));
    VpCountPrecisionAndScale(p, out_precision, out_scale);
}

/*
 *  call-seq:
 *    precision -> integer
 *
 *  Returns the number of decimal digits in +self+:
 *
 *    BigDecimal("0").precision         # => 0
 *    BigDecimal("1").precision         # => 1
 *    BigDecimal("1.1").precision       # => 2
 *    BigDecimal("3.1415").precision    # => 5
 *    BigDecimal("-1e20").precision     # => 21
 *    BigDecimal("1e-20").precision     # => 20
 *    BigDecimal("Infinity").precision  # => 0
 *    BigDecimal("-Infinity").precision # => 0
 *    BigDecimal("NaN").precision       # => 0
 *
 */
static VALUE
BigDecimal_precision(VALUE self)
{
    ssize_t precision;
    BigDecimal_count_precision_and_scale(self, &precision, NULL);
    return SSIZET2NUM(precision);
}

/*
 *  call-seq:
 *    scale -> integer
 *
 *  Returns the number of decimal digits following the decimal digits in +self+.
 *
 *    BigDecimal("0").scale         # => 0
 *    BigDecimal("1").scale         # => 0
 *    BigDecimal("1.1").scale       # => 1
 *    BigDecimal("3.1415").scale    # => 4
 *    BigDecimal("-1e20").precision # => 0
 *    BigDecimal("1e-20").precision # => 20
 *    BigDecimal("Infinity").scale  # => 0
 *    BigDecimal("-Infinity").scale # => 0
 *    BigDecimal("NaN").scale       # => 0
 */
static VALUE
BigDecimal_scale(VALUE self)
{
    ssize_t scale;
    BigDecimal_count_precision_and_scale(self, NULL, &scale);
    return SSIZET2NUM(scale);
}

/*
 *  call-seq:
 *    precision_scale -> [integer, integer]
 *
 *  Returns a 2-length array; the first item is the result of
 *  BigDecimal#precision and the second one is of BigDecimal#scale.
 *
 *  See BigDecimal#precision.
 *  See BigDecimal#scale.
 */
static VALUE
BigDecimal_precision_scale(VALUE self)
{
    ssize_t precision, scale;
    BigDecimal_count_precision_and_scale(self, &precision, &scale);
    return rb_assoc_new(SSIZET2NUM(precision), SSIZET2NUM(scale));
}

/*
 *  call-seq:
 *    n_significant_digits -> integer
 *
 *  Returns the number of decimal significant digits in +self+.
 *
 *    BigDecimal("0").n_significant_digits         # => 0
 *    BigDecimal("1").n_significant_digits         # => 1
 *    BigDecimal("1.1").n_significant_digits       # => 2
 *    BigDecimal("3.1415").n_significant_digits    # => 5
 *    BigDecimal("-1e20").n_significant_digits     # => 1
 *    BigDecimal("1e-20").n_significant_digits     # => 1
 *    BigDecimal("Infinity").n_significant_digits  # => 0
 *    BigDecimal("-Infinity").n_significant_digits # => 0
 *    BigDecimal("NaN").n_significant_digits       # => 0
 */
static VALUE
BigDecimal_n_significant_digits(VALUE self)
{
    ENTER(1);

    Real *p;
    GUARD_OBJ(p, GetVpValue(self, 1));
    if (VpIsZero(p) || !VpIsDef(p)) {
        return INT2FIX(0);
    }

    ssize_t n = p->Prec;  /* The length of frac without trailing zeros. */
    for (n = p->Prec; n > 0 && p->frac[n-1] == 0; --n);
    if (n == 0) return INT2FIX(0);

    DECDIG x;
    int nlz = BASE_FIG;
    for (x = p->frac[0]; x > 0; x /= 10) --nlz;

    int ntz = 0;
    for (x = p->frac[n-1]; x > 0 && x % 10 == 0; x /= 10) ++ntz;

    ssize_t n_significant_digits = BASE_FIG*n - nlz - ntz;
    return SSIZET2NUM(n_significant_digits);
}

/*
 *  call-seq:
 *    hash -> integer
 *
 *  Returns the integer hash value for +self+.
 *
 *  Two instances of \BigDecimal have the same hash value if and only if
 *  they have equal:
 *
 *  - Sign.
 *  - Fractional part.
 *  - Exponent.
 *
 */
static VALUE
BigDecimal_hash(VALUE self)
{
    ENTER(1);
    Real *p;
    st_index_t hash;

    GUARD_OBJ(p, GetVpValue(self, 1));
    hash = (st_index_t)p->sign;
    /* hash!=2: the case for 0(1),NaN(0) or +-Infinity(3) is sign itself */
    if(hash == 2 || hash == (st_index_t)-2) {
        hash ^= rb_memhash(p->frac, sizeof(DECDIG)*p->Prec);
        hash += p->exponent;
    }
    return ST2FIX(hash);
}

/*
 *  call-seq:
 *    _dump -> string
 *
 *  Returns a string representing the marshalling of +self+.
 *  See module Marshal.
 *
 *    inf = BigDecimal('Infinity') # => Infinity
 *    dumped = inf._dump           # => "9:Infinity"
 *    BigDecimal._load(dumped)     # => Infinity
 *
 */
static VALUE
BigDecimal_dump(int argc, VALUE *argv, VALUE self)
{
    ENTER(5);
    Real *vp;
    char *psz;
    VALUE dummy;
    volatile VALUE dump;
    size_t len;

    rb_scan_args(argc, argv, "01", &dummy);
    GUARD_OBJ(vp,GetVpValue(self, 1));
    dump = rb_str_new(0, VpNumOfChars(vp, "E")+50);
    psz = RSTRING_PTR(dump);
    snprintf(psz, RSTRING_LEN(dump), "%"PRIuSIZE":", VpMaxPrec(vp)*VpBaseFig());
    len = strlen(psz);
    VpToString(vp, psz+len, RSTRING_LEN(dump)-len, 0, 0);
    rb_str_resize(dump, strlen(psz));
    return dump;
}

/*
 * Internal method used to provide marshalling support. See the Marshal module.
 */
static VALUE
BigDecimal_load(VALUE self, VALUE str)
{
    ENTER(2);
    Real *pv;
    unsigned char *pch;
    unsigned char ch;
    unsigned long m=0;

    pch = (unsigned char *)StringValueCStr(str);
    /* First get max prec */
    while((*pch) != (unsigned char)'\0' && (ch = *pch++) != (unsigned char)':') {
        if(!ISDIGIT(ch)) {
            rb_raise(rb_eTypeError, "load failed: invalid character in the marshaled string");
        }
        m = m*10 + (unsigned long)(ch-'0');
    }
    if (m > VpBaseFig()) m -= VpBaseFig();
    GUARD_OBJ(pv, VpNewRbClass(m, (char *)pch, self, true, true));
    m /= VpBaseFig();
    if (m && pv->MaxPrec > m) {
	pv->MaxPrec = m+1;
    }
    return VpCheckGetValue(pv);
}

static unsigned short
check_rounding_mode_option(VALUE const opts)
{
    VALUE mode;
    char const *s;
    long l;

    assert(RB_TYPE_P(opts, T_HASH));

    if (NIL_P(opts))
        goto no_opt;

    mode = rb_hash_lookup2(opts, ID2SYM(id_half), Qundef);
    if (mode == Qundef || NIL_P(mode))
        goto no_opt;

    if (SYMBOL_P(mode))
        mode = rb_sym2str(mode);
    else if (!RB_TYPE_P(mode, T_STRING)) {
        VALUE str_mode = rb_check_string_type(mode);
        if (NIL_P(str_mode))
            goto invalid;
        mode = str_mode;
    }
    s = RSTRING_PTR(mode);
    l = RSTRING_LEN(mode);
    switch (l) {
      case 2:
        if (strncasecmp(s, "up", 2) == 0)
            return VP_ROUND_HALF_UP;
        break;
      case 4:
        if (strncasecmp(s, "even", 4) == 0)
            return VP_ROUND_HALF_EVEN;
        else if (strncasecmp(s, "down", 4) == 0)
            return VP_ROUND_HALF_DOWN;
        break;
      default:
        break;
    }

  invalid:
    rb_raise(rb_eArgError, "invalid rounding mode (%"PRIsVALUE")", mode);

  no_opt:
    return VpGetRoundMode();
}

static unsigned short
check_rounding_mode(VALUE const v)
{
    unsigned short sw;
    ID id;
    if (RB_TYPE_P(v, T_SYMBOL)) {
        int i;
        id = SYM2ID(v);
        for (i = 0; i < RBD_NUM_ROUNDING_MODES; ++i) {
            if (rbd_rounding_modes[i].id == id) {
                return rbd_rounding_modes[i].mode;
            }
        }
        rb_raise(rb_eArgError, "invalid rounding mode (%"PRIsVALUE")", v);
    }
    else {
        sw = NUM2USHORT(v);
        if (!VpIsRoundMode(sw)) {
            rb_raise(rb_eArgError, "invalid rounding mode (%"PRIsVALUE")", v);
        }
        return sw;
    }
}

/*  call-seq:
 *    BigDecimal.mode(mode, setting = nil) -> integer
 *
 *  Returns an integer representing the mode settings
 *  for exception handling and rounding.
 *
 *  These modes control exception handling:
 *
 *  - \BigDecimal::EXCEPTION_NaN.
 *  - \BigDecimal::EXCEPTION_INFINITY.
 *  - \BigDecimal::EXCEPTION_UNDERFLOW.
 *  - \BigDecimal::EXCEPTION_OVERFLOW.
 *  - \BigDecimal::EXCEPTION_ZERODIVIDE.
 *  - \BigDecimal::EXCEPTION_ALL.
 *
 *  Values for +setting+ for exception handling:
 *
 *  - +true+: sets the given +mode+ to +true+.
 *  - +false+: sets the given +mode+ to +false+.
 *  - +nil+: does not modify the mode settings.
 *
 *  You can use method BigDecimal.save_exception_mode
 *  to temporarily change, and then automatically restore, exception modes.
 *
 *  For clarity, some examples below begin by setting all
 *  exception modes to +false+.
 *
 *  This mode controls the way rounding is to be performed:
 *
 *  - \BigDecimal::ROUND_MODE
 *
 *  You can use method BigDecimal.save_rounding_mode
 *  to temporarily change, and then automatically restore, the rounding mode.
 *
 *  <b>NaNs</b>
 *
 *  Mode \BigDecimal::EXCEPTION_NaN controls behavior
 *  when a \BigDecimal NaN is created.
 *
 *  Settings:
 *
 *  - +false+ (default): Returns <tt>BigDecimal('NaN')</tt>.
 *  - +true+: Raises FloatDomainError.
 *
 *  Examples:
 *
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ALL, false) # => 0
 *    BigDecimal('NaN')                                 # => NaN
 *    BigDecimal.mode(BigDecimal::EXCEPTION_NaN, true)  # => 2
 *    BigDecimal('NaN') # Raises FloatDomainError
 *
 *  <b>Infinities</b>
 *
 *  Mode \BigDecimal::EXCEPTION_INFINITY controls behavior
 *  when a \BigDecimal Infinity or -Infinity is created.
 *  Settings:
 *
 *  - +false+ (default): Returns <tt>BigDecimal('Infinity')</tt>
 *    or <tt>BigDecimal('-Infinity')</tt>.
 *  - +true+: Raises FloatDomainError.
 *
 *  Examples:
 *
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ALL, false)     # => 0
 *    BigDecimal('Infinity')                                # => Infinity
 *    BigDecimal('-Infinity')                               # => -Infinity
 *    BigDecimal.mode(BigDecimal::EXCEPTION_INFINITY, true) # => 1
 *    BigDecimal('Infinity')  # Raises FloatDomainError
 *    BigDecimal('-Infinity') # Raises FloatDomainError
 *
 *  <b>Underflow</b>
 *
 *  Mode \BigDecimal::EXCEPTION_UNDERFLOW controls behavior
 *  when a \BigDecimal underflow occurs.
 *  Settings:
 *
 *  - +false+ (default): Returns <tt>BigDecimal('0')</tt>
 *    or <tt>BigDecimal('-Infinity')</tt>.
 *  - +true+: Raises FloatDomainError.
 *
 *  Examples:
 *
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ALL, false)      # => 0
 *    def flow_under
 *      x = BigDecimal('0.1')
 *      100.times { x *= x }
 *    end
 *    flow_under                                             # => 100
 *    BigDecimal.mode(BigDecimal::EXCEPTION_UNDERFLOW, true) # => 4
 *    flow_under # Raises FloatDomainError
 *
 *  <b>Overflow</b>
 *
 *  Mode \BigDecimal::EXCEPTION_OVERFLOW controls behavior
 *  when a \BigDecimal overflow occurs.
 *  Settings:
 *
 *  - +false+ (default): Returns <tt>BigDecimal('Infinity')</tt>
 *    or <tt>BigDecimal('-Infinity')</tt>.
 *  - +true+: Raises FloatDomainError.
 *
 *  Examples:
 *
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ALL, false)     # => 0
 *    def flow_over
 *      x = BigDecimal('10')
 *      100.times { x *= x }
 *    end
 *    flow_over                                             # => 100
 *    BigDecimal.mode(BigDecimal::EXCEPTION_OVERFLOW, true) # => 1
 *    flow_over # Raises FloatDomainError
 *
 *  <b>Zero Division</b>
 *
 *  Mode \BigDecimal::EXCEPTION_ZERODIVIDE controls behavior
 *  when a zero-division occurs.
 *  Settings:
 *
 *  - +false+ (default): Returns <tt>BigDecimal('Infinity')</tt>
 *    or <tt>BigDecimal('-Infinity')</tt>.
 *  - +true+: Raises FloatDomainError.
 *
 *  Examples:
 *
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ALL, false)       # => 0
 *    one = BigDecimal('1')
 *    zero = BigDecimal('0')
 *    one / zero                                              # => Infinity
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ZERODIVIDE, true) # => 16
 *    one / zero # Raises FloatDomainError
 *
 *  <b>All Exceptions</b>
 *
 *  Mode \BigDecimal::EXCEPTION_ALL controls all of the above:
 *
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ALL, false) # => 0
 *    BigDecimal.mode(BigDecimal::EXCEPTION_ALL, true)  # => 23
 *
 *  <b>Rounding</b>
 *
 *  Mode \BigDecimal::ROUND_MODE controls the way rounding is to be performed;
 *  its +setting+ values are:
 *
 *  - +ROUND_UP+: Round away from zero.
 *    Aliased as +:up+.
 *  - +ROUND_DOWN+: Round toward zero.
 *    Aliased as +:down+ and +:truncate+.
 *  - +ROUND_HALF_UP+: Round toward the nearest neighbor;
 *    if the neighbors are equidistant, round away from zero.
 *    Aliased as +:half_up+ and +:default+.
 *  - +ROUND_HALF_DOWN+: Round toward the nearest neighbor;
 *    if the neighbors are equidistant, round toward zero.
 *    Aliased as +:half_down+.
 *  - +ROUND_HALF_EVEN+ (Banker's rounding): Round toward the nearest neighbor;
 *    if the neighbors are equidistant, round toward the even neighbor.
 *    Aliased as +:half_even+ and +:banker+.
 *  - +ROUND_CEILING+: Round toward positive infinity.
 *    Aliased as +:ceiling+ and +:ceil+.
 *  - +ROUND_FLOOR+: Round toward negative infinity.
 *    Aliased as +:floor:+.
 *
 */
static VALUE
BigDecimal_mode(int argc, VALUE *argv, VALUE self)
{
    VALUE which;
    VALUE val;
    unsigned long f,fo;

    rb_scan_args(argc, argv, "11", &which, &val);
    f = (unsigned long)NUM2INT(which);

    if (f & VP_EXCEPTION_ALL) {
	/* Exception mode setting */
	fo = VpGetException();
	if (val == Qnil) return INT2FIX(fo);
	if (val != Qfalse && val!=Qtrue) {
	    rb_raise(rb_eArgError, "second argument must be true or false");
	    return Qnil; /* Not reached */
	}
	if (f & VP_EXCEPTION_INFINITY) {
	    VpSetException((unsigned short)((val == Qtrue) ? (fo | VP_EXCEPTION_INFINITY) :
			(fo & (~VP_EXCEPTION_INFINITY))));
	}
	fo = VpGetException();
	if (f & VP_EXCEPTION_NaN) {
	    VpSetException((unsigned short)((val == Qtrue) ? (fo | VP_EXCEPTION_NaN) :
			(fo & (~VP_EXCEPTION_NaN))));
	}
	fo = VpGetException();
	if (f & VP_EXCEPTION_UNDERFLOW) {
	    VpSetException((unsigned short)((val == Qtrue) ? (fo | VP_EXCEPTION_UNDERFLOW) :
			(fo & (~VP_EXCEPTION_UNDERFLOW))));
	}
	fo = VpGetException();
	if(f & VP_EXCEPTION_ZERODIVIDE) {
	    VpSetException((unsigned short)((val == Qtrue) ? (fo | VP_EXCEPTION_ZERODIVIDE) :
			(fo & (~VP_EXCEPTION_ZERODIVIDE))));
	}
	fo = VpGetException();
	return INT2FIX(fo);
    }
    if (VP_ROUND_MODE == f) {
	/* Rounding mode setting */
	unsigned short sw;
	fo = VpGetRoundMode();
	if (NIL_P(val)) return INT2FIX(fo);
	sw = check_rounding_mode(val);
	fo = VpSetRoundMode(sw);
	return INT2FIX(fo);
    }
    rb_raise(rb_eTypeError, "first argument for BigDecimal.mode invalid");
    return Qnil;
}

static size_t
GetAddSubPrec(Real *a, Real *b)
{
    size_t mxs;
    size_t mx = a->Prec;
    SIGNED_VALUE d;

    if (!VpIsDef(a) || !VpIsDef(b)) return (size_t)-1L;
    if (mx < b->Prec) mx = b->Prec;
    if (a->exponent != b->exponent) {
	mxs = mx;
	d = a->exponent - b->exponent;
	if (d < 0) d = -d;
	mx = mx + (size_t)d;
	if (mx < mxs) {
	    return VpException(VP_EXCEPTION_INFINITY, "Exponent overflow", 0);
	}
    }
    return mx;
}

static inline SIGNED_VALUE
check_int_precision(VALUE v)
{
    SIGNED_VALUE n;
#if SIZEOF_VALUE <= SIZEOF_LONG
    n = (SIGNED_VALUE)NUM2LONG(v);
#elif SIZEOF_VALUE <= SIZEOF_LONG_LONG
    n = (SIGNED_VALUE)NUM2LL(v);
#else
#   error SIZEOF_VALUE is too large
#endif
    if (n < 0) {
	rb_raise(rb_eArgError, "negative precision");
    }
    return n;
}

static VALUE
BigDecimal_wrap_struct(VALUE obj, Real *vp)
{
    assert(is_kind_of_BigDecimal(obj));
    assert(vp != NULL);

    if (vp->obj == obj && RTYPEDDATA_DATA(obj) == vp)
        return obj;

    assert(RTYPEDDATA_DATA(obj) == NULL);
    assert(vp->obj == 0);

    RTYPEDDATA_DATA(obj) = vp;
    vp->obj = obj;
    RB_OBJ_FREEZE(obj);
    return obj;
}

VP_EXPORT Real *
VpNewRbClass(size_t mx, const char *str, VALUE klass, bool strict_p, bool raise_exception)
{
    VALUE obj = TypedData_Wrap_Struct(klass, &BigDecimal_data_type, 0);
    Real *pv = VpAlloc(mx, str, strict_p, raise_exception);
    if (!pv)
        return NULL;
    BigDecimal_wrap_struct(obj, pv);
    return pv;
}

VP_EXPORT Real *
VpCreateRbObject(size_t mx, const char *str, bool raise_exception)
{
    return VpNewRbClass(mx, str, rb_cBigDecimal, true, raise_exception);
}

static Real *
VpCopy(Real *pv, Real const* const x)
{
    assert(x != NULL);

    pv = rbd_reallocate_struct(pv, x->MaxPrec);
    pv->MaxPrec = x->MaxPrec;
    pv->Prec = x->Prec;
    pv->exponent = x->exponent;
    pv->sign = x->sign;
    pv->flag = x->flag;
    MEMCPY(pv->frac, x->frac, DECDIG, pv->MaxPrec);

    return pv;
}

/* Returns True if the value is Not a Number. */
static VALUE
BigDecimal_IsNaN(VALUE self)
{
    Real *p = GetVpValue(self, 1);
    if (VpIsNaN(p))  return Qtrue;
    return Qfalse;
}

/* Returns nil, -1, or +1 depending on whether the value is finite,
 * -Infinity, or +Infinity.
 */
static VALUE
BigDecimal_IsInfinite(VALUE self)
{
    Real *p = GetVpValue(self, 1);
    if (VpIsPosInf(p)) return INT2FIX(1);
    if (VpIsNegInf(p)) return INT2FIX(-1);
    return Qnil;
}

/* Returns True if the value is finite (not NaN or infinite). */
static VALUE
BigDecimal_IsFinite(VALUE self)
{
    Real *p = GetVpValue(self, 1);
    if (VpIsNaN(p)) return Qfalse;
    if (VpIsInf(p)) return Qfalse;
    return Qtrue;
}

static void
BigDecimal_check_num(Real *p)
{
    VpCheckException(p, true);
}

static VALUE BigDecimal_split(VALUE self);

/* Returns the value as an Integer.
 *
 * If the BigDecimal is infinity or NaN, raises FloatDomainError.
 */
static VALUE
BigDecimal_to_i(VALUE self)
{
    ENTER(5);
    ssize_t e, nf;
    Real *p;

    GUARD_OBJ(p, GetVpValue(self, 1));
    BigDecimal_check_num(p);

    e = VpExponent10(p);
    if (e <= 0) return INT2FIX(0);
    nf = VpBaseFig();
    if (e <= nf) {
        return LONG2NUM((long)(VpGetSign(p) * (DECDIG_DBL_SIGNED)p->frac[0]));
    }
    else {
	VALUE a = BigDecimal_split(self);
	VALUE digits = RARRAY_AREF(a, 1);
	VALUE numerator = rb_funcall(digits, rb_intern("to_i"), 0);
	VALUE ret;
	ssize_t dpower = e - (ssize_t)RSTRING_LEN(digits);

	if (BIGDECIMAL_NEGATIVE_P(p)) {
	    numerator = rb_funcall(numerator, '*', 1, INT2FIX(-1));
	}
	if (dpower < 0) {
	    ret = rb_funcall(numerator, rb_intern("div"), 1,
			      rb_funcall(INT2FIX(10), rb_intern("**"), 1,
					 INT2FIX(-dpower)));
	}
	else {
	    ret = rb_funcall(numerator, '*', 1,
			     rb_funcall(INT2FIX(10), rb_intern("**"), 1,
					INT2FIX(dpower)));
	}
	if (RB_TYPE_P(ret, T_FLOAT)) {
	    rb_raise(rb_eFloatDomainError, "Infinity");
	}
	return ret;
    }
}

/* Returns a new Float object having approximately the same value as the
 * BigDecimal number. Normal accuracy limits and built-in errors of binary
 * Float arithmetic apply.
 */
static VALUE
BigDecimal_to_f(VALUE self)
{
    ENTER(1);
    Real *p;
    double d;
    SIGNED_VALUE e;
    char *buf;
    volatile VALUE str;

    GUARD_OBJ(p, GetVpValue(self, 1));
    if (VpVtoD(&d, &e, p) != 1)
	return rb_float_new(d);
    if (e > (SIGNED_VALUE)(DBL_MAX_10_EXP+BASE_FIG))
	goto overflow;
    if (e < (SIGNED_VALUE)(DBL_MIN_10_EXP-BASE_FIG))
	goto underflow;

    str = rb_str_new(0, VpNumOfChars(p, "E"));
    buf = RSTRING_PTR(str);
    VpToString(p, buf, RSTRING_LEN(str), 0, 0);
    errno = 0;
    d = strtod(buf, 0);
    if (errno == ERANGE) {
	if (d == 0.0) goto underflow;
	if (fabs(d) >= HUGE_VAL) goto overflow;
    }
    return rb_float_new(d);

overflow:
    VpException(VP_EXCEPTION_OVERFLOW, "BigDecimal to Float conversion", 0);
    if (BIGDECIMAL_NEGATIVE_P(p))
	return rb_float_new(VpGetDoubleNegInf());
    else
	return rb_float_new(VpGetDoublePosInf());

underflow:
    VpException(VP_EXCEPTION_UNDERFLOW, "BigDecimal to Float conversion", 0);
    if (BIGDECIMAL_NEGATIVE_P(p))
	return rb_float_new(-0.0);
    else
	return rb_float_new(0.0);
}


/* Converts a BigDecimal to a Rational.
 */
static VALUE
BigDecimal_to_r(VALUE self)
{
    Real *p;
    ssize_t sign, power, denomi_power;
    VALUE a, digits, numerator;

    p = GetVpValue(self, 1);
    BigDecimal_check_num(p);

    sign = VpGetSign(p);
    power = VpExponent10(p);
    a = BigDecimal_split(self);
    digits = RARRAY_AREF(a, 1);
    denomi_power = power - RSTRING_LEN(digits);
    numerator = rb_funcall(digits, rb_intern("to_i"), 0);

    if (sign < 0) {
	numerator = rb_funcall(numerator, '*', 1, INT2FIX(-1));
    }
    if (denomi_power < 0) {
	return rb_Rational(numerator,
			   rb_funcall(INT2FIX(10), rb_intern("**"), 1,
				      INT2FIX(-denomi_power)));
    }
    else {
	return rb_Rational1(rb_funcall(numerator, '*', 1,
				       rb_funcall(INT2FIX(10), rb_intern("**"), 1,
						  INT2FIX(denomi_power))));
    }
}

/* The coerce method provides support for Ruby type coercion. It is not
 * enabled by default.
 *
 * This means that binary operations like + * / or - can often be performed
 * on a BigDecimal and an object of another type, if the other object can
 * be coerced into a BigDecimal value.
 *
 * e.g.
 *   a = BigDecimal("1.0")
 *   b = a / 2.0 #=> 0.5
 *
 * Note that coercing a String to a BigDecimal is not supported by default;
 * it requires a special compile-time option when building Ruby.
 */
static VALUE
BigDecimal_coerce(VALUE self, VALUE other)
{
    ENTER(2);
    VALUE obj;
    Real *b;

    if (RB_TYPE_P(other, T_FLOAT)) {
	GUARD_OBJ(b, GetVpValueWithPrec(other, 0, 1));
        obj = rb_assoc_new(VpCheckGetValue(b), self);
    }
    else {
	if (RB_TYPE_P(other, T_RATIONAL)) {
	    Real* pv = DATA_PTR(self);
	    GUARD_OBJ(b, GetVpValueWithPrec(other, pv->Prec*VpBaseFig(), 1));
	}
	else {
	    GUARD_OBJ(b, GetVpValue(other, 1));
	}
	obj = rb_assoc_new(b->obj, self);
    }

    return obj;
}

/*
 *  call-seq:
 *    +big_decimal -> self
 *
 *  Returns +self+:
 *
 *     +BigDecimal(5)  # => 0.5e1
 *     +BigDecimal(-5) # => -0.5e1
 *
 */

static VALUE
BigDecimal_uplus(VALUE self)
{
    return self;
}

 /*
  *  call-seq:
  *    self + value -> bigdecimal
  *
  *  Returns the \BigDecimal sum of +self+ and +value+:
  *
  *    b = BigDecimal('111111.111') # => 0.111111111e6
  *    b + 2                        # => 0.111113111e6
  *    b + 2.0                      # => 0.111113111e6
  *    b + Rational(2, 1)           # => 0.111113111e6
  *    b + Complex(2, 0)            # => (0.111113111e6+0i)
  *
  *  See the {Note About Precision}[BigDecimal.html#class-BigDecimal-label-A+Note+About+Precision].
  *
  */

static VALUE
BigDecimal_add(VALUE self, VALUE r)
{
    ENTER(5);
    Real *c, *a, *b;
    size_t mx;

    GUARD_OBJ(a, GetVpValue(self, 1));
    if (RB_TYPE_P(r, T_FLOAT)) {
	b = GetVpValueWithPrec(r, 0, 1);
    }
    else if (RB_TYPE_P(r, T_RATIONAL)) {
	b = GetVpValueWithPrec(r, a->Prec*VpBaseFig(), 1);
    }
    else {
	b = GetVpValue(r, 0);
    }

    if (!b) return DoSomeOne(self,r,'+');
    SAVE(b);

    if (VpIsNaN(b)) return b->obj;
    if (VpIsNaN(a)) return a->obj;

    mx = GetAddSubPrec(a, b);
    if (mx == (size_t)-1L) {
        GUARD_OBJ(c, NewZeroWrapLimited(1, VpBaseFig() + 1));
        VpAddSub(c, a, b, 1);
    }
    else {
        GUARD_OBJ(c, NewZeroWrapLimited(1, mx * (VpBaseFig() + 1)));
        if (!mx) {
            VpSetInf(c, VpGetSign(a));
        }
        else {
            VpAddSub(c, a, b, 1);
        }
    }
    return VpCheckGetValue(c);
}

 /*
  *  call-seq:
  *    self - value -> bigdecimal
  *
  *  Returns the \BigDecimal difference of +self+ and +value+:
  *
  *    b = BigDecimal('333333.333') # => 0.333333333e6
  *    b - 2                        # => 0.333331333e6
  *    b - 2.0                      # => 0.333331333e6
  *    b - Rational(2, 1)           # => 0.333331333e6
  *    b - Complex(2, 0)            # => (0.333331333e6+0i)
  *
  *  See the {Note About Precision}[BigDecimal.html#class-BigDecimal-label-A+Note+About+Precision].
  *
  */
static VALUE
BigDecimal_sub(VALUE self, VALUE r)
{
    ENTER(5);
    Real *c, *a, *b;
    size_t mx;

    GUARD_OBJ(a, GetVpValue(self,1));
    if (RB_TYPE_P(r, T_FLOAT)) {
	b = GetVpValueWithPrec(r, 0, 1);
    }
    else if (RB_TYPE_P(r, T_RATIONAL)) {
	b = GetVpValueWithPrec(r, a->Prec*VpBaseFig(), 1);
    }
    else {
	b = GetVpValue(r,0);
    }

    if (!b) return DoSomeOne(self,r,'-');
    SAVE(b);

    if (VpIsNaN(b)) return b->obj;
    if (VpIsNaN(a)) return a->obj;

    mx = GetAddSubPrec(a,b);
    if (mx == (size_t)-1L) {
        GUARD_OBJ(c, NewZeroWrapLimited(1, VpBaseFig() + 1));
        VpAddSub(c, a, b, -1);
    }
    else {
        GUARD_OBJ(c, NewZeroWrapLimited(1, mx *(VpBaseFig() + 1)));
        if (!mx) {
            VpSetInf(c,VpGetSign(a));
        }
        else {
            VpAddSub(c, a, b, -1);
        }
    }
    return VpCheckGetValue(c);
}

static VALUE
BigDecimalCmp(VALUE self, VALUE r,char op)
{
    ENTER(5);
    SIGNED_VALUE e;
    Real *a, *b=0;
    GUARD_OBJ(a, GetVpValue(self, 1));
    switch (TYPE(r)) {
    case T_DATA:
	if (!is_kind_of_BigDecimal(r)) break;
	/* fall through */
    case T_FIXNUM:
	/* fall through */
    case T_BIGNUM:
	GUARD_OBJ(b, GetVpValue(r, 0));
	break;

    case T_FLOAT:
	GUARD_OBJ(b, GetVpValueWithPrec(r, 0, 0));
	break;

    case T_RATIONAL:
	GUARD_OBJ(b, GetVpValueWithPrec(r, a->Prec*VpBaseFig(), 0));
	break;

    default:
	break;
    }
    if (b == NULL) {
	ID f = 0;

	switch (op) {
	case '*':
	    return rb_num_coerce_cmp(self, r, rb_intern("<=>"));

	case '=':
	    return RTEST(rb_num_coerce_cmp(self, r, rb_intern("=="))) ? Qtrue : Qfalse;

	case 'G':
	    f = rb_intern(">=");
	    break;

	case 'L':
	    f = rb_intern("<=");
	    break;

	case '>':
	    /* fall through */
	case '<':
	    f = (ID)op;
	    break;

	default:
	    break;
	}
	return rb_num_coerce_relop(self, r, f);
    }
    SAVE(b);
    e = VpComp(a, b);
    if (e == 999)
	return (op == '*') ? Qnil : Qfalse;
    switch (op) {
    case '*':
	return   INT2FIX(e); /* any op */

    case '=':
	if (e == 0) return Qtrue;
	return Qfalse;

    case 'G':
	if (e >= 0) return Qtrue;
	return Qfalse;

    case '>':
	if (e >  0) return Qtrue;
	return Qfalse;

    case 'L':
	if (e <= 0) return Qtrue;
	return Qfalse;

    case '<':
	if (e <  0) return Qtrue;
	return Qfalse;

    default:
	break;
    }

    rb_bug("Undefined operation in BigDecimalCmp()");

    UNREACHABLE;
}

/* Returns True if the value is zero. */
static VALUE
BigDecimal_zero(VALUE self)
{
    Real *a = GetVpValue(self, 1);
    return VpIsZero(a) ? Qtrue : Qfalse;
}

/* Returns self if the value is non-zero, nil otherwise. */
static VALUE
BigDecimal_nonzero(VALUE self)
{
    Real *a = GetVpValue(self, 1);
    return VpIsZero(a) ? Qnil : self;
}

/* The comparison operator.
 * a <=> b is 0 if a == b, 1 if a > b, -1 if a < b.
 */
static VALUE
BigDecimal_comp(VALUE self, VALUE r)
{
    return BigDecimalCmp(self, r, '*');
}

/*
 * Tests for value equality; returns true if the values are equal.
 *
 * The == and === operators and the eql? method have the same implementation
 * for BigDecimal.
 *
 * Values may be coerced to perform the comparison:
 *
 *   BigDecimal('1.0') == 1.0  #=> true
 */
static VALUE
BigDecimal_eq(VALUE self, VALUE r)
{
    return BigDecimalCmp(self, r, '=');
}

/*  call-seq:
 *    self < other -> true or false
 *
 *  Returns +true+ if +self+ is less than +other+, +false+ otherwise:
 *
 *    b = BigDecimal('1.5') # => 0.15e1
 *    b < 2                 # => true
 *    b < 2.0               # => true
 *    b < Rational(2, 1)    # => true
 *    b < 1.5               # => false
 *
 *  Raises an exception if the comparison cannot be made.
 *
 */
static VALUE
BigDecimal_lt(VALUE self, VALUE r)
{
    return BigDecimalCmp(self, r, '<');
}

/*  call-seq:
 *    self <= other -> true or false
 *
 *  Returns +true+ if +self+ is less or equal to than +other+, +false+ otherwise:
 *
 *    b = BigDecimal('1.5') # => 0.15e1
 *    b <= 2                # => true
 *    b <= 2.0              # => true
 *    b <= Rational(2, 1)   # => true
 *    b <= 1.5              # => true
 *    b < 1                 # => false
 *
 *  Raises an exception if the comparison cannot be made.
 *
 */
static VALUE
BigDecimal_le(VALUE self, VALUE r)
{
    return BigDecimalCmp(self, r, 'L');
}

/*  call-seq:
 *    self > other -> true or false
 *
 *  Returns +true+ if +self+ is greater than +other+, +false+ otherwise:
 *
 *    b = BigDecimal('1.5')
 *    b > 1              # => true
 *    b > 1.0            # => true
 *    b > Rational(1, 1) # => true
 *    b > 2              # => false
 *
 *  Raises an exception if the comparison cannot be made.
 *
 */
static VALUE
BigDecimal_gt(VALUE self, VALUE r)
{
    return BigDecimalCmp(self, r, '>');
}

/*  call-seq:
 *    self >= other -> true or false
 *
 *  Returns +true+ if +self+ is greater than or equal to +other+, +false+ otherwise:
 *
 *    b = BigDecimal('1.5')
 *    b >= 1              # => true
 *    b >= 1.0            # => true
 *    b >= Rational(1, 1) # => true
 *    b >= 1.5            # => true
 *    b > 2               # => false
 *
 *  Raises an exception if the comparison cannot be made.
 *
 */
static VALUE
BigDecimal_ge(VALUE self, VALUE r)
{
    return BigDecimalCmp(self, r, 'G');
}

/*
 *  call-seq:
 *    -self -> bigdecimal
 *
 *  Returns the \BigDecimal negation of self:
 *
 *    b0 = BigDecimal('1.5')
 *    b1 = -b0 # => -0.15e1
 *    b2 = -b1 # => 0.15e1
 *
 */

static VALUE
BigDecimal_neg(VALUE self)
{
    ENTER(5);
    Real *c, *a;
    GUARD_OBJ(a, GetVpValue(self, 1));
    GUARD_OBJ(c, NewZeroWrapLimited(1, a->Prec *(VpBaseFig() + 1)));
    VpAsgn(c, a, -1);
    return VpCheckGetValue(c);
}

/*
 * call-seq:
 *   a * b   -> bigdecimal
 *
 * Multiply by the specified value.
 *
 * The result precision will be the precision of the sum of each precision.
 *
 * See BigDecimal#mult.
 */

static VALUE
BigDecimal_mult(VALUE self, VALUE r)
{
    ENTER(5);
    Real *c, *a, *b;
    size_t mx;

    GUARD_OBJ(a, GetVpValue(self, 1));
    if (RB_TYPE_P(r, T_FLOAT)) {
        b = GetVpValueWithPrec(r, 0, 1);
    }
    else if (RB_TYPE_P(r, T_RATIONAL)) {
	b = GetVpValueWithPrec(r, a->Prec*VpBaseFig(), 1);
    }
    else {
	b = GetVpValue(r,0);
    }

    if (!b) return DoSomeOne(self, r, '*');
    SAVE(b);

    mx = a->Prec + b->Prec;
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx * (VpBaseFig() + 1)));
    VpMult(c, a, b);
    return VpCheckGetValue(c);
}

static VALUE BigDecimal_DoDivmod(VALUE self, VALUE r, Real **div, Real **mod);

/* call-seq:
 *   a / b   -> bigdecimal
 *
 * Divide by the specified value.
 *
 * The result precision will be the precision of the larger operand,
 * but its minimum is 2*Float::DIG.
 *
 * See BigDecimal#div.
 * See BigDecimal#quo.
 */
static VALUE
BigDecimal_div(VALUE self, VALUE r)
/* For c = self/r: with round operation */
{
    if (
        !is_kind_of_BigDecimal(r) &&
        !RB_INTEGER_TYPE_P(r) &&
        !RB_TYPE_P(r, T_FLOAT) &&
        !RB_TYPE_P(r, T_RATIONAL)
    ) {
        return DoSomeOne(self, r, '/');
    }
    return BigDecimal_div2(self, r, INT2FIX(0));
}

static VALUE BigDecimal_round(int argc, VALUE *argv, VALUE self);

/* call-seq:
 *   quo(value)  -> bigdecimal
 *   quo(value, digits)  -> bigdecimal
 *
 * Divide by the specified value.
 *
 * digits:: If specified and less than the number of significant digits of
 *          the result, the result is rounded to the given number of digits,
 *          according to the rounding mode indicated by BigDecimal.mode.
 *
 *          If digits is 0 or omitted, the result is the same as for the
 *          / operator.
 *
 * See BigDecimal#/.
 * See BigDecimal#div.
 */
static VALUE
BigDecimal_quo(int argc, VALUE *argv, VALUE self)
{
    VALUE value, digits, result;
    SIGNED_VALUE n = -1;

    argc = rb_scan_args(argc, argv, "11", &value, &digits);
    if (argc > 1) {
        n = check_int_precision(digits);
    }

    if (n > 0) {
        result = BigDecimal_div2(self, value, digits);
    }
    else {
        result = BigDecimal_div(self, value);
    }

    return result;
}

/*
 * %: mod = a%b = a - (a.to_f/b).floor * b
 * div = (a.to_f/b).floor
 */
static VALUE
BigDecimal_DoDivmod(VALUE self, VALUE r, Real **div, Real **mod)
{
    ENTER(8);
    Real *c=NULL, *d=NULL, *res=NULL;
    Real *a, *b;
    ssize_t a_prec, b_prec;
    size_t mx;

    TypedData_Get_Struct(self, Real, &BigDecimal_data_type, a);
    SAVE(a);

    VALUE rr = r;
    if (is_kind_of_BigDecimal(rr)) {
        /* do nothing */
    }
    else if (RB_INTEGER_TYPE_P(r)) {
        rr = rb_inum_convert_to_BigDecimal(r, 0, true);
    }
    else if (RB_TYPE_P(r, T_FLOAT)) {
        rr = rb_float_convert_to_BigDecimal(r, 0, true);
    }
    else if (RB_TYPE_P(r, T_RATIONAL)) {
        rr = rb_rational_convert_to_BigDecimal(r, a->Prec*BASE_FIG, true);
    }

    if (!is_kind_of_BigDecimal(rr)) {
        return Qfalse;
    }

    TypedData_Get_Struct(rr, Real, &BigDecimal_data_type, b);
    SAVE(b);

    if (VpIsNaN(a) || VpIsNaN(b)) goto NaN;
    if (VpIsInf(a) && VpIsInf(b)) goto NaN;
    if (VpIsZero(b)) {
        rb_raise(rb_eZeroDivError, "divided by 0");
    }
    if (VpIsInf(a)) {
        if (VpGetSign(a) == VpGetSign(b)) {
            VALUE inf = BigDecimal_positive_infinity();
            TypedData_Get_Struct(inf, Real, &BigDecimal_data_type, *div);
        }
        else {
            VALUE inf = BigDecimal_negative_infinity();
            TypedData_Get_Struct(inf, Real, &BigDecimal_data_type, *div);
        }
        VALUE nan = BigDecimal_nan();
        TypedData_Get_Struct(nan, Real, &BigDecimal_data_type, *mod);
        return Qtrue;
    }
    if (VpIsInf(b)) {
        VALUE zero = BigDecimal_positive_zero();
        TypedData_Get_Struct(zero, Real, &BigDecimal_data_type, *div);
        *mod = a;
        return Qtrue;
    }
    if (VpIsZero(a)) {
        VALUE zero = BigDecimal_positive_zero();
        TypedData_Get_Struct(zero, Real, &BigDecimal_data_type, *div);
        TypedData_Get_Struct(zero, Real, &BigDecimal_data_type, *mod);
        return Qtrue;
    }

    BigDecimal_count_precision_and_scale(self, &a_prec, NULL);
    BigDecimal_count_precision_and_scale(rr, &b_prec, NULL);

    mx = (a_prec > b_prec) ? a_prec : b_prec;
    mx *= 2;

    if (2*BIGDECIMAL_DOUBLE_FIGURES > mx)
        mx = 2*BIGDECIMAL_DOUBLE_FIGURES;

    GUARD_OBJ(c, NewZeroWrapLimited(1, mx + 2*BASE_FIG));
    GUARD_OBJ(res, NewZeroWrapNolimit(1, mx*2 + 2*BASE_FIG));
    VpDivd(c, res, a, b);

    mx = c->Prec * BASE_FIG;
    GUARD_OBJ(d, NewZeroWrapLimited(1, mx));
    VpActiveRound(d, c, VP_ROUND_DOWN, 0);

    VpMult(res, d, b);
    VpAddSub(c, a, res, -1);

    if (!VpIsZero(c) && (VpGetSign(a) * VpGetSign(b) < 0)) {
        /* result adjustment for negative case */
        res = rbd_reallocate_struct(res, d->MaxPrec);
        res->MaxPrec = d->MaxPrec;
        VpAddSub(res, d, VpOne(), -1);
        GUARD_OBJ(d, NewZeroWrapLimited(1, GetAddSubPrec(c, b) * 2*BASE_FIG));
        VpAddSub(d, c, b, 1);
        *div = res;
        *mod = d;
    }
    else {
        *div = d;
        *mod = c;
    }
    return Qtrue;

  NaN:
    {
        VALUE nan = BigDecimal_nan();
        TypedData_Get_Struct(nan, Real, &BigDecimal_data_type, *div);
        TypedData_Get_Struct(nan, Real, &BigDecimal_data_type, *mod);
    }
    return Qtrue;
}

/* call-seq:
 *   a % b
 *   a.modulo(b)
 *
 * Returns the modulus from dividing by b.
 *
 * See BigDecimal#divmod.
 */
static VALUE
BigDecimal_mod(VALUE self, VALUE r) /* %: a%b = a - (a.to_f/b).floor * b */
{
    ENTER(3);
    Real *div = NULL, *mod = NULL;

    if (BigDecimal_DoDivmod(self, r, &div, &mod)) {
	SAVE(div); SAVE(mod);
        return VpCheckGetValue(mod);
    }
    return DoSomeOne(self, r, '%');
}

static VALUE
BigDecimal_divremain(VALUE self, VALUE r, Real **dv, Real **rv)
{
    ENTER(10);
    size_t mx;
    Real *a = NULL, *b = NULL, *c = NULL, *res = NULL, *d = NULL, *rr = NULL, *ff = NULL;
    Real *f = NULL;

    GUARD_OBJ(a, GetVpValue(self, 1));
    if (RB_TYPE_P(r, T_FLOAT)) {
	b = GetVpValueWithPrec(r, 0, 1);
    }
    else if (RB_TYPE_P(r, T_RATIONAL)) {
	b = GetVpValueWithPrec(r, a->Prec*VpBaseFig(), 1);
    }
    else {
	b = GetVpValue(r, 0);
    }

    if (!b) return DoSomeOne(self, r, rb_intern("remainder"));
    SAVE(b);

    if (VpIsPosInf(b) || VpIsNegInf(b)) {
       GUARD_OBJ(*dv, NewZeroWrapLimited(1, 1));
       VpSetZero(*dv, 1);
       *rv = a;
       return Qnil;
    }

    mx = (a->MaxPrec + b->MaxPrec) *VpBaseFig();
    GUARD_OBJ(c,   NewZeroWrapLimited(1, mx));
    GUARD_OBJ(res, NewZeroWrapNolimit(1, (mx+1) * 2 + (VpBaseFig() + 1)));
    GUARD_OBJ(rr,  NewZeroWrapNolimit(1, (mx+1) * 2 + (VpBaseFig() + 1)));
    GUARD_OBJ(ff,  NewZeroWrapNolimit(1, (mx+1) * 2 + (VpBaseFig() + 1)));

    VpDivd(c, res, a, b);

    mx = c->Prec *(VpBaseFig() + 1);

    GUARD_OBJ(d, NewZeroWrapLimited(1, mx));
    GUARD_OBJ(f, NewZeroWrapLimited(1, mx));

    VpActiveRound(d, c, VP_ROUND_DOWN, 0); /* 0: round off */

    VpFrac(f, c);
    VpMult(rr, f, b);
    VpAddSub(ff, res, rr, 1);

    *dv = d;
    *rv = ff;
    return Qnil;
}

/* call-seq:
 *   remainder(value)
 *
 * Returns the remainder from dividing by the value.
 *
 * x.remainder(y) means x-y*(x/y).truncate
 */
static VALUE
BigDecimal_remainder(VALUE self, VALUE r) /* remainder */
{
    VALUE  f;
    Real  *d, *rv = 0;
    f = BigDecimal_divremain(self, r, &d, &rv);
    if (!NIL_P(f)) return f;
    return VpCheckGetValue(rv);
}

/* call-seq:
 *   divmod(value)
 *
 * Divides by the specified value, and returns the quotient and modulus
 * as BigDecimal numbers. The quotient is rounded towards negative infinity.
 *
 * For example:
 *
 *   require 'bigdecimal'
 *
 *   a = BigDecimal("42")
 *   b = BigDecimal("9")
 *
 *   q, m = a.divmod(b)
 *
 *   c = q * b + m
 *
 *   a == c  #=> true
 *
 * The quotient q is (a/b).floor, and the modulus is the amount that must be
 * added to q * b to get a.
 */
static VALUE
BigDecimal_divmod(VALUE self, VALUE r)
{
    ENTER(5);
    Real *div = NULL, *mod = NULL;

    if (BigDecimal_DoDivmod(self, r, &div, &mod)) {
	SAVE(div); SAVE(mod);
        return rb_assoc_new(VpCheckGetValue(div), VpCheckGetValue(mod));
    }
    return DoSomeOne(self,r,rb_intern("divmod"));
}

/*
 * Do the same manner as Float#div when n is nil.
 * Do the same manner as BigDecimal#quo when n is 0.
 */
static inline VALUE
BigDecimal_div2(VALUE self, VALUE b, VALUE n)
{
    ENTER(5);
    SIGNED_VALUE ix;
    Real *res = NULL;
    Real *av = NULL, *bv = NULL, *cv = NULL;
    size_t mx, pl;

    if (NIL_P(n)) { /* div in Float sense */
        Real *div = NULL;
        Real *mod;
        if (BigDecimal_DoDivmod(self, b, &div, &mod)) {
            return BigDecimal_to_i(VpCheckGetValue(div));
        }
        return DoSomeOne(self, b, rb_intern("div"));
    }

    /* div in BigDecimal sense */
    ix = check_int_precision(n);

    pl = VpSetPrecLimit(0);
    if (ix == 0) ix = pl;

    GUARD_OBJ(av, GetVpValue(self, 1));
    if (RB_FLOAT_TYPE_P(b) && ix > BIGDECIMAL_DOUBLE_FIGURES) {
        /* TODO: I want to refactor this precision control for a float value later
         *       by introducing an implicit conversion function instead of
         *       GetVpValueWithPrec.  */
        GUARD_OBJ(bv, GetVpValueWithPrec(b, BIGDECIMAL_DOUBLE_FIGURES, 1));
    }
    else {
        GUARD_OBJ(bv, GetVpValueWithPrec(b, ix, 1));
    }

    if (ix == 0) {
        ssize_t a_prec, b_prec;
        VpCountPrecisionAndScale(av, &a_prec, NULL);
        VpCountPrecisionAndScale(bv, &b_prec, NULL);
        ix = ((a_prec > b_prec) ? a_prec : b_prec) + BIGDECIMAL_DOUBLE_FIGURES;
        if (2 * BIGDECIMAL_DOUBLE_FIGURES > ix)
            ix = 2 * BIGDECIMAL_DOUBLE_FIGURES;
    }

    // VpDivd needs 2 extra DECDIGs. One more is needed for rounding.
    GUARD_OBJ(cv, NewZeroWrapLimited(1, ix + 3 * VpBaseFig()));

    mx = bv->Prec + cv->MaxPrec - 1;
    if (mx <= av->Prec) mx = av->Prec + 1;
    GUARD_OBJ(res, NewZeroWrapNolimit(1, mx * VpBaseFig()));
    VpDivd(cv, res, av, bv);
    VpSetPrecLimit(pl);
    if (!VpIsZero(res)) {
        // Remainder value affects rounding result.
        // ROUND_UP cv = 0.1e0 with ix=10 will be:
        // 0.1e0 if remainder == 0
        // 0.1000000001e0 if remainder != 0
        size_t idx = roomof(ix, BASE_FIG);
        while (cv->Prec <= idx) cv->frac[cv->Prec++] = 0;
        if (cv->frac[idx] == 0 || cv->frac[idx] == HALF_BASE) cv->frac[idx]++;
    }
    VpLeftRound(cv, VpGetRoundMode(), ix);
    return VpCheckGetValue(cv);
}

 /*
  * Document-method: BigDecimal#div
  *
  * call-seq:
  *   div(value)  -> integer
  *   div(value, digits)  -> bigdecimal or integer
  *
  * Divide by the specified value.
  *
  * digits:: If specified and less than the number of significant digits of the
  *          result, the result is rounded to that number of digits, according
  *          to BigDecimal.mode.
  *
  *          If digits is 0, the result is the same as for the / operator
  *          or #quo.
  *
  *          If digits is not specified, the result is an integer,
  *          by analogy with Float#div; see also BigDecimal#divmod.
  *
  * See BigDecimal#/.
  * See BigDecimal#quo.
  *
  * Examples:
  *
  *   a = BigDecimal("4")
  *   b = BigDecimal("3")
  *
  *   a.div(b, 3)  # => 0.133e1
  *
  *   a.div(b, 0)  # => 0.1333333333333333333e1
  *   a / b        # => 0.1333333333333333333e1
  *   a.quo(b)     # => 0.1333333333333333333e1
  *
  *   a.div(b)     # => 1
  */
static VALUE
BigDecimal_div3(int argc, VALUE *argv, VALUE self)
{
    VALUE b,n;

    rb_scan_args(argc, argv, "11", &b, &n);

    return BigDecimal_div2(self, b, n);
}

 /*
  *  call-seq:
  *    add(value, ndigits) -> new_bigdecimal
  *
  *  Returns the \BigDecimal sum of +self+ and +value+
  *  with a precision of +ndigits+ decimal digits.
  *
  *  When +ndigits+ is less than the number of significant digits
  *  in the sum, the sum is rounded to that number of digits,
  *  according to the current rounding mode; see BigDecimal.mode.
  *
  *  Examples:
  *
  *    # Set the rounding mode.
  *    BigDecimal.mode(BigDecimal::ROUND_MODE, :half_up)
  *    b = BigDecimal('111111.111')
  *    b.add(1, 0)               # => 0.111112111e6
  *    b.add(1, 3)               # => 0.111e6
  *    b.add(1, 6)               # => 0.111112e6
  *    b.add(1, 15)              # => 0.111112111e6
  *    b.add(1.0, 15)            # => 0.111112111e6
  *    b.add(Rational(1, 1), 15) # => 0.111112111e6
  *
  */

static VALUE
BigDecimal_add2(VALUE self, VALUE b, VALUE n)
{
    ENTER(2);
    Real *cv;
    SIGNED_VALUE mx = check_int_precision(n);
    if (mx == 0) return BigDecimal_add(self, b);
    else {
	size_t pl = VpSetPrecLimit(0);
	VALUE   c = BigDecimal_add(self, b);
	VpSetPrecLimit(pl);
	GUARD_OBJ(cv, GetVpValue(c, 1));
	VpLeftRound(cv, VpGetRoundMode(), mx);
        return VpCheckGetValue(cv);
    }
}

/* call-seq:
 *   sub(value, digits)  -> bigdecimal
 *
 * Subtract the specified value.
 *
 * e.g.
 *   c = a.sub(b,n)
 *
 * digits:: If specified and less than the number of significant digits of the
 *          result, the result is rounded to that number of digits, according
 *          to BigDecimal.mode.
 *
 */
static VALUE
BigDecimal_sub2(VALUE self, VALUE b, VALUE n)
{
    ENTER(2);
    Real *cv;
    SIGNED_VALUE mx = check_int_precision(n);
    if (mx == 0) return BigDecimal_sub(self, b);
    else {
	size_t pl = VpSetPrecLimit(0);
	VALUE   c = BigDecimal_sub(self, b);
	VpSetPrecLimit(pl);
	GUARD_OBJ(cv, GetVpValue(c, 1));
	VpLeftRound(cv, VpGetRoundMode(), mx);
        return VpCheckGetValue(cv);
    }
}

 /*
  *  call-seq:
  *    mult(other, ndigits) -> bigdecimal
  *
  *  Returns the \BigDecimal product of +self+ and +value+
  *  with a precision of +ndigits+ decimal digits.
  *
  *  When +ndigits+ is less than the number of significant digits
  *  in the sum, the sum is rounded to that number of digits,
  *  according to the current rounding mode; see BigDecimal.mode.
  *
  *  Examples:
  *
  *    # Set the rounding mode.
  *    BigDecimal.mode(BigDecimal::ROUND_MODE, :half_up)
  *    b = BigDecimal('555555.555')
  *    b.mult(3, 0)              # => 0.1666666665e7
  *    b.mult(3, 3)              # => 0.167e7
  *    b.mult(3, 6)              # => 0.166667e7
  *    b.mult(3, 15)             # => 0.1666666665e7
  *    b.mult(3.0, 0)            # => 0.1666666665e7
  *    b.mult(Rational(3, 1), 0) # => 0.1666666665e7
  *    b.mult(Complex(3, 0), 0)  # => (0.1666666665e7+0.0i)
  *
  */

static VALUE
BigDecimal_mult2(VALUE self, VALUE b, VALUE n)
{
    ENTER(2);
    Real *cv;
    SIGNED_VALUE mx = check_int_precision(n);
    if (mx == 0) return BigDecimal_mult(self, b);
    else {
	size_t pl = VpSetPrecLimit(0);
	VALUE   c = BigDecimal_mult(self, b);
	VpSetPrecLimit(pl);
	GUARD_OBJ(cv, GetVpValue(c, 1));
	VpLeftRound(cv, VpGetRoundMode(), mx);
        return VpCheckGetValue(cv);
    }
}

/*
 *  call-seq:
 *    abs -> bigdecimal
 *
 *  Returns the \BigDecimal absolute value of +self+:
 *
 *    BigDecimal('5').abs  # => 0.5e1
 *    BigDecimal('-3').abs # => 0.3e1
 *
 */

static VALUE
BigDecimal_abs(VALUE self)
{
    ENTER(5);
    Real *c, *a;
    size_t mx;

    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec *(VpBaseFig() + 1);
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpAsgn(c, a, 1);
    VpChangeSign(c, 1);
    return VpCheckGetValue(c);
}

/* call-seq:
 *   sqrt(n)
 *
 * Returns the square root of the value.
 *
 * Result has at least n significant digits.
 */
static VALUE
BigDecimal_sqrt(VALUE self, VALUE nFig)
{
    ENTER(5);
    Real *c, *a;
    size_t mx, n;

    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec * (VpBaseFig() + 1);

    n = check_int_precision(nFig);
    n += VpDblFig() + VpBaseFig();
    if (mx <= n) mx = n;
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpSqrt(c, a);
    return VpCheckGetValue(c);
}

/* Return the integer part of the number, as a BigDecimal.
 */
static VALUE
BigDecimal_fix(VALUE self)
{
    ENTER(5);
    Real *c, *a;
    size_t mx;

    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec *(VpBaseFig() + 1);
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpActiveRound(c, a, VP_ROUND_DOWN, 0); /* 0: round off */
    return VpCheckGetValue(c);
}

/* call-seq:
 *   round(n, mode)
 *
 * Round to the nearest integer (by default), returning the result as a
 * BigDecimal if n is specified and positive, or as an Integer if it isn't.
 *
 *	BigDecimal('3.14159').round #=> 3
 *	BigDecimal('8.7').round #=> 9
 *	BigDecimal('-9.9').round #=> -10
 *
 *	BigDecimal('3.14159').round(2).class.name #=> "BigDecimal"
 *	BigDecimal('3.14159').round.class.name #=> "Integer"
 *	BigDecimal('3.14159').round(0).class.name #=> "Integer"
 *
 * If n is specified and positive, the fractional part of the result has no
 * more than that many digits.
 *
 * If n is specified and negative, at least that many digits to the left of the
 * decimal point will be 0 in the result, and return value will be an Integer.
 *
 *	BigDecimal('3.14159').round(3) #=> 3.142
 *	BigDecimal('13345.234').round(-2) #=> 13300
 *
 * The value of the optional mode argument can be used to determine how
 * rounding is performed; see BigDecimal.mode.
 */
static VALUE
BigDecimal_round(int argc, VALUE *argv, VALUE self)
{
    ENTER(5);
    Real   *c, *a;
    int    iLoc = 0;
    VALUE  vLoc;
    VALUE  vRound;
    int    round_to_int = 0;
    size_t mx, pl;

    unsigned short sw = VpGetRoundMode();

    switch (rb_scan_args(argc, argv, "02", &vLoc, &vRound)) {
      case 0:
	iLoc = 0;
        round_to_int = 1;
	break;
      case 1:
        if (RB_TYPE_P(vLoc, T_HASH)) {
	    sw = check_rounding_mode_option(vLoc);
	}
	else {
	    iLoc = NUM2INT(vLoc);
            if (iLoc < 1) round_to_int = 1;
	}
	break;
      case 2:
	iLoc = NUM2INT(vLoc);
	if (RB_TYPE_P(vRound, T_HASH)) {
	    sw = check_rounding_mode_option(vRound);
	}
	else {
	    sw = check_rounding_mode(vRound);
	}
	break;
      default:
	break;
    }

    pl = VpSetPrecLimit(0);
    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec * (VpBaseFig() + 1);
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpSetPrecLimit(pl);
    VpActiveRound(c, a, sw, iLoc);
    if (round_to_int) {
        return BigDecimal_to_i(VpCheckGetValue(c));
    }
    return VpCheckGetValue(c);
}

/* call-seq:
 *   truncate(n)
 *
 * Truncate to the nearest integer (by default), returning the result as a
 * BigDecimal.
 *
 *	BigDecimal('3.14159').truncate #=> 3
 *	BigDecimal('8.7').truncate #=> 8
 *	BigDecimal('-9.9').truncate #=> -9
 *
 * If n is specified and positive, the fractional part of the result has no
 * more than that many digits.
 *
 * If n is specified and negative, at least that many digits to the left of the
 * decimal point will be 0 in the result.
 *
 *	BigDecimal('3.14159').truncate(3) #=> 3.141
 *	BigDecimal('13345.234').truncate(-2) #=> 13300.0
 */
static VALUE
BigDecimal_truncate(int argc, VALUE *argv, VALUE self)
{
    ENTER(5);
    Real *c, *a;
    int iLoc;
    VALUE vLoc;
    size_t mx, pl = VpSetPrecLimit(0);

    if (rb_scan_args(argc, argv, "01", &vLoc) == 0) {
	iLoc = 0;
    }
    else {
	iLoc = NUM2INT(vLoc);
    }

    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec * (VpBaseFig() + 1);
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpSetPrecLimit(pl);
    VpActiveRound(c, a, VP_ROUND_DOWN, iLoc); /* 0: truncate */
    if (argc == 0) {
        return BigDecimal_to_i(VpCheckGetValue(c));
    }
    return VpCheckGetValue(c);
}

/* Return the fractional part of the number, as a BigDecimal.
 */
static VALUE
BigDecimal_frac(VALUE self)
{
    ENTER(5);
    Real *c, *a;
    size_t mx;

    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec * (VpBaseFig() + 1);
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpFrac(c, a);
    return VpCheckGetValue(c);
}

/* call-seq:
 *   floor(n)
 *
 * Return the largest integer less than or equal to the value, as a BigDecimal.
 *
 *	BigDecimal('3.14159').floor #=> 3
 *	BigDecimal('-9.1').floor #=> -10
 *
 * If n is specified and positive, the fractional part of the result has no
 * more than that many digits.
 *
 * If n is specified and negative, at least that
 * many digits to the left of the decimal point will be 0 in the result.
 *
 *	BigDecimal('3.14159').floor(3) #=> 3.141
 *	BigDecimal('13345.234').floor(-2) #=> 13300.0
 */
static VALUE
BigDecimal_floor(int argc, VALUE *argv, VALUE self)
{
    ENTER(5);
    Real *c, *a;
    int iLoc;
    VALUE vLoc;
    size_t mx, pl = VpSetPrecLimit(0);

    if (rb_scan_args(argc, argv, "01", &vLoc)==0) {
	iLoc = 0;
    }
    else {
	iLoc = NUM2INT(vLoc);
    }

    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec * (VpBaseFig() + 1);
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpSetPrecLimit(pl);
    VpActiveRound(c, a, VP_ROUND_FLOOR, iLoc);
#ifdef BIGDECIMAL_DEBUG
    VPrint(stderr, "floor: c=%\n", c);
#endif
    if (argc == 0) {
        return BigDecimal_to_i(VpCheckGetValue(c));
    }
    return VpCheckGetValue(c);
}

/* call-seq:
 *   ceil(n)
 *
 * Return the smallest integer greater than or equal to the value, as a BigDecimal.
 *
 *	BigDecimal('3.14159').ceil #=> 4
 *	BigDecimal('-9.1').ceil #=> -9
 *
 * If n is specified and positive, the fractional part of the result has no
 * more than that many digits.
 *
 * If n is specified and negative, at least that
 * many digits to the left of the decimal point will be 0 in the result.
 *
 *	BigDecimal('3.14159').ceil(3) #=> 3.142
 *	BigDecimal('13345.234').ceil(-2) #=> 13400.0
 */
static VALUE
BigDecimal_ceil(int argc, VALUE *argv, VALUE self)
{
    ENTER(5);
    Real *c, *a;
    int iLoc;
    VALUE vLoc;
    size_t mx, pl = VpSetPrecLimit(0);

    if (rb_scan_args(argc, argv, "01", &vLoc) == 0) {
	iLoc = 0;
    } else {
	iLoc = NUM2INT(vLoc);
    }

    GUARD_OBJ(a, GetVpValue(self, 1));
    mx = a->Prec * (VpBaseFig() + 1);
    GUARD_OBJ(c, NewZeroWrapLimited(1, mx));
    VpSetPrecLimit(pl);
    VpActiveRound(c, a, VP_ROUND_CEIL, iLoc);
    if (argc == 0) {
        return BigDecimal_to_i(VpCheckGetValue(c));
    }
    return VpCheckGetValue(c);
}

/* call-seq:
 *   to_s(s)
 *
 * Converts the value to a string.
 *
 * The default format looks like  0.xxxxEnn.
 *
 * The optional parameter s consists of either an integer; or an optional '+'
 * or ' ', followed by an optional number, followed by an optional 'E' or 'F'.
 *
 * If there is a '+' at the start of s, positive values are returned with
 * a leading '+'.
 *
 * A space at the start of s returns positive values with a leading space.
 *
 * If s contains a number, a space is inserted after each group of that many
 * digits, starting from '.' and counting outwards.
 *
 * If s ends with an 'E', engineering notation (0.xxxxEnn) is used.
 *
 * If s ends with an 'F', conventional floating point notation is used.
 *
 * Examples:
 *
 *   BigDecimal('-1234567890123.45678901234567890').to_s('5F')
 *     #=> '-123 45678 90123.45678 90123 45678 9'
 *
 *   BigDecimal('1234567890123.45678901234567890').to_s('+8F')
 *     #=> '+12345 67890123.45678901 23456789'
 *
 *   BigDecimal('1234567890123.45678901234567890').to_s(' F')
 *     #=> ' 1234567890123.4567890123456789'
 */
static VALUE
BigDecimal_to_s(int argc, VALUE *argv, VALUE self)
{
    ENTER(5);
    int   fmt = 0;   /* 0: E format, 1: F format */
    int   fPlus = 0; /* 0: default, 1: set ' ' before digits, 2: set '+' before digits. */
    Real  *vp;
    volatile VALUE str;
    char  *psz;
    char   ch;
    size_t nc, mc = 0;
    SIGNED_VALUE m;
    VALUE  f;

    GUARD_OBJ(vp, GetVpValue(self, 1));

    if (rb_scan_args(argc, argv, "01", &f) == 1) {
	if (RB_TYPE_P(f, T_STRING)) {
	    psz = StringValueCStr(f);
	    if (*psz == ' ') {
		fPlus = 1;
		psz++;
	    }
	    else if (*psz == '+') {
		fPlus = 2;
		psz++;
	    }
	    while ((ch = *psz++) != 0) {
		if (ISSPACE(ch)) {
		    continue;
		}
		if (!ISDIGIT(ch)) {
		    if (ch == 'F' || ch == 'f') {
			fmt = 1; /* F format */
		    }
		    break;
		}
		mc = mc*10 + ch - '0';
	    }
	}
	else {
	    m = NUM2INT(f);
	    if (m <= 0) {
		rb_raise(rb_eArgError, "argument must be positive");
	    }
	    mc = (size_t)m;
	}
    }
    if (fmt) {
	nc = VpNumOfChars(vp, "F");
    }
    else {
	nc = VpNumOfChars(vp, "E");
    }
    if (mc > 0) {
	nc += (nc + mc - 1) / mc + 1;
    }

    str = rb_usascii_str_new(0, nc);
    psz = RSTRING_PTR(str);

    if (fmt) {
	VpToFString(vp, psz, RSTRING_LEN(str), mc, fPlus);
    }
    else {
	VpToString (vp, psz, RSTRING_LEN(str), mc, fPlus);
    }
    rb_str_resize(str, strlen(psz));
    return str;
}

/* Splits a BigDecimal number into four parts, returned as an array of values.
 *
 * The first value represents the sign of the BigDecimal, and is -1 or 1, or 0
 * if the BigDecimal is Not a Number.
 *
 * The second value is a string representing the significant digits of the
 * BigDecimal, with no leading zeros.
 *
 * The third value is the base used for arithmetic (currently always 10) as an
 * Integer.
 *
 * The fourth value is an Integer exponent.
 *
 * If the BigDecimal can be represented as 0.xxxxxx*10**n, then xxxxxx is the
 * string of significant digits with no leading zeros, and n is the exponent.
 *
 * From these values, you can translate a BigDecimal to a float as follows:
 *
 *   sign, significant_digits, base, exponent = a.split
 *   f = sign * "0.#{significant_digits}".to_f * (base ** exponent)
 *
 * (Note that the to_f method is provided as a more convenient way to translate
 * a BigDecimal to a Float.)
 */
static VALUE
BigDecimal_split(VALUE self)
{
    ENTER(5);
    Real *vp;
    VALUE obj,str;
    ssize_t e, s;
    char *psz1;

    GUARD_OBJ(vp, GetVpValue(self, 1));
    str = rb_str_new(0, VpNumOfChars(vp, "E"));
    psz1 = RSTRING_PTR(str);
    VpSzMantissa(vp, psz1, RSTRING_LEN(str));
    s = 1;
    if(psz1[0] == '-') {
	size_t len = strlen(psz1 + 1);

	memmove(psz1, psz1 + 1, len);
	psz1[len] = '\0';
        s = -1;
    }
    if (psz1[0] == 'N') s = 0; /* NaN */
    e = VpExponent10(vp);
    obj = rb_ary_new2(4);
    rb_ary_push(obj, INT2FIX(s));
    rb_ary_push(obj, str);
    rb_str_resize(str, strlen(psz1));
    rb_ary_push(obj, INT2FIX(10));
    rb_ary_push(obj, SSIZET2NUM(e));
    return obj;
}

/* Returns the exponent of the BigDecimal number, as an Integer.
 *
 * If the number can be represented as 0.xxxxxx*10**n where xxxxxx is a string
 * of digits with no leading zeros, then n is the exponent.
 */
static VALUE
BigDecimal_exponent(VALUE self)
{
    ssize_t e = VpExponent10(GetVpValue(self, 1));
    return SSIZET2NUM(e);
}

/* Returns a string representation of self.
 *
 *   BigDecimal("1234.5678").inspect
 *     #=> "0.12345678e4"
 */
static VALUE
BigDecimal_inspect(VALUE self)
{
    ENTER(5);
    Real *vp;
    volatile VALUE str;
    size_t nc;

    GUARD_OBJ(vp, GetVpValue(self, 1));
    nc = VpNumOfChars(vp, "E");

    str = rb_str_new(0, nc);
    VpToString(vp, RSTRING_PTR(str), RSTRING_LEN(str), 0, 0);
    rb_str_resize(str, strlen(RSTRING_PTR(str)));
    return str;
}

static VALUE BigMath_s_exp(VALUE, VALUE, VALUE);
static VALUE BigMath_s_log(VALUE, VALUE, VALUE);

#define BigMath_exp(x, n) BigMath_s_exp(rb_mBigMath, (x), (n))
#define BigMath_log(x, n) BigMath_s_log(rb_mBigMath, (x), (n))

inline static int
is_integer(VALUE x)
{
    return (RB_TYPE_P(x, T_FIXNUM) || RB_TYPE_P(x, T_BIGNUM));
}

inline static int
is_negative(VALUE x)
{
    if (FIXNUM_P(x)) {
	return FIX2LONG(x) < 0;
    }
    else if (RB_TYPE_P(x, T_BIGNUM)) {
	return FIX2INT(rb_big_cmp(x, INT2FIX(0))) < 0;
    }
    else if (RB_TYPE_P(x, T_FLOAT)) {
	return RFLOAT_VALUE(x) < 0.0;
    }
    return RTEST(rb_funcall(x, '<', 1, INT2FIX(0)));
}

#define is_positive(x) (!is_negative(x))

inline static int
is_zero(VALUE x)
{
    VALUE num;

    switch (TYPE(x)) {
      case T_FIXNUM:
	return FIX2LONG(x) == 0;

      case T_BIGNUM:
	return Qfalse;

      case T_RATIONAL:
	num = rb_rational_num(x);
	return FIXNUM_P(num) && FIX2LONG(num) == 0;

      default:
	break;
    }

    return RTEST(rb_funcall(x, id_eq, 1, INT2FIX(0)));
}

inline static int
is_one(VALUE x)
{
    VALUE num, den;

    switch (TYPE(x)) {
      case T_FIXNUM:
	return FIX2LONG(x) == 1;

      case T_BIGNUM:
	return Qfalse;

      case T_RATIONAL:
	num = rb_rational_num(x);
	den = rb_rational_den(x);
	return FIXNUM_P(den) && FIX2LONG(den) == 1 &&
	       FIXNUM_P(num) && FIX2LONG(num) == 1;

      default:
	break;
    }

    return RTEST(rb_funcall(x, id_eq, 1, INT2FIX(1)));
}

inline static int
is_even(VALUE x)
{
    switch (TYPE(x)) {
      case T_FIXNUM:
	return (FIX2LONG(x) % 2) == 0;

      case T_BIGNUM:
        {
            unsigned long l;
            rb_big_pack(x, &l, 1);
            return l % 2 == 0;
        }

      default:
	break;
    }

    return 0;
}

static VALUE
bigdecimal_power_by_bigdecimal(Real const* x, Real const* exp, ssize_t const n)
{
    VALUE log_x, multiplied, y;
    volatile VALUE obj = exp->obj;

    if (VpIsZero(exp)) {
        return VpCheckGetValue(NewOneWrapLimited(1, n));
    }

    log_x = BigMath_log(x->obj, SSIZET2NUM(n+1));
    multiplied = BigDecimal_mult2(exp->obj, log_x, SSIZET2NUM(n+1));
    y = BigMath_exp(multiplied, SSIZET2NUM(n));
    RB_GC_GUARD(obj);

    return y;
}

/* call-seq:
 *   power(n)
 *   power(n, prec)
 *
 * Returns the value raised to the power of n.
 *
 * Note that n must be an Integer.
 *
 * Also available as the operator **.
 */
static VALUE
BigDecimal_power(int argc, VALUE*argv, VALUE self)
{
    ENTER(5);
    VALUE vexp, prec;
    Real* exp = NULL;
    Real *x, *y;
    ssize_t mp, ma, n;
    SIGNED_VALUE int_exp;
    double d;

    rb_scan_args(argc, argv, "11", &vexp, &prec);

    GUARD_OBJ(x, GetVpValue(self, 1));
    n = NIL_P(prec) ? (ssize_t)(x->Prec*VpBaseFig()) : NUM2SSIZET(prec);

    if (VpIsNaN(x)) {
        y = NewZeroWrapLimited(1, n);
        VpSetNaN(y);
        RB_GC_GUARD(y->obj);
        return VpCheckGetValue(y);
    }

  retry:
    switch (TYPE(vexp)) {
      case T_FIXNUM:
	break;

      case T_BIGNUM:
	break;

      case T_FLOAT:
	d = RFLOAT_VALUE(vexp);
	if (d == round(d)) {
	    if (FIXABLE(d)) {
		vexp = LONG2FIX((long)d);
	    }
	    else {
		vexp = rb_dbl2big(d);
	    }
	    goto retry;
	}
        if (NIL_P(prec)) {
            n += BIGDECIMAL_DOUBLE_FIGURES;
        }
        exp = GetVpValueWithPrec(vexp, 0, 1);
	break;

      case T_RATIONAL:
	if (is_zero(rb_rational_num(vexp))) {
	    if (is_positive(vexp)) {
		vexp = INT2FIX(0);
		goto retry;
	    }
	}
	else if (is_one(rb_rational_den(vexp))) {
	    vexp = rb_rational_num(vexp);
	    goto retry;
	}
	exp = GetVpValueWithPrec(vexp, n, 1);
        if (NIL_P(prec)) {
            n += n;
        }
	break;

      case T_DATA:
	if (is_kind_of_BigDecimal(vexp)) {
	    VALUE zero = INT2FIX(0);
	    VALUE rounded = BigDecimal_round(1, &zero, vexp);
	    if (RTEST(BigDecimal_eq(vexp, rounded))) {
		vexp = BigDecimal_to_i(vexp);
		goto retry;
	    }
            if (NIL_P(prec)) {
                GUARD_OBJ(y, GetVpValue(vexp, 1));
                n += y->Prec*VpBaseFig();
            }
	    exp = DATA_PTR(vexp);
	    break;
	}
	/* fall through */
      default:
	rb_raise(rb_eTypeError,
		 "wrong argument type %"PRIsVALUE" (expected scalar Numeric)",
		 RB_OBJ_CLASSNAME(vexp));
    }

    if (VpIsZero(x)) {
        if (is_negative(vexp)) {
            y = NewZeroWrapNolimit(1, n);
            if (BIGDECIMAL_NEGATIVE_P(x)) {
                if (is_integer(vexp)) {
                    if (is_even(vexp)) {
                        /* (-0) ** (-even_integer)  -> Infinity */
                        VpSetPosInf(y);
                    }
                    else {
                        /* (-0) ** (-odd_integer)  -> -Infinity */
                        VpSetNegInf(y);
                    }
                }
                else {
                    /* (-0) ** (-non_integer)  -> Infinity */
                    VpSetPosInf(y);
                }
            }
            else {
                /* (+0) ** (-num)  -> Infinity */
                VpSetPosInf(y);
            }
            RB_GC_GUARD(y->obj);
            return VpCheckGetValue(y);
        }
        else if (is_zero(vexp)) {
            return VpCheckGetValue(NewOneWrapLimited(1, n));
        }
        else {
            return VpCheckGetValue(NewZeroWrapLimited(1, n));
        }
    }

    if (is_zero(vexp)) {
        return VpCheckGetValue(NewOneWrapLimited(1, n));
    }
    else if (is_one(vexp)) {
        return self;
    }

    if (VpIsInf(x)) {
        if (is_negative(vexp)) {
            if (BIGDECIMAL_NEGATIVE_P(x)) {
                if (is_integer(vexp)) {
                    if (is_even(vexp)) {
                        /* (-Infinity) ** (-even_integer) -> +0 */
                        return VpCheckGetValue(NewZeroWrapLimited(1, n));
                    }
                    else {
                        /* (-Infinity) ** (-odd_integer) -> -0 */
                        return VpCheckGetValue(NewZeroWrapLimited(-1, n));
                    }
                }
                else {
                    /* (-Infinity) ** (-non_integer) -> -0 */
                    return VpCheckGetValue(NewZeroWrapLimited(-1, n));
                }
            }
            else {
                return VpCheckGetValue(NewZeroWrapLimited(1, n));
            }
        }
        else {
            y = NewZeroWrapLimited(1, n);
            if (BIGDECIMAL_NEGATIVE_P(x)) {
                if (is_integer(vexp)) {
                    if (is_even(vexp)) {
                        VpSetPosInf(y);
                    }
                    else {
                        VpSetNegInf(y);
                    }
                }
                else {
                    /* TODO: support complex */
                    rb_raise(rb_eMathDomainError,
                            "a non-integral exponent for a negative base");
                }
            }
            else {
                VpSetPosInf(y);
            }
            return VpCheckGetValue(y);
        }
    }

    if (exp != NULL) {
        return bigdecimal_power_by_bigdecimal(x, exp, n);
    }
    else if (RB_TYPE_P(vexp, T_BIGNUM)) {
        VALUE abs_value = BigDecimal_abs(self);
        if (is_one(abs_value)) {
            return VpCheckGetValue(NewOneWrapLimited(1, n));
        }
        else if (RTEST(rb_funcall(abs_value, '<', 1, INT2FIX(1)))) {
            if (is_negative(vexp)) {
                y = NewZeroWrapLimited(1, n);
                VpSetInf(y, (is_even(vexp) ? 1 : -1) * VpGetSign(x));
                return VpCheckGetValue(y);
            }
            else if (BIGDECIMAL_NEGATIVE_P(x) && is_even(vexp)) {
                return VpCheckGetValue(NewZeroWrapLimited(-1, n));
            }
            else {
                return VpCheckGetValue(NewZeroWrapLimited(1, n));
            }
        }
        else {
            if (is_positive(vexp)) {
                y = NewZeroWrapLimited(1, n);
                VpSetInf(y, (is_even(vexp) ? 1 : -1) * VpGetSign(x));
                return VpCheckGetValue(y);
            }
            else if (BIGDECIMAL_NEGATIVE_P(x) && is_even(vexp)) {
                return VpCheckGetValue(NewZeroWrapLimited(-1, n));
            }
            else {
                return VpCheckGetValue(NewZeroWrapLimited(1, n));
            }
        }
    }

    int_exp = FIX2LONG(vexp);
    ma = int_exp;
    if (ma <  0) ma = -ma;
    if (ma == 0) ma = 1;

    if (VpIsDef(x)) {
        mp = x->Prec * (VpBaseFig() + 1);
        GUARD_OBJ(y, NewZeroWrapLimited(1, mp * (ma + 1)));
    }
    else {
        GUARD_OBJ(y, NewZeroWrapLimited(1, 1));
    }
    VpPowerByInt(y, x, int_exp);
    if (!NIL_P(prec) && VpIsDef(y)) {
        VpMidRound(y, VpGetRoundMode(), n);
    }
    return VpCheckGetValue(y);
}

/*  call-seq:
 *    self ** other -> bigdecimal
 *
 *  Returns the \BigDecimal value of +self+ raised to power +other+:
 *
 *    b = BigDecimal('3.14')
 *    b ** 2              # => 0.98596e1
 *    b ** 2.0            # => 0.98596e1
 *    b ** Rational(2, 1) # => 0.98596e1
 *
 *  Related: BigDecimal#power.
 *
 */
static VALUE
BigDecimal_power_op(VALUE self, VALUE exp)
{
    return BigDecimal_power(1, &exp, self);
}

/* :nodoc:
 *
 * private method for dup and clone the provided BigDecimal +other+
 */
static VALUE
BigDecimal_initialize_copy(VALUE self, VALUE other)
{
    Real *pv = rb_check_typeddata(self, &BigDecimal_data_type);
    Real *x = rb_check_typeddata(other, &BigDecimal_data_type);

    if (self != other) {
	DATA_PTR(self) = VpCopy(pv, x);
    }
    return self;
}

/* :nodoc: */
static VALUE
BigDecimal_clone(VALUE self)
{
    return self;
}

#ifdef HAVE_RB_OPTS_EXCEPTION_P
int rb_opts_exception_p(VALUE opts, int default_value);
#define opts_exception_p(opts) rb_opts_exception_p((opts), 1)
#else
static int
opts_exception_p(VALUE opts)
{
    static ID kwds[1];
    VALUE exception;
    if (!kwds[0]) {
        kwds[0] = rb_intern_const("exception");
    }
    if (!rb_get_kwargs(opts, kwds, 0, 1, &exception)) return 1;
    switch (exception) {
      case Qtrue: case Qfalse:
        break;
      default:
        rb_raise(rb_eArgError, "true or false is expected as exception: %+"PRIsVALUE,
                 exception);
    }
    return exception != Qfalse;
}
#endif

static VALUE
check_exception(VALUE bd)
{
    assert(is_kind_of_BigDecimal(bd));

    Real *vp;
    TypedData_Get_Struct(bd, Real, &BigDecimal_data_type, vp);
    VpCheckGetValue(vp); /* VpCheckGetValue performs exception check */

    return bd;
}

static VALUE
rb_uint64_convert_to_BigDecimal(uint64_t uval, RB_UNUSED_VAR(size_t digs), int raise_exception)
{
    VALUE obj = TypedData_Wrap_Struct(rb_cBigDecimal, &BigDecimal_data_type, 0);

    Real *vp;
    if (uval == 0) {
        vp = rbd_allocate_struct(1);
        vp->MaxPrec = 1;
        vp->Prec = 1;
        vp->exponent = 1;
        VpSetZero(vp, 1);
        vp->frac[0] = 0;
    }
    else if (uval < BASE) {
        vp = rbd_allocate_struct(1);
        vp->MaxPrec = 1;
        vp->Prec = 1;
        vp->exponent = 1;
        VpSetSign(vp, 1);
        vp->frac[0] = (DECDIG)uval;
    }
    else {
        DECDIG buf[BIGDECIMAL_INT64_MAX_LENGTH] = {0,};
        DECDIG r = uval % BASE;
        size_t len = 0, ntz = 0;
        if (r == 0) {
            // Count and skip trailing zeros
            for (; r == 0 && uval > 0; ++ntz) {
                uval /= BASE;
                r = uval % BASE;
            }
        }
        for (; uval > 0; ++len) {
            // Store digits
            buf[BIGDECIMAL_INT64_MAX_LENGTH - len - 1] = r;
            uval /= BASE;
            r = uval % BASE;
        }

        const size_t exp = len + ntz;
        vp = rbd_allocate_struct(len);
        vp->MaxPrec = len;
        vp->Prec = len;
        vp->exponent = exp;
        VpSetSign(vp, 1);
        MEMCPY(vp->frac, buf + BIGDECIMAL_INT64_MAX_LENGTH - len, DECDIG, len);
    }

    return BigDecimal_wrap_struct(obj, vp);
}

static VALUE
rb_int64_convert_to_BigDecimal(int64_t ival, size_t digs, int raise_exception)
{
    const uint64_t uval = (ival < 0) ? (((uint64_t)-(ival+1))+1) : (uint64_t)ival;
    VALUE bd = rb_uint64_convert_to_BigDecimal(uval, digs, raise_exception);
    if (ival < 0) {
        Real *vp;
        TypedData_Get_Struct(bd, Real, &BigDecimal_data_type, vp);
        VpSetSign(vp, -1);
    }
    return bd;
}

static VALUE
rb_big_convert_to_BigDecimal(VALUE val, RB_UNUSED_VAR(size_t digs), int raise_exception)
{
    assert(RB_TYPE_P(val, T_BIGNUM));

    int leading_zeros;
    size_t size = rb_absint_size(val, &leading_zeros);
    int sign = FIX2INT(rb_big_cmp(val, INT2FIX(0)));
    if (sign < 0 && leading_zeros == 0) {
        size += 1;
    }
    if (size <= sizeof(long)) {
        if (sign < 0) {
            return rb_int64_convert_to_BigDecimal(NUM2LONG(val), digs, raise_exception);
        }
        else {
            return rb_uint64_convert_to_BigDecimal(NUM2ULONG(val), digs, raise_exception);
        }
    }
#if defined(SIZEOF_LONG_LONG) && SIZEOF_LONG < SIZEOF_LONG_LONG
    else if (size <= sizeof(LONG_LONG)) {
        if (sign < 0) {
            return rb_int64_convert_to_BigDecimal(NUM2LL(val), digs, raise_exception);
        }
        else {
            return rb_uint64_convert_to_BigDecimal(NUM2ULL(val), digs, raise_exception);
        }
    }
#endif
    else {
        VALUE str = rb_big2str(val, 10);
        Real *vp = VpCreateRbObject(RSTRING_LEN(str) + BASE_FIG + 1,
                                    RSTRING_PTR(str), true);
        RB_GC_GUARD(str);
        return check_exception(vp->obj);
    }
}

static VALUE
rb_inum_convert_to_BigDecimal(VALUE val, RB_UNUSED_VAR(size_t digs), int raise_exception)
{
    assert(RB_INTEGER_TYPE_P(val));
    if (FIXNUM_P(val)) {
        return rb_int64_convert_to_BigDecimal(FIX2LONG(val), digs, raise_exception);
    }
    else {
        return rb_big_convert_to_BigDecimal(val, digs, raise_exception);
    }
}

static VALUE
rb_float_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception)
{
    assert(RB_FLOAT_TYPE_P(val));

    double d = RFLOAT_VALUE(val);

    if (isnan(d)) {
        VALUE obj = BigDecimal_nan();
        return check_exception(obj);
    }
    else if (isinf(d)) {
        VALUE obj;
        if (d > 0) {
            obj = BigDecimal_positive_infinity();
        }
        else {
            obj = BigDecimal_negative_infinity();
        }
        return check_exception(obj);
    }
    else if (d == 0.0) {
        if (1/d < 0.0) {
            return BigDecimal_negative_zero();
        }
        else {
            return BigDecimal_positive_zero();
        }
    }

    if (digs == SIZE_MAX) {
        if (!raise_exception)
            return Qnil;
        rb_raise(rb_eArgError,
                 "can't omit precision for a %"PRIsVALUE".",
                 CLASS_OF(val));
    }
    else if (digs > BIGDECIMAL_DOUBLE_FIGURES) {
        if (!raise_exception)
            return Qnil;
        rb_raise(rb_eArgError, "precision too large.");
    }

    /* Use the same logic in flo_to_s to convert a float to a decimal string */
    char buf[BIGDECIMAL_DOUBLE_FIGURES + BASE_FIG + 2 + 1];  /* sizeof(buf) == 28 in the typical case */
    int decpt, negative_p;
    char *e;
    const int mode = digs == 0 ? 0 : 2;
    char *p = BigDecimal_dtoa(d, mode, (int)digs, &decpt, &negative_p, &e);
    int len10 = (int)(e - p);
    if (len10 > BIGDECIMAL_DOUBLE_FIGURES) {
        /* TODO: Presumably, rounding should be done here. */
        len10 = BIGDECIMAL_DOUBLE_FIGURES;
    }
    memcpy(buf, p, len10);
    xfree(p);

    VALUE inum;
    size_t RB_UNUSED_VAR(prec) = 0;
    SIGNED_VALUE exp = 0;
    if (decpt > 0) {
        if (decpt < len10) {
            /*
             *     len10 |---------------|
             *           :       |-------| frac_len10 = len10 - decpt
             *     decpt |-------|       |--| ntz10 = BASE_FIG - frac_len10 % BASE_FIG
             *           :       :       :
             *         00 dd dddd.dddd dd 00
             *   prec |-----.----.----.-----| prec = exp + roomof(frac_len, BASE_FIG)
             *   exp  |-----.----| exp = roomof(decpt, BASE_FIG)
             */
            const size_t frac_len10 = len10 - decpt;
            const size_t ntz10 = BASE_FIG - frac_len10 % BASE_FIG;
            memset(buf + len10, '0', ntz10);
            buf[len10 + ntz10] = '\0';
            inum = rb_cstr_to_inum(buf, 10, false);

            exp = roomof(decpt, BASE_FIG);
            prec = exp + roomof(frac_len10, BASE_FIG);
        }
        else {
            /*
             *      decpt |-----------------------|
             *      len10 |----------|            :
             *            :          |------------| exp10
             *            :          :            :
             *          00 dd dddd dd 00 0000 0000.0
             *         :             :  :         :
             *         :             |--| ntz10 = exp10 % BASE_FIG
             *    prec |-----.----.-----|         :
             *         :                |----.----| exp10 / BASE_FIG
             *     exp |-----.----.-----.----.----|
             */
            const size_t exp10 = decpt - len10;
            const size_t ntz10 = exp10 % BASE_FIG;

            memset(buf + len10, '0', ntz10);
            buf[len10 + ntz10] = '\0';
            inum = rb_cstr_to_inum(buf, 10, false);

            prec = roomof(len10 + ntz10, BASE_FIG);
            exp = prec + exp10 / BASE_FIG;
        }
    }
    else if (decpt == 0) {
        /*
         *   len10 |------------|
         *         :            :
         *        0.dddd dddd dd 00
         *         :            :  :
         *         :            |--| ntz10 = prec * BASE_FIG - len10
         *    prec |----.----.-----| roomof(len10, BASE_FIG)
         */
        prec = roomof(len10, BASE_FIG);
        const size_t ntz10 = prec * BASE_FIG - len10;

        memset(buf + len10, '0', ntz10);
        buf[len10 + ntz10] = '\0';
        inum = rb_cstr_to_inum(buf, 10, false);
    }
    else {
        /*
         *           len10 |---------------|
         *                 :               :
         *   decpt |-------|               |--| ntz10 = prec * BASE_FIG - nlz10 - len10
         *         :       :               :
         *        0.0000 00 dd dddd dddd dd 00
         *              :  :                  :
         *        nlz10 |--|                  : decpt % BASE_FIG
         *         prec |-----.----.----.-----| roomof(decpt + len10, BASE_FIG) - exp
         *    exp  |----| decpt / BASE_FIG
         */
        decpt = -decpt;

        const size_t nlz10 = decpt % BASE_FIG;
        exp = decpt / BASE_FIG;
        prec = roomof(decpt + len10, BASE_FIG) - exp;
        const size_t ntz10 = prec * BASE_FIG - nlz10 - len10;

        if (nlz10 > 0) {
            memmove(buf + nlz10, buf, len10);
            memset(buf, '0', nlz10);
        }
        memset(buf + nlz10 + len10, '0', ntz10);
        buf[nlz10 + len10 + ntz10] = '\0';
        inum = rb_cstr_to_inum(buf, 10, false);

        exp = -exp;
    }

    VALUE bd = rb_inum_convert_to_BigDecimal(inum, SIZE_MAX, raise_exception);
    Real *vp;
    TypedData_Get_Struct(bd, Real, &BigDecimal_data_type, vp);
    assert(vp->Prec == prec);
    vp->exponent = exp;

    if (negative_p) VpSetSign(vp, -1);
    return bd;
}

static VALUE
rb_rational_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception)
{
    assert(RB_TYPE_P(val, T_RATIONAL));

    if (digs == SIZE_MAX) {
        if (!raise_exception)
            return Qnil;
        rb_raise(rb_eArgError,
                 "can't omit precision for a %"PRIsVALUE".",
                 CLASS_OF(val));
    }

    VALUE num = rb_inum_convert_to_BigDecimal(rb_rational_num(val), 0, raise_exception);
    VALUE d = BigDecimal_div2(num, rb_rational_den(val), SIZET2NUM(digs));
    return d;
}

static VALUE
rb_cstr_convert_to_BigDecimal(const char *c_str, size_t digs, int raise_exception)
{
    if (digs == SIZE_MAX)
        digs = 0;

    Real *vp = VpCreateRbObject(digs, c_str, raise_exception);
    if (!vp)
        return Qnil;
    return VpCheckGetValue(vp);
}

static inline VALUE
rb_str_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception)
{
    const char *c_str = StringValueCStr(val);
    return rb_cstr_convert_to_BigDecimal(c_str, digs, raise_exception);
}

static VALUE
rb_convert_to_BigDecimal(VALUE val, size_t digs, int raise_exception)
{
    switch (val) {
      case Qnil:
      case Qtrue:
      case Qfalse:
        if (raise_exception) {
            const char *cname = NIL_P(val)    ? "nil"   :
                                val == Qtrue  ? "true"  :
                                val == Qfalse ? "false" :
                                NULL;
            rb_raise(rb_eTypeError,
                       "can't convert %s into BigDecimal", cname);
        }
        return Qnil;

      default:
        break;
    }

    if (is_kind_of_BigDecimal(val)) {
        if (digs == SIZE_MAX)
            return check_exception(val);

        Real *vp;
        TypedData_Get_Struct(val, Real, &BigDecimal_data_type, vp);

        VALUE copy = TypedData_Wrap_Struct(rb_cBigDecimal, &BigDecimal_data_type, 0);
        vp = VpCopy(NULL, vp);
        /* TODO: rounding */
        BigDecimal_wrap_struct(copy, vp);
        return VpCheckGetValue(vp);
    }
    else if (RB_INTEGER_TYPE_P(val)) {
        return rb_inum_convert_to_BigDecimal(val, digs, raise_exception);
    }
    else if (RB_FLOAT_TYPE_P(val)) {
        return rb_float_convert_to_BigDecimal(val, digs, raise_exception);
    }
    else if (RB_TYPE_P(val, T_RATIONAL)) {
        return rb_rational_convert_to_BigDecimal(val, digs, raise_exception);
    }
    else if (RB_TYPE_P(val, T_COMPLEX)) {
        VALUE im = rb_complex_imag(val);
        if (!is_zero(im)) {
            /* TODO: handle raise_exception */
            rb_raise(rb_eArgError,
                     "Unable to make a BigDecimal from non-zero imaginary number");
        }
        return rb_convert_to_BigDecimal(rb_complex_real(val), digs, raise_exception);
    }
    else if (RB_TYPE_P(val, T_STRING)) {
        return rb_str_convert_to_BigDecimal(val, digs, raise_exception);
    }

    /* TODO: chheck to_d */
    /* TODO: chheck to_int */

    VALUE str = rb_check_convert_type(val, T_STRING, "String", "to_str");
    if (!RB_TYPE_P(str, T_STRING)) {
        if (raise_exception) {
            rb_raise(rb_eTypeError,
                     "can't convert %"PRIsVALUE" into BigDecimal", rb_obj_class(val));
        }
        return Qnil;
    }
    return rb_str_convert_to_BigDecimal(str, digs, raise_exception);
}

/*  call-seq:
 *    BigDecimal(value, exception: true) -> bigdecimal
 *    BigDecimal(value, ndigits, exception: true) -> bigdecimal
 *
 *  Returns the \BigDecimal converted from +value+
 *  with a precision of +ndigits+ decimal digits.
 *
 *  When +ndigits+ is less than the number of significant digits
 *  in the value, the result is rounded to that number of digits,
 *  according to the current rounding mode; see BigDecimal.mode.
 *
 *  When +ndigits+ is 0, the number of digits to correctly represent a float number
 *  is determined automatically.
 *
 *  Returns +value+ converted to a \BigDecimal, depending on the type of +value+:
 *
 *  - Integer, Float, Rational, Complex, or BigDecimal: converted directly:
 *
 *      # Integer, Complex, or BigDecimal value does not require ndigits; ignored if given.
 *      BigDecimal(2)                     # => 0.2e1
 *      BigDecimal(Complex(2, 0))         # => 0.2e1
 *      BigDecimal(BigDecimal(2))         # => 0.2e1
 *      # Float or Rational value requires ndigits.
 *      BigDecimal(2.0, 0)                # => 0.2e1
 *      BigDecimal(Rational(2, 1), 0)     # => 0.2e1
 *
 *  - String: converted by parsing if it contains an integer or floating-point literal;
 *    leading and trailing whitespace is ignored:
 *
 *      # String does not require ndigits; ignored if given.
 *      BigDecimal('2')     # => 0.2e1
 *      BigDecimal('2.0')   # => 0.2e1
 *      BigDecimal('0.2e1') # => 0.2e1
 *      BigDecimal(' 2.0 ') # => 0.2e1
 *
 *  - Other type that responds to method <tt>:to_str</tt>:
 *    first converted to a string, then converted to a \BigDecimal, as above.
 *
 *  - Other type:
 *
 *    - Raises an exception if keyword argument +exception+ is +true+.
 *    - Returns +nil+ if keyword argument +exception+ is +false+.
 *
 *  Raises an exception if +value+ evaluates to a Float
 *  and +digits+ is larger than Float::DIG + 1.
 *
 */
static VALUE
f_BigDecimal(int argc, VALUE *argv, VALUE self)
{
    VALUE val, digs_v, opts = Qnil;
    argc = rb_scan_args(argc, argv, "11:", &val, &digs_v, &opts);
    int exception = opts_exception_p(opts);

    size_t digs = SIZE_MAX; /* this means digs is omitted */
    if (argc > 1) {
        digs_v = rb_to_int(digs_v);
        if (FIXNUM_P(digs_v)) {
            long n = FIX2LONG(digs_v);
            if (n < 0)
                goto negative_digs;
            digs = (size_t)n;
        }
        else {
            if (RBIGNUM_NEGATIVE_P(digs_v)) {
              negative_digs:
                if (!exception)
                    return Qnil;
                rb_raise(rb_eArgError, "negative precision");
            }
            digs = NUM2SIZET(digs_v);
        }
    }

    return rb_convert_to_BigDecimal(val, digs, exception);
}

/*  call-seq:
 *    BigDecimal.interpret_loosely(string) -> bigdecimal
 *
 *  Returns the +BigDecimal+ converted loosely from +string+.
 */

static VALUE
BigDecimal_s_interpret_loosely(VALUE klass, VALUE str)
{
    char const *c_str = StringValueCStr(str);
    Real *vp = VpNewRbClass(0, c_str, klass, false, true);
    if (!vp)
        return Qnil;
    else
        return VpCheckGetValue(vp);
}

 /*
  * call-seq:
  *   BigDecimal.limit(digits)
  *
  * Limit the number of significant digits in newly created BigDecimal
  * numbers to the specified value. Rounding is performed as necessary,
  * as specified by BigDecimal.mode.
  *
  * A limit of 0, the default, means no upper limit.
  *
  * The limit specified by this method takes less priority over any limit
  * specified to instance methods such as ceil, floor, truncate, or round.
  */
static VALUE
BigDecimal_limit(int argc, VALUE *argv, VALUE self)
{
    VALUE  nFig;
    VALUE  nCur = SIZET2NUM(VpGetPrecLimit());

    if (rb_scan_args(argc, argv, "01", &nFig) == 1) {
	int nf;
	if (NIL_P(nFig)) return nCur;
	nf = NUM2INT(nFig);
	if (nf < 0) {
	    rb_raise(rb_eArgError, "argument must be positive");
	}
	VpSetPrecLimit(nf);
    }
    return nCur;
}

/* Returns the sign of the value.
 *
 * Returns a positive value if > 0, a negative value if < 0.
 * It behaves the same with zeros -
 * it returns a positive value for a positive zero (BigDecimal('0')) and
 * a negative value for a negative zero (BigDecimal('-0')).
 *
 * The specific value returned indicates the type and sign of the BigDecimal,
 * as follows:
 *
 * BigDecimal::SIGN_NaN:: value is Not a Number
 * BigDecimal::SIGN_POSITIVE_ZERO:: value is +0
 * BigDecimal::SIGN_NEGATIVE_ZERO:: value is -0
 * BigDecimal::SIGN_POSITIVE_INFINITE:: value is +Infinity
 * BigDecimal::SIGN_NEGATIVE_INFINITE:: value is -Infinity
 * BigDecimal::SIGN_POSITIVE_FINITE:: value is positive
 * BigDecimal::SIGN_NEGATIVE_FINITE:: value is negative
 */
static VALUE
BigDecimal_sign(VALUE self)
{ /* sign */
    int s = GetVpValue(self, 1)->sign;
    return INT2FIX(s);
}

/*
 * call-seq: BigDecimal.save_exception_mode { ... }
 *
 * Execute the provided block, but preserve the exception mode
 *
 *     BigDecimal.save_exception_mode do
 *       BigDecimal.mode(BigDecimal::EXCEPTION_OVERFLOW, false)
 *       BigDecimal.mode(BigDecimal::EXCEPTION_NaN, false)
 *
 *       BigDecimal(BigDecimal('Infinity'))
 *       BigDecimal(BigDecimal('-Infinity'))
 *       BigDecimal(BigDecimal('NaN'))
 *     end
 *
 * For use with the BigDecimal::EXCEPTION_*
 *
 * See BigDecimal.mode
 */
static VALUE
BigDecimal_save_exception_mode(VALUE self)
{
    unsigned short const exception_mode = VpGetException();
    int state;
    VALUE ret = rb_protect(rb_yield, Qnil, &state);
    VpSetException(exception_mode);
    if (state) rb_jump_tag(state);
    return ret;
}

/*
 * call-seq: BigDecimal.save_rounding_mode { ... }
 *
 * Execute the provided block, but preserve the rounding mode
 *
 *     BigDecimal.save_rounding_mode do
 *       BigDecimal.mode(BigDecimal::ROUND_MODE, :up)
 *       puts BigDecimal.mode(BigDecimal::ROUND_MODE)
 *     end
 *
 * For use with the BigDecimal::ROUND_*
 *
 * See BigDecimal.mode
 */
static VALUE
BigDecimal_save_rounding_mode(VALUE self)
{
    unsigned short const round_mode = VpGetRoundMode();
    int state;
    VALUE ret = rb_protect(rb_yield, Qnil, &state);
    VpSetRoundMode(round_mode);
    if (state) rb_jump_tag(state);
    return ret;
}

/*
 * call-seq: BigDecimal.save_limit { ... }
 *
 * Execute the provided block, but preserve the precision limit
 *
 *      BigDecimal.limit(100)
 *      puts BigDecimal.limit
 *      BigDecimal.save_limit do
 *          BigDecimal.limit(200)
 *          puts BigDecimal.limit
 *      end
 *      puts BigDecimal.limit
 *
 */
static VALUE
BigDecimal_save_limit(VALUE self)
{
    size_t const limit = VpGetPrecLimit();
    int state;
    VALUE ret = rb_protect(rb_yield, Qnil, &state);
    VpSetPrecLimit(limit);
    if (state) rb_jump_tag(state);
    return ret;
}

/* call-seq:
 *   BigMath.exp(decimal, numeric)    -> BigDecimal
 *
 * Computes the value of e (the base of natural logarithms) raised to the
 * power of +decimal+, to the specified number of digits of precision.
 *
 * If +decimal+ is infinity, returns Infinity.
 *
 * If +decimal+ is NaN, returns NaN.
 */
static VALUE
BigMath_s_exp(VALUE klass, VALUE x, VALUE vprec)
{
    ssize_t prec, n, i;
    Real* vx = NULL;
    VALUE one, d, y;
    int negative = 0;
    int infinite = 0;
    int nan = 0;
    double flo;

    prec = NUM2SSIZET(vprec);
    if (prec <= 0) {
	rb_raise(rb_eArgError, "Zero or negative precision for exp");
    }

    /* TODO: the following switch statement is almost same as one in the
     *       BigDecimalCmp function. */
    switch (TYPE(x)) {
      case T_DATA:
	if (!is_kind_of_BigDecimal(x)) break;
	vx = DATA_PTR(x);
	negative = BIGDECIMAL_NEGATIVE_P(vx);
	infinite = VpIsPosInf(vx) || VpIsNegInf(vx);
	nan = VpIsNaN(vx);
	break;

      case T_FIXNUM:
	/* fall through */
      case T_BIGNUM:
	vx = GetVpValue(x, 0);
	break;

      case T_FLOAT:
	flo = RFLOAT_VALUE(x);
	negative = flo < 0;
	infinite = isinf(flo);
	nan = isnan(flo);
	if (!infinite && !nan) {
	    vx = GetVpValueWithPrec(x, 0, 0);
	}
	break;

      case T_RATIONAL:
	vx = GetVpValueWithPrec(x, prec, 0);
	break;

      default:
	break;
    }
    if (infinite) {
	if (negative) {
            return VpCheckGetValue(GetVpValueWithPrec(INT2FIX(0), prec, 1));
	}
	else {
	    Real* vy = NewZeroWrapNolimit(1, prec);
	    VpSetInf(vy, VP_SIGN_POSITIVE_INFINITE);
	    RB_GC_GUARD(vy->obj);
            return VpCheckGetValue(vy);
	}
    }
    else if (nan) {
        Real* vy = NewZeroWrapNolimit(1, prec);
        VpSetNaN(vy);
        RB_GC_GUARD(vy->obj);
        return VpCheckGetValue(vy);
    }
    else if (vx == NULL) {
	cannot_be_coerced_into_BigDecimal(rb_eArgError, x);
    }
    x = vx->obj;

    n = prec + BIGDECIMAL_DOUBLE_FIGURES;
    negative = BIGDECIMAL_NEGATIVE_P(vx);
    if (negative) {
        VALUE x_zero = INT2NUM(1);
        VALUE x_copy = f_BigDecimal(1, &x_zero, klass);
        x = BigDecimal_initialize_copy(x_copy, x);
        vx = DATA_PTR(x);
	VpSetSign(vx, 1);
    }

    one = VpCheckGetValue(NewOneWrapLimited(1, 1));
    y   = one;
    d   = y;
    i   = 1;

    while (!VpIsZero((Real*)DATA_PTR(d))) {
	SIGNED_VALUE const ey = VpExponent10(DATA_PTR(y));
	SIGNED_VALUE const ed = VpExponent10(DATA_PTR(d));
	ssize_t m = n - vabs(ey - ed);

	rb_thread_check_ints();

	if (m <= 0) {
	    break;
	}
	else if ((size_t)m < BIGDECIMAL_DOUBLE_FIGURES) {
	    m = BIGDECIMAL_DOUBLE_FIGURES;
	}

	d = BigDecimal_mult(d, x);                             /* d <- d * x */
	d = BigDecimal_div2(d, SSIZET2NUM(i), SSIZET2NUM(m));  /* d <- d / i */
	y = BigDecimal_add(y, d);                              /* y <- y + d  */
	++i;                                                   /* i  <- i + 1 */
    }

    if (negative) {
	return BigDecimal_div2(one, y, vprec);
    }
    else {
	vprec = SSIZET2NUM(prec - VpExponent10(DATA_PTR(y)));
	return BigDecimal_round(1, &vprec, y);
    }

    RB_GC_GUARD(one);
    RB_GC_GUARD(x);
    RB_GC_GUARD(y);
    RB_GC_GUARD(d);
}

/* call-seq:
 *   BigMath.log(decimal, numeric)    -> BigDecimal
 *
 * Computes the natural logarithm of +decimal+ to the specified number of
 * digits of precision, +numeric+.
 *
 * If +decimal+ is zero or negative, raises Math::DomainError.
 *
 * If +decimal+ is positive infinity, returns Infinity.
 *
 * If +decimal+ is NaN, returns NaN.
 */
static VALUE
BigMath_s_log(VALUE klass, VALUE x, VALUE vprec)
{
    ssize_t prec, n, i;
    SIGNED_VALUE expo;
    Real* vx = NULL;
    VALUE vn, one, two, w, x2, y, d;
    int zero = 0;
    int negative = 0;
    int infinite = 0;
    int nan = 0;
    double flo;
    long fix;

    if (!is_integer(vprec)) {
	rb_raise(rb_eArgError, "precision must be an Integer");
    }

    prec = NUM2SSIZET(vprec);
    if (prec <= 0) {
	rb_raise(rb_eArgError, "Zero or negative precision for exp");
    }

    /* TODO: the following switch statement is almost same as one in the
     *       BigDecimalCmp function. */
    switch (TYPE(x)) {
      case T_DATA:
	  if (!is_kind_of_BigDecimal(x)) break;
	  vx = DATA_PTR(x);
	  zero = VpIsZero(vx);
	  negative = BIGDECIMAL_NEGATIVE_P(vx);
	  infinite = VpIsPosInf(vx) || VpIsNegInf(vx);
	  nan = VpIsNaN(vx);
	  break;

      case T_FIXNUM:
	fix = FIX2LONG(x);
	zero = fix == 0;
	negative = fix < 0;
	goto get_vp_value;

      case T_BIGNUM:
        i = FIX2INT(rb_big_cmp(x, INT2FIX(0)));
	zero = i == 0;
	negative = i < 0;
get_vp_value:
	if (zero || negative) break;
	vx = GetVpValue(x, 0);
	break;

      case T_FLOAT:
	flo = RFLOAT_VALUE(x);
	zero = flo == 0;
	negative = flo < 0;
	infinite = isinf(flo);
	nan = isnan(flo);
	if (!zero && !negative && !infinite && !nan) {
	    vx = GetVpValueWithPrec(x, 0, 1);
	}
	break;

      case T_RATIONAL:
	zero = RRATIONAL_ZERO_P(x);
	negative = RRATIONAL_NEGATIVE_P(x);
	if (zero || negative) break;
	vx = GetVpValueWithPrec(x, prec, 1);
	break;

      case T_COMPLEX:
	rb_raise(rb_eMathDomainError,
		 "Complex argument for BigMath.log");

      default:
	break;
    }
    if (infinite && !negative) {
        Real *vy = NewZeroWrapNolimit(1, prec);
	RB_GC_GUARD(vy->obj);
	VpSetInf(vy, VP_SIGN_POSITIVE_INFINITE);
        return VpCheckGetValue(vy);
    }
    else if (nan) {
	Real* vy = NewZeroWrapNolimit(1, prec);
	RB_GC_GUARD(vy->obj);
	VpSetNaN(vy);
        return VpCheckGetValue(vy);
    }
    else if (zero || negative) {
	rb_raise(rb_eMathDomainError,
		 "Zero or negative argument for log");
    }
    else if (vx == NULL) {
	cannot_be_coerced_into_BigDecimal(rb_eArgError, x);
    }
    x = VpCheckGetValue(vx);

    one = VpCheckGetValue(NewOneWrapLimited(1, 1));
    two = VpCheckGetValue(VpCreateRbObject(1, "2", true));

    n = prec + BIGDECIMAL_DOUBLE_FIGURES;
    vn = SSIZET2NUM(n);
    expo = VpExponent10(vx);
    if (expo < 0 || expo >= 3) {
	char buf[DECIMAL_SIZE_OF_BITS(SIZEOF_VALUE * CHAR_BIT) + 4];
	snprintf(buf, sizeof(buf), "1E%"PRIdVALUE, -expo);
        x = BigDecimal_mult2(x, VpCheckGetValue(VpCreateRbObject(1, buf, true)), vn);
    }
    else {
	expo = 0;
    }
    w = BigDecimal_sub(x, one);
    x = BigDecimal_div2(w, BigDecimal_add(x, one), vn);
    x2 = BigDecimal_mult2(x, x, vn);
    y = x;
    d = y;
    i = 1;
    while (!VpIsZero((Real*)DATA_PTR(d))) {
	SIGNED_VALUE const ey = VpExponent10(DATA_PTR(y));
	SIGNED_VALUE const ed = VpExponent10(DATA_PTR(d));
	ssize_t m = n - vabs(ey - ed);
	if (m <= 0) {
	    break;
	}
	else if ((size_t)m < BIGDECIMAL_DOUBLE_FIGURES) {
	    m = BIGDECIMAL_DOUBLE_FIGURES;
	}

	x = BigDecimal_mult2(x2, x, vn);
	i += 2;
	d = BigDecimal_div2(x, SSIZET2NUM(i), SSIZET2NUM(m));
	y = BigDecimal_add(y, d);
    }

    y = BigDecimal_mult(y, two);
    if (expo != 0) {
	VALUE log10, vexpo, dy;
	log10 = BigMath_s_log(klass, INT2FIX(10), vprec);
        vexpo = VpCheckGetValue(GetVpValue(SSIZET2NUM(expo), 1));
	dy = BigDecimal_mult(log10, vexpo);
	y = BigDecimal_add(y, dy);
    }

    RB_GC_GUARD(one);
    RB_GC_GUARD(two);
    RB_GC_GUARD(vn);
    RB_GC_GUARD(x2);
    RB_GC_GUARD(y);
    RB_GC_GUARD(d);

    return y;
}

static VALUE BIGDECIMAL_NAN = Qnil;

static VALUE
BigDecimal_nan(void)
{
    return BIGDECIMAL_NAN;
}

static VALUE BIGDECIMAL_POSITIVE_INFINITY = Qnil;

static VALUE
BigDecimal_positive_infinity(void)
{
    return BIGDECIMAL_POSITIVE_INFINITY;
}

static VALUE BIGDECIMAL_NEGATIVE_INFINITY = Qnil;

static VALUE
BigDecimal_negative_infinity(void)
{
    return BIGDECIMAL_NEGATIVE_INFINITY;
}

static VALUE BIGDECIMAL_POSITIVE_ZERO = Qnil;

static VALUE
BigDecimal_positive_zero(void)
{
    return BIGDECIMAL_POSITIVE_ZERO;
}

static VALUE BIGDECIMAL_NEGATIVE_ZERO = Qnil;

static VALUE
BigDecimal_negative_zero(void)
{
    return BIGDECIMAL_NEGATIVE_ZERO;
}

static inline VALUE
BigDecimal_literal(const char *str)
{
    VALUE arg = rb_str_new_cstr(str);
    VALUE val = f_BigDecimal(1, &arg, rb_cBigDecimal);
    rb_gc_register_mark_object(val);
    return val;
}

#define BIGDECIMAL_LITERAL(var, val) (BIGDECIMAL_ ## var = BigDecimal_literal(#val))

/* Document-class: BigDecimal
 * BigDecimal provides arbitrary-precision floating point decimal arithmetic.
 *
 * == Introduction
 *
 * Ruby provides built-in support for arbitrary precision integer arithmetic.
 *
 * For example:
 *
 *	42**13  #=>   1265437718438866624512
 *
 * BigDecimal provides similar support for very large or very accurate floating
 * point numbers.
 *
 * Decimal arithmetic is also useful for general calculation, because it
 * provides the correct answers people expect--whereas normal binary floating
 * point arithmetic often introduces subtle errors because of the conversion
 * between base 10 and base 2.
 *
 * For example, try:
 *
 *   sum = 0
 *   10_000.times do
 *     sum = sum + 0.0001
 *   end
 *   print sum #=> 0.9999999999999062
 *
 * and contrast with the output from:
 *
 *   require 'bigdecimal'
 *
 *   sum = BigDecimal("0")
 *   10_000.times do
 *     sum = sum + BigDecimal("0.0001")
 *   end
 *   print sum #=> 0.1E1
 *
 * Similarly:
 *
 *	(BigDecimal("1.2") - BigDecimal("1.0")) == BigDecimal("0.2") #=> true
 *
 *	(1.2 - 1.0) == 0.2 #=> false
 *
 * == A Note About Precision
 *
 * For a calculation using a \BigDecimal and another +value+,
 * the precision of the result depends on the type of +value+:
 *
 * - If +value+ is a \Float,
 *   the precision is Float::DIG + 1.
 * - If +value+ is a \Rational, the precision is larger than Float::DIG + 1.
 * - If +value+ is a \BigDecimal, the precision is +value+'s precision in the
 *   internal representation, which is platform-dependent.
 * - If +value+ is other object, the precision is determined by the result of +BigDecimal(value)+.
 *
 * == Special features of accurate decimal arithmetic
 *
 * Because BigDecimal is more accurate than normal binary floating point
 * arithmetic, it requires some special values.
 *
 * === Infinity
 *
 * BigDecimal sometimes needs to return infinity, for example if you divide
 * a value by zero.
 *
 *	BigDecimal("1.0") / BigDecimal("0.0")  #=> Infinity
 *	BigDecimal("-1.0") / BigDecimal("0.0")  #=> -Infinity
 *
 * You can represent infinite numbers to BigDecimal using the strings
 * <code>'Infinity'</code>, <code>'+Infinity'</code> and
 * <code>'-Infinity'</code> (case-sensitive)
 *
 * === Not a Number
 *
 * When a computation results in an undefined value, the special value +NaN+
 * (for 'not a number') is returned.
 *
 * Example:
 *
 *	BigDecimal("0.0") / BigDecimal("0.0") #=> NaN
 *
 * You can also create undefined values.
 *
 * NaN is never considered to be the same as any other value, even NaN itself:
 *
 *	n = BigDecimal('NaN')
 *	n == 0.0 #=> false
 *	n == n #=> false
 *
 * === Positive and negative zero
 *
 * If a computation results in a value which is too small to be represented as
 * a BigDecimal within the currently specified limits of precision, zero must
 * be returned.
 *
 * If the value which is too small to be represented is negative, a BigDecimal
 * value of negative zero is returned.
 *
 *	BigDecimal("1.0") / BigDecimal("-Infinity") #=> -0.0
 *
 * If the value is positive, a value of positive zero is returned.
 *
 *	BigDecimal("1.0") / BigDecimal("Infinity") #=> 0.0
 *
 * (See BigDecimal.mode for how to specify limits of precision.)
 *
 * Note that +-0.0+ and +0.0+ are considered to be the same for the purposes of
 * comparison.
 *
 * Note also that in mathematics, there is no particular concept of negative
 * or positive zero; true mathematical zero has no sign.
 *
 * == bigdecimal/util
 *
 * When you require +bigdecimal/util+, the #to_d method will be
 * available on BigDecimal and the native Integer, Float, Rational,
 * and String classes:
 *
 *	require 'bigdecimal/util'
 *
 *      42.to_d         # => 0.42e2
 *      0.5.to_d        # => 0.5e0
 *      (2/3r).to_d(3)  # => 0.667e0
 *      "0.5".to_d      # => 0.5e0
 *
 * == Methods for Working with \JSON
 *
 * - {::json_create}[https://docs.ruby-lang.org/en/master/BigDecimal.html#method-c-json_create]:
 *   Returns a new \BigDecimal object constructed from the given object.
 * - {#as_json}[https://docs.ruby-lang.org/en/master/BigDecimal.html#method-i-as_json]:
 *   Returns a 2-element hash representing +self+.
 * - {#to_json}[https://docs.ruby-lang.org/en/master/BigDecimal.html#method-i-to_json]:
 *   Returns a \JSON string representing +self+.
 *
 * These methods are provided by the {JSON gem}[https://github.com/flori/json]. To make these methods available:
 *
 *   require 'json/add/bigdecimal'
 *
 * * == License
 *
 * Copyright (C) 2002 by Shigeo Kobayashi <shigeo@tinyforest.gr.jp>.
 *
 * BigDecimal is released under the Ruby and 2-clause BSD licenses.
 * See LICENSE.txt for details.
 *
 * Maintained by mrkn <mrkn@mrkn.jp> and ruby-core members.
 *
 * Documented by zzak <zachary@zacharyscott.net>, mathew <meta@pobox.com>, and
 * many other contributors.
 */
void
Init_bigdecimal(void)
{
#ifdef HAVE_RB_EXT_RACTOR_SAFE
    rb_ext_ractor_safe(true);
#endif

    id_BigDecimal_exception_mode = rb_intern_const("BigDecimal.exception_mode");
    id_BigDecimal_rounding_mode = rb_intern_const("BigDecimal.rounding_mode");
    id_BigDecimal_precision_limit = rb_intern_const("BigDecimal.precision_limit");

    /* Initialize VP routines */
    VpInit(0UL);

    /* Class and method registration */
    rb_cBigDecimal = rb_define_class("BigDecimal", rb_cNumeric);

    /* Global function */
    rb_define_global_function("BigDecimal", f_BigDecimal, -1);

    /* Class methods */
    rb_undef_alloc_func(rb_cBigDecimal);
    rb_undef_method(CLASS_OF(rb_cBigDecimal), "new");
    rb_define_singleton_method(rb_cBigDecimal, "interpret_loosely", BigDecimal_s_interpret_loosely, 1);
    rb_define_singleton_method(rb_cBigDecimal, "mode", BigDecimal_mode, -1);
    rb_define_singleton_method(rb_cBigDecimal, "limit", BigDecimal_limit, -1);
    rb_define_singleton_method(rb_cBigDecimal, "double_fig", BigDecimal_double_fig, 0);
    rb_define_singleton_method(rb_cBigDecimal, "_load", BigDecimal_load, 1);

    rb_define_singleton_method(rb_cBigDecimal, "save_exception_mode", BigDecimal_save_exception_mode, 0);
    rb_define_singleton_method(rb_cBigDecimal, "save_rounding_mode", BigDecimal_save_rounding_mode, 0);
    rb_define_singleton_method(rb_cBigDecimal, "save_limit", BigDecimal_save_limit, 0);

    /* Constants definition */

    /*
     * The version of bigdecimal library
     */
    rb_define_const(rb_cBigDecimal, "VERSION", rb_str_new2(BIGDECIMAL_VERSION));

    /*
     * Base value used in internal calculations.  On a 32 bit system, BASE
     * is 10000, indicating that calculation is done in groups of 4 digits.
     * (If it were larger, BASE**2 wouldn't fit in 32 bits, so you couldn't
     * guarantee that two groups could always be multiplied together without
     * overflow.)
     */
    rb_define_const(rb_cBigDecimal, "BASE", INT2FIX((SIGNED_VALUE)VpBaseVal()));

    /* Exceptions */

    /*
     * 0xff: Determines whether overflow, underflow or zero divide result in
     * an exception being thrown. See BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "EXCEPTION_ALL", INT2FIX(VP_EXCEPTION_ALL));

    /*
     * 0x02: Determines what happens when the result of a computation is not a
     * number (NaN). See BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "EXCEPTION_NaN", INT2FIX(VP_EXCEPTION_NaN));

    /*
     * 0x01: Determines what happens when the result of a computation is
     * infinity.  See BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "EXCEPTION_INFINITY", INT2FIX(VP_EXCEPTION_INFINITY));

    /*
     * 0x04: Determines what happens when the result of a computation is an
     * underflow (a result too small to be represented). See BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "EXCEPTION_UNDERFLOW", INT2FIX(VP_EXCEPTION_UNDERFLOW));

    /*
     * 0x01: Determines what happens when the result of a computation is an
     * overflow (a result too large to be represented). See BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "EXCEPTION_OVERFLOW", INT2FIX(VP_EXCEPTION_OVERFLOW));

    /*
     * 0x10: Determines what happens when a division by zero is performed.
     * See BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "EXCEPTION_ZERODIVIDE", INT2FIX(VP_EXCEPTION_ZERODIVIDE));

    /*
     * 0x100: Determines what happens when a result must be rounded in order to
     * fit in the appropriate number of significant digits. See
     * BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "ROUND_MODE", INT2FIX(VP_ROUND_MODE));

    /* 1: Indicates that values should be rounded away from zero. See
     * BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "ROUND_UP", INT2FIX(VP_ROUND_UP));

    /* 2: Indicates that values should be rounded towards zero. See
     * BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "ROUND_DOWN", INT2FIX(VP_ROUND_DOWN));

    /* 3: Indicates that digits >= 5 should be rounded up, others rounded down.
     * See BigDecimal.mode. */
    rb_define_const(rb_cBigDecimal, "ROUND_HALF_UP", INT2FIX(VP_ROUND_HALF_UP));

    /* 4: Indicates that digits >= 6 should be rounded up, others rounded down.
     * See BigDecimal.mode.
     */
    rb_define_const(rb_cBigDecimal, "ROUND_HALF_DOWN", INT2FIX(VP_ROUND_HALF_DOWN));
    /* 5: Round towards +Infinity. See BigDecimal.mode. */
    rb_define_const(rb_cBigDecimal, "ROUND_CEILING", INT2FIX(VP_ROUND_CEIL));

    /* 6: Round towards -Infinity. See BigDecimal.mode. */
    rb_define_const(rb_cBigDecimal, "ROUND_FLOOR", INT2FIX(VP_ROUND_FLOOR));

    /* 7: Round towards the even neighbor. See BigDecimal.mode. */
    rb_define_const(rb_cBigDecimal, "ROUND_HALF_EVEN", INT2FIX(VP_ROUND_HALF_EVEN));

    /* 0: Indicates that a value is not a number. See BigDecimal.sign. */
    rb_define_const(rb_cBigDecimal, "SIGN_NaN", INT2FIX(VP_SIGN_NaN));

    /* 1: Indicates that a value is +0. See BigDecimal.sign. */
    rb_define_const(rb_cBigDecimal, "SIGN_POSITIVE_ZERO", INT2FIX(VP_SIGN_POSITIVE_ZERO));

    /* -1: Indicates that a value is -0. See BigDecimal.sign. */
    rb_define_const(rb_cBigDecimal, "SIGN_NEGATIVE_ZERO", INT2FIX(VP_SIGN_NEGATIVE_ZERO));

    /* 2: Indicates that a value is positive and finite. See BigDecimal.sign. */
    rb_define_const(rb_cBigDecimal, "SIGN_POSITIVE_FINITE", INT2FIX(VP_SIGN_POSITIVE_FINITE));

    /* -2: Indicates that a value is negative and finite. See BigDecimal.sign. */
    rb_define_const(rb_cBigDecimal, "SIGN_NEGATIVE_FINITE", INT2FIX(VP_SIGN_NEGATIVE_FINITE));

    /* 3: Indicates that a value is positive and infinite. See BigDecimal.sign. */
    rb_define_const(rb_cBigDecimal, "SIGN_POSITIVE_INFINITE", INT2FIX(VP_SIGN_POSITIVE_INFINITE));

    /* -3: Indicates that a value is negative and infinite. See BigDecimal.sign. */
    rb_define_const(rb_cBigDecimal, "SIGN_NEGATIVE_INFINITE", INT2FIX(VP_SIGN_NEGATIVE_INFINITE));

    /* Positive zero value. */
    BIGDECIMAL_LITERAL(POSITIVE_ZERO, +0);

    /* Negative zero value. */
    BIGDECIMAL_LITERAL(NEGATIVE_ZERO, -0);

    /* Positive infinity[rdoc-ref:BigDecimal@Infinity] value. */
    rb_define_const(rb_cBigDecimal, "INFINITY", BIGDECIMAL_LITERAL(POSITIVE_INFINITY, +Infinity));

    /* Negative infinity value. */
    BIGDECIMAL_LITERAL(NEGATIVE_INFINITY, -Infinity);

    /* '{Not a Number}[rdoc-ref:BigDecimal@Not+a+Number]' value. */
    rb_define_const(rb_cBigDecimal, "NAN", BIGDECIMAL_LITERAL(NAN, NaN));

    /* instance methods */
    rb_define_method(rb_cBigDecimal, "precs", BigDecimal_prec, 0);
    rb_define_method(rb_cBigDecimal, "precision", BigDecimal_precision, 0);
    rb_define_method(rb_cBigDecimal, "scale", BigDecimal_scale, 0);
    rb_define_method(rb_cBigDecimal, "precision_scale", BigDecimal_precision_scale, 0);
    rb_define_method(rb_cBigDecimal, "n_significant_digits", BigDecimal_n_significant_digits, 0);

    rb_define_method(rb_cBigDecimal, "add", BigDecimal_add2, 2);
    rb_define_method(rb_cBigDecimal, "sub", BigDecimal_sub2, 2);
    rb_define_method(rb_cBigDecimal, "mult", BigDecimal_mult2, 2);
    rb_define_method(rb_cBigDecimal, "div", BigDecimal_div3, -1);
    rb_define_method(rb_cBigDecimal, "hash", BigDecimal_hash, 0);
    rb_define_method(rb_cBigDecimal, "to_s", BigDecimal_to_s, -1);
    rb_define_method(rb_cBigDecimal, "to_i", BigDecimal_to_i, 0);
    rb_define_method(rb_cBigDecimal, "to_int", BigDecimal_to_i, 0);
    rb_define_method(rb_cBigDecimal, "to_r", BigDecimal_to_r, 0);
    rb_define_method(rb_cBigDecimal, "split", BigDecimal_split, 0);
    rb_define_method(rb_cBigDecimal, "+", BigDecimal_add, 1);
    rb_define_method(rb_cBigDecimal, "-", BigDecimal_sub, 1);
    rb_define_method(rb_cBigDecimal, "+@", BigDecimal_uplus, 0);
    rb_define_method(rb_cBigDecimal, "-@", BigDecimal_neg, 0);
    rb_define_method(rb_cBigDecimal, "*", BigDecimal_mult, 1);
    rb_define_method(rb_cBigDecimal, "/", BigDecimal_div, 1);
    rb_define_method(rb_cBigDecimal, "quo", BigDecimal_quo, -1);
    rb_define_method(rb_cBigDecimal, "%", BigDecimal_mod, 1);
    rb_define_method(rb_cBigDecimal, "modulo", BigDecimal_mod, 1);
    rb_define_method(rb_cBigDecimal, "remainder", BigDecimal_remainder, 1);
    rb_define_method(rb_cBigDecimal, "divmod", BigDecimal_divmod, 1);
    rb_define_method(rb_cBigDecimal, "clone", BigDecimal_clone, 0);
    rb_define_method(rb_cBigDecimal, "dup", BigDecimal_clone, 0);
    rb_define_method(rb_cBigDecimal, "to_f", BigDecimal_to_f, 0);
    rb_define_method(rb_cBigDecimal, "abs", BigDecimal_abs, 0);
    rb_define_method(rb_cBigDecimal, "sqrt", BigDecimal_sqrt, 1);
    rb_define_method(rb_cBigDecimal, "fix", BigDecimal_fix, 0);
    rb_define_method(rb_cBigDecimal, "round", BigDecimal_round, -1);
    rb_define_method(rb_cBigDecimal, "frac", BigDecimal_frac, 0);
    rb_define_method(rb_cBigDecimal, "floor", BigDecimal_floor, -1);
    rb_define_method(rb_cBigDecimal, "ceil", BigDecimal_ceil, -1);
    rb_define_method(rb_cBigDecimal, "power", BigDecimal_power, -1);
    rb_define_method(rb_cBigDecimal, "**", BigDecimal_power_op, 1);
    rb_define_method(rb_cBigDecimal, "<=>", BigDecimal_comp, 1);
    rb_define_method(rb_cBigDecimal, "==", BigDecimal_eq, 1);
    rb_define_method(rb_cBigDecimal, "===", BigDecimal_eq, 1);
    rb_define_method(rb_cBigDecimal, "eql?", BigDecimal_eq, 1);
    rb_define_method(rb_cBigDecimal, "<", BigDecimal_lt, 1);
    rb_define_method(rb_cBigDecimal, "<=", BigDecimal_le, 1);
    rb_define_method(rb_cBigDecimal, ">", BigDecimal_gt, 1);
    rb_define_method(rb_cBigDecimal, ">=", BigDecimal_ge, 1);
    rb_define_method(rb_cBigDecimal, "zero?", BigDecimal_zero, 0);
    rb_define_method(rb_cBigDecimal, "nonzero?", BigDecimal_nonzero, 0);
    rb_define_method(rb_cBigDecimal, "coerce", BigDecimal_coerce, 1);
    rb_define_method(rb_cBigDecimal, "inspect", BigDecimal_inspect, 0);
    rb_define_method(rb_cBigDecimal, "exponent", BigDecimal_exponent, 0);
    rb_define_method(rb_cBigDecimal, "sign", BigDecimal_sign, 0);
    rb_define_method(rb_cBigDecimal, "nan?",      BigDecimal_IsNaN, 0);
    rb_define_method(rb_cBigDecimal, "infinite?", BigDecimal_IsInfinite, 0);
    rb_define_method(rb_cBigDecimal, "finite?",   BigDecimal_IsFinite, 0);
    rb_define_method(rb_cBigDecimal, "truncate",  BigDecimal_truncate, -1);
    rb_define_method(rb_cBigDecimal, "_dump", BigDecimal_dump, -1);

    rb_mBigMath = rb_define_module("BigMath");
    rb_define_singleton_method(rb_mBigMath, "exp", BigMath_s_exp, 2);
    rb_define_singleton_method(rb_mBigMath, "log", BigMath_s_log, 2);

#define ROUNDING_MODE(i, name, value) \
    id_##name = rb_intern_const(#name); \
    rbd_rounding_modes[i].id   = id_##name; \
    rbd_rounding_modes[i].mode = value;

    ROUNDING_MODE(0, up,        RBD_ROUND_UP);
    ROUNDING_MODE(1, down,      RBD_ROUND_DOWN);
    ROUNDING_MODE(2, half_up,   RBD_ROUND_HALF_UP);
    ROUNDING_MODE(3, half_down, RBD_ROUND_HALF_DOWN);
    ROUNDING_MODE(4, ceil,      RBD_ROUND_CEIL);
    ROUNDING_MODE(5, floor,     RBD_ROUND_FLOOR);
    ROUNDING_MODE(6, half_even, RBD_ROUND_HALF_EVEN);

    ROUNDING_MODE(7,  default,   RBD_ROUND_DEFAULT);
    ROUNDING_MODE(8,  truncate,  RBD_ROUND_TRUNCATE);
    ROUNDING_MODE(9,  banker,    RBD_ROUND_BANKER);
    ROUNDING_MODE(10, ceiling,   RBD_ROUND_CEILING);

#undef ROUNDING_MODE

    id_to_r = rb_intern_const("to_r");
    id_eq = rb_intern_const("==");
    id_half = rb_intern_const("half");

    (void)VPrint;  /* suppress unused warning */
}

/*
 *
 *  ============================================================================
 *
 *  vp_ routines begin from here.
 *
 *  ============================================================================
 *
 */
#ifdef BIGDECIMAL_DEBUG
static int gfDebug = 1;         /* Debug switch */
#if 0
static int gfCheckVal = 1;      /* Value checking flag in VpNmlz()  */
#endif
#endif /* BIGDECIMAL_DEBUG */

static Real *VpConstOne;    /* constant 1.0 */
static Real *VpConstPt5;    /* constant 0.5 */
#define maxnr 100UL    /* Maximum iterations for calculating sqrt. */
                /* used in VpSqrt() */

/* ETC */
#define MemCmp(x,y,z) memcmp(x,y,z)
#define StrCmp(x,y)   strcmp(x,y)

enum op_sw {
    OP_SW_ADD = 1,  /* + */
    OP_SW_SUB,      /* - */
    OP_SW_MULT,     /* * */
    OP_SW_DIV       /* / */
};

static int VpIsDefOP(Real *c, Real *a, Real *b, enum op_sw sw);
static int AddExponent(Real *a, SIGNED_VALUE n);
static DECDIG VpAddAbs(Real *a,Real *b,Real *c);
static DECDIG VpSubAbs(Real *a,Real *b,Real *c);
static size_t VpSetPTR(Real *a, Real *b, Real *c, size_t *a_pos, size_t *b_pos, size_t *c_pos, DECDIG *av, DECDIG *bv);
static int VpNmlz(Real *a);
static void VpFormatSt(char *psz, size_t fFmt);
static int VpRdup(Real *m, size_t ind_m);

#ifdef BIGDECIMAL_DEBUG
# ifdef HAVE_RB_EXT_RACTOR_SAFE
#  error Need to make rewiting gnAlloc atomic
# endif
static int gnAlloc = 0; /* Memory allocation counter */
#endif /* BIGDECIMAL_DEBUG */

/*
 * EXCEPTION Handling.
 */

#define bigdecimal_set_thread_local_exception_mode(mode) \
    rb_thread_local_aset( \
	rb_thread_current(), \
	id_BigDecimal_exception_mode, \
	INT2FIX((int)(mode)) \
    )

static unsigned short
VpGetException (void)
{
    VALUE const vmode = rb_thread_local_aref(
	rb_thread_current(),
	id_BigDecimal_exception_mode
    );

    if (NIL_P(vmode)) {
	bigdecimal_set_thread_local_exception_mode(BIGDECIMAL_EXCEPTION_MODE_DEFAULT);
	return BIGDECIMAL_EXCEPTION_MODE_DEFAULT;
    }

    return NUM2USHORT(vmode);
}

static void
VpSetException(unsigned short f)
{
    bigdecimal_set_thread_local_exception_mode(f);
}

static void
VpCheckException(Real *p, bool always)
{
    if (VpIsNaN(p)) {
        VpException(VP_EXCEPTION_NaN, "Computation results in 'NaN' (Not a Number)", always);
    }
    else if (VpIsPosInf(p)) {
        VpException(VP_EXCEPTION_INFINITY, "Computation results in 'Infinity'", always);
    }
    else if (VpIsNegInf(p)) {
        VpException(VP_EXCEPTION_INFINITY, "Computation results in '-Infinity'", always);
    }
}

static VALUE
VpCheckGetValue(Real *p)
{
    VpCheckException(p, false);
    return p->obj;
}

/*
 * Precision limit.
 */

#define bigdecimal_set_thread_local_precision_limit(limit) \
    rb_thread_local_aset( \
	rb_thread_current(), \
	id_BigDecimal_precision_limit, \
	SIZET2NUM(limit) \
    )
#define BIGDECIMAL_PRECISION_LIMIT_DEFAULT ((size_t)0)

/* These 2 functions added at v1.1.7 */
VP_EXPORT size_t
VpGetPrecLimit(void)
{
    VALUE const vlimit = rb_thread_local_aref(
	rb_thread_current(),
	id_BigDecimal_precision_limit
    );

    if (NIL_P(vlimit)) {
	bigdecimal_set_thread_local_precision_limit(BIGDECIMAL_PRECISION_LIMIT_DEFAULT);
	return BIGDECIMAL_PRECISION_LIMIT_DEFAULT;
    }

    return NUM2SIZET(vlimit);
}

VP_EXPORT size_t
VpSetPrecLimit(size_t n)
{
    size_t const s = VpGetPrecLimit();
    bigdecimal_set_thread_local_precision_limit(n);
    return s;
}

/*
 * Rounding mode.
 */

#define bigdecimal_set_thread_local_rounding_mode(mode) \
    rb_thread_local_aset( \
	rb_thread_current(), \
	id_BigDecimal_rounding_mode, \
	INT2FIX((int)(mode)) \
    )

VP_EXPORT unsigned short
VpGetRoundMode(void)
{
    VALUE const vmode = rb_thread_local_aref(
	rb_thread_current(),
	id_BigDecimal_rounding_mode
    );

    if (NIL_P(vmode)) {
	bigdecimal_set_thread_local_rounding_mode(BIGDECIMAL_ROUNDING_MODE_DEFAULT);
	return BIGDECIMAL_ROUNDING_MODE_DEFAULT;
    }

    return NUM2USHORT(vmode);
}

VP_EXPORT int
VpIsRoundMode(unsigned short n)
{
    switch (n) {
      case VP_ROUND_UP:
      case VP_ROUND_DOWN:
      case VP_ROUND_HALF_UP:
      case VP_ROUND_HALF_DOWN:
      case VP_ROUND_CEIL:
      case VP_ROUND_FLOOR:
      case VP_ROUND_HALF_EVEN:
	return 1;

      default:
	return 0;
    }
}

VP_EXPORT unsigned short
VpSetRoundMode(unsigned short n)
{
    if (VpIsRoundMode(n)) {
	bigdecimal_set_thread_local_rounding_mode(n);
	return n;
    }

    return VpGetRoundMode();
}

/*
 *  0.0 & 1.0 generator
 *    These gZero_..... and gOne_..... can be any name
 *    referenced from nowhere except Zero() and One().
 *    gZero_..... and gOne_..... must have global scope
 *    (to let the compiler know they may be changed in outside
 *    (... but not actually..)).
 */
volatile const double gOne_ABCED9B4_CE73__00400511F31D  = 1.0;

static double
One(void)
{
    return gOne_ABCED9B4_CE73__00400511F31D;
}

/*
  ----------------------------------------------------------------
  Value of sign in Real structure is reserved for future use.
  short sign;
                    ==0 : NaN
                      1 : Positive zero
                     -1 : Negative zero
                      2 : Positive number
                     -2 : Negative number
                      3 : Positive infinite number
                     -3 : Negative infinite number
  ----------------------------------------------------------------
*/

VP_EXPORT double
VpGetDoubleNaN(void) /* Returns the value of NaN */
{
    return nan("");
}

VP_EXPORT double
VpGetDoublePosInf(void) /* Returns the value of +Infinity */
{
    return HUGE_VAL;
}

VP_EXPORT double
VpGetDoubleNegInf(void) /* Returns the value of -Infinity */
{
    return -HUGE_VAL;
}

VP_EXPORT double
VpGetDoubleNegZero(void) /* Returns the value of -0 */
{
    static double nzero = 1000.0;
    if (nzero != 0.0) nzero = (One()/VpGetDoubleNegInf());
    return nzero;
}

#if 0  /* unused */
VP_EXPORT int
VpIsNegDoubleZero(double v)
{
    double z = VpGetDoubleNegZero();
    return MemCmp(&v,&z,sizeof(v))==0;
}
#endif

VP_EXPORT int
VpException(unsigned short f, const char *str,int always)
{
    unsigned short const exception_mode = VpGetException();

    if (f == VP_EXCEPTION_OP) always = 1;

    if (always || (exception_mode & f)) {
	switch(f) {
	  /* case VP_EXCEPTION_OVERFLOW: */
	  case VP_EXCEPTION_ZERODIVIDE:
	  case VP_EXCEPTION_INFINITY:
	  case VP_EXCEPTION_NaN:
	  case VP_EXCEPTION_UNDERFLOW:
	  case VP_EXCEPTION_OP:
	    rb_raise(rb_eFloatDomainError, "%s", str);
	    break;
	  default:
	    rb_fatal("%s", str);
	}
    }
    return 0; /* 0 Means VpException() raised no exception */
}

/* Throw exception or returns 0,when resulting c is Inf or NaN */
/*  sw=1:+ 2:- 3:* 4:/ */
static int
VpIsDefOP(Real *c, Real *a, Real *b, enum op_sw sw)
{
    if (VpIsNaN(a) || VpIsNaN(b)) {
	/* at least a or b is NaN */
	VpSetNaN(c);
	goto NaN;
    }

    if (VpIsInf(a)) {
	if (VpIsInf(b)) {
	    switch(sw) {
	      case OP_SW_ADD: /* + */
		if (VpGetSign(a) == VpGetSign(b)) {
		    VpSetInf(c, VpGetSign(a));
		    goto Inf;
		}
		else {
		    VpSetNaN(c);
		    goto NaN;
		}
	      case OP_SW_SUB: /* - */
		if (VpGetSign(a) != VpGetSign(b)) {
		    VpSetInf(c, VpGetSign(a));
		    goto Inf;
		}
		else {
		    VpSetNaN(c);
		    goto NaN;
		}
	      case OP_SW_MULT: /* * */
		VpSetInf(c, VpGetSign(a)*VpGetSign(b));
		goto Inf;
	      case OP_SW_DIV: /* / */
		VpSetNaN(c);
		goto NaN;
	    }
	    VpSetNaN(c);
	    goto NaN;
	}
	/* Inf op Finite */
	switch(sw) {
	  case OP_SW_ADD: /* + */
	  case OP_SW_SUB: /* - */
	    VpSetInf(c, VpGetSign(a));
	    break;
	  case OP_SW_MULT: /* * */
	    if (VpIsZero(b)) {
		VpSetNaN(c);
		goto NaN;
	    }
	    VpSetInf(c, VpGetSign(a)*VpGetSign(b));
	    break;
	  case OP_SW_DIV: /* / */
	    VpSetInf(c, VpGetSign(a)*VpGetSign(b));
	}
	goto Inf;
    }

    if (VpIsInf(b)) {
	switch(sw) {
	  case OP_SW_ADD: /* + */
	    VpSetInf(c, VpGetSign(b));
	    break;
	  case OP_SW_SUB: /* - */
	    VpSetInf(c, -VpGetSign(b));
	    break;
	  case OP_SW_MULT: /* * */
	    if (VpIsZero(a)) {
		VpSetNaN(c);
		goto NaN;
	    }
	    VpSetInf(c, VpGetSign(a)*VpGetSign(b));
	    break;
	  case OP_SW_DIV: /* / */
	    VpSetZero(c, VpGetSign(a)*VpGetSign(b));
	}
	goto Inf;
    }
    return 1; /* Results OK */

Inf:
    if (VpIsPosInf(c)) {
	return VpException(VP_EXCEPTION_INFINITY, "Computation results to 'Infinity'", 0);
    }
    else {
	return VpException(VP_EXCEPTION_INFINITY, "Computation results to '-Infinity'", 0);
    }

NaN:
    return VpException(VP_EXCEPTION_NaN, "Computation results to 'NaN'", 0);
}

/*
  ----------------------------------------------------------------
*/

/*
 *    returns number of chars needed to represent vp in specified format.
 */
VP_EXPORT size_t
VpNumOfChars(Real *vp,const char *pszFmt)
{
    SIGNED_VALUE  ex;
    size_t nc;

    if (vp == NULL)   return BASE_FIG*2+6;
    if (!VpIsDef(vp)) return 32; /* not sure,may be OK */

    switch(*pszFmt) {
      case 'F':
	nc = BASE_FIG*(vp->Prec + 1)+2;
	ex = vp->exponent;
	if (ex < 0) {
	    nc += BASE_FIG*(size_t)(-ex);
	}
	else {
	    if ((size_t)ex > vp->Prec) {
		nc += BASE_FIG*((size_t)ex - vp->Prec);
	    }
	}
	break;
      case 'E':
	/* fall through */
      default:
	nc = BASE_FIG*(vp->Prec + 2)+6; /* 3: sign + exponent chars */
    }
    return nc;
}

/*
 * Initializer for Vp routines and constants used.
 * [Input]
 *   BaseVal: Base value(assigned to BASE) for Vp calculation.
 *   It must be the form BaseVal=10**n.(n=1,2,3,...)
 *   If Base <= 0L,then the BASE will be calculated so
 *   that BASE is as large as possible satisfying the
 *   relation MaxVal <= BASE*(BASE+1). Where the value
 *   MaxVal is the largest value which can be represented
 *   by one DECDIG word in the computer used.
 *
 * [Returns]
 *   BIGDECIMAL_DOUBLE_FIGURES  ... OK
 */
VP_EXPORT size_t
VpInit(DECDIG BaseVal)
{
    /* Setup +/- Inf  NaN -0 */
    VpGetDoubleNegZero();

    /* Const 1.0 */
    VpConstOne = NewOneNolimit(1, 1);

    /* Const 0.5 */
    VpConstPt5 = NewOneNolimit(1, 1);
    VpConstPt5->exponent = 0;
    VpConstPt5->frac[0] = 5*BASE1;

#ifdef BIGDECIMAL_DEBUG
    gnAlloc = 0;
#endif /* BIGDECIMAL_DEBUG */

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
        printf("VpInit: BaseVal = %"PRIuDECDIG"\n", BaseVal);
        printf("\tBASE      = %"PRIuDECDIG"\n", BASE);
        printf("\tHALF_BASE = %"PRIuDECDIG"\n", HALF_BASE);
        printf("\tBASE1     = %"PRIuDECDIG"\n", BASE1);
        printf("\tBASE_FIG  = %u\n", BASE_FIG);
        printf("\tBIGDECIMAL_DOUBLE_FIGURES = %d\n", BIGDECIMAL_DOUBLE_FIGURES);
    }
#endif /* BIGDECIMAL_DEBUG */

    return BIGDECIMAL_DOUBLE_FIGURES;
}

VP_EXPORT Real *
VpOne(void)
{
    return VpConstOne;
}

/* If exponent overflows,then raise exception or returns 0 */
static int
AddExponent(Real *a, SIGNED_VALUE n)
{
    SIGNED_VALUE e = a->exponent;
    SIGNED_VALUE m = e+n;
    SIGNED_VALUE eb, mb;
    if (e > 0) {
	if (n > 0) {
            if (MUL_OVERFLOW_SIGNED_VALUE_P(m, (SIGNED_VALUE)BASE_FIG) ||
                MUL_OVERFLOW_SIGNED_VALUE_P(e, (SIGNED_VALUE)BASE_FIG))
                goto overflow;
	    mb = m*(SIGNED_VALUE)BASE_FIG;
	    eb = e*(SIGNED_VALUE)BASE_FIG;
	    if (eb - mb > 0) goto overflow;
	}
    }
    else if (n < 0) {
        if (MUL_OVERFLOW_SIGNED_VALUE_P(m, (SIGNED_VALUE)BASE_FIG) ||
            MUL_OVERFLOW_SIGNED_VALUE_P(e, (SIGNED_VALUE)BASE_FIG))
            goto underflow;
	mb = m*(SIGNED_VALUE)BASE_FIG;
	eb = e*(SIGNED_VALUE)BASE_FIG;
	if (mb - eb > 0) goto underflow;
    }
    a->exponent = m;
    return 1;

/* Overflow/Underflow ==> Raise exception or returns 0 */
underflow:
    VpSetZero(a, VpGetSign(a));
    return VpException(VP_EXCEPTION_UNDERFLOW, "Exponent underflow", 0);

overflow:
    VpSetInf(a, VpGetSign(a));
    return VpException(VP_EXCEPTION_OVERFLOW, "Exponent overflow", 0);
}

Real *
bigdecimal_parse_special_string(const char *str)
{
    static const struct {
        const char *str;
        size_t len;
        int sign;
    } table[] = {
        { SZ_INF,  sizeof(SZ_INF)  - 1, VP_SIGN_POSITIVE_INFINITE },
        { SZ_PINF, sizeof(SZ_PINF) - 1, VP_SIGN_POSITIVE_INFINITE },
        { SZ_NINF, sizeof(SZ_NINF) - 1, VP_SIGN_NEGATIVE_INFINITE },
        { SZ_NaN,  sizeof(SZ_NaN)  - 1, VP_SIGN_NaN               }
    };
    static const size_t table_length = sizeof(table) / sizeof(table[0]);
    size_t i;

    for (i = 0; i < table_length; ++i) {
        const char *p;
        if (strncmp(str, table[i].str, table[i].len) != 0) {
            continue;
        }

        p = str + table[i].len;
        while (*p && ISSPACE(*p)) ++p;
        if (*p == '\0') {
            Real *vp = rbd_allocate_struct(1);
            vp->MaxPrec = 1;
            switch (table[i].sign) {
              default:
                UNREACHABLE; break;
              case VP_SIGN_POSITIVE_INFINITE:
                VpSetPosInf(vp);
                return vp;
              case VP_SIGN_NEGATIVE_INFINITE:
                VpSetNegInf(vp);
                return vp;
              case VP_SIGN_NaN:
                VpSetNaN(vp);
                return vp;
            }
        }
    }

    return NULL;
}

struct VpCtoV_args {
  Real *a;
  const char *int_chr;
  size_t ni;
  const char *frac;
  size_t nf;
  const char *exp_chr;
  size_t ne;
};

static VALUE
call_VpCtoV(VALUE arg)
{
  struct VpCtoV_args *x = (struct VpCtoV_args *)arg;
  return (VALUE)VpCtoV(x->a, x->int_chr, x->ni, x->frac, x->nf, x->exp_chr, x->ne);
}

static int
protected_VpCtoV(Real *a, const char *int_chr, size_t ni, const char *frac, size_t nf, const char *exp_chr, size_t ne, int free_on_error)
{
  struct VpCtoV_args args;
  int state = 0;

  args.a = a;
  args.int_chr = int_chr;
  args.ni = ni;
  args.frac = frac;
  args.nf = nf;
  args.exp_chr = exp_chr;
  args.ne = ne;

  VALUE result = rb_protect(call_VpCtoV, (VALUE)&args, &state);
  if (state) {
    if (free_on_error) {
      rbd_free_struct(a);
    }
    rb_jump_tag(state);
  }

  return (int)result;
}

/*
 * Allocates variable.
 * [Input]
 *   mx ... The number of decimal digits to be allocated, if zero then mx is determined by szVal.
 *          The mx will be the number of significant digits can to be stored.
 *   szVal ... The value assigned(char). If szVal==NULL, then zero is assumed.
 *             If szVal[0]=='#' then MaxPrec is not affected by the precision limit
 *             so that the full precision specified by szVal is allocated.
 *
 * [Returns]
 *   Pointer to the newly allocated variable, or
 *   NULL be returned if memory allocation is failed,or any error.
 */
VP_EXPORT Real *
VpAlloc(size_t mx, const char *szVal, int strict_p, int exc)
{
    const char *orig_szVal = szVal;
    size_t i, j, ni, ipf, nf, ipe, ne, exp_seen, nalloc;
    size_t len;
    char v, *psz;
    int  sign=1;
    Real *vp = NULL;
    VALUE buf;

    if (szVal == NULL) {
      return_zero:
        /* necessary to be able to store */
        /* at least mx digits. */
        /* szVal==NULL ==> allocate zero value. */
        vp = rbd_allocate_struct(mx);
        vp->MaxPrec = rbd_calculate_internal_digits(mx, false);  /* Must false */
        VpSetZero(vp, 1);    /* initialize vp to zero. */
        return vp;
    }

    /* Skipping leading spaces */
    while (ISSPACE(*szVal)) szVal++;

    /* Check on Inf & NaN */
    if ((vp = bigdecimal_parse_special_string(szVal)) != NULL) {
        return vp;
    }

    /* Processing the leading one `#` */
    if (*szVal != '#') {
        len = rbd_calculate_internal_digits(mx, true);
    }
    else {
        len = rbd_calculate_internal_digits(mx, false);
        ++szVal;
    }

    /* Scanning digits */

    /* A buffer for keeping scanned digits */
    buf = rb_str_tmp_new(strlen(szVal) + 1);
    psz = RSTRING_PTR(buf);

    /* cursor: i for psz, and j for szVal */
    i = j = 0;

    /* Scanning: sign part */
    v = psz[i] = szVal[j];
    if ((v == '-') || (v == '+')) {
        sign = -(v == '-');
        ++i;
        ++j;
    }

    /* Scanning: integer part */
    ni  = 0; /* number of digits in the integer part */
    while ((v = psz[i] = szVal[j]) != '\0') {
        if (!strict_p && ISSPACE(v)) {
            v = psz[i] = '\0';
            break;
        }
        if (v == '_') {
            if (ni > 0) {
                v = szVal[j+1];
                if (v == '\0' || ISSPACE(v) || ISDIGIT(v)) {
                    ++j;
                    continue;
                }
                if (!strict_p) {
                    v = psz[i] = '\0';
                    break;
                }
            }
            goto invalid_value;
        }
        if (!ISDIGIT(v)) {
            break;
        }
        ++ni;
        ++i;
        ++j;
    }

    /* Scanning: fractional part */
    nf  = 0; /* number of digits in the fractional part */
    ne  = 0; /* number of digits in the exponential part */
    ipf = 0; /* index of the beginning of the fractional part */
    ipe = 0; /* index of the beginning of the exponential part */
    exp_seen = 0;

    if (v != '\0') {
        /* Scanning fractional part */
        if ((psz[i] = szVal[j]) == '.') {
            ++i;
            ++j;
            ipf = i;
            while ((v = psz[i] = szVal[j]) != '\0') {
                if (!strict_p && ISSPACE(v)) {
                    v = psz[i] = '\0';
                    break;
                }
                if (v == '_') {
                    if (nf > 0 && ISDIGIT(szVal[j+1])) {
                        ++j;
                        continue;
                    }
                    if (!strict_p) {
                        v = psz[i] = '\0';
                        break;
                    }
                    goto invalid_value;
                }
                if (!ISDIGIT(v)) break;
                ++i;
                ++j;
                ++nf;
            }
        }

        /* Scanning exponential part */
        if (v != '\0') {
            switch ((psz[i] = szVal[j])) {
                case '\0':
                    break;
                case 'e': case 'E':
                case 'd': case 'D':
                    exp_seen = 1;
                    ++i;
                    ++j;
                    ipe = i;
                    v = psz[i] = szVal[j];
                    if ((v == '-') || (v == '+')) {
                        ++i;
                        ++j;
                    }
                    while ((v = psz[i] = szVal[j]) != '\0') {
                        if (!strict_p && ISSPACE(v)) {
                            v = psz[i] = '\0';
                            break;
                        }
                        if (v == '_') {
                            if (ne > 0 && ISDIGIT(szVal[j+1])) {
                                ++j;
                                continue;
                            }
                            if (!strict_p) {
                                v = psz[i] = '\0';
                                if (ne == 0) {
                                    exp_seen = 0;
                                }
                                break;
                            }
                            goto invalid_value;
                        }
                        if (!ISDIGIT(v)) break;
                        ++i;
                        ++j;
                        ++ne;
                    }
                    break;
                default:
                    break;
            }
        }

        if (v != '\0') {
            /* Scanning trailing spaces */
            while (ISSPACE(szVal[j])) ++j;

            /* Invalid character */
            if (szVal[j] && strict_p) {
                goto invalid_value;
            }
        }
    }

    psz[i] = '\0';

    if (strict_p && ((ni == 0 && nf == 0) || (exp_seen && ne == 0))) {
        VALUE str;
      invalid_value:
        if (!strict_p) {
            goto return_zero;
        }
        if (!exc) {
            return NULL;
        }
        str = rb_str_new2(orig_szVal);
        rb_raise(rb_eArgError, "invalid value for BigDecimal(): \"%"PRIsVALUE"\"", str);
    }

    nalloc = (ni + nf + BASE_FIG - 1) / BASE_FIG + 1;    /* set effective allocation  */
    /* units for szVal[]  */
    if (len == 0) len = 1;
    nalloc = Max(nalloc, len);
    len = nalloc;
    vp = rbd_allocate_struct(len);
    vp->MaxPrec = len;        /* set max precision */
    VpSetZero(vp, sign);
    protected_VpCtoV(vp, psz, ni, psz + ipf, nf, psz + ipe, ne, true);
    rb_str_resize(buf, 0);
    return vp;
}

/*
 * Assignment(c=a).
 * [Input]
 *   a   ... RHSV
 *   isw ... switch for assignment.
 *    c = a  when isw > 0
 *    c = -a when isw < 0
 *    if c->MaxPrec < a->Prec,then round operation
 *    will be performed.
 * [Output]
 *  c  ... LHSV
 */
VP_EXPORT size_t
VpAsgn(Real *c, Real *a, int isw)
{
    size_t n;
    if (VpIsNaN(a)) {
	VpSetNaN(c);
	return 0;
    }
    if (VpIsInf(a)) {
	VpSetInf(c, isw * VpGetSign(a));
	return 0;
    }

    /* check if the RHS is zero */
    if (!VpIsZero(a)) {
	c->exponent = a->exponent;    /* store  exponent */
	VpSetSign(c, isw * VpGetSign(a));    /* set sign */
	n = (a->Prec < c->MaxPrec) ? (a->Prec) : (c->MaxPrec);
	c->Prec = n;
        memcpy(c->frac, a->frac, n * sizeof(DECDIG));
	/* Needs round ? */
	if (isw != 10) {
	    /* Not in ActiveRound */
	    if(c->Prec < a->Prec) {
		VpInternalRound(c, n, (n>0) ? a->frac[n-1] : 0, a->frac[n]);
	    }
	    else {
		VpLimitRound(c,0);
	    }
	}
    }
    else {
	/* The value of 'a' is zero.  */
	VpSetZero(c, isw * VpGetSign(a));
	return 1;
    }
    return c->Prec * BASE_FIG;
}

/*
 *   c = a + b  when operation =  1 or 2
 *   c = a - b  when operation = -1 or -2.
 *   Returns number of significant digits of c
 */
VP_EXPORT size_t
VpAddSub(Real *c, Real *a, Real *b, int operation)
{
    short sw, isw;
    Real *a_ptr, *b_ptr;
    size_t n, na, nb, i;
    DECDIG mrv;

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpAddSub(enter) a=% \n", a);
	VPrint(stdout, "     b=% \n", b);
	printf(" operation=%d\n", operation);
    }
#endif /* BIGDECIMAL_DEBUG */

    if (!VpIsDefOP(c, a, b, (operation > 0) ? OP_SW_ADD : OP_SW_SUB)) return 0; /* No significant digits */

    /* check if a or b is zero  */
    if (VpIsZero(a)) {
	/* a is zero,then assign b to c */
	if (!VpIsZero(b)) {
	    VpAsgn(c, b, operation);
	}
	else {
	    /* Both a and b are zero. */
	    if (VpGetSign(a) < 0 && operation * VpGetSign(b) < 0) {
		/* -0 -0 */
		VpSetZero(c, -1);
	    }
	    else {
		VpSetZero(c, 1);
	    }
	    return 1; /* 0: 1 significant digits */
	}
	return c->Prec * BASE_FIG;
    }
    if (VpIsZero(b)) {
	/* b is zero,then assign a to c. */
	VpAsgn(c, a, 1);
	return c->Prec*BASE_FIG;
    }

    if (operation < 0) sw = -1;
    else               sw =  1;

    /* compare absolute value. As a result,|a_ptr|>=|b_ptr| */
    if (a->exponent > b->exponent) {
	a_ptr = a;
	b_ptr = b;
    }         /* |a|>|b| */
    else if (a->exponent < b->exponent) {
	a_ptr = b;
	b_ptr = a;
    }                /* |a|<|b| */
    else {
	/* Exponent part of a and b is the same,then compare fraction */
	/* part */
	na = a->Prec;
	nb = b->Prec;
	n  = Min(na, nb);
	for (i=0; i < n; ++i) {
	    if (a->frac[i] > b->frac[i]) {
		a_ptr = a;
		b_ptr = b;
		goto end_if;
	    }
	    else if (a->frac[i] < b->frac[i]) {
		a_ptr = b;
		b_ptr = a;
		goto end_if;
	    }
	}
	if (na > nb) {
	    a_ptr = a;
	    b_ptr = b;
	    goto end_if;
	}
	else if (na < nb) {
	    a_ptr = b;
	    b_ptr = a;
	    goto end_if;
	}
	/* |a| == |b| */
	if (VpGetSign(a) + sw *VpGetSign(b) == 0) {
	    VpSetZero(c, 1);        /* abs(a)=abs(b) and operation = '-'  */
	    return c->Prec * BASE_FIG;
	}
	a_ptr = a;
	b_ptr = b;
    }

end_if:
    isw = VpGetSign(a) + sw *VpGetSign(b);
    /*
     *  isw = 0 ...( 1)+(-1),( 1)-( 1),(-1)+(1),(-1)-(-1)
     *      = 2 ...( 1)+( 1),( 1)-(-1)
     *      =-2 ...(-1)+(-1),(-1)-( 1)
     *   If isw==0, then c =(Sign a_ptr)(|a_ptr|-|b_ptr|)
     *              else c =(Sign ofisw)(|a_ptr|+|b_ptr|)
     */
    if (isw) {            /* addition */
	VpSetSign(c, 1);
	mrv = VpAddAbs(a_ptr, b_ptr, c);
	VpSetSign(c, isw / 2);
    }
    else {            /* subtraction */
	VpSetSign(c, 1);
	mrv = VpSubAbs(a_ptr, b_ptr, c);
	if (a_ptr == a) {
	    VpSetSign(c,VpGetSign(a));
	}
	else {
	    VpSetSign(c, VpGetSign(a_ptr) * sw);
	}
    }
    VpInternalRound(c, 0, (c->Prec > 0) ? c->frac[c->Prec-1] : 0, mrv);

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpAddSub(result) c=% \n", c);
	VPrint(stdout, "     a=% \n", a);
	VPrint(stdout, "     b=% \n", b);
	printf(" operation=%d\n", operation);
    }
#endif /* BIGDECIMAL_DEBUG */
    return c->Prec * BASE_FIG;
}

/*
 * Addition of two values with variable precision
 * a and b assuming abs(a)>abs(b).
 *   c = abs(a) + abs(b) ; where |a|>=|b|
 */
static DECDIG
VpAddAbs(Real *a, Real *b, Real *c)
{
    size_t word_shift;
    size_t ap;
    size_t bp;
    size_t cp;
    size_t a_pos;
    size_t b_pos, b_pos_with_word_shift;
    size_t c_pos;
    DECDIG av, bv, carry, mrv;

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpAddAbs called: a = %\n", a);
	VPrint(stdout, "     b = %\n", b);
    }
#endif /* BIGDECIMAL_DEBUG */

    word_shift = VpSetPTR(a, b, c, &ap, &bp, &cp, &av, &bv);
    a_pos = ap;
    b_pos = bp;
    c_pos = cp;

    if (word_shift == (size_t)-1L) return 0; /* Overflow */
    if (b_pos == (size_t)-1L) goto Assign_a;

    mrv = av + bv; /* Most right val. Used for round. */

    /* Just assign the last few digits of b to c because a has no  */
    /* corresponding digits to be added. */
    if (b_pos > 0) {
	while (b_pos > 0 && b_pos + word_shift > a_pos) {
	    c->frac[--c_pos] = b->frac[--b_pos];
	}
    }
    if (b_pos == 0 && word_shift > a_pos) {
	while (word_shift-- > a_pos) {
	    c->frac[--c_pos] = 0;
	}
    }

    /* Just assign the last few digits of a to c because b has no */
    /* corresponding digits to be added. */
    b_pos_with_word_shift = b_pos + word_shift;
    while (a_pos > b_pos_with_word_shift) {
	c->frac[--c_pos] = a->frac[--a_pos];
    }
    carry = 0;    /* set first carry be zero */

    /* Now perform addition until every digits of b will be */
    /* exhausted. */
    while (b_pos > 0) {
	c->frac[--c_pos] = a->frac[--a_pos] + b->frac[--b_pos] + carry;
	if (c->frac[c_pos] >= BASE) {
	    c->frac[c_pos] -= BASE;
	    carry = 1;
	}
	else {
	    carry = 0;
	}
    }

    /* Just assign the first few digits of a with considering */
    /* the carry obtained so far because b has been exhausted. */
    while (a_pos > 0) {
	c->frac[--c_pos] = a->frac[--a_pos] + carry;
	if (c->frac[c_pos] >= BASE) {
	    c->frac[c_pos] -= BASE;
	    carry = 1;
	}
	else {
	    carry = 0;
	}
    }
    if (c_pos) c->frac[c_pos - 1] += carry;
    goto Exit;

Assign_a:
    VpAsgn(c, a, 1);
    mrv = 0;

Exit:

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpAddAbs exit: c=% \n", c);
    }
#endif /* BIGDECIMAL_DEBUG */
    return mrv;
}

/*
 * c = abs(a) - abs(b)
 */
static DECDIG
VpSubAbs(Real *a, Real *b, Real *c)
{
    size_t word_shift;
    size_t ap;
    size_t bp;
    size_t cp;
    size_t a_pos;
    size_t b_pos, b_pos_with_word_shift;
    size_t c_pos;
    DECDIG av, bv, borrow, mrv;

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpSubAbs called: a = %\n", a);
	VPrint(stdout, "     b = %\n", b);
    }
#endif /* BIGDECIMAL_DEBUG */

    word_shift = VpSetPTR(a, b, c, &ap, &bp, &cp, &av, &bv);
    a_pos = ap;
    b_pos = bp;
    c_pos = cp;
    if (word_shift == (size_t)-1L) return 0; /* Overflow */
    if (b_pos == (size_t)-1L) goto Assign_a;

    if (av >= bv) {
	mrv = av - bv;
	borrow = 0;
    }
    else {
	mrv    = 0;
	borrow = 1;
    }

    /* Just assign the values which are the BASE subtracted by   */
    /* each of the last few digits of the b because the a has no */
    /* corresponding digits to be subtracted. */
    if (b_pos + word_shift > a_pos) {
	while (b_pos > 0 && b_pos + word_shift > a_pos) {
	    c->frac[--c_pos] = BASE - b->frac[--b_pos] - borrow;
	    borrow = 1;
	}
	if (b_pos == 0) {
	    while (word_shift > a_pos) {
		--word_shift;
		c->frac[--c_pos] = BASE - borrow;
		borrow = 1;
	    }
	}
    }
    /* Just assign the last few digits of a to c because b has no */
    /* corresponding digits to subtract. */

    b_pos_with_word_shift = b_pos + word_shift;
    while (a_pos > b_pos_with_word_shift) {
	c->frac[--c_pos] = a->frac[--a_pos];
    }

    /* Now perform subtraction until every digits of b will be */
    /* exhausted. */
    while (b_pos > 0) {
	--c_pos;
	if (a->frac[--a_pos] < b->frac[--b_pos] + borrow) {
	    c->frac[c_pos] = BASE + a->frac[a_pos] - b->frac[b_pos] - borrow;
	    borrow = 1;
	}
	else {
	    c->frac[c_pos] = a->frac[a_pos] - b->frac[b_pos] - borrow;
	    borrow = 0;
	}
    }

    /* Just assign the first few digits of a with considering */
    /* the borrow obtained so far because b has been exhausted. */
    while (a_pos > 0) {
	--c_pos;
	if (a->frac[--a_pos] < borrow) {
	    c->frac[c_pos] = BASE + a->frac[a_pos] - borrow;
	    borrow = 1;
	}
	else {
	    c->frac[c_pos] = a->frac[a_pos] - borrow;
	    borrow = 0;
	}
    }
    if (c_pos) c->frac[c_pos - 1] -= borrow;
    goto Exit;

Assign_a:
    VpAsgn(c, a, 1);
    mrv = 0;

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpSubAbs exit: c=% \n", c);
    }
#endif /* BIGDECIMAL_DEBUG */
    return mrv;
}

/*
 * Note: If(av+bv)>= HALF_BASE,then 1 will be added to the least significant
 *    digit of c(In case of addition).
 * ------------------------- figure of output -----------------------------------
 *      a =  xxxxxxxxxxx
 *      b =    xxxxxxxxxx
 *      c =xxxxxxxxxxxxxxx
 *      word_shift =  |   |
 *      right_word =  |    | (Total digits in RHSV)
 *      left_word  = |   |   (Total digits in LHSV)
 *      a_pos      =    |
 *      b_pos      =     |
 *      c_pos      =      |
 */
static size_t
VpSetPTR(Real *a, Real *b, Real *c, size_t *a_pos, size_t *b_pos, size_t *c_pos, DECDIG *av, DECDIG *bv)
{
    size_t left_word, right_word, word_shift;

    size_t const round_limit = (VpGetPrecLimit() + BASE_FIG - 1) / BASE_FIG;

    assert(a->exponent >= b->exponent);

    c->frac[0] = 0;
    *av = *bv = 0;

    word_shift = (a->exponent - b->exponent);
    left_word = b->Prec + word_shift;
    right_word = Max(a->Prec, left_word);
    left_word = c->MaxPrec - 1;    /* -1 ... prepare for round up */

    /*
     * check if 'round' is needed.
     */
    if (right_word > left_word) {    /* round ? */
	/*---------------------------------
	 *  Actual size of a = xxxxxxAxx
	 *  Actual size of b = xxxBxxxxx
	 *  Max. size of   c = xxxxxx
	 *  Round off        =   |-----|
	 *  c_pos            =   |
	 *  right_word       =   |
	 *  a_pos            =    |
	 */
	*c_pos = right_word = left_word + 1;    /* Set resulting precision */
	/* be equal to that of c */
	if (a->Prec >= c->MaxPrec) {
	    /*
	     *   a =  xxxxxxAxxx
	     *   c =  xxxxxx
	     *   a_pos =    |
	     */
	    *a_pos = left_word;
	    if (*a_pos <= round_limit) {
		*av = a->frac[*a_pos];    /* av is 'A' shown in above. */
	    }
	}
	else {
	    /*
	     *   a = xxxxxxx
	     *   c = xxxxxxxxxx
	     *  a_pos =     |
	     */
	    *a_pos = a->Prec;
	}
	if (b->Prec + word_shift >= c->MaxPrec) {
	    /*
	     *   a = xxxxxxxxx
	     *   b =  xxxxxxxBxxx
	     *   c = xxxxxxxxxxx
	     *  b_pos =   |
	     */
	    if (c->MaxPrec >= word_shift + 1) {
		*b_pos = c->MaxPrec - word_shift - 1;
		if (*b_pos + word_shift <= round_limit) {
		    *bv = b->frac[*b_pos];
		}
	    }
	    else {
		*b_pos = -1L;
	    }
	}
	else {
	    /*
	     *   a = xxxxxxxxxxxxxxxx
	     *   b =  xxxxxx
	     *   c = xxxxxxxxxxxxx
	     *  b_pos =     |
	     */
	    *b_pos = b->Prec;
	}
    }
    else {            /* The MaxPrec of c - 1 > The Prec of a + b  */
	/*
	 *    a =   xxxxxxx
	 *    b =   xxxxxx
	 *    c = xxxxxxxxxxx
	 *   c_pos =   |
	 */
	*b_pos = b->Prec;
	*a_pos = a->Prec;
	*c_pos = right_word + 1;
    }
    c->Prec = *c_pos;
    c->exponent = a->exponent;
    if (!AddExponent(c, 1)) return (size_t)-1L;
    return word_shift;
}

/*
 * Return number of significant digits
 *       c = a * b , Where a = a0a1a2 ... an
 *             b = b0b1b2 ... bm
 *             c = c0c1c2 ... cl
 *          a0 a1 ... an   * bm
 *       a0 a1 ... an   * bm-1
 *         .   .    .
 *       .   .   .
 *        a0 a1 .... an    * b0
 *      +_____________________________
 *     c0 c1 c2  ......  cl
 *     nc      <---|
 *     MaxAB |--------------------|
 */
VP_EXPORT size_t
VpMult(Real *c, Real *a, Real *b)
{
    size_t MxIndA, MxIndB, MxIndAB, MxIndC;
    size_t ind_c, i, ii, nc;
    size_t ind_as, ind_ae, ind_bs;
    DECDIG carry;
    DECDIG_DBL s;
    Real *w;

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpMult(Enter): a=% \n", a);
	VPrint(stdout, "      b=% \n", b);
    }
#endif /* BIGDECIMAL_DEBUG */

    if (!VpIsDefOP(c, a, b, OP_SW_MULT)) return 0; /* No significant digit */

    if (VpIsZero(a) || VpIsZero(b)) {
	/* at least a or b is zero */
	VpSetZero(c, VpGetSign(a) * VpGetSign(b));
	return 1; /* 0: 1 significant digit */
    }

    if (VpIsOne(a)) {
	VpAsgn(c, b, VpGetSign(a));
	goto Exit;
    }
    if (VpIsOne(b)) {
	VpAsgn(c, a, VpGetSign(b));
	goto Exit;
    }
    if (b->Prec > a->Prec) {
	/* Adjust so that digits(a)>digits(b) */
	w = a;
	a = b;
	b = w;
    }
    w = NULL;
    MxIndA = a->Prec - 1;
    MxIndB = b->Prec - 1;
    MxIndC = c->MaxPrec - 1;
    MxIndAB = a->Prec + b->Prec - 1;

    if (MxIndC < MxIndAB) {    /* The Max. prec. of c < Prec(a)+Prec(b) */
	w = c;
        c = NewZeroNolimit(1, (size_t)((MxIndAB + 1) * BASE_FIG));
	MxIndC = MxIndAB;
    }

    /* set LHSV c info */

    c->exponent = a->exponent;    /* set exponent */
    if (!AddExponent(c, b->exponent)) {
        if (w) rbd_free_struct(c);
        return 0;
    }
    VpSetSign(c, VpGetSign(a) * VpGetSign(b));    /* set sign  */
    carry = 0;
    nc = ind_c = MxIndAB;
    memset(c->frac, 0, (nc + 1) * sizeof(DECDIG));        /* Initialize c  */
    c->Prec = nc + 1;        /* set precision */
    for (nc = 0; nc < MxIndAB; ++nc, --ind_c) {
	if (nc < MxIndB) {    /* The left triangle of the Fig. */
	    ind_as = MxIndA - nc;
	    ind_ae = MxIndA;
	    ind_bs = MxIndB;
	}
	else if (nc <= MxIndA) {    /* The middle rectangular of the Fig. */
	    ind_as = MxIndA - nc;
	    ind_ae = MxIndA - (nc - MxIndB);
	    ind_bs = MxIndB;
	}
	else /* if (nc > MxIndA) */ {    /*  The right triangle of the Fig. */
	    ind_as = 0;
	    ind_ae = MxIndAB - nc - 1;
	    ind_bs = MxIndB - (nc - MxIndA);
	}

	for (i = ind_as; i <= ind_ae; ++i) {
            s = (DECDIG_DBL)a->frac[i] * b->frac[ind_bs--];
            carry = (DECDIG)(s / BASE);
            s -= (DECDIG_DBL)carry * BASE;
            c->frac[ind_c] += (DECDIG)s;
            if (c->frac[ind_c] >= BASE) {
                s = c->frac[ind_c] / BASE;
                carry += (DECDIG)s;
                c->frac[ind_c] -= (DECDIG)(s * BASE);
            }
	    if (carry) {
		ii = ind_c;
		while (ii-- > 0) {
		    c->frac[ii] += carry;
		    if (c->frac[ii] >= BASE) {
			carry = c->frac[ii] / BASE;
			c->frac[ii] -= (carry * BASE);
		    }
		    else {
			break;
		    }
		}
	    }
	}
    }
    if (w != NULL) {        /* free work variable */
        VpNmlz(c);
        VpAsgn(w, c, 1);
        rbd_free_struct(c);
        c = w;
    }
    else {
	VpLimitRound(c,0);
    }

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpMult(c=a*b): c=% \n", c);
	VPrint(stdout, "      a=% \n", a);
	VPrint(stdout, "      b=% \n", b);
    }
#endif /*BIGDECIMAL_DEBUG */
    return c->Prec*BASE_FIG;
}

/*
 *   c = a / b,  remainder = r
 */
VP_EXPORT size_t
VpDivd(Real *c, Real *r, Real *a, Real *b)
{
    size_t word_a, word_b, word_c, word_r;
    size_t i, n, ind_a, ind_b, ind_c, ind_r;
    size_t nLoop;
    DECDIG_DBL q, b1, b1p1, b1b2, b1b2p1, r1r2;
    DECDIG borrow, borrow1, borrow2;
    DECDIG_DBL qb;

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, " VpDivd(c=a/b)  a=% \n", a);
	VPrint(stdout, "    b=% \n", b);
    }
#endif /*BIGDECIMAL_DEBUG */

    VpSetNaN(r);
    if (!VpIsDefOP(c, a, b, OP_SW_DIV)) goto Exit;
    if (VpIsZero(a) && VpIsZero(b)) {
	VpSetNaN(c);
	return VpException(VP_EXCEPTION_NaN, "Computation results to 'NaN'", 0);
    }
    if (VpIsZero(b)) {
	VpSetInf(c, VpGetSign(a) * VpGetSign(b));
	return VpException(VP_EXCEPTION_ZERODIVIDE, "Divide by zero", 0);
    }
    if (VpIsZero(a)) {
	/* numerator a is zero  */
	VpSetZero(c, VpGetSign(a) * VpGetSign(b));
	VpSetZero(r, VpGetSign(a) * VpGetSign(b));
	goto Exit;
    }
    if (VpIsOne(b)) {
	/* divide by one  */
	VpAsgn(c, a, VpGetSign(b));
	VpSetZero(r, VpGetSign(a));
	goto Exit;
    }

    word_a = a->Prec;
    word_b = b->Prec;
    word_c = c->MaxPrec;
    word_r = r->MaxPrec;

    if (word_a >= word_r || word_b + word_c - 2 >= word_r) goto space_error;

    ind_r = 1;
    r->frac[0] = 0;
    while (ind_r <= word_a) {
	r->frac[ind_r] = a->frac[ind_r - 1];
	++ind_r;
    }
    while (ind_r < word_r) r->frac[ind_r++] = 0;

    ind_c = 0;
    while (ind_c < word_c) c->frac[ind_c++] = 0;

    /* initial procedure */
    b1 = b1p1 = b->frac[0];
    if (b->Prec <= 1) {
	b1b2p1 = b1b2 = b1p1 * BASE;
    }
    else {
	b1p1 = b1 + 1;
	b1b2p1 = b1b2 = b1 * BASE + b->frac[1];
	if (b->Prec > 2) ++b1b2p1;
    }

    /* */
    /* loop start */
    ind_c = word_r - 1;
    nLoop = Min(word_c,ind_c);
    ind_c = 1;
    while (ind_c < nLoop) {
	if (r->frac[ind_c] == 0) {
	    ++ind_c;
	    continue;
	}
        r1r2 = (DECDIG_DBL)r->frac[ind_c] * BASE + r->frac[ind_c + 1];
	if (r1r2 == b1b2) {
	    /* The first two word digits is the same */
	    ind_b = 2;
	    ind_a = ind_c + 2;
	    while (ind_b < word_b) {
		if (r->frac[ind_a] < b->frac[ind_b]) goto div_b1p1;
		if (r->frac[ind_a] > b->frac[ind_b]) break;
		++ind_a;
		++ind_b;
	    }
	    /* The first few word digits of r and b is the same and */
	    /* the first different word digit of w is greater than that */
	    /* of b, so quotient is 1 and just subtract b from r. */
	    borrow = 0;        /* quotient=1, then just r-b */
	    ind_b = b->Prec - 1;
	    ind_r = ind_c + ind_b;
	    if (ind_r >= word_r) goto space_error;
	    n = ind_b;
	    for (i = 0; i <= n; ++i) {
		if (r->frac[ind_r] < b->frac[ind_b] + borrow) {
		    r->frac[ind_r] += (BASE - (b->frac[ind_b] + borrow));
		    borrow = 1;
		}
		else {
		    r->frac[ind_r] = r->frac[ind_r] - b->frac[ind_b] - borrow;
		    borrow = 0;
		}
		--ind_r;
		--ind_b;
	    }
	    ++c->frac[ind_c];
	    goto carry;
	}
	/* The first two word digits is not the same, */
	/* then compare magnitude, and divide actually. */
	if (r1r2 >= b1b2p1) {
            q = r1r2 / b1b2p1;  /* q == (DECDIG)q  */
            c->frac[ind_c] += (DECDIG)q;
            ind_r = b->Prec + ind_c - 1;
            goto sub_mult;
	}

div_b1p1:
        if (ind_c + 1 >= word_c) goto out_side;
        q = r1r2 / b1p1;  /* q == (DECDIG)q */
        c->frac[ind_c + 1] += (DECDIG)q;
        ind_r = b->Prec + ind_c;

sub_mult:
	borrow1 = borrow2 = 0;
	ind_b = word_b - 1;
	if (ind_r >= word_r) goto space_error;
	n = ind_b;
	for (i = 0; i <= n; ++i) {
	    /* now, perform r = r - q * b */
	    qb = q * b->frac[ind_b];
	    if (qb < BASE) borrow1 = 0;
	    else {
                borrow1 = (DECDIG)(qb / BASE);
                qb -= (DECDIG_DBL)borrow1 * BASE;	/* get qb < BASE */
	    }
	    if(r->frac[ind_r] < qb) {
                r->frac[ind_r] += (DECDIG)(BASE - qb);
                borrow2 = borrow2 + borrow1 + 1;
	    }
	    else {
                r->frac[ind_r] -= (DECDIG)qb;
                borrow2 += borrow1;
	    }
	    if (borrow2) {
		if(r->frac[ind_r - 1] < borrow2) {
		    r->frac[ind_r - 1] += (BASE - borrow2);
		    borrow2 = 1;
		}
		else {
		    r->frac[ind_r - 1] -= borrow2;
		    borrow2 = 0;
		}
	    }
	    --ind_r;
	    --ind_b;
	}

	r->frac[ind_r] -= borrow2;
carry:
	ind_r = ind_c;
	while (c->frac[ind_r] >= BASE) {
	    c->frac[ind_r] -= BASE;
	    --ind_r;
	    ++c->frac[ind_r];
	}
    }
    /* End of operation, now final arrangement */
out_side:
    c->Prec = word_c;
    c->exponent = a->exponent;
    if (!AddExponent(c, 2)) return 0;
    if (!AddExponent(c, -(b->exponent))) return 0;

    VpSetSign(c, VpGetSign(a) * VpGetSign(b));
    VpNmlz(c);            /* normalize c */
    r->Prec = word_r;
    r->exponent = a->exponent;
    if (!AddExponent(r, 1)) return 0;
    VpSetSign(r, VpGetSign(a));
    VpNmlz(r);            /* normalize r(remainder) */
    goto Exit;

space_error:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	printf("   word_a=%"PRIuSIZE"\n", word_a);
	printf("   word_b=%"PRIuSIZE"\n", word_b);
	printf("   word_c=%"PRIuSIZE"\n", word_c);
	printf("   word_r=%"PRIuSIZE"\n", word_r);
	printf("   ind_r =%"PRIuSIZE"\n", ind_r);
    }
#endif /* BIGDECIMAL_DEBUG */
    rb_bug("ERROR(VpDivd): space for remainder too small.");

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, " VpDivd(c=a/b), c=% \n", c);
	VPrint(stdout, "    r=% \n", r);
    }
#endif /* BIGDECIMAL_DEBUG */
    return c->Prec * BASE_FIG;
}

/*
 *  Input  a = 00000xxxxxxxx En(5 preceding zeros)
 *  Output a = xxxxxxxx En-5
 */
static int
VpNmlz(Real *a)
{
    size_t ind_a, i;

    if (!VpIsDef(a)) goto NoVal;
    if (VpIsZero(a)) goto NoVal;

    ind_a = a->Prec;
    while (ind_a--) {
	if (a->frac[ind_a]) {
	    a->Prec = ind_a + 1;
	    i = 0;
	    while (a->frac[i] == 0) ++i;        /* skip the first few zeros */
	    if (i) {
                a->Prec -= i;
                if (!AddExponent(a, -(SIGNED_VALUE)i)) return 0;
                memmove(&a->frac[0], &a->frac[i], a->Prec*sizeof(DECDIG));
	    }
	    return 1;
	}
    }
    /* a is zero(no non-zero digit) */
    VpSetZero(a, VpGetSign(a));
    return 0;

NoVal:
    a->frac[0] = 0;
    a->Prec = 1;
    return 0;
}

/*
 *  VpComp = 0  ... if a=b,
 *   Pos  ... a>b,
 *   Neg  ... a<b.
 *   999  ... result undefined(NaN)
 */
VP_EXPORT int
VpComp(Real *a, Real *b)
{
    int val;
    size_t mx, ind;
    int e;
    val = 0;
    if (VpIsNaN(a) || VpIsNaN(b)) return 999;
    if (!VpIsDef(a)) {
	if (!VpIsDef(b)) e = a->sign - b->sign;
	else             e = a->sign;

	if (e > 0)      return  1;
	else if (e < 0) return -1;
	else            return  0;
    }
    if (!VpIsDef(b)) {
	e = -b->sign;
	if (e > 0) return  1;
	else       return -1;
    }
    /* Zero check */
    if (VpIsZero(a)) {
	if (VpIsZero(b)) return 0; /* both zero */
	val = -VpGetSign(b);
	goto Exit;
    }
    if (VpIsZero(b)) {
	val = VpGetSign(a);
	goto Exit;
    }

    /* compare sign */
    if (VpGetSign(a) > VpGetSign(b)) {
	val = 1;        /* a>b */
	goto Exit;
    }
    if (VpGetSign(a) < VpGetSign(b)) {
	val = -1;        /* a<b */
	goto Exit;
    }

    /* a and b have same sign, && sign!=0,then compare exponent */
    if (a->exponent > b->exponent) {
	val = VpGetSign(a);
	goto Exit;
    }
    if (a->exponent < b->exponent) {
	val = -VpGetSign(b);
	goto Exit;
    }

    /* a and b have same exponent, then compare their significand. */
    mx = (a->Prec < b->Prec) ? a->Prec : b->Prec;
    ind = 0;
    while (ind < mx) {
	if (a->frac[ind] > b->frac[ind]) {
	    val = VpGetSign(a);
	    goto Exit;
	}
	if (a->frac[ind] < b->frac[ind]) {
	    val = -VpGetSign(b);
	    goto Exit;
	}
	++ind;
    }
    if (a->Prec > b->Prec) {
	val = VpGetSign(a);
    }
    else if (a->Prec < b->Prec) {
	val = -VpGetSign(b);
    }

Exit:
    if      (val >  1) val =  1;
    else if (val < -1) val = -1;

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, " VpComp a=%\n", a);
	VPrint(stdout, "  b=%\n", b);
	printf("  ans=%d\n", val);
    }
#endif /* BIGDECIMAL_DEBUG */
    return (int)val;
}

/*
 *    cntl_chr ... ASCIIZ Character, print control characters
 *     Available control codes:
 *      %  ... VP variable. To print '%', use '%%'.
 *      \n ... new line
 *      \b ... backspace
 *      \t ... tab
 *     Note: % must not appear more than once
 *    a  ... VP variable to be printed
 */
static int
VPrint(FILE *fp, const char *cntl_chr, Real *a)
{
    size_t i, j, nc, nd, ZeroSup, sep = 10;
    DECDIG m, e, nn;

    j = 0;
    nd = nc = 0;        /*  nd : number of digits in fraction part(every 10 digits, */
    /*    nd<=10). */
    /*  nc : number of characters printed  */
    ZeroSup = 1;        /* Flag not to print the leading zeros as 0.00xxxxEnn */
    while (*(cntl_chr + j)) {
        if (*(cntl_chr + j) == '%' && *(cntl_chr + j + 1) != '%') {
            nc = 0;
            if (VpIsNaN(a)) {
                fprintf(fp, SZ_NaN);
                nc += 8;
            }
            else if (VpIsPosInf(a)) {
                fprintf(fp, SZ_INF);
                nc += 8;
            }
            else if (VpIsNegInf(a)) {
                fprintf(fp, SZ_NINF);
                nc += 9;
            }
            else if (!VpIsZero(a)) {
                if (BIGDECIMAL_NEGATIVE_P(a)) {
                    fprintf(fp, "-");
                    ++nc;
                }
                nc += fprintf(fp, "0.");
                switch (*(cntl_chr + j + 1)) {
                  default:
                    break;

                  case '0': case 'z':
                    ZeroSup = 0;
                    ++j;
                    sep = cntl_chr[j] == 'z' ? BIGDECIMAL_COMPONENT_FIGURES : 10;
                    break;
                }
                for (i = 0; i < a->Prec; ++i) {
                    m = BASE1;
                    e = a->frac[i];
                    while (m) {
                        nn = e / m;
                        if (!ZeroSup || nn) {
                            nc += fprintf(fp, "%lu", (unsigned long)nn);    /* The leading zero(s) */
                            /* as 0.00xx will not */
                            /* be printed. */
                            ++nd;
                            ZeroSup = 0;    /* Set to print succeeding zeros */
                        }
                        if (nd >= sep) {    /* print ' ' after every 10 digits */
                            nd = 0;
                            nc += fprintf(fp, " ");
                        }
                        e = e - nn * m;
                        m /= 10;
                    }
                }
                nc += fprintf(fp, "E%"PRIdSIZE, VpExponent10(a));
                nc += fprintf(fp, " (%"PRIdVALUE", %"PRIuSIZE", %"PRIuSIZE")", a->exponent, a->Prec, a->MaxPrec);
            }
            else {
                nc += fprintf(fp, "0.0");
            }
        }
        else {
            ++nc;
            if (*(cntl_chr + j) == '\\') {
                switch (*(cntl_chr + j + 1)) {
                  case 'n':
                    fprintf(fp, "\n");
                    ++j;
                    break;
                  case 't':
                    fprintf(fp, "\t");
                    ++j;
                    break;
                  case 'b':
                    fprintf(fp, "\n");
                    ++j;
                    break;
                  default:
                    fprintf(fp, "%c", *(cntl_chr + j));
                    break;
                }
            }
            else {
                fprintf(fp, "%c", *(cntl_chr + j));
                if (*(cntl_chr + j) == '%') ++j;
            }
        }
        j++;
    }

    return (int)nc;
}

static void
VpFormatSt(char *psz, size_t fFmt)
{
    size_t ie, i, nf = 0;
    char ch;

    if (fFmt == 0) return;

    ie = strlen(psz);
    for (i = 0; i < ie; ++i) {
	ch = psz[i];
	if (!ch) break;
	if (ISSPACE(ch) || ch=='-' || ch=='+') continue;
	if (ch == '.') { nf = 0; continue; }
	if (ch == 'E' || ch == 'e') break;

	if (++nf > fFmt) {
	    memmove(psz + i + 1, psz + i, ie - i + 1);
	    ++ie;
	    nf = 0;
	    psz[i] = ' ';
	}
    }
}

VP_EXPORT ssize_t
VpExponent10(Real *a)
{
    ssize_t ex;
    size_t n;

    if (!VpHasVal(a)) return 0;

    ex = a->exponent * (ssize_t)BASE_FIG;
    n = BASE1;
    while ((a->frac[0] / n) == 0) {
	--ex;
	n /= 10;
    }
    return ex;
}

VP_EXPORT void
VpSzMantissa(Real *a, char *buf, size_t buflen)
{
    size_t i, n, ZeroSup;
    DECDIG_DBL m, e, nn;

    if (VpIsNaN(a)) {
        snprintf(buf, buflen, SZ_NaN);
        return;
    }
    if (VpIsPosInf(a)) {
	snprintf(buf, buflen, SZ_INF);
	return;
    }
    if (VpIsNegInf(a)) {
	snprintf(buf, buflen, SZ_NINF);
	return;
    }

    ZeroSup = 1;        /* Flag not to print the leading zeros as 0.00xxxxEnn */
    if (!VpIsZero(a)) {
        if (BIGDECIMAL_NEGATIVE_P(a)) *buf++ = '-';
        n = a->Prec;
        for (i = 0; i < n; ++i) {
            m = BASE1;
            e = a->frac[i];
            while (m) {
                nn = e / m;
                if (!ZeroSup || nn) {
                    snprintf(buf, buflen, "%lu", (unsigned long)nn); /* The leading zero(s) */
                    buf += strlen(buf);
                    /* as 0.00xx will be ignored. */
                    ZeroSup = 0; /* Set to print succeeding zeros */
                }
                e = e - nn * m;
                m /= 10;
            }
        }
        *buf = 0;
        while (buf[-1] == '0') *(--buf) = 0;
    }
    else {
	if (VpIsPosZero(a)) snprintf(buf, buflen, "0");
	else                snprintf(buf, buflen, "-0");
    }
}

VP_EXPORT int
VpToSpecialString(Real *a, char *buf, size_t buflen, int fPlus)
/* fPlus = 0: default, 1: set ' ' before digits, 2: set '+' before digits. */
{
    if (VpIsNaN(a)) {
        snprintf(buf, buflen, SZ_NaN);
        return 1;
    }

    if (VpIsPosInf(a)) {
        if (fPlus == 1) {
            *buf++ = ' ';
        }
        else if (fPlus == 2) {
            *buf++ = '+';
        }
        snprintf(buf, buflen, SZ_INF);
        return 1;
    }
    if (VpIsNegInf(a)) {
        snprintf(buf, buflen, SZ_NINF);
        return 1;
    }
    if (VpIsZero(a)) {
        if (VpIsPosZero(a)) {
            if (fPlus == 1)      snprintf(buf, buflen, " 0.0");
            else if (fPlus == 2) snprintf(buf, buflen, "+0.0");
            else                 snprintf(buf, buflen,  "0.0");
        }
        else                     snprintf(buf, buflen, "-0.0");
        return 1;
    }
    return 0;
}

VP_EXPORT void
VpToString(Real *a, char *buf, size_t buflen, size_t fFmt, int fPlus)
/* fPlus = 0: default, 1: set ' ' before digits, 2: set '+' before digits. */
{
    size_t i, n, ZeroSup;
    DECDIG shift, m, e, nn;
    char *p = buf;
    size_t plen = buflen;
    ssize_t ex;

    if (VpToSpecialString(a, buf, buflen, fPlus)) return;

    ZeroSup = 1;    /* Flag not to print the leading zeros as 0.00xxxxEnn */

#define ADVANCE(n) do { \
    if (plen < n) goto overflow; \
    p += n; \
    plen -= n; \
} while (0)

    if (BIGDECIMAL_NEGATIVE_P(a)) {
        *p = '-';
        ADVANCE(1);
    }
    else if (fPlus == 1) {
        *p = ' ';
        ADVANCE(1);
    }
    else if (fPlus == 2) {
        *p = '+';
        ADVANCE(1);
    }

    *p = '0'; ADVANCE(1);
    *p = '.'; ADVANCE(1);

    n = a->Prec;
    for (i = 0; i < n; ++i) {
        m = BASE1;
        e = a->frac[i];
        while (m) {
            nn = e / m;
            if (!ZeroSup || nn) {
                /* The reading zero(s) */
                size_t n = (size_t)snprintf(p, plen, "%lu", (unsigned long)nn);
                if (n > plen) goto overflow;
                ADVANCE(n);
                /* as 0.00xx will be ignored. */
                ZeroSup = 0;    /* Set to print succeeding zeros */
            }
            e = e - nn * m;
            m /= 10;
        }
    }

    ex = a->exponent * (ssize_t)BASE_FIG;
    shift = BASE1;
    while (a->frac[0] / shift == 0) {
        --ex;
        shift /= 10;
    }
    while (p - 1 > buf && p[-1] == '0') {
        *(--p) = '\0';
        ++plen;
    }
    snprintf(p, plen, "e%"PRIdSIZE, ex);
    if (fFmt) VpFormatSt(buf, fFmt);

  overflow:
    return;
#undef ADVANCE
}

VP_EXPORT void
VpToFString(Real *a, char *buf, size_t buflen, size_t fFmt, int fPlus)
/* fPlus = 0: default, 1: set ' ' before digits, 2: set '+' before digits. */
{
    size_t i, n;
    DECDIG m, e;
    char *p = buf;
    size_t plen = buflen, delim = fFmt;
    ssize_t ex;

    if (VpToSpecialString(a, buf, buflen, fPlus)) return;

#define APPEND(c, group) do { \
    if (plen < 1) goto overflow; \
    if (group && delim == 0) { \
        *p = ' '; \
        p += 1; \
        plen -= 1; \
    } \
    if (plen < 1) goto overflow; \
    *p = c; \
    p += 1; \
    plen -= 1; \
    if (group) delim = (delim + 1) % fFmt; \
} while (0)


    if (BIGDECIMAL_NEGATIVE_P(a)) {
        APPEND('-', false);
    }
    else if (fPlus == 1) {
        APPEND(' ', false);
    }
    else if (fPlus == 2) {
        APPEND('+', false);
    }

    n  = a->Prec;
    ex = a->exponent;
    if (ex <= 0) {
        APPEND('0', false);
        APPEND('.', false);
    }
    while (ex < 0) {
        for (i=0; i < BASE_FIG; ++i) {
            APPEND('0', fFmt > 0);
        }
        ++ex;
    }

    for (i = 0; i < n; ++i) {
        m = BASE1;
        e = a->frac[i];
        if (i == 0 && ex > 0) {
            for (delim = 0; e / m == 0; delim++) {
                m /= 10;
            }
            if (fFmt > 0) {
              delim = 2*fFmt - (ex * BASE_FIG - delim) % fFmt;
            }
        }
        while (m && (e || (i < n - 1) || ex > 0)) {
            APPEND((char)(e / m + '0'), fFmt > 0);
            e %= m;
            m /= 10;
        }
        if (--ex == 0) {
            APPEND('.', false);
            delim = fFmt;
        }
    }

    while (ex > 0) {
        for (i=0; i < BASE_FIG; ++i) {
            APPEND('0', fFmt > 0);
        }
        if (--ex == 0) {
            APPEND('.', false);
        }
    }

    *p = '\0';
    if (p - 1 > buf && p[-1] == '.') {
        snprintf(p, plen, "0");
    }

  overflow:
    return;
#undef APPEND
}

/*
 *  [Output]
 *   a[]  ... variable to be assigned the value.
 *  [Input]
 *   int_chr[]  ... integer part(may include '+/-').
 *   ni   ... number of characters in int_chr[],not including '+/-'.
 *   frac[]  ... fraction part.
 *   nf   ... number of characters in frac[].
 *   exp_chr[]  ... exponent part(including '+/-').
 *   ne   ... number of characters in exp_chr[],not including '+/-'.
 */
VP_EXPORT int
VpCtoV(Real *a, const char *int_chr, size_t ni, const char *frac, size_t nf, const char *exp_chr, size_t ne)
{
    size_t i, j, ind_a, ma, mi, me;
    SIGNED_VALUE e, es, eb, ef;
    int  sign, signe, exponent_overflow;

    /* get exponent part */
    e = 0;
    ma = a->MaxPrec;
    mi = ni;
    me = ne;
    signe = 1;
    exponent_overflow = 0;
    memset(a->frac, 0, ma * sizeof(DECDIG));
    if (ne > 0) {
	i = 0;
	if (exp_chr[0] == '-') {
	    signe = -1;
	    ++i;
	    ++me;
	}
	else if (exp_chr[0] == '+') {
	    ++i;
	    ++me;
	}
	while (i < me) {
            if (MUL_OVERFLOW_SIGNED_VALUE_P(e, (SIGNED_VALUE)BASE_FIG)) {
                es = e;
                goto exp_overflow;
            }
	    es = e * (SIGNED_VALUE)BASE_FIG;
            if (MUL_OVERFLOW_SIGNED_VALUE_P(e, 10) ||
                SIGNED_VALUE_MAX - (exp_chr[i] - '0') < e * 10)
                goto exp_overflow;
	    e = e * 10 + exp_chr[i] - '0';
            if (MUL_OVERFLOW_SIGNED_VALUE_P(e, (SIGNED_VALUE)BASE_FIG))
                goto exp_overflow;
	    if (es > (SIGNED_VALUE)(e * BASE_FIG)) {
              exp_overflow:
		exponent_overflow = 1;
		e = es; /* keep sign */
		break;
	    }
	    ++i;
	}
    }

    /* get integer part */
    i = 0;
    sign = 1;
    if (1 /*ni >= 0*/) {
	if (int_chr[0] == '-') {
	    sign = -1;
	    ++i;
	    ++mi;
	}
	else if (int_chr[0] == '+') {
	    ++i;
	    ++mi;
	}
    }

    e = signe * e;        /* e: The value of exponent part. */
    e = e + ni;        /* set actual exponent size. */

    if (e > 0) signe = 1;
    else       signe = -1;

    /* Adjust the exponent so that it is the multiple of BASE_FIG. */
    j = 0;
    ef = 1;
    while (ef) {
	if (e >= 0) eb =  e;
	else        eb = -e;
	ef = eb / (SIGNED_VALUE)BASE_FIG;
	ef = eb - ef * (SIGNED_VALUE)BASE_FIG;
	if (ef) {
	    ++j;        /* Means to add one more preceding zero */
	    ++e;
	}
    }

    eb = e / (SIGNED_VALUE)BASE_FIG;

    if (exponent_overflow) {
	int zero = 1;
	for (     ; i < mi && zero; i++) zero = int_chr[i] == '0';
	for (i = 0; i < nf && zero; i++) zero = frac[i] == '0';
	if (!zero && signe > 0) {
	    VpSetInf(a, sign);
	    VpException(VP_EXCEPTION_INFINITY, "exponent overflow",0);
	}
	else VpSetZero(a, sign);
	return 1;
    }

    ind_a = 0;
    while (i < mi) {
	a->frac[ind_a] = 0;
	while (j < BASE_FIG && i < mi) {
	    a->frac[ind_a] = a->frac[ind_a] * 10 + int_chr[i] - '0';
	    ++j;
	    ++i;
	}
	if (i < mi) {
	    ++ind_a;
	    if (ind_a >= ma) goto over_flow;
	    j = 0;
	}
    }

    /* get fraction part */

    i = 0;
    while (i < nf) {
	while (j < BASE_FIG && i < nf) {
	    a->frac[ind_a] = a->frac[ind_a] * 10 + frac[i] - '0';
	    ++j;
	    ++i;
	}
	if (i < nf) {
	    ++ind_a;
	    if (ind_a >= ma) goto over_flow;
	    j = 0;
	}
    }
    goto Final;

over_flow:
    rb_warn("Conversion from String to BigDecimal overflow (last few digits discarded).");

Final:
    if (ind_a >= ma) ind_a = ma - 1;
    while (j < BASE_FIG) {
	a->frac[ind_a] = a->frac[ind_a] * 10;
	++j;
    }
    a->Prec = ind_a + 1;
    a->exponent = eb;
    VpSetSign(a, sign);
    VpNmlz(a);
    return 1;
}

/*
 * [Input]
 *   *m  ... Real
 * [Output]
 *   *d  ... fraction part of m(d = 0.xxxxxxx). where # of 'x's is fig.
 *   *e  ... exponent of m.
 * BIGDECIMAL_DOUBLE_FIGURES ... Number of digits in a double variable.
 *
 *  m -> d*10**e, 0<d<BASE
 * [Returns]
 *   0 ... Zero
 *   1 ... Normal
 *   2 ... Infinity
 *  -1 ... NaN
 */
VP_EXPORT int
VpVtoD(double *d, SIGNED_VALUE *e, Real *m)
{
    size_t ind_m, mm, fig;
    double div;
    int    f = 1;

    if (VpIsNaN(m)) {
	*d = VpGetDoubleNaN();
	*e = 0;
	f = -1; /* NaN */
	goto Exit;
    }
    else if (VpIsPosZero(m)) {
	*d = 0.0;
	*e = 0;
	f  = 0;
	goto Exit;
    }
    else if (VpIsNegZero(m)) {
	*d = VpGetDoubleNegZero();
	*e = 0;
	f  = 0;
	goto Exit;
    }
    else if (VpIsPosInf(m)) {
	*d = VpGetDoublePosInf();
	*e = 0;
	f  = 2;
	goto Exit;
    }
    else if (VpIsNegInf(m)) {
	*d = VpGetDoubleNegInf();
	*e = 0;
	f  = 2;
	goto Exit;
    }
    /* Normal number */
    fig = roomof(BIGDECIMAL_DOUBLE_FIGURES, BASE_FIG);
    ind_m = 0;
    mm = Min(fig, m->Prec);
    *d = 0.0;
    div = 1.;
    while (ind_m < mm) {
	div /= (double)BASE;
	*d = *d + (double)m->frac[ind_m++] * div;
    }
    *e = m->exponent * (SIGNED_VALUE)BASE_FIG;
    *d *= VpGetSign(m);

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, " VpVtoD: m=%\n", m);
	printf("   d=%e * 10 **%ld\n", *d, *e);
	printf("   BIGDECIMAL_DOUBLE_FIGURES = %d\n", BIGDECIMAL_DOUBLE_FIGURES);
    }
#endif /*BIGDECIMAL_DEBUG */
    return f;
}

/*
 * m <- d
 */
VP_EXPORT void
VpDtoV(Real *m, double d)
{
    size_t ind_m, mm;
    SIGNED_VALUE ne;
    DECDIG i;
    double  val, val2;

    if (isnan(d)) {
	VpSetNaN(m);
	goto Exit;
    }
    if (isinf(d)) {
	if (d > 0.0) VpSetPosInf(m);
	else VpSetNegInf(m);
	goto Exit;
    }

    if (d == 0.0) {
	VpSetZero(m, 1);
	goto Exit;
    }
    val = (d > 0.) ? d : -d;
    ne = 0;
    if (val >= 1.0) {
	while (val >= 1.0) {
	    val /= (double)BASE;
	    ++ne;
	}
    }
    else {
	val2 = 1.0 / (double)BASE;
	while (val < val2) {
	    val *= (double)BASE;
	    --ne;
	}
    }
    /* Now val = 0.xxxxx*BASE**ne */

    mm = m->MaxPrec;
    memset(m->frac, 0, mm * sizeof(DECDIG));
    for (ind_m = 0; val > 0.0 && ind_m < mm; ind_m++) {
        val *= (double)BASE;
        i = (DECDIG)val;
        val -= (double)i;
        m->frac[ind_m] = i;
    }
    if (ind_m >= mm) ind_m = mm - 1;
    VpSetSign(m, (d > 0.0) ? 1 : -1);
    m->Prec = ind_m + 1;
    m->exponent = ne;

    VpInternalRound(m, 0, (m->Prec > 0) ? m->frac[m->Prec-1] : 0,
                    (DECDIG)(val*(double)BASE));

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	printf("VpDtoV d=%30.30e\n", d);
	VPrint(stdout, "  m=%\n", m);
    }
#endif /* BIGDECIMAL_DEBUG */
    return;
}

/*
 *  m <- ival
 */
#if 0  /* unused */
VP_EXPORT void
VpItoV(Real *m, SIGNED_VALUE ival)
{
    size_t mm, ind_m;
    size_t val, v1, v2, v;
    int isign;
    SIGNED_VALUE ne;

    if (ival == 0) {
	VpSetZero(m, 1);
	goto Exit;
    }
    isign = 1;
    val = ival;
    if (ival < 0) {
	isign = -1;
	val  =(size_t)(-ival);
    }
    ne = 0;
    ind_m = 0;
    mm = m->MaxPrec;
    while (ind_m < mm) {
	m->frac[ind_m] = 0;
	++ind_m;
    }
    ind_m = 0;
    while (val > 0) {
	if (val) {
	    v1 = val;
	    v2 = 1;
	    while (v1 >= BASE) {
		v1 /= BASE;
		v2 *= BASE;
	    }
	    val = val - v2 * v1;
	    v = v1;
	}
	else {
	    v = 0;
	}
	m->frac[ind_m] = v;
	++ind_m;
	++ne;
    }
    m->Prec = ind_m - 1;
    m->exponent = ne;
    VpSetSign(m, isign);
    VpNmlz(m);

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	printf(" VpItoV i=%d\n", ival);
	VPrint(stdout, "  m=%\n", m);
    }
#endif /* BIGDECIMAL_DEBUG */
    return;
}
#endif

/*
 * y = SQRT(x),  y*y - x =>0
 */
VP_EXPORT int
VpSqrt(Real *y, Real *x)
{
    Real *f = NULL;
    Real *r = NULL;
    size_t y_prec;
    SIGNED_VALUE n, e;
    ssize_t nr;
    double val;

    /* Zero or +Infinity ? */
    if (VpIsZero(x) || VpIsPosInf(x)) {
	VpAsgn(y,x,1);
	goto Exit;
    }

    /* Negative ? */
    if (BIGDECIMAL_NEGATIVE_P(x)) {
	VpSetNaN(y);
	return VpException(VP_EXCEPTION_OP, "sqrt of negative value", 0);
    }

    /* NaN ? */
    if (VpIsNaN(x)) {
	VpSetNaN(y);
	return VpException(VP_EXCEPTION_OP, "sqrt of 'NaN'(Not a Number)", 0);
    }

    /* One ? */
    if (VpIsOne(x)) {
	VpSetOne(y);
	goto Exit;
    }

    n = (SIGNED_VALUE)y->MaxPrec;
    if (x->MaxPrec > (size_t)n) n = (ssize_t)x->MaxPrec;

    /* allocate temporally variables  */
    /* TODO: reconsider MaxPrec of f and r */
    f = NewOneNolimit(1, y->MaxPrec * (BASE_FIG + 2));
    r = NewOneNolimit(1, (n + n) * (BASE_FIG + 2));

    nr = 0;
    y_prec = y->MaxPrec;

    VpVtoD(&val, &e, x);    /* val <- x  */
    e /= (SIGNED_VALUE)BASE_FIG;
    n = e / 2;
    if (e - n * 2 != 0) {
	val /= BASE;
	n = (e + 1) / 2;
    }
    VpDtoV(y, sqrt(val));    /* y <- sqrt(val) */
    y->exponent += n;
    n = (SIGNED_VALUE)roomof(BIGDECIMAL_DOUBLE_FIGURES, BASE_FIG);
    y->MaxPrec = Min((size_t)n , y_prec);
    f->MaxPrec = y->MaxPrec + 1;
    n = (SIGNED_VALUE)(y_prec * BASE_FIG);
    if (n > (SIGNED_VALUE)maxnr) n = (SIGNED_VALUE)maxnr;

    /*
     * Perform: y_{n+1} = (y_n - x/y_n) / 2
     */
    do {
        y->MaxPrec *= 2;
        if (y->MaxPrec > y_prec) y->MaxPrec = y_prec;
        f->MaxPrec = y->MaxPrec;
        VpDivd(f, r, x, y);        /* f = x/y    */
        VpAddSub(r, f, y, -1);     /* r = f - y  */
        VpMult(f, VpConstPt5, r);  /* f = 0.5*r  */
        if (VpIsZero(f))
            goto converge;
        VpAddSub(r, f, y, 1);      /* r = y + f  */
        VpAsgn(y, r, 1);           /* y = r      */
    } while (++nr < n);

#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	printf("ERROR(VpSqrt): did not converge within %ld iterations.\n", nr);
    }
#endif /* BIGDECIMAL_DEBUG */
    y->MaxPrec = y_prec;

converge:
    VpChangeSign(y, 1);
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VpMult(r, y, y);
	VpAddSub(f, x, r, -1);
	printf("VpSqrt: iterations = %"PRIdSIZE"\n", nr);
	VPrint(stdout, "  y =% \n", y);
	VPrint(stdout, "  x =% \n", x);
	VPrint(stdout, "  x-y*y = % \n", f);
    }
#endif /* BIGDECIMAL_DEBUG */
    y->MaxPrec = y_prec;

Exit:
    rbd_free_struct(f);
    rbd_free_struct(r);
    return 1;
}

/*
 * Round relatively from the decimal point.
 *    f: rounding mode
 *   nf: digit location to round from the decimal point.
 */
VP_EXPORT int
VpMidRound(Real *y, unsigned short f, ssize_t nf)
{
    /* fracf: any positive digit under rounding position? */
    /* fracf_1further: any positive digits under one further than the rounding position? */
    /* exptoadd: number of digits needed to compensate negative nf */
    int fracf, fracf_1further;
    ssize_t n,i,ix,ioffset, exptoadd;
    DECDIG v, shifter;
    DECDIG div;

    nf += y->exponent * (ssize_t)BASE_FIG;
    exptoadd=0;
    if (nf < 0) {
	/* rounding position too left(large). */
	if (f != VP_ROUND_CEIL && f != VP_ROUND_FLOOR) {
	    VpSetZero(y, VpGetSign(y)); /* truncate everything */
	    return 0;
	}
	exptoadd = -nf;
	nf = 0;
    }

    ix = nf / (ssize_t)BASE_FIG;
    if ((size_t)ix >= y->Prec) return 0;  /* rounding position too right(small). */
    v = y->frac[ix];

    ioffset = nf - ix*(ssize_t)BASE_FIG;
    n = (ssize_t)BASE_FIG - ioffset - 1;
    for (shifter = 1, i = 0; i < n; ++i) shifter *= 10;

    /* so the representation used (in y->frac) is an array of DECDIG, where
       each DECDIG contains a value between 0 and BASE-1, consisting of BASE_FIG
       decimal places.

       (that numbers of decimal places are typed as ssize_t is somewhat confusing)

       nf is now position (in decimal places) of the digit from the start of
       the array.

       ix is the position (in DECDIGs) of the DECDIG containing the decimal digit,
       from the start of the array.

       v is the value of this DECDIG

       ioffset is the number of extra decimal places along of this decimal digit
       within v.

       n is the number of decimal digits remaining within v after this decimal digit
       shifter is 10**n,

       v % shifter are the remaining digits within v
       v % (shifter * 10) are the digit together with the remaining digits within v
       v / shifter are the digit's predecessors together with the digit
       div = v / shifter / 10 is just the digit's precessors
       (v / shifter) - div*10 is just the digit, which is what v ends up being reassigned to.
       */

    fracf = (v % (shifter * 10) > 0);
    fracf_1further = ((v % shifter) > 0);

    v /= shifter;
    div = v / 10;
    v = v - div*10;
    /* now v is just the digit required.
       now fracf is whether the digit or any of the remaining digits within v are non-zero
       now fracf_1further is whether any of the remaining digits within v are non-zero
       */

    /* now check all the remaining DECDIGs for zero-ness a whole DECDIG at a time.
       if we spot any non-zeroness, that means that we found a positive digit under
       rounding position, and we also found a positive digit under one further than
       the rounding position, so both searches (to see if any such non-zero digit exists)
       can stop */

    for (i = ix + 1; (size_t)i < y->Prec; i++) {
	if (y->frac[i] % BASE) {
	    fracf = fracf_1further = 1;
	    break;
	}
    }

    /* now fracf = does any positive digit exist under the rounding position?
       now fracf_1further = does any positive digit exist under one further than the
       rounding position?
       now v = the first digit under the rounding position */

    /* drop digits after pointed digit */
    memset(y->frac + ix + 1, 0, (y->Prec - (ix + 1)) * sizeof(DECDIG));

    switch (f) {
      case VP_ROUND_DOWN: /* Truncate */
	break;
      case VP_ROUND_UP:   /* Roundup */
	if (fracf) ++div;
	break;
      case VP_ROUND_HALF_UP:
	if (v>=5) ++div;
	break;
      case VP_ROUND_HALF_DOWN:
	if (v > 5 || (v == 5 && fracf_1further)) ++div;
	break;
      case VP_ROUND_CEIL:
	if (fracf && BIGDECIMAL_POSITIVE_P(y)) ++div;
	break;
      case VP_ROUND_FLOOR:
	if (fracf && BIGDECIMAL_NEGATIVE_P(y)) ++div;
	break;
      case VP_ROUND_HALF_EVEN: /* Banker's rounding */
	if (v > 5) ++div;
	else if (v == 5) {
	    if (fracf_1further) {
		++div;
	    }
	    else {
		if (ioffset == 0) {
                    /* v is the first decimal digit of its DECDIG;
                       need to grab the previous DECDIG if present
                       to check for evenness of the previous decimal
                       digit (which is same as that of the DECDIG since
                       base 10 has a factor of 2) */
		    if (ix && (y->frac[ix-1] % 2)) ++div;
		}
		else {
		    if (div % 2) ++div;
		}
	    }
	}
	break;
    }
    for (i = 0; i <= n; ++i) div *= 10;
    if (div >= BASE) {
	if (ix) {
	    y->frac[ix] = 0;
	    VpRdup(y, ix);
	}
	else {
	    short s = VpGetSign(y);
	    SIGNED_VALUE e = y->exponent;
	    VpSetOne(y);
	    VpSetSign(y, s);
	    y->exponent = e + 1;
	}
    }
    else {
	y->frac[ix] = div;
	VpNmlz(y);
    }
    if (exptoadd > 0) {
	y->exponent += (SIGNED_VALUE)(exptoadd / BASE_FIG);
	exptoadd %= (ssize_t)BASE_FIG;
	for (i = 0; i < exptoadd; i++) {
	    y->frac[0] *= 10;
	    if (y->frac[0] >= BASE) {
		y->frac[0] /= BASE;
		y->exponent++;
	    }
	}
    }
    return 1;
}

VP_EXPORT int
VpLeftRound(Real *y, unsigned short f, ssize_t nf)
/*
 * Round from the left hand side of the digits.
 */
{
    DECDIG v;
    if (!VpHasVal(y)) return 0; /* Unable to round */
    v = y->frac[0];
    nf -= VpExponent(y) * (ssize_t)BASE_FIG;
    while ((v /= 10) != 0) nf--;
    nf += (ssize_t)BASE_FIG-1;
    return VpMidRound(y, f, nf);
}

VP_EXPORT int
VpActiveRound(Real *y, Real *x, unsigned short f, ssize_t nf)
{
    /* First,assign whole value in truncation mode */
    if (VpAsgn(y, x, 10) <= 1) return 0; /* Zero,NaN,or Infinity */
    return VpMidRound(y, f, nf);
}

static int
VpLimitRound(Real *c, size_t ixDigit)
{
    size_t ix = VpGetPrecLimit();
    if (!VpNmlz(c)) return -1;
    if (!ix)        return  0;
    if (!ixDigit) ixDigit = c->Prec-1;
    if ((ix + BASE_FIG - 1) / BASE_FIG > ixDigit + 1) return 0;
    return VpLeftRound(c, VpGetRoundMode(), (ssize_t)ix);
}

/* If I understand correctly, this is only ever used to round off the final decimal
   digit of precision */
static void
VpInternalRound(Real *c, size_t ixDigit, DECDIG vPrev, DECDIG v)
{
    int f = 0;

    unsigned short const rounding_mode = VpGetRoundMode();

    if (VpLimitRound(c, ixDigit)) return;
    if (!v) return;

    v /= BASE1;
    switch (rounding_mode) {
      case VP_ROUND_DOWN:
	break;
      case VP_ROUND_UP:
	if (v) f = 1;
	break;
      case VP_ROUND_HALF_UP:
	if (v >= 5) f = 1;
	break;
      case VP_ROUND_HALF_DOWN:
	/* this is ok - because this is the last digit of precision,
	   the case where v == 5 and some further digits are nonzero
	   will never occur */
	if (v >= 6) f = 1;
	break;
      case VP_ROUND_CEIL:
	if (v && BIGDECIMAL_POSITIVE_P(c)) f = 1;
	break;
      case VP_ROUND_FLOOR:
	if (v && BIGDECIMAL_NEGATIVE_P(c)) f = 1;
	break;
      case VP_ROUND_HALF_EVEN:  /* Banker's rounding */
	/* as per VP_ROUND_HALF_DOWN, because this is the last digit of precision,
	   there is no case to worry about where v == 5 and some further digits are nonzero */
	if (v > 5) f = 1;
	else if (v == 5 && vPrev % 2) f = 1;
	break;
    }
    if (f) {
	VpRdup(c, ixDigit);
	VpNmlz(c);
    }
}

/*
 *  Rounds up m(plus one to final digit of m).
 */
static int
VpRdup(Real *m, size_t ind_m)
{
    DECDIG carry;

    if (!ind_m) ind_m = m->Prec;

    carry = 1;
    while (carry > 0 && ind_m--) {
	m->frac[ind_m] += carry;
	if (m->frac[ind_m] >= BASE) m->frac[ind_m] -= BASE;
	else                        carry = 0;
    }
    if (carry > 0) { /* Overflow,count exponent and set fraction part be 1  */
	if (!AddExponent(m, 1)) return 0;
	m->Prec = m->frac[0] = 1;
    }
    else {
	VpNmlz(m);
    }
    return 1;
}

/*
 *  y = x - fix(x)
 */
VP_EXPORT void
VpFrac(Real *y, Real *x)
{
    size_t my, ind_y, ind_x;

    if (!VpHasVal(x)) {
	VpAsgn(y, x, 1);
	goto Exit;
    }

    if (x->exponent > 0 && (size_t)x->exponent >= x->Prec) {
	VpSetZero(y, VpGetSign(x));
	goto Exit;
    }
    else if (x->exponent <= 0) {
	VpAsgn(y, x, 1);
	goto Exit;
    }

    /* satisfy: x->exponent > 0 */

    y->Prec = x->Prec - (size_t)x->exponent;
    y->Prec = Min(y->Prec, y->MaxPrec);
    y->exponent = 0;
    VpSetSign(y, VpGetSign(x));
    ind_y = 0;
    my = y->Prec;
    ind_x = x->exponent;
    while (ind_y < my) {
	y->frac[ind_y] = x->frac[ind_x];
	++ind_y;
	++ind_x;
    }
    VpNmlz(y);

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpFrac y=%\n", y);
	VPrint(stdout, "    x=%\n", x);
    }
#endif /* BIGDECIMAL_DEBUG */
    return;
}

/*
 *   y = x ** n
 */
VP_EXPORT int
VpPowerByInt(Real *y, Real *x, SIGNED_VALUE n)
{
    size_t s, ss;
    ssize_t sign;
    Real *w1 = NULL;
    Real *w2 = NULL;

    if (VpIsZero(x)) {
	if (n == 0) {
	    VpSetOne(y);
	    goto Exit;
	}
	sign = VpGetSign(x);
	if (n < 0) {
	    n = -n;
	    if (sign < 0) sign = (n % 2) ? -1 : 1;
	    VpSetInf(y, sign);
	}
	else {
	    if (sign < 0) sign = (n % 2) ? -1 : 1;
	    VpSetZero(y,sign);
	}
	goto Exit;
    }
    if (VpIsNaN(x)) {
	VpSetNaN(y);
	goto Exit;
    }
    if (VpIsInf(x)) {
	if (n == 0) {
	    VpSetOne(y);
	    goto Exit;
	}
	if (n > 0) {
	    VpSetInf(y, (n % 2 == 0 || VpIsPosInf(x)) ? 1 : -1);
	    goto Exit;
	}
	VpSetZero(y, (n % 2 == 0 || VpIsPosInf(x)) ? 1 : -1);
	goto Exit;
    }

    if (x->exponent == 1 && x->Prec == 1 && x->frac[0] == 1) {
	/* abs(x) = 1 */
	VpSetOne(y);
	if (BIGDECIMAL_POSITIVE_P(x)) goto Exit;
	if ((n % 2) == 0) goto Exit;
	VpSetSign(y, -1);
	goto Exit;
    }

    if (n > 0) sign = 1;
    else if (n < 0) {
	sign = -1;
	n = -n;
    }
    else {
	VpSetOne(y);
	goto Exit;
    }

    /* Allocate working variables  */
    /* TODO: reconsider MaxPrec of w1 and w2 */
    w1 = NewZeroNolimit(1, (y->MaxPrec + 2) * BASE_FIG);
    w2 = NewZeroNolimit(1, (w1->MaxPrec * 2 + 1) * BASE_FIG);

    /* calculation start */

    VpAsgn(y, x, 1);
    --n;
    while (n > 0) {
	VpAsgn(w1, x, 1);
	s = 1;
	while (ss = s, (s += s) <= (size_t)n) {
	    VpMult(w2, w1, w1);
	    VpAsgn(w1, w2, 1);
	}
	n -= (SIGNED_VALUE)ss;
	VpMult(w2, y, w1);
	VpAsgn(y, w2, 1);
    }
    if (sign < 0) {
	VpDivd(w1, w2, VpConstOne, y);
	VpAsgn(y, w1, 1);
    }

Exit:
#ifdef BIGDECIMAL_DEBUG
    if (gfDebug) {
	VPrint(stdout, "VpPowerByInt y=%\n", y);
	VPrint(stdout, "VpPowerByInt x=%\n", x);
	printf("  n=%"PRIdVALUE"\n", n);
    }
#endif /* BIGDECIMAL_DEBUG */
    rbd_free_struct(w2);
    rbd_free_struct(w1);
    return 1;
}

#ifdef BIGDECIMAL_DEBUG
int
VpVarCheck(Real * v)
/*
 * Checks the validity of the Real variable v.
 * [Input]
 *   v ... Real *, variable to be checked.
 * [Returns]
 *   0  ... correct v.
 *   other ... error
 */
{
    size_t i;

    if (v->MaxPrec == 0) {
	printf("ERROR(VpVarCheck): Illegal Max. Precision(=%"PRIuSIZE")\n",
	       v->MaxPrec);
	return 1;
    }
    if (v->Prec == 0 || v->Prec > v->MaxPrec) {
	printf("ERROR(VpVarCheck): Illegal Precision(=%"PRIuSIZE")\n", v->Prec);
	printf("       Max. Prec.=%"PRIuSIZE"\n", v->MaxPrec);
	return 2;
    }
    for (i = 0; i < v->Prec; ++i) {
	if (v->frac[i] >= BASE) {
            printf("ERROR(VpVarCheck): Illegal fraction\n");
            printf("       Frac[%"PRIuSIZE"]=%"PRIuDECDIG"\n", i, v->frac[i]);
            printf("       Prec.   =%"PRIuSIZE"\n", v->Prec);
            printf("       Exp. =%"PRIdVALUE"\n", v->exponent);
            printf("       BASE =%"PRIuDECDIG"\n", BASE);
            return 3;
	}
    }
    return 0;
}
#endif /* BIGDECIMAL_DEBUG */
