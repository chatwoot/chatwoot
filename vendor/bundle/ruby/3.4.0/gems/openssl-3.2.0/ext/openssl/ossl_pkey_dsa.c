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

#if !defined(OPENSSL_NO_DSA)

#define GetPKeyDSA(obj, pkey) do { \
    GetPKey((obj), (pkey)); \
    if (EVP_PKEY_base_id(pkey) != EVP_PKEY_DSA) { /* PARANOIA? */ \
	ossl_raise(rb_eRuntimeError, "THIS IS NOT A DSA!"); \
    } \
} while (0)
#define GetDSA(obj, dsa) do { \
    EVP_PKEY *_pkey; \
    GetPKeyDSA((obj), _pkey); \
    (dsa) = EVP_PKEY_get0_DSA(_pkey); \
} while (0)

static inline int
DSA_HAS_PRIVATE(OSSL_3_const DSA *dsa)
{
    const BIGNUM *bn;
    DSA_get0_key(dsa, NULL, &bn);
    return !!bn;
}

static inline int
DSA_PRIVATE(VALUE obj, OSSL_3_const DSA *dsa)
{
    return DSA_HAS_PRIVATE(dsa) || OSSL_PKEY_IS_PRIVATE(obj);
}

/*
 * Classes
 */
VALUE cDSA;
VALUE eDSAError;

/*
 * Private
 */
/*
 *  call-seq:
 *    DSA.new -> dsa
 *    DSA.new(string [, pass]) -> dsa
 *    DSA.new(size) -> dsa
 *
 * Creates a new DSA instance by reading an existing key from _string_.
 *
 * If called without arguments, creates a new instance with no key components
 * set. They can be set individually by #set_pqg and #set_key.
 *
 * If called with a String, tries to parse as DER or PEM encoding of a \DSA key.
 * See also OpenSSL::PKey.read which can parse keys of any kinds.
 *
 * If called with a number, generates random parameters and a key pair. This
 * form works as an alias of DSA.generate.
 *
 * +string+::
 *   A String that contains a DER or PEM encoded key.
 * +pass+::
 *   A String that contains an optional password.
 * +size+::
 *   See DSA.generate.
 *
 * Examples:
 *   p OpenSSL::PKey::DSA.new(1024)
 *   #=> #<OpenSSL::PKey::DSA:0x000055a8d6025bf0 oid=DSA>
 *
 *   p OpenSSL::PKey::DSA.new(File.read('dsa.pem'))
 *   #=> #<OpenSSL::PKey::DSA:0x000055555d6b8110 oid=DSA>
 *
 *   p OpenSSL::PKey::DSA.new(File.read('dsa.pem'), 'mypassword')
 *   #=> #<OpenSSL::PKey::DSA:0x0000556f973c40b8 oid=DSA>
 */
static VALUE
ossl_dsa_initialize(int argc, VALUE *argv, VALUE self)
{
    EVP_PKEY *pkey;
    DSA *dsa;
    BIO *in = NULL;
    VALUE arg, pass;
    int type;

    TypedData_Get_Struct(self, EVP_PKEY, &ossl_evp_pkey_type, pkey);
    if (pkey)
        rb_raise(rb_eTypeError, "pkey already initialized");

    /* The DSA.new(size, generator) form is handled by lib/openssl/pkey.rb */
    rb_scan_args(argc, argv, "02", &arg, &pass);
    if (argc == 0) {
        dsa = DSA_new();
        if (!dsa)
            ossl_raise(eDSAError, "DSA_new");
        goto legacy;
    }

    pass = ossl_pem_passwd_value(pass);
    arg = ossl_to_der_if_possible(arg);
    in = ossl_obj2bio(&arg);

    /* DER-encoded DSAPublicKey format isn't supported by the generic routine */
    dsa = (DSA *)PEM_ASN1_read_bio((d2i_of_void *)d2i_DSAPublicKey,
                                   PEM_STRING_DSA_PUBLIC,
                                   in, NULL, NULL, NULL);
    if (dsa)
        goto legacy;
    OSSL_BIO_reset(in);

    pkey = ossl_pkey_read_generic(in, pass);
    BIO_free(in);
    if (!pkey)
        ossl_raise(eDSAError, "Neither PUB key nor PRIV key");

    type = EVP_PKEY_base_id(pkey);
    if (type != EVP_PKEY_DSA) {
        EVP_PKEY_free(pkey);
        rb_raise(eDSAError, "incorrect pkey type: %s", OBJ_nid2sn(type));
    }
    RTYPEDDATA_DATA(self) = pkey;
    return self;

  legacy:
    BIO_free(in);
    pkey = EVP_PKEY_new();
    if (!pkey || EVP_PKEY_assign_DSA(pkey, dsa) != 1) {
        EVP_PKEY_free(pkey);
        DSA_free(dsa);
        ossl_raise(eDSAError, "EVP_PKEY_assign_DSA");
    }
    RTYPEDDATA_DATA(self) = pkey;
    return self;
}

#ifndef HAVE_EVP_PKEY_DUP
static VALUE
ossl_dsa_initialize_copy(VALUE self, VALUE other)
{
    EVP_PKEY *pkey;
    DSA *dsa, *dsa_new;

    TypedData_Get_Struct(self, EVP_PKEY, &ossl_evp_pkey_type, pkey);
    if (pkey)
        rb_raise(rb_eTypeError, "pkey already initialized");
    GetDSA(other, dsa);

    dsa_new = (DSA *)ASN1_dup((i2d_of_void *)i2d_DSAPrivateKey,
                              (d2i_of_void *)d2i_DSAPrivateKey,
                              (char *)dsa);
    if (!dsa_new)
	ossl_raise(eDSAError, "ASN1_dup");

    pkey = EVP_PKEY_new();
    if (!pkey || EVP_PKEY_assign_DSA(pkey, dsa_new) != 1) {
        EVP_PKEY_free(pkey);
        DSA_free(dsa_new);
        ossl_raise(eDSAError, "EVP_PKEY_assign_DSA");
    }
    RTYPEDDATA_DATA(self) = pkey;

    return self;
}
#endif

/*
 *  call-seq:
 *    dsa.public? -> true | false
 *
 * Indicates whether this DSA instance has a public key associated with it or
 * not. The public key may be retrieved with DSA#public_key.
 */
static VALUE
ossl_dsa_is_public(VALUE self)
{
    const DSA *dsa;
    const BIGNUM *bn;

    GetDSA(self, dsa);
    DSA_get0_key(dsa, &bn, NULL);

    return bn ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *    dsa.private? -> true | false
 *
 * Indicates whether this DSA instance has a private key associated with it or
 * not. The private key may be retrieved with DSA#private_key.
 */
static VALUE
ossl_dsa_is_private(VALUE self)
{
    OSSL_3_const DSA *dsa;

    GetDSA(self, dsa);

    return DSA_PRIVATE(self, dsa) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *    dsa.export([cipher, password]) -> aString
 *    dsa.to_pem([cipher, password]) -> aString
 *    dsa.to_s([cipher, password]) -> aString
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
 *   X.509 SubjectPublicKeyInfo regardless of whether it is a public key
 *   or a private key.
 *
 * [When the key contains private components, and no parameters are given]
 *
 *   Serializes it into a traditional \OpenSSL DSAPrivateKey.
 *
 *   A PEM-encoded key will look like:
 *
 *     -----BEGIN DSA PRIVATE KEY-----
 *     [...]
 *     -----END DSA PRIVATE KEY-----
 *
 * [When the key contains private components, and _cipher_ and _password_ are given]
 *
 *   Serializes it into a traditional \OpenSSL DSAPrivateKey and encrypts it in
 *   OpenSSL's traditional PEM encryption format.
 *   _cipher_ must be a cipher name understood by OpenSSL::Cipher.new or an
 *   instance of OpenSSL::Cipher.
 *
 *   An encrypted PEM-encoded key will look like:
 *
 *     -----BEGIN DSA PRIVATE KEY-----
 *     Proc-Type: 4,ENCRYPTED
 *     DEK-Info: AES-128-CBC,733F5302505B34701FC41F5C0746E4C0
 *
 *     [...]
 *     -----END DSA PRIVATE KEY-----
 *
 *   Note that this format uses MD5 to derive the encryption key, and hence
 *   will not be available on FIPS-compliant systems.
 *
 * <b>This method is kept for compatibility.</b>
 * This should only be used when the traditional, non-standard \OpenSSL format
 * is required.
 *
 * Consider using #public_to_pem (X.509 SubjectPublicKeyInfo) or #private_to_pem
 * (PKCS #8 PrivateKeyInfo or EncryptedPrivateKeyInfo) instead.
 */
static VALUE
ossl_dsa_export(int argc, VALUE *argv, VALUE self)
{
    OSSL_3_const DSA *dsa;

    GetDSA(self, dsa);
    if (DSA_HAS_PRIVATE(dsa))
        return ossl_pkey_export_traditional(argc, argv, self, 0);
    else
        return ossl_pkey_export_spki(self, 0);
}

/*
 *  call-seq:
 *    dsa.to_der -> aString
 *
 * Serializes a private or public key to a DER-encoding.
 *
 * See #to_pem for details.
 *
 * <b>This method is kept for compatibility.</b>
 * This should only be used when the traditional, non-standard \OpenSSL format
 * is required.
 *
 * Consider using #public_to_der or #private_to_der instead.
 */
static VALUE
ossl_dsa_to_der(VALUE self)
{
    OSSL_3_const DSA *dsa;

    GetDSA(self, dsa);
    if (DSA_HAS_PRIVATE(dsa))
        return ossl_pkey_export_traditional(0, NULL, self, 1);
    else
        return ossl_pkey_export_spki(self, 1);
}


/*
 *  call-seq:
 *    dsa.params -> hash
 *
 * Stores all parameters of key to the hash
 * INSECURE: PRIVATE INFORMATIONS CAN LEAK OUT!!!
 * Don't use :-)) (I's up to you)
 */
static VALUE
ossl_dsa_get_params(VALUE self)
{
    OSSL_3_const DSA *dsa;
    VALUE hash;
    const BIGNUM *p, *q, *g, *pub_key, *priv_key;

    GetDSA(self, dsa);
    DSA_get0_pqg(dsa, &p, &q, &g);
    DSA_get0_key(dsa, &pub_key, &priv_key);

    hash = rb_hash_new();
    rb_hash_aset(hash, rb_str_new2("p"), ossl_bn_new(p));
    rb_hash_aset(hash, rb_str_new2("q"), ossl_bn_new(q));
    rb_hash_aset(hash, rb_str_new2("g"), ossl_bn_new(g));
    rb_hash_aset(hash, rb_str_new2("pub_key"), ossl_bn_new(pub_key));
    rb_hash_aset(hash, rb_str_new2("priv_key"), ossl_bn_new(priv_key));

    return hash;
}

/*
 * Document-method: OpenSSL::PKey::DSA#set_pqg
 * call-seq:
 *   dsa.set_pqg(p, q, g) -> self
 *
 * Sets _p_, _q_, _g_ to the DSA instance.
 */
OSSL_PKEY_BN_DEF3(dsa, DSA, pqg, p, q, g)
/*
 * Document-method: OpenSSL::PKey::DSA#set_key
 * call-seq:
 *   dsa.set_key(pub_key, priv_key) -> self
 *
 * Sets _pub_key_ and _priv_key_ for the DSA instance. _priv_key_ may be +nil+.
 */
OSSL_PKEY_BN_DEF2(dsa, DSA, key, pub_key, priv_key)

/*
 * INIT
 */
void
Init_ossl_dsa(void)
{
#if 0
    mPKey = rb_define_module_under(mOSSL, "PKey");
    cPKey = rb_define_class_under(mPKey, "PKey", rb_cObject);
    ePKeyError = rb_define_class_under(mPKey, "PKeyError", eOSSLError);
#endif

    /* Document-class: OpenSSL::PKey::DSAError
     *
     * Generic exception that is raised if an operation on a DSA PKey
     * fails unexpectedly or in case an instantiation of an instance of DSA
     * fails due to non-conformant input data.
     */
    eDSAError = rb_define_class_under(mPKey, "DSAError", ePKeyError);

    /* Document-class: OpenSSL::PKey::DSA
     *
     * DSA, the Digital Signature Algorithm, is specified in NIST's
     * FIPS 186-3. It is an asymmetric public key algorithm that may be used
     * similar to e.g. RSA.
     */
    cDSA = rb_define_class_under(mPKey, "DSA", cPKey);

    rb_define_method(cDSA, "initialize", ossl_dsa_initialize, -1);
#ifndef HAVE_EVP_PKEY_DUP
    rb_define_method(cDSA, "initialize_copy", ossl_dsa_initialize_copy, 1);
#endif

    rb_define_method(cDSA, "public?", ossl_dsa_is_public, 0);
    rb_define_method(cDSA, "private?", ossl_dsa_is_private, 0);
    rb_define_method(cDSA, "export", ossl_dsa_export, -1);
    rb_define_alias(cDSA, "to_pem", "export");
    rb_define_alias(cDSA, "to_s", "export");
    rb_define_method(cDSA, "to_der", ossl_dsa_to_der, 0);

    DEF_OSSL_PKEY_BN(cDSA, dsa, p);
    DEF_OSSL_PKEY_BN(cDSA, dsa, q);
    DEF_OSSL_PKEY_BN(cDSA, dsa, g);
    DEF_OSSL_PKEY_BN(cDSA, dsa, pub_key);
    DEF_OSSL_PKEY_BN(cDSA, dsa, priv_key);
    rb_define_method(cDSA, "set_pqg", ossl_dsa_set_pqg, 3);
    rb_define_method(cDSA, "set_key", ossl_dsa_set_key, 2);

    rb_define_method(cDSA, "params", ossl_dsa_get_params, 0);
}

#else /* defined NO_DSA */
void
Init_ossl_dsa(void)
{
}
#endif /* NO_DSA */
