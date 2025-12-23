#include "pg.h"

/********************************************************************
 *
 * Document-class: PG::Tuple
 *
 * The class to represent one query result tuple (row).
 * An instance of this class can be created by PG::Result#tuple .
 *
 * All field values of the tuple are retrieved on demand from the underlying PGresult object and converted to a Ruby object.
 * Subsequent access to the same field returns the same object, since they are cached when materialized.
 * Each PG::Tuple holds a reference to the related PG::Result object, but gets detached, when all fields are materialized.
 *
 * Example:
 *    require 'pg'
 *    conn = PG.connect(:dbname => 'test')
 *    res  = conn.exec('VALUES(1,2), (3,4)')
 *    t0 = res.tuple(0)  # => #<PG::Tuple column1: "1", column2: "2">
 *    t1 = res.tuple(1)  # => #<PG::Tuple column1: "3", column2: "4">
 *    t1[0]  # => "3"
 *    t1["column2"]  # => "4"
 */

static VALUE rb_cPG_Tuple;

typedef struct {
	/* PG::Result object this tuple was retrieved from.
	 * Qnil when all fields are materialized.
	 */
	VALUE result;

	/* Store the typemap of the result.
	 * It's not enough to reference the PG::TypeMap object through the result,
	 * since it could be exchanged after the tuple has been created.
	 */
	VALUE typemap;

	/* Hash with maps field names to index into values[]
	 * Shared between all instances retrieved from one PG::Result.
	 */
	VALUE field_map;

	/* Row number within the result set. */
	int row_num;

	/* Number of fields in the result set. */
	int num_fields;

	/* Materialized values.
	 * And in case of dup column names, a field_names Array subsequently.
	 */
	VALUE values[0];
} t_pg_tuple;

static inline VALUE *
pg_tuple_get_field_names_ptr( t_pg_tuple *this )
{
	if( this->num_fields != (int)RHASH_SIZE(this->field_map) ){
		return &this->values[this->num_fields];
	} else {
		static VALUE f = Qfalse;
		return &f;
	}
}

static inline VALUE
pg_tuple_get_field_names( t_pg_tuple *this )
{
	return *pg_tuple_get_field_names_ptr(this);
}

static void
pg_tuple_gc_mark( void *_this )
{
	t_pg_tuple *this = (t_pg_tuple *)_this;
	int i;

	if( !this ) return;
	rb_gc_mark_movable( this->result );
	rb_gc_mark_movable( this->typemap );
	rb_gc_mark_movable( this->field_map );

	for( i = 0; i < this->num_fields; i++ ){
		rb_gc_mark_movable( this->values[i] );
	}
	rb_gc_mark_movable( pg_tuple_get_field_names(this) );
}

static void
pg_tuple_gc_compact( void *_this )
{
	t_pg_tuple *this = (t_pg_tuple *)_this;
	int i;

	if( !this ) return;
	pg_gc_location( this->result );
	pg_gc_location( this->typemap );
	pg_gc_location( this->field_map );

	for( i = 0; i < this->num_fields; i++ ){
		pg_gc_location( this->values[i] );
	}
	pg_gc_location( *pg_tuple_get_field_names_ptr(this) );
}

static void
pg_tuple_gc_free( void *_this )
{
	t_pg_tuple *this = (t_pg_tuple *)_this;
	if( !this ) return;
	xfree(this);
}

static size_t
pg_tuple_memsize( const void *_this )
{
	const t_pg_tuple *this = (const t_pg_tuple *)_this;
	if( this==NULL ) return 0;
	return sizeof(*this) +  sizeof(*this->values) * this->num_fields;
}

static const rb_data_type_t pg_tuple_type = {
	"PG::Tuple",
	{
		pg_tuple_gc_mark,
		pg_tuple_gc_free,
		pg_tuple_memsize,
		pg_compact_callback(pg_tuple_gc_compact),
	},
	0, 0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED | PG_RUBY_TYPED_FROZEN_SHAREABLE,
};

/*
 * Document-method: allocate
 *
 * call-seq:
 *   PG::VeryTuple.allocate -> obj
 */
static VALUE
pg_tuple_s_allocate( VALUE klass )
{
	return TypedData_Wrap_Struct( klass, &pg_tuple_type, NULL );
}

VALUE
pg_tuple_new(VALUE result, int row_num)
{
	t_pg_tuple *this;
	VALUE self = pg_tuple_s_allocate( rb_cPG_Tuple );
	t_pg_result *p_result = pgresult_get_this(result);
	int num_fields = p_result->nfields;
	int i;
	VALUE field_map = p_result->field_map;
	int dup_names = num_fields != (int)RHASH_SIZE(field_map);

	this = (t_pg_tuple *)xmalloc(
		sizeof(*this) +
		sizeof(*this->values) * num_fields +
		sizeof(*this->values) * (dup_names ? 1 : 0));

	RB_OBJ_WRITE(self, &this->result, result);
	RB_OBJ_WRITE(self, &this->typemap, p_result->typemap);
	RB_OBJ_WRITE(self, &this->field_map, field_map);
	this->row_num = row_num;
	this->num_fields = num_fields;

	for( i = 0; i < num_fields; i++ ){
		this->values[i] = Qundef;
	}

	if( dup_names ){
		/* Some of the column names are duplicated -> we need the keys as Array in addition.
		 * Store it behind the values to save the space in the common case of no dups.
		 */
		VALUE keys_array = rb_obj_freeze(rb_ary_new4(num_fields, p_result->fnames));
		RB_OBJ_WRITE(self, &this->values[num_fields], keys_array);
	}

	RTYPEDDATA_DATA(self) = this;

	return self;
}

static inline t_pg_tuple *
pg_tuple_get_this( VALUE self )
{
	t_pg_tuple *this;
	TypedData_Get_Struct(self, t_pg_tuple, &pg_tuple_type, this);
	if (this == NULL)
		rb_raise(rb_eTypeError, "tuple is empty");

	return this;
}

static VALUE
pg_tuple_materialize_field(VALUE self, int col)
{
	t_pg_tuple *this = RTYPEDDATA_DATA( self );
	VALUE value = this->values[col];

	if( value == Qundef ){
		t_typemap *p_typemap = RTYPEDDATA_DATA( this->typemap );

		pgresult_get(this->result); /* make sure we have a valid PGresult object */
		value = p_typemap->funcs.typecast_result_value(p_typemap, this->result, this->row_num, col);
		RB_OBJ_WRITE(self, &this->values[col], value);
	}

	return value;
}

static void
pg_tuple_detach(VALUE self)
{
	t_pg_tuple *this = RTYPEDDATA_DATA( self );
	RB_OBJ_WRITE(self, &this->result, Qnil);
	RB_OBJ_WRITE(self, &this->typemap, Qnil);
	this->row_num = -1;
}

static void
pg_tuple_materialize(VALUE self)
{
	t_pg_tuple *this = RTYPEDDATA_DATA( self );
	int field_num;
	for(field_num = 0; field_num < this->num_fields; field_num++) {
		pg_tuple_materialize_field(self, field_num);
	}

	pg_tuple_detach(self);
}

/*
 * call-seq:
 *    tup.fetch(key) → value
 *    tup.fetch(key, default) → value
 *    tup.fetch(key) { |key| block } → value
 *
 * Returns a field value by either column index or column name.
 *
 * An integer +key+ is interpreted as column index.
 * Negative values of index count from the end of the array.
 *
 * Depending on Result#field_name_type= a string or symbol +key+ is interpreted as column name.
 *
 * If the key can't be found, there are several options:
 * With no other arguments, it will raise a IndexError exception;
 * if default is given, then that will be returned;
 * if the optional code block is specified, then that will be run and its result returned.
 */
static VALUE
pg_tuple_fetch(int argc, VALUE *argv, VALUE self)
{
	VALUE key;
	long block_given;
	VALUE index;
	int field_num;
	t_pg_tuple *this = pg_tuple_get_this(self);

	rb_check_arity(argc, 1, 2);
	key = argv[0];

	block_given = rb_block_given_p();
	if (block_given && argc == 2) {
		rb_warn("block supersedes default value argument");
	}

	switch(rb_type(key)){
		case T_FIXNUM:
		case T_BIGNUM:
			field_num = NUM2INT(key);
			if ( field_num < 0 )
				field_num = this->num_fields + field_num;
			if ( field_num < 0 || field_num >= this->num_fields ){
				if (block_given) return rb_yield(key);
				if (argc == 1) rb_raise( rb_eIndexError, "Index %d is out of range", field_num );
				return argv[1];
			}
			break;
		default:
			index = rb_hash_aref(this->field_map, key);

			if (index == Qnil) {
				if (block_given) return rb_yield(key);
				if (argc == 1) rb_raise( rb_eKeyError, "column not found" );
				return argv[1];
			}

			field_num = NUM2INT(index);
	}

	return pg_tuple_materialize_field(self, field_num);
}

/*
 * call-seq:
 *    tup[ key ] -> value
 *
 * Returns a field value by either column index or column name.
 *
 * An integer +key+ is interpreted as column index.
 * Negative values of index count from the end of the array.
 *
 * Depending on Result#field_name_type= a string or symbol +key+ is interpreted as column name.
 *
 * If the key can't be found, it returns +nil+ .
 */
static VALUE
pg_tuple_aref(VALUE self, VALUE key)
{
	VALUE index;
	int field_num;
	t_pg_tuple *this = pg_tuple_get_this(self);

	switch(rb_type(key)){
		case T_FIXNUM:
		case T_BIGNUM:
			field_num = NUM2INT(key);
			if ( field_num < 0 )
				field_num = this->num_fields + field_num;
			if ( field_num < 0 || field_num >= this->num_fields )
				return Qnil;
			break;
		default:
			index = rb_hash_aref(this->field_map, key);
			if( index == Qnil ) return Qnil;
			field_num = NUM2INT(index);
	}

	return pg_tuple_materialize_field(self, field_num);
}

static VALUE
pg_tuple_num_fields_for_enum(VALUE self, VALUE args, VALUE eobj)
{
	t_pg_tuple *this = pg_tuple_get_this(self);
	return INT2NUM(this->num_fields);
}

static int
pg_tuple_yield_key_value(VALUE key, VALUE index, VALUE self)
{
	VALUE value = pg_tuple_materialize_field(self, NUM2INT(index));
	rb_yield_values(2, key, value);
	return ST_CONTINUE;
}

/*
 * call-seq:
 *    tup.each{ |key, value| ... }
 *
 * Invokes block for each field name and value in the tuple.
 */
static VALUE
pg_tuple_each(VALUE self)
{
	t_pg_tuple *this = pg_tuple_get_this(self);
	VALUE field_names;

	RETURN_SIZED_ENUMERATOR(self, 0, NULL, pg_tuple_num_fields_for_enum);

	field_names = pg_tuple_get_field_names(this);

	if( field_names == Qfalse ){
		rb_hash_foreach(this->field_map, pg_tuple_yield_key_value, self);
	} else {
		int i;
		for( i = 0; i < this->num_fields; i++ ){
			VALUE value = pg_tuple_materialize_field(self, i);
			rb_yield_values(2, RARRAY_AREF(field_names, i), value);
		}
	}

	pg_tuple_detach(self);
	return self;
}

/*
 * call-seq:
 *    tup.each_value{ |value| ... }
 *
 * Invokes block for each field value in the tuple.
 */
static VALUE
pg_tuple_each_value(VALUE self)
{
	t_pg_tuple *this = pg_tuple_get_this(self);
	int field_num;

	RETURN_SIZED_ENUMERATOR(self, 0, NULL, pg_tuple_num_fields_for_enum);

	for(field_num = 0; field_num < this->num_fields; field_num++) {
		VALUE value = pg_tuple_materialize_field(self, field_num);
		rb_yield(value);
	}

	pg_tuple_detach(self);
	return self;
}


/*
 * call-seq:
 *    tup.values  -> Array
 *
 * Returns the values of this tuple as Array.
 * +res.tuple(i).values+ is equal to +res.tuple_values(i)+ .
 */
static VALUE
pg_tuple_values(VALUE self)
{
	t_pg_tuple *this = pg_tuple_get_this(self);

	pg_tuple_materialize(self);
	return rb_ary_new4(this->num_fields, &this->values[0]);
}

static VALUE
pg_tuple_field_map(VALUE self)
{
	t_pg_tuple *this = pg_tuple_get_this(self);
	return this->field_map;
}

static VALUE
pg_tuple_field_names(VALUE self)
{
	t_pg_tuple *this = pg_tuple_get_this(self);
	return pg_tuple_get_field_names(this);
}

/*
 * call-seq:
 *    tup.length → integer
 *
 * Returns number of fields of this tuple.
 */
static VALUE
pg_tuple_length(VALUE self)
{
	t_pg_tuple *this = pg_tuple_get_this(self);
	return INT2NUM(this->num_fields);
}

/*
 * call-seq:
 *    tup.index(key) → integer
 *
 * Returns the field number which matches the given column name.
 */
static VALUE
pg_tuple_index(VALUE self, VALUE key)
{
	t_pg_tuple *this = pg_tuple_get_this(self);
	return rb_hash_aref(this->field_map, key);
}


static VALUE
pg_tuple_dump(VALUE self)
{
	VALUE field_names;
	VALUE values;
	VALUE a;
	t_pg_tuple *this = pg_tuple_get_this(self);

	pg_tuple_materialize(self);

	field_names = pg_tuple_get_field_names(this);
	if( field_names == Qfalse )
		field_names = rb_funcall(this->field_map, rb_intern("keys"), 0);

	values = rb_ary_new4(this->num_fields, &this->values[0]);
	a = rb_ary_new3(2, field_names, values);

        rb_copy_generic_ivar(a, self);

	return a;
}

static VALUE
pg_tuple_load(VALUE self, VALUE a)
{
	int num_fields;
	int i;
	t_pg_tuple *this;
	VALUE values;
	VALUE field_names;
	VALUE field_map;
	int dup_names;

	rb_check_frozen(self);

	TypedData_Get_Struct(self, t_pg_tuple, &pg_tuple_type, this);
	if (this)
		rb_raise(rb_eTypeError, "tuple is not empty");

	Check_Type(a, T_ARRAY);
	if (RARRAY_LEN(a) != 2)
		rb_raise(rb_eTypeError, "expected an array of 2 elements");

	field_names = RARRAY_AREF(a, 0);
	Check_Type(field_names, T_ARRAY);
	rb_obj_freeze(field_names);
	values = RARRAY_AREF(a, 1);
	Check_Type(values, T_ARRAY);
	num_fields = RARRAY_LENINT(values);

	if (RARRAY_LENINT(field_names) != num_fields)
		rb_raise(rb_eTypeError, "different number of fields and values");

	field_map = rb_hash_new();
	for( i = 0; i < num_fields; i++ ){
		rb_hash_aset(field_map, RARRAY_AREF(field_names, i), INT2FIX(i));
	}
	rb_obj_freeze(field_map);

	dup_names = num_fields != (int)RHASH_SIZE(field_map);

	this = (t_pg_tuple *)xmalloc(
		sizeof(*this) +
		sizeof(*this->values) * num_fields +
		sizeof(*this->values) * (dup_names ? 1 : 0));

	RB_OBJ_WRITE(self, &this->result, Qnil);
	RB_OBJ_WRITE(self, &this->typemap, Qnil);
	this->row_num = -1;
	this->num_fields = num_fields;
	RB_OBJ_WRITE(self, &this->field_map, field_map);

	for( i = 0; i < num_fields; i++ ){
		VALUE v = RARRAY_AREF(values, i);
		if( v == Qundef )
			rb_raise(rb_eTypeError, "field %d is not materialized", i);
		RB_OBJ_WRITE(self, &this->values[i], v);
	}

	if( dup_names ){
		RB_OBJ_WRITE(self, &this->values[num_fields], field_names);
	}

	RTYPEDDATA_DATA(self) = this;

	rb_copy_generic_ivar(self, a);

	return self;
}

void
init_pg_tuple(void)
{
	rb_cPG_Tuple = rb_define_class_under( rb_mPG, "Tuple", rb_cObject );
	rb_define_alloc_func( rb_cPG_Tuple, pg_tuple_s_allocate );
	rb_include_module(rb_cPG_Tuple, rb_mEnumerable);

	rb_define_method(rb_cPG_Tuple, "fetch", pg_tuple_fetch, -1);
	rb_define_method(rb_cPG_Tuple, "[]", pg_tuple_aref, 1);
	rb_define_method(rb_cPG_Tuple, "each", pg_tuple_each, 0);
	rb_define_method(rb_cPG_Tuple, "each_value", pg_tuple_each_value, 0);
	rb_define_method(rb_cPG_Tuple, "values", pg_tuple_values, 0);
	rb_define_method(rb_cPG_Tuple, "length", pg_tuple_length, 0);
	rb_define_alias(rb_cPG_Tuple, "size", "length");
	rb_define_method(rb_cPG_Tuple, "index", pg_tuple_index, 1);

	rb_define_private_method(rb_cPG_Tuple, "field_map", pg_tuple_field_map, 0);
	rb_define_private_method(rb_cPG_Tuple, "field_names", pg_tuple_field_names, 0);

	/* methods for marshaling */
	rb_define_private_method(rb_cPG_Tuple, "marshal_dump", pg_tuple_dump, 0);
	rb_define_private_method(rb_cPG_Tuple, "marshal_load", pg_tuple_load, 1);
}
