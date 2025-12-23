/*
  date_strptime.c: Coded by Tadayoshi Funaba 2011,2012
*/

#include "ruby.h"
#include "ruby/encoding.h"
#include "ruby/re.h"
#include <ctype.h>

#undef strncasecmp
#define strncasecmp STRNCASECMP

static const char *day_names[] = {
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday",
};
static const int ABBREVIATED_DAY_NAME_LENGTH = 3;

static const char *month_names[] = {
    "January", "February", "March", "April",
    "May", "June", "July", "August", "September",
    "October", "November", "December",
};
static const int ABBREVIATED_MONTH_NAME_LENGTH = 3;

#define sizeof_array(o) (sizeof o / sizeof o[0])

#define f_negate(x) rb_funcall(x, rb_intern("-@"), 0)
#define f_add(x,y) rb_funcall(x, '+', 1, y)
#define f_sub(x,y) rb_funcall(x, '-', 1, y)
#define f_mul(x,y) rb_funcall(x, '*', 1, y)
#define f_div(x,y) rb_funcall(x, '/', 1, y)
#define f_idiv(x,y) rb_funcall(x, rb_intern("div"), 1, y)
#define f_mod(x,y) rb_funcall(x, '%', 1, y)
#define f_expt(x,y) rb_funcall(x, rb_intern("**"), 1, y)

#define f_lt_p(x,y) rb_funcall(x, '<', 1, y)
#define f_gt_p(x,y) rb_funcall(x, '>', 1, y)
#define f_le_p(x,y) rb_funcall(x, rb_intern("<="), 1, y)
#define f_ge_p(x,y) rb_funcall(x, rb_intern(">="), 1, y)

#define f_match(r,s) rb_funcall(r, rb_intern("match"), 1, s)
#define f_aref(o,i) rb_funcall(o, rb_intern("[]"), 1, i)
#define f_end(o,i) rb_funcall(o, rb_intern("end"), 1, i)

#define issign(c) ((c) == '-' || (c) == '+')

static int
num_pattern_p(const char *s)
{
    if (isdigit((unsigned char)*s))
	return 1;
    if (*s == '%') {
	s++;
	if (*s == 'E' || *s == 'O')
	    s++;
	if (*s &&
	    (strchr("CDdeFGgHIjkLlMmNQRrSsTUuVvWwXxYy", *s) ||
	     isdigit((unsigned char)*s)))
	    return 1;
    }
    return 0;
}

#define NUM_PATTERN_P() num_pattern_p(&fmt[fi + 1])

static long
read_digits(const char *s, size_t slen, VALUE *n, size_t width)
{
    size_t l;

    if (!width)
        return 0;

    l = 0;
    while (l < slen && ISDIGIT(s[l])) {
        if (++l == width) break;
    }

    if (l == 0)
	return 0;

    if ((4 * l * sizeof(char)) <= (sizeof(long)*CHAR_BIT)) {
	const char *os = s;
	long v;

	v = 0;
	while ((size_t)(s - os) < l) {
	    v *= 10;
	    v += *s - '0';
	    s++;
	}
	if (os == s)
	    return 0;
	*n = LONG2NUM(v);
	return l;
    }
    else {
	VALUE vbuf = 0;
	char *s2 = ALLOCV_N(char, vbuf, l + 1);
	memcpy(s2, s, l);
	s2[l] = '\0';
	*n = rb_cstr_to_inum(s2, 10, 0);
	ALLOCV_END(vbuf);
	return l;
    }
}

#define set_hash(k,v) rb_hash_aset(hash, ID2SYM(rb_intern(k"")), v)
#define ref_hash(k) rb_hash_aref(hash, ID2SYM(rb_intern(k"")))
#define del_hash(k) rb_hash_delete(hash, ID2SYM(rb_intern(k"")))

#define fail() \
do { \
    set_hash("_fail", Qtrue); \
    return 0; \
} while (0)

#define fail_p() (!NIL_P(ref_hash("_fail")))

#define READ_DIGITS(n,w) \
do { \
    size_t l; \
    l = read_digits(&str[si], slen - si, &n, w); \
    if (l == 0) \
	fail();	\
    si += l; \
} while (0)

#define READ_DIGITS_MAX(n) READ_DIGITS(n, LONG_MAX)

static int
valid_range_p(VALUE v, int a, int b)
{
    if (FIXNUM_P(v)) {
	int vi = FIX2INT(v);
	return !(vi < a || vi > b);
    }
    return !(f_lt_p(v, INT2NUM(a)) || f_gt_p(v, INT2NUM(b)));
}

#define recur(fmt) \
do { \
    size_t l; \
    l = date__strptime_internal(&str[si], slen - si, \
				fmt, sizeof fmt - 1, hash); \
    if (fail_p()) \
	return 0; \
    si += l; \
} while (0)

VALUE date_zone_to_diff(VALUE);

static inline int
head_match_p(size_t len, const char *name, const char *str, size_t slen, size_t si)
{
    return slen - si >= len && strncasecmp(name, &str[si], len) == 0;
}

static size_t
date__strptime_internal(const char *str, size_t slen,
			const char *fmt, size_t flen, VALUE hash)
{
    size_t si, fi;
    int c;

#define HEAD_MATCH_P(len, name) head_match_p(len, name, str, slen, si)
    si = fi = 0;

    while (fi < flen) {
	if (isspace((unsigned char)fmt[fi])) {
	    while (si < slen && isspace((unsigned char)str[si]))
		si++;
	    while (++fi < flen && isspace((unsigned char)fmt[fi]));
	    continue;
	}

	if (si >= slen) fail();

	switch (fmt[fi]) {
	  case '%':

	  again:
	    fi++;
	    c = fmt[fi];

	    switch (c) {
	      case 'E':
		if (fmt[fi + 1] && strchr("cCxXyY", fmt[fi + 1]))
		    goto again;
		fi--;
		goto ordinal;
	      case 'O':
		if (fmt[fi + 1] && strchr("deHImMSuUVwWy", fmt[fi + 1]))
		    goto again;
		fi--;
		goto ordinal;
	      case ':':
		{
		    int i;

		    for (i = 1; i < 3 && fi + i < flen && fmt[fi+i] == ':'; ++i);
		    if (fmt[fi+i] == 'z') {
			fi += i - 1;
			goto again;
		    }
		    fail();
		}

	      case 'A':
	      case 'a':
		{
		    int i;

		    for (i = 0; i < (int)sizeof_array(day_names); i++) {
			const char *day_name = day_names[i];
			size_t l = strlen(day_name);
			if (HEAD_MATCH_P(l, day_name) ||
			    HEAD_MATCH_P(l = ABBREVIATED_DAY_NAME_LENGTH, day_name)) {
			    si += l;
			    set_hash("wday", INT2FIX(i));
			    goto matched;
			}
		    }
		    fail();
		}
	      case 'B':
	      case 'b':
	      case 'h':
		{
		    int i;

		    for (i = 0; i < (int)sizeof_array(month_names); i++) {
			const char *month_name = month_names[i];
			size_t l = strlen(month_name);
			if (HEAD_MATCH_P(l, month_name) ||
			    HEAD_MATCH_P(l = ABBREVIATED_MONTH_NAME_LENGTH, month_name)) {
			    si += l;
			    set_hash("mon", INT2FIX(i + 1));
			    goto matched;
			}
		    }
		    fail();
		}

	      case 'C':
		{
		    VALUE n;

		    if (NUM_PATTERN_P())
			READ_DIGITS(n, 2);
		    else
			READ_DIGITS_MAX(n);
		    set_hash("_cent", n);
		    goto matched;
		}

	      case 'c':
		recur("%a %b %e %H:%M:%S %Y");
		goto matched;

	      case 'D':
		recur("%m/%d/%y");
		goto matched;

	      case 'd':
	      case 'e':
		{
		    VALUE n;

		    if (str[si] == ' ') {
			si++;
			READ_DIGITS(n, 1);
		    } else {
			READ_DIGITS(n, 2);
		    }
		    if (!valid_range_p(n, 1, 31))
			fail();
		    set_hash("mday", n);
		    goto matched;
		}

	      case 'F':
		recur("%Y-%m-%d");
		goto matched;

	      case 'G':
		{
		    VALUE n;

		    if (NUM_PATTERN_P())
			READ_DIGITS(n, 4);
		    else
			READ_DIGITS_MAX(n);
		    set_hash("cwyear", n);
		    goto matched;
		}

	      case 'g':
		{
		    VALUE n;

		    READ_DIGITS(n, 2);
		    if (!valid_range_p(n, 0, 99))
			fail();
		    set_hash("cwyear",n);
		    if (NIL_P(ref_hash("_cent")))
			set_hash("_cent",
				 INT2FIX(f_ge_p(n, INT2FIX(69)) ? 19 : 20));
		    goto matched;
		}

	      case 'H':
	      case 'k':
		{
		    VALUE n;

		    if (str[si] == ' ') {
			si++;
			READ_DIGITS(n, 1);
		    } else {
			READ_DIGITS(n, 2);
		    }
		    if (!valid_range_p(n, 0, 24))
			fail();
		    set_hash("hour", n);
		    goto matched;
		}

	      case 'I':
	      case 'l':
		{
		    VALUE n;

		    if (str[si] == ' ') {
			si++;
			READ_DIGITS(n, 1);
		    } else {
			READ_DIGITS(n, 2);
		    }
		    if (!valid_range_p(n, 1, 12))
			fail();
		    set_hash("hour", n);
		    goto matched;
		}

	      case 'j':
		{
		    VALUE n;

		    READ_DIGITS(n, 3);
		    if (!valid_range_p(n, 1, 366))
			fail();
		    set_hash("yday", n);
		    goto matched;
		}

	      case 'L':
	      case 'N':
		{
		    VALUE n;
		    int sign = 1;
		    size_t osi;

		    if (issign(str[si])) {
			if (str[si] == '-')
			    sign = -1;
			si++;
		    }
		    osi = si;
		    if (NUM_PATTERN_P())
			READ_DIGITS(n, c == 'L' ? 3 : 9);
		    else
			READ_DIGITS_MAX(n);
		    if (sign == -1)
			n = f_negate(n);
		    set_hash("sec_fraction",
			     rb_rational_new2(n,
					      f_expt(INT2FIX(10),
						     ULONG2NUM(si - osi))));
		    goto matched;
		}

	      case 'M':
		{
		    VALUE n;

		    READ_DIGITS(n, 2);
		    if (!valid_range_p(n, 0, 59))
			fail();
		    set_hash("min", n);
		    goto matched;
		}

	      case 'm':
		{
		    VALUE n;

		    READ_DIGITS(n, 2);
		    if (!valid_range_p(n, 1, 12))
			fail();
		    set_hash("mon", n);
		    goto matched;
		}

	      case 'n':
	      case 't':
		recur(" ");
		goto matched;

	      case 'P':
	      case 'p':
		if (slen - si < 2) fail();
		{
		    char c = str[si];
		    const int hour = (c == 'P' || c == 'p') ? 12 : 0;
		    if (!hour && !(c == 'A' || c == 'a')) fail();
		    if ((c = str[si+1]) == '.') {
			if (slen - si < 4 || str[si+3] != '.') fail();
			c = str[si += 2];
		    }
		    if (!(c == 'M' || c == 'm')) fail();
		    si += 2;
		    set_hash("_merid", INT2FIX(hour));
		    goto matched;
		}

	      case 'Q':
		{
		    VALUE n;
		    int sign = 1;

		    if (str[si] == '-') {
			sign = -1;
			si++;
		    }
		    READ_DIGITS_MAX(n);
		    if (sign == -1)
			n = f_negate(n);
		    set_hash("seconds",
			     rb_rational_new2(n, INT2FIX(1000)));
		    goto matched;
		}

	      case 'R':
		recur("%H:%M");
		goto matched;

	      case 'r':
		recur("%I:%M:%S %p");
		goto matched;

	      case 'S':
		{
		    VALUE n;

		    READ_DIGITS(n, 2);
		    if (!valid_range_p(n, 0, 60))
			fail();
		    set_hash("sec", n);
		    goto matched;
		}

	      case 's':
		{
		    VALUE n;
		    int sign = 1;

		    if (str[si] == '-') {
			sign = -1;
			si++;
		    }
		    READ_DIGITS_MAX(n);
		    if (sign == -1)
			n = f_negate(n);
		    set_hash("seconds", n);
		    goto matched;
		}

	      case 'T':
		recur("%H:%M:%S");
		goto matched;

	      case 'U':
	      case 'W':
		{
		    VALUE n;

		    READ_DIGITS(n, 2);
		    if (!valid_range_p(n, 0, 53))
			fail();
		    set_hash(c == 'U' ? "wnum0" : "wnum1", n);
		    goto matched;
		}

	      case 'u':
		{
		    VALUE n;

		    READ_DIGITS(n, 1);
		    if (!valid_range_p(n, 1, 7))
			fail();
		    set_hash("cwday", n);
		    goto matched;
		}

	      case 'V':
		{
		    VALUE n;

		    READ_DIGITS(n, 2);
		    if (!valid_range_p(n, 1, 53))
			fail();
		    set_hash("cweek", n);
		    goto matched;
		}

	      case 'v':
		recur("%e-%b-%Y");
		goto matched;

	      case 'w':
		{
		    VALUE n;

		    READ_DIGITS(n, 1);
		    if (!valid_range_p(n, 0, 6))
			fail();
		    set_hash("wday", n);
		    goto matched;
		}

	      case 'X':
		recur("%H:%M:%S");
		goto matched;

	      case 'x':
		recur("%m/%d/%y");
		goto matched;

	      case 'Y':
		{
		    VALUE n;
		    int sign = 1;

		    if (issign(str[si])) {
			if (str[si] == '-')
			    sign = -1;
			si++;
		    }
		    if (NUM_PATTERN_P())
			READ_DIGITS(n, 4);
		    else
			READ_DIGITS_MAX(n);
		    if (sign == -1)
			n = f_negate(n);
		    set_hash("year", n);
		    goto matched;
		}

	      case 'y':
		{
		    VALUE n;
		    int sign = 1;

		    READ_DIGITS(n, 2);
		    if (!valid_range_p(n, 0, 99))
			fail();
		    if (sign == -1)
			n = f_negate(n);
		    set_hash("year", n);
		    if (NIL_P(ref_hash("_cent")))
			set_hash("_cent",
				 INT2FIX(f_ge_p(n, INT2FIX(69)) ? 19 : 20));
		    goto matched;
		}

	      case 'Z':
	      case 'z':
		{
		    static const char pat_source[] =
			"\\A("
			"(?:gmt|utc?)?[-+]\\d+(?:[,.:]\\d+(?::\\d+)?)?"
			"|(?-i:[[:alpha:].\\s]+)(?:standard|daylight)\\s+time\\b"
			"|(?-i:[[:alpha:]]+)(?:\\s+dst)?\\b"
			")";
		    static VALUE pat = Qnil;
		    VALUE m, b;

		    if (NIL_P(pat)) {
			pat = rb_reg_new(pat_source, sizeof pat_source - 1,
					 ONIG_OPTION_IGNORECASE);
			rb_obj_freeze(pat);
			rb_gc_register_mark_object(pat);
		    }

		    b = rb_backref_get();
		    rb_match_busy(b);
		    m = f_match(pat, rb_usascii_str_new(&str[si], slen - si));

		    if (!NIL_P(m)) {
			VALUE s, l, o;

			s = rb_reg_nth_match(1, m);
			l = f_end(m, INT2FIX(0));
			o = date_zone_to_diff(s);
			si += NUM2LONG(l);
			set_hash("zone", s);
			set_hash("offset", o);
			rb_backref_set(b);
			goto matched;
		    }
		    rb_backref_set(b);
		    fail();
		}

	      case '%':
		if (str[si] != '%')
		    fail();
		si++;
		goto matched;

	      case '+':
		recur("%a %b %e %H:%M:%S %Z %Y");
		goto matched;

	      default:
		if (str[si] != '%')
		    fail();
		si++;
		if (fi < flen) {
		    if (si >= slen || str[si] != fmt[fi])
			fail();
		    si++;
		}
		goto matched;
	    }
	  default:
	  ordinal:
	    if (str[si] != fmt[fi])
		fail();
	    si++;
	    fi++;
	    break;
	  matched:
	    fi++;
	    break;
	}
    }

    return si;
}

VALUE
date__strptime(const char *str, size_t slen,
	       const char *fmt, size_t flen, VALUE hash)
{
    size_t si;
    VALUE cent, merid;

    si = date__strptime_internal(str, slen, fmt, flen, hash);

    if (slen > si) {
	VALUE s;

	s = rb_usascii_str_new(&str[si], slen - si);
	set_hash("leftover", s);
    }

    if (fail_p())
	return Qnil;

    cent = del_hash("_cent");
    if (!NIL_P(cent)) {
	VALUE year;

	year = ref_hash("cwyear");
	if (!NIL_P(year))
	    set_hash("cwyear", f_add(year, f_mul(cent, INT2FIX(100))));
	year = ref_hash("year");
	if (!NIL_P(year))
	    set_hash("year", f_add(year, f_mul(cent, INT2FIX(100))));
    }

    merid = del_hash("_merid");
    if (!NIL_P(merid)) {
	VALUE hour;

	hour = ref_hash("hour");
	if (!NIL_P(hour)) {
	    hour = f_mod(hour, INT2FIX(12));
	    set_hash("hour", f_add(hour, merid));
	}
    }

    return hash;
}

/*
Local variables:
c-file-style: "ruby"
End:
*/
