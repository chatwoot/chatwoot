#include <nokogiri.h>

VALUE cNokogiriXmlText ;

/*
 * call-seq:
 *  new(content, document)
 *
 * Create a new Text element on the +document+ with +content+
 */
static VALUE
rb_xml_text_s_new(int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr c_document;
  xmlNodePtr c_node;
  VALUE rb_string;
  VALUE rb_document;
  VALUE rb_rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &rb_string, &rb_document, &rb_rest);

  Check_Type(rb_string, T_STRING);
  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlNode)) {
    rb_raise(rb_eTypeError,
             "expected second parameter to be a Nokogiri::XML::Document, received %"PRIsVALUE,
             rb_obj_class(rb_document));
  }

  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlDocument)) {
    xmlNodePtr deprecated_node_type_arg;
    NOKO_WARN_DEPRECATION("Passing a Node as the second parameter to Text.new is deprecated. Please pass a Document instead. This will become an error in Nokogiri v1.17.0."); // TODO: deprecated in v1.15.3, remove in v1.17.0
    Noko_Node_Get_Struct(rb_document, xmlNode, deprecated_node_type_arg);
    c_document = deprecated_node_type_arg->doc;
  } else {
    c_document = noko_xml_document_unwrap(rb_document);
  }

  c_node = xmlNewDocText(c_document, (xmlChar *)StringValueCStr(rb_string));
  noko_xml_document_pin_node(c_node);
  rb_node = noko_xml_node_wrap(klass, c_node) ;
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

void
noko_init_xml_text(void)
{
  assert(cNokogiriXmlCharacterData);
  /*
   * Wraps Text nodes.
   */
  cNokogiriXmlText = rb_define_class_under(mNokogiriXml, "Text", cNokogiriXmlCharacterData);

  rb_define_singleton_method(cNokogiriXmlText, "new", rb_xml_text_s_new, -1);
}
