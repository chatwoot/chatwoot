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

#define NewHMAC(klass) \
    TypedData_Wrap_Struct((klass), &ossl_hmac_type, 0)
#define GetHMAC(obj, ctx) do { \
    TypedData_Get_Struct((obj), EVP_MD_CTX, &ossl_hmac_type, (ctx)); \
    if (!(ctx)) { \
	ossl_raise(rb_eRuntimeError, "HMAC wasn't initialized"); \
    } \
} while (0)

/*
 * Classes
 */
VALUE cHMAC;
VALUE eHMACError;

/*
 * Public
 */

/*
 * Private
 */
static void
ossl_hmac_free(void *ctx)
{
    EVP_MD_CTX_free(ctx);
}

static const rb_data_type_t ossl_hmac_type = {
    "OpenSSL/HMAC",
    {
	0, ossl_hmac_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
ossl_hmac_alloc(VALUE klass)
{
    VALUE obj;
    EVP_MD_CTX *ctx;

    obj = NewHMAC(klass);
    ctx = EVP_MD_CTX_new();
    if (!ctx)
        ossl_raise(eHMACError, "EVP_MD_CTX");
    RTYPEDDATA_DATA(obj) = ctx;

    return obj;
}


/*
 *  call-seq:
 *     HMAC.new(key, digest) -> hmac
 *
 * Returns an instance of OpenSSL::HMAC set with the key and digest
 * algorithm to be used. The instance represents the initial state of
 * the message authentication code before any data has been processed.
 * To process data with it, use the instance method #update with your
 * data as an argument.
 *
 * === Example
 *
 *	key = 'key'
 * 	instance = OpenSSL::HMAC.new(key, 'SHA1')
 * 	#=> f42bb0eeb018ebbd4597ae7213711ec60760843f
 * 	instance.class
 * 	#=> OpenSSL::HMAC
 *
 * === A note about comparisons
 *
 * Two instances can be securely compared with #== in constant time:
 *
 *	other_instance = OpenSSL::HMAC.new('key', 'SHA1')
 *  #=> f42bb0eeb018ebbd4597ae7213711ec60760843f
 *  instance == other_instance
 *  #=> true
 *
 */
static VALUE
ossl_hmac_initialize(VALUE self, VALUE key, VALUE digest)
{
    EVP_MD_CTX *ctx;
    EVP_PKEY *pkey;

    GetHMAC(self, ctx);
    StringValue(key);
#ifdef HAVE_EVP_PKEY_NEW_RAW_PRIVATE_KEY
    pkey = EVP_PKEY_new_raw_private_key(EVP_PKEY_HMAC, NULL,
                                        (unsigned char *)RSTRING_PTR(key),
                                        RSTRING_LENINT(key));
    if (!pkey)
        ossl_raise(eHMACError, "EVP_PKEY_new_raw_private_key");
#else
    pkey = EVP_PKEY_new_mac_key(EVP_PKEY_HMAC, NULL,
                                (unsigned char *)RSTRING_PTR(key),
                                RSTRING_LENINT(key));
    if (!pkey)
        ossl_raise(eHMACError, "EVP_PKEY_new_mac_key");
#endif
    if (EVP_DigestSignInit(ctx, NULL, ossl_evp_get_digestbyname(digest),
                           NULL, pkey) != 1) {
        EVP_PKEY_free(pkey);
        ossl_raise(eHMACError, "EVP_DigestSignInit");
    }
    /* Decrement reference counter; EVP_MD_CTX still keeps it */
    EVP_PKEY_free(pkey);

    return self;
}

static VALUE
ossl_hmac_copy(VALUE self, VALUE other)
{
    EVP_MD_CTX *ctx1, *ctx2;

    rb_check_frozen(self);
    if (self == other) return self;

    GetHMAC(self, ctx1);
    GetHMAC(other, ctx2);
    if (EVP_MD_CTX_copy(ctx1, ctx2) != 1)
        ossl_raise(eHMACError, "EVP_MD_CTX_copy");
    return self;
}

/*
 *  call-seq:
 *     hmac.update(string) -> self
 *
 * Returns _hmac_ updated with the message to be authenticated.
 * Can be called repeatedly with chunks of the message.
 *
 * === Example
 *
 *	first_chunk = 'The quick brown fox jumps '
 * 	second_chunk = 'over the lazy dog'
 *
 * 	instance.update(first_chunk)
 * 	#=> 5b9a8038a65d571076d97fe783989e52278a492a
 * 	instance.update(second_chunk)
 * 	#=> de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9
 *
 */
static VALUE
ossl_hmac_update(VALUE self, VALUE data)
{
    EVP_MD_CTX *ctx;

    StringValue(data);
    GetHMAC(self, ctx);
    if (EVP_DigestSignUpdate(ctx, RSTRING_PTR(data), RSTRING_LEN(data)) != 1)
        ossl_raise(eHMACError, "EVP_DigestSignUpdate");

    return self;
}

/*
 *  call-seq:
 *     hmac.digest -> string
 *
 * Returns the authentication code an instance represents as a binary string.
 *
 * === Example
 *  instance = OpenSSL::HMAC.new('key', 'SHA1')
 *  #=> f42bb0eeb018ebbd4597ae7213711ec60760843f
 *  instance.digest
 *  #=> "\xF4+\xB0\xEE\xB0\x18\xEB\xBDE\x97\xAEr\x13q\x1E\xC6\a`\x84?"
 */
static VALUE
ossl_hmac_digest(VALUE self)
{
    EVP_MD_CTX *ctx;
    size_t buf_len = EVP_MAX_MD_SIZE;
    VALUE ret;

    GetHMAC(self, ctx);
    ret = rb_str_new(NULL, EVP_MAX_MD_SIZE);
    if (EVP_DigestSignFinal(ctx, (unsigned char *)RSTRING_PTR(ret),
                            &buf_len) != 1)
        ossl_raise(eHMACError, "EVP_DigestSignFinal");
    rb_str_set_len(ret, (long)buf_len);

    return ret;
}

/*
 *  call-seq:
 *     hmac.hexdigest -> string
 *
 * Returns the authentication code an instance represents as a hex-encoded
 * string.
 */
static VALUE
ossl_hmac_hexdigest(VALUE self)
{
    EVP_MD_CTX *ctx;
    unsigned char buf[EVP_MAX_MD_SIZE];
    size_t buf_len = EVP_MAX_MD_SIZE;
    VALUE ret;

    GetHMAC(self, ctx);
    if (EVP_DigestSignFinal(ctx, buf, &buf_len) != 1)
        ossl_raise(eHMACError, "EVP_DigestSignFinal");
    ret = rb_str_new(NULL, buf_len * 2);
    ossl_bin2hex(buf, RSTRING_PTR(ret), buf_len);

    return ret;
}

/*
 *  call-seq:
 *     hmac.reset -> self
 *
 * Returns _hmac_ as it was when it was first initialized, with all processed
 * data cleared from it.
 *
 * === Example
 *
 *	data = "The quick brown fox jumps over the lazy dog"
 * 	instance = OpenSSL::HMAC.new('key', 'SHA1')
 * 	#=> f42bb0eeb018ebbd4597ae7213711ec60760843f
 *
 * 	instance.update(data)
 * 	#=> de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9
 * 	instance.reset
 * 	#=> f42bb0eeb018ebbd4597ae7213711ec60760843f
 *
 */
static VALUE
ossl_hmac_reset(VALUE self)
{
    EVP_MD_CTX *ctx;
    EVP_PKEY *pkey;

    GetHMAC(self, ctx);
    pkey = EVP_PKEY_CTX_get0_pkey(EVP_MD_CTX_get_pkey_ctx(ctx));
    if (EVP_DigestSignInit(ctx, NULL, EVP_MD_CTX_get0_md(ctx), NULL, pkey) != 1)
        ossl_raise(eHMACError, "EVP_DigestSignInit");

    return self;
}

/*
 * INIT
 */
void
Init_ossl_hmac(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    /*
     * Document-class: OpenSSL::HMAC
     *
     * OpenSSL::HMAC allows computing Hash-based Message Authentication Code
     * (HMAC). It is a type of message authentication code (MAC) involving a
     * hash function in combination with a key. HMAC can be used to verify the
     * integrity of a message as well as the authenticity.
     *
     * OpenSSL::HMAC has a similar interface to OpenSSL::Digest.
     *
     * === HMAC-SHA256 using one-shot interface
     *
     *   key = "key"
     *   data = "message-to-be-authenticated"
     *   mac = OpenSSL::HMAC.hexdigest("SHA256", key, data)
     *   #=> "cddb0db23f469c8bf072b21fd837149bd6ace9ab771cceef14c9e517cc93282e"
     *
     * === HMAC-SHA256 using incremental interface
     *
     *   data1 = File.binread("file1")
     *   data2 = File.binread("file2")
     *   key = "key"
     *   hmac = OpenSSL::HMAC.new(key, 'SHA256')
     *   hmac << data1
     *   hmac << data2
     *   mac = hmac.digest
     */
    eHMACError = rb_define_class_under(mOSSL, "HMACError", eOSSLError);

    cHMAC = rb_define_class_under(mOSSL, "HMAC", rb_cObject);

    rb_define_alloc_func(cHMAC, ossl_hmac_alloc);

    rb_define_method(cHMAC, "initialize", ossl_hmac_initialize, 2);
    rb_define_method(cHMAC, "initialize_copy", ossl_hmac_copy, 1);

    rb_define_method(cHMAC, "reset", ossl_hmac_reset, 0);
    rb_define_method(cHMAC, "update", ossl_hmac_update, 1);
    rb_define_alias(cHMAC, "<<", "update");
    rb_define_method(cHMAC, "digest", ossl_hmac_digest, 0);
    rb_define_method(cHMAC, "hexdigest", ossl_hmac_hexdigest, 0);
    rb_define_alias(cHMAC, "inspect", "hexdigest");
    rb_define_alias(cHMAC, "to_s", "hexdigest");
}
