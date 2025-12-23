#include <nokogiri.h>

VALUE cNokogiriXmlSchema;

static void
xml_schema_deallocate(void *data)
{
  xmlSchemaPtr schema = data;
  xmlSchemaFree(schema);
}

static const rb_data_type_t xml_schema_type = {
  .wrap_struct_name = "xmlSchema",
  .function = {
    .dfree = xml_schema_deallocate,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
noko_xml_schema__validate_document(VALUE self, VALUE document)
{
  xmlDocPtr doc;
  xmlSchemaPtr schema;
  xmlSchemaValidCtxtPtr valid_ctxt;
  VALUE errors;

  TypedData_Get_Struct(self, xmlSchema, &xml_schema_type, schema);
  doc = noko_xml_document_unwrap(document);

  errors = rb_ary_new();

  valid_ctxt = xmlSchemaNewValidCtxt(schema);

  if (NULL == valid_ctxt) {
    /* we have a problem */
    rb_raise(rb_eRuntimeError, "Could not create a validation context");
  }

  xmlSchemaSetValidStructuredErrors(
    valid_ctxt,
    noko__error_array_pusher,
    (void *)errors
  );

  int status = xmlSchemaValidateDoc(valid_ctxt, doc);

  xmlSchemaFreeValidCtxt(valid_ctxt);

  if (status != 0) {
    if (RARRAY_LEN(errors) == 0) {
      rb_ary_push(errors, rb_str_new2("Could not validate document"));
    }
  }

  return errors;
}

static VALUE
noko_xml_schema__validate_file(VALUE self, VALUE rb_filename)
{
  xmlSchemaPtr schema;
  xmlSchemaValidCtxtPtr valid_ctxt;
  const char *filename ;
  VALUE errors;

  TypedData_Get_Struct(self, xmlSchema, &xml_schema_type, schema);
  filename = (const char *)StringValueCStr(rb_filename) ;

  errors = rb_ary_new();

  valid_ctxt = xmlSchemaNewValidCtxt(schema);

  if (NULL == valid_ctxt) {
    /* we have a problem */
    rb_raise(rb_eRuntimeError, "Could not create a validation context");
  }

  xmlSchemaSetValidStructuredErrors(
    valid_ctxt,
    noko__error_array_pusher,
    (void *)errors
  );

  int status = xmlSchemaValidateFile(valid_ctxt, filename, 0);

  xmlSchemaFreeValidCtxt(valid_ctxt);

  if (status != 0) {
    if (RARRAY_LEN(errors) == 0) {
      rb_ary_push(errors, rb_str_new2("Could not validate file."));
    }
  }

  return errors;
}

static VALUE
xml_schema_parse_schema(
  VALUE rb_class,
  xmlSchemaParserCtxtPtr c_parser_context,
  VALUE rb_parse_options
)
{
  xmlExternalEntityLoader saved_loader = 0;
  libxmlStructuredErrorHandlerState handler_state;

  if (NIL_P(rb_parse_options)) {
    rb_parse_options = rb_const_get_at(
                         rb_const_get_at(mNokogiriXml, rb_intern("ParseOptions")),
                         rb_intern("DEFAULT_SCHEMA")
                       );
  }
  int c_parse_options = (int)NUM2INT(rb_funcall(rb_parse_options, rb_intern("to_i"), 0));

  VALUE rb_errors = rb_ary_new();
  noko__structured_error_func_save_and_set(&handler_state, (void *)rb_errors, noko__error_array_pusher);

  xmlSchemaSetParserStructuredErrors(
    c_parser_context,
    noko__error_array_pusher,
    (void *)rb_errors
  );

  if (c_parse_options & XML_PARSE_NONET) {
    saved_loader = xmlGetExternalEntityLoader();
    xmlSetExternalEntityLoader(xmlNoNetExternalEntityLoader);
  }

  xmlSchemaPtr c_schema = xmlSchemaParse(c_parser_context);

  if (saved_loader) {
    xmlSetExternalEntityLoader(saved_loader);
  }

  xmlSchemaFreeParserCtxt(c_parser_context);
  noko__structured_error_func_restore(&handler_state);

  if (NULL == c_schema) {
    VALUE exception = rb_funcall(cNokogiriXmlSyntaxError, rb_intern("aggregate"), 1, rb_errors);
    if (RB_TEST(exception)) {
      rb_exc_raise(exception);
    } else {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    }
  }

  VALUE rb_schema = TypedData_Wrap_Struct(rb_class, &xml_schema_type, c_schema);
  rb_iv_set(rb_schema, "@errors", rb_errors);
  rb_iv_set(rb_schema, "@parse_options", rb_parse_options);

  return rb_schema;
}

/*
 * :call-seq:
 *   from_document(input) → Nokogiri::XML::Schema
 *   from_document(input, parse_options) → Nokogiri::XML::Schema
 *
 * Parse an \XSD schema definition from a Document to create a new Nokogiri::XML::Schema
 *
 * [Parameters]
 * - +input+ (XML::Document) A document containing the \XSD schema definition
 * - +parse_options+ (Nokogiri::XML::ParseOptions)
 *   Defaults to Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA
 *
 * [Returns] Nokogiri::XML::Schema
 */
static VALUE
noko_xml_schema_s_from_document(int argc, VALUE *argv, VALUE rb_class)
{
  /* TODO: deprecate this method and put file-or-string logic into .new so that becomes the
   * preferred entry point, and this can become a private method */
  VALUE rb_document;
  VALUE rb_parse_options;
  VALUE rb_schema;
  xmlDocPtr c_document;
  xmlSchemaParserCtxtPtr c_parser_context;
  int defensive_copy_p = 0;

  rb_scan_args(argc, argv, "11", &rb_document, &rb_parse_options);

  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlNode)) {
    rb_raise(rb_eTypeError,
             "expected parameter to be a Nokogiri::XML::Document, received %"PRIsVALUE,
             rb_obj_class(rb_document));
  }

  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlDocument)) {
    xmlNodePtr deprecated_node_type_arg;
    NOKO_WARN_DEPRECATION("Passing a Node as the first parameter to Schema.from_document is deprecated. Please pass a Document instead. This will become an error in Nokogiri v1.17.0."); // TODO: deprecated in v1.15.3, remove in v1.17.0
    Noko_Node_Get_Struct(rb_document, xmlNode, deprecated_node_type_arg);
    c_document = deprecated_node_type_arg->doc;
  } else {
    c_document = noko_xml_document_unwrap(rb_document);
  }

  if (noko_xml_document_has_wrapped_blank_nodes_p(c_document)) {
    // see https://github.com/sparklemotion/nokogiri/pull/2001
    c_document = xmlCopyDoc(c_document, 1);
    defensive_copy_p = 1;
  }

  c_parser_context = xmlSchemaNewDocParserCtxt(c_document);
  rb_schema = xml_schema_parse_schema(rb_class, c_parser_context, rb_parse_options);

  if (defensive_copy_p) {
    xmlFreeDoc(c_document);
    c_document = NULL;
  }

  return rb_schema;
}

void
noko_init_xml_schema(void)
{
  cNokogiriXmlSchema = rb_define_class_under(mNokogiriXml, "Schema", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlSchema);

  rb_define_singleton_method(cNokogiriXmlSchema, "from_document", noko_xml_schema_s_from_document, -1);

  rb_define_private_method(cNokogiriXmlSchema, "validate_document", noko_xml_schema__validate_document, 1);
  rb_define_private_method(cNokogiriXmlSchema, "validate_file",     noko_xml_schema__validate_file, 1);
}
