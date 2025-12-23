/*
 *  Copyright (C) 2004-2007 Technorama Ltd. <oss-ruby@technorama.net>
 */

#include "ossl.h"

#ifndef OPENSSL_NO_SOCK
VALUE cSSLSession;
static VALUE eSSLSession;

static void
ossl_ssl_session_free(void *ptr)
{
    SSL_SESSION_free(ptr);
}

const rb_data_type_t ossl_ssl_session_type = {
    "OpenSSL/SSL/Session",
    {
	0, ossl_ssl_session_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE ossl_ssl_session_alloc(VALUE klass)
{
	return TypedData_Wrap_Struct(klass, &ossl_ssl_session_type, NULL);
}

/*
 * call-seq:
 *   Session.new(ssl_socket) -> Session
 *   Session.new(string) -> Session
 *
 * Creates a new Session object from an instance of SSLSocket or DER/PEM encoded
 * String.
 */
static VALUE
ossl_ssl_session_initialize(VALUE self, VALUE arg1)
{
    SSL_SESSION *ctx;

    if (RTYPEDDATA_DATA(self))
        ossl_raise(eSSLSession, "SSL Session already initialized");

    if (rb_obj_is_instance_of(arg1, cSSLSocket)) {
        SSL *ssl;

        GetSSL(arg1, ssl);

        if ((ctx = SSL_get1_session(ssl)) == NULL)
            ossl_raise(eSSLSession, "no session available");
    }
    else {
        BIO *in = ossl_obj2bio(&arg1);

        ctx = d2i_SSL_SESSION_bio(in, NULL);
        if (!ctx) {
            OSSL_BIO_reset(in);
            ctx = PEM_read_bio_SSL_SESSION(in, NULL, NULL, NULL);
        }
        BIO_free(in);
        if (!ctx)
            ossl_raise(rb_eArgError, "unknown type");
    }

    RTYPEDDATA_DATA(self) = ctx;

    return self;
}

static VALUE
ossl_ssl_session_initialize_copy(VALUE self, VALUE other)
{
    SSL_SESSION *sess, *sess_other, *sess_new;

    rb_check_frozen(self);
    sess = RTYPEDDATA_DATA(self); /* XXX */
    GetSSLSession(other, sess_other);

    sess_new = ASN1_dup((i2d_of_void *)i2d_SSL_SESSION, (d2i_of_void *)d2i_SSL_SESSION,
			(char *)sess_other);
    if (!sess_new)
	ossl_raise(eSSLSession, "ASN1_dup");

    RTYPEDDATA_DATA(self) = sess_new;
    SSL_SESSION_free(sess);

    return self;
}

static int
ossl_SSL_SESSION_cmp(const SSL_SESSION *a, const SSL_SESSION *b)
{
    unsigned int a_len;
    const unsigned char *a_sid = SSL_SESSION_get_id(a, &a_len);
    unsigned int b_len;
    const unsigned char *b_sid = SSL_SESSION_get_id(b, &b_len);

    if (SSL_SESSION_get_protocol_version(a) != SSL_SESSION_get_protocol_version(b))
	return 1;
    if (a_len != b_len)
	return 1;

    return CRYPTO_memcmp(a_sid, b_sid, a_len);
}

/*
 * call-seq:
 *   session1 == session2 -> boolean
 *
 * Returns +true+ if the two Session is the same, +false+ if not.
 */
static VALUE ossl_ssl_session_eq(VALUE val1, VALUE val2)
{
	SSL_SESSION *ctx1, *ctx2;

	GetSSLSession(val1, ctx1);
	GetSSLSession(val2, ctx2);

	switch (ossl_SSL_SESSION_cmp(ctx1, ctx2)) {
	case 0:		return Qtrue;
	default:	return Qfalse;
	}
}

/*
 * call-seq:
 *    session.time -> Time
 *
 * Returns the time at which the session was established.
 */
static VALUE
ossl_ssl_session_get_time(VALUE self)
{
    SSL_SESSION *ctx;
    long t;

    GetSSLSession(self, ctx);
    t = SSL_SESSION_get_time(ctx);
    if (t == 0)
	return Qnil;

    return rb_funcall(rb_cTime, rb_intern("at"), 1, LONG2NUM(t));
}

/*
 * call-seq:
 *    session.timeout -> Integer
 *
 * Returns the timeout value set for the session, in seconds from the
 * established time.
 *
 */
static VALUE
ossl_ssl_session_get_timeout(VALUE self)
{
    SSL_SESSION *ctx;
    long t;

    GetSSLSession(self, ctx);
    t = SSL_SESSION_get_timeout(ctx);

    return LONG2NUM(t);
}

/*
 * call-seq:
 *    session.time = time
 *    session.time = integer
 *
 * Sets start time of the session. Time resolution is in seconds.
 *
 */
static VALUE ossl_ssl_session_set_time(VALUE self, VALUE time_v)
{
	SSL_SESSION *ctx;
	long t;

	GetSSLSession(self, ctx);
	if (rb_obj_is_instance_of(time_v, rb_cTime)) {
		time_v = rb_funcall(time_v, rb_intern("to_i"), 0);
	}
	t = NUM2LONG(time_v);
	SSL_SESSION_set_time(ctx, t);
	return ossl_ssl_session_get_time(self);
}

/*
 * call-seq:
 *    session.timeout = integer
 *
 * Sets how long until the session expires in seconds.
 */
static VALUE ossl_ssl_session_set_timeout(VALUE self, VALUE time_v)
{
	SSL_SESSION *ctx;
	long t;

	GetSSLSession(self, ctx);
	t = NUM2LONG(time_v);
	SSL_SESSION_set_timeout(ctx, t);
	return ossl_ssl_session_get_timeout(self);
}

/*
 * call-seq:
 *    session.id -> String
 *
 * Returns the Session ID.
*/
static VALUE ossl_ssl_session_get_id(VALUE self)
{
	SSL_SESSION *ctx;
	const unsigned char *p = NULL;
	unsigned int i = 0;

	GetSSLSession(self, ctx);

	p = SSL_SESSION_get_id(ctx, &i);

	return rb_str_new((const char *) p, i);
}

/*
 * call-seq:
 *    session.to_der -> String
 *
 * Returns an ASN1 encoded String that contains the Session object.
 */
static VALUE ossl_ssl_session_to_der(VALUE self)
{
	SSL_SESSION *ctx;
	unsigned char *p;
	int len;
	VALUE str;

	GetSSLSession(self, ctx);
	len = i2d_SSL_SESSION(ctx, NULL);
	if (len <= 0) {
		ossl_raise(eSSLSession, "i2d_SSL_SESSION");
	}

	str = rb_str_new(0, len);
	p = (unsigned char *)RSTRING_PTR(str);
	i2d_SSL_SESSION(ctx, &p);
	ossl_str_adjust(str, p);
	return str;
}

/*
 * call-seq:
 *    session.to_pem -> String
 *
 * Returns a PEM encoded String that contains the Session object.
 */
static VALUE ossl_ssl_session_to_pem(VALUE self)
{
	SSL_SESSION *ctx;
	BIO *out;

	GetSSLSession(self, ctx);

	if (!(out = BIO_new(BIO_s_mem()))) {
		ossl_raise(eSSLSession, "BIO_s_mem()");
	}

	if (!PEM_write_bio_SSL_SESSION(out, ctx)) {
		BIO_free(out);
		ossl_raise(eSSLSession, "SSL_SESSION_print()");
	}


	return ossl_membio2str(out);
}


/*
 * call-seq:
 *    session.to_text -> String
 *
 * Shows everything in the Session object. This is for diagnostic purposes.
 */
static VALUE ossl_ssl_session_to_text(VALUE self)
{
	SSL_SESSION *ctx;
	BIO *out;

	GetSSLSession(self, ctx);

	if (!(out = BIO_new(BIO_s_mem()))) {
		ossl_raise(eSSLSession, "BIO_s_mem()");
	}

	if (!SSL_SESSION_print(out, ctx)) {
		BIO_free(out);
		ossl_raise(eSSLSession, "SSL_SESSION_print()");
	}

	return ossl_membio2str(out);
}

#endif /* !defined(OPENSSL_NO_SOCK) */

void Init_ossl_ssl_session(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    mSSL = rb_define_module_under(mOSSL, "SSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif
#ifndef OPENSSL_NO_SOCK
	cSSLSession = rb_define_class_under(mSSL, "Session", rb_cObject);
	eSSLSession = rb_define_class_under(cSSLSession, "SessionError", eOSSLError);

	rb_define_alloc_func(cSSLSession, ossl_ssl_session_alloc);
	rb_define_method(cSSLSession, "initialize", ossl_ssl_session_initialize, 1);
	rb_define_method(cSSLSession, "initialize_copy", ossl_ssl_session_initialize_copy, 1);

	rb_define_method(cSSLSession, "==", ossl_ssl_session_eq, 1);

	rb_define_method(cSSLSession, "time", ossl_ssl_session_get_time, 0);
	rb_define_method(cSSLSession, "time=", ossl_ssl_session_set_time, 1);
	rb_define_method(cSSLSession, "timeout", ossl_ssl_session_get_timeout, 0);
	rb_define_method(cSSLSession, "timeout=", ossl_ssl_session_set_timeout, 1);
	rb_define_method(cSSLSession, "id", ossl_ssl_session_get_id, 0);
	rb_define_method(cSSLSession, "to_der", ossl_ssl_session_to_der, 0);
	rb_define_method(cSSLSession, "to_pem", ossl_ssl_session_to_pem, 0);
	rb_define_method(cSSLSession, "to_text", ossl_ssl_session_to_text, 0);
#endif /* !defined(OPENSSL_NO_SOCK) */
}
