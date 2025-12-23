#ifndef NOKOGIRI_NATIVE
#define NOKOGIRI_NATIVE

#include <ruby/defines.h> // https://github.com/sparklemotion/nokogiri/issues/2696

#ifdef _MSC_VER
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif /* WIN32_LEAN_AND_MEAN */

#  ifndef WIN32
#    define WIN32
#  endif /* WIN32 */

#  include <winsock2.h>
#  include <ws2tcpip.h>
#  include <windows.h>
#endif

#ifdef _WIN32
#  define NOKOPUBFUN __declspec(dllexport)
#  define NOKOPUBVAR __declspec(dllexport) extern
#else
#  define NOKOPUBFUN
#  define NOKOPUBVAR extern
#endif

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>


#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/entities.h>
#include <libxml/xpath.h>
#include <libxml/xmlreader.h>
#include <libxml/xmlsave.h>
#include <libxml/xmlschemas.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>
#include <libxml/relaxng.h>
#include <libxml/xinclude.h>
#include <libxml/c14n.h>
#include <libxml/parserInternals.h>
#include <libxml/xpathInternals.h>

#include <libxslt/extensions.h>
#include <libxslt/xsltconfig.h>
#include <libxslt/xsltutils.h>
#include <libxslt/transform.h>
#include <libxslt/imports.h>
#include <libxslt/xsltInternals.h>

#include <libexslt/exslt.h>

/* libxml2_polyfill.c */
#ifndef HAVE_XMLCTXTSETOPTIONS
int xmlCtxtSetOptions(xmlParserCtxtPtr ctxt, int options);
#endif
#ifndef HAVE_XMLCTXTGETOPTIONS
int xmlCtxtGetOptions(xmlParserCtxtPtr ctxt);
#endif
#ifndef HAVE_XMLSWITCHENCODINGNAME
int xmlSwitchEncodingName(xmlParserCtxtPtr ctxt, const char *encoding);
#endif

#define XMLNS_PREFIX "xmlns"
#define XMLNS_PREFIX_LEN 6 /* including either colon or \0 */

#ifndef xmlErrorConstPtr
#  if LIBXML_VERSION >= 21200
#    define xmlErrorConstPtr const xmlError *
#  else
#    define xmlErrorConstPtr xmlError *
#  endif
#endif

#include <ruby.h>
#include <ruby/st.h>
#include <ruby/encoding.h>
#include <ruby/util.h>
#include <ruby/version.h>

#define NOKOGIRI_STR_NEW2(str) NOKOGIRI_STR_NEW(str, strlen((const char *)(str)))
#define NOKOGIRI_STR_NEW(str, len) rb_external_str_new_with_enc((const char *)(str), (long)(len), rb_utf8_encoding())
#define RBSTR_OR_QNIL(_str) (_str ? NOKOGIRI_STR_NEW2(_str) : Qnil)

#ifndef NORETURN_DECL
#  if defined(__GNUC__)
#    define NORETURN_DECL __attribute__ ((noreturn))
#  else
#    define NORETURN_DECL
#  endif
#endif

#ifndef PRINTFLIKE_DECL
#  if defined(__GNUC__)
#    define PRINTFLIKE_DECL(stringidx, argidx) __attribute__ ((format(printf,stringidx,argidx)))
#  else
#    define PRINTFLIKE_DECL(stringidx, argidx)
#  endif
#endif

#if defined(TRUFFLERUBY) && !defined(NOKOGIRI_PACKAGED_LIBRARIES)
#  define TRUFFLERUBY_NOKOGIRI_SYSTEM_LIBRARIES
#endif

NOKOPUBVAR VALUE mNokogiri ;
NOKOPUBVAR VALUE mNokogiriGumbo ;
NOKOPUBVAR VALUE mNokogiriHtml4 ;
NOKOPUBVAR VALUE mNokogiriHtml4Sax ;
NOKOPUBVAR VALUE mNokogiriHtml5 ;
NOKOPUBVAR VALUE mNokogiriXml ;
NOKOPUBVAR VALUE mNokogiriXmlSax ;
NOKOPUBVAR VALUE mNokogiriXmlXpath ;
NOKOPUBVAR VALUE mNokogiriXslt ;

NOKOPUBVAR VALUE cNokogiriEncodingHandler;
NOKOPUBVAR VALUE cNokogiriSyntaxError;
NOKOPUBVAR VALUE cNokogiriXmlAttr;
NOKOPUBVAR VALUE cNokogiriXmlAttributeDecl;
NOKOPUBVAR VALUE cNokogiriXmlCData;
NOKOPUBVAR VALUE cNokogiriXmlCharacterData;
NOKOPUBVAR VALUE cNokogiriXmlComment;
NOKOPUBVAR VALUE cNokogiriXmlDocument ;
NOKOPUBVAR VALUE cNokogiriXmlDocumentFragment;
NOKOPUBVAR VALUE cNokogiriXmlDtd;
NOKOPUBVAR VALUE cNokogiriXmlElement ;
NOKOPUBVAR VALUE cNokogiriXmlElementContent;
NOKOPUBVAR VALUE cNokogiriXmlElementDecl;
NOKOPUBVAR VALUE cNokogiriXmlEntityDecl;
NOKOPUBVAR VALUE cNokogiriXmlEntityReference;
NOKOPUBVAR VALUE cNokogiriXmlNamespace ;
NOKOPUBVAR VALUE cNokogiriXmlNode ;
NOKOPUBVAR VALUE cNokogiriXmlNodeSet ;
NOKOPUBVAR VALUE cNokogiriXmlProcessingInstruction;
NOKOPUBVAR VALUE cNokogiriXmlReader;
NOKOPUBVAR VALUE cNokogiriXmlRelaxNG;
NOKOPUBVAR VALUE cNokogiriXmlSaxParser ;
NOKOPUBVAR VALUE cNokogiriXmlSaxParserContext;
NOKOPUBVAR VALUE cNokogiriXmlSaxPushParser ;
NOKOPUBVAR VALUE cNokogiriXmlSchema;
NOKOPUBVAR VALUE cNokogiriXmlSyntaxError;
NOKOPUBVAR VALUE cNokogiriXmlText ;
NOKOPUBVAR VALUE cNokogiriXmlXpathContext;
NOKOPUBVAR VALUE cNokogiriXmlXpathSyntaxError;
NOKOPUBVAR VALUE cNokogiriXsltStylesheet ;

NOKOPUBVAR VALUE cNokogiriHtml4Document ;
NOKOPUBVAR VALUE cNokogiriHtml4SaxPushParser ;
NOKOPUBVAR VALUE cNokogiriHtml4ElementDescription ;
NOKOPUBVAR VALUE cNokogiriHtml4SaxParser;
NOKOPUBVAR VALUE cNokogiriHtml4SaxParserContext;
NOKOPUBVAR VALUE cNokogiriHtml5Document ;

typedef struct _nokogiriTuple {
  VALUE         doc;
  st_table     *unlinkedNodes;
  VALUE         node_cache;
} nokogiriTuple;
typedef nokogiriTuple *nokogiriTuplePtr;

typedef struct _libxmlStructuredErrorHandlerState {
  void *user_data;
  xmlStructuredErrorFunc handler;
} libxmlStructuredErrorHandlerState ;

typedef struct _nokogiriXsltStylesheetTuple {
  xsltStylesheetPtr ss;
  VALUE func_instances;
} nokogiriXsltStylesheetTuple;

void noko_xml_document_pin_node(xmlNodePtr);
void noko_xml_document_pin_namespace(xmlNsPtr, xmlDocPtr);
int noko_xml_document_has_wrapped_blank_nodes_p(xmlDocPtr c_document);

int noko_io_read(void *ctx, char *buffer, int len);
int noko_io_write(void *ctx, char *buffer, int len);
int noko_io_close(void *ctx);

#define Noko_Node_Get_Struct(obj,type,sval) ((sval) = (type*)DATA_PTR(obj))
#define Noko_Namespace_Get_Struct(obj,type,sval) ((sval) = (type*)DATA_PTR(obj))

VALUE noko_xml_node_wrap(VALUE klass, xmlNodePtr node) ;
VALUE noko_xml_node_wrap_node_set_result(xmlNodePtr node, VALUE node_set) ;
VALUE noko_xml_node_attrs(xmlNodePtr node) ;

VALUE noko_xml_namespace_wrap(xmlNsPtr node, xmlDocPtr doc);
VALUE noko_xml_namespace_wrap_xpath_copy(xmlNsPtr node);

VALUE noko_xml_element_content_wrap(VALUE doc, xmlElementContentPtr element);

VALUE noko_xml_node_set_wrap(xmlNodeSetPtr node_set, VALUE document) ;
xmlNodeSetPtr noko_xml_node_set_unwrap(VALUE rb_node_set) ;

VALUE noko_xml_document_wrap_with_init_args(VALUE klass, xmlDocPtr doc, int argc, VALUE *argv);
VALUE noko_xml_document_wrap(VALUE klass, xmlDocPtr doc);
xmlDocPtr noko_xml_document_unwrap(VALUE rb_document);
NOKOPUBFUN VALUE Nokogiri_wrap_xml_document(VALUE klass,
    xmlDocPtr doc); /* deprecated. use noko_xml_document_wrap() instead. */

xmlSAXHandlerPtr noko_xml_sax_parser_unwrap(VALUE rb_sax_handler);

xmlParserCtxtPtr noko_xml_sax_push_parser_unwrap(VALUE rb_parser);

VALUE noko_xml_sax_parser_context_wrap(VALUE klass, xmlParserCtxtPtr c_context);
xmlParserCtxtPtr noko_xml_sax_parser_context_unwrap(VALUE rb_context);
void noko_xml_sax_parser_context_set_encoding(xmlParserCtxtPtr c_context, VALUE rb_encoding);

#define DOC_RUBY_OBJECT_TEST(x) ((nokogiriTuplePtr)(x->_private))
#define DOC_RUBY_OBJECT(x) (((nokogiriTuplePtr)(x->_private))->doc)
#define DOC_UNLINKED_NODE_HASH(x) (((nokogiriTuplePtr)(x->_private))->unlinkedNodes)
#define DOC_NODE_CACHE(x) (((nokogiriTuplePtr)(x->_private))->node_cache)
#define NOKOGIRI_NAMESPACE_EH(node) ((node)->type == XML_NAMESPACE_DECL)

#define DISCARD_CONST_QUAL(t, v) ((t)(uintptr_t)(v))
#define DISCARD_CONST_QUAL_XMLCHAR(v) DISCARD_CONST_QUAL(xmlChar *, v)

#if HAVE_RB_CATEGORY_WARNING
#  define NOKO_WARN_DEPRECATION(message...) rb_category_warning(RB_WARN_CATEGORY_DEPRECATED, message)
#else
#  define NOKO_WARN_DEPRECATION(message...) rb_warning(message)
#endif

void noko__structured_error_func_save(libxmlStructuredErrorHandlerState *handler_state);
void noko__structured_error_func_save_and_set(libxmlStructuredErrorHandlerState *handler_state, void *user_data,
    xmlStructuredErrorFunc handler);
void noko__structured_error_func_restore(libxmlStructuredErrorHandlerState *handler_state);
VALUE noko_xml_syntax_error__wrap(xmlErrorConstPtr error);
void noko__error_array_pusher(void *ctx, xmlErrorConstPtr error);
NORETURN_DECL void noko__error_raise(void *ctx, xmlErrorConstPtr error);
void Nokogiri_marshal_xpath_funcall_and_return_values(xmlXPathParserContextPtr ctx, int nargs, VALUE handler,
    const char *function_name) ;

#endif /* NOKOGIRI_NATIVE */
