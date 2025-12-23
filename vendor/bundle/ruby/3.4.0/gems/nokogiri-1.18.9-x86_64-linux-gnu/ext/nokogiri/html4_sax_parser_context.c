#include <nokogiri.h>

VALUE cNokogiriHtml4SaxParserContext ;

/* :nodoc: */
static VALUE
noko_html4_sax_parser_context_s_native_memory(VALUE rb_class, VALUE rb_input, VALUE rb_encoding)
{
  Check_Type(rb_input, T_STRING);
  if (!(int)RSTRING_LEN(rb_input)) {
    rb_raise(rb_eRuntimeError, "input string cannot be empty");
  }

  if (!NIL_P(rb_encoding) && !rb_obj_is_kind_of(rb_encoding, rb_cEncoding)) {
    rb_raise(rb_eTypeError, "argument must be an Encoding object");
  }

  htmlParserCtxtPtr c_context =
    htmlCreateMemoryParserCtxt(StringValuePtr(rb_input), (int)RSTRING_LEN(rb_input));
  if (!c_context) {
    rb_raise(rb_eRuntimeError, "failed to create xml sax parser context");
  }

  noko_xml_sax_parser_context_set_encoding(c_context, rb_encoding);

  if (c_context->sax) {
    xmlFree(c_context->sax);
    c_context->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(rb_class, c_context);
}

/* :nodoc: */
static VALUE
noko_html4_sax_parser_context_s_native_file(VALUE rb_class, VALUE rb_filename, VALUE rb_encoding)
{
  if (!NIL_P(rb_encoding) && !rb_obj_is_kind_of(rb_encoding, rb_cEncoding)) {
    rb_raise(rb_eTypeError, "argument must be an Encoding object");
  }

  htmlParserCtxtPtr c_context = htmlCreateFileParserCtxt(StringValueCStr(rb_filename), NULL);
  if (!c_context) {
    rb_raise(rb_eRuntimeError, "failed to create xml sax parser context");
  }

  noko_xml_sax_parser_context_set_encoding(c_context, rb_encoding);

  if (c_context->sax) {
    xmlFree(c_context->sax);
    c_context->sax = NULL;
  }

  return noko_xml_sax_parser_context_wrap(rb_class, c_context);
}

static VALUE
noko_html4_sax_parser_context__parse_with(VALUE rb_context, VALUE rb_sax_parser)
{
  htmlParserCtxtPtr ctxt;
  htmlSAXHandlerPtr sax;

  if (!rb_obj_is_kind_of(rb_sax_parser, cNokogiriXmlSaxParser)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::SAX::Parser");
  }

  ctxt = noko_xml_sax_parser_context_unwrap(rb_context);
  sax = noko_xml_sax_parser_unwrap(rb_sax_parser);

  ctxt->sax = sax;
  ctxt->userData = ctxt; /* so we can use libxml2/SAX2.c handlers if we want to */
  ctxt->_private = (void *)rb_sax_parser;

  xmlSetStructuredErrorFunc(NULL, NULL);

  /* although we're calling back into Ruby here, we don't need to worry about exceptions, because we
   * don't have any cleanup to do. The only memory we need to free is handled by
   * xml_sax_parser_context_type_free */
  htmlParseDocument(ctxt);

  return Qnil;
}

void
noko_init_html_sax_parser_context(void)
{
  assert(cNokogiriXmlSaxParserContext);
  cNokogiriHtml4SaxParserContext = rb_define_class_under(mNokogiriHtml4Sax, "ParserContext",
                                   cNokogiriXmlSaxParserContext);

  rb_define_singleton_method(cNokogiriHtml4SaxParserContext, "native_memory",
                             noko_html4_sax_parser_context_s_native_memory, 2);
  rb_define_singleton_method(cNokogiriHtml4SaxParserContext, "native_file",
                             noko_html4_sax_parser_context_s_native_file, 2);

  rb_define_method(cNokogiriHtml4SaxParserContext, "parse_with",
                   noko_html4_sax_parser_context__parse_with, 1);
}
