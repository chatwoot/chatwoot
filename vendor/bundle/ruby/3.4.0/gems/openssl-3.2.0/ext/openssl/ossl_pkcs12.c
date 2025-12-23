/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include "ossl.h"

#define NewPKCS12(klass) \
    TypedData_Wrap_Struct((klass), &ossl_pkcs12_type, 0)

#define SetPKCS12(obj, p12) do { \
    if(!(p12)) ossl_raise(rb_eRuntimeError, "PKCS12 wasn't initialized."); \
    RTYPEDDATA_DATA(obj) = (p12); \
} while (0)

#define GetPKCS12(obj, p12) do { \
    TypedData_Get_Struct((obj), PKCS12, &ossl_pkcs12_type, (p12)); \
    if(!(p12)) ossl_raise(rb_eRuntimeError, "PKCS12 wasn't initialized."); \
} while (0)

#define ossl_pkcs12_set_key(o,v)      rb_iv_set((o), "@key", (v))
#define ossl_pkcs12_set_cert(o,v)     rb_iv_set((o), "@certificate", (v))
#define ossl_pkcs12_set_ca_certs(o,v) rb_iv_set((o), "@ca_certs", (v))
#define ossl_pkcs12_get_key(o)        rb_iv_get((o), "@key")
#define ossl_pkcs12_get_cert(o)       rb_iv_get((o), "@certificate")
#define ossl_pkcs12_get_ca_certs(o)   rb_iv_get((o), "@ca_certs")

/*
 * Classes
 */
VALUE cPKCS12;
VALUE ePKCS12Error;

/*
 * Private
 */
static void
ossl_pkcs12_free(void *ptr)
{
    PKCS12_free(ptr);
}

static const rb_data_type_t ossl_pkcs12_type = {
    "OpenSSL/PKCS12",
    {
	0, ossl_pkcs12_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
ossl_pkcs12_s_allocate(VALUE klass)
{
    PKCS12 *p12;
    VALUE obj;

    obj = NewPKCS12(klass);
    if(!(p12 = PKCS12_new())) ossl_raise(ePKCS12Error, NULL);
    SetPKCS12(obj, p12);

    return obj;
}

static VALUE
ossl_pkcs12_initialize_copy(VALUE self, VALUE other)
{
    PKCS12 *p12, *p12_old, *p12_new;

    rb_check_frozen(self);
    GetPKCS12(self, p12_old);
    GetPKCS12(other, p12);

    p12_new = ASN1_dup((i2d_of_void *)i2d_PKCS12, (d2i_of_void *)d2i_PKCS12, (char *)p12);
    if (!p12_new)
	ossl_raise(ePKCS12Error, "ASN1_dup");

    SetPKCS12(self, p12_new);
    PKCS12_free(p12_old);

    return self;
}

/*
 * call-seq:
 *    PKCS12.create(pass, name, key, cert [, ca, [, key_pbe [, cert_pbe [, key_iter [, mac_iter [, keytype]]]]]])
 *
 * === Parameters
 * * _pass_ - string
 * * _name_ - A string describing the key.
 * * _key_ - Any PKey.
 * * _cert_ - A X509::Certificate.
 *   * The public_key portion of the certificate must contain a valid public key.
 *   * The not_before and not_after fields must be filled in.
 * * _ca_ - An optional array of X509::Certificate's.
 * * _key_pbe_ - string
 * * _cert_pbe_ - string
 * * _key_iter_ - integer
 * * _mac_iter_ - integer
 * * _keytype_ - An integer representing an MSIE specific extension.
 *
 * Any optional arguments may be supplied as +nil+ to preserve the OpenSSL defaults.
 *
 * See the OpenSSL documentation for PKCS12_create().
 */
static VALUE
ossl_pkcs12_s_create(int argc, VALUE *argv, VALUE self)
{
    VALUE pass, name, pkey, cert, ca, key_nid, cert_nid, key_iter, mac_iter, keytype;
    VALUE obj;
    char *passphrase, *friendlyname;
    EVP_PKEY *key;
    X509 *x509;
    STACK_OF(X509) *x509s;
    int nkey = 0, ncert = 0, kiter = 0, miter = 0, ktype = 0;
    PKCS12 *p12;

    rb_scan_args(argc, argv, "46", &pass, &name, &pkey, &cert, &ca, &key_nid, &cert_nid, &key_iter, &mac_iter, &keytype);
    passphrase = NIL_P(pass) ? NULL : StringValueCStr(pass);
    friendlyname = NIL_P(name) ? NULL : StringValueCStr(name);
    key = GetPKeyPtr(pkey);
    x509 = GetX509CertPtr(cert);
/* TODO: make a VALUE to nid function */
    if (!NIL_P(key_nid)) {
        if ((nkey = OBJ_txt2nid(StringValueCStr(key_nid))) == NID_undef)
	    ossl_raise(rb_eArgError, "Unknown PBE algorithm %"PRIsVALUE, key_nid);
    }
    if (!NIL_P(cert_nid)) {
        if ((ncert = OBJ_txt2nid(StringValueCStr(cert_nid))) == NID_undef)
	    ossl_raise(rb_eArgError, "Unknown PBE algorithm %"PRIsVALUE, cert_nid);
    }
    if (!NIL_P(key_iter))
        kiter = NUM2INT(key_iter);
    if (!NIL_P(mac_iter))
        miter = NUM2INT(mac_iter);
    if (!NIL_P(keytype))
        ktype = NUM2INT(keytype);

    obj = NewPKCS12(cPKCS12);
    x509s = NIL_P(ca) ? NULL : ossl_x509_ary2sk(ca);
    p12 = PKCS12_create(passphrase, friendlyname, key, x509, x509s,
                        nkey, ncert, kiter, miter, ktype);
    sk_X509_pop_free(x509s, X509_free);
    if(!p12) ossl_raise(ePKCS12Error, NULL);
    SetPKCS12(obj, p12);

    ossl_pkcs12_set_key(obj, pkey);
    ossl_pkcs12_set_cert(obj, cert);
    ossl_pkcs12_set_ca_certs(obj, ca);

    return obj;
}

static VALUE
ossl_pkey_new_i(VALUE arg)
{
    return ossl_pkey_new((EVP_PKEY *)arg);
}

static VALUE
ossl_x509_new_i(VALUE arg)
{
    return ossl_x509_new((X509 *)arg);
}

static VALUE
ossl_x509_sk2ary_i(VALUE arg)
{
    return ossl_x509_sk2ary((STACK_OF(X509) *)arg);
}

/*
 * call-seq:
 *    PKCS12.new -> pkcs12
 *    PKCS12.new(str) -> pkcs12
 *    PKCS12.new(str, pass) -> pkcs12
 *
 * === Parameters
 * * _str_ - Must be a DER encoded PKCS12 string.
 * * _pass_ - string
 */
static VALUE
ossl_pkcs12_initialize(int argc, VALUE *argv, VALUE self)
{
    BIO *in;
    VALUE arg, pass, pkey, cert, ca;
    char *passphrase;
    EVP_PKEY *key;
    X509 *x509;
    STACK_OF(X509) *x509s = NULL;
    int st = 0;
    PKCS12 *pkcs = DATA_PTR(self);

    if(rb_scan_args(argc, argv, "02", &arg, &pass) == 0) return self;
    passphrase = NIL_P(pass) ? NULL : StringValueCStr(pass);
    in = ossl_obj2bio(&arg);
    d2i_PKCS12_bio(in, &pkcs);
    DATA_PTR(self) = pkcs;
    BIO_free(in);

    pkey = cert = ca = Qnil;
    /* OpenSSL's bug; PKCS12_parse() puts errors even if it succeeds.
     * Fixed in OpenSSL 1.0.0t, 1.0.1p, 1.0.2d */
    ERR_set_mark();
    if(!PKCS12_parse(pkcs, passphrase, &key, &x509, &x509s))
	ossl_raise(ePKCS12Error, "PKCS12_parse");
    ERR_pop_to_mark();
    if (key) {
	pkey = rb_protect(ossl_pkey_new_i, (VALUE)key, &st);
	if (st) goto err;
    }
    if (x509) {
	cert = rb_protect(ossl_x509_new_i, (VALUE)x509, &st);
	if (st) goto err;
    }
    if (x509s) {
	ca = rb_protect(ossl_x509_sk2ary_i, (VALUE)x509s, &st);
	if (st) goto err;
    }

  err:
    X509_free(x509);
    sk_X509_pop_free(x509s, X509_free);
    ossl_pkcs12_set_key(self, pkey);
    ossl_pkcs12_set_cert(self, cert);
    ossl_pkcs12_set_ca_certs(self, ca);
    if(st) rb_jump_tag(st);

    return self;
}

static VALUE
ossl_pkcs12_to_der(VALUE self)
{
    PKCS12 *p12;
    VALUE str;
    long len;
    unsigned char *p;

    GetPKCS12(self, p12);
    if((len = i2d_PKCS12(p12, NULL)) <= 0)
	ossl_raise(ePKCS12Error, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if(i2d_PKCS12(p12, &p) <= 0)
	ossl_raise(ePKCS12Error, NULL);
    ossl_str_adjust(str, p);

    return str;
}

void
Init_ossl_pkcs12(void)
{
#undef rb_intern
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    /*
     * Defines a file format commonly used to store private keys with
     * accompanying public key certificates, protected with a password-based
     * symmetric key.
     */
    cPKCS12 = rb_define_class_under(mOSSL, "PKCS12", rb_cObject);
    ePKCS12Error = rb_define_class_under(cPKCS12, "PKCS12Error", eOSSLError);
    rb_define_singleton_method(cPKCS12, "create", ossl_pkcs12_s_create, -1);

    rb_define_alloc_func(cPKCS12, ossl_pkcs12_s_allocate);
    rb_define_method(cPKCS12, "initialize_copy", ossl_pkcs12_initialize_copy, 1);
    rb_attr(cPKCS12, rb_intern("key"), 1, 0, Qfalse);
    rb_attr(cPKCS12, rb_intern("certificate"), 1, 0, Qfalse);
    rb_attr(cPKCS12, rb_intern("ca_certs"), 1, 0, Qfalse);
    rb_define_method(cPKCS12, "initialize", ossl_pkcs12_initialize, -1);
    rb_define_method(cPKCS12, "to_der", ossl_pkcs12_to_der, 0);
}
