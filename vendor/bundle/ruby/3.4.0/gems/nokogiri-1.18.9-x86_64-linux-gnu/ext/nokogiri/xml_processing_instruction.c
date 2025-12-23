#include <nokogiri.h>

VALUE cNokogiriXmlProcessingInstruction;

/*
 * call-seq:
 *  new(document, name, content)
 *
 * Create a new ProcessingInstruction element on the +document+ with +name+
 * and +content+
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  xmlNodePtr node;
  VALUE document;
  VALUE name;
  VALUE content;
  VALUE rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "3*", &document, &name, &content, &rest);

  xml_doc = noko_xml_document_unwrap(document);

  node = xmlNewDocPI(
           xml_doc,
           (const xmlChar *)StringValueCStr(name),
           (const xmlChar *)StringValueCStr(content)
         );

  noko_xml_document_pin_node(node);

  rb_node = noko_xml_node_wrap(klass, node);
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

void
noko_init_xml_processing_instruction(void)
{
  assert(cNokogiriXmlNode);
  /*
   * ProcessingInstruction represents a ProcessingInstruction node in an xml
   * document.
   */
  cNokogiriXmlProcessingInstruction = rb_define_class_under(mNokogiriXml, "ProcessingInstruction", cNokogiriXmlNode);

  rb_define_singleton_method(cNokogiriXmlProcessingInstruction, "new", new, -1);
}
