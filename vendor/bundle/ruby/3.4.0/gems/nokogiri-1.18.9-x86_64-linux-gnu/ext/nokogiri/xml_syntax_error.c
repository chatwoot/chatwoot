#include <nokogiri.h>

VALUE cNokogiriXmlSyntaxError;

void
noko__structured_error_func_save(libxmlStructuredErrorHandlerState *handler_state)
{
  /* this method is tightly coupled to the implementation of xmlSetStructuredErrorFunc */
  handler_state->user_data = xmlStructuredErrorContext;
  handler_state->handler = xmlStructuredError;
}

void
noko__structured_error_func_save_and_set(
  libxmlStructuredErrorHandlerState *handler_state,
  void *user_data,
  xmlStructuredErrorFunc handler
)
{
  noko__structured_error_func_save(handler_state);
  xmlSetStructuredErrorFunc(user_data, handler);
}

void
noko__structured_error_func_restore(libxmlStructuredErrorHandlerState *handler_state)
{
  xmlSetStructuredErrorFunc(handler_state->user_data, handler_state->handler);
}

void
noko__error_array_pusher(void *ctx, xmlErrorConstPtr error)
{
  VALUE list = (VALUE)ctx;
  Check_Type(list, T_ARRAY);
  rb_ary_push(list,  noko_xml_syntax_error__wrap(error));
}

void
noko__error_raise(void *ctx, xmlErrorConstPtr error)
{
  rb_exc_raise(noko_xml_syntax_error__wrap(error));
}

VALUE
noko_xml_syntax_error__wrap(xmlErrorConstPtr error)
{
  xmlChar *c_path ;
  VALUE msg, e, klass;

  klass = cNokogiriXmlSyntaxError;

  if (error && error->domain == XML_FROM_XPATH) {
    klass = cNokogiriXmlXpathSyntaxError;
  }

  msg = (error && error->message) ? NOKOGIRI_STR_NEW2(error->message) : Qnil;

  e = rb_class_new_instance(
        1,
        &msg,
        klass
      );

  if (error) {
    c_path = xmlGetNodePath(error->node);

    rb_iv_set(e, "@domain", INT2NUM(error->domain));
    rb_iv_set(e, "@code", INT2NUM(error->code));
    rb_iv_set(e, "@level", INT2NUM((short)error->level));
    rb_iv_set(e, "@file", RBSTR_OR_QNIL(error->file));
    rb_iv_set(e, "@line", INT2NUM(error->line));
    rb_iv_set(e, "@path", RBSTR_OR_QNIL(c_path));
    rb_iv_set(e, "@str1", RBSTR_OR_QNIL(error->str1));
    rb_iv_set(e, "@str2", RBSTR_OR_QNIL(error->str2));
    rb_iv_set(e, "@str3", RBSTR_OR_QNIL(error->str3));
    rb_iv_set(e, "@int1", INT2NUM(error->int1));
    rb_iv_set(e, "@column", INT2NUM(error->int2));

    xmlFree(c_path);
  }

  return e;
}

void
noko_init_xml_syntax_error(void)
{
  assert(cNokogiriSyntaxError);
  /*
   * The XML::SyntaxError is raised on parse errors
   */
  cNokogiriXmlSyntaxError = rb_define_class_under(mNokogiriXml, "SyntaxError", cNokogiriSyntaxError);
}
