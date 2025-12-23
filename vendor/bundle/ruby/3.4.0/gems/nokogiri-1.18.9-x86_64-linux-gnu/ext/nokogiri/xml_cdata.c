#include <nokogiri.h>

VALUE cNokogiriXmlCData;

/*
 * call-seq:
 *  new(document, content)
 *
 * Create a new CDATA element on the +document+ with +content+
 *
 * If +content+ cannot be implicitly converted to a string, this method will
 * raise a TypeError exception.
 */
static VALUE
rb_xml_cdata_s_new(int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr c_document;
  xmlNodePtr c_node;
  VALUE rb_document;
  VALUE rb_content;
  VALUE rb_rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &rb_document, &rb_content, &rb_rest);

  Check_Type(rb_content, T_STRING);
  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlNode)) {
    rb_raise(rb_eTypeError,
             "expected first parameter to be a Nokogiri::XML::Document, received %"PRIsVALUE,
             rb_obj_class(rb_document));
  }

  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlDocument)) {
    xmlNodePtr deprecated_node_type_arg;
    NOKO_WARN_DEPRECATION("Passing a Node as the first parameter to CDATA.new is deprecated. Please pass a Document instead. This will become an error in Nokogiri v1.17.0."); // TODO: deprecated in v1.15.3, remove in v1.17.0
    Noko_Node_Get_Struct(rb_document, xmlNode, deprecated_node_type_arg);
    c_document = deprecated_node_type_arg->doc;
  } else {
    c_document = noko_xml_document_unwrap(rb_document);
  }

  c_node = xmlNewCDataBlock(c_document, (xmlChar *)StringValueCStr(rb_content), RSTRING_LENINT(rb_content));
  noko_xml_document_pin_node(c_node);
  rb_node = noko_xml_node_wrap(klass, c_node);
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

void
noko_init_xml_cdata(void)
{
  assert(cNokogiriXmlText);
  /*
   * CData represents a CData node in an xml document.
   */
  cNokogiriXmlCData = rb_define_class_under(mNokogiriXml, "CDATA", cNokogiriXmlText);

  rb_define_singleton_method(cNokogiriXmlCData, "new", rb_xml_cdata_s_new, -1);
}
