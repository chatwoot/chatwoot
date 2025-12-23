/*
 * pg_column_map.c - PG::ColumnMap class extension
 * $Id$
 *
 */

#include "pg.h"

static VALUE rb_cTypeMapByColumn;
static ID s_id_decode;
static ID s_id_encode;

static VALUE pg_tmbc_s_allocate( VALUE klass );

static VALUE
pg_tmbc_fit_to_result( VALUE self, VALUE result )
{
	int nfields;
	t_tmbc *this = RTYPEDDATA_DATA( self );
	t_typemap *default_tm;
	VALUE sub_typemap;

	nfields = PQnfields( pgresult_get(result) );
	if ( this->nfields != nfields ) {
		rb_raise( rb_eArgError, "number of result fields (%d) does not match number of mapped columns (%d)",
				nfields, this->nfields );
	}

	/* Ensure that the default type map fits equally. */
	default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
	sub_typemap = default_tm->funcs.fit_to_result( this->typemap.default_typemap, result );

	/* Did the default type return the same object ? */
	if( sub_typemap == this->typemap.default_typemap ){
		return self;
	} else {
		/* Our default type map built a new object, so we need to propagate it
		 * and build a copy of this type map and set it as default there.. */
		VALUE new_typemap = pg_tmbc_s_allocate( rb_cTypeMapByColumn );
		size_t struct_size = sizeof(t_tmbc) + sizeof(struct pg_tmbc_converter) * nfields;
		t_tmbc *p_new_typemap = (t_tmbc *)xmalloc(struct_size);

		memcpy( p_new_typemap, this, struct_size );
		p_new_typemap->typemap.default_typemap = sub_typemap;
		RTYPEDDATA_DATA(new_typemap) = p_new_typemap;
		return new_typemap;
	}
}

static VALUE
pg_tmbc_fit_to_query( VALUE self, VALUE params )
{
	int nfields;
	t_tmbc *this = RTYPEDDATA_DATA( self );
	t_typemap *default_tm;

	nfields = (int)RARRAY_LEN( params );
	if ( this->nfields != nfields ) {
		rb_raise( rb_eArgError, "number of result fields (%d) does not match number of mapped columns (%d)",
				nfields, this->nfields );
	}

	/* Ensure that the default type map fits equally. */
	default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
	default_tm->funcs.fit_to_query( this->typemap.default_typemap, params );

	return self;
}

static int
pg_tmbc_fit_to_copy_get( VALUE self )
{
	t_tmbc *this = RTYPEDDATA_DATA( self );

	/* Ensure that the default type map fits equally. */
	t_typemap *default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
	default_tm->funcs.fit_to_copy_get( this->typemap.default_typemap );

	return this->nfields;
}


VALUE
pg_tmbc_result_value( t_typemap *p_typemap, VALUE result, int tuple, int field )
{
	t_pg_coder *p_coder = NULL;
	t_pg_result *p_result = pgresult_get_this(result);
	t_tmbc *this = (t_tmbc *) p_typemap;
	t_typemap *default_tm;

	if (PQgetisnull(p_result->pgresult, tuple, field)) {
		return Qnil;
	}

	p_coder = this->convs[field].cconv;

	if( p_coder ){
		char * val = PQgetvalue( p_result->pgresult, tuple, field );
		int len = PQgetlength( p_result->pgresult, tuple, field );

		if( p_coder->dec_func ){
			return p_coder->dec_func(p_coder, val, len, tuple, field, p_result->enc_idx);
		} else {
			t_pg_coder_dec_func dec_func;
			dec_func = pg_coder_dec_func( p_coder, PQfformat(p_result->pgresult, field) );
			return dec_func(p_coder, val, len, tuple, field, p_result->enc_idx);
		}
	}

	default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
	return default_tm->funcs.typecast_result_value( default_tm, result, tuple, field );
}

static t_pg_coder *
pg_tmbc_typecast_query_param( t_typemap *p_typemap, VALUE param_value, int field )
{
	t_tmbc *this = (t_tmbc *) p_typemap;

	/* Number of fields were already checked in pg_tmbc_fit_to_query() */
	t_pg_coder *p_coder = this->convs[field].cconv;

	if( !p_coder ){
		t_typemap *default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
		return default_tm->funcs.typecast_query_param( default_tm, param_value, field );
	}

	return p_coder;
}

static VALUE
pg_tmbc_typecast_copy_get( t_typemap *p_typemap, VALUE field_str, int fieldno, int format, int enc_idx )
{
	t_tmbc *this = (t_tmbc *) p_typemap;
	t_pg_coder *p_coder;
	t_pg_coder_dec_func dec_func;

	if ( fieldno >= this->nfields || fieldno < 0 ) {
		rb_raise( rb_eArgError, "number of copy fields (%d) exceeds number of mapped columns (%d)",
				fieldno, this->nfields );
	}

	p_coder = this->convs[fieldno].cconv;

	if( !p_coder ){
		t_typemap *default_tm = RTYPEDDATA_DATA( this->typemap.default_typemap );
		return default_tm->funcs.typecast_copy_get( default_tm, field_str, fieldno, format, enc_idx );
	}

	dec_func = pg_coder_dec_func( p_coder, format );

	/* Is it a pure String conversion? Then we can directly send field_str to the user. */
	if( dec_func == pg_text_dec_string ){
		rb_str_modify(field_str);
		PG_ENCODING_SET_NOCHECK( field_str, enc_idx );
		return field_str;
	}
	if( dec_func == pg_bin_dec_bytea ){
		rb_str_modify(field_str);
		PG_ENCODING_SET_NOCHECK( field_str, rb_ascii8bit_encindex() );
		return field_str;
	}

	return dec_func( p_coder, RSTRING_PTR(field_str), RSTRING_LENINT(field_str), 0, fieldno, enc_idx );
}

const struct pg_typemap_funcs pg_tmbc_funcs = {
	pg_tmbc_fit_to_result,
	pg_tmbc_fit_to_query,
	pg_tmbc_fit_to_copy_get,
	pg_tmbc_result_value,
	pg_tmbc_typecast_query_param,
	pg_tmbc_typecast_copy_get
};

static void
pg_tmbc_mark( void *_this )
{
	t_tmbc *this = (t_tmbc *)_this;
	int i;

	/* allocated but not initialized ? */
	if( this == (t_tmbc *)&pg_typemap_funcs ) return;

	pg_typemap_mark(&this->typemap);
	for( i=0; i<this->nfields; i++){
		t_pg_coder *p_coder = this->convs[i].cconv;
		if( p_coder )
			rb_gc_mark_movable(p_coder->coder_obj);
	}
}

static size_t
pg_tmbc_memsize( const void *_this )
{
	const t_tmbc *this = (const t_tmbc *)_this;
	return sizeof(t_tmbc) + sizeof(struct pg_tmbc_converter) * this->nfields;
}

static void
pg_tmbc_compact( void *_this )
{
	t_tmbc *this = (t_tmbc *)_this;
	int i;

	/* allocated but not initialized ? */
	if( this == (t_tmbc *)&pg_typemap_funcs ) return;

	pg_typemap_compact(&this->typemap);
	for( i=0; i<this->nfields; i++){
		t_pg_coder *p_coder = this->convs[i].cconv;
		if( p_coder )
			pg_gc_location(p_coder->coder_obj);
	}
}

static void
pg_tmbc_free( void *_this )
{
	t_tmbc *this = (t_tmbc *)_this;
	/* allocated but not initialized ? */
	if( this == (t_tmbc *)&pg_typemap_funcs ) return;
	xfree( this );
}

static const rb_data_type_t pg_tmbc_type = {
	"PG::TypeMapByColumn",
	{
		pg_tmbc_mark,
		pg_tmbc_free,
		pg_tmbc_memsize,
		pg_compact_callback(pg_tmbc_compact),
	},
	&pg_typemap_type,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED | PG_RUBY_TYPED_FROZEN_SHAREABLE,
};

static VALUE
pg_tmbc_s_allocate( VALUE klass )
{
	/* Use pg_typemap_funcs as interim struct until #initialize is called. */
	return TypedData_Wrap_Struct( klass, &pg_tmbc_type, (t_tmbc *)&pg_typemap_funcs );
}

VALUE
pg_tmbc_allocate(void)
{
	return pg_tmbc_s_allocate(rb_cTypeMapByColumn);
}

/*
 * call-seq:
 *    PG::TypeMapByColumn.new( coders )
 *
 * Builds a new type map and assigns a list of coders for the given column.
 * +coders+ must be an Array of PG::Coder objects or +nil+ values.
 * The length of the Array corresponds to
 * the number of columns or bind parameters this type map is usable for.
 *
 * A +nil+ value will forward the given field to the #default_type_map .
 */
static VALUE
pg_tmbc_init(VALUE self, VALUE conv_ary)
{
	long i;
	t_tmbc *this;
	int conv_ary_len;

	rb_check_frozen(self);
	Check_Type(conv_ary, T_ARRAY);
	conv_ary_len = RARRAY_LENINT(conv_ary);
	this = xmalloc(sizeof(t_tmbc) + sizeof(struct pg_tmbc_converter) * conv_ary_len);
	/* Set nfields to 0 at first, so that GC mark function doesn't access uninitialized memory. */
	this->nfields = 0;
	this->typemap.funcs = pg_tmbc_funcs;
	RB_OBJ_WRITE(self, &this->typemap.default_typemap, pg_typemap_all_strings);
	RTYPEDDATA_DATA(self) = this;

	for(i=0; i<conv_ary_len; i++)
	{
		VALUE obj = rb_ary_entry(conv_ary, i);

		if( obj == Qnil ){
			/* no type cast */
			this->convs[i].cconv = NULL;
		} else {
			t_pg_coder *p_coder;
			/* Check argument type and store the coder pointer */
			TypedData_Get_Struct(obj, t_pg_coder, &pg_coder_type, p_coder);
			RB_OBJ_WRITTEN(self, Qnil, p_coder->coder_obj);
			this->convs[i].cconv = p_coder;
		}
	}

	this->nfields = conv_ary_len;

	return self;
}

/*
 * call-seq:
 *    typemap.coders -> Array
 *
 * Array of PG::Coder objects. The length of the Array corresponds to
 * the number of columns or bind parameters this type map is usable for.
 */
static VALUE
pg_tmbc_coders(VALUE self)
{
	int i;
	t_tmbc *this = RTYPEDDATA_DATA( self );
	VALUE ary_coders = rb_ary_new();

	for( i=0; i<this->nfields; i++){
		t_pg_coder *conv = this->convs[i].cconv;
		if( conv ) {
			rb_ary_push( ary_coders, conv->coder_obj );
		} else {
			rb_ary_push( ary_coders, Qnil );
		}
	}

	return rb_obj_freeze(ary_coders);
}

void
init_pg_type_map_by_column(void)
{
	s_id_decode = rb_intern("decode");
	s_id_encode = rb_intern("encode");

	/*
	 * Document-class: PG::TypeMapByColumn < PG::TypeMap
	 *
	 * This type map casts values by a coder assigned per field/column.
	 *
	 * Each PG::TypeMapByColumn has a fixed list of either encoders or decoders,
	 * that is defined at TypeMapByColumn.new . A type map with encoders is usable for type casting
	 * query bind parameters and COPY data for PG::Connection#put_copy_data .
	 * A type map with decoders is usable for type casting of result values and
	 * COPY data from PG::Connection#get_copy_data .
	 *
	 * PG::TypeMapByColumn objects are in particular useful in conjunction with prepared statements,
	 * since they can be cached alongside with the statement handle.
	 *
	 * This type map strategy is also used internally by PG::TypeMapByOid, when the
	 * number of rows of a result set exceeds a given limit.
	 */
	rb_cTypeMapByColumn = rb_define_class_under( rb_mPG, "TypeMapByColumn", rb_cTypeMap );
	rb_define_alloc_func( rb_cTypeMapByColumn, pg_tmbc_s_allocate );
	rb_define_method( rb_cTypeMapByColumn, "initialize", pg_tmbc_init, 1 );
	rb_define_method( rb_cTypeMapByColumn, "coders", pg_tmbc_coders, 0 );
	/* rb_mDefaultTypeMappable = rb_define_module_under( rb_cTypeMap, "DefaultTypeMappable"); */
	rb_include_module( rb_cTypeMapByColumn, rb_mDefaultTypeMappable );
}
