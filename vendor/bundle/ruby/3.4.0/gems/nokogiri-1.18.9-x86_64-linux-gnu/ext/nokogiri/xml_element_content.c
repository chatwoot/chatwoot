#include <nokogiri.h>

VALUE cNokogiriXmlElementContent;

static const rb_data_type_t xml_element_content_type = {
  .wrap_struct_name = "xmlElementContent",
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * call-seq:
 *   name → String
 *
 * [Returns] The content element's +name+
 */
static VALUE
get_name(VALUE self)
{
  xmlElementContentPtr elem;
  TypedData_Get_Struct(self, xmlElementContent, &xml_element_content_type, elem);

  if (!elem->name) { return Qnil; }
  return NOKOGIRI_STR_NEW2(elem->name);
}

/*
 * call-seq:
 *   type → Integer
 *
 * [Returns] The content element's +type+. Possible values are +PCDATA+, +ELEMENT+, +SEQ+, or +OR+.
 */
static VALUE
get_type(VALUE self)
{
  xmlElementContentPtr elem;
  TypedData_Get_Struct(self, xmlElementContent, &xml_element_content_type, elem);

  return INT2NUM(elem->type);
}

/*
 * Get the first child.
 */
static VALUE
get_c1(VALUE self)
{
  xmlElementContentPtr elem;
  TypedData_Get_Struct(self, xmlElementContent, &xml_element_content_type, elem);

  if (!elem->c1) { return Qnil; }
  return noko_xml_element_content_wrap(rb_iv_get(self, "@document"), elem->c1);
}

/*
 * Get the second child.
 */
static VALUE
get_c2(VALUE self)
{
  xmlElementContentPtr elem;
  TypedData_Get_Struct(self, xmlElementContent, &xml_element_content_type, elem);

  if (!elem->c2) { return Qnil; }
  return noko_xml_element_content_wrap(rb_iv_get(self, "@document"), elem->c2);
}

/*
 * call-seq:
 *   occur → Integer
 *
 * [Returns] The content element's +occur+ flag. Possible values are +ONCE+, +OPT+, +MULT+ or +PLUS+.
 */
static VALUE
get_occur(VALUE self)
{
  xmlElementContentPtr elem;
  TypedData_Get_Struct(self, xmlElementContent, &xml_element_content_type, elem);

  return INT2NUM(elem->ocur);
}

/*
 * call-seq:
 *   prefix → String
 *
 * [Returns] The content element's namespace +prefix+.
 */
static VALUE
get_prefix(VALUE self)
{
  xmlElementContentPtr elem;
  TypedData_Get_Struct(self, xmlElementContent, &xml_element_content_type, elem);

  if (!elem->prefix) { return Qnil; }

  return NOKOGIRI_STR_NEW2(elem->prefix);
}

/*
 *  create a Nokogiri::XML::ElementContent object around an +element+.
 */
VALUE
noko_xml_element_content_wrap(VALUE rb_document, xmlElementContentPtr c_element_content)
{
  VALUE elem = TypedData_Wrap_Struct(
                 cNokogiriXmlElementContent,
                 &xml_element_content_type,
                 c_element_content
               );

  /* keep a handle on the document for GC marking */
  rb_iv_set(elem, "@document", rb_document);

  return elem;
}

void
noko_init_xml_element_content(void)
{
  cNokogiriXmlElementContent = rb_define_class_under(mNokogiriXml, "ElementContent", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlElementContent);

  rb_define_method(cNokogiriXmlElementContent, "name", get_name, 0);
  rb_define_method(cNokogiriXmlElementContent, "type", get_type, 0);
  rb_define_method(cNokogiriXmlElementContent, "occur", get_occur, 0);
  rb_define_method(cNokogiriXmlElementContent, "prefix", get_prefix, 0);

  rb_define_private_method(cNokogiriXmlElementContent, "c1", get_c1, 0);
  rb_define_private_method(cNokogiriXmlElementContent, "c2", get_c2, 0);
}
