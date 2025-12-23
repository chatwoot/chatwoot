#include <nokogiri.h>

/*
 *  The lifecycle of a Namespace node is more complicated than other Nodes, for two reasons:
 *
 *  1. the underlying C structure has a different layout than all the other node structs, with the
 *     `_private` member where we store a pointer to Ruby object data not being in first position.
 *  2. xmlNs structures returned in an xmlNodeset from an XPath query are copies of the document's
 *     namespaces, and so do not share the same memory lifecycle as everything else in a document.
 *
 *  As a result of 1, you may see special handling of XML_NAMESPACE_DECL node types throughout the
 *  Nokogiri C code, though I intend to wrap up that logic in ruby_object_{get,set} functions
 *  shortly.
 *
 *  As a result of 2, you will see we have special handling in this file and in xml_node_set.c to
 *  carefully manage the memory lifecycle of xmlNs structs to match the Ruby object's GC
 *  lifecycle. In xml_node_set.c we have local versions of xmlXPathNodeSetDel() and
 *  xmlXPathFreeNodeSet() that avoid freeing xmlNs structs in the node set. In this file, we decide
 *  whether or not to call dealloc_namespace() depending on whether the xmlNs struct appears to be
 *  in an xmlNodeSet (and thus the result of an XPath query) or not.
 *
 *  Yes, this is madness.
 */

VALUE cNokogiriXmlNamespace ;

static void
_xml_namespace_dealloc(void *ptr)
{
  /*
   * this deallocator is only used for namespace nodes that are part of an xpath
   * node set. see noko_xml_namespace_wrap().
   */
  xmlNsPtr ns = ptr;

  if (ns->href) {
    xmlFree(DISCARD_CONST_QUAL_XMLCHAR(ns->href));
  }
  if (ns->prefix) {
    xmlFree(DISCARD_CONST_QUAL_XMLCHAR(ns->prefix));
  }
  xmlFree(ns);
}

static void
_xml_namespace_update_references(void *ptr)
{
  xmlNsPtr ns = ptr;
  if (ns->_private) {
    ns->_private = (void *)rb_gc_location((VALUE)ns->_private);
  }
}

static const rb_data_type_t xml_ns_type_with_free = {
  .wrap_struct_name = "xmlNs (with free)",
  .function = {
    .dfree = _xml_namespace_dealloc,
    .dcompact = _xml_namespace_update_references,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static const rb_data_type_t xml_ns_type_without_free = {
  .wrap_struct_name = "xmlNs (without free)",
  .function = {
    .dcompact = _xml_namespace_update_references,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 *  :call-seq:
 *    prefix() → String or nil
 *
 *  Return the prefix for this Namespace, or +nil+ if there is no prefix (e.g., default namespace).
 *
 *  *Example*
 *
 *    doc = Nokogiri::XML.parse(<<~XML)
 *      <?xml version="1.0"?>
 *      <root xmlns="http://nokogiri.org/ns/default" xmlns:noko="http://nokogiri.org/ns/noko">
 *        <child1 foo="abc" noko:bar="def"/>
 *        <noko:child2 foo="qwe" noko:bar="rty"/>
 *      </root>
 *    XML
 *
 *    doc.root.elements.first.namespace.prefix
 *    # => nil
 *
 *    doc.root.elements.last.namespace.prefix
 *    # => "noko"
 */
static VALUE
prefix(VALUE self)
{
  xmlNsPtr ns;

  Noko_Namespace_Get_Struct(self, xmlNs, ns);
  if (!ns->prefix) { return Qnil; }

  return NOKOGIRI_STR_NEW2(ns->prefix);
}

/*
 *  :call-seq:
 *    href() → String
 *
 *  Returns the URI reference for this Namespace.
 *
 *  *Example*
 *
 *    doc = Nokogiri::XML.parse(<<~XML)
 *      <?xml version="1.0"?>
 *      <root xmlns="http://nokogiri.org/ns/default" xmlns:noko="http://nokogiri.org/ns/noko">
 *        <child1 foo="abc" noko:bar="def"/>
 *        <noko:child2 foo="qwe" noko:bar="rty"/>
 *      </root>
 *    XML
 *
 *    doc.root.elements.first.namespace.href
 *    # => "http://nokogiri.org/ns/default"
 *
 *    doc.root.elements.last.namespace.href
 *    # => "http://nokogiri.org/ns/noko"
 */
static VALUE
href(VALUE self)
{
  xmlNsPtr ns;

  Noko_Namespace_Get_Struct(self, xmlNs, ns);
  if (!ns->href) { return Qnil; }

  return NOKOGIRI_STR_NEW2(ns->href);
}

VALUE
noko_xml_namespace_wrap(xmlNsPtr c_namespace, xmlDocPtr c_document)
{
  VALUE rb_namespace;

  if (c_namespace->_private) {
    return (VALUE)c_namespace->_private;
  }

  if (c_document) {
    rb_namespace = TypedData_Wrap_Struct(cNokogiriXmlNamespace,
                                         &xml_ns_type_without_free,
                                         c_namespace);

    if (DOC_RUBY_OBJECT_TEST(c_document)) {
      rb_iv_set(rb_namespace, "@document", DOC_RUBY_OBJECT(c_document));
      rb_ary_push(DOC_NODE_CACHE(c_document), rb_namespace);
    }
  } else {
    rb_namespace = TypedData_Wrap_Struct(cNokogiriXmlNamespace,
                                         &xml_ns_type_with_free,
                                         c_namespace);
  }

  c_namespace->_private = (void *)rb_namespace;

  return rb_namespace;
}

VALUE
noko_xml_namespace_wrap_xpath_copy(xmlNsPtr c_namespace)
{
  return noko_xml_namespace_wrap(c_namespace, NULL);
}

void
noko_init_xml_namespace(void)
{
  cNokogiriXmlNamespace = rb_define_class_under(mNokogiriXml, "Namespace", rb_cObject);

  rb_undef_alloc_func(cNokogiriXmlNamespace);

  rb_define_method(cNokogiriXmlNamespace, "prefix", prefix, 0);
  rb_define_method(cNokogiriXmlNamespace, "href", href, 0);
}
