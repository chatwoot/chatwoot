/*
  date_parse.c: Coded by Tadayoshi Funaba 2011,2012
*/

#include "ruby.h"
#include "ruby/encoding.h"
#include "ruby/re.h"
#include <ctype.h>

#undef strncasecmp
#define strncasecmp STRNCASECMP

RUBY_EXTERN VALUE rb_int_positive_pow(long x, unsigned long y);
RUBY_EXTERN unsigned long ruby_scan_digits(const char *str, ssize_t len, int base, size_t *retlen, int *overflow);

/* #define TIGHT_PARSER */

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

#define f_to_s(x) rb_funcall(x, rb_intern("to_s"), 0)

#define f_match(r,s) rb_funcall(r, rb_intern("match"), 1, s)
#define f_aref(o,i) rb_funcall(o, rb_intern("[]"), 1, i)
#define f_aref2(o,i,j) rb_funcall(o, rb_intern("[]"), 2, i, j)
#define f_begin(o,i) rb_funcall(o, rb_intern("begin"), 1, i)
#define f_end(o,i) rb_funcall(o, rb_intern("end"), 1, i)
#define f_aset(o,i,v) rb_funcall(o, rb_intern("[]="), 2, i, v)
#define f_aset2(o,i,j,v) rb_funcall(o, rb_intern("[]="), 3, i, j, v)
#define f_sub_bang(s,r,x) rb_funcall(s, rb_intern("sub!"), 2, r, x)
#define f_gsub_bang(s,r,x) rb_funcall(s, rb_intern("gsub!"), 2, r, x)

#define set_hash(k,v) rb_hash_aset(hash, ID2SYM(rb_intern(k"")), v)
#define ref_hash(k) rb_hash_aref(hash, ID2SYM(rb_intern(k"")))
#define del_hash(k) rb_hash_delete(hash, ID2SYM(rb_intern(k"")))

#define cstr2num(s) rb_cstr_to_inum(s, 10, 0)
#define str2num(s) rb_str_to_inum(s, 10, 0)

static const char abbr_days[][4] = {
    "sun", "mon", "tue", "wed",
    "thu", "fri", "sat"
};

static const char abbr_months[][4] = {
    "jan", "feb", "mar", "apr", "may", "jun",
    "jul", "aug", "sep", "oct", "nov", "dec"
};

#define issign(c) ((c) == '-' || (c) == '+')
#define asp_string() rb_str_new(" ", 1)
#ifdef TIGHT_PARSER
#define asuba_string() rb_str_new("\001", 1)
#define asubb_string() rb_str_new("\002", 1)
#define asubw_string() rb_str_new("\027", 1)
#define asubt_string() rb_str_new("\024", 1)
#endif

static size_t
digit_span(const char *s, const char *e)
{
    size_t i = 0;
    while (s + i < e && isdigit((unsigned char)s[i])) i++;
    return i;
}

static void
s3e(VALUE hash, VALUE y, VALUE m, VALUE d, int bc)
{
    VALUE vbuf = 0;
    VALUE c = Qnil;

    if (!RB_TYPE_P(m, T_STRING))
	m = f_to_s(m);

    if (!NIL_P(y) && !NIL_P(m) && NIL_P(d)) {
	VALUE oy = y;
	VALUE om = m;
	VALUE od = d;

	y = od;
	m = oy;
	d = om;
    }

    if (NIL_P(y)) {
	if (!NIL_P(d) && RSTRING_LEN(d) > 2) {
	    y = d;
	    d = Qnil;
	}
	if (!NIL_P(d) && RSTRING_LEN(d) > 0 && *RSTRING_PTR(d) == '\'') {
	    y = d;
	    d = Qnil;
	}
    }

    if (!NIL_P(y)) {
	const char *s, *bp, *ep;
	size_t l;

	s = RSTRING_PTR(y);
	ep = RSTRING_END(y);
	while (s < ep && !issign(*s) && !isdigit((unsigned char)*s))
	    s++;
	if (s >= ep) goto no_date;
	bp = s;
	if (issign((unsigned char)*s))
	    s++;
	l = digit_span(s, ep);
	ep = s + l;
	if (*ep) {
	    y = d;
	    d = rb_str_new(bp, ep - bp);
	}
      no_date:;
    }

    if (!NIL_P(m)) {
	const char *s;

	s = RSTRING_PTR(m);
	if (*s == '\'' || RSTRING_LEN(m) > 2) {
	    /* us -> be */
	    VALUE oy = y;
	    VALUE om = m;
	    VALUE od = d;

	    y = om;
	    m = od;
	    d = oy;
	}
    }

    if (!NIL_P(d)) {
	const char *s;

	s = RSTRING_PTR(d);
	if (*s == '\'' || RSTRING_LEN(d) > 2) {
	    VALUE oy = y;
	    VALUE od = d;

	    y = od;
	    d = oy;
	}
    }

    if (!NIL_P(y)) {
	const char *s, *bp, *ep;
	int sign = 0;
	size_t l;
	VALUE iy;

	s = RSTRING_PTR(y);
	ep = RSTRING_END(y);
	while (s < ep && !issign(*s) && !isdigit((unsigned char)*s))
	    s++;
	if (s >= ep) goto no_year;
	bp = s;
	if (issign(*s)) {
	    s++;
	    sign = 1;
	}
	if (sign)
	    c = Qfalse;
	l = digit_span(s, ep);
	ep = s + l;
	if (l > 2)
	    c = Qfalse;
	{
	    char *buf;

	    buf = ALLOCV_N(char, vbuf, ep - bp + 1);
	    memcpy(buf, bp, ep - bp);
	    buf[ep - bp] = '\0';
	    iy = cstr2num(buf);
	    ALLOCV_END(vbuf);
	}
	set_hash("year", iy);
      no_year:;
    }

    if (bc)
	set_hash("_bc", Qtrue);

    if (!NIL_P(m)) {
	const char *s, *bp, *ep;
	size_t l;
	VALUE im;

	s = RSTRING_PTR(m);
	ep = RSTRING_END(m);
	while (s < ep && !isdigit((unsigned char)*s))
	    s++;
	if (s >= ep) goto no_month;
	bp = s;
	l = digit_span(s, ep);
	ep = s + l;
	{
	    char *buf;

	    buf = ALLOCV_N(char, vbuf, ep - bp + 1);
	    memcpy(buf, bp, ep - bp);
	    buf[ep - bp] = '\0';
	    im = cstr2num(buf);
	    ALLOCV_END(vbuf);
	}
	set_hash("mon", im);
      no_month:;
    }

    if (!NIL_P(d)) {
	const char *s, *bp, *ep;
	size_t l;
	VALUE id;

	s = RSTRING_PTR(d);
	ep = RSTRING_END(d);
	while (s < ep && !isdigit((unsigned char)*s))
	    s++;
	if (s >= ep) goto no_mday;
	bp = s;
	l = digit_span(s, ep);
	ep = s + l;
	{
	    char *buf;

	    buf = ALLOCV_N(char, vbuf, ep - bp + 1);
	    memcpy(buf, bp, ep - bp);
	    buf[ep - bp] = '\0';
	    id = cstr2num(buf);
	    ALLOCV_END(vbuf);
	}
	set_hash("mday", id);
      no_mday:;
    }

    if (!NIL_P(c))
	set_hash("_comp", c);
}

#define DAYS "sunday|monday|tuesday|wednesday|thursday|friday|saturday"
#define MONTHS "january|february|march|april|may|june|july|august|september|october|november|december"
#define ABBR_DAYS "sun|mon|tue|wed|thu|fri|sat"
#define ABBR_MONTHS "jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec"

#define NUMBER "(?<!\\d)\\d"

#ifdef TIGHT_PARSER
#define VALID_DAYS "(?:" DAYS ")" "|(?:tues|wednes|thurs|thur|" ABBR_DAYS ")\\.?"
#define VALID_MONTHS "(?:" MONTHS ")" "|(?:sept|" ABBR_MONTHS ")\\.?"
#define DOTLESS_VALID_MONTHS "(?:" MONTHS ")" "|(?:sept|" ABBR_MONTHS ")"
#define BOS "\\A\\s*"
#define FPA "\\001"
#define FPB "\\002"
#define FPW "\\027"
#define FPT "\\024"
#define FPW_COM "\\s*(?:" FPW "\\s*,?)?\\s*"
#define FPT_COM "\\s*(?:" FPT "\\s*,?)?\\s*"
#define COM_FPW "\\s*(?:,?\\s*" FPW ")?\\s*"
#define COM_FPT "\\s*(?:,?\\s*(?:@|\\b[aA][tT]\\b)?\\s*" FPT ")?\\s*"
#define TEE_FPT "\\s*(?:[tT]?" FPT ")?"
#define EOS "\\s*\\z"
#endif

static VALUE
regcomp(const char *source, long len, int opt)
{
    VALUE pat;

    pat = rb_reg_new(source, len, opt);
    rb_obj_freeze(pat);
    rb_gc_register_mark_object(pat);
    return pat;
}

#define REGCOMP(pat,opt) \
do { \
    if (NIL_P(pat)) \
	pat = regcomp(pat##_source, sizeof pat##_source - 1, opt); \
} while (0)

#define REGCOMP_0(pat) REGCOMP(pat, 0)
#define REGCOMP_I(pat) REGCOMP(pat, ONIG_OPTION_IGNORECASE)

#define MATCH(s,p,c) \
do { \
    return match(s, p, hash, c); \
} while (0)

static int
match(VALUE str, VALUE pat, VALUE hash, int (*cb)(VALUE, VALUE))
{
    VALUE m;

    m = f_match(pat, str);

    if (NIL_P(m))
	return 0;

    (*cb)(m, hash);

    return 1;
}

static int
subx(VALUE str, VALUE rep, VALUE pat, VALUE hash, int (*cb)(VALUE, VALUE))
{
    VALUE m;

    m = f_match(pat, str);

    if (NIL_P(m))
	return 0;

    {
	VALUE be, en;

	be = f_begin(m, INT2FIX(0));
	en = f_end(m, INT2FIX(0));
	f_aset2(str, be, LONG2NUM(NUM2LONG(en) - NUM2LONG(be)), rep);
	(*cb)(m, hash);
    }

    return 1;
}

#define SUBS(s,p,c) \
do { \
    return subx(s, asp_string(), p, hash, c); \
} while (0)

#ifdef TIGHT_PARSER
#define SUBA(s,p,c) \
do { \
    return subx(s, asuba_string(), p, hash, c); \
} while (0)

#define SUBB(s,p,c) \
do { \
    return subx(s, asubb_string(), p, hash, c); \
} while (0)

#define SUBW(s,p,c) \
do { \
    return subx(s, asubw_string(), p, hash, c); \
} while (0)

#define SUBT(s,p,c) \
do { \
    return subx(s, asubt_string(), p, hash, c); \
} while (0)
#endif

#include "zonetab.h"

static int
str_end_with_word(const char *s, long l, const char *w)
{
    int n = (int)strlen(w);
    if (l <= n || !isspace((unsigned char)s[l - n - 1])) return 0;
    if (strncasecmp(&s[l - n], w, n)) return 0;
    do ++n; while (l > n && isspace((unsigned char)s[l - n - 1]));
    return n;
}

static long
shrunk_size(const char *s, long l)
{
    long i, ni;
    int sp = 0;
    for (i = ni = 0; i < l; ++i) {
	if (!isspace((unsigned char)s[i])) {
	    if (sp) ni++;
	    sp = 0;
	    ni++;
	}
	else {
	    sp = 1;
	}
    }
    return ni < l ? ni : 0;
}

static long
shrink_space(char *d, const char *s, long l)
{
    long i, ni;
    int sp = 0;
    for (i = ni = 0; i < l; ++i) {
	if (!isspace((unsigned char)s[i])) {
	    if (sp) d[ni++] = ' ';
	    sp = 0;
	    d[ni++] = s[i];
	}
	else {
	    sp = 1;
	}
    }
    return ni;
}

VALUE
date_zone_to_diff(VALUE str)
{
    VALUE offset = Qnil;
    long l = RSTRING_LEN(str);
    const char *s = RSTRING_PTR(str);

    {
	int dst = 0;
	int w;

	if ((w = str_end_with_word(s, l, "time")) > 0) {
	    int wtime = w;
	    l -= w;
	    if ((w = str_end_with_word(s, l, "standard")) > 0) {
		l -= w;
	    }
	    else if ((w = str_end_with_word(s, l, "daylight")) > 0) {
		l -= w;
		dst = 1;
	    }
	    else {
		l += wtime;
	    }
	}
	else if ((w = str_end_with_word(s, l, "dst")) > 0) {
	    l -= w;
	    dst = 1;
	}

	{
	    const char *zn = s;
	    long sl = shrunk_size(s, l);
	    char shrunk_buff[MAX_WORD_LENGTH]; /* no terminator to be added */
	    const struct zone *z = 0;

	    if (sl <= 0) {
		sl = l;
	    }
	    else if (sl <= MAX_WORD_LENGTH) {
		char *d = shrunk_buff;
		sl = shrink_space(d, s, l);
		zn = d;
	    }

	    if (sl > 0 && sl <= MAX_WORD_LENGTH) {
		z = zonetab(zn, (unsigned int)sl);
	    }

	    if (z) {
		int d = z->offset;
		if (dst)
		    d += 3600;
		offset = INT2FIX(d);
		goto ok;
	    }
	}

	{
	    char *p;
	    int sign = 0;
	    long hour = 0, min = 0, sec = 0;

	    if (l > 3 &&
		(strncasecmp(s, "gmt", 3) == 0 ||
		 strncasecmp(s, "utc", 3) == 0)) {
		s += 3;
		l -= 3;
	    }
	    if (issign(*s)) {
		sign = *s == '-';
		s++;
		l--;

#define out_of_range(v, min, max) ((v) < (min) || (max) < (v))
		hour = STRTOUL(s, &p, 10);
		if (*p == ':') {
		    if (out_of_range(hour, 0, 23)) return Qnil;
		    s = ++p;
		    min = STRTOUL(s, &p, 10);
		    if (out_of_range(min, 0, 59)) return Qnil;
		    if (*p == ':') {
			s = ++p;
			sec = STRTOUL(s, &p, 10);
			if (out_of_range(sec, 0, 59)) return Qnil;
		    }
		}
		else if (*p == ',' || *p == '.') {
		    /* fractional hour */
		    size_t n;
		    int ov;
		    /* no over precision for offset; 10**-7 hour = 0.36
		     * milliseconds should be enough. */
		    const size_t max_digits = 7; /* 36 * 10**7 < 32-bit FIXNUM_MAX */

		    if (out_of_range(hour, 0, 23)) return Qnil;

		    n = (s + l) - ++p;
		    if (n > max_digits) n = max_digits;
		    sec = ruby_scan_digits(p, n, 10, &n, &ov);
		    if ((p += n) < s + l && *p >= ('5' + !(sec & 1)) && *p <= '9') {
			/* round half to even */
			sec++;
		    }
		    sec *= 36;
		    if (sign) {
			hour = -hour;
			sec = -sec;
		    }
		    if (n <= 2) {
			/* HH.nn or HH.n */
			if (n == 1) sec *= 10;
			offset = INT2FIX(sec + hour * 3600);
		    }
		    else {
			VALUE denom = rb_int_positive_pow(10, (int)(n - 2));
			offset = f_add(rb_rational_new(INT2FIX(sec), denom), INT2FIX(hour * 3600));
			if (rb_rational_den(offset) == INT2FIX(1)) {
			    offset = rb_rational_num(offset);
			}
		    }
		    goto ok;
		}
		else if (l > 2) {
		    size_t n;
		    int ov;

		    if (l >= 1)
			hour = ruby_scan_digits(&s[0], 2 - l % 2, 10, &n, &ov);
		    if (l >= 3)
			min  = ruby_scan_digits(&s[2 - l % 2], 2, 10, &n, &ov);
		    if (l >= 5)
			sec  = ruby_scan_digits(&s[4 - l % 2], 2, 10, &n, &ov);
		}
		sec += min * 60 + hour * 3600;
		if (sign) sec = -sec;
		offset = INT2FIX(sec);
#undef out_of_range
	    }
	}
    }
    RB_GC_GUARD(str);
  ok:
    return offset;
}

static int
day_num(VALUE s)
{
    int i;

    for (i = 0; i < (int)sizeof_array(abbr_days); i++)
	if (strncasecmp(abbr_days[i], RSTRING_PTR(s), 3) == 0)
	    break;
    return i;
}

static int
mon_num(VALUE s)
{
    int i;

    for (i = 0; i < (int)sizeof_array(abbr_months); i++)
	if (strncasecmp(abbr_months[i], RSTRING_PTR(s), 3) == 0)
	    break;
    return i + 1;
}

static int
parse_day_cb(VALUE m, VALUE hash)
{
    VALUE s;

    s = rb_reg_nth_match(1, m);
    set_hash("wday", INT2FIX(day_num(s)));
    return 1;
}

static int
parse_day(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"\\b(" ABBR_DAYS ")[^-/\\d\\s]*"
#else
	"(" VALID_DAYS ")"
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
#ifndef TIGHT_PARSER
    SUBS(str, pat, parse_day_cb);
#else
    SUBW(str, pat, parse_day_cb);
#endif
}

static int
parse_time2_cb(VALUE m, VALUE hash)
{
    VALUE h, min, s, f, p;

    h = rb_reg_nth_match(1, m);
    h = str2num(h);

    min = rb_reg_nth_match(2, m);
    if (!NIL_P(min))
	min = str2num(min);

    s = rb_reg_nth_match(3, m);
    if (!NIL_P(s))
	s = str2num(s);

    f = rb_reg_nth_match(4, m);

    if (!NIL_P(f))
	f = rb_rational_new2(str2num(f),
			     f_expt(INT2FIX(10), LONG2NUM(RSTRING_LEN(f))));

    p = rb_reg_nth_match(5, m);

    if (!NIL_P(p)) {
	int ih = NUM2INT(h);
	ih %= 12;
	if (*RSTRING_PTR(p) == 'P' || *RSTRING_PTR(p) == 'p')
	    ih += 12;
	h = INT2FIX(ih);
    }

    set_hash("hour", h);
    if (!NIL_P(min))
	set_hash("min", min);
    if (!NIL_P(s))
	set_hash("sec", s);
    if (!NIL_P(f))
	set_hash("sec_fraction", f);

    return 1;
}

static int
parse_time_cb(VALUE m, VALUE hash)
{
    static const char pat_source[] =
	    "\\A(\\d+)h?"
	      "(?:\\s*:?\\s*(\\d+)m?"
		"(?:"
		  "\\s*:?\\s*(\\d+)(?:[,.](\\d+))?s?"
		")?"
	      ")?"
	    "(?:\\s*([ap])(?:m\\b|\\.m\\.))?";
    static VALUE pat = Qnil;
    VALUE s1, s2;

    s1 = rb_reg_nth_match(1, m);
    s2 = rb_reg_nth_match(2, m);

    if (!NIL_P(s2))
	set_hash("zone", s2);

    REGCOMP_I(pat);

    {
	VALUE m = f_match(pat, s1);

	if (NIL_P(m))
	    return 0;
	parse_time2_cb(m, hash);
    }

    return 1;
}

static int
parse_time(VALUE str, VALUE hash)
{
    static const char pat_source[] =
		"("
		   "" NUMBER "+\\s*"
		   "(?:"
		     "(?:"
		       ":\\s*\\d+"
		       "(?:"
#ifndef TIGHT_PARSER
		         "\\s*:\\s*\\d+(?:[,.]\\d*)?"
#else
		         "\\s*:\\s*\\d+(?:[,.]\\d+)?"
#endif
		       ")?"
		     "|"
		       "h(?:\\s*\\d+m?(?:\\s*\\d+s?)?)?"
		     ")"
		     "(?:"
		       "\\s*"
		       "[ap](?:m\\b|\\.m\\.)"
		     ")?"
		   "|"
		     "[ap](?:m\\b|\\.m\\.)"
		   ")"
		 ")"
		 "(?:"
		   "\\s*"
		   "("
		     "(?:gmt|utc?)?[-+]\\d+(?:[,.:]\\d+(?::\\d+)?)?"
		   "|"
		     "(?-i:[[:alpha:].\\s]+)(?:standard|daylight)\\stime\\b"
		   "|"
		     "(?-i:[[:alpha:]]+)(?:\\sdst)?\\b"
		   ")"
		")?";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
#ifndef TIGHT_PARSER
    SUBS(str, pat, parse_time_cb);
#else
    SUBT(str, pat, parse_time_cb);
#endif
}

#define BEGIN_ERA "\\b"
#define END_ERA "(?!(?<!\\.)[a-z])"

#ifdef TIGHT_PARSER
static int
parse_era1_cb(VALUE m, VALUE hash)
{
    return 1;
}

static int
parse_era1(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	BEGIN_ERA "(a(?:d\\b|\\.d\\.))" END_ERA;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBA(str, pat, parse_era1_cb);
}

static int
parse_era2_cb(VALUE m, VALUE hash)
{
    VALUE b;

    b = rb_reg_nth_match(1, m);
    if (*RSTRING_PTR(b) == 'B' ||
	*RSTRING_PTR(b) == 'b')
	set_hash("_bc", Qtrue);
    return 1;
}

static int
parse_era2(VALUE str, VALUE hash)
{
    static const char pat_source[] = BEGIN_ERA
	"(c(?:e\\b|\\.e\\.)|b(?:ce\\b|\\.c\\.e\\.)|b(?:c\\b|\\.c\\.))"
	END_ERA;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBB(str, pat, parse_era2_cb);
}

static int
parse_era(VALUE str, VALUE hash)
{
    if (parse_era1(str, hash)) /* pre */
	goto ok;
    if (parse_era2(str, hash)) /* post */
	goto ok;
    return 0;
  ok:
    return 1;
}
#endif

#ifdef TIGHT_PARSER
static int
check_year_width(VALUE y)
{
    const char *s;
    long l;

    l = RSTRING_LEN(y);
    if (l < 2) return 0;
    s = RSTRING_PTR(y);
    if (!isdigit((unsigned char)s[1])) return 0;
    return (l == 2 || !isdigit((unsigned char)s[2]));
}

static int
check_apost(VALUE a, VALUE b, VALUE c)
{
    int f = 0;

    if (!NIL_P(a) && *RSTRING_PTR(a) == '\'') {
	if (!check_year_width(a))
	    return 0;
	f++;
    }
    if (!NIL_P(b) && *RSTRING_PTR(b) == '\'') {
	if (!check_year_width(b))
	    return 0;
	if (!NIL_P(c))
	    return 0;
	f++;
    }
    if (!NIL_P(c) && *RSTRING_PTR(c) == '\'') {
	if (!check_year_width(c))
	    return 0;
	f++;
    }
    if (f > 1)
	return 0;
    return 1;
}
#endif

static int
parse_eu_cb(VALUE m, VALUE hash)
{
#ifndef TIGHT_PARSER
    VALUE y, mon, d, b;

    d = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    b = rb_reg_nth_match(3, m);
    y = rb_reg_nth_match(4, m);

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, !NIL_P(b) &&
	(*RSTRING_PTR(b) == 'B' ||
	 *RSTRING_PTR(b) == 'b'));
#else
    VALUE y, mon, d;

    d = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

    if (!check_apost(d, mon, y))
	return 0;

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
#endif
    return 1;
}

static int
parse_eu(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifdef TIGHT_PARSER
		BOS
		FPW_COM FPT_COM
#endif
#ifndef TIGHT_PARSER
		"('?" NUMBER "+)[^-\\d\\s]*"
#else
		"(\\d+)(?:(?:st|nd|rd|th)\\b)?"
#endif
		 "\\s*"
#ifndef TIGHT_PARSER
		 "(" ABBR_MONTHS ")[^-\\d\\s']*"
#else
		 "(" VALID_MONTHS ")"
#endif
		 "(?:"
		   "\\s*"
#ifndef TIGHT_PARSER
		   "(?:"
		     BEGIN_ERA
		     "(c(?:e|\\.e\\.)|b(?:ce|\\.c\\.e\\.)|a(?:d|\\.d\\.)|b(?:c|\\.c\\.))"
		     END_ERA
		   ")?"
		   "\\s*"
		   "('?-?\\d+(?:(?:st|nd|rd|th)\\b)?)"
#else
		   "(?:" FPA ")?"
		   "\\s*"
		   "([-']?\\d+)"
		   "\\s*"
		   "(?:" FPA "|" FPB ")?"
#endif
		")?"
#ifdef TIGHT_PARSER
		COM_FPT COM_FPW
		EOS
#endif
		;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_eu_cb);
}

static int
parse_us_cb(VALUE m, VALUE hash)
{
#ifndef TIGHT_PARSER
    VALUE y, mon, d, b;

    mon = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);

    b = rb_reg_nth_match(3, m);
    y = rb_reg_nth_match(4, m);

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, !NIL_P(b) &&
	(*RSTRING_PTR(b) == 'B' ||
	 *RSTRING_PTR(b) == 'b'));
#else
    VALUE y, mon, d;

    mon = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

    if (!check_apost(mon, d, y))
	return 0;

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
#endif
    return 1;
}

static int
parse_us(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifdef TIGHT_PARSER
		BOS
		FPW_COM FPT_COM
#endif
#ifndef TIGHT_PARSER
		"\\b(" ABBR_MONTHS ")[^-\\d\\s']*"
#else
		"\\b(" VALID_MONTHS ")"
#endif
		 "\\s*"
#ifndef TIGHT_PARSER
		 "('?\\d+)[^-\\d\\s']*"
#else
		 "('?\\d+)(?:(?:st|nd|rd|th)\\b)?"
		COM_FPT
#endif
		 "(?:"
		   "\\s*+,?"
		   "\\s*+"
#ifndef TIGHT_PARSER
		   "(c(?:e|\\.e\\.)|b(?:ce|\\.c\\.e\\.)|a(?:d|\\.d\\.)|b(?:c|\\.c\\.))?"
		   "\\s*"
		   "('?-?\\d+)"
#else
		   "(?:" FPA ")?"
		   "\\s*"
		   "([-']?\\d+)"
		   "\\s*"
		   "(?:" FPA "|" FPB ")?"
#endif
		")?"
#ifdef TIGHT_PARSER
		COM_FPT COM_FPW
		EOS
#endif
		;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_us_cb);
}

static int
parse_iso_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    y = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    d = rb_reg_nth_match(3, m);

#ifdef TIGHT_PARSER
    if (!check_apost(y, mon, d))
	return 0;
#endif

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_iso(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"('?[-+]?" NUMBER "+)-(\\d+)-('?-?\\d+)"
#else
	BOS
	FPW_COM FPT_COM
	"([-+']?\\d+)-(\\d+)-([-']?\\d+)"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_0(pat);
    SUBS(str, pat, parse_iso_cb);
}

static int
parse_iso21_cb(VALUE m, VALUE hash)
{
    VALUE y, w, d;

    y = rb_reg_nth_match(1, m);
    w = rb_reg_nth_match(2, m);
    d = rb_reg_nth_match(3, m);

    if (!NIL_P(y))
	set_hash("cwyear", str2num(y));
    set_hash("cweek", str2num(w));
    if (!NIL_P(d))
	set_hash("cwday", str2num(d));

    return 1;
}

static int
parse_iso21(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"\\b(\\d{2}|\\d{4})?-?w(\\d{2})(?:-?(\\d))?\\b"
#else
	BOS
	FPW_COM FPT_COM
	"(\\d{2}|\\d{4})?-?w(\\d{2})(?:-?(\\d))?"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_iso21_cb);
}

static int
parse_iso22_cb(VALUE m, VALUE hash)
{
    VALUE d;

    d = rb_reg_nth_match(1, m);
    set_hash("cwday", str2num(d));
    return 1;
}

static int
parse_iso22(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"-w-(\\d)\\b"
#else
	BOS
	FPW_COM FPT_COM
	"-w-(\\d)"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_iso22_cb);
}

static int
parse_iso23_cb(VALUE m, VALUE hash)
{
    VALUE mon, d;

    mon = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);

    if (!NIL_P(mon))
	set_hash("mon", str2num(mon));
    set_hash("mday", str2num(d));

    return 1;
}

static int
parse_iso23(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"--(\\d{2})?-(\\d{2})\\b"
#else
	BOS
	FPW_COM FPT_COM
	"--(\\d{2})?-(\\d{2})"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_0(pat);
    SUBS(str, pat, parse_iso23_cb);
}

static int
parse_iso24_cb(VALUE m, VALUE hash)
{
    VALUE mon, d;

    mon = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);

    set_hash("mon", str2num(mon));
    if (!NIL_P(d))
	set_hash("mday", str2num(d));

    return 1;
}

static int
parse_iso24(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"--(\\d{2})(\\d{2})?\\b"
#else
	BOS
	FPW_COM FPT_COM
	"--(\\d{2})(\\d{2})?"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_0(pat);
    SUBS(str, pat, parse_iso24_cb);
}

static int
parse_iso25_cb(VALUE m, VALUE hash)
{
    VALUE y, d;

    y = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);

    set_hash("year", str2num(y));
    set_hash("yday", str2num(d));

    return 1;
}

static int
parse_iso25(VALUE str, VALUE hash)
{
    static const char pat0_source[] =
#ifndef TIGHT_PARSER
	"[,.](\\d{2}|\\d{4})-\\d{3}\\b"
#else
	BOS
	FPW_COM FPT_COM
	"[,.](\\d{2}|\\d{4})-\\d{3}"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat0 = Qnil;
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"\\b(\\d{2}|\\d{4})-(\\d{3})\\b"
#else
	BOS
	FPW_COM FPT_COM
	"(\\d{2}|\\d{4})-(\\d{3})"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_0(pat0);
    REGCOMP_0(pat);

    if (!NIL_P(f_match(pat0, str)))
	return 0;
    SUBS(str, pat, parse_iso25_cb);
}

static int
parse_iso26_cb(VALUE m, VALUE hash)
{
    VALUE d;

    d = rb_reg_nth_match(1, m);
    set_hash("yday", str2num(d));

    return 1;
}
static int
parse_iso26(VALUE str, VALUE hash)
{
    static const char pat0_source[] =
#ifndef TIGHT_PARSER
	"\\d-\\d{3}\\b"
#else
	BOS
	FPW_COM FPT_COM
	"\\d-\\d{3}"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat0 = Qnil;
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"\\b-(\\d{3})\\b"
#else
	BOS
	FPW_COM FPT_COM
	"-(\\d{3})"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_0(pat0);
    REGCOMP_0(pat);

    if (!NIL_P(f_match(pat0, str)))
	return 0;
    SUBS(str, pat, parse_iso26_cb);
}

static int
parse_iso2(VALUE str, VALUE hash)
{
    if (parse_iso21(str, hash))
	goto ok;
    if (parse_iso22(str, hash))
	goto ok;
    if (parse_iso23(str, hash))
	goto ok;
    if (parse_iso24(str, hash))
	goto ok;
    if (parse_iso25(str, hash))
	goto ok;
    if (parse_iso26(str, hash))
	goto ok;
    return 0;

  ok:
    return 1;
}

#define JISX0301_ERA_INITIALS "mtshr"
#define JISX0301_DEFAULT_ERA 'H' /* obsolete */

static int
gengo(int c)
{
    int e;

    switch (c) {
      case 'M': case 'm': e = 1867; break;
      case 'T': case 't': e = 1911; break;
      case 'S': case 's': e = 1925; break;
      case 'H': case 'h': e = 1988; break;
      case 'R': case 'r': e = 2018; break;
      default:  e = 0; break;
    }
    return e;
}

static int
parse_jis_cb(VALUE m, VALUE hash)
{
    VALUE e, y, mon, d;
    int ep;

    e = rb_reg_nth_match(1, m);
    y = rb_reg_nth_match(2, m);
    mon = rb_reg_nth_match(3, m);
    d = rb_reg_nth_match(4, m);

    ep = gengo(*RSTRING_PTR(e));

    set_hash("year", f_add(str2num(y), INT2FIX(ep)));
    set_hash("mon", str2num(mon));
    set_hash("mday", str2num(d));

    return 1;
}

static int
parse_jis(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
        "\\b([" JISX0301_ERA_INITIALS "])(\\d+)\\.(\\d+)\\.(\\d+)"
#else
	BOS
	FPW_COM FPT_COM
        "([" JISX0301_ERA_INITIALS "])(\\d+)\\.(\\d+)\\.(\\d+)"
	TEE_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_jis_cb);
}

static int
parse_vms11_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    d = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

#ifdef TIGHT_PARSER
    if (!check_apost(d, mon, y))
	return 0;
#endif

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_vms11(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"('?-?" NUMBER "+)-(" ABBR_MONTHS ")[^-/.]*"
	"-('?-?\\d+)"
#else
	BOS
	FPW_COM FPT_COM
	"([-']?\\d+)-(" DOTLESS_VALID_MONTHS ")"
	"-([-']?\\d+)"
	COM_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_vms11_cb);
}

static int
parse_vms12_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    mon = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

#ifdef TIGHT_PARSER
    if (!check_apost(mon, d, y))
	return 0;
#endif

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_vms12(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"\\b(" ABBR_MONTHS ")[^-/.]*"
	"-('?-?\\d+)(?:-('?-?\\d+))?"
#else
	BOS
	FPW_COM FPT_COM
	"(" DOTLESS_VALID_MONTHS ")"
	"-([-']?\\d+)(?:-([-']?\\d+))?"
	COM_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_vms12_cb);
}

static int
parse_vms(VALUE str, VALUE hash)
{
    if (parse_vms11(str, hash))
	goto ok;
    if (parse_vms12(str, hash))
	goto ok;
    return 0;

  ok:
    return 1;
}

static int
parse_sla_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    y = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    d = rb_reg_nth_match(3, m);

#ifdef TIGHT_PARSER
    if (!check_apost(y, mon, d))
	return 0;
#endif

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_sla(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"('?-?" NUMBER "+)/\\s*('?\\d+)(?:\\D\\s*('?-?\\d+))?"
#else
	BOS
	FPW_COM FPT_COM
	"([-']?\\d+)/\\s*('?\\d+)(?:(?:[-/]|\\s+)\\s*([-']?\\d+))?"
	COM_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_sla_cb);
}

#ifdef TIGHT_PARSER
static int
parse_sla2_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    d = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

    if (!check_apost(d, mon, y))
	return 0;

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_sla2(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	BOS
	FPW_COM FPT_COM
	"([-']?\\d+)/\\s*(" DOTLESS_VALID_MONTHS ")(?:(?:[-/]|\\s+)\\s*([-']?\\d+))?"
	COM_FPT COM_FPW
	EOS
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_sla2_cb);
}

static int
parse_sla3_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    mon = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

    if (!check_apost(mon, d, y))
	return 0;

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_sla3(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	BOS
	FPW_COM FPT_COM
	"(" DOTLESS_VALID_MONTHS ")/\\s*([-']?\\d+)(?:(?:[-/]|\\s+)\\s*([-']?\\d+))?"
	COM_FPT COM_FPW
	EOS
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_sla3_cb);
}
#endif

static int
parse_dot_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    y = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    d = rb_reg_nth_match(3, m);

#ifdef TIGHT_PARSER
    if (!check_apost(y, mon, d))
	return 0;
#endif

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_dot(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"('?-?" NUMBER "+)\\.\\s*('?\\d+)\\.\\s*('?-?\\d+)"
#else
	BOS
	FPW_COM FPT_COM
	"([-']?\\d+)\\.\\s*(\\d+)\\.\\s*([-']?\\d+)"
	COM_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_dot_cb);
}

#ifdef TIGHT_PARSER
static int
parse_dot2_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    d = rb_reg_nth_match(1, m);
    mon = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

    if (!check_apost(d, mon, y))
	return 0;

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_dot2(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	BOS
	FPW_COM FPT_COM
	"([-']?\\d+)\\.\\s*(" DOTLESS_VALID_MONTHS ")(?:(?:[./])\\s*([-']?\\d+))?"
	COM_FPT COM_FPW
	EOS
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_dot2_cb);
}

static int
parse_dot3_cb(VALUE m, VALUE hash)
{
    VALUE y, mon, d;

    mon = rb_reg_nth_match(1, m);
    d = rb_reg_nth_match(2, m);
    y = rb_reg_nth_match(3, m);

    if (!check_apost(mon, d, y))
	return 0;

    mon = INT2FIX(mon_num(mon));

    s3e(hash, y, mon, d, 0);
    return 1;
}

static int
parse_dot3(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	BOS
	FPW_COM FPT_COM
	"(" DOTLESS_VALID_MONTHS ")\\.\\s*([-']?\\d+)(?:(?:[./])\\s*([-']?\\d+))?"
	COM_FPT COM_FPW
	EOS
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_dot3_cb);
}
#endif

static int
parse_year_cb(VALUE m, VALUE hash)
{
    VALUE y;

    y = rb_reg_nth_match(1, m);
    set_hash("year", str2num(y));
    return 1;
}

static int
parse_year(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"'(\\d+)\\b"
#else
	BOS
	FPW_COM FPT_COM
	"'(\\d+)"
	COM_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_0(pat);
    SUBS(str, pat, parse_year_cb);
}

static int
parse_mon_cb(VALUE m, VALUE hash)
{
    VALUE mon;

    mon = rb_reg_nth_match(1, m);
    set_hash("mon", INT2FIX(mon_num(mon)));
    return 1;
}

static int
parse_mon(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"\\b(" ABBR_MONTHS ")\\S*"
#else
	BOS
	FPW_COM FPT_COM
	"(" VALID_MONTHS ")"
	COM_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_mon_cb);
}

static int
parse_mday_cb(VALUE m, VALUE hash)
{
    VALUE d;

    d = rb_reg_nth_match(1, m);
    set_hash("mday", str2num(d));
    return 1;
}

static int
parse_mday(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifndef TIGHT_PARSER
	"(" NUMBER "+)(st|nd|rd|th)\\b"
#else
	BOS
	FPW_COM FPT_COM
	"(\\d+)(st|nd|rd|th)"
	COM_FPT COM_FPW
	EOS
#endif
	;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_mday_cb);
}

static int
n2i(const char *s, long f, long w)
{
    long e, i;
    int v;

    e = f + w;
    v = 0;
    for (i = f; i < e; i++) {
	v *= 10;
	v += s[i] - '0';
    }
    return v;
}

static int
parse_ddd_cb(VALUE m, VALUE hash)
{
    VALUE s1, s2, s3, s4, s5;
    const char *cs2, *cs3, *cs5;
    long l2, l3, l4, l5;

    s1 = rb_reg_nth_match(1, m);
    s2 = rb_reg_nth_match(2, m);
    s3 = rb_reg_nth_match(3, m);
    s4 = rb_reg_nth_match(4, m);
    s5 = rb_reg_nth_match(5, m);

    cs2 = RSTRING_PTR(s2);
    l2 = RSTRING_LEN(s2);

    switch (l2) {
      case 2:
	if (NIL_P(s3) && !NIL_P(s4))
	    set_hash("sec",  INT2FIX(n2i(cs2, l2-2, 2)));
	else
	    set_hash("mday", INT2FIX(n2i(cs2,    0, 2)));
	break;
      case 4:
	if (NIL_P(s3) && !NIL_P(s4)) {
	    set_hash("sec",  INT2FIX(n2i(cs2, l2-2, 2)));
	    set_hash("min",  INT2FIX(n2i(cs2, l2-4, 2)));
	}
	else {
	    set_hash("mon",  INT2FIX(n2i(cs2,    0, 2)));
	    set_hash("mday", INT2FIX(n2i(cs2,    2, 2)));
	}
	break;
      case 6:
	if (NIL_P(s3) && !NIL_P(s4)) {
	    set_hash("sec",  INT2FIX(n2i(cs2, l2-2, 2)));
	    set_hash("min",  INT2FIX(n2i(cs2, l2-4, 2)));
	    set_hash("hour", INT2FIX(n2i(cs2, l2-6, 2)));
	}
	else {
	    int                  y = n2i(cs2,    0, 2);
	    if (!NIL_P(s1) && *RSTRING_PTR(s1) == '-')
		y = -y;
	    set_hash("year", INT2FIX(y));
	    set_hash("mon",  INT2FIX(n2i(cs2,    2, 2)));
	    set_hash("mday", INT2FIX(n2i(cs2,    4, 2)));
	}
	break;
      case 8:
      case 10:
      case 12:
      case 14:
	if (NIL_P(s3) && !NIL_P(s4)) {
	    set_hash("sec",  INT2FIX(n2i(cs2, l2-2, 2)));
	    set_hash("min",  INT2FIX(n2i(cs2, l2-4, 2)));
	    set_hash("hour", INT2FIX(n2i(cs2, l2-6, 2)));
	    set_hash("mday", INT2FIX(n2i(cs2, l2-8, 2)));
	    if (l2 >= 10)
		set_hash("mon", INT2FIX(n2i(cs2, l2-10, 2)));
	    if (l2 == 12) {
		int y = n2i(cs2, l2-12, 2);
		if (!NIL_P(s1) && *RSTRING_PTR(s1) == '-')
		    y = -y;
		set_hash("year", INT2FIX(y));
	    }
	    if (l2 == 14) {
		int y = n2i(cs2, l2-14, 4);
		if (!NIL_P(s1) && *RSTRING_PTR(s1) == '-')
		    y = -y;
		set_hash("year", INT2FIX(y));
		set_hash("_comp", Qfalse);
	    }
	}
	else {
	    int                  y = n2i(cs2,    0, 4);
	    if (!NIL_P(s1) && *RSTRING_PTR(s1) == '-')
		y = -y;
	    set_hash("year", INT2FIX(y));
	    set_hash("mon",  INT2FIX(n2i(cs2,    4, 2)));
	    set_hash("mday", INT2FIX(n2i(cs2,    6, 2)));
	    if (l2 >= 10)
		set_hash("hour", INT2FIX(n2i(cs2,    8, 2)));
	    if (l2 >= 12)
		set_hash("min",  INT2FIX(n2i(cs2,   10, 2)));
	    if (l2 >= 14)
		set_hash("sec",  INT2FIX(n2i(cs2,   12, 2)));
	    set_hash("_comp", Qfalse);
	}
	break;
      case 3:
	if (NIL_P(s3) && !NIL_P(s4)) {
	    set_hash("sec",  INT2FIX(n2i(cs2, l2-2, 2)));
	    set_hash("min",  INT2FIX(n2i(cs2, l2-3, 1)));
	}
	else
	    set_hash("yday", INT2FIX(n2i(cs2,    0, 3)));
	break;
      case 5:
	if (NIL_P(s3) && !NIL_P(s4)) {
	    set_hash("sec",  INT2FIX(n2i(cs2, l2-2, 2)));
	    set_hash("min",  INT2FIX(n2i(cs2, l2-4, 2)));
	    set_hash("hour", INT2FIX(n2i(cs2, l2-5, 1)));
	}
	else {
	    int                  y = n2i(cs2,    0, 2);
	    if (!NIL_P(s1) && *RSTRING_PTR(s1) == '-')
		y = -y;
	    set_hash("year", INT2FIX(y));
	    set_hash("yday", INT2FIX(n2i(cs2,    2, 3)));
	}
	break;
      case 7:
	if (NIL_P(s3) && !NIL_P(s4)) {
	    set_hash("sec",  INT2FIX(n2i(cs2, l2-2, 2)));
	    set_hash("min",  INT2FIX(n2i(cs2, l2-4, 2)));
	    set_hash("hour", INT2FIX(n2i(cs2, l2-6, 2)));
	    set_hash("mday", INT2FIX(n2i(cs2, l2-7, 1)));
	}
	else {
	    int                  y = n2i(cs2,    0, 4);
	    if (!NIL_P(s1) && *RSTRING_PTR(s1) == '-')
		y = -y;
	    set_hash("year", INT2FIX(y));
	    set_hash("yday", INT2FIX(n2i(cs2,    4, 3)));
	}
	break;
    }
    RB_GC_GUARD(s2);
    if (!NIL_P(s3)) {
	cs3 = RSTRING_PTR(s3);
	l3 = RSTRING_LEN(s3);

	if (!NIL_P(s4)) {
	    switch (l3) {
	      case 2:
	      case 4:
	      case 6:
		set_hash("sec", INT2FIX(n2i(cs3, l3-2, 2)));
		if (l3 >= 4)
		    set_hash("min", INT2FIX(n2i(cs3, l3-4, 2)));
		if (l3 >= 6)
		    set_hash("hour", INT2FIX(n2i(cs3, l3-6, 2)));
		break;
	    }
	}
	else {
	    switch (l3) {
	      case 2:
	      case 4:
	      case 6:
		set_hash("hour", INT2FIX(n2i(cs3, 0, 2)));
		if (l3 >= 4)
		    set_hash("min", INT2FIX(n2i(cs3, 2, 2)));
		if (l3 >= 6)
		    set_hash("sec", INT2FIX(n2i(cs3, 4, 2)));
		break;
	    }
	}
	RB_GC_GUARD(s3);
    }
    if (!NIL_P(s4)) {
	l4 = RSTRING_LEN(s4);

	set_hash("sec_fraction",
		 rb_rational_new2(str2num(s4),
				  f_expt(INT2FIX(10), LONG2NUM(l4))));
    }
    if (!NIL_P(s5)) {
	cs5 = RSTRING_PTR(s5);
	l5 = RSTRING_LEN(s5);

	set_hash("zone", s5);

	if (*cs5 == '[') {
            const char *s1, *s2;
	    VALUE zone;

            l5 -= 2;
            s1 = cs5 + 1;
            s2 = memchr(s1, ':', l5);
	    if (s2) {
		s2++;
                zone = rb_str_subseq(s5, s2 - cs5, l5 - (s2 - s1));
                s5 = rb_str_subseq(s5, 1, s2 - s1);
	    }
            else {
                zone = rb_str_subseq(s5, 1, l5);
                if (isdigit((unsigned char)*s1))
                    s5 = rb_str_append(rb_str_new_cstr("+"), zone);
                else
                    s5 = zone;
            }
	    set_hash("zone", zone);
            set_hash("offset", date_zone_to_diff(s5));
	}
	RB_GC_GUARD(s5);
    }

    return 1;
}

static int
parse_ddd(VALUE str, VALUE hash)
{
    static const char pat_source[] =
#ifdef TIGHT_PARSER
		BOS
#endif
		"([-+]?)(" NUMBER "{2,14})"
		  "(?:"
		    "\\s*"
		    "t?"
		    "\\s*"
		    "(\\d{2,6})?(?:[,.](\\d*))?"
		  ")?"
		  "(?:"
		    "\\s*"
		    "("
		      "z\\b"
		    "|"
		      "[-+]\\d{1,4}\\b"
		    "|"
		      "\\[[-+]?\\d[^\\]]*\\]"
		    ")"
		")?"
#ifdef TIGHT_PARSER
		EOS
#endif
		;
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_ddd_cb);
}

#ifndef TIGHT_PARSER
static int
parse_bc_cb(VALUE m, VALUE hash)
{
    set_hash("_bc", Qtrue);
    return 1;
}

static int
parse_bc(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\b(bc\\b|bce\\b|b\\.c\\.|b\\.c\\.e\\.)";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_bc_cb);
}

static int
parse_frag_cb(VALUE m, VALUE hash)
{
    VALUE s, n;

    s = rb_reg_nth_match(1, m);

    if (!NIL_P(ref_hash("hour")) && NIL_P(ref_hash("mday"))) {
	n = str2num(s);
	if (f_ge_p(n, INT2FIX(1)) &&
	    f_le_p(n, INT2FIX(31)))
	    set_hash("mday", n);
    }
    if (!NIL_P(ref_hash("mday")) && NIL_P(ref_hash("hour"))) {
	n = str2num(s);
	if (f_ge_p(n, INT2FIX(0)) &&
	    f_le_p(n, INT2FIX(24)))
	    set_hash("hour", n);
    }

    return 1;
}

static int
parse_frag(VALUE str, VALUE hash)
{
    static const char pat_source[] = "\\A\\s*(\\d{1,2})\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    SUBS(str, pat, parse_frag_cb);
}
#endif

#ifdef TIGHT_PARSER
static int
parse_dummy_cb(VALUE m, VALUE hash)
{
    return 1;
}

static int
parse_wday_only(VALUE str, VALUE hash)
{
    static const char pat_source[] = "\\A\\s*" FPW "\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_0(pat);
    SUBS(str, pat, parse_dummy_cb);
}

static int
parse_time_only(VALUE str, VALUE hash)
{
    static const char pat_source[] = "\\A\\s*" FPT "\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_0(pat);
    SUBS(str, pat, parse_dummy_cb);
}

static int
parse_wday_and_time(VALUE str, VALUE hash)
{
    static const char pat_source[] = "\\A\\s*(" FPW "\\s+" FPT "|" FPT "\\s+" FPW ")\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_0(pat);
    SUBS(str, pat, parse_dummy_cb);
}

static unsigned
have_invalid_char_p(VALUE s)
{
    long i;

    for (i = 0; i < RSTRING_LEN(s); i++)
	if (iscntrl((unsigned char)RSTRING_PTR(s)[i]) &&
	    !isspace((unsigned char)RSTRING_PTR(s)[i]))
	    return 1;
    return 0;
}
#endif

#define HAVE_ALPHA (1<<0)
#define HAVE_DIGIT (1<<1)
#define HAVE_DASH (1<<2)
#define HAVE_DOT (1<<3)
#define HAVE_SLASH (1<<4)

static unsigned
check_class(VALUE s)
{
    unsigned flags;
    long i;

    flags = 0;
    for (i = 0; i < RSTRING_LEN(s); i++) {
	if (isalpha((unsigned char)RSTRING_PTR(s)[i]))
	    flags |= HAVE_ALPHA;
	if (isdigit((unsigned char)RSTRING_PTR(s)[i]))
	    flags |= HAVE_DIGIT;
	if (RSTRING_PTR(s)[i] == '-')
	    flags |= HAVE_DASH;
	if (RSTRING_PTR(s)[i] == '.')
	    flags |= HAVE_DOT;
	if (RSTRING_PTR(s)[i] == '/')
	    flags |= HAVE_SLASH;
    }
    return flags;
}

#define HAVE_ELEM_P(x) ((check_class(str) & (x)) == (x))

#ifdef TIGHT_PARSER
#define PARSER_ERROR return rb_hash_new()
#endif

VALUE
date__parse(VALUE str, VALUE comp)
{
    VALUE backref, hash;

#ifdef TIGHT_PARSER
    if (have_invalid_char_p(str))
	PARSER_ERROR;
#endif

    backref = rb_backref_get();
    rb_match_busy(backref);

    {
	static const char pat_source[] =
#ifndef TIGHT_PARSER
	    "[^-+',./:@[:alnum:]\\[\\]]+"
#else
	    "[^[:graph:]]+"
#endif
	    ;
	static VALUE pat = Qnil;

	REGCOMP_0(pat);
	str = rb_str_dup(str);
	f_gsub_bang(str, pat, asp_string());
    }

    hash = rb_hash_new();
    set_hash("_comp", comp);

    if (HAVE_ELEM_P(HAVE_ALPHA))
	parse_day(str, hash);
    if (HAVE_ELEM_P(HAVE_DIGIT))
	parse_time(str, hash);

#ifdef TIGHT_PARSER
    if (HAVE_ELEM_P(HAVE_ALPHA))
	parse_era(str, hash);
#endif

    if (HAVE_ELEM_P(HAVE_ALPHA|HAVE_DIGIT)) {
	if (parse_eu(str, hash))
	    goto ok;
	if (parse_us(str, hash))
	    goto ok;
    }
    if (HAVE_ELEM_P(HAVE_DIGIT|HAVE_DASH))
	if (parse_iso(str, hash))
	    goto ok;
    if (HAVE_ELEM_P(HAVE_DIGIT|HAVE_DOT))
	if (parse_jis(str, hash))
	    goto ok;
    if (HAVE_ELEM_P(HAVE_ALPHA|HAVE_DIGIT|HAVE_DASH))
	if (parse_vms(str, hash))
	    goto ok;
    if (HAVE_ELEM_P(HAVE_DIGIT|HAVE_SLASH))
	if (parse_sla(str, hash))
	    goto ok;
#ifdef TIGHT_PARSER
    if (HAVE_ELEM_P(HAVE_ALPHA|HAVE_DIGIT|HAVE_SLASH)) {
	if (parse_sla2(str, hash))
	    goto ok;
	if (parse_sla3(str, hash))
	    goto ok;
    }
#endif
    if (HAVE_ELEM_P(HAVE_DIGIT|HAVE_DOT))
	if (parse_dot(str, hash))
	    goto ok;
#ifdef TIGHT_PARSER
    if (HAVE_ELEM_P(HAVE_ALPHA|HAVE_DIGIT|HAVE_DOT)) {
	if (parse_dot2(str, hash))
	    goto ok;
	if (parse_dot3(str, hash))
	    goto ok;
    }
#endif
    if (HAVE_ELEM_P(HAVE_DIGIT))
	if (parse_iso2(str, hash))
	    goto ok;
    if (HAVE_ELEM_P(HAVE_DIGIT))
	if (parse_year(str, hash))
	    goto ok;
    if (HAVE_ELEM_P(HAVE_ALPHA))
	if (parse_mon(str, hash))
	    goto ok;
    if (HAVE_ELEM_P(HAVE_DIGIT))
	if (parse_mday(str, hash))
	    goto ok;
    if (HAVE_ELEM_P(HAVE_DIGIT))
	if (parse_ddd(str, hash))
	    goto ok;

#ifdef TIGHT_PARSER
    if (parse_wday_only(str, hash))
	goto ok;
    if (parse_time_only(str, hash))
	    goto ok;
    if (parse_wday_and_time(str, hash))
	goto ok;

    PARSER_ERROR; /* not found */
#endif

  ok:
#ifndef TIGHT_PARSER
    if (HAVE_ELEM_P(HAVE_ALPHA))
	parse_bc(str, hash);
    if (HAVE_ELEM_P(HAVE_DIGIT))
	parse_frag(str, hash);
#endif

    {
        if (RTEST(del_hash("_bc"))) {
	    VALUE y;

	    y = ref_hash("cwyear");
	    if (!NIL_P(y)) {
		y = f_add(f_negate(y), INT2FIX(1));
		set_hash("cwyear", y);
	    }
	    y = ref_hash("year");
	    if (!NIL_P(y)) {
		y = f_add(f_negate(y), INT2FIX(1));
		set_hash("year", y);
	    }
	}

        if (RTEST(del_hash("_comp"))) {
	    VALUE y;

	    y = ref_hash("cwyear");
	    if (!NIL_P(y))
		if (f_ge_p(y, INT2FIX(0)) && f_le_p(y, INT2FIX(99))) {
		    if (f_ge_p(y, INT2FIX(69)))
			set_hash("cwyear", f_add(y, INT2FIX(1900)));
		    else
			set_hash("cwyear", f_add(y, INT2FIX(2000)));
		}
	    y = ref_hash("year");
	    if (!NIL_P(y))
		if (f_ge_p(y, INT2FIX(0)) && f_le_p(y, INT2FIX(99))) {
		    if (f_ge_p(y, INT2FIX(69)))
			set_hash("year", f_add(y, INT2FIX(1900)));
		    else
			set_hash("year", f_add(y, INT2FIX(2000)));
		}
	}

    }

    {
	VALUE zone = ref_hash("zone");
	if (!NIL_P(zone) && NIL_P(ref_hash("offset")))
	    set_hash("offset", date_zone_to_diff(zone));
    }

    rb_backref_set(backref);

    return hash;
}

static VALUE
comp_year69(VALUE y)
{
    if (f_ge_p(y, INT2FIX(69)))
	return f_add(y, INT2FIX(1900));
    return f_add(y, INT2FIX(2000));
}

static VALUE
comp_year50(VALUE y)
{
    if (f_ge_p(y, INT2FIX(50)))
	return f_add(y, INT2FIX(1900));
    return f_add(y, INT2FIX(2000));
}

static VALUE
sec_fraction(VALUE f)
{
    return rb_rational_new2(str2num(f),
			    f_expt(INT2FIX(10),
				   LONG2NUM(RSTRING_LEN(f))));
}

#define SNUM 14

static int
iso8601_ext_datetime_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1], y;

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    if (!NIL_P(s[1])) {
	if (!NIL_P(s[3])) set_hash("mday", str2num(s[3]));
	if (strcmp(RSTRING_PTR(s[1]), "-") != 0) {
	    y = str2num(s[1]);
	    if (RSTRING_LEN(s[1]) < 4)
		y = comp_year69(y);
	    set_hash("year", y);
	}
	if (NIL_P(s[2])) {
	    if (strcmp(RSTRING_PTR(s[1]), "-") != 0)
		return 0;
	}
	else
	    set_hash("mon", str2num(s[2]));
    }
    else if (!NIL_P(s[5])) {
	set_hash("yday", str2num(s[5]));
	if (!NIL_P(s[4])) {
	    y = str2num(s[4]);
	    if (RSTRING_LEN(s[4]) < 4)
		y = comp_year69(y);
	    set_hash("year", y);
	}
    }
    else if (!NIL_P(s[8])) {
	set_hash("cweek", str2num(s[7]));
	set_hash("cwday", str2num(s[8]));
	if (!NIL_P(s[6])) {
	    y = str2num(s[6]);
	    if (RSTRING_LEN(s[6]) < 4)
		y = comp_year69(y);
	    set_hash("cwyear", y);
	}
    }
    else if (!NIL_P(s[9])) {
	set_hash("cwday", str2num(s[9]));
    }
    if (!NIL_P(s[10])) {
	set_hash("hour", str2num(s[10]));
	set_hash("min", str2num(s[11]));
	if (!NIL_P(s[12]))
	    set_hash("sec", str2num(s[12]));
    }
    if (!NIL_P(s[13])) {
	set_hash("sec_fraction", sec_fraction(s[13]));
    }
    if (!NIL_P(s[14])) {
	set_hash("zone", s[14]);
	set_hash("offset", date_zone_to_diff(s[14]));
    }

    return 1;
}

static int
iso8601_ext_datetime(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(?:([-+]?\\d{2,}|-)-(\\d{2})?(?:-(\\d{2}))?|"
		"([-+]?\\d{2,})?-(\\d{3})|"
		"(\\d{4}|\\d{2})?-w(\\d{2})-(\\d)|"
		"-w-(\\d))"
	"(?:t"
	"(\\d{2}):(\\d{2})(?::(\\d{2})(?:[,.](\\d+))?)?"
	"(z|[-+]\\d{2}(?::?\\d{2})?)?)?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, iso8601_ext_datetime_cb);
}

#undef SNUM
#define SNUM 17

static int
iso8601_bas_datetime_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1], y;

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    if (!NIL_P(s[3])) {
	set_hash("mday", str2num(s[3]));
	if (strcmp(RSTRING_PTR(s[1]), "--") != 0) {
	    y = str2num(s[1]);
	    if (RSTRING_LEN(s[1]) < 4)
		y = comp_year69(y);
	    set_hash("year", y);
	}
	if (*RSTRING_PTR(s[2]) == '-') {
	    if (strcmp(RSTRING_PTR(s[1]), "--") != 0)
		return 0;
	}
	else
	    set_hash("mon", str2num(s[2]));
    }
    else if (!NIL_P(s[5])) {
	set_hash("yday", str2num(s[5]));
	y = str2num(s[4]);
	if (RSTRING_LEN(s[4]) < 4)
	    y = comp_year69(y);
	set_hash("year", y);
    }
    else if (!NIL_P(s[6])) {
	set_hash("yday", str2num(s[6]));
    }
    else if (!NIL_P(s[9])) {
	set_hash("cweek", str2num(s[8]));
	set_hash("cwday", str2num(s[9]));
	y = str2num(s[7]);
	if (RSTRING_LEN(s[7]) < 4)
	    y = comp_year69(y);
	set_hash("cwyear", y);
    }
    else if (!NIL_P(s[11])) {
	set_hash("cweek", str2num(s[10]));
	set_hash("cwday", str2num(s[11]));
    }
    else if (!NIL_P(s[12])) {
	set_hash("cwday", str2num(s[12]));
    }
    if (!NIL_P(s[13])) {
	set_hash("hour", str2num(s[13]));
	set_hash("min", str2num(s[14]));
	if (!NIL_P(s[15]))
	    set_hash("sec", str2num(s[15]));
    }
    if (!NIL_P(s[16])) {
	set_hash("sec_fraction", sec_fraction(s[16]));
    }
    if (!NIL_P(s[17])) {
	set_hash("zone", s[17]);
	set_hash("offset", date_zone_to_diff(s[17]));
    }

    return 1;
}

static int
iso8601_bas_datetime(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(?:([-+]?(?:\\d{4}|\\d{2})|--)(\\d{2}|-)(\\d{2})|"
		   "([-+]?(?:\\d{4}|\\d{2}))(\\d{3})|"
		   "-(\\d{3})|"
		   "(\\d{4}|\\d{2})w(\\d{2})(\\d)|"
		   "-w(\\d{2})(\\d)|"
		   "-w-(\\d))"
	"(?:t?"
	"(\\d{2})(\\d{2})(?:(\\d{2})(?:[,.](\\d+))?)?"
	"(z|[-+]\\d{2}(?:\\d{2})?)?)?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, iso8601_bas_datetime_cb);
}

#undef SNUM
#define SNUM 5

static int
iso8601_ext_time_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    set_hash("hour", str2num(s[1]));
    set_hash("min", str2num(s[2]));
    if (!NIL_P(s[3]))
	set_hash("sec", str2num(s[3]));
    if (!NIL_P(s[4]))
	set_hash("sec_fraction", sec_fraction(s[4]));
    if (!NIL_P(s[5])) {
	set_hash("zone", s[5]);
	set_hash("offset", date_zone_to_diff(s[5]));
    }

    return 1;
}

#define iso8601_bas_time_cb iso8601_ext_time_cb

static int
iso8601_ext_time(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(\\d{2}):(\\d{2})(?::(\\d{2})(?:[,.](\\d+))?"
	"(z|[-+]\\d{2}(:?\\d{2})?)?)?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, iso8601_ext_time_cb);
}

static int
iso8601_bas_time(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(\\d{2})(\\d{2})(?:(\\d{2})(?:[,.](\\d+))?"
	"(z|[-+]\\d{2}(\\d{2})?)?)?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, iso8601_bas_time_cb);
}

VALUE
date__iso8601(VALUE str)
{
    VALUE backref, hash;

    backref = rb_backref_get();
    rb_match_busy(backref);

    hash = rb_hash_new();

    if (iso8601_ext_datetime(str, hash))
	goto ok;
    if (iso8601_bas_datetime(str, hash))
	goto ok;
    if (iso8601_ext_time(str, hash))
	goto ok;
    if (iso8601_bas_time(str, hash))
	goto ok;

  ok:
    rb_backref_set(backref);

    return hash;
}

#undef SNUM
#define SNUM 8

static int
rfc3339_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    set_hash("year", str2num(s[1]));
    set_hash("mon", str2num(s[2]));
    set_hash("mday", str2num(s[3]));
    set_hash("hour", str2num(s[4]));
    set_hash("min", str2num(s[5]));
    set_hash("sec", str2num(s[6]));
    set_hash("zone", s[8]);
    set_hash("offset", date_zone_to_diff(s[8]));
    if (!NIL_P(s[7]))
	set_hash("sec_fraction", sec_fraction(s[7]));

    return 1;
}

static int
rfc3339(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(-?\\d{4})-(\\d{2})-(\\d{2})"
	"(?:t|\\s)"
	"(\\d{2}):(\\d{2}):(\\d{2})(?:\\.(\\d+))?"
	"(z|[-+]\\d{2}:\\d{2})\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, rfc3339_cb);
}

VALUE
date__rfc3339(VALUE str)
{
    VALUE backref, hash;

    backref = rb_backref_get();
    rb_match_busy(backref);

    hash = rb_hash_new();
    rfc3339(str, hash);
    rb_backref_set(backref);
    return hash;
}

#undef SNUM
#define SNUM 8

static int
xmlschema_datetime_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    set_hash("year", str2num(s[1]));
    if (!NIL_P(s[2]))
	set_hash("mon", str2num(s[2]));
    if (!NIL_P(s[3]))
	set_hash("mday", str2num(s[3]));
    if (!NIL_P(s[4]))
	set_hash("hour", str2num(s[4]));
    if (!NIL_P(s[5]))
	set_hash("min", str2num(s[5]));
    if (!NIL_P(s[6]))
	set_hash("sec", str2num(s[6]));
    if (!NIL_P(s[7]))
	set_hash("sec_fraction", sec_fraction(s[7]));
    if (!NIL_P(s[8])) {
	set_hash("zone", s[8]);
	set_hash("offset", date_zone_to_diff(s[8]));
    }

    return 1;
}

static int
xmlschema_datetime(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(-?\\d{4,})(?:-(\\d{2})(?:-(\\d{2}))?)?"
	"(?:t"
	  "(\\d{2}):(\\d{2}):(\\d{2})(?:\\.(\\d+))?)?"
	"(z|[-+]\\d{2}:\\d{2})?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, xmlschema_datetime_cb);
}

#undef SNUM
#define SNUM 5

static int
xmlschema_time_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    set_hash("hour", str2num(s[1]));
    set_hash("min", str2num(s[2]));
    if (!NIL_P(s[3]))
	set_hash("sec", str2num(s[3]));
    if (!NIL_P(s[4]))
	set_hash("sec_fraction", sec_fraction(s[4]));
    if (!NIL_P(s[5])) {
	set_hash("zone", s[5]);
	set_hash("offset", date_zone_to_diff(s[5]));
    }

    return 1;
}

static int
xmlschema_time(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(\\d{2}):(\\d{2}):(\\d{2})(?:\\.(\\d+))?"
	"(z|[-+]\\d{2}:\\d{2})?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, xmlschema_time_cb);
}

#undef SNUM
#define SNUM 4

static int
xmlschema_trunc_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    if (!NIL_P(s[1]))
	set_hash("mon", str2num(s[1]));
    if (!NIL_P(s[2]))
	set_hash("mday", str2num(s[2]));
    if (!NIL_P(s[3]))
	set_hash("mday", str2num(s[3]));
    if (!NIL_P(s[4])) {
	set_hash("zone", s[4]);
	set_hash("offset", date_zone_to_diff(s[4]));
    }

    return 1;
}

static int
xmlschema_trunc(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(?:--(\\d{2})(?:-(\\d{2}))?|---(\\d{2}))"
	"(z|[-+]\\d{2}:\\d{2})?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, xmlschema_trunc_cb);
}

VALUE
date__xmlschema(VALUE str)
{
    VALUE backref, hash;

    backref = rb_backref_get();
    rb_match_busy(backref);

    hash = rb_hash_new();

    if (xmlschema_datetime(str, hash))
	goto ok;
    if (xmlschema_time(str, hash))
	goto ok;
    if (xmlschema_trunc(str, hash))
	goto ok;

  ok:
    rb_backref_set(backref);

    return hash;
}

#undef SNUM
#define SNUM 8

static int
rfc2822_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1], y;

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    if (!NIL_P(s[1])) {
	set_hash("wday", INT2FIX(day_num(s[1])));
    }
    set_hash("mday", str2num(s[2]));
    set_hash("mon", INT2FIX(mon_num(s[3])));
    y = str2num(s[4]);
    if (RSTRING_LEN(s[4]) < 4)
	y = comp_year50(y);
    set_hash("year", y);
    set_hash("hour", str2num(s[5]));
    set_hash("min", str2num(s[6]));
    if (!NIL_P(s[7]))
	set_hash("sec", str2num(s[7]));
    set_hash("zone", s[8]);
    set_hash("offset", date_zone_to_diff(s[8]));

    return 1;
}

static int
rfc2822(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(?:(" ABBR_DAYS ")\\s*,\\s+)?"
	"(\\d{1,2})\\s+"
	"(" ABBR_MONTHS ")\\s+"
	"(-?\\d{2,})\\s+"
	"(\\d{2}):(\\d{2})(?::(\\d{2}))?\\s*"
	"([-+]\\d{4}|ut|gmt|e[sd]t|c[sd]t|m[sd]t|p[sd]t|[a-ik-z])\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, rfc2822_cb);
}

VALUE
date__rfc2822(VALUE str)
{
    VALUE backref, hash;

    backref = rb_backref_get();
    rb_match_busy(backref);

    hash = rb_hash_new();
    rfc2822(str, hash);
    rb_backref_set(backref);
    return hash;
}

#undef SNUM
#define SNUM 8

static int
httpdate_type1_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    set_hash("wday", INT2FIX(day_num(s[1])));
    set_hash("mday", str2num(s[2]));
    set_hash("mon", INT2FIX(mon_num(s[3])));
    set_hash("year", str2num(s[4]));
    set_hash("hour", str2num(s[5]));
    set_hash("min", str2num(s[6]));
    set_hash("sec", str2num(s[7]));
    set_hash("zone", s[8]);
    set_hash("offset", INT2FIX(0));

    return 1;
}

static int
httpdate_type1(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(" ABBR_DAYS ")\\s*,\\s+"
	"(\\d{2})\\s+"
	"(" ABBR_MONTHS ")\\s+"
	"(-?\\d{4})\\s+"
	"(\\d{2}):(\\d{2}):(\\d{2})\\s+"
	"(gmt)\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, httpdate_type1_cb);
}

#undef SNUM
#define SNUM 8

static int
httpdate_type2_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1], y;

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    set_hash("wday", INT2FIX(day_num(s[1])));
    set_hash("mday", str2num(s[2]));
    set_hash("mon", INT2FIX(mon_num(s[3])));
    y = str2num(s[4]);
    if (f_ge_p(y, INT2FIX(0)) && f_le_p(y, INT2FIX(99)))
	y = comp_year69(y);
    set_hash("year", y);
    set_hash("hour", str2num(s[5]));
    set_hash("min", str2num(s[6]));
    set_hash("sec", str2num(s[7]));
    set_hash("zone", s[8]);
    set_hash("offset", INT2FIX(0));

    return 1;
}

static int
httpdate_type2(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(" DAYS ")\\s*,\\s+"
	"(\\d{2})\\s*-\\s*"
	"(" ABBR_MONTHS ")\\s*-\\s*"
	"(\\d{2})\\s+"
	"(\\d{2}):(\\d{2}):(\\d{2})\\s+"
	"(gmt)\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, httpdate_type2_cb);
}

#undef SNUM
#define SNUM 7

static int
httpdate_type3_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    set_hash("wday", INT2FIX(day_num(s[1])));
    set_hash("mon", INT2FIX(mon_num(s[2])));
    set_hash("mday", str2num(s[3]));
    set_hash("hour", str2num(s[4]));
    set_hash("min", str2num(s[5]));
    set_hash("sec", str2num(s[6]));
    set_hash("year", str2num(s[7]));

    return 1;
}

static int
httpdate_type3(VALUE str, VALUE hash)
{
    static const char pat_source[] =
	"\\A\\s*(" ABBR_DAYS ")\\s+"
	"(" ABBR_MONTHS ")\\s+"
	"(\\d{1,2})\\s+"
	"(\\d{2}):(\\d{2}):(\\d{2})\\s+"
	"(\\d{4})\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, httpdate_type3_cb);
}

VALUE
date__httpdate(VALUE str)
{
    VALUE backref, hash;

    backref = rb_backref_get();
    rb_match_busy(backref);

    hash = rb_hash_new();

    if (httpdate_type1(str, hash))
	goto ok;
    if (httpdate_type2(str, hash))
	goto ok;
    if (httpdate_type3(str, hash))
	goto ok;

  ok:
    rb_backref_set(backref);

    return hash;
}

#undef SNUM
#define SNUM 9

static int
jisx0301_cb(VALUE m, VALUE hash)
{
    VALUE s[SNUM + 1];
    int ep;

    {
	int i;
	s[0] = Qnil;
	for (i = 1; i <= SNUM; i++)
	    s[i] = rb_reg_nth_match(i, m);
    }

    ep = gengo(NIL_P(s[1]) ? JISX0301_DEFAULT_ERA : *RSTRING_PTR(s[1]));
    set_hash("year", f_add(str2num(s[2]), INT2FIX(ep)));
    set_hash("mon", str2num(s[3]));
    set_hash("mday", str2num(s[4]));
    if (!NIL_P(s[5])) {
	set_hash("hour", str2num(s[5]));
	if (!NIL_P(s[6]))
	    set_hash("min", str2num(s[6]));
	if (!NIL_P(s[7]))
	    set_hash("sec", str2num(s[7]));
    }
    if (!NIL_P(s[8]))
	set_hash("sec_fraction", sec_fraction(s[8]));
    if (!NIL_P(s[9])) {
	set_hash("zone", s[9]);
	set_hash("offset", date_zone_to_diff(s[9]));
    }

    return 1;
}

static int
jisx0301(VALUE str, VALUE hash)
{
    static const char pat_source[] =
        "\\A\\s*([" JISX0301_ERA_INITIALS "])?(\\d{2})\\.(\\d{2})\\.(\\d{2})"
	"(?:t"
	"(?:(\\d{2}):(\\d{2})(?::(\\d{2})(?:[,.](\\d*))?)?"
	"(z|[-+]\\d{2}(?::?\\d{2})?)?)?)?\\s*\\z";
    static VALUE pat = Qnil;

    REGCOMP_I(pat);
    MATCH(str, pat, jisx0301_cb);
}

VALUE
date__jisx0301(VALUE str)
{
    VALUE backref, hash;

    backref = rb_backref_get();
    rb_match_busy(backref);

    hash = rb_hash_new();
    if (jisx0301(str, hash))
	goto ok;
    hash = date__iso8601(str);

  ok:
    rb_backref_set(backref);
    return hash;
}

/*
Local variables:
c-file-style: "ruby"
End:
*/
