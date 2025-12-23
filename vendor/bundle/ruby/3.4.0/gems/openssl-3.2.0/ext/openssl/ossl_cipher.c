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

#define NewCipher(klass) \
    TypedData_Wrap_Struct((klass), &ossl_cipher_type, 0)
#define AllocCipher(obj, ctx) do { \
    (ctx) = EVP_CIPHER_CTX_new(); \
    if (!(ctx)) \
	ossl_raise(rb_eRuntimeError, NULL); \
    RTYPEDDATA_DATA(obj) = (ctx); \
} while (0)
#define GetCipherInit(obj, ctx) do { \
    TypedData_Get_Struct((obj), EVP_CIPHER_CTX, &ossl_cipher_type, (ctx)); \
} while (0)
#define GetCipher(obj, ctx) do { \
    GetCipherInit((obj), (ctx)); \
    if (!(ctx)) { \
	ossl_raise(rb_eRuntimeError, "Cipher not initialized!"); \
    } \
} while (0)

/*
 * Classes
 */
VALUE cCipher;
VALUE eCipherError;
static ID id_auth_tag_len, id_key_set;

static VALUE ossl_cipher_alloc(VALUE klass);
static void ossl_cipher_free(void *ptr);

static const rb_data_type_t ossl_cipher_type = {
    "OpenSSL/Cipher",
    {
	0, ossl_cipher_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

/*
 * PUBLIC
 */
const EVP_CIPHER *
ossl_evp_get_cipherbyname(VALUE obj)
{
    if (rb_obj_is_kind_of(obj, cCipher)) {
	EVP_CIPHER_CTX *ctx;

	GetCipher(obj, ctx);

	return EVP_CIPHER_CTX_cipher(ctx);
    }
    else {
	const EVP_CIPHER *cipher;

	StringValueCStr(obj);
	cipher = EVP_get_cipherbyname(RSTRING_PTR(obj));
	if (!cipher)
	    ossl_raise(rb_eArgError,
		       "unsupported cipher algorithm: %"PRIsVALUE, obj);

	return cipher;
    }
}

VALUE
ossl_cipher_new(const EVP_CIPHER *cipher)
{
    VALUE ret;
    EVP_CIPHER_CTX *ctx;

    ret = ossl_cipher_alloc(cCipher);
    AllocCipher(ret, ctx);
    if (EVP_CipherInit_ex(ctx, cipher, NULL, NULL, NULL, -1) != 1)
	ossl_raise(eCipherError, NULL);

    return ret;
}

/*
 * PRIVATE
 */
static void
ossl_cipher_free(void *ptr)
{
    EVP_CIPHER_CTX_free(ptr);
}

static VALUE
ossl_cipher_alloc(VALUE klass)
{
    return NewCipher(klass);
}

/*
 *  call-seq:
 *     Cipher.new(string) -> cipher
 *
 *  The string must contain a valid cipher name like "aes-256-cbc".
 *
 *  A list of cipher names is available by calling OpenSSL::Cipher.ciphers.
 */
static VALUE
ossl_cipher_initialize(VALUE self, VALUE str)
{
    EVP_CIPHER_CTX *ctx;
    const EVP_CIPHER *cipher;
    char *name;

    name = StringValueCStr(str);
    GetCipherInit(self, ctx);
    if (ctx) {
	ossl_raise(rb_eRuntimeError, "Cipher already initialized!");
    }
    AllocCipher(self, ctx);
    if (!(cipher = EVP_get_cipherbyname(name))) {
	ossl_raise(rb_eRuntimeError, "unsupported cipher algorithm (%"PRIsVALUE")", str);
    }
    if (EVP_CipherInit_ex(ctx, cipher, NULL, NULL, NULL, -1) != 1)
	ossl_raise(eCipherError, NULL);

    return self;
}

static VALUE
ossl_cipher_copy(VALUE self, VALUE other)
{
    EVP_CIPHER_CTX *ctx1, *ctx2;

    rb_check_frozen(self);
    if (self == other) return self;

    GetCipherInit(self, ctx1);
    if (!ctx1) {
	AllocCipher(self, ctx1);
    }
    GetCipher(other, ctx2);
    if (EVP_CIPHER_CTX_copy(ctx1, ctx2) != 1)
	ossl_raise(eCipherError, NULL);

    return self;
}

static void
add_cipher_name_to_ary(const OBJ_NAME *name, void *arg)
{
    VALUE ary = (VALUE)arg;
    rb_ary_push(ary, rb_str_new2(name->name));
}

/*
 *  call-seq:
 *     OpenSSL::Cipher.ciphers -> array[string...]
 *
 *  Returns the names of all available ciphers in an array.
 */
static VALUE
ossl_s_ciphers(VALUE self)
{
    VALUE ary;

    ary = rb_ary_new();
    OBJ_NAME_do_all_sorted(OBJ_NAME_TYPE_CIPHER_METH,
                    add_cipher_name_to_ary,
                    (void*)ary);

    return ary;
}

/*
 *  call-seq:
 *     cipher.reset -> self
 *
 *  Fully resets the internal state of the Cipher. By using this, the same
 *  Cipher instance may be used several times for encryption or decryption tasks.
 *
 *  Internally calls EVP_CipherInit_ex(ctx, NULL, NULL, NULL, NULL, -1).
 */
static VALUE
ossl_cipher_reset(VALUE self)
{
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);
    if (EVP_CipherInit_ex(ctx, NULL, NULL, NULL, NULL, -1) != 1)
	ossl_raise(eCipherError, NULL);

    return self;
}

static VALUE
ossl_cipher_init(int argc, VALUE *argv, VALUE self, int mode)
{
    EVP_CIPHER_CTX *ctx;
    unsigned char key[EVP_MAX_KEY_LENGTH], *p_key = NULL;
    unsigned char iv[EVP_MAX_IV_LENGTH], *p_iv = NULL;
    VALUE pass, init_v;

    if(rb_scan_args(argc, argv, "02", &pass, &init_v) > 0){
	/*
	 * oops. this code mistakes salt for IV.
	 * We deprecated the arguments for this method, but we decided
	 * keeping this behaviour for backward compatibility.
	 */
	VALUE cname  = rb_class_path(rb_obj_class(self));
	rb_warn("arguments for %"PRIsVALUE"#encrypt and %"PRIsVALUE"#decrypt were deprecated; "
                "use %"PRIsVALUE"#pkcs5_keyivgen to derive key and IV",
                cname, cname, cname);
	StringValue(pass);
	GetCipher(self, ctx);
	if (NIL_P(init_v)) memcpy(iv, "OpenSSL for Ruby rulez!", sizeof(iv));
	else{
	    StringValue(init_v);
	    if (EVP_MAX_IV_LENGTH > RSTRING_LEN(init_v)) {
		memset(iv, 0, EVP_MAX_IV_LENGTH);
		memcpy(iv, RSTRING_PTR(init_v), RSTRING_LEN(init_v));
	    }
	    else memcpy(iv, RSTRING_PTR(init_v), sizeof(iv));
	}
	EVP_BytesToKey(EVP_CIPHER_CTX_cipher(ctx), EVP_md5(), iv,
		       (unsigned char *)RSTRING_PTR(pass), RSTRING_LENINT(pass), 1, key, NULL);
	p_key = key;
	p_iv = iv;
    }
    else {
	GetCipher(self, ctx);
    }
    if (EVP_CipherInit_ex(ctx, NULL, NULL, p_key, p_iv, mode) != 1) {
	ossl_raise(eCipherError, NULL);
    }

    rb_ivar_set(self, id_key_set, p_key ? Qtrue : Qfalse);

    return self;
}

/*
 *  call-seq:
 *     cipher.encrypt -> self
 *
 *  Initializes the Cipher for encryption.
 *
 *  Make sure to call Cipher#encrypt or Cipher#decrypt before using any of the
 *  following methods:
 *  * [#key=, #iv=, #random_key, #random_iv, #pkcs5_keyivgen]
 *
 *  Internally calls EVP_CipherInit_ex(ctx, NULL, NULL, NULL, NULL, 1).
 */
static VALUE
ossl_cipher_encrypt(int argc, VALUE *argv, VALUE self)
{
    return ossl_cipher_init(argc, argv, self, 1);
}

/*
 *  call-seq:
 *     cipher.decrypt -> self
 *
 *  Initializes the Cipher for decryption.
 *
 *  Make sure to call Cipher#encrypt or Cipher#decrypt before using any of the
 *  following methods:
 *  * [#key=, #iv=, #random_key, #random_iv, #pkcs5_keyivgen]
 *
 *  Internally calls EVP_CipherInit_ex(ctx, NULL, NULL, NULL, NULL, 0).
 */
static VALUE
ossl_cipher_decrypt(int argc, VALUE *argv, VALUE self)
{
    return ossl_cipher_init(argc, argv, self, 0);
}

/*
 *  call-seq:
 *     cipher.pkcs5_keyivgen(pass, salt = nil, iterations = 2048, digest = "MD5") -> nil
 *
 *  Generates and sets the key/IV based on a password.
 *
 *  *WARNING*: This method is only PKCS5 v1.5 compliant when using RC2, RC4-40,
 *  or DES with MD5 or SHA1. Using anything else (like AES) will generate the
 *  key/iv using an OpenSSL specific method. This method is deprecated and
 *  should no longer be used. Use a PKCS5 v2 key generation method from
 *  OpenSSL::PKCS5 instead.
 *
 *  === Parameters
 *  * _salt_ must be an 8 byte string if provided.
 *  * _iterations_ is an integer with a default of 2048.
 *  * _digest_ is a Digest object that defaults to 'MD5'
 *
 *  A minimum of 1000 iterations is recommended.
 *
 */
static VALUE
ossl_cipher_pkcs5_keyivgen(int argc, VALUE *argv, VALUE self)
{
    EVP_CIPHER_CTX *ctx;
    const EVP_MD *digest;
    VALUE vpass, vsalt, viter, vdigest;
    unsigned char key[EVP_MAX_KEY_LENGTH], iv[EVP_MAX_IV_LENGTH], *salt = NULL;
    int iter;

    rb_scan_args(argc, argv, "13", &vpass, &vsalt, &viter, &vdigest);
    StringValue(vpass);
    if(!NIL_P(vsalt)){
	StringValue(vsalt);
	if(RSTRING_LEN(vsalt) != PKCS5_SALT_LEN)
	    ossl_raise(eCipherError, "salt must be an 8-octet string");
	salt = (unsigned char *)RSTRING_PTR(vsalt);
    }
    iter = NIL_P(viter) ? 2048 : NUM2INT(viter);
    if (iter <= 0)
	rb_raise(rb_eArgError, "iterations must be a positive integer");
    digest = NIL_P(vdigest) ? EVP_md5() : ossl_evp_get_digestbyname(vdigest);
    GetCipher(self, ctx);
    EVP_BytesToKey(EVP_CIPHER_CTX_cipher(ctx), digest, salt,
		   (unsigned char *)RSTRING_PTR(vpass), RSTRING_LENINT(vpass), iter, key, iv);
    if (EVP_CipherInit_ex(ctx, NULL, NULL, key, iv, -1) != 1)
	ossl_raise(eCipherError, NULL);
    OPENSSL_cleanse(key, sizeof key);
    OPENSSL_cleanse(iv, sizeof iv);

    rb_ivar_set(self, id_key_set, Qtrue);

    return Qnil;
}

static int
ossl_cipher_update_long(EVP_CIPHER_CTX *ctx, unsigned char *out, long *out_len_ptr,
			const unsigned char *in, long in_len)
{
    int out_part_len;
    int limit = INT_MAX / 2 + 1;
    long out_len = 0;

    do {
	int in_part_len = in_len > limit ? limit : (int)in_len;

	if (!EVP_CipherUpdate(ctx, out ? (out + out_len) : 0,
			      &out_part_len, in, in_part_len))
	    return 0;

	out_len += out_part_len;
	in += in_part_len;
    } while ((in_len -= limit) > 0);

    if (out_len_ptr)
	*out_len_ptr = out_len;

    return 1;
}

/*
 *  call-seq:
 *     cipher.update(data [, buffer]) -> string or buffer
 *
 *  Encrypts data in a streaming fashion. Hand consecutive blocks of data
 *  to the #update method in order to encrypt it. Returns the encrypted
 *  data chunk. When done, the output of Cipher#final should be additionally
 *  added to the result.
 *
 *  If _buffer_ is given, the encryption/decryption result will be written to
 *  it. _buffer_ will be resized automatically.
 */
static VALUE
ossl_cipher_update(int argc, VALUE *argv, VALUE self)
{
    EVP_CIPHER_CTX *ctx;
    unsigned char *in;
    long in_len, out_len;
    VALUE data, str;

    rb_scan_args(argc, argv, "11", &data, &str);

    if (!RTEST(rb_attr_get(self, id_key_set)))
	ossl_raise(eCipherError, "key not set");

    StringValue(data);
    in = (unsigned char *)RSTRING_PTR(data);
    in_len = RSTRING_LEN(data);
    GetCipher(self, ctx);
    out_len = in_len+EVP_CIPHER_CTX_block_size(ctx);
    if (out_len <= 0) {
	ossl_raise(rb_eRangeError,
		   "data too big to make output buffer: %ld bytes", in_len);
    }

    if (NIL_P(str)) {
        str = rb_str_new(0, out_len);
    } else {
        StringValue(str);
        rb_str_resize(str, out_len);
    }

    if (!ossl_cipher_update_long(ctx, (unsigned char *)RSTRING_PTR(str), &out_len, in, in_len))
	ossl_raise(eCipherError, NULL);
    assert(out_len < RSTRING_LEN(str));
    rb_str_set_len(str, out_len);

    return str;
}

/*
 *  call-seq:
 *     cipher.final -> string
 *
 *  Returns the remaining data held in the cipher object. Further calls to
 *  Cipher#update or Cipher#final will return garbage. This call should always
 *  be made as the last call of an encryption or decryption operation, after
 *  having fed the entire plaintext or ciphertext to the Cipher instance.
 *
 *  If an authenticated cipher was used, a CipherError is raised if the tag
 *  could not be authenticated successfully. Only call this method after
 *  setting the authentication tag and passing the entire contents of the
 *  ciphertext into the cipher.
 */
static VALUE
ossl_cipher_final(VALUE self)
{
    EVP_CIPHER_CTX *ctx;
    int out_len;
    VALUE str;

    GetCipher(self, ctx);
    str = rb_str_new(0, EVP_CIPHER_CTX_block_size(ctx));
    if (!EVP_CipherFinal_ex(ctx, (unsigned char *)RSTRING_PTR(str), &out_len))
	ossl_raise(eCipherError, NULL);
    assert(out_len <= RSTRING_LEN(str));
    rb_str_set_len(str, out_len);

    return str;
}

/*
 *  call-seq:
 *     cipher.name -> string
 *
 *  Returns the name of the cipher which may differ slightly from the original
 *  name provided.
 */
static VALUE
ossl_cipher_name(VALUE self)
{
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);

    return rb_str_new2(EVP_CIPHER_name(EVP_CIPHER_CTX_cipher(ctx)));
}

/*
 *  call-seq:
 *     cipher.key = string -> string
 *
 *  Sets the cipher key. To generate a key, you should either use a secure
 *  random byte string or, if the key is to be derived from a password, you
 *  should rely on PBKDF2 functionality provided by OpenSSL::PKCS5. To
 *  generate a secure random-based key, Cipher#random_key may be used.
 *
 *  Only call this method after calling Cipher#encrypt or Cipher#decrypt.
 */
static VALUE
ossl_cipher_set_key(VALUE self, VALUE key)
{
    EVP_CIPHER_CTX *ctx;
    int key_len;

    StringValue(key);
    GetCipher(self, ctx);

    key_len = EVP_CIPHER_CTX_key_length(ctx);
    if (RSTRING_LEN(key) != key_len)
	ossl_raise(rb_eArgError, "key must be %d bytes", key_len);

    if (EVP_CipherInit_ex(ctx, NULL, NULL, (unsigned char *)RSTRING_PTR(key), NULL, -1) != 1)
	ossl_raise(eCipherError, NULL);

    rb_ivar_set(self, id_key_set, Qtrue);

    return key;
}

/*
 *  call-seq:
 *     cipher.iv = string -> string
 *
 *  Sets the cipher IV. Please note that since you should never be using ECB
 *  mode, an IV is always explicitly required and should be set prior to
 *  encryption. The IV itself can be safely transmitted in public, but it
 *  should be unpredictable to prevent certain kinds of attacks. You may use
 *  Cipher#random_iv to create a secure random IV.
 *
 *  Only call this method after calling Cipher#encrypt or Cipher#decrypt.
 */
static VALUE
ossl_cipher_set_iv(VALUE self, VALUE iv)
{
    EVP_CIPHER_CTX *ctx;
    int iv_len = 0;

    StringValue(iv);
    GetCipher(self, ctx);

    if (EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER)
	iv_len = (int)(VALUE)EVP_CIPHER_CTX_get_app_data(ctx);
    if (!iv_len)
	iv_len = EVP_CIPHER_CTX_iv_length(ctx);
    if (RSTRING_LEN(iv) != iv_len)
	ossl_raise(rb_eArgError, "iv must be %d bytes", iv_len);

    if (EVP_CipherInit_ex(ctx, NULL, NULL, NULL, (unsigned char *)RSTRING_PTR(iv), -1) != 1)
	ossl_raise(eCipherError, NULL);

    return iv;
}

/*
 *  call-seq:
 *     cipher.authenticated? -> true | false
 *
 *  Indicated whether this Cipher instance uses an Authenticated Encryption
 *  mode.
 */
static VALUE
ossl_cipher_is_authenticated(VALUE self)
{
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);

    return (EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *     cipher.auth_data = string -> string
 *
 *  Sets the cipher's additional authenticated data. This field must be
 *  set when using AEAD cipher modes such as GCM or CCM. If no associated
 *  data shall be used, this method must *still* be called with a value of "".
 *  The contents of this field should be non-sensitive data which will be
 *  added to the ciphertext to generate the authentication tag which validates
 *  the contents of the ciphertext.
 *
 *  The AAD must be set prior to encryption or decryption. In encryption mode,
 *  it must be set after calling Cipher#encrypt and setting Cipher#key= and
 *  Cipher#iv=. When decrypting, the authenticated data must be set after key,
 *  iv and especially *after* the authentication tag has been set. I.e. set it
 *  only after calling Cipher#decrypt, Cipher#key=, Cipher#iv= and
 *  Cipher#auth_tag= first.
 */
static VALUE
ossl_cipher_set_auth_data(VALUE self, VALUE data)
{
    EVP_CIPHER_CTX *ctx;
    unsigned char *in;
    long in_len, out_len;

    StringValue(data);

    in = (unsigned char *) RSTRING_PTR(data);
    in_len = RSTRING_LEN(data);

    GetCipher(self, ctx);
    if (!(EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER))
	ossl_raise(eCipherError, "AEAD not supported by this cipher");

    if (!ossl_cipher_update_long(ctx, NULL, &out_len, in, in_len))
        ossl_raise(eCipherError, "couldn't set additional authenticated data");

    return data;
}

/*
 *  call-seq:
 *     cipher.auth_tag(tag_len = 16) -> String
 *
 *  Gets the authentication tag generated by Authenticated Encryption Cipher
 *  modes (GCM for example). This tag may be stored along with the ciphertext,
 *  then set on the decryption cipher to authenticate the contents of the
 *  ciphertext against changes. If the optional integer parameter _tag_len_ is
 *  given, the returned tag will be _tag_len_ bytes long. If the parameter is
 *  omitted, the default length of 16 bytes or the length previously set by
 *  #auth_tag_len= will be used. For maximum security, the longest possible
 *  should be chosen.
 *
 *  The tag may only be retrieved after calling Cipher#final.
 */
static VALUE
ossl_cipher_get_auth_tag(int argc, VALUE *argv, VALUE self)
{
    VALUE vtag_len, ret;
    EVP_CIPHER_CTX *ctx;
    int tag_len = 16;

    rb_scan_args(argc, argv, "01", &vtag_len);
    if (NIL_P(vtag_len))
	vtag_len = rb_attr_get(self, id_auth_tag_len);
    if (!NIL_P(vtag_len))
	tag_len = NUM2INT(vtag_len);

    GetCipher(self, ctx);

    if (!(EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER))
	ossl_raise(eCipherError, "authentication tag not supported by this cipher");

    ret = rb_str_new(NULL, tag_len);
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_GET_TAG, tag_len, RSTRING_PTR(ret)))
	ossl_raise(eCipherError, "retrieving the authentication tag failed");

    return ret;
}

/*
 *  call-seq:
 *     cipher.auth_tag = string -> string
 *
 *  Sets the authentication tag to verify the integrity of the ciphertext.
 *  This can be called only when the cipher supports AE. The tag must be set
 *  after calling Cipher#decrypt, Cipher#key= and Cipher#iv=, but before
 *  calling Cipher#final. After all decryption is performed, the tag is
 *  verified automatically in the call to Cipher#final.
 *
 *  For OCB mode, the tag length must be supplied with #auth_tag_len=
 *  beforehand.
 */
static VALUE
ossl_cipher_set_auth_tag(VALUE self, VALUE vtag)
{
    EVP_CIPHER_CTX *ctx;
    unsigned char *tag;
    int tag_len;

    StringValue(vtag);
    tag = (unsigned char *) RSTRING_PTR(vtag);
    tag_len = RSTRING_LENINT(vtag);

    GetCipher(self, ctx);
    if (!(EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER))
	ossl_raise(eCipherError, "authentication tag not supported by this cipher");

    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_TAG, tag_len, tag))
	ossl_raise(eCipherError, "unable to set AEAD tag");

    return vtag;
}

/*
 *  call-seq:
 *     cipher.auth_tag_len = Integer -> Integer
 *
 *  Sets the length of the authentication tag to be generated or to be given for
 *  AEAD ciphers that requires it as in input parameter. Note that not all AEAD
 *  ciphers support this method.
 *
 *  In OCB mode, the length must be supplied both when encrypting and when
 *  decrypting, and must be before specifying an IV.
 */
static VALUE
ossl_cipher_set_auth_tag_len(VALUE self, VALUE vlen)
{
    int tag_len = NUM2INT(vlen);
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);
    if (!(EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER))
	ossl_raise(eCipherError, "AEAD not supported by this cipher");

    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_TAG, tag_len, NULL))
	ossl_raise(eCipherError, "unable to set authentication tag length");

    /* for #auth_tag */
    rb_ivar_set(self, id_auth_tag_len, INT2NUM(tag_len));

    return vlen;
}

/*
 * call-seq:
 *   cipher.iv_len = integer -> integer
 *
 * Sets the IV/nonce length of the Cipher. Normally block ciphers don't allow
 * changing the IV length, but some make use of IV for 'nonce'. You may need
 * this for interoperability with other applications.
 */
static VALUE
ossl_cipher_set_iv_length(VALUE self, VALUE iv_length)
{
    int len = NUM2INT(iv_length);
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);
    if (!(EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER))
	ossl_raise(eCipherError, "cipher does not support AEAD");

    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_IVLEN, len, NULL))
	ossl_raise(eCipherError, "unable to set IV length");

    /*
     * EVP_CIPHER_CTX_iv_length() returns the default length. So we need to save
     * the length somewhere. Luckily currently we aren't using app_data.
     */
    EVP_CIPHER_CTX_set_app_data(ctx, (void *)(VALUE)len);

    return iv_length;
}

/*
 *  call-seq:
 *     cipher.key_len = integer -> integer
 *
 *  Sets the key length of the cipher.  If the cipher is a fixed length cipher
 *  then attempting to set the key length to any value other than the fixed
 *  value is an error.
 *
 *  Under normal circumstances you do not need to call this method (and probably shouldn't).
 *
 *  See EVP_CIPHER_CTX_set_key_length for further information.
 */
static VALUE
ossl_cipher_set_key_length(VALUE self, VALUE key_length)
{
    int len = NUM2INT(key_length);
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);
    if (EVP_CIPHER_CTX_set_key_length(ctx, len) != 1)
        ossl_raise(eCipherError, NULL);

    return key_length;
}

/*
 *  call-seq:
 *     cipher.padding = integer -> integer
 *
 *  Enables or disables padding. By default encryption operations are padded using standard block padding and the
 *  padding is checked and removed when decrypting. If the pad parameter is zero then no padding is performed, the
 *  total amount of data encrypted or decrypted must then be a multiple of the block size or an error will occur.
 *
 *  See EVP_CIPHER_CTX_set_padding for further information.
 */
static VALUE
ossl_cipher_set_padding(VALUE self, VALUE padding)
{
    EVP_CIPHER_CTX *ctx;
    int pad = NUM2INT(padding);

    GetCipher(self, ctx);
    if (EVP_CIPHER_CTX_set_padding(ctx, pad) != 1)
	ossl_raise(eCipherError, NULL);
    return padding;
}

/*
 *  call-seq:
 *     cipher.key_len -> integer
 *
 *  Returns the key length in bytes of the Cipher.
 */
static VALUE
ossl_cipher_key_length(VALUE self)
{
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);

    return INT2NUM(EVP_CIPHER_CTX_key_length(ctx));
}

/*
 *  call-seq:
 *     cipher.iv_len -> integer
 *
 *  Returns the expected length in bytes for an IV for this Cipher.
 */
static VALUE
ossl_cipher_iv_length(VALUE self)
{
    EVP_CIPHER_CTX *ctx;
    int len = 0;

    GetCipher(self, ctx);
    if (EVP_CIPHER_flags(EVP_CIPHER_CTX_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER)
	len = (int)(VALUE)EVP_CIPHER_CTX_get_app_data(ctx);
    if (!len)
	len = EVP_CIPHER_CTX_iv_length(ctx);

    return INT2NUM(len);
}

/*
 *  call-seq:
 *     cipher.block_size -> integer
 *
 *  Returns the size in bytes of the blocks on which this Cipher operates on.
 */
static VALUE
ossl_cipher_block_size(VALUE self)
{
    EVP_CIPHER_CTX *ctx;

    GetCipher(self, ctx);

    return INT2NUM(EVP_CIPHER_CTX_block_size(ctx));
}

/*
 *  call-seq:
 *     cipher.ccm_data_len = integer -> integer
 *
 *  Sets the length of the plaintext / ciphertext message that will be
 *  processed in CCM mode. Make sure to call this method after #key= and
 *  #iv= have been set, and before #auth_data=.
 *
 *  Only call this method after calling Cipher#encrypt or Cipher#decrypt.
 */
static VALUE
ossl_cipher_set_ccm_data_len(VALUE self, VALUE data_len)
{
    int in_len, out_len;
    EVP_CIPHER_CTX *ctx;

    in_len = NUM2INT(data_len);

    GetCipher(self, ctx);
    if (EVP_CipherUpdate(ctx, NULL, &out_len, NULL, in_len) != 1)
        ossl_raise(eCipherError, NULL);

    return data_len;
}

/*
 * INIT
 */
void
Init_ossl_cipher(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
#endif

    /* Document-class: OpenSSL::Cipher
     *
     * Provides symmetric algorithms for encryption and decryption. The
     * algorithms that are available depend on the particular version
     * of OpenSSL that is installed.
     *
     * === Listing all supported algorithms
     *
     * A list of supported algorithms can be obtained by
     *
     *   puts OpenSSL::Cipher.ciphers
     *
     * === Instantiating a Cipher
     *
     * There are several ways to create a Cipher instance. Generally, a
     * Cipher algorithm is categorized by its name, the key length in bits
     * and the cipher mode to be used. The most generic way to create a
     * Cipher is the following
     *
     *   cipher = OpenSSL::Cipher.new('<name>-<key length>-<mode>')
     *
     * That is, a string consisting of the hyphenated concatenation of the
     * individual components name, key length and mode. Either all uppercase
     * or all lowercase strings may be used, for example:
     *
     *  cipher = OpenSSL::Cipher.new('aes-128-cbc')
     *
     * === Choosing either encryption or decryption mode
     *
     * Encryption and decryption are often very similar operations for
     * symmetric algorithms, this is reflected by not having to choose
     * different classes for either operation, both can be done using the
     * same class. Still, after obtaining a Cipher instance, we need to
     * tell the instance what it is that we intend to do with it, so we
     * need to call either
     *
     *   cipher.encrypt
     *
     * or
     *
     *   cipher.decrypt
     *
     * on the Cipher instance. This should be the first call after creating
     * the instance, otherwise configuration that has already been set could
     * get lost in the process.
     *
     * === Choosing a key
     *
     * Symmetric encryption requires a key that is the same for the encrypting
     * and for the decrypting party and after initial key establishment should
     * be kept as private information. There are a lot of ways to create
     * insecure keys, the most notable is to simply take a password as the key
     * without processing the password further. A simple and secure way to
     * create a key for a particular Cipher is
     *
     *  cipher = OpenSSL::Cipher.new('aes-256-cfb')
     *  cipher.encrypt
     *  key = cipher.random_key # also sets the generated key on the Cipher
     *
     * If you absolutely need to use passwords as encryption keys, you
     * should use Password-Based Key Derivation Function 2 (PBKDF2) by
     * generating the key with the help of the functionality provided by
     * OpenSSL::PKCS5.pbkdf2_hmac_sha1 or OpenSSL::PKCS5.pbkdf2_hmac.
     *
     * Although there is Cipher#pkcs5_keyivgen, its use is deprecated and
     * it should only be used in legacy applications because it does not use
     * the newer PKCS#5 v2 algorithms.
     *
     * === Choosing an IV
     *
     * The cipher modes CBC, CFB, OFB and CTR all need an "initialization
     * vector", or short, IV. ECB mode is the only mode that does not require
     * an IV, but there is almost no legitimate use case for this mode
     * because of the fact that it does not sufficiently hide plaintext
     * patterns. Therefore
     *
     * <b>You should never use ECB mode unless you are absolutely sure that
     * you absolutely need it</b>
     *
     * Because of this, you will end up with a mode that explicitly requires
     * an IV in any case. Although the IV can be seen as public information,
     * i.e. it may be transmitted in public once generated, it should still
     * stay unpredictable to prevent certain kinds of attacks. Therefore,
     * ideally
     *
     * <b>Always create a secure random IV for every encryption of your
     * Cipher</b>
     *
     * A new, random IV should be created for every encryption of data. Think
     * of the IV as a nonce (number used once) - it's public but random and
     * unpredictable. A secure random IV can be created as follows
     *
     *   cipher = ...
     *   cipher.encrypt
     *   key = cipher.random_key
     *   iv = cipher.random_iv # also sets the generated IV on the Cipher
     *
     * Although the key is generally a random value, too, it is a bad choice
     * as an IV. There are elaborate ways how an attacker can take advantage
     * of such an IV. As a general rule of thumb, exposing the key directly
     * or indirectly should be avoided at all cost and exceptions only be
     * made with good reason.
     *
     * === Calling Cipher#final
     *
     * ECB (which should not be used) and CBC are both block-based modes.
     * This means that unlike for the other streaming-based modes, they
     * operate on fixed-size blocks of data, and therefore they require a
     * "finalization" step to produce or correctly decrypt the last block of
     * data by appropriately handling some form of padding. Therefore it is
     * essential to add the output of OpenSSL::Cipher#final to your
     * encryption/decryption buffer or you will end up with decryption errors
     * or truncated data.
     *
     * Although this is not really necessary for streaming-mode ciphers, it is
     * still recommended to apply the same pattern of adding the output of
     * Cipher#final there as well - it also enables you to switch between
     * modes more easily in the future.
     *
     * === Encrypting and decrypting some data
     *
     *   data = "Very, very confidential data"
     *
     *   cipher = OpenSSL::Cipher.new('aes-128-cbc')
     *   cipher.encrypt
     *   key = cipher.random_key
     *   iv = cipher.random_iv
     *
     *   encrypted = cipher.update(data) + cipher.final
     *   ...
     *   decipher = OpenSSL::Cipher.new('aes-128-cbc')
     *   decipher.decrypt
     *   decipher.key = key
     *   decipher.iv = iv
     *
     *   plain = decipher.update(encrypted) + decipher.final
     *
     *   puts data == plain #=> true
     *
     * === Authenticated Encryption and Associated Data (AEAD)
     *
     * If the OpenSSL version used supports it, an Authenticated Encryption
     * mode (such as GCM or CCM) should always be preferred over any
     * unauthenticated mode. Currently, OpenSSL supports AE only in combination
     * with Associated Data (AEAD) where additional associated data is included
     * in the encryption process to compute a tag at the end of the encryption.
     * This tag will also be used in the decryption process and by verifying
     * its validity, the authenticity of a given ciphertext is established.
     *
     * This is superior to unauthenticated modes in that it allows to detect
     * if somebody effectively changed the ciphertext after it had been
     * encrypted. This prevents malicious modifications of the ciphertext that
     * could otherwise be exploited to modify ciphertexts in ways beneficial to
     * potential attackers.
     *
     * An associated data is used where there is additional information, such as
     * headers or some metadata, that must be also authenticated but not
     * necessarily need to be encrypted. If no associated data is needed for
     * encryption and later decryption, the OpenSSL library still requires a
     * value to be set - "" may be used in case none is available.
     *
     * An example using the GCM (Galois/Counter Mode). You have 16 bytes _key_,
     * 12 bytes (96 bits) _nonce_ and the associated data _auth_data_. Be sure
     * not to reuse the _key_ and _nonce_ pair. Reusing an nonce ruins the
     * security guarantees of GCM mode.
     *
     *   cipher = OpenSSL::Cipher.new('aes-128-gcm').encrypt
     *   cipher.key = key
     *   cipher.iv = nonce
     *   cipher.auth_data = auth_data
     *
     *   encrypted = cipher.update(data) + cipher.final
     *   tag = cipher.auth_tag # produces 16 bytes tag by default
     *
     * Now you are the receiver. You know the _key_ and have received _nonce_,
     * _auth_data_, _encrypted_ and _tag_ through an untrusted network. Note
     * that GCM accepts an arbitrary length tag between 1 and 16 bytes. You may
     * additionally need to check that the received tag has the correct length,
     * or you allow attackers to forge a valid single byte tag for the tampered
     * ciphertext with a probability of 1/256.
     *
     *   raise "tag is truncated!" unless tag.bytesize == 16
     *   decipher = OpenSSL::Cipher.new('aes-128-gcm').decrypt
     *   decipher.key = key
     *   decipher.iv = nonce
     *   decipher.auth_tag = tag
     *   decipher.auth_data = auth_data
     *
     *   decrypted = decipher.update(encrypted) + decipher.final
     *
     *   puts data == decrypted #=> true
     */
    cCipher = rb_define_class_under(mOSSL, "Cipher", rb_cObject);
    eCipherError = rb_define_class_under(cCipher, "CipherError", eOSSLError);

    rb_define_alloc_func(cCipher, ossl_cipher_alloc);
    rb_define_method(cCipher, "initialize_copy", ossl_cipher_copy, 1);
    rb_define_module_function(cCipher, "ciphers", ossl_s_ciphers, 0);
    rb_define_method(cCipher, "initialize", ossl_cipher_initialize, 1);
    rb_define_method(cCipher, "reset", ossl_cipher_reset, 0);
    rb_define_method(cCipher, "encrypt", ossl_cipher_encrypt, -1);
    rb_define_method(cCipher, "decrypt", ossl_cipher_decrypt, -1);
    rb_define_method(cCipher, "pkcs5_keyivgen", ossl_cipher_pkcs5_keyivgen, -1);
    rb_define_method(cCipher, "update", ossl_cipher_update, -1);
    rb_define_method(cCipher, "final", ossl_cipher_final, 0);
    rb_define_method(cCipher, "name", ossl_cipher_name, 0);
    rb_define_method(cCipher, "key=", ossl_cipher_set_key, 1);
    rb_define_method(cCipher, "auth_data=", ossl_cipher_set_auth_data, 1);
    rb_define_method(cCipher, "auth_tag=", ossl_cipher_set_auth_tag, 1);
    rb_define_method(cCipher, "auth_tag", ossl_cipher_get_auth_tag, -1);
    rb_define_method(cCipher, "auth_tag_len=", ossl_cipher_set_auth_tag_len, 1);
    rb_define_method(cCipher, "authenticated?", ossl_cipher_is_authenticated, 0);
    rb_define_method(cCipher, "key_len=", ossl_cipher_set_key_length, 1);
    rb_define_method(cCipher, "key_len", ossl_cipher_key_length, 0);
    rb_define_method(cCipher, "iv=", ossl_cipher_set_iv, 1);
    rb_define_method(cCipher, "iv_len=", ossl_cipher_set_iv_length, 1);
    rb_define_method(cCipher, "iv_len", ossl_cipher_iv_length, 0);
    rb_define_method(cCipher, "block_size", ossl_cipher_block_size, 0);
    rb_define_method(cCipher, "padding=", ossl_cipher_set_padding, 1);
    rb_define_method(cCipher, "ccm_data_len=", ossl_cipher_set_ccm_data_len, 1);

    id_auth_tag_len = rb_intern_const("auth_tag_len");
    id_key_set = rb_intern_const("key_set");
}
