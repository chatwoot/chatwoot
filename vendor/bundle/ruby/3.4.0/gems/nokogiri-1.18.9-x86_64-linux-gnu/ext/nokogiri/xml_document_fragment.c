#include <nokogiri.h>

VALUE cNokogiriXmlDocumentFragment;

/* :nodoc: */
static VALUE
noko_xml_document_fragment_s_native_new(VALUE klass, VALUE rb_doc)
{
  xmlDocPtr c_doc;
  xmlNodePtr c_node;
  VALUE rb_node;

  c_doc = noko_xml_document_unwrap(rb_doc);
  c_node = xmlNewDocFragment(c_doc->doc);
  noko_xml_document_pin_node(c_node);
  rb_node = noko_xml_node_wrap(klass, c_node);

  return rb_node;
}

void
noko_init_xml_document_fragment(void)
{
  assert(cNokogiriXmlNode);

  cNokogiriXmlDocumentFragment = rb_define_class_under(mNokogiriXml, "DocumentFragment", cNokogiriXmlNode);

  rb_define_singleton_method(cNokogiriXmlDocumentFragment, "native_new", noko_xml_document_fragment_s_native_new, 1);
}
