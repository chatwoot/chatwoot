/*
 * pg_text_decoder.c - PG::TextDecoder module
 * $Id$
 *
 */

/*
 *
 * Type casts for decoding PostgreSQL string representations to Ruby objects.
 *
 * Decoder classes are defined with pg_define_coder(). This creates a new coder class and
 * assigns a decoder function.
 *
 * Signature of all type cast decoders is:
 *    VALUE decoder_function(t_pg_coder *this, const char *val, int len, int tuple, int field, int enc_idx)
 *
 * Params:
 *   this     - The data part of the coder object that belongs to the decoder function.
 *   val, len - The text or binary data to decode.
 *              The caller ensures, that text data (format=0) is zero terminated so that val[len]=0.
 *              The memory should be used read-only by the callee.
 *   tuple    - Row of the value within the result set.
 *   field    - Column of the value within the result set.
 *   enc_idx  - Index of the Encoding that any output String should get assigned.
 *
 * Returns:
 *   The type casted Ruby object.
 *
 */

#include "ruby/version.h"
#include "pg.h"
#include "pg_util.h"
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif
#include <ctype.h>
#include <time.h>
#if !defined(_WIN32)
#include <arpa/inet.h>
#include <sys/socket.h>
#endif
#include <string.h>

VALUE rb_mPG_TextDecoder;
static ID s_id_Rational;
static ID s_id_new;
static ID s_id_utc;
static ID s_id_getlocal;
static ID s_id_BigDecimal;

static VALUE s_IPAddr;
static VALUE s_vmasks4;
static VALUE s_vmasks6;
static VALUE s_nan, s_pos_inf, s_neg_inf;
static int use_ipaddr_alloc;
static ID s_id_lshift;
static ID s_id_add;
static ID s_id_mask;
static ID s_ivar_family;
static ID s_ivar_addr;
static ID s_ivar_mask_addr;

/*
 * Document-class: PG::TextDecoder::Boolean < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL boolean type
 * to Ruby true or false values.
 *
 */
static VALUE
pg_text_dec_boolean(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	if (len < 1) {
		rb_raise( rb_eTypeError, "wrong data for text boolean converter in tuple %d field %d", tuple, field);
	}
	return *val == 't' ? Qtrue : Qfalse;
}

/*
 * Document-class: PG::TextDecoder::String < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL text output to
 * to Ruby String object. The output value will have the character encoding
 * set with PG::Connection#internal_encoding= .
 *
 */
VALUE
pg_text_dec_string(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	VALUE ret = rb_str_new( val, len );
	PG_ENCODING_SET_NOCHECK( ret, enc_idx );
	return ret;
}

/*
 * Document-class: PG::TextDecoder::Integer < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL integer types
 * to Ruby Integer objects.
 *
 */
static VALUE
pg_text_dec_integer(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	long i;
	int max_len;

	if( sizeof(i) >= 8 && FIXNUM_MAX >= 1000000000000000000LL ){
		/* 64 bit system can safely handle all numbers up to 18 digits as Fixnum */
		max_len = 18;
	} else if( sizeof(i) >= 4 && FIXNUM_MAX >= 1000000000LL ){
		/* 32 bit system can safely handle all numbers up to 9 digits as Fixnum */
		max_len = 9;
	} else {
		/* unknown -> don't use fast path for int conversion */
		max_len = 0;
	}

	if( len <= max_len ){
		/* rb_cstr2inum() seems to be slow, so we do the int conversion by hand.
		 * This proved to be 40% faster by the following benchmark:
		 *
		 *   conn.type_mapping_for_results = PG::BasicTypeMapForResults.new conn
		 *   Benchmark.measure do
		 *     conn.exec("select generate_series(1,1000000)").values }
		 *   end
		 */
		const char *val_pos = val;
		char digit = *val_pos;
		int neg;
		int error = 0;

		if( digit=='-' ){
			neg = 1;
			i = 0;
		}else if( digit>='0' && digit<='9' ){
			neg = 0;
			i = digit - '0';
		} else {
			error = 1;
		}

		while (!error && (digit=*++val_pos)) {
			if( digit>='0' && digit<='9' ){
				i = i * 10 + (digit - '0');
			} else {
				error = 1;
			}
		}

		if( !error ){
			return LONG2FIX(neg ? -i : i);
		}
	}
	/* Fallback to ruby method if number too big or unrecognized. */
	return rb_cstr2inum(val, 10);
}

/*
 * Document-class: PG::TextDecoder::Numeric < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL numeric types
 * to Ruby BigDecimal objects.
 *
 */
static VALUE
pg_text_dec_numeric(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	return rb_funcall(rb_cObject, s_id_BigDecimal, 1, rb_str_new(val, len));
}

/* called per autoload when TextDecoder::Numeric is used */
static VALUE
init_pg_text_decoder_numeric(VALUE rb_mPG_TextDecoder)
{
	rb_require("bigdecimal");
	s_id_BigDecimal = rb_intern("BigDecimal");

	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Numeric", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Numeric", pg_text_dec_numeric, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder );

	return Qnil;
}

/*
 * Document-class: PG::TextDecoder::Float < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL float4 and float8 types
 * to Ruby Float objects.
 *
 */
static VALUE
pg_text_dec_float(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	switch(*val) {
		case 'N':
			return s_nan;
		case 'I':
			return s_pos_inf;
		case '-':
			if (val[1] == 'I') {
				return s_neg_inf;
			} else {
				return rb_float_new(rb_cstr_to_dbl(val, Qfalse));
			}
		default:
			return rb_float_new(rb_cstr_to_dbl(val, Qfalse));
	}
}

struct pg_blob_initialization {
	char *blob_string;
	size_t length;
};

static VALUE pg_create_blob(VALUE v) {
	struct pg_blob_initialization *bi = (struct pg_blob_initialization *)v;
	return rb_str_new(bi->blob_string, bi->length);
}

static VALUE pg_pq_freemem(VALUE mem) {
  PQfreemem((void *)mem);
  return Qfalse;
}

/*
 * Document-class: PG::TextDecoder::Bytea < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL bytea type
 * to binary String objects.
 *
 */
static VALUE
pg_text_dec_bytea(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	struct pg_blob_initialization bi;

	bi.blob_string = (char *)PQunescapeBytea((unsigned char*)val, &bi.length);
	if (bi.blob_string == NULL) {
		rb_raise(rb_eNoMemError, "PQunescapeBytea failure: probably not enough memory");
	}
	return rb_ensure(pg_create_blob, (VALUE)&bi, pg_pq_freemem, (VALUE)bi.blob_string);
}

/*
 * array_isspace() --- a non-locale-dependent isspace()
 *
 * We used to use isspace() for parsing array values, but that has
 * undesirable results: an array value might be silently interpreted
 * differently depending on the locale setting.  Now we just hard-wire
 * the traditional ASCII definition of isspace().
 */
static int
array_isspace(char ch)
{
	if (ch == ' ' ||
		ch == '\t' ||
		ch == '\n' ||
		ch == '\r' ||
		ch == '\v' ||
		ch == '\f')
		return 1;
	return 0;
}

static int
array_isdim(char ch)
{
	if ( (ch >= '0' && ch <= '9') ||
		(ch == '-') ||
		(ch == '+') ||
		(ch == ':') )
		return 1;
	return 0;
}

static void
array_parser_error(t_pg_composite_coder *this, const char *text){
	if( (this->comp.flags & PG_CODER_FORMAT_ERROR_MASK) == PG_CODER_FORMAT_ERROR_TO_RAISE ){
		rb_raise( rb_eTypeError, "%s", text );
	}
}

/*
 * Array parser functions are thankfully borrowed from here:
 * https://github.com/dockyard/pg_array_parser
 */
static VALUE
read_array_without_dim(t_pg_composite_coder *this, int *index, const char *c_pg_array_string, int array_string_length, char *word, int enc_idx, int tuple, int field, t_pg_coder_dec_func dec_func)
{
	/* Return value: array */
	VALUE array;
	int word_index = 0;

	/* The current character in the input string. */
	char c;

	/*  0: Currently outside a quoted string, current word never quoted
	*  1: Currently inside a quoted string
	* -1: Currently outside a quoted string, current word previously quoted */
	int openQuote = 0;

	/* Inside quoted input means the next character should be treated literally,
	* instead of being treated as a metacharacter.
	* Outside of quoted input, means that the word shouldn't be pushed to the array,
	* used when the last entry was a subarray (which adds to the array itself). */
	int escapeNext = 0;

	array = rb_ary_new();

	/* Special case the empty array, so it doesn't need to be handled manually inside
	* the loop. */
	if(((*index) < array_string_length) && c_pg_array_string[*index] == '}')
	{
		return array;
	}

	for(;(*index) < array_string_length; ++(*index))
	{
		c = c_pg_array_string[*index];
		if(openQuote < 1)
		{
			if(c == this->delimiter || c == '}')
			{
				if(!escapeNext)
				{
					if(openQuote == 0 && word_index == 4 && !strncmp(word, "NULL", word_index))
					{
						rb_ary_push(array, Qnil);
					}
					else
					{
						VALUE val;
						word[word_index] = 0;
						val = dec_func(this->elem, word, word_index, tuple, field, enc_idx);
						rb_ary_push(array, val);
					}
				}
				if(c == '}')
				{
					return array;
				}
				escapeNext = 0;
				openQuote = 0;
				word_index = 0;
			}
			else if(c == '"')
			{
				openQuote = 1;
			}
			else if(c == '{')
			{
				VALUE subarray;
				(*index)++;
				subarray = read_array_without_dim(this, index, c_pg_array_string, array_string_length, word, enc_idx, tuple, field, dec_func);
				rb_ary_push(array, subarray);
				escapeNext = 1;
			}
			else if(c == 0)
			{
				array_parser_error( this, "premature end of the array string" );
				return array;
			}
			else
			{
				word[word_index] = c;
				word_index++;
			}
		}
		else if (escapeNext) {
			word[word_index] = c;
			word_index++;
			escapeNext = 0;
		}
		else if (c == '\\')
		{
			escapeNext = 1;
		}
		else if (c == '"')
		{
			openQuote = -1;
		}
		else
		{
			word[word_index] = c;
			word_index++;
		}
	}

	array_parser_error( this, "premature end of the array string" );
	return array;
}

/*
 * Document-class: PG::TextDecoder::Array < PG::CompositeDecoder
 *
 * This is a decoder class for PostgreSQL array types.
 *
 * It returns an Array with possibly an arbitrary number of sub-Arrays.
 * All values are decoded according to the #elements_type accessor.
 * Sub-arrays are decoded recursively.
 *
 * This decoder simply ignores any dimension decorations preceding the array values.
 * It returns all array values as regular ruby Array with a zero based index, regardless of the index given in the dimension decoration.
 *
 * An array decoder which respects dimension decorations is waiting to be implemented.
 *
 */
static VALUE
pg_text_dec_array(t_pg_coder *conv, const char *c_pg_array_string, int array_string_length, int tuple, int field, int enc_idx)
{
	int index = 0;
	int ndim = 0;
	VALUE ret;
	t_pg_composite_coder *this = (t_pg_composite_coder *)conv;

	/*
	 * If the input string starts with dimension info, read and use that.
	 * Otherwise, we require the input to be in curly-brace style, and we
	 * prescan the input to determine dimensions.
	 *
	 * Dimension info takes the form of one or more [n] or [m:n] items. The
	 * outer loop iterates once per dimension item.
	 */
	for (;;)
	{
		/*
		 * Note: we currently allow whitespace between, but not within,
		 * dimension items.
		 */
		while (array_isspace(c_pg_array_string[index]))
			index++;
		if (c_pg_array_string[index] != '[')
			break;				/* no more dimension items */
		index++;

		while (array_isdim(c_pg_array_string[index]))
			index++;

		if (c_pg_array_string[index] != ']'){
			array_parser_error( this, "missing \"]\" in array dimensions");
			break;
		}
		index++;

		ndim++;
	}

	if (ndim == 0)
	{
		/* No array dimensions */
	}
	else
	{
		/* If array dimensions are given, expect '=' operator */
		if (c_pg_array_string[index] != '=') {
			array_parser_error( this, "missing assignment operator");
			index-=2; /* jump back to before "]" so that we don't break behavior to pg < 1.1 */
		}
		index++;

		while (array_isspace(c_pg_array_string[index]))
			index++;
	}

	if (c_pg_array_string[index] != '{')
		array_parser_error( this, "array value must start with \"{\" or dimension information");
	index++;

	if ( index < array_string_length && c_pg_array_string[index] == '}' ) {
		/* avoid buffer allocation for empty array */
		ret = rb_ary_new();
	} else {
		t_pg_coder_dec_func dec_func = pg_coder_dec_func(this->elem, 0);
		/* create a buffer of the same length, as that will be the worst case */
		VALUE buf = rb_str_new(NULL, array_string_length);
		char *word = RSTRING_PTR(buf);

		ret = read_array_without_dim(this, &index, c_pg_array_string, array_string_length, word, enc_idx, tuple, field, dec_func);

		RB_GC_GUARD(buf);
	}

	if (c_pg_array_string[index] != '}' )
		array_parser_error( this, "array value must end with \"}\"");
	index++;

	/* only whitespace is allowed after the closing brace */
	for(;index < array_string_length; ++index)
	{
		if (!array_isspace(c_pg_array_string[index]))
			array_parser_error( this, "malformed array literal: Junk after closing right brace.");
	}

	return ret;
}

/*
 * Document-class: PG::TextDecoder::Identifier < PG::SimpleDecoder
 *
 * This is the decoder class for PostgreSQL identifiers.
 *
 * Returns an Array of identifiers:
 *   PG::TextDecoder::Identifier.new.decode('schema."table"."column"')
 *      => ["schema", "table", "column"]
 *
 */
static VALUE
pg_text_dec_identifier(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	/* Return value: array */
	VALUE array;
	VALUE elem;
	int word_index = 0;
	int index;
	/* Use a buffer of the same length, as that will be the worst case */
	PG_VARIABLE_LENGTH_ARRAY(char, word, len + 1, NAMEDATALEN)

	/* The current character in the input string. */
	char c;

	/*  0: Currently outside a quoted string
	*  1: Currently inside a quoted string, last char was a quote
	*  2: Currently inside a quoted string, last char was no quote */
	int openQuote = 0;

	array = rb_ary_new();

	for(index = 0; index < len; ++index) {
		c = val[index];
		if(c == '.' && openQuote < 2 ) {
			word[word_index] = 0;

			elem = pg_text_dec_string(conv, word, word_index, tuple, field, enc_idx);
			rb_ary_push(array, elem);

			openQuote = 0;
			word_index = 0;
		} else if(c == '"') {
			if (openQuote == 1) {
				word[word_index] = c;
				word_index++;
				openQuote = 2;
			} else if (openQuote == 2){
				openQuote = 1;
			} else {
				openQuote = 2;
			}
		} else {
			word[word_index] = c;
			word_index++;
		}
	}

	word[word_index] = 0;
	elem = pg_text_dec_string(conv, word, word_index, tuple, field, enc_idx);
	rb_ary_push(array, elem);

	return array;
}

/*
 * Document-class: PG::TextDecoder::FromBase64 < PG::CompositeDecoder
 *
 * This is a decoder class for conversion of base64 encoded data
 * to it's binary representation. It outputs a binary Ruby String
 * or some other Ruby object, if a #elements_type decoder was defined.
 *
 */
static VALUE
pg_text_dec_from_base64(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	t_pg_composite_coder *this = (t_pg_composite_coder *)conv;
	t_pg_coder_dec_func dec_func = pg_coder_dec_func(this->elem, this->comp.format);
	int decoded_len;
	/* create a buffer of the expected decoded length */
	VALUE out_value = rb_str_new(NULL, BASE64_DECODED_SIZE(len));

	decoded_len = base64_decode( RSTRING_PTR(out_value), val, len );
	rb_str_set_len(out_value, decoded_len);

	/* Is it a pure String conversion? Then we can directly send out_value to the user. */
	if( this->comp.format == 0 && dec_func == pg_text_dec_string ){
		PG_ENCODING_SET_NOCHECK( out_value, enc_idx );
		return out_value;
	}
	if( this->comp.format == 1 && dec_func == pg_bin_dec_bytea ){
		PG_ENCODING_SET_NOCHECK( out_value, rb_ascii8bit_encindex() );
		return out_value;
	}
	out_value = dec_func(this->elem, RSTRING_PTR(out_value), decoded_len, tuple, field, enc_idx);

	return out_value;
}

static inline int char_to_digit(char c)
{
	return c - '0';
}

static int str2_to_int(const char *str)
{
	return char_to_digit(str[0]) * 10
			+ char_to_digit(str[1]);
}

static int parse_year(const char **str) {
	int year = 0;
	int i;
	const char * p = *str;

	for(i = 0; isdigit(*p) && i < 7; i++, p++) {
		year = 10 * year + char_to_digit(*p);
	}

	*str = p;
	return year;
}

#define TZ_NEG 1
#define TZ_POS 2

/*
 * Document-class: PG::TextDecoder::Timestamp < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL text timestamps
 * to Ruby Time objects.
 *
 * The following flags can be used to specify time interpretation when no timezone is given:
 * * +PG::Coder::TIMESTAMP_DB_UTC+ : Interpret timestamp as UTC time (default)
 * * +PG::Coder::TIMESTAMP_DB_LOCAL+ : Interpret timestamp as local time
 * * +PG::Coder::TIMESTAMP_APP_UTC+ : Return timestamp as UTC time (default)
 * * +PG::Coder::TIMESTAMP_APP_LOCAL+ : Return timestamp as local time
 *
 * Example:
 *   deco = PG::TextDecoder::Timestamp.new(flags: PG::Coder::TIMESTAMP_DB_UTC | PG::Coder::TIMESTAMP_APP_LOCAL)
 *   deco.decode("2000-01-01 00:00:00")  # => 2000-01-01 01:00:00 +0100
 *   deco.decode("2000-01-01 00:00:00.123-06")  # => 2000-01-01 00:00:00 -0600
 */
static VALUE pg_text_dec_timestamp(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	const char *str = val;
	int year, mon, day;
	int hour, min, sec;
	int nsec = 0;
	int tz_given = 0;
	int tz_hour = 0;
	int tz_min = 0;
	int tz_sec = 0;

	year = parse_year(&str);

	if ( year > 0
		&& str[0] == '-' && isdigit(str[1]) && isdigit(str[2])
		&& str[3] == '-' && isdigit(str[4]) && isdigit(str[5])
		&& str[6] == ' ' && isdigit(str[7]) && isdigit(str[8])
		&& str[9] == ':' && isdigit(str[10]) && isdigit(str[11])
		&& str[12] == ':' && isdigit(str[13]) && isdigit(str[14])
	) {

		mon = str2_to_int(str+1); str += 3;
		day = str2_to_int(str+1); str += 3;
		hour = str2_to_int(str+1); str += 3;
		min = str2_to_int(str+1); str += 3;
		sec = str2_to_int(str+1); str += 3;

		if (str[0] == '.' && isdigit(str[1])) {
			/* nano second part, up to 9 digits */
			static const int coef[9] = {
				100000000, 10000000, 1000000,
				100000, 10000, 1000, 100, 10, 1
			};
			int i;

			str++;
			for (i = 0; i < 9 && isdigit(*str); i++)
			{
				nsec += coef[i] * char_to_digit(*str++);
			}
			/* consume digits smaller than nsec */
			while(isdigit(*str)) str++;
		}

		if ((str[0] == '+' || str[0] == '-') && isdigit(str[1]) && isdigit(str[2])) {
			tz_given = str[0] == '-' ? TZ_NEG : TZ_POS;
			tz_hour = str2_to_int(str+1); str += 3;

			if (str[0] == ':' && isdigit(str[1]) && isdigit(str[2]))
			{
				tz_min = str2_to_int(str+1); str += 3;
			}
			if (str[0] == ':' && isdigit(str[1]) && isdigit(str[2]))
			{
				tz_sec = str2_to_int(str+1); str += 3;
			}
		}

		if (str[0] == ' ' && str[1] == 'B' && str[2] == 'C') {
			year = -year + 1;
			str += 3;
		}

		if (*str == '\0') { /* must have consumed all the string */
			VALUE sec_value;
			VALUE gmt_offset_value;
			VALUE res;

#if (RUBY_API_VERSION_MAJOR > 2 || (RUBY_API_VERSION_MAJOR == 2 && RUBY_API_VERSION_MINOR >= 3)) && defined(HAVE_TIMEGM)
			/* Fast path for time conversion */
			struct tm tm;
			struct timespec ts;
			tm.tm_year = year - 1900;
			tm.tm_mon = mon - 1;
			tm.tm_mday = day;
			tm.tm_hour = hour;
			tm.tm_min = min;
			tm.tm_sec = sec;
			tm.tm_isdst = -1;

			if (tz_given) {
				/* with timezone */
				time_t time = timegm(&tm);
				if (time != -1){
					int gmt_offset;

					gmt_offset = tz_hour * 3600 + tz_min * 60 + tz_sec;
					if (tz_given == TZ_NEG)
					{
						gmt_offset = - gmt_offset;
					}
					ts.tv_sec = time - gmt_offset;
					ts.tv_nsec = nsec;
					return rb_time_timespec_new(&ts, gmt_offset);
				}
			} else {
				/* without timezone */
				time_t time;

				if( conv->flags & PG_CODER_TIMESTAMP_DB_LOCAL ) {
					time = mktime(&tm);
				} else {
					time = timegm(&tm);
				}
				if (time != -1){
					ts.tv_sec = time;
					ts.tv_nsec = nsec;
					return rb_time_timespec_new(&ts, conv->flags & PG_CODER_TIMESTAMP_APP_LOCAL ? INT_MAX : INT_MAX-1);
				}
			}
			/* Some libc implementations fail to convert certain values,
			* so that we fall through to the slow path.
			*/
#endif
			if (nsec) {
				int sec_numerator = sec * 1000000 + nsec / 1000;
				int sec_denominator = 1000000;
				sec_value = rb_funcall(Qnil, s_id_Rational, 2,
						INT2NUM(sec_numerator), INT2NUM(sec_denominator));
			} else {
				sec_value = INT2NUM(sec);
			}

			if (tz_given) {
				/* with timezone */
				int gmt_offset;

				gmt_offset = tz_hour * 3600 + tz_min * 60 + tz_sec;
				if (tz_given == TZ_NEG)
				{
					gmt_offset = - gmt_offset;
				}
				gmt_offset_value = INT2NUM(gmt_offset);
			} else {
				/* without timezone */
				gmt_offset_value = conv->flags & PG_CODER_TIMESTAMP_DB_LOCAL ? Qnil : INT2NUM(0);
			}

			res = rb_funcall(rb_cTime, s_id_new, 7,
					INT2NUM(year),
					INT2NUM(mon),
					INT2NUM(day),
					INT2NUM(hour),
					INT2NUM(min),
					sec_value,
					gmt_offset_value);

			if (tz_given) {
				/* with timezone */
				return res;
			} else {
				/* without timezone */
				if( (conv->flags & PG_CODER_TIMESTAMP_DB_LOCAL) && (conv->flags & PG_CODER_TIMESTAMP_APP_LOCAL) ) {
					return res;
				} else if( conv->flags & PG_CODER_TIMESTAMP_APP_LOCAL ) {
					return rb_funcall(res, s_id_getlocal, 0);
				} else {
					return rb_funcall(res, s_id_utc, 0);
				}
			}
		}
	}

	/* fall through to string conversion */
	return pg_text_dec_string(conv, val, len, tuple, field, enc_idx);
}

/*
 * Document-class: PG::TextDecoder::Inet < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL inet type
 * to Ruby IPAddr values.
 *
 */
static VALUE
pg_text_dec_inet(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	VALUE ip;
#if defined(_WIN32)
	ip = rb_str_new(val, len);
	ip = rb_class_new_instance(1, &ip, s_IPAddr);
#else
	VALUE ip_int;
	VALUE vmasks;
	char dst[16];
	char buf[64];
	int af = strchr(val, '.') ? AF_INET : AF_INET6;
	int mask = -1;

	if (len >= 64) {
		rb_raise(rb_eTypeError, "too long data for text inet converter in tuple %d field %d", tuple, field);
	}

	if (len >= 4) {
		if (val[len-2] == '/') {
			mask = val[len-1] - '0';
			memcpy(buf, val, len-2);
			buf[len-2] = '\0';
			val = buf;
		} else if (val[len-3] == '/') {
			mask = (val[len-2]- '0')*10 + val[len-1] - '0';
			memcpy(buf, val, len-3);
			buf[len-3] = '\0';
			val = buf;
		} else if (val[len-4] == '/') {
			mask = (val[len-3]- '0')*100 + (val[len-2]- '0')*10 + val[len-1] - '0';
			memcpy(buf, val, len-4);
			buf[len-4] = '\0';
			val = buf;
		}
	}

	if (1 != inet_pton(af, val, dst)) {
		rb_raise(rb_eTypeError, "wrong data for text inet converter in tuple %d field %d val", tuple, field);
	}

	if (af == AF_INET) {
		unsigned int ip_int_native;

		if (mask == -1) {
			mask = 32;
		} else if (mask < 0 || mask > 32) {
			rb_raise(rb_eTypeError, "invalid mask for IPv4: %d", mask);
		}
		vmasks = s_vmasks4;

		ip_int_native = read_nbo32(dst);

		/* Work around broken IPAddr behavior of converting portion
		   of address after netmask to 0 */
		switch (mask) {
			case 0:
				ip_int_native = 0;
				break;
			case 32:
				/* nothing to do */
				break;
			default:
				ip_int_native &= ~((1UL<<(32-mask))-1);
				break;
		}

		ip_int = UINT2NUM(ip_int_native);
	} else {
		unsigned long long * dstllp = (unsigned long long *)dst;
		unsigned long long ip_int_native1;
		unsigned long long ip_int_native2;

		if (mask == -1) {
			mask = 128;
		} else if (mask < 0 || mask > 128) {
			rb_raise(rb_eTypeError, "invalid mask for IPv6: %d", mask);
		}
		vmasks = s_vmasks6;

		ip_int_native1 = read_nbo64(dstllp);
		dstllp++;
		ip_int_native2 = read_nbo64(dstllp);

		if (mask == 128) {
			/* nothing to do */
		} else if (mask == 64) {
			ip_int_native2 = 0;
		} else if (mask == 0) {
			ip_int_native1 = 0;
			ip_int_native2 = 0;
		} else if (mask < 64) {
			ip_int_native1 &= ~((1ULL<<(64-mask))-1);
			ip_int_native2 = 0;
		} else {
			ip_int_native2 &= ~((1ULL<<(128-mask))-1);
		}

		/* 4 Bignum allocations */
		ip_int = ULL2NUM(ip_int_native1);
		ip_int = rb_funcall(ip_int, s_id_lshift, 1, INT2NUM(64));
		ip_int = rb_funcall(ip_int, s_id_add, 1, ULL2NUM(ip_int_native2));
	}

	if (use_ipaddr_alloc) {
		ip = rb_obj_alloc(s_IPAddr);
		rb_ivar_set(ip, s_ivar_family, INT2NUM(af));
		rb_ivar_set(ip, s_ivar_addr, ip_int);
		rb_ivar_set(ip, s_ivar_mask_addr, RARRAY_AREF(vmasks, mask));
	} else {
		VALUE ip_args[2];
		ip_args[0] = ip_int;
		ip_args[1] = INT2NUM(af);
		ip = rb_class_new_instance(2, ip_args, s_IPAddr);
		ip = rb_funcall(ip, s_id_mask, 1, INT2NUM(mask));
	}

#endif
	return ip;
}

/* called per autoload when TextDecoder::Inet is used */
static VALUE
init_pg_text_decoder_inet(VALUE rb_mPG_TextDecoder)
{
	rb_require("ipaddr");
	s_IPAddr = rb_funcall(rb_cObject, rb_intern("const_get"), 1, rb_str_new2("IPAddr"));
	rb_global_variable(&s_IPAddr);
	s_ivar_family = rb_intern("@family");
	s_ivar_addr = rb_intern("@addr");
	s_ivar_mask_addr = rb_intern("@mask_addr");
	s_id_lshift = rb_intern("<<");
	s_id_add = rb_intern("+");
	s_id_mask = rb_intern("mask");

	use_ipaddr_alloc = RTEST(rb_eval_string("IPAddr.new.instance_variables.sort == [:@addr, :@family, :@mask_addr]"));

	s_vmasks4 = rb_eval_string("a = [0]*33; a[0] = 0; a[32] = 0xffffffff; 31.downto(1){|i| a[i] = a[i+1] - (1 << (31 - i))}; a.freeze");
	rb_global_variable(&s_vmasks4);
	s_vmasks6 = rb_eval_string("a = [0]*129; a[0] = 0; a[128] = 0xffffffffffffffffffffffffffffffff; 127.downto(1){|i| a[i] = a[i+1] - (1 << (127 - i))}; a.freeze");
	rb_global_variable(&s_vmasks6);

	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Inet", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Inet", pg_text_dec_inet, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder);

	return Qnil;
}


void
init_pg_text_decoder(void)
{
	s_id_Rational = rb_intern("Rational");
	s_id_new = rb_intern("new");
	s_id_utc = rb_intern("utc");
	s_id_getlocal = rb_intern("getlocal");

	s_nan = rb_eval_string("0.0/0.0");
	rb_global_variable(&s_nan);
	s_pos_inf = rb_eval_string("1.0/0.0");
	rb_global_variable(&s_pos_inf);
	s_neg_inf = rb_eval_string("-1.0/0.0");
	rb_global_variable(&s_neg_inf);

	/* This module encapsulates all decoder classes with text input format */
	rb_mPG_TextDecoder = rb_define_module_under( rb_mPG, "TextDecoder" );
	rb_define_private_method(rb_singleton_class(rb_mPG_TextDecoder), "init_inet", init_pg_text_decoder_inet, 0);
	rb_define_private_method(rb_singleton_class(rb_mPG_TextDecoder), "init_numeric", init_pg_text_decoder_numeric, 0);

	/* Make RDoc aware of the decoder classes... */
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Boolean", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Boolean", pg_text_dec_boolean, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder );
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Integer", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Integer", pg_text_dec_integer, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder );
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Float", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Float", pg_text_dec_float, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder );
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "String", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "String", pg_text_dec_string, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder );
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Bytea", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Bytea", pg_text_dec_bytea, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder );
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Identifier", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Identifier", pg_text_dec_identifier, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder );
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Timestamp", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Timestamp", pg_text_dec_timestamp, rb_cPG_SimpleDecoder, rb_mPG_TextDecoder);

	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Array", rb_cPG_CompositeDecoder ); */
	pg_define_coder( "Array", pg_text_dec_array, rb_cPG_CompositeDecoder, rb_mPG_TextDecoder );
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "FromBase64", rb_cPG_CompositeDecoder ); */
	pg_define_coder( "FromBase64", pg_text_dec_from_base64, rb_cPG_CompositeDecoder, rb_mPG_TextDecoder );
}
