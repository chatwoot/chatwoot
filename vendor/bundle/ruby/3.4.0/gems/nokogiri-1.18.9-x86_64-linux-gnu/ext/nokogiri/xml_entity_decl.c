#include <nokogiri.h>

VALUE cNokogiriXmlEntityDecl;

/*
 * call-seq:
 *  original_content
 *
 * Get the original_content before ref substitution
 */
static VALUE
original_content(VALUE self)
{
  xmlEntityPtr node;
  Noko_Node_Get_Struct(self, xmlEntity, node);

  if (!node->orig) { return Qnil; }

  return NOKOGIRI_STR_NEW2(node->orig);
}

/*
 * call-seq:
 *  content
 *
 * Get the content
 */
static VALUE
get_content(VALUE self)
{
  xmlEntityPtr node;
  Noko_Node_Get_Struct(self, xmlEntity, node);

  if (!node->content) { return Qnil; }

  return NOKOGIRI_STR_NEW(node->content, node->length);
}

/*
 * call-seq:
 *  entity_type
 *
 * Get the entity type
 */
static VALUE
entity_type(VALUE self)
{
  xmlEntityPtr node;
  Noko_Node_Get_Struct(self, xmlEntity, node);

  return INT2NUM((int)node->etype);
}

/*
 * call-seq:
 *  external_id
 *
 * Get the external identifier for PUBLIC
 */
static VALUE
external_id(VALUE self)
{
  xmlEntityPtr node;
  Noko_Node_Get_Struct(self, xmlEntity, node);

  if (!node->ExternalID) { return Qnil; }

  return NOKOGIRI_STR_NEW2(node->ExternalID);
}

/*
 * call-seq:
 *  system_id
 *
 * Get the URI for a SYSTEM or PUBLIC Entity
 */
static VALUE
system_id(VALUE self)
{
  xmlEntityPtr node;
  Noko_Node_Get_Struct(self, xmlEntity, node);

  if (!node->SystemID) { return Qnil; }

  return NOKOGIRI_STR_NEW2(node->SystemID);
}

void
noko_init_xml_entity_decl(void)
{
  assert(cNokogiriXmlNode);
  cNokogiriXmlEntityDecl = rb_define_class_under(mNokogiriXml, "EntityDecl", cNokogiriXmlNode);

  rb_define_method(cNokogiriXmlEntityDecl, "original_content", original_content, 0);
  rb_define_method(cNokogiriXmlEntityDecl, "content", get_content, 0);
  rb_define_method(cNokogiriXmlEntityDecl, "entity_type", entity_type, 0);
  rb_define_method(cNokogiriXmlEntityDecl, "external_id", external_id, 0);
  rb_define_method(cNokogiriXmlEntityDecl, "system_id", system_id, 0);

  rb_const_set(cNokogiriXmlEntityDecl, rb_intern("INTERNAL_GENERAL"),
               INT2NUM(XML_INTERNAL_GENERAL_ENTITY));
  rb_const_set(cNokogiriXmlEntityDecl, rb_intern("EXTERNAL_GENERAL_PARSED"),
               INT2NUM(XML_EXTERNAL_GENERAL_PARSED_ENTITY));
  rb_const_set(cNokogiriXmlEntityDecl, rb_intern("EXTERNAL_GENERAL_UNPARSED"),
               INT2NUM(XML_EXTERNAL_GENERAL_UNPARSED_ENTITY));
  rb_const_set(cNokogiriXmlEntityDecl, rb_intern("INTERNAL_PARAMETER"),
               INT2NUM(XML_INTERNAL_PARAMETER_ENTITY));
  rb_const_set(cNokogiriXmlEntityDecl, rb_intern("EXTERNAL_PARAMETER"),
               INT2NUM(XML_EXTERNAL_PARAMETER_ENTITY));
  rb_const_set(cNokogiriXmlEntityDecl, rb_intern("INTERNAL_PREDEFINED"),
               INT2NUM(XML_INTERNAL_PREDEFINED_ENTITY));
}
