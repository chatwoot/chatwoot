#include <nokogiri.h>

VALUE cNokogiriXmlNodeSet ;

static ID decorate ;

static void
Check_Node_Set_Node_Type(VALUE node)
{
  if (!(rb_obj_is_kind_of(node, cNokogiriXmlNode) ||
        rb_obj_is_kind_of(node, cNokogiriXmlNamespace))) {
    rb_raise(rb_eArgError, "node must be a Nokogiri::XML::Node or Nokogiri::XML::Namespace");
  }
}


static
VALUE
ruby_object_get(xmlNodePtr c_node)
{
  /* see xmlElementType in libxml2 tree.h */
  switch (c_node->type) {
    case XML_NAMESPACE_DECL:
      /* _private is later in the namespace struct */
      return (VALUE)(((xmlNsPtr)c_node)->_private);

    case XML_DOCUMENT_NODE:
    case XML_HTML_DOCUMENT_NODE:
      /* in documents we use _private to store a tuple */
      if (DOC_RUBY_OBJECT_TEST(((xmlDocPtr)c_node))) {
        return DOC_RUBY_OBJECT((xmlDocPtr)c_node);
      }
      return (VALUE)NULL;

    default:
      return (VALUE)(c_node->_private);
  }
}


static void
xml_node_set_mark(void *data)
{
  xmlNodeSetPtr node_set = data;
  VALUE rb_node;
  int jnode;

  for (jnode = 0; jnode < node_set->nodeNr; jnode++) {
    rb_node = ruby_object_get(node_set->nodeTab[jnode]);
    if (rb_node) {
      rb_gc_mark(rb_node);
    }
  }
}

static void
xml_node_set_deallocate(void *data)
{
  xmlNodeSetPtr node_set = data;
  /*
   * For reasons outlined in xml_namespace.c, here we reproduce xmlXPathFreeNodeSet() except for the
   * offending call to xmlXPathNodeSetFreeNs().
   */
  if (node_set->nodeTab != NULL) {
    xmlFree(node_set->nodeTab);
  }

  xmlFree(node_set);
}

static const rb_data_type_t xml_node_set_type = {
  .wrap_struct_name = "xmlNodeSet",
  .function = {
    .dmark = xml_node_set_mark,
    .dfree = xml_node_set_deallocate,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE
xml_node_set_allocate(VALUE klass)
{
  return TypedData_Wrap_Struct(klass, &xml_node_set_type, xmlXPathNodeSetCreate(NULL));
}

/* :nodoc: */
static VALUE
rb_xml_node_set_initialize_copy(VALUE rb_self, VALUE rb_other)
{
  xmlNodeSetPtr c_self, c_other;
  VALUE rb_document;

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);
  TypedData_Get_Struct(rb_other, xmlNodeSet, &xml_node_set_type, c_other);

  xmlXPathNodeSetMerge(c_self, c_other);

  rb_document = rb_iv_get(rb_other, "@document");
  if (!NIL_P(rb_document)) {
    rb_iv_set(rb_self, "@document", rb_document);
    rb_funcall(rb_document, decorate, 1, rb_self);
  }

  return rb_self;
}

static void
xpath_node_set_del(xmlNodeSetPtr cur, xmlNodePtr val)
{
  /*
   * For reasons outlined in xml_namespace.c, here we reproduce xmlXPathNodeSetDel() except for the
   * offending call to xmlXPathNodeSetFreeNs().
   */
  int i;

  if (cur == NULL) { return; }
  if (val == NULL) { return; }

  /*
   * find node in nodeTab
   */
  for (i = 0; i < cur->nodeNr; i++)
    if (cur->nodeTab[i] == val) { break; }

  if (i >= cur->nodeNr) {	/* not found */
    return;
  }
  cur->nodeNr--;
  for (; i < cur->nodeNr; i++) {
    cur->nodeTab[i] = cur->nodeTab[i + 1];
  }
  cur->nodeTab[cur->nodeNr] = NULL;
}

/*
 * call-seq:
 *  length
 *
 * Get the length of the node set
 */
static VALUE
length(VALUE rb_self)
{
  xmlNodeSetPtr c_self;

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);

  return c_self ? INT2NUM(c_self->nodeNr) : INT2NUM(0);
}

/*
 * call-seq:
 *  push(node)
 *
 * Append +node+ to the NodeSet.
 */
static VALUE
push(VALUE rb_self, VALUE rb_node)
{
  xmlNodeSetPtr c_self;
  xmlNodePtr node;

  Check_Node_Set_Node_Type(rb_node);

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);
  Noko_Node_Get_Struct(rb_node, xmlNode, node);

  xmlXPathNodeSetAdd(c_self, node);

  return rb_self;
}

/*
 *  call-seq:
 *    delete(node)
 *
 *  Delete +node+ from the Nodeset, if it is a member. Returns the deleted node
 *  if found, otherwise returns nil.
 */
static VALUE
delete (VALUE rb_self, VALUE rb_node)
{
  xmlNodeSetPtr c_self;
  xmlNodePtr node;

  Check_Node_Set_Node_Type(rb_node);

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);
  Noko_Node_Get_Struct(rb_node, xmlNode, node);

  if (xmlXPathNodeSetContains(c_self, node)) {
    xpath_node_set_del(c_self, node);
    return rb_node;
  }
  return Qnil ;
}


/*
 * call-seq:
 *  &(node_set)
 *
 * Set Intersection — Returns a new NodeSet containing nodes common to the two NodeSets.
 */
static VALUE
intersection(VALUE rb_self, VALUE rb_other)
{
  xmlNodeSetPtr c_self, c_other ;
  xmlNodeSetPtr intersection;

  if (!rb_obj_is_kind_of(rb_other, cNokogiriXmlNodeSet)) {
    rb_raise(rb_eArgError, "node_set must be a Nokogiri::XML::NodeSet");
  }

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);
  TypedData_Get_Struct(rb_other, xmlNodeSet, &xml_node_set_type, c_other);

  intersection = xmlXPathIntersection(c_self, c_other);
  return noko_xml_node_set_wrap(intersection, rb_iv_get(rb_self, "@document"));
}


/*
 * call-seq:
 *  include?(node)
 *
 *  Returns true if any member of node set equals +node+.
 */
static VALUE
include_eh(VALUE rb_self, VALUE rb_node)
{
  xmlNodeSetPtr c_self;
  xmlNodePtr node;

  Check_Node_Set_Node_Type(rb_node);

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);
  Noko_Node_Get_Struct(rb_node, xmlNode, node);

  return (xmlXPathNodeSetContains(c_self, node) ? Qtrue : Qfalse);
}


/*
 * call-seq:
 *  |(node_set)
 *
 * Returns a new set built by merging the set and the elements of the given
 * set.
 */
static VALUE
rb_xml_node_set_union(VALUE rb_self, VALUE rb_other)
{
  xmlNodeSetPtr c_self, c_other;
  xmlNodeSetPtr c_new_node_set;

  if (!rb_obj_is_kind_of(rb_other, cNokogiriXmlNodeSet)) {
    rb_raise(rb_eArgError, "node_set must be a Nokogiri::XML::NodeSet");
  }

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);
  TypedData_Get_Struct(rb_other, xmlNodeSet, &xml_node_set_type, c_other);

  c_new_node_set = xmlXPathNodeSetMerge(NULL, c_self);
  c_new_node_set = xmlXPathNodeSetMerge(c_new_node_set, c_other);

  return noko_xml_node_set_wrap(c_new_node_set, rb_iv_get(rb_self, "@document"));
}

/*
 * call-seq:
 *  -(node_set)
 *
 *  Difference - returns a new NodeSet that is a copy of this NodeSet, removing
 *  each item that also appears in +node_set+
 */
static VALUE
minus(VALUE rb_self, VALUE rb_other)
{
  xmlNodeSetPtr c_self, c_other;
  xmlNodeSetPtr new;
  int j ;

  if (!rb_obj_is_kind_of(rb_other, cNokogiriXmlNodeSet)) {
    rb_raise(rb_eArgError, "node_set must be a Nokogiri::XML::NodeSet");
  }

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);
  TypedData_Get_Struct(rb_other, xmlNodeSet, &xml_node_set_type, c_other);

  new = xmlXPathNodeSetMerge(NULL, c_self);
  for (j = 0 ; j < c_other->nodeNr ; ++j) {
    xpath_node_set_del(new, c_other->nodeTab[j]);
  }

  return noko_xml_node_set_wrap(new, rb_iv_get(rb_self, "@document"));
}


static VALUE
index_at(VALUE rb_self, long offset)
{
  xmlNodeSetPtr c_self;

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);

  if (offset >= c_self->nodeNr || abs((int)offset) > c_self->nodeNr) {
    return Qnil;
  }

  if (offset < 0) { offset += c_self->nodeNr ; }

  return noko_xml_node_wrap_node_set_result(c_self->nodeTab[offset], rb_self);
}

static VALUE
subseq(VALUE rb_self, long beg, long len)
{
  long j;
  xmlNodeSetPtr c_self;
  xmlNodeSetPtr new_set ;

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);

  if (beg > c_self->nodeNr) { return Qnil ; }
  if (beg < 0 || len < 0) { return Qnil ; }

  if ((beg + len) > c_self->nodeNr) {
    len = c_self->nodeNr - beg ;
  }

  new_set = xmlXPathNodeSetCreate(NULL);
  for (j = beg ; j < beg + len ; ++j) {
    xmlXPathNodeSetAddUnique(new_set, c_self->nodeTab[j]);
  }
  return noko_xml_node_set_wrap(new_set, rb_iv_get(rb_self, "@document"));
}

/*
 * call-seq:
 *  [index] -> Node or nil
 *  [start, length] -> NodeSet or nil
 *  [range] -> NodeSet or nil
 *  slice(index) -> Node or nil
 *  slice(start, length) -> NodeSet or nil
 *  slice(range) -> NodeSet or nil
 *
 * Element reference - returns the node at +index+, or returns a NodeSet
 * containing nodes starting at +start+ and continuing for +length+ elements, or
 * returns a NodeSet containing nodes specified by +range+. Negative +indices+
 * count backward from the end of the +node_set+ (-1 is the last node). Returns
 * nil if the +index+ (or +start+) are out of range.
 */
static VALUE
slice(int argc, VALUE *argv, VALUE rb_self)
{
  VALUE arg ;
  long beg, len ;
  xmlNodeSetPtr c_self;

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);

  if (argc == 2) {
    beg = NUM2LONG(argv[0]);
    len = NUM2LONG(argv[1]);
    if (beg < 0) {
      beg += c_self->nodeNr ;
    }
    return subseq(rb_self, beg, len);
  }

  if (argc != 1) {
    rb_scan_args(argc, argv, "11", NULL, NULL);
  }
  arg = argv[0];

  if (FIXNUM_P(arg)) {
    return index_at(rb_self, FIX2LONG(arg));
  }

  /* if arg is Range */
  switch (rb_range_beg_len(arg, &beg, &len, (long)c_self->nodeNr, 0)) {
    case Qfalse:
      break;
    case Qnil:
      return Qnil;
    default:
      return subseq(rb_self, beg, len);
  }

  return index_at(rb_self, NUM2LONG(arg));
}


/*
 * call-seq:
 *  to_a
 *
 * Return this list as an Array
 */
static VALUE
to_array(VALUE rb_self)
{
  xmlNodeSetPtr c_self ;
  VALUE list;
  int i;

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);

  list = rb_ary_new2(c_self->nodeNr);
  for (i = 0; i < c_self->nodeNr; i++) {
    VALUE elt = noko_xml_node_wrap_node_set_result(c_self->nodeTab[i], rb_self);
    rb_ary_push(list, elt);
  }

  return list;
}

/*
 *  call-seq:
 *    unlink
 *
 * Unlink this NodeSet and all Node objects it contains from their current context.
 */
static VALUE
unlink_nodeset(VALUE rb_self)
{
  xmlNodeSetPtr c_self;
  int j, nodeNr ;

  TypedData_Get_Struct(rb_self, xmlNodeSet, &xml_node_set_type, c_self);

  nodeNr = c_self->nodeNr ;
  for (j = 0 ; j < nodeNr ; j++) {
    if (! NOKOGIRI_NAMESPACE_EH(c_self->nodeTab[j])) {
      VALUE node ;
      xmlNodePtr node_ptr;
      node = noko_xml_node_wrap(Qnil, c_self->nodeTab[j]);
      rb_funcall(node, rb_intern("unlink"), 0); /* modifies the C struct out from under the object */
      Noko_Node_Get_Struct(node, xmlNode, node_ptr);
      c_self->nodeTab[j] = node_ptr ;
    }
  }
  return rb_self ;
}


VALUE
noko_xml_node_set_wrap(xmlNodeSetPtr c_node_set, VALUE document)
{
  int j;
  VALUE rb_node_set ;

  if (c_node_set == NULL) {
    rb_node_set = xml_node_set_allocate(cNokogiriXmlNodeSet);
  } else {
    rb_node_set = TypedData_Wrap_Struct(cNokogiriXmlNodeSet, &xml_node_set_type, c_node_set);
  }

  if (!NIL_P(document)) {
    rb_iv_set(rb_node_set, "@document", document);
    rb_funcall(document, decorate, 1, rb_node_set);
  }

  if (c_node_set) {
    /* create ruby objects for all the results, so they'll be marked during the GC mark phase */
    for (j = 0 ; j < c_node_set->nodeNr ; j++) {
      noko_xml_node_wrap_node_set_result(c_node_set->nodeTab[j], rb_node_set);
    }
  }

  return rb_node_set ;
}


VALUE
noko_xml_node_wrap_node_set_result(xmlNodePtr node, VALUE node_set)
{
  if (NOKOGIRI_NAMESPACE_EH(node)) {
    return noko_xml_namespace_wrap_xpath_copy((xmlNsPtr)node);
  } else {
    return noko_xml_node_wrap(Qnil, node);
  }
}


xmlNodeSetPtr
noko_xml_node_set_unwrap(VALUE rb_node_set)
{
  xmlNodeSetPtr c_node_set;
  TypedData_Get_Struct(rb_node_set, xmlNodeSet, &xml_node_set_type, c_node_set);
  return c_node_set;
}


void
noko_init_xml_node_set(void)
{
  cNokogiriXmlNodeSet = rb_define_class_under(mNokogiriXml, "NodeSet", rb_cObject);

  rb_define_alloc_func(cNokogiriXmlNodeSet, xml_node_set_allocate);

  rb_define_method(cNokogiriXmlNodeSet, "&", intersection, 1);
  rb_define_method(cNokogiriXmlNodeSet, "-", minus, 1);
  rb_define_method(cNokogiriXmlNodeSet, "[]", slice, -1);
  rb_define_method(cNokogiriXmlNodeSet, "delete", delete, 1);
  rb_define_method(cNokogiriXmlNodeSet, "include?", include_eh, 1);
  rb_define_method(cNokogiriXmlNodeSet, "length", length, 0);
  rb_define_method(cNokogiriXmlNodeSet, "push", push, 1);
  rb_define_method(cNokogiriXmlNodeSet, "slice", slice, -1);
  rb_define_method(cNokogiriXmlNodeSet, "to_a", to_array, 0);
  rb_define_method(cNokogiriXmlNodeSet, "unlink", unlink_nodeset, 0);
  rb_define_method(cNokogiriXmlNodeSet, "|", rb_xml_node_set_union, 1);

  rb_define_private_method(cNokogiriXmlNodeSet, "initialize_copy", rb_xml_node_set_initialize_copy, 1);

  decorate = rb_intern("decorate");
}
