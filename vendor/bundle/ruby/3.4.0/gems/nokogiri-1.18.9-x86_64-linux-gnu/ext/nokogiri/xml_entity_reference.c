#include <nokogiri.h>

VALUE cNokogiriXmlEntityReference;

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new EntityReference element on the +document+ with +name+
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  xmlNodePtr node;
  VALUE document;
  VALUE name;
  VALUE rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &document, &name, &rest);

  xml_doc = noko_xml_document_unwrap(document);

  node = xmlNewReference(
           xml_doc,
           (const xmlChar *)StringValueCStr(name)
         );

  noko_xml_document_pin_node(node);

  rb_node = noko_xml_node_wrap(klass, node);
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

void
noko_init_xml_entity_reference(void)
{
  assert(cNokogiriXmlNode);
  /*
   * EntityReference represents an EntityReference node in an xml document.
   */
  cNokogiriXmlEntityReference = rb_define_class_under(mNokogiriXml, "EntityReference", cNokogiriXmlNode);

  rb_define_singleton_method(cNokogiriXmlEntityReference, "new", new, -1);
}
