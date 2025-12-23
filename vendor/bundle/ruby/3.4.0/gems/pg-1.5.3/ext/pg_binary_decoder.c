/*
 * pg_column_map.c - PG::ColumnMap class extension
 * $Id$
 *
 */

#include "ruby/version.h"
#include "pg.h"
#include "pg_util.h"
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif

VALUE rb_mPG_BinaryDecoder;
static VALUE s_Date;
static ID s_id_new;


/*
 * Document-class: PG::BinaryDecoder::Boolean < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL binary +bool+ type
 * to Ruby +true+ or +false+ objects.
 *
 */
static VALUE
pg_bin_dec_boolean(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	if (len < 1) {
		rb_raise( rb_eTypeError, "wrong data for binary boolean converter in tuple %d field %d", tuple, field);
	}
	return *val == 0 ? Qfalse : Qtrue;
}

/*
 * Document-class: PG::BinaryDecoder::Integer < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL binary +int2+, +int4+ and +int8+ types
 * to Ruby Integer objects.
 *
 */
static VALUE
pg_bin_dec_integer(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	switch( len ){
		case 2:
			return INT2NUM(read_nbo16(val));
		case 4:
			return LONG2NUM(read_nbo32(val));
		case 8:
			return LL2NUM(read_nbo64(val));
		default:
			rb_raise( rb_eTypeError, "wrong data for binary integer converter in tuple %d field %d length %d", tuple, field, len);
	}
}

/*
 * Document-class: PG::BinaryDecoder::Float < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL binary +float4+ and +float8+ types
 * to Ruby Float objects.
 *
 */
static VALUE
pg_bin_dec_float(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	union {
		float f;
		int32_t i;
	} swap4;
	union {
		double f;
		int64_t i;
	} swap8;

	switch( len ){
		case 4:
			swap4.i = read_nbo32(val);
			return rb_float_new(swap4.f);
		case 8:
			swap8.i = read_nbo64(val);
			return rb_float_new(swap8.f);
		default:
			rb_raise( rb_eTypeError, "wrong data for BinaryFloat converter in tuple %d field %d length %d", tuple, field, len);
	}
}

/*
 * Document-class: PG::BinaryDecoder::Bytea < PG::SimpleDecoder
 *
 * This decoder class delivers the data received from the server as binary String object.
 * It is therefore suitable for conversion of PostgreSQL +bytea+ data as well as any other
 * data in binary format.
 *
 */
VALUE
pg_bin_dec_bytea(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	VALUE ret;
	ret = rb_str_new( val, len );
	PG_ENCODING_SET_NOCHECK( ret, rb_ascii8bit_encindex() );
	return ret;
}

/*
 * Document-class: PG::BinaryDecoder::ToBase64 < PG::CompositeDecoder
 *
 * This is a decoder class for conversion of binary +bytea+ to base64 data.
 *
 */
static VALUE
pg_bin_dec_to_base64(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	t_pg_composite_coder *this = (t_pg_composite_coder *)conv;
	t_pg_coder_dec_func dec_func = pg_coder_dec_func(this->elem, this->comp.format);
	int encoded_len = BASE64_ENCODED_SIZE(len);
	/* create a buffer of the encoded length */
	VALUE out_value = rb_str_new(NULL, encoded_len);

	base64_encode( RSTRING_PTR(out_value), val, len );

	/* Is it a pure String conversion? Then we can directly send out_value to the user. */
	if( this->comp.format == 0 && dec_func == pg_text_dec_string ){
		PG_ENCODING_SET_NOCHECK( out_value, enc_idx );
		return out_value;
	}
	if( this->comp.format == 1 && dec_func == pg_bin_dec_bytea ){
		PG_ENCODING_SET_NOCHECK( out_value, rb_ascii8bit_encindex() );
		return out_value;
	}
	out_value = dec_func(this->elem, RSTRING_PTR(out_value), encoded_len, tuple, field, enc_idx);

	return out_value;
}

#define PG_INT64_MIN	(-0x7FFFFFFFFFFFFFFFL - 1)
#define PG_INT64_MAX	0x7FFFFFFFFFFFFFFFL

/*
 * Document-class: PG::BinaryDecoder::Timestamp < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL binary timestamps
 * to Ruby Time objects.
 *
 * The following flags can be used to specify timezone interpretation:
 * * +PG::Coder::TIMESTAMP_DB_UTC+ : Interpret timestamp as UTC time (default)
 * * +PG::Coder::TIMESTAMP_DB_LOCAL+ : Interpret timestamp as local time
 * * +PG::Coder::TIMESTAMP_APP_UTC+ : Return timestamp as UTC time (default)
 * * +PG::Coder::TIMESTAMP_APP_LOCAL+ : Return timestamp as local time
 *
 * Example:
 *   deco = PG::BinaryDecoder::Timestamp.new(flags: PG::Coder::TIMESTAMP_DB_UTC | PG::Coder::TIMESTAMP_APP_LOCAL)
 *   deco.decode("\0"*8)  # => 2000-01-01 01:00:00 +0100
 */
static VALUE
pg_bin_dec_timestamp(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	int64_t timestamp;
	int64_t sec;
	int64_t nsec;
	VALUE t;

	if( len != sizeof(timestamp) ){
		rb_raise( rb_eTypeError, "wrong data for timestamp converter in tuple %d field %d length %d", tuple, field, len);
	}

	timestamp = read_nbo64(val);

	switch(timestamp){
		case PG_INT64_MAX:
			return rb_str_new2("infinity");
		case PG_INT64_MIN:
			return rb_str_new2("-infinity");
		default:
			/* PostgreSQL's timestamp is based on year 2000 and Ruby's time is based on 1970.
			 * Adjust the 30 years difference. */
			sec = (timestamp / 1000000) + 10957L * 24L * 3600L;
			nsec = (timestamp % 1000000) * 1000;

#if (RUBY_API_VERSION_MAJOR > 2 || (RUBY_API_VERSION_MAJOR == 2 && RUBY_API_VERSION_MINOR >= 3)) && defined(NEGATIVE_TIME_T) && defined(SIZEOF_TIME_T) && SIZEOF_TIME_T >= 8
			/* Fast path for time conversion */
			{
				struct timespec ts = {sec, nsec};
				t = rb_time_timespec_new(&ts, conv->flags & PG_CODER_TIMESTAMP_APP_LOCAL ? INT_MAX : INT_MAX-1);
			}
#else
			t = rb_funcall(rb_cTime, rb_intern("at"), 2, LL2NUM(sec), LL2NUM(nsec / 1000));
			if( !(conv->flags & PG_CODER_TIMESTAMP_APP_LOCAL) ) {
				t = rb_funcall(t, rb_intern("utc"), 0);
			}
#endif
			if( conv->flags & PG_CODER_TIMESTAMP_DB_LOCAL ) {
				/* interpret it as local time */
				t = rb_funcall(t, rb_intern("-"), 1, rb_funcall(t, rb_intern("utc_offset"), 0));
			}
			return t;
	}
}

#define PG_INT32_MIN    (-0x7FFFFFFF-1)
#define PG_INT32_MAX    (0x7FFFFFFF)
#define POSTGRES_EPOCH_JDATE   2451545 /* == date2j(2000, 1, 1) */
#define MONTHS_PER_YEAR 12

/* taken from PostgreSQL sources at src/backend/utils/adt/datetime.c */
void
j2date(int jd, int *year, int *month, int *day)
{
	unsigned int julian;
	unsigned int quad;
	unsigned int extra;
	int			y;

	julian = jd;
	julian += 32044;
	quad = julian / 146097;
	extra = (julian - quad * 146097) * 4 + 3;
	julian += 60 + quad * 3 + extra / 146097;
	quad = julian / 1461;
	julian -= quad * 1461;
	y = julian * 4 / 1461;
	julian = ((y != 0) ? ((julian + 305) % 365) : ((julian + 306) % 366))
		+ 123;
	y += quad * 4;
	*year = y - 4800;
	quad = julian * 2141 / 65536;
	*day = julian - 7834 * quad / 256;
	*month = (quad + 10) % MONTHS_PER_YEAR + 1;
}								/* j2date() */

/*
 * Document-class: PG::BinaryDecoder::Date < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL binary date
 * to Ruby Date objects.
 */
static VALUE
pg_bin_dec_date(t_pg_coder *conv, const char *val, int len, int tuple, int field, int enc_idx)
{
	int year, month, day;
	int date;

	if (len != 4) {
		rb_raise(rb_eTypeError, "unexpected date format != 4 bytes");
	}

	date = read_nbo32(val);
	switch(date){
		case PG_INT32_MAX:
			return rb_str_new2("infinity");
		case PG_INT32_MIN:
			return rb_str_new2("-infinity");
		default:
			j2date(date + POSTGRES_EPOCH_JDATE, &year, &month, &day);

			return rb_funcall(s_Date, s_id_new, 3, INT2NUM(year), INT2NUM(month), INT2NUM(day));
	}
}

/* called per autoload when BinaryDecoder::Date is used */
static VALUE
init_pg_bin_decoder_date(VALUE rb_mPG_BinaryDecoder)
{
	rb_require("date");
	s_Date = rb_const_get(rb_cObject, rb_intern("Date"));
	rb_gc_register_mark_object(s_Date);
	s_id_new = rb_intern("new");

	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "Date", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Date", pg_bin_dec_date, rb_cPG_SimpleDecoder, rb_mPG_BinaryDecoder );

	return Qnil;
}


/*
 * Document-class: PG::BinaryDecoder::String < PG::SimpleDecoder
 *
 * This is a decoder class for conversion of PostgreSQL text output to
 * to Ruby String object. The output value will have the character encoding
 * set with PG::Connection#internal_encoding= .
 *
 */

void
init_pg_binary_decoder(void)
{
	/* This module encapsulates all decoder classes with binary input format */
	rb_mPG_BinaryDecoder = rb_define_module_under( rb_mPG, "BinaryDecoder" );
	rb_define_private_method(rb_singleton_class(rb_mPG_BinaryDecoder), "init_date", init_pg_bin_decoder_date, 0);

	/* Make RDoc aware of the decoder classes... */
	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "Boolean", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Boolean", pg_bin_dec_boolean, rb_cPG_SimpleDecoder, rb_mPG_BinaryDecoder );
	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "Integer", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Integer", pg_bin_dec_integer, rb_cPG_SimpleDecoder, rb_mPG_BinaryDecoder );
	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "Float", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Float", pg_bin_dec_float, rb_cPG_SimpleDecoder, rb_mPG_BinaryDecoder );
	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "String", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "String", pg_text_dec_string, rb_cPG_SimpleDecoder, rb_mPG_BinaryDecoder );
	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "Bytea", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Bytea", pg_bin_dec_bytea, rb_cPG_SimpleDecoder, rb_mPG_BinaryDecoder );
	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "Timestamp", rb_cPG_SimpleDecoder ); */
	pg_define_coder( "Timestamp", pg_bin_dec_timestamp, rb_cPG_SimpleDecoder, rb_mPG_BinaryDecoder );

	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "ToBase64", rb_cPG_CompositeDecoder ); */
	pg_define_coder( "ToBase64", pg_bin_dec_to_base64, rb_cPG_CompositeDecoder, rb_mPG_BinaryDecoder );
}
