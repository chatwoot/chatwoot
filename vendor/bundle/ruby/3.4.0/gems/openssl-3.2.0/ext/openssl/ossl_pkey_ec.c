/*
 * Copyright (C) 2006-2007 Technorama Ltd. <oss-ruby@technorama.net>
 */

#include "ossl.h"

#if !defined(OPENSSL_NO_EC)

#define EXPORT_PEM 0
#define EXPORT_DER 1

static const rb_data_type_t ossl_ec_group_type;
static const rb_data_type_t ossl_ec_point_type;

#define GetPKeyEC(obj, pkey) do { \
    GetPKey((obj), (pkey)); \
    if (EVP_PKEY_base_id(pkey) != EVP_PKEY_EC) { \
	ossl_raise(rb_eRuntimeError, "THIS IS NOT A EC PKEY!"); \
    } \
} while (0)
#define GetEC(obj, key) do { \
    EVP_PKEY *_pkey; \
    GetPKeyEC(obj, _pkey); \
    (key) = EVP_PKEY_get0_EC_KEY(_pkey); \
} while (0)

#define GetECGroup(obj, group) do { \
    TypedData_Get_Struct(obj, EC_GROUP, &ossl_ec_group_type, group); \
    if ((group) == NULL) \
	ossl_raise(eEC_GROUP, "EC_GROUP is not initialized"); \
} while (0)

#define GetECPoint(obj, point) do { \
    TypedData_Get_Struct(obj, EC_POINT, &ossl_ec_point_type, point); \
    if ((point) == NULL) \
	ossl_raise(eEC_POINT, "EC_POINT is not initialized"); \
} while (0)
#define GetECPointGroup(obj, group) do { \
    VALUE _group = rb_attr_get(obj, id_i_group); \
    GetECGroup(_group, group); \
} while (0)

VALUE cEC;
VALUE eECError;
VALUE cEC_GROUP;
VALUE eEC_GROUP;
VALUE cEC_POINT;
VALUE eEC_POINT;

static ID s_GFp, s_GF2m;

static ID ID_uncompressed;
static ID ID_compressed;
static ID ID_hybrid;

static ID id_i_group;

static VALUE ec_group_new(const EC_GROUP *group);
static VALUE ec_point_new(const EC_POINT *point, const EC_GROUP *group);

/*
 * Creates a new EC_KEY on the EC group obj. arg can be an EC::Group or a String
 * representing an OID.
 */
static EC_KEY *
ec_key_new_from_group(VALUE arg)
{
    EC_KEY *ec;

    if (rb_obj_is_kind_of(arg, cEC_GROUP)) {
	EC_GROUP *group;

	GetECGroup(arg, group);
	if (!(ec = EC_KEY_new()))
	    ossl_raise(eECError, NULL);

	if (!EC_KEY_set_group(ec, group)) {
	    EC_KEY_free(ec);
	    ossl_raise(eECError, NULL);
	}
    } else {
	int nid = OBJ_sn2nid(StringValueCStr(arg));

	if (nid == NID_undef)
	    ossl_raise(eECError, "invalid curve name");

	if (!(ec = EC_KEY_new_by_curve_name(nid)))
	    ossl_raise(eECError, NULL);

	EC_KEY_set_asn1_flag(ec, OPENSSL_EC_NAMED_CURVE);
	EC_KEY_set_conv_form(ec, POINT_CONVERSION_UNCOMPRESSED);
    }

    return ec;
}

/*
 *  call-seq:
 *     EC.generate(ec_group) -> ec
 *     EC.generate(string) -> ec
 *
 * Creates a new EC instance with a new random private and public key.
 */
static VALUE
ossl_ec_key_s_generate(VALUE klass, VALUE arg)
{
    EVP_PKEY *pkey;
    EC_KEY *ec;
    VALUE obj;

    obj = rb_obj_alloc(klass);

    ec = ec_key_new_from_group(arg);
    pkey = EVP_PKEY_new();
    if (!pkey || EVP_PKEY_assign_EC_KEY(pkey, ec) != 1) {
        EVP_PKEY_free(pkey);
        EC_KEY_free(ec);
        ossl_raise(eECError, "EVP_PKEY_assign_EC_KEY");
    }
    RTYPEDDATA_DATA(obj) = pkey;

    if (!EC_KEY_generate_key(ec))
	ossl_raise(eECError, "EC_KEY_generate_key");

    return obj;
}

/*
 * call-seq:
 *   OpenSSL::PKey::EC.new
 *   OpenSSL::PKey::EC.new(ec_key)
 *   OpenSSL::PKey::EC.new(ec_group)
 *   OpenSSL::PKey::EC.new("secp112r1")
 *   OpenSSL::PKey::EC.new(pem_string [, pwd])
 *   OpenSSL::PKey::EC.new(der_string)
 *
 * Creates a new EC object from given arguments.
 */
static VALUE ossl_ec_key_initialize(int argc, VALUE *argv, VALUE self)
{
    EVP_PKEY *pkey;
    EC_KEY *ec;
    BIO *in;
    VALUE arg, pass;
    int type;

    TypedData_Get_Struct(self, EVP_PKEY, &ossl_evp_pkey_type, pkey);
    if (pkey)
        rb_raise(rb_eTypeError, "pkey already initialized");

    rb_scan_args(argc, argv, "02", &arg, &pass);
    if (NIL_P(arg)) {
        if (!(ec = EC_KEY_new()))
            ossl_raise(eECError, "EC_KEY_new");
        goto legacy;
    }
    else if (rb_obj_is_kind_of(arg, cEC_GROUP)) {
        ec = ec_key_new_from_group(arg);
        goto legacy;
    }

    pass = ossl_pem_passwd_value(pass);
    arg = ossl_to_der_if_possible(arg);
    in = ossl_obj2bio(&arg);

    pkey = ossl_pkey_read_generic(in, pass);
    BIO_free(in);
    if (!pkey) {
        ossl_clear_error();
        ec = ec_key_new_from_group(arg);
        goto legacy;
    }

    type = EVP_PKEY_base_id(pkey);
    if (type != EVP_PKEY_EC) {
        EVP_PKEY_free(pkey);
        rb_raise(eDSAError, "incorrect pkey type: %s", OBJ_nid2sn(type));
    }
    RTYPEDDATA_DATA(self) = pkey;
    return self;

  legacy:
    pkey = EVP_PKEY_new();
    if (!pkey || EVP_PKEY_assign_EC_KEY(pkey, ec) != 1) {
        EVP_PKEY_free(pkey);
        EC_KEY_free(ec);
        ossl_raise(eECError, "EVP_PKEY_assign_EC_KEY");
    }
    RTYPEDDATA_DATA(self) = pkey;
    return self;
}

#ifndef HAVE_EVP_PKEY_DUP
static VALUE
ossl_ec_key_initialize_copy(VALUE self, VALUE other)
{
    EVP_PKEY *pkey;
    EC_KEY *ec, *ec_new;

    TypedData_Get_Struct(self, EVP_PKEY, &ossl_evp_pkey_type, pkey);
    if (pkey)
        rb_raise(rb_eTypeError, "pkey already initialized");
    GetEC(other, ec);

    ec_new = EC_KEY_dup(ec);
    if (!ec_new)
	ossl_raise(eECError, "EC_KEY_dup");

    pkey = EVP_PKEY_new();
    if (!pkey || EVP_PKEY_assign_EC_KEY(pkey, ec_new) != 1) {
        EC_KEY_free(ec_new);
        ossl_raise(eECError, "EVP_PKEY_assign_EC_KEY");
    }
    RTYPEDDATA_DATA(self) = pkey;

    return self;
}
#endif

/*
 * call-seq:
 *   key.group   => group
 *
 * Returns the EC::Group that the key is associated with. Modifying the returned
 * group does not affect _key_.
 */
static VALUE
ossl_ec_key_get_group(VALUE self)
{
    OSSL_3_const EC_KEY *ec;
    const EC_GROUP *group;

    GetEC(self, ec);
    group = EC_KEY_get0_group(ec);
    if (!group)
	return Qnil;

    return ec_group_new(group);
}

/*
 * call-seq:
 *   key.group = group
 *
 * Sets the EC::Group for the key. The group structure is internally copied so
 * modification to _group_ after assigning to a key has no effect on the key.
 */
static VALUE
ossl_ec_key_set_group(VALUE self, VALUE group_v)
{
#if OSSL_OPENSSL_PREREQ(3, 0, 0)
    rb_raise(ePKeyError, "pkeys are immutable on OpenSSL 3.0");
#else
    EC_KEY *ec;
    EC_GROUP *group;

    GetEC(self, ec);
    GetECGroup(group_v, group);

    if (EC_KEY_set_group(ec, group) != 1)
        ossl_raise(eECError, "EC_KEY_set_group");

    return group_v;
#endif
}

/*
 *  call-seq:
 *     key.private_key   => OpenSSL::BN
 *
 *  See the OpenSSL documentation for EC_KEY_get0_private_key()
 */
static VALUE ossl_ec_key_get_private_key(VALUE self)
{
    OSSL_3_const EC_KEY *ec;
    const BIGNUM *bn;

    GetEC(self, ec);
    if ((bn = EC_KEY_get0_private_key(ec)) == NULL)
        return Qnil;

    return ossl_bn_new(bn);
}

/*
 *  call-seq:
 *     key.private_key = openssl_bn
 *
 *  See the OpenSSL documentation for EC_KEY_set_private_key()
 */
static VALUE ossl_ec_key_set_private_key(VALUE self, VALUE private_key)
{
#if OSSL_OPENSSL_PREREQ(3, 0, 0)
    rb_raise(ePKeyError, "pkeys are immutable on OpenSSL 3.0");
#else
    EC_KEY *ec;
    BIGNUM *bn = NULL;

    GetEC(self, ec);
    if (!NIL_P(private_key))
        bn = GetBNPtr(private_key);

    switch (EC_KEY_set_private_key(ec, bn)) {
    case 1:
        break;
    case 0:
        if (bn == NULL)
            break;
	/* fallthrough */
    default:
        ossl_raise(eECError, "EC_KEY_set_private_key");
    }

    return private_key;
#endif
}

/*
 *  call-seq:
 *     key.public_key   => OpenSSL::PKey::EC::Point
 *
 *  See the OpenSSL documentation for EC_KEY_get0_public_key()
 */
static VALUE ossl_ec_key_get_public_key(VALUE self)
{
    OSSL_3_const EC_KEY *ec;
    const EC_POINT *point;

    GetEC(self, ec);
    if ((point = EC_KEY_get0_public_key(ec)) == NULL)
        return Qnil;

    return ec_point_new(point, EC_KEY_get0_group(ec));
}

/*
 *  call-seq:
 *     key.public_key = ec_point
 *
 *  See the OpenSSL documentation for EC_KEY_set_public_key()
 */
static VALUE ossl_ec_key_set_public_key(VALUE self, VALUE public_key)
{
#if OSSL_OPENSSL_PREREQ(3, 0, 0)
    rb_raise(ePKeyError, "pkeys are immutable on OpenSSL 3.0");
#else
    EC_KEY *ec;
    EC_POINT *point = NULL;

    GetEC(self, ec);
    if (!NIL_P(public_key))
        GetECPoint(public_key, point);

    switch (EC_KEY_set_public_key(ec, point)) {
    case 1:
        break;
    case 0:
        if (point == NULL)
            break;
	/* fallthrough */
    default:
        ossl_raise(eECError, "EC_KEY_set_public_key");
    }

    return public_key;
#endif
}

/*
 *  call-seq:
 *     key.public? => true or false
 *
 *  Returns whether this EC instance has a public key. The public key
 *  (EC::Point) can be retrieved with EC#public_key.
 */
static VALUE ossl_ec_key_is_public(VALUE self)
{
    OSSL_3_const EC_KEY *ec;

    GetEC(self, ec);

    return EC_KEY_get0_public_key(ec) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *     key.private? => true or false
 *
 *  Returns whether this EC instance has a private key. The private key (BN) can
 *  be retrieved with EC#private_key.
 */
static VALUE ossl_ec_key_is_private(VALUE self)
{
    OSSL_3_const EC_KEY *ec;

    GetEC(self, ec);

    return EC_KEY_get0_private_key(ec) ? Qtrue : Qfalse;
}

/*
 *  call-seq:
 *     key.export([cipher, password]) => String
 *     key.to_pem([cipher, password]) => String
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
 *   Serializes it into a SEC 1/RFC 5915 ECPrivateKey.
 *
 *   A PEM-encoded key will look like:
 *
 *     -----BEGIN EC PRIVATE KEY-----
 *     [...]
 *     -----END EC PRIVATE KEY-----
 *
 * [When the key contains private components, and _cipher_ and _password_ are given]
 *
 *   Serializes it into a SEC 1/RFC 5915 ECPrivateKey
 *   and encrypts it in OpenSSL's traditional PEM encryption format.
 *   _cipher_ must be a cipher name understood by OpenSSL::Cipher.new or an
 *   instance of OpenSSL::Cipher.
 *
 *   An encrypted PEM-encoded key will look like:
 *
 *     -----BEGIN EC PRIVATE KEY-----
 *     Proc-Type: 4,ENCRYPTED
 *     DEK-Info: AES-128-CBC,733F5302505B34701FC41F5C0746E4C0
 *
 *     [...]
 *     -----END EC PRIVATE KEY-----
 *
 *   Note that this format uses MD5 to derive the encryption key, and hence
 *   will not be available on FIPS-compliant systems.
 *
 * <b>This method is kept for compatibility.</b>
 * This should only be used when the SEC 1/RFC 5915 ECPrivateKey format is
 * required.
 *
 * Consider using #public_to_pem (X.509 SubjectPublicKeyInfo) or #private_to_pem
 * (PKCS #8 PrivateKeyInfo or EncryptedPrivateKeyInfo) instead.
 */
static VALUE
ossl_ec_key_export(int argc, VALUE *argv, VALUE self)
{
    OSSL_3_const EC_KEY *ec;

    GetEC(self, ec);
    if (EC_KEY_get0_public_key(ec) == NULL)
        ossl_raise(eECError, "can't export - no public key set");
    if (EC_KEY_get0_private_key(ec))
        return ossl_pkey_export_traditional(argc, argv, self, 0);
    else
        return ossl_pkey_export_spki(self, 0);
}

/*
 *  call-seq:
 *     key.to_der   => String
 *
 * Serializes a private or public key to a DER-encoding.
 *
 * See #to_pem for details.
 *
 * <b>This method is kept for compatibility.</b>
 * This should only be used when the SEC 1/RFC 5915 ECPrivateKey format is
 * required.
 *
 * Consider using #public_to_der or #private_to_der instead.
 */
static VALUE
ossl_ec_key_to_der(VALUE self)
{
    OSSL_3_const EC_KEY *ec;

    GetEC(self, ec);
    if (EC_KEY_get0_public_key(ec) == NULL)
        ossl_raise(eECError, "can't export - no public key set");
    if (EC_KEY_get0_private_key(ec))
        return ossl_pkey_export_traditional(0, NULL, self, 1);
    else
        return ossl_pkey_export_spki(self, 1);
}
/*
 *  call-seq:
 *     key.generate_key!   => self
 *
 * Generates a new random private and public key.
 *
 * See also the OpenSSL documentation for EC_KEY_generate_key()
 *
 * === Example
 *   ec = OpenSSL::PKey::EC.new("prime256v1")
 *   p ec.private_key # => nil
 *   ec.generate_key!
 *   p ec.private_key # => #<OpenSSL::BN XXXXXX>
 */
static VALUE ossl_ec_key_generate_key(VALUE self)
{
#if OSSL_OPENSSL_PREREQ(3, 0, 0)
    rb_raise(ePKeyError, "pkeys are immutable on OpenSSL 3.0");
#else
    EC_KEY *ec;

    GetEC(self, ec);
    if (EC_KEY_generate_key(ec) != 1)
	ossl_raise(eECError, "EC_KEY_generate_key");

    return self;
#endif
}

/*
 * call-seq:
 *    key.check_key   => true
 *
 * Raises an exception if the key is invalid.
 *
 * See also the man page EVP_PKEY_public_check(3).
 */
static VALUE ossl_ec_key_check_key(VALUE self)
{
#ifdef HAVE_EVP_PKEY_CHECK
    EVP_PKEY *pkey;
    EVP_PKEY_CTX *pctx;
    const EC_KEY *ec;

    GetPKey(self, pkey);
    GetEC(self, ec);
    pctx = EVP_PKEY_CTX_new(pkey, /* engine */NULL);
    if (!pctx)
        ossl_raise(eECError, "EVP_PKEY_CTX_new");

    if (EC_KEY_get0_private_key(ec) != NULL) {
        if (EVP_PKEY_check(pctx) != 1) {
            EVP_PKEY_CTX_free(pctx);
            ossl_raise(eECError, "EVP_PKEY_check");
        }
    }
    else {
        if (EVP_PKEY_public_check(pctx) != 1) {
            EVP_PKEY_CTX_free(pctx);
            ossl_raise(eECError, "EVP_PKEY_public_check");
        }
    }

    EVP_PKEY_CTX_free(pctx);
#else
    EC_KEY *ec;

    GetEC(self, ec);
    if (EC_KEY_check_key(ec) != 1)
	ossl_raise(eECError, "EC_KEY_check_key");
#endif

    return Qtrue;
}

/*
 * OpenSSL::PKey::EC::Group
 */
static void
ossl_ec_group_free(void *ptr)
{
    EC_GROUP_free(ptr);
}

static const rb_data_type_t ossl_ec_group_type = {
    "OpenSSL/ec_group",
    {
	0, ossl_ec_group_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
ossl_ec_group_alloc(VALUE klass)
{
    return TypedData_Wrap_Struct(klass, &ossl_ec_group_type, NULL);
}

static VALUE
ec_group_new(const EC_GROUP *group)
{
    VALUE obj;
    EC_GROUP *group_new;

    obj = ossl_ec_group_alloc(cEC_GROUP);
    group_new = EC_GROUP_dup(group);
    if (!group_new)
	ossl_raise(eEC_GROUP, "EC_GROUP_dup");
    RTYPEDDATA_DATA(obj) = group_new;

    return obj;
}

/*
 * call-seq:
 *   OpenSSL::PKey::EC::Group.new(ec_group)
 *   OpenSSL::PKey::EC::Group.new(pem_or_der_encoded)
 *   OpenSSL::PKey::EC::Group.new(:GFp, bignum_p, bignum_a, bignum_b)
 *   OpenSSL::PKey::EC::Group.new(:GF2m, bignum_p, bignum_a, bignum_b)
 *
 * Creates a new EC::Group object.
 *
 * If the first argument is :GFp or :GF2m, creates a new curve with given
 * parameters.
 */
static VALUE ossl_ec_group_initialize(int argc, VALUE *argv, VALUE self)
{
    VALUE arg1, arg2, arg3, arg4;
    EC_GROUP *group;

    TypedData_Get_Struct(self, EC_GROUP, &ossl_ec_group_type, group);
    if (group)
        ossl_raise(rb_eRuntimeError, "EC_GROUP is already initialized");

    switch (rb_scan_args(argc, argv, "13", &arg1, &arg2, &arg3, &arg4)) {
    case 1:
        if (rb_obj_is_kind_of(arg1, cEC_GROUP)) {
            const EC_GROUP *arg1_group;

            GetECGroup(arg1, arg1_group);
            if ((group = EC_GROUP_dup(arg1_group)) == NULL)
                ossl_raise(eEC_GROUP, "EC_GROUP_dup");
        } else {
            BIO *in = ossl_obj2bio(&arg1);

            group = PEM_read_bio_ECPKParameters(in, NULL, NULL, NULL);
            if (!group) {
		OSSL_BIO_reset(in);
                group = d2i_ECPKParameters_bio(in, NULL);
            }

            BIO_free(in);

            if (!group) {
                const char *name = StringValueCStr(arg1);
                int nid = OBJ_sn2nid(name);

		ossl_clear_error(); /* ignore errors in d2i_ECPKParameters_bio() */
                if (nid == NID_undef)
                    ossl_raise(eEC_GROUP, "unknown curve name (%"PRIsVALUE")", arg1);

                group = EC_GROUP_new_by_curve_name(nid);
                if (group == NULL)
                    ossl_raise(eEC_GROUP, "unable to create curve (%"PRIsVALUE")", arg1);

                EC_GROUP_set_asn1_flag(group, OPENSSL_EC_NAMED_CURVE);
                EC_GROUP_set_point_conversion_form(group, POINT_CONVERSION_UNCOMPRESSED);
            }
        }

        break;
    case 4:
        if (SYMBOL_P(arg1)) {
            ID id = SYM2ID(arg1);
            EC_GROUP *(*new_curve)(const BIGNUM *, const BIGNUM *, const BIGNUM *, BN_CTX *) = NULL;
            const BIGNUM *p = GetBNPtr(arg2);
            const BIGNUM *a = GetBNPtr(arg3);
            const BIGNUM *b = GetBNPtr(arg4);

            if (id == s_GFp) {
                new_curve = EC_GROUP_new_curve_GFp;
#if !defined(OPENSSL_NO_EC2M)
            } else if (id == s_GF2m) {
                new_curve = EC_GROUP_new_curve_GF2m;
#endif
            } else {
                ossl_raise(rb_eArgError, "unknown symbol, must be :GFp or :GF2m");
            }

            if ((group = new_curve(p, a, b, ossl_bn_ctx)) == NULL)
                ossl_raise(eEC_GROUP, "EC_GROUP_new_by_GF*");
        } else {
             ossl_raise(rb_eArgError, "unknown argument, must be :GFp or :GF2m");
        }

        break;
    default:
        ossl_raise(rb_eArgError, "wrong number of arguments");
    }

    ASSUME(group);
    RTYPEDDATA_DATA(self) = group;

    return self;
}

static VALUE
ossl_ec_group_initialize_copy(VALUE self, VALUE other)
{
    EC_GROUP *group, *group_new;

    TypedData_Get_Struct(self, EC_GROUP, &ossl_ec_group_type, group_new);
    if (group_new)
	ossl_raise(eEC_GROUP, "EC::Group already initialized");
    GetECGroup(other, group);

    group_new = EC_GROUP_dup(group);
    if (!group_new)
	ossl_raise(eEC_GROUP, "EC_GROUP_dup");
    RTYPEDDATA_DATA(self) = group_new;

    return self;
}

/*
 * call-seq:
 *   group1.eql?(group2)   => true | false
 *   group1 == group2   => true | false
 *
 * Returns +true+ if the two groups use the same curve and have the same
 * parameters, +false+ otherwise.
 */
static VALUE ossl_ec_group_eql(VALUE a, VALUE b)
{
    EC_GROUP *group1 = NULL, *group2 = NULL;

    GetECGroup(a, group1);
    GetECGroup(b, group2);

    switch (EC_GROUP_cmp(group1, group2, ossl_bn_ctx)) {
    case 0: return Qtrue;
    case 1: return Qfalse;
    default: ossl_raise(eEC_GROUP, "EC_GROUP_cmp");
    }
}

/*
 * call-seq:
 *   group.generator   => ec_point
 *
 * Returns the generator of the group.
 *
 * See the OpenSSL documentation for EC_GROUP_get0_generator()
 */
static VALUE ossl_ec_group_get_generator(VALUE self)
{
    EC_GROUP *group;
    const EC_POINT *generator;

    GetECGroup(self, group);
    generator = EC_GROUP_get0_generator(group);
    if (!generator)
	return Qnil;

    return ec_point_new(generator, group);
}

/*
 * call-seq:
 *   group.set_generator(generator, order, cofactor)   => self
 *
 * Sets the curve parameters. _generator_ must be an instance of EC::Point that
 * is on the curve. _order_ and _cofactor_ are integers.
 *
 * See the OpenSSL documentation for EC_GROUP_set_generator()
 */
static VALUE ossl_ec_group_set_generator(VALUE self, VALUE generator, VALUE order, VALUE cofactor)
{
    EC_GROUP *group = NULL;
    const EC_POINT *point;
    const BIGNUM *o, *co;

    GetECGroup(self, group);
    GetECPoint(generator, point);
    o = GetBNPtr(order);
    co = GetBNPtr(cofactor);

    if (EC_GROUP_set_generator(group, point, o, co) != 1)
        ossl_raise(eEC_GROUP, "EC_GROUP_set_generator");

    return self;
}

/*
 * call-seq:
 *   group.get_order   => order_bn
 *
 * Returns the order of the group.
 *
 * See the OpenSSL documentation for EC_GROUP_get_order()
 */
static VALUE ossl_ec_group_get_order(VALUE self)
{
    VALUE bn_obj;
    BIGNUM *bn;
    EC_GROUP *group = NULL;

    GetECGroup(self, group);

    bn_obj = ossl_bn_new(NULL);
    bn = GetBNPtr(bn_obj);

    if (EC_GROUP_get_order(group, bn, ossl_bn_ctx) != 1)
        ossl_raise(eEC_GROUP, "EC_GROUP_get_order");

    return bn_obj;
}

/*
 * call-seq:
 *   group.get_cofactor   => cofactor_bn
 *
 * Returns the cofactor of the group.
 *
 * See the OpenSSL documentation for EC_GROUP_get_cofactor()
 */
static VALUE ossl_ec_group_get_cofactor(VALUE self)
{
    VALUE bn_obj;
    BIGNUM *bn;
    EC_GROUP *group = NULL;

    GetECGroup(self, group);

    bn_obj = ossl_bn_new(NULL);
    bn = GetBNPtr(bn_obj);

    if (EC_GROUP_get_cofactor(group, bn, ossl_bn_ctx) != 1)
        ossl_raise(eEC_GROUP, "EC_GROUP_get_cofactor");

    return bn_obj;
}

/*
 * call-seq:
 *   group.curve_name  => String
 *
 * Returns the curve name (sn).
 *
 * See the OpenSSL documentation for EC_GROUP_get_curve_name()
 */
static VALUE ossl_ec_group_get_curve_name(VALUE self)
{
    EC_GROUP *group = NULL;
    int nid;

    GetECGroup(self, group);
    if (group == NULL)
        return Qnil;

    nid = EC_GROUP_get_curve_name(group);

/* BUG: an nid or asn1 object should be returned, maybe. */
    return rb_str_new2(OBJ_nid2sn(nid));
}

/*
 * call-seq:
 *   EC.builtin_curves => [[sn, comment], ...]
 *
 * Obtains a list of all predefined curves by the OpenSSL. Curve names are
 * returned as sn.
 *
 * See the OpenSSL documentation for EC_get_builtin_curves().
 */
static VALUE ossl_s_builtin_curves(VALUE self)
{
    EC_builtin_curve *curves = NULL;
    int n;
    int crv_len = rb_long2int(EC_get_builtin_curves(NULL, 0));
    VALUE ary, ret;

    curves = ALLOCA_N(EC_builtin_curve, crv_len);
    if (curves == NULL)
        return Qnil;
    if (!EC_get_builtin_curves(curves, crv_len))
        ossl_raise(rb_eRuntimeError, "EC_get_builtin_curves");

    ret = rb_ary_new2(crv_len);

    for (n = 0; n < crv_len; n++) {
        const char *sname = OBJ_nid2sn(curves[n].nid);
        const char *comment = curves[n].comment;

        ary = rb_ary_new2(2);
        rb_ary_push(ary, rb_str_new2(sname));
        rb_ary_push(ary, comment ? rb_str_new2(comment) : Qnil);
        rb_ary_push(ret, ary);
    }

    return ret;
}

/*
 * call-seq:
 *   group.asn1_flag -> Integer
 *
 * Returns the flags set on the group.
 *
 * See also #asn1_flag=.
 */
static VALUE ossl_ec_group_get_asn1_flag(VALUE self)
{
    EC_GROUP *group = NULL;
    int flag;

    GetECGroup(self, group);
    flag = EC_GROUP_get_asn1_flag(group);

    return INT2NUM(flag);
}

/*
 * call-seq:
 *   group.asn1_flag = flags
 *
 * Sets flags on the group. The flag value is used to determine how to encode
 * the group: encode explicit parameters or named curve using an OID.
 *
 * The flag value can be either of:
 *
 * * EC::NAMED_CURVE
 * * EC::EXPLICIT_CURVE
 *
 * See the OpenSSL documentation for EC_GROUP_set_asn1_flag().
 */
static VALUE ossl_ec_group_set_asn1_flag(VALUE self, VALUE flag_v)
{
    EC_GROUP *group = NULL;

    GetECGroup(self, group);
    EC_GROUP_set_asn1_flag(group, NUM2INT(flag_v));

    return flag_v;
}

/*
 * call-seq:
 *   group.point_conversion_form -> Symbol
 *
 * Returns the form how EC::Point data is encoded as ASN.1.
 *
 * See also #point_conversion_form=.
 */
static VALUE ossl_ec_group_get_point_conversion_form(VALUE self)
{
    EC_GROUP *group = NULL;
    point_conversion_form_t form;
    VALUE ret;

    GetECGroup(self, group);
    form = EC_GROUP_get_point_conversion_form(group);

    switch (form) {
    case POINT_CONVERSION_UNCOMPRESSED:	ret = ID_uncompressed; break;
    case POINT_CONVERSION_COMPRESSED:	ret = ID_compressed; break;
    case POINT_CONVERSION_HYBRID:	ret = ID_hybrid; break;
    default:	ossl_raise(eEC_GROUP, "unsupported point conversion form: %d, this module should be updated", form);
    }

   return ID2SYM(ret);
}

static point_conversion_form_t
parse_point_conversion_form_symbol(VALUE sym)
{
    ID id = SYM2ID(sym);

    if (id == ID_uncompressed)
	return POINT_CONVERSION_UNCOMPRESSED;
    else if (id == ID_compressed)
	return POINT_CONVERSION_COMPRESSED;
    else if (id == ID_hybrid)
	return POINT_CONVERSION_HYBRID;
    else
	ossl_raise(rb_eArgError, "unsupported point conversion form %+"PRIsVALUE
		   " (expected :compressed, :uncompressed, or :hybrid)", sym);
}

/*
 * call-seq:
 *   group.point_conversion_form = form
 *
 * Sets the form how EC::Point data is encoded as ASN.1 as defined in X9.62.
 *
 * _format_ can be one of these:
 *
 * +:compressed+::
 *   Encoded as z||x, where z is an octet indicating which solution of the
 *   equation y is. z will be 0x02 or 0x03.
 * +:uncompressed+::
 *   Encoded as z||x||y, where z is an octet 0x04.
 * +:hybrid+::
 *   Encodes as z||x||y, where z is an octet indicating which solution of the
 *   equation y is. z will be 0x06 or 0x07.
 *
 * See the OpenSSL documentation for EC_GROUP_set_point_conversion_form()
 */
static VALUE
ossl_ec_group_set_point_conversion_form(VALUE self, VALUE form_v)
{
    EC_GROUP *group;
    point_conversion_form_t form;

    GetECGroup(self, group);
    form = parse_point_conversion_form_symbol(form_v);

    EC_GROUP_set_point_conversion_form(group, form);

    return form_v;
}

/*
 * call-seq:
 *   group.seed   => String or nil
 *
 * See the OpenSSL documentation for EC_GROUP_get0_seed()
 */
static VALUE ossl_ec_group_get_seed(VALUE self)
{
    EC_GROUP *group = NULL;
    size_t seed_len;

    GetECGroup(self, group);
    seed_len = EC_GROUP_get_seed_len(group);

    if (seed_len == 0)
        return Qnil;

    return rb_str_new((const char *)EC_GROUP_get0_seed(group), seed_len);
}

/*
 * call-seq:
 *   group.seed = seed  => seed
 *
 * See the OpenSSL documentation for EC_GROUP_set_seed()
 */
static VALUE ossl_ec_group_set_seed(VALUE self, VALUE seed)
{
    EC_GROUP *group = NULL;

    GetECGroup(self, group);
    StringValue(seed);

    if (EC_GROUP_set_seed(group, (unsigned char *)RSTRING_PTR(seed), RSTRING_LEN(seed)) != (size_t)RSTRING_LEN(seed))
        ossl_raise(eEC_GROUP, "EC_GROUP_set_seed");

    return seed;
}

/* get/set curve GFp, GF2m */

/*
 * call-seq:
 *   group.degree   => integer
 *
 * See the OpenSSL documentation for EC_GROUP_get_degree()
 */
static VALUE ossl_ec_group_get_degree(VALUE self)
{
    EC_GROUP *group = NULL;

    GetECGroup(self, group);

    return INT2NUM(EC_GROUP_get_degree(group));
}

static VALUE ossl_ec_group_to_string(VALUE self, int format)
{
    EC_GROUP *group;
    BIO *out;
    int i = -1;
    VALUE str;

    GetECGroup(self, group);

    if (!(out = BIO_new(BIO_s_mem())))
        ossl_raise(eEC_GROUP, "BIO_new(BIO_s_mem())");

    switch(format) {
    case EXPORT_PEM:
        i = PEM_write_bio_ECPKParameters(out, group);
    	break;
    case EXPORT_DER:
        i = i2d_ECPKParameters_bio(out, group);
    	break;
    default:
        BIO_free(out);
    	ossl_raise(rb_eRuntimeError, "unknown format (internal error)");
    }

    if (i != 1) {
        BIO_free(out);
        ossl_raise(eECError, NULL);
    }

    str = ossl_membio2str(out);

    return str;
}

/*
 * call-seq:
 *   group.to_pem   => String
 *
 *  See the OpenSSL documentation for PEM_write_bio_ECPKParameters()
 */
static VALUE ossl_ec_group_to_pem(VALUE self)
{
    return ossl_ec_group_to_string(self, EXPORT_PEM);
}

/*
 * call-seq:
 *   group.to_der   => String
 *
 * See the OpenSSL documentation for i2d_ECPKParameters_bio()
 */
static VALUE ossl_ec_group_to_der(VALUE self)
{
    return ossl_ec_group_to_string(self, EXPORT_DER);
}

/*
 * call-seq:
 *   group.to_text   => String
 *
 * See the OpenSSL documentation for ECPKParameters_print()
 */
static VALUE ossl_ec_group_to_text(VALUE self)
{
    EC_GROUP *group;
    BIO *out;
    VALUE str;

    GetECGroup(self, group);
    if (!(out = BIO_new(BIO_s_mem()))) {
	ossl_raise(eEC_GROUP, "BIO_new(BIO_s_mem())");
    }
    if (!ECPKParameters_print(out, group, 0)) {
	BIO_free(out);
	ossl_raise(eEC_GROUP, NULL);
    }
    str = ossl_membio2str(out);

    return str;
}


/*
 * OpenSSL::PKey::EC::Point
 */
static void
ossl_ec_point_free(void *ptr)
{
    EC_POINT_clear_free(ptr);
}

static const rb_data_type_t ossl_ec_point_type = {
    "OpenSSL/EC_POINT",
    {
	0, ossl_ec_point_free,
    },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

static VALUE
ossl_ec_point_alloc(VALUE klass)
{
    return TypedData_Wrap_Struct(klass, &ossl_ec_point_type, NULL);
}

static VALUE
ec_point_new(const EC_POINT *point, const EC_GROUP *group)
{
    EC_POINT *point_new;
    VALUE obj;

    obj = ossl_ec_point_alloc(cEC_POINT);
    point_new = EC_POINT_dup(point, group);
    if (!point_new)
	ossl_raise(eEC_POINT, "EC_POINT_dup");
    RTYPEDDATA_DATA(obj) = point_new;
    rb_ivar_set(obj, id_i_group, ec_group_new(group));

    return obj;
}

static VALUE ossl_ec_point_initialize_copy(VALUE, VALUE);
/*
 * call-seq:
 *   OpenSSL::PKey::EC::Point.new(point)
 *   OpenSSL::PKey::EC::Point.new(group [, encoded_point])
 *
 * Creates a new instance of OpenSSL::PKey::EC::Point. If the only argument is
 * an instance of EC::Point, a copy is returned. Otherwise, creates a point
 * that belongs to _group_.
 *
 * _encoded_point_ is the octet string representation of the point. This
 * must be either a String or an OpenSSL::BN.
 */
static VALUE ossl_ec_point_initialize(int argc, VALUE *argv, VALUE self)
{
    EC_POINT *point;
    VALUE group_v, arg2;
    const EC_GROUP *group;

    TypedData_Get_Struct(self, EC_POINT, &ossl_ec_point_type, point);
    if (point)
	rb_raise(eEC_POINT, "EC_POINT already initialized");

    rb_scan_args(argc, argv, "11", &group_v, &arg2);
    if (rb_obj_is_kind_of(group_v, cEC_POINT)) {
	if (argc != 1)
	    rb_raise(rb_eArgError, "invalid second argument");
	return ossl_ec_point_initialize_copy(self, group_v);
    }

    GetECGroup(group_v, group);
    if (argc == 1) {
	point = EC_POINT_new(group);
	if (!point)
	    ossl_raise(eEC_POINT, "EC_POINT_new");
    }
    else {
	if (rb_obj_is_kind_of(arg2, cBN)) {
	    point = EC_POINT_bn2point(group, GetBNPtr(arg2), NULL, ossl_bn_ctx);
	    if (!point)
		ossl_raise(eEC_POINT, "EC_POINT_bn2point");
	}
	else {
	    StringValue(arg2);
	    point = EC_POINT_new(group);
	    if (!point)
		ossl_raise(eEC_POINT, "EC_POINT_new");
	    if (!EC_POINT_oct2point(group, point,
				    (unsigned char *)RSTRING_PTR(arg2),
				    RSTRING_LEN(arg2), ossl_bn_ctx)) {
		EC_POINT_free(point);
		ossl_raise(eEC_POINT, "EC_POINT_oct2point");
	    }
	}
    }

    RTYPEDDATA_DATA(self) = point;
    rb_ivar_set(self, id_i_group, group_v);

    return self;
}

static VALUE
ossl_ec_point_initialize_copy(VALUE self, VALUE other)
{
    EC_POINT *point, *point_new;
    EC_GROUP *group;
    VALUE group_v;

    TypedData_Get_Struct(self, EC_POINT, &ossl_ec_point_type, point_new);
    if (point_new)
	ossl_raise(eEC_POINT, "EC::Point already initialized");
    GetECPoint(other, point);

    group_v = rb_obj_dup(rb_attr_get(other, id_i_group));
    GetECGroup(group_v, group);

    point_new = EC_POINT_dup(point, group);
    if (!point_new)
	ossl_raise(eEC_POINT, "EC_POINT_dup");
    RTYPEDDATA_DATA(self) = point_new;
    rb_ivar_set(self, id_i_group, group_v);

    return self;
}

/*
 * call-seq:
 *   point1.eql?(point2) => true | false
 *   point1 == point2 => true | false
 */
static VALUE ossl_ec_point_eql(VALUE a, VALUE b)
{
    EC_POINT *point1, *point2;
    VALUE group_v1 = rb_attr_get(a, id_i_group);
    VALUE group_v2 = rb_attr_get(b, id_i_group);
    const EC_GROUP *group;

    if (ossl_ec_group_eql(group_v1, group_v2) == Qfalse)
        return Qfalse;

    GetECPoint(a, point1);
    GetECPoint(b, point2);
    GetECGroup(group_v1, group);

    switch (EC_POINT_cmp(group, point1, point2, ossl_bn_ctx)) {
    case 0: return Qtrue;
    case 1: return Qfalse;
    default: ossl_raise(eEC_POINT, "EC_POINT_cmp");
    }

    UNREACHABLE;
}

/*
 * call-seq:
 *   point.infinity? => true | false
 */
static VALUE ossl_ec_point_is_at_infinity(VALUE self)
{
    EC_POINT *point;
    const EC_GROUP *group;

    GetECPoint(self, point);
    GetECPointGroup(self, group);

    switch (EC_POINT_is_at_infinity(group, point)) {
    case 1: return Qtrue;
    case 0: return Qfalse;
    default: ossl_raise(eEC_POINT, "EC_POINT_is_at_infinity");
    }

    UNREACHABLE;
}

/*
 * call-seq:
 *   point.on_curve? => true | false
 */
static VALUE ossl_ec_point_is_on_curve(VALUE self)
{
    EC_POINT *point;
    const EC_GROUP *group;

    GetECPoint(self, point);
    GetECPointGroup(self, group);

    switch (EC_POINT_is_on_curve(group, point, ossl_bn_ctx)) {
    case 1: return Qtrue;
    case 0: return Qfalse;
    default: ossl_raise(eEC_POINT, "EC_POINT_is_on_curve");
    }

    UNREACHABLE;
}

/*
 * call-seq:
 *   point.make_affine! => self
 *
 * This method is deprecated and should not be used. This is a no-op.
 */
static VALUE ossl_ec_point_make_affine(VALUE self)
{
    EC_POINT *point;
    const EC_GROUP *group;

    GetECPoint(self, point);
    GetECPointGroup(self, group);

    rb_warn("OpenSSL::PKey::EC::Point#make_affine! is deprecated");
#if !OSSL_OPENSSL_PREREQ(3, 0, 0)
    if (EC_POINT_make_affine(group, point, ossl_bn_ctx) != 1)
        ossl_raise(eEC_POINT, "EC_POINT_make_affine");
#endif

    return self;
}

/*
 * call-seq:
 *   point.invert! => self
 */
static VALUE ossl_ec_point_invert(VALUE self)
{
    EC_POINT *point;
    const EC_GROUP *group;

    GetECPoint(self, point);
    GetECPointGroup(self, group);

    if (EC_POINT_invert(group, point, ossl_bn_ctx) != 1)
        ossl_raise(eEC_POINT, "EC_POINT_invert");

    return self;
}

/*
 * call-seq:
 *   point.set_to_infinity! => self
 */
static VALUE ossl_ec_point_set_to_infinity(VALUE self)
{
    EC_POINT *point;
    const EC_GROUP *group;

    GetECPoint(self, point);
    GetECPointGroup(self, group);

    if (EC_POINT_set_to_infinity(group, point) != 1)
        ossl_raise(eEC_POINT, "EC_POINT_set_to_infinity");

    return self;
}

/*
 * call-seq:
 *    point.to_octet_string(conversion_form) -> String
 *
 * Returns the octet string representation of the elliptic curve point.
 *
 * _conversion_form_ specifies how the point is converted. Possible values are:
 *
 * - +:compressed+
 * - +:uncompressed+
 * - +:hybrid+
 */
static VALUE
ossl_ec_point_to_octet_string(VALUE self, VALUE conversion_form)
{
    EC_POINT *point;
    const EC_GROUP *group;
    point_conversion_form_t form;
    VALUE str;
    size_t len;

    GetECPoint(self, point);
    GetECPointGroup(self, group);
    form = parse_point_conversion_form_symbol(conversion_form);

    len = EC_POINT_point2oct(group, point, form, NULL, 0, ossl_bn_ctx);
    if (!len)
	ossl_raise(eEC_POINT, "EC_POINT_point2oct");
    str = rb_str_new(NULL, (long)len);
    if (!EC_POINT_point2oct(group, point, form,
			    (unsigned char *)RSTRING_PTR(str), len,
			    ossl_bn_ctx))
	ossl_raise(eEC_POINT, "EC_POINT_point2oct");
    return str;
}

/*
 * call-seq:
 *   point.add(point) => point
 *
 * Performs elliptic curve point addition.
 */
static VALUE ossl_ec_point_add(VALUE self, VALUE other)
{
    EC_POINT *point_self, *point_other, *point_result;
    const EC_GROUP *group;
    VALUE group_v = rb_attr_get(self, id_i_group);
    VALUE result;

    GetECPoint(self, point_self);
    GetECPoint(other, point_other);
    GetECGroup(group_v, group);

    result = rb_obj_alloc(cEC_POINT);
    ossl_ec_point_initialize(1, &group_v, result);
    GetECPoint(result, point_result);

    if (EC_POINT_add(group, point_result, point_self, point_other, ossl_bn_ctx) != 1) {
        ossl_raise(eEC_POINT, "EC_POINT_add");
    }

    return result;
}

/*
 * call-seq:
 *   point.mul(bn1 [, bn2]) => point
 *   point.mul(bns, points [, bn2]) => point
 *
 * Performs elliptic curve point multiplication.
 *
 * The first form calculates <tt>bn1 * point + bn2 * G</tt>, where +G+ is the
 * generator of the group of _point_. _bn2_ may be omitted, and in that case,
 * the result is just <tt>bn1 * point</tt>.
 *
 * The second form calculates <tt>bns[0] * point + bns[1] * points[0] + ...
 * + bns[-1] * points[-1] + bn2 * G</tt>. _bn2_ may be omitted. _bns_ must be
 * an array of OpenSSL::BN. _points_ must be an array of
 * OpenSSL::PKey::EC::Point. Please note that <tt>points[0]</tt> is not
 * multiplied by <tt>bns[0]</tt>, but <tt>bns[1]</tt>.
 */
static VALUE ossl_ec_point_mul(int argc, VALUE *argv, VALUE self)
{
    EC_POINT *point_self, *point_result;
    const EC_GROUP *group;
    VALUE group_v = rb_attr_get(self, id_i_group);
    VALUE arg1, arg2, arg3, result;
    const BIGNUM *bn_g = NULL;

    GetECPoint(self, point_self);
    GetECGroup(group_v, group);

    result = rb_obj_alloc(cEC_POINT);
    ossl_ec_point_initialize(1, &group_v, result);
    GetECPoint(result, point_result);

    rb_scan_args(argc, argv, "12", &arg1, &arg2, &arg3);
    if (!RB_TYPE_P(arg1, T_ARRAY)) {
	BIGNUM *bn = GetBNPtr(arg1);

	if (!NIL_P(arg2))
	    bn_g = GetBNPtr(arg2);
	if (EC_POINT_mul(group, point_result, bn_g, point_self, bn, ossl_bn_ctx) != 1)
	    ossl_raise(eEC_POINT, NULL);
    } else {
#if (defined(OPENSSL_VERSION_MAJOR) && OPENSSL_VERSION_MAJOR >= 3) || defined(LIBRESSL_VERSION_NUMBER)
        rb_raise(rb_eNotImpError, "calling #mul with arrays is not" \
                 "supported by this OpenSSL version");
#else
	/*
	 * bignums | arg1[0] | arg1[1] | arg1[2] | ...
	 * points  | self    | arg2[0] | arg2[1] | ...
	 */
	long i, num;
	VALUE bns_tmp, tmp_p, tmp_b;
	const EC_POINT **points;
	const BIGNUM **bignums;

	Check_Type(arg1, T_ARRAY);
	Check_Type(arg2, T_ARRAY);
	if (RARRAY_LEN(arg1) != RARRAY_LEN(arg2) + 1) /* arg2 must be 1 larger */
	    ossl_raise(rb_eArgError, "bns must be 1 longer than points; see the documentation");

        rb_warning("OpenSSL::PKey::EC::Point#mul(ary, ary) is deprecated; " \
                   "use #mul(bn) form instead");

	num = RARRAY_LEN(arg1);
	bns_tmp = rb_ary_tmp_new(num);
	bignums = ALLOCV_N(const BIGNUM *, tmp_b, num);
	for (i = 0; i < num; i++) {
	    VALUE item = RARRAY_AREF(arg1, i);
	    bignums[i] = GetBNPtr(item);
	    rb_ary_push(bns_tmp, item);
	}

	points = ALLOCV_N(const EC_POINT *, tmp_p, num);
	points[0] = point_self; /* self */
	for (i = 0; i < num - 1; i++)
	    GetECPoint(RARRAY_AREF(arg2, i), points[i + 1]);

	if (!NIL_P(arg3))
	    bn_g = GetBNPtr(arg3);

	if (EC_POINTs_mul(group, point_result, bn_g, num, points, bignums, ossl_bn_ctx) != 1) {
	    ALLOCV_END(tmp_b);
	    ALLOCV_END(tmp_p);
	    ossl_raise(eEC_POINT, NULL);
	}

	ALLOCV_END(tmp_b);
	ALLOCV_END(tmp_p);
#endif
    }

    return result;
}

void Init_ossl_ec(void)
{
#undef rb_intern
#if 0
    mPKey = rb_define_module_under(mOSSL, "PKey");
    cPKey = rb_define_class_under(mPKey, "PKey", rb_cObject);
    eOSSLError = rb_define_class_under(mOSSL, "OpenSSLError", rb_eStandardError);
    ePKeyError = rb_define_class_under(mPKey, "PKeyError", eOSSLError);
#endif

    eECError = rb_define_class_under(mPKey, "ECError", ePKeyError);

    /*
     * Document-class: OpenSSL::PKey::EC
     *
     * OpenSSL::PKey::EC provides access to Elliptic Curve Digital Signature
     * Algorithm (ECDSA) and Elliptic Curve Diffie-Hellman (ECDH).
     *
     * === Key exchange
     *   ec1 = OpenSSL::PKey::EC.generate("prime256v1")
     *   ec2 = OpenSSL::PKey::EC.generate("prime256v1")
     *   # ec1 and ec2 have own private key respectively
     *   shared_key1 = ec1.dh_compute_key(ec2.public_key)
     *   shared_key2 = ec2.dh_compute_key(ec1.public_key)
     *
     *   p shared_key1 == shared_key2 #=> true
     */
    cEC = rb_define_class_under(mPKey, "EC", cPKey);
    cEC_GROUP = rb_define_class_under(cEC, "Group", rb_cObject);
    cEC_POINT = rb_define_class_under(cEC, "Point", rb_cObject);
    eEC_GROUP = rb_define_class_under(cEC_GROUP, "Error", eOSSLError);
    eEC_POINT = rb_define_class_under(cEC_POINT, "Error", eOSSLError);

    s_GFp = rb_intern("GFp");
    s_GF2m = rb_intern("GF2m");

    ID_uncompressed = rb_intern("uncompressed");
    ID_compressed = rb_intern("compressed");
    ID_hybrid = rb_intern("hybrid");

    rb_define_const(cEC, "NAMED_CURVE", INT2NUM(OPENSSL_EC_NAMED_CURVE));
#if defined(OPENSSL_EC_EXPLICIT_CURVE)
    rb_define_const(cEC, "EXPLICIT_CURVE", INT2NUM(OPENSSL_EC_EXPLICIT_CURVE));
#endif

    rb_define_singleton_method(cEC, "builtin_curves", ossl_s_builtin_curves, 0);

    rb_define_singleton_method(cEC, "generate", ossl_ec_key_s_generate, 1);
    rb_define_method(cEC, "initialize", ossl_ec_key_initialize, -1);
#ifndef HAVE_EVP_PKEY_DUP
    rb_define_method(cEC, "initialize_copy", ossl_ec_key_initialize_copy, 1);
#endif

    rb_define_method(cEC, "group", ossl_ec_key_get_group, 0);
    rb_define_method(cEC, "group=", ossl_ec_key_set_group, 1);
    rb_define_method(cEC, "private_key", ossl_ec_key_get_private_key, 0);
    rb_define_method(cEC, "private_key=", ossl_ec_key_set_private_key, 1);
    rb_define_method(cEC, "public_key", ossl_ec_key_get_public_key, 0);
    rb_define_method(cEC, "public_key=", ossl_ec_key_set_public_key, 1);
    rb_define_method(cEC, "private?", ossl_ec_key_is_private, 0);
    rb_define_method(cEC, "public?", ossl_ec_key_is_public, 0);
    rb_define_alias(cEC, "private_key?", "private?");
    rb_define_alias(cEC, "public_key?", "public?");
/*  rb_define_method(cEC, "", ossl_ec_key_get_, 0);
    rb_define_method(cEC, "=", ossl_ec_key_set_ 1);
    set/get enc_flags
    set/get _conv_from
    set/get asn1_flag (can use ruby to call self.group.asn1_flag)
    set/get precompute_mult
*/
    rb_define_method(cEC, "generate_key!", ossl_ec_key_generate_key, 0);
    rb_define_alias(cEC, "generate_key", "generate_key!");
    rb_define_method(cEC, "check_key", ossl_ec_key_check_key, 0);

    rb_define_method(cEC, "export", ossl_ec_key_export, -1);
    rb_define_alias(cEC, "to_pem", "export");
    rb_define_method(cEC, "to_der", ossl_ec_key_to_der, 0);


    rb_define_alloc_func(cEC_GROUP, ossl_ec_group_alloc);
    rb_define_method(cEC_GROUP, "initialize", ossl_ec_group_initialize, -1);
    rb_define_method(cEC_GROUP, "initialize_copy", ossl_ec_group_initialize_copy, 1);
    rb_define_method(cEC_GROUP, "eql?", ossl_ec_group_eql, 1);
    rb_define_alias(cEC_GROUP, "==", "eql?");
/* copy/dup/cmp */

    rb_define_method(cEC_GROUP, "generator", ossl_ec_group_get_generator, 0);
    rb_define_method(cEC_GROUP, "set_generator", ossl_ec_group_set_generator, 3);
    rb_define_method(cEC_GROUP, "order", ossl_ec_group_get_order, 0);
    rb_define_method(cEC_GROUP, "cofactor", ossl_ec_group_get_cofactor, 0);

    rb_define_method(cEC_GROUP, "curve_name", ossl_ec_group_get_curve_name, 0);
/*    rb_define_method(cEC_GROUP, "curve_name=", ossl_ec_group_set_curve_name, 1); */

    rb_define_method(cEC_GROUP, "asn1_flag", ossl_ec_group_get_asn1_flag, 0);
    rb_define_method(cEC_GROUP, "asn1_flag=", ossl_ec_group_set_asn1_flag, 1);

    rb_define_method(cEC_GROUP, "point_conversion_form", ossl_ec_group_get_point_conversion_form, 0);
    rb_define_method(cEC_GROUP, "point_conversion_form=", ossl_ec_group_set_point_conversion_form, 1);

    rb_define_method(cEC_GROUP, "seed", ossl_ec_group_get_seed, 0);
    rb_define_method(cEC_GROUP, "seed=", ossl_ec_group_set_seed, 1);

/* get/set GFp, GF2m */

    rb_define_method(cEC_GROUP, "degree", ossl_ec_group_get_degree, 0);

/* check* */


    rb_define_method(cEC_GROUP, "to_pem", ossl_ec_group_to_pem, 0);
    rb_define_method(cEC_GROUP, "to_der", ossl_ec_group_to_der, 0);
    rb_define_method(cEC_GROUP, "to_text", ossl_ec_group_to_text, 0);


    rb_define_alloc_func(cEC_POINT, ossl_ec_point_alloc);
    rb_define_method(cEC_POINT, "initialize", ossl_ec_point_initialize, -1);
    rb_define_method(cEC_POINT, "initialize_copy", ossl_ec_point_initialize_copy, 1);
    rb_attr(cEC_POINT, rb_intern("group"), 1, 0, 0);
    rb_define_method(cEC_POINT, "eql?", ossl_ec_point_eql, 1);
    rb_define_alias(cEC_POINT, "==", "eql?");

    rb_define_method(cEC_POINT, "infinity?", ossl_ec_point_is_at_infinity, 0);
    rb_define_method(cEC_POINT, "on_curve?", ossl_ec_point_is_on_curve, 0);
    rb_define_method(cEC_POINT, "make_affine!", ossl_ec_point_make_affine, 0);
    rb_define_method(cEC_POINT, "invert!", ossl_ec_point_invert, 0);
    rb_define_method(cEC_POINT, "set_to_infinity!", ossl_ec_point_set_to_infinity, 0);
/* all the other methods */

    rb_define_method(cEC_POINT, "to_octet_string", ossl_ec_point_to_octet_string, 1);
    rb_define_method(cEC_POINT, "add", ossl_ec_point_add, 1);
    rb_define_method(cEC_POINT, "mul", ossl_ec_point_mul, -1);

    id_i_group = rb_intern("@group");
}

#else /* defined NO_EC */
void Init_ossl_ec(void)
{
}
#endif /* NO_EC */
