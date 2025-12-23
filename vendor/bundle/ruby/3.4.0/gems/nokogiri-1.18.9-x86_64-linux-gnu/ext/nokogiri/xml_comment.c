#include <nokogiri.h>

VALUE cNokogiriXmlComment;

static ID document_id ;

/*
 * call-seq:
 *  new(document_or_node, content)
 *
 * Create a new Comment element on the +document+ with +content+.
 * Alternatively, if a +node+ is passed, the +node+'s document is used.
 */
static VALUE
new (int argc, VALUE *argv, VALUE klass)
{
  xmlDocPtr xml_doc;
  xmlNodePtr node;
  VALUE document;
  VALUE content;
  VALUE rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &document, &content, &rest);

  Check_Type(content, T_STRING);
  if (rb_obj_is_kind_of(document, cNokogiriXmlNode)) {
    document = rb_funcall(document, document_id, 0);
  } else if (!rb_obj_is_kind_of(document, cNokogiriXmlDocument)
             && !rb_obj_is_kind_of(document, cNokogiriXmlDocumentFragment)) {
    rb_raise(rb_eArgError, "first argument must be a XML::Document or XML::Node");
  }
  xml_doc = noko_xml_document_unwrap(document);

  node = xmlNewDocComment(xml_doc, (const xmlChar *)StringValueCStr(content));
  noko_xml_document_pin_node(node);
  rb_node = noko_xml_node_wrap(klass, node);
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

void
noko_init_xml_comment(void)
{
  assert(cNokogiriXmlCharacterData);
  /*
   * Comment represents a comment node in an xml document.
   */
  cNokogiriXmlComment = rb_define_class_under(mNokogiriXml, "Comment", cNokogiriXmlCharacterData);

  rb_define_singleton_method(cNokogiriXmlComment, "new", new, -1);

  document_id = rb_intern("document");
}
