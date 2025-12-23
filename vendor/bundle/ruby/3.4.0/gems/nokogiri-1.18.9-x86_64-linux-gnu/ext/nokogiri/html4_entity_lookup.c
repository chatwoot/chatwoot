#include <nokogiri.h>

static VALUE cNokogiriHtml4EntityLookup;

/*
 * call-seq:
 *  get(key)
 *
 * Get the HTML4::EntityDescription for +key+
 */
static VALUE
get(VALUE _, VALUE rb_entity_name)
{
  VALUE cNokogiriHtml4EntityDescription;
  const htmlEntityDesc *c_entity_desc;
  VALUE rb_constructor_args[3];

  c_entity_desc = htmlEntityLookup((const xmlChar *)StringValueCStr(rb_entity_name));
  if (NULL == c_entity_desc) {
    return Qnil;
  }

  rb_constructor_args[0] = UINT2NUM(c_entity_desc->value);
  rb_constructor_args[1] = NOKOGIRI_STR_NEW2(c_entity_desc->name);
  rb_constructor_args[2] = NOKOGIRI_STR_NEW2(c_entity_desc->desc);

  cNokogiriHtml4EntityDescription = rb_const_get_at(mNokogiriHtml4, rb_intern("EntityDescription"));
  return rb_class_new_instance(3, rb_constructor_args, cNokogiriHtml4EntityDescription);
}

void
noko_init_html_entity_lookup(void)
{
  cNokogiriHtml4EntityLookup = rb_define_class_under(mNokogiriHtml4, "EntityLookup", rb_cObject);

  rb_define_method(cNokogiriHtml4EntityLookup, "get", get, 1);
}
