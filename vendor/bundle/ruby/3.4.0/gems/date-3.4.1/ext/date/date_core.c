/*
  date_core.c: Coded by Tadayoshi Funaba 2010-2014
*/

#include "ruby.h"
#include "ruby/encoding.h"
#include "ruby/util.h"
#include <math.h>
#include <time.h>
#if defined(HAVE_SYS_TIME_H)
#include <sys/time.h>
#endif

#undef NDEBUG
#define NDEBUG
#include <assert.h>

#ifdef RUBY_EXTCONF_H
#include RUBY_EXTCONF_H
#endif

#define USE_PACK

static ID id_cmp, id_le_p, id_ge_p, id_eqeq_p;
static VALUE cDate, cDateTime;
static VALUE eDateError;
static VALUE half_days_in_day, day_in_nanoseconds;
static double positive_inf, negative_inf;

// used by deconstruct_keys
static VALUE sym_year, sym_month, sym_day, sym_yday, sym_wday;
static VALUE sym_hour, sym_min, sym_sec, sym_sec_fraction, sym_zone;

#define f_boolcast(x) ((x) ? Qtrue : Qfalse)

#define f_abs(x) rb_funcall(x, rb_intern("abs"), 0)
#define f_negate(x) rb_funcall(x, rb_intern("-@"), 0)
#define f_add(x,y) rb_funcall(x, '+', 1, y)
#define f_sub(x,y) rb_funcall(x, '-', 1, y)
#define f_mul(x,y) rb_funcall(x, '*', 1, y)
#define f_div(x,y) rb_funcall(x, '/', 1, y)
#define f_quo(x,y) rb_funcall(x, rb_intern("quo"), 1, y)
#define f_idiv(x,y) rb_funcall(x, rb_intern("div"), 1, y)
#define f_mod(x,y) rb_funcall(x, '%', 1, y)
#define f_remainder(x,y) rb_funcall(x, rb_intern("remainder"), 1, y)
#define f_expt(x,y) rb_funcall(x, rb_intern("**"), 1, y)
#define f_floor(x) rb_funcall(x, rb_intern("floor"), 0)
#define f_ceil(x) rb_funcall(x, rb_intern("ceil"), 0)
#define f_truncate(x) rb_funcall(x, rb_intern("truncate"), 0)
#define f_round(x) rb_funcall(x, rb_intern("round"), 0)

#define f_to_i(x) rb_funcall(x, rb_intern("to_i"), 0)
#define f_to_r(x) rb_funcall(x, rb_intern("to_r"), 0)
#define f_to_s(x) rb_funcall(x, rb_intern("to_s"), 0)
#define f_inspect(x) rb_funcall(x, rb_intern("inspect"), 0)

#define f_add3(x,y,z) f_add(f_add(x, y), z)
#define f_sub3(x,y,z) f_sub(f_sub(x, y), z)

#define f_frozen_ary(...) rb_ary_freeze(rb_ary_new3(__VA_ARGS__))

static VALUE date_initialize(int argc, VALUE *argv, VALUE self);
static VALUE datetime_initialize(int argc, VALUE *argv, VALUE self);

#define RETURN_FALSE_UNLESS_NUMERIC(obj) if(!RTEST(rb_obj_is_kind_of((obj), rb_cNumeric))) return Qfalse
inline static void
check_numeric(VALUE obj, const char* field)
{
    if(!RTEST(rb_obj_is_kind_of(obj, rb_cNumeric))) {
        rb_raise(rb_eTypeError, "invalid %s (not numeric)", field);
    }
}

inline static int
f_cmp(VALUE x, VALUE y)
{
    if (FIXNUM_P(x) && FIXNUM_P(y)) {
	long c = FIX2LONG(x) - FIX2LONG(y);
	if (c > 0)
	    return 1;
	else if (c < 0)
	    return -1;
	return 0;
    }
    return rb_cmpint(rb_funcallv(x, id_cmp, 1, &y), x, y);
}

inline static VALUE
f_lt_p(VALUE x, VALUE y)
{
    if (FIXNUM_P(x) && FIXNUM_P(y))
	return f_boolcast(FIX2LONG(x) < FIX2LONG(y));
    return rb_funcall(x, '<', 1, y);
}

inline static VALUE
f_gt_p(VALUE x, VALUE y)
{
    if (FIXNUM_P(x) && FIXNUM_P(y))
	return f_boolcast(FIX2LONG(x) > FIX2LONG(y));
    return rb_funcall(x, '>', 1, y);
}

inline static VALUE
f_le_p(VALUE x, VALUE y)
{
    if (FIXNUM_P(x) && FIXNUM_P(y))
	return f_boolcast(FIX2LONG(x) <= FIX2LONG(y));
    return rb_funcall(x, id_le_p, 1, y);
}

inline static VALUE
f_ge_p(VALUE x, VALUE y)
{
    if (FIXNUM_P(x) && FIXNUM_P(y))
	return f_boolcast(FIX2LONG(x) >= FIX2LONG(y));
    return rb_funcall(x, id_ge_p, 1, y);
}

inline static VALUE
f_eqeq_p(VALUE x, VALUE y)
{
    if (FIXNUM_P(x) && FIXNUM_P(y))
	return f_boolcast(FIX2LONG(x) == FIX2LONG(y));
    return rb_funcall(x, id_eqeq_p, 1, y);
}

inline static VALUE
f_zero_p(VALUE x)
{
    switch (TYPE(x)) {
      case T_FIXNUM:
	return f_boolcast(FIX2LONG(x) == 0);
      case T_BIGNUM:
	return Qfalse;
      case T_RATIONAL:
	{
	    VALUE num = rb_rational_num(x);
	    return f_boolcast(FIXNUM_P(num) && FIX2LONG(num) == 0);
	}
    }
    return rb_funcall(x, id_eqeq_p, 1, INT2FIX(0));
}

#define f_nonzero_p(x) (!f_zero_p(x))

inline static VALUE
f_negative_p(VALUE x)
{
    if (FIXNUM_P(x))
	return f_boolcast(FIX2LONG(x) < 0);
    return rb_funcall(x, '<', 1, INT2FIX(0));
}

#define f_positive_p(x) (!f_negative_p(x))

#define f_ajd(x) rb_funcall(x, rb_intern("ajd"), 0)
#define f_jd(x) rb_funcall(x, rb_intern("jd"), 0)
#define f_year(x) rb_funcall(x, rb_intern("year"), 0)
#define f_mon(x) rb_funcall(x, rb_intern("mon"), 0)
#define f_mday(x) rb_funcall(x, rb_intern("mday"), 0)
#define f_wday(x) rb_funcall(x, rb_intern("wday"), 0)
#define f_hour(x) rb_funcall(x, rb_intern("hour"), 0)
#define f_min(x) rb_funcall(x, rb_intern("min"), 0)
#define f_sec(x) rb_funcall(x, rb_intern("sec"), 0)

/* copied from time.c */
#define NDIV(x,y) (-(-((x)+1)/(y))-1)
#define NMOD(x,y) ((y)-(-((x)+1)%(y))-1)
#define DIV(n,d) ((n)<0 ? NDIV((n),(d)) : (n)/(d))
#define MOD(n,d) ((n)<0 ? NMOD((n),(d)) : (n)%(d))

#define HAVE_JD     (1 << 0)
#define HAVE_DF     (1 << 1)
#define HAVE_CIVIL  (1 << 2)
#define HAVE_TIME   (1 << 3)
#define COMPLEX_DAT (1 << 7)

#define have_jd_p(x) ((x)->flags & HAVE_JD)
#define have_df_p(x) ((x)->flags & HAVE_DF)
#define have_civil_p(x) ((x)->flags & HAVE_CIVIL)
#define have_time_p(x) ((x)->flags & HAVE_TIME)
#define complex_dat_p(x) ((x)->flags & COMPLEX_DAT)
#define simple_dat_p(x) (!complex_dat_p(x))

#define ITALY 2299161 /* 1582-10-15 */
#define ENGLAND 2361222 /* 1752-09-14 */
#define JULIAN positive_inf
#define GREGORIAN negative_inf
#define DEFAULT_SG ITALY

#define UNIX_EPOCH_IN_CJD INT2FIX(2440588) /* 1970-01-01 */

#define MINUTE_IN_SECONDS 60
#define HOUR_IN_SECONDS 3600
#define DAY_IN_SECONDS 86400
#define SECOND_IN_MILLISECONDS 1000
#define SECOND_IN_NANOSECONDS 1000000000

#define JC_PERIOD0 1461		/* 365.25 * 4 */
#define GC_PERIOD0 146097	/* 365.2425 * 400 */
#define CM_PERIOD0 71149239	/* (lcm 7 1461 146097) */
#define CM_PERIOD (0xfffffff / CM_PERIOD0 * CM_PERIOD0)
#define CM_PERIOD_JCY (CM_PERIOD / JC_PERIOD0 * 4)
#define CM_PERIOD_GCY (CM_PERIOD / GC_PERIOD0 * 400)

#define REFORM_BEGIN_YEAR 1582
#define REFORM_END_YEAR   1930
#define REFORM_BEGIN_JD 2298874	/* ns 1582-01-01 */
#define REFORM_END_JD   2426355	/* os 1930-12-31 */

#ifdef USE_PACK
#define SEC_WIDTH  6
#define MIN_WIDTH  6
#define HOUR_WIDTH 5
#define MDAY_WIDTH 5
#define MON_WIDTH  4

#define SEC_SHIFT  0
#define MIN_SHIFT  SEC_WIDTH
#define HOUR_SHIFT (MIN_WIDTH + SEC_WIDTH)
#define MDAY_SHIFT (HOUR_WIDTH + MIN_WIDTH + SEC_WIDTH)
#define MON_SHIFT  (MDAY_WIDTH + HOUR_WIDTH + MIN_WIDTH + SEC_WIDTH)

#define PK_MASK(x) ((1 << (x)) - 1)

#define EX_SEC(x)  (((x) >> SEC_SHIFT)  & PK_MASK(SEC_WIDTH))
#define EX_MIN(x)  (((x) >> MIN_SHIFT)  & PK_MASK(MIN_WIDTH))
#define EX_HOUR(x) (((x) >> HOUR_SHIFT) & PK_MASK(HOUR_WIDTH))
#define EX_MDAY(x) (((x) >> MDAY_SHIFT) & PK_MASK(MDAY_WIDTH))
#define EX_MON(x)  (((x) >> MON_SHIFT)  & PK_MASK(MON_WIDTH))

#define PACK5(m,d,h,min,s) \
    (((m) << MON_SHIFT) | ((d) << MDAY_SHIFT) |\
     ((h) << HOUR_SHIFT) | ((min) << MIN_SHIFT) | ((s) << SEC_SHIFT))

#define PACK2(m,d) \
    (((m) << MON_SHIFT) | ((d) << MDAY_SHIFT))
#endif

#ifdef HAVE_FLOAT_H
#include <float.h>
#endif

#if defined(FLT_RADIX) && defined(FLT_MANT_DIG) && FLT_RADIX == 2 && FLT_MANT_DIG > 22
#define date_sg_t float
#else
#define date_sg_t double
#endif

#define JULIAN_EPOCH_DATE "-4712-01-01"
#define JULIAN_EPOCH_DATETIME JULIAN_EPOCH_DATE "T00:00:00+00:00"
#define JULIAN_EPOCH_DATETIME_RFC3339 "Mon, 1 Jan -4712 00:00:00 +0000"
#define JULIAN_EPOCH_DATETIME_HTTPDATE "Mon, 01 Jan -4712 00:00:00 GMT"

/* A set of nth, jd, df and sf denote ajd + 1/2.  Each ajd begin at
 * noon of GMT (assume equal to UTC).  However, this begins at
 * midnight.
 */

struct SimpleDateData
{
    unsigned flags;
    int jd;	/* as utc */
    VALUE nth;	/* not always canonicalized */
    date_sg_t sg;  /* 2298874..2426355 or -/+oo -- at most 22 bits */
    /* decoded as utc=local */
    int year;	/* truncated */
#ifndef USE_PACK
    int mon;
    int mday;
    /* hour is zero */
    /* min is zero */
    /* sec is zero */
#else
    /* packed civil */
    unsigned pc;
#endif
};

struct ComplexDateData
{
    unsigned flags;
    int jd; 	/* as utc */
    VALUE nth;	/* not always canonicalized */
    date_sg_t sg;  /* 2298874..2426355 or -/+oo -- at most 22 bits */
    /* decoded as local */
    int year;	/* truncated */
#ifndef USE_PACK
    int mon;
    int mday;
    int hour;
    int min;
    int sec;
#else
    /* packed civil */
    unsigned pc;
#endif
    int df;	/* as utc, in secs */
    int of;	/* in secs */
    VALUE sf;	/* in nano secs */
};

union DateData {
    unsigned flags;
    struct SimpleDateData s;
    struct ComplexDateData c;
};

#define get_d1(x)\
    union DateData *dat;\
    TypedData_Get_Struct(x, union DateData, &d_lite_type, dat);

#define get_d1a(x)\
    union DateData *adat;\
    TypedData_Get_Struct(x, union DateData, &d_lite_type, adat);

#define get_d1b(x)\
    union DateData *bdat;\
    TypedData_Get_Struct(x, union DateData, &d_lite_type, bdat);

#define get_d2(x,y)\
    union DateData *adat, *bdat;\
    TypedData_Get_Struct(x, union DateData, &d_lite_type, adat);\
    TypedData_Get_Struct(y, union DateData, &d_lite_type, bdat);

inline static VALUE
canon(VALUE x)
{
    if (RB_TYPE_P(x, T_RATIONAL)) {
	VALUE den = rb_rational_den(x);
	if (FIXNUM_P(den) && FIX2LONG(den) == 1)
	    return rb_rational_num(x);
    }
    return x;
}

#ifndef USE_PACK
#define set_to_simple(obj, x, _nth, _jd ,_sg, _year, _mon, _mday, _flags) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, canon(_nth)); \
    (x)->jd = _jd;\
    (x)->sg = (date_sg_t)(_sg);\
    (x)->year = _year;\
    (x)->mon = _mon;\
    (x)->mday = _mday;\
    (x)->flags = (_flags) & ~COMPLEX_DAT;\
} while (0)
#else
#define set_to_simple(obj, x, _nth, _jd ,_sg, _year, _mon, _mday, _flags) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, canon(_nth)); \
    (x)->jd = _jd;\
    (x)->sg = (date_sg_t)(_sg);\
    (x)->year = _year;\
    (x)->pc = PACK2(_mon, _mday);\
    (x)->flags = (_flags) & ~COMPLEX_DAT;\
} while (0)
#endif

#ifndef USE_PACK
#define set_to_complex(obj, x, _nth, _jd ,_df, _sf, _of, _sg,\
_year, _mon, _mday, _hour, _min, _sec, _flags) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, canon(_nth));\
    (x)->jd = _jd;\
    (x)->df = _df;\
    RB_OBJ_WRITE((obj), &(x)->sf, canon(_sf));\
    (x)->of = _of;\
    (x)->sg = (date_sg_t)(_sg);\
    (x)->year = _year;\
    (x)->mon = _mon;\
    (x)->mday = _mday;\
    (x)->hour = _hour;\
    (x)->min = _min;\
    (x)->sec = _sec;\
    (x)->flags = (_flags) | COMPLEX_DAT;\
} while (0)
#else
#define set_to_complex(obj, x, _nth, _jd ,_df, _sf, _of, _sg,\
_year, _mon, _mday, _hour, _min, _sec, _flags) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, canon(_nth));\
    (x)->jd = _jd;\
    (x)->df = _df;\
    RB_OBJ_WRITE((obj), &(x)->sf, canon(_sf));\
    (x)->of = _of;\
    (x)->sg = (date_sg_t)(_sg);\
    (x)->year = _year;\
    (x)->pc = PACK5(_mon, _mday, _hour, _min, _sec);\
    (x)->flags = (_flags) | COMPLEX_DAT;\
} while (0)
#endif

#ifndef USE_PACK
#define copy_simple_to_complex(obj, x, y) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, (y)->nth);\
    (x)->jd = (y)->jd;\
    (x)->df = 0;\
    (x)->sf = INT2FIX(0);\
    (x)->of = 0;\
    (x)->sg = (date_sg_t)((y)->sg);\
    (x)->year = (y)->year;\
    (x)->mon = (y)->mon;\
    (x)->mday = (y)->mday;\
    (x)->hour = 0;\
    (x)->min = 0;\
    (x)->sec = 0;\
    (x)->flags = (y)->flags;\
} while (0)
#else
#define copy_simple_to_complex(obj, x, y) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, (y)->nth);\
    (x)->jd = (y)->jd;\
    (x)->df = 0;\
    RB_OBJ_WRITE((obj), &(x)->sf, INT2FIX(0));\
    (x)->of = 0;\
    (x)->sg = (date_sg_t)((y)->sg);\
    (x)->year = (y)->year;\
    (x)->pc = PACK5(EX_MON((y)->pc), EX_MDAY((y)->pc), 0, 0, 0);\
    (x)->flags = (y)->flags;\
} while (0)
#endif

#ifndef USE_PACK
#define copy_complex_to_simple(obj, x, y) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, (y)->nth);\
    (x)->jd = (y)->jd;\
    (x)->sg = (date_sg_t)((y)->sg);\
    (x)->year = (y)->year;\
    (x)->mon = (y)->mon;\
    (x)->mday = (y)->mday;\
    (x)->flags = (y)->flags;\
} while (0)
#else
#define copy_complex_to_simple(obj, x, y) \
do {\
    RB_OBJ_WRITE((obj), &(x)->nth, (y)->nth);\
    (x)->jd = (y)->jd;\
    (x)->sg = (date_sg_t)((y)->sg);\
    (x)->year = (y)->year;\
    (x)->pc = PACK2(EX_MON((y)->pc), EX_MDAY((y)->pc));\
    (x)->flags = (y)->flags;\
} while (0)
#endif

/* base */

static int c_valid_civil_p(int, int, int, double,
			   int *, int *, int *, int *);

static int
c_find_fdoy(int y, double sg, int *rjd, int *ns)
{
    int d, rm, rd;

    for (d = 1; d < 31; d++)
	if (c_valid_civil_p(y, 1, d, sg, &rm, &rd, rjd, ns))
	    return 1;
    return 0;
}

static int
c_find_ldoy(int y, double sg, int *rjd, int *ns)
{
    int i, rm, rd;

    for (i = 0; i < 30; i++)
	if (c_valid_civil_p(y, 12, 31 - i, sg, &rm, &rd, rjd, ns))
	    return 1;
    return 0;
}

#ifndef NDEBUG
/* :nodoc: */
static int
c_find_fdom(int y, int m, double sg, int *rjd, int *ns)
{
    int d, rm, rd;

    for (d = 1; d < 31; d++)
	if (c_valid_civil_p(y, m, d, sg, &rm, &rd, rjd, ns))
	    return 1;
    return 0;
}
#endif

static int
c_find_ldom(int y, int m, double sg, int *rjd, int *ns)
{
    int i, rm, rd;

    for (i = 0; i < 30; i++)
	if (c_valid_civil_p(y, m, 31 - i, sg, &rm, &rd, rjd, ns))
	    return 1;
    return 0;
}

static void
c_civil_to_jd(int y, int m, int d, double sg, int *rjd, int *ns)
{
    double a, b, jd;

    if (m <= 2) {
	y -= 1;
	m += 12;
    }
    a = floor(y / 100.0);
    b = 2 - a + floor(a / 4.0);
    jd = floor(365.25 * (y + 4716)) +
	floor(30.6001 * (m + 1)) +
	d + b - 1524;
    if (jd < sg) {
	jd -= b;
	*ns = 0;
    }
    else
	*ns = 1;

    *rjd = (int)jd;
}

static void
c_jd_to_civil(int jd, double sg, int *ry, int *rm, int *rdom)
{
    double x, a, b, c, d, e, y, m, dom;

    if (jd < sg)
	a = jd;
    else {
	x = floor((jd - 1867216.25) / 36524.25);
	a = jd + 1 + x - floor(x / 4.0);
    }
    b = a + 1524;
    c = floor((b - 122.1) / 365.25);
    d = floor(365.25 * c);
    e = floor((b - d) / 30.6001);
    dom = b - d - floor(30.6001 * e);
    if (e <= 13) {
	m = e - 1;
	y = c - 4716;
    }
    else {
	m = e - 13;
	y = c - 4715;
    }

    *ry = (int)y;
    *rm = (int)m;
    *rdom = (int)dom;
}

static void
c_ordinal_to_jd(int y, int d, double sg, int *rjd, int *ns)
{
    int ns2;

    c_find_fdoy(y, sg, rjd, &ns2);
    *rjd += d - 1;
    *ns = (*rjd < sg) ? 0 : 1;
}

static void
c_jd_to_ordinal(int jd, double sg, int *ry, int *rd)
{
    int rm2, rd2, rjd, ns;

    c_jd_to_civil(jd, sg, ry, &rm2, &rd2);
    c_find_fdoy(*ry, sg, &rjd, &ns);
    *rd = (jd - rjd) + 1;
}

static void
c_commercial_to_jd(int y, int w, int d, double sg, int *rjd, int *ns)
{
    int rjd2, ns2;

    c_find_fdoy(y, sg, &rjd2, &ns2);
    rjd2 += 3;
    *rjd =
	(rjd2 - MOD((rjd2 - 1) + 1, 7)) +
	7 * (w - 1) +
	(d - 1);
    *ns = (*rjd < sg) ? 0 : 1;
}

static void
c_jd_to_commercial(int jd, double sg, int *ry, int *rw, int *rd)
{
    int ry2, rm2, rd2, a, rjd2, ns2;

    c_jd_to_civil(jd - 3, sg, &ry2, &rm2, &rd2);
    a = ry2;
    c_commercial_to_jd(a + 1, 1, 1, sg, &rjd2, &ns2);
    if (jd >= rjd2)
	*ry = a + 1;
    else {
	c_commercial_to_jd(a, 1, 1, sg, &rjd2, &ns2);
	*ry = a;
    }
    *rw = 1 + DIV(jd - rjd2, 7);
    *rd = MOD(jd + 1, 7);
    if (*rd == 0)
	*rd = 7;
}

static void
c_weeknum_to_jd(int y, int w, int d, int f, double sg, int *rjd, int *ns)
{
    int rjd2, ns2;

    c_find_fdoy(y, sg, &rjd2, &ns2);
    rjd2 += 6;
    *rjd = (rjd2 - MOD(((rjd2 - f) + 1), 7) - 7) + 7 * w + d;
    *ns = (*rjd < sg) ? 0 : 1;
}

static void
c_jd_to_weeknum(int jd, int f, double sg, int *ry, int *rw, int *rd)
{
    int rm, rd2, rjd, ns, j;

    c_jd_to_civil(jd, sg, ry, &rm, &rd2);
    c_find_fdoy(*ry, sg, &rjd, &ns);
    rjd += 6;
    j = jd - (rjd - MOD((rjd - f) + 1, 7)) + 7;
    *rw = (int)DIV(j, 7);
    *rd = (int)MOD(j, 7);
}

#ifndef NDEBUG
/* :nodoc: */
static void
c_nth_kday_to_jd(int y, int m, int n, int k, double sg, int *rjd, int *ns)
{
    int rjd2, ns2;

    if (n > 0) {
	c_find_fdom(y, m, sg, &rjd2, &ns2);
	rjd2 -= 1;
    }
    else {
	c_find_ldom(y, m, sg, &rjd2, &ns2);
	rjd2 += 7;
    }
    *rjd = (rjd2 - MOD((rjd2 - k) + 1, 7)) + 7 * n;
    *ns = (*rjd < sg) ? 0 : 1;
}
#endif

inline static int
c_jd_to_wday(int jd)
{
    return MOD(jd + 1, 7);
}

#ifndef NDEBUG
/* :nodoc: */
static void
c_jd_to_nth_kday(int jd, double sg, int *ry, int *rm, int *rn, int *rk)
{
    int rd, rjd, ns2;

    c_jd_to_civil(jd, sg, ry, rm, &rd);
    c_find_fdom(*ry, *rm, sg, &rjd, &ns2);
    *rn = DIV(jd - rjd, 7) + 1;
    *rk = c_jd_to_wday(jd);
}
#endif

static int
c_valid_ordinal_p(int y, int d, double sg,
		  int *rd, int *rjd, int *ns)
{
    int ry2, rd2;

    if (d < 0) {
	int rjd2, ns2;

	if (!c_find_ldoy(y, sg, &rjd2, &ns2))
	    return 0;
	c_jd_to_ordinal(rjd2 + d + 1, sg, &ry2, &rd2);
	if (ry2 != y)
	    return 0;
	d = rd2;
    }
    c_ordinal_to_jd(y, d, sg, rjd, ns);
    c_jd_to_ordinal(*rjd, sg, &ry2, &rd2);
    if (ry2 != y || rd2 != d)
	return 0;
    return 1;
}

static const int monthtab[2][13] = {
    { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
    { 0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
};

inline static int
c_julian_leap_p(int y)
{
    return MOD(y, 4) == 0;
}

inline static int
c_gregorian_leap_p(int y)
{
    return (MOD(y, 4) == 0 && y % 100 != 0) || MOD(y, 400) == 0;
}

static int
c_julian_last_day_of_month(int y, int m)
{
    assert(m >= 1 && m <= 12);
    return monthtab[c_julian_leap_p(y) ? 1 : 0][m];
}

static int
c_gregorian_last_day_of_month(int y, int m)
{
    assert(m >= 1 && m <= 12);
    return monthtab[c_gregorian_leap_p(y) ? 1 : 0][m];
}

static int
c_valid_julian_p(int y, int m, int d, int *rm, int *rd)
{
    int last;

    if (m < 0)
	m += 13;
    if (m < 1 || m > 12)
	return 0;
    last = c_julian_last_day_of_month(y, m);
    if (d < 0)
	d = last + d + 1;
    if (d < 1 || d > last)
	return 0;
    *rm = m;
    *rd = d;
    return 1;
}

static int
c_valid_gregorian_p(int y, int m, int d, int *rm, int *rd)
{
    int last;

    if (m < 0)
	m += 13;
    if (m < 1 || m > 12)
	return 0;
    last = c_gregorian_last_day_of_month(y, m);
    if (d < 0)
	d = last + d + 1;
    if (d < 1 || d > last)
	return 0;
    *rm = m;
    *rd = d;
    return 1;
}

static int
c_valid_civil_p(int y, int m, int d, double sg,
		int *rm, int *rd, int *rjd, int *ns)
{
    int ry;

    if (m < 0)
	m += 13;
    if (m < 1 || m > 12)
	return 0;
    if (d < 0) {
	if (!c_find_ldom(y, m, sg, rjd, ns))
	    return 0;
	c_jd_to_civil(*rjd + d + 1, sg, &ry, rm, rd);
	if (ry != y || *rm != m)
	    return 0;
	d = *rd;
    }
    c_civil_to_jd(y, m, d, sg, rjd, ns);
    c_jd_to_civil(*rjd, sg, &ry, rm, rd);
    if (ry != y || *rm != m || *rd != d)
	return 0;
    return 1;
}

static int
c_valid_commercial_p(int y, int w, int d, double sg,
		     int *rw, int *rd, int *rjd, int *ns)
{
    int ns2, ry2, rw2, rd2;

    if (d < 0)
	d += 8;
    if (w < 0) {
	int rjd2;

	c_commercial_to_jd(y + 1, 1, 1, sg, &rjd2, &ns2);
	c_jd_to_commercial(rjd2 + w * 7, sg, &ry2, &rw2, &rd2);
	if (ry2 != y)
	    return 0;
	w = rw2;
    }
    c_commercial_to_jd(y, w, d, sg, rjd, ns);
    c_jd_to_commercial(*rjd, sg, &ry2, rw, rd);
    if (y != ry2 || w != *rw || d != *rd)
	return 0;
    return 1;
}

static int
c_valid_weeknum_p(int y, int w, int d, int f, double sg,
		  int *rw, int *rd, int *rjd, int *ns)
{
    int ns2, ry2, rw2, rd2;

    if (d < 0)
	d += 7;
    if (w < 0) {
	int rjd2;

	c_weeknum_to_jd(y + 1, 1, f, f, sg, &rjd2, &ns2);
	c_jd_to_weeknum(rjd2 + w * 7, f, sg, &ry2, &rw2, &rd2);
	if (ry2 != y)
	    return 0;
	w = rw2;
    }
    c_weeknum_to_jd(y, w, d, f, sg, rjd, ns);
    c_jd_to_weeknum(*rjd, f, sg, &ry2, rw, rd);
    if (y != ry2 || w != *rw || d != *rd)
	return 0;
    return 1;
}

#ifndef NDEBUG
/* :nodoc: */
static int
c_valid_nth_kday_p(int y, int m, int n, int k, double sg,
		   int *rm, int *rn, int *rk, int *rjd, int *ns)
{
    int ns2, ry2, rm2, rn2, rk2;

    if (k < 0)
	k += 7;
    if (n < 0) {
	int t, ny, nm, rjd2;

	t = y * 12 + m;
	ny = DIV(t, 12);
	nm = MOD(t, 12) + 1;

	c_nth_kday_to_jd(ny, nm, 1, k, sg, &rjd2, &ns2);
	c_jd_to_nth_kday(rjd2 + n * 7, sg, &ry2, &rm2, &rn2, &rk2);
	if (ry2 != y || rm2 != m)
	    return 0;
	n = rn2;
    }
    c_nth_kday_to_jd(y, m, n, k, sg, rjd, ns);
    c_jd_to_nth_kday(*rjd, sg, &ry2, rm, rn, rk);
    if (y != ry2 || m != *rm || n != *rn || k != *rk)
	return 0;
    return 1;
}
#endif

static int
c_valid_time_p(int h, int min, int s, int *rh, int *rmin, int *rs)
{
    if (h < 0)
	h += 24;
    if (min < 0)
	min += 60;
    if (s < 0)
	s += 60;
    *rh = h;
    *rmin = min;
    *rs = s;
    return !(h   < 0 || h   > 24 ||
	     min < 0 || min > 59 ||
	     s   < 0 || s   > 59 ||
	     (h == 24 && (min > 0 || s > 0)));
}

inline static int
c_valid_start_p(double sg)
{
    if (isnan(sg))
	return 0;
    if (isinf(sg))
	return 1;
    if (sg < REFORM_BEGIN_JD || sg > REFORM_END_JD)
	return 0;
    return 1;
}

inline static int
df_local_to_utc(int df, int of)
{
    df -= of;
    if (df < 0)
	df += DAY_IN_SECONDS;
    else if (df >= DAY_IN_SECONDS)
	df -= DAY_IN_SECONDS;
    return df;
}

inline static int
df_utc_to_local(int df, int of)
{
    df += of;
    if (df < 0)
	df += DAY_IN_SECONDS;
    else if (df >= DAY_IN_SECONDS)
	df -= DAY_IN_SECONDS;
    return df;
}

inline static int
jd_local_to_utc(int jd, int df, int of)
{
    df -= of;
    if (df < 0)
	jd -= 1;
    else if (df >= DAY_IN_SECONDS)
	jd += 1;
    return jd;
}

inline static int
jd_utc_to_local(int jd, int df, int of)
{
    df += of;
    if (df < 0)
	jd -= 1;
    else if (df >= DAY_IN_SECONDS)
	jd += 1;
    return jd;
}

inline static int
time_to_df(int h, int min, int s)
{
    return h * HOUR_IN_SECONDS + min * MINUTE_IN_SECONDS + s;
}

inline static void
df_to_time(int df, int *h, int *min, int *s)
{
    *h = df / HOUR_IN_SECONDS;
    df %= HOUR_IN_SECONDS;
    *min = df / MINUTE_IN_SECONDS;
    *s = df % MINUTE_IN_SECONDS;
}

static VALUE
sec_to_day(VALUE s)
{
    if (FIXNUM_P(s))
	return rb_rational_new2(s, INT2FIX(DAY_IN_SECONDS));
    return f_quo(s, INT2FIX(DAY_IN_SECONDS));
}

inline static VALUE
isec_to_day(int s)
{
    return sec_to_day(INT2FIX(s));
}

static VALUE
ns_to_day(VALUE n)
{
    if (FIXNUM_P(n))
	return rb_rational_new2(n, day_in_nanoseconds);
    return f_quo(n, day_in_nanoseconds);
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
ms_to_sec(VALUE m)
{
    if (FIXNUM_P(m))
	return rb_rational_new2(m, INT2FIX(SECOND_IN_MILLISECONDS));
    return f_quo(m, INT2FIX(SECOND_IN_MILLISECONDS));
}
#endif

static VALUE
ns_to_sec(VALUE n)
{
    if (FIXNUM_P(n))
	return rb_rational_new2(n, INT2FIX(SECOND_IN_NANOSECONDS));
    return f_quo(n, INT2FIX(SECOND_IN_NANOSECONDS));
}

#ifndef NDEBUG
/* :nodoc: */
inline static VALUE
ins_to_day(int n)
{
    return ns_to_day(INT2FIX(n));
}
#endif

static int
safe_mul_p(VALUE x, long m)
{
    long ix;

    if (!FIXNUM_P(x))
	return 0;
    ix = FIX2LONG(x);
    if (ix < 0) {
	if (ix <= (FIXNUM_MIN / m))
	    return 0;
    }
    else {
	if (ix >= (FIXNUM_MAX / m))
	    return 0;
    }
    return 1;
}

static VALUE
day_to_sec(VALUE d)
{
    if (safe_mul_p(d, DAY_IN_SECONDS))
	return LONG2FIX(FIX2LONG(d) * DAY_IN_SECONDS);
    return f_mul(d, INT2FIX(DAY_IN_SECONDS));
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
day_to_ns(VALUE d)
{
    return f_mul(d, day_in_nanoseconds);
}
#endif

static VALUE
sec_to_ms(VALUE s)
{
    if (safe_mul_p(s, SECOND_IN_MILLISECONDS))
	return LONG2FIX(FIX2LONG(s) * SECOND_IN_MILLISECONDS);
    return f_mul(s, INT2FIX(SECOND_IN_MILLISECONDS));
}

static VALUE
sec_to_ns(VALUE s)
{
    if (safe_mul_p(s, SECOND_IN_NANOSECONDS))
	return LONG2FIX(FIX2LONG(s) * SECOND_IN_NANOSECONDS);
    return f_mul(s, INT2FIX(SECOND_IN_NANOSECONDS));
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
isec_to_ns(int s)
{
    return sec_to_ns(INT2FIX(s));
}
#endif

static VALUE
div_day(VALUE d, VALUE *f)
{
    if (f)
	*f = f_mod(d, INT2FIX(1));
    return f_floor(d);
}

static VALUE
div_df(VALUE d, VALUE *f)
{
    VALUE s = day_to_sec(d);

    if (f)
	*f = f_mod(s, INT2FIX(1));
    return f_floor(s);
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
div_sf(VALUE s, VALUE *f)
{
    VALUE n = sec_to_ns(s);

    if (f)
	*f = f_mod(n, INT2FIX(1));
    return f_floor(n);
}
#endif

static void
decode_day(VALUE d, VALUE *jd, VALUE *df, VALUE *sf)
{
    VALUE f;

    *jd = div_day(d, &f);
    *df = div_df(f, &f);
    *sf = sec_to_ns(f);
}

inline static double
s_virtual_sg(union DateData *x)
{
    if (isinf(x->s.sg))
	return x->s.sg;
    if (f_zero_p(x->s.nth))
	return x->s.sg;
    else if (f_negative_p(x->s.nth))
	return positive_inf;
    return negative_inf;
}

inline static double
c_virtual_sg(union DateData *x)
{
    if (isinf(x->c.sg))
	return x->c.sg;
    if (f_zero_p(x->c.nth))
	return x->c.sg;
    else if (f_negative_p(x->c.nth))
	return positive_inf;
    return negative_inf;
}

inline static double
m_virtual_sg(union DateData *x)
{
    if (simple_dat_p(x))
	return s_virtual_sg(x);
    else
	return c_virtual_sg(x);
}

#define canonicalize_jd(_nth, _jd) \
do {\
    if (_jd < 0) {\
	_nth = f_sub(_nth, INT2FIX(1));\
	_jd += CM_PERIOD;\
    }\
    if (_jd >= CM_PERIOD) {\
	_nth = f_add(_nth, INT2FIX(1));\
	_jd -= CM_PERIOD;\
    }\
} while (0)

inline static void
canonicalize_s_jd(VALUE obj, union DateData *x)
{
    int j = x->s.jd;
    VALUE nth = x->s.nth;
    assert(have_jd_p(x));
    canonicalize_jd(nth, x->s.jd);
    RB_OBJ_WRITE(obj, &x->s.nth, nth);
    if (x->s.jd != j)
	x->flags &= ~HAVE_CIVIL;
}

inline static void
get_s_jd(union DateData *x)
{
    assert(simple_dat_p(x));
    if (!have_jd_p(x)) {
	int jd, ns;

	assert(have_civil_p(x));
#ifndef USE_PACK
	c_civil_to_jd(x->s.year, x->s.mon, x->s.mday,
		      s_virtual_sg(x), &jd, &ns);
#else
	c_civil_to_jd(x->s.year, EX_MON(x->s.pc), EX_MDAY(x->s.pc),
		      s_virtual_sg(x), &jd, &ns);
#endif
	x->s.jd = jd;
	x->s.flags |= HAVE_JD;
    }
}

inline static void
get_s_civil(union DateData *x)
{
    assert(simple_dat_p(x));
    if (!have_civil_p(x)) {
	int y, m, d;

	assert(have_jd_p(x));
	c_jd_to_civil(x->s.jd, s_virtual_sg(x), &y, &m, &d);
	x->s.year = y;
#ifndef USE_PACK
	x->s.mon = m;
	x->s.mday = d;
#else
	x->s.pc = PACK2(m, d);
#endif
	x->s.flags |= HAVE_CIVIL;
    }
}

inline static void
get_c_df(union DateData *x)
{
    assert(complex_dat_p(x));
    if (!have_df_p(x)) {
	assert(have_time_p(x));
#ifndef USE_PACK
	x->c.df = df_local_to_utc(time_to_df(x->c.hour, x->c.min, x->c.sec),
				  x->c.of);
#else
	x->c.df = df_local_to_utc(time_to_df(EX_HOUR(x->c.pc),
					     EX_MIN(x->c.pc),
					     EX_SEC(x->c.pc)),
				  x->c.of);
#endif
	x->c.flags |= HAVE_DF;
    }
}

inline static void
get_c_time(union DateData *x)
{
    assert(complex_dat_p(x));
    if (!have_time_p(x)) {
#ifndef USE_PACK
	int r;
	assert(have_df_p(x));
	r = df_utc_to_local(x->c.df, x->c.of);
	df_to_time(r, &x->c.hour, &x->c.min, &x->c.sec);
	x->c.flags |= HAVE_TIME;
#else
	int r, m, d, h, min, s;

	assert(have_df_p(x));
	m = EX_MON(x->c.pc);
	d = EX_MDAY(x->c.pc);
	r = df_utc_to_local(x->c.df, x->c.of);
	df_to_time(r, &h, &min, &s);
	x->c.pc = PACK5(m, d, h, min, s);
	x->c.flags |= HAVE_TIME;
#endif
    }
}

inline static void
canonicalize_c_jd(VALUE obj, union DateData *x)
{
    int j = x->c.jd;
    VALUE nth = x->c.nth;
    assert(have_jd_p(x));
    canonicalize_jd(nth, x->c.jd);
    RB_OBJ_WRITE(obj, &x->c.nth, nth);
    if (x->c.jd != j)
	x->flags &= ~HAVE_CIVIL;
}

inline static void
get_c_jd(union DateData *x)
{
    assert(complex_dat_p(x));
    if (!have_jd_p(x)) {
	int jd, ns;

	assert(have_civil_p(x));
#ifndef USE_PACK
	c_civil_to_jd(x->c.year, x->c.mon, x->c.mday,
		      c_virtual_sg(x), &jd, &ns);
#else
	c_civil_to_jd(x->c.year, EX_MON(x->c.pc), EX_MDAY(x->c.pc),
		      c_virtual_sg(x), &jd, &ns);
#endif

	get_c_time(x);
#ifndef USE_PACK
	x->c.jd = jd_local_to_utc(jd,
				  time_to_df(x->c.hour, x->c.min, x->c.sec),
				  x->c.of);
#else
	x->c.jd = jd_local_to_utc(jd,
				  time_to_df(EX_HOUR(x->c.pc),
					     EX_MIN(x->c.pc),
					     EX_SEC(x->c.pc)),
				  x->c.of);
#endif
	x->c.flags |= HAVE_JD;
    }
}

inline static void
get_c_civil(union DateData *x)
{
    assert(complex_dat_p(x));
    if (!have_civil_p(x)) {
#ifndef USE_PACK
	int jd, y, m, d;
#else
	int jd, y, m, d, h, min, s;
#endif

	assert(have_jd_p(x));
	get_c_df(x);
	jd = jd_utc_to_local(x->c.jd, x->c.df, x->c.of);
	c_jd_to_civil(jd, c_virtual_sg(x), &y, &m, &d);
	x->c.year = y;
#ifndef USE_PACK
	x->c.mon = m;
	x->c.mday = d;
#else
	h = EX_HOUR(x->c.pc);
	min = EX_MIN(x->c.pc);
	s = EX_SEC(x->c.pc);
	x->c.pc = PACK5(m, d, h, min, s);
#endif
	x->c.flags |= HAVE_CIVIL;
    }
}

inline static int
local_jd(union DateData *x)
{
    assert(complex_dat_p(x));
    assert(have_jd_p(x));
    assert(have_df_p(x));
    return jd_utc_to_local(x->c.jd, x->c.df, x->c.of);
}

inline static int
local_df(union DateData *x)
{
    assert(complex_dat_p(x));
    assert(have_df_p(x));
    return df_utc_to_local(x->c.df, x->c.of);
}

static void
decode_year(VALUE y, double style,
	    VALUE *nth, int *ry)
{
    int period;
    VALUE t;

    period = (style < 0) ?
	CM_PERIOD_GCY :
	CM_PERIOD_JCY;
    if (FIXNUM_P(y)) {
	long iy, it, inth;

	iy = FIX2LONG(y);
	if (iy >= (FIXNUM_MAX - 4712))
	    goto big;
	it = iy + 4712; /* shift */
	inth = DIV(it, ((long)period));
	*nth = LONG2FIX(inth);
	if (inth)
	    it = MOD(it, ((long)period));
	*ry = (int)it - 4712; /* unshift */
	return;
    }
  big:
    t = f_add(y, INT2FIX(4712)); /* shift */
    *nth = f_idiv(t, INT2FIX(period));
    if (f_nonzero_p(*nth))
	t = f_mod(t, INT2FIX(period));
    *ry = FIX2INT(t) - 4712; /* unshift */
}

static void
encode_year(VALUE nth, int y, double style,
	    VALUE *ry)
{
    int period;
    VALUE t;

    period = (style < 0) ?
	CM_PERIOD_GCY :
	CM_PERIOD_JCY;
    if (f_zero_p(nth))
	*ry = INT2FIX(y);
    else {
	t = f_mul(INT2FIX(period), nth);
	t = f_add(t, INT2FIX(y));
	*ry = t;
    }
}

static void
decode_jd(VALUE jd, VALUE *nth, int *rjd)
{
    *nth = f_idiv(jd, INT2FIX(CM_PERIOD));
    if (f_zero_p(*nth)) {
	*rjd = FIX2INT(jd);
	return;
    }
    *rjd = FIX2INT(f_mod(jd, INT2FIX(CM_PERIOD)));
}

static void
encode_jd(VALUE nth, int jd, VALUE *rjd)
{
    if (f_zero_p(nth)) {
	*rjd = INT2FIX(jd);
	return;
    }
    *rjd = f_add(f_mul(INT2FIX(CM_PERIOD), nth), INT2FIX(jd));
}

inline static double
guess_style(VALUE y, double sg) /* -/+oo or zero */
{
    double style = 0;

    if (isinf(sg))
	style = sg;
    else if (!FIXNUM_P(y))
	style = f_positive_p(y) ? negative_inf : positive_inf;
    else {
	long iy = FIX2LONG(y);

	assert(FIXNUM_P(y));
	if (iy < REFORM_BEGIN_YEAR)
	    style = positive_inf;
	else if (iy > REFORM_END_YEAR)
	    style = negative_inf;
    }
    return style;
}

inline static void
m_canonicalize_jd(VALUE obj, union DateData *x)
{
    if (simple_dat_p(x)) {
	get_s_jd(x);
	canonicalize_s_jd(obj, x);
    }
    else {
	get_c_jd(x);
	canonicalize_c_jd(obj, x);
    }
}

inline static VALUE
m_nth(union DateData *x)
{
    if (simple_dat_p(x))
	return x->s.nth;
    else {
	get_c_civil(x);
	return x->c.nth;
    }
}

inline static int
m_jd(union DateData *x)
{
    if (simple_dat_p(x)) {
	get_s_jd(x);
	return x->s.jd;
    }
    else {
	get_c_jd(x);
	return x->c.jd;
    }
}

static VALUE
m_real_jd(union DateData *x)
{
    VALUE nth, rjd;
    int jd;

    nth = m_nth(x);
    jd = m_jd(x);

    encode_jd(nth, jd, &rjd);
    return rjd;
}

static int
m_local_jd(union DateData *x)
{
    if (simple_dat_p(x)) {
	get_s_jd(x);
	return x->s.jd;
    }
    else {
	get_c_jd(x);
	get_c_df(x);
	return local_jd(x);
    }
}

static VALUE
m_real_local_jd(union DateData *x)
{
    VALUE nth, rjd;
    int jd;

    nth = m_nth(x);
    jd = m_local_jd(x);

    encode_jd(nth, jd, &rjd);
    return rjd;
}

inline static int
m_df(union DateData *x)
{
    if (simple_dat_p(x))
	return 0;
    else {
	get_c_df(x);
	return x->c.df;
    }
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
m_df_in_day(union DateData *x)
{
    return isec_to_day(m_df(x));
}
#endif

static int
m_local_df(union DateData *x)
{
    if (simple_dat_p(x))
	return 0;
    else {
	get_c_df(x);
	return local_df(x);
    }
}

#ifndef NDEBUG
static VALUE
m_local_df_in_day(union DateData *x)
{
    return isec_to_day(m_local_df(x));
}
#endif

inline static VALUE
m_sf(union DateData *x)
{
    if (simple_dat_p(x))
	return INT2FIX(0);
    else
	return x->c.sf;
}

#ifndef NDEBUG
static VALUE
m_sf_in_day(union DateData *x)
{
    return ns_to_day(m_sf(x));
}
#endif

static VALUE
m_sf_in_sec(union DateData *x)
{
    return ns_to_sec(m_sf(x));
}

static VALUE
m_fr(union DateData *x)
{
    if (simple_dat_p(x))
	return INT2FIX(0);
    else {
	int df;
	VALUE sf, fr;

	df = m_local_df(x);
	sf = m_sf(x);
	fr = isec_to_day(df);
	if (f_nonzero_p(sf))
	    fr = f_add(fr, ns_to_day(sf));
	return fr;
    }
}

#define HALF_DAYS_IN_SECONDS (DAY_IN_SECONDS / 2)

static VALUE
m_ajd(union DateData *x)
{
    VALUE r, sf;
    int df;

    if (simple_dat_p(x)) {
	r = m_real_jd(x);
	if (FIXNUM_P(r) && FIX2LONG(r) <= (FIXNUM_MAX / 2)) {
	    long ir = FIX2LONG(r);
	    ir = ir * 2 - 1;
	    return rb_rational_new2(LONG2FIX(ir), INT2FIX(2));
	}
	else
	    return rb_rational_new2(f_sub(f_mul(r,
						INT2FIX(2)),
					  INT2FIX(1)),
				    INT2FIX(2));
    }

    r = m_real_jd(x);
    df = m_df(x);
    df -= HALF_DAYS_IN_SECONDS;
    if (df)
	r = f_add(r, isec_to_day(df));
    sf = m_sf(x);
    if (f_nonzero_p(sf))
	r = f_add(r, ns_to_day(sf));

    return r;
}

static VALUE
m_amjd(union DateData *x)
{
    VALUE r, sf;
    int df;

    r = m_real_jd(x);
    if (FIXNUM_P(r) && FIX2LONG(r) >= (FIXNUM_MIN + 2400001)) {
	long ir = FIX2LONG(r);
	ir -= 2400001;
	r = rb_rational_new1(LONG2FIX(ir));
    }
    else
	r = rb_rational_new1(f_sub(m_real_jd(x),
				   INT2FIX(2400001)));

    if (simple_dat_p(x))
	return r;

    df = m_df(x);
    if (df)
	r = f_add(r, isec_to_day(df));
    sf = m_sf(x);
    if (f_nonzero_p(sf))
	r = f_add(r, ns_to_day(sf));

    return r;
}

inline static int
m_of(union DateData *x)
{
    if (simple_dat_p(x))
	return 0;
    else {
	get_c_jd(x);
	return x->c.of;
    }
}

static VALUE
m_of_in_day(union DateData *x)
{
    return isec_to_day(m_of(x));
}

inline static double
m_sg(union DateData *x)
{
    if (simple_dat_p(x))
	return x->s.sg;
    else {
	get_c_jd(x);
	return x->c.sg;
    }
}

static int
m_julian_p(union DateData *x)
{
    int jd;
    double sg;

    if (simple_dat_p(x)) {
	get_s_jd(x);
	jd = x->s.jd;
	sg = s_virtual_sg(x);
    }
    else {
	get_c_jd(x);
	jd = x->c.jd;
	sg = c_virtual_sg(x);
    }
    if (isinf(sg))
	return sg == positive_inf;
    return jd < sg;
}

inline static int
m_gregorian_p(union DateData *x)
{
    return !m_julian_p(x);
}

inline static int
m_proleptic_julian_p(union DateData *x)
{
    double sg;

    sg = m_sg(x);
    if (isinf(sg) && sg > 0)
	return 1;
    return 0;
}

inline static int
m_proleptic_gregorian_p(union DateData *x)
{
    double sg;

    sg = m_sg(x);
    if (isinf(sg) && sg < 0)
	return 1;
    return 0;
}

inline static int
m_year(union DateData *x)
{
    if (simple_dat_p(x)) {
	get_s_civil(x);
	return x->s.year;
    }
    else {
	get_c_civil(x);
	return x->c.year;
    }
}

static VALUE
m_real_year(union DateData *x)
{
    VALUE nth, ry;
    int year;

    nth = m_nth(x);
    year = m_year(x);

    if (f_zero_p(nth))
	return INT2FIX(year);

    encode_year(nth, year,
		m_gregorian_p(x) ? -1 : +1,
		&ry);
    return ry;
}

inline static int
m_mon(union DateData *x)
{
    if (simple_dat_p(x)) {
	get_s_civil(x);
#ifndef USE_PACK
	return x->s.mon;
#else
	return EX_MON(x->s.pc);
#endif
    }
    else {
	get_c_civil(x);
#ifndef USE_PACK
	return x->c.mon;
#else
	return EX_MON(x->c.pc);
#endif
    }
}

inline static int
m_mday(union DateData *x)
{
    if (simple_dat_p(x)) {
	get_s_civil(x);
#ifndef USE_PACK
	return x->s.mday;
#else
	return EX_MDAY(x->s.pc);
#endif
    }
    else {
	get_c_civil(x);
#ifndef USE_PACK
	return x->c.mday;
#else
	return EX_MDAY(x->c.pc);
#endif
    }
}

static const int yeartab[2][13] = {
    { 0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 },
    { 0, 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 }
};

static int
c_julian_to_yday(int y, int m, int d)
{
    assert(m >= 1 && m <= 12);
    return yeartab[c_julian_leap_p(y) ? 1 : 0][m] + d;
}

static int
c_gregorian_to_yday(int y, int m, int d)
{
    assert(m >= 1 && m <= 12);
    return yeartab[c_gregorian_leap_p(y) ? 1 : 0][m] + d;
}

static int
m_yday(union DateData *x)
{
    int jd, ry, rd;
    double sg;

    jd = m_local_jd(x);
    sg = m_virtual_sg(x); /* !=m_sg() */

    if (m_proleptic_gregorian_p(x) ||
	(jd - sg) > 366)
	return c_gregorian_to_yday(m_year(x), m_mon(x), m_mday(x));
    if (m_proleptic_julian_p(x))
	return c_julian_to_yday(m_year(x), m_mon(x), m_mday(x));
    c_jd_to_ordinal(jd, sg, &ry, &rd);
    return rd;
}

static int
m_wday(union DateData *x)
{
    return c_jd_to_wday(m_local_jd(x));
}

static int
m_cwyear(union DateData *x)
{
    int ry, rw, rd;

    c_jd_to_commercial(m_local_jd(x), m_virtual_sg(x), /* !=m_sg() */
		       &ry, &rw, &rd);
    return ry;
}

static VALUE
m_real_cwyear(union DateData *x)
{
    VALUE nth, ry;
    int year;

    nth = m_nth(x);
    year = m_cwyear(x);

    if (f_zero_p(nth))
	return INT2FIX(year);

    encode_year(nth, year,
		m_gregorian_p(x) ? -1 : +1,
		&ry);
    return ry;
}

static int
m_cweek(union DateData *x)
{
    int ry, rw, rd;

    c_jd_to_commercial(m_local_jd(x), m_virtual_sg(x), /* !=m_sg() */
		       &ry, &rw, &rd);
    return rw;
}

static int
m_cwday(union DateData *x)
{
    int w;

    w = m_wday(x);
    if (w == 0)
	w = 7;
    return w;
}

static int
m_wnumx(union DateData *x, int f)
{
    int ry, rw, rd;

    c_jd_to_weeknum(m_local_jd(x), f, m_virtual_sg(x), /* !=m_sg() */
		    &ry, &rw, &rd);
    return rw;
}

static int
m_wnum0(union DateData *x)
{
    return m_wnumx(x, 0);
}

static int
m_wnum1(union DateData *x)
{
    return m_wnumx(x, 1);
}

inline static int
m_hour(union DateData *x)
{
    if (simple_dat_p(x))
	return 0;
    else {
	get_c_time(x);
#ifndef USE_PACK
	return x->c.hour;
#else
	return EX_HOUR(x->c.pc);
#endif
    }
}

inline static int
m_min(union DateData *x)
{
    if (simple_dat_p(x))
	return 0;
    else {
	get_c_time(x);
#ifndef USE_PACK
	return x->c.min;
#else
	return EX_MIN(x->c.pc);
#endif
    }
}

inline static int
m_sec(union DateData *x)
{
    if (simple_dat_p(x))
	return 0;
    else {
	get_c_time(x);
#ifndef USE_PACK
	return x->c.sec;
#else
	return EX_SEC(x->c.pc);
#endif
    }
}

#define decode_offset(of,s,h,m)\
do {\
    int a;\
    s = (of < 0) ? '-' : '+';\
    a = (of < 0) ? -of : of;\
    h = a / HOUR_IN_SECONDS;\
    m = a % HOUR_IN_SECONDS / MINUTE_IN_SECONDS;\
} while (0)

static VALUE
of2str(int of)
{
    int s, h, m;

    decode_offset(of, s, h, m);
    return rb_enc_sprintf(rb_usascii_encoding(), "%c%02d:%02d", s, h, m);
}

static VALUE
m_zone(union DateData *x)
{
    if (simple_dat_p(x))
	return rb_usascii_str_new2("+00:00");
    return of2str(m_of(x));
}

inline static VALUE
f_kind_of_p(VALUE x, VALUE c)
{
    return rb_obj_is_kind_of(x, c);
}

inline static VALUE
k_date_p(VALUE x)
{
    return f_kind_of_p(x, cDate);
}

inline static VALUE
k_numeric_p(VALUE x)
{
    return f_kind_of_p(x, rb_cNumeric);
}

inline static VALUE
k_rational_p(VALUE x)
{
    return f_kind_of_p(x, rb_cRational);
}

static inline void
expect_numeric(VALUE x)
{
    if (!k_numeric_p(x))
	rb_raise(rb_eTypeError, "expected numeric");
}

#ifndef NDEBUG
/* :nodoc: */
static void
civil_to_jd(VALUE y, int m, int d, double sg,
	    VALUE *nth, int *ry,
	    int *rjd,
	    int *ns)
{
    double style = guess_style(y, sg);

    if (style == 0) {
	int jd;

	c_civil_to_jd(FIX2INT(y), m, d, sg, &jd, ns);
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	c_civil_to_jd(*ry, m, d, style, rjd, ns);
    }
}

static void
jd_to_civil(VALUE jd, double sg,
	    VALUE *nth, int *rjd,
	    int *ry, int *rm, int *rd)
{
    decode_jd(jd, nth, rjd);
    c_jd_to_civil(*rjd, sg, ry, rm, rd);
}

static void
ordinal_to_jd(VALUE y, int d, double sg,
	      VALUE *nth, int *ry,
	      int *rjd,
	      int *ns)
{
    double style = guess_style(y, sg);

    if (style == 0) {
	int jd;

	c_ordinal_to_jd(FIX2INT(y), d, sg, &jd, ns);
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	c_ordinal_to_jd(*ry, d, style, rjd, ns);
    }
}

static void
jd_to_ordinal(VALUE jd, double sg,
	      VALUE *nth, int *rjd,
	      int *ry, int *rd)
{
    decode_jd(jd, nth, rjd);
    c_jd_to_ordinal(*rjd, sg, ry, rd);
}

static void
commercial_to_jd(VALUE y, int w, int d, double sg,
		 VALUE *nth, int *ry,
		 int *rjd,
		 int *ns)
{
    double style = guess_style(y, sg);

    if (style == 0) {
	int jd;

	c_commercial_to_jd(FIX2INT(y), w, d, sg, &jd, ns);
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	c_commercial_to_jd(*ry, w, d, style, rjd, ns);
    }
}

static void
jd_to_commercial(VALUE jd, double sg,
		 VALUE *nth, int *rjd,
		 int *ry, int *rw, int *rd)
{
    decode_jd(jd, nth, rjd);
    c_jd_to_commercial(*rjd, sg, ry, rw, rd);
}

static void
weeknum_to_jd(VALUE y, int w, int d, int f, double sg,
	      VALUE *nth, int *ry,
	      int *rjd,
	      int *ns)
{
    double style = guess_style(y, sg);

    if (style == 0) {
	int jd;

	c_weeknum_to_jd(FIX2INT(y), w, d, f, sg, &jd, ns);
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	c_weeknum_to_jd(*ry, w, d, f, style, rjd, ns);
    }
}

static void
jd_to_weeknum(VALUE jd, int f, double sg,
	      VALUE *nth, int *rjd,
	      int *ry, int *rw, int *rd)
{
    decode_jd(jd, nth, rjd);
    c_jd_to_weeknum(*rjd, f, sg, ry, rw, rd);
}

static void
nth_kday_to_jd(VALUE y, int m, int n, int k, double sg,
	       VALUE *nth, int *ry,
	       int *rjd,
	       int *ns)
{
    double style = guess_style(y, sg);

    if (style == 0) {
	int jd;

	c_nth_kday_to_jd(FIX2INT(y), m, n, k, sg, &jd, ns);
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	c_nth_kday_to_jd(*ry, m, n, k, style, rjd, ns);
    }
}

static void
jd_to_nth_kday(VALUE jd, double sg,
	       VALUE *nth, int *rjd,
	       int *ry, int *rm, int *rn, int *rk)
{
    decode_jd(jd, nth, rjd);
    c_jd_to_nth_kday(*rjd, sg, ry, rm, rn, rk);
}
#endif

static int
valid_ordinal_p(VALUE y, int d, double sg,
		VALUE *nth, int *ry,
		int *rd, int *rjd,
		int *ns)
{
    double style = guess_style(y, sg);
    int r;

    if (style == 0) {
	int jd;

	r = c_valid_ordinal_p(FIX2INT(y), d, sg, rd, &jd, ns);
	if (!r)
	    return 0;
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	r = c_valid_ordinal_p(*ry, d, style, rd, rjd, ns);
    }
    return r;
}

static int
valid_gregorian_p(VALUE y, int m, int d,
		  VALUE *nth, int *ry,
		  int *rm, int *rd)
{
    decode_year(y, -1, nth, ry);
    return c_valid_gregorian_p(*ry, m, d, rm, rd);
}

static int
valid_civil_p(VALUE y, int m, int d, double sg,
	      VALUE *nth, int *ry,
	      int *rm, int *rd, int *rjd,
	      int *ns)
{
    double style = guess_style(y, sg);
    int r;

    if (style == 0) {
	int jd;

	r = c_valid_civil_p(FIX2INT(y), m, d, sg, rm, rd, &jd, ns);
	if (!r)
	    return 0;
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	if (style < 0)
	    r = c_valid_gregorian_p(*ry, m, d, rm, rd);
	else
	    r = c_valid_julian_p(*ry, m, d, rm, rd);
	if (!r)
	    return 0;
	c_civil_to_jd(*ry, *rm, *rd, style, rjd, ns);
    }
    return r;
}

static int
valid_commercial_p(VALUE y, int w, int d, double sg,
		   VALUE *nth, int *ry,
		   int *rw, int *rd, int *rjd,
		   int *ns)
{
    double style = guess_style(y, sg);
    int r;

    if (style == 0) {
	int jd;

	r = c_valid_commercial_p(FIX2INT(y), w, d, sg, rw, rd, &jd, ns);
	if (!r)
	    return 0;
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	r = c_valid_commercial_p(*ry, w, d, style, rw, rd, rjd, ns);
    }
    return r;
}

static int
valid_weeknum_p(VALUE y, int w, int d, int f, double sg,
		VALUE *nth, int *ry,
		int *rw, int *rd, int *rjd,
		int *ns)
{
    double style = guess_style(y, sg);
    int r;

    if (style == 0) {
	int jd;

	r = c_valid_weeknum_p(FIX2INT(y), w, d, f, sg, rw, rd, &jd, ns);
	if (!r)
	    return 0;
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	r = c_valid_weeknum_p(*ry, w, d, f, style, rw, rd, rjd, ns);
    }
    return r;
}

#ifndef NDEBUG
/* :nodoc: */
static int
valid_nth_kday_p(VALUE y, int m, int n, int k, double sg,
		 VALUE *nth, int *ry,
		 int *rm, int *rn, int *rk, int *rjd,
		 int *ns)
{
    double style = guess_style(y, sg);
    int r;

    if (style == 0) {
	int jd;

	r = c_valid_nth_kday_p(FIX2INT(y), m, n, k, sg, rm, rn, rk, &jd, ns);
	if (!r)
	    return 0;
	decode_jd(INT2FIX(jd), nth, rjd);
	if (f_zero_p(*nth))
	    *ry = FIX2INT(y);
	else {
	    VALUE nth2;
	    decode_year(y, *ns ? -1 : +1, &nth2, ry);
	}
    }
    else {
	decode_year(y, style, nth, ry);
	r = c_valid_nth_kday_p(*ry, m, n, k, style, rm, rn, rk, rjd, ns);
    }
    return r;
}
#endif

VALUE date_zone_to_diff(VALUE);

static int
offset_to_sec(VALUE vof, int *rof)
{
    int try_rational = 1;

  again:
    switch (TYPE(vof)) {
      case T_FIXNUM:
	{
	    long n;

	    n = FIX2LONG(vof);
	    if (n != -1 && n != 0 && n != 1)
		return 0;
	    *rof = (int)n * DAY_IN_SECONDS;
	    return 1;
	}
      case T_FLOAT:
	{
	    double n;

	    n = RFLOAT_VALUE(vof) * DAY_IN_SECONDS;
	    if (n < -DAY_IN_SECONDS || n > DAY_IN_SECONDS)
		return 0;
	    *rof = (int)round(n);
	    if (*rof != n)
		rb_warning("fraction of offset is ignored");
	    return 1;
	}
      default:
	expect_numeric(vof);
	vof = f_to_r(vof);
	if (!k_rational_p(vof)) {
	    if (!try_rational) Check_Type(vof, T_RATIONAL);
	    try_rational = 0;
	    goto again;
	}
	/* fall through */
      case T_RATIONAL:
	{
	    VALUE vs, vn, vd;
	    long n;

	    vs = day_to_sec(vof);

	    if (!k_rational_p(vs)) {
		vn = vs;
		goto rounded;
	    }
	    vn = rb_rational_num(vs);
	    vd = rb_rational_den(vs);

	    if (FIXNUM_P(vn) && FIXNUM_P(vd) && (FIX2LONG(vd) == 1))
		n = FIX2LONG(vn);
	    else {
		vn = f_round(vs);
		if (!f_eqeq_p(vn, vs))
		    rb_warning("fraction of offset is ignored");
	      rounded:
		if (!FIXNUM_P(vn))
		    return 0;
		n = FIX2LONG(vn);
		if (n < -DAY_IN_SECONDS || n > DAY_IN_SECONDS)
		    return 0;
	    }
	    *rof = (int)n;
	    return 1;
	}
      case T_STRING:
	{
	    VALUE vs = date_zone_to_diff(vof);
	    long n;

	    if (!FIXNUM_P(vs))
		return 0;
	    n = FIX2LONG(vs);
	    if (n < -DAY_IN_SECONDS || n > DAY_IN_SECONDS)
		return 0;
	    *rof = (int)n;
	    return 1;
	}
    }
    return 0;
}

/* date */

#define valid_sg(sg) \
do {\
    if (!c_valid_start_p(sg)) {\
	sg = 0;\
	rb_warning("invalid start is ignored");\
    }\
} while (0)

static VALUE
valid_jd_sub(int argc, VALUE *argv, VALUE klass, int need_jd)
{
    double sg = NUM2DBL(argv[1]);
    valid_sg(sg);
    return argv[0];
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
date_s__valid_jd_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vjd, vsg;
    VALUE argv2[2];

    rb_scan_args(argc, argv, "11", &vjd, &vsg);

    argv2[0] = vjd;
    if (argc < 2)
	argv2[1] = DBL2NUM(GREGORIAN);
    else
	argv2[1] = vsg;

    return valid_jd_sub(2, argv2, klass, 1);
}
#endif

/*
 * call-seq:
 *   Date.valid_jd?(jd, start = Date::ITALY) -> true
 *
 * Implemented for compatibility;
 * returns +true+ unless +jd+ is invalid (i.e., not a Numeric).
 *
 *   Date.valid_jd?(2451944) # => true
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.jd.
 */
static VALUE
date_s_valid_jd_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vjd, vsg;
    VALUE argv2[2];

    rb_scan_args(argc, argv, "11", &vjd, &vsg);

    RETURN_FALSE_UNLESS_NUMERIC(vjd);
    argv2[0] = vjd;
    if (argc < 2)
	argv2[1] = INT2FIX(DEFAULT_SG);
    else
	argv2[1] = vsg;

    if (NIL_P(valid_jd_sub(2, argv2, klass, 0)))
	return Qfalse;
    return Qtrue;
}

static VALUE
valid_civil_sub(int argc, VALUE *argv, VALUE klass, int need_jd)
{
    VALUE nth, y;
    int m, d, ry, rm, rd;
    double sg;

    y = argv[0];
    m = NUM2INT(argv[1]);
    d = NUM2INT(argv[2]);
    sg = NUM2DBL(argv[3]);

    valid_sg(sg);

    if (!need_jd && (guess_style(y, sg) < 0)) {
	if (!valid_gregorian_p(y, m, d,
			       &nth, &ry,
			       &rm, &rd))
	    return Qnil;
	return INT2FIX(0); /* dummy */
    }
    else {
	int rjd, ns;
	VALUE rjd2;

	if (!valid_civil_p(y, m, d, sg,
			   &nth, &ry,
			   &rm, &rd, &rjd,
			   &ns))
	    return Qnil;
	if (!need_jd)
	    return INT2FIX(0); /* dummy */
	encode_jd(nth, rjd, &rjd2);
	return rjd2;
    }
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
date_s__valid_civil_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vm, vd, vsg;
    VALUE argv2[4];

    rb_scan_args(argc, argv, "31", &vy, &vm, &vd, &vsg);

    argv2[0] = vy;
    argv2[1] = vm;
    argv2[2] = vd;
    if (argc < 4)
	argv2[3] = DBL2NUM(GREGORIAN);
    else
	argv2[3] = vsg;

    return valid_civil_sub(4, argv2, klass, 1);
}
#endif

/*
 * call-seq:
 *   Date.valid_civil?(year, month, mday, start = Date::ITALY) -> true or false
 *
 * Returns +true+ if the arguments define a valid ordinal date,
 * +false+ otherwise:
 *
 *   Date.valid_date?(2001, 2, 3)  # => true
 *   Date.valid_date?(2001, 2, 29) # => false
 *   Date.valid_date?(2001, 2, -1) # => true
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.jd, Date.new.
 */
static VALUE
date_s_valid_civil_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vm, vd, vsg;
    VALUE argv2[4];

    rb_scan_args(argc, argv, "31", &vy, &vm, &vd, &vsg);

    RETURN_FALSE_UNLESS_NUMERIC(vy);
    RETURN_FALSE_UNLESS_NUMERIC(vm);
    RETURN_FALSE_UNLESS_NUMERIC(vd);
    argv2[0] = vy;
    argv2[1] = vm;
    argv2[2] = vd;
    if (argc < 4)
	argv2[3] = INT2FIX(DEFAULT_SG);
    else
	argv2[3] = vsg;

    if (NIL_P(valid_civil_sub(4, argv2, klass, 0)))
	return Qfalse;
    return Qtrue;
}

static VALUE
valid_ordinal_sub(int argc, VALUE *argv, VALUE klass, int need_jd)
{
    VALUE nth, y;
    int d, ry, rd;
    double sg;

    y = argv[0];
    d = NUM2INT(argv[1]);
    sg = NUM2DBL(argv[2]);

    valid_sg(sg);

    {
	int rjd, ns;
	VALUE rjd2;

	if (!valid_ordinal_p(y, d, sg,
			     &nth, &ry,
			     &rd, &rjd,
			     &ns))
	    return Qnil;
	if (!need_jd)
	    return INT2FIX(0); /* dummy */
	encode_jd(nth, rjd, &rjd2);
	return rjd2;
    }
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
date_s__valid_ordinal_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vd, vsg;
    VALUE argv2[3];

    rb_scan_args(argc, argv, "21", &vy, &vd, &vsg);

    argv2[0] = vy;
    argv2[1] = vd;
    if (argc < 3)
	argv2[2] = DBL2NUM(GREGORIAN);
    else
	argv2[2] = vsg;

    return valid_ordinal_sub(3, argv2, klass, 1);
}
#endif

/*
 * call-seq:
 *   Date.valid_ordinal?(year, yday, start = Date::ITALY) -> true or false
 *
 * Returns +true+ if the arguments define a valid ordinal date,
 * +false+ otherwise:
 *
 *   Date.valid_ordinal?(2001, 34)  # => true
 *   Date.valid_ordinal?(2001, 366) # => false
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.jd, Date.ordinal.
 */
static VALUE
date_s_valid_ordinal_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vd, vsg;
    VALUE argv2[3];

    rb_scan_args(argc, argv, "21", &vy, &vd, &vsg);

    RETURN_FALSE_UNLESS_NUMERIC(vy);
    RETURN_FALSE_UNLESS_NUMERIC(vd);
    argv2[0] = vy;
    argv2[1] = vd;
    if (argc < 3)
	argv2[2] = INT2FIX(DEFAULT_SG);
    else
	argv2[2] = vsg;

    if (NIL_P(valid_ordinal_sub(3, argv2, klass, 0)))
	return Qfalse;
    return Qtrue;
}

static VALUE
valid_commercial_sub(int argc, VALUE *argv, VALUE klass, int need_jd)
{
    VALUE nth, y;
    int w, d, ry, rw, rd;
    double sg;

    y = argv[0];
    w = NUM2INT(argv[1]);
    d = NUM2INT(argv[2]);
    sg = NUM2DBL(argv[3]);

    valid_sg(sg);

    {
	int rjd, ns;
	VALUE rjd2;

	if (!valid_commercial_p(y, w, d, sg,
				&nth, &ry,
				&rw, &rd, &rjd,
				&ns))
	    return Qnil;
	if (!need_jd)
	    return INT2FIX(0); /* dummy */
	encode_jd(nth, rjd, &rjd2);
	return rjd2;
    }
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
date_s__valid_commercial_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vsg;
    VALUE argv2[4];

    rb_scan_args(argc, argv, "31", &vy, &vw, &vd, &vsg);

    argv2[0] = vy;
    argv2[1] = vw;
    argv2[2] = vd;
    if (argc < 4)
	argv2[3] = DBL2NUM(GREGORIAN);
    else
	argv2[3] = vsg;

    return valid_commercial_sub(4, argv2, klass, 1);
}
#endif

/*
 * call-seq:
 *   Date.valid_commercial?(cwyear, cweek, cwday, start = Date::ITALY) -> true or false
 *
 * Returns +true+ if the arguments define a valid commercial date,
 * +false+ otherwise:
 *
 *   Date.valid_commercial?(2001, 5, 6) # => true
 *   Date.valid_commercial?(2001, 5, 8) # => false
 *
 * See Date.commercial.
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.jd, Date.commercial.
 */
static VALUE
date_s_valid_commercial_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vsg;
    VALUE argv2[4];

    rb_scan_args(argc, argv, "31", &vy, &vw, &vd, &vsg);

    RETURN_FALSE_UNLESS_NUMERIC(vy);
    RETURN_FALSE_UNLESS_NUMERIC(vw);
    RETURN_FALSE_UNLESS_NUMERIC(vd);
    argv2[0] = vy;
    argv2[1] = vw;
    argv2[2] = vd;
    if (argc < 4)
	argv2[3] = INT2FIX(DEFAULT_SG);
    else
	argv2[3] = vsg;

    if (NIL_P(valid_commercial_sub(4, argv2, klass, 0)))
	return Qfalse;
    return Qtrue;
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
valid_weeknum_sub(int argc, VALUE *argv, VALUE klass, int need_jd)
{
    VALUE nth, y;
    int w, d, f, ry, rw, rd;
    double sg;

    y = argv[0];
    w = NUM2INT(argv[1]);
    d = NUM2INT(argv[2]);
    f = NUM2INT(argv[3]);
    sg = NUM2DBL(argv[4]);

    valid_sg(sg);

    {
	int rjd, ns;
	VALUE rjd2;

	if (!valid_weeknum_p(y, w, d, f, sg,
			     &nth, &ry,
			     &rw, &rd, &rjd,
			     &ns))
	    return Qnil;
	if (!need_jd)
	    return INT2FIX(0); /* dummy */
	encode_jd(nth, rjd, &rjd2);
	return rjd2;
    }
}

/* :nodoc: */
static VALUE
date_s__valid_weeknum_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vf, vsg;
    VALUE argv2[5];

    rb_scan_args(argc, argv, "41", &vy, &vw, &vd, &vf, &vsg);

    argv2[0] = vy;
    argv2[1] = vw;
    argv2[2] = vd;
    argv2[3] = vf;
    if (argc < 5)
	argv2[4] = DBL2NUM(GREGORIAN);
    else
	argv2[4] = vsg;

    return valid_weeknum_sub(5, argv2, klass, 1);
}

/* :nodoc: */
static VALUE
date_s_valid_weeknum_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vf, vsg;
    VALUE argv2[5];

    rb_scan_args(argc, argv, "41", &vy, &vw, &vd, &vf, &vsg);

    argv2[0] = vy;
    argv2[1] = vw;
    argv2[2] = vd;
    argv2[3] = vf;
    if (argc < 5)
	argv2[4] = INT2FIX(DEFAULT_SG);
    else
	argv2[4] = vsg;

    if (NIL_P(valid_weeknum_sub(5, argv2, klass, 0)))
	return Qfalse;
    return Qtrue;
}

static VALUE
valid_nth_kday_sub(int argc, VALUE *argv, VALUE klass, int need_jd)
{
    VALUE nth, y;
    int m, n, k, ry, rm, rn, rk;
    double sg;

    y = argv[0];
    m = NUM2INT(argv[1]);
    n = NUM2INT(argv[2]);
    k = NUM2INT(argv[3]);
    sg = NUM2DBL(argv[4]);

    {
	int rjd, ns;
	VALUE rjd2;

	if (!valid_nth_kday_p(y, m, n, k, sg,
			      &nth, &ry,
			      &rm, &rn, &rk, &rjd,
			      &ns))
	    return Qnil;
	if (!need_jd)
	    return INT2FIX(0); /* dummy */
	encode_jd(nth, rjd, &rjd2);
	return rjd2;
    }
}

/* :nodoc: */
static VALUE
date_s__valid_nth_kday_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vm, vn, vk, vsg;
    VALUE argv2[5];

    rb_scan_args(argc, argv, "41", &vy, &vm, &vn, &vk, &vsg);

    argv2[0] = vy;
    argv2[1] = vm;
    argv2[2] = vn;
    argv2[3] = vk;
    if (argc < 5)
	argv2[4] = DBL2NUM(GREGORIAN);
    else
	argv2[4] = vsg;

    return valid_nth_kday_sub(5, argv2, klass, 1);
}

/* :nodoc: */
static VALUE
date_s_valid_nth_kday_p(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vm, vn, vk, vsg;
    VALUE argv2[5];

    rb_scan_args(argc, argv, "41", &vy, &vm, &vn, &vk, &vsg);

    argv2[0] = vy;
    argv2[1] = vm;
    argv2[2] = vn;
    argv2[3] = vk;
    if (argc < 5)
	argv2[4] = INT2FIX(DEFAULT_SG);
    else
	argv2[4] = vsg;

    if (NIL_P(valid_nth_kday_sub(5, argv2, klass, 0)))
	return Qfalse;
    return Qtrue;
}

/* :nodoc: */
static VALUE
date_s_zone_to_diff(VALUE klass, VALUE str)
{
    return date_zone_to_diff(str);
}
#endif

/*
 * call-seq:
 *   Date.julian_leap?(year) -> true or false
 *
 * Returns +true+ if the given year is a leap year
 * in the {proleptic Julian calendar}[https://en.wikipedia.org/wiki/Proleptic_Julian_calendar], +false+ otherwise:
 *
 *   Date.julian_leap?(1900) # => true
 *   Date.julian_leap?(1901) # => false
 *
 * Related: Date.gregorian_leap?.
 */
static VALUE
date_s_julian_leap_p(VALUE klass, VALUE y)
{
    VALUE nth;
    int ry;

    check_numeric(y, "year");
    decode_year(y, +1, &nth, &ry);
    return f_boolcast(c_julian_leap_p(ry));
}

/*
 * call-seq:
 *   Date.gregorian_leap?(year) -> true or false
 *
 * Returns +true+ if the given year is a leap year
 * in the {proleptic Gregorian calendar}[https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar], +false+ otherwise:
 *
 *   Date.gregorian_leap?(2000) # => true
 *   Date.gregorian_leap?(2001) # => false
 *
 * Related: Date.julian_leap?.
 */
static VALUE
date_s_gregorian_leap_p(VALUE klass, VALUE y)
{
    VALUE nth;
    int ry;

    check_numeric(y, "year");
    decode_year(y, -1, &nth, &ry);
    return f_boolcast(c_gregorian_leap_p(ry));
}

static void
d_lite_gc_mark(void *ptr)
{
    union DateData *dat = ptr;
    if (simple_dat_p(dat))
	rb_gc_mark(dat->s.nth);
    else {
	rb_gc_mark(dat->c.nth);
	rb_gc_mark(dat->c.sf);
    }
}

static size_t
d_lite_memsize(const void *ptr)
{
    const union DateData *dat = ptr;
    return complex_dat_p(dat) ? sizeof(struct ComplexDateData) : sizeof(struct SimpleDateData);
}

#ifndef HAVE_RB_EXT_RACTOR_SAFE
#   define RUBY_TYPED_FROZEN_SHAREABLE 0
#endif

static const rb_data_type_t d_lite_type = {
    "Date",
    {d_lite_gc_mark, RUBY_TYPED_DEFAULT_FREE, d_lite_memsize,},
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY|RUBY_TYPED_WB_PROTECTED|RUBY_TYPED_FROZEN_SHAREABLE,
};

inline static VALUE
d_simple_new_internal(VALUE klass,
		      VALUE nth, int jd,
		      double sg,
		      int y, int m, int d,
		      unsigned flags)
{
    struct SimpleDateData *dat;
    VALUE obj;

    obj = TypedData_Make_Struct(klass, struct SimpleDateData,
				&d_lite_type, dat);
    set_to_simple(obj, dat, nth, jd, sg, y, m, d, flags);

    assert(have_jd_p(dat) || have_civil_p(dat));

    return obj;
}

inline static VALUE
d_complex_new_internal(VALUE klass,
		       VALUE nth, int jd,
		       int df, VALUE sf,
		       int of, double sg,
		       int y, int m, int d,
		       int h, int min, int s,
		       unsigned flags)
{
    struct ComplexDateData *dat;
    VALUE obj;

    obj = TypedData_Make_Struct(klass, struct ComplexDateData,
				&d_lite_type, dat);
    set_to_complex(obj, dat, nth, jd, df, sf, of, sg,
		   y, m, d, h, min, s, flags);

    assert(have_jd_p(dat) || have_civil_p(dat));
    assert(have_df_p(dat) || have_time_p(dat));

    return obj;
}

static VALUE
d_lite_s_alloc_simple(VALUE klass)
{
    return d_simple_new_internal(klass,
				 INT2FIX(0), 0,
				 DEFAULT_SG,
				 0, 0, 0,
				 HAVE_JD);
}

static VALUE
d_lite_s_alloc_complex(VALUE klass)
{
    return d_complex_new_internal(klass,
				  INT2FIX(0), 0,
				  0, INT2FIX(0),
				  0, DEFAULT_SG,
				  0, 0, 0,
				  0, 0, 0,
				  HAVE_JD | HAVE_DF);
}

static VALUE
d_lite_s_alloc(VALUE klass)
{
    return d_lite_s_alloc_complex(klass);
}

static void
old_to_new(VALUE ajd, VALUE of, VALUE sg,
	   VALUE *rnth, int *rjd, int *rdf, VALUE *rsf,
	   int *rof, double *rsg)
{
    VALUE jd, df, sf, of2, t;

    decode_day(f_add(ajd, half_days_in_day),
	       &jd, &df, &sf);
    t = day_to_sec(of);
    of2 = f_round(t);

    if (!f_eqeq_p(of2, t))
	rb_warning("fraction of offset is ignored");

    decode_jd(jd, rnth, rjd);

    *rdf = NUM2INT(df);
    *rsf = sf;
    *rof = NUM2INT(of2);
    *rsg = NUM2DBL(sg);

    if (*rdf < 0 || *rdf >= DAY_IN_SECONDS)
	rb_raise(eDateError, "invalid day fraction");

    if (f_lt_p(*rsf, INT2FIX(0)) ||
	f_ge_p(*rsf, INT2FIX(SECOND_IN_NANOSECONDS)))

    if (*rof < -DAY_IN_SECONDS || *rof > DAY_IN_SECONDS) {
	*rof = 0;
	rb_warning("invalid offset is ignored");
    }

    if (!c_valid_start_p(*rsg)) {
	*rsg = DEFAULT_SG;
	rb_warning("invalid start is ignored");
    }
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
date_s_new_bang(int argc, VALUE *argv, VALUE klass)
{
    VALUE ajd, of, sg, nth, sf;
    int jd, df, rof;
    double rsg;

    rb_scan_args(argc, argv, "03", &ajd, &of, &sg);

    switch (argc) {
      case 0:
	ajd = INT2FIX(0);
      case 1:
	of = INT2FIX(0);
      case 2:
	sg = INT2FIX(DEFAULT_SG);
    }

    old_to_new(ajd, of, sg,
	       &nth, &jd, &df, &sf, &rof, &rsg);

    if (!df && f_zero_p(sf) && !rof)
	return d_simple_new_internal(klass,
				     nth, jd,
				     rsg,
				     0, 0, 0,
				     HAVE_JD);
    else
	return d_complex_new_internal(klass,
				      nth, jd,
				      df, sf,
				      rof, rsg,
				      0, 0, 0,
				      0, 0, 0,
				      HAVE_JD | HAVE_DF);
}
#endif

inline static int
wholenum_p(VALUE x)
{
    if (FIXNUM_P(x))
	return 1;
    switch (TYPE(x)) {
      case T_BIGNUM:
	return 1;
      case T_FLOAT:
	{
	    double d = RFLOAT_VALUE(x);
	    return round(d) == d;
	}
	break;
      case T_RATIONAL:
	{
	    VALUE den = rb_rational_den(x);
	    return FIXNUM_P(den) && FIX2LONG(den) == 1;
	}
	break;
    }
    return 0;
}

inline static VALUE
to_integer(VALUE x)
{
    if (RB_INTEGER_TYPE_P(x))
	return x;
    return f_to_i(x);
}

inline static VALUE
d_trunc(VALUE d, VALUE *fr)
{
    VALUE rd;

    if (wholenum_p(d)) {
	rd = to_integer(d);
	*fr = INT2FIX(0);
    }
    else {
	rd = f_idiv(d, INT2FIX(1));
	*fr = f_mod(d, INT2FIX(1));
    }
    return rd;
}

#define jd_trunc d_trunc
#define k_trunc d_trunc

inline static VALUE
h_trunc(VALUE h, VALUE *fr)
{
    VALUE rh;

    if (wholenum_p(h)) {
	rh = to_integer(h);
	*fr = INT2FIX(0);
    }
    else {
	rh = f_idiv(h, INT2FIX(1));
	*fr = f_mod(h, INT2FIX(1));
	*fr = f_quo(*fr, INT2FIX(24));
    }
    return rh;
}

inline static VALUE
min_trunc(VALUE min, VALUE *fr)
{
    VALUE rmin;

    if (wholenum_p(min)) {
	rmin = to_integer(min);
	*fr = INT2FIX(0);
    }
    else {
	rmin = f_idiv(min, INT2FIX(1));
	*fr = f_mod(min, INT2FIX(1));
	*fr = f_quo(*fr, INT2FIX(1440));
    }
    return rmin;
}

inline static VALUE
s_trunc(VALUE s, VALUE *fr)
{
    VALUE rs;

    if (wholenum_p(s)) {
	rs = to_integer(s);
	*fr = INT2FIX(0);
    }
    else {
	rs = f_idiv(s, INT2FIX(1));
	*fr = f_mod(s, INT2FIX(1));
	*fr = f_quo(*fr, INT2FIX(86400));
    }
    return rs;
}

#define num2num_with_frac(s,n) \
do {\
    s = s##_trunc(v##s, &fr);\
    if (f_nonzero_p(fr)) {\
	if (argc > n)\
	    rb_raise(eDateError, "invalid fraction");\
	fr2 = fr;\
    }\
} while (0)

#define num2int_with_frac(s,n) \
do {\
    s = NUM2INT(s##_trunc(v##s, &fr));\
    if (f_nonzero_p(fr)) {\
	if (argc > n)\
	    rb_raise(eDateError, "invalid fraction");\
	fr2 = fr;\
    }\
} while (0)

#define canon24oc() \
do {\
    if (rh == 24) {\
	rh = 0;\
	fr2 = f_add(fr2, INT2FIX(1));\
    }\
} while (0)

#define add_frac() \
do {\
    if (f_nonzero_p(fr2))\
	ret = d_lite_plus(ret, fr2);\
} while (0)

#define val2sg(vsg,dsg) \
do {\
    dsg = NUM2DBL(vsg);\
    if (!c_valid_start_p(dsg)) {\
	dsg = DEFAULT_SG;\
	rb_warning("invalid start is ignored");\
    }\
} while (0)

static VALUE d_lite_plus(VALUE, VALUE);

/*
 * call-seq:
 *   Date.jd(jd = 0, start = Date::ITALY) -> date
 *
 * Returns a new \Date object formed from the arguments:
 *
 *   Date.jd(2451944).to_s # => "2001-02-03"
 *   Date.jd(2451945).to_s # => "2001-02-04"
 *   Date.jd(0).to_s       # => "-4712-01-01"
 *
 * The returned date is:
 *
 * - Gregorian, if the argument is greater than or equal to +start+:
 *
 *     Date::ITALY                         # => 2299161
 *     Date.jd(Date::ITALY).gregorian?     # => true
 *     Date.jd(Date::ITALY + 1).gregorian? # => true
 *
 * - Julian, otherwise
 *
 *     Date.jd(Date::ITALY - 1).julian?    # => true
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.new.
 */
static VALUE
date_s_jd(int argc, VALUE *argv, VALUE klass)
{
    VALUE vjd, vsg, jd, fr, fr2, ret;
    double sg;

    rb_scan_args(argc, argv, "02", &vjd, &vsg);

    jd = INT2FIX(0);
    fr2 = INT2FIX(0);
    sg = DEFAULT_SG;

    switch (argc) {
      case 2:
	val2sg(vsg, sg);
      case 1:
        check_numeric(vjd, "jd");
	num2num_with_frac(jd, positive_inf);
    }

    {
	VALUE nth;
	int rjd;

	decode_jd(jd, &nth, &rjd);
	ret = d_simple_new_internal(klass,
				    nth, rjd,
				    sg,
				    0, 0, 0,
				    HAVE_JD);
    }
    add_frac();
    return ret;
}

/*
 * call-seq:
 *   Date.ordinal(year = -4712, yday = 1, start = Date::ITALY) -> date
 *
 * Returns a new \Date object formed fom the arguments.
 *
 * With no arguments, returns the date for January 1, -4712:
 *
 *   Date.ordinal.to_s # => "-4712-01-01"
 *
 * With argument +year+, returns the date for January 1 of that year:
 *
 *   Date.ordinal(2001).to_s  # => "2001-01-01"
 *   Date.ordinal(-2001).to_s # => "-2001-01-01"
 *
 * With positive argument +yday+ == +n+,
 * returns the date for the +nth+ day of the given year:
 *
 *   Date.ordinal(2001, 14).to_s # => "2001-01-14"
 *
 * With negative argument +yday+, counts backward from the end of the year:
 *
 *   Date.ordinal(2001, -14).to_s # => "2001-12-18"
 *
 * Raises an exception if +yday+ is zero or out of range.
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.jd, Date.new.
 */
static VALUE
date_s_ordinal(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vd, vsg, y, fr, fr2, ret;
    int d;
    double sg;

    rb_scan_args(argc, argv, "03", &vy, &vd, &vsg);

    y = INT2FIX(-4712);
    d = 1;
    fr2 = INT2FIX(0);
    sg = DEFAULT_SG;

    switch (argc) {
      case 3:
	val2sg(vsg, sg);
      case 2:
        check_numeric(vd, "yday");
	num2int_with_frac(d, positive_inf);
      case 1:
        check_numeric(vy, "year");
	y = vy;
    }

    {
	VALUE nth;
	int ry, rd, rjd, ns;

	if (!valid_ordinal_p(y, d, sg,
			     &nth, &ry,
			     &rd, &rjd,
			     &ns))
	    rb_raise(eDateError, "invalid date");

	ret = d_simple_new_internal(klass,
				     nth, rjd,
				     sg,
				     0, 0, 0,
				     HAVE_JD);
    }
    add_frac();
    return ret;
}

/*
 * Same as Date.new.
 */
static VALUE
date_s_civil(int argc, VALUE *argv, VALUE klass)
{
    return date_initialize(argc, argv, d_lite_s_alloc_simple(klass));
}

/*
 * call-seq:
 *   Date.new(year = -4712, month = 1, mday = 1, start = Date::ITALY) -> date
 *
 * Returns a new \Date object constructed from the given arguments:
 *
 *   Date.new(2022).to_s        # => "2022-01-01"
 *   Date.new(2022, 2).to_s     # => "2022-02-01"
 *   Date.new(2022, 2, 4).to_s  # => "2022-02-04"
 *
 * Argument +month+ should be in range (1..12) or range (-12..-1);
 * when the argument is negative, counts backward from the end of the year:
 *
 *   Date.new(2022, -11, 4).to_s # => "2022-02-04"
 *
 * Argument +mday+ should be in range (1..n) or range (-n..-1)
 * where +n+ is the number of days in the month;
 * when the argument is negative, counts backward from the end of the month.
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.jd.
 */
static VALUE
date_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE vy, vm, vd, vsg, y, fr, fr2, ret;
    int m, d;
    double sg;
    struct SimpleDateData *dat = rb_check_typeddata(self, &d_lite_type);

    if (!simple_dat_p(dat)) {
	rb_raise(rb_eTypeError, "Date expected");
    }

    rb_scan_args(argc, argv, "04", &vy, &vm, &vd, &vsg);

    y = INT2FIX(-4712);
    m = 1;
    d = 1;
    fr2 = INT2FIX(0);
    sg = DEFAULT_SG;

    switch (argc) {
      case 4:
	val2sg(vsg, sg);
      case 3:
        check_numeric(vd, "day");
	num2int_with_frac(d, positive_inf);
      case 2:
        check_numeric(vm, "month");
	m = NUM2INT(vm);
      case 1:
        check_numeric(vy, "year");
	y = vy;
    }

    if (guess_style(y, sg) < 0) {
	VALUE nth;
	int ry, rm, rd;

	if (!valid_gregorian_p(y, m, d,
			       &nth, &ry,
			       &rm, &rd))
	    rb_raise(eDateError, "invalid date");

	set_to_simple(self, dat, nth, 0, sg, ry, rm, rd, HAVE_CIVIL);
    }
    else {
	VALUE nth;
	int ry, rm, rd, rjd, ns;

	if (!valid_civil_p(y, m, d, sg,
			   &nth, &ry,
			   &rm, &rd, &rjd,
			   &ns))
	    rb_raise(eDateError, "invalid date");

	set_to_simple(self, dat, nth, rjd, sg, ry, rm, rd, HAVE_JD | HAVE_CIVIL);
    }
    ret = self;
    add_frac();
    return ret;
}

/*
 * call-seq:
 *   Date.commercial(cwyear = -4712, cweek = 1, cwday = 1, start = Date::ITALY) -> date
 *
 * Returns a new \Date object constructed from the arguments.
 *
 * Argument +cwyear+ gives the year, and should be an integer.
 *
 * Argument +cweek+ gives the index of the week within the year,
 * and should be in range (1..53) or (-53..-1);
 * in some years, 53 or -53 will be out-of-range;
 * if negative, counts backward from the end of the year:
 *
 *   Date.commercial(2022, 1, 1).to_s  # => "2022-01-03"
 *   Date.commercial(2022, 52, 1).to_s # => "2022-12-26"
 *
 * Argument +cwday+ gives the indes of the weekday within the week,
 * and should be in range (1..7) or (-7..-1);
 * 1 or -7 is Monday;
 * if negative, counts backward from the end of the week:
 *
 *   Date.commercial(2022, 1, 1).to_s  # => "2022-01-03"
 *   Date.commercial(2022, 1, -7).to_s # => "2022-01-03"
 *
 * When +cweek+ is 1:
 *
 * - If January 1 is a Friday, Saturday, or Sunday,
 *   the first week begins in the week after:
 *
 *     Date::ABBR_DAYNAMES[Date.new(2023, 1, 1).wday] # => "Sun"
 *     Date.commercial(2023, 1, 1).to_s # => "2023-01-02"
       Date.commercial(2023, 1, 7).to_s # => "2023-01-08"
 *
 * - Otherwise, the first week is the week of January 1,
 *   which may mean some of the days fall on the year before:
 *
 *     Date::ABBR_DAYNAMES[Date.new(2020, 1, 1).wday] # => "Wed"
 *     Date.commercial(2020, 1, 1).to_s # => "2019-12-30"
       Date.commercial(2020, 1, 7).to_s # => "2020-01-05"
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * Related: Date.jd, Date.new, Date.ordinal.
 */
static VALUE
date_s_commercial(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vsg, y, fr, fr2, ret;
    int w, d;
    double sg;

    rb_scan_args(argc, argv, "04", &vy, &vw, &vd, &vsg);

    y = INT2FIX(-4712);
    w = 1;
    d = 1;
    fr2 = INT2FIX(0);
    sg = DEFAULT_SG;

    switch (argc) {
      case 4:
	val2sg(vsg, sg);
      case 3:
        check_numeric(vd, "cwday");
	num2int_with_frac(d, positive_inf);
      case 2:
        check_numeric(vw, "cweek");
	w = NUM2INT(vw);
      case 1:
        check_numeric(vy, "year");
	y = vy;
    }

    {
	VALUE nth;
	int ry, rw, rd, rjd, ns;

	if (!valid_commercial_p(y, w, d, sg,
				&nth, &ry,
				&rw, &rd, &rjd,
				&ns))
	    rb_raise(eDateError, "invalid date");

	ret = d_simple_new_internal(klass,
				    nth, rjd,
				    sg,
				    0, 0, 0,
				    HAVE_JD);
    }
    add_frac();
    return ret;
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
date_s_weeknum(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vf, vsg, y, fr, fr2, ret;
    int w, d, f;
    double sg;

    rb_scan_args(argc, argv, "05", &vy, &vw, &vd, &vf, &vsg);

    y = INT2FIX(-4712);
    w = 0;
    d = 1;
    f = 0;
    fr2 = INT2FIX(0);
    sg = DEFAULT_SG;

    switch (argc) {
      case 5:
	val2sg(vsg, sg);
      case 4:
	f = NUM2INT(vf);
      case 3:
	num2int_with_frac(d, positive_inf);
      case 2:
	w = NUM2INT(vw);
      case 1:
	y = vy;
    }

    {
	VALUE nth;
	int ry, rw, rd, rjd, ns;

	if (!valid_weeknum_p(y, w, d, f, sg,
			     &nth, &ry,
			     &rw, &rd, &rjd,
			     &ns))
	    rb_raise(eDateError, "invalid date");

	ret = d_simple_new_internal(klass,
				    nth, rjd,
				    sg,
				    0, 0, 0,
				    HAVE_JD);
    }
    add_frac();
    return ret;
}

/* :nodoc: */
static VALUE
date_s_nth_kday(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vm, vn, vk, vsg, y, fr, fr2, ret;
    int m, n, k;
    double sg;

    rb_scan_args(argc, argv, "05", &vy, &vm, &vn, &vk, &vsg);

    y = INT2FIX(-4712);
    m = 1;
    n = 1;
    k = 1;
    fr2 = INT2FIX(0);
    sg = DEFAULT_SG;

    switch (argc) {
      case 5:
	val2sg(vsg, sg);
      case 4:
	num2int_with_frac(k, positive_inf);
      case 3:
	n = NUM2INT(vn);
      case 2:
	m = NUM2INT(vm);
      case 1:
	y = vy;
    }

    {
	VALUE nth;
	int ry, rm, rn, rk, rjd, ns;

	if (!valid_nth_kday_p(y, m, n, k, sg,
			      &nth, &ry,
			      &rm, &rn, &rk, &rjd,
			      &ns))
	    rb_raise(eDateError, "invalid date");

	ret = d_simple_new_internal(klass,
				    nth, rjd,
				    sg,
				    0, 0, 0,
				    HAVE_JD);
    }
    add_frac();
    return ret;
}
#endif

#if !defined(HAVE_GMTIME_R)
static struct tm*
gmtime_r(const time_t *t, struct tm *tm)
{
    auto struct tm *tmp = gmtime(t);
    if (tmp)
	*tm = *tmp;
    return tmp;
}

static struct tm*
localtime_r(const time_t *t, struct tm *tm)
{
    auto struct tm *tmp = localtime(t);
    if (tmp)
	*tm = *tmp;
    return tmp;
}
#endif

static void set_sg(union DateData *, double);

/*
 * call-seq:
 *   Date.today(start = Date::ITALY) -> date
 *
 * Returns a new \Date object constructed from the present date:
 *
 *   Date.today.to_s # => "2022-07-06"
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 */
static VALUE
date_s_today(int argc, VALUE *argv, VALUE klass)
{
    VALUE vsg, nth, ret;
    double sg;
    time_t t;
    struct tm tm;
    int y, ry, m, d;

    rb_scan_args(argc, argv, "01", &vsg);

    if (argc < 1)
	sg = DEFAULT_SG;
    else
	val2sg(vsg, sg);

    if (time(&t) == -1)
	rb_sys_fail("time");
    tzset();
    if (!localtime_r(&t, &tm))
	rb_sys_fail("localtime");

    y = tm.tm_year + 1900;
    m = tm.tm_mon + 1;
    d = tm.tm_mday;

    decode_year(INT2FIX(y), -1, &nth, &ry);

    ret = d_simple_new_internal(klass,
				nth, 0,
				GREGORIAN,
				ry, m, d,
				HAVE_CIVIL);
    {
	get_d1(ret);
	set_sg(dat, sg);
    }
    return ret;
}

#define set_hash0(k,v) rb_hash_aset(hash, k, v)
#define ref_hash0(k) rb_hash_aref(hash, k)
#define del_hash0(k) rb_hash_delete(hash, k)

#define sym(x) ID2SYM(rb_intern(x""))

#define set_hash(k,v) set_hash0(sym(k), v)
#define ref_hash(k) ref_hash0(sym(k))
#define del_hash(k) del_hash0(sym(k))

static VALUE
rt_rewrite_frags(VALUE hash)
{
    VALUE seconds;

    seconds = del_hash("seconds");
    if (!NIL_P(seconds)) {
	VALUE offset, d, h, min, s, fr;

	offset = ref_hash("offset");
	if (!NIL_P(offset))
	    seconds = f_add(seconds, offset);

	d = f_idiv(seconds, INT2FIX(DAY_IN_SECONDS));
	fr = f_mod(seconds, INT2FIX(DAY_IN_SECONDS));

	h = f_idiv(fr, INT2FIX(HOUR_IN_SECONDS));
	fr = f_mod(fr, INT2FIX(HOUR_IN_SECONDS));

	min = f_idiv(fr, INT2FIX(MINUTE_IN_SECONDS));
	fr = f_mod(fr, INT2FIX(MINUTE_IN_SECONDS));

	s = f_idiv(fr, INT2FIX(1));
	fr = f_mod(fr, INT2FIX(1));

	set_hash("jd", f_add(UNIX_EPOCH_IN_CJD, d));
	set_hash("hour", h);
	set_hash("min", min);
	set_hash("sec", s);
	set_hash("sec_fraction", fr);
    }
    return hash;
}

static VALUE d_lite_year(VALUE);
static VALUE d_lite_wday(VALUE);
static VALUE d_lite_jd(VALUE);

static VALUE
rt_complete_frags(VALUE klass, VALUE hash)
{
    static VALUE tab = Qnil;
    int g;
    long e;
    VALUE k, a, d;

    if (NIL_P(tab)) {
	tab = f_frozen_ary(11,
			  f_frozen_ary(2,
				      sym("time"),
				      f_frozen_ary(3,
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      Qnil,
				      f_frozen_ary(1,
						  sym("jd"))),
			  f_frozen_ary(2,
				      sym("ordinal"),
				      f_frozen_ary(5,
						  sym("year"),
						  sym("yday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      sym("civil"),
				      f_frozen_ary(6,
						  sym("year"),
						  sym("mon"),
						  sym("mday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      sym("commercial"),
				      f_frozen_ary(6,
						  sym("cwyear"),
						  sym("cweek"),
						  sym("cwday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      sym("wday"),
				      f_frozen_ary(4,
						  sym("wday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      sym("wnum0"),
				      f_frozen_ary(6,
						  sym("year"),
						  sym("wnum0"),
						  sym("wday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      sym("wnum1"),
				      f_frozen_ary(6,
						  sym("year"),
						  sym("wnum1"),
						  sym("wday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      Qnil,
				      f_frozen_ary(6,
						  sym("cwyear"),
						  sym("cweek"),
						  sym("wday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      Qnil,
				      f_frozen_ary(6,
						  sym("year"),
						  sym("wnum0"),
						  sym("cwday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))),
			  f_frozen_ary(2,
				      Qnil,
				      f_frozen_ary(6,
						  sym("year"),
						  sym("wnum1"),
						  sym("cwday"),
						  sym("hour"),
						  sym("min"),
						  sym("sec"))));
	rb_gc_register_mark_object(tab);
    }

    {
	long i, eno = 0, idx = 0;

	for (i = 0; i < RARRAY_LEN(tab); i++) {
	    VALUE x, a;

	    x = RARRAY_AREF(tab, i);
	    a = RARRAY_AREF(x, 1);

	    {
		long j, n = 0;

		for (j = 0; j < RARRAY_LEN(a); j++)
		    if (!NIL_P(ref_hash0(RARRAY_AREF(a, j))))
			n++;
		if (n > eno) {
		    eno = n;
		    idx = i;
		}
	    }
	}
	if (eno == 0)
	    g = 0;
	else {
	    g = 1;
	    k = RARRAY_AREF(RARRAY_AREF(tab, idx), 0);
	    a = RARRAY_AREF(RARRAY_AREF(tab, idx), 1);
	    e =	eno;
	}
    }

    d = Qnil;

    if (g && !NIL_P(k) && (RARRAY_LEN(a) - e)) {
	if (k == sym("ordinal")) {
	    if (NIL_P(ref_hash("year"))) {
		if (NIL_P(d))
		    d = date_s_today(0, (VALUE *)0, cDate);
		set_hash("year", d_lite_year(d));
	    }
	    if (NIL_P(ref_hash("yday")))
		set_hash("yday", INT2FIX(1));
	}
	else if (k == sym("civil")) {
	    long i;

	    for (i = 0; i < RARRAY_LEN(a); i++) {
		VALUE e = RARRAY_AREF(a, i);

		if (!NIL_P(ref_hash0(e)))
		    break;
		if (NIL_P(d))
		    d = date_s_today(0, (VALUE *)0, cDate);
		set_hash0(e, rb_funcall(d, SYM2ID(e), 0));
	    }
	    if (NIL_P(ref_hash("mon")))
		set_hash("mon", INT2FIX(1));
	    if (NIL_P(ref_hash("mday")))
		set_hash("mday", INT2FIX(1));
	}
	else if (k == sym("commercial")) {
	    long i;

	    for (i = 0; i < RARRAY_LEN(a); i++) {
		VALUE e = RARRAY_AREF(a, i);

		if (!NIL_P(ref_hash0(e)))
		    break;
		if (NIL_P(d))
		    d = date_s_today(0, (VALUE *)0, cDate);
		set_hash0(e, rb_funcall(d, SYM2ID(e), 0));
	    }
	    if (NIL_P(ref_hash("cweek")))
		set_hash("cweek", INT2FIX(1));
	    if (NIL_P(ref_hash("cwday")))
		set_hash("cwday", INT2FIX(1));
	}
	else if (k == sym("wday")) {
	    if (NIL_P(d))
		d = date_s_today(0, (VALUE *)0, cDate);
	    set_hash("jd", d_lite_jd(f_add(f_sub(d,
						 d_lite_wday(d)),
					   ref_hash("wday"))));
	}
	else if (k == sym("wnum0")) {
	    long i;

	    for (i = 0; i < RARRAY_LEN(a); i++) {
		VALUE e = RARRAY_AREF(a, i);

		if (!NIL_P(ref_hash0(e)))
		    break;
		if (NIL_P(d))
		    d = date_s_today(0, (VALUE *)0, cDate);
		set_hash0(e, rb_funcall(d, SYM2ID(e), 0));
	    }
	    if (NIL_P(ref_hash("wnum0")))
		set_hash("wnum0", INT2FIX(0));
	    if (NIL_P(ref_hash("wday")))
		set_hash("wday", INT2FIX(0));
	}
	else if (k == sym("wnum1")) {
	    long i;

	    for (i = 0; i < RARRAY_LEN(a); i++) {
		VALUE e = RARRAY_AREF(a, i);

		if (!NIL_P(ref_hash0(e)))
		    break;
		if (NIL_P(d))
		    d = date_s_today(0, (VALUE *)0, cDate);
		set_hash0(e, rb_funcall(d, SYM2ID(e), 0));
	    }
	    if (NIL_P(ref_hash("wnum1")))
		set_hash("wnum1", INT2FIX(0));
	    if (NIL_P(ref_hash("wday")))
		set_hash("wday", INT2FIX(1));
	}
    }

    if (g && k == sym("time")) {
	if (f_le_p(klass, cDateTime)) {
	    if (NIL_P(d))
		d = date_s_today(0, (VALUE *)0, cDate);
	    if (NIL_P(ref_hash("jd")))
		set_hash("jd", d_lite_jd(d));
	}
    }

    if (NIL_P(ref_hash("hour")))
	set_hash("hour", INT2FIX(0));
    if (NIL_P(ref_hash("min")))
	set_hash("min", INT2FIX(0));
    if (NIL_P(ref_hash("sec")))
	set_hash("sec", INT2FIX(0));
    else if (f_gt_p(ref_hash("sec"), INT2FIX(59)))
	set_hash("sec", INT2FIX(59));

    return hash;
}

static VALUE
rt__valid_jd_p(VALUE jd, VALUE sg)
{
    return jd;
}

static VALUE
rt__valid_ordinal_p(VALUE y, VALUE d, VALUE sg)
{
    VALUE nth, rjd2;
    int ry, rd, rjd, ns;

    if (!valid_ordinal_p(y, NUM2INT(d), NUM2DBL(sg),
			 &nth, &ry,
			 &rd, &rjd,
			 &ns))
	return Qnil;
    encode_jd(nth, rjd, &rjd2);
    return rjd2;
}

static VALUE
rt__valid_civil_p(VALUE y, VALUE m, VALUE d, VALUE sg)
{
    VALUE nth, rjd2;
    int ry, rm, rd, rjd, ns;

    if (!valid_civil_p(y, NUM2INT(m), NUM2INT(d), NUM2DBL(sg),
		       &nth, &ry,
		       &rm, &rd, &rjd,
		       &ns))
	return Qnil;
    encode_jd(nth, rjd, &rjd2);
    return rjd2;
}

static VALUE
rt__valid_commercial_p(VALUE y, VALUE w, VALUE d, VALUE sg)
{
    VALUE nth, rjd2;
    int ry, rw, rd, rjd, ns;

    if (!valid_commercial_p(y, NUM2INT(w), NUM2INT(d), NUM2DBL(sg),
			    &nth, &ry,
			    &rw, &rd, &rjd,
			    &ns))
	return Qnil;
    encode_jd(nth, rjd, &rjd2);
    return rjd2;
}

static VALUE
rt__valid_weeknum_p(VALUE y, VALUE w, VALUE d, VALUE f, VALUE sg)
{
    VALUE nth, rjd2;
    int ry, rw, rd, rjd, ns;

    if (!valid_weeknum_p(y, NUM2INT(w), NUM2INT(d), NUM2INT(f), NUM2DBL(sg),
			 &nth, &ry,
			 &rw, &rd, &rjd,
			 &ns))
	return Qnil;
    encode_jd(nth, rjd, &rjd2);
    return rjd2;
}

static VALUE
rt__valid_date_frags_p(VALUE hash, VALUE sg)
{
    {
	VALUE vjd;

	if (!NIL_P(vjd = ref_hash("jd"))) {
	    VALUE jd = rt__valid_jd_p(vjd, sg);
	    if (!NIL_P(jd))
		return jd;
	}
    }

    {
	VALUE year, yday;

	if (!NIL_P(yday = ref_hash("yday")) &&
	    !NIL_P(year = ref_hash("year"))) {
	    VALUE jd = rt__valid_ordinal_p(year, yday, sg);
	    if (!NIL_P(jd))
		return jd;
	}
    }

    {
	VALUE year, mon, mday;

	if (!NIL_P(mday = ref_hash("mday")) &&
	    !NIL_P(mon = ref_hash("mon")) &&
	    !NIL_P(year = ref_hash("year"))) {
	    VALUE jd = rt__valid_civil_p(year, mon, mday, sg);
	    if (!NIL_P(jd))
		return jd;
	}
    }

    {
	VALUE year, week, wday;

	wday = ref_hash("cwday");
	if (NIL_P(wday)) {
	    wday = ref_hash("wday");
	    if (!NIL_P(wday))
		if (f_zero_p(wday))
		    wday = INT2FIX(7);
	}

	if (!NIL_P(wday) &&
	    !NIL_P(week = ref_hash("cweek")) &&
	    !NIL_P(year = ref_hash("cwyear"))) {
	    VALUE jd = rt__valid_commercial_p(year, week, wday, sg);
	    if (!NIL_P(jd))
		return jd;
	}
    }

    {
	VALUE year, week, wday;

	wday = ref_hash("wday");
	if (NIL_P(wday)) {
	    wday = ref_hash("cwday");
	    if (!NIL_P(wday))
		if (f_eqeq_p(wday, INT2FIX(7)))
		    wday = INT2FIX(0);
	}

	if (!NIL_P(wday) &&
	    !NIL_P(week = ref_hash("wnum0")) &&
	    !NIL_P(year = ref_hash("year"))) {
	    VALUE jd = rt__valid_weeknum_p(year, week, wday, INT2FIX(0), sg);
	    if (!NIL_P(jd))
		return jd;
	}
    }

    {
	VALUE year, week, wday;

	wday = ref_hash("wday");
	if (NIL_P(wday))
	    wday = ref_hash("cwday");
	if (!NIL_P(wday))
	    wday = f_mod(f_sub(wday, INT2FIX(1)),
			 INT2FIX(7));

	if (!NIL_P(wday) &&
	    !NIL_P(week = ref_hash("wnum1")) &&
	    !NIL_P(year = ref_hash("year"))) {
	    VALUE jd = rt__valid_weeknum_p(year, week, wday, INT2FIX(1), sg);
	    if (!NIL_P(jd))
		return jd;
	}
    }
    return Qnil;
}

static VALUE
d_new_by_frags(VALUE klass, VALUE hash, VALUE sg)
{
    VALUE jd;

    if (!c_valid_start_p(NUM2DBL(sg))) {
	sg = INT2FIX(DEFAULT_SG);
	rb_warning("invalid start is ignored");
    }

    if (NIL_P(hash))
	rb_raise(eDateError, "invalid date");

    if (NIL_P(ref_hash("jd")) &&
	NIL_P(ref_hash("yday")) &&
	!NIL_P(ref_hash("year")) &&
	!NIL_P(ref_hash("mon")) &&
	!NIL_P(ref_hash("mday")))
	jd = rt__valid_civil_p(ref_hash("year"),
			       ref_hash("mon"),
			       ref_hash("mday"), sg);
    else {
	hash = rt_rewrite_frags(hash);
	hash = rt_complete_frags(klass, hash);
	jd = rt__valid_date_frags_p(hash, sg);
    }

    if (NIL_P(jd))
	rb_raise(eDateError, "invalid date");
    {
	VALUE nth;
	int rjd;

	decode_jd(jd, &nth, &rjd);
	return d_simple_new_internal(klass,
				     nth, rjd,
				     NUM2DBL(sg),
				     0, 0, 0,
				     HAVE_JD);
    }
}

VALUE date__strptime(const char *str, size_t slen,
		     const char *fmt, size_t flen, VALUE hash);

static VALUE
date_s__strptime_internal(int argc, VALUE *argv, VALUE klass,
			  const char *default_fmt)
{
    VALUE vstr, vfmt, hash;
    const char *str, *fmt;
    size_t slen, flen;

    rb_scan_args(argc, argv, "11", &vstr, &vfmt);

    StringValue(vstr);
    if (!rb_enc_str_asciicompat_p(vstr))
	rb_raise(rb_eArgError,
		 "string should have ASCII compatible encoding");
    str = RSTRING_PTR(vstr);
    slen = RSTRING_LEN(vstr);
    if (argc < 2) {
	fmt = default_fmt;
	flen = strlen(default_fmt);
    }
    else {
	StringValue(vfmt);
	if (!rb_enc_str_asciicompat_p(vfmt))
	    rb_raise(rb_eArgError,
		     "format should have ASCII compatible encoding");
	fmt = RSTRING_PTR(vfmt);
	flen = RSTRING_LEN(vfmt);
    }
    hash = rb_hash_new();
    if (NIL_P(date__strptime(str, slen, fmt, flen, hash)))
	return Qnil;

    {
	VALUE zone = ref_hash("zone");
	VALUE left = ref_hash("leftover");

	if (!NIL_P(zone)) {
	    rb_enc_copy(zone, vstr);
	    set_hash("zone", zone);
	}
	if (!NIL_P(left)) {
	    rb_enc_copy(left, vstr);
	    set_hash("leftover", left);
	}
    }

    return hash;
}

/*
 * call-seq:
 *   Date._strptime(string, format = '%F') -> hash
 *
 * Returns a hash of values parsed from +string+
 * according to the given +format+:
 *
 *   Date._strptime('2001-02-03', '%Y-%m-%d') # => {:year=>2001, :mon=>2, :mday=>3}
 *
 * For other formats, see
 * {Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html].
 * (Unlike Date.strftime, does not support flags and width.)
 *
 * See also {strptime(3)}[https://man7.org/linux/man-pages/man3/strptime.3.html].
 *
 * Related: Date.strptime (returns a \Date object).
 */
static VALUE
date_s__strptime(int argc, VALUE *argv, VALUE klass)
{
    return date_s__strptime_internal(argc, argv, klass, "%F");
}

/*
 * call-seq:
 *   Date.strptime(string = '-4712-01-01', format = '%F', start = Date::ITALY) -> date
 *
 * Returns a new \Date object with values parsed from +string+,
 * according to the given +format+:
 *
 *   Date.strptime('2001-02-03', '%Y-%m-%d')  # => #<Date: 2001-02-03>
 *   Date.strptime('03-02-2001', '%d-%m-%Y')  # => #<Date: 2001-02-03>
 *   Date.strptime('2001-034', '%Y-%j')       # => #<Date: 2001-02-03>
 *   Date.strptime('2001-W05-6', '%G-W%V-%u') # => #<Date: 2001-02-03>
 *   Date.strptime('2001 04 6', '%Y %U %w')   # => #<Date: 2001-02-03>
 *   Date.strptime('2001 05 6', '%Y %W %u')   # => #<Date: 2001-02-03>
 *   Date.strptime('sat3feb01', '%a%d%b%y')   # => #<Date: 2001-02-03>
 *
 * For other formats, see
 * {Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html].
 * (Unlike Date.strftime, does not support flags and width.)
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 * See also {strptime(3)}[https://man7.org/linux/man-pages/man3/strptime.3.html].
 *
 * Related: Date._strptime (returns a hash).
 */
static VALUE
date_s_strptime(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, fmt, sg;

    rb_scan_args(argc, argv, "03", &str, &fmt, &sg);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATE);
      case 1:
	fmt = rb_str_new2("%F");
      case 2:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
	VALUE argv2[2], hash;

	argv2[0] = str;
	argv2[1] = fmt;
	hash = date_s__strptime(2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

VALUE date__parse(VALUE str, VALUE comp);

static size_t
get_limit(VALUE opt)
{
    if (!NIL_P(opt)) {
        VALUE limit = rb_hash_aref(opt, ID2SYM(rb_intern("limit")));
        if (NIL_P(limit)) return SIZE_MAX;
        return NUM2SIZET(limit);
    }
    return 128;
}

#ifndef HAVE_RB_CATEGORY_WARN
#define rb_category_warn(category, fmt) rb_warn(fmt)
#endif

static void
check_limit(VALUE str, VALUE opt)
{
    size_t slen, limit;
    if (NIL_P(str)) return;
    StringValue(str);
    slen = RSTRING_LEN(str);
    limit = get_limit(opt);
    if (slen > limit) {
	rb_raise(rb_eArgError,
		 "string length (%"PRI_SIZE_PREFIX"u) exceeds the limit %"PRI_SIZE_PREFIX"u", slen, limit);
    }
}

static VALUE
date_s__parse_internal(int argc, VALUE *argv, VALUE klass)
{
    VALUE vstr, vcomp, hash, opt;

    argc = rb_scan_args(argc, argv, "11:", &vstr, &vcomp, &opt);
    check_limit(vstr, opt);
    StringValue(vstr);
    if (!rb_enc_str_asciicompat_p(vstr))
	rb_raise(rb_eArgError,
		 "string should have ASCII compatible encoding");
    if (argc < 2)
	vcomp = Qtrue;

    hash = date__parse(vstr, vcomp);

    return hash;
}

/*
 * call-seq:
 *   Date._parse(string, comp = true, limit: 128) -> hash
 *
 * <b>Note</b>:
 * This method recognizes many forms in +string+,
 * but it is not a validator.
 * For formats, see
 * {"Specialized Format Strings" in Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-Specialized+Format+Strings]
 *
 * If +string+ does not specify a valid date,
 * the result is unpredictable;
 * consider using Date._strptime instead.
 *
 * Returns a hash of values parsed from +string+:
 *
 *   Date._parse('2001-02-03') # => {:year=>2001, :mon=>2, :mday=>3}
 *
 * If +comp+ is +true+ and the given year is in the range <tt>(0..99)</tt>,
 * the current century is supplied;
 * otherwise, the year is taken as given:
 *
 *   Date._parse('01-02-03', true)  # => {:year=>2001, :mon=>2, :mday=>3}
 *   Date._parse('01-02-03', false) # => {:year=>1, :mon=>2, :mday=>3}
 *
 * See argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date.parse(returns a \Date object).
 */
static VALUE
date_s__parse(int argc, VALUE *argv, VALUE klass)
{
    return date_s__parse_internal(argc, argv, klass);
}

/*
 * call-seq:
 *   Date.parse(string = '-4712-01-01', comp = true, start = Date::ITALY, limit: 128) -> date
 *
 * <b>Note</b>:
 * This method recognizes many forms in +string+,
 * but it is not a validator.
 * For formats, see
 * {"Specialized Format Strings" in Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-Specialized+Format+Strings]
 * If +string+ does not specify a valid date,
 * the result is unpredictable;
 * consider using Date._strptime instead.
 *
 * Returns a new \Date object with values parsed from +string+:
 *
 *   Date.parse('2001-02-03')   # => #<Date: 2001-02-03>
 *   Date.parse('20010203')     # => #<Date: 2001-02-03>
 *   Date.parse('3rd Feb 2001') # => #<Date: 2001-02-03>
 *
 * If +comp+ is +true+ and the given year is in the range <tt>(0..99)</tt>,
 * the current century is supplied;
 * otherwise, the year is taken as given:
 *
 *   Date.parse('01-02-03', true)  # => #<Date: 2001-02-03>
 *   Date.parse('01-02-03', false) # => #<Date: 0001-02-03>
 *
 * See:
 *
 * - Argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 * - Argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date._parse (returns a hash).
 */
static VALUE
date_s_parse(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, comp, sg, opt;

    argc = rb_scan_args(argc, argv, "03:", &str, &comp, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATE);
      case 1:
	comp = Qtrue;
      case 2:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 2;
	VALUE argv2[3], hash;
        argv2[0] = str;
        argv2[1] = comp;
        if (!NIL_P(opt)) argv2[argc2++] = opt;
	hash = date_s__parse(argc2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

VALUE date__iso8601(VALUE);
VALUE date__rfc3339(VALUE);
VALUE date__xmlschema(VALUE);
VALUE date__rfc2822(VALUE);
VALUE date__httpdate(VALUE);
VALUE date__jisx0301(VALUE);

/*
 * call-seq:
 *   Date._iso8601(string, limit: 128) -> hash
 *
 * Returns a hash of values parsed from +string+, which should contain
 * an {ISO 8601 formatted date}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-ISO+8601+Format+Specifications]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.iso8601    # => "2001-02-03"
 *   Date._iso8601(s) # => {:mday=>3, :year=>2001, :mon=>2}
 *
 * See argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date.iso8601 (returns a \Date object).
 */
static VALUE
date_s__iso8601(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, opt;

    rb_scan_args(argc, argv, "1:", &str, &opt);
    check_limit(str, opt);

    return date__iso8601(str);
}

/*
 * call-seq:
 *   Date.iso8601(string = '-4712-01-01', start = Date::ITALY, limit: 128) -> date
 *
 * Returns a new \Date object with values parsed from +string+,
 * which should contain
 * an {ISO 8601 formatted date}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-ISO+8601+Format+Specifications]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.iso8601   # => "2001-02-03"
 *   Date.iso8601(s) # => #<Date: 2001-02-03>
 *
 * See:
 *
 * - Argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 * - Argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date._iso8601 (returns a hash).
 */
static VALUE
date_s_iso8601(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATE);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        if (!NIL_P(opt)) argv2[argc2++] = opt;
	hash = date_s__iso8601(argc2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *   Date._rfc3339(string, limit: 128) -> hash
 *
 * Returns a hash of values parsed from +string+, which should be a valid
 * {RFC 3339 format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-RFC+3339+Format]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.rfc3339     # => "2001-02-03T00:00:00+00:00"
 *   Date._rfc3339(s)
 *   # => {:year=>2001, :mon=>2, :mday=>3, :hour=>0, :min=>0, :sec=>0, :zone=>"+00:00", :offset=>0}
 *
 * See argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date.rfc3339 (returns a \Date object).
 */
static VALUE
date_s__rfc3339(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, opt;

    rb_scan_args(argc, argv, "1:", &str, &opt);
    check_limit(str, opt);

    return date__rfc3339(str);
}

/*
 * call-seq:
 *   Date.rfc3339(string = '-4712-01-01T00:00:00+00:00', start = Date::ITALY, limit: 128) -> date
 *
 * Returns a new \Date object with values parsed from +string+,
 * which should be a valid
 * {RFC 3339 format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-RFC+3339+Format]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.rfc3339   # => "2001-02-03T00:00:00+00:00"
 *   Date.rfc3339(s) # => #<Date: 2001-02-03>
 *
 * See:
 *
 * - Argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 * - Argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date._rfc3339 (returns a hash).
 */
static VALUE
date_s_rfc3339(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        if (!NIL_P(opt)) argv2[argc2++] = opt;
	hash = date_s__rfc3339(argc2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *   Date._xmlschema(string, limit: 128) -> hash
 *
 * Returns a hash of values parsed from +string+, which should be a valid
 * XML date format:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.xmlschema    # => "2001-02-03"
 *   Date._xmlschema(s) # => {:year=>2001, :mon=>2, :mday=>3}
 *
 * See argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date.xmlschema (returns a \Date object).
 */
static VALUE
date_s__xmlschema(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, opt;

    rb_scan_args(argc, argv, "1:", &str, &opt);
    check_limit(str, opt);

    return date__xmlschema(str);
}

/*
 * call-seq:
 *   Date.xmlschema(string = '-4712-01-01', start = Date::ITALY, limit: 128)  ->  date
 *
 * Returns a new \Date object with values parsed from +string+,
 * which should be a valid XML date format:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.xmlschema   # => "2001-02-03"
 *   Date.xmlschema(s) # => #<Date: 2001-02-03>
 *
 * See:
 *
 * - Argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 * - Argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date._xmlschema (returns a hash).
 */
static VALUE
date_s_xmlschema(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATE);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        if (!NIL_P(opt)) argv2[argc2++] = opt;
	hash = date_s__xmlschema(argc2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *   Date._rfc2822(string, limit: 128) -> hash
 *
 * Returns a hash of values parsed from +string+, which should be a valid
 * {RFC 2822 date format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-RFC+2822+Format]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.rfc2822 # => "Sat, 3 Feb 2001 00:00:00 +0000"
 *   Date._rfc2822(s)
 *   # => {:wday=>6, :mday=>3, :mon=>2, :year=>2001, :hour=>0, :min=>0, :sec=>0, :zone=>"+0000", :offset=>0}
 *
 * See argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date.rfc2822 (returns a \Date object).
 */
static VALUE
date_s__rfc2822(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, opt;

    rb_scan_args(argc, argv, "1:", &str, &opt);
    check_limit(str, opt);

    return date__rfc2822(str);
}

/*
 * call-seq:
 *   Date.rfc2822(string = 'Mon, 1 Jan -4712 00:00:00 +0000', start = Date::ITALY, limit: 128) -> date
 *
 * Returns a new \Date object with values parsed from +string+,
 * which should be a valid
 * {RFC 2822 date format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-RFC+2822+Format]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.rfc2822   # => "Sat, 3 Feb 2001 00:00:00 +0000"
 *   Date.rfc2822(s) # => #<Date: 2001-02-03>
 *
 * See:
 *
 * - Argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 * - Argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date._rfc2822 (returns a hash).
 */
static VALUE
date_s_rfc2822(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME_RFC3339);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        if (!NIL_P(opt)) argv2[argc2++] = opt;
	hash = date_s__rfc2822(argc2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *   Date._httpdate(string, limit: 128) -> hash
 *
 * Returns a hash of values parsed from +string+, which should be a valid
 * {HTTP date format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-HTTP+Format]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.httpdate # => "Sat, 03 Feb 2001 00:00:00 GMT"
 *   Date._httpdate(s)
 *   # => {:wday=>6, :mday=>3, :mon=>2, :year=>2001, :hour=>0, :min=>0, :sec=>0, :zone=>"GMT", :offset=>0}
 *
 * Related: Date.httpdate (returns a \Date object).
 */
static VALUE
date_s__httpdate(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, opt;

    rb_scan_args(argc, argv, "1:", &str, &opt);
    check_limit(str, opt);

    return date__httpdate(str);
}

/*
 * call-seq:
 *   Date.httpdate(string = 'Mon, 01 Jan -4712 00:00:00 GMT', start = Date::ITALY, limit: 128) -> date
 *
 * Returns a new \Date object with values parsed from +string+,
 * which should be a valid
 * {HTTP date format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-HTTP+Format]:
 *
 *   d = Date.new(2001, 2, 3)
     s = d.httpdate   # => "Sat, 03 Feb 2001 00:00:00 GMT"
     Date.httpdate(s) # => #<Date: 2001-02-03>
 *
 * See:
 *
 * - Argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 * - Argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date._httpdate (returns a hash).
 */
static VALUE
date_s_httpdate(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME_HTTPDATE);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        if (!NIL_P(opt)) argv2[argc2++] = opt;
	hash = date_s__httpdate(argc2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *   Date._jisx0301(string, limit: 128) -> hash
 *
 * Returns a hash of values parsed from +string+, which should be a valid
 * {JIS X 0301 date format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-JIS+X+0301+Format]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.jisx0301    # => "H13.02.03"
 *   Date._jisx0301(s) # => {:year=>2001, :mon=>2, :mday=>3}
 *
 * See argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date.jisx0301 (returns a \Date object).
 */
static VALUE
date_s__jisx0301(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, opt;

    rb_scan_args(argc, argv, "1:", &str, &opt);
    check_limit(str, opt);

    return date__jisx0301(str);
}

/*
 * call-seq:
 *   Date.jisx0301(string = '-4712-01-01', start = Date::ITALY, limit: 128) -> date
 *
 * Returns a new \Date object with values parsed from +string+,
 * which should be a valid {JIS X 0301 format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-JIS+X+0301+Format]:
 *
 *   d = Date.new(2001, 2, 3)
 *   s = d.jisx0301   # => "H13.02.03"
 *   Date.jisx0301(s) # => #<Date: 2001-02-03>
 *
 * For no-era year, legacy format, Heisei is assumed.
 *
 *   Date.jisx0301('13.02.03') # => #<Date: 2001-02-03>
 *
 * See:
 *
 * - Argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 * - Argument {limit}[rdoc-ref:Date@Argument+limit].
 *
 * Related: Date._jisx0301 (returns a hash).
 */
static VALUE
date_s_jisx0301(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATE);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        if (!NIL_P(opt)) argv2[argc2++] = opt;
	hash = date_s__jisx0301(argc2, argv2, klass);
	return d_new_by_frags(klass, hash, sg);
    }
}

static VALUE
dup_obj(VALUE self)
{
    get_d1a(self);

    if (simple_dat_p(adat)) {
	VALUE new = d_lite_s_alloc_simple(rb_obj_class(self));
	{
	    get_d1b(new);
	    bdat->s = adat->s;
	    RB_OBJ_WRITTEN(new, Qundef, bdat->s.nth);
	    return new;
	}
    }
    else {
	VALUE new = d_lite_s_alloc_complex(rb_obj_class(self));
	{
	    get_d1b(new);
	    bdat->c = adat->c;
	    RB_OBJ_WRITTEN(new, Qundef, bdat->c.nth);
	    RB_OBJ_WRITTEN(new, Qundef, bdat->c.sf);
	    return new;
	}
    }
}

static VALUE
dup_obj_as_complex(VALUE self)
{
    get_d1a(self);

    if (simple_dat_p(adat)) {
	VALUE new = d_lite_s_alloc_complex(rb_obj_class(self));
	{
	    get_d1b(new);
	    copy_simple_to_complex(new, &bdat->c, &adat->s);
	    bdat->c.flags |= HAVE_DF | COMPLEX_DAT;
	    return new;
	}
    }
    else {
	VALUE new = d_lite_s_alloc_complex(rb_obj_class(self));
	{
	    get_d1b(new);
	    bdat->c = adat->c;
	    RB_OBJ_WRITTEN(new, Qundef, bdat->c.nth);
	    RB_OBJ_WRITTEN(new, Qundef, bdat->c.sf);
	    return new;
	}
    }
}

#define val2off(vof,iof) \
do {\
    if (!offset_to_sec(vof, &iof)) {\
	iof = 0;\
	rb_warning("invalid offset is ignored");\
    }\
} while (0)

#if 0
static VALUE
d_lite_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE jd, vjd, vdf, sf, vsf, vof, vsg;
    int df, of;
    double sg;

    rb_check_frozen(self);

    rb_scan_args(argc, argv, "05", &vjd, &vdf, &vsf, &vof, &vsg);

    jd = INT2FIX(0);
    df = 0;
    sf = INT2FIX(0);
    of = 0;
    sg = DEFAULT_SG;

    switch (argc) {
      case 5:
	val2sg(vsg, sg);
      case 4:
	val2off(vof, of);
      case 3:
	sf = vsf;
	if (f_lt_p(sf, INT2FIX(0)) ||
	    f_ge_p(sf, INT2FIX(SECOND_IN_NANOSECONDS)))
	    rb_raise(eDateError, "invalid second fraction");
      case 2:
	df = NUM2INT(vdf);
	if (df < 0 || df >= DAY_IN_SECONDS)
	    rb_raise(eDateError, "invalid day fraction");
      case 1:
	jd = vjd;
    }

    {
	VALUE nth;
	int rjd;

	get_d1(self);

	decode_jd(jd, &nth, &rjd);
	if (!df && f_zero_p(sf) && !of) {
	    set_to_simple(self, &dat->s, nth, rjd, sg, 0, 0, 0, HAVE_JD);
	}
	else {
	    if (!complex_dat_p(dat))
		rb_raise(rb_eArgError,
			 "cannot load complex into simple");

	    set_to_complex(self, &dat->c, nth, rjd, df, sf, of, sg,
			   0, 0, 0, 0, 0, 0, HAVE_JD | HAVE_DF);
	}
    }
    return self;
}
#endif

/* :nodoc: */
static VALUE
d_lite_initialize_copy(VALUE copy, VALUE date)
{
    rb_check_frozen(copy);

    if (copy == date)
	return copy;
    {
	get_d2(copy, date);
	if (simple_dat_p(bdat)) {
	    if (simple_dat_p(adat)) {
		adat->s = bdat->s;
	    }
	    else {
		adat->c.flags = bdat->s.flags | COMPLEX_DAT;
		adat->c.nth = bdat->s.nth;
		adat->c.jd = bdat->s.jd;
		adat->c.df = 0;
		adat->c.sf = INT2FIX(0);
		adat->c.of = 0;
		adat->c.sg = bdat->s.sg;
		adat->c.year = bdat->s.year;
#ifndef USE_PACK
		adat->c.mon = bdat->s.mon;
		adat->c.mday = bdat->s.mday;
		adat->c.hour = bdat->s.hour;
		adat->c.min = bdat->s.min;
		adat->c.sec = bdat->s.sec;
#else
		adat->c.pc = bdat->s.pc;
#endif
	    }
	}
	else {
	    if (!complex_dat_p(adat))
		rb_raise(rb_eArgError,
			 "cannot load complex into simple");

	    adat->c = bdat->c;
	}
    }
    return copy;
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
d_lite_fill(VALUE self)
{
    get_d1(self);

    if (simple_dat_p(dat)) {
	get_s_jd(dat);
	get_s_civil(dat);
    }
    else {
	get_c_jd(dat);
	get_c_civil(dat);
	get_c_df(dat);
	get_c_time(dat);
    }
    return self;
}
#endif

/*
 * call-seq:
 *    d.ajd  ->  rational
 *
 * Returns the astronomical Julian day number.  This is a fractional
 * number, which is not adjusted by the offset.
 *
 *    DateTime.new(2001,2,3,4,5,6,'+7').ajd	#=> (11769328217/4800)
 *    DateTime.new(2001,2,2,14,5,6,'-7').ajd	#=> (11769328217/4800)
 */
static VALUE
d_lite_ajd(VALUE self)
{
    get_d1(self);
    return m_ajd(dat);
}

/*
 * call-seq:
 *    d.amjd  ->  rational
 *
 * Returns the astronomical modified Julian day number.  This is
 * a fractional number, which is not adjusted by the offset.
 *
 *    DateTime.new(2001,2,3,4,5,6,'+7').amjd	#=> (249325817/4800)
 *    DateTime.new(2001,2,2,14,5,6,'-7').amjd	#=> (249325817/4800)
 */
static VALUE
d_lite_amjd(VALUE self)
{
    get_d1(self);
    return m_amjd(dat);
}

/*
 * call-seq:
 *    d.jd  ->  integer
 *
 * Returns the Julian day number.  This is a whole number, which is
 * adjusted by the offset as the local time.
 *
 *    DateTime.new(2001,2,3,4,5,6,'+7').jd	#=> 2451944
 *    DateTime.new(2001,2,3,4,5,6,'-7').jd	#=> 2451944
 */
static VALUE
d_lite_jd(VALUE self)
{
    get_d1(self);
    return m_real_local_jd(dat);
}

/*
 * call-seq:
 *    d.mjd  ->  integer
 *
 * Returns the modified Julian day number.  This is a whole number,
 * which is adjusted by the offset as the local time.
 *
 *    DateTime.new(2001,2,3,4,5,6,'+7').mjd	#=> 51943
 *    DateTime.new(2001,2,3,4,5,6,'-7').mjd	#=> 51943
 */
static VALUE
d_lite_mjd(VALUE self)
{
    get_d1(self);
    return f_sub(m_real_local_jd(dat), INT2FIX(2400001));
}

/*
 * call-seq:
 *   ld -> integer
 *
 * Returns the
 * {Lilian day number}[https://en.wikipedia.org/wiki/Lilian_date],
 * which is the number of days since the beginning of the Gregorian
 * calendar, October 15, 1582.
 *
 *   Date.new(2001, 2, 3).ld # => 152784
 *
 */
static VALUE
d_lite_ld(VALUE self)
{
    get_d1(self);
    return f_sub(m_real_local_jd(dat), INT2FIX(2299160));
}

/*
 * call-seq:
 *   year -> integer
 *
 * Returns the year:
 *
 *   Date.new(2001, 2, 3).year    # => 2001
 *   (Date.new(1, 1, 1) - 1).year # => 0
 *
 */
static VALUE
d_lite_year(VALUE self)
{
    get_d1(self);
    return m_real_year(dat);
}

/*
 * call-seq:
 *   yday -> integer
 *
 * Returns the day of the year, in range (1..366):
 *
 *   Date.new(2001, 2, 3).yday # => 34
 *
 */
static VALUE
d_lite_yday(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_yday(dat));
}

/*
 * call-seq:
 *   mon -> integer
 *
 * Returns the month in range (1..12):
 *
 *   Date.new(2001, 2, 3).mon # => 2
 *
 */
static VALUE
d_lite_mon(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_mon(dat));
}

/*
 * call-seq:
 *   mday -> integer
 *
 * Returns the day of the month in range (1..31):
 *
 *   Date.new(2001, 2, 3).mday # => 3
 *
 */
static VALUE
d_lite_mday(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_mday(dat));
}

/*
 * call-seq:
 *   day_fraction -> rational
 *
 * Returns the fractional part of the day in range (Rational(0, 1)...Rational(1, 1)):
 *
 *   DateTime.new(2001,2,3,12).day_fraction # => (1/2)
 *
 */
static VALUE
d_lite_day_fraction(VALUE self)
{
    get_d1(self);
    if (simple_dat_p(dat))
	return INT2FIX(0);
    return m_fr(dat);
}

/*
 * call-seq:
 *   cwyear -> integer
 *
 * Returns commercial-date year for +self+
 * (see Date.commercial):
 *
 *   Date.new(2001, 2, 3).cwyear # => 2001
 *   Date.new(2000, 1, 1).cwyear # => 1999
 *
 */
static VALUE
d_lite_cwyear(VALUE self)
{
    get_d1(self);
    return m_real_cwyear(dat);
}

/*
 * call-seq:
 *   cweek -> integer
 *
 * Returns commercial-date week index for +self+
 * (see Date.commercial):
 *
 *   Date.new(2001, 2, 3).cweek # => 5
 *
 */
static VALUE
d_lite_cweek(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_cweek(dat));
}

/*
 * call-seq:
 *   cwday -> integer
 *
 * Returns the commercial-date weekday index for +self+
 * (see Date.commercial);
 * 1 is Monday:
 *
 *   Date.new(2001, 2, 3).cwday # => 6
 *
 */
static VALUE
d_lite_cwday(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_cwday(dat));
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
d_lite_wnum0(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_wnum0(dat));
}

/* :nodoc: */
static VALUE
d_lite_wnum1(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_wnum1(dat));
}
#endif

/*
 * call-seq:
 *   wday -> integer
 *
 * Returns the day of week in range (0..6); Sunday is 0:
 *
 *   Date.new(2001, 2, 3).wday # => 6
 *
 */
static VALUE
d_lite_wday(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_wday(dat));
}

/*
 * call-seq:
 *   sunday? -> true or false
 *
 * Returns +true+ if +self+ is a Sunday, +false+ otherwise.
 */
static VALUE
d_lite_sunday_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_wday(dat) == 0);
}

/*
 * call-seq:
 *   monday? -> true or false
 *
 * Returns +true+ if +self+ is a Monday, +false+ otherwise.
 */
static VALUE
d_lite_monday_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_wday(dat) == 1);
}

/*
 * call-seq:
 *   tuesday? -> true or false
 *
 * Returns +true+ if +self+ is a Tuesday, +false+ otherwise.
 */
static VALUE
d_lite_tuesday_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_wday(dat) == 2);
}

/*
 * call-seq:
 *   wednesday? -> true or false
 *
 * Returns +true+ if +self+ is a Wednesday, +false+ otherwise.
 */
static VALUE
d_lite_wednesday_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_wday(dat) == 3);
}

/*
 * call-seq:
 *   thursday? -> true or false
 *
 * Returns +true+ if +self+ is a Thursday, +false+ otherwise.
 */
static VALUE
d_lite_thursday_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_wday(dat) == 4);
}

/*
 * call-seq:
 *   friday? -> true or false
 *
 * Returns +true+ if +self+ is a Friday, +false+ otherwise.
 */
static VALUE
d_lite_friday_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_wday(dat) == 5);
}

/*
 * call-seq:
 *   saturday? -> true or false
 *
 * Returns +true+ if +self+ is a Saturday, +false+ otherwise.
 */
static VALUE
d_lite_saturday_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_wday(dat) == 6);
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
d_lite_nth_kday_p(VALUE self, VALUE n, VALUE k)
{
    int rjd, ns;

    get_d1(self);

    if (NUM2INT(k) != m_wday(dat))
	return Qfalse;

    c_nth_kday_to_jd(m_year(dat), m_mon(dat),
		     NUM2INT(n), NUM2INT(k), m_virtual_sg(dat), /* !=m_sg() */
		     &rjd, &ns);
    if (m_local_jd(dat) != rjd)
	return Qfalse;
    return Qtrue;
}
#endif

/*
 * call-seq:
 *   hour -> integer
 *
 * Returns the hour in range (0..23):
 *
 *   DateTime.new(2001, 2, 3, 4, 5, 6).hour # => 4
 *
 */
static VALUE
d_lite_hour(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_hour(dat));
}

/*
 * call-seq:
 *   min -> integer
 *
 * Returns the minute in range (0..59):
 *
 *   DateTime.new(2001, 2, 3, 4, 5, 6).min # => 5
 *
 */
static VALUE
d_lite_min(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_min(dat));
}

/*
 * call-seq:
 *   sec -> integer
 *
 * Returns the second in range (0..59):
 *
 *   DateTime.new(2001, 2, 3, 4, 5, 6).sec # => 6
 *
 */
static VALUE
d_lite_sec(VALUE self)
{
    get_d1(self);
    return INT2FIX(m_sec(dat));
}

/*
 * call-seq:
 *   sec_fraction -> rational
 *
 * Returns the fractional part of the second in range
 * (Rational(0, 1)...Rational(1, 1)):
 *
 *   DateTime.new(2001, 2, 3, 4, 5, 6.5).sec_fraction # => (1/2)
 *
 */
static VALUE
d_lite_sec_fraction(VALUE self)
{
    get_d1(self);
    return m_sf_in_sec(dat);
}

/*
 * call-seq:
 *    d.offset  ->  rational
 *
 * Returns the offset.
 *
 *    DateTime.parse('04pm+0730').offset	#=> (5/16)
 */
static VALUE
d_lite_offset(VALUE self)
{
    get_d1(self);
    return m_of_in_day(dat);
}

/*
 * call-seq:
 *    d.zone  ->  string
 *
 * Returns the timezone.
 *
 *    DateTime.parse('04pm+0730').zone		#=> "+07:30"
 */
static VALUE
d_lite_zone(VALUE self)
{
    get_d1(self);
    return m_zone(dat);
}

/*
 * call-seq:
 *   d.julian? -> true or false
 *
 * Returns +true+ if the date is before the date of calendar reform,
 * +false+ otherwise:
 *
 *   (Date.new(1582, 10, 15) - 1).julian? # => true
 *   Date.new(1582, 10, 15).julian?       # => false
 *
 */
static VALUE
d_lite_julian_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_julian_p(dat));
}

/*
 * call-seq:
 *   gregorian? -> true or false
 *
 * Returns +true+ if the date is on or after
 * the date of calendar reform, +false+ otherwise:
 *
 *   Date.new(1582, 10, 15).gregorian?       # => true
 *   (Date.new(1582, 10, 15) - 1).gregorian? # => false
 *
 */
static VALUE
d_lite_gregorian_p(VALUE self)
{
    get_d1(self);
    return f_boolcast(m_gregorian_p(dat));
}

/*
 * call-seq:
 *   leap? -> true or false
 *
 * Returns +true+ if the year is a leap year, +false+ otherwise:
 *
 *   Date.new(2000).leap? # => true
 *   Date.new(2001).leap? # => false
 *
 */
static VALUE
d_lite_leap_p(VALUE self)
{
    int rjd, ns, ry, rm, rd;

    get_d1(self);
    if (m_gregorian_p(dat))
	return f_boolcast(c_gregorian_leap_p(m_year(dat)));

    c_civil_to_jd(m_year(dat), 3, 1, m_virtual_sg(dat),
		  &rjd, &ns);
    c_jd_to_civil(rjd - 1, m_virtual_sg(dat), &ry, &rm, &rd);
    return f_boolcast(rd == 29);
}

/*
 * call-seq:
 *   start -> float
 *
 * Returns the Julian start date for calendar reform;
 * if not an infinity, the returned value is suitable
 * for passing to Date#jd:
 *
 *   d = Date.new(2001, 2, 3, Date::ITALY)
 *   s = d.start     # => 2299161.0
 *   Date.jd(s).to_s # => "1582-10-15"
 *
 *   d = Date.new(2001, 2, 3, Date::ENGLAND)
 *   s = d.start     # => 2361222.0
 *   Date.jd(s).to_s # => "1752-09-14"
 *
 *   Date.new(2001, 2, 3, Date::GREGORIAN).start # => -Infinity
 *   Date.new(2001, 2, 3, Date::JULIAN).start    # => Infinity
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 */
static VALUE
d_lite_start(VALUE self)
{
    get_d1(self);
    return DBL2NUM(m_sg(dat));
}

static void
clear_civil(union DateData *x)
{
    if (simple_dat_p(x)) {
	x->s.year = 0;
#ifndef USE_PACK
	x->s.mon = 0;
	x->s.mday = 0;
#else
	x->s.pc = 0;
#endif
	x->s.flags &= ~HAVE_CIVIL;
    }
    else {
	x->c.year = 0;
#ifndef USE_PACK
	x->c.mon = 0;
	x->c.mday = 0;
	x->c.hour = 0;
	x->c.min = 0;
	x->c.sec = 0;
#else
	x->c.pc = 0;
#endif
	x->c.flags &= ~(HAVE_CIVIL | HAVE_TIME);
    }
}

static void
set_sg(union DateData *x, double sg)
{
    if (simple_dat_p(x)) {
	get_s_jd(x);
	clear_civil(x);
	x->s.sg = (date_sg_t)sg;
    } else {
	get_c_jd(x);
	get_c_df(x);
	clear_civil(x);
	x->c.sg = (date_sg_t)sg;
    }
}

static VALUE
dup_obj_with_new_start(VALUE obj, double sg)
{
    volatile VALUE dup = dup_obj(obj);
    {
	get_d1(dup);
	set_sg(dat, sg);
    }
    return dup;
}

/*
 * call-seq:
 *   new_start(start = Date::ITALY]) -> new_date
 *
 * Returns a copy of +self+ with the given +start+ value:
 *
 *   d0 = Date.new(2000, 2, 3)
 *   d0.julian? # => false
 *   d1 = d0.new_start(Date::JULIAN)
 *   d1.julian? # => true
 *
 * See argument {start}[rdoc-ref:calendars.rdoc@Argument+start].
 *
 */
static VALUE
d_lite_new_start(int argc, VALUE *argv, VALUE self)
{
    VALUE vsg;
    double sg;

    rb_scan_args(argc, argv, "01", &vsg);

    sg = DEFAULT_SG;
    if (argc >= 1)
	val2sg(vsg, sg);

    return dup_obj_with_new_start(self, sg);
}

/*
 * call-seq:
 *   italy -> new_date
 *
 * Equivalent to Date#new_start with argument Date::ITALY.
 *
 */
static VALUE
d_lite_italy(VALUE self)
{
    return dup_obj_with_new_start(self, ITALY);
}

/*
 * call-seq:
 *   england -> new_date
 *
 * Equivalent to Date#new_start with argument Date::ENGLAND.
 */
static VALUE
d_lite_england(VALUE self)
{
    return dup_obj_with_new_start(self, ENGLAND);
}

/*
 * call-seq:
 *   julian -> new_date
 *
 * Equivalent to Date#new_start with argument Date::JULIAN.
 */
static VALUE
d_lite_julian(VALUE self)
{
    return dup_obj_with_new_start(self, JULIAN);
}

/*
 * call-seq:
 *   gregorian -> new_date
 *
 * Equivalent to Date#new_start with argument Date::GREGORIAN.
 */
static VALUE
d_lite_gregorian(VALUE self)
{
    return dup_obj_with_new_start(self, GREGORIAN);
}

static void
set_of(union DateData *x, int of)
{
    assert(complex_dat_p(x));
    get_c_jd(x);
    get_c_df(x);
    clear_civil(x);
    x->c.of = of;
}

static VALUE
dup_obj_with_new_offset(VALUE obj, int of)
{
    volatile VALUE dup = dup_obj_as_complex(obj);
    {
	get_d1(dup);
	set_of(dat, of);
    }
    return dup;
}

/*
 * call-seq:
 *    d.new_offset([offset=0])  ->  date
 *
 * Duplicates self and resets its offset.
 *
 *    d = DateTime.new(2001,2,3,4,5,6,'-02:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06-02:00 ...>
 *    d.new_offset('+09:00')	#=> #<DateTime: 2001-02-03T15:05:06+09:00 ...>
 */
static VALUE
d_lite_new_offset(int argc, VALUE *argv, VALUE self)
{
    VALUE vof;
    int rof;

    rb_scan_args(argc, argv, "01", &vof);

    rof = 0;
    if (argc >= 1)
	val2off(vof, rof);

    return dup_obj_with_new_offset(self, rof);
}

/*
 * call-seq:
 *    d + other  ->  date
 *
 * Returns a date object pointing +other+ days after self.  The other
 * should be a numeric value.  If the other is a fractional number,
 * assumes its precision is at most nanosecond.
 *
 *    Date.new(2001,2,3) + 1	#=> #<Date: 2001-02-04 ...>
 *    DateTime.new(2001,2,3) + Rational(1,2)
 *				#=> #<DateTime: 2001-02-03T12:00:00+00:00 ...>
 *    DateTime.new(2001,2,3) + Rational(-1,2)
 *				#=> #<DateTime: 2001-02-02T12:00:00+00:00 ...>
 *    DateTime.jd(0,12) + DateTime.new(2001,2,3).ajd
 *				#=> #<DateTime: 2001-02-03T00:00:00+00:00 ...>
 */
static VALUE
d_lite_plus(VALUE self, VALUE other)
{
    int try_rational = 1;
    get_d1(self);

  again:
    switch (TYPE(other)) {
      case T_FIXNUM:
	{
	    VALUE nth;
	    long t;
	    int jd;

	    nth = m_nth(dat);
	    t = FIX2LONG(other);
	    if (DIV(t, CM_PERIOD)) {
		nth = f_add(nth, INT2FIX(DIV(t, CM_PERIOD)));
		t = MOD(t, CM_PERIOD);
	    }

	    if (!t)
		jd = m_jd(dat);
	    else {
		jd = m_jd(dat) + (int)t;
		canonicalize_jd(nth, jd);
	    }

	    if (simple_dat_p(dat))
		return d_simple_new_internal(rb_obj_class(self),
					     nth, jd,
					     dat->s.sg,
					     0, 0, 0,
					     (dat->s.flags | HAVE_JD) &
					     ~HAVE_CIVIL);
	    else
		return d_complex_new_internal(rb_obj_class(self),
					      nth, jd,
					      dat->c.df, dat->c.sf,
					      dat->c.of, dat->c.sg,
					      0, 0, 0,
#ifndef USE_PACK
					      dat->c.hour,
					      dat->c.min,
					      dat->c.sec,
#else
					      EX_HOUR(dat->c.pc),
					      EX_MIN(dat->c.pc),
					      EX_SEC(dat->c.pc),
#endif
					      (dat->c.flags | HAVE_JD) &
					      ~HAVE_CIVIL);
	}
	break;
      case T_BIGNUM:
	{
	    VALUE nth;
	    int jd, s;

	    if (f_positive_p(other))
		s = +1;
	    else {
		s = -1;
		other = f_negate(other);
	    }

	    nth = f_idiv(other, INT2FIX(CM_PERIOD));
	    jd = FIX2INT(f_mod(other, INT2FIX(CM_PERIOD)));

	    if (s < 0) {
		nth = f_negate(nth);
		jd = -jd;
	    }

	    if (!jd)
		jd = m_jd(dat);
	    else {
		jd = m_jd(dat) + jd;
		canonicalize_jd(nth, jd);
	    }

	    if (f_zero_p(nth))
		nth = m_nth(dat);
	    else
		nth = f_add(m_nth(dat), nth);

	    if (simple_dat_p(dat))
		return d_simple_new_internal(rb_obj_class(self),
					     nth, jd,
					     dat->s.sg,
					     0, 0, 0,
					     (dat->s.flags | HAVE_JD) &
					     ~HAVE_CIVIL);
	    else
		return d_complex_new_internal(rb_obj_class(self),
					      nth, jd,
					      dat->c.df, dat->c.sf,
					      dat->c.of, dat->c.sg,
					      0, 0, 0,
#ifndef USE_PACK
					      dat->c.hour,
					      dat->c.min,
					      dat->c.sec,
#else
					      EX_HOUR(dat->c.pc),
					      EX_MIN(dat->c.pc),
					      EX_SEC(dat->c.pc),
#endif
					      (dat->c.flags | HAVE_JD) &
					      ~HAVE_CIVIL);
	}
	break;
      case T_FLOAT:
	{
	    double jd, o, tmp;
	    int s, df;
	    VALUE nth, sf;

	    o = RFLOAT_VALUE(other);

	    if (o > 0)
		s = +1;
	    else {
		s = -1;
		o = -o;
	    }

	    o = modf(o, &tmp);

	    if (!floor(tmp / CM_PERIOD)) {
		nth = INT2FIX(0);
		jd = (int)tmp;
	    }
	    else {
		double i, f;

		f = modf(tmp / CM_PERIOD, &i);
		nth = f_floor(DBL2NUM(i));
		jd = (int)(f * CM_PERIOD);
	    }

	    o *= DAY_IN_SECONDS;
	    o = modf(o, &tmp);
	    df = (int)tmp;
	    o *= SECOND_IN_NANOSECONDS;
	    sf = INT2FIX((int)round(o));

	    if (s < 0) {
		jd = -jd;
		df = -df;
		sf = f_negate(sf);
	    }

	    if (f_zero_p(sf))
		sf = m_sf(dat);
	    else {
		sf = f_add(m_sf(dat), sf);
		if (f_lt_p(sf, INT2FIX(0))) {
		    df -= 1;
		    sf = f_add(sf, INT2FIX(SECOND_IN_NANOSECONDS));
		}
		else if (f_ge_p(sf, INT2FIX(SECOND_IN_NANOSECONDS))) {
		    df += 1;
		    sf = f_sub(sf, INT2FIX(SECOND_IN_NANOSECONDS));
		}
	    }

	    if (!df)
		df = m_df(dat);
	    else {
		df = m_df(dat) + df;
		if (df < 0) {
		    jd -= 1;
		    df += DAY_IN_SECONDS;
		}
		else if (df >= DAY_IN_SECONDS) {
		    jd += 1;
		    df -= DAY_IN_SECONDS;
		}
	    }

	    if (!jd)
		jd = m_jd(dat);
	    else {
		jd = m_jd(dat) + jd;
		canonicalize_jd(nth, jd);
	    }

	    if (f_zero_p(nth))
		nth = m_nth(dat);
	    else
		nth = f_add(m_nth(dat), nth);

	    if (!df && f_zero_p(sf) && !m_of(dat))
		return d_simple_new_internal(rb_obj_class(self),
					     nth, (int)jd,
					     m_sg(dat),
					     0, 0, 0,
					     (dat->s.flags | HAVE_JD) &
					     ~(HAVE_CIVIL | HAVE_TIME |
					       COMPLEX_DAT));
	    else
		return d_complex_new_internal(rb_obj_class(self),
					      nth, (int)jd,
					      df, sf,
					      m_of(dat), m_sg(dat),
					      0, 0, 0,
					      0, 0, 0,
					      (dat->c.flags |
					       HAVE_JD | HAVE_DF) &
					      ~(HAVE_CIVIL | HAVE_TIME));
	}
	break;
      default:
	expect_numeric(other);
	other = f_to_r(other);
	if (!k_rational_p(other)) {
	    if (!try_rational) Check_Type(other, T_RATIONAL);
	    try_rational = 0;
	    goto again;
	}
	/* fall through */
      case T_RATIONAL:
	{
	    VALUE nth, sf, t;
	    int jd, df, s;

	    if (wholenum_p(other)) {
		other = rb_rational_num(other);
		goto again;
	    }

	    if (f_positive_p(other))
		s = +1;
	    else {
		s = -1;
		other = f_negate(other);
	    }

	    nth = f_idiv(other, INT2FIX(CM_PERIOD));
	    t = f_mod(other, INT2FIX(CM_PERIOD));

	    jd = FIX2INT(f_idiv(t, INT2FIX(1)));
	    t = f_mod(t, INT2FIX(1));

	    t = f_mul(t, INT2FIX(DAY_IN_SECONDS));
	    df = FIX2INT(f_idiv(t, INT2FIX(1)));
	    t = f_mod(t, INT2FIX(1));

	    sf = f_mul(t, INT2FIX(SECOND_IN_NANOSECONDS));

	    if (s < 0) {
		nth = f_negate(nth);
		jd = -jd;
		df = -df;
		sf = f_negate(sf);
	    }

	    if (f_zero_p(sf))
		sf = m_sf(dat);
	    else {
		sf = f_add(m_sf(dat), sf);
		if (f_lt_p(sf, INT2FIX(0))) {
		    df -= 1;
		    sf = f_add(sf, INT2FIX(SECOND_IN_NANOSECONDS));
		}
		else if (f_ge_p(sf, INT2FIX(SECOND_IN_NANOSECONDS))) {
		    df += 1;
		    sf = f_sub(sf, INT2FIX(SECOND_IN_NANOSECONDS));
		}
	    }

	    if (!df)
		df = m_df(dat);
	    else {
		df = m_df(dat) + df;
		if (df < 0) {
		    jd -= 1;
		    df += DAY_IN_SECONDS;
		}
		else if (df >= DAY_IN_SECONDS) {
		    jd += 1;
		    df -= DAY_IN_SECONDS;
		}
	    }

	    if (!jd)
		jd = m_jd(dat);
	    else {
		jd = m_jd(dat) + jd;
		canonicalize_jd(nth, jd);
	    }

	    if (f_zero_p(nth))
		nth = m_nth(dat);
	    else
		nth = f_add(m_nth(dat), nth);

	    if (!df && f_zero_p(sf) && !m_of(dat))
		return d_simple_new_internal(rb_obj_class(self),
					     nth, jd,
					     m_sg(dat),
					     0, 0, 0,
					     (dat->s.flags | HAVE_JD) &
					     ~(HAVE_CIVIL | HAVE_TIME |
					       COMPLEX_DAT));
	    else
		return d_complex_new_internal(rb_obj_class(self),
					      nth, jd,
					      df, sf,
					      m_of(dat), m_sg(dat),
					      0, 0, 0,
					      0, 0, 0,
					      (dat->c.flags |
					       HAVE_JD | HAVE_DF) &
					      ~(HAVE_CIVIL | HAVE_TIME));
	}
	break;
    }
}

static VALUE
minus_dd(VALUE self, VALUE other)
{
    get_d2(self, other);

    {
	int d, df;
	VALUE n, sf, r;

	n = f_sub(m_nth(adat), m_nth(bdat));
	d = m_jd(adat) - m_jd(bdat);
	df = m_df(adat) - m_df(bdat);
	sf = f_sub(m_sf(adat), m_sf(bdat));
	canonicalize_jd(n, d);

	if (df < 0) {
	    d -= 1;
	    df += DAY_IN_SECONDS;
	}
	else if (df >= DAY_IN_SECONDS) {
	    d += 1;
	    df -= DAY_IN_SECONDS;
	}

	if (f_lt_p(sf, INT2FIX(0))) {
	    df -= 1;
	    sf = f_add(sf, INT2FIX(SECOND_IN_NANOSECONDS));
	}
	else if (f_ge_p(sf, INT2FIX(SECOND_IN_NANOSECONDS))) {
	    df += 1;
	    sf = f_sub(sf, INT2FIX(SECOND_IN_NANOSECONDS));
	}

	if (f_zero_p(n))
	    r = INT2FIX(0);
	else
	    r = f_mul(n, INT2FIX(CM_PERIOD));

	if (d)
	    r = f_add(r, rb_rational_new1(INT2FIX(d)));
	if (df)
	    r = f_add(r, isec_to_day(df));
	if (f_nonzero_p(sf))
	    r = f_add(r, ns_to_day(sf));

	if (RB_TYPE_P(r, T_RATIONAL))
	    return r;
	return rb_rational_new1(r);
    }
}

/*
 * call-seq:
 *    d - other  ->  date or rational
 *
 * If the other is a date object, returns a Rational
 * whose value is the difference between the two dates in days.
 * If the other is a numeric value, returns a date object
 * pointing +other+ days before self.
 * If the other is a fractional number,
 * assumes its precision is at most nanosecond.
 *
 *     Date.new(2001,2,3) - 1	#=> #<Date: 2001-02-02 ...>
 *     DateTime.new(2001,2,3) - Rational(1,2)
 *				#=> #<DateTime: 2001-02-02T12:00:00+00:00 ...>
 *     Date.new(2001,2,3) - Date.new(2001)
 *				#=> (33/1)
 *     DateTime.new(2001,2,3) - DateTime.new(2001,2,2,12)
 *				#=> (1/2)
 */
static VALUE
d_lite_minus(VALUE self, VALUE other)
{
    if (k_date_p(other))
	return minus_dd(self, other);

    switch (TYPE(other)) {
      case T_FIXNUM:
	return d_lite_plus(self, LONG2NUM(-FIX2LONG(other)));
      case T_FLOAT:
	return d_lite_plus(self, DBL2NUM(-RFLOAT_VALUE(other)));
      default:
	expect_numeric(other);
	/* fall through */
      case T_BIGNUM:
      case T_RATIONAL:
	return d_lite_plus(self, f_negate(other));
    }
}

/*
 * call-seq:
 *   next_day(n = 1) -> new_date
 *
 * Equivalent to Date#+ with argument +n+.
 */
static VALUE
d_lite_next_day(int argc, VALUE *argv, VALUE self)
{
    VALUE n;

    rb_scan_args(argc, argv, "01", &n);
    if (argc < 1)
	n = INT2FIX(1);
    return d_lite_plus(self, n);
}

/*
 * call-seq:
 *   prev_day(n = 1) -> new_date
 *
 * Equivalent to Date#- with argument +n+.
 */
static VALUE
d_lite_prev_day(int argc, VALUE *argv, VALUE self)
{
    VALUE n;

    rb_scan_args(argc, argv, "01", &n);
    if (argc < 1)
	n = INT2FIX(1);
    return d_lite_minus(self, n);
}

/*
 * call-seq:
 *   d.next -> new_date
 *
 * Returns a new \Date object representing the following day:
 *
 *   d = Date.new(2001, 2, 3)
 *   d.to_s      # => "2001-02-03"
 *   d.next.to_s # => "2001-02-04"
 *
 */
static VALUE
d_lite_next(VALUE self)
{
    return d_lite_next_day(0, (VALUE *)NULL, self);
}

/*
 * call-seq:
 *   d >> n -> new_date
 *
 * Returns a new \Date object representing the date
 * +n+ months later; +n+ should be a numeric:
 *
 *   (Date.new(2001, 2, 3) >> 1).to_s  # => "2001-03-03"
 *   (Date.new(2001, 2, 3) >> -2).to_s # => "2000-12-03"
 *
 * When the same day does not exist for the new month,
 * the last day of that month is used instead:
 *
 *   (Date.new(2001, 1, 31) >> 1).to_s  # => "2001-02-28"
 *   (Date.new(2001, 1, 31) >> -4).to_s # => "2000-09-30"
 *
 * This results in the following, possibly unexpected, behaviors:
 *
 *   d0 = Date.new(2001, 1, 31)
 *   d1 = d0 >> 1 # => #<Date: 2001-02-28>
 *   d2 = d1 >> 1 # => #<Date: 2001-03-28>
 *
 *   d0 = Date.new(2001, 1, 31)
 *   d1 = d0 >> 1  # => #<Date: 2001-02-28>
 *   d2 = d1 >> -1 # => #<Date: 2001-01-28>
 *
 */
static VALUE
d_lite_rshift(VALUE self, VALUE other)
{
    VALUE t, y, nth, rjd2;
    int m, d, rjd;
    double sg;

    get_d1(self);
    t = f_add3(f_mul(m_real_year(dat), INT2FIX(12)),
	       INT2FIX(m_mon(dat) - 1),
	       other);
    if (FIXNUM_P(t)) {
	long it = FIX2LONG(t);
	y = LONG2NUM(DIV(it, 12));
	it = MOD(it, 12);
	m = (int)it + 1;
    }
    else {
	y = f_idiv(t, INT2FIX(12));
	t = f_mod(t, INT2FIX(12));
	m = FIX2INT(t) + 1;
    }
    d = m_mday(dat);
    sg = m_sg(dat);

    while (1) {
	int ry, rm, rd, ns;

	if (valid_civil_p(y, m, d, sg,
			  &nth, &ry,
			  &rm, &rd, &rjd, &ns))
	    break;
	if (--d < 1)
	    rb_raise(eDateError, "invalid date");
    }
    encode_jd(nth, rjd, &rjd2);
    return d_lite_plus(self, f_sub(rjd2, m_real_local_jd(dat)));
}

/*
 * call-seq:
 *    d << n  ->  date
 *
 * Returns a new \Date object representing the date
 * +n+ months earlier; +n+ should be a numeric:
 *
 *   (Date.new(2001, 2, 3) << 1).to_s  # => "2001-01-03"
 *   (Date.new(2001, 2, 3) << -2).to_s # => "2001-04-03"
 *
 * When the same day does not exist for the new month,
 * the last day of that month is used instead:
 *
 *   (Date.new(2001, 3, 31) << 1).to_s  # => "2001-02-28"
 *   (Date.new(2001, 3, 31) << -6).to_s # => "2001-09-30"
 *
 * This results in the following, possibly unexpected, behaviors:
 *
 *   d0 = Date.new(2001, 3, 31)
 *   d0 << 2      # => #<Date: 2001-01-31>
 *   d0 << 1 << 1 # => #<Date: 2001-01-28>
 *
 *   d0 = Date.new(2001, 3, 31)
 *   d1 = d0 << 1  # => #<Date: 2001-02-28>
 *   d2 = d1 << -1 # => #<Date: 2001-03-28>
 *
 */
static VALUE
d_lite_lshift(VALUE self, VALUE other)
{
    expect_numeric(other);
    return d_lite_rshift(self, f_negate(other));
}

/*
 * call-seq:
 *   next_month(n = 1) -> new_date
 *
 * Equivalent to #>> with argument +n+.
 */
static VALUE
d_lite_next_month(int argc, VALUE *argv, VALUE self)
{
    VALUE n;

    rb_scan_args(argc, argv, "01", &n);
    if (argc < 1)
	n = INT2FIX(1);
    return d_lite_rshift(self, n);
}

/*
 * call-seq:
 *   prev_month(n = 1) -> new_date
 *
 * Equivalent to #<< with argument +n+.
 */
static VALUE
d_lite_prev_month(int argc, VALUE *argv, VALUE self)
{
    VALUE n;

    rb_scan_args(argc, argv, "01", &n);
    if (argc < 1)
	n = INT2FIX(1);
    return d_lite_lshift(self, n);
}

/*
 * call-seq:
 *   next_year(n = 1) -> new_date
 *
 * Equivalent to #>> with argument <tt>n * 12</tt>.
 */
static VALUE
d_lite_next_year(int argc, VALUE *argv, VALUE self)
{
    VALUE n;

    rb_scan_args(argc, argv, "01", &n);
    if (argc < 1)
	n = INT2FIX(1);
    return d_lite_rshift(self, f_mul(n, INT2FIX(12)));
}

/*
 * call-seq:
 *   prev_year(n = 1) -> new_date
 *
 * Equivalent to #<< with argument <tt>n * 12</tt>.
 */
static VALUE
d_lite_prev_year(int argc, VALUE *argv, VALUE self)
{
    VALUE n;

    rb_scan_args(argc, argv, "01", &n);
    if (argc < 1)
	n = INT2FIX(1);
    return d_lite_lshift(self, f_mul(n, INT2FIX(12)));
}

static VALUE d_lite_cmp(VALUE, VALUE);

/*
 * call-seq:
 *   step(limit, step = 1){|date| ... } -> self
 *
 * Calls the block with specified dates;
 * returns +self+.
 *
 * - The first +date+ is +self+.
 * - Each successive +date+ is <tt>date + step</tt>,
 *   where +step+ is the numeric step size in days.
 * - The last date is the last one that is before or equal to +limit+,
 *   which should be a \Date object.
 *
 * Example:
 *
 *   limit = Date.new(2001, 12, 31)
 *   Date.new(2001).step(limit){|date| p date.to_s if date.mday == 31 }
 *
 * Output:
 *
 *   "2001-01-31"
 *   "2001-03-31"
 *   "2001-05-31"
 *   "2001-07-31"
 *   "2001-08-31"
 *   "2001-10-31"
 *   "2001-12-31"
 *
 * Returns an Enumerator if no block is given.
 */
static VALUE
d_lite_step(int argc, VALUE *argv, VALUE self)
{
    VALUE limit, step, date;
    int c;

    rb_scan_args(argc, argv, "11", &limit, &step);

    if (argc < 2)
	step = INT2FIX(1);

#if 0
    if (f_zero_p(step))
	rb_raise(rb_eArgError, "step can't be 0");
#endif

    RETURN_ENUMERATOR(self, argc, argv);

    date = self;
    c = f_cmp(step, INT2FIX(0));
    if (c < 0) {
	while (FIX2INT(d_lite_cmp(date, limit)) >= 0) {
	    rb_yield(date);
	    date = d_lite_plus(date, step);
	}
    }
    else if (c == 0) {
	while (1)
	    rb_yield(date);
    }
    else /* if (c > 0) */ {
	while (FIX2INT(d_lite_cmp(date, limit)) <= 0) {
	    rb_yield(date);
	    date = d_lite_plus(date, step);
	}
    }
    return self;
}

/*
 * call-seq:
 *   upto(max){|date| ... } -> self
 *
 * Equivalent to #step with arguments +max+ and +1+.
 */
static VALUE
d_lite_upto(VALUE self, VALUE max)
{
    VALUE date;

    RETURN_ENUMERATOR(self, 1, &max);

    date = self;
    while (FIX2INT(d_lite_cmp(date, max)) <= 0) {
	rb_yield(date);
	date = d_lite_plus(date, INT2FIX(1));
    }
    return self;
}

/*
 * call-seq:
 *   downto(min){|date| ... } -> self
 *
 * Equivalent to #step with arguments +min+ and <tt>-1</tt>.
 */
static VALUE
d_lite_downto(VALUE self, VALUE min)
{
    VALUE date;

    RETURN_ENUMERATOR(self, 1, &min);

    date = self;
    while (FIX2INT(d_lite_cmp(date, min)) >= 0) {
	rb_yield(date);
	date = d_lite_plus(date, INT2FIX(-1));
    }
    return self;
}

static VALUE
cmp_gen(VALUE self, VALUE other)
{
    get_d1(self);

    if (k_numeric_p(other))
	return INT2FIX(f_cmp(m_ajd(dat), other));
    else if (k_date_p(other))
	return INT2FIX(f_cmp(m_ajd(dat), f_ajd(other)));
    return rb_num_coerce_cmp(self, other, id_cmp);
}

static VALUE
cmp_dd(VALUE self, VALUE other)
{
    get_d2(self, other);

    {
	VALUE a_nth, b_nth,
	    a_sf, b_sf;
	int a_jd, b_jd,
	    a_df, b_df;

	m_canonicalize_jd(self, adat);
	m_canonicalize_jd(other, bdat);
	a_nth = m_nth(adat);
	b_nth = m_nth(bdat);
	if (f_eqeq_p(a_nth, b_nth)) {
	    a_jd = m_jd(adat);
	    b_jd = m_jd(bdat);
	    if (a_jd == b_jd) {
		a_df = m_df(adat);
		b_df = m_df(bdat);
		if (a_df == b_df) {
		    a_sf = m_sf(adat);
		    b_sf = m_sf(bdat);
		    if (f_eqeq_p(a_sf, b_sf)) {
			return INT2FIX(0);
		    }
		    else if (f_lt_p(a_sf, b_sf)) {
			return INT2FIX(-1);
		    }
		    else {
			return INT2FIX(1);
		    }
		}
		else if (a_df < b_df) {
		    return INT2FIX(-1);
		}
		else {
		    return INT2FIX(1);
		}
	    }
	    else if (a_jd < b_jd) {
		return INT2FIX(-1);
	    }
	    else {
		return INT2FIX(1);
	    }
	}
	else if (f_lt_p(a_nth, b_nth)) {
	    return INT2FIX(-1);
	}
	else {
	    return INT2FIX(1);
	}
    }
}

/*
 * call-seq:
 *   self <=> other  -> -1, 0, 1 or nil
 *
 * Compares +self+ and +other+, returning:
 *
 * - <tt>-1</tt> if +other+ is larger.
 * - <tt>0</tt> if the two are equal.
 * - <tt>1</tt> if +other+ is smaller.
 * - +nil+ if the two are incomparable.
 *
 * Argument +other+ may be:
 *
 * - Another \Date object:
 *
 *     d = Date.new(2022, 7, 27) # => #<Date: 2022-07-27 ((2459788j,0s,0n),+0s,2299161j)>
 *     prev_date = d.prev_day    # => #<Date: 2022-07-26 ((2459787j,0s,0n),+0s,2299161j)>
 *     next_date = d.next_day    # => #<Date: 2022-07-28 ((2459789j,0s,0n),+0s,2299161j)>
 *     d <=> next_date           # => -1
 *     d <=> d                   # => 0
 *     d <=> prev_date           # => 1
 *
 * - A DateTime object:
 *
 *     d <=> DateTime.new(2022, 7, 26) # => 1
 *     d <=> DateTime.new(2022, 7, 27) # => 0
 *     d <=> DateTime.new(2022, 7, 28) # => -1
 *
 * - A numeric (compares <tt>self.ajd</tt> to +other+):
 *
 *     d <=> 2459788 # => -1
 *     d <=> 2459787 # => 1
 *     d <=> 2459786 # => 1
 *     d <=> d.ajd   # => 0
 *
 * - Any other object:
 *
 *     d <=> Object.new # => nil
 *
 */
static VALUE
d_lite_cmp(VALUE self, VALUE other)
{
    if (!k_date_p(other))
	return cmp_gen(self, other);

    {
	get_d2(self, other);

	if (!(simple_dat_p(adat) && simple_dat_p(bdat) &&
	      m_gregorian_p(adat) == m_gregorian_p(bdat)))
	    return cmp_dd(self, other);

	{
	    VALUE a_nth, b_nth;
	    int a_jd, b_jd;

	    m_canonicalize_jd(self, adat);
	    m_canonicalize_jd(other, bdat);
	    a_nth = m_nth(adat);
	    b_nth = m_nth(bdat);
	    if (f_eqeq_p(a_nth, b_nth)) {
		a_jd = m_jd(adat);
		b_jd = m_jd(bdat);
		if (a_jd == b_jd) {
		    return INT2FIX(0);
		}
		else if (a_jd < b_jd) {
		    return INT2FIX(-1);
		}
		else {
		    return INT2FIX(1);
		}
	    }
	    else if (f_lt_p(a_nth, b_nth)) {
		return INT2FIX(-1);
	    }
	    else {
		return INT2FIX(1);
	    }
	}
    }
}

static VALUE
equal_gen(VALUE self, VALUE other)
{
    get_d1(self);

    if (k_numeric_p(other))
	return f_eqeq_p(m_real_local_jd(dat), other);
    else if (k_date_p(other))
	return f_eqeq_p(m_real_local_jd(dat), f_jd(other));
    return rb_num_coerce_cmp(self, other, id_eqeq_p);
}

/*
 * call-seq:
 *   self === other -> true, false, or nil.
 *
 * Returns +true+ if +self+ and +other+ represent the same date,
 * +false+ if not, +nil+ if the two are not comparable.
 *
 * Argument +other+ may be:
 *
 * - Another \Date object:
 *
 *     d = Date.new(2022, 7, 27) # => #<Date: 2022-07-27 ((2459788j,0s,0n),+0s,2299161j)>
 *     prev_date = d.prev_day    # => #<Date: 2022-07-26 ((2459787j,0s,0n),+0s,2299161j)>
 *     next_date = d.next_day    # => #<Date: 2022-07-28 ((2459789j,0s,0n),+0s,2299161j)>
 *     d === prev_date           # => false
 *     d === d                   # => true
 *     d === next_date           # => false
 *
 * - A DateTime object:
 *
 *     d === DateTime.new(2022, 7, 26) # => false
 *     d === DateTime.new(2022, 7, 27) # => true
 *     d === DateTime.new(2022, 7, 28) # => false
 *
 * - A numeric (compares <tt>self.jd</tt> to +other+):
 *
 *     d === 2459788 # => true
 *     d === 2459787 # => false
 *     d === 2459786 # => false
 *     d === d.jd    # => true
 *
 * - An object not comparable:
 *
 *     d === Object.new # => nil
 *
 */
static VALUE
d_lite_equal(VALUE self, VALUE other)
{
    if (!k_date_p(other))
	return equal_gen(self, other);

    {
	get_d2(self, other);

	if (!(m_gregorian_p(adat) == m_gregorian_p(bdat)))
	    return equal_gen(self, other);

	{
	    VALUE a_nth, b_nth;
	    int a_jd, b_jd;

	    m_canonicalize_jd(self, adat);
	    m_canonicalize_jd(other, bdat);
	    a_nth = m_nth(adat);
	    b_nth = m_nth(bdat);
	    a_jd = m_local_jd(adat);
	    b_jd = m_local_jd(bdat);
	    if (f_eqeq_p(a_nth, b_nth) &&
		a_jd == b_jd)
		return Qtrue;
	    return Qfalse;
	}
    }
}

/* :nodoc: */
static VALUE
d_lite_eql_p(VALUE self, VALUE other)
{
    if (!k_date_p(other))
	return Qfalse;
    return f_zero_p(d_lite_cmp(self, other));
}

/* :nodoc: */
static VALUE
d_lite_hash(VALUE self)
{
    st_index_t v, h[4];

    get_d1(self);
    h[0] = m_nth(dat);
    h[1] = m_jd(dat);
    h[2] = m_df(dat);
    h[3] = m_sf(dat);
    v = rb_memhash(h, sizeof(h));
    return ST2FIX(v);
}

#include "date_tmx.h"
static void set_tmx(VALUE, struct tmx *);
static VALUE strftimev(const char *, VALUE,
		       void (*)(VALUE, struct tmx *));

/*
 * call-seq:
 *   to_s -> string
 *
 * Returns a string representation of the date in +self+
 * in {ISO 8601 extended date format}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-ISO+8601+Format+Specifications]
 * (<tt>'%Y-%m-%d'</tt>):
 *
 *   Date.new(2001, 2, 3).to_s # => "2001-02-03"
 *
 */
static VALUE
d_lite_to_s(VALUE self)
{
    return strftimev("%Y-%m-%d", self, set_tmx);
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
mk_inspect_raw(union DateData *x, VALUE klass)
{
    char flags[6];

    flags[0] = (x->flags & COMPLEX_DAT) ? 'C' : 'S';
    flags[1] = (x->flags & HAVE_JD)     ? 'j' : '-';
    flags[2] = (x->flags & HAVE_DF)     ? 'd' : '-';
    flags[3] = (x->flags & HAVE_CIVIL)  ? 'c' : '-';
    flags[4] = (x->flags & HAVE_TIME)   ? 't' : '-';
    flags[5] = '\0';

    if (simple_dat_p(x)) {
	return rb_enc_sprintf(rb_usascii_encoding(),
			      "#<%"PRIsVALUE": "
			      "(%+"PRIsVALUE"th,%dj),+0s,%.0fj; "
			      "%dy%dm%dd; %s>",
			      klass,
			      x->s.nth, x->s.jd, x->s.sg,
#ifndef USE_PACK
			      x->s.year, x->s.mon, x->s.mday,
#else
			      x->s.year,
			      EX_MON(x->s.pc), EX_MDAY(x->s.pc),
#endif
			      flags);
    }
    else {
	return rb_enc_sprintf(rb_usascii_encoding(),
			      "#<%"PRIsVALUE": "
			      "(%+"PRIsVALUE"th,%dj,%ds,%+"PRIsVALUE"n),"
			      "%+ds,%.0fj; "
			      "%dy%dm%dd %dh%dm%ds; %s>",
			      klass,
			      x->c.nth, x->c.jd, x->c.df, x->c.sf,
			      x->c.of, x->c.sg,
#ifndef USE_PACK
			      x->c.year, x->c.mon, x->c.mday,
			      x->c.hour, x->c.min, x->c.sec,
#else
			      x->c.year,
			      EX_MON(x->c.pc), EX_MDAY(x->c.pc),
			      EX_HOUR(x->c.pc), EX_MIN(x->c.pc),
			      EX_SEC(x->c.pc),
#endif
			      flags);
    }
}

/* :nodoc: */
static VALUE
d_lite_inspect_raw(VALUE self)
{
    get_d1(self);
    return mk_inspect_raw(dat, rb_obj_class(self));
}
#endif

static VALUE
mk_inspect(union DateData *x, VALUE klass, VALUE to_s)
{
    return rb_enc_sprintf(rb_usascii_encoding(),
			  "#<%"PRIsVALUE": %"PRIsVALUE" "
			  "((%+"PRIsVALUE"j,%ds,%+"PRIsVALUE"n),%+ds,%.0fj)>",
			  klass, to_s,
			  m_real_jd(x), m_df(x), m_sf(x),
			  m_of(x), m_sg(x));
}

/*
 * call-seq:
 *   inspect -> string
 *
 * Returns a string representation of +self+:
 *
 *   Date.new(2001, 2, 3).inspect
 *   # => "#<Date: 2001-02-03 ((2451944j,0s,0n),+0s,2299161j)>"
 *
 */
static VALUE
d_lite_inspect(VALUE self)
{
    get_d1(self);
    return mk_inspect(dat, rb_obj_class(self), self);
}

#include <errno.h>
#include "date_tmx.h"

size_t date_strftime(char *s, size_t maxsize, const char *format,
		     const struct tmx *tmx);

#define SMALLBUF 100
static size_t
date_strftime_alloc(char **buf, const char *format,
		    struct tmx *tmx)
{
    size_t size, len, flen;

    (*buf)[0] = '\0';
    flen = strlen(format);
    if (flen == 0) {
	return 0;
    }
    errno = 0;
    len = date_strftime(*buf, SMALLBUF, format, tmx);
    if (len != 0 || (**buf == '\0' && errno != ERANGE)) return len;
    for (size=1024; ; size*=2) {
	*buf = xmalloc(size);
	(*buf)[0] = '\0';
	len = date_strftime(*buf, size, format, tmx);
	/*
	 * buflen can be zero EITHER because there's not enough
	 * room in the string, or because the control command
	 * goes to the empty string. Make a reasonable guess that
	 * if the buffer is 1024 times bigger than the length of the
	 * format string, it's not failing for lack of room.
	 */
	if (len > 0) break;
	xfree(*buf);
	if (size >= 1024 * flen) {
	    rb_sys_fail(format);
	    break;
	}
    }
    return len;
}

static VALUE
tmx_m_secs(union DateData *x)
{
    VALUE s;
    int df;

    s = day_to_sec(f_sub(m_real_jd(x),
			 UNIX_EPOCH_IN_CJD));
    if (simple_dat_p(x))
	return s;
    df = m_df(x);
    if (df)
	s = f_add(s, INT2FIX(df));
    return s;
}

#define MILLISECOND_IN_NANOSECONDS 1000000

static VALUE
tmx_m_msecs(union DateData *x)
{
    VALUE s, sf;

    s = sec_to_ms(tmx_m_secs(x));
    if (simple_dat_p(x))
	return s;
    sf = m_sf(x);
    if (f_nonzero_p(sf))
	s = f_add(s, f_div(sf, INT2FIX(MILLISECOND_IN_NANOSECONDS)));
    return s;
}

static int
tmx_m_of(union DateData *x)
{
    return m_of(x);
}

static char *
tmx_m_zone(union DateData *x)
{
    VALUE zone = m_zone(x);
    /* TODO: fix potential dangling pointer */
    return RSTRING_PTR(zone);
}

static const struct tmx_funcs tmx_funcs = {
    (VALUE (*)(void *))m_real_year,
    (int (*)(void *))m_yday,
    (int (*)(void *))m_mon,
    (int (*)(void *))m_mday,
    (VALUE (*)(void *))m_real_cwyear,
    (int (*)(void *))m_cweek,
    (int (*)(void *))m_cwday,
    (int (*)(void *))m_wnum0,
    (int (*)(void *))m_wnum1,
    (int (*)(void *))m_wday,
    (int (*)(void *))m_hour,
    (int (*)(void *))m_min,
    (int (*)(void *))m_sec,
    (VALUE (*)(void *))m_sf_in_sec,
    (VALUE (*)(void *))tmx_m_secs,
    (VALUE (*)(void *))tmx_m_msecs,
    (int (*)(void *))tmx_m_of,
    (char *(*)(void *))tmx_m_zone
};

static void
set_tmx(VALUE self, struct tmx *tmx)
{
    get_d1(self);
    tmx->dat = (void *)dat;
    tmx->funcs = &tmx_funcs;
}

static VALUE
date_strftime_internal(int argc, VALUE *argv, VALUE self,
		       const char *default_fmt,
		       void (*func)(VALUE, struct tmx *))
{
    VALUE vfmt;
    const char *fmt;
    long len;
    char buffer[SMALLBUF], *buf = buffer;
    struct tmx tmx;
    VALUE str;

    rb_scan_args(argc, argv, "01", &vfmt);

    if (argc < 1)
	vfmt = rb_usascii_str_new2(default_fmt);
    else {
	StringValue(vfmt);
	if (!rb_enc_str_asciicompat_p(vfmt)) {
	    rb_raise(rb_eArgError,
		     "format should have ASCII compatible encoding");
	}
    }
    fmt = RSTRING_PTR(vfmt);
    len = RSTRING_LEN(vfmt);
    (*func)(self, &tmx);
    if (memchr(fmt, '\0', len)) {
	/* Ruby string may contain \0's. */
	const char *p = fmt, *pe = fmt + len;

	str = rb_str_new(0, 0);
	while (p < pe) {
	    len = date_strftime_alloc(&buf, p, &tmx);
	    rb_str_cat(str, buf, len);
	    p += strlen(p);
	    if (buf != buffer) {
		xfree(buf);
		buf = buffer;
	    }
	    for (fmt = p; p < pe && !*p; ++p);
	    if (p > fmt) rb_str_cat(str, fmt, p - fmt);
	}
	rb_enc_copy(str, vfmt);
	return str;
    }
    else
	len = date_strftime_alloc(&buf, fmt, &tmx);

    str = rb_str_new(buf, len);
    if (buf != buffer) xfree(buf);
    rb_enc_copy(str, vfmt);
    return str;
}

/*
 * call-seq:
 *   strftime(format = '%F') -> string
 *
 * Returns a string representation of the date in +self+,
 * formatted according the given +format+:
 *
 *   Date.new(2001, 2, 3).strftime # => "2001-02-03"
 *
 * For other formats, see
 * {Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html].
 *
 */
static VALUE
d_lite_strftime(int argc, VALUE *argv, VALUE self)
{
    return date_strftime_internal(argc, argv, self,
				  "%Y-%m-%d", set_tmx);
}

static VALUE
strftimev(const char *fmt, VALUE self,
	  void (*func)(VALUE, struct tmx *))
{
    char buffer[SMALLBUF], *buf = buffer;
    struct tmx tmx;
    long len;
    VALUE str;

    (*func)(self, &tmx);
    len = date_strftime_alloc(&buf, fmt, &tmx);
    RB_GC_GUARD(self);
    str = rb_usascii_str_new(buf, len);
    if (buf != buffer) xfree(buf);
    return str;
}

/*
 * call-seq:
 *   asctime -> string
 *
 * Equivalent to #strftime with argument <tt>'%a %b %e %T %Y'</tt>
 * (or its {shorthand form}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-Shorthand+Conversion+Specifiers]
 * <tt>'%c'</tt>):
 *
 *   Date.new(2001, 2, 3).asctime # => "Sat Feb  3 00:00:00 2001"
 *
 * See {asctime}[https://linux.die.net/man/3/asctime].
 *
 */
static VALUE
d_lite_asctime(VALUE self)
{
    return strftimev("%a %b %e %H:%M:%S %Y", self, set_tmx);
}

/*
 * call-seq:
 *   iso8601    ->  string
 *
 * Equivalent to #strftime with argument <tt>'%Y-%m-%d'</tt>
 * (or its {shorthand form}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-Shorthand+Conversion+Specifiers]
 * <tt>'%F'</tt>);
 *
 *   Date.new(2001, 2, 3).iso8601 # => "2001-02-03"
 *
 */
static VALUE
d_lite_iso8601(VALUE self)
{
    return strftimev("%Y-%m-%d", self, set_tmx);
}

/*
 * call-seq:
 *   rfc3339 -> string
 *
 * Equivalent to #strftime with argument <tt>'%FT%T%:z'</tt>;
 * see {Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html]:
 *
 *   Date.new(2001, 2, 3).rfc3339 # => "2001-02-03T00:00:00+00:00"
 *
 */
static VALUE
d_lite_rfc3339(VALUE self)
{
    return strftimev("%Y-%m-%dT%H:%M:%S%:z", self, set_tmx);
}

/*
 * call-seq:
 *   rfc2822 -> string
 *
 * Equivalent to #strftime with argument <tt>'%a, %-d %b %Y %T %z'</tt>;
 * see {Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html]:
 *
 *   Date.new(2001, 2, 3).rfc2822 # => "Sat, 3 Feb 2001 00:00:00 +0000"
 *
 */
static VALUE
d_lite_rfc2822(VALUE self)
{
    return strftimev("%a, %-d %b %Y %T %z", self, set_tmx);
}

/*
 * call-seq:
 *   httpdate -> string
 *
 * Equivalent to #strftime with argument <tt>'%a, %d %b %Y %T GMT'</tt>;
 * see {Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html]:
 *
 *   Date.new(2001, 2, 3).httpdate # => "Sat, 03 Feb 2001 00:00:00 GMT"
 *
 */
static VALUE
d_lite_httpdate(VALUE self)
{
    volatile VALUE dup = dup_obj_with_new_offset(self, 0);
    return strftimev("%a, %d %b %Y %T GMT", dup, set_tmx);
}

enum {
    DECIMAL_SIZE_OF_LONG = DECIMAL_SIZE_OF_BITS(CHAR_BIT*sizeof(long)),
    JISX0301_DATE_SIZE = DECIMAL_SIZE_OF_LONG+8
};

static const char *
jisx0301_date_format(char *fmt, size_t size, VALUE jd, VALUE y)
{
    if (FIXNUM_P(jd)) {
	long d = FIX2INT(jd);
	long s;
	char c;
	if (d < 2405160)
	    return "%Y-%m-%d";
	if (d < 2419614) {
	    c = 'M';
	    s = 1867;
	}
	else if (d < 2424875) {
	    c = 'T';
	    s = 1911;
	}
	else if (d < 2447535) {
	    c = 'S';
	    s = 1925;
	}
	else if (d < 2458605) {
	    c = 'H';
	    s = 1988;
	}
	else {
	    c = 'R';
	    s = 2018;
	}
	snprintf(fmt, size, "%c%02ld" ".%%m.%%d", c, FIX2INT(y) - s);
	return fmt;
    }
    return "%Y-%m-%d";
}

/*
 * call-seq:
 *   jisx0301 -> string
 *
 * Returns a string representation of the date in +self+
 * in JIS X 0301 format.
 *
 *   Date.new(2001, 2, 3).jisx0301 # => "H13.02.03"
 *
 */
static VALUE
d_lite_jisx0301(VALUE self)
{
    char fmtbuf[JISX0301_DATE_SIZE];
    const char *fmt;

    get_d1(self);
    fmt = jisx0301_date_format(fmtbuf, sizeof(fmtbuf),
			       m_real_local_jd(dat),
			       m_real_year(dat));
    return strftimev(fmt, self, set_tmx);
}

static VALUE
deconstruct_keys(VALUE self, VALUE keys, int is_datetime)
{
    VALUE h = rb_hash_new();
    long i;

    get_d1(self);

    if (NIL_P(keys)) {
        rb_hash_aset(h, sym_year, m_real_year(dat));
        rb_hash_aset(h, sym_month, INT2FIX(m_mon(dat)));
        rb_hash_aset(h, sym_day, INT2FIX(m_mday(dat)));
        rb_hash_aset(h, sym_yday, INT2FIX(m_yday(dat)));
        rb_hash_aset(h, sym_wday, INT2FIX(m_wday(dat)));
        if (is_datetime) {
            rb_hash_aset(h, sym_hour, INT2FIX(m_hour(dat)));
            rb_hash_aset(h, sym_min, INT2FIX(m_min(dat)));
            rb_hash_aset(h, sym_sec, INT2FIX(m_sec(dat)));
            rb_hash_aset(h, sym_sec_fraction, m_sf_in_sec(dat));
            rb_hash_aset(h, sym_zone, m_zone(dat));
        }

        return h;
    }
    if (!RB_TYPE_P(keys, T_ARRAY)) {
        rb_raise(rb_eTypeError,
                 "wrong argument type %"PRIsVALUE" (expected Array or nil)",
                 rb_obj_class(keys));

    }

    for (i=0; i<RARRAY_LEN(keys); i++) {
        VALUE key = RARRAY_AREF(keys, i);

        if (sym_year == key) rb_hash_aset(h, key, m_real_year(dat));
        if (sym_month == key) rb_hash_aset(h, key, INT2FIX(m_mon(dat)));
        if (sym_day == key) rb_hash_aset(h, key, INT2FIX(m_mday(dat)));
        if (sym_yday == key) rb_hash_aset(h, key, INT2FIX(m_yday(dat)));
        if (sym_wday == key) rb_hash_aset(h, key, INT2FIX(m_wday(dat)));
        if (is_datetime) {
            if (sym_hour == key) rb_hash_aset(h, key, INT2FIX(m_hour(dat)));
            if (sym_min == key) rb_hash_aset(h, key, INT2FIX(m_min(dat)));
            if (sym_sec == key) rb_hash_aset(h, key, INT2FIX(m_sec(dat)));
            if (sym_sec_fraction == key) rb_hash_aset(h, key, m_sf_in_sec(dat));
            if (sym_zone == key) rb_hash_aset(h, key, m_zone(dat));
        }
    }
    return h;
}

/*
 *  call-seq:
 *    deconstruct_keys(array_of_names_or_nil) -> hash
 *
 *  Returns a hash of the name/value pairs, to use in pattern matching.
 *  Possible keys are: <tt>:year</tt>, <tt>:month</tt>, <tt>:day</tt>,
 *  <tt>:wday</tt>, <tt>:yday</tt>.
 *
 *  Possible usages:
 *
 *    d = Date.new(2022, 10, 5)
 *
 *    if d in wday: 3, day: ..7  # uses deconstruct_keys underneath
 *      puts "first Wednesday of the month"
 *    end
 *    #=> prints "first Wednesday of the month"
 *
 *    case d
 *    in year: ...2022
 *      puts "too old"
 *    in month: ..9
 *      puts "quarter 1-3"
 *    in wday: 1..5, month:
 *      puts "working day in month #{month}"
 *    end
 *    #=> prints "working day in month 10"
 *
 *  Note that deconstruction by pattern can also be combined with class check:
 *
 *    if d in Date(wday: 3, day: ..7)
 *      puts "first Wednesday of the month"
 *    end
 *
 */
static VALUE
d_lite_deconstruct_keys(VALUE self, VALUE keys)
{
    return deconstruct_keys(self, keys, /* is_datetime=false */ 0);
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
d_lite_marshal_dump_old(VALUE self)
{
    VALUE a;

    get_d1(self);

    a = rb_ary_new3(3,
		    m_ajd(dat),
		    m_of_in_day(dat),
		    DBL2NUM(m_sg(dat)));

    if (FL_TEST(self, FL_EXIVAR)) {
	rb_copy_generic_ivar(a, self);
	FL_SET(a, FL_EXIVAR);
    }

    return a;
}
#endif

/* :nodoc: */
static VALUE
d_lite_marshal_dump(VALUE self)
{
    VALUE a;

    get_d1(self);

    a = rb_ary_new3(6,
		    m_nth(dat),
		    INT2FIX(m_jd(dat)),
		    INT2FIX(m_df(dat)),
		    m_sf(dat),
		    INT2FIX(m_of(dat)),
		    DBL2NUM(m_sg(dat)));

    if (FL_TEST(self, FL_EXIVAR)) {
	rb_copy_generic_ivar(a, self);
	FL_SET(a, FL_EXIVAR);
    }

    return a;
}

/* :nodoc: */
static VALUE
d_lite_marshal_load(VALUE self, VALUE a)
{
    VALUE nth, sf;
    int jd, df, of;
    double sg;

    get_d1(self);

    rb_check_frozen(self);

    if (!RB_TYPE_P(a, T_ARRAY))
	rb_raise(rb_eTypeError, "expected an array");

    switch (RARRAY_LEN(a)) {
      case 2: /* 1.6.x */
      case 3: /* 1.8.x, 1.9.2 */
	{
	    VALUE ajd, vof, vsg;

	    if  (RARRAY_LEN(a) == 2) {
		ajd = f_sub(RARRAY_AREF(a, 0), half_days_in_day);
		vof = INT2FIX(0);
		vsg = RARRAY_AREF(a, 1);
		if (!k_numeric_p(vsg))
		    vsg = DBL2NUM(RTEST(vsg) ? GREGORIAN : JULIAN);
	    }
	    else {
		ajd = RARRAY_AREF(a, 0);
		vof = RARRAY_AREF(a, 1);
		vsg = RARRAY_AREF(a, 2);
	    }

	    old_to_new(ajd, vof, vsg,
		       &nth, &jd, &df, &sf, &of, &sg);
	}
	break;
      case 6:
	{
	    nth = RARRAY_AREF(a, 0);
	    jd = NUM2INT(RARRAY_AREF(a, 1));
	    df = NUM2INT(RARRAY_AREF(a, 2));
	    sf = RARRAY_AREF(a, 3);
	    of = NUM2INT(RARRAY_AREF(a, 4));
	    sg = NUM2DBL(RARRAY_AREF(a, 5));
	}
	break;
      default:
	rb_raise(rb_eTypeError, "invalid size");
	break;
    }

    if (simple_dat_p(dat)) {
	if (df || !f_zero_p(sf) || of) {
	    /* loading a fractional date; promote to complex */
	    dat = ruby_xrealloc(dat, sizeof(struct ComplexDateData));
	    RTYPEDDATA(self)->data = dat;
	    goto complex_data;
	}
	set_to_simple(self, &dat->s, nth, jd, sg, 0, 0, 0, HAVE_JD);
    } else {
      complex_data:
	set_to_complex(self, &dat->c, nth, jd, df, sf, of, sg,
		       0, 0, 0, 0, 0, 0,
		       HAVE_JD | HAVE_DF);
    }

    if (FL_TEST(a, FL_EXIVAR)) {
	rb_copy_generic_ivar(self, a);
	FL_SET(self, FL_EXIVAR);
    }

    return self;
}

/* :nodoc: */
static VALUE
date_s__load(VALUE klass, VALUE s)
{
    VALUE a, obj;

    a = rb_marshal_load(s);
    obj = d_lite_s_alloc(klass);
    return d_lite_marshal_load(obj, a);
}

/* datetime */

/*
 * call-seq:
 *    DateTime.jd([jd=0[, hour=0[, minute=0[, second=0[, offset=0[, start=Date::ITALY]]]]]])  ->  datetime
 *
 * Creates a DateTime object denoting the given chronological Julian
 * day number.
 *
 *    DateTime.jd(2451944)	#=> #<DateTime: 2001-02-03T00:00:00+00:00 ...>
 *    DateTime.jd(2451945)	#=> #<DateTime: 2001-02-04T00:00:00+00:00 ...>
 *    DateTime.jd(Rational('0.5'))
 * 				#=> #<DateTime: -4712-01-01T12:00:00+00:00 ...>
 */
static VALUE
datetime_s_jd(int argc, VALUE *argv, VALUE klass)
{
    VALUE vjd, vh, vmin, vs, vof, vsg, jd, fr, fr2, ret;
    int h, min, s, rof;
    double sg;

    rb_scan_args(argc, argv, "06", &vjd, &vh, &vmin, &vs, &vof, &vsg);

    jd = INT2FIX(0);

    h = min = s = 0;
    fr2 = INT2FIX(0);
    rof = 0;
    sg = DEFAULT_SG;

    switch (argc) {
      case 6:
	val2sg(vsg, sg);
      case 5:
	val2off(vof, rof);
      case 4:
        check_numeric(vs, "second");
	num2int_with_frac(s, positive_inf);
      case 3:
        check_numeric(vmin, "minute");
	num2int_with_frac(min, 3);
      case 2:
        check_numeric(vh, "hour");
	num2int_with_frac(h, 2);
      case 1:
        check_numeric(vjd, "jd");
	num2num_with_frac(jd, 1);
    }

    {
	VALUE nth;
	int rh, rmin, rs, rjd, rjd2;

	if (!c_valid_time_p(h, min, s, &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");
	canon24oc();

	decode_jd(jd, &nth, &rjd);
	rjd2 = jd_local_to_utc(rjd,
			       time_to_df(rh, rmin, rs),
			       rof);

	ret = d_complex_new_internal(klass,
				     nth, rjd2,
				     0, INT2FIX(0),
				     rof, sg,
				     0, 0, 0,
				     rh, rmin, rs,
				     HAVE_JD | HAVE_TIME);
    }
    add_frac();
    return ret;
}

/*
 * call-seq:
 *    DateTime.ordinal([year=-4712[, yday=1[, hour=0[, minute=0[, second=0[, offset=0[, start=Date::ITALY]]]]]]])  ->  datetime
 *
 * Creates a DateTime object denoting the given ordinal date.
 *
 *    DateTime.ordinal(2001,34)	#=> #<DateTime: 2001-02-03T00:00:00+00:00 ...>
 *    DateTime.ordinal(2001,34,4,5,6,'+7')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.ordinal(2001,-332,-20,-55,-54,'+7')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 */
static VALUE
datetime_s_ordinal(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vd, vh, vmin, vs, vof, vsg, y, fr, fr2, ret;
    int d, h, min, s, rof;
    double sg;

    rb_scan_args(argc, argv, "07", &vy, &vd, &vh, &vmin, &vs, &vof, &vsg);

    y = INT2FIX(-4712);
    d = 1;

    h = min = s = 0;
    fr2 = INT2FIX(0);
    rof = 0;
    sg = DEFAULT_SG;

    switch (argc) {
      case 7:
	val2sg(vsg, sg);
      case 6:
	val2off(vof, rof);
      case 5:
        check_numeric(vs, "second");
	num2int_with_frac(s, positive_inf);
      case 4:
        check_numeric(vmin, "minute");
	num2int_with_frac(min, 4);
      case 3:
        check_numeric(vh, "hour");
	num2int_with_frac(h, 3);
      case 2:
        check_numeric(vd, "yday");
	num2int_with_frac(d, 2);
      case 1:
        check_numeric(vy, "year");
	y = vy;
    }

    {
	VALUE nth;
	int ry, rd, rh, rmin, rs, rjd, rjd2, ns;

	if (!valid_ordinal_p(y, d, sg,
			     &nth, &ry,
			     &rd, &rjd,
			     &ns))
	    rb_raise(eDateError, "invalid date");
	if (!c_valid_time_p(h, min, s, &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");
	canon24oc();

	rjd2 = jd_local_to_utc(rjd,
			       time_to_df(rh, rmin, rs),
			       rof);

	ret = d_complex_new_internal(klass,
				     nth, rjd2,
				     0, INT2FIX(0),
				     rof, sg,
				     0, 0, 0,
				     rh, rmin, rs,
				     HAVE_JD | HAVE_TIME);
    }
    add_frac();
    return ret;
}

/*
 * Same as DateTime.new.
 */
static VALUE
datetime_s_civil(int argc, VALUE *argv, VALUE klass)
{
    return datetime_initialize(argc, argv, d_lite_s_alloc_complex(klass));
}

static VALUE
datetime_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE vy, vm, vd, vh, vmin, vs, vof, vsg, y, fr, fr2, ret;
    int m, d, h, min, s, rof;
    double sg;
    struct ComplexDateData *dat = rb_check_typeddata(self, &d_lite_type);

    if (!complex_dat_p(dat)) {
	rb_raise(rb_eTypeError, "DateTime expected");
    }

    rb_scan_args(argc, argv, "08", &vy, &vm, &vd, &vh, &vmin, &vs, &vof, &vsg);

    y = INT2FIX(-4712);
    m = 1;
    d = 1;

    h = min = s = 0;
    fr2 = INT2FIX(0);
    rof = 0;
    sg = DEFAULT_SG;

    switch (argc) {
      case 8:
	val2sg(vsg, sg);
      case 7:
	val2off(vof, rof);
      case 6:
        check_numeric(vs, "second");
	num2int_with_frac(s, positive_inf);
      case 5:
        check_numeric(vmin, "minute");
	num2int_with_frac(min, 5);
      case 4:
        check_numeric(vh, "hour");
	num2int_with_frac(h, 4);
      case 3:
        check_numeric(vd, "day");
	num2int_with_frac(d, 3);
      case 2:
        check_numeric(vm, "month");
	m = NUM2INT(vm);
      case 1:
        check_numeric(vy, "year");
	y = vy;
    }

    if (guess_style(y, sg) < 0) {
	VALUE nth;
	int ry, rm, rd, rh, rmin, rs;

	if (!valid_gregorian_p(y, m, d,
			       &nth, &ry,
			       &rm, &rd))
	    rb_raise(eDateError, "invalid date");
	if (!c_valid_time_p(h, min, s, &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");
	canon24oc();

	set_to_complex(self, dat,
		       nth, 0,
		       0, INT2FIX(0),
		       rof, sg,
		       ry, rm, rd,
		       rh, rmin, rs,
		       HAVE_CIVIL | HAVE_TIME);
    }
    else {
	VALUE nth;
	int ry, rm, rd, rh, rmin, rs, rjd, rjd2, ns;

	if (!valid_civil_p(y, m, d, sg,
			   &nth, &ry,
			   &rm, &rd, &rjd,
			   &ns))
	    rb_raise(eDateError, "invalid date");
	if (!c_valid_time_p(h, min, s, &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");
	canon24oc();

	rjd2 = jd_local_to_utc(rjd,
			       time_to_df(rh, rmin, rs),
			       rof);

	set_to_complex(self, dat,
		       nth, rjd2,
		       0, INT2FIX(0),
		       rof, sg,
		       ry, rm, rd,
		       rh, rmin, rs,
		       HAVE_JD | HAVE_CIVIL | HAVE_TIME);
    }
    ret = self;
    add_frac();
    return ret;
}

/*
 * call-seq:
 *    DateTime.commercial([cwyear=-4712[, cweek=1[, cwday=1[, hour=0[, minute=0[, second=0[, offset=0[, start=Date::ITALY]]]]]]]])  ->  datetime
 *
 * Creates a DateTime object denoting the given week date.
 *
 *    DateTime.commercial(2001)	#=> #<DateTime: 2001-01-01T00:00:00+00:00 ...>
 *    DateTime.commercial(2002)	#=> #<DateTime: 2001-12-31T00:00:00+00:00 ...>
 *    DateTime.commercial(2001,5,6,4,5,6,'+7')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 */
static VALUE
datetime_s_commercial(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vh, vmin, vs, vof, vsg, y, fr, fr2, ret;
    int w, d, h, min, s, rof;
    double sg;

    rb_scan_args(argc, argv, "08", &vy, &vw, &vd, &vh, &vmin, &vs, &vof, &vsg);

    y = INT2FIX(-4712);
    w = 1;
    d = 1;

    h = min = s = 0;
    fr2 = INT2FIX(0);
    rof = 0;
    sg = DEFAULT_SG;

    switch (argc) {
      case 8:
	val2sg(vsg, sg);
      case 7:
	val2off(vof, rof);
      case 6:
        check_numeric(vs, "second");
	num2int_with_frac(s, positive_inf);
      case 5:
        check_numeric(vmin, "minute");
	num2int_with_frac(min, 5);
      case 4:
        check_numeric(vh, "hour");
	num2int_with_frac(h, 4);
      case 3:
        check_numeric(vd, "cwday");
	num2int_with_frac(d, 3);
      case 2:
        check_numeric(vw, "cweek");
	w = NUM2INT(vw);
      case 1:
        check_numeric(vy, "year");
	y = vy;
    }

    {
	VALUE nth;
	int ry, rw, rd, rh, rmin, rs, rjd, rjd2, ns;

	if (!valid_commercial_p(y, w, d, sg,
				&nth, &ry,
				&rw, &rd, &rjd,
				&ns))
	    rb_raise(eDateError, "invalid date");
	if (!c_valid_time_p(h, min, s, &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");
	canon24oc();

	rjd2 = jd_local_to_utc(rjd,
			       time_to_df(rh, rmin, rs),
			       rof);

	ret = d_complex_new_internal(klass,
				     nth, rjd2,
				     0, INT2FIX(0),
				     rof, sg,
				     0, 0, 0,
				     rh, rmin, rs,
				     HAVE_JD | HAVE_TIME);
    }
    add_frac();
    return ret;
}

#ifndef NDEBUG
/* :nodoc: */
static VALUE
datetime_s_weeknum(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vw, vd, vf, vh, vmin, vs, vof, vsg, y, fr, fr2, ret;
    int w, d, f, h, min, s, rof;
    double sg;

    rb_scan_args(argc, argv, "09", &vy, &vw, &vd, &vf,
		 &vh, &vmin, &vs, &vof, &vsg);

    y = INT2FIX(-4712);
    w = 0;
    d = 1;
    f = 0;

    h = min = s = 0;
    fr2 = INT2FIX(0);
    rof = 0;
    sg = DEFAULT_SG;

    switch (argc) {
      case 9:
	val2sg(vsg, sg);
      case 8:
	val2off(vof, rof);
      case 7:
	num2int_with_frac(s, positive_inf);
      case 6:
	num2int_with_frac(min, 6);
      case 5:
	num2int_with_frac(h, 5);
      case 4:
	f = NUM2INT(vf);
      case 3:
	num2int_with_frac(d, 4);
      case 2:
	w = NUM2INT(vw);
      case 1:
	y = vy;
    }

    {
	VALUE nth;
	int ry, rw, rd, rh, rmin, rs, rjd, rjd2, ns;

	if (!valid_weeknum_p(y, w, d, f, sg,
			     &nth, &ry,
			     &rw, &rd, &rjd,
			     &ns))
	    rb_raise(eDateError, "invalid date");
	if (!c_valid_time_p(h, min, s, &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");
	canon24oc();

	rjd2 = jd_local_to_utc(rjd,
			       time_to_df(rh, rmin, rs),
			       rof);
	ret = d_complex_new_internal(klass,
				     nth, rjd2,
				     0, INT2FIX(0),
				     rof, sg,
				     0, 0, 0,
				     rh, rmin, rs,
				     HAVE_JD | HAVE_TIME);
    }
    add_frac();
    return ret;
}

/* :nodoc: */
static VALUE
datetime_s_nth_kday(int argc, VALUE *argv, VALUE klass)
{
    VALUE vy, vm, vn, vk, vh, vmin, vs, vof, vsg, y, fr, fr2, ret;
    int m, n, k, h, min, s, rof;
    double sg;

    rb_scan_args(argc, argv, "09", &vy, &vm, &vn, &vk,
		 &vh, &vmin, &vs, &vof, &vsg);

    y = INT2FIX(-4712);
    m = 1;
    n = 1;
    k = 1;

    h = min = s = 0;
    fr2 = INT2FIX(0);
    rof = 0;
    sg = DEFAULT_SG;

    switch (argc) {
      case 9:
	val2sg(vsg, sg);
      case 8:
	val2off(vof, rof);
      case 7:
	num2int_with_frac(s, positive_inf);
      case 6:
	num2int_with_frac(min, 6);
      case 5:
	num2int_with_frac(h, 5);
      case 4:
	num2int_with_frac(k, 4);
      case 3:
	n = NUM2INT(vn);
      case 2:
	m = NUM2INT(vm);
      case 1:
	y = vy;
    }

    {
	VALUE nth;
	int ry, rm, rn, rk, rh, rmin, rs, rjd, rjd2, ns;

	if (!valid_nth_kday_p(y, m, n, k, sg,
			      &nth, &ry,
			      &rm, &rn, &rk, &rjd,
			      &ns))
	    rb_raise(eDateError, "invalid date");
	if (!c_valid_time_p(h, min, s, &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");
	canon24oc();

	rjd2 = jd_local_to_utc(rjd,
			       time_to_df(rh, rmin, rs),
			       rof);
	ret = d_complex_new_internal(klass,
				     nth, rjd2,
				     0, INT2FIX(0),
				     rof, sg,
				     0, 0, 0,
				     rh, rmin, rs,
				     HAVE_JD | HAVE_TIME);
    }
    add_frac();
    return ret;
}
#endif

/*
 * call-seq:
 *    DateTime.now([start=Date::ITALY])  ->  datetime
 *
 * Creates a DateTime object denoting the present time.
 *
 *    DateTime.now		#=> #<DateTime: 2011-06-11T21:20:44+09:00 ...>
 */
static VALUE
datetime_s_now(int argc, VALUE *argv, VALUE klass)
{
    VALUE vsg, nth, ret;
    double sg;
#ifdef HAVE_CLOCK_GETTIME
    struct timespec ts;
#else
    struct timeval tv;
#endif
    time_t sec;
    struct tm tm;
    long sf, of;
    int y, ry, m, d, h, min, s;

    rb_scan_args(argc, argv, "01", &vsg);

    if (argc < 1)
	sg = DEFAULT_SG;
    else
	sg = NUM2DBL(vsg);

#ifdef HAVE_CLOCK_GETTIME
    if (clock_gettime(CLOCK_REALTIME, &ts) == -1)
	rb_sys_fail("clock_gettime");
    sec = ts.tv_sec;
#else
    if (gettimeofday(&tv, NULL) == -1)
	rb_sys_fail("gettimeofday");
    sec = tv.tv_sec;
#endif
    tzset();
    if (!localtime_r(&sec, &tm))
	rb_sys_fail("localtime");

    y = tm.tm_year + 1900;
    m = tm.tm_mon + 1;
    d = tm.tm_mday;
    h = tm.tm_hour;
    min = tm.tm_min;
    s = tm.tm_sec;
    if (s == 60)
	s = 59;
#ifdef HAVE_STRUCT_TM_TM_GMTOFF
    of = tm.tm_gmtoff;
#elif defined(HAVE_TIMEZONE)
#if defined(HAVE_ALTZONE) && !defined(_AIX)
    of = (long)-((tm.tm_isdst > 0) ? altzone : timezone);
#else
    of = (long)-timezone;
    if (tm.tm_isdst) {
	time_t sec2;

	tm.tm_isdst = 0;
	sec2 = mktime(&tm);
	of += (long)difftime(sec2, sec);
    }
#endif
#elif defined(HAVE_TIMEGM)
    {
	time_t sec2;

	sec2 = timegm(&tm);
	of = (long)difftime(sec2, sec);
    }
#else
    {
	struct tm tm2;
	time_t sec2;

	if (!gmtime_r(&sec, &tm2))
	    rb_sys_fail("gmtime");
	tm2.tm_isdst = tm.tm_isdst;
	sec2 = mktime(&tm2);
	of = (long)difftime(sec, sec2);
    }
#endif
#ifdef HAVE_CLOCK_GETTIME
    sf = ts.tv_nsec;
#else
    sf = tv.tv_usec * 1000;
#endif

    if (of < -DAY_IN_SECONDS || of > DAY_IN_SECONDS) {
	of = 0;
	rb_warning("invalid offset is ignored");
    }

    decode_year(INT2FIX(y), -1, &nth, &ry);

    ret = d_complex_new_internal(klass,
				 nth, 0,
				 0, LONG2NUM(sf),
				 (int)of, GREGORIAN,
				 ry, m, d,
				 h, min, s,
				 HAVE_CIVIL | HAVE_TIME);
    {
	get_d1(ret);
	set_sg(dat, sg);
    }
    return ret;
}

static VALUE
dt_new_by_frags(VALUE klass, VALUE hash, VALUE sg)
{
    VALUE jd, sf, t;
    int df, of;

    if (!c_valid_start_p(NUM2DBL(sg))) {
	sg = INT2FIX(DEFAULT_SG);
	rb_warning("invalid start is ignored");
    }

    if (NIL_P(hash))
	rb_raise(eDateError, "invalid date");

    if (NIL_P(ref_hash("jd")) &&
	NIL_P(ref_hash("yday")) &&
	!NIL_P(ref_hash("year")) &&
	!NIL_P(ref_hash("mon")) &&
	!NIL_P(ref_hash("mday"))) {
	jd = rt__valid_civil_p(ref_hash("year"),
			       ref_hash("mon"),
			       ref_hash("mday"), sg);

	if (NIL_P(ref_hash("hour")))
	    set_hash("hour", INT2FIX(0));
	if (NIL_P(ref_hash("min")))
	    set_hash("min", INT2FIX(0));
	if (NIL_P(ref_hash("sec")))
	    set_hash("sec", INT2FIX(0));
	else if (f_eqeq_p(ref_hash("sec"), INT2FIX(60)))
	    set_hash("sec", INT2FIX(59));
    }
    else {
	hash = rt_rewrite_frags(hash);
	hash = rt_complete_frags(klass, hash);
	jd = rt__valid_date_frags_p(hash, sg);
    }

    if (NIL_P(jd))
	rb_raise(eDateError, "invalid date");

    {
	int rh, rmin, rs;

	if (!c_valid_time_p(NUM2INT(ref_hash("hour")),
			    NUM2INT(ref_hash("min")),
			    NUM2INT(ref_hash("sec")),
			    &rh, &rmin, &rs))
	    rb_raise(eDateError, "invalid date");

	df = time_to_df(rh, rmin, rs);
    }

    t = ref_hash("sec_fraction");
    if (NIL_P(t))
	sf = INT2FIX(0);
    else
	sf = sec_to_ns(t);

    t = ref_hash("offset");
    if (NIL_P(t))
	of = 0;
    else {
	of = NUM2INT(t);
	if (of < -DAY_IN_SECONDS || of > DAY_IN_SECONDS) {
	    of = 0;
	    rb_warning("invalid offset is ignored");
	}
    }
    {
	VALUE nth;
	int rjd, rjd2;

	decode_jd(jd, &nth, &rjd);
	rjd2 = jd_local_to_utc(rjd, df, of);
	df = df_local_to_utc(df, of);

	return d_complex_new_internal(klass,
				      nth, rjd2,
				      df, sf,
				      of, NUM2DBL(sg),
				      0, 0, 0,
				      0, 0, 0,
				      HAVE_JD | HAVE_DF);
    }
}

/*
 * call-seq:
 *    DateTime._strptime(string[, format='%FT%T%z'])  ->  hash
 *
 * Parses the given representation of date and time with the given
 * template, and returns a hash of parsed elements.  _strptime does
 * not support specification of flags and width unlike strftime.
 *
 * See also strptime(3) and #strftime.
 */
static VALUE
datetime_s__strptime(int argc, VALUE *argv, VALUE klass)
{
    return date_s__strptime_internal(argc, argv, klass, "%FT%T%z");
}

/*
 * call-seq:
 *    DateTime.strptime([string='-4712-01-01T00:00:00+00:00'[, format='%FT%T%z'[ ,start=Date::ITALY]]])  ->  datetime
 *
 * Parses the given representation of date and time with the given
 * template, and creates a DateTime object.  strptime does not support
 * specification of flags and width unlike strftime.
 *
 *    DateTime.strptime('2001-02-03T04:05:06+07:00', '%Y-%m-%dT%H:%M:%S%z')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.strptime('03-02-2001 04:05:06 PM', '%d-%m-%Y %I:%M:%S %p')
 *				#=> #<DateTime: 2001-02-03T16:05:06+00:00 ...>
 *    DateTime.strptime('2001-W05-6T04:05:06+07:00', '%G-W%V-%uT%H:%M:%S%z')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.strptime('2001 04 6 04 05 06 +7', '%Y %U %w %H %M %S %z')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.strptime('2001 05 6 04 05 06 +7', '%Y %W %u %H %M %S %z')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.strptime('-1', '%s')
 *				#=> #<DateTime: 1969-12-31T23:59:59+00:00 ...>
 *    DateTime.strptime('-1000', '%Q')
 *				#=> #<DateTime: 1969-12-31T23:59:59+00:00 ...>
 *    DateTime.strptime('sat3feb014pm+7', '%a%d%b%y%H%p%z')
 *				#=> #<DateTime: 2001-02-03T16:00:00+07:00 ...>
 *
 * See also strptime(3) and #strftime.
 */
static VALUE
datetime_s_strptime(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, fmt, sg;

    rb_scan_args(argc, argv, "03", &str, &fmt, &sg);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME);
      case 1:
	fmt = rb_str_new2("%FT%T%z");
      case 2:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
	VALUE argv2[2], hash;

	argv2[0] = str;
	argv2[1] = fmt;
	hash = date_s__strptime(2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    DateTime.parse(string='-4712-01-01T00:00:00+00:00'[, comp=true[, start=Date::ITALY]], limit: 128)  ->  datetime
 *
 * Parses the given representation of date and time, and creates a
 * DateTime object.
 *
 * This method *does* *not* function as a validator.  If the input
 * string does not match valid formats strictly, you may get a cryptic
 * result.  Should consider to use DateTime.strptime instead of this
 * method as possible.
 *
 * If the optional second argument is true and the detected year is in
 * the range "00" to "99", makes it full.
 *
 *    DateTime.parse('2001-02-03T04:05:06+07:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.parse('20010203T040506+0700')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.parse('3rd Feb 2001 04:05:06 PM')
 *				#=> #<DateTime: 2001-02-03T16:05:06+00:00 ...>
 *
 * Raise an ArgumentError when the string length is longer than _limit_.
 * You can stop this check by passing <code>limit: nil</code>, but note
 * that it may take a long time to parse.
 */
static VALUE
datetime_s_parse(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, comp, sg, opt;

    argc = rb_scan_args(argc, argv, "03:", &str, &comp, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME);
      case 1:
	comp = Qtrue;
      case 2:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 2;
        VALUE argv2[3], hash;
        argv2[0] = str;
        argv2[1] = comp;
        argv2[2] = opt;
        if (!NIL_P(opt)) argc2++;
	hash = date_s__parse(argc2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    DateTime.iso8601(string='-4712-01-01T00:00:00+00:00'[, start=Date::ITALY], limit: 128)  ->  datetime
 *
 * Creates a new DateTime object by parsing from a string according to
 * some typical ISO 8601 formats.
 *
 *    DateTime.iso8601('2001-02-03T04:05:06+07:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.iso8601('20010203T040506+0700')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *    DateTime.iso8601('2001-W05-6T04:05:06+07:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *
 * Raise an ArgumentError when the string length is longer than _limit_.
 * You can stop this check by passing <code>limit: nil</code>, but note
 * that it may take a long time to parse.
 */
static VALUE
datetime_s_iso8601(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        argv2[1] = opt;
        if (!NIL_P(opt)) argc2++;
	hash = date_s__iso8601(argc2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    DateTime.rfc3339(string='-4712-01-01T00:00:00+00:00'[, start=Date::ITALY], limit: 128)  ->  datetime
 *
 * Creates a new DateTime object by parsing from a string according to
 * some typical RFC 3339 formats.
 *
 *    DateTime.rfc3339('2001-02-03T04:05:06+07:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *
 * Raise an ArgumentError when the string length is longer than _limit_.
 * You can stop this check by passing <code>limit: nil</code>, but note
 * that it may take a long time to parse.
 */
static VALUE
datetime_s_rfc3339(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        argv2[1] = opt;
        if (!NIL_P(opt)) argc2++;
	hash = date_s__rfc3339(argc2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    DateTime.xmlschema(string='-4712-01-01T00:00:00+00:00'[, start=Date::ITALY], limit: 128)  ->  datetime
 *
 * Creates a new DateTime object by parsing from a string according to
 * some typical XML Schema formats.
 *
 *    DateTime.xmlschema('2001-02-03T04:05:06+07:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *
 * Raise an ArgumentError when the string length is longer than _limit_.
 * You can stop this check by passing <code>limit: nil</code>, but note
 * that it may take a long time to parse.
 */
static VALUE
datetime_s_xmlschema(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        argv2[1] = opt;
        if (!NIL_P(opt)) argc2++;
	hash = date_s__xmlschema(argc2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    DateTime.rfc2822(string='Mon, 1 Jan -4712 00:00:00 +0000'[, start=Date::ITALY], limit: 128)  ->  datetime
 *    DateTime.rfc822(string='Mon, 1 Jan -4712 00:00:00 +0000'[, start=Date::ITALY], limit: 128)   ->  datetime
 *
 * Creates a new DateTime object by parsing from a string according to
 * some typical RFC 2822 formats.
 *
 *     DateTime.rfc2822('Sat, 3 Feb 2001 04:05:06 +0700')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *
 * Raise an ArgumentError when the string length is longer than _limit_.
 * You can stop this check by passing <code>limit: nil</code>, but note
 * that it may take a long time to parse.
 */
static VALUE
datetime_s_rfc2822(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME_RFC3339);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        argv2[1] = opt;
        if (!NIL_P(opt)) argc2++;
	hash = date_s__rfc2822(argc2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    DateTime.httpdate(string='Mon, 01 Jan -4712 00:00:00 GMT'[, start=Date::ITALY])  ->  datetime
 *
 * Creates a new DateTime object by parsing from a string according to
 * some RFC 2616 format.
 *
 *    DateTime.httpdate('Sat, 03 Feb 2001 04:05:06 GMT')
 *				#=> #<DateTime: 2001-02-03T04:05:06+00:00 ...>
 *
 * Raise an ArgumentError when the string length is longer than _limit_.
 * You can stop this check by passing <code>limit: nil</code>, but note
 * that it may take a long time to parse.
 */
static VALUE
datetime_s_httpdate(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME_HTTPDATE);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        argv2[1] = opt;
        if (!NIL_P(opt)) argc2++;
	hash = date_s__httpdate(argc2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    DateTime.jisx0301(string='-4712-01-01T00:00:00+00:00'[, start=Date::ITALY], limit: 128)  ->  datetime
 *
 * Creates a new DateTime object by parsing from a string according to
 * some typical JIS X 0301 formats.
 *
 *    DateTime.jisx0301('H13.02.03T04:05:06+07:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *
 * For no-era year, legacy format, Heisei is assumed.
 *
 *    DateTime.jisx0301('13.02.03T04:05:06+07:00')
 *				#=> #<DateTime: 2001-02-03T04:05:06+07:00 ...>
 *
 * Raise an ArgumentError when the string length is longer than _limit_.
 * You can stop this check by passing <code>limit: nil</code>, but note
 * that it may take a long time to parse.
 */
static VALUE
datetime_s_jisx0301(int argc, VALUE *argv, VALUE klass)
{
    VALUE str, sg, opt;

    argc = rb_scan_args(argc, argv, "02:", &str, &sg, &opt);

    switch (argc) {
      case 0:
	str = rb_str_new2(JULIAN_EPOCH_DATETIME);
      case 1:
	sg = INT2FIX(DEFAULT_SG);
    }

    {
        int argc2 = 1;
        VALUE argv2[2], hash;
        argv2[0] = str;
        argv2[1] = opt;
        if (!NIL_P(opt)) argc2++;
	hash = date_s__jisx0301(argc2, argv2, klass);
	return dt_new_by_frags(klass, hash, sg);
    }
}

/*
 * call-seq:
 *    dt.to_s  ->  string
 *
 * Returns a string in an ISO 8601 format. (This method doesn't use the
 * expanded representations.)
 *
 *     DateTime.new(2001,2,3,4,5,6,'-7').to_s
 *				#=> "2001-02-03T04:05:06-07:00"
 */
static VALUE
dt_lite_to_s(VALUE self)
{
    return strftimev("%Y-%m-%dT%H:%M:%S%:z", self, set_tmx);
}

/*
 * call-seq:
 *   strftime(format = '%FT%T%:z') -> string
 *
 * Returns a string representation of +self+,
 * formatted according the given +format:
 *
 *   DateTime.now.strftime # => "2022-07-01T11:03:19-05:00"
 *
 * For other formats,
 * see {Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html]:
 *
 */
static VALUE
dt_lite_strftime(int argc, VALUE *argv, VALUE self)
{
    return date_strftime_internal(argc, argv, self,
				  "%Y-%m-%dT%H:%M:%S%:z", set_tmx);
}

static VALUE
iso8601_timediv(VALUE self, long n)
{
    static const char timefmt[] = "T%H:%M:%S";
    static const char zone[] = "%:z";
    char fmt[sizeof(timefmt) + sizeof(zone) + rb_strlen_lit(".%N") +
	     DECIMAL_SIZE_OF_LONG];
    char *p = fmt;

    memcpy(p, timefmt, sizeof(timefmt)-1);
    p += sizeof(timefmt)-1;
    if (n > 0) p += snprintf(p, fmt+sizeof(fmt)-p, ".%%%ldN", n);
    memcpy(p, zone, sizeof(zone));
    return strftimev(fmt, self, set_tmx);
}

/*
 * call-seq:
 *    dt.iso8601([n=0])    ->  string
 *    dt.xmlschema([n=0])  ->  string
 *
 * This method is equivalent to strftime('%FT%T%:z').
 * The optional argument +n+ is the number of digits for fractional seconds.
 *
 *    DateTime.parse('2001-02-03T04:05:06.123456789+07:00').iso8601(9)
 *				#=> "2001-02-03T04:05:06.123456789+07:00"
 */
static VALUE
dt_lite_iso8601(int argc, VALUE *argv, VALUE self)
{
    long n = 0;

    rb_check_arity(argc, 0, 1);
    if (argc >= 1)
	n = NUM2LONG(argv[0]);

    return rb_str_append(strftimev("%Y-%m-%d", self, set_tmx),
			 iso8601_timediv(self, n));
}

/*
 * call-seq:
 *    dt.rfc3339([n=0])  ->  string
 *
 * This method is equivalent to strftime('%FT%T%:z').
 * The optional argument +n+ is the number of digits for fractional seconds.
 *
 *    DateTime.parse('2001-02-03T04:05:06.123456789+07:00').rfc3339(9)
 *				#=> "2001-02-03T04:05:06.123456789+07:00"
 */
static VALUE
dt_lite_rfc3339(int argc, VALUE *argv, VALUE self)
{
    return dt_lite_iso8601(argc, argv, self);
}

/*
 * call-seq:
 *    dt.jisx0301([n=0])  ->  string
 *
 * Returns a string in a JIS X 0301 format.
 * The optional argument +n+ is the number of digits for fractional seconds.
 *
 *    DateTime.parse('2001-02-03T04:05:06.123456789+07:00').jisx0301(9)
 *				#=> "H13.02.03T04:05:06.123456789+07:00"
 */
static VALUE
dt_lite_jisx0301(int argc, VALUE *argv, VALUE self)
{
    long n = 0;

    rb_check_arity(argc, 0, 1);
    if (argc >= 1)
	n = NUM2LONG(argv[0]);

    return rb_str_append(d_lite_jisx0301(self),
			 iso8601_timediv(self, n));
}

/*
 *  call-seq:
 *    deconstruct_keys(array_of_names_or_nil) -> hash
 *
 *  Returns a hash of the name/value pairs, to use in pattern matching.
 *  Possible keys are: <tt>:year</tt>, <tt>:month</tt>, <tt>:day</tt>,
 *  <tt>:wday</tt>, <tt>:yday</tt>, <tt>:hour</tt>, <tt>:min</tt>,
 *  <tt>:sec</tt>, <tt>:sec_fraction</tt>, <tt>:zone</tt>.
 *
 *  Possible usages:
 *
 *    dt = DateTime.new(2022, 10, 5, 13, 30)
 *
 *    if d in wday: 1..5, hour: 10..18  # uses deconstruct_keys underneath
 *      puts "Working time"
 *    end
 *    #=> prints "Working time"
 *
 *    case dt
 *    in year: ...2022
 *      puts "too old"
 *    in month: ..9
 *      puts "quarter 1-3"
 *    in wday: 1..5, month:
 *      puts "working day in month #{month}"
 *    end
 *    #=> prints "working day in month 10"
 *
 *  Note that deconstruction by pattern can also be combined with class check:
 *
 *    if d in DateTime(wday: 1..5, hour: 10..18, day: ..7)
 *      puts "Working time, first week of the month"
 *    end
 *
 */
static VALUE
dt_lite_deconstruct_keys(VALUE self, VALUE keys)
{
    return deconstruct_keys(self, keys, /* is_datetime=true */ 1);
}

/* conversions */

#define f_subsec(x) rb_funcall(x, rb_intern("subsec"), 0)
#define f_utc_offset(x) rb_funcall(x, rb_intern("utc_offset"), 0)
#define f_local3(x,y,m,d) rb_funcall(x, rb_intern("local"), 3, y, m, d)

/*
 * call-seq:
 *    t.to_time  ->  time
 *
 * Returns self.
 */
static VALUE
time_to_time(VALUE self)
{
    return self;
}

/*
 * call-seq:
 *    t.to_date  ->  date
 *
 * Returns a Date object which denotes self.
 */
static VALUE
time_to_date(VALUE self)
{
    VALUE y, nth, ret;
    int ry, m, d;

    y = f_year(self);
    m = FIX2INT(f_mon(self));
    d = FIX2INT(f_mday(self));

    decode_year(y, -1, &nth, &ry);

    ret = d_simple_new_internal(cDate,
				nth, 0,
				GREGORIAN,
				ry, m, d,
				HAVE_CIVIL);
    {
	get_d1(ret);
	set_sg(dat, DEFAULT_SG);
    }
    return ret;
}

/*
 * call-seq:
 *    t.to_datetime  ->  datetime
 *
 * Returns a DateTime object which denotes self.
 */
static VALUE
time_to_datetime(VALUE self)
{
    VALUE y, sf, nth, ret;
    int ry, m, d, h, min, s, of;

    y = f_year(self);
    m = FIX2INT(f_mon(self));
    d = FIX2INT(f_mday(self));

    h = FIX2INT(f_hour(self));
    min = FIX2INT(f_min(self));
    s = FIX2INT(f_sec(self));
    if (s == 60)
	s = 59;

    sf = sec_to_ns(f_subsec(self));
    of = FIX2INT(f_utc_offset(self));

    decode_year(y, -1, &nth, &ry);

    ret = d_complex_new_internal(cDateTime,
				 nth, 0,
				 0, sf,
				 of, GREGORIAN,
				 ry, m, d,
				 h, min, s,
				 HAVE_CIVIL | HAVE_TIME);
    {
	get_d1(ret);
	set_sg(dat, DEFAULT_SG);
    }
    return ret;
}

/*
 * call-seq:
 *   to_time -> time
 *
 * Returns a new Time object with the same value as +self+;
 * if +self+ is a Julian date, derives its Gregorian date
 * for conversion to the \Time object:
 *
 *   Date.new(2001, 2, 3).to_time               # => 2001-02-03 00:00:00 -0600
 *   Date.new(2001, 2, 3, Date::JULIAN).to_time # => 2001-02-16 00:00:00 -0600
 *
 */
static VALUE
date_to_time(VALUE self)
{
    VALUE t;

    get_d1a(self);

    if (m_julian_p(adat)) {
        VALUE g = d_lite_gregorian(self);
        get_d1b(g);
        adat = bdat;
        self = g;
    }

    t = f_local3(rb_cTime,
        m_real_year(adat),
        INT2FIX(m_mon(adat)),
        INT2FIX(m_mday(adat)));
    RB_GC_GUARD(self); /* may be the converted gregorian */
    return t;
}

/*
 * call-seq:
 *   to_date -> self
 *
 * Returns +self+.
 */
static VALUE
date_to_date(VALUE self)
{
    return self;
}

/*
 * call-seq:
 *    d.to_datetime  -> datetime
 *
 * Returns a DateTime whose value is the same as +self+:
 *
 *   Date.new(2001, 2, 3).to_datetime # => #<DateTime: 2001-02-03T00:00:00+00:00>
 *
 */
static VALUE
date_to_datetime(VALUE self)
{
    get_d1a(self);

    if (simple_dat_p(adat)) {
	VALUE new = d_lite_s_alloc_simple(cDateTime);
	{
	    get_d1b(new);
	    bdat->s = adat->s;
	    return new;
	}
    }
    else {
	VALUE new = d_lite_s_alloc_complex(cDateTime);
	{
	    get_d1b(new);
	    bdat->c = adat->c;
	    bdat->c.df = 0;
	    RB_OBJ_WRITE(new, &bdat->c.sf, INT2FIX(0));
#ifndef USE_PACK
	    bdat->c.hour = 0;
	    bdat->c.min = 0;
	    bdat->c.sec = 0;
#else
	    bdat->c.pc = PACK5(EX_MON(adat->c.pc), EX_MDAY(adat->c.pc),
			       0, 0, 0);
	    bdat->c.flags |= HAVE_DF | HAVE_TIME;
#endif
	    return new;
	}
    }
}

/*
 * call-seq:
 *    dt.to_time  ->  time
 *
 * Returns a Time object which denotes self.
 */
static VALUE
datetime_to_time(VALUE self)
{
    get_d1(self);

    if (m_julian_p(dat)) {
	VALUE g = d_lite_gregorian(self);
	get_d1a(g);
	dat = adat;
	self = g;
    }

    {
	VALUE t;

	t = rb_funcall(rb_cTime,
		   rb_intern("new"),
                   7,
		   m_real_year(dat),
		   INT2FIX(m_mon(dat)),
		   INT2FIX(m_mday(dat)),
		   INT2FIX(m_hour(dat)),
		   INT2FIX(m_min(dat)),
		   f_add(INT2FIX(m_sec(dat)),
			 m_sf_in_sec(dat)),
		   INT2FIX(m_of(dat)));
	RB_GC_GUARD(self); /* may be the converted gregorian */
	return t;
    }
}

/*
 * call-seq:
 *    dt.to_date  ->  date
 *
 * Returns a Date object which denotes self.
 */
static VALUE
datetime_to_date(VALUE self)
{
    get_d1a(self);

    if (simple_dat_p(adat)) {
	VALUE new = d_lite_s_alloc_simple(cDate);
	{
	    get_d1b(new);
	    bdat->s = adat->s;
	    bdat->s.jd = m_local_jd(adat);
	    return new;
	}
    }
    else {
	VALUE new = d_lite_s_alloc_simple(cDate);
	{
	    get_d1b(new);
	    copy_complex_to_simple(new, &bdat->s, &adat->c);
	    bdat->s.jd = m_local_jd(adat);
	    bdat->s.flags &= ~(HAVE_DF | HAVE_TIME | COMPLEX_DAT);
	    return new;
	}
    }
}

/*
 * call-seq:
 *    dt.to_datetime  ->  self
 *
 * Returns self.
 */
static VALUE
datetime_to_datetime(VALUE self)
{
    return self;
}

#ifndef NDEBUG
/* tests */

#define MIN_YEAR -4713
#define MAX_YEAR 1000000
#define MIN_JD -327
#define MAX_JD 366963925

/* :nodoc: */
static int
test_civil(int from, int to, double sg)
{
    int j;

    fprintf(stderr, "test_civil: %d...%d (%d) - %.0f\n",
	    from, to, to - from, sg);
    for (j = from; j <= to; j++) {
	int y, m, d, rj, ns;

	c_jd_to_civil(j, sg, &y, &m, &d);
	c_civil_to_jd(y, m, d, sg, &rj, &ns);
	if (j != rj) {
	    fprintf(stderr, "%d != %d\n", j, rj);
	    return 0;
	}
    }
    return 1;
}

/* :nodoc: */
static VALUE
date_s_test_civil(VALUE klass)
{
    if (!test_civil(MIN_JD, MIN_JD + 366, GREGORIAN))
	return Qfalse;
    if (!test_civil(2305814, 2598007, GREGORIAN))
	return Qfalse;
    if (!test_civil(MAX_JD - 366, MAX_JD, GREGORIAN))
	return Qfalse;

    if (!test_civil(MIN_JD, MIN_JD + 366, ITALY))
	return Qfalse;
    if (!test_civil(2305814, 2598007, ITALY))
	return Qfalse;
    if (!test_civil(MAX_JD - 366, MAX_JD, ITALY))
	return Qfalse;

    return Qtrue;
}

/* :nodoc: */
static int
test_ordinal(int from, int to, double sg)
{
    int j;

    fprintf(stderr, "test_ordinal: %d...%d (%d) - %.0f\n",
	    from, to, to - from, sg);
    for (j = from; j <= to; j++) {
	int y, d, rj, ns;

	c_jd_to_ordinal(j, sg, &y, &d);
	c_ordinal_to_jd(y, d, sg, &rj, &ns);
	if (j != rj) {
	    fprintf(stderr, "%d != %d\n", j, rj);
	    return 0;
	}
    }
    return 1;
}

/* :nodoc: */
static VALUE
date_s_test_ordinal(VALUE klass)
{
    if (!test_ordinal(MIN_JD, MIN_JD + 366, GREGORIAN))
	return Qfalse;
    if (!test_ordinal(2305814, 2598007, GREGORIAN))
	return Qfalse;
    if (!test_ordinal(MAX_JD - 366, MAX_JD, GREGORIAN))
	return Qfalse;

    if (!test_ordinal(MIN_JD, MIN_JD + 366, ITALY))
	return Qfalse;
    if (!test_ordinal(2305814, 2598007, ITALY))
	return Qfalse;
    if (!test_ordinal(MAX_JD - 366, MAX_JD, ITALY))
	return Qfalse;

    return Qtrue;
}

/* :nodoc: */
static int
test_commercial(int from, int to, double sg)
{
    int j;

    fprintf(stderr, "test_commercial: %d...%d (%d) - %.0f\n",
	    from, to, to - from, sg);
    for (j = from; j <= to; j++) {
	int y, w, d, rj, ns;

	c_jd_to_commercial(j, sg, &y, &w, &d);
	c_commercial_to_jd(y, w, d, sg, &rj, &ns);
	if (j != rj) {
	    fprintf(stderr, "%d != %d\n", j, rj);
	    return 0;
	}
    }
    return 1;
}

/* :nodoc: */
static VALUE
date_s_test_commercial(VALUE klass)
{
    if (!test_commercial(MIN_JD, MIN_JD + 366, GREGORIAN))
	return Qfalse;
    if (!test_commercial(2305814, 2598007, GREGORIAN))
	return Qfalse;
    if (!test_commercial(MAX_JD - 366, MAX_JD, GREGORIAN))
	return Qfalse;

    if (!test_commercial(MIN_JD, MIN_JD + 366, ITALY))
	return Qfalse;
    if (!test_commercial(2305814, 2598007, ITALY))
	return Qfalse;
    if (!test_commercial(MAX_JD - 366, MAX_JD, ITALY))
	return Qfalse;

    return Qtrue;
}

/* :nodoc: */
static int
test_weeknum(int from, int to, int f, double sg)
{
    int j;

    fprintf(stderr, "test_weeknum: %d...%d (%d) - %.0f\n",
	    from, to, to - from, sg);
    for (j = from; j <= to; j++) {
	int y, w, d, rj, ns;

	c_jd_to_weeknum(j, f, sg, &y, &w, &d);
	c_weeknum_to_jd(y, w, d, f, sg, &rj, &ns);
	if (j != rj) {
	    fprintf(stderr, "%d != %d\n", j, rj);
	    return 0;
	}
    }
    return 1;
}

/* :nodoc: */
static VALUE
date_s_test_weeknum(VALUE klass)
{
    int f;

    for (f = 0; f <= 1; f++) {
	if (!test_weeknum(MIN_JD, MIN_JD + 366, f, GREGORIAN))
	    return Qfalse;
	if (!test_weeknum(2305814, 2598007, f, GREGORIAN))
	    return Qfalse;
	if (!test_weeknum(MAX_JD - 366, MAX_JD, f, GREGORIAN))
	    return Qfalse;

	if (!test_weeknum(MIN_JD, MIN_JD + 366, f, ITALY))
	    return Qfalse;
	if (!test_weeknum(2305814, 2598007, f, ITALY))
	    return Qfalse;
	if (!test_weeknum(MAX_JD - 366, MAX_JD, f, ITALY))
	    return Qfalse;
    }

    return Qtrue;
}

/* :nodoc: */
static int
test_nth_kday(int from, int to, double sg)
{
    int j;

    fprintf(stderr, "test_nth_kday: %d...%d (%d) - %.0f\n",
	    from, to, to - from, sg);
    for (j = from; j <= to; j++) {
	int y, m, n, k, rj, ns;

	c_jd_to_nth_kday(j, sg, &y, &m, &n, &k);
	c_nth_kday_to_jd(y, m, n, k, sg, &rj, &ns);
	if (j != rj) {
	    fprintf(stderr, "%d != %d\n", j, rj);
	    return 0;
	}
    }
    return 1;
}

/* :nodoc: */
static VALUE
date_s_test_nth_kday(VALUE klass)
{
    if (!test_nth_kday(MIN_JD, MIN_JD + 366, GREGORIAN))
	return Qfalse;
    if (!test_nth_kday(2305814, 2598007, GREGORIAN))
	return Qfalse;
    if (!test_nth_kday(MAX_JD - 366, MAX_JD, GREGORIAN))
	return Qfalse;

    if (!test_nth_kday(MIN_JD, MIN_JD + 366, ITALY))
	return Qfalse;
    if (!test_nth_kday(2305814, 2598007, ITALY))
	return Qfalse;
    if (!test_nth_kday(MAX_JD - 366, MAX_JD, ITALY))
	return Qfalse;

    return Qtrue;
}

/* :nodoc: */
static int
test_unit_v2v(VALUE i,
	      VALUE (* conv1)(VALUE),
	      VALUE (* conv2)(VALUE))
{
    VALUE c, o;
    c = (*conv1)(i);
    o = (*conv2)(c);
    return f_eqeq_p(o, i);
}

/* :nodoc: */
static int
test_unit_v2v_iter2(VALUE (* conv1)(VALUE),
		    VALUE (* conv2)(VALUE))
{
    if (!test_unit_v2v(INT2FIX(0), conv1, conv2))
	return 0;
    if (!test_unit_v2v(INT2FIX(1), conv1, conv2))
	return 0;
    if (!test_unit_v2v(INT2FIX(2), conv1, conv2))
	return 0;
    if (!test_unit_v2v(INT2FIX(3), conv1, conv2))
	return 0;
    if (!test_unit_v2v(INT2FIX(11), conv1, conv2))
	return 0;
    if (!test_unit_v2v(INT2FIX(65535), conv1, conv2))
	return 0;
    if (!test_unit_v2v(INT2FIX(1073741823), conv1, conv2))
	return 0;
    if (!test_unit_v2v(INT2NUM(1073741824), conv1, conv2))
	return 0;
    if (!test_unit_v2v(rb_rational_new2(INT2FIX(0), INT2FIX(1)), conv1, conv2))
	return 0;
    if (!test_unit_v2v(rb_rational_new2(INT2FIX(1), INT2FIX(1)), conv1, conv2))
	return 0;
    if (!test_unit_v2v(rb_rational_new2(INT2FIX(1), INT2FIX(2)), conv1, conv2))
	return 0;
    if (!test_unit_v2v(rb_rational_new2(INT2FIX(2), INT2FIX(3)), conv1, conv2))
	return 0;
    return 1;
}

/* :nodoc: */
static int
test_unit_v2v_iter(VALUE (* conv1)(VALUE),
		   VALUE (* conv2)(VALUE))
{
    if (!test_unit_v2v_iter2(conv1, conv2))
	return 0;
    if (!test_unit_v2v_iter2(conv2, conv1))
	return 0;
    return 1;
}

/* :nodoc: */
static VALUE
date_s_test_unit_conv(VALUE klass)
{
    if (!test_unit_v2v_iter(sec_to_day, day_to_sec))
	return Qfalse;
    if (!test_unit_v2v_iter(ms_to_sec, sec_to_ms))
	return Qfalse;
    if (!test_unit_v2v_iter(ns_to_day, day_to_ns))
	return Qfalse;
    if (!test_unit_v2v_iter(ns_to_sec, sec_to_ns))
	return Qfalse;
    return Qtrue;
}

/* :nodoc: */
static VALUE
date_s_test_all(VALUE klass)
{
    if (date_s_test_civil(klass) == Qfalse)
	return Qfalse;
    if (date_s_test_ordinal(klass) == Qfalse)
	return Qfalse;
    if (date_s_test_commercial(klass) == Qfalse)
	return Qfalse;
    if (date_s_test_weeknum(klass) == Qfalse)
	return Qfalse;
    if (date_s_test_nth_kday(klass) == Qfalse)
	return Qfalse;
    if (date_s_test_unit_conv(klass) == Qfalse)
	return Qfalse;
    return Qtrue;
}
#endif

static const char *monthnames[] = {
    NULL,
    "January", "February", "March",
    "April", "May", "June",
    "July", "August", "September",
    "October", "November", "December"
};

static const char *abbr_monthnames[] = {
    NULL,
    "Jan", "Feb", "Mar", "Apr",
    "May", "Jun", "Jul", "Aug",
    "Sep", "Oct", "Nov", "Dec"
};

static const char *daynames[] = {
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday"
};

static const char *abbr_daynames[] = {
    "Sun", "Mon", "Tue", "Wed",
    "Thu", "Fri", "Sat"
};

static VALUE
mk_ary_of_str(long len, const char *a[])
{
    VALUE o;
    long i;

    o = rb_ary_new2(len);
    for (i = 0; i < len; i++) {
	VALUE e;

	if (!a[i])
	    e = Qnil;
	else {
	    e = rb_usascii_str_new2(a[i]);
	    rb_obj_freeze(e);
	}
	rb_ary_push(o, e);
    }
    rb_ary_freeze(o);
    return o;
}

/* :nodoc: */
static VALUE
d_lite_zero(VALUE x)
{
    return INT2FIX(0);
}

void
Init_date_core(void)
{
    #ifdef HAVE_RB_EXT_RACTOR_SAFE
	RB_EXT_RACTOR_SAFE(true);
    #endif
    id_cmp = rb_intern_const("<=>");
    id_le_p = rb_intern_const("<=");
    id_ge_p = rb_intern_const(">=");
    id_eqeq_p = rb_intern_const("==");

    sym_year = ID2SYM(rb_intern_const("year"));
    sym_month = ID2SYM(rb_intern_const("month"));
    sym_yday = ID2SYM(rb_intern_const("yday"));
    sym_wday = ID2SYM(rb_intern_const("wday"));
    sym_day = ID2SYM(rb_intern_const("day"));
    sym_hour = ID2SYM(rb_intern_const("hour"));
    sym_min = ID2SYM(rb_intern_const("min"));
    sym_sec = ID2SYM(rb_intern_const("sec"));
    sym_sec_fraction = ID2SYM(rb_intern_const("sec_fraction"));
    sym_zone = ID2SYM(rb_intern_const("zone"));

    half_days_in_day = rb_rational_new2(INT2FIX(1), INT2FIX(2));

#if (LONG_MAX / DAY_IN_SECONDS) > SECOND_IN_NANOSECONDS
    day_in_nanoseconds = LONG2NUM((long)DAY_IN_SECONDS *
				  SECOND_IN_NANOSECONDS);
#elif defined HAVE_LONG_LONG
    day_in_nanoseconds = LL2NUM((LONG_LONG)DAY_IN_SECONDS *
				SECOND_IN_NANOSECONDS);
#else
    day_in_nanoseconds = f_mul(INT2FIX(DAY_IN_SECONDS),
			       INT2FIX(SECOND_IN_NANOSECONDS));
#endif

    rb_gc_register_mark_object(half_days_in_day);
    rb_gc_register_mark_object(day_in_nanoseconds);

    positive_inf = +INFINITY;
    negative_inf = -INFINITY;

    /*
     * \Class \Date provides methods for storing and manipulating
     * calendar dates.
     *
     * Consider using
     * {class Time}[https://docs.ruby-lang.org/en/master/Time.html]
     * instead of class \Date if:
     *
     * - You need both dates and times; \Date handles only dates.
     * - You need only Gregorian dates (and not Julian dates);
     *   see {Julian and Gregorian Calendars}[rdoc-ref:calendars.rdoc].
     *
     * A \Date object, once created, is immutable, and cannot be modified.
     *
     * == Creating a \Date
     *
     * You can create a date for the current date, using Date.today:
     *
     *   Date.today # => #<Date: 1999-12-31>
     *
     * You can create a specific date from various combinations of arguments:
     *
     * - Date.new takes integer year, month, and day-of-month:
     *
     *     Date.new(1999, 12, 31) # => #<Date: 1999-12-31>
     *
     * - Date.ordinal takes integer year and day-of-year:
     *
     *     Date.ordinal(1999, 365) # => #<Date: 1999-12-31>
     *
     * - Date.jd takes integer Julian day:
     *
     *     Date.jd(2451544) # => #<Date: 1999-12-31>
     *
     * - Date.commercial takes integer commercial data (year, week, day-of-week):
     *
     *     Date.commercial(1999, 52, 5) # => #<Date: 1999-12-31>
     *
     * - Date.parse takes a string, which it parses heuristically:
     *
     *     Date.parse('1999-12-31')    # => #<Date: 1999-12-31>
     *     Date.parse('31-12-1999')    # => #<Date: 1999-12-31>
     *     Date.parse('1999-365')      # => #<Date: 1999-12-31>
     *     Date.parse('1999-W52-5')    # => #<Date: 1999-12-31>
     *
     * - Date.strptime takes a date string and a format string,
     *   then parses the date string according to the format string:
     *
     *     Date.strptime('1999-12-31', '%Y-%m-%d')  # => #<Date: 1999-12-31>
     *     Date.strptime('31-12-1999', '%d-%m-%Y')  # => #<Date: 1999-12-31>
     *     Date.strptime('1999-365', '%Y-%j')       # => #<Date: 1999-12-31>
     *     Date.strptime('1999-W52-5', '%G-W%V-%u') # => #<Date: 1999-12-31>
     *     Date.strptime('1999 52 5', '%Y %U %w')   # => #<Date: 1999-12-31>
     *     Date.strptime('1999 52 5', '%Y %W %u')   # => #<Date: 1999-12-31>
     *     Date.strptime('fri31dec99', '%a%d%b%y')  # => #<Date: 1999-12-31>
     *
     * See also the specialized methods in
     * {"Specialized Format Strings" in Formats for Dates and Times}[https://docs.ruby-lang.org/en/master/strftime_formatting_rdoc.html#label-Specialized+Format+Strings]
     *
     * == Argument +limit+
     *
     * Certain singleton methods in \Date that parse string arguments
     * also take optional keyword argument +limit+,
     * which can limit the length of the string argument.
     *
     * When +limit+ is:
     *
     * - Non-negative:
     *   raises ArgumentError if the string length is greater than _limit_.
     * - Other numeric or +nil+: ignores +limit+.
     * - Other non-numeric: raises TypeError.
     *
     */
    cDate = rb_define_class("Date", rb_cObject);

    /* Exception for invalid date/time */
    eDateError = rb_define_class_under(cDate, "Error", rb_eArgError);

    rb_include_module(cDate, rb_mComparable);

    /* An array of strings of full month names in English.  The first
     * element is nil.
     */
    rb_define_const(cDate, "MONTHNAMES", mk_ary_of_str(13, monthnames));

    /* An array of strings of abbreviated month names in English.  The
     * first element is nil.
     */
    rb_define_const(cDate, "ABBR_MONTHNAMES",
		    mk_ary_of_str(13, abbr_monthnames));

    /* An array of strings of the full names of days of the week in English.
     * The first is "Sunday".
     */
    rb_define_const(cDate, "DAYNAMES", mk_ary_of_str(7, daynames));

    /* An array of strings of abbreviated day names in English.  The
     * first is "Sun".
     */
    rb_define_const(cDate, "ABBR_DAYNAMES", mk_ary_of_str(7, abbr_daynames));

    /* The Julian day number of the day of calendar reform for Italy
     * and some catholic countries.
     */
    rb_define_const(cDate, "ITALY", INT2FIX(ITALY));

    /* The Julian day number of the day of calendar reform for England
     * and her colonies.
     */
    rb_define_const(cDate, "ENGLAND", INT2FIX(ENGLAND));

    /* The Julian day number of the day of calendar reform for the
     * proleptic Julian calendar.
     */
    rb_define_const(cDate, "JULIAN", DBL2NUM(JULIAN));

    /* The Julian day number of the day of calendar reform for the
     * proleptic Gregorian calendar.
     */
    rb_define_const(cDate, "GREGORIAN", DBL2NUM(GREGORIAN));

    rb_define_alloc_func(cDate, d_lite_s_alloc_simple);

#ifndef NDEBUG
    rb_define_private_method(CLASS_OF(cDate), "_valid_jd?",
			     date_s__valid_jd_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "_valid_ordinal?",
			     date_s__valid_ordinal_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "_valid_civil?",
			     date_s__valid_civil_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "_valid_date?",
			     date_s__valid_civil_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "_valid_commercial?",
			     date_s__valid_commercial_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "_valid_weeknum?",
			     date_s__valid_weeknum_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "_valid_nth_kday?",
			     date_s__valid_nth_kday_p, -1);
#endif

    rb_define_singleton_method(cDate, "valid_jd?", date_s_valid_jd_p, -1);
    rb_define_singleton_method(cDate, "valid_ordinal?",
			       date_s_valid_ordinal_p, -1);
    rb_define_singleton_method(cDate, "valid_civil?", date_s_valid_civil_p, -1);
    rb_define_singleton_method(cDate, "valid_date?", date_s_valid_civil_p, -1);
    rb_define_singleton_method(cDate, "valid_commercial?",
			       date_s_valid_commercial_p, -1);

#ifndef NDEBUG
    rb_define_private_method(CLASS_OF(cDate), "valid_weeknum?",
			     date_s_valid_weeknum_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "valid_nth_kday?",
			     date_s_valid_nth_kday_p, -1);
    rb_define_private_method(CLASS_OF(cDate), "zone_to_diff",
			     date_s_zone_to_diff, 1);
#endif

    rb_define_singleton_method(cDate, "julian_leap?", date_s_julian_leap_p, 1);
    rb_define_singleton_method(cDate, "gregorian_leap?",
			       date_s_gregorian_leap_p, 1);
    rb_define_singleton_method(cDate, "leap?",
			       date_s_gregorian_leap_p, 1);

#ifndef NDEBUG
    rb_define_singleton_method(cDate, "new!", date_s_new_bang, -1);
    rb_define_alias(rb_singleton_class(cDate), "new_l!", "new");
#endif

    rb_define_singleton_method(cDate, "jd", date_s_jd, -1);
    rb_define_singleton_method(cDate, "ordinal", date_s_ordinal, -1);
    rb_define_singleton_method(cDate, "civil", date_s_civil, -1);
    rb_define_singleton_method(cDate, "commercial", date_s_commercial, -1);

#ifndef NDEBUG
    rb_define_singleton_method(cDate, "weeknum", date_s_weeknum, -1);
    rb_define_singleton_method(cDate, "nth_kday", date_s_nth_kday, -1);
#endif

    rb_define_singleton_method(cDate, "today", date_s_today, -1);
    rb_define_singleton_method(cDate, "_strptime", date_s__strptime, -1);
    rb_define_singleton_method(cDate, "strptime", date_s_strptime, -1);
    rb_define_singleton_method(cDate, "_parse", date_s__parse, -1);
    rb_define_singleton_method(cDate, "parse", date_s_parse, -1);
    rb_define_singleton_method(cDate, "_iso8601", date_s__iso8601, -1);
    rb_define_singleton_method(cDate, "iso8601", date_s_iso8601, -1);
    rb_define_singleton_method(cDate, "_rfc3339", date_s__rfc3339, -1);
    rb_define_singleton_method(cDate, "rfc3339", date_s_rfc3339, -1);
    rb_define_singleton_method(cDate, "_xmlschema", date_s__xmlschema, -1);
    rb_define_singleton_method(cDate, "xmlschema", date_s_xmlschema, -1);
    rb_define_singleton_method(cDate, "_rfc2822", date_s__rfc2822, -1);
    rb_define_singleton_method(cDate, "_rfc822", date_s__rfc2822, -1);
    rb_define_singleton_method(cDate, "rfc2822", date_s_rfc2822, -1);
    rb_define_singleton_method(cDate, "rfc822", date_s_rfc2822, -1);
    rb_define_singleton_method(cDate, "_httpdate", date_s__httpdate, -1);
    rb_define_singleton_method(cDate, "httpdate", date_s_httpdate, -1);
    rb_define_singleton_method(cDate, "_jisx0301", date_s__jisx0301, -1);
    rb_define_singleton_method(cDate, "jisx0301", date_s_jisx0301, -1);

    rb_define_method(cDate, "initialize", date_initialize, -1);
    rb_define_method(cDate, "initialize_copy", d_lite_initialize_copy, 1);

#ifndef NDEBUG
    rb_define_method(cDate, "fill", d_lite_fill, 0);
#endif

    rb_define_method(cDate, "ajd", d_lite_ajd, 0);
    rb_define_method(cDate, "amjd", d_lite_amjd, 0);
    rb_define_method(cDate, "jd", d_lite_jd, 0);
    rb_define_method(cDate, "mjd", d_lite_mjd, 0);
    rb_define_method(cDate, "ld", d_lite_ld, 0);

    rb_define_method(cDate, "year", d_lite_year, 0);
    rb_define_method(cDate, "yday", d_lite_yday, 0);
    rb_define_method(cDate, "mon", d_lite_mon, 0);
    rb_define_method(cDate, "month", d_lite_mon, 0);
    rb_define_method(cDate, "mday", d_lite_mday, 0);
    rb_define_method(cDate, "day", d_lite_mday, 0);
    rb_define_method(cDate, "day_fraction", d_lite_day_fraction, 0);

    rb_define_method(cDate, "cwyear", d_lite_cwyear, 0);
    rb_define_method(cDate, "cweek", d_lite_cweek, 0);
    rb_define_method(cDate, "cwday", d_lite_cwday, 0);

#ifndef NDEBUG
    rb_define_private_method(cDate, "wnum0", d_lite_wnum0, 0);
    rb_define_private_method(cDate, "wnum1", d_lite_wnum1, 0);
#endif

    rb_define_method(cDate, "wday", d_lite_wday, 0);

    rb_define_method(cDate, "sunday?", d_lite_sunday_p, 0);
    rb_define_method(cDate, "monday?", d_lite_monday_p, 0);
    rb_define_method(cDate, "tuesday?", d_lite_tuesday_p, 0);
    rb_define_method(cDate, "wednesday?", d_lite_wednesday_p, 0);
    rb_define_method(cDate, "thursday?", d_lite_thursday_p, 0);
    rb_define_method(cDate, "friday?", d_lite_friday_p, 0);
    rb_define_method(cDate, "saturday?", d_lite_saturday_p, 0);

#ifndef NDEBUG
    rb_define_method(cDate, "nth_kday?", d_lite_nth_kday_p, 2);
#endif

    rb_define_private_method(cDate, "hour", d_lite_zero, 0);
    rb_define_private_method(cDate, "min", d_lite_zero, 0);
    rb_define_private_method(cDate, "minute", d_lite_zero, 0);
    rb_define_private_method(cDate, "sec", d_lite_zero, 0);
    rb_define_private_method(cDate, "second", d_lite_zero, 0);

    rb_define_method(cDate, "julian?", d_lite_julian_p, 0);
    rb_define_method(cDate, "gregorian?", d_lite_gregorian_p, 0);
    rb_define_method(cDate, "leap?", d_lite_leap_p, 0);

    rb_define_method(cDate, "start", d_lite_start, 0);
    rb_define_method(cDate, "new_start", d_lite_new_start, -1);
    rb_define_method(cDate, "italy", d_lite_italy, 0);
    rb_define_method(cDate, "england", d_lite_england, 0);
    rb_define_method(cDate, "julian", d_lite_julian, 0);
    rb_define_method(cDate, "gregorian", d_lite_gregorian, 0);

    rb_define_method(cDate, "+", d_lite_plus, 1);
    rb_define_method(cDate, "-", d_lite_minus, 1);

    rb_define_method(cDate, "next_day", d_lite_next_day, -1);
    rb_define_method(cDate, "prev_day", d_lite_prev_day, -1);
    rb_define_method(cDate, "next", d_lite_next, 0);
    rb_define_method(cDate, "succ", d_lite_next, 0);

    rb_define_method(cDate, ">>", d_lite_rshift, 1);
    rb_define_method(cDate, "<<", d_lite_lshift, 1);

    rb_define_method(cDate, "next_month", d_lite_next_month, -1);
    rb_define_method(cDate, "prev_month", d_lite_prev_month, -1);
    rb_define_method(cDate, "next_year", d_lite_next_year, -1);
    rb_define_method(cDate, "prev_year", d_lite_prev_year, -1);

    rb_define_method(cDate, "step", d_lite_step, -1);
    rb_define_method(cDate, "upto", d_lite_upto, 1);
    rb_define_method(cDate, "downto", d_lite_downto, 1);

    rb_define_method(cDate, "<=>", d_lite_cmp, 1);
    rb_define_method(cDate, "===", d_lite_equal, 1);
    rb_define_method(cDate, "eql?", d_lite_eql_p, 1);
    rb_define_method(cDate, "hash", d_lite_hash, 0);

    rb_define_method(cDate, "to_s", d_lite_to_s, 0);
#ifndef NDEBUG
    rb_define_method(cDate, "inspect_raw", d_lite_inspect_raw, 0);
#endif
    rb_define_method(cDate, "inspect", d_lite_inspect, 0);

    rb_define_method(cDate, "strftime", d_lite_strftime, -1);

    rb_define_method(cDate, "asctime", d_lite_asctime, 0);
    rb_define_method(cDate, "ctime", d_lite_asctime, 0);
    rb_define_method(cDate, "iso8601", d_lite_iso8601, 0);
    rb_define_method(cDate, "xmlschema", d_lite_iso8601, 0);
    rb_define_method(cDate, "rfc3339", d_lite_rfc3339, 0);
    rb_define_method(cDate, "rfc2822", d_lite_rfc2822, 0);
    rb_define_method(cDate, "rfc822", d_lite_rfc2822, 0);
    rb_define_method(cDate, "httpdate", d_lite_httpdate, 0);
    rb_define_method(cDate, "jisx0301", d_lite_jisx0301, 0);

    rb_define_method(cDate, "deconstruct_keys", d_lite_deconstruct_keys, 1);

#ifndef NDEBUG
    rb_define_method(cDate, "marshal_dump_old", d_lite_marshal_dump_old, 0);
#endif
    rb_define_method(cDate, "marshal_dump", d_lite_marshal_dump, 0);
    rb_define_method(cDate, "marshal_load", d_lite_marshal_load, 1);
    rb_define_singleton_method(cDate, "_load", date_s__load, 1);

    /*
     * == DateTime
     *
     * A subclass of Date that easily handles date, hour, minute, second,
     * and offset.
     *
     * DateTime class is considered deprecated. Use Time class.
     *
     * DateTime does not consider any leap seconds, does not track
     * any summer time rules.
     *
     * A DateTime object is created with DateTime::new, DateTime::jd,
     * DateTime::ordinal, DateTime::commercial, DateTime::parse,
     * DateTime::strptime, DateTime::now, Time#to_datetime, etc.
     *
     *     require 'date'
     *
     *     DateTime.new(2001,2,3,4,5,6)
     *                         #=> #<DateTime: 2001-02-03T04:05:06+00:00 ...>
     *
     * The last element of day, hour, minute, or second can be a
     * fractional number. The fractional number's precision is assumed
     * at most nanosecond.
     *
     *     DateTime.new(2001,2,3.5)
     *                         #=> #<DateTime: 2001-02-03T12:00:00+00:00 ...>
     *
     * An optional argument, the offset, indicates the difference
     * between the local time and UTC. For example, <tt>Rational(3,24)</tt>
     * represents ahead of 3 hours of UTC, <tt>Rational(-5,24)</tt> represents
     * behind of 5 hours of UTC. The offset should be -1 to +1, and
     * its precision is assumed at most second. The default value is
     * zero (equals to UTC).
     *
     *     DateTime.new(2001,2,3,4,5,6,Rational(3,24))
     *                         #=> #<DateTime: 2001-02-03T04:05:06+03:00 ...>
     *
     * The offset also accepts string form:
     *
     *     DateTime.new(2001,2,3,4,5,6,'+03:00')
     *                         #=> #<DateTime: 2001-02-03T04:05:06+03:00 ...>
     *
     * An optional argument, the day of calendar reform (+start+), denotes
     * a Julian day number, which should be 2298874 to 2426355 or
     * negative/positive infinity.
     * The default value is +Date::ITALY+ (2299161=1582-10-15).
     *
     * A DateTime object has various methods. See each reference.
     *
     *     d = DateTime.parse('3rd Feb 2001 04:05:06+03:30')
     *                         #=> #<DateTime: 2001-02-03T04:05:06+03:30 ...>
     *     d.hour              #=> 4
     *     d.min               #=> 5
     *     d.sec               #=> 6
     *     d.offset            #=> (7/48)
     *     d.zone              #=> "+03:30"
     *     d += Rational('1.5')
     *                         #=> #<DateTime: 2001-02-04%16:05:06+03:30 ...>
     *     d = d.new_offset('+09:00')
     *                         #=> #<DateTime: 2001-02-04%21:35:06+09:00 ...>
     *     d.strftime('%I:%M:%S %p')
     *                         #=> "09:35:06 PM"
     *     d > DateTime.new(1999)
     *                         #=> true
     *
     * === When should you use DateTime and when should you use Time?
     *
     * It's a common misconception that
     * {William Shakespeare}[https://en.wikipedia.org/wiki/William_Shakespeare]
     * and
     * {Miguel de Cervantes}[https://en.wikipedia.org/wiki/Miguel_de_Cervantes]
     * died on the same day in history -
     * so much so that UNESCO named April 23 as
     * {World Book Day because of this fact}[https://en.wikipedia.org/wiki/World_Book_Day].
     * However, because England hadn't yet adopted the
     * {Gregorian Calendar Reform}[https://en.wikipedia.org/wiki/Gregorian_calendar#Gregorian_reform]
     * (and wouldn't until {1752}[https://en.wikipedia.org/wiki/Calendar_(New_Style)_Act_1750])
     * their deaths are actually 10 days apart.
     * Since Ruby's Time class implements a
     * {proleptic Gregorian calendar}[https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar]
     * and has no concept of calendar reform there's no way
     * to express this with Time objects. This is where DateTime steps in:
     *
     *     shakespeare = DateTime.iso8601('1616-04-23', Date::ENGLAND)
     *      #=> Tue, 23 Apr 1616 00:00:00 +0000
     *     cervantes = DateTime.iso8601('1616-04-23', Date::ITALY)
     *      #=> Sat, 23 Apr 1616 00:00:00 +0000
     *
     * Already you can see something is weird - the days of the week
     * are different. Taking this further:
     *
     *     cervantes == shakespeare
     *      #=> false
     *     (shakespeare - cervantes).to_i
     *      #=> 10
     *
     * This shows that in fact they died 10 days apart (in reality
     * 11 days since Cervantes died a day earlier but was buried on
     * the 23rd). We can see the actual date of Shakespeare's death by
     * using the #gregorian method to convert it:
     *
     *     shakespeare.gregorian
     *      #=> Tue, 03 May 1616 00:00:00 +0000
     *
     * So there's an argument that all the celebrations that take
     * place on the 23rd April in Stratford-upon-Avon are actually
     * the wrong date since England is now using the Gregorian calendar.
     * You can see why when we transition across the reform
     * date boundary:
     *
     *     # start off with the anniversary of Shakespeare's birth in 1751
     *     shakespeare = DateTime.iso8601('1751-04-23', Date::ENGLAND)
     *      #=> Tue, 23 Apr 1751 00:00:00 +0000
     *
     *     # add 366 days since 1752 is a leap year and April 23 is after February 29
     *     shakespeare + 366
     *      #=> Thu, 23 Apr 1752 00:00:00 +0000
     *
     *     # add another 365 days to take us to the anniversary in 1753
     *     shakespeare + 366 + 365
     *      #=> Fri, 04 May 1753 00:00:00 +0000
     *
     * As you can see, if we're accurately tracking the number of
     * {solar years}[https://en.wikipedia.org/wiki/Tropical_year]
     * since Shakespeare's birthday then the correct anniversary date
     * would be the 4th May and not the 23rd April.
     *
     * So when should you use DateTime in Ruby and when should
     * you use Time? Almost certainly you'll want to use Time
     * since your app is probably dealing with current dates and
     * times. However, if you need to deal with dates and times in a
     * historical context you'll want to use DateTime to avoid
     * making the same mistakes as UNESCO. If you also have to deal
     * with timezones then best of luck - just bear in mind that
     * you'll probably be dealing with
     * {local solar times}[https://en.wikipedia.org/wiki/Solar_time],
     * since it wasn't until the 19th century that the introduction
     * of the railways necessitated the need for
     * {Standard Time}[https://en.wikipedia.org/wiki/Standard_time#Great_Britain]
     * and eventually timezones.
     */

    cDateTime = rb_define_class("DateTime", cDate);
    rb_define_alloc_func(cDateTime, d_lite_s_alloc_complex);

    rb_define_singleton_method(cDateTime, "jd", datetime_s_jd, -1);
    rb_define_singleton_method(cDateTime, "ordinal", datetime_s_ordinal, -1);
    rb_define_singleton_method(cDateTime, "civil", datetime_s_civil, -1);
    rb_define_singleton_method(cDateTime, "new", datetime_s_civil, -1);
    rb_define_singleton_method(cDateTime, "commercial",
			       datetime_s_commercial, -1);

#ifndef NDEBUG
    rb_define_singleton_method(cDateTime, "weeknum",
			       datetime_s_weeknum, -1);
    rb_define_singleton_method(cDateTime, "nth_kday",
			       datetime_s_nth_kday, -1);
#endif

    rb_undef_method(CLASS_OF(cDateTime), "today");

    rb_define_singleton_method(cDateTime, "now", datetime_s_now, -1);
    rb_define_singleton_method(cDateTime, "_strptime",
			       datetime_s__strptime, -1);
    rb_define_singleton_method(cDateTime, "strptime",
			       datetime_s_strptime, -1);
    rb_define_singleton_method(cDateTime, "parse",
			       datetime_s_parse, -1);
    rb_define_singleton_method(cDateTime, "iso8601",
			       datetime_s_iso8601, -1);
    rb_define_singleton_method(cDateTime, "rfc3339",
			       datetime_s_rfc3339, -1);
    rb_define_singleton_method(cDateTime, "xmlschema",
			       datetime_s_xmlschema, -1);
    rb_define_singleton_method(cDateTime, "rfc2822",
			       datetime_s_rfc2822, -1);
    rb_define_singleton_method(cDateTime, "rfc822",
			       datetime_s_rfc2822, -1);
    rb_define_singleton_method(cDateTime, "httpdate",
			       datetime_s_httpdate, -1);
    rb_define_singleton_method(cDateTime, "jisx0301",
			       datetime_s_jisx0301, -1);

    rb_define_method(cDateTime, "hour", d_lite_hour, 0);
    rb_define_method(cDateTime, "min", d_lite_min, 0);
    rb_define_method(cDateTime, "minute", d_lite_min, 0);
    rb_define_method(cDateTime, "sec", d_lite_sec, 0);
    rb_define_method(cDateTime, "second", d_lite_sec, 0);
    rb_define_method(cDateTime, "sec_fraction", d_lite_sec_fraction, 0);
    rb_define_method(cDateTime, "second_fraction", d_lite_sec_fraction, 0);
    rb_define_method(cDateTime, "offset", d_lite_offset, 0);
    rb_define_method(cDateTime, "zone", d_lite_zone, 0);
    rb_define_method(cDateTime, "new_offset", d_lite_new_offset, -1);

    rb_define_method(cDateTime, "to_s", dt_lite_to_s, 0);

    rb_define_method(cDateTime, "strftime", dt_lite_strftime, -1);

    rb_define_method(cDateTime, "iso8601", dt_lite_iso8601, -1);
    rb_define_method(cDateTime, "xmlschema", dt_lite_iso8601, -1);
    rb_define_method(cDateTime, "rfc3339", dt_lite_rfc3339, -1);
    rb_define_method(cDateTime, "jisx0301", dt_lite_jisx0301, -1);

    rb_define_method(cDateTime, "deconstruct_keys", dt_lite_deconstruct_keys, 1);

    /* conversions */

    rb_define_method(rb_cTime, "to_time", time_to_time, 0);
    rb_define_method(rb_cTime, "to_date", time_to_date, 0);
    rb_define_method(rb_cTime, "to_datetime", time_to_datetime, 0);

    rb_define_method(cDate, "to_time", date_to_time, 0);
    rb_define_method(cDate, "to_date", date_to_date, 0);
    rb_define_method(cDate, "to_datetime", date_to_datetime, 0);

    rb_define_method(cDateTime, "to_time", datetime_to_time, 0);
    rb_define_method(cDateTime, "to_date", datetime_to_date, 0);
    rb_define_method(cDateTime, "to_datetime", datetime_to_datetime, 0);

#ifndef NDEBUG
    /* tests */

    rb_define_singleton_method(cDate, "test_civil", date_s_test_civil, 0);
    rb_define_singleton_method(cDate, "test_ordinal", date_s_test_ordinal, 0);
    rb_define_singleton_method(cDate, "test_commercial",
			       date_s_test_commercial, 0);
    rb_define_singleton_method(cDate, "test_weeknum", date_s_test_weeknum, 0);
    rb_define_singleton_method(cDate, "test_nth_kday", date_s_test_nth_kday, 0);
    rb_define_singleton_method(cDate, "test_unit_conv",
			       date_s_test_unit_conv, 0);
    rb_define_singleton_method(cDate, "test_all", date_s_test_all, 0);
#endif
}

/*
Local variables:
c-file-style: "ruby"
End:
*/
