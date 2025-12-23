#include <ruby.h>
#include "../compat/ruby.h"

#include "extconf.h"
#include "crc16_genibus.h"

VALUE Digest_CRC16Genibus_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc16_t crc = NUM2USHORT(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc16_genibus_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, USHORT2NUM(crc));
	return self;
}

void Init_crc16_genibus_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC16Genibus = rb_const_get(mDigest, rb_intern("CRC16Genibus"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_undef_method(cCRC16Genibus, "update");
	rb_define_method(cCRC16Genibus, "update", Digest_CRC16Genibus_update, 1);
}
