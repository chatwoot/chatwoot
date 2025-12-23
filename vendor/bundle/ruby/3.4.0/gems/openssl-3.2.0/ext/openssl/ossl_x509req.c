/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#define NewX509Req(klass) \
    TypedData_Wrap_Struct((klass), &ossl_x509req_type, 0)
#define SetX509Req(obj, req) do { \
    if (!(req)) { \
	ossl_raise(rb_eRuntimeError, "Req wasn't initialized!"); \
    } \
    RTYPEDDATA_DATA(obj) = (req); \
} while (0)
#define GetX509Req(obj, req) do { \
    TypedData_Get_Struct((obj), X509_REQ, &ossl_x509req_type, (req)); \
    if (!(req)) { \
	ossl_raise(rb_eRuntimeError, "Req wasn't initialized!"); \
    } \
} while (0)

/*
 * Classes
 */
VALUE cX509Req;
VALUE eX509ReqError;

static void
ossl_x509req_free(void *ptr)
{
    X509_REQ_free(ptr);
}

static const rb_data_type_t ossl_x509req_type = {
    "OpenSSL/X509/REQ",
    {
	0, ossl_x509req_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * Public functions
 */
X509_REQ *
GetX509ReqPtr(VALUE obj)
{
    X509_REQ *req;

    GetX509Req(obj, req);

    return req;
}

/*
 * Private functions
 */
static VALUE
ossl_x509req_alloc(VALUE klass)
{
    X509_REQ *req;
    VALUE obj;

    obj = NewX509Req(klass);
    if (!(req = X509_REQ_new())) {
	ossl_raise(eX509ReqError, NULL);
    }
    SetX509Req(obj, req);

    return obj;
}

static VALUE
ossl_x509req_initialize(int argc, VALUE *argv, VALUE self)
{
    BIO *in;
    X509_REQ *req, *req_orig = RTYPEDDATA_DATA(self);
    VALUE arg;

    rb_check_frozen(self);
    if (rb_scan_args(argc, argv, "01", &arg) == 0) {
	return self;
    }
    arg = ossl_to_der_if_possible(arg);
    in = ossl_obj2bio(&arg);
    req = d2i_X509_REQ_bio(in, NULL);
    if (!req) {
        OSSL_BIO_reset(in);
        req = PEM_read_bio_X509_REQ(in, NULL, NULL, NULL);
    }
    BIO_free(in);
    if (!req)
        ossl_raise(eX509ReqError, "PEM_read_bio_X509_REQ");

    RTYPEDDATA_DATA(self) = req;
    X509_REQ_free(req_orig);

    return self;
}

static VALUE
ossl_x509req_copy(VALUE self, VALUE other)
{
    X509_REQ *a, *b, *req;

    rb_check_frozen(self);
    if (self == other) return self;
    GetX509Req(self, a);
    GetX509Req(other, b);
    if (!(req = X509_REQ_dup(b))) {
	ossl_raise(eX509ReqError, NULL);
    }
    X509_REQ_free(a);
    DATA_PTR(self) = req;

    return self;
}

static VALUE
ossl_x509req_to_pem(VALUE self)
{
    X509_REQ *req;
    BIO *out;

    GetX509Req(self, req);
    if (!(out = BIO_new(BIO_s_mem()))) {
	ossl_raise(eX509ReqError, NULL);
    }
    if (!PEM_write_bio_X509_REQ(out, req)) {
	BIO_free(out);
	ossl_raise(eX509ReqError, NULL);
    }

    return ossl_membio2str(out);
}

static VALUE
ossl_x509req_to_der(VALUE self)
{
    X509_REQ *req;
    VALUE str;
    long len;
    unsigned char *p;

    GetX509Req(self, req);
    if ((len = i2d_X509_REQ(req, NULL)) <= 0)
	ossl_raise(eX509ReqError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if (i2d_X509_REQ(req, &p) <= 0)
	ossl_raise(eX509ReqError, NULL);
    ossl_str_adjust(str, p);

    return str;
}

static VALUE
ossl_x509req_to_text(VALUE self)
{
    X509_REQ *req;
    BIO *out;

    GetX509Req(self, req);
    if (!(out = BIO_new(BIO_s_mem()))) {
	ossl_raise(eX509ReqError, NULL);
    }
    if (!X509_REQ_print(out, req)) {
	BIO_free(out);
	ossl_raise(eX509ReqError, NULL);
    }

    return ossl_membio2str(out);
}

#if 0
/*
 * Makes X509 from X509_REQuest
 */
static VALUE
ossl_x509req_to_x509(VALUE self, VALUE days, VALUE key)
{
    X509_REQ *req;
    X509 *x509;

    GetX509Req(self, req);
    ...
    if (!(x509 = X509_REQ_to_X509(req, d, pkey))) {
	ossl_raise(eX509ReqError, NULL);
    }

    return ossl_x509_new(x509);
}
#endif

static VALUE
ossl_x509req_get_version(VALUE self)
{
    X509_REQ *req;
    long version;

    GetX509Req(self, req);
    version = X509_REQ_get_version(req);

    return LONG2NUM(version);
}

static VALUE
ossl_x509req_set_version(VALUE self, VALUE version)
{
    X509_REQ *req;
    long ver;

    if ((ver = NUM2LONG(version)) < 0) {
	ossl_raise(eX509ReqError, "version must be >= 0!");
    }
    GetX509Req(self, req);
    if (!X509_REQ_set_version(req, ver)) {
	ossl_raise(eX509ReqError, "X509_REQ_set_version");
    }

    return version;
}

static VALUE
ossl_x509req_get_subject(VALUE self)
{
    X509_REQ *req;
    X509_NAME *name;

    GetX509Req(self, req);
    if (!(name = X509_REQ_get_subject_name(req))) { /* NO DUP - don't free */
	ossl_raise(eX509ReqError, NULL);
    }

    return ossl_x509name_new(name);
}

static VALUE
ossl_x509req_set_subject(VALUE self, VALUE subject)
{
    X509_REQ *req;

    GetX509Req(self, req);
    /* DUPs name */
    if (!X509_REQ_set_subject_name(req, GetX509NamePtr(subject))) {
	ossl_raise(eX509ReqError, NULL);
    }

    return subject;
}

static VALUE
ossl_x509req_get_signature_algorithm(VALUE self)
{
    X509_REQ *req;
    const X509_ALGOR *alg;
    BIO *out;

    GetX509Req(self, req);

    if (!(out = BIO_new(BIO_s_mem()))) {
	ossl_raise(eX509ReqError, NULL);
    }
    X509_REQ_get0_signature(req, NULL, &alg);
    if (!i2a_ASN1_OBJECT(out, alg->algorithm)) {
	BIO_free(out);
	ossl_raise(eX509ReqError, NULL);
    }

    return ossl_membio2str(out);
}

static VALUE
ossl_x509req_get_public_key(VALUE self)
{
    X509_REQ *req;
    EVP_PKEY *pkey;

    GetX509Req(self, req);
    if (!(pkey = X509_REQ_get_pubkey(req))) { /* adds reference */
	ossl_raise(eX509ReqError, NULL);
    }

    return ossl_pkey_new(pkey); /* NO DUP - OK */
}

static VALUE
ossl_x509req_set_public_key(VALUE self, VALUE key)
{
    X509_REQ *req;
    EVP_PKEY *pkey;

    GetX509Req(self, req);
    pkey = GetPKeyPtr(key);
    ossl_pkey_check_public_key(pkey);
    if (!X509_REQ_set_pubkey(req, pkey))
	ossl_raise(eX509ReqError, "X509_REQ_set_pubkey");
    return key;
}

static VALUE
ossl_x509req_sign(VALUE self, VALUE key, VALUE digest)
{
    X509_REQ *req;
    EVP_PKEY *pkey;
    const EVP_MD *md;

    GetX509Req(self, req);
    pkey = GetPrivPKeyPtr(key); /* NO NEED TO DUP */
    md = ossl_evp_get_digestbyname(digest);
    if (!X509_REQ_sign(req, pkey, md)) {
	ossl_raise(eX509ReqError, NULL);
    }

    return self;
}

/*
 * Checks that cert signature is made with PRIVversion of this PUBLIC 'key'
 */
static VALUE
ossl_x509req_verify(VALUE self, VALUE key)
{
    X509_REQ *req;
    EVP_PKEY *pkey;

    GetX509Req(self, req);
    pkey = GetPKeyPtr(key);
    ossl_pkey_check_public_key(pkey);
    switch (X509_REQ_verify(req, pkey)) {
      case 1:
	return Qtrue;
      case 0:
	ossl_clear_error();
	return Qfalse;
      default:
	ossl_raise(eX509ReqError, NULL);
    }
}

static VALUE
ossl_x509req_get_attributes(VALUE self)
{
    X509_REQ *req;
    int count, i;
    X509_ATTRIBUTE *attr;
    VALUE ary;

    GetX509Req(self, req);

    count = X509_REQ_get_attr_count(req);
    if (count < 0) {
	OSSL_Debug("count < 0???");
	return rb_ary_new();
    }
    ary = rb_ary_new2(count);
    for (i=0; i<count; i++) {
	attr = X509_REQ_get_attr(req, i);
	rb_ary_push(ary, ossl_x509attr_new(attr));
    }

    return ary;
}

static VALUE
ossl_x509req_set_attributes(VALUE self, VALUE ary)
{
    X509_REQ *req;
    X509_ATTRIBUTE *attr;
    long i;
    VALUE item;

    Check_Type(ary, T_ARRAY);
    for (i=0;i<RARRAY_LEN(ary); i++) {
	OSSL_Check_Kind(RARRAY_AREF(ary, i), cX509Attr);
    }
    GetX509Req(self, req);
    for (i = X509_REQ_get_attr_count(req); i > 0; i--)
        X509_ATTRIBUTE_free(X509_REQ_delete_attr(req, 0));
    for (i=0;i<RARRAY_LEN(ary); i++) {
	item = RARRAY_AREF(ary, i);
	attr = GetX509AttrPtr(item);
	if (!X509_REQ_add1_attr(req, attr)) {
	    ossl_raise(eX509ReqError, "X509_REQ_add1_attr");
	}
    }
    return ary;
}

static VALUE
ossl_x509req_add_attribute(VALUE self, VALUE attr)
{
    X509_REQ *req;

    GetX509Req(self, req);
    if (!X509_REQ_add1_attr(req, GetX509AttrPtr(attr))) {
	ossl_raise(eX509ReqError, NULL);
    }

    return attr;
}

/*
 * X509_REQUEST init
 */
void
Init_ossl_x509req(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
    mX509 = rb_define_module_under(mOSSL, "X509");
#endif

    eX509ReqError = rb_define_class_under(mX509, "RequestError", eOSSLError);

    cX509Req = rb_define_class_under(mX509, "Request", rb_cObject);

    rb_define_alloc_func(cX509Req, ossl_x509req_alloc);
    rb_define_method(cX509Req, "initialize", ossl_x509req_initialize, -1);
    rb_define_method(cX509Req, "initialize_copy", ossl_x509req_copy, 1);

    rb_define_method(cX509Req, "to_pem", ossl_x509req_to_pem, 0);
    rb_define_method(cX509Req, "to_der", ossl_x509req_to_der, 0);
    rb_define_alias(cX509Req, "to_s", "to_pem");
    rb_define_method(cX509Req, "to_text", ossl_x509req_to_text, 0);
    rb_define_method(cX509Req, "version", ossl_x509req_get_version, 0);
    rb_define_method(cX509Req, "version=", ossl_x509req_set_version, 1);
    rb_define_method(cX509Req, "subject", ossl_x509req_get_subject, 0);
    rb_define_method(cX509Req, "subject=", ossl_x509req_set_subject, 1);
    rb_define_method(cX509Req, "signature_algorithm", ossl_x509req_get_signature_algorithm, 0);
    rb_define_method(cX509Req, "public_key", ossl_x509req_get_public_key, 0);
    rb_define_method(cX509Req, "public_key=", ossl_x509req_set_public_key, 1);
    rb_define_method(cX509Req, "sign", ossl_x509req_sign, 2);
    rb_define_method(cX509Req, "verify", ossl_x509req_verify, 1);
    rb_define_method(cX509Req, "attributes", ossl_x509req_get_attributes, 0);
    rb_define_method(cX509Req, "attributes=", ossl_x509req_set_attributes, 1);
    rb_define_method(cX509Req, "add_attribute", ossl_x509req_add_attribute, 1);
}
