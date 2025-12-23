#include <nokogiri.h>

VALUE cNokogiriHtml4SaxParser;

static ID id_start_document;

static void
noko_html4_sax_parser_start_document(void *ctx)
{
  xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr)ctx;
  VALUE self = (VALUE)ctxt->_private;
  VALUE doc = rb_iv_get(self, "@document");

  xmlSAX2StartDocument(ctx);

  rb_funcall(doc, id_start_document, 0);
}

static VALUE
noko_html4_sax_parser_initialize(VALUE self)
{
  xmlSAXHandlerPtr handler = noko_xml_sax_parser_unwrap(self);

  rb_call_super(0, NULL);

  handler->startDocument = noko_html4_sax_parser_start_document;

  return self;
}

void
noko_init_html4_sax_parser(void)
{
  cNokogiriHtml4SaxParser = rb_define_class_under(mNokogiriHtml4Sax, "Parser", cNokogiriXmlSaxParser);

  rb_define_private_method(cNokogiriHtml4SaxParser, "initialize_native",
                           noko_html4_sax_parser_initialize, 0);

  id_start_document = rb_intern("start_document");
}
