#include <nokogiri.h>

VALUE cNokogiriXmlAttr;

/*
 * call-seq:
 *  value=(content)
 *
 * Set the value for this Attr to +content+. Use +nil+ to remove the value
 * (e.g., a HTML boolean attribute).
 */
static VALUE
set_value(VALUE self, VALUE content)
{
  xmlAttrPtr attr;
  xmlChar *value;
  xmlNode *cur;

  Noko_Node_Get_Struct(self, xmlAttr, attr);

  if (attr->children) {
    xmlFreeNodeList(attr->children);
  }
  attr->children = attr->last = NULL;

  if (content == Qnil) {
    return content;
  }

  value = xmlEncodeEntitiesReentrant(attr->doc, (unsigned char *)StringValueCStr(content));
  if (xmlStrlen(value) == 0) {
    attr->children = xmlNewDocText(attr->doc, value);
  } else {
    attr->children = xmlStringGetNodeList(attr->doc, value);
  }
  xmlFree(value);

  for (cur = attr->children; cur; cur = cur->next) {
    cur->parent = (xmlNode *)attr;
    cur->doc = attr->doc;
    if (cur->next == NULL) {
      attr->last = cur;
    }
  }

  return content;
}

/*
 * call-seq:
 *  new(document, name)
 *
 * Create a new Attr element on the +document+ with +name+
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  VALUE document;
  VALUE name;
  VALUE rest;
  xmlAttrPtr node;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &document, &name, &rest);

  if (! rb_obj_is_kind_of(document, cNokogiriXmlDocument)) {
    rb_raise(rb_eArgError, "parameter must be a Nokogiri::XML::Document");
  }

  xml_doc = noko_xml_document_unwrap(document);

  node = xmlNewDocProp(
           xml_doc,
           (const xmlChar *)StringValueCStr(name),
           NULL
         );

  noko_xml_document_pin_node((xmlNodePtr)node);

  rb_node = noko_xml_node_wrap(klass, (xmlNodePtr)node);
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) {
    rb_yield(rb_node);
  }

  return rb_node;
}

void
noko_init_xml_attr(void)
{
  assert(cNokogiriXmlNode);
  /*
   * Attr represents a Attr node in an xml document.
   */
  cNokogiriXmlAttr = rb_define_class_under(mNokogiriXml, "Attr", cNokogiriXmlNode);

  rb_define_singleton_method(cNokogiriXmlAttr, "new", new, -1);

  rb_define_method(cNokogiriXmlAttr, "value=", set_value, 1);
}
