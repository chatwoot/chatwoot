/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001 Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#if !defined(OSSL_PKEY_H)
#define OSSL_PKEY_H

extern VALUE mPKey;
extern VALUE cPKey;
extern VALUE ePKeyError;
extern const rb_data_type_t ossl_evp_pkey_type;

/* For ENGINE */
#define OSSL_PKEY_SET_PRIVATE(obj) rb_ivar_set((obj), rb_intern("private"), Qtrue)
#define OSSL_PKEY_IS_PRIVATE(obj)  (rb_attr_get((obj), rb_intern("private")) == Qtrue)

#define GetPKey(obj, pkey) do {\
    TypedData_Get_Struct((obj), EVP_PKEY, &ossl_evp_pkey_type, (pkey)); \
    if (!(pkey)) { \
	rb_raise(rb_eRuntimeError, "PKEY wasn't initialized!");\
    } \
} while (0)

/* Takes ownership of the EVP_PKEY */
VALUE ossl_pkey_new(EVP_PKEY *);
void ossl_pkey_check_public_key(const EVP_PKEY *);
EVP_PKEY *ossl_pkey_read_generic(BIO *, VALUE);
EVP_PKEY *GetPKeyPtr(VALUE);
EVP_PKEY *DupPKeyPtr(VALUE);
EVP_PKEY *GetPrivPKeyPtr(VALUE);

/*
 * Serializes _self_ in X.509 SubjectPublicKeyInfo format and returns the
 * resulting String. Sub-classes use this when overriding #to_der.
 */
VALUE ossl_pkey_export_spki(VALUE self, int to_der);
/*
 * Serializes the private key _self_ in the traditional private key format
 * and returns the resulting String. Sub-classes use this when overriding
 * #to_der.
 */
VALUE ossl_pkey_export_traditional(int argc, VALUE *argv, VALUE self,
				   int to_der);

void Init_ossl_pkey(void);

/*
 * RSA
 */
extern VALUE cRSA;
extern VALUE eRSAError;

void Init_ossl_rsa(void);

/*
 * DSA
 */
extern VALUE cDSA;
extern VALUE eDSAError;

void Init_ossl_dsa(void);

/*
 * DH
 */
extern VALUE cDH;
extern VALUE eDHError;

void Init_ossl_dh(void);

/*
 * EC
 */
extern VALUE cEC;
extern VALUE eECError;
extern VALUE cEC_GROUP;
extern VALUE eEC_GROUP;
extern VALUE cEC_POINT;
extern VALUE eEC_POINT;
VALUE ossl_ec_new(EVP_PKEY *);
void Init_ossl_ec(void);

#define OSSL_PKEY_BN_DEF_GETTER0(_keytype, _type, _name, _get)		\
/*									\
 *  call-seq:								\
 *     _keytype##.##_name -> aBN					\
 */									\
static VALUE ossl_##_keytype##_get_##_name(VALUE self)			\
{									\
	const _type *obj;						\
	const BIGNUM *bn;						\
									\
	Get##_type(self, obj);						\
	_get;								\
	if (bn == NULL)							\
		return Qnil;						\
	return ossl_bn_new(bn);						\
}

#define OSSL_PKEY_BN_DEF_GETTER3(_keytype, _type, _group, a1, a2, a3)	\
	OSSL_PKEY_BN_DEF_GETTER0(_keytype, _type, a1,			\
		_type##_get0_##_group(obj, &bn, NULL, NULL))		\
	OSSL_PKEY_BN_DEF_GETTER0(_keytype, _type, a2,			\
		_type##_get0_##_group(obj, NULL, &bn, NULL))		\
	OSSL_PKEY_BN_DEF_GETTER0(_keytype, _type, a3,			\
		_type##_get0_##_group(obj, NULL, NULL, &bn))

#define OSSL_PKEY_BN_DEF_GETTER2(_keytype, _type, _group, a1, a2)	\
	OSSL_PKEY_BN_DEF_GETTER0(_keytype, _type, a1,			\
		_type##_get0_##_group(obj, &bn, NULL))			\
	OSSL_PKEY_BN_DEF_GETTER0(_keytype, _type, a2,			\
		_type##_get0_##_group(obj, NULL, &bn))

#if !OSSL_OPENSSL_PREREQ(3, 0, 0)
#define OSSL_PKEY_BN_DEF_SETTER3(_keytype, _type, _group, a1, a2, a3)	\
/*									\
 *  call-seq:								\
 *     _keytype##.set_##_group(a1, a2, a3) -> self			\
 */									\
static VALUE ossl_##_keytype##_set_##_group(VALUE self, VALUE v1, VALUE v2, VALUE v3) \
{									\
	_type *obj;							\
	BIGNUM *bn1 = NULL, *orig_bn1 = NIL_P(v1) ? NULL : GetBNPtr(v1);\
	BIGNUM *bn2 = NULL, *orig_bn2 = NIL_P(v2) ? NULL : GetBNPtr(v2);\
	BIGNUM *bn3 = NULL, *orig_bn3 = NIL_P(v3) ? NULL : GetBNPtr(v3);\
									\
	Get##_type(self, obj);						\
        if ((orig_bn1 && !(bn1 = BN_dup(orig_bn1))) ||			\
            (orig_bn2 && !(bn2 = BN_dup(orig_bn2))) ||			\
            (orig_bn3 && !(bn3 = BN_dup(orig_bn3)))) {			\
		BN_clear_free(bn1);					\
		BN_clear_free(bn2);					\
		BN_clear_free(bn3);					\
		ossl_raise(eBNError, NULL);				\
	}								\
									\
	if (!_type##_set0_##_group(obj, bn1, bn2, bn3)) {		\
		BN_clear_free(bn1);					\
		BN_clear_free(bn2);					\
		BN_clear_free(bn3);					\
		ossl_raise(ePKeyError, #_type"_set0_"#_group);		\
	}								\
	return self;							\
}

#define OSSL_PKEY_BN_DEF_SETTER2(_keytype, _type, _group, a1, a2)	\
/*									\
 *  call-seq:								\
 *     _keytype##.set_##_group(a1, a2) -> self				\
 */									\
static VALUE ossl_##_keytype##_set_##_group(VALUE self, VALUE v1, VALUE v2) \
{									\
	_type *obj;							\
	BIGNUM *bn1 = NULL, *orig_bn1 = NIL_P(v1) ? NULL : GetBNPtr(v1);\
	BIGNUM *bn2 = NULL, *orig_bn2 = NIL_P(v2) ? NULL : GetBNPtr(v2);\
									\
	Get##_type(self, obj);						\
        if ((orig_bn1 && !(bn1 = BN_dup(orig_bn1))) ||			\
            (orig_bn2 && !(bn2 = BN_dup(orig_bn2)))) {			\
		BN_clear_free(bn1);					\
		BN_clear_free(bn2);					\
		ossl_raise(eBNError, NULL);				\
	}								\
									\
	if (!_type##_set0_##_group(obj, bn1, bn2)) {			\
		BN_clear_free(bn1);					\
		BN_clear_free(bn2);					\
		ossl_raise(ePKeyError, #_type"_set0_"#_group);		\
	}								\
	return self;							\
}
#else
#define OSSL_PKEY_BN_DEF_SETTER3(_keytype, _type, _group, a1, a2, a3)	\
static VALUE ossl_##_keytype##_set_##_group(VALUE self, VALUE v1, VALUE v2, VALUE v3) \
{									\
        rb_raise(ePKeyError,						\
                 #_keytype"#set_"#_group"= is incompatible with OpenSSL 3.0"); \
}

#define OSSL_PKEY_BN_DEF_SETTER2(_keytype, _type, _group, a1, a2)	\
static VALUE ossl_##_keytype##_set_##_group(VALUE self, VALUE v1, VALUE v2) \
{									\
        rb_raise(ePKeyError,						\
                 #_keytype"#set_"#_group"= is incompatible with OpenSSL 3.0"); \
}
#endif

#define OSSL_PKEY_BN_DEF3(_keytype, _type, _group, a1, a2, a3)		\
	OSSL_PKEY_BN_DEF_GETTER3(_keytype, _type, _group, a1, a2, a3)	\
	OSSL_PKEY_BN_DEF_SETTER3(_keytype, _type, _group, a1, a2, a3)

#define OSSL_PKEY_BN_DEF2(_keytype, _type, _group, a1, a2)		\
	OSSL_PKEY_BN_DEF_GETTER2(_keytype, _type, _group, a1, a2)	\
	OSSL_PKEY_BN_DEF_SETTER2(_keytype, _type, _group, a1, a2)

#define DEF_OSSL_PKEY_BN(class, keytype, name)				\
	rb_define_method((class), #name, ossl_##keytype##_get_##name, 0)

#endif /* OSSL_PKEY_H */
