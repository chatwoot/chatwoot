#include <nokogiri.h>

VALUE cNokogiriHtml4Document ;

static ID id_encoding_found;
static ID id_to_s;

/*
 * call-seq:
 *  new(uri=nil, external_id=nil) → HTML4::Document
 *
 * Create a new empty document with base URI +uri+ and external ID +external_id+.
 */
static VALUE
rb_html_document_s_new(int argc, VALUE *argv, VALUE klass)
{
  VALUE uri, external_id, rest, rb_doc;
  htmlDocPtr doc;

  rb_scan_args(argc, argv, "0*", &rest);
  uri = rb_ary_entry(rest, (long)0);
  external_id = rb_ary_entry(rest, (long)1);

  doc = htmlNewDoc(
          RTEST(uri) ? (const xmlChar *)StringValueCStr(uri) : NULL,
          RTEST(external_id) ? (const xmlChar *)StringValueCStr(external_id) : NULL
        );
  rb_doc = noko_xml_document_wrap_with_init_args(klass, doc, argc, argv);
  return rb_doc ;
}

/*
 * call-seq:
 *  read_io(io, url, encoding, options)
 *
 * Read the HTML document from +io+ with given +url+, +encoding+,
 * and +options+.  See Nokogiri::HTML4.parse
 */
static VALUE
rb_html_document_s_read_io(VALUE klass, VALUE rb_io, VALUE rb_url, VALUE rb_encoding, VALUE rb_options)
{
  VALUE rb_doc;
  VALUE rb_error_list = rb_ary_new();
  htmlDocPtr c_doc;
  const char *c_url = NIL_P(rb_url) ? NULL : StringValueCStr(rb_url);
  const char *c_encoding = NIL_P(rb_encoding) ? NULL : StringValueCStr(rb_encoding);
  int options = NUM2INT(rb_options);

  xmlSetStructuredErrorFunc((void *)rb_error_list, noko__error_array_pusher);

  c_doc = htmlReadIO(noko_io_read, noko_io_close, (void *)rb_io, c_url, c_encoding, options);

  xmlSetStructuredErrorFunc(NULL, NULL);

  /*
   * If EncodingFound has occurred in EncodingReader, make sure to do
   * a cleanup and propagate the error.
   */
  if (rb_respond_to(rb_io, id_encoding_found)) {
    VALUE encoding_found = rb_funcall(rb_io, id_encoding_found, 0);
    if (!NIL_P(encoding_found)) {
      xmlFreeDoc(c_doc);
      rb_exc_raise(encoding_found);
    }
  }

  if ((c_doc == NULL) || (!(options & XML_PARSE_RECOVER) && (RARRAY_LEN(rb_error_list) > 0))) {
    VALUE rb_error ;

    xmlFreeDoc(c_doc);

    rb_error = rb_ary_entry(rb_error_list, 0);
    if (rb_error == Qnil) {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    } else {
      VALUE exception_message = rb_funcall(rb_error, id_to_s, 0);
      exception_message = rb_str_concat(rb_str_new2("Parser without recover option encountered error or warning: "),
                                        exception_message);
      rb_exc_raise(rb_class_new_instance(1, &exception_message, cNokogiriXmlSyntaxError));
    }

    return Qnil;
  }

  rb_doc = noko_xml_document_wrap(klass, c_doc);
  rb_iv_set(rb_doc, "@errors", rb_error_list);
  return rb_doc;
}

/*
 * call-seq:
 *  read_memory(string, url, encoding, options)
 *
 * Read the HTML document contained in +string+ with given +url+, +encoding+,
 * and +options+.  See Nokogiri::HTML4.parse
 */
static VALUE
rb_html_document_s_read_memory(VALUE klass, VALUE rb_html, VALUE rb_url, VALUE rb_encoding, VALUE rb_options)
{
  VALUE rb_doc;
  VALUE rb_error_list = rb_ary_new();
  htmlDocPtr c_doc;
  const char *c_buffer = StringValuePtr(rb_html);
  const char *c_url = NIL_P(rb_url) ? NULL : StringValueCStr(rb_url);
  const char *c_encoding = NIL_P(rb_encoding) ? NULL : StringValueCStr(rb_encoding);
  int html_len = (int)RSTRING_LEN(rb_html);
  int options = NUM2INT(rb_options);

  xmlSetStructuredErrorFunc((void *)rb_error_list, noko__error_array_pusher);

  c_doc = htmlReadMemory(c_buffer, html_len, c_url, c_encoding, options);

  xmlSetStructuredErrorFunc(NULL, NULL);

  if ((c_doc == NULL) || (!(options & XML_PARSE_RECOVER) && (RARRAY_LEN(rb_error_list) > 0))) {
    VALUE rb_error ;

    xmlFreeDoc(c_doc);

    rb_error = rb_ary_entry(rb_error_list, 0);
    if (rb_error == Qnil) {
      rb_raise(rb_eRuntimeError, "Could not parse document");
    } else {
      VALUE exception_message = rb_funcall(rb_error, id_to_s, 0);
      exception_message = rb_str_concat(rb_str_new2("Parser without recover option encountered error or warning: "),
                                        exception_message);
      rb_exc_raise(rb_class_new_instance(1, &exception_message, cNokogiriXmlSyntaxError));
    }

    return Qnil;
  }

  rb_doc = noko_xml_document_wrap(klass, c_doc);
  rb_iv_set(rb_doc, "@errors", rb_error_list);
  return rb_doc;
}

/*
 * call-seq:
 *  type
 *
 * The type for this document
 */
static VALUE
rb_html_document_type(VALUE self)
{
  htmlDocPtr doc = noko_xml_document_unwrap(self);
  return INT2NUM(doc->type);
}

void
noko_init_html_document(void)
{
  /* this is here so that rdoc doesn't ignore this file. */
  /*
    mNokogiri         = rb_define_module("Nokogiri");
    mNokogiriHtml4    = rb_define_module_under(mNokogiri, "HTML4");
  */

  assert(cNokogiriXmlDocument);
  cNokogiriHtml4Document = rb_define_class_under(mNokogiriHtml4, "Document", cNokogiriXmlDocument);

  rb_define_singleton_method(cNokogiriHtml4Document, "read_memory", rb_html_document_s_read_memory, 4);
  rb_define_singleton_method(cNokogiriHtml4Document, "read_io", rb_html_document_s_read_io, 4);
  rb_define_singleton_method(cNokogiriHtml4Document, "new", rb_html_document_s_new, -1);

  rb_define_method(cNokogiriHtml4Document, "type", rb_html_document_type, 0);

  id_encoding_found = rb_intern("encoding_found");
  id_to_s = rb_intern("to_s");
}
