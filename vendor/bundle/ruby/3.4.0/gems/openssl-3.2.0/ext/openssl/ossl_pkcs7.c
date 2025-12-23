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

#define NewPKCS7si(klass) \
    TypedData_Wrap_Struct((klass), &ossl_pkcs7_signer_info_type, 0)
#define SetPKCS7si(obj, p7si) do { \
    if (!(p7si)) { \
	ossl_raise(rb_eRuntimeError, "PKCS7si wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (p7si); \
} while (0)
#define GetPKCS7si(obj, p7si) do { \
    TypedData_Get_Struct((obj), PKCS7_SIGNER_INFO, &ossl_pkcs7_signer_info_type, (p7si)); \
    if (!(p7si)) { \
	ossl_raise(rb_eRuntimeError, "PKCS7si wasn't initialized."); \
    } \
} while (0)

#define NewPKCS7ri(klass) \
    TypedData_Wrap_Struct((klass), &ossl_pkcs7_recip_info_type, 0)
#define SetPKCS7ri(obj, p7ri) do { \
    if (!(p7ri)) { \
	ossl_raise(rb_eRuntimeError, "PKCS7ri wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (p7ri); \
} while (0)
#define GetPKCS7ri(obj, p7ri) do { \
    TypedData_Get_Struct((obj), PKCS7_RECIP_INFO, &ossl_pkcs7_recip_info_type, (p7ri)); \
    if (!(p7ri)) { \
	ossl_raise(rb_eRuntimeError, "PKCS7ri wasn't initialized."); \
    } \
} while (0)

#define numberof(ary) (int)(sizeof(ary)/sizeof((ary)[0]))

#define ossl_pkcs7_set_data(o,v)       rb_iv_set((o), "@data", (v))
#define ossl_pkcs7_get_data(o)         rb_iv_get((o), "@data")
#define ossl_pkcs7_set_err_string(o,v) rb_iv_set((o), "@error_string", (v))
#define ossl_pkcs7_get_err_string(o)   rb_iv_get((o), "@error_string")

/*
 * Classes
 */
VALUE cPKCS7;
VALUE cPKCS7Signer;
VALUE cPKCS7Recipient;
VALUE ePKCS7Error;

static void
ossl_pkcs7_free(void *ptr)
{
    PKCS7_free(ptr);
}

const rb_data_type_t ossl_pkcs7_type = {
    "OpenSSL/PKCS7",
    {
	0, ossl_pkcs7_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_pkcs7_signer_info_free(void *ptr)
{
    PKCS7_SIGNER_INFO_free(ptr);
}

static const rb_data_type_t ossl_pkcs7_signer_info_type = {
    "OpenSSL/PKCS7/SIGNER_INFO",
    {
	0, ossl_pkcs7_signer_info_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static void
ossl_pkcs7_recip_info_free(void *ptr)
{
    PKCS7_RECIP_INFO_free(ptr);
}

static const rb_data_type_t ossl_pkcs7_recip_info_type = {
    "OpenSSL/PKCS7/RECIP_INFO",
    {
	0, ossl_pkcs7_recip_info_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * Public
 * (MADE PRIVATE UNTIL SOMEBODY WILL NEED THEM)
 */
static PKCS7_SIGNER_INFO *
ossl_PKCS7_SIGNER_INFO_dup(PKCS7_SIGNER_INFO *si)
{
    PKCS7_SIGNER_INFO *si_new = ASN1_dup((i2d_of_void *)i2d_PKCS7_SIGNER_INFO,
                                         (d2i_of_void *)d2i_PKCS7_SIGNER_INFO,
                                         si);
    if (si_new && si->pkey) {
        EVP_PKEY_up_ref(si->pkey);
        si_new->pkey = si->pkey;
    }
    return si_new;
}

static PKCS7_RECIP_INFO *
ossl_PKCS7_RECIP_INFO_dup(PKCS7_RECIP_INFO *si)
{
    return ASN1_dup((i2d_of_void *)i2d_PKCS7_RECIP_INFO,
                    (d2i_of_void *)d2i_PKCS7_RECIP_INFO,
                    si);
}

static VALUE
ossl_pkcs7si_new(PKCS7_SIGNER_INFO *p7si)
{
    PKCS7_SIGNER_INFO *pkcs7;
    VALUE obj;

    obj = NewPKCS7si(cPKCS7Signer);
    pkcs7 = p7si ? ossl_PKCS7_SIGNER_INFO_dup(p7si) : PKCS7_SIGNER_INFO_new();
    if (!pkcs7) ossl_raise(ePKCS7Error, NULL);
    SetPKCS7si(obj, pkcs7);

    return obj;
}

static VALUE
ossl_pkcs7ri_new(PKCS7_RECIP_INFO *p7ri)
{
    PKCS7_RECIP_INFO *pkcs7;
    VALUE obj;

    obj = NewPKCS7ri(cPKCS7Recipient);
    pkcs7 = p7ri ? ossl_PKCS7_RECIP_INFO_dup(p7ri) : PKCS7_RECIP_INFO_new();
    if (!pkcs7) ossl_raise(ePKCS7Error, NULL);
    SetPKCS7ri(obj, pkcs7);

    return obj;
}

/*
 * call-seq:
 *    PKCS7.read_smime(string) => pkcs7
 */
static VALUE
ossl_pkcs7_s_read_smime(VALUE klass, VALUE arg)
{
    BIO *in, *out;
    PKCS7 *pkcs7;
    VALUE ret, data;

    ret = NewPKCS7(cPKCS7);
    in = ossl_obj2bio(&arg);
    out = NULL;
    pkcs7 = SMIME_read_PKCS7(in, &out);
    BIO_free(in);
    if(!pkcs7) ossl_raise(ePKCS7Error, NULL);
    data = out ? ossl_membio2str(out) : Qnil;
    SetPKCS7(ret, pkcs7);
    ossl_pkcs7_set_data(ret, data);
    ossl_pkcs7_set_err_string(ret, Qnil);

    return ret;
}

/*
 * call-seq:
 *    PKCS7.write_smime(pkcs7 [, data [, flags]]) => string
 */
static VALUE
ossl_pkcs7_s_write_smime(int argc, VALUE *argv, VALUE klass)
{
    VALUE pkcs7, data, flags;
    BIO *out, *in;
    PKCS7 *p7;
    VALUE str;
    int flg;

    rb_scan_args(argc, argv, "12", &pkcs7, &data, &flags);
    flg = NIL_P(flags) ? 0 : NUM2INT(flags);
    if(NIL_P(data)) data = ossl_pkcs7_get_data(pkcs7);
    GetPKCS7(pkcs7, p7);
    if(!NIL_P(data) && PKCS7_is_detached(p7))
	flg |= PKCS7_DETACHED;
    in = NIL_P(data) ? NULL : ossl_obj2bio(&data);
    if(!(out = BIO_new(BIO_s_mem()))){
        BIO_free(in);
        ossl_raise(ePKCS7Error, NULL);
    }
    if(!SMIME_write_PKCS7(out, p7, in, flg)){
        BIO_free(out);
        BIO_free(in);
        ossl_raise(ePKCS7Error, NULL);
    }
    BIO_free(in);
    str = ossl_membio2str(out);

    return str;
}

/*
 * call-seq:
 *    PKCS7.sign(cert, key, data, [, certs [, flags]]) => pkcs7
 */
static VALUE
ossl_pkcs7_s_sign(int argc, VALUE *argv, VALUE klass)
{
    VALUE cert, key, data, certs, flags;
    X509 *x509;
    EVP_PKEY *pkey;
    BIO *in;
    STACK_OF(X509) *x509s;
    int flg, status = 0;
    PKCS7 *pkcs7;
    VALUE ret;

    rb_scan_args(argc, argv, "32", &cert, &key, &data, &certs, &flags);
    x509 = GetX509CertPtr(cert); /* NO NEED TO DUP */
    pkey = GetPrivPKeyPtr(key); /* NO NEED TO DUP */
    flg = NIL_P(flags) ? 0 : NUM2INT(flags);
    ret = NewPKCS7(cPKCS7);
    in = ossl_obj2bio(&data);
    if(NIL_P(certs)) x509s = NULL;
    else{
	x509s = ossl_protect_x509_ary2sk(certs, &status);
	if(status){
	    BIO_free(in);
	    rb_jump_tag(status);
	}
    }
    if(!(pkcs7 = PKCS7_sign(x509, pkey, x509s, in, flg))){
	BIO_free(in);
	sk_X509_pop_free(x509s, X509_free);
	ossl_raise(ePKCS7Error, NULL);
    }
    SetPKCS7(ret, pkcs7);
    ossl_pkcs7_set_data(ret, data);
    ossl_pkcs7_set_err_string(ret, Qnil);
    BIO_free(in);
    sk_X509_pop_free(x509s, X509_free);

    return ret;
}

/*
 * call-seq:
 *    PKCS7.encrypt(certs, data, [, cipher [, flags]]) => pkcs7
 */
static VALUE
ossl_pkcs7_s_encrypt(int argc, VALUE *argv, VALUE klass)
{
    VALUE certs, data, cipher, flags;
    STACK_OF(X509) *x509s;
    BIO *in;
    const EVP_CIPHER *ciph;
    int flg, status = 0;
    VALUE ret;
    PKCS7 *p7;

    rb_scan_args(argc, argv, "22", &certs, &data, &cipher, &flags);
    if(NIL_P(cipher)){
#if !defined(OPENSSL_NO_RC2)
	ciph = EVP_rc2_40_cbc();
#elif !defined(OPENSSL_NO_DES)
	ciph = EVP_des_ede3_cbc();
#elif !defined(OPENSSL_NO_RC2)
	ciph = EVP_rc2_40_cbc();
#elif !defined(OPENSSL_NO_AES)
	ciph = EVP_EVP_aes_128_cbc();
#else
	ossl_raise(ePKCS7Error, "Must specify cipher");
#endif

    }
    else ciph = ossl_evp_get_cipherbyname(cipher);
    flg = NIL_P(flags) ? 0 : NUM2INT(flags);
    ret = NewPKCS7(cPKCS7);
    in = ossl_obj2bio(&data);
    x509s = ossl_protect_x509_ary2sk(certs, &status);
    if(status){
	BIO_free(in);
	rb_jump_tag(status);
    }
    if(!(p7 = PKCS7_encrypt(x509s, in, (EVP_CIPHER*)ciph, flg))){
	BIO_free(in);
	sk_X509_pop_free(x509s, X509_free);
	ossl_raise(ePKCS7Error, NULL);
    }
    BIO_free(in);
    SetPKCS7(ret, p7);
    ossl_pkcs7_set_data(ret, data);
    sk_X509_pop_free(x509s, X509_free);

    return ret;
}

static VALUE
ossl_pkcs7_alloc(VALUE klass)
{
    PKCS7 *pkcs7;
    VALUE obj;

    obj = NewPKCS7(klass);
    if (!(pkcs7 = PKCS7_new())) {
	ossl_raise(ePKCS7Error, NULL);
    }
    SetPKCS7(obj, pkcs7);

    return obj;
}

/*
 * call-seq:
 *    PKCS7.new => pkcs7
 *    PKCS7.new(string) => pkcs7
 *
 * Many methods in this class aren't documented.
 */
static VALUE
ossl_pkcs7_initialize(int argc, VALUE *argv, VALUE self)
{
    PKCS7 *p7, *p7_orig = RTYPEDDATA_DATA(self);
    BIO *in;
    VALUE arg;

    if(rb_scan_args(argc, argv, "01", &arg) == 0)
	return self;
    arg = ossl_to_der_if_possible(arg);
    in = ossl_obj2bio(&arg);
    p7 = d2i_PKCS7_bio(in, NULL);
    if (!p7) {
        OSSL_BIO_reset(in);
        p7 = PEM_read_bio_PKCS7(in, NULL, NULL, NULL);
    }
    BIO_free(in);
    if (!p7)
        ossl_raise(rb_eArgError, "Could not parse the PKCS7");

    RTYPEDDATA_DATA(self) = p7;
    PKCS7_free(p7_orig);
    ossl_pkcs7_set_data(self, Qnil);
    ossl_pkcs7_set_err_string(self, Qnil);

    return self;
}

static VALUE
ossl_pkcs7_copy(VALUE self, VALUE other)
{
    PKCS7 *a, *b, *pkcs7;

    rb_check_frozen(self);
    if (self == other) return self;

    GetPKCS7(self, a);
    GetPKCS7(other, b);

    pkcs7 = PKCS7_dup(b);
    if (!pkcs7) {
	ossl_raise(ePKCS7Error, NULL);
    }
    DATA_PTR(self) = pkcs7;
    PKCS7_free(a);

    return self;
}

static int
ossl_pkcs7_sym2typeid(VALUE sym)
{
    int i, ret = Qnil;
    const char *s;
    size_t l;

    static const struct {
        char name[20];
        int nid;
    } p7_type_tab[] = {
        { "signed",             NID_pkcs7_signed },
        { "data",               NID_pkcs7_data },
        { "signedAndEnveloped", NID_pkcs7_signedAndEnveloped },
        { "enveloped",          NID_pkcs7_enveloped },
        { "encrypted",          NID_pkcs7_encrypted },
        { "digest",             NID_pkcs7_digest },
    };

    if (SYMBOL_P(sym)) sym = rb_sym2str(sym);
    else StringValue(sym);
    RSTRING_GETMEM(sym, s, l);

    for(i = 0; ; i++){
	if(i == numberof(p7_type_tab))
	    ossl_raise(ePKCS7Error, "unknown type \"%"PRIsVALUE"\"", sym);
	if(strlen(p7_type_tab[i].name) != l) continue;
	if(strcmp(p7_type_tab[i].name, s) == 0){
	    ret = p7_type_tab[i].nid;
	    break;
	}
    }

    return ret;
}

/*
 * call-seq:
 *    pkcs7.type = type => type
 */
static VALUE
ossl_pkcs7_set_type(VALUE self, VALUE type)
{
    PKCS7 *p7;

    GetPKCS7(self, p7);
    if(!PKCS7_set_type(p7, ossl_pkcs7_sym2typeid(type)))
	ossl_raise(ePKCS7Error, NULL);

    return type;
}

/*
 * call-seq:
 *    pkcs7.type => string or nil
 */
static VALUE
ossl_pkcs7_get_type(VALUE self)
{
    PKCS7 *p7;

    GetPKCS7(self, p7);
    if(PKCS7_type_is_signed(p7))
	return ID2SYM(rb_intern("signed"));
    if(PKCS7_type_is_encrypted(p7))
	return ID2SYM(rb_intern("encrypted"));
    if(PKCS7_type_is_enveloped(p7))
	return ID2SYM(rb_intern("enveloped"));
    if(PKCS7_type_is_signedAndEnveloped(p7))
	return ID2SYM(rb_intern("signedAndEnveloped"));
    if(PKCS7_type_is_data(p7))
	return ID2SYM(rb_intern("data"));
    return Qnil;
}

static VALUE
ossl_pkcs7_set_detached(VALUE self, VALUE flag)
{
    PKCS7 *p7;

    GetPKCS7(self, p7);
    if(flag != Qtrue && flag != Qfalse)
	ossl_raise(ePKCS7Error, "must specify a boolean");
    if(!PKCS7_set_detached(p7, flag == Qtrue ? 1 : 0))
	ossl_raise(ePKCS7Error, NULL);

    return flag;
}

static VALUE
ossl_pkcs7_get_detached(VALUE self)
{
    PKCS7 *p7;
    GetPKCS7(self, p7);
    return PKCS7_get_detached(p7) ? Qtrue : Qfalse;
}

static VALUE
ossl_pkcs7_detached_p(VALUE self)
{
    PKCS7 *p7;
    GetPKCS7(self, p7);
    return PKCS7_is_detached(p7) ? Qtrue : Qfalse;
}

static VALUE
ossl_pkcs7_set_cipher(VALUE self, VALUE cipher)
{
    PKCS7 *pkcs7;

    GetPKCS7(self, pkcs7);
    if (!PKCS7_set_cipher(pkcs7, ossl_evp_get_cipherbyname(cipher))) {
	ossl_raise(ePKCS7Error, NULL);
    }

    return cipher;
}

static VALUE
ossl_pkcs7_add_signer(VALUE self, VALUE signer)
{
    PKCS7 *pkcs7;
    PKCS7_SIGNER_INFO *si, *si_new;

    GetPKCS7(self, pkcs7);
    GetPKCS7si(signer, si);

    si_new = ossl_PKCS7_SIGNER_INFO_dup(si);
    if (!si_new)
        ossl_raise(ePKCS7Error, "PKCS7_SIGNER_INFO_dup");

    if (PKCS7_add_signer(pkcs7, si_new) != 1) {
        PKCS7_SIGNER_INFO_free(si_new);
        ossl_raise(ePKCS7Error, "PKCS7_add_signer");
    }

    return self;
}

static VALUE
ossl_pkcs7_get_signer(VALUE self)
{
    PKCS7 *pkcs7;
    STACK_OF(PKCS7_SIGNER_INFO) *sk;
    PKCS7_SIGNER_INFO *si;
    int num, i;
    VALUE ary;

    GetPKCS7(self, pkcs7);
    if (!(sk = PKCS7_get_signer_info(pkcs7))) {
	OSSL_Debug("OpenSSL::PKCS7#get_signer_info == NULL!");
	return rb_ary_new();
    }
    if ((num = sk_PKCS7_SIGNER_INFO_num(sk)) < 0) {
	ossl_raise(ePKCS7Error, "Negative number of signers!");
    }
    ary = rb_ary_new2(num);
    for (i=0; i<num; i++) {
	si = sk_PKCS7_SIGNER_INFO_value(sk, i);
	rb_ary_push(ary, ossl_pkcs7si_new(si));
    }

    return ary;
}

static VALUE
ossl_pkcs7_add_recipient(VALUE self, VALUE recip)
{
    PKCS7 *pkcs7;
    PKCS7_RECIP_INFO *ri, *ri_new;

    GetPKCS7(self, pkcs7);
    GetPKCS7ri(recip, ri);

    ri_new = ossl_PKCS7_RECIP_INFO_dup(ri);
    if (!ri_new)
        ossl_raise(ePKCS7Error, "PKCS7_RECIP_INFO_dup");

    if (PKCS7_add_recipient_info(pkcs7, ri_new) != 1) {
        PKCS7_RECIP_INFO_free(ri_new);
        ossl_raise(ePKCS7Error, "PKCS7_add_recipient_info");
    }

    return self;
}

static VALUE
ossl_pkcs7_get_recipient(VALUE self)
{
    PKCS7 *pkcs7;
    STACK_OF(PKCS7_RECIP_INFO) *sk;
    PKCS7_RECIP_INFO *si;
    int num, i;
    VALUE ary;

    GetPKCS7(self, pkcs7);
    if (PKCS7_type_is_enveloped(pkcs7))
	sk = pkcs7->d.enveloped->recipientinfo;
    else if (PKCS7_type_is_signedAndEnveloped(pkcs7))
	sk = pkcs7->d.signed_and_enveloped->recipientinfo;
    else sk = NULL;
    if (!sk) return rb_ary_new();
    if ((num = sk_PKCS7_RECIP_INFO_num(sk)) < 0) {
	ossl_raise(ePKCS7Error, "Negative number of recipient!");
    }
    ary = rb_ary_new2(num);
    for (i=0; i<num; i++) {
	si = sk_PKCS7_RECIP_INFO_value(sk, i);
	rb_ary_push(ary, ossl_pkcs7ri_new(si));
    }

    return ary;
}

static VALUE
ossl_pkcs7_add_certificate(VALUE self, VALUE cert)
{
    PKCS7 *pkcs7;
    X509 *x509;

    GetPKCS7(self, pkcs7);
    x509 = GetX509CertPtr(cert);  /* NO NEED TO DUP */
    if (!PKCS7_add_certificate(pkcs7, x509)){
	ossl_raise(ePKCS7Error, NULL);
    }

    return self;
}

static STACK_OF(X509) *
pkcs7_get_certs(VALUE self)
{
    PKCS7 *pkcs7;
    STACK_OF(X509) *certs;
    int i;

    GetPKCS7(self, pkcs7);
    i = OBJ_obj2nid(pkcs7->type);
    switch(i){
    case NID_pkcs7_signed:
        certs = pkcs7->d.sign->cert;
        break;
    case NID_pkcs7_signedAndEnveloped:
        certs = pkcs7->d.signed_and_enveloped->cert;
        break;
    default:
        certs = NULL;
    }

    return certs;
}

static STACK_OF(X509_CRL) *
pkcs7_get_crls(VALUE self)
{
    PKCS7 *pkcs7;
    STACK_OF(X509_CRL) *crls;
    int i;

    GetPKCS7(self, pkcs7);
    i = OBJ_obj2nid(pkcs7->type);
    switch(i){
    case NID_pkcs7_signed:
        crls = pkcs7->d.sign->crl;
        break;
    case NID_pkcs7_signedAndEnveloped:
        crls = pkcs7->d.signed_and_enveloped->crl;
        break;
    default:
        crls = NULL;
    }

    return crls;
}

static VALUE
ossl_pkcs7_set_certs_i(RB_BLOCK_CALL_FUNC_ARGLIST(i, arg))
{
    return ossl_pkcs7_add_certificate(arg, i);
}

static VALUE
ossl_pkcs7_set_certificates(VALUE self, VALUE ary)
{
    STACK_OF(X509) *certs;
    X509 *cert;

    certs = pkcs7_get_certs(self);
    while((cert = sk_X509_pop(certs))) X509_free(cert);
    rb_block_call(ary, rb_intern("each"), 0, 0, ossl_pkcs7_set_certs_i, self);

    return ary;
}

static VALUE
ossl_pkcs7_get_certificates(VALUE self)
{
    return ossl_x509_sk2ary(pkcs7_get_certs(self));
}

static VALUE
ossl_pkcs7_add_crl(VALUE self, VALUE crl)
{
    PKCS7 *pkcs7;
    X509_CRL *x509crl;

    GetPKCS7(self, pkcs7); /* NO DUP needed! */
    x509crl = GetX509CRLPtr(crl);
    if (!PKCS7_add_crl(pkcs7, x509crl)) {
	ossl_raise(ePKCS7Error, NULL);
    }

    return self;
}

static VALUE
ossl_pkcs7_set_crls_i(RB_BLOCK_CALL_FUNC_ARGLIST(i, arg))
{
    return ossl_pkcs7_add_crl(arg, i);
}

static VALUE
ossl_pkcs7_set_crls(VALUE self, VALUE ary)
{
    STACK_OF(X509_CRL) *crls;
    X509_CRL *crl;

    crls = pkcs7_get_crls(self);
    while((crl = sk_X509_CRL_pop(crls))) X509_CRL_free(crl);
    rb_block_call(ary, rb_intern("each"), 0, 0, ossl_pkcs7_set_crls_i, self);

    return ary;
}

static VALUE
ossl_pkcs7_get_crls(VALUE self)
{
    return ossl_x509crl_sk2ary(pkcs7_get_crls(self));
}

static VALUE
ossl_pkcs7_verify(int argc, VALUE *argv, VALUE self)
{
    VALUE certs, store, indata, flags;
    STACK_OF(X509) *x509s;
    X509_STORE *x509st;
    int flg, ok, status = 0;
    BIO *in, *out;
    PKCS7 *p7;
    VALUE data;
    const char *msg;

    GetPKCS7(self, p7);
    rb_scan_args(argc, argv, "22", &certs, &store, &indata, &flags);
    x509st = GetX509StorePtr(store);
    flg = NIL_P(flags) ? 0 : NUM2INT(flags);
    if(NIL_P(indata)) indata = ossl_pkcs7_get_data(self);
    in = NIL_P(indata) ? NULL : ossl_obj2bio(&indata);
    if(NIL_P(certs)) x509s = NULL;
    else{
	x509s = ossl_protect_x509_ary2sk(certs, &status);
	if(status){
	    BIO_free(in);
	    rb_jump_tag(status);
	}
    }
    if(!(out = BIO_new(BIO_s_mem()))){
	BIO_free(in);
	sk_X509_pop_free(x509s, X509_free);
	ossl_raise(ePKCS7Error, NULL);
    }
    ok = PKCS7_verify(p7, x509s, x509st, in, out, flg);
    BIO_free(in);
    sk_X509_pop_free(x509s, X509_free);
    if (ok < 0) ossl_raise(ePKCS7Error, "PKCS7_verify");
    msg = ERR_reason_error_string(ERR_peek_error());
    ossl_pkcs7_set_err_string(self, msg ? rb_str_new2(msg) : Qnil);
    ossl_clear_error();
    data = ossl_membio2str(out);
    ossl_pkcs7_set_data(self, data);

    return (ok == 1) ? Qtrue : Qfalse;
}

static VALUE
ossl_pkcs7_decrypt(int argc, VALUE *argv, VALUE self)
{
    VALUE pkey, cert, flags;
    EVP_PKEY *key;
    X509 *x509;
    int flg;
    PKCS7 *p7;
    BIO *out;
    VALUE str;

    rb_scan_args(argc, argv, "12", &pkey, &cert, &flags);
    key = GetPrivPKeyPtr(pkey); /* NO NEED TO DUP */
    x509 = NIL_P(cert) ? NULL : GetX509CertPtr(cert); /* NO NEED TO DUP */
    flg = NIL_P(flags) ? 0 : NUM2INT(flags);
    GetPKCS7(self, p7);
    if(!(out = BIO_new(BIO_s_mem())))
	ossl_raise(ePKCS7Error, NULL);
    if(!PKCS7_decrypt(p7, key, x509, out, flg)){
	BIO_free(out);
	ossl_raise(ePKCS7Error, NULL);
    }
    str = ossl_membio2str(out); /* out will be free */

    return str;
}

static VALUE
ossl_pkcs7_add_data(VALUE self, VALUE data)
{
    PKCS7 *pkcs7;
    BIO *out, *in;
    char buf[4096];
    int len;

    GetPKCS7(self, pkcs7);
    if(PKCS7_type_is_signed(pkcs7)){
	if(!PKCS7_content_new(pkcs7, NID_pkcs7_data))
	    ossl_raise(ePKCS7Error, NULL);
    }
    in = ossl_obj2bio(&data);
    if(!(out = PKCS7_dataInit(pkcs7, NULL))) goto err;
    for(;;){
	if((len = BIO_read(in, buf, sizeof(buf))) <= 0)
	    break;
	if(BIO_write(out, buf, len) != len)
	    goto err;
    }
    if(!PKCS7_dataFinal(pkcs7, out)) goto err;
    ossl_pkcs7_set_data(self, Qnil);

 err:
    BIO_free_all(out);
    BIO_free(in);
    if(ERR_peek_error()){
	ossl_raise(ePKCS7Error, NULL);
    }

    return data;
}

static VALUE
ossl_pkcs7_to_der(VALUE self)
{
    PKCS7 *pkcs7;
    VALUE str;
    long len;
    unsigned char *p;

    GetPKCS7(self, pkcs7);
    if((len = i2d_PKCS7(pkcs7, NULL)) <= 0)
	ossl_raise(ePKCS7Error, NULL);
    str = rb_str_new(0, len);
    p = (unsigned char *)RSTRING_PTR(str);
    if(i2d_PKCS7(pkcs7, &p) <= 0)
	ossl_raise(ePKCS7Error, NULL);
    ossl_str_adjust(str, p);

    return str;
}

static VALUE
ossl_pkcs7_to_pem(VALUE self)
{
    PKCS7 *pkcs7;
    BIO *out;
    VALUE str;

    GetPKCS7(self, pkcs7);
    if (!(out = BIO_new(BIO_s_mem()))) {
	ossl_raise(ePKCS7Error, NULL);
    }
    if (!PEM_write_bio_PKCS7(out, pkcs7)) {
	BIO_free(out);
	ossl_raise(ePKCS7Error, NULL);
    }
    str = ossl_membio2str(out);

    return str;
}

/*
 * SIGNER INFO
 */
static VALUE
ossl_pkcs7si_alloc(VALUE klass)
{
    PKCS7_SIGNER_INFO *p7si;
    VALUE obj;

    obj = NewPKCS7si(klass);
    if (!(p7si = PKCS7_SIGNER_INFO_new())) {
	ossl_raise(ePKCS7Error, NULL);
    }
    SetPKCS7si(obj, p7si);

    return obj;
}

static VALUE
ossl_pkcs7si_initialize(VALUE self, VALUE cert, VALUE key, VALUE digest)
{
    PKCS7_SIGNER_INFO *p7si;
    EVP_PKEY *pkey;
    X509 *x509;
    const EVP_MD *md;

    pkey = GetPrivPKeyPtr(key); /* NO NEED TO DUP */
    x509 = GetX509CertPtr(cert); /* NO NEED TO DUP */
    md = ossl_evp_get_digestbyname(digest);
    GetPKCS7si(self, p7si);
    if (!(PKCS7_SIGNER_INFO_set(p7si, x509, pkey, (EVP_MD*)md))) {
	ossl_raise(ePKCS7Error, NULL);
    }

    return self;
}

static VALUE
ossl_pkcs7si_get_issuer(VALUE self)
{
    PKCS7_SIGNER_INFO *p7si;

    GetPKCS7si(self, p7si);

    return ossl_x509name_new(p7si->issuer_and_serial->issuer);
}

static VALUE
ossl_pkcs7si_get_serial(VALUE self)
{
    PKCS7_SIGNER_INFO *p7si;

    GetPKCS7si(self, p7si);

    return asn1integer_to_num(p7si->issuer_and_serial->serial);
}

static VALUE
ossl_pkcs7si_get_signed_time(VALUE self)
{
    PKCS7_SIGNER_INFO *p7si;
    ASN1_TYPE *asn1obj;

    GetPKCS7si(self, p7si);

    if (!(asn1obj = PKCS7_get_signed_attribute(p7si, NID_pkcs9_signingTime))) {
	ossl_raise(ePKCS7Error, NULL);
    }
    if (asn1obj->type == V_ASN1_UTCTIME) {
	return asn1time_to_time(asn1obj->value.utctime);
    }
    /*
     * OR
     * ossl_raise(ePKCS7Error, "...");
     * ?
     */

    return Qnil;
}

/*
 * RECIPIENT INFO
 */
static VALUE
ossl_pkcs7ri_alloc(VALUE klass)
{
    PKCS7_RECIP_INFO *p7ri;
    VALUE obj;

    obj = NewPKCS7ri(klass);
    if (!(p7ri = PKCS7_RECIP_INFO_new())) {
	ossl_raise(ePKCS7Error, NULL);
    }
    SetPKCS7ri(obj, p7ri);

    return obj;
}

static VALUE
ossl_pkcs7ri_initialize(VALUE self, VALUE cert)
{
    PKCS7_RECIP_INFO *p7ri;
    X509 *x509;

    x509 = GetX509CertPtr(cert); /* NO NEED TO DUP */
    GetPKCS7ri(self, p7ri);
    if (!PKCS7_RECIP_INFO_set(p7ri, x509)) {
	ossl_raise(ePKCS7Error, NULL);
    }

    return self;
}

static VALUE
ossl_pkcs7ri_get_issuer(VALUE self)
{
    PKCS7_RECIP_INFO *p7ri;

    GetPKCS7ri(self, p7ri);

    return ossl_x509name_new(p7ri->issuer_and_serial->issuer);
}

static VALUE
ossl_pkcs7ri_get_serial(VALUE self)
{
    PKCS7_RECIP_INFO *p7ri;

    GetPKCS7ri(self, p7ri);

    return asn1integer_to_num(p7ri->issuer_and_serial->serial);
}

static VALUE
ossl_pkcs7ri_get_enc_key(VALUE self)
{
    PKCS7_RECIP_INFO *p7ri;

    GetPKCS7ri(self, p7ri);

    return asn1str_to_str(p7ri->enc_key);
}

/*
 * INIT
 */
void
Init_ossl_pkcs7(void)
{
#undef rb_intern
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    cPKCS7 = rb_define_class_under(mOSSL, "PKCS7", rb_cObject);
    ePKCS7Error = rb_define_class_under(cPKCS7, "PKCS7Error", eOSSLError);
    rb_define_singleton_method(cPKCS7, "read_smime", ossl_pkcs7_s_read_smime, 1);
    rb_define_singleton_method(cPKCS7, "write_smime", ossl_pkcs7_s_write_smime, -1);
    rb_define_singleton_method(cPKCS7, "sign",  ossl_pkcs7_s_sign, -1);
    rb_define_singleton_method(cPKCS7, "encrypt", ossl_pkcs7_s_encrypt, -1);
    rb_attr(cPKCS7, rb_intern("data"), 1, 0, Qfalse);
    rb_attr(cPKCS7, rb_intern("error_string"), 1, 1, Qfalse);
    rb_define_alloc_func(cPKCS7, ossl_pkcs7_alloc);
    rb_define_method(cPKCS7, "initialize_copy", ossl_pkcs7_copy, 1);
    rb_define_method(cPKCS7, "initialize", ossl_pkcs7_initialize, -1);
    rb_define_method(cPKCS7, "type=", ossl_pkcs7_set_type, 1);
    rb_define_method(cPKCS7, "type", ossl_pkcs7_get_type, 0);
    rb_define_method(cPKCS7, "detached=", ossl_pkcs7_set_detached, 1);
    rb_define_method(cPKCS7, "detached", ossl_pkcs7_get_detached, 0);
    rb_define_method(cPKCS7, "detached?", ossl_pkcs7_detached_p, 0);
    rb_define_method(cPKCS7, "cipher=", ossl_pkcs7_set_cipher, 1);
    rb_define_method(cPKCS7, "add_signer", ossl_pkcs7_add_signer, 1);
    rb_define_method(cPKCS7, "signers", ossl_pkcs7_get_signer, 0);
    rb_define_method(cPKCS7, "add_recipient", ossl_pkcs7_add_recipient, 1);
    rb_define_method(cPKCS7, "recipients", ossl_pkcs7_get_recipient, 0);
    rb_define_method(cPKCS7, "add_certificate", ossl_pkcs7_add_certificate, 1);
    rb_define_method(cPKCS7, "certificates=", ossl_pkcs7_set_certificates, 1);
    rb_define_method(cPKCS7, "certificates", ossl_pkcs7_get_certificates, 0);
    rb_define_method(cPKCS7, "add_crl", ossl_pkcs7_add_crl, 1);
    rb_define_method(cPKCS7, "crls=", ossl_pkcs7_set_crls, 1);
    rb_define_method(cPKCS7, "crls", ossl_pkcs7_get_crls, 0);
    rb_define_method(cPKCS7, "add_data", ossl_pkcs7_add_data, 1);
    rb_define_alias(cPKCS7,  "data=", "add_data");
    rb_define_method(cPKCS7, "verify", ossl_pkcs7_verify, -1);
    rb_define_method(cPKCS7, "decrypt", ossl_pkcs7_decrypt, -1);
    rb_define_method(cPKCS7, "to_pem", ossl_pkcs7_to_pem, 0);
    rb_define_alias(cPKCS7,  "to_s", "to_pem");
    rb_define_method(cPKCS7, "to_der", ossl_pkcs7_to_der, 0);

    cPKCS7Signer = rb_define_class_under(cPKCS7, "SignerInfo", rb_cObject);
    rb_define_const(cPKCS7, "Signer", cPKCS7Signer);
    rb_define_alloc_func(cPKCS7Signer, ossl_pkcs7si_alloc);
    rb_define_method(cPKCS7Signer, "initialize", ossl_pkcs7si_initialize,3);
    rb_define_method(cPKCS7Signer, "issuer", ossl_pkcs7si_get_issuer, 0);
    rb_define_method(cPKCS7Signer, "serial", ossl_pkcs7si_get_serial,0);
    rb_define_method(cPKCS7Signer,"signed_time",ossl_pkcs7si_get_signed_time,0);

    cPKCS7Recipient = rb_define_class_under(cPKCS7,"RecipientInfo",rb_cObject);
    rb_define_alloc_func(cPKCS7Recipient, ossl_pkcs7ri_alloc);
    rb_define_method(cPKCS7Recipient, "initialize", ossl_pkcs7ri_initialize,1);
    rb_define_method(cPKCS7Recipient, "issuer", ossl_pkcs7ri_get_issuer,0);
    rb_define_method(cPKCS7Recipient, "serial", ossl_pkcs7ri_get_serial,0);
    rb_define_method(cPKCS7Recipient, "enc_key", ossl_pkcs7ri_get_enc_key,0);

#define DefPKCS7Const(x) rb_define_const(cPKCS7, #x, INT2NUM(PKCS7_##x))

    DefPKCS7Const(TEXT);
    DefPKCS7Const(NOCERTS);
    DefPKCS7Const(NOSIGS);
    DefPKCS7Const(NOCHAIN);
    DefPKCS7Const(NOINTERN);
    DefPKCS7Const(NOVERIFY);
    DefPKCS7Const(DETACHED);
    DefPKCS7Const(BINARY);
    DefPKCS7Const(NOATTR);
    DefPKCS7Const(NOSMIMECAP);
}
