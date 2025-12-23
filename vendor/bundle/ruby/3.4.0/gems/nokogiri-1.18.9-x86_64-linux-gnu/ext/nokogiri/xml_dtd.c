#include <nokogiri.h>

VALUE cNokogiriXmlDtd;

static void
notation_copier(void *c_notation_ptr, void *rb_hash_ptr, const xmlChar *name)
{
  VALUE rb_hash = (VALUE)rb_hash_ptr;
  xmlNotationPtr c_notation = (xmlNotationPtr)c_notation_ptr;
  VALUE rb_notation;
  VALUE cNokogiriXmlNotation;
  VALUE rb_constructor_args[3];

  rb_constructor_args[0] = (c_notation->name ? NOKOGIRI_STR_NEW2(c_notation->name) : Qnil);
  rb_constructor_args[1] = (c_notation->PublicID ? NOKOGIRI_STR_NEW2(c_notation->PublicID) : Qnil);
  rb_constructor_args[2] = (c_notation->SystemID ? NOKOGIRI_STR_NEW2(c_notation->SystemID) : Qnil);

  cNokogiriXmlNotation = rb_const_get_at(mNokogiriXml, rb_intern("Notation"));
  rb_notation = rb_class_new_instance(3, rb_constructor_args, cNokogiriXmlNotation);

  rb_hash_aset(rb_hash, NOKOGIRI_STR_NEW2(name), rb_notation);
}

static void
element_copier(void *c_node_ptr, void *rb_hash_ptr, const xmlChar *c_name)
{
  VALUE rb_hash = (VALUE)rb_hash_ptr;
  xmlNodePtr c_node = (xmlNodePtr)c_node_ptr;

  VALUE rb_node = noko_xml_node_wrap(Qnil, c_node);

  rb_hash_aset(rb_hash, NOKOGIRI_STR_NEW2(c_name), rb_node);
}

/*
 * call-seq:
 *   entities
 *
 * Get a hash of the elements for this DTD.
 */
static VALUE
entities(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Noko_Node_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->entities) { return Qnil; }

  hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->entities, element_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   notations() → Hash<name(String)⇒Notation>
 *
 * [Returns] All the notations for this DTD in a Hash of Notation +name+ to Notation.
 */
static VALUE
notations(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Noko_Node_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->notations) { return Qnil; }

  hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->notations, notation_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   attributes
 *
 * Get a hash of the attributes for this DTD.
 */
static VALUE
attributes(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Noko_Node_Get_Struct(self, xmlDtd, dtd);

  hash = rb_hash_new();

  if (!dtd->attributes) { return hash; }

  xmlHashScan((xmlHashTablePtr)dtd->attributes, element_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   elements
 *
 * Get a hash of the elements for this DTD.
 */
static VALUE
elements(VALUE self)
{
  xmlDtdPtr dtd;
  VALUE hash;

  Noko_Node_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->elements) { return Qnil; }

  hash = rb_hash_new();

  xmlHashScan((xmlHashTablePtr)dtd->elements, element_copier, (void *)hash);

  return hash;
}

/*
 * call-seq:
 *   validate(document)
 *
 * Validate +document+ returning a list of errors
 */
static VALUE
validate(VALUE self, VALUE document)
{
  xmlDocPtr doc;
  xmlDtdPtr dtd;
  xmlValidCtxtPtr ctxt;
  VALUE error_list;

  Noko_Node_Get_Struct(self, xmlDtd, dtd);
  doc = noko_xml_document_unwrap(document);
  error_list = rb_ary_new();

  ctxt = xmlNewValidCtxt();

  xmlSetStructuredErrorFunc((void *)error_list, noko__error_array_pusher);

  xmlValidateDtd(ctxt, doc, dtd);

  xmlSetStructuredErrorFunc(NULL, NULL);

  xmlFreeValidCtxt(ctxt);

  return error_list;
}

/*
 * call-seq:
 *   system_id
 *
 * Get the System ID for this DTD
 */
static VALUE
system_id(VALUE self)
{
  xmlDtdPtr dtd;
  Noko_Node_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->SystemID) { return Qnil; }

  return NOKOGIRI_STR_NEW2(dtd->SystemID);
}

/*
 * call-seq:
 *   external_id
 *
 * Get the External ID for this DTD
 */
static VALUE
external_id(VALUE self)
{
  xmlDtdPtr dtd;
  Noko_Node_Get_Struct(self, xmlDtd, dtd);

  if (!dtd->ExternalID) { return Qnil; }

  return NOKOGIRI_STR_NEW2(dtd->ExternalID);
}

void
noko_init_xml_dtd(void)
{
  assert(cNokogiriXmlNode);
  /*
   * Nokogiri::XML::DTD wraps DTD nodes in an XML document
   */
  cNokogiriXmlDtd = rb_define_class_under(mNokogiriXml, "DTD", cNokogiriXmlNode);

  rb_define_method(cNokogiriXmlDtd, "notations", notations, 0);
  rb_define_method(cNokogiriXmlDtd, "elements", elements, 0);
  rb_define_method(cNokogiriXmlDtd, "entities", entities, 0);
  rb_define_method(cNokogiriXmlDtd, "validate", validate, 1);
  rb_define_method(cNokogiriXmlDtd, "attributes", attributes, 0);
  rb_define_method(cNokogiriXmlDtd, "system_id", system_id, 0);
  rb_define_method(cNokogiriXmlDtd, "external_id", external_id, 0);
}
