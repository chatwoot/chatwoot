/*
 * Ruby/OpenSSL Project
 * Copyright (C) 2007, 2017 Ruby/OpenSSL Project Authors
 */
#include "ossl.h"
#if OSSL_OPENSSL_PREREQ(1, 1, 0) || OSSL_LIBRESSL_PREREQ(3, 6, 0)
# include <openssl/kdf.h>
#endif

static VALUE mKDF, eKDF;

/*
 * call-seq:
 *   KDF.pbkdf2_hmac(pass, salt:, iterations:, length:, hash:) -> aString
 *
 * PKCS #5 PBKDF2 (Password-Based Key Derivation Function 2) in combination
 * with HMAC. Takes _pass_, _salt_ and _iterations_, and then derives a key
 * of _length_ bytes.
 *
 * For more information about PBKDF2, see RFC 2898 Section 5.2
 * (https://tools.ietf.org/html/rfc2898#section-5.2).
 *
 * === Parameters
 * pass       :: The password.
 * salt       :: The salt. Salts prevent attacks based on dictionaries of common
 *               passwords and attacks based on rainbow tables. It is a public
 *               value that can be safely stored along with the password (e.g.
 *               if the derived value is used for password storage).
 * iterations :: The iteration count. This provides the ability to tune the
 *               algorithm. It is better to use the highest count possible for
 *               the maximum resistance to brute-force attacks.
 * length     :: The desired length of the derived key in octets.
 * hash       :: The hash algorithm used with HMAC for the PRF. May be a String
 *               representing the algorithm name, or an instance of
 *               OpenSSL::Digest.
 */
static VALUE
kdf_pbkdf2_hmac(int argc, VALUE *argv, VALUE self)
{
    VALUE pass, salt, opts, kwargs[4], str;
    static ID kwargs_ids[4];
    int iters, len;
    const EVP_MD *md;

    if (!kwargs_ids[0]) {
	kwargs_ids[0] = rb_intern_const("salt");
	kwargs_ids[1] = rb_intern_const("iterations");
	kwargs_ids[2] = rb_intern_const("length");
	kwargs_ids[3] = rb_intern_const("hash");
    }
    rb_scan_args(argc, argv, "1:", &pass, &opts);
    rb_get_kwargs(opts, kwargs_ids, 4, 0, kwargs);

    StringValue(pass);
    salt = StringValue(kwargs[0]);
    iters = NUM2INT(kwargs[1]);
    len = NUM2INT(kwargs[2]);
    md = ossl_evp_get_digestbyname(kwargs[3]);

    str = rb_str_new(0, len);
    if (!PKCS5_PBKDF2_HMAC(RSTRING_PTR(pass), RSTRING_LENINT(pass),
			   (unsigned char *)RSTRING_PTR(salt),
			   RSTRING_LENINT(salt), iters, md, len,
			   (unsigned char *)RSTRING_PTR(str)))
	ossl_raise(eKDF, "PKCS5_PBKDF2_HMAC");

    return str;
}

#if defined(HAVE_EVP_PBE_SCRYPT)
/*
 * call-seq:
 *   KDF.scrypt(pass, salt:, N:, r:, p:, length:) -> aString
 *
 * Derives a key from _pass_ using given parameters with the scrypt
 * password-based key derivation function. The result can be used for password
 * storage.
 *
 * scrypt is designed to be memory-hard and more secure against brute-force
 * attacks using custom hardwares than alternative KDFs such as PBKDF2 or
 * bcrypt.
 *
 * The keyword arguments _N_, _r_ and _p_ can be used to tune scrypt. RFC 7914
 * (published on 2016-08, https://tools.ietf.org/html/rfc7914#section-2) states
 * that using values r=8 and p=1 appears to yield good results.
 *
 * See RFC 7914 (https://tools.ietf.org/html/rfc7914) for more information.
 *
 * === Parameters
 * pass   :: Passphrase.
 * salt   :: Salt.
 * N      :: CPU/memory cost parameter. This must be a power of 2.
 * r      :: Block size parameter.
 * p      :: Parallelization parameter.
 * length :: Length in octets of the derived key.
 *
 * === Example
 *   pass = "password"
 *   salt = SecureRandom.random_bytes(16)
 *   dk = OpenSSL::KDF.scrypt(pass, salt: salt, N: 2**14, r: 8, p: 1, length: 32)
 *   p dk #=> "\xDA\xE4\xE2...\x7F\xA1\x01T"
 */
static VALUE
kdf_scrypt(int argc, VALUE *argv, VALUE self)
{
    VALUE pass, salt, opts, kwargs[5], str;
    static ID kwargs_ids[5];
    size_t len;
    uint64_t N, r, p, maxmem;

    if (!kwargs_ids[0]) {
	kwargs_ids[0] = rb_intern_const("salt");
	kwargs_ids[1] = rb_intern_const("N");
	kwargs_ids[2] = rb_intern_const("r");
	kwargs_ids[3] = rb_intern_const("p");
	kwargs_ids[4] = rb_intern_const("length");
    }
    rb_scan_args(argc, argv, "1:", &pass, &opts);
    rb_get_kwargs(opts, kwargs_ids, 5, 0, kwargs);

    StringValue(pass);
    salt = StringValue(kwargs[0]);
    N = NUM2UINT64T(kwargs[1]);
    r = NUM2UINT64T(kwargs[2]);
    p = NUM2UINT64T(kwargs[3]);
    len = NUM2LONG(kwargs[4]);
    /*
     * OpenSSL uses 32MB by default (if zero is specified), which is too small.
     * Let's not limit memory consumption but just let malloc() fail inside
     * OpenSSL. The amount is controllable by other parameters.
     */
    maxmem = SIZE_MAX;

    str = rb_str_new(0, len);
    if (!EVP_PBE_scrypt(RSTRING_PTR(pass), RSTRING_LEN(pass),
			(unsigned char *)RSTRING_PTR(salt), RSTRING_LEN(salt),
			N, r, p, maxmem, (unsigned char *)RSTRING_PTR(str), len))
	ossl_raise(eKDF, "EVP_PBE_scrypt");

    return str;
}
#endif

#if OSSL_OPENSSL_PREREQ(1, 1, 0) || OSSL_LIBRESSL_PREREQ(3, 6, 0)
/*
 * call-seq:
 *    KDF.hkdf(ikm, salt:, info:, length:, hash:) -> String
 *
 * HMAC-based Extract-and-Expand Key Derivation Function (HKDF) as specified in
 * {RFC 5869}[https://tools.ietf.org/html/rfc5869].
 *
 * New in OpenSSL 1.1.0.
 *
 * === Parameters
 * _ikm_::
 *   The input keying material.
 * _salt_::
 *   The salt.
 * _info_::
 *   The context and application specific information.
 * _length_::
 *   The output length in octets. Must be <= <tt>255 * HashLen</tt>, where
 *   HashLen is the length of the hash function output in octets.
 * _hash_::
 *   The hash function.
 *
 * === Example
 *   # The values from https://datatracker.ietf.org/doc/html/rfc5869#appendix-A.1
 *   ikm = ["0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"].pack("H*")
 *   salt = ["000102030405060708090a0b0c"].pack("H*")
 *   info = ["f0f1f2f3f4f5f6f7f8f9"].pack("H*")
 *   p OpenSSL::KDF.hkdf(ikm, salt: salt, info: info, length: 42, hash: "SHA256").unpack1("H*")
 *   # => "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"
 */
static VALUE
kdf_hkdf(int argc, VALUE *argv, VALUE self)
{
    VALUE ikm, salt, info, opts, kwargs[4], str;
    static ID kwargs_ids[4];
    int saltlen, ikmlen, infolen;
    size_t len;
    const EVP_MD *md;
    EVP_PKEY_CTX *pctx;

    if (!kwargs_ids[0]) {
	kwargs_ids[0] = rb_intern_const("salt");
	kwargs_ids[1] = rb_intern_const("info");
	kwargs_ids[2] = rb_intern_const("length");
	kwargs_ids[3] = rb_intern_const("hash");
    }
    rb_scan_args(argc, argv, "1:", &ikm, &opts);
    rb_get_kwargs(opts, kwargs_ids, 4, 0, kwargs);

    StringValue(ikm);
    ikmlen = RSTRING_LENINT(ikm);
    salt = StringValue(kwargs[0]);
    saltlen = RSTRING_LENINT(salt);
    info = StringValue(kwargs[1]);
    infolen = RSTRING_LENINT(info);
    len = (size_t)NUM2LONG(kwargs[2]);
    if (len > LONG_MAX)
	rb_raise(rb_eArgError, "length must be non-negative");
    md = ossl_evp_get_digestbyname(kwargs[3]);

    str = rb_str_new(NULL, (long)len);
    pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_HKDF, NULL);
    if (!pctx)
	ossl_raise(eKDF, "EVP_PKEY_CTX_new_id");
    if (EVP_PKEY_derive_init(pctx) <= 0) {
	EVP_PKEY_CTX_free(pctx);
	ossl_raise(eKDF, "EVP_PKEY_derive_init");
    }
    if (EVP_PKEY_CTX_set_hkdf_md(pctx, md) <= 0) {
	EVP_PKEY_CTX_free(pctx);
	ossl_raise(eKDF, "EVP_PKEY_CTX_set_hkdf_md");
    }
    if (EVP_PKEY_CTX_set1_hkdf_salt(pctx, (unsigned char *)RSTRING_PTR(salt),
				    saltlen) <= 0) {
	EVP_PKEY_CTX_free(pctx);
	ossl_raise(eKDF, "EVP_PKEY_CTX_set_hkdf_salt");
    }
    if (EVP_PKEY_CTX_set1_hkdf_key(pctx, (unsigned char *)RSTRING_PTR(ikm),
				   ikmlen) <= 0) {
	EVP_PKEY_CTX_free(pctx);
	ossl_raise(eKDF, "EVP_PKEY_CTX_set_hkdf_key");
    }
    if (EVP_PKEY_CTX_add1_hkdf_info(pctx, (unsigned char *)RSTRING_PTR(info),
				    infolen) <= 0) {
	EVP_PKEY_CTX_free(pctx);
	ossl_raise(eKDF, "EVP_PKEY_CTX_set_hkdf_info");
    }
    if (EVP_PKEY_derive(pctx, (unsigned char *)RSTRING_PTR(str), &len) <= 0) {
	EVP_PKEY_CTX_free(pctx);
	ossl_raise(eKDF, "EVP_PKEY_derive");
    }
    rb_str_set_len(str, (long)len);
    EVP_PKEY_CTX_free(pctx);

    return str;
}
#endif

void
Init_ossl_kdf(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    /*
     * Document-module: OpenSSL::KDF
     *
     * Provides functionality of various KDFs (key derivation function).
     *
     * KDF is typically used for securely deriving arbitrary length symmetric
     * keys to be used with an OpenSSL::Cipher from passwords. Another use case
     * is for storing passwords: Due to the ability to tweak the effort of
     * computation by increasing the iteration count, computation can be slowed
     * down artificially in order to render possible attacks infeasible.
     *
     * Currently, OpenSSL::KDF provides implementations for the following KDF:
     *
     * * PKCS #5 PBKDF2 (Password-Based Key Derivation Function 2) in
     *   combination with HMAC
     * * scrypt
     * * HKDF
     *
     * == Examples
     * === Generating a 128 bit key for a Cipher (e.g. AES)
     *   pass = "secret"
     *   salt = OpenSSL::Random.random_bytes(16)
     *   iter = 20_000
     *   key_len = 16
     *   key = OpenSSL::KDF.pbkdf2_hmac(pass, salt: salt, iterations: iter,
     *                                  length: key_len, hash: "sha1")
     *
     * === Storing Passwords
     *   pass = "secret"
     *   # store this with the generated value
     *   salt = OpenSSL::Random.random_bytes(16)
     *   iter = 20_000
     *   hash = OpenSSL::Digest.new('SHA256')
     *   len = hash.digest_length
     *   # the final value to be stored
     *   value = OpenSSL::KDF.pbkdf2_hmac(pass, salt: salt, iterations: iter,
     *                                    length: len, hash: hash)
     *
     * == Important Note on Checking Passwords
     * When comparing passwords provided by the user with previously stored
     * values, a common mistake made is comparing the two values using "==".
     * Typically, "==" short-circuits on evaluation, and is therefore
     * vulnerable to timing attacks. The proper way is to use a method that
     * always takes the same amount of time when comparing two values, thus
     * not leaking any information to potential attackers. To do this, use
     * +OpenSSL.fixed_length_secure_compare+.
     */
    mKDF = rb_define_module_under(mOSSL, "KDF");
    /*
     * Generic exception class raised if an error occurs in OpenSSL::KDF module.
     */
    eKDF = rb_define_class_under(mKDF, "KDFError", eOSSLError);

    rb_define_module_function(mKDF, "pbkdf2_hmac", kdf_pbkdf2_hmac, -1);
#if defined(HAVE_EVP_PBE_SCRYPT)
    rb_define_module_function(mKDF, "scrypt", kdf_scrypt, -1);
#endif
#if OSSL_OPENSSL_PREREQ(1, 1, 0) || OSSL_LIBRESSL_PREREQ(3, 6, 0)
    rb_define_module_function(mKDF, "hkdf", kdf_hkdf, -1);
#endif
}
