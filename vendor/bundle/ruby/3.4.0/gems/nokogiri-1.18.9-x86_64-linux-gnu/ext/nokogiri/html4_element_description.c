#include <nokogiri.h>

static const rb_data_type_t html_elem_desc_type = {
  .wrap_struct_name = "htmlElemDesc",
  .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

VALUE cNokogiriHtml4ElementDescription ;

/*
 * call-seq:
 *  required_attributes
 *
 * A list of required attributes for this element
 */
static VALUE
required_attributes(VALUE self)
{
  const htmlElemDesc *description;
  VALUE list;
  int i;

  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  list = rb_ary_new();

  if (NULL == description->attrs_req) { return list; }

  for (i = 0; description->attrs_depr[i]; i++) {
    rb_ary_push(list, NOKOGIRI_STR_NEW2(description->attrs_req[i]));
  }

  return list;
}

/*
 * call-seq:
 *  deprecated_attributes
 *
 * A list of deprecated attributes for this element
 */
static VALUE
deprecated_attributes(VALUE self)
{
  const htmlElemDesc *description;
  VALUE list;
  int i;

  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  list = rb_ary_new();

  if (NULL == description->attrs_depr) { return list; }

  for (i = 0; description->attrs_depr[i]; i++) {
    rb_ary_push(list, NOKOGIRI_STR_NEW2(description->attrs_depr[i]));
  }

  return list;
}

/*
 * call-seq:
 *  optional_attributes
 *
 * A list of optional attributes for this element
 */
static VALUE
optional_attributes(VALUE self)
{
  const htmlElemDesc *description;
  VALUE list;
  int i;

  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  list = rb_ary_new();

  if (NULL == description->attrs_opt) { return list; }

  for (i = 0; description->attrs_opt[i]; i++) {
    rb_ary_push(list, NOKOGIRI_STR_NEW2(description->attrs_opt[i]));
  }

  return list;
}

/*
 * call-seq:
 *  default_sub_element
 *
 * The default sub element for this element
 */
static VALUE
default_sub_element(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (description->defaultsubelt) {
    return NOKOGIRI_STR_NEW2(description->defaultsubelt);
  }

  return Qnil;
}

/*
 * call-seq:
 *  sub_elements
 *
 * A list of allowed sub elements for this element.
 */
static VALUE
sub_elements(VALUE self)
{
  const htmlElemDesc *description;
  VALUE list;
  int i;

  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  list = rb_ary_new();

  if (NULL == description->subelts) { return list; }

  for (i = 0; description->subelts[i]; i++) {
    rb_ary_push(list, NOKOGIRI_STR_NEW2(description->subelts[i]));
  }

  return list;
}

/*
 * call-seq:
 *  description
 *
 * The description for this element
 */
static VALUE
description(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  return NOKOGIRI_STR_NEW2(description->desc);
}

/*
 * call-seq:
 *  inline?
 *
 * Is this element an inline element?
 */
static VALUE
inline_eh(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (description->isinline) { return Qtrue; }
  return Qfalse;
}

/*
 * call-seq:
 *  deprecated?
 *
 * Is this element deprecated?
 */
static VALUE
deprecated_eh(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (description->depr) { return Qtrue; }
  return Qfalse;
}

/*
 * call-seq:
 *  empty?
 *
 * Is this an empty element?
 */
static VALUE
empty_eh(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (description->empty) { return Qtrue; }
  return Qfalse;
}

/*
 * call-seq:
 *  save_end_tag?
 *
 * Should the end tag be saved?
 */
static VALUE
save_end_tag_eh(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (description->saveEndTag) { return Qtrue; }
  return Qfalse;
}

/*
 * call-seq:
 *  implied_end_tag?
 *
 * Can the end tag be implied for this tag?
 */
static VALUE
implied_end_tag_eh(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (description->endTag) { return Qtrue; }
  return Qfalse;
}

/*
 * call-seq:
 *  implied_start_tag?
 *
 * Can the start tag be implied for this tag?
 */
static VALUE
implied_start_tag_eh(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (description->startTag) { return Qtrue; }
  return Qfalse;
}

/*
 * call-seq:
 *  name
 *
 * Get the tag name for this ElementDescription
 */
static VALUE
name(VALUE self)
{
  const htmlElemDesc *description;
  TypedData_Get_Struct(self, htmlElemDesc, &html_elem_desc_type, description);

  if (NULL == description->name) { return Qnil; }
  return NOKOGIRI_STR_NEW2(description->name);
}

/*
 * call-seq:
 *  [](tag_name)
 *
 * Get ElementDescription for +tag_name+
 */
static VALUE
get_description(VALUE klass, VALUE tag_name)
{
  const htmlElemDesc *description = htmlTagLookup(
                                      (const xmlChar *)StringValueCStr(tag_name)
                                    );

  if (NULL == description) { return Qnil; }
  return TypedData_Wrap_Struct(klass, &html_elem_desc_type, DISCARD_CONST_QUAL(void *, description));
}

void
noko_init_html_element_description(void)
{
  cNokogiriHtml4ElementDescription = rb_define_class_under(mNokogiriHtml4, "ElementDescription", rb_cObject);

  rb_undef_alloc_func(cNokogiriHtml4ElementDescription);

  rb_define_singleton_method(cNokogiriHtml4ElementDescription, "[]", get_description, 1);

  rb_define_method(cNokogiriHtml4ElementDescription, "name", name, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "implied_start_tag?", implied_start_tag_eh, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "implied_end_tag?", implied_end_tag_eh, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "save_end_tag?", save_end_tag_eh, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "empty?", empty_eh, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "deprecated?", deprecated_eh, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "inline?", inline_eh, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "description", description, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "sub_elements", sub_elements, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "default_sub_element", default_sub_element, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "optional_attributes", optional_attributes, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "deprecated_attributes", deprecated_attributes, 0);
  rb_define_method(cNokogiriHtml4ElementDescription, "required_attributes", required_attributes, 0);
}
