#include "ruby.h"
#include "extconf.h"

#include "crc32c.h"

VALUE Digest_CRC32c_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc32_t crc = NUM2UINT(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc32c_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, UINT2NUM(crc));
	return self;
}

void Init_crc32c_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC32c = rb_const_get(mDigest, rb_intern("CRC32c"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_define_method(cCRC32c, "update", Digest_CRC32c_update, 1);
}
