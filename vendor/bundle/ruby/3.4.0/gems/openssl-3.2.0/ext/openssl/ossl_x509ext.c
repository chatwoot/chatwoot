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

#define NewX509Ext(klass) \
    TypedData_Wrap_Struct((klass), &ossl_x509ext_type, 0)
#define SetX509Ext(obj, ext) do { \
    if (!(ext)) { \
	ossl_raise(rb_eRuntimeError, "EXT wasn't initialized!"); \
    } \
    RTYPEDDATA_DATA(obj) = (ext); \
} while (0)
#define GetX509Ext(obj, ext) do { \
    TypedData_Get_Struct((obj), X509_EXTENSION, &ossl_x509ext_type, (ext)); \
    if (!(ext)) { \
	ossl_raise(rb_eRuntimeError, "EXT wasn't initialized!"); \
    } \
} while (0)
#define MakeX509ExtFactory(klass, obj, ctx) do { \
    (obj) = TypedData_Wrap_Struct((klass), &ossl_x509extfactory_type, 0); \
    if (!((ctx) = OPENSSL_malloc(sizeof(X509V3_CTX)))) \
        ossl_raise(rb_eRuntimeError, "CTX wasn't allocated!"); \
    X509V3_set_ctx((ctx), NULL, NULL, NULL, NULL, 0); \
    RTYPEDDATA_DATA(obj) = (ctx); \
} while (0)
#define GetX509ExtFactory(obj, ctx) do { \
    TypedData_Get_Struct((obj), X509V3_CTX, &ossl_x509extfactory_type, (ctx)); \
    if (!(ctx)) { \
	ossl_raise(rb_eRuntimeError, "CTX wasn't initialized!"); \
    } \
} while (0)

/*
 * Classes
 */
VALUE cX509Ext;
VALUE cX509ExtFactory;
VALUE eX509ExtError;

static void
ossl_x509ext_free(void *ptr)
{
    X509_EXTENSION_free(ptr);
}

static const rb_data_type_t ossl_x509ext_type = {
    "OpenSSL/X509/EXTENSION",
    {
	0, ossl_x509ext_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * Public
 */
VALUE
ossl_x509ext_new(X509_EXTENSION *ext)
{
    X509_EXTENSION *new;
    VALUE obj;

    obj = NewX509Ext(cX509Ext);
    if (!ext) {
	new = X509_EXTENSION_new();
    } else {
	new = X509_EXTENSION_dup(ext);
    }
    if (!new) {
	ossl_raise(eX509ExtError, NULL);
    }
    SetX509Ext(obj, new);

    return obj;
}

X509_EXTENSION *
GetX509ExtPtr(VALUE obj)
{
    X509_EXTENSION *ext;

    GetX509Ext(obj, ext);

    return ext;
}

/*
 * Private
 */
/*
 * Ext factory
 */
static void
ossl_x509extfactory_free(void *ctx)
{
    OPENSSL_free(ctx);
}

static const rb_data_type_t ossl_x509extfactory_type = {
    "OpenSSL/X509/EXTENSION/Factory",
    {
	0, ossl_x509extfactory_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
ossl_x509extfactory_alloc(VALUE klass)
{
    X509V3_CTX *ctx;
    VALUE obj;

    MakeX509ExtFactory(klass, obj, ctx);
    rb_iv_set(obj, "@config", Qnil);

    return obj;
}

static VALUE
ossl_x509extfactory_set_issuer_cert(VALUE self, VALUE cert)
{
    X509V3_CTX *ctx;

    GetX509ExtFactory(self, ctx);
    rb_iv_set(self, "@issuer_certificate", cert);
    ctx->issuer_cert = GetX509CertPtr(cert); /* NO DUP NEEDED */

    return cert;
}

static VALUE
ossl_x509extfactory_set_subject_cert(VALUE self, VALUE cert)
{
    X509V3_CTX *ctx;

    GetX509ExtFactory(self, ctx);
    rb_iv_set(self, "@subject_certificate", cert);
    ctx->subject_cert = GetX509CertPtr(cert); /* NO DUP NEEDED */

    return cert;
}

static VALUE
ossl_x509extfactory_set_subject_req(VALUE self, VALUE req)
{
    X509V3_CTX *ctx;

    GetX509ExtFactory(self, ctx);
    rb_iv_set(self, "@subject_request", req);
    ctx->subject_req = GetX509ReqPtr(req); /* NO DUP NEEDED */

    return req;
}

static VALUE
ossl_x509extfactory_set_crl(VALUE self, VALUE crl)
{
    X509V3_CTX *ctx;

    GetX509ExtFactory(self, ctx);
    rb_iv_set(self, "@crl", crl);
    ctx->crl = GetX509CRLPtr(crl); /* NO DUP NEEDED */

    return crl;
}

static VALUE
ossl_x509extfactory_initialize(int argc, VALUE *argv, VALUE self)
{
    /*X509V3_CTX *ctx;*/
    VALUE issuer_cert, subject_cert, subject_req, crl;

    /*GetX509ExtFactory(self, ctx);*/

    rb_scan_args(argc, argv, "04",
		 &issuer_cert, &subject_cert, &subject_req, &crl);
    if (!NIL_P(issuer_cert))
	ossl_x509extfactory_set_issuer_cert(self, issuer_cert);
    if (!NIL_P(subject_cert))
	ossl_x509extfactory_set_subject_cert(self, subject_cert);
    if (!NIL_P(subject_req))
	ossl_x509extfactory_set_subject_req(self, subject_req);
    if (!NIL_P(crl))
	ossl_x509extfactory_set_crl(self, crl);

    return self;
}

/*
 * call-seq:
 *   ef.create_ext(ln_or_sn, "value", critical = false) -> X509::Extension
 *   ef.create_ext(ln_or_sn, "critical,value")          -> X509::Extension
 *
 * Creates a new X509::Extension with passed values. See also x509v3_config(5).
 */
static VALUE
ossl_x509extfactory_create_ext(int argc, VALUE *argv, VALUE self)
{
    X509V3_CTX *ctx;
    X509_EXTENSION *ext;
    VALUE oid, value, critical, valstr, obj;
    int nid;
    VALUE rconf;
    CONF *conf;
    const char *oid_cstr = NULL;

    rb_scan_args(argc, argv, "21", &oid, &value, &critical);
    StringValue(value);
    if(NIL_P(critical)) critical = Qfalse;

    oid_cstr = StringValueCStr(oid);
    nid = OBJ_ln2nid(oid_cstr);
    if (nid != NID_undef)
      oid_cstr = OBJ_nid2sn(nid);

    valstr = rb_str_new2(RTEST(critical) ? "critical," : "");
    rb_str_append(valstr, value);
    StringValueCStr(valstr);

    GetX509ExtFactory(self, ctx);
    obj = NewX509Ext(cX509Ext);
    rconf = rb_iv_get(self, "@config");
    conf = NIL_P(rconf) ? NULL : GetConfig(rconf);
    X509V3_set_nconf(ctx, conf);

#if OSSL_OPENSSL_PREREQ(1, 1, 0) || OSSL_IS_LIBRESSL
    ext = X509V3_EXT_nconf(conf, ctx, oid_cstr, RSTRING_PTR(valstr));
#else
    ext = X509V3_EXT_nconf(conf, ctx, (char *)oid_cstr, RSTRING_PTR(valstr));
#endif
    X509V3_set_ctx_nodb(ctx);
    if (!ext){
	ossl_raise(eX509ExtError, "%"PRIsVALUE" = %"PRIsVALUE, oid, valstr);
    }
    SetX509Ext(obj, ext);

    return obj;
}

/*
 * Ext
 */
static VALUE
ossl_x509ext_alloc(VALUE klass)
{
    X509_EXTENSION *ext;
    VALUE obj;

    obj = NewX509Ext(klass);
    if(!(ext = X509_EXTENSION_new())){
	ossl_raise(eX509ExtError, NULL);
    }
    SetX509Ext(obj, ext);

    return obj;
}

/*
 * call-seq:
 *    OpenSSL::X509::Extension.new(der)
 *    OpenSSL::X509::Extension.new(oid, value)
 *    OpenSSL::X509::Extension.new(oid, value, critical)
 *
 * Creates an X509 extension.
 *
 * The extension may be created from _der_ data or from an extension _oid_
 * and _value_.  The _oid_ may be either an OID or an extension name.  If
 * _critical_ is +true+ the extension is marked critical.
 */
static VALUE
ossl_x509ext_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE oid, value, critical;
    const unsigned char *p;
    X509_EXTENSION *ext, *x;

    GetX509Ext(self, ext);
    if(rb_scan_args(argc, argv, "12", &oid, &value, &critical) == 1){
	oid = ossl_to_der_if_possible(oid);
	StringValue(oid);
	p = (unsigned char *)RSTRING_PTR(oid);
	x = d2i_X509_EXTENSION(&ext, &p, RSTRING_LEN(oid));
	DATA_PTR(self) = ext;
	if(!x)
	    ossl_raise(eX509ExtError, NULL);
	return self;
    }
    rb_funcall(self, rb_intern("oid="), 1, oid);
    rb_funcall(self, rb_intern("value="), 1, value);
    if(argc > 2) rb_funcall(self, rb_intern("critical="), 1, critical);

    return self;
}

static VALUE
ossl_x509ext_initialize_copy(VALUE self, VALUE other)
{
    X509_EXTENSION *ext, *ext_other, *ext_new;

    rb_check_frozen(self);
    GetX509Ext(self, ext);
    GetX509Ext(other, ext_other);

    ext_new = X509_EXTENSION_dup(ext_other);
    if (!ext_new)
	ossl_raise(eX509ExtError, "X509_EXTENSION_dup");

    SetX509Ext(self, ext_new);
    X509_EXTENSION_free(ext);

    return self;
}

static VALUE
ossl_x509ext_set_oid(VALUE self, VALUE oid)
{
    X509_EXTENSION *ext;
    ASN1_OBJECT *obj;

    GetX509Ext(self, ext);
    obj = OBJ_txt2obj(StringValueCStr(oid), 0);
    if (!obj)
	ossl_raise(eX509ExtError, "OBJ_txt2obj");
    if (!X509_EXTENSION_set_object(ext, obj)) {
	ASN1_OBJECT_free(obj);
	ossl_raise(eX509ExtError, "X509_EXTENSION_set_object");
    }
    ASN1_OBJECT_free(obj);

    return oid;
}

static VALUE
ossl_x509ext_set_value(VALUE self, VALUE data)
{
    X509_EXTENSION *ext;
    ASN1_OCTET_STRING *asn1s;

    GetX509Ext(self, ext);
    data = ossl_to_der_if_possible(data);
    StringValue(data);
    asn1s = X509_EXTENSION_get_data(ext);

    if (!ASN1_OCTET_STRING_set(asn1s, (unsigned char *)RSTRING_PTR(data),
			       RSTRING_LENINT(data))) {
	ossl_raise(eX509ExtError, "ASN1_OCTET_STRING_set");
    }

    return data;
}

static VALUE
ossl_x509ext_set_critical(VALUE self, VALUE flag)
{
    X509_EXTENSION *ext;

    GetX509Ext(self, ext);
    X509_EXTENSION_set_critical(ext, RTEST(flag) ? 1 : 0);

    return flag;
}

static VALUE
ossl_x509ext_get_oid(VALUE obj)
{
    X509_EXTENSION *ext;
    ASN1_OBJECT *extobj;
    BIO *out;
    VALUE ret;
    int nid;

    GetX509Ext(obj, ext);
    extobj = X509_EXTENSION_get_object(ext);
    if ((nid = OBJ_obj2nid(extobj)) != NID_undef)
	ret = rb_str_new2(OBJ_nid2sn(nid));
    else{
	if (!(out = BIO_new(BIO_s_mem())))
	    ossl_raise(eX509ExtError, NULL);
	i2a_ASN1_OBJECT(out, extobj);
	ret = ossl_membio2str(out);
    }

    return ret;
}

static VALUE
ossl_x509ext_get_value(VALUE obj)
{
    X509_EXTENSION *ext;
    BIO *out;
    VALUE ret;

    GetX509Ext(obj, ext);
    if (!(out = BIO_new(BIO_s_mem())))
	ossl_raise(eX509ExtError, NULL);
    if (!X509V3_EXT_print(out, ext, 0, 0))
	ASN1_STRING_print(out, (ASN1_STRING *)X509_EXTENSION_get_data(ext));
    ret = ossl_membio2str(out);

    return ret;
}

static VALUE
ossl_x509ext_get_value_der(VALUE obj)
{
    X509_EXTENSION *ext;
    ASN1_OCTET_STRING *value;

    GetX509Ext(obj, ext);
    if ((value = X509_EXTENSION_get_data(ext)) == NULL)
	ossl_raise(eX509ExtError, NULL);

    return rb_str_new((const char *)value->data, value->length);
}

static VALUE
ossl_x509ext_get_critical(VALUE obj)
{
    X509_EXTENSION *ext;

    GetX509Ext(obj, ext);
    return X509_EXTENSION_get_critical(ext) ? Qtrue : Qfalse;
}

static VALUE
ossl_x509ext_to_der(VALUE obj)
{
    X509_EXTENSION *ext;
    unsigned char *p;
    long len;
    VALUE str;

    GetX509Ext(obj, ext);
    if((len = i2d_X509_EXTENSION(ext, NULL)) <= 0)
	ossl_raise(eX509ExtError, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if(i2d_X509_EXTENSION(ext, &p) < 0)
	ossl_raise(eX509ExtError, NULL);
    ossl_str_adjust(str, p);

    return str;
}

/*
 * INIT
 */
void
Init_ossl_x509ext(void)
{
#undef rb_intern
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
    mX509 = rb_define_module_under(mOSSL, "X509");
#endif

    eX509ExtError = rb_define_class_under(mX509, "ExtensionError", eOSSLError);

    cX509ExtFactory = rb_define_class_under(mX509, "ExtensionFactory", rb_cObject);

    rb_define_alloc_func(cX509ExtFactory, ossl_x509extfactory_alloc);
    rb_define_method(cX509ExtFactory, "initialize", ossl_x509extfactory_initialize, -1);

    rb_attr(cX509ExtFactory, rb_intern("issuer_certificate"), 1, 0, Qfalse);
    rb_attr(cX509ExtFactory, rb_intern("subject_certificate"), 1, 0, Qfalse);
    rb_attr(cX509ExtFactory, rb_intern("subject_request"), 1, 0, Qfalse);
    rb_attr(cX509ExtFactory, rb_intern("crl"), 1, 0, Qfalse);
    rb_attr(cX509ExtFactory, rb_intern("config"), 1, 1, Qfalse);

    rb_define_method(cX509ExtFactory, "issuer_certificate=", ossl_x509extfactory_set_issuer_cert, 1);
    rb_define_method(cX509ExtFactory, "subject_certificate=", ossl_x509extfactory_set_subject_cert, 1);
    rb_define_method(cX509ExtFactory, "subject_request=", ossl_x509extfactory_set_subject_req, 1);
    rb_define_method(cX509ExtFactory, "crl=", ossl_x509extfactory_set_crl, 1);
    rb_define_method(cX509ExtFactory, "create_ext", ossl_x509extfactory_create_ext, -1);

    cX509Ext = rb_define_class_under(mX509, "Extension", rb_cObject);
    rb_define_alloc_func(cX509Ext, ossl_x509ext_alloc);
    rb_define_method(cX509Ext, "initialize", ossl_x509ext_initialize, -1);
    rb_define_method(cX509Ext, "initialize_copy", ossl_x509ext_initialize_copy, 1);
    rb_define_method(cX509Ext, "oid=", ossl_x509ext_set_oid, 1);
    rb_define_method(cX509Ext, "value=", ossl_x509ext_set_value, 1);
    rb_define_method(cX509Ext, "critical=", ossl_x509ext_set_critical, 1);
    rb_define_method(cX509Ext, "oid", ossl_x509ext_get_oid, 0);
    rb_define_method(cX509Ext, "value", ossl_x509ext_get_value, 0);
    rb_define_method(cX509Ext, "value_der", ossl_x509ext_get_value_der, 0);
    rb_define_method(cX509Ext, "critical?", ossl_x509ext_get_critical, 0);
    rb_define_method(cX509Ext, "to_der", ossl_x509ext_to_der, 0);
}
