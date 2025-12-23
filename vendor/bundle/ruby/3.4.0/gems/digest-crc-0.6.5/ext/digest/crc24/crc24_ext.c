#include "ruby.h"
#include "extconf.h"

#include "crc24.h"

VALUE Digest_CRC24_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc24_t crc = NUM2UINT(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc24_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, UINT2NUM(crc));
	return self;
}

void Init_crc24_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC24 = rb_const_get(mDigest, rb_intern("CRC24"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_undef_method(cCRC24, "update");
	rb_define_method(cCRC24, "update", Digest_CRC24_update, 1);
}
