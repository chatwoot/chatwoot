/*
 * pg_record_coder.c - PG::Coder class extension
 *
 */

#include "pg.h"

VALUE rb_cPG_RecordCoder;
VALUE rb_cPG_RecordEncoder;
VALUE rb_cPG_RecordDecoder;

typedef struct {
	t_pg_coder comp;
	VALUE typemap;
} t_pg_recordcoder;


static void
pg_recordcoder_mark( void *_this )
{
	t_pg_recordcoder *this = (t_pg_recordcoder *)_this;
	rb_gc_mark_movable(this->typemap);
}

static size_t
pg_recordcoder_memsize( const void *_this )
{
	const t_pg_recordcoder *this = (const t_pg_recordcoder *)_this;
	return sizeof(*this);
}

static void
pg_recordcoder_compact( void *_this )
{
	t_pg_recordcoder *this = (t_pg_recordcoder *)_this;
	pg_coder_compact(&this->comp);
	pg_gc_location(this->typemap);
}

static const rb_data_type_t pg_recordcoder_type = {
	"PG::RecordCoder",
	{
		pg_recordcoder_mark,
		RUBY_TYPED_DEFAULT_FREE,
		pg_recordcoder_memsize,
		pg_compact_callback(pg_recordcoder_compact),
	},
	&pg_coder_type,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED | PG_RUBY_TYPED_FROZEN_SHAREABLE,
};

static VALUE
pg_recordcoder_encoder_allocate( VALUE klass )
{
	t_pg_recordcoder *this;
	VALUE self = TypedData_Make_Struct( klass, t_pg_recordcoder, &pg_recordcoder_type, this );
	pg_coder_init_encoder( self );
	RB_OBJ_WRITE(self, &this->typemap, pg_typemap_all_strings);
	return self;
}

static VALUE
pg_recordcoder_decoder_allocate( VALUE klass )
{
	t_pg_recordcoder *this;
	VALUE self = TypedData_Make_Struct( klass, t_pg_recordcoder, &pg_recordcoder_type, this );
	pg_coder_init_decoder( self );
	RB_OBJ_WRITE(self, &this->typemap, pg_typemap_all_strings);
	return self;
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
pg_recordcoder_type_map_set(VALUE self, VALUE type_map)
{
	t_pg_recordcoder *this = RTYPEDDATA_DATA( self );

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
pg_recordcoder_type_map_get(VALUE self)
{
	t_pg_recordcoder *this = RTYPEDDATA_DATA( self );

	return this->typemap;
}


/*
 * Document-class: PG::TextEncoder::Record < PG::RecordEncoder
 *
 * This class encodes one record of columns for transmission as query parameter in text format.
 * See PostgreSQL {Composite Types}[https://www.postgresql.org/docs/current/rowtypes.html] for a description of the format and how it can be used.
 *
 * PostgreSQL allows composite types to be used in many of the same ways that simple types can be used.
 * For example, a column of a table can be declared to be of a composite type.
 *
 * The encoder expects the record columns as array of values.
 * The single values are encoded as defined in the assigned #type_map.
 * If no type_map was assigned, all values are converted to strings by PG::TextEncoder::String.
 *
 * It is possible to manually assign a type encoder for each column per PG::TypeMapByColumn,
 * or to make use of PG::BasicTypeMapBasedOnResult to assign them based on the table OIDs.
 *
 * Encode a record from an <code>Array<String></code> to a +String+ in PostgreSQL Composite Type format (uses default type map TypeMapAllStrings):
 *   PG::TextEncoder::Record.new.encode([1, 2])  # => "(\"1\",\"2\")"
 *
 * Encode a record from <code>Array<Float></code> to +String+ :
 *   # Build a type map for two Floats
 *   tm = PG::TypeMapByColumn.new([PG::TextEncoder::Float.new]*2)
 *   # Use this type map to encode the record:
 *   PG::TextEncoder::Record.new(type_map: tm).encode([1,2])
 *   # => "(\"1.0\",\"2.0\")"
 *
 * Records can also be encoded and decoded directly to and from the database.
 * This avoids intermediate string allocations and is very fast.
 * Take the following type and table definitions:
 *   conn.exec("CREATE TYPE complex AS (r float, i float) ")
 *   conn.exec("CREATE TABLE my_table (v1 complex, v2 complex) ")
 *
 * A record can be encoded by adding a type map to Connection#exec_params and siblings:
 *   # Build a type map for the two floats "r" and "i" as in our "complex" type
 *   tm = PG::TypeMapByColumn.new([PG::TextEncoder::Float.new]*2)
 *   # Build a record encoder to encode this type as a record:
 *   enco = PG::TextEncoder::Record.new(type_map: tm)
 *   # Insert table data and use the encoder to cast the complex value "v1" from ruby array:
 *   conn.exec_params("INSERT INTO my_table VALUES ($1) RETURNING v1", [[1,2]], 0, PG::TypeMapByColumn.new([enco])).to_a
 *   # => [{"v1"=>"(1,2)"}]
 *
 * Alternatively the typemap can be build based on database OIDs rather than manually assigning encoders.
 *   # Fetch a NULL record of our type to retrieve the OIDs of the two fields "r" and "i"
 *   oids = conn.exec( "SELECT (NULL::complex).*" )
 *   # Build a type map (PG::TypeMapByColumn) for encoding the "complex" type
 *   etm = PG::BasicTypeMapBasedOnResult.new(conn).build_column_map( oids )
 *
 * It's also possible to use the BasicTypeMapForQueries to send records to the database server.
 * In contrast to ORM libraries, PG doesn't have information regarding the type of data the server is expecting.
 * So BasicTypeMapForQueries works based on the class of the values to be sent and it has to be instructed that a ruby array shall be casted to a record.
 *   # Retrieve OIDs of all basic types from the database
 *   etm = PG::BasicTypeMapForQueries.new(conn)
 *   etm.encode_array_as = :record
 *   # Apply the basic type registry to all values sent to the server
 *   conn.type_map_for_queries = etm
 *   # Send a complex number as an array of two integers
 *   conn.exec_params("INSERT INTO my_table VALUES ($1) RETURNING v1", [[1,2]]).to_a
 *   # => [{"v1"=>"(1,2)"}]
 *
 * Records can also be nested or further wrapped into other encoders like PG::TextEncoder::CopyRow.
 *
 * See also PG::TextDecoder::Record for the decoding direction.
 */
static int
pg_text_enc_record(t_pg_coder *conv, VALUE value, char *out, VALUE *intermediate, int enc_idx)
{
	t_pg_recordcoder *this = (t_pg_recordcoder *)conv;
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
	PG_RB_STR_ENSURE_CAPA( *intermediate, 1, current_out, end_capa_ptr );
	*current_out++ = '(';

	for( i=0; i<RARRAY_LEN(value); i++){
		char *ptr1;
		char *ptr2;
		long strlen;
		int backslashs;
		VALUE subint;
		VALUE entry;

		entry = rb_ary_entry(value, i);

		if( i > 0 ){
			PG_RB_STR_ENSURE_CAPA( *intermediate, 1, current_out, end_capa_ptr );
			*current_out++ = ',';
		}

		switch(TYPE(entry)){
			case T_NIL:
				/* emit nothing... */
				break;
			default:
				p_elem_coder = p_typemap->funcs.typecast_query_param(p_typemap, entry, i);
				enc_func = pg_coder_enc_func(p_elem_coder);

				/* 1st pass for retiving the required memory space */
				strlen = enc_func(p_elem_coder, entry, NULL, &subint, enc_idx);

				if( strlen == -1 ){
					/* we can directly use String value in subint */
					strlen = RSTRING_LEN(subint);

					/* size of string assuming the worst case, that every character must be escaped. */
					PG_RB_STR_ENSURE_CAPA( *intermediate, strlen * 2 + 2, current_out, end_capa_ptr );

					*current_out++ = '"';
					/* Record string from subint with backslash escaping */
					for(ptr1 = RSTRING_PTR(subint); ptr1 < RSTRING_PTR(subint) + strlen; ptr1++) {
						if (*ptr1 == '"' || *ptr1 == '\\') {
							*current_out++ = *ptr1;
						}
						*current_out++ = *ptr1;
					}
					*current_out++ = '"';
				} else {
					/* 2nd pass for writing the data to prepared buffer */
					/* size of string assuming the worst case, that every character must be escaped. */
					PG_RB_STR_ENSURE_CAPA( *intermediate, strlen * 2 + 2, current_out, end_capa_ptr );

					*current_out++ = '"';
					/* Place the unescaped string at current output position. */
					strlen = enc_func(p_elem_coder, entry, current_out, &subint, enc_idx);

					ptr1 = current_out;
					ptr2 = current_out + strlen;

					/* count required backlashs */
					for(backslashs = 0; ptr1 != ptr2; ptr1++) {
						/* Escape backslash itself, newline, carriage return, and the current delimiter character. */
						if(*ptr1 == '"' || *ptr1 == '\\'){
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
						if(*ptr1 == '"' || *ptr1 == '\\'){
							*--ptr2 = *ptr1;
						}
					}
					*current_out++ = '"';
				}
		}
	}
	PG_RB_STR_ENSURE_CAPA( *intermediate, 1, current_out, end_capa_ptr );
	*current_out++ = ')';

	rb_str_set_len( *intermediate, current_out - RSTRING_PTR(*intermediate) );

	return -1;
}

/*
 * record_isspace() --- a non-locale-dependent isspace()
 *
 * We used to use isspace() for parsing array values, but that has
 * undesirable results: an array value might be silently interpreted
 * differently depending on the locale setting.  Now we just hard-wire
 * the traditional ASCII definition of isspace().
 */
static int
record_isspace(char ch)
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

/*
 * Document-class: PG::TextDecoder::Record < PG::RecordDecoder
 *
 * This class decodes one record of values received from a composite type column in text format.
 * See PostgreSQL {Composite Types}[https://www.postgresql.org/docs/current/rowtypes.html] for a description of the format and how it can be used.
 *
 * PostgreSQL allows composite types to be used in many of the same ways that simple types can be used.
 * For example, a column of a table can be declared to be of a composite type.
 *
 * The columns are returned from the decoder as array of values.
 * The single values are decoded as defined in the assigned #type_map.
 * If no type_map was assigned, all values are converted to strings by PG::TextDecoder::String.
 *
 * Decode a record in Composite Type format from +String+ to <code>Array<String></code> (uses default type map TypeMapAllStrings):
 *   PG::TextDecoder::Record.new.decode("(1,2)")  # => ["1", "2"]
 *
 * Decode a record from +String+ to <code>Array<Float></code> :
 *   # Build a type map for two Floats
 *   tm = PG::TypeMapByColumn.new([PG::TextDecoder::Float.new]*2)
 *   # Use this type map to decode the record:
 *   PG::TextDecoder::Record.new(type_map: tm).decode("(1,2)")
 *   # => [1.0, 2.0]
 *
 * Records can also be encoded and decoded directly to and from the database.
 * This avoids intermediate String allocations and is very fast.
 * Take the following type and table definitions:
 *   conn.exec("CREATE TYPE complex AS (r float, i float) ")
 *   conn.exec("CREATE TABLE my_table (v1 complex, v2 complex) ")
 *   conn.exec("INSERT INTO my_table VALUES((2,3), (4,5)), ((6,7), (8,9)) ")
 *
 * The record can be decoded by applying a type map to the PG::Result object:
 *   # Build a type map for two floats "r" and "i"
 *   tm = PG::TypeMapByColumn.new([PG::TextDecoder::Float.new]*2)
 *   # Build a record decoder to decode this two-value type:
 *   deco = PG::TextDecoder::Record.new(type_map: tm)
 *   # Fetch table data and use the decoder to cast the two complex values "v1" and "v2":
 *   conn.exec("SELECT * FROM my_table").map_types!(PG::TypeMapByColumn.new([deco]*2)).to_a
 *   # => [{"v1"=>[2.0, 3.0], "v2"=>[4.0, 5.0]}, {"v1"=>[6.0, 7.0], "v2"=>[8.0, 9.0]}]
 *
 * It's more very convenient to use the PG::BasicTypeRegistry, which is based on database OIDs.
 *   # Fetch a NULL record of our type to retrieve the OIDs of the two fields "r" and "i"
 *   oids = conn.exec( "SELECT (NULL::complex).*" )
 *   # Build a type map (PG::TypeMapByColumn) for decoding the "complex" type
 *   dtm = PG::BasicTypeMapForResults.new(conn).build_column_map( oids )
 *   # Build a type map and populate with basic types
 *   btr = PG::BasicTypeRegistry.new.register_default_types
 *   # Register a new record decoder for decoding our type "complex"
 *   btr.register_coder(PG::TextDecoder::Record.new(type_map: dtm, name: "complex"))
 *   # Apply our basic type registry to all results retrieved from the server
 *   conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: btr)
 *   # Now queries decode the "complex" type (and many basic types) automatically
 *   conn.exec("SELECT * FROM my_table").to_a
 *   # => [{"v1"=>[2.0, 3.0], "v2"=>[4.0, 5.0]}, {"v1"=>[6.0, 7.0], "v2"=>[8.0, 9.0]}]
 *
 * Records can also be nested or further wrapped into other decoders like PG::TextDecoder::CopyRow.
 *
 * See also PG::TextEncoder::Record for the encoding direction (data sent to the server).
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
 * src/backend/utils/adt/rowtypes.c
 */
static VALUE
pg_text_dec_record(t_pg_coder *conv, char *input_line, int len, int _tuple, int _field, int enc_idx)
{
	t_pg_recordcoder *this = (t_pg_recordcoder *)conv;

	/* Return value: array */
	VALUE array;

	/* Current field */
	VALUE field_str;

	int fieldno;
	int expected_fields;
	char *output_ptr;
	char *cur_ptr;
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

	/*
	 * Scan the string.  We use "buf" to accumulate the de-quoted data for
	 * each column, which is then fed to the appropriate input converter.
	 */
	/* Allow leading whitespace */
	while (*cur_ptr && record_isspace(*cur_ptr))
		cur_ptr++;
	if (*cur_ptr++ != '(')
		rb_raise( rb_eArgError, "malformed record literal: \"%s\" - Missing left parenthesis.", input_line );

	for (fieldno = 0; ; fieldno++)
	{
		/* Check for null: completely empty input means null */
		if (*cur_ptr == ',' || *cur_ptr == ')')
		{
			rb_ary_push(array, Qnil);
		}
		else
		{
			/* Extract string for this column */
			int inquote = 0;
			VALUE field_value;

			while (inquote || !(*cur_ptr == ',' || *cur_ptr == ')'))
			{
				char ch = *cur_ptr++;

				if (ch == '\0')
					rb_raise( rb_eArgError, "malformed record literal: \"%s\" - Unexpected end of input.", input_line );
				if (ch == '\\')
				{
					if (*cur_ptr == '\0')
						rb_raise( rb_eArgError, "malformed record literal: \"%s\" - Unexpected end of input.", input_line );
					PG_RB_STR_ENSURE_CAPA( field_str, 1, output_ptr, end_capa_ptr );
					*output_ptr++ = *cur_ptr++;
				}
				else if (ch == '"')
				{
					if (!inquote)
						inquote = 1;
					else if (*cur_ptr == '"')
					{
						/* doubled quote within quote sequence */
						PG_RB_STR_ENSURE_CAPA( field_str, 1, output_ptr, end_capa_ptr );
						*output_ptr++ = *cur_ptr++;
					}
					else
						inquote = 0;
				} else {
					PG_RB_STR_ENSURE_CAPA( field_str, 1, output_ptr, end_capa_ptr );
					/* Add ch to output string */
					*output_ptr++ = ch;
				}
			}

			/* Convert the column value */
			rb_str_set_len( field_str, output_ptr - RSTRING_PTR(field_str) );
			field_value = p_typemap->funcs.typecast_copy_get( p_typemap, field_str, fieldno, 0, enc_idx );

			rb_ary_push(array, field_value);

			if( field_value == field_str ){
				/* Our output string will be send to the user, so we can not reuse
				 * it for the next field. */
				PG_RB_STR_NEW( field_str, output_ptr, end_capa_ptr );
			}
			/* Reset the pointer to the start of the output/buffer string. */
			output_ptr = RSTRING_PTR(field_str);
		}

		/* Skip comma that separates prior field from this one */
		if (*cur_ptr == ',') {
			cur_ptr++;
		} else if (*cur_ptr == ')') {
			cur_ptr++;
			/* Done if we hit closing parenthesis */
			break;
		} else {
			rb_raise( rb_eArgError, "malformed record literal: \"%s\" - Too few columns.", input_line );
		}
	}

	/* Allow trailing whitespace */
	while (*cur_ptr && record_isspace(*cur_ptr))
		cur_ptr++;
	if (*cur_ptr)
		rb_raise( rb_eArgError, "malformed record literal: \"%s\" - Junk after right parenthesis.", input_line );

	return array;
}


void
init_pg_recordcoder(void)
{
	/* Document-class: PG::RecordCoder < PG::Coder
	 *
	 * This is the base class for all type cast classes for COPY data,
	 */
	rb_cPG_RecordCoder = rb_define_class_under( rb_mPG, "RecordCoder", rb_cPG_Coder );
	rb_define_method( rb_cPG_RecordCoder, "type_map=", pg_recordcoder_type_map_set, 1 );
	rb_define_method( rb_cPG_RecordCoder, "type_map", pg_recordcoder_type_map_get, 0 );

	/* Document-class: PG::RecordEncoder < PG::RecordCoder */
	rb_cPG_RecordEncoder = rb_define_class_under( rb_mPG, "RecordEncoder", rb_cPG_RecordCoder );
	rb_define_alloc_func( rb_cPG_RecordEncoder, pg_recordcoder_encoder_allocate );
	/* Document-class: PG::RecordDecoder < PG::RecordCoder */
	rb_cPG_RecordDecoder = rb_define_class_under( rb_mPG, "RecordDecoder", rb_cPG_RecordCoder );
	rb_define_alloc_func( rb_cPG_RecordDecoder, pg_recordcoder_decoder_allocate );

	/* Make RDoc aware of the encoder classes... */
	/* rb_mPG_TextEncoder = rb_define_module_under( rb_mPG, "TextEncoder" ); */
	/* dummy = rb_define_class_under( rb_mPG_TextEncoder, "Record", rb_cPG_RecordEncoder ); */
	pg_define_coder( "Record", pg_text_enc_record, rb_cPG_RecordEncoder, rb_mPG_TextEncoder );
	/* rb_mPG_TextDecoder = rb_define_module_under( rb_mPG, "TextDecoder" ); */
	/* dummy = rb_define_class_under( rb_mPG_TextDecoder, "Record", rb_cPG_RecordDecoder ); */
	pg_define_coder( "Record", pg_text_dec_record, rb_cPG_RecordDecoder, rb_mPG_TextDecoder );
}
