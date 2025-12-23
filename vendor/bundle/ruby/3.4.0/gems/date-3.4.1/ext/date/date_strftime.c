/*
  date_strftime.c: based on a public-domain implementation of ANSI C
  library routine strftime, which is originally written by Arnold
  Robbins.
 */

#include "ruby/ruby.h"
#include "date_tmx.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>

#if defined(HAVE_SYS_TIME_H)
#include <sys/time.h>
#endif

#undef strchr	/* avoid AIX weirdness */

#define range(low, item, hi)	(item)

#define add(x,y) (rb_funcall((x), '+', 1, (y)))
#define sub(x,y) (rb_funcall((x), '-', 1, (y)))
#define mul(x,y) (rb_funcall((x), '*', 1, (y)))
#define quo(x,y) (rb_funcall((x), rb_intern("quo"), 1, (y)))
#define div(x,y) (rb_funcall((x), rb_intern("div"), 1, (y)))
#define mod(x,y) (rb_funcall((x), '%', 1, (y)))

static void
upcase(char *s, size_t i)
{
    do {
	if (ISLOWER(*s))
	    *s = TOUPPER(*s);
    } while (s++, --i);
}

static void
downcase(char *s, size_t i)
{
    do {
	if (ISUPPER(*s))
	    *s = TOLOWER(*s);
    } while (s++, --i);
}

/* strftime --- produce formatted time */

static size_t
date_strftime_with_tmx(char *s, const size_t maxsize, const char *format,
		       const struct tmx *tmx)
{
    char *endp = s + maxsize;
    char *start = s;
    const char *sp, *tp;
    auto char tbuf[100];
    ptrdiff_t i;
    int v, w;
    size_t colons;
    int precision, flags;
    char padding;
    /* LOCALE_[OE] and COLONS are actually modifiers, not flags */
    enum {LEFT, CHCASE, LOWER, UPPER, LOCALE_O, LOCALE_E, COLONS};
#define BIT_OF(n) (1U<<(n))

    /* various tables for locale C */
    static const char days_l[][10] = {
	"Sunday", "Monday", "Tuesday", "Wednesday",
	"Thursday", "Friday", "Saturday",
    };
    static const char months_l[][10] = {
	"January", "February", "March", "April",
	"May", "June", "July", "August", "September",
	"October", "November", "December",
    };
    static const char ampm[][3] = { "AM", "PM", };

    if (s == NULL || format == NULL || tmx == NULL || maxsize == 0)
	return 0;

    /* quick check if we even need to bother */
    if (strchr(format, '%') == NULL && strlen(format) + 1 >= maxsize) {
      err:
	errno = ERANGE;
	return 0;
    }

    for (; *format && s < endp - 1; format++) {
#define FLAG_FOUND() do {						\
	    if (precision > 0 || flags & (BIT_OF(LOCALE_E) | BIT_OF(LOCALE_O) | BIT_OF(COLONS))) \
		goto unknown;						\
	} while (0)
#define NEEDS(n) do if (s >= endp || (n) >= endp - s - 1) goto err; while (0)
#define FILL_PADDING(i) do {						\
	    if (!(flags & BIT_OF(LEFT)) && precision > (i)) {		\
		NEEDS(precision);					\
		memset(s, padding ? padding : ' ', precision - (i));	\
		s += precision - (i);					\
	    }								\
	    else {							\
		NEEDS(i);						\
	    }								\
	} while (0);
#define FMT(def_pad, def_prec, fmt, val)				\
	do {								\
	    int l;							\
	    if (precision <= 0) precision = (def_prec);			\
	    if (flags & BIT_OF(LEFT)) precision = 1;			\
	    l = snprintf(s, endp - s,					\
			 ((padding == '0' || (!padding && (def_pad) == '0')) ? \
			  "%0*"fmt : "%*"fmt),				\
			 precision, (val));				\
	    if (l < 0) goto err;					\
	    s += l;							\
	} while (0)
#define STRFTIME(fmt)							\
	do {								\
	    i = date_strftime_with_tmx(s, endp - s, (fmt), tmx);	\
	    if (!i) return 0;						\
	    if (flags & BIT_OF(UPPER))					\
		upcase(s, i);						\
	    if (!(flags & BIT_OF(LEFT)) && precision > i) {		\
		if (start + maxsize < s + precision) {			\
		    errno = ERANGE;					\
		    return 0;						\
		}							\
		memmove(s + precision - i, s, i);			\
		memset(s, padding ? padding : ' ', precision - i);	\
		s += precision;						\
	    }								\
	    else s += i;						\
	} while (0)
#define FMTV(def_pad, def_prec, fmt, val)				\
	do {								\
	    VALUE tmp = (val);						\
	    if (FIXNUM_P(tmp)) {					\
		FMT((def_pad), (def_prec), "l"fmt, FIX2LONG(tmp));	\
	    }								\
	    else {							\
		VALUE args[2], result;					\
		size_t l;						\
		if (precision <= 0) precision = (def_prec);		\
		if (flags & BIT_OF(LEFT)) precision = 1;		\
		args[0] = INT2FIX(precision);				\
		args[1] = (val);					\
		if (padding == '0' || (!padding && (def_pad) == '0'))	\
		    result = rb_str_format(2, args, rb_str_new2("%0*"fmt)); \
		else							\
		    result = rb_str_format(2, args, rb_str_new2("%*"fmt)); \
		l = strlcpy(s, StringValueCStr(result), endp - s);	\
		if ((size_t)(endp - s) <= l)				\
		    goto err;						\
		s += l;							\
	    }								\
	} while (0)

	if (*format != '%') {
	    *s++ = *format;
	    continue;
	}
	tp = tbuf;
	sp = format;
	precision = -1;
	flags = 0;
	padding = 0;
	colons = 0;
      again:
	switch (*++format) {
	  case '\0':
	    format--;
	    goto unknown;

	  case 'A':	/* full weekday name */
	  case 'a':	/* abbreviated weekday name */
	    if (flags & BIT_OF(CHCASE)) {
		flags &= ~(BIT_OF(LOWER) | BIT_OF(CHCASE));
		flags |= BIT_OF(UPPER);
	    }
	    {
		int wday = tmx_wday;
		if (wday < 0 || wday > 6)
		    i = 1, tp = "?";
		else {
		    if (*format == 'A')
			i = strlen(tp = days_l[wday]);
		    else
			i = 3, tp = days_l[wday];
		}
	    }
	    break;

	  case 'B':	/* full month name */
	  case 'b':	/* abbreviated month name */
	  case 'h':	/* same as %b */
	    if (flags & BIT_OF(CHCASE)) {
		flags &= ~(BIT_OF(LOWER) | BIT_OF(CHCASE));
		flags |= BIT_OF(UPPER);
	    }
	    {
		int mon = tmx_mon;
		if (mon < 1 || mon > 12)
		    i = 1, tp = "?";
		else {
		    if (*format == 'B')
			i = strlen(tp = months_l[mon - 1]);
		    else
			i = 3, tp = months_l[mon - 1];
		}
	    }
	    break;

	  case 'C':	/* century (year/100) */
	    FMTV('0', 2, "d", div(tmx_year, INT2FIX(100)));
	    continue;

	  case 'c':	/* appropriate date and time representation */
	    STRFTIME("%a %b %e %H:%M:%S %Y");
	    continue;

	  case 'D':
	    STRFTIME("%m/%d/%y");
	    continue;

	  case 'd':	/* day of the month, 01 - 31 */
	  case 'e':	/* day of month, blank padded */
	    v = range(1, tmx_mday, 31);
	    FMT((*format == 'd') ? '0' : ' ', 2, "d", v);
	    continue;

	  case 'F':
	    STRFTIME("%Y-%m-%d");
	    continue;

	  case 'G':	/* year of ISO week with century */
	  case 'Y':	/* year with century */
	    {
		VALUE year = (*format == 'G') ? tmx_cwyear : tmx_year;
		if (FIXNUM_P(year)) {
		    long y = FIX2LONG(year);
		    FMT('0', 0 <= y ? 4 : 5, "ld", y);
		}
		else {
		    FMTV('0', 4, "d", year);
		}
	    }
	    continue;

	  case 'g':	/* year of ISO week without a century */
	  case 'y':	/* year without a century */
	    v = NUM2INT(mod((*format == 'g') ? tmx_cwyear : tmx_year, INT2FIX(100)));
	    FMT('0', 2, "d", v);
	    continue;

	  case 'H':	/* hour, 24-hour clock, 00 - 23 */
	  case 'k':	/* hour, 24-hour clock, blank pad */
	    v = range(0, tmx_hour, 23);
	    FMT((*format == 'H') ? '0' : ' ', 2, "d", v);
	    continue;

	  case 'I':	/* hour, 12-hour clock, 01 - 12 */
	  case 'l':	/* hour, 12-hour clock, 1 - 12, blank pad */
	    v = range(0, tmx_hour, 23);
	    if (v == 0)
		v = 12;
	    else if (v > 12)
		v -= 12;
	    FMT((*format == 'I') ? '0' : ' ', 2, "d", v);
	    continue;

	  case 'j':	/* day of the year, 001 - 366 */
	    v = range(1, tmx_yday, 366);
	    FMT('0', 3, "d", v);
	    continue;

	  case 'L':	/* millisecond */
	  case 'N':	/* nanosecond */
	    if (*format == 'L')
		w = 3;
	    else
		w = 9;
	    if (precision <= 0)
		precision = w;
	    NEEDS(precision);

	    {
		VALUE subsec = tmx_sec_fraction;
		int ww;
		long n;

		ww = precision;
		while (9 <= ww) {
		    subsec = mul(subsec, INT2FIX(1000000000));
		    ww -= 9;
		}
		n = 1;
		for (; 0 < ww; ww--)
		    n *= 10;
		if (n != 1)
		    subsec = mul(subsec, INT2FIX(n));
		subsec = div(subsec, INT2FIX(1));

		if (FIXNUM_P(subsec)) {
		    (void)snprintf(s, endp - s, "%0*ld",
				   precision, FIX2LONG(subsec));
		    s += precision;
		}
		else {
		    VALUE args[2], result;
		    args[0] = INT2FIX(precision);
		    args[1] = subsec;
		    result = rb_str_format(2, args, rb_str_new2("%0*d"));
		    (void)strlcpy(s, StringValueCStr(result), endp - s);
		    s += precision;
		}
	    }
	    continue;

	  case 'M':	/* minute, 00 - 59 */
	    v = range(0, tmx_min, 59);
	    FMT('0', 2, "d", v);
	    continue;

	  case 'm':	/* month, 01 - 12 */
	    v = range(1, tmx_mon, 12);
	    FMT('0', 2, "d", v);
	    continue;

	  case 'n':	/* same as \n */
	    FILL_PADDING(1);
	    *s++ = '\n';
	    continue;

	  case 't':	/* same as \t */
	    FILL_PADDING(1);
	    *s++ = '\t';
	    continue;

	  case 'P':	/* am or pm based on 12-hour clock */
	  case 'p':	/* AM or PM based on 12-hour clock */
	    if ((*format == 'p' && (flags & BIT_OF(CHCASE))) ||
		(*format == 'P' && !(flags & (BIT_OF(CHCASE) | BIT_OF(UPPER))))) {
		flags &= ~(BIT_OF(UPPER) | BIT_OF(CHCASE));
		flags |= BIT_OF(LOWER);
	    }
	    v = range(0, tmx_hour, 23);
	    if (v < 12)
		tp = ampm[0];
	    else
		tp = ampm[1];
	    i = 2;
	    break;

	  case 'Q':	/* milliseconds since Unix epoch */
	    FMTV('0', 1, "d", tmx_msecs);
	    continue;

	  case 'R':
	    STRFTIME("%H:%M");
	    continue;

	  case 'r':
	    STRFTIME("%I:%M:%S %p");
	    continue;

	  case 'S':	/* second, 00 - 59 */
	    v = range(0, tmx_sec, 59);
	    FMT('0', 2, "d", v);
	    continue;

	  case 's':	/* seconds since Unix epoch */
	    FMTV('0', 1, "d", tmx_secs);
	    continue;

	  case 'T':
	    STRFTIME("%H:%M:%S");
	    continue;

	  case 'U':	/* week of year, Sunday is first day of week */
	  case 'W':	/* week of year, Monday is first day of week */
	    v = range(0, (*format == 'U') ? tmx_wnum0 : tmx_wnum1, 53);
	    FMT('0', 2, "d", v);
	    continue;

	  case 'u':	/* weekday, Monday == 1, 1 - 7 */
	    v = range(1, tmx_cwday, 7);
	    FMT('0', 1, "d", v);
	    continue;

	  case 'V':	/* week of year according ISO 8601 */
	    v = range(1, tmx_cweek, 53);
	    FMT('0', 2, "d", v);
	    continue;

	  case 'v':
	    STRFTIME("%e-%^b-%Y");
	    continue;

	  case 'w':	/* weekday, Sunday == 0, 0 - 6 */
	    v = range(0, tmx_wday, 6);
	    FMT('0', 1, "d", v);
	    continue;

	  case 'X':	/* appropriate time representation */
	    STRFTIME("%H:%M:%S");
	    continue;

	  case 'x':	/* appropriate date representation */
	    STRFTIME("%m/%d/%y");
	    continue;

	  case 'Z':	/* time zone name or abbreviation */
	    if (flags & BIT_OF(CHCASE)) {
		flags &= ~(BIT_OF(UPPER) | BIT_OF(CHCASE));
		flags |= BIT_OF(LOWER);
	    }
	    {
		char *zone = tmx_zone;
		if (zone == NULL)
		    tp = "";
		else
		    tp = zone;
		i = strlen(tp);
	    }
	    break;

	  case 'z':	/* offset from UTC */
	    {
		long off, aoff;
		int hl, hw;

		off = tmx_offset;
		aoff = off;
		if (aoff < 0)
		    aoff = -off;

		if ((aoff / 3600) < 10)
		    hl = 1;
		else
		    hl = 2;
		hw = 2;
		if (flags & BIT_OF(LEFT) && hl == 1)
		    hw = 1;

		switch (colons) {
		  case 0: /* %z -> +hhmm */
		    precision = precision <= (3 + hw) ? hw : precision - 3;
		    NEEDS(precision + 3);
		    break;

		  case 1: /* %:z -> +hh:mm */
		    precision = precision <= (4 + hw) ? hw : precision - 4;
		    NEEDS(precision + 4);
		    break;

		  case 2: /* %::z -> +hh:mm:ss */
		    precision = precision <= (7 + hw) ? hw : precision - 7;
		    NEEDS(precision + 7);
		    break;

		  case 3: /* %:::z -> +hh[:mm[:ss]] */
		    {
			if (aoff % 3600 == 0) {
			    precision = precision <= (1 + hw) ?
				hw : precision - 1;
			    NEEDS(precision + 3);
			}
			else if (aoff % 60 == 0) {
			    precision = precision <= (4 + hw) ?
				hw : precision - 4;
			    NEEDS(precision + 4);
			}
			else {
			    precision = precision <= (7 + hw) ?
				hw : precision - 7;
			    NEEDS(precision + 7);
			}
		    }
		    break;

		  default:
		    format--;
		    goto unknown;
		}
		if (padding == ' ' && precision > hl) {
		    i = snprintf(s, endp - s, "%*s", precision - hl, "");
		    precision = hl;
		    if (i < 0) goto err;
		    s += i;
		}
		if (off < 0) {
		    off = -off;
		    *s++ = '-';
		} else {
		    *s++ = '+';
		}
		i = snprintf(s, endp - s, "%.*ld", precision, off / 3600);
		if (i < 0) goto err;
		s += i;
		off = off % 3600;
		if (colons == 3 && off == 0)
		    continue;
		if (1 <= colons)
		    *s++ = ':';
		i = snprintf(s, endp - s, "%02d", (int)(off / 60));
		if (i < 0) goto err;
		s += i;
		off = off % 60;
		if (colons == 3 && off == 0)
		    continue;
		if (2 <= colons) {
		    *s++ = ':';
		    i = snprintf(s, endp - s, "%02d", (int)off);
		    if (i < 0) goto err;
		    s += i;
		}
	    }
	    continue;

	  case '+':
	    STRFTIME("%a %b %e %H:%M:%S %Z %Y");
	    continue;

	  case 'E':
	    /* POSIX locale extensions, ignored for now */
	    flags |= BIT_OF(LOCALE_E);
	    if (*(format + 1) && strchr("cCxXyY", *(format + 1)))
		goto again;
	    goto unknown;
	  case 'O':
	    /* POSIX locale extensions, ignored for now */
	    flags |= BIT_OF(LOCALE_O);
	    if (*(format + 1) && strchr("deHkIlmMSuUVwWy", *(format + 1)))
		goto again;
	    goto unknown;

	  case ':':
	    flags |= BIT_OF(COLONS);
	    {
		size_t l = strspn(format, ":");
		format += l;
		if (*format == 'z') {
		    colons = l;
		    format--;
		    goto again;
		}
		format -= l;
	    }
	    goto unknown;

	  case '_':
	    FLAG_FOUND();
	    padding = ' ';
	    goto again;

	  case '-':
	    FLAG_FOUND();
	    flags |= BIT_OF(LEFT);
	    goto again;

	  case '^':
	    FLAG_FOUND();
	    flags |= BIT_OF(UPPER);
	    goto again;

	  case '#':
	    FLAG_FOUND();
	    flags |= BIT_OF(CHCASE);
	    goto again;

	  case '0':
	    FLAG_FOUND();
	    padding = '0';
	  case '1':  case '2': case '3': case '4':
	  case '5': case '6':  case '7': case '8': case '9':
	    {
		char *e;
		unsigned long prec = strtoul(format, &e, 10);
		if (prec > INT_MAX || prec > maxsize) {
		    errno = ERANGE;
		    return 0;
		}
		precision = (int)prec;
		format = e - 1;
		goto again;
	    }

	  case '%':
	    FILL_PADDING(1);
	    *s++ = '%';
	    continue;

	  default:
	  unknown:
	    i = format - sp + 1;
	    tp = sp;
	    precision = -1;
	    flags = 0;
	    padding = 0;
	    colons = 0;
	    break;
	}
	if (i) {
	    FILL_PADDING(i);
	    memcpy(s, tp, i);
	    switch (flags & (BIT_OF(UPPER) | BIT_OF(LOWER))) {
	      case BIT_OF(UPPER):
		upcase(s, i);
		break;
	      case BIT_OF(LOWER):
		downcase(s, i);
		break;
	    }
	    s += i;
	}
    }
    if (s >= endp) {
	goto err;
    }
    if (*format == '\0') {
	*s = '\0';
	return (s - start);
    }
    return 0;
}

size_t
date_strftime(char *s, size_t maxsize, const char *format,
	      const struct tmx *tmx)
{
    return date_strftime_with_tmx(s, maxsize, format, tmx);
}

/*
Local variables:
c-file-style: "ruby"
End:
*/
