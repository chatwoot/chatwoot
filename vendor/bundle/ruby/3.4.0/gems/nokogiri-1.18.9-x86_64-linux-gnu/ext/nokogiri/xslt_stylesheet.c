#include <nokogiri.h>

VALUE cNokogiriXsltStylesheet;

static void
mark(void *data)
{
  nokogiriXsltStylesheetTuple *wrapper = (nokogiriXsltStylesheetTuple *)data;
  rb_gc_mark(wrapper->func_instances);
}

static void
dealloc(void *data)
{
  nokogiriXsltStylesheetTuple *wrapper = (nokogiriXsltStylesheetTuple *)data;
  xsltStylesheetPtr doc = wrapper->ss;
  xsltFreeStylesheet(doc);
  ruby_xfree(wrapper);
}

static const rb_data_type_t nokogiri_xslt_stylesheet_tuple_type = {
  .wrap_struct_name = "nokogiriXsltStylesheetTuple",
  .function = {
    .dmark = mark,
    .dfree = dealloc,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

PRINTFLIKE_DECL(2, 3)
static void
xslt_generic_error_handler(void *ctx, const char *msg, ...)
{
  VALUE message;

#ifdef TRUFFLERUBY_NOKOGIRI_SYSTEM_LIBRARIES
  /* It is not currently possible to pass var args from native
     functions to sulong, so we work around the issue here. */
  message = rb_sprintf("xslt_generic_error_handler: %s", msg);
#else
  va_list args;
  va_start(args, msg);
  message = rb_vsprintf(msg, args);
  va_end(args);
#endif

  rb_str_concat((VALUE)ctx, message);
}

VALUE
Nokogiri_wrap_xslt_stylesheet(xsltStylesheetPtr ss)
{
  VALUE self;
  nokogiriXsltStylesheetTuple *wrapper;

  self = TypedData_Make_Struct(
           cNokogiriXsltStylesheet,
           nokogiriXsltStylesheetTuple,
           &nokogiri_xslt_stylesheet_tuple_type,
           wrapper
         );

  ss->_private = (void *)self;
  wrapper->ss = ss;
  wrapper->func_instances = rb_ary_new();

  return self;
}

/*
 * call-seq:
 *   parse_stylesheet_doc(document)
 *
 * Parse an XSLT::Stylesheet from +document+.
 *
 * [Parameters]
 * - +document+ (Nokogiri::XML::Document) the document to be parsed.
 *
 * [Returns] Nokogiri::XSLT::Stylesheet
 */
static VALUE
parse_stylesheet_doc(VALUE klass, VALUE xmldocobj)
{
  xmlDocPtr xml, xml_cpy;
  VALUE errstr, exception;
  xsltStylesheetPtr ss ;

  xml = noko_xml_document_unwrap(xmldocobj);

  errstr = rb_str_new(0, 0);
  xsltSetGenericErrorFunc((void *)errstr, xslt_generic_error_handler);

  xml_cpy = xmlCopyDoc(xml, 1); /* 1 => recursive */
  ss = xsltParseStylesheetDoc(xml_cpy);

  xsltSetGenericErrorFunc(NULL, NULL);

  if (!ss) {
    xmlFreeDoc(xml_cpy);
    exception = rb_exc_new3(rb_eRuntimeError, errstr);
    rb_exc_raise(exception);
  }

  return Nokogiri_wrap_xslt_stylesheet(ss);
}


/*
 * call-seq:
 *   serialize(document)
 *
 * Serialize +document+ to an xml string, as specified by the +method+ parameter in the Stylesheet.
 */
static VALUE
rb_xslt_stylesheet_serialize(VALUE self, VALUE xmlobj)
{
  xmlDocPtr xml ;
  nokogiriXsltStylesheetTuple *wrapper;
  xmlChar *doc_ptr ;
  int doc_len ;
  VALUE rval ;

  xml = noko_xml_document_unwrap(xmlobj);
  TypedData_Get_Struct(
    self,
    nokogiriXsltStylesheetTuple,
    &nokogiri_xslt_stylesheet_tuple_type,
    wrapper
  );
  xsltSaveResultToString(&doc_ptr, &doc_len, xml, wrapper->ss);
  rval = NOKOGIRI_STR_NEW(doc_ptr, doc_len);
  xmlFree(doc_ptr);
  return rval ;
}

/*
 * call-seq:
 *   transform(document)
 *   transform(document, params = {})
 *
 * Transform an XML::Document as defined by an XSLT::Stylesheet.
 *
 * [Parameters]
 * - +document+ (Nokogiri::XML::Document) the document to be transformed.
 * - +params+ (Hash, Array) strings used as XSLT parameters.
 *
 * [Returns] Nokogiri::XML::Document
 *
 * *Example* of basic transformation:
 *
 *   xslt = <<~XSLT
 *     <xsl:stylesheet version="1.0"
 *     xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 *
 *     <xsl:param name="title"/>
 *
 *     <xsl:template match="/">
 *       <html>
 *         <body>
 *           <h1><xsl:value-of select="$title"/></h1>
 *           <ol>
 *             <xsl:for-each select="staff/employee">
 *               <li><xsl:value-of select="employeeId"></li>
 *             </xsl:for-each>
 *           </ol>
 *         </body>
 *       </html>
 *     </xsl:stylesheet>
 *   XSLT
 *
 *   xml = <<~XML
 *     <?xml version="1.0"?>
 *     <staff>
 *       <employee>
 *         <employeeId>EMP0001</employeeId>
 *         <position>Accountant</position>
 *       </employee>
 *       <employee>
 *         <employeeId>EMP0002</employeeId>
 *         <position>Developer</position>
 *       </employee>
 *     </staff>
 *   XML
 *
 *   doc = Nokogiri::XML::Document.parse(xml)
 *   stylesheet = Nokogiri::XSLT.parse(xslt)
 *
 * ⚠ Note that the +h1+ element is empty because no param has been provided!
 *
 *   stylesheet.transform(doc).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1></h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * *Example* of using an input parameter hash:
 *
 * ⚠ The title is populated, but note how we need to quote-escape the value.
 *
 *   stylesheet.transform(doc, { "title" => "'Employee List'" }).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Employee List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * *Example* using the XSLT.quote_params helper method to safely quote-escape strings:
 *
 *   stylesheet.transform(doc, Nokogiri::XSLT.quote_params({ "title" => "Aaron's List" })).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Aaron's List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * *Example* using an array of XSLT parameters
 *
 * You can also use an array if you want to.
 *
 *   stylesheet.transform(doc, ["title", "'Employee List'"]).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Employee List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * Or pass an array to XSLT.quote_params:
 *
 *   stylesheet.transform(doc, Nokogiri::XSLT.quote_params(["title", "Aaron's List"])).to_xml
 *   # => "<html><body>\n" +
 *   #    "<h1>Aaron's List</h1>\n" +
 *   #    "<ol>\n" +
 *   #    "<li>EMP0001</li>\n" +
 *   #    "<li>EMP0002</li>\n" +
 *   #    "</ol>\n" +
 *   #    "</body></html>\n"
 *
 * See: Nokogiri::XSLT.quote_params
 */
static VALUE
rb_xslt_stylesheet_transform(int argc, VALUE *argv, VALUE self)
{
  VALUE rb_document, rb_param, rb_error_str;
  xmlDocPtr c_document ;
  xmlDocPtr c_result_document ;
  nokogiriXsltStylesheetTuple *wrapper;
  const char **params ;
  long param_len, j ;
  int parse_error_occurred ;
  int defensive_copy_p = 0;

  rb_scan_args(argc, argv, "11", &rb_document, &rb_param);
  if (NIL_P(rb_param)) { rb_param = rb_ary_new2(0L) ; }
  if (!rb_obj_is_kind_of(rb_document, cNokogiriXmlDocument)) {
    rb_raise(rb_eArgError, "argument must be a Nokogiri::XML::Document");
  }

  /* handle hashes as arguments. */
  if (T_HASH == TYPE(rb_param)) {
    rb_param = rb_funcall(rb_param, rb_intern("to_a"), 0);
    rb_param = rb_funcall(rb_param, rb_intern("flatten"), 0);
  }

  Check_Type(rb_param, T_ARRAY);

  c_document = noko_xml_document_unwrap(rb_document);
  TypedData_Get_Struct(self, nokogiriXsltStylesheetTuple, &nokogiri_xslt_stylesheet_tuple_type, wrapper);

  param_len = RARRAY_LEN(rb_param);
  params = ruby_xcalloc((size_t)param_len + 1, sizeof(char *));
  for (j = 0 ; j < param_len ; j++) {
    VALUE entry = rb_ary_entry(rb_param, j);
    const char *ptr = StringValueCStr(entry);
    params[j] = ptr;
  }
  params[param_len] = 0 ;

  xsltTransformContextPtr c_transform_context = xsltNewTransformContext(wrapper->ss, c_document);
  if (xsltNeedElemSpaceHandling(c_transform_context) &&
      noko_xml_document_has_wrapped_blank_nodes_p(c_document)) {
    // see https://github.com/sparklemotion/nokogiri/issues/2800
    c_document = xmlCopyDoc(c_document, 1);
    defensive_copy_p = 1;
  }
  xsltFreeTransformContext(c_transform_context);

  rb_error_str = rb_str_new(0, 0);
  xsltSetGenericErrorFunc((void *)rb_error_str, xslt_generic_error_handler);
  xmlSetGenericErrorFunc((void *)rb_error_str, xslt_generic_error_handler);

  c_result_document = xsltApplyStylesheet(wrapper->ss, c_document, params);

  ruby_xfree(params);
  if (defensive_copy_p) {
    xmlFreeDoc(c_document);
    c_document = NULL;
  }

  xsltSetGenericErrorFunc(NULL, NULL);
  xmlSetGenericErrorFunc(NULL, NULL);

  parse_error_occurred = (Qfalse == rb_funcall(rb_error_str, rb_intern("empty?"), 0));

  if (parse_error_occurred) {
    rb_exc_raise(rb_exc_new3(rb_eRuntimeError, rb_error_str));
  }

  return noko_xml_document_wrap((VALUE)0, c_result_document) ;
}

static void
method_caller(xmlXPathParserContextPtr ctxt, int nargs)
{
  VALUE handler;
  const char *function_name;
  xsltTransformContextPtr transform;
  const xmlChar *functionURI;

  transform = xsltXPathGetTransformContext(ctxt);
  functionURI = ctxt->context->functionURI;
  handler = (VALUE)xsltGetExtData(transform, functionURI);
  function_name = (const char *)(ctxt->context->function);

  Nokogiri_marshal_xpath_funcall_and_return_values(
    ctxt,
    nargs,
    handler,
    (const char *)function_name
  );
}

static void *
initFunc(xsltTransformContextPtr ctxt, const xmlChar *uri)
{
  VALUE modules = rb_iv_get(mNokogiriXslt, "@modules");
  VALUE obj = rb_hash_aref(modules, rb_str_new2((const char *)uri));
  VALUE args = { Qfalse };
  VALUE methods = rb_funcall(obj, rb_intern("instance_methods"), 1, args);
  VALUE inst;
  nokogiriXsltStylesheetTuple *wrapper;
  int i;

  for (i = 0; i < RARRAY_LEN(methods); i++) {
    VALUE method_name = rb_obj_as_string(rb_ary_entry(methods, i));
    xsltRegisterExtFunction(
      ctxt,
      (unsigned char *)StringValueCStr(method_name),
      uri,
      method_caller
    );
  }

  TypedData_Get_Struct(
    (VALUE)ctxt->style->_private,
    nokogiriXsltStylesheetTuple,
    &nokogiri_xslt_stylesheet_tuple_type,
    wrapper
  );
  inst = rb_class_new_instance(0, NULL, obj);
  rb_ary_push(wrapper->func_instances, inst);

  return (void *)inst;
}

static void
shutdownFunc(xsltTransformContextPtr ctxt,
             const xmlChar *uri, void *data)
{
  nokogiriXsltStylesheetTuple *wrapper;

  TypedData_Get_Struct(
    (VALUE)ctxt->style->_private,
    nokogiriXsltStylesheetTuple,
    &nokogiri_xslt_stylesheet_tuple_type,
    wrapper
  );

  rb_ary_clear(wrapper->func_instances);
}

/* docstring is in lib/nokogiri/xslt.rb */
static VALUE
rb_xslt_s_register(VALUE self, VALUE uri, VALUE obj)
{
  VALUE modules = rb_iv_get(self, "@modules");
  if (NIL_P(modules)) {
    rb_raise(rb_eRuntimeError, "internal error: @modules not set");
  }

  rb_hash_aset(modules, uri, obj);
  xsltRegisterExtModule(
    (unsigned char *)StringValueCStr(uri),
    initFunc,
    shutdownFunc
  );
  return self;
}

void
noko_init_xslt_stylesheet(void)
{
  rb_define_singleton_method(mNokogiriXslt, "register", rb_xslt_s_register, 2);
  rb_iv_set(mNokogiriXslt, "@modules", rb_hash_new());

  cNokogiriXsltStylesheet = rb_define_class_under(mNokogiriXslt, "Stylesheet", rb_cObject);

  rb_undef_alloc_func(cNokogiriXsltStylesheet);

  rb_define_singleton_method(cNokogiriXsltStylesheet, "parse_stylesheet_doc", parse_stylesheet_doc, 1);
  rb_define_method(cNokogiriXsltStylesheet, "serialize", rb_xslt_stylesheet_serialize, 1);
  rb_define_method(cNokogiriXsltStylesheet, "transform", rb_xslt_stylesheet_transform, -1);
}
