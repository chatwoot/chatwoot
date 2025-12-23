#include <nokogiri.h>

#include <stdbool.h>

// :stopdoc:

VALUE cNokogiriXmlNode ;
static ID id_decorate, id_decorate_bang;

typedef xmlNodePtr(*pivot_reparentee_func)(xmlNodePtr, xmlNodePtr);

static void
_xml_node_mark(void *ptr)
{
  xmlNodePtr node = ptr;

  if (!DOC_RUBY_OBJECT_TEST(node->doc)) {
    return;
  }

  xmlDocPtr doc = node->doc;
  if (doc->type == XML_DOCUMENT_NODE || doc->type == XML_HTML_DOCUMENT_NODE) {
    if (DOC_RUBY_OBJECT_TEST(doc)) {
      rb_gc_mark(DOC_RUBY_OBJECT(doc));
    }
  } else if (node->doc->_private) {
    rb_gc_mark((VALUE)doc->_private);
  }
}

static void
_xml_node_update_references(void *ptr)
{
  xmlNodePtr node = ptr;

  if (node->_private) {
    node->_private = (void *)rb_gc_location((VALUE)node->_private);
  }
}

static const rb_data_type_t xml_node_type = {
  .wrap_struct_name = "xmlNode",
  .function = {
    .dmark = _xml_node_mark,
    .dcompact = _xml_node_update_references,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE
_xml_node_alloc(VALUE klass)
{
  return TypedData_Wrap_Struct(klass, &xml_node_type, NULL);
}

static void
_xml_node_data_ptr_set(VALUE rb_node, xmlNodePtr c_node)
{
  assert(DATA_PTR(rb_node) == NULL);
  assert(c_node->_private == NULL);

  DATA_PTR(rb_node) = c_node;
  c_node->_private = (void *)rb_node;

  return;
}

static void
relink_namespace(xmlNodePtr reparented)
{
  xmlNodePtr child;
  xmlAttrPtr attr;

  if (reparented->type != XML_ATTRIBUTE_NODE &&
      reparented->type != XML_ELEMENT_NODE) { return; }

  if (reparented->ns == NULL || reparented->ns->prefix == NULL) {
    xmlNsPtr ns = NULL;
    xmlChar *name = NULL, *prefix = NULL;

    name = xmlSplitQName2(reparented->name, &prefix);

    if (reparented->type == XML_ATTRIBUTE_NODE) {
      if (prefix == NULL || strcmp((char *)prefix, XMLNS_PREFIX) == 0) {
        xmlFree(name);
        xmlFree(prefix);
        return;
      }
    }

    ns = xmlSearchNs(reparented->doc, reparented, prefix);

    if (ns != NULL) {
      xmlNodeSetName(reparented, name);
      xmlSetNs(reparented, ns);
    }

    xmlFree(name);
    xmlFree(prefix);
  }

  /* Avoid segv when relinking against unlinked nodes. */
  if (reparented->type != XML_ELEMENT_NODE || !reparented->parent) { return; }

  /* Make sure that our reparented node has the correct namespaces */
  if (!reparented->ns &&
      (reparented->doc != (xmlDocPtr)reparented->parent) &&
      (rb_iv_get(DOC_RUBY_OBJECT(reparented->doc), "@namespace_inheritance") == Qtrue)) {
    xmlSetNs(reparented, reparented->parent->ns);
  }

  /* Search our parents for an existing definition */
  if (reparented->nsDef) {
    xmlNsPtr curr = reparented->nsDef;
    xmlNsPtr prev = NULL;

    while (curr) {
      xmlNsPtr ns = xmlSearchNsByHref(
                      reparented->doc,
                      reparented->parent,
                      curr->href
                    );
      /* If we find the namespace is already declared, remove it from this
       * definition list. */
      if (ns && ns != curr && xmlStrEqual(ns->prefix, curr->prefix)) {
        if (prev) {
          prev->next = curr->next;
        } else {
          reparented->nsDef = curr->next;
        }
        noko_xml_document_pin_namespace(curr, reparented->doc);
      } else {
        prev = curr;
      }
      curr = curr->next;
    }
  }

  /*
   *  Search our parents for an existing definition of current namespace,
   *  because the definition it's pointing to may have just been removed nsDef.
   *
   *  And although that would technically probably be OK, I'd feel better if we
   *  referred to a namespace that's still present in a node's nsDef somewhere
   *  in the doc.
   */
  if (reparented->ns) {
    xmlNsPtr ns = xmlSearchNs(reparented->doc, reparented, reparented->ns->prefix);
    if (ns
        && ns != reparented->ns
        && xmlStrEqual(ns->prefix, reparented->ns->prefix)
        && xmlStrEqual(ns->href, reparented->ns->href)
       ) {
      xmlSetNs(reparented, ns);
    }
  }

  /* Only walk all children if there actually is a namespace we need to */
  /* reparent. */
  if (NULL == reparented->ns) { return; }

  /* When a node gets reparented, walk its children to make sure that */
  /* their namespaces are reparented as well. */
  child = reparented->children;
  while (NULL != child) {
    relink_namespace(child);
    child = child->next;
  }

  if (reparented->type == XML_ELEMENT_NODE) {
    attr = reparented->properties;
    while (NULL != attr) {
      relink_namespace((xmlNodePtr)attr);
      attr = attr->next;
    }
  }
}


/* internal function meant to wrap xmlReplaceNode
   and fix some issues we have with libxml2 merging nodes */
static xmlNodePtr
xmlReplaceNodeWrapper(xmlNodePtr pivot, xmlNodePtr new_node)
{
  xmlNodePtr retval ;

  retval = xmlReplaceNode(pivot, new_node) ;

  if (retval == pivot) {
    retval = new_node ; /* return semantics for reparent_node_with */
  }

  /* work around libxml2 issue: https://bugzilla.gnome.org/show_bug.cgi?id=615612 */
  if (retval && retval->type == XML_TEXT_NODE) {
    if (retval->prev && retval->prev->type == XML_TEXT_NODE) {
      retval = xmlTextMerge(retval->prev, retval);
    }
    if (retval->next && retval->next->type == XML_TEXT_NODE) {
      retval = xmlTextMerge(retval, retval->next);
    }
  }

  return retval ;
}


static void
raise_if_ancestor_of_self(xmlNodePtr self)
{
  for (xmlNodePtr ancestor = self->parent ; ancestor ; ancestor = ancestor->parent) {
    if (self == ancestor) {
      rb_raise(rb_eRuntimeError, "cycle detected: node '%s' is an ancestor of itself", self->name);
    }
  }
}


static VALUE
reparent_node_with(VALUE pivot_obj, VALUE reparentee_obj, pivot_reparentee_func prf)
{
  VALUE reparented_obj ;
  xmlNodePtr reparentee, original_reparentee, pivot, reparented, next_text, new_next_text, parent ;
  int original_ns_prefix_is_default = 0 ;

  if (!rb_obj_is_kind_of(reparentee_obj, cNokogiriXmlNode)) {
    rb_raise(rb_eArgError, "node must be a Nokogiri::XML::Node");
  }
  if (rb_obj_is_kind_of(reparentee_obj, cNokogiriXmlDocument)) {
    rb_raise(rb_eArgError, "node must be a Nokogiri::XML::Node");
  }

  Noko_Node_Get_Struct(reparentee_obj, xmlNode, reparentee);
  Noko_Node_Get_Struct(pivot_obj, xmlNode, pivot);

  /*
   * Check if nodes given are appropriate to have a parent-child
   * relationship, based on the DOM specification.
   *
   * cf. http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-1590626202
   */
  if (prf == xmlAddChild) {
    parent = pivot;
  } else {
    parent = pivot->parent;
  }

  if (parent) {
    switch (parent->type) {
      case XML_DOCUMENT_NODE:
      case XML_HTML_DOCUMENT_NODE:
        switch (reparentee->type) {
          case XML_ELEMENT_NODE:
          case XML_PI_NODE:
          case XML_COMMENT_NODE:
          case XML_DOCUMENT_TYPE_NODE:
          /*
           * The DOM specification says no to adding text-like nodes
           * directly to a document, but we allow it for compatibility.
           */
          case XML_TEXT_NODE:
          case XML_CDATA_SECTION_NODE:
          case XML_ENTITY_REF_NODE:
            goto ok;
          default:
            break;
        }
        break;
      case XML_DOCUMENT_FRAG_NODE:
      case XML_ENTITY_REF_NODE:
      case XML_ELEMENT_NODE:
        switch (reparentee->type) {
          case XML_ELEMENT_NODE:
          case XML_PI_NODE:
          case XML_COMMENT_NODE:
          case XML_TEXT_NODE:
          case XML_CDATA_SECTION_NODE:
          case XML_ENTITY_REF_NODE:
            goto ok;
          default:
            break;
        }
        break;
      case XML_ATTRIBUTE_NODE:
        switch (reparentee->type) {
          case XML_TEXT_NODE:
          case XML_ENTITY_REF_NODE:
            goto ok;
          default:
            break;
        }
        break;
      case XML_TEXT_NODE:
        /*
         * xmlAddChild() breaks the DOM specification in that it allows
         * adding a text node to another, in which case text nodes are
         * coalesced, but since our JRuby version does not support such
         * operation, we should inhibit it.
         */
        break;
      default:
        break;
    }

    rb_raise(rb_eArgError, "cannot reparent %s there", rb_obj_classname(reparentee_obj));
  }

ok:
  original_reparentee = reparentee;

  if (reparentee->doc != pivot->doc || reparentee->type == XML_TEXT_NODE) {
    /*
     *  if the reparentee is a text node, there's a very good chance it will be
     *  merged with an adjacent text node after being reparented, and in that case
     *  libxml will free the underlying C struct.
     *
     *  since we clearly have a ruby object which references the underlying
     *  memory, we can't let the C struct get freed. let's pickle the original
     *  reparentee by rooting it; and then we'll reparent a duplicate of the
     *  node that we don't care about preserving.
     *
     *  alternatively, if the reparentee is from a different document than the
     *  pivot node, libxml2 is going to get confused about which document's
     *  "dictionary" the node's strings belong to (this is an otherwise
     *  uninteresting libxml2 implementation detail). as a result, we cannot
     *  reparent the actual reparentee, so we reparent a duplicate.
     */
    if (reparentee->type == XML_TEXT_NODE && reparentee->_private) {
      /*
       *  additionally, since we know this C struct isn't going to be related to
       *  a Ruby object anymore, let's break the relationship on this end as
       *  well.
       *
       *  this is not absolutely necessary unless libxml-ruby is also in effect,
       *  in which case its global callback `rxml_node_deregisterNode` will try
       *  to do things to our data.
       *
       *  for more details on this particular (and particularly nasty) edge
       *  case, see:
       *
       *    https://github.com/sparklemotion/nokogiri/issues/1426
       */
      reparentee->_private = NULL ;
    }

    if (reparentee->ns != NULL && reparentee->ns->prefix == NULL) {
      original_ns_prefix_is_default = 1;
    }

    noko_xml_document_pin_node(reparentee);

    if (!(reparentee = xmlDocCopyNode(reparentee, pivot->doc, 1))) {
      rb_raise(rb_eRuntimeError, "Could not reparent node (xmlDocCopyNode)");
    }

    if (original_ns_prefix_is_default && reparentee->ns != NULL && reparentee->ns->prefix != NULL) {
      /*
       *  issue #391, where new node's prefix may become the string "default"
       *  see libxml2 tree.c xmlNewReconciliedNs which implements this behavior.
       */
      xmlFree(DISCARD_CONST_QUAL_XMLCHAR(reparentee->ns->prefix));
      reparentee->ns->prefix = NULL;
    }
  }

  xmlUnlinkNode(original_reparentee);

  if (prf != xmlAddPrevSibling && prf != xmlAddNextSibling && prf != xmlAddChild
      && reparentee->type == XML_TEXT_NODE && pivot->next && pivot->next->type == XML_TEXT_NODE) {
    /*
     *  libxml merges text nodes in a right-to-left fashion, meaning that if
     *  there are two text nodes who would be adjacent, the right (or following,
     *  or next) node will be merged into the left (or preceding, or previous)
     *  node.
     *
     *  and by "merged" I mean the string contents will be concatenated onto the
     *  left node's contents, and then the node will be freed.
     *
     *  which means that if we have a ruby object wrapped around the right node,
     *  its memory would be freed out from under it.
     *
     *  so, we detect this edge case and unlink-and-root the text node before it gets
     *  merged. then we dup the node and insert that duplicate back into the
     *  document where the real node was.
     *
     *  yes, this is totally lame.
     */
    next_text     = pivot->next ;
    new_next_text = xmlDocCopyNode(next_text, pivot->doc, 1) ;

    xmlUnlinkNode(next_text);
    noko_xml_document_pin_node(next_text);

    xmlAddNextSibling(pivot, new_next_text);
  }

  if (!(reparented = (*prf)(pivot, reparentee))) {
    rb_raise(rb_eRuntimeError, "Could not reparent node");
  }

  /*
   *  make sure the ruby object is pointed at the just-reparented node, which
   *  might be a duplicate (see above) or might be the result of merging
   *  adjacent text nodes.
   */
  DATA_PTR(reparentee_obj) = reparented ;
  reparented_obj = noko_xml_node_wrap(Qnil, reparented);

  rb_funcall(reparented_obj, id_decorate_bang, 0);

  /* if we've created a cycle, raise an exception */
  raise_if_ancestor_of_self(reparented);

  relink_namespace(reparented);

  return reparented_obj ;
}

// :startdoc:

/*
 * :call-seq:
 *   add_namespace_definition(prefix, href) → Nokogiri::XML::Namespace
 *   add_namespace(prefix, href) → Nokogiri::XML::Namespace
 *
 * :category: Manipulating Document Structure
 *
 * Adds a namespace definition to this node with +prefix+ using +href+ value, as if this node had
 * included an attribute "xmlns:prefix=href".
 *
 * A default namespace definition for this node can be added by passing +nil+ for +prefix+.
 *
 * [Parameters]
 * - +prefix+ (String, +nil+) An {XML Name}[https://www.w3.org/TR/xml-names/#ns-decl]
 * - +href+ (String) The {URI reference}[https://www.w3.org/TR/xml-names/#sec-namespaces]
 *
 * [Returns] The new Nokogiri::XML::Namespace
 *
 * *Example:* adding a non-default namespace definition
 *
 *   doc = Nokogiri::XML("<store><inventory></inventory></store>")
 *   inventory = doc.at_css("inventory")
 *   inventory.add_namespace_definition("automobile", "http://alices-autos.com/")
 *   inventory.add_namespace_definition("bicycle", "http://bobs-bikes.com/")
 *   inventory.add_child("<automobile:tire>Michelin model XGV, size 75R</automobile:tire>")
 *   doc.to_xml
 *   # => "<?xml version=\"1.0\"?>\n" +
 *   #    "<store>\n" +
 *   #    "  <inventory xmlns:automobile=\"http://alices-autos.com/\" xmlns:bicycle=\"http://bobs-bikes.com/\">\n" +
 *   #    "    <automobile:tire>Michelin model XGV, size 75R</automobile:tire>\n" +
 *   #    "  </inventory>\n" +
 *   #    "</store>\n"
 *
 * *Example:* adding a default namespace definition
 *
 *   doc = Nokogiri::XML("<store><inventory><tire>Michelin model XGV, size 75R</tire></inventory></store>")
 *   doc.at_css("tire").add_namespace_definition(nil, "http://bobs-bikes.com/")
 *   doc.to_xml
 *   # => "<?xml version=\"1.0\"?>\n" +
 *   #    "<store>\n" +
 *   #    "  <inventory>\n" +
 *   #    "    <tire xmlns=\"http://bobs-bikes.com/\">Michelin model XGV, size 75R</tire>\n" +
 *   #    "  </inventory>\n" +
 *   #    "</store>\n"
 *
 */
static VALUE
rb_xml_node_add_namespace_definition(VALUE rb_node, VALUE rb_prefix, VALUE rb_href)
{
  xmlNodePtr c_node, element;
  xmlNsPtr c_namespace;
  const xmlChar *c_prefix = (const xmlChar *)(NIL_P(rb_prefix) ? NULL : StringValueCStr(rb_prefix));

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);
  element = c_node ;

  c_namespace = xmlSearchNs(c_node->doc, c_node, c_prefix);

  if (!c_namespace) {
    if (c_node->type != XML_ELEMENT_NODE) {
      element = c_node->parent;
    }
    c_namespace = xmlNewNs(element, (const xmlChar *)StringValueCStr(rb_href), c_prefix);
  }

  if (!c_namespace) {
    return Qnil ;
  }

  if (NIL_P(rb_prefix) || c_node != element) {
    xmlSetNs(c_node, c_namespace);
  }

  return noko_xml_namespace_wrap(c_namespace, c_node->doc);
}


/*
 * :call-seq: attribute(name) → Nokogiri::XML::Attr
 *
 * :category: Working With Node Attributes
 *
 * [Returns] Attribute (Nokogiri::XML::Attr) belonging to this node with name +name+.
 *
 * ⚠ Note that attribute namespaces are ignored and only the simple (non-namespace-prefixed) name is
 * used to find a matching attribute. In case of a simple name collision, only one of the matching
 * attributes will be returned. In this case, you will need to use #attribute_with_ns.
 *
 * *Example:*
 *
 *   doc = Nokogiri::XML("<root><child size='large' class='big wide tall'/></root>")
 *   child = doc.at_css("child")
 *   child.attribute("size") # => #<Nokogiri::XML::Attr:0x550 name="size" value="large">
 *   child.attribute("class") # => #<Nokogiri::XML::Attr:0x564 name="class" value="big wide tall">
 *
 * *Example* showing that namespaced attributes will not be returned:
 *
 * ⚠ Note that only one of the two matching attributes is returned.
 *
 *   doc = Nokogiri::XML(<<~EOF)
 *     <root xmlns:width='http://example.com/widths'
 *           xmlns:height='http://example.com/heights'>
 *       <child width:size='broad' height:size='tall'/>
 *     </root>
 *   EOF
 *   doc.at_css("child").attribute("size")
 *   # => #(Attr:0x550 {
 *   #      name = "size",
 *   #      namespace = #(Namespace:0x564 {
 *   #        prefix = "width",
 *   #        href = "http://example.com/widths"
 *   #        }),
 *   #      value = "broad"
 *   #      })
 */
static VALUE
rb_xml_node_attribute(VALUE self, VALUE name)
{
  xmlNodePtr node;
  xmlAttrPtr prop;
  Noko_Node_Get_Struct(self, xmlNode, node);
  prop = xmlHasProp(node, (xmlChar *)StringValueCStr(name));

  if (! prop) { return Qnil; }
  return noko_xml_node_wrap(Qnil, (xmlNodePtr)prop);
}


/*
 * :call-seq: attribute_nodes() → Array<Nokogiri::XML::Attr>
 *
 * :category: Working With Node Attributes
 *
 * [Returns] Attributes (an Array of Nokogiri::XML::Attr) belonging to this node.
 *
 * Note that this is the preferred alternative to #attributes when the simple
 * (non-namespace-prefixed) attribute names may collide.
 *
 * *Example:*
 *
 * Contrast this with the colliding-name example from #attributes.
 *
 *   doc = Nokogiri::XML(<<~EOF)
 *     <root xmlns:width='http://example.com/widths'
 *           xmlns:height='http://example.com/heights'>
 *       <child width:size='broad' height:size='tall'/>
 *     </root>
 *   EOF
 *   doc.at_css("child").attribute_nodes
 *   # => [#(Attr:0x550 {
 *   #       name = "size",
 *   #       namespace = #(Namespace:0x564 {
 *   #         prefix = "width",
 *   #         href = "http://example.com/widths"
 *   #         }),
 *   #       value = "broad"
 *   #       }),
 *   #     #(Attr:0x578 {
 *   #       name = "size",
 *   #       namespace = #(Namespace:0x58c {
 *   #         prefix = "height",
 *   #         href = "http://example.com/heights"
 *   #         }),
 *   #       value = "tall"
 *   #       })]
 */
static VALUE
rb_xml_node_attribute_nodes(VALUE rb_node)
{
  xmlNodePtr c_node;

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  return noko_xml_node_attrs(c_node);
}


/*
 * :call-seq: attribute_with_ns(name, namespace) → Nokogiri::XML::Attr
 *
 * :category: Working With Node Attributes
 *
 * [Returns]
 *   Attribute (Nokogiri::XML::Attr) belonging to this node with matching +name+ and +namespace+.
 *
 * [Parameters]
 * - +name+ (String): the simple (non-namespace-prefixed) name of the attribute
 * - +namespace+ (String): the URI of the attribute's namespace
 *
 * See related: #attribute
 *
 * *Example:*
 *
 *   doc = Nokogiri::XML(<<~EOF)
 *     <root xmlns:width='http://example.com/widths'
 *           xmlns:height='http://example.com/heights'>
 *       <child width:size='broad' height:size='tall'/>
 *     </root>
 *   EOF
 *   doc.at_css("child").attribute_with_ns("size", "http://example.com/widths")
 *   # => #(Attr:0x550 {
 *   #      name = "size",
 *   #      namespace = #(Namespace:0x564 {
 *   #        prefix = "width",
 *   #        href = "http://example.com/widths"
 *   #        }),
 *   #      value = "broad"
 *   #      })
 *   doc.at_css("child").attribute_with_ns("size", "http://example.com/heights")
 *   # => #(Attr:0x578 {
 *   #      name = "size",
 *   #      namespace = #(Namespace:0x58c {
 *   #        prefix = "height",
 *   #        href = "http://example.com/heights"
 *   #        }),
 *   #      value = "tall"
 *   #      })
 */
static VALUE
rb_xml_node_attribute_with_ns(VALUE self, VALUE name, VALUE namespace)
{
  xmlNodePtr node;
  xmlAttrPtr prop;
  Noko_Node_Get_Struct(self, xmlNode, node);
  prop = xmlHasNsProp(node, (xmlChar *)StringValueCStr(name),
                      NIL_P(namespace) ? NULL : (xmlChar *)StringValueCStr(namespace));

  if (! prop) { return Qnil; }
  return noko_xml_node_wrap(Qnil, (xmlNodePtr)prop);
}



/*
 * call-seq: blank? → Boolean
 *
 * [Returns] +true+ if the node is an empty or whitespace-only text or cdata node, else +false+.
 *
 * *Example:*
 *
 *     Nokogiri("<root><child/></root>").root.child.blank? # => false
 *     Nokogiri("<root>\t \n</root>").root.child.blank? # => true
 *     Nokogiri("<root><![CDATA[\t \n]]></root>").root.child.blank? # => true
 *     Nokogiri("<root>not-blank</root>").root.child
 *       .tap { |n| n.content = "" }.blank # => true
 */
static VALUE
rb_xml_node_blank_eh(VALUE self)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  return (1 == xmlIsBlankNode(node)) ? Qtrue : Qfalse ;
}


/*
 * :call-seq: child() → Nokogiri::XML::Node
 *
 * :category: Traversing Document Structure
 *
 * [Returns] First of this node's children, or +nil+ if there are no children
 *
 * This is a convenience method and is equivalent to:
 *
 *   node.children.first
 *
 * See related: #children
 */
static VALUE
rb_xml_node_child(VALUE self)
{
  xmlNodePtr node, child;
  Noko_Node_Get_Struct(self, xmlNode, node);

  child = node->children;
  if (!child) { return Qnil; }

  return noko_xml_node_wrap(Qnil, child);
}


/*
 * :call-seq: children() → Nokogiri::XML::NodeSet
 *
 * :category: Traversing Document Structure
 *
 * [Returns] Nokogiri::XML::NodeSet containing this node's children.
 */
static VALUE
rb_xml_node_children(VALUE self)
{
  xmlNodePtr node;
  xmlNodePtr child;
  xmlNodeSetPtr set;
  VALUE document;
  VALUE node_set;

  Noko_Node_Get_Struct(self, xmlNode, node);

  child = node->children;
  set = xmlXPathNodeSetCreate(child);

  document = DOC_RUBY_OBJECT(node->doc);

  if (!child) { return noko_xml_node_set_wrap(set, document); }

  child = child->next;
  while (NULL != child) {
    xmlXPathNodeSetAddUnique(set, child);
    child = child->next;
  }

  node_set = noko_xml_node_set_wrap(set, document);

  return node_set;
}


/*
 * :call-seq:
 *   content() → String
 *   inner_text() → String
 *   text() → String
 *   to_str() → String
 *
 * [Returns]
 *   Contents of all the text nodes in this node's subtree, concatenated together into a single
 *   String.
 *
 * ⚠ Note that entities will _always_ be expanded in the returned String.
 *
 * See related: #inner_html
 *
 * *Example* of how entities are handled:
 *
 * Note that <tt>&lt;</tt> becomes <tt><</tt> in the returned String.
 *
 *   doc = Nokogiri::XML.fragment("<child>a &lt; b</child>")
 *   doc.at_css("child").content
 *   # => "a < b"
 *
 * *Example* of how a subtree is handled:
 *
 * Note that the <tt><span></tt> tags are omitted and only the text node contents are returned,
 * concatenated into a single string.
 *
 *   doc = Nokogiri::XML.fragment("<child><span>first</span> <span>second</span></child>")
 *   doc.at_css("child").content
 *   # => "first second"
 */
static VALUE
rb_xml_node_content(VALUE self)
{
  xmlNodePtr node;
  xmlChar *content;

  Noko_Node_Get_Struct(self, xmlNode, node);

  content = xmlNodeGetContent(node);
  if (content) {
    VALUE rval = NOKOGIRI_STR_NEW2(content);
    xmlFree(content);
    return rval;
  }
  return Qnil;
}


/*
 * :call-seq: document() → Nokogiri::XML::Document
 *
 * :category: Traversing Document Structure
 *
 * [Returns] Parent Nokogiri::XML::Document for this node
 */
static VALUE
rb_xml_node_document(VALUE self)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  return DOC_RUBY_OBJECT(node->doc);
}

/*
 * :call-seq: pointer_id() → Integer
 *
 * [Returns]
 *   A unique id for this node based on the internal memory structures. This method is used by #==
 *   to determine node identity.
 */
static VALUE
rb_xml_node_pointer_id(VALUE self)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);

  return rb_uint2inum((uintptr_t)(node));
}

/*
 * :call-seq: encode_special_chars(string) → String
 *
 * Encode any special characters in +string+
 */
static VALUE
encode_special_chars(VALUE self, VALUE string)
{
  xmlNodePtr node;
  xmlChar *encoded;
  VALUE encoded_str;

  Noko_Node_Get_Struct(self, xmlNode, node);
  encoded = xmlEncodeSpecialChars(
              node->doc,
              (const xmlChar *)StringValueCStr(string)
            );

  encoded_str = NOKOGIRI_STR_NEW2(encoded);
  xmlFree(encoded);

  return encoded_str;
}

/*
 * :call-seq:
 *   create_internal_subset(name, external_id, system_id)
 *
 * Create the internal subset of a document.
 *
 *   doc.create_internal_subset("chapter", "-//OASIS//DTD DocBook XML//EN", "chapter.dtd")
 *   # => <!DOCTYPE chapter PUBLIC "-//OASIS//DTD DocBook XML//EN" "chapter.dtd">
 *
 *   doc.create_internal_subset("chapter", nil, "chapter.dtd")
 *   # => <!DOCTYPE chapter SYSTEM "chapter.dtd">
 */
static VALUE
create_internal_subset(VALUE self, VALUE name, VALUE external_id, VALUE system_id)
{
  xmlNodePtr node;
  xmlDocPtr doc;
  xmlDtdPtr dtd;

  Noko_Node_Get_Struct(self, xmlNode, node);

  doc = node->doc;

  if (xmlGetIntSubset(doc)) {
    rb_raise(rb_eRuntimeError, "Document already has an internal subset");
  }

  dtd = xmlCreateIntSubset(
          doc,
          NIL_P(name)        ? NULL : (const xmlChar *)StringValueCStr(name),
          NIL_P(external_id) ? NULL : (const xmlChar *)StringValueCStr(external_id),
          NIL_P(system_id)   ? NULL : (const xmlChar *)StringValueCStr(system_id)
        );

  if (!dtd) { return Qnil; }

  return noko_xml_node_wrap(Qnil, (xmlNodePtr)dtd);
}

/*
 * :call-seq:
 *   create_external_subset(name, external_id, system_id)
 *
 * Create an external subset
 */
static VALUE
create_external_subset(VALUE self, VALUE name, VALUE external_id, VALUE system_id)
{
  xmlNodePtr node;
  xmlDocPtr doc;
  xmlDtdPtr dtd;

  Noko_Node_Get_Struct(self, xmlNode, node);

  doc = node->doc;

  if (doc->extSubset) {
    rb_raise(rb_eRuntimeError, "Document already has an external subset");
  }

  dtd = xmlNewDtd(
          doc,
          NIL_P(name)        ? NULL : (const xmlChar *)StringValueCStr(name),
          NIL_P(external_id) ? NULL : (const xmlChar *)StringValueCStr(external_id),
          NIL_P(system_id)   ? NULL : (const xmlChar *)StringValueCStr(system_id)
        );

  if (!dtd) { return Qnil; }

  return noko_xml_node_wrap(Qnil, (xmlNodePtr)dtd);
}

/*
 * :call-seq:
 *   external_subset()
 *
 * Get the external subset
 */
static VALUE
external_subset(VALUE self)
{
  xmlNodePtr node;
  xmlDocPtr doc;
  xmlDtdPtr dtd;

  Noko_Node_Get_Struct(self, xmlNode, node);

  if (!node->doc) { return Qnil; }

  doc = node->doc;
  dtd = doc->extSubset;

  if (!dtd) { return Qnil; }

  return noko_xml_node_wrap(Qnil, (xmlNodePtr)dtd);
}

/*
 * :call-seq:
 *   internal_subset()
 *
 * Get the internal subset
 */
static VALUE
internal_subset(VALUE self)
{
  xmlNodePtr node;
  xmlDocPtr doc;
  xmlDtdPtr dtd;

  Noko_Node_Get_Struct(self, xmlNode, node);

  if (!node->doc) { return Qnil; }

  doc = node->doc;
  dtd = xmlGetIntSubset(doc);

  if (!dtd) { return Qnil; }

  return noko_xml_node_wrap(Qnil, (xmlNodePtr)dtd);
}

/* :nodoc: */
static VALUE
rb_xml_node_initialize_copy_with_args(VALUE rb_self, VALUE rb_other, VALUE rb_level, VALUE rb_new_parent_doc)
{
  xmlNodePtr c_self, c_other;
  int c_level;
  xmlDocPtr c_new_parent_doc;
  VALUE rb_node_cache;

  Noko_Node_Get_Struct(rb_other, xmlNode, c_other);
  c_level = (int)NUM2INT(rb_level);
  c_new_parent_doc = noko_xml_document_unwrap(rb_new_parent_doc);

  c_self = xmlDocCopyNode(c_other, c_new_parent_doc, c_level);
  if (c_self == NULL) { return Qnil; }

  _xml_node_data_ptr_set(rb_self, c_self);
  noko_xml_document_pin_node(c_self);

  rb_node_cache = DOC_NODE_CACHE(c_new_parent_doc);
  rb_ary_push(rb_node_cache, rb_self);
  rb_funcall(rb_new_parent_doc, id_decorate, 1, rb_self);

  return rb_self;
}

/*
 * :call-seq:
 *   unlink() → self
 *
 * Unlink this node from its current context.
 */
static VALUE
unlink_node(VALUE self)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  xmlUnlinkNode(node);
  noko_xml_document_pin_node(node);
  return self;
}


/*
 * call-seq:
 *  next_sibling
 *
 * Returns the next sibling node
 */
static VALUE
next_sibling(VALUE self)
{
  xmlNodePtr node, sibling;
  Noko_Node_Get_Struct(self, xmlNode, node);

  sibling = node->next;
  if (!sibling) { return Qnil; }

  return noko_xml_node_wrap(Qnil, sibling) ;
}

/*
 * call-seq:
 *  previous_sibling
 *
 * Returns the previous sibling node
 */
static VALUE
previous_sibling(VALUE self)
{
  xmlNodePtr node, sibling;
  Noko_Node_Get_Struct(self, xmlNode, node);

  sibling = node->prev;
  if (!sibling) { return Qnil; }

  return noko_xml_node_wrap(Qnil, sibling);
}

/*
 * call-seq:
 *  next_element
 *
 * Returns the next Nokogiri::XML::Element type sibling node.
 */
static VALUE
next_element(VALUE self)
{
  xmlNodePtr node, sibling;
  Noko_Node_Get_Struct(self, xmlNode, node);

  sibling = xmlNextElementSibling(node);
  if (!sibling) { return Qnil; }

  return noko_xml_node_wrap(Qnil, sibling);
}

/*
 * call-seq:
 *  previous_element
 *
 * Returns the previous Nokogiri::XML::Element type sibling node.
 */
static VALUE
previous_element(VALUE self)
{
  xmlNodePtr node, sibling;
  Noko_Node_Get_Struct(self, xmlNode, node);

  sibling = xmlPreviousElementSibling(node);
  if (!sibling) { return Qnil; }

  return noko_xml_node_wrap(Qnil, sibling);
}

/* :nodoc: */
static VALUE
replace(VALUE self, VALUE new_node)
{
  VALUE reparent = reparent_node_with(self, new_node, xmlReplaceNodeWrapper);

  xmlNodePtr pivot;
  Noko_Node_Get_Struct(self, xmlNode, pivot);
  noko_xml_document_pin_node(pivot);

  return reparent;
}

/*
 * :call-seq:
 *   element_children() → NodeSet
 *   elements() → NodeSet
 *
 * [Returns]
 *   The node's child elements as a NodeSet. Only children that are elements will be returned, which
 *   notably excludes Text nodes.
 *
 * *Example:*
 *
 * Note that #children returns the Text node "hello" while #element_children does not.
 *
 *   div = Nokogiri::HTML5("<div>hello<span>world</span>").at_css("div")
 *   div.element_children
 *   # => [#<Nokogiri::XML::Element:0x50 name="span" children=[#<Nokogiri::XML::Text:0x3c "world">]>]
 *   div.children
 *   # => [#<Nokogiri::XML::Text:0x64 "hello">,
 *   #     #<Nokogiri::XML::Element:0x50 name="span" children=[#<Nokogiri::XML::Text:0x3c "world">]>]
 */
static VALUE
rb_xml_node_element_children(VALUE self)
{
  xmlNodePtr node;
  xmlNodePtr child;
  xmlNodeSetPtr set;
  VALUE document;
  VALUE node_set;

  Noko_Node_Get_Struct(self, xmlNode, node);

  child = xmlFirstElementChild(node);
  set = xmlXPathNodeSetCreate(child);

  document = DOC_RUBY_OBJECT(node->doc);

  if (!child) { return noko_xml_node_set_wrap(set, document); }

  child = xmlNextElementSibling(child);
  while (NULL != child) {
    xmlXPathNodeSetAddUnique(set, child);
    child = xmlNextElementSibling(child);
  }

  node_set = noko_xml_node_set_wrap(set, document);

  return node_set;
}

/*
 * :call-seq:
 *   first_element_child() → Node
 *
 * [Returns] The first child Node that is an element.
 *
 * *Example:*
 *
 * Note that the "hello" child, which is a Text node, is skipped and the <tt><span></tt> element is
 * returned.
 *
 *   div = Nokogiri::HTML5("<div>hello<span>world</span>").at_css("div")
 *   div.first_element_child
 *   # => #(Element:0x3c { name = "span", children = [ #(Text "world")] })
 */
static VALUE
rb_xml_node_first_element_child(VALUE self)
{
  xmlNodePtr node, child;
  Noko_Node_Get_Struct(self, xmlNode, node);

  child = xmlFirstElementChild(node);
  if (!child) { return Qnil; }

  return noko_xml_node_wrap(Qnil, child);
}

/*
 * :call-seq:
 *   last_element_child() → Node
 *
 * [Returns] The last child Node that is an element.
 *
 * *Example:*
 *
 * Note that the "hello" child, which is a Text node, is skipped and the <tt><span>yes</span></tt>
 * element is returned.
 *
 *   div = Nokogiri::HTML5("<div><span>no</span><span>yes</span>skip</div>").at_css("div")
 *   div.last_element_child
 *   # => #(Element:0x3c { name = "span", children = [ #(Text "yes")] })
 */
static VALUE
rb_xml_node_last_element_child(VALUE self)
{
  xmlNodePtr node, child;
  Noko_Node_Get_Struct(self, xmlNode, node);

  child = xmlLastElementChild(node);
  if (!child) { return Qnil; }

  return noko_xml_node_wrap(Qnil, child);
}

/*
 * call-seq:
 *  key?(attribute)
 *
 * Returns true if +attribute+ is set
 */
static VALUE
key_eh(VALUE self, VALUE attribute)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  if (xmlHasProp(node, (xmlChar *)StringValueCStr(attribute))) {
    return Qtrue;
  }
  return Qfalse;
}

/*
 * call-seq:
 *  namespaced_key?(attribute, namespace)
 *
 * Returns true if +attribute+ is set with +namespace+
 */
static VALUE
namespaced_key_eh(VALUE self, VALUE attribute, VALUE namespace)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  if (xmlHasNsProp(node, (xmlChar *)StringValueCStr(attribute),
                   NIL_P(namespace) ? NULL : (xmlChar *)StringValueCStr(namespace))) {
    return Qtrue;
  }
  return Qfalse;
}

/*
 * call-seq:
 *  []=(property, value)
 *
 * Set the +property+ to +value+
 */
static VALUE
set(VALUE self, VALUE property, VALUE value)
{
  xmlNodePtr node, cur;
  xmlAttrPtr prop;
  Noko_Node_Get_Struct(self, xmlNode, node);

  /* If a matching attribute node already exists, then xmlSetProp will destroy
   * the existing node's children. However, if Nokogiri has a node object
   * pointing to one of those children, we are left with a broken reference.
   *
   * We can avoid this by unlinking these nodes first.
   */
  if (node->type != XML_ELEMENT_NODE) {
    return (Qnil);
  }
  prop = xmlHasProp(node, (xmlChar *)StringValueCStr(property));
  if (prop && prop->children) {
    for (cur = prop->children; cur; cur = cur->next) {
      if (cur->_private) {
        noko_xml_document_pin_node(cur);
        xmlUnlinkNode(cur);
      }
    }
  }

  xmlSetProp(node, (xmlChar *)StringValueCStr(property),
             (xmlChar *)StringValueCStr(value));

  return value;
}

/*
 * call-seq:
 *   get(attribute)
 *
 * Get the value for +attribute+
 */
static VALUE
get(VALUE self, VALUE rattribute)
{
  xmlNodePtr node;
  xmlChar *value = 0;
  VALUE rvalue;
  xmlChar *colon;
  xmlChar *attribute, *attr_name, *prefix;
  xmlNsPtr ns;

  if (NIL_P(rattribute)) { return Qnil; }

  Noko_Node_Get_Struct(self, xmlNode, node);
  attribute = xmlCharStrdup(StringValueCStr(rattribute));

  colon = DISCARD_CONST_QUAL_XMLCHAR(xmlStrchr(attribute, (const xmlChar)':'));
  if (colon) {
    /* split the attribute string into separate prefix and name by
     * null-terminating the prefix at the colon */
    prefix = attribute;
    attr_name = colon + 1;
    (*colon) = 0;

    ns = xmlSearchNs(node->doc, node, prefix);
    if (ns) {
      value = xmlGetNsProp(node, attr_name, ns->href);
    } else {
      value = xmlGetProp(node, (xmlChar *)StringValueCStr(rattribute));
    }
  } else {
    value = xmlGetNoNsProp(node, attribute);
  }

  xmlFree((void *)attribute);
  if (!value) { return Qnil; }

  rvalue = NOKOGIRI_STR_NEW2(value);
  xmlFree((void *)value);

  return rvalue ;
}

/*
 * call-seq:
 *   set_namespace(namespace)
 *
 * Set the namespace to +namespace+
 */
static VALUE
set_namespace(VALUE self, VALUE namespace)
{
  xmlNodePtr node;
  xmlNsPtr ns = NULL;

  Noko_Node_Get_Struct(self, xmlNode, node);

  if (!NIL_P(namespace)) {
    Noko_Namespace_Get_Struct(namespace, xmlNs, ns);
  }

  xmlSetNs(node, ns);

  return self;
}

/*
 * :call-seq:
 *   namespace() → Namespace
 *
 * [Returns] The Namespace of the element or attribute node, or +nil+ if there is no namespace.
 *
 * *Example:*
 *
 *   doc = Nokogiri::XML(<<~EOF)
 *     <root>
 *       <first/>
 *       <second xmlns="http://example.com/child"/>
 *       <foo:third xmlns:foo="http://example.com/foo"/>
 *     </root>
 *   EOF
 *   doc.at_xpath("//first").namespace
 *   # => nil
 *   doc.at_xpath("//xmlns:second", "xmlns" => "http://example.com/child").namespace
 *   # => #(Namespace:0x3c { href = "http://example.com/child" })
 *   doc.at_xpath("//foo:third", "foo" => "http://example.com/foo").namespace
 *   # => #(Namespace:0x50 { prefix = "foo", href = "http://example.com/foo" })
 */
static VALUE
rb_xml_node_namespace(VALUE rb_node)
{
  xmlNodePtr c_node ;
  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  if (c_node->ns) {
    return noko_xml_namespace_wrap(c_node->ns, c_node->doc);
  }

  return Qnil ;
}

/*
 * :call-seq:
 *   namespace_definitions() → Array<Nokogiri::XML::Namespace>
 *
 * [Returns]
 *   Namespaces that are defined directly on this node, as an Array of Namespace objects. The array
 *   will be empty if no namespaces are defined on this node.
 *
 * *Example:*
 *
 *   doc = Nokogiri::XML(<<~EOF)
 *     <root xmlns="http://example.com/root">
 *       <first/>
 *       <second xmlns="http://example.com/child" xmlns:unused="http://example.com/unused"/>
 *       <foo:third xmlns:foo="http://example.com/foo"/>
 *     </root>
 *   EOF
 *   doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_definitions
 *   # => []
 *   doc.at_xpath("//xmlns:second", "xmlns" => "http://example.com/child").namespace_definitions
 *   # => [#(Namespace:0x3c { href = "http://example.com/child" }),
 *   #     #(Namespace:0x50 {
 *   #       prefix = "unused",
 *   #       href = "http://example.com/unused"
 *   #       })]
 *   doc.at_xpath("//foo:third", "foo" => "http://example.com/foo").namespace_definitions
 *   # => [#(Namespace:0x64 { prefix = "foo", href = "http://example.com/foo" })]
 */
static VALUE
namespace_definitions(VALUE rb_node)
{
  /* this code in the mode of xmlHasProp() */
  xmlNodePtr c_node ;
  xmlNsPtr c_namespace;
  VALUE definitions = rb_ary_new();

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  c_namespace = c_node->nsDef;
  if (!c_namespace) {
    return definitions;
  }

  while (c_namespace != NULL) {
    rb_ary_push(definitions, noko_xml_namespace_wrap(c_namespace, c_node->doc));
    c_namespace = c_namespace->next;
  }

  return definitions;
}

/*
 * :call-seq:
 *   namespace_scopes() → Array<Nokogiri::XML::Namespace>
 *
 * [Returns] Array of all the Namespaces on this node and its ancestors.
 *
 * See also #namespaces
 *
 * *Example:*
 *
 *   doc = Nokogiri::XML(<<~EOF)
 *     <root xmlns="http://example.com/root" xmlns:bar="http://example.com/bar">
 *       <first/>
 *       <second xmlns="http://example.com/child"/>
 *       <third xmlns:foo="http://example.com/foo"/>
 *     </root>
 *   EOF
 *   doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_scopes
 *   # => [#(Namespace:0x3c { href = "http://example.com/root" }),
 *   #     #(Namespace:0x50 { prefix = "bar", href = "http://example.com/bar" })]
 *   doc.at_xpath("//child:second", "child" => "http://example.com/child").namespace_scopes
 *   # => [#(Namespace:0x64 { href = "http://example.com/child" }),
 *   #     #(Namespace:0x50 { prefix = "bar", href = "http://example.com/bar" })]
 *   doc.at_xpath("//root:third", "root" => "http://example.com/root").namespace_scopes
 *   # => [#(Namespace:0x78 { prefix = "foo", href = "http://example.com/foo" }),
 *   #     #(Namespace:0x3c { href = "http://example.com/root" }),
 *   #     #(Namespace:0x50 { prefix = "bar", href = "http://example.com/bar" })]
 */
static VALUE
rb_xml_node_namespace_scopes(VALUE rb_node)
{
  xmlNodePtr c_node ;
  xmlNsPtr *namespaces;
  VALUE scopes = rb_ary_new();
  int j;

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  namespaces = xmlGetNsList(c_node->doc, c_node);
  if (!namespaces) {
    return scopes;
  }

  for (j = 0 ; namespaces[j] != NULL ; ++j) {
    rb_ary_push(scopes, noko_xml_namespace_wrap(namespaces[j], c_node->doc));
  }

  xmlFree(namespaces);
  return scopes;
}

/*
 * call-seq:
 *  node_type
 *
 * Get the type for this Node
 */
static VALUE
node_type(VALUE self)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  return INT2NUM(node->type);
}

/*
 * call-seq:
 *   native_content=(input)
 *
 * Set the content of this node to +input+.
 *
 * [Parameters]
 * - +input+ (String) The new content for this node.
 *
 * ⚠ This method behaves differently depending on the node type. For Text, CDATA, Comment, and
 * ProcessingInstruction nodes, it treats the input as raw content, which means that the final DOM
 * will contain the entity-escaped version of the input (see example below). For Element and Attr
 * nodes, it treats the input as parsed content and expects it to be valid markup that is already
 * entity-escaped.
 *
 * 💡 Use Node#content= for a more consistent API across node types.
 *
 * [Example]
 * Note the behavior differences of this method between Text and Element nodes:
 *
 *   doc = Nokogiri::HTML::Document.parse(<<~HTML)
 *     <html>
 *       <body>
 *         <div id="first">asdf</div>
 *         <div id="second">asdf</div>
 *   HTML
 *
 *   text_node = doc.at_css("div#first").children.first
 *   div_node = doc.at_css("div#second")
 *
 *   value = "You &amp; Me"
 *
 *   text_node.native_content = value
 *   div_node.native_content = value
 *
 *   doc.css("div").to_html
 *   # => "<div id=\"first\">You &amp;amp; Me</div>
 *   #     <div id=\"second\">You &amp; Me</div>"
 *
 * See also: #content=
 */
static VALUE
set_native_content(VALUE self, VALUE content)
{
  xmlNodePtr node, child, next ;
  Noko_Node_Get_Struct(self, xmlNode, node);

  child = node->children;
  while (NULL != child) {
    next = child->next ;
    xmlUnlinkNode(child) ;
    noko_xml_document_pin_node(child);
    child = next ;
  }

  xmlNodeSetContent(node, (xmlChar *)StringValueCStr(content));
  return content;
}

/*
 * call-seq:
 *  lang=
 *
 * Set the language of a node, i.e. the values of the xml:lang attribute.
 */
static VALUE
set_lang(VALUE self_rb, VALUE lang_rb)
{
  xmlNodePtr self ;
  xmlChar *lang ;

  Noko_Node_Get_Struct(self_rb, xmlNode, self);
  lang = (xmlChar *)StringValueCStr(lang_rb);

  xmlNodeSetLang(self, lang);

  return Qnil ;
}

/*
 * call-seq:
 *  lang
 *
 * Searches the language of a node, i.e. the values of the xml:lang attribute or
 * the one carried by the nearest ancestor.
 */
static VALUE
get_lang(VALUE self_rb)
{
  xmlNodePtr self ;
  xmlChar *lang ;
  VALUE lang_rb ;

  Noko_Node_Get_Struct(self_rb, xmlNode, self);

  lang = xmlNodeGetLang(self);
  if (lang) {
    lang_rb = NOKOGIRI_STR_NEW2(lang);
    xmlFree(lang);
    return lang_rb ;
  }

  return Qnil ;
}

/* :nodoc: */
static VALUE
add_child(VALUE self, VALUE new_child)
{
  return reparent_node_with(self, new_child, xmlAddChild);
}

/*
 * call-seq:
 *  parent
 *
 * Get the parent Node for this Node
 */
static VALUE
get_parent(VALUE self)
{
  xmlNodePtr node, parent;
  Noko_Node_Get_Struct(self, xmlNode, node);

  parent = node->parent;
  if (!parent) { return Qnil; }

  return noko_xml_node_wrap(Qnil, parent) ;
}

/*
 * call-seq:
 *  name=(new_name)
 *
 * Set the name for this Node
 */
static VALUE
set_name(VALUE self, VALUE new_name)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  xmlNodeSetName(node, (xmlChar *)StringValueCStr(new_name));
  return new_name;
}

/*
 * call-seq:
 *  name
 *
 * Returns the name for this Node
 */
static VALUE
get_name(VALUE self)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  if (node->name) {
    return NOKOGIRI_STR_NEW2(node->name);
  }
  return Qnil;
}

/*
 * call-seq:
 *  path
 *
 * Returns the path associated with this Node
 */
static VALUE
rb_xml_node_path(VALUE rb_node)
{
  xmlNodePtr c_node;
  xmlChar *c_path ;
  VALUE rval;

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  c_path = xmlGetNodePath(c_node);
  if (c_path == NULL) {
    // see https://github.com/sparklemotion/nokogiri/issues/2250
    // this behavior is clearly undesirable, but is what libxml <= 2.9.10 returned, and so we
    // do this for now to preserve the behavior across libxml2 versions.
    rval = NOKOGIRI_STR_NEW2("?");
  } else {
    rval = NOKOGIRI_STR_NEW2(c_path);
    xmlFree(c_path);
  }

  return rval ;
}

/* :nodoc: */
static VALUE
add_next_sibling(VALUE self, VALUE new_sibling)
{
  return reparent_node_with(self, new_sibling, xmlAddNextSibling) ;
}

/* :nodoc: */
static VALUE
add_previous_sibling(VALUE self, VALUE new_sibling)
{
  return reparent_node_with(self, new_sibling, xmlAddPrevSibling) ;
}

/*
 * call-seq:
 *  native_write_to(io, encoding, options)
 *
 * Write this Node to +io+ with +encoding+ and +options+
 */
static VALUE
native_write_to(
  VALUE self,
  VALUE io,
  VALUE encoding,
  VALUE indent_string,
  VALUE options
)
{
  xmlNodePtr node;
  const char *before_indent;
  xmlSaveCtxtPtr savectx;

  Noko_Node_Get_Struct(self, xmlNode, node);

  xmlIndentTreeOutput = 1;

  before_indent = xmlTreeIndentString;

  xmlTreeIndentString = StringValueCStr(indent_string);

  savectx = xmlSaveToIO(
              (xmlOutputWriteCallback)noko_io_write,
              (xmlOutputCloseCallback)noko_io_close,
              (void *)io,
              RTEST(encoding) ? StringValueCStr(encoding) : NULL,
              (int)NUM2INT(options)
            );

  xmlSaveTree(savectx, node);
  xmlSaveClose(savectx);

  xmlTreeIndentString = before_indent;
  return io;
}


static inline void
output_partial_string(VALUE out, char const *str, size_t length)
{
  if (length) {
    rb_enc_str_buf_cat(out, str, (long)length, rb_utf8_encoding());
  }
}

static inline void
output_char(VALUE out, char ch)
{
  output_partial_string(out, &ch, 1);
}

static inline void
output_string(VALUE out, char const *str)
{
  output_partial_string(out, str, strlen(str));
}

static inline void
output_tagname(VALUE out, xmlNodePtr elem)
{
  // Elements in the HTML, MathML, and SVG namespaces do not use a namespace
  // prefix in the HTML syntax.
  char const *name = (char const *)elem->name;
  xmlNsPtr ns = elem->ns;
  if (ns && ns->href && ns->prefix
      && strcmp((char const *)ns->href, "http://www.w3.org/1999/xhtml")
      && strcmp((char const *)ns->href, "http://www.w3.org/1998/Math/MathML")
      && strcmp((char const *)ns->href, "http://www.w3.org/2000/svg")) {
    output_string(out, (char const *)elem->ns->prefix);
    output_char(out, ':');
    char const *colon = strchr(name, ':');
    if (colon) {
      name = colon + 1;
    }
  }
  output_string(out, name);
}

static inline void
output_attr_name(VALUE out, xmlAttrPtr attr)
{
  xmlNsPtr ns = attr->ns;
  char const *name = (char const *)attr->name;
  if (ns && ns->href) {
    char const *uri = (char const *)ns->href;
    char const *localname = strchr(name, ':');
    if (localname) {
      ++localname;
    } else {
      localname = name;
    }

    if (!strcmp(uri, "http://www.w3.org/XML/1998/namespace")) {
      output_string(out, "xml:");
      name = localname;
    } else if (!strcmp(uri, "http://www.w3.org/2000/xmlns/")) {
      // xmlns:xmlns -> xmlns
      // xmlns:foo -> xmlns:foo
      if (strcmp(localname, "xmlns")) {
        output_string(out, "xmlns:");
      }
      name = localname;
    } else if (!strcmp(uri, "http://www.w3.org/1999/xlink")) {
      output_string(out, "xlink:");
      name = localname;
    } else if (ns->prefix) {
      output_string(out, (char const *)ns->prefix);
      output_char(out, ':');
      name = localname;
    }
  }
  output_string(out, name);
}

static void
output_escaped_string(VALUE out, xmlChar const *start, bool attr)
{
  xmlChar const *next = start;
  int ch;

  while ((ch = *next) != 0) {
    char const *replacement = NULL;
    size_t replaced_bytes = 1;
    if (ch == '&') {
      replacement = "&amp;";
    } else if (ch == 0xC2 && next[1] == 0xA0) {
      // U+00A0 NO-BREAK SPACE has the UTF-8 encoding C2 A0.
      replacement = "&nbsp;";
      replaced_bytes = 2;
    } else if (attr && ch == '"') {
      replacement = "&quot;";
    } else if (!attr && ch == '<') {
      replacement = "&lt;";
    } else if (!attr && ch == '>') {
      replacement = "&gt;";
    } else {
      ++next;
      continue;
    }
    output_partial_string(out, (char const *)start, (size_t)(next - start));
    output_string(out, replacement);
    next += replaced_bytes;
    start = next;
  }
  output_partial_string(out, (char const *)start, (size_t)(next - start));
}

static bool
should_prepend_newline(xmlNodePtr node)
{
  char const *name = (char const *)node->name;
  xmlNodePtr child = node->children;

  if (!name || !child || (strcmp(name, "pre") && strcmp(name, "textarea") && strcmp(name, "listing"))) {
    return false;
  }

  return child->type == XML_TEXT_NODE && child->content && child->content[0] == '\n';
}

static VALUE
rb_prepend_newline(VALUE self)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  return should_prepend_newline(node) ? Qtrue : Qfalse;
}

static bool
is_one_of(xmlNodePtr node, char const *const *tagnames, size_t num_tagnames)
{
  char const *name = (char const *)node->name;
  if (name == NULL) { // fragments don't have a name
    return false;
  }

  if (node->ns != NULL) {
    // if the node has a namespace, it's in a foreign context and is not one of the HTML tags we're
    // matching against.
    return false;
  }

  for (size_t idx = 0; idx < num_tagnames; ++idx) {
    if (!strcmp(name, tagnames[idx])) {
      return true;
    }
  }
  return false;
}

static void
output_node(
  VALUE out,
  xmlNodePtr node,
  bool preserve_newline
)
{
  static char const *const VOID_ELEMENTS[] = {
    "area", "base", "basefont", "bgsound", "br", "col", "embed", "frame", "hr",
    "img", "input", "keygen", "link", "meta", "param", "source", "track", "wbr",
  };

  static char const *const UNESCAPED_TEXT_ELEMENTS[] = {
    "style", "script", "xmp", "iframe", "noembed", "noframes", "plaintext", "noscript",
  };

  switch (node->type) {
    case XML_ELEMENT_NODE:
      // Serialize the start tag.
      output_char(out, '<');
      output_tagname(out, node);

      // Add attributes.
      for (xmlAttrPtr attr = node->properties; attr; attr = attr->next) {
        output_char(out, ' ');
        output_node(out, (xmlNodePtr)attr, preserve_newline);
      }
      output_char(out, '>');

      // Add children and end tag if element is not void.
      if (!is_one_of(node, VOID_ELEMENTS, sizeof VOID_ELEMENTS / sizeof VOID_ELEMENTS[0])) {
        if (preserve_newline && should_prepend_newline(node)) {
          output_char(out, '\n');
        }
        for (xmlNodePtr child = node->children; child; child = child->next) {
          output_node(out, child, preserve_newline);
        }
        output_string(out, "</");
        output_tagname(out, node);
        output_char(out, '>');
      }
      break;

    case XML_ATTRIBUTE_NODE: {
      xmlAttrPtr attr = (xmlAttrPtr)node;
      output_attr_name(out, attr);
      if (attr->children) {
        output_string(out, "=\"");
        xmlChar *value = xmlNodeListGetString(attr->doc, attr->children, 1);
        output_escaped_string(out, value, true);
        xmlFree(value);
        output_char(out, '"');
      } else {
        // Output name=""
        output_string(out, "=\"\"");
      }
    }
    break;

    case XML_TEXT_NODE:
      if (node->parent
          && is_one_of(node->parent, UNESCAPED_TEXT_ELEMENTS,
                       sizeof UNESCAPED_TEXT_ELEMENTS / sizeof UNESCAPED_TEXT_ELEMENTS[0])) {
        output_string(out, (char const *)node->content);
      } else {
        output_escaped_string(out, node->content, false);
      }
      break;

    case XML_CDATA_SECTION_NODE:
      output_string(out, "<![CDATA[");
      output_string(out, (char const *)node->content);
      output_string(out, "]]>");
      break;

    case XML_COMMENT_NODE:
      output_string(out, "<!--");
      output_string(out, (char const *)node->content);
      output_string(out, "-->");
      break;

    case XML_PI_NODE:
      output_string(out, "<?");
      output_string(out, (char const *)node->content);
      output_char(out, '>');
      break;

    case XML_DOCUMENT_TYPE_NODE:
    case XML_DTD_NODE:
      output_string(out, "<!DOCTYPE ");
      output_string(out, (char const *)node->name);
      output_string(out, ">");
      break;

    case XML_DOCUMENT_NODE:
    case XML_DOCUMENT_FRAG_NODE:
    case XML_HTML_DOCUMENT_NODE:
      for (xmlNodePtr child = node->children; child; child = child->next) {
        output_node(out, child, preserve_newline);
      }
      break;

    default:
      rb_raise(rb_eRuntimeError, "Unsupported document node (%d); this is a bug in Nokogiri", node->type);
      break;
  }
}

static VALUE
html_standard_serialize(
  VALUE self,
  VALUE preserve_newline
)
{
  xmlNodePtr node;
  Noko_Node_Get_Struct(self, xmlNode, node);
  VALUE output = rb_str_buf_new(4096);
  output_node(output, node, RTEST(preserve_newline));
  return output;
}

/*
 * :call-seq:
 *   line() → Integer
 *
 * [Returns] The line number of this Node.
 *
 * ---
 *
 * <b> ⚠ The CRuby and JRuby implementations differ in important ways! </b>
 *
 * Semantic differences:
 * - The CRuby method reflects the node's line number <i>in the parsed string</i>
 * - The JRuby method reflects the node's line number <i>in the final DOM structure</i> after
 *   corrections have been applied
 *
 * Performance differences:
 * - The CRuby method is {O(1)}[https://en.wikipedia.org/wiki/Time_complexity#Constant_time]
 *   (constant time)
 * - The JRuby method is {O(n)}[https://en.wikipedia.org/wiki/Time_complexity#Linear_time] (linear
 *   time, where n is the number of nodes before/above the element in the DOM)
 *
 * If you'd like to help improve the JRuby implementation, please review these issues and reach out
 * to the maintainers:
 * - https://github.com/sparklemotion/nokogiri/issues/1223
 * - https://github.com/sparklemotion/nokogiri/pull/2177
 * - https://github.com/sparklemotion/nokogiri/issues/2380
 */
static VALUE
rb_xml_node_line(VALUE rb_node)
{
  xmlNodePtr c_node;
  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  return LONG2NUM(xmlGetLineNo(c_node));
}

/*
 * call-seq:
 *  line=(num)
 *
 * Sets the line for this Node. num must be less than 65535.
 */
static VALUE
rb_xml_node_line_set(VALUE rb_node, VALUE rb_line_number)
{
  xmlNodePtr c_node;
  int line_number = NUM2INT(rb_line_number);

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  // libxml2 optionally uses xmlNode.psvi to store longer line numbers, but only for text nodes.
  // search for "psvi" in SAX2.c and tree.c to learn more.
  if (line_number < 65535) {
    c_node->line = (short unsigned)line_number;
  } else {
    c_node->line = 65535;
    if (c_node->type == XML_TEXT_NODE) {
      c_node->psvi = (void *)(ptrdiff_t)line_number;
    }
  }

  return rb_line_number;
}

/* :nodoc: documented in lib/nokogiri/xml/node.rb */
static VALUE
rb_xml_node_new(int argc, VALUE *argv, VALUE klass)
{
  xmlNodePtr c_document_node;
  xmlNodePtr c_node;
  VALUE rb_name;
  VALUE rb_document_node;
  VALUE rest;
  VALUE rb_node;

  rb_scan_args(argc, argv, "2*", &rb_name, &rb_document_node, &rest);

  if (!rb_obj_is_kind_of(rb_document_node, cNokogiriXmlNode)) {
    rb_raise(rb_eArgError, "document must be a Nokogiri::XML::Node");
  }
  if (!rb_obj_is_kind_of(rb_document_node, cNokogiriXmlDocument)) {
    NOKO_WARN_DEPRECATION("Passing a Node as the second parameter to Node.new is deprecated. Please pass a Document instead, or prefer an alternative constructor like Node#add_child. This will become an error in Nokogiri v1.17.0."); // TODO: deprecated in v1.13.0, remove in v1.17.0
  }
  Noko_Node_Get_Struct(rb_document_node, xmlNode, c_document_node);

  c_node = xmlNewNode(NULL, (xmlChar *)StringValueCStr(rb_name));
  c_node->doc = c_document_node->doc;
  noko_xml_document_pin_node(c_node);

  rb_node = noko_xml_node_wrap(
              klass == cNokogiriXmlNode ? (VALUE)NULL : klass,
              c_node
            );
  rb_obj_call_init(rb_node, argc, argv);

  if (rb_block_given_p()) { rb_yield(rb_node); }

  return rb_node;
}

/*
 * call-seq:
 *  dump_html
 *
 * Returns the Node as html.
 */
static VALUE
dump_html(VALUE self)
{
  xmlBufferPtr buf ;
  xmlNodePtr node ;
  VALUE html;

  Noko_Node_Get_Struct(self, xmlNode, node);

  buf = xmlBufferCreate() ;
  htmlNodeDump(buf, node->doc, node);
  html = NOKOGIRI_STR_NEW2(xmlBufferContent(buf));
  xmlBufferFree(buf);
  return html ;
}

/*
 * call-seq:
 *  compare(other)
 *
 * Compare this Node to +other+ with respect to their Document
 */
static VALUE
compare(VALUE self, VALUE _other)
{
  xmlNodePtr node, other;
  Noko_Node_Get_Struct(self, xmlNode, node);
  Noko_Node_Get_Struct(_other, xmlNode, other);

  return INT2NUM(xmlXPathCmpNodes(other, node));
}


/*
 * call-seq:
 *   process_xincludes(flags)
 *
 * Loads and substitutes all xinclude elements below the node. The
 * parser context will be initialized with +flags+.
 */
static VALUE
noko_xml_node__process_xincludes(VALUE rb_node, VALUE rb_flags)
{
  int status ;
  xmlNodePtr c_node;
  VALUE rb_errors = rb_ary_new();
  libxmlStructuredErrorHandlerState handler_state;

  Noko_Node_Get_Struct(rb_node, xmlNode, c_node);

  noko__structured_error_func_save_and_set(&handler_state, (void *)rb_errors, noko__error_array_pusher);

  status = xmlXIncludeProcessTreeFlags(c_node, (int)NUM2INT(rb_flags));

  noko__structured_error_func_restore(&handler_state);

  if (status < 0) {
    VALUE exception = rb_funcall(cNokogiriXmlSyntaxError, rb_intern("aggregate"), 1, rb_errors);

    if (RB_TEST(exception)) {
      rb_exc_raise(exception);
    } else {
      rb_raise(rb_eRuntimeError, "Could not perform xinclude substitution");
    }
  }

  return rb_node;
}


/* TODO: DOCUMENT ME */
static VALUE
in_context(VALUE self, VALUE _str, VALUE _options)
{
  xmlNodePtr node, list = 0, tmp, child_iter, node_children, doc_children;
  xmlNodeSetPtr set;
  xmlParserErrors error;
  VALUE doc, err;
  int doc_is_empty;

  Noko_Node_Get_Struct(self, xmlNode, node);

  doc = DOC_RUBY_OBJECT(node->doc);
  err = rb_iv_get(doc, "@errors");
  doc_is_empty = (node->doc->children == NULL) ? 1 : 0;
  node_children = node->children;
  doc_children  = node->doc->children;

  xmlSetStructuredErrorFunc((void *)err, noko__error_array_pusher);

  /* This function adds a fake node to the child of +node+.  If the parser
   * does not exit cleanly with XML_ERR_OK, the list is freed.  This can
   * leave the child pointers in a bad state if they were originally empty.
   *
   * http://git.gnome.org/browse/libxml2/tree/parser.c#n13177
   * */
  error = xmlParseInNodeContext(node, StringValuePtr(_str),
                                (int)RSTRING_LEN(_str),
                                (int)NUM2INT(_options), &list);

  /* xmlParseInNodeContext should not mutate the original document or node,
   * so reassigning these pointers should be OK.  The reason we're reassigning
   * is because if there were errors, it's possible for the child pointers
   * to be manipulated. */
  if (error != XML_ERR_OK) {
    node->doc->children = doc_children;
    node->children = node_children;
  }

  /* make sure parent/child pointers are coherent so an unlink will work
   * properly (#331)
   */
  child_iter = node->doc->children ;
  while (child_iter) {
    child_iter->parent = (xmlNodePtr)node->doc;
    child_iter = child_iter->next;
  }

  xmlSetStructuredErrorFunc(NULL, NULL);

  /*
   * Workaround for a libxml2 bug where a parsing error may leave a broken
   * node reference in node->doc->children.
   *
   * https://bugzilla.gnome.org/show_bug.cgi?id=668155
   *
   * This workaround is limited to when a parse error occurs, the document
   * went from having no children to having children, and the context node is
   * part of a document fragment.
   *
   * TODO: This was fixed in libxml 2.8.0 by 71a243d
   */
  if (error != XML_ERR_OK && doc_is_empty && node->doc->children != NULL) {
    child_iter = node;
    while (child_iter->parent) {
      child_iter = child_iter->parent;
    }

    if (child_iter->type == XML_DOCUMENT_FRAG_NODE) {
      node->doc->children = NULL;
    }
  }

  /* FIXME: This probably needs to handle more constants... */
  switch (error) {
    case XML_ERR_INTERNAL_ERROR:
    case XML_ERR_NO_MEMORY:
      rb_raise(rb_eRuntimeError, "error parsing fragment (%d)", error);
      break;
    default:
      break;
  }

  set = xmlXPathNodeSetCreate(NULL);

  while (list) {
    tmp = list->next;
    list->next = NULL;
    xmlXPathNodeSetAddUnique(set, list);
    noko_xml_document_pin_node(list);
    list = tmp;
  }

  return noko_xml_node_set_wrap(set, doc);
}

/* :nodoc: */
VALUE
rb_xml_node_data_ptr_eh(VALUE self)
{
  xmlNodePtr c_node;
  Noko_Node_Get_Struct(self, xmlNode, c_node);
  return c_node ? Qtrue : Qfalse;
}

VALUE
noko_xml_node_wrap(VALUE rb_class, xmlNodePtr c_node)
{
  VALUE rb_document, rb_node_cache, rb_node;
  nokogiriTuplePtr node_has_a_document;
  xmlDocPtr c_doc;

  assert(c_node);

  if (c_node->type == XML_DOCUMENT_NODE || c_node->type == XML_HTML_DOCUMENT_NODE) {
    return DOC_RUBY_OBJECT(c_node->doc);
  }

  c_doc = c_node->doc;

  // Nodes yielded from XML::Reader don't have a fully-realized Document
  node_has_a_document = DOC_RUBY_OBJECT_TEST(c_doc);

  if (c_node->_private && node_has_a_document) {
    return (VALUE)c_node->_private;
  }

  if (!RTEST(rb_class)) {
    switch (c_node->type) {
      case XML_ELEMENT_NODE:
        rb_class = cNokogiriXmlElement;
        break;
      case XML_TEXT_NODE:
        rb_class = cNokogiriXmlText;
        break;
      case XML_ATTRIBUTE_NODE:
        rb_class = cNokogiriXmlAttr;
        break;
      case XML_ENTITY_REF_NODE:
        rb_class = cNokogiriXmlEntityReference;
        break;
      case XML_COMMENT_NODE:
        rb_class = cNokogiriXmlComment;
        break;
      case XML_DOCUMENT_FRAG_NODE:
        rb_class = cNokogiriXmlDocumentFragment;
        break;
      case XML_PI_NODE:
        rb_class = cNokogiriXmlProcessingInstruction;
        break;
      case XML_ENTITY_DECL:
        rb_class = cNokogiriXmlEntityDecl;
        break;
      case XML_CDATA_SECTION_NODE:
        rb_class = cNokogiriXmlCData;
        break;
      case XML_DTD_NODE:
        rb_class = cNokogiriXmlDtd;
        break;
      case XML_ATTRIBUTE_DECL:
        rb_class = cNokogiriXmlAttributeDecl;
        break;
      case XML_ELEMENT_DECL:
        rb_class = cNokogiriXmlElementDecl;
        break;
      default:
        rb_class = cNokogiriXmlNode;
    }
  }

  rb_node = _xml_node_alloc(rb_class);
  _xml_node_data_ptr_set(rb_node, c_node);

  if (node_has_a_document) {
    rb_document = DOC_RUBY_OBJECT(c_doc);
    rb_node_cache = DOC_NODE_CACHE(c_doc);
    rb_ary_push(rb_node_cache, rb_node);
    rb_funcall(rb_document, id_decorate, 1, rb_node);
  }

  return rb_node ;
}


/*
 *  return Array<Nokogiri::XML::Attr> containing the node's attributes
 */
VALUE
noko_xml_node_attrs(xmlNodePtr c_node)
{
  VALUE rb_properties = rb_ary_new();
  xmlAttrPtr c_property;

  c_property = c_node->properties ;
  while (c_property != NULL) {
    rb_ary_push(rb_properties, noko_xml_node_wrap(Qnil, (xmlNodePtr)c_property));
    c_property = c_property->next ;
  }

  return rb_properties;
}

void
noko_init_xml_node(void)
{
  cNokogiriXmlNode = rb_define_class_under(mNokogiriXml, "Node", rb_cObject);

  rb_define_alloc_func(cNokogiriXmlNode, _xml_node_alloc);

  rb_define_singleton_method(cNokogiriXmlNode, "new", rb_xml_node_new, -1);

  rb_define_method(cNokogiriXmlNode, "add_namespace_definition", rb_xml_node_add_namespace_definition, 2);
  rb_define_method(cNokogiriXmlNode, "attribute", rb_xml_node_attribute, 1);
  rb_define_method(cNokogiriXmlNode, "attribute_nodes", rb_xml_node_attribute_nodes, 0);
  rb_define_method(cNokogiriXmlNode, "attribute_with_ns", rb_xml_node_attribute_with_ns, 2);
  rb_define_method(cNokogiriXmlNode, "blank?", rb_xml_node_blank_eh, 0);
  rb_define_method(cNokogiriXmlNode, "child", rb_xml_node_child, 0);
  rb_define_method(cNokogiriXmlNode, "children", rb_xml_node_children, 0);
  rb_define_method(cNokogiriXmlNode, "content", rb_xml_node_content, 0);
  rb_define_method(cNokogiriXmlNode, "create_external_subset", create_external_subset, 3);
  rb_define_method(cNokogiriXmlNode, "create_internal_subset", create_internal_subset, 3);
  rb_define_method(cNokogiriXmlNode, "data_ptr?", rb_xml_node_data_ptr_eh, 0);
  rb_define_method(cNokogiriXmlNode, "document", rb_xml_node_document, 0);
  rb_define_method(cNokogiriXmlNode, "element_children", rb_xml_node_element_children, 0);
  rb_define_method(cNokogiriXmlNode, "encode_special_chars", encode_special_chars, 1);
  rb_define_method(cNokogiriXmlNode, "external_subset", external_subset, 0);
  rb_define_method(cNokogiriXmlNode, "first_element_child", rb_xml_node_first_element_child, 0);
  rb_define_method(cNokogiriXmlNode, "internal_subset", internal_subset, 0);
  rb_define_method(cNokogiriXmlNode, "key?", key_eh, 1);
  rb_define_method(cNokogiriXmlNode, "lang", get_lang, 0);
  rb_define_method(cNokogiriXmlNode, "lang=", set_lang, 1);
  rb_define_method(cNokogiriXmlNode, "last_element_child", rb_xml_node_last_element_child, 0);
  rb_define_method(cNokogiriXmlNode, "line", rb_xml_node_line, 0);
  rb_define_method(cNokogiriXmlNode, "line=", rb_xml_node_line_set, 1);
  rb_define_method(cNokogiriXmlNode, "namespace", rb_xml_node_namespace, 0);
  rb_define_method(cNokogiriXmlNode, "namespace_definitions", namespace_definitions, 0);
  rb_define_method(cNokogiriXmlNode, "namespace_scopes", rb_xml_node_namespace_scopes, 0);
  rb_define_method(cNokogiriXmlNode, "namespaced_key?", namespaced_key_eh, 2);
  rb_define_method(cNokogiriXmlNode, "native_content=", set_native_content, 1);
  rb_define_method(cNokogiriXmlNode, "next_element", next_element, 0);
  rb_define_method(cNokogiriXmlNode, "next_sibling", next_sibling, 0);
  rb_define_method(cNokogiriXmlNode, "node_name", get_name, 0);
  rb_define_method(cNokogiriXmlNode, "node_name=", set_name, 1);
  rb_define_method(cNokogiriXmlNode, "node_type", node_type, 0);
  rb_define_method(cNokogiriXmlNode, "parent", get_parent, 0);
  rb_define_method(cNokogiriXmlNode, "path", rb_xml_node_path, 0);
  rb_define_method(cNokogiriXmlNode, "pointer_id", rb_xml_node_pointer_id, 0);
  rb_define_method(cNokogiriXmlNode, "previous_element", previous_element, 0);
  rb_define_method(cNokogiriXmlNode, "previous_sibling", previous_sibling, 0);
  rb_define_method(cNokogiriXmlNode, "unlink", unlink_node, 0);

  rb_define_protected_method(cNokogiriXmlNode, "initialize_copy_with_args", rb_xml_node_initialize_copy_with_args, 3);

  rb_define_private_method(cNokogiriXmlNode, "add_child_node", add_child, 1);
  rb_define_private_method(cNokogiriXmlNode, "add_next_sibling_node", add_next_sibling, 1);
  rb_define_private_method(cNokogiriXmlNode, "add_previous_sibling_node", add_previous_sibling, 1);
  rb_define_private_method(cNokogiriXmlNode, "compare", compare, 1);
  rb_define_private_method(cNokogiriXmlNode, "dump_html", dump_html, 0);
  rb_define_private_method(cNokogiriXmlNode, "get", get, 1);
  rb_define_private_method(cNokogiriXmlNode, "in_context", in_context, 2);
  rb_define_private_method(cNokogiriXmlNode, "native_write_to", native_write_to, 4);
  rb_define_private_method(cNokogiriXmlNode, "prepend_newline?", rb_prepend_newline, 0);
  rb_define_private_method(cNokogiriXmlNode, "html_standard_serialize", html_standard_serialize, 1);
  rb_define_private_method(cNokogiriXmlNode, "process_xincludes", noko_xml_node__process_xincludes, 1);
  rb_define_private_method(cNokogiriXmlNode, "replace_node", replace, 1);
  rb_define_private_method(cNokogiriXmlNode, "set", set, 2);
  rb_define_private_method(cNokogiriXmlNode, "set_namespace", set_namespace, 1);

  id_decorate      = rb_intern("decorate");
  id_decorate_bang = rb_intern("decorate!");
}
