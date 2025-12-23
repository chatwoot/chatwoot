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

#if !defined(OPENSSL_NO_RSA)

#define GetPKeyRSA(obj, pkey) do { \
    GetPKey((obj), (pkey)); \
    if (EVP_PKEY_base_id(pkey) != EVP_PKEY_RSA) { /* PARANOIA? */ \
	ossl_raise(rb_eRuntimeError, "THIS IS NOT A RSA!") ; \
    } \
} while (0)
#define GetRSA(obj, rsa) do { \
    EVP_PKEY *_pkey; \
    GetPKeyRSA((obj), _pkey); \
    (rsa) = EVP_PKEY_get0_RSA(_pkey); \
} while (0)

static inline int
RSA_HAS_PRIVATE(OSSL_3_const RSA *rsa)
{
    const BIGNUM *e, *d;

    RSA_get0_key(rsa, NULL, &e, &d);
    return e && d;
}

static inline int
RSA_PRIVATE(VALUE obj, OSSL_3_const RSA *rsa)
{
    return RSA_HAS_PRIVATE(rsa) || OSSL_PKEY_IS_PRIVATE(obj);
}

/*
 * Classes
 */
VALUE cRSA;
VALUE eRSAError;

/*
 * Private
 */
/*
 * call-seq:
 *   RSA.new -> rsa
 *   RSA.new(encoded_key [, password ]) -> rsa
 *   RSA.new(encoded_key) { password } -> rsa
 *   RSA.new(size [, exponent]) -> rsa
 *
 * Generates or loads an \RSA keypair.
 *
 * If called without arguments, creates a new instance with no key components
 * set. They can be set individually by #set_key, #set_factors, and
 * #set_crt_params.
 *
 * If called with a String, tries to parse as DER or PEM encoding of an \RSA key.
 * Note that if _password_ is not specified, but the key is encrypted with a
 * password, \OpenSSL will prompt for it.
 * See also OpenSSL::PKey.read which can parse keys of any kind.
 *
 * If called with a number, generates a new key pair. This form works as an
 * alias of RSA.generate.
 *
 * Examples:
 *   OpenSSL::PKey::RSA.new 2048
 *   OpenSSL::PKey::RSA.new File.read 'rsa.pem'
 *   OpenSSL::PKey::RSA.new File.read('rsa.pem'), 'my password'
 */
static VALUE
ossl_rsa_initialize(int argc, VALUE *argv, VALUE self)
{
    EVP_PKEY *pkey;
    RSA *rsa;
    BIO *in = NULL;
    VALUE arg, pass;
    int type;

    TypedData_Get_Struct(self, EVP_PKEY, &ossl_evp_pkey_type, pkey);
    if (pkey)
        rb_raise(rb_eTypeError, "pkey already initialized");

    /* The RSA.new(size, generator) form is handled by lib/openssl/pkey.rb */
    rb_scan_args(argc, argv, "02", &arg, &pass);
    if (argc == 0) {
	rsa = RSA_new();
        if (!rsa)
            ossl_raise(eRSAError, "RSA_new");
        goto legacy;
    }

    pass = ossl_pem_passwd_value(pass);
    arg = ossl_to_der_if_possible(arg);
    in = ossl_obj2bio(&arg);

    /* First try RSAPublicKey format */
    rsa = d2i_RSAPublicKey_bio(in, NULL);
    if (rsa)
        goto legacy;
    OSSL_BIO_reset(in);
    rsa = PEM_read_bio_RSAPublicKey(in, NULL, NULL, NULL);
    if (rsa)
        goto legacy;
    OSSL_BIO_reset(in);

    /* Use the generic routine */
    pkey = ossl_pkey_read_generic(in, pass);
    BIO_free(in);
    if (!pkey)
        ossl_raise(eRSAError, "Neither PUB key nor PRIV key");

    type = EVP_PKEY_base_id(pkey);
    if (type != EVP_PKEY_RSA) {
        EVP_PKEY_free(pkey);
        rb_raise(eRSAError, "incorrect pkey type: %s", OBJ_nid2sn(type));
    }
    RTYPEDDATA_DATA(self) = pkey;
    return self;

  legacy:
    BIO_free(in);
    pkey = EVP_PKEY_new();
    if (!pkey || EVP_PKEY_assign_RSA(pkey, rsa) != 1) {
        EVP_PKEY_free(pkey);
        RSA_free(rsa);
        ossl_raise(eRSAError, "EVP_PKEY_assign_RSA");
    }
    RTYPEDDATA_DATA(self) = pkey;
    return self;
}

#ifndef HAVE_EVP_PKEY_DUP
static VALUE
ossl_rsa_initialize_copy(VALUE self, VALUE other)
{
    EVP_PKEY *pkey;
    RSA *rsa, *rsa_new;

    TypedData_Get_Struct(self, EVP_PKEY, &ossl_evp_pkey_type, pkey);
    if (pkey)
        rb_raise(rb_eTypeError, "pkey already initialized");
    GetRSA(other, rsa);

    rsa_new = (RSA *)ASN1_dup((i2d_of_void *)i2d_RSAPrivateKey,
                              (d2i_of_void *)d2i_RSAPrivateKey,
                              (char *)rsa);
    if (!rsa_new)
	ossl_raise(eRSAError, "ASN1_dup");

    pkey = EVP_PKEY_new();
    if (!pkey || EVP_PKEY_assign_RSA(pkey, rsa_new) != 1) {
        RSA_free(rsa_new);
        ossl_raise(eRSAError, "EVP_PKEY_assign_RSA");
    }
    RTYPEDDATA_DATA(self) = pkey;

    return self;
}
#endif

/*
 * call-seq:
 *   rsa.public? => true
 *
 * The return value is always +true+ since every private key is also a public
 * key.
 */
static VALUE
ossl_rsa_is_public(VALUE self)
{
    OSSL_3_const RSA *rsa;

    GetRSA(self, rsa);
    /*
     * This method should check for n and e.  BUG.
     */
    (void)rsa;
    return Qtrue;
}

/*
 * call-seq:
 *   rsa.private? => true | false
 *
 * Does this keypair contain a private key?
 */
static VALUE
ossl_rsa_is_private(VALUE self)
{
    OSSL_3_const RSA *rsa;

    GetRSA(self, rsa);

    return RSA_PRIVATE(self, rsa) ? Qtrue : Qfalse;
}

static int
can_export_rsaprivatekey(VALUE self)
{
    OSSL_3_const RSA *rsa;
    const BIGNUM *n, *e, *d, *p, *q, *dmp1, *dmq1, *iqmp;

    GetRSA(self, rsa);

    RSA_get0_key(rsa, &n, &e, &d);
    RSA_get0_factors(rsa, &p, &q);
    RSA_get0_crt_params(rsa, &dmp1, &dmq1, &iqmp);

    return n && e && d && p && q && dmp1 && dmq1 && iqmp;
}

/*
 * call-seq:
 *   rsa.export([cipher, password]) => PEM-format String
 *   rsa.to_pem([cipher, password]) => PEM-format String
 *   rsa.to_s([cipher, password]) => PEM-format String
 *
 * Serializes a private or public key to a PEM-encoding.
 *
 * [When the key contains public components only]
 *
 *   Serializes it into an X.509 SubjectPublicKeyInfo.
 *   The parameters _cipher_ and _password_ are ignored.
 *
 *   A PEM-encoded key will look like:
 *
 *     -----BEGIN PUBLIC KEY-----
 *     [...]
 *     -----END PUBLIC KEY-----
 *
 *   Consider using #public_to_pem instead. This serializes the key into an
 *   X.509 SubjectPublicKeyInfo regardless of whether the key is a public key
 *   or a private key.
 *
 * [When the key contains private components, and no parameters are given]
 *
 *   Serializes it into a PKCS #1 RSAPrivateKey.
 *
 *   A PEM-encoded key will look like:
 *
 *     -----BEGIN RSA PRIVATE KEY-----
 *     [...]
 *     -----END RSA PRIVATE KEY-----
 *
 * [When the key contains private components, and _cipher_ and _password_ are given]
 *
 *   Serializes it into a PKCS #1 RSAPrivateKey
 *   and encrypts it in OpenSSL's traditional PEM encryption format.
 *   _cipher_ must be a cipher name understood by OpenSSL::Cipher.new or an
 *   instance of OpenSSL::Cipher.
 *
 *   An encrypted PEM-encoded key will look like:
 *
 *     -----BEGIN RSA PRIVATE KEY-----
 *     Proc-Type: 4,ENCRYPTED
 *     DEK-Info: AES-128-CBC,733F5302505B34701FC41F5C0746E4C0
 *
 *     [...]
 *     -----END RSA PRIVATE KEY-----
 *
 *   Note that this format uses MD5 to derive the encryption key, and hence
 *   will not be available on FIPS-compliant systems.
 *
 * <b>This method is kept for compatibility.</b>
 * This should only be used when the PKCS #1 RSAPrivateKey format is required.
 *
 * Consider using #public_to_pem (X.509 SubjectPublicKeyInfo) or #private_to_pem
 * (PKCS #8 PrivateKeyInfo or EncryptedPrivateKeyInfo) instead.
 */
static VALUE
ossl_rsa_export(int argc, VALUE *argv, VALUE self)
{
    if (can_export_rsaprivatekey(self))
        return ossl_pkey_export_traditional(argc, argv, self, 0);
    else
        return ossl_pkey_export_spki(self, 0);
}

/*
 * call-seq:
 *   rsa.to_der => DER-format String
 *
 * Serializes a private or public key to a DER-encoding.
 *
 * See #to_pem for details.
 *
 * <b>This method is kept for compatibility.</b>
 * This should only be used when the PKCS #1 RSAPrivateKey format is required.
 *
 * Consider using #public_to_der or #private_to_der instead.
 */
static VALUE
ossl_rsa_to_der(VALUE self)
{
    if (can_export_rsaprivatekey(self))
        return ossl_pkey_export_traditional(0, NULL, self, 1);
    else
        return ossl_pkey_export_spki(self, 1);
}

/*
 * call-seq:
 *    rsa.sign_pss(digest, data, salt_length:, mgf1_hash:) -> String
 *
 * Signs _data_ using the Probabilistic Signature Scheme (RSA-PSS) and returns
 * the calculated signature.
 *
 * RSAError will be raised if an error occurs.
 *
 * See #verify_pss for the verification operation.
 *
 * === Parameters
 * _digest_::
 *   A String containing the message digest algorithm name.
 * _data_::
 *   A String. The data to be signed.
 * _salt_length_::
 *   The length in octets of the salt. Two special values are reserved:
 *   +:digest+ means the digest length, and +:max+ means the maximum possible
 *   length for the combination of the private key and the selected message
 *   digest algorithm.
 * _mgf1_hash_::
 *   The hash algorithm used in MGF1 (the currently supported mask generation
 *   function (MGF)).
 *
 * === Example
 *   data = "Sign me!"
 *   pkey = OpenSSL::PKey::RSA.new(2048)
 *   signature = pkey.sign_pss("SHA256", data, salt_length: :max, mgf1_hash: "SHA256")
 *   pub_key = OpenSSL::PKey.read(pkey.public_to_der)
 *   puts pub_key.verify_pss("SHA256", signature, data,
 *                           salt_length: :auto, mgf1_hash: "SHA256") # => true
 */
static VALUE
ossl_rsa_sign_pss(int argc, VALUE *argv, VALUE self)
{
    VALUE digest, data, options, kwargs[2], signature;
    static ID kwargs_ids[2];
    EVP_PKEY *pkey;
    EVP_PKEY_CTX *pkey_ctx;
    const EVP_MD *md, *mgf1md;
    EVP_MD_CTX *md_ctx;
    size_t buf_len;
    int salt_len;

    if (!kwargs_ids[0]) {
	kwargs_ids[0] = rb_intern_const("salt_length");
	kwargs_ids[1] = rb_intern_const("mgf1_hash");
    }
    rb_scan_args(argc, argv, "2:", &digest, &data, &options);
    rb_get_kwargs(options, kwargs_ids, 2, 0, kwargs);
    if (kwargs[0] == ID2SYM(rb_intern("max")))
	salt_len = -2; /* RSA_PSS_SALTLEN_MAX_SIGN */
    else if (kwargs[0] == ID2SYM(rb_intern("digest")))
	salt_len = -1; /* RSA_PSS_SALTLEN_DIGEST */
    else
	salt_len = NUM2INT(kwargs[0]);
    mgf1md = ossl_evp_get_digestbyname(kwargs[1]);

    pkey = GetPrivPKeyPtr(self);
    buf_len = EVP_PKEY_size(pkey);
    md = ossl_evp_get_digestbyname(digest);
    StringValue(data);
    signature = rb_str_new(NULL, (long)buf_len);

    md_ctx = EVP_MD_CTX_new();
    if (!md_ctx)
	goto err;

    if (EVP_DigestSignInit(md_ctx, &pkey_ctx, md, NULL, pkey) != 1)
	goto err;

    if (EVP_PKEY_CTX_set_rsa_padding(pkey_ctx, RSA_PKCS1_PSS_PADDING) != 1)
	goto err;

    if (EVP_PKEY_CTX_set_rsa_pss_saltlen(pkey_ctx, salt_len) != 1)
	goto err;

    if (EVP_PKEY_CTX_set_rsa_mgf1_md(pkey_ctx, mgf1md) != 1)
	goto err;

    if (EVP_DigestSignUpdate(md_ctx, RSTRING_PTR(data), RSTRING_LEN(data)) != 1)
	goto err;

    if (EVP_DigestSignFinal(md_ctx, (unsigned char *)RSTRING_PTR(signature), &buf_len) != 1)
	goto err;

    rb_str_set_len(signature, (long)buf_len);

    EVP_MD_CTX_free(md_ctx);
    return signature;

  err:
    EVP_MD_CTX_free(md_ctx);
    ossl_raise(eRSAError, NULL);
}

/*
 * call-seq:
 *    rsa.verify_pss(digest, signature, data, salt_length:, mgf1_hash:) -> true | false
 *
 * Verifies _data_ using the Probabilistic Signature Scheme (RSA-PSS).
 *
 * The return value is +true+ if the signature is valid, +false+ otherwise.
 * RSAError will be raised if an error occurs.
 *
 * See #sign_pss for the signing operation and an example code.
 *
 * === Parameters
 * _digest_::
 *   A String containing the message digest algorithm name.
 * _data_::
 *   A String. The data to be signed.
 * _salt_length_::
 *   The length in octets of the salt. Two special values are reserved:
 *   +:digest+ means the digest length, and +:auto+ means automatically
 *   determining the length based on the signature.
 * _mgf1_hash_::
 *   The hash algorithm used in MGF1.
 */
static VALUE
ossl_rsa_verify_pss(int argc, VALUE *argv, VALUE self)
{
    VALUE digest, signature, data, options, kwargs[2];
    static ID kwargs_ids[2];
    EVP_PKEY *pkey;
    EVP_PKEY_CTX *pkey_ctx;
    const EVP_MD *md, *mgf1md;
    EVP_MD_CTX *md_ctx;
    int result, salt_len;

    if (!kwargs_ids[0]) {
	kwargs_ids[0] = rb_intern_const("salt_length");
	kwargs_ids[1] = rb_intern_const("mgf1_hash");
    }
    rb_scan_args(argc, argv, "3:", &digest, &signature, &data, &options);
    rb_get_kwargs(options, kwargs_ids, 2, 0, kwargs);
    if (kwargs[0] == ID2SYM(rb_intern("auto")))
	salt_len = -2; /* RSA_PSS_SALTLEN_AUTO */
    else if (kwargs[0] == ID2SYM(rb_intern("digest")))
	salt_len = -1; /* RSA_PSS_SALTLEN_DIGEST */
    else
	salt_len = NUM2INT(kwargs[0]);
    mgf1md = ossl_evp_get_digestbyname(kwargs[1]);

    GetPKey(self, pkey);
    md = ossl_evp_get_digestbyname(digest);
    StringValue(signature);
    StringValue(data);

    md_ctx = EVP_MD_CTX_new();
    if (!md_ctx)
	goto err;

    if (EVP_DigestVerifyInit(md_ctx, &pkey_ctx, md, NULL, pkey) != 1)
	goto err;

    if (EVP_PKEY_CTX_set_rsa_padding(pkey_ctx, RSA_PKCS1_PSS_PADDING) != 1)
	goto err;

    if (EVP_PKEY_CTX_set_rsa_pss_saltlen(pkey_ctx, salt_len) != 1)
	goto err;

    if (EVP_PKEY_CTX_set_rsa_mgf1_md(pkey_ctx, mgf1md) != 1)
	goto err;

    if (EVP_DigestVerifyUpdate(md_ctx, RSTRING_PTR(data), RSTRING_LEN(data)) != 1)
	goto err;

    result = EVP_DigestVerifyFinal(md_ctx,
				   (unsigned char *)RSTRING_PTR(signature),
				   RSTRING_LEN(signature));

    switch (result) {
      case 0:
	ossl_clear_error();
	EVP_MD_CTX_free(md_ctx);
	return Qfalse;
      case 1:
	EVP_MD_CTX_free(md_ctx);
	return Qtrue;
      default:
	goto err;
    }

  err:
    EVP_MD_CTX_free(md_ctx);
    ossl_raise(eRSAError, NULL);
}

/*
 * call-seq:
 *   rsa.params => hash
 *
 * THIS METHOD IS INSECURE, PRIVATE INFORMATION CAN LEAK OUT!!!
 *
 * Stores all parameters of key to the hash.  The hash has keys 'n', 'e', 'd',
 * 'p', 'q', 'dmp1', 'dmq1', 'iqmp'.
 *
 * Don't use :-)) (It's up to you)
 */
static VALUE
ossl_rsa_get_params(VALUE self)
{
    OSSL_3_const RSA *rsa;
    VALUE hash;
    const BIGNUM *n, *e, *d, *p, *q, *dmp1, *dmq1, *iqmp;

    GetRSA(self, rsa);
    RSA_get0_key(rsa, &n, &e, &d);
    RSA_get0_factors(rsa, &p, &q);
    RSA_get0_crt_params(rsa, &dmp1, &dmq1, &iqmp);

    hash = rb_hash_new();
    rb_hash_aset(hash, rb_str_new2("n"), ossl_bn_new(n));
    rb_hash_aset(hash, rb_str_new2("e"), ossl_bn_new(e));
    rb_hash_aset(hash, rb_str_new2("d"), ossl_bn_new(d));
    rb_hash_aset(hash, rb_str_new2("p"), ossl_bn_new(p));
    rb_hash_aset(hash, rb_str_new2("q"), ossl_bn_new(q));
    rb_hash_aset(hash, rb_str_new2("dmp1"), ossl_bn_new(dmp1));
    rb_hash_aset(hash, rb_str_new2("dmq1"), ossl_bn_new(dmq1));
    rb_hash_aset(hash, rb_str_new2("iqmp"), ossl_bn_new(iqmp));

    return hash;
}

/*
 * Document-method: OpenSSL::PKey::RSA#set_key
 * call-seq:
 *   rsa.set_key(n, e, d) -> self
 *
 * Sets _n_, _e_, _d_ for the RSA instance.
 */
OSSL_PKEY_BN_DEF3(rsa, RSA, key, n, e, d)
/*
 * Document-method: OpenSSL::PKey::RSA#set_factors
 * call-seq:
 *   rsa.set_factors(p, q) -> self
 *
 * Sets _p_, _q_ for the RSA instance.
 */
OSSL_PKEY_BN_DEF2(rsa, RSA, factors, p, q)
/*
 * Document-method: OpenSSL::PKey::RSA#set_crt_params
 * call-seq:
 *   rsa.set_crt_params(dmp1, dmq1, iqmp) -> self
 *
 * Sets _dmp1_, _dmq1_, _iqmp_ for the RSA instance. They are calculated by
 * <tt>d mod (p - 1)</tt>, <tt>d mod (q - 1)</tt> and <tt>q^(-1) mod p</tt>
 * respectively.
 */
OSSL_PKEY_BN_DEF3(rsa, RSA, crt_params, dmp1, dmq1, iqmp)

/*
 * INIT
 */
#define DefRSAConst(x) rb_define_const(cRSA, #x, INT2NUM(RSA_##x))

void
Init_ossl_rsa(void)
{
#if 0
    mPKey = rb_define_module_under(mOSSL, "PKey");
    cPKey = rb_define_class_under(mPKey, "PKey", rb_cObject);
    ePKeyError = rb_define_class_under(mPKey, "PKeyError", eOSSLError);
#endif

    /* Document-class: OpenSSL::PKey::RSAError
     *
     * Generic exception that is raised if an operation on an RSA PKey
     * fails unexpectedly or in case an instantiation of an instance of RSA
     * fails due to non-conformant input data.
     */
    eRSAError = rb_define_class_under(mPKey, "RSAError", ePKeyError);

    /* Document-class: OpenSSL::PKey::RSA
     *
     * RSA is an asymmetric public key algorithm that has been formalized in
     * RFC 3447. It is in widespread use in public key infrastructures (PKI)
     * where certificates (cf. OpenSSL::X509::Certificate) often are issued
     * on the basis of a public/private RSA key pair. RSA is used in a wide
     * field of applications such as secure (symmetric) key exchange, e.g.
     * when establishing a secure TLS/SSL connection. It is also used in
     * various digital signature schemes.
     */
    cRSA = rb_define_class_under(mPKey, "RSA", cPKey);

    rb_define_method(cRSA, "initialize", ossl_rsa_initialize, -1);
#ifndef HAVE_EVP_PKEY_DUP
    rb_define_method(cRSA, "initialize_copy", ossl_rsa_initialize_copy, 1);
#endif

    rb_define_method(cRSA, "public?", ossl_rsa_is_public, 0);
    rb_define_method(cRSA, "private?", ossl_rsa_is_private, 0);
    rb_define_method(cRSA, "export", ossl_rsa_export, -1);
    rb_define_alias(cRSA, "to_pem", "export");
    rb_define_alias(cRSA, "to_s", "export");
    rb_define_method(cRSA, "to_der", ossl_rsa_to_der, 0);
    rb_define_method(cRSA, "sign_pss", ossl_rsa_sign_pss, -1);
    rb_define_method(cRSA, "verify_pss", ossl_rsa_verify_pss, -1);

    DEF_OSSL_PKEY_BN(cRSA, rsa, n);
    DEF_OSSL_PKEY_BN(cRSA, rsa, e);
    DEF_OSSL_PKEY_BN(cRSA, rsa, d);
    DEF_OSSL_PKEY_BN(cRSA, rsa, p);
    DEF_OSSL_PKEY_BN(cRSA, rsa, q);
    DEF_OSSL_PKEY_BN(cRSA, rsa, dmp1);
    DEF_OSSL_PKEY_BN(cRSA, rsa, dmq1);
    DEF_OSSL_PKEY_BN(cRSA, rsa, iqmp);
    rb_define_method(cRSA, "set_key", ossl_rsa_set_key, 3);
    rb_define_method(cRSA, "set_factors", ossl_rsa_set_factors, 2);
    rb_define_method(cRSA, "set_crt_params", ossl_rsa_set_crt_params, 3);

    rb_define_method(cRSA, "params", ossl_rsa_get_params, 0);

/*
 * TODO: Test it
    rb_define_method(cRSA, "blinding_on!", ossl_rsa_blinding_on, 0);
    rb_define_method(cRSA, "blinding_off!", ossl_rsa_blinding_off, 0);
 */
}

#else /* defined NO_RSA */
void
Init_ossl_rsa(void)
{
}
#endif /* NO_RSA */
