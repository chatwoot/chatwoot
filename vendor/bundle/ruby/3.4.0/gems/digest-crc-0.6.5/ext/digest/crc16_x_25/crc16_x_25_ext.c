#include <ruby.h>
#include "../compat/ruby.h"

#include "extconf.h"
#include "crc16_x_25.h"

VALUE Digest_CRC16X25_update(VALUE self, VALUE data)
{
	VALUE crc_ivar_name = rb_intern("@crc");
	VALUE crc_ivar = rb_ivar_get(self, crc_ivar_name);
	crc16_t crc = NUM2USHORT(crc_ivar);

	const char *data_ptr = StringValuePtr(data);
	size_t length = RSTRING_LEN(data);

	crc = crc16_x_25_update(crc,data_ptr,length);

	rb_ivar_set(self, crc_ivar_name, USHORT2NUM(crc));
	return self;
}

void Init_crc16_x_25_ext()
{
	VALUE mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
	VALUE cCRC16X25 = rb_const_get(mDigest, rb_intern("CRC16X25"));

	#ifdef HAVE_RB_EXT_RACTOR_SAFE
		rb_ext_ractor_safe(true);
	#endif

	rb_define_method(cCRC16X25, "update", Digest_CRC16X25_update, 1);
}
