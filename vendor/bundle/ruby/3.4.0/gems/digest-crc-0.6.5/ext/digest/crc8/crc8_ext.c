#include "ruby.h"
#include "extconf.h"

#include "crc8.h"

VALUE Digest_CRC8_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc8_t crc = NUM2CHR(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc8_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, UINT2NUM(crc));
	return self;
}

void Init_crc8_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC8 = rb_const_get(mDigest, rb_intern("CRC8"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_undef_method(cCRC8, "update");
	rb_define_method(cCRC8, "update", Digest_CRC8_update, 1);
}
