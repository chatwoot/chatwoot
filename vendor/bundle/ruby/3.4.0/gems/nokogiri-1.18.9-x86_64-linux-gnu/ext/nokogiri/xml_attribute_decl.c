#include <nokogiri.h>

VALUE cNokogiriXmlAttributeDecl;

/*
 * call-seq:
 *  attribute_type
 *
 * The attribute_type for this AttributeDecl
 */
static VALUE
attribute_type(VALUE self)
{
  xmlAttributePtr node;
  Noko_Node_Get_Struct(self, xmlAttribute, node);
  return INT2NUM(node->atype);
}

/*
 * call-seq:
 *  default
 *
 * The default value
 */
static VALUE
default_value(VALUE self)
{
  xmlAttributePtr node;
  Noko_Node_Get_Struct(self, xmlAttribute, node);

  if (node->defaultValue) { return NOKOGIRI_STR_NEW2(node->defaultValue); }
  return Qnil;
}

/*
 * call-seq:
 *  enumeration
 *
 * An enumeration of possible values
 */
static VALUE
enumeration(VALUE self)
{
  xmlAttributePtr node;
  xmlEnumerationPtr enm;
  VALUE list;

  Noko_Node_Get_Struct(self, xmlAttribute, node);

  list = rb_ary_new();
  enm = node->tree;

  while (enm) {
    rb_ary_push(list, NOKOGIRI_STR_NEW2(enm->name));
    enm = enm->next;
  }

  return list;
}

void
noko_init_xml_attribute_decl(void)
{
  assert(cNokogiriXmlNode);
  cNokogiriXmlAttributeDecl = rb_define_class_under(mNokogiriXml, "AttributeDecl", cNokogiriXmlNode);

  rb_define_method(cNokogiriXmlAttributeDecl, "attribute_type", attribute_type, 0);
  rb_define_method(cNokogiriXmlAttributeDecl, "default", default_value, 0);
  rb_define_method(cNokogiriXmlAttributeDecl, "enumeration", enumeration, 0);
}
