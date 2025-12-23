#include <nokogiri.h>

VALUE cNokogiriXmlSaxParserContext ;

static ID id_read;

static void
xml_sax_parser_context_type_free(void *data)
{
  xmlParserCtxtPtr ctxt = data;
  ctxt->sax = NULL;
  if (ctxt->myDoc) {
    xmlFreeDoc(ctxt->myDoc);
  }
  if (ctxt) {
    xmlFreeParserCtxt(ctxt);
  }
}

/*
 *  note that htmlParserCtxtPtr == xmlParserCtxtPtr and xmlFreeParserCtxt() == htmlFreeParserCtxt()
 *  so we use this type for both XML::SAX::ParserContext and HTML::SAX::ParserContext
 */
static const rb_data_type_t xml_sax_parser_context_type = {
  .wrap_struct_name = "xmlParserCtxt",
  .function = {
    .dfree = xml_sax_parser_context_type_free,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

xmlParserCtxtPtr
noko_xml_sax_parser_context_unwrap(VALUE rb_context)
{
  xmlParserCtxtPtr c_context;
  TypedData_Get_Struct(rb_context, xmlParserCtxt, &xml_sax_parser_context_type, c_context);
  return c_context;
}

VALUE
noko_xml_sax_parser_context_wrap(VALUE klass, xmlParserCtxtPtr c_context)
{
  return TypedData_Wrap_Struct(klass, &xml_sax_parser_context_type, c_context);
}

void
noko_xml_sax_parser_context_set_encoding(xmlParserCtxtPtr c_context, VALUE rb_encoding)
{
  if (!NIL_P(rb_encoding)) {
    VALUE rb_encoding_name = rb_funcall(rb_encoding, rb_intern("name"), 0);

    char *encoding_name = StringValueCStr(rb_encoding_name);
    if (encoding_name) {
      libxmlStructuredErrorHandlerState handler_state;
      VALUE rb_errors = rb_ary_new();

      noko__structured_error_func_save_and_set(&handler_state, (void *)rb_errors, noko__error_array_pusher);

      int result = xmlSwitchEncodingName(c_context, encoding_name);

      noko__structured_error_func_restore(&handler_state);

      if (result != 0) {
        xmlFreeParserCtxt(c_context);

        VALUE exception = rb_funcall(cNokogiriXmlSyntaxError, rb_intern("aggregate"), 1, rb_errors);
        if (!NIL_P(exception)) {
          rb_exc_raise(exception);
        } else {
          rb_raise(rb_eRuntimeError, "could not set encoding");
        }
      }
    }
  }
}

/* :nodoc: */
static VALUE
noko_xml_sax_parser_context_s_native_io(VALUE rb_class, VALUE rb_io, VALUE rb_encoding)
{
  if (!rb_respond_to(rb_io, id_read)) {
    rb_raise(rb_eTypeError, "argument expected to respond to :read");
  }

  if (!NIL_P(rb_encoding) && !rb_obj_is_kind_of(rb_encoding, rb_cEncoding)) {
    rb_raise(rb_eTypeError, "argument must be an Encoding object");
  }

  xmlParserCtxtPtr c_context =
    xmlCreateIOParserCtxt(NULL, NULL,
                          (xmlInputReadCallback)noko_io_read,
                          (xmlInputCloseCallback)noko_io_close,
                          (void *)rb_io, XML_CHAR_ENCODING_NONE);
  if (!c_context) {
    rb_raise(rb_eRuntimeError, "failed to create xml sax parser context");
  }

  noko_xml_sax_parser_context_set_encoding(c_context, rb_encoding);

  if (c_context->sax) {
    xmlFree(c_context->sax);
    c_context->sax = NULL;
  }

  VALUE rb_context = noko_xml_sax_parser_context_wrap(rb_class, c_context);
  rb_iv_set(rb_context, "@input", rb_io);

  return rb_context;
}

/* :nodoc: */
static VALUE
noko_xml_sax_parser_context_s_native_file(VALUE rb_class, VALUE rb_path, VALUE rb_encoding)
{
  if (!NIL_P(rb_encoding) && !rb_obj_is_kind_of(rb_encoding, rb_cEncoding)) {
    rb_raise(rb_eTypeError, "argument must be an Encoding object");
  }

  xmlParserCtxtPtr c_context = xmlCreateFileParserCtxt(StringValueCStr(rb_path));
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
noko_xml_sax_parser_context_s_native_memory(VALUE rb_class, VALUE rb_input, VALUE rb_encoding)
{
  Check_Type(rb_input, T_STRING);
  if (!(int)RSTRING_LEN(rb_input)) {
    rb_raise(rb_eRuntimeError, "input string cannot be empty");
  }

  if (!NIL_P(rb_encoding) && !rb_obj_is_kind_of(rb_encoding, rb_cEncoding)) {
    rb_raise(rb_eTypeError, "argument must be an Encoding object");
  }

  xmlParserCtxtPtr c_context =
    xmlCreateMemoryParserCtxt(StringValuePtr(rb_input), (int)RSTRING_LEN(rb_input));
  if (!c_context) {
    rb_raise(rb_eRuntimeError, "failed to create xml sax parser context");
  }

  noko_xml_sax_parser_context_set_encoding(c_context, rb_encoding);

  if (c_context->sax) {
    xmlFree(c_context->sax);
    c_context->sax = NULL;
  }

  VALUE rb_context = noko_xml_sax_parser_context_wrap(rb_class, c_context);
  rb_iv_set(rb_context, "@input", rb_input);

  return rb_context;
}

/*
 * call-seq:
 *  parse_with(sax_handler)
 *
 * Use +sax_handler+ and parse the current document
 *
 * 💡 Calling this method directly is discouraged. Use Nokogiri::XML::SAX::Parser methods which are
 * more convenient for most use cases.
 */
static VALUE
noko_xml_sax_parser_context__parse_with(VALUE rb_context, VALUE rb_sax_parser)
{
  xmlParserCtxtPtr c_context;
  xmlSAXHandlerPtr sax;

  if (!rb_obj_is_kind_of(rb_sax_parser, cNokogiriXmlSaxParser)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::SAX::Parser");
  }

  c_context = noko_xml_sax_parser_context_unwrap(rb_context);
  sax = noko_xml_sax_parser_unwrap(rb_sax_parser);

  c_context->sax = sax;
  c_context->userData = c_context; /* so we can use libxml2/SAX2.c handlers if we want to */
  c_context->_private = (void *)rb_sax_parser;

  xmlSetStructuredErrorFunc(NULL, NULL);

  /* although we're calling back into Ruby here, we don't need to worry about exceptions, because we
   * don't have any cleanup to do. The only memory we need to free is handled by
   * xml_sax_parser_context_type_free */
  xmlParseDocument(c_context);

  return Qnil;
}

/*
 * call-seq:
 *   replace_entities=(value)
 *
 * See Document@Entity+Handling for an explanation of the behavior controlled by this flag.
 *
 * [Parameters]
 * - +value+ (Boolean) Whether external parsed entities will be resolved.
 *
 * ⚠ <b>It is UNSAFE to set this option to +true+</b> when parsing untrusted documents. The option
 * defaults to +false+ for this reason.
 *
 * This option is perhaps misnamed by the libxml2 author, since it controls resolution and not
 * replacement.
 *
 * [Example]
 * Because this class is generally not instantiated directly, you would typically set this option
 * via the block argument to Nokogiri::XML::SAX::Parser.parse et al:
 *
 *     parser = Nokogiri::XML::SAX::Parser.new(document_handler)
 *     parser.parse(xml) do |ctx|
 *       ctx.replace_entities = true # this is UNSAFE for untrusted documents!
 *     end
 */
static VALUE
noko_xml_sax_parser_context__replace_entities_set(VALUE rb_context, VALUE rb_value)
{
  int error;
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (RB_TEST(rb_value)) {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) | XML_PARSE_NOENT);
  } else {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) & ~XML_PARSE_NOENT);
  }

  if (error) {
    rb_raise(rb_eRuntimeError, "failed to set parser context options (%x)", error);
  }

  return rb_value;
}

/*
 * call-seq:
 *   replace_entities
 *
 * See Document@Entity+Handling for an explanation of the behavior controlled by this flag.
 *
 * [Returns] (Boolean) Value of the parse option. (Default +false+)
 *
 * This option is perhaps misnamed by the libxml2 author, since it controls resolution and not
 * replacement.
 */
static VALUE
noko_xml_sax_parser_context__replace_entities_get(VALUE rb_context)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (xmlCtxtGetOptions(ctxt) & XML_PARSE_NOENT) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/*
 * call-seq: line
 *
 * [Returns] (Integer) the line number of the line being currently parsed.
 */
static VALUE
noko_xml_sax_parser_context__line(VALUE rb_context)
{
  xmlParserInputPtr io;
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  io = ctxt->input;
  if (io) {
    return INT2NUM(io->line);
  }

  return Qnil;
}

/*
 * call-seq: column
 *
 * [Returns] (Integer) the column number of the column being currently parsed.
 */
static VALUE
noko_xml_sax_parser_context__column(VALUE rb_context)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);
  xmlParserInputPtr io;

  io = ctxt->input;
  if (io) {
    return INT2NUM(io->col);
  }

  return Qnil;
}

/*
 * call-seq:
 *   recovery=(value)
 *
 * Controls whether this parser will recover from parsing errors. If set to +true+, the parser will
 * invoke the SAX::Document#error callback and continue processing the file. If set to +false+, the
 * parser will stop processing the file on the first parsing error.
 *
 * [Parameters]
 * - +value+ (Boolean) Recover from parsing errors. (Default is +false+ for XML and +true+ for HTML.)
 *
 * [Returns] (Boolean) The passed +value+.
 *
 * [Example]
 * Because this class is generally not instantiated directly, you would typically set this option
 * via the block argument to Nokogiri::XML::SAX::Parser.parse et al:
 *
 *     parser = Nokogiri::XML::SAX::Parser.new(document_handler)
 *     parser.parse(xml) do |ctx|
 *       ctx.recovery = true
 *     end
 */
static VALUE
noko_xml_sax_parser_context__recovery_set(VALUE rb_context, VALUE rb_value)
{
  int error;
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (RB_TEST(rb_value)) {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) | XML_PARSE_RECOVER);
  } else {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) & ~XML_PARSE_RECOVER);
  }

  if (error) {
    rb_raise(rb_eRuntimeError, "failed to set parser context options (%x)", error);
  }

  return rb_value;
}

/*
 * call-seq:
 *   recovery
 *
 * Inspect whether this parser will recover from parsing errors. If set to +true+, the parser will
 * invoke the SAX::Document#error callback and continue processing the file. If set to +false+, the
 * parser will stop processing the file on the first parsing error.
 *
 * [Returns] (Boolean) Whether this parser will recover from parsing errors.
 *
 * Default is +false+ for XML and +true+ for HTML.
 */
static VALUE
noko_xml_sax_parser_context__recovery_get(VALUE rb_context)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_parser_context_unwrap(rb_context);

  if (xmlCtxtGetOptions(ctxt) & XML_PARSE_RECOVER) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

void
noko_init_xml_sax_parser_context(void)
{
  cNokogiriXmlSaxParserContext = rb_define_class_under(mNokogiriXmlSax, "ParserContext", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlSaxParserContext);

  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "native_io",
                             noko_xml_sax_parser_context_s_native_io, 2);
  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "native_memory",
                             noko_xml_sax_parser_context_s_native_memory, 2);
  rb_define_singleton_method(cNokogiriXmlSaxParserContext, "native_file",
                             noko_xml_sax_parser_context_s_native_file, 2);

  rb_define_method(cNokogiriXmlSaxParserContext, "parse_with", noko_xml_sax_parser_context__parse_with, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "replace_entities=",
                   noko_xml_sax_parser_context__replace_entities_set, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "replace_entities",
                   noko_xml_sax_parser_context__replace_entities_get, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "recovery=", noko_xml_sax_parser_context__recovery_set, 1);
  rb_define_method(cNokogiriXmlSaxParserContext, "recovery", noko_xml_sax_parser_context__recovery_get, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "line", noko_xml_sax_parser_context__line, 0);
  rb_define_method(cNokogiriXmlSaxParserContext, "column", noko_xml_sax_parser_context__column, 0);

  id_read = rb_intern("read");
}
