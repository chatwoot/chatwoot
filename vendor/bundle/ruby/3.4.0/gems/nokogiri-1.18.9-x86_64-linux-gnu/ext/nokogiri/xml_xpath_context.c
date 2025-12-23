#include <nokogiri.h>

VALUE cNokogiriXmlXpathContext;

/*
 * these constants have matching declarations in
 * ext/java/nokogiri/internals/NokogiriNamespaceContext.java
 */
static const xmlChar *NOKOGIRI_PREFIX = (const xmlChar *)"nokogiri";
static const xmlChar *NOKOGIRI_URI = (const xmlChar *)"http://www.nokogiri.org/default_ns/ruby/extensions_functions";
static const xmlChar *NOKOGIRI_BUILTIN_PREFIX = (const xmlChar *)"nokogiri-builtin";
static const xmlChar *NOKOGIRI_BUILTIN_URI = (const xmlChar *)"https://www.nokogiri.org/default_ns/ruby/builtins";

static void
_noko_xml_xpath_context_dfree(void *data)
{
  xmlXPathContextPtr c_context = data;
  xmlXPathFreeContext(c_context);
}

static const rb_data_type_t _noko_xml_xpath_context_type = {
  .wrap_struct_name = "xmlXPathContext",
  .function = {
    .dfree = _noko_xml_xpath_context_dfree,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/* find a CSS class in an HTML element's `class` attribute */
static const xmlChar *
_noko_xml_xpath_context__css_class(const xmlChar *str, const xmlChar *val)
{
  int val_len;

  if (str == NULL) { return (NULL); }
  if (val == NULL) { return (NULL); }

  val_len = xmlStrlen(val);
  if (val_len == 0) { return (str); }

  while (*str != 0) {
    if ((*str == *val) && !xmlStrncmp(str, val, val_len)) {
      const xmlChar *next_byte = str + val_len;

      /* only match if the next byte is whitespace or end of string */
      if ((*next_byte == 0) || (IS_BLANK_CH(*next_byte))) {
        return ((const xmlChar *)str);
      }
    }

    /* advance str to whitespace */
    while ((*str != 0) && !IS_BLANK_CH(*str)) {
      str++;
    }

    /* advance str to start of next word or end of string */
    while ((*str != 0) && IS_BLANK_CH(*str)) {
      str++;
    }
  }

  return (NULL);
}

/* xmlXPathFunction to wrap _noko_xml_xpath_context__css_class() */
static void
noko_xml_xpath_context_xpath_func_css_class(xmlXPathParserContextPtr ctxt, int nargs)
{
  xmlXPathObjectPtr hay, needle;

  CHECK_ARITY(2);

  CAST_TO_STRING;
  needle = valuePop(ctxt);
  if ((needle == NULL) || (needle->type != XPATH_STRING)) {
    xmlXPathFreeObject(needle);
    XP_ERROR(XPATH_INVALID_TYPE);
  }

  CAST_TO_STRING;
  hay = valuePop(ctxt);
  if ((hay == NULL) || (hay->type != XPATH_STRING)) {
    xmlXPathFreeObject(hay);
    xmlXPathFreeObject(needle);
    XP_ERROR(XPATH_INVALID_TYPE);
  }

  if (_noko_xml_xpath_context__css_class(hay->stringval, needle->stringval)) {
    valuePush(ctxt, xmlXPathNewBoolean(1));
  } else {
    valuePush(ctxt, xmlXPathNewBoolean(0));
  }

  xmlXPathFreeObject(hay);
  xmlXPathFreeObject(needle);
}


/* xmlXPathFunction to select nodes whose local name matches, for HTML5 CSS queries that should
 * ignore namespaces */
static void
noko_xml_xpath_context_xpath_func_local_name_is(xmlXPathParserContextPtr ctxt, int nargs)
{
  xmlXPathObjectPtr element_name;

  assert(ctxt->context->node);

  CHECK_ARITY(1);
  CAST_TO_STRING;
  CHECK_TYPE(XPATH_STRING);
  element_name = valuePop(ctxt);

  valuePush(
    ctxt,
    xmlXPathNewBoolean(xmlStrEqual(ctxt->context->node->name, element_name->stringval))
  );

  xmlXPathFreeObject(element_name);
}


/*
 * call-seq:
 *   register_ns(prefix, uri) → Nokogiri::XML::XPathContext
 *
 * Register the namespace with +prefix+ and +uri+ for use in future queries.
 * Passing a uri of +nil+ will unregister the namespace.
 *
 * [Returns] +self+
 */
static VALUE
noko_xml_xpath_context_register_ns(VALUE rb_context, VALUE prefix, VALUE uri)
{
  xmlXPathContextPtr c_context;
  const xmlChar *ns_uri;

  TypedData_Get_Struct(rb_context, xmlXPathContext, &_noko_xml_xpath_context_type, c_context);

  if (NIL_P(uri)) {
    ns_uri = NULL;
  } else {
    ns_uri = (const xmlChar *)StringValueCStr(uri);
  }

  xmlXPathRegisterNs(c_context, (const xmlChar *)StringValueCStr(prefix), ns_uri);

  return rb_context;
}

/*
 * call-seq:
 *   register_variable(name, value) → Nokogiri::XML::XPathContext
 *
 * Register the variable +name+ with +value+ for use in future queries.
 * Passing a value of +nil+ will unregister the variable.
 *
 * [Returns] +self+
 */
static VALUE
noko_xml_xpath_context_register_variable(VALUE rb_context, VALUE name, VALUE value)
{
  xmlXPathContextPtr c_context;
  xmlXPathObjectPtr xmlValue;

  TypedData_Get_Struct(rb_context, xmlXPathContext, &_noko_xml_xpath_context_type, c_context);

  if (NIL_P(value)) {
    xmlValue = NULL;
  } else {
    xmlValue = xmlXPathNewCString(StringValueCStr(value));
  }

  xmlXPathRegisterVariable(c_context, (const xmlChar *)StringValueCStr(name), xmlValue);

  return rb_context;
}


/*
 *  convert an XPath object into a Ruby object of the appropriate type.
 *  returns Qundef if no conversion was possible.
 */
static VALUE
_noko_xml_xpath_context__xpath2ruby(xmlXPathObjectPtr c_xpath_object, xmlXPathContextPtr c_context)
{
  VALUE rb_retval;

  assert(c_context->doc);
  assert(DOC_RUBY_OBJECT_TEST(c_context->doc));

  switch (c_xpath_object->type) {
    case XPATH_STRING:
      rb_retval = NOKOGIRI_STR_NEW2(c_xpath_object->stringval);
      xmlFree(c_xpath_object->stringval);
      return rb_retval;

    case XPATH_NODESET:
      return noko_xml_node_set_wrap(
               c_xpath_object->nodesetval,
               DOC_RUBY_OBJECT(c_context->doc)
             );

    case XPATH_NUMBER:
      return rb_float_new(c_xpath_object->floatval);

    case XPATH_BOOLEAN:
      return (c_xpath_object->boolval == 1) ? Qtrue : Qfalse;

    default:
      return Qundef;
  }
}

void
Nokogiri_marshal_xpath_funcall_and_return_values(
  xmlXPathParserContextPtr ctxt,
  int argc,
  VALUE rb_xpath_handler,
  const char *method_name
)
{
  VALUE rb_retval;
  VALUE *argv;
  VALUE rb_node_set = Qnil;
  xmlNodeSetPtr c_node_set = NULL;
  xmlXPathObjectPtr c_xpath_object;

  assert(ctxt->context->doc);
  assert(DOC_RUBY_OBJECT_TEST(ctxt->context->doc));

  argv = (VALUE *)ruby_xcalloc((size_t)argc, sizeof(VALUE));
  for (int j = 0 ; j < argc ; ++j) {
    rb_gc_register_address(&argv[j]);
  }

  for (int j = argc - 1 ; j >= 0 ; --j) {
    c_xpath_object = valuePop(ctxt);
    argv[j] = _noko_xml_xpath_context__xpath2ruby(c_xpath_object, ctxt->context);
    if (argv[j] == Qundef) {
      argv[j] = NOKOGIRI_STR_NEW2(xmlXPathCastToString(c_xpath_object));
    }
    xmlXPathFreeNodeSetList(c_xpath_object);
  }

  rb_retval = rb_funcall2(
                rb_xpath_handler,
                rb_intern((const char *)method_name),
                argc,
                argv
              );

  for (int j = 0 ; j < argc ; ++j) {
    rb_gc_unregister_address(&argv[j]);
  }
  ruby_xfree(argv);

  switch (TYPE(rb_retval)) {
    case T_FLOAT:
    case T_BIGNUM:
    case T_FIXNUM:
      xmlXPathReturnNumber(ctxt, NUM2DBL(rb_retval));
      break;
    case T_STRING:
      xmlXPathReturnString(ctxt, xmlCharStrdup(StringValueCStr(rb_retval)));
      break;
    case T_TRUE:
      xmlXPathReturnTrue(ctxt);
      break;
    case T_FALSE:
      xmlXPathReturnFalse(ctxt);
      break;
    case T_NIL:
      break;
    case T_ARRAY: {
      VALUE construct_args[2] = { DOC_RUBY_OBJECT(ctxt->context->doc), rb_retval };
      rb_node_set = rb_class_new_instance(2, construct_args, cNokogiriXmlNodeSet);
      c_node_set = noko_xml_node_set_unwrap(rb_node_set);
      xmlXPathReturnNodeSet(ctxt, xmlXPathNodeSetMerge(NULL, c_node_set));
    }
    break;
    case T_DATA:
      if (rb_obj_is_kind_of(rb_retval, cNokogiriXmlNodeSet)) {
        c_node_set = noko_xml_node_set_unwrap(rb_retval);
        /* Copy the node set, otherwise it will get GC'd. */
        xmlXPathReturnNodeSet(ctxt, xmlXPathNodeSetMerge(NULL, c_node_set));
        break;
      }
    default:
      rb_raise(rb_eRuntimeError, "Invalid return type");
  }
}

static void
_noko_xml_xpath_context__handler_invoker(xmlXPathParserContextPtr ctxt, int argc)
{
  VALUE rb_xpath_handler = Qnil;
  const char *method_name = NULL ;

  assert(ctxt);
  assert(ctxt->context);
  assert(ctxt->context->userData);
  assert(ctxt->context->function);

  rb_xpath_handler = (VALUE)(ctxt->context->userData);
  method_name = (const char *)(ctxt->context->function);

  Nokogiri_marshal_xpath_funcall_and_return_values(
    ctxt,
    argc,
    rb_xpath_handler,
    method_name
  );
}

static xmlXPathFunction
_noko_xml_xpath_context_handler_lookup(void *data, const xmlChar *c_name, const xmlChar *c_ns_uri)
{
  VALUE rb_handler = (VALUE)data;
  if (rb_respond_to(rb_handler, rb_intern((const char *)c_name))) {
    if (c_ns_uri == NULL) {
      NOKO_WARN_DEPRECATION("A custom XPath or CSS handler function named '%s' is being invoked without a namespace. Please update your query to reference this function as 'nokogiri:%s'. Invoking custom handler functions without a namespace is deprecated and will become an error in Nokogiri v1.17.0.",
                            c_name, c_name); // TODO deprecated in v1.15.0, remove in v1.19.0
    }
    return _noko_xml_xpath_context__handler_invoker;
  }

  return NULL;
}

PRINTFLIKE_DECL(2, 3)
static void
_noko_xml_xpath_context__generic_exception_pusher(void *data, const char *msg, ...)
{
  VALUE rb_errors = (VALUE)data;
  VALUE rb_message;
  VALUE rb_exception;

  Check_Type(rb_errors, T_ARRAY);

#ifdef TRUFFLERUBY_NOKOGIRI_SYSTEM_LIBRARIES
  /* It is not currently possible to pass var args from native
     functions to sulong, so we work around the issue here. */
  rb_message = rb_sprintf("_noko_xml_xpath_context__generic_exception_pusher: %s", msg);
#else
  va_list args;
  va_start(args, msg);
  rb_message = rb_vsprintf(msg, args);
  va_end(args);
#endif

  rb_exception = rb_exc_new_str(cNokogiriXmlXpathSyntaxError, rb_message);
  rb_ary_push(rb_errors, rb_exception);
}

/*
 * call-seq:
 *   evaluate(search_path, handler = nil) → Object
 *
 * Evaluate the +search_path+ query.
 *
 * [Returns] an object of the appropriate type for the query, which could be +NodeSet+, a +String+,
 * a +Float+, or a boolean.
 */
static VALUE
noko_xml_xpath_context_evaluate(int argc, VALUE *argv, VALUE rb_context)
{
  xmlXPathContextPtr c_context;
  VALUE rb_expression = Qnil;
  VALUE rb_function_lookup_handler = Qnil;
  xmlChar *c_expression_str = NULL;
  VALUE rb_errors = rb_ary_new();
  xmlXPathObjectPtr c_xpath_object;
  VALUE rb_xpath_object = Qnil;

  TypedData_Get_Struct(rb_context, xmlXPathContext, &_noko_xml_xpath_context_type, c_context);

  rb_scan_args(argc, argv, "11", &rb_expression, &rb_function_lookup_handler);

  c_expression_str = (xmlChar *)StringValueCStr(rb_expression);

  if (Qnil != rb_function_lookup_handler) {
    /* FIXME: not sure if this is the correct place to shove private data. */
    c_context->userData = (void *)rb_function_lookup_handler;
    xmlXPathRegisterFuncLookup(
      c_context,
      _noko_xml_xpath_context_handler_lookup,
      (void *)rb_function_lookup_handler
    );
  }

  /* TODO: use xmlXPathSetErrorHandler (as of 2.13.0) */
  xmlSetStructuredErrorFunc((void *)rb_errors, noko__error_array_pusher);
  xmlSetGenericErrorFunc((void *)rb_errors, _noko_xml_xpath_context__generic_exception_pusher);

  c_xpath_object = xmlXPathEvalExpression(c_expression_str, c_context);

  xmlSetStructuredErrorFunc(NULL, NULL);
  xmlSetGenericErrorFunc(NULL, NULL);

  xmlXPathRegisterFuncLookup(c_context, NULL, NULL);

  if (c_xpath_object == NULL) {
    rb_exc_raise(rb_ary_entry(rb_errors, 0));
  }

  rb_xpath_object = _noko_xml_xpath_context__xpath2ruby(c_xpath_object, c_context);
  if (rb_xpath_object == Qundef) {
    rb_xpath_object = noko_xml_node_set_wrap(NULL, DOC_RUBY_OBJECT(c_context->doc));
  }

  xmlXPathFreeNodeSetList(c_xpath_object);

  return rb_xpath_object;
}

/*
 * call-seq:
 *   new(node)
 *
 * Create a new XPathContext with +node+ as the context node.
 */
static VALUE
noko_xml_xpath_context_new(VALUE klass, VALUE rb_node)
{
  xmlNodePtr c_node;
  xmlXPathContextPtr c_context;
  VALUE rb_context;

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

#if LIBXML_VERSION < 21000
  xmlXPathInit(); /* deprecated in 40483d0 */
#endif

  c_context = xmlXPathNewContext(c_node->doc);
  c_context->node = c_node;

  xmlXPathRegisterNs(c_context, NOKOGIRI_PREFIX, NOKOGIRI_URI);
  xmlXPathRegisterNs(c_context, NOKOGIRI_BUILTIN_PREFIX, NOKOGIRI_BUILTIN_URI);

  xmlXPathRegisterFuncNS(c_context,
                         (const xmlChar *)"css-class", NOKOGIRI_BUILTIN_URI,
                         noko_xml_xpath_context_xpath_func_css_class);
  xmlXPathRegisterFuncNS(c_context,
                         (const xmlChar *)"local-name-is", NOKOGIRI_BUILTIN_URI,
                         noko_xml_xpath_context_xpath_func_local_name_is);

  rb_context = TypedData_Wrap_Struct(klass, &_noko_xml_xpath_context_type, c_context);

  return rb_context;
}


/* :nodoc: */
static VALUE
noko_xml_xpath_context_set_node(VALUE rb_context, VALUE rb_node)
{
  xmlNodePtr c_node;
  xmlXPathContextPtr c_context;

  TypedData_Get_Struct(rb_context, xmlXPathContext, &_noko_xml_xpath_context_type, c_context);
  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  c_context->doc = c_node->doc;
  c_context->node = c_node;

  return rb_node;
}

void
noko_init_xml_xpath_context(void)
{
  /*
   * XPathContext is the entry point for searching a +Document+ by using XPath.
   */
  cNokogiriXmlXpathContext = rb_define_class_under(mNokogiriXml, "XPathContext", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlXpathContext);

  rb_define_singleton_method(cNokogiriXmlXpathContext, "new", noko_xml_xpath_context_new, 1);

  rb_define_method(cNokogiriXmlXpathContext, "evaluate", noko_xml_xpath_context_evaluate, -1);
  rb_define_method(cNokogiriXmlXpathContext, "register_variable", noko_xml_xpath_context_register_variable, 2);
  rb_define_method(cNokogiriXmlXpathContext, "register_ns", noko_xml_xpath_context_register_ns, 2);
  rb_define_method(cNokogiriXmlXpathContext, "node=", noko_xml_xpath_context_set_node, 1);
}
