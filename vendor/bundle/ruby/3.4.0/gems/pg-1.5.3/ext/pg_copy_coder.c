/*
 * pg_copycoder.c - PG::Coder class extension
 *
 */

#include "pg.h"
#include "pg_util.h"

#define ISOCTAL(c) (((c) >= '0') && ((c) <= '7'))
#define OCTVALUE(c) ((c) - '0')

VALUE rb_cPG_CopyCoder;
VALUE rb_cPG_CopyEncoder;
VALUE rb_cPG_CopyDecoder;

typedef struct {
	t_pg_coder comp;
	VALUE typemap;
	VALUE null_string;
	char delimiter;
} t_pg_copycoder;


static void
pg_copycoder_mark( void *_this )
{
	t_pg_copycoder *this = (t_pg_copycoder *)_this;
	rb_gc_mark_movable(this->typemap);
	rb_gc_mark_movable(this->null_string);
}

static size_t
pg_copycoder_memsize( const void *_this )
{
	const t_pg_copycoder *this = (const t_pg_copycoder *)_this;
	return sizeof(*this);
}

static void
pg_copycoder_compact( void *_this )
{
	t_pg_copycoder *this = (t_pg_copycoder *)_this;
	pg_coder_compact(&this->comp);
	pg_gc_location(this->typemap);
	pg_gc_location(this->null_string);
}

static const rb_data_type_t pg_copycoder_type = {
	"PG::CopyCoder",
	{
		pg_copycoder_mark,
		RUBY_TYPED_DEFAULT_FREE,
		pg_copycoder_memsize,
		pg_compact_callback(pg_copycoder_compact),
	},
	&pg_coder_type,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED | PG_RUBY_TYPED_FROZEN_SHAREABLE,
};

static VALUE
pg_copycoder_encoder_allocate( VALUE klass )
{
	t_pg_copycoder *this;
	VALUE self = TypedData_Make_Struct( klass, t_pg_copycoder, &pg_copycoder_type, this );
	pg_coder_init_encoder( self );
	RB_OBJ_WRITE(self, &this->typemap, pg_typemap_all_strings);
	this->delimiter = '\t';
	RB_OBJ_WRITE(self, &this->null_string, rb_str_new_cstr("\\N"));
	return self;
}

static VALUE
pg_copycoder_decoder_allocate( VALUE klass )
{
	t_pg_copycoder *this;
	VALUE self = TypedData_Make_Struct( klass, t_pg_copycoder, &pg_copycoder_type, this );
	pg_coder_init_decoder( self );
	RB_OBJ_WRITE(self, &this->typemap, pg_typemap_all_strings);
	this->delimiter = '\t';
	RB_OBJ_WRITE(self, &this->null_string, rb_str_new_cstr("\\N"));
	return self;
}

/*
 * call-seq:
 *    coder.delimiter = String
 *
 * Specifies the character that separates columns within each row (line) of the file.
 * The default is a tab character in text format.
 * This must be a single one-byte character.
 *
 * This option is ignored when using binary format.
 */
static VALUE
pg_copycoder_delimiter_set(VALUE self, VALUE delimiter)
{
	t_pg_copycoder *this = RTYPEDDATA_DATA(self);
	rb_check_frozen(self);
	StringValue(delimiter);
	if(RSTRING_LEN(delimiter) != 1)
		rb_raise( rb_eArgError, "delimiter size must be one byte");
	this->delimiter = *RSTRING_PTR(delimiter);
	return delimiter;
}

/*
 * call-seq:
 *    coder.delimiter -> String
 *
 * The character that separates columns within each row (line) of the file.
 */
static VALUE
pg_copycoder_delimiter_get(VALUE self)
{
	t_pg_copycoder *this = RTYPEDDATA_DATA(self);
	return rb_str_new(&this->delimiter, 1);
}

/*
 * Specifies the string that represents a null value.
 * The default is \\N (backslash-N) in text format.
 * You might prefer an empty string even in text format for cases where you don't want to distinguish nulls from empty strings.
 *
 * This option is ignored when using binary format.
 */
static VALUE
pg_copycoder_null_string_set(VALUE self, VALUE null_string)
{
	t_pg_copycoder *this = RTYPEDDATA_DATA(self);
	rb_check_frozen(self);
	StringValue(null_string);
	RB_OBJ_WRITE(self, &this->null_string, null_string);
	return null_string;
}

/*
 * The string that represents a null value.
 */
static VALUE
pg_copycoder_null_string_get(VALUE self)
{
	t_pg_copycoder *this = RTYPEDDATA_DATA(self);
	return this->null_string;
}

/*
 * call-seq:
 *    coder.type_map = map
 *
 * Defines how single columns are encoded or decoded.
 * +map+ must be a kind of PG::TypeMap .
 *
 * Defaults to a PG::TypeMapAllStrings , so that PG::TextEncoder::String respectively
 * PG::TextDecoder::String is used for encoding/decoding of each column.
 *
 */
static VALUE
pg_copycoder_type_map_set(VALUE self, VALUE type_map)
{
	t_pg_copycoder *this = RTYPEDDATA_DATA( self );

	rb_check_frozen(self);
	if ( !rb_obj_is_kind_of(type_map, rb_cTypeMap) ){
		rb_raise( rb_eTypeError, "wrong elements type %s (expected some kind of PG::TypeMap)",
				rb_obj_classname( type_map ) );
	}
	RB_OBJ_WRITE(self, &this->typemap, type_map);

	return type_map;
}

/*
 * call-seq:
 *    coder.type_map -> PG::TypeMap
 *
 * The PG::TypeMap that will be used for encoding and decoding of columns.
 */
static VALUE
pg_copycoder_type_map_get(VALUE self)
{
	t_pg_copycoder *this = RTYPEDDATA_DATA( self );

	return this->typemap;
}


/*
 * Document-class: PG::TextEncoder::CopyRow < PG::CopyEncoder
 *
 * This class encodes one row of arbitrary columns for transmission as COPY data in text format.
 * See the {COPY command}[http://www.postgresql.org/docs/current/static/sql-copy.html]
 * for description of the format.
 *
 * It is intended to be used in conjunction with PG::Connection#put_copy_data .
 *
 * The columns are expected as Array of values. The single values are encoded as defined
 * in the assigned #type_map. If no type_map was assigned, all values are converted to
 * strings by PG::TextEncoder::String.
 *
 * Example with default type map ( TypeMapAllStrings ):
 *   conn.exec "create table my_table (a text,b int,c bool)"
 *   enco = PG::TextEncoder::CopyRow.new
 *   conn.copy_data "COPY my_table FROM STDIN", enco do
 *     conn.put_copy_data ["astring", 7, false]
 *     conn.put_copy_data ["string2", 42, true]
 *   end
 * This creates +my_table+ and inserts two rows.
 *
 * It is possible to manually assign a type encoder for each column per PG::TypeMapByColumn,
 * or to make use of PG::BasicTypeMapBasedOnResult to assign them based on the table OIDs.
 *
 * See also PG::TextDecoder::CopyRow for the decoding direction with
 * PG::Connection#get_copy_data .
 */
static int
pg_text_enc_copy_row(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	t_pg_copycoder *this = (t_pg_copycoder *)conv;
	t_pg_coder_enc_func enc_func;
	static t_pg_coder *p_elem_coder;
	int i;
	t_typemap *p_typemap;
	char *current_out;
	char *end_capa_ptr;

	p_typemap = RTYPEDDATA_DATA( this->typemap );
	p_typemap->funcs.fit_to_query( this->typemap, value );

	/* Allocate a new string with embedded capacity and realloc exponential when needed. */
	PG_RB_STR_NEW( *intermediate, current_out, end_capa_ptr );
	PG_ENCODING_SET_NOCHECK(*intermediate, enc_idx);

	for( i=0; i<RARRAY_LEN(value); i++){
		char *ptr1;
		char *ptr2;
		int strlen;
		int backslashs;
		VALUE subint;
		VALUE entry;

		entry = rb_ary_entry(value, i);

		if( i > 0 ){
			PG_RB_STR_ENSURE_CAPA( *intermediate, 1, current_out, end_capa_ptr );
			*current_out++ = this->delimiter;
		}

		switch(TYPE(entry)){
			case T_NIL:
				PG_RB_STR_ENSURE_CAPA( *intermediate, RSTRING_LEN(this->null_string), current_out, end_capa_ptr );
				memcpy( current_out, RSTRING_PTR(this->null_string), RSTRING_LEN(this->null_string) );
				current_out += RSTRING_LEN(this->null_string);
				break;
			default:
				p_elem_coder = p_typemap->funcs.typecast_query_param(p_typemap, entry, i);
				enc_func = pg_coder_enc_func(p_elem_coder);

				/* 1st pass for retiving the required memory space */
				strlen = enc_func(p_elem_coder, entry, NULL, &subint, enc_idx);

				if( strlen == -1 ){
					/* we can directly use String value in subint */
					strlen = RSTRING_LENINT(subint);

					/* size of string assuming the worst case, that every character must be escaped. */
					PG_RB_STR_ENSURE_CAPA( *intermediate, strlen * 2, current_out, end_capa_ptr );

					/* Copy string from subint with backslash escaping */
					for(ptr1 = RSTRING_PTR(subint); ptr1 < RSTRING_PTR(subint) + strlen; ptr1++) {
						/* Escape backslash itself, newline, carriage return, and the current delimiter character. */
						if(*ptr1 == '\\' || *ptr1 == '\n' || *ptr1 == '\r' || *ptr1 == this->delimiter){
							*current_out++ = '\\';
						}
						*current_out++ = *ptr1;
					}
				} else {
					/* 2nd pass for writing the data to prepared buffer */
					/* size of string assuming the worst case, that every character must be escaped. */
					PG_RB_STR_ENSURE_CAPA( *intermediate, strlen * 2, current_out, end_capa_ptr );

					/* Place the unescaped string at current output position. */
					strlen = enc_func(p_elem_coder, entry, current_out, &subint, enc_idx);

					ptr1 = current_out;
					ptr2 = current_out + strlen;

					/* count required backlashs */
					for(backslashs = 0; ptr1 != ptr2; ptr1++) {
						/* Escape backslash itself, newline, carriage return, and the current delimiter character. */
						if(*ptr1 == '\\' || *ptr1 == '\n' || *ptr1 == '\r' || *ptr1 == this->delimiter){
							backslashs++;
						}
					}

					ptr1 = current_out + strlen;
					ptr2 = current_out + strlen + backslashs;
					current_out = ptr2;

					/* Then store the escaped string on the final position, walking
					 * right to left, until all backslashs are placed. */
					while( ptr1 != ptr2 ) {
						*--ptr2 = *--ptr1;
						if(*ptr1 == '\\' || *ptr1 == '\n' || *ptr1 == '\r' || *ptr1 == this->delimiter){
							*--ptr2 = '\\';
						}
					}
				}
		}
	}
	PG_RB_STR_ENSURE_CAPA( *intermediate, 1, current_out, end_capa_ptr );
	*current_out++ = '\n';

	rb_str_set_len( *intermediate, current_out - RSTRING_PTR(*intermediate) );

	return -1;
}


/*
 * Document-class: PG::BinaryEncoder::CopyRow < PG::CopyEncoder
 *
 * This class encodes one row of arbitrary columns for transmission as COPY data in binary format.
 * See the {COPY command}[http://www.postgresql.org/docs/current/static/sql-copy.html]
 * for description of the format.
 *
 * It is intended to be used in conjunction with PG::Connection#put_copy_data .
 *
 * The columns are expected as Array of values. The single values are encoded as defined
 * in the assigned #type_map. If no type_map was assigned, all values are converted to
 * strings by PG::BinaryEncoder::String.
 *
 * Example with default type map ( TypeMapAllStrings ):
 *   conn.exec "create table my_table (a text,b int,c bool)"
 *   enco = PG::BinaryEncoder::CopyRow.new
 *   conn.copy_data "COPY my_table FROM STDIN WITH (FORMAT binary)", enco do
 *     conn.put_copy_data ["astring", "\x00\x00\x00\a", "\x00"]
 *     conn.put_copy_data ["string2", "\x00\x00\x00*", "\x01"]
 *   end
 * This creates +my_table+ and inserts two rows with binary fields.
 *
 * The binary format is less portable and less readable than the text format.
 * It is therefore recommended to either manually assign a type encoder for each column per PG::TypeMapByColumn,
 * or to make use of PG::BasicTypeMapBasedOnResult to assign them based on the table OIDs.
 *
 * Manually assigning a type encoder works per type map like so:
 *
 *   conn.exec "create table my_table (a text,b int,c bool)"
 *   tm = PG::TypeMapByColumn.new( [
 *     PG::BinaryEncoder::String.new,
 *     PG::BinaryEncoder::Int4.new,
 *     PG::BinaryEncoder::Boolean.new] )
 *   enco = PG::BinaryEncoder::CopyRow.new( type_map: tm )
 *   conn.copy_data "COPY my_table FROM STDIN WITH (FORMAT binary)", enco do
 *     conn.put_copy_data ["astring", 7, false]
 *     conn.put_copy_data ["string2", 42, true]
 *   end
 *
 * See also PG::BinaryDecoder::CopyRow for the decoding direction with
 * PG::Connection#get_copy_data .
 */
static int
pg_bin_enc_copy_row(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	t_pg_copycoder *this = (t_pg_copycoder *)conv;
	int i;
	t_typemap *p_typemap;
	char *current_out;
	char *end_capa_ptr;

	p_typemap = RTYPEDDATA_DATA( this->typemap );
	p_typemap->funcs.fit_to_query( this->typemap, value );

	/* Allocate a new string with embedded capacity and realloc exponential when needed. */
	PG_RB_STR_NEW( *intermediate, current_out, end_capa_ptr );
	PG_ENCODING_SET_NOCHECK(*intermediate, enc_idx);

	/* 2 bytes for number of fields */
	PG_RB_STR_ENSURE_CAPA( *intermediate, 2, current_out, end_capa_ptr );
	write_nbo16(RARRAY_LEN(value), current_out);
	current_out += 2;

	for( i=0; i<RARRAY_LEN(value); i++){
		int strlen;
		VALUE subint;
		VALUE entry;
		t_pg_coder_enc_func enc_func;
		static t_pg_coder *p_elem_coder;

		entry = rb_ary_entry(value, i);

		switch(TYPE(entry)){
			case T_NIL:
				/* 4 bytes for -1 indicationg a NULL value */
				PG_RB_STR_ENSURE_CAPA( *intermediate, 4, current_out, end_capa_ptr );
				write_nbo32(-1, current_out);
				current_out += 4;
				break;
			default:
				p_elem_coder = p_typemap->funcs.typecast_query_param(p_typemap, entry, i);
				enc_func = pg_coder_enc_func(p_elem_coder);

				/* 1st pass for retiving the required memory space */
				strlen = enc_func(p_elem_coder, entry, NULL, &subint, enc_idx);

				if( strlen == -1 ){
					/* we can directly use String value in subint */
					strlen = RSTRING_LENINT(subint);

					PG_RB_STR_ENSURE_CAPA( *intermediate, 4 + strlen, current_out, end_capa_ptr );
					/* 4 bytes length */
					write_nbo32(strlen, current_out);
					current_out += 4;

					memcpy( current_out, RSTRING_PTR(subint), strlen );
					current_out += strlen;
				} else {
					/* 2nd pass for writing the data to prepared buffer */
					PG_RB_STR_ENSURE_CAPA( *intermediate, 4 + strlen, current_out, end_capa_ptr );
					/* 4 bytes length */
					write_nbo32(strlen, current_out);
					current_out += 4;

					/* Place the string at current output position. */
					strlen = enc_func(p_elem_coder, entry, current_out, &subint, enc_idx);
					current_out += strlen;
				}
		}
	}

	rb_str_set_len( *intermediate, current_out - RSTRING_PTR(*intermediate) );

	return -1;
}


/*
 *	Return decimal value for a hexadecimal digit
 */
static int
GetDecimalFromHex(char hex)
{
	if (hex >= '0' && hex <= '9')
		return hex - '0';
	else if (hex >= 'a' && hex <= 'f')
		return hex - 'a' + 10;
	else if (hex >= 'A' && hex <= 'F')
		return hex - 'A' + 10;
	else
		return -1;
}

/*
 * Document-class: PG::TextDecoder::CopyRow < PG::CopyDecoder
 *
 * This class decodes one row of arbitrary columns received as COPY data in text format.
 * See the {COPY command}[http://www.postgresql.org/docs/current/static/sql-copy.html]
 * for description of the format.
 *
 * It is intended to be used in conjunction with PG::Connection#get_copy_data .
 *
 * The columns are retrieved as Array of values. The single values are decoded as defined
 * in the assigned #type_map. If no type_map was assigned, all values are converted to
 * strings by PG::TextDecoder::String.
 *
 * Example with default type map ( TypeMapAllStrings ):
 *   conn.exec("CREATE TABLE my_table AS VALUES('astring', 7, FALSE), ('string2', 42, TRUE) ")
 *
 *   deco = PG::TextDecoder::CopyRow.new
 *   conn.copy_data "COPY my_table TO STDOUT", deco do
 *     while row=conn.get_copy_data
 *       p row
 *     end
 *   end
 * This prints all rows of +my_table+ :
 *   ["astring", "7", "f"]
 *   ["string2", "42", "t"]
 *
 * Example with column based type map:
 *   tm = PG::TypeMapByColumn.new( [
 *     PG::TextDecoder::String.new,
 *     PG::TextDecoder::Integer.new,
 *     PG::TextDecoder::Boolean.new] )
 *   deco = PG::TextDecoder::CopyRow.new( type_map: tm )
 *   conn.copy_data "COPY my_table TO STDOUT", deco do
 *     while row=conn.get_copy_data
 *       p row
 *     end
 *   end
 * This prints the rows with type casted columns:
 *   ["astring", 7, false]
 *   ["string2", 42, true]
 *
 * Instead of manually assigning a type decoder for each column, PG::BasicTypeMapForResults
 * can be used to assign them based on the table OIDs.
 *
 * See also PG::TextEncoder::CopyRow for the encoding direction with
 * PG::Connection#put_copy_data .
 */
/*
 * Parse the current line into separate attributes (fields),
 * performing de-escaping as needed.
 *
 * All fields are gathered into a ruby Array. The de-escaped field data is written
 * into to a ruby String. This object is reused for non string columns.
 * For String columns the field value is directly used as return value and no
 * reuse of the memory is done.
 *
 * The parser is thankfully borrowed from the PostgreSQL sources:
 * src/backend/commands/copy.c
 */
static VALUE
pg_text_dec_copy_row(t_pg_coder *conv, const char *input_line, int len, int _tuple, int _field, int enc_idx)
{
	t_pg_copycoder *this = (t_pg_copycoder *)conv;

	/* Return value: array */
	VALUE array;

	/* Current field */
	VALUE field_str;

	char delimc = this->delimiter;
	int fieldno;
	int expected_fields;
	char *output_ptr;
	const char *cur_ptr;
	const char *line_end_ptr;
	char *end_capa_ptr;
	t_typemap *p_typemap;

	p_typemap = RTYPEDDATA_DATA( this->typemap );
	expected_fields = p_typemap->funcs.fit_to_copy_get( this->typemap );

	/* The received input string will probably have this->nfields fields. */
	array = rb_ary_new2(expected_fields);

	/* Allocate a new string with embedded capacity and realloc later with
	 * exponential growing size when needed. */
	PG_RB_STR_NEW( field_str, output_ptr, end_capa_ptr );

	/* set pointer variables for loop */
	cur_ptr = input_line;
	line_end_ptr = input_line + len;

	/* Outer loop iterates over fields */
	fieldno = 0;
	for (;;)
	{
		int found_delim = 0;
		const char *start_ptr;
		const char *end_ptr;
		long input_len;

		/* Remember start of field on input side */
		start_ptr = cur_ptr;

		/*
		 * Scan data for field.
		 *
		 * Note that in this loop, we are scanning to locate the end of field
		 * and also speculatively performing de-escaping.  Once we find the
		 * end-of-field, we can match the raw field contents against the null
		 * marker string.  Only after that comparison fails do we know that
		 * de-escaping is actually the right thing to do; therefore we *must
		 * not* throw any syntax errors before we've done the null-marker
		 * check.
		 */
		for (;;)
		{
			/* The current character in the input string. */
			char c;

			end_ptr = cur_ptr;
			if (cur_ptr >= line_end_ptr)
				break;
			c = *cur_ptr++;
			if (c == delimc){
				found_delim = 1;
				break;
			}
			if (c == '\n'){
				break;
			}
			if (c == '\\'){
				if (cur_ptr >= line_end_ptr)
					break;

				c = *cur_ptr++;
				switch (c){
					case '0':
					case '1':
					case '2':
					case '3':
					case '4':
					case '5':
					case '6':
					case '7':
						{
							/* handle \013 */
							int val;

							val = OCTVALUE(c);
							if (cur_ptr < line_end_ptr)
							{
								c = *cur_ptr;
								if (ISOCTAL(c))
								{
									cur_ptr++;
									val = (val << 3) + OCTVALUE(c);
									if (cur_ptr < line_end_ptr)
									{
										c = *cur_ptr;
										if (ISOCTAL(c))
										{
											cur_ptr++;
											val = (val << 3) + OCTVALUE(c);
										}
									}
								}
							}
							c = val & 0377;
						}
						break;
					case 'x':
						/* Handle \x3F */
						if (cur_ptr < line_end_ptr)
						{
							char hexchar = *cur_ptr;
							int val = GetDecimalFromHex(hexchar);;

							if (val >= 0)
							{
								cur_ptr++;
								if (cur_ptr < line_end_ptr)
								{
									int val2;
									hexchar = *cur_ptr;
									val2 = GetDecimalFromHex(hexchar);

									if (val2 >= 0)
									{
										cur_ptr++;
										val = (val << 4) + val2;
									}
								}
								c = val & 0xff;
							}
						}
						break;
					case 'b':
						c = '\b';
						break;
					case 'f':
						c = '\f';
						break;
					case 'n':
						c = '\n';
						break;
					case 'r':
						c = '\r';
						break;
					case 't':
						c = '\t';
						break;
					case 'v':
						c = '\v';
						break;

						/*
						 * in all other cases, take the char after '\'
						 * literally
						 */
				}
			}

			PG_RB_STR_ENSURE_CAPA( field_str, 1, output_ptr, end_capa_ptr );
			/* Add c to output string */
			*output_ptr++ = c;
		}

		if (!found_delim && cur_ptr < line_end_ptr)
			rb_raise( rb_eArgError, "trailing data after linefeed at position: %ld", (long)(cur_ptr - input_line) + 1 );


		/* Check whether raw input matched null marker */
		input_len = end_ptr - start_ptr;
		if (input_len == RSTRING_LEN(this->null_string) &&
					strncmp(start_ptr, RSTRING_PTR(this->null_string), input_len) == 0) {
			rb_ary_push(array, Qnil);
		} else {
			VALUE field_value;

			rb_str_set_len( field_str, output_ptr - RSTRING_PTR(field_str) );
			field_value = p_typemap->funcs.typecast_copy_get( p_typemap, field_str, fieldno, 0, enc_idx );

			rb_ary_push(array, field_value);

			if( field_value == field_str ){
				/* Our output string will be send to the user, so we can not reuse
				 * it for the next field. */
				PG_RB_STR_NEW( field_str, output_ptr, end_capa_ptr );
			}
		}
		/* Reset the pointer to the start of the output/buffer string. */
		output_ptr = RSTRING_PTR(field_str);

		fieldno++;
		/* Done if we hit EOL instead of a delim */
		if (!found_delim)
			break;
	}

	return array;
}


static const char BinarySignature[11] = "PGCOPY\n\377\r\n\0";

/*
 * Document-class: PG::BinaryDecoder::CopyRow < PG::CopyDecoder
 *
 * This class decodes one row of arbitrary columns received as COPY data in binary format.
 * See the {COPY command}[http://www.postgresql.org/docs/current/static/sql-copy.html]
 * for description of the format.
 *
 * It is intended to be used in conjunction with PG::Connection#get_copy_data .
 *
 * The columns are retrieved as Array of values. The single values are decoded as defined
 * in the assigned #type_map. If no type_map was assigned, all values are converted to
 * strings by PG::BinaryDecoder::String.
 *
 * Example with default type map ( TypeMapAllStrings ):
 *   conn.exec("CREATE TABLE my_table AS VALUES('astring', 7, FALSE), ('string2', 42, TRUE) ")
 *
 *   deco = PG::BinaryDecoder::CopyRow.new
 *   conn.copy_data "COPY my_table TO STDOUT WITH (FORMAT binary)", deco do
 *     while row=conn.get_copy_data
 *       p row
 *     end
 *   end
 * This prints all rows of +my_table+ in binary format:
 *   ["astring", "\x00\x00\x00\a", "\x00"]
 *   ["string2", "\x00\x00\x00*", "\x01"]
 *
 * Example with column based type map:
 *   tm = PG::TypeMapByColumn.new( [
 *     PG::BinaryDecoder::String.new,
 *     PG::BinaryDecoder::Integer.new,
 *     PG::BinaryDecoder::Boolean.new] )
 *   deco = PG::BinaryDecoder::CopyRow.new( type_map: tm )
 *   conn.copy_data "COPY my_table TO STDOUT WITH (FORMAT binary)", deco do
 *     while row=conn.get_copy_data
 *       p row
 *     end
 *   end
 * This prints the rows with type casted columns:
 *   ["astring", 7, false]
 *   ["string2", 42, true]
 *
 * Instead of manually assigning a type decoder for each column, PG::BasicTypeMapForResults
 * can be used to assign them based on the table OIDs.
 *
 * See also PG::BinaryEncoder::CopyRow for the encoding direction with
 * PG::Connection#put_copy_data .
 */
static VALUE
pg_bin_dec_copy_row(t_pg_coder *conv, const char *input_line, int len, int _tuple, int _field, int enc_idx)
{
	t_pg_copycoder *this = (t_pg_copycoder *)conv;

	/* Return value: array */
	VALUE array;

	/* Current field */
	VALUE field_str;

	int nfields;
	int expected_fields;
	int fieldno;
	char *output_ptr;
	const char *cur_ptr;
	const char *line_end_ptr;
	char *end_capa_ptr;
	t_typemap *p_typemap;

	p_typemap = RTYPEDDATA_DATA( this->typemap );
	expected_fields = p_typemap->funcs.fit_to_copy_get( this->typemap );

	/* Allocate a new string with embedded capacity and realloc later with
	 * exponential growing size when needed. */
	PG_RB_STR_NEW( field_str, output_ptr, end_capa_ptr );

	/* set pointer variables for loop */
	cur_ptr = input_line;
	line_end_ptr = input_line + len;

	if (cur_ptr + 11 <= line_end_ptr && memcmp(cur_ptr, BinarySignature, 11) == 0){
		/* binary COPY header signature detected -> just drop it */
		int ext_bytes;
		cur_ptr += 11;

		/* read flags */
		if (cur_ptr + 4 > line_end_ptr) goto length_error;
		cur_ptr += 4;

		/* read header extensions */
		if (cur_ptr + 4 > line_end_ptr) goto length_error;
		ext_bytes = read_nbo32(cur_ptr);
		if (ext_bytes < 0) goto length_error;
		cur_ptr += 4;
		if (cur_ptr + ext_bytes > line_end_ptr) goto length_error;
		cur_ptr += ext_bytes;
	}

	/* read row header */
	if (cur_ptr + 2 > line_end_ptr) goto length_error;
	nfields = read_nbo16(cur_ptr);
	cur_ptr += 2;

	/* COPY data trailer? */
	if (nfields < 0) {
		if (nfields != -1) goto length_error;
		array = Qnil;
	} else {
		array = rb_ary_new2(expected_fields);

		for( fieldno = 0; fieldno < nfields; fieldno++){
			long input_len;
			VALUE field_value;

			/* read field size */
			if (cur_ptr + 4 > line_end_ptr) goto length_error;
			input_len = read_nbo32(cur_ptr);
			cur_ptr += 4;

			if (input_len < 0) {
				if (input_len != -1) goto length_error;
				/* NULL indicator */
				rb_ary_push(array, Qnil);
			} else {
				if (cur_ptr + input_len > line_end_ptr) goto length_error;

				/* copy input data to field_str */
				PG_RB_STR_ENSURE_CAPA( field_str, input_len, output_ptr, end_capa_ptr );
				memcpy(output_ptr, cur_ptr, input_len);
				cur_ptr += input_len;
				output_ptr += input_len;
				/* convert field_str through the type map */
				rb_str_set_len( field_str, output_ptr - RSTRING_PTR(field_str) );
				field_value = p_typemap->funcs.typecast_copy_get( p_typemap, field_str, fieldno, 1, enc_idx );

				rb_ary_push(array, field_value);

				if( field_value == field_str ){
					/* Our output string will be send to the user, so we can not reuse
					* it for the next field. */
					PG_RB_STR_NEW( field_str, output_ptr, end_capa_ptr );
				}
			}

			/* Reset the pointer to the start of the output/buffer string. */
			output_ptr = RSTRING_PTR(field_str);
		}
	}

	if (cur_ptr < line_end_ptr)
		rb_raise( rb_eArgError, "trailing data after row data at position: %ld", (long)(cur_ptr - input_line) + 1 );

	return array;

length_error:
	rb_raise( rb_eArgError, "premature end of COPY data at position: %ld", (long)(cur_ptr - input_line) + 1 );
}

void
init_pg_copycoder(void)
{
	VALUE coder;
	/* Document-class: PG::CopyCoder < PG::Coder
	 *
	 * This is the base class for all type cast classes for COPY data,
	 */
	rb_cPG_CopyCoder = rb_define_class_under( rb_mPG, "CopyCoder", rb_cPG_Coder );
	rb_define_method( rb_cPG_CopyCoder, "type_map=", pg_copycoder_type_map_set, 1 );
	rb_define_method( rb_cPG_CopyCoder, "type_map", pg_copycoder_type_map_get, 0 );
	rb_define_method( rb_cPG_CopyCoder, "delimiter=", pg_copycoder_delimiter_set, 1 );
	rb_define_method( rb_cPG_CopyCoder, "delimiter", pg_copycoder_delimiter_get, 0 );
	rb_define_method( rb_cPG_CopyCoder, "null_string=", pg_copycoder_null_string_set, 1 );
	rb_define_method( rb_cPG_CopyCoder, "null_string", pg_copycoder_null_string_get, 0 );

	/* Document-class: PG::CopyEncoder < PG::CopyCoder */
	rb_cPG_CopyEncoder = rb_define_class_under( rb_mPG, "CopyEncoder", rb_cPG_CopyCoder );
	rb_define_alloc_func( rb_cPG_CopyEncoder, pg_copycoder_encoder_allocate );
	/* Document-class: PG::CopyDecoder < PG::CopyCoder */
	rb_cPG_CopyDecoder = rb_define_class_under( rb_mPG, "CopyDecoder", rb_cPG_CopyCoder );
	rb_define_alloc_func( rb_cPG_CopyDecoder, pg_copycoder_decoder_allocate );

	/* Make RDoc aware of the encoder classes... */
	/* rb_mPG_TextEncoder = rb_define_module_under( rb_mPG, "TextEncoder" ); */
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "CopyRow", rb_cPG_CopyEncoder ); */
	coder = pg_define_coder( "CopyRow", pg_text_enc_copy_row, rb_cPG_CopyEncoder, rb_mPG_TextEncoder );
	rb_include_module( coder, rb_mPG_BinaryFormatting );
	/* rb_mPG_BinaryEncoder = rb_define_module_under( rb_mPG, "BinaryEncoder" ); */
	/* dummy = rb_define_class_under( rb_mPG_BinaryEncoder, "CopyRow", rb_cPG_CopyEncoder ); */
	pg_define_coder( "CopyRow", pg_bin_enc_copy_row, rb_cPG_CopyEncoder, rb_mPG_BinaryEncoder );

	/* rb_mPG_TextDecoder = rb_define_module_under( rb_mPG, "TextDecoder" ); */
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "CopyRow", rb_cPG_CopyDecoder ); */
	coder = pg_define_coder( "CopyRow", pg_text_dec_copy_row, rb_cPG_CopyDecoder, rb_mPG_TextDecoder );
	/* Although CopyRow is a text decoder, data can contain zero bytes and are not zero terminated.
	 * They are handled like binaries. So format is set to 1 (binary). */
	rb_include_module( coder, rb_mPG_BinaryFormatting );
	/* rb_mPG_BinaryDecoder = rb_define_module_under( rb_mPG, "BinaryDecoder" ); */
	/* dummy = rb_define_class_under( rb_mPG_BinaryDecoder, "CopyRow", rb_cPG_CopyDecoder ); */
	pg_define_coder( "CopyRow", pg_bin_dec_copy_row, rb_cPG_CopyDecoder, rb_mPG_BinaryDecoder );
}
