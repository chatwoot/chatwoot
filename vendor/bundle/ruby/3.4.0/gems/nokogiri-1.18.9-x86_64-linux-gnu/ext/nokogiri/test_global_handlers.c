#include <nokogiri.h>

static VALUE foreign_error_handler_block = Qnil;

static void
foreign_error_handler(void *user_data, xmlErrorConstPtr c_error)
{
  rb_funcall(foreign_error_handler_block, rb_intern("call"), 0);
}

/*
 * call-seq:
 *   __foreign_error_handler { ... } -> nil
 *
 * Override libxml2's global error handlers to call the block. This method thus has very little
 * value except to test that Nokogiri is properly setting error handlers elsewhere in the code. See
 * test/helper.rb for how this is being used.
 */
static VALUE
rb_foreign_error_handler(VALUE klass)
{
  rb_need_block();
  foreign_error_handler_block = rb_block_proc();
  xmlSetStructuredErrorFunc(NULL, foreign_error_handler);
  return Qnil;
}

/*
 *  Document-module: Nokogiri::Test
 *
 *  The Nokogiri::Test module should only be used for testing Nokogiri.
 *  Do NOT use this outside of the Nokogiri test suite.
 */
void
noko_init_test_global_handlers(void)
{
  VALUE mNokogiriTest = rb_define_module_under(mNokogiri, "Test");

  rb_define_singleton_method(mNokogiriTest, "__foreign_error_handler", rb_foreign_error_handler, 0);
}
