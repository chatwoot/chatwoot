/*
 * pg_column_map.c - PG::ColumnMap class extension
 * $Id$
 *
 */

#include "pg.h"

void
pg_typemap_mark( void *_this )
{
	t_typemap *this = (t_typemap *)_this;
	rb_gc_mark_movable(this->default_typemap);
}

size_t
pg_typemap_memsize( const void *_this )
{
	t_typemap *this = (t_typemap *)_this;
	return sizeof(*this);
}

void
pg_typemap_compact( void *_this )
{
	t_typemap *this = (t_typemap *)_this;
	pg_gc_location(this->default_typemap);
}

const rb_data_type_t pg_typemap_type = {
	"PG::TypeMap",
	{
		pg_typemap_mark,
		RUBY_TYPED_DEFAULT_FREE,
		pg_typemap_memsize,
		pg_compact_callback(pg_typemap_compact),
	},
	0,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED | PG_RUBY_TYPED_FROZEN_SHAREABLE,
};

VALUE rb_cTypeMap;
VALUE rb_mDefaultTypeMappable;
static ID s_id_fit_to_query;
static ID s_id_fit_to_result;

NORETURN( VALUE
pg_typemap_fit_to_result( VALUE self, VALUE result ));
NORETURN( VALUE
pg_typemap_fit_to_query( VALUE self, VALUE params ));
NORETURN( int
pg_typemap_fit_to_copy_get( VALUE self ));
NORETURN( VALUE
pg_typemap_result_value( t_typemap *p_typemap, VALUE result, int tuple, int field ));
NORETURN( t_pg_coder *
pg_typemap_typecast_query_param( t_typemap *p_typemap, VALUE param_value, int field ));
NORETURN( VALUE
pg_typemap_typecast_copy_get( t_typemap *p_typemap, VALUE field_str, int fieldno, int format, int enc_idx ));

VALUE
pg_typemap_fit_to_result( VALUE self, VALUE result )
{
	rb_raise( rb_eNotImpError, "type map %s is not suitable to map result values", rb_obj_classname(self) );
}

VALUE
pg_typemap_fit_to_query( VALUE self, VALUE params )
{
	rb_raise( rb_eNotImpError, "type map %s is not suitable to map query params", rb_obj_classname(self) );
}

int
pg_typemap_fit_to_copy_get( VALUE self )
{
	rb_raise( rb_eNotImpError, "type map %s is not suitable to map get_copy_data results", rb_obj_classname(self) );
}

VALUE
pg_typemap_result_value( t_typemap *p_typemap, VALUE result, int tuple, int field )
{
	rb_raise( rb_eNotImpError, "type map is not suitable to map result values" );
}

t_pg_coder *
pg_typemap_typecast_query_param( t_typemap *p_typemap, VALUE param_value, int field )
{
	rb_raise( rb_eNotImpError, "type map is not suitable to map query params" );
}

VALUE
pg_typemap_typecast_copy_get( t_typemap *p_typemap, VALUE field_str, int fieldno, int format, int enc_idx )
{
	rb_raise( rb_eNotImpError, "type map is not suitable to map get_copy_data results" );
}

const struct pg_typemap_funcs pg_typemap_funcs = {
	pg_typemap_fit_to_result,
	pg_typemap_fit_to_query,
	pg_typemap_fit_to_copy_get,
	pg_typemap_result_value,
	pg_typemap_typecast_query_param,
	pg_typemap_typecast_copy_get
};

static VALUE
pg_typemap_s_allocate( VALUE klass )
{
	VALUE self;
	t_typemap *this;

	self = TypedData_Make_Struct( klass, t_typemap, &pg_typemap_type, this );
	this->funcs = pg_typemap_funcs;

	return self;
}

/*
 * call-seq:
 *    res.default_type_map = typemap
 *
 * Set the default TypeMap that is used for values that could not be
 * casted by this type map.
 *
 * +typemap+ must be a kind of PG::TypeMap
 *
 */
static VALUE
pg_typemap_default_type_map_set(VALUE self, VALUE typemap)
{
	t_typemap *this = RTYPEDDATA_DATA( self );
	t_typemap *tm;
	UNUSED(tm);

	rb_check_frozen(self);
	/* Check type of method param */
	TypedData_Get_Struct(typemap, t_typemap, &pg_typemap_type, tm);
	RB_OBJ_WRITE(self, &this->default_typemap, typemap);

	return typemap;
}

/*
 * call-seq:
 *    res.default_type_map -> TypeMap
 *
 * Returns the default TypeMap that is currently set for values that could not be
 * casted by this type map.
 *
 * Returns a kind of PG::TypeMap.
 *
 */
static VALUE
pg_typemap_default_type_map_get(VALUE self)
{
	t_typemap *this = RTYPEDDATA_DATA( self );

	return this->default_typemap;
}

/*
 * call-seq:
 *    res.with_default_type_map( typemap )
 *
 * Set the default TypeMap that is used for values that could not be
 * casted by this type map.
 *
 * +typemap+ must be a kind of PG::TypeMap
 *
 * Returns self.
 */
static VALUE
pg_typemap_with_default_type_map(VALUE self, VALUE typemap)
{
	pg_typemap_default_type_map_set( self, typemap );
	return self;
}

void
init_pg_type_map(void)
{
	s_id_fit_to_query = rb_intern("fit_to_query");
	s_id_fit_to_result = rb_intern("fit_to_result");

	/*
	 * Document-class: PG::TypeMap < Object
	 *
	 * This is the base class for type maps.
	 * See derived classes for implementations of different type cast strategies
	 * ( PG::TypeMapByColumn, PG::TypeMapByOid ).
	 *
	 */
	rb_cTypeMap = rb_define_class_under( rb_mPG, "TypeMap", rb_cObject );
	rb_define_alloc_func( rb_cTypeMap, pg_typemap_s_allocate );

	rb_mDefaultTypeMappable = rb_define_module_under( rb_cTypeMap, "DefaultTypeMappable");
	rb_define_method( rb_mDefaultTypeMappable, "default_type_map=", pg_typemap_default_type_map_set, 1 );
	rb_define_method( rb_mDefaultTypeMappable, "default_type_map", pg_typemap_default_type_map_get, 0 );
	rb_define_method( rb_mDefaultTypeMappable, "with_default_type_map", pg_typemap_with_default_type_map, 1 );
}
