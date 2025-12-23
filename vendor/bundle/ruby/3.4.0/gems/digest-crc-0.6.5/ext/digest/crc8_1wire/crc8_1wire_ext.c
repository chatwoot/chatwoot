#include "ruby.h"
#include "extconf.h"

#include "crc8_1wire.h"

VALUE Digest_CRC81Wire_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc8_t crc = NUM2CHR(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc8_1wire_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, UINT2NUM(crc));
	return self;
}

void Init_crc8_1wire_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC81Wire = rb_const_get(mDigest, rb_intern("CRC8_1Wire"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_define_method(cCRC81Wire, "update", Digest_CRC81Wire_update, 1);
}
