/*
 *
 * Ruby BigDecimal(Variable decimal precision) extension library.
 *
 * Copyright(C) 2002 by Shigeo Kobayashi(shigeo@tinyforest.gr.jp)
 *
 */

#ifndef  RUBY_BIG_DECIMAL_H
#define  RUBY_BIG_DECIMAL_H 1

#define RUBY_NO_OLD_COMPATIBILITY
#include "ruby/ruby.h"
#include "missing.h"

#ifdef HAVE_FLOAT_H
# include <float.h>
#endif

#ifdef HAVE_INT64_T
# define DECDIG uint32_t
# define DECDIG_DBL uint64_t
# define DECDIG_DBL_SIGNED int64_t
# define SIZEOF_DECDIG 4
# define PRI_DECDIG_PREFIX ""
# ifdef PRI_LL_PREFIX
#  define PRI_DECDIG_DBL_PREFIX PRI_LL_PREFIX
# else
#  define PRI_DECDIG_DBL_PREFIX "l"
# endif
#else
# define DECDIG uint16_t
# define DECDIG_DBL uint32_t
# define DECDIG_DBL_SIGNED int32_t
# define SIZEOF_DECDIG 2
# define PRI_DECDIG_PREFIX "h"
# define PRI_DECDIG_DBL_PREFIX ""
#endif

#define PRIdDECDIG PRI_DECDIG_PREFIX"d"
#define PRIiDECDIG PRI_DECDIG_PREFIX"i"
#define PRIoDECDIG PRI_DECDIG_PREFIX"o"
#define PRIuDECDIG PRI_DECDIG_PREFIX"u"
#define PRIxDECDIG PRI_DECDIG_PREFIX"x"
#define PRIXDECDIG PRI_DECDIG_PREFIX"X"

#define PRIdDECDIG_DBL PRI_DECDIG_DBL_PREFIX"d"
#define PRIiDECDIG_DBL PRI_DECDIG_DBL_PREFIX"i"
#define PRIoDECDIG_DBL PRI_DECDIG_DBL_PREFIX"o"
#define PRIuDECDIG_DBL PRI_DECDIG_DBL_PREFIX"u"
#define PRIxDECDIG_DBL PRI_DECDIG_DBL_PREFIX"x"
#define PRIXDECDIG_DBL PRI_DECDIG_DBL_PREFIX"X"

#if SIZEOF_DECDIG == 4
# define BIGDECIMAL_BASE ((DECDIG)1000000000U)
# define BIGDECIMAL_COMPONENT_FIGURES 9
/*
 * The number of components required for a 64-bit integer.
 *
 *   INT64_MAX:   9_223372036_854775807
 *   UINT64_MAX: 18_446744073_709551615
 */
# define BIGDECIMAL_INT64_MAX_LENGTH 3

#elif SIZEOF_DECDIG == 2
# define BIGDECIMAL_BASE ((DECDIG)10000U)
# define BIGDECIMAL_COMPONENT_FIGURES 4
/*
 * The number of components required for a 64-bit integer.
 *
 *   INT64_MAX:   922_3372_0368_5477_5807
 *   UINT64_MAX: 1844_6744_0737_0955_1615
 */
# define BIGDECIMAL_INT64_MAX_LENGTH 5

#else
# error Unknown size of DECDIG
#endif

#define BIGDECIMAL_DOUBLE_FIGURES (1+DBL_DIG)

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

extern VALUE rb_cBigDecimal;

/*
 *  NaN & Infinity
 */
#define SZ_NaN  "NaN"
#define SZ_INF  "Infinity"
#define SZ_PINF "+Infinity"
#define SZ_NINF "-Infinity"

/*
 *   #define VP_EXPORT other than static to let VP_ routines
 *   be called from outside of this module.
 */
#define VP_EXPORT static

/* Exception mode */
#define VP_EXCEPTION_ALL        ((unsigned short)0x00FF)
#define VP_EXCEPTION_INFINITY   ((unsigned short)0x0001)
#define VP_EXCEPTION_NaN        ((unsigned short)0x0002)
#define VP_EXCEPTION_UNDERFLOW  ((unsigned short)0x0004)
#define VP_EXCEPTION_OVERFLOW   ((unsigned short)0x0001) /* 0x0008) */
#define VP_EXCEPTION_ZERODIVIDE ((unsigned short)0x0010)

/* Following 2 exceptions can't controlled by user */
#define VP_EXCEPTION_OP         ((unsigned short)0x0020)

#define BIGDECIMAL_EXCEPTION_MODE_DEFAULT 0U

/* This is used in BigDecimal#mode */
#define VP_ROUND_MODE            ((unsigned short)0x0100)

/* Rounding mode */
#define VP_ROUND_UP         RBD_ROUND_UP
#define VP_ROUND_DOWN       RBD_ROUND_DOWN
#define VP_ROUND_HALF_UP    RBD_ROUND_HALF_UP
#define VP_ROUND_HALF_DOWN  RBD_ROUND_HALF_DOWN
#define VP_ROUND_CEIL       RBD_ROUND_CEIL
#define VP_ROUND_FLOOR      RBD_ROUND_FLOOR
#define VP_ROUND_HALF_EVEN  RBD_ROUND_HALF_EVEN

enum rbd_rounding_mode {
    RBD_ROUND_UP          = 1,
    RBD_ROUND_DOWN        = 2,
    RBD_ROUND_HALF_UP     = 3,
    RBD_ROUND_HALF_DOWN   = 4,
    RBD_ROUND_CEIL        = 5,
    RBD_ROUND_FLOOR       = 6,
    RBD_ROUND_HALF_EVEN   = 7,

    RBD_ROUND_DEFAULT  = RBD_ROUND_HALF_UP,
    RBD_ROUND_TRUNCATE = RBD_ROUND_DOWN,
    RBD_ROUND_BANKER   = RBD_ROUND_HALF_EVEN,
    RBD_ROUND_CEILING  = RBD_ROUND_CEIL
};

#define BIGDECIMAL_ROUNDING_MODE_DEFAULT  VP_ROUND_HALF_UP

/* Sign flag */
#define VP_SIGN_NaN                0 /* NaN                      */
#define VP_SIGN_POSITIVE_ZERO      1 /* Positive zero            */
#define VP_SIGN_NEGATIVE_ZERO     -1 /* Negative zero            */
#define VP_SIGN_POSITIVE_FINITE    2 /* Positive finite number   */
#define VP_SIGN_NEGATIVE_FINITE   -2 /* Negative finite number   */
#define VP_SIGN_POSITIVE_INFINITE  3 /* Positive infinite number */
#define VP_SIGN_NEGATIVE_INFINITE -3 /* Negative infinite number */

/* The size of fraction part array */
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L)
#define	FLEXIBLE_ARRAY_SIZE /* */
#elif defined(__GNUC__) && !defined(__STRICT_ANSI__)
#define	FLEXIBLE_ARRAY_SIZE 0
#else
#define	FLEXIBLE_ARRAY_SIZE 1
#endif

/*
 * VP representation
 *  r = 0.xxxxxxxxx *BASE**exponent
 */
typedef struct {
    VALUE  obj;     /* Back pointer(VALUE) for Ruby object.     */
    size_t MaxPrec; /* Maximum precision size                   */
                    /* This is the actual size of frac[]        */
                    /*(frac[0] to frac[MaxPrec] are available). */
    size_t Prec;    /* Current precision size.                  */
                    /* This indicates how much the              */
                    /* array frac[] is actually used.           */
    SIGNED_VALUE exponent; /* Exponent part.                    */
    short  sign;    /* Attributes of the value.                 */
                    /*
                     *        ==0 : NaN
                     *          1 : Positive zero
                     *         -1 : Negative zero
                     *          2 : Positive number
                     *         -2 : Negative number
                     *          3 : Positive infinite number
                     *         -3 : Negative infinite number
                     */
    short  flag;    /* Not used in vp_routines,space for user.  */
    DECDIG frac[FLEXIBLE_ARRAY_SIZE]; /* Array of fraction part. */
} Real;

/*
 *  ------------------
 *   EXPORTables.
 *  ------------------
 */

VP_EXPORT Real *VpNewRbClass(size_t mx, char const *str, VALUE klass, bool strict_p, bool raise_exception);

VP_EXPORT Real *VpCreateRbObject(size_t mx, const char *str, bool raise_exception);

#define VpBaseFig() BIGDECIMAL_COMPONENT_FIGURES
#define VpDblFig() BIGDECIMAL_DOUBLE_FIGURES
#define VpBaseVal() BIGDECIMAL_BASE

/* Zero,Inf,NaN (isinf(),isnan() used to check) */
VP_EXPORT double VpGetDoubleNaN(void);
VP_EXPORT double VpGetDoublePosInf(void);
VP_EXPORT double VpGetDoubleNegInf(void);
VP_EXPORT double VpGetDoubleNegZero(void);

/* These 2 functions added at v1.1.7 */
VP_EXPORT size_t VpGetPrecLimit(void);
VP_EXPORT size_t VpSetPrecLimit(size_t n);

/* Round mode */
VP_EXPORT int            VpIsRoundMode(unsigned short n);
VP_EXPORT unsigned short VpGetRoundMode(void);
VP_EXPORT unsigned short VpSetRoundMode(unsigned short n);

VP_EXPORT int VpException(unsigned short f,const char *str,int always);
#if 0  /* unused */
VP_EXPORT int VpIsNegDoubleZero(double v);
#endif
VP_EXPORT size_t VpNumOfChars(Real *vp,const char *pszFmt);
VP_EXPORT size_t VpInit(DECDIG BaseVal);
VP_EXPORT Real *VpAlloc(size_t mx, const char *szVal, int strict_p, int exc);
VP_EXPORT size_t VpAsgn(Real *c, Real *a, int isw);
VP_EXPORT size_t VpAddSub(Real *c,Real *a,Real *b,int operation);
VP_EXPORT size_t VpMult(Real *c,Real *a,Real *b);
VP_EXPORT size_t VpDivd(Real *c,Real *r,Real *a,Real *b);
VP_EXPORT int VpComp(Real *a,Real *b);
VP_EXPORT ssize_t VpExponent10(Real *a);
VP_EXPORT void VpSzMantissa(Real *a, char *buf, size_t bufsize);
VP_EXPORT int VpToSpecialString(Real *a, char *buf, size_t bufsize, int fPlus);
VP_EXPORT void VpToString(Real *a, char *buf, size_t bufsize, size_t fFmt, int fPlus);
VP_EXPORT void VpToFString(Real *a, char *buf, size_t bufsize, size_t fFmt, int fPlus);
VP_EXPORT int VpCtoV(Real *a, const char *int_chr, size_t ni, const char *frac, size_t nf, const char *exp_chr, size_t ne);
VP_EXPORT int VpVtoD(double *d, SIGNED_VALUE *e, Real *m);
VP_EXPORT void VpDtoV(Real *m,double d);
#if 0  /* unused */
VP_EXPORT void VpItoV(Real *m,S_INT ival);
#endif
VP_EXPORT int VpSqrt(Real *y,Real *x);
VP_EXPORT int VpActiveRound(Real *y, Real *x, unsigned short f, ssize_t il);
VP_EXPORT int VpMidRound(Real *y, unsigned short f, ssize_t nf);
VP_EXPORT int VpLeftRound(Real *y, unsigned short f, ssize_t nf);
VP_EXPORT void VpFrac(Real *y, Real *x);
VP_EXPORT int VpPowerByInt(Real *y, Real *x, SIGNED_VALUE n);
#define VpPower VpPowerByInt

/* VP constants */
VP_EXPORT Real *VpOne(void);

/*
 *  ------------------
 *  MACRO definitions.
 *  ------------------
 */
#define Abs(a)     (((a)>= 0)?(a):(-(a)))
#define Max(a, b)  (((a)>(b))?(a):(b))
#define Min(a, b)  (((a)>(b))?(b):(a))

#define VpMaxPrec(a)   ((a)->MaxPrec)
#define VpPrec(a)      ((a)->Prec)
#define VpGetFlag(a)   ((a)->flag)

/* Sign */

/* VpGetSign(a) returns 1,-1 if a>0,a<0 respectively */
#define VpGetSign(a) (((a)->sign>0)?1:(-1))
/* Change sign of a to a>0,a<0 if s = 1,-1 respectively */
#define VpChangeSign(a,s) {if((s)>0) (a)->sign=(short)Abs((ssize_t)(a)->sign);else (a)->sign=-(short)Abs((ssize_t)(a)->sign);}
/* Sets sign of a to a>0,a<0 if s = 1,-1 respectively */
#define VpSetSign(a,s)    {if((s)>0) (a)->sign=(short)VP_SIGN_POSITIVE_FINITE;else (a)->sign=(short)VP_SIGN_NEGATIVE_FINITE;}

/* 1 */
#define VpSetOne(a)       {(a)->Prec=(a)->exponent=(a)->frac[0]=1;(a)->sign=VP_SIGN_POSITIVE_FINITE;}

/* ZEROs */
#define VpIsPosZero(a)  ((a)->sign==VP_SIGN_POSITIVE_ZERO)
#define VpIsNegZero(a)  ((a)->sign==VP_SIGN_NEGATIVE_ZERO)
#define VpIsZero(a)     (VpIsPosZero(a) || VpIsNegZero(a))
#define VpSetPosZero(a) ((a)->frac[0]=0,(a)->Prec=1,(a)->sign=VP_SIGN_POSITIVE_ZERO)
#define VpSetNegZero(a) ((a)->frac[0]=0,(a)->Prec=1,(a)->sign=VP_SIGN_NEGATIVE_ZERO)
#define VpSetZero(a,s)  (void)(((s)>0)?VpSetPosZero(a):VpSetNegZero(a))

/* NaN */
#define VpIsNaN(a)      ((a)->sign==VP_SIGN_NaN)
#define VpSetNaN(a)     ((a)->frac[0]=0,(a)->Prec=1,(a)->sign=VP_SIGN_NaN)

/* Infinity */
#define VpIsPosInf(a)   ((a)->sign==VP_SIGN_POSITIVE_INFINITE)
#define VpIsNegInf(a)   ((a)->sign==VP_SIGN_NEGATIVE_INFINITE)
#define VpIsInf(a)      (VpIsPosInf(a) || VpIsNegInf(a))
#define VpIsDef(a)      ( !(VpIsNaN(a)||VpIsInf(a)) )
#define VpSetPosInf(a)  ((a)->frac[0]=0,(a)->Prec=1,(a)->sign=VP_SIGN_POSITIVE_INFINITE)
#define VpSetNegInf(a)  ((a)->frac[0]=0,(a)->Prec=1,(a)->sign=VP_SIGN_NEGATIVE_INFINITE)
#define VpSetInf(a,s)   (void)(((s)>0)?VpSetPosInf(a):VpSetNegInf(a))
#define VpHasVal(a)     (a->frac[0])
#define VpIsOne(a)      ((a->Prec==1)&&(a->frac[0]==1)&&(a->exponent==1))
#define VpExponent(a)   (a->exponent)
#ifdef BIGDECIMAL_DEBUG
int VpVarCheck(Real * v);
#endif /* BIGDECIMAL_DEBUG */

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
}  /* extern "C" { */
#endif
#endif /* RUBY_BIG_DECIMAL_H */
