#include <nokogiri.h>

VALUE cNokogiriXmlSaxPushParser ;

static void
xml_sax_push_parser_free(void *data)
{
  xmlParserCtxtPtr ctx = data;
  if (ctx->myDoc) {
    xmlFreeDoc(ctx->myDoc);
  }
  if (ctx) {
    xmlFreeParserCtxt(ctx);
  }
}

static const rb_data_type_t xml_sax_push_parser_type = {
  .wrap_struct_name = "xmlParserCtxt",
  .function = {
    .dfree = xml_sax_push_parser_free,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
xml_sax_push_parser_allocate(VALUE klass)
{
  return TypedData_Wrap_Struct(klass, &xml_sax_push_parser_type, NULL);
}

xmlParserCtxtPtr
noko_xml_sax_push_parser_unwrap(VALUE rb_parser)
{
  xmlParserCtxtPtr c_parser;
  TypedData_Get_Struct(rb_parser, xmlParserCtxt, &xml_sax_push_parser_type, c_parser);
  return c_parser;
}

/*
 * Write +chunk+ to PushParser. +last_chunk+ triggers the end_document handle
 */
static VALUE
noko_xml_sax_push_parser__native_write(VALUE self, VALUE _chunk, VALUE _last_chunk)
{
  xmlParserCtxtPtr ctx;
  const char *chunk  = NULL;
  int size            = 0;

  ctx = noko_xml_sax_push_parser_unwrap(self);

  if (Qnil != _chunk) {
    chunk = StringValuePtr(_chunk);
    size = (int)RSTRING_LEN(_chunk);
  }

  xmlSetStructuredErrorFunc(NULL, NULL);

  if (xmlParseChunk(ctx, chunk, size, Qtrue == _last_chunk ? 1 : 0)) {
    if (!(xmlCtxtGetOptions(ctx) & XML_PARSE_RECOVER)) {
      xmlErrorConstPtr e = xmlCtxtGetLastError(ctx);
      noko__error_raise(NULL, e);
    }
  }

  return self;
}

/*
 * call-seq:
 *  initialize_native(xml_sax, filename)
 *
 * Initialize the push parser with +xml_sax+ using +filename+
 */
static VALUE
noko_xml_sax_push_parser__initialize_native(VALUE self, VALUE _xml_sax, VALUE _filename)
{
  xmlSAXHandlerPtr sax;
  const char *filename = NULL;
  xmlParserCtxtPtr ctx;

  sax = noko_xml_sax_parser_unwrap(_xml_sax);

  if (_filename != Qnil) { filename = StringValueCStr(_filename); }

  ctx = xmlCreatePushParserCtxt(
          sax,
          NULL,
          NULL,
          0,
          filename
        );
  if (ctx == NULL) {
    rb_raise(rb_eRuntimeError, "Could not create a parser context");
  }

  ctx->userData = ctx;
  ctx->_private = (void *)_xml_sax;

  DATA_PTR(self) = ctx;
  return self;
}

static VALUE
noko_xml_sax_push_parser__options_get(VALUE self)
{
  xmlParserCtxtPtr ctx;

  ctx = noko_xml_sax_push_parser_unwrap(self);

  return INT2NUM(xmlCtxtGetOptions(ctx));
}

static VALUE
noko_xml_sax_push_parser__options_set(VALUE self, VALUE options)
{
  int error;
  xmlParserCtxtPtr ctx;

  ctx = noko_xml_sax_push_parser_unwrap(self);

  error = xmlCtxtSetOptions(ctx, (int)NUM2INT(options));
  if (error) {
    rb_raise(rb_eRuntimeError, "Cannot set XML parser context options (%x)", error);
  }

  return Qnil;
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
noko_xml_sax_push_parser__replace_entities_get(VALUE self)
{
  xmlParserCtxtPtr ctxt = noko_xml_sax_push_parser_unwrap(self);

  if (xmlCtxtGetOptions(ctxt) & XML_PARSE_NOENT) {
    return Qtrue;
  } else {
    return Qfalse;
  }
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
 */
static VALUE
noko_xml_sax_push_parser__replace_entities_set(VALUE self, VALUE value)
{
  int error;
  xmlParserCtxtPtr ctxt = noko_xml_sax_push_parser_unwrap(self);

  if (RB_TEST(value)) {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) | XML_PARSE_NOENT);
  } else {
    error = xmlCtxtSetOptions(ctxt, xmlCtxtGetOptions(ctxt) & ~XML_PARSE_NOENT);
  }

  if (error) {
    rb_raise(rb_eRuntimeError, "failed to set parser context options (%x)", error);
  }

  return value;
}

void
noko_init_xml_sax_push_parser(void)
{
  cNokogiriXmlSaxPushParser = rb_define_class_under(mNokogiriXmlSax, "PushParser", rb_cObject);

  rb_define_alloc_func(cNokogiriXmlSaxPushParser, xml_sax_push_parser_allocate);

  rb_define_method(cNokogiriXmlSaxPushParser, "options",
                   noko_xml_sax_push_parser__options_get, 0);
  rb_define_method(cNokogiriXmlSaxPushParser, "options=",
                   noko_xml_sax_push_parser__options_set, 1);
  rb_define_method(cNokogiriXmlSaxPushParser, "replace_entities",
                   noko_xml_sax_push_parser__replace_entities_get, 0);
  rb_define_method(cNokogiriXmlSaxPushParser, "replace_entities=",
                   noko_xml_sax_push_parser__replace_entities_set, 1);

  rb_define_private_method(cNokogiriXmlSaxPushParser, "initialize_native",
                           noko_xml_sax_push_parser__initialize_native, 2);
  rb_define_private_method(cNokogiriXmlSaxPushParser, "native_write",
                           noko_xml_sax_push_parser__native_write, 2);
}
