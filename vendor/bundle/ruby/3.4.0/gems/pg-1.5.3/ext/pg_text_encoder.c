/*
 * pg_text_encoder.c - PG::TextEncoder module
 * $Id$
 *
 */

/*
 *
 * Type casts for encoding Ruby objects to PostgreSQL string representations.
 *
 * Encoder classes are defined with pg_define_coder(). This creates a new coder class and
 * assigns an encoder function. The encoder function can decide between two different options
 * to return the encoded data. It can either return it as a Ruby String object or write the
 * encoded data to a memory space provided by the caller. In the second case, the encoder
 * function is called twice, once for deciding the encoding option and returning the expected
 * data length, and a second time when the requested memory space was made available by the
 * calling function, to do the actual conversion and writing. Parameter intermediate can be
 * used to store data between these two calls.
 *
 * Signature of all type cast encoders is:
 *    int encoder_function(t_pg_coder *this, VALUE value, char *out, VALUE *intermediate)
 *
 * Params:
 *   this  - The data part of the coder object that belongs to the encoder function.
 *   value - The Ruby object to cast.
 *   out   - NULL for the first call,
 *           pointer to a buffer with the requested size for the second call.
 *   intermediate - Pointer to a VALUE that might be set by the encoding function to some
 *           value in the first call that can be retrieved later in the second call.
 *           This VALUE is not yet initialized by the caller.
 *   enc_idx  - Index of the output Encoding that strings should be converted to.
 *
 * Returns:
 *   >= 0  - If out==NULL the encoder function must return the expected output buffer size.
 *           This can be larger than the size of the second call, but may not be smaller.
 *           If out!=NULL the encoder function must return the actually used output buffer size
 *           without a termination character.
 *   -1    - The encoder function can alternatively return -1 to indicate that no second call
 *           is required, but the String value in *intermediate should be used instead.
 */


#include "pg.h"
#include "pg_util.h"
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif
#include <math.h>

VALUE rb_mPG_TextEncoder;
static ID s_id_encode;
static ID s_id_to_i;
static ID s_id_to_s;
static ID s_cBigDecimal;
static VALUE s_str_F;

static int pg_text_enc_integer(t_pg_coder *this, VALUE value, char *out, VALUE *intermediate, int enc_idx);

VALUE
pg_obj_to_i( VALUE value )
{
	switch (TYPE(value)) {
		case T_FIXNUM:
		case T_FLOAT:
		case T_BIGNUM:
			return value;
		default:
			return rb_funcall(value, s_id_to_i, 0);
	}
}

/*
 * Document-class: PG::TextEncoder::Boolean < PG::SimpleEncoder
 *
 * This is the encoder class for the PostgreSQL bool type.
 *
 * Ruby value false is encoded as SQL +FALSE+ value.
 * Ruby value true is encoded as SQL +TRUE+ value.
 * Any other value is sent as it's string representation.
 *
 */
static int
pg_text_enc_boolean(t_pg_coder *this, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	switch( TYPE(value) ){
		case T_FALSE:
			if(out) *out = 'f';
			return 1;
		case T_TRUE:
			if(out) *out = 't';
			return 1;
		case T_FIXNUM:
		case T_BIGNUM:
			if( NUM2LONG(value) == 0 ){
				if(out) *out = '0';
				return 1;
			} else if( NUM2LONG(value) == 1 ){
				if(out) *out = '1';
				return 1;
			} else {
				return pg_text_enc_integer(this, value, out, intermediate, enc_idx);
			}
		default:
			return pg_coder_enc_to_s(this, value, out, intermediate, enc_idx);
	}
	/* never reached */
	return 0;
}


/*
 * Document-class: PG::TextEncoder::String < PG::SimpleEncoder
 *
 * This is the encoder class for the PostgreSQL text types.
 *
 * Non-String values are expected to have method +to_s+ defined.
 *
 */
int
pg_coder_enc_to_s(t_pg_coder *this, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	VALUE str = rb_obj_as_string(value);
	if( ENCODING_GET(str) == enc_idx ){
		*intermediate = str;
	}else{
		*intermediate = rb_str_export_to_enc(str, rb_enc_from_index(enc_idx));
	}
	return -1;
}

static int
count_leading_zero_bits(unsigned long long x)
{
#if defined(__GNUC__) || defined(__clang__)
	return __builtin_clzll(x);
#elif defined(_MSC_VER)
	DWORD r = 0;
	_BitScanForward64(&r, x);
	return (int)r;
#else
	unsigned int a;
	for(a=0; a < sizeof(unsigned long long) * 8; a++){
		if( x & (1 << (sizeof(unsigned long long) * 8 - 1))) return a;
		x <<= 1;
	}
	return a;
#endif
}

/*
 * Document-class: PG::TextEncoder::Integer < PG::SimpleEncoder
 *
 * This is the encoder class for the PostgreSQL integer types.
 *
 * Non-Integer values are expected to have method +to_i+ defined.
 *
 */
static int
pg_text_enc_integer(t_pg_coder *this, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	if(out){
		if(TYPE(*intermediate) == T_STRING){
			return pg_coder_enc_to_s(this, value, out, intermediate, enc_idx);
		}else{
			char *start = out;
			int len;
			int neg = 0;
			long long sll = NUM2LL(*intermediate);
			unsigned long long ll;

			if (sll < 0) {
				/* Avoid problems with the most negative integer not being representable
				 * as a positive integer, by using unsigned long long for encoding.
				 */
				ll = -sll;
				neg = 1;
			} else {
				ll = sll;
			}

			/* Compute the result string backwards. */
			do {
				unsigned long long remainder;
				unsigned long long oldval = ll;

				ll /= 10;
				remainder = oldval - ll * 10;
				*out++ = '0' + remainder;
			} while (ll != 0);

			if (neg)
				*out++ = '-';

			len = (int)(out - start);

			/* Reverse string. */
			out--;
			while (start < out)
			{
				char swap = *start;

				*start++ = *out;
				*out-- = swap;
			}

			return len;
		}
	}else{
		*intermediate = pg_obj_to_i(value);
		if(TYPE(*intermediate) == T_FIXNUM){
			long long sll = NUM2LL(*intermediate);
			unsigned long long ll = sll < 0 ? -sll : sll;
			int len = (sizeof(unsigned long long) * 8 - count_leading_zero_bits(ll)) / 3;
			return sll < 0 ? len+2 : len+1;
		}else{
			return pg_coder_enc_to_s(this, *intermediate, NULL, intermediate, enc_idx);
		}
	}
}

#define MAX_DOUBLE_DIGITS 16

/*
 * Document-class: PG::TextEncoder::Float < PG::SimpleEncoder
 *
 * This is the encoder class for the PostgreSQL float types.
 *
 */
static int
pg_text_enc_float(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	if(out){
		double dvalue = NUM2DBL(value);
		int len = 0;
		int neg = 0;
		int exp2i, exp10i, i;
		unsigned long long ll, remainder, oldval;
		VALUE intermediate;

		/* Cast to the same strings as value.to_s . */
		if( isinf(dvalue) ){
			if( dvalue < 0 ){
				memcpy( out, "-Infinity", 9);
				return 9;
			} else {
				memcpy( out, "Infinity", 8);
				return 8;
			}
		} else if (isnan(dvalue)) {
			memcpy( out, "NaN", 3);
			return 3;
		}

		/*
		 * The following computation is roughly a conversion kind of
		 *   sprintf( out, "%.16E", dvalue);
		 */

		/* write the algebraic sign */
		if( dvalue < 0 ) {
			dvalue = -dvalue;
			*out++ = '-';
			neg++;
		}

		/* retrieve the power of 2 exponent */
		frexp(dvalue, &exp2i);
		/* compute the power of 10 exponent */
		exp10i = (int)floor(exp2i * 0.30102999566398114); /* Math.log(2)/Math.log(10) */
		/* move the decimal point, so that we get an integer of MAX_DOUBLE_DIGITS decimal digits */
		ll = (unsigned long long)(dvalue * pow(10, MAX_DOUBLE_DIGITS - 1 - exp10i) + 0.5);

		/* avoid leading zeros due to inaccuracy of deriving exp10i from exp2i */
		/* otherwise we would print "09.0" instead of "9.0" */
		if( ll < 1000000000000000 ){ /* pow(10, MAX_DOUBLE_DIGITS-1) */
			exp10i--;
			ll *= 10;
		}

		if( exp10i <= -5 || exp10i >= 15 ) {
			/* Write the float in exponent format (1.23e45) */

			/* write fraction digits from right to left */
			for( i = MAX_DOUBLE_DIGITS; i > 1; i--){
				oldval = ll;
				ll /= 10;
				remainder = oldval - ll * 10;
				/* omit trailing zeros */
				if(remainder != 0 || len ) {
					out[i] = '0' + remainder;
					len++;
				}
			}

			/* write decimal point */
			if( len ){
				out[1] = '.';
				len++;
			}

			/* write remaining single digit left to the decimal point */
			oldval = ll;
			ll /= 10;
			remainder = oldval - ll * 10;
			out[0] = '0' + remainder;
			len++;

			/* write exponent */
			out[len++] = 'e';
			intermediate = INT2NUM(exp10i);

			return neg + len + pg_text_enc_integer(conv, Qnil, out + len, &intermediate, enc_idx);
		} else {
			/* write the float in non exponent format (0.001234 or 123450.0) */

			/* write digits from right to left */
			int lz = exp10i < 0 ? 0 : exp10i;
			for( i = MAX_DOUBLE_DIGITS - (exp10i < 0 ? exp10i : 0); i >= 0; i-- ){
				oldval = ll;
				ll /= 10;
				remainder = oldval - ll * 10;
				/* write decimal point */
				if( i - 1 == lz ){
					out[i--] = '.';
					len++;
				}
				/* if possible then omit trailing zeros */
				if(remainder != 0 || len || i - 2 == lz) {
					out[i] = '0' + remainder;
					len++;
				}
			}
			return neg + len;
		}
	}else{
		return 1 /*sign*/ + MAX_DOUBLE_DIGITS + 1 /*dot*/ + 1 /*e*/ + 1 /*exp sign*/ + 3 /*exp digits*/;
	}
}


/*
 * Document-class: PG::TextEncoder::Numeric < PG::SimpleEncoder
 *
 * This is the encoder class for the PostgreSQL numeric types.
 *
 * It converts Integer, Float and BigDecimal objects.
 * All other objects are expected to respond to +to_s+.
 */
static int
pg_text_enc_numeric(t_pg_coder *this, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	switch(TYPE(value)){
		case T_FIXNUM:
		case T_BIGNUM:
			return pg_text_enc_integer(this, value, out, intermediate, enc_idx);
		case T_FLOAT:
			return pg_text_enc_float(this, value, out, intermediate, enc_idx);
		default:
			if(out){ /* second pass */
				rb_bug("unexpected value type: %d", TYPE(value));
			} else { /* first pass */
				if( rb_obj_is_kind_of(value, s_cBigDecimal) ){
					/* value.to_s('F') */
					*intermediate = rb_funcall(value, s_id_to_s, 1, s_str_F);
					return -1; /* no second pass */
				} else {
					return pg_coder_enc_to_s(this, value, NULL, intermediate, enc_idx);
					/* no second pass */
				}
			}
	}
}

/* called per autoload when TextEncoder::Numeric is used */
static VALUE
init_pg_text_encoder_numeric(VALUE rb_mPG_TextDecoder)
{
	s_str_F = rb_str_freeze(rb_str_new_cstr("F"));
	rb_global_variable(&s_str_F);
	rb_require("bigdecimal");
	s_cBigDecimal = rb_const_get(rb_cObject, rb_intern("BigDecimal"));

	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Numeric", rb_cPG_SimpleEncoder ); */
	pg_define_coder( "Numeric", pg_text_enc_numeric, rb_cPG_SimpleEncoder, rb_mPG_TextEncoder );

	return Qnil;
}


static const char hextab[] = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
};

/*
 * Document-class: PG::TextEncoder::Bytea < PG::SimpleEncoder
 *
 * This is an encoder class for the PostgreSQL +bytea+ type.
 *
 * The binary String is converted to hexadecimal representation for transmission
 * in text format. For query bind parameters it is recommended to use
 * PG::BinaryEncoder::Bytea or the hash form <tt>{value: binary_string, format: 1}</tt> instead,
 * in order to decrease network traffic and CPU usage.
 * See PG::Connection#exec_params for using the hash form.
 *
 * This encoder is particular useful when PG::TextEncoder::CopyRow is used with the COPY command.
 * In this case there's no way to change the format of a single column to binary, so that the data have to be converted to bytea hex representation.
 *
 */
static int
pg_text_enc_bytea(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	if(out){
		size_t strlen = RSTRING_LEN(*intermediate);
		char *iptr = RSTRING_PTR(*intermediate);
		char *eptr = iptr + strlen;
		char *optr = out;
		*optr++ = '\\';
		*optr++ = 'x';

		for( ; iptr < eptr; iptr++ ){
			unsigned char c = *iptr;
			*optr++ = hextab[c >> 4];
			*optr++ = hextab[c & 0xf];
		}
		return (int)(optr - out);
	}else{
		*intermediate = rb_obj_as_string(value);
		/* The output starts with "\x" and each character is converted to hex. */
		return 2 + RSTRING_LENINT(*intermediate) * 2;
	}
}

typedef int (*t_quote_func)( void *_this, char *p_in, int strlen, char *p_out );

static int
quote_array_buffer( void *_this, char *p_in, int strlen, char *p_out ){
	t_pg_composite_coder *this = _this;
	char *ptr1;
	char *ptr2;
	int backslashs = 0;
	int needquote;

	/* count data plus backslashes; detect chars needing quotes */
	if (strlen == 0)
		needquote = 1;   /* force quotes for empty string */
	else if (strlen == 4 && rbpg_strncasecmp(p_in, "NULL", strlen) == 0)
		needquote = 1;   /* force quotes for literal NULL */
	else
		needquote = 0;

	/* count required backlashs */
	for(ptr1 = p_in; ptr1 != p_in + strlen; ptr1++) {
		char ch = *ptr1;

		if (ch == '"' || ch == '\\'){
			needquote = 1;
			backslashs++;
		} else if (ch == '{' || ch == '}' || ch == this->delimiter ||
					ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == '\v' || ch == '\f'){
			needquote = 1;
		}
	}

	if( needquote ){
		ptr1 = p_in + strlen;
		ptr2 = p_out + strlen + backslashs + 2;
		/* Write end quote */
		*--ptr2 = '"';

		/* Then store the escaped string on the final position, walking
			* right to left, until all backslashs are placed. */
		while( ptr1 != p_in ) {
			*--ptr2 = *--ptr1;
			if(*ptr2 == '"' || *ptr2 == '\\'){
				*--ptr2 = '\\';
			}
		}
		/* Write start quote */
		*p_out = '"';
		return strlen + backslashs + 2;
	} else {
		if( p_in != p_out )
			memcpy( p_out, p_in, strlen );
		return strlen;
	}
}

static char *
quote_string(t_pg_coder *this, VALUE value, VALUE string, char *current_out, int with_quote, t_quote_func quote_buffer, void *func_data, int enc_idx)
{
	int strlen;
	VALUE subint;
	t_pg_coder_enc_func enc_func = pg_coder_enc_func(this);

	strlen = enc_func(this, value, NULL, &subint, enc_idx);

	if( strlen == -1 ){
		/* we can directly use String value in subint */
		strlen = RSTRING_LENINT(subint);

		if(with_quote){
			/* size of string assuming the worst case, that every character must be escaped. */
			current_out = pg_rb_str_ensure_capa( string, strlen * 2 + 2, current_out, NULL );

			current_out += quote_buffer( func_data, RSTRING_PTR(subint), strlen, current_out );
		} else {
			current_out = pg_rb_str_ensure_capa( string, strlen, current_out, NULL );
			memcpy( current_out, RSTRING_PTR(subint), strlen );
			current_out += strlen;
		}

	} else {

		if(with_quote){
			/* size of string assuming the worst case, that every character must be escaped
			 * plus two bytes for quotation.
			 */
			current_out = pg_rb_str_ensure_capa( string, 2 * strlen + 2, current_out, NULL );

			/* Place the unescaped string at current output position. */
			strlen = enc_func(this, value, current_out, &subint, enc_idx);

			current_out += quote_buffer( func_data, current_out, strlen, current_out );
		}else{
			/* size of the unquoted string */
			current_out = pg_rb_str_ensure_capa( string, strlen, current_out, NULL );
			current_out += enc_func(this, value, current_out, &subint, enc_idx);
		}
	}
	return current_out;
}

static char *
write_array(t_pg_composite_coder *this, VALUE value, char *current_out, VALUE string, int quote, int enc_idx)
{
	int i;

	/* size of "{}" */
	current_out = pg_rb_str_ensure_capa( string, 2, current_out, NULL );
	*current_out++ = '{';

	for( i=0; i<RARRAY_LEN(value); i++){
		VALUE entry = rb_ary_entry(value, i);

		if( i > 0 ){
			current_out = pg_rb_str_ensure_capa( string, 1, current_out, NULL );
			*current_out++ = this->delimiter;
		}

		switch(TYPE(entry)){
			case T_ARRAY:
				current_out = write_array(this, entry, current_out, string, quote, enc_idx);
			break;
			case T_NIL:
				current_out = pg_rb_str_ensure_capa( string, 4, current_out, NULL );
				*current_out++ = 'N';
				*current_out++ = 'U';
				*current_out++ = 'L';
				*current_out++ = 'L';
				break;
			default:
				current_out = quote_string( this->elem, entry, string, current_out, quote, quote_array_buffer, this, enc_idx );
		}
	}
	current_out = pg_rb_str_ensure_capa( string, 1, current_out, NULL );
	*current_out++ = '}';
	return current_out;
}


/*
 * Document-class: PG::TextEncoder::Array < PG::CompositeEncoder
 *
 * This is the encoder class for PostgreSQL array types.
 *
 * All values are encoded according to the #elements_type
 * accessor. Sub-arrays are encoded recursively.
 *
 * This encoder expects an Array of values or sub-arrays as input.
 * Other values are passed through as text without interpretation.
 *
 */
static int
pg_text_enc_array(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	char *end_ptr;
	t_pg_composite_coder *this = (t_pg_composite_coder *)conv;

	if( TYPE(value) == T_ARRAY){
		VALUE out_str = rb_str_new(NULL, 0);
		PG_ENCODING_SET_NOCHECK(out_str, enc_idx);

		end_ptr = write_array(this, value, RSTRING_PTR(out_str), out_str, this->needs_quotation, enc_idx);

		rb_str_set_len( out_str, end_ptr - RSTRING_PTR(out_str) );
		*intermediate = out_str;

		return -1;
	} else {
		return pg_coder_enc_to_s( conv, value, out, intermediate, enc_idx );
	}
}

static char *
quote_identifier( VALUE value, VALUE out_string, char *current_out ){
	char *p_in = RSTRING_PTR(value);
	size_t strlen = RSTRING_LEN(value);
	char *p_inend = p_in + strlen;
	char *end_capa = current_out;

	PG_RB_STR_ENSURE_CAPA( out_string, strlen + 2, current_out, end_capa );
	*current_out++ = '"';
	for(; p_in != p_inend; p_in++) {
		char c = *p_in;
		if (c == '"'){
			PG_RB_STR_ENSURE_CAPA( out_string, p_inend - p_in + 2, current_out, end_capa );
			*current_out++ = '"';
		} else if (c == 0){
			rb_raise(rb_eArgError, "string contains null byte");
		}
		*current_out++ = c;
	}
	PG_RB_STR_ENSURE_CAPA( out_string, 1, current_out, end_capa );
	*current_out++ = '"';

	return current_out;
}

static char *
pg_text_enc_array_identifier(VALUE value, VALUE string, char *out, int enc_idx)
{
	long i;
	long nr_elems;

	Check_Type(value, T_ARRAY);
	nr_elems = RARRAY_LEN(value);

	for( i=0; i<nr_elems; i++){
		VALUE entry = rb_ary_entry(value, i);

		StringValue(entry);
		if( ENCODING_GET(entry) != enc_idx ){
			entry = rb_str_export_to_enc(entry, rb_enc_from_index(enc_idx));
		}
		out = quote_identifier(entry, string, out);
		if( i < nr_elems-1 ){
			out = pg_rb_str_ensure_capa( string, 1, out, NULL );
			*out++ = '.';
		}
	}
	return out;
}

/*
 * Document-class: PG::TextEncoder::Identifier < PG::SimpleEncoder
 *
 * This is the encoder class for PostgreSQL identifiers.
 *
 * An Array value can be used for identifiers of the kind "schema.table.column".
 * This ensures that each element is properly quoted:
 *   PG::TextEncoder::Identifier.new.encode(['schema', 'table', 'column'])
 *      => '"schema"."table"."column"'
 *
 *  This encoder can also be used per PG::Connection#quote_ident .
 */
int
pg_text_enc_identifier(t_pg_coder *this, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	VALUE out_str;
	UNUSED( this );
	if( TYPE(value) == T_ARRAY){
		out_str = rb_str_new(NULL, 0);
		out = RSTRING_PTR(out_str);
		out = pg_text_enc_array_identifier(value, out_str, out, enc_idx);
	} else {
		StringValue(value);
		if( ENCODING_GET(value) != enc_idx ){
			value = rb_str_export_to_enc(value, rb_enc_from_index(enc_idx));
		}
		out_str = rb_str_new(NULL, RSTRING_LEN(value) + 2);
		out = RSTRING_PTR(out_str);
		out = quote_identifier(value, out_str, out);
	}
	rb_str_set_len( out_str, out - RSTRING_PTR(out_str) );
	PG_ENCODING_SET_NOCHECK(out_str, enc_idx);
	*intermediate = out_str;
	return -1;
}


static int
quote_literal_buffer( void *_this, char *p_in, int strlen, char *p_out ){
	char *ptr1;
	char *ptr2;
	int backslashs = 0;

	/* count required backlashs */
	for(ptr1 = p_in; ptr1 != p_in + strlen; ptr1++) {
		if (*ptr1 == '\''){
			backslashs++;
		}
	}

	ptr1 = p_in + strlen;
	ptr2 = p_out + strlen + backslashs + 2;
	/* Write end quote */
	*--ptr2 = '\'';

	/* Then store the escaped string on the final position, walking
		* right to left, until all backslashs are placed. */
	while( ptr1 != p_in ) {
		*--ptr2 = *--ptr1;
		if(*ptr2 == '\''){
			*--ptr2 = '\'';
		}
	}
	/* Write start quote */
	*p_out = '\'';
	return strlen + backslashs + 2;
}


/*
 * Document-class: PG::TextEncoder::QuotedLiteral < PG::CompositeEncoder
 *
 * This is the encoder class for PostgreSQL literals.
 *
 * A literal is quoted and escaped by the <tt>'</tt> character, so that it can be inserted into SQL queries.
 * It works equal to PG::Connection#escape_literal, but integrates into the type cast system of ruby-pg.
 *
 * Both expressions have the same result:
 *   conn.escape_literal(PG::TextEncoder::Array.new.encode(["v1","v2"])) # => "'{v1,v2}'"
 *   PG::TextEncoder::QuotedLiteral.new(elements_type: PG::TextEncoder::Array.new).encode(["v1","v2"]) # => "'{v1,v2}'"
 * While escape_literal requires a intermediate ruby string allocation, QuotedLiteral encodes the values directly to the result string.
 *
 */
static int
pg_text_enc_quoted_literal(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	t_pg_composite_coder *this = (t_pg_composite_coder *)conv;
	VALUE out_str = rb_str_new(NULL, 0);
	PG_ENCODING_SET_NOCHECK(out_str, enc_idx);

	out = RSTRING_PTR(out_str);
	out = quote_string(this->elem, value, out_str, out, this->needs_quotation, quote_literal_buffer, this, enc_idx);
	rb_str_set_len( out_str, out - RSTRING_PTR(out_str) );
	*intermediate = out_str;
	return -1;
}

/*
 * Document-class: PG::TextEncoder::ToBase64 < PG::CompositeEncoder
 *
 * This is an encoder class for conversion of binary to base64 data.
 *
 */
static int
pg_text_enc_to_base64(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	int strlen;
	VALUE subint;
	t_pg_composite_coder *this = (t_pg_composite_coder *)conv;
	t_pg_coder_enc_func enc_func = pg_coder_enc_func(this->elem);

	if(out){
		/* Second encoder pass, if required */
		strlen = enc_func(this->elem, value, out, intermediate, enc_idx);
		base64_encode( out, out, strlen );

		return BASE64_ENCODED_SIZE(strlen);
	} else {
		/* First encoder pass */
		strlen = enc_func(this->elem, value, NULL, &subint, enc_idx);

		if( strlen == -1 ){
			/* Encoded string is returned in subint */
			VALUE out_str;

			strlen = RSTRING_LENINT(subint);
			out_str = rb_str_new(NULL, BASE64_ENCODED_SIZE(strlen));
			PG_ENCODING_SET_NOCHECK(out_str, enc_idx);

			base64_encode( RSTRING_PTR(out_str), RSTRING_PTR(subint), strlen);
			*intermediate = out_str;

			return -1;
		} else {
			*intermediate = subint;

			return BASE64_ENCODED_SIZE(strlen);
		}
	}
}


void
init_pg_text_encoder(void)
{
	s_id_encode = rb_intern("encode");
	s_id_to_i = rb_intern("to_i");
	s_id_to_s = rb_intern("to_s");

	/* This module encapsulates all encoder classes with text output format */
	rb_mPG_TextEncoder = rb_define_module_under( rb_mPG, "TextEncoder" );
	rb_define_private_method(rb_singleton_class(rb_mPG_TextEncoder), "init_numeric", init_pg_text_encoder_numeric, 0);

	/* Make RDoc aware of the encoder classes... */
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Boolean", rb_cPG_SimpleEncoder ); */
	pg_define_coder( "Boolean", pg_text_enc_boolean, rb_cPG_SimpleEncoder, rb_mPG_TextEncoder );
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Integer", rb_cPG_SimpleEncoder ); */
	pg_define_coder( "Integer", pg_text_enc_integer, rb_cPG_SimpleEncoder, rb_mPG_TextEncoder );
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Float", rb_cPG_SimpleEncoder ); */
	pg_define_coder( "Float", pg_text_enc_float, rb_cPG_SimpleEncoder, rb_mPG_TextEncoder );
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "String", rb_cPG_SimpleEncoder ); */
	pg_define_coder( "String", pg_coder_enc_to_s, rb_cPG_SimpleEncoder, rb_mPG_TextEncoder );
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Bytea", rb_cPG_SimpleEncoder ); */
	pg_define_coder( "Bytea", pg_text_enc_bytea, rb_cPG_SimpleEncoder, rb_mPG_TextEncoder );
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Identifier", rb_cPG_SimpleEncoder ); */
	pg_define_coder( "Identifier", pg_text_enc_identifier, rb_cPG_SimpleEncoder, rb_mPG_TextEncoder );

	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Array", rb_cPG_CompositeEncoder ); */
	pg_define_coder( "Array", pg_text_enc_array, rb_cPG_CompositeEncoder, rb_mPG_TextEncoder );
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "QuotedLiteral", rb_cPG_CompositeEncoder ); */
	pg_define_coder( "QuotedLiteral", pg_text_enc_quoted_literal, rb_cPG_CompositeEncoder, rb_mPG_TextEncoder );
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "ToBase64", rb_cPG_CompositeEncoder ); */
	pg_define_coder( "ToBase64", pg_text_enc_to_base64, rb_cPG_CompositeEncoder, rb_mPG_TextEncoder );
}
