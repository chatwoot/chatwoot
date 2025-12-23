#include "ruby.h"
#include "extconf.h"

#include "crc12_3gpp.h"

VALUE Digest_CRC12_3GPP_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc12_t crc = NUM2UINT(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc12_3gpp_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, UINT2NUM(crc));
	return self;
}

void Init_crc12_3gpp_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC12_3GPP = rb_const_get(mDigest, rb_intern("CRC12_3GPP"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_undef_method(cCRC12_3GPP, "update");
	rb_define_method(cCRC12_3GPP, "update", Digest_CRC12_3GPP_update, 1);
}
