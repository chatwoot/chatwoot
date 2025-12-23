#include <nokogiri.h>

VALUE cNokogiriEncodingHandler;

static void
xml_encoding_handler_dealloc(void *data)
{
  /* make sure iconv handlers are cleaned up and freed */
  xmlCharEncodingHandlerPtr c_handler = data;
  xmlCharEncCloseFunc(c_handler);
}

static const rb_data_type_t xml_char_encoding_handler_type = {
  .wrap_struct_name = "xmlCharEncodingHandler",
  .function = {
    .dfree = xml_encoding_handler_dealloc,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};


/*
 * call-seq: Nokogiri::EncodingHandler.[](name)
 *
 * Get the encoding handler for +name+
 */
static VALUE
rb_xml_encoding_handler_s_get(VALUE klass, VALUE key)
{
  xmlCharEncodingHandlerPtr handler;

  handler = xmlFindCharEncodingHandler(StringValueCStr(key));
  if (handler) {
    return TypedData_Wrap_Struct(klass, &xml_char_encoding_handler_type, handler);
  }

  return Qnil;
}


/*
 * call-seq: Nokogiri::EncodingHandler.delete(name)
 *
 * Delete the encoding alias named +name+
 */
static VALUE
rb_xml_encoding_handler_s_delete(VALUE klass, VALUE name)
{
  if (xmlDelEncodingAlias(StringValueCStr(name))) { return Qnil; }

  return Qtrue;
}


/*
 * call-seq: Nokogiri::EncodingHandler.alias(real_name, alias_name)
 *
 * Alias encoding handler with name +real_name+ to name +alias_name+
 */
static VALUE
rb_xml_encoding_handler_s_alias(VALUE klass, VALUE from, VALUE to)
{
  xmlAddEncodingAlias(StringValueCStr(from), StringValueCStr(to));

  return to;
}


/*
 * call-seq: Nokogiri::EncodingHandler.clear_aliases!
 *
 * Remove all encoding aliases.
 */
static VALUE
rb_xml_encoding_handler_s_clear_aliases(VALUE klass)
{
  xmlCleanupEncodingAliases();

  return klass;
}


/*
 * call-seq: name
 *
 * Get the name of this EncodingHandler
 */
static VALUE
rb_xml_encoding_handler_name(VALUE self)
{
  xmlCharEncodingHandlerPtr handler;

  TypedData_Get_Struct(self, xmlCharEncodingHandler, &xml_char_encoding_handler_type, handler);

  return NOKOGIRI_STR_NEW2(handler->name);
}


void
noko_init_xml_encoding_handler(void)
{
  cNokogiriEncodingHandler = rb_define_class_under(mNokogiri, "EncodingHandler", rb_cObject);

  rb_undef_alloc_func(cNokogiriEncodingHandler);

  rb_define_singleton_method(cNokogiriEncodingHandler, "[]", rb_xml_encoding_handler_s_get, 1);
  rb_define_singleton_method(cNokogiriEncodingHandler, "delete", rb_xml_encoding_handler_s_delete, 1);
  rb_define_singleton_method(cNokogiriEncodingHandler, "alias", rb_xml_encoding_handler_s_alias, 2);
  rb_define_singleton_method(cNokogiriEncodingHandler, "clear_aliases!", rb_xml_encoding_handler_s_clear_aliases, 0);

  rb_define_method(cNokogiriEncodingHandler, "name", rb_xml_encoding_handler_name, 0);
}
