/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#if !defined(_OSSL_OPENSSL_MISSING_H_)
#define _OSSL_OPENSSL_MISSING_H_

#include "ruby/config.h"

/* added in 1.1.0 */
#if !defined(HAVE_EVP_MD_CTX_NEW)
#  define EVP_MD_CTX_new EVP_MD_CTX_create
#endif

#if !defined(HAVE_EVP_MD_CTX_FREE)
#  define EVP_MD_CTX_free EVP_MD_CTX_destroy
#endif

#if !defined(HAVE_X509_STORE_GET_EX_DATA)
#  define X509_STORE_get_ex_data(x, idx) \
	CRYPTO_get_ex_data(&(x)->ex_data, (idx))
#endif

#if !defined(HAVE_X509_STORE_SET_EX_DATA)
#  define X509_STORE_set_ex_data(x, idx, data) \
	CRYPTO_set_ex_data(&(x)->ex_data, (idx), (data))
#endif

#if !defined(HAVE_X509_STORE_GET_EX_NEW_INDEX) && !defined(X509_STORE_get_ex_new_index)
#  define X509_STORE_get_ex_new_index(l, p, newf, dupf, freef) \
	CRYPTO_get_ex_new_index(CRYPTO_EX_INDEX_X509_STORE, (l), (p), \
				(newf), (dupf), (freef))
#endif

#if !defined(HAVE_X509_CRL_GET0_SIGNATURE)
void ossl_X509_CRL_get0_signature(const X509_CRL *, const ASN1_BIT_STRING **, const X509_ALGOR **);
#  define X509_CRL_get0_signature ossl_X509_CRL_get0_signature
#endif

#if !defined(HAVE_X509_REQ_GET0_SIGNATURE)
void ossl_X509_REQ_get0_signature(const X509_REQ *, const ASN1_BIT_STRING **, const X509_ALGOR **);
#  define X509_REQ_get0_signature ossl_X509_REQ_get0_signature
#endif

#if !defined(HAVE_X509_REVOKED_GET0_SERIALNUMBER)
#  define X509_REVOKED_get0_serialNumber(x) ((x)->serialNumber)
#endif

#if !defined(HAVE_X509_REVOKED_GET0_REVOCATIONDATE)
#  define X509_REVOKED_get0_revocationDate(x) ((x)->revocationDate)
#endif

#if !defined(HAVE_X509_GET0_TBS_SIGALG)
#  define X509_get0_tbs_sigalg(x) ((x)->cert_info->signature)
#endif

#if !defined(HAVE_X509_STORE_CTX_GET0_UNTRUSTED)
#  define X509_STORE_CTX_get0_untrusted(x) ((x)->untrusted)
#endif

#if !defined(HAVE_X509_STORE_CTX_GET0_CERT)
#  define X509_STORE_CTX_get0_cert(x) ((x)->cert)
#endif

#if !defined(HAVE_X509_STORE_CTX_GET0_CHAIN)
#  define X509_STORE_CTX_get0_chain(ctx) X509_STORE_CTX_get_chain(ctx)
#endif

#if !defined(HAVE_OCSP_SINGLERESP_GET0_ID)
#  define OCSP_SINGLERESP_get0_id(s) ((s)->certId)
#endif

#if !defined(HAVE_SSL_CTX_GET_CIPHERS)
#  define SSL_CTX_get_ciphers(ctx) ((ctx)->cipher_list)
#endif

#if !defined(HAVE_X509_UP_REF)
#  define X509_up_ref(x) \
	CRYPTO_add(&(x)->references, 1, CRYPTO_LOCK_X509)
#endif

#if !defined(HAVE_X509_CRL_UP_REF)
#  define X509_CRL_up_ref(x) \
	CRYPTO_add(&(x)->references, 1, CRYPTO_LOCK_X509_CRL);
#endif

#if !defined(HAVE_X509_STORE_UP_REF)
#  define X509_STORE_up_ref(x) \
	CRYPTO_add(&(x)->references, 1, CRYPTO_LOCK_X509_STORE);
#endif

#if !defined(HAVE_SSL_SESSION_UP_REF)
#  define SSL_SESSION_up_ref(x) \
	CRYPTO_add(&(x)->references, 1, CRYPTO_LOCK_SSL_SESSION);
#endif

#if !defined(HAVE_EVP_PKEY_UP_REF)
#  define EVP_PKEY_up_ref(x) \
	CRYPTO_add(&(x)->references, 1, CRYPTO_LOCK_EVP_PKEY);
#endif

#if !defined(HAVE_OPAQUE_OPENSSL)
#define IMPL_PKEY_GETTER(_type, _name) \
static inline _type *EVP_PKEY_get0_##_type(EVP_PKEY *pkey) { \
	return pkey->pkey._name; }
#define IMPL_KEY_ACCESSOR2(_type, _group, a1, a2, _fail_cond) \
static inline void _type##_get0_##_group(const _type *obj, const BIGNUM **a1, const BIGNUM **a2) { \
	if (a1) *a1 = obj->a1; \
	if (a2) *a2 = obj->a2; } \
static inline int _type##_set0_##_group(_type *obj, BIGNUM *a1, BIGNUM *a2) { \
	if (_fail_cond) return 0; \
	BN_clear_free(obj->a1); obj->a1 = a1; \
	BN_clear_free(obj->a2); obj->a2 = a2; \
	return 1; }
#define IMPL_KEY_ACCESSOR3(_type, _group, a1, a2, a3, _fail_cond) \
static inline void _type##_get0_##_group(const _type *obj, const BIGNUM **a1, const BIGNUM **a2, const BIGNUM **a3) { \
	if (a1) *a1 = obj->a1; \
	if (a2) *a2 = obj->a2; \
	if (a3) *a3 = obj->a3; } \
static inline int _type##_set0_##_group(_type *obj, BIGNUM *a1, BIGNUM *a2, BIGNUM *a3) { \
	if (_fail_cond) return 0; \
	BN_clear_free(obj->a1); obj->a1 = a1; \
	BN_clear_free(obj->a2); obj->a2 = a2; \
	BN_clear_free(obj->a3); obj->a3 = a3; \
	return 1; }

#if !defined(OPENSSL_NO_RSA)
IMPL_PKEY_GETTER(RSA, rsa)
IMPL_KEY_ACCESSOR3(RSA, key, n, e, d, (n == obj->n || e == obj->e || (obj->d && d == obj->d)))
IMPL_KEY_ACCESSOR2(RSA, factors, p, q, (p == obj->p || q == obj->q))
IMPL_KEY_ACCESSOR3(RSA, crt_params, dmp1, dmq1, iqmp, (dmp1 == obj->dmp1 || dmq1 == obj->dmq1 || iqmp == obj->iqmp))
#endif

#if !defined(OPENSSL_NO_DSA)
IMPL_PKEY_GETTER(DSA, dsa)
IMPL_KEY_ACCESSOR2(DSA, key, pub_key, priv_key, (pub_key == obj->pub_key || (obj->priv_key && priv_key == obj->priv_key)))
IMPL_KEY_ACCESSOR3(DSA, pqg, p, q, g, (p == obj->p || q == obj->q || g == obj->g))
#endif

#if !defined(OPENSSL_NO_DH)
IMPL_PKEY_GETTER(DH, dh)
IMPL_KEY_ACCESSOR2(DH, key, pub_key, priv_key, (pub_key == obj->pub_key || (obj->priv_key && priv_key == obj->priv_key)))
IMPL_KEY_ACCESSOR3(DH, pqg, p, q, g, (p == obj->p || (obj->q && q == obj->q) || g == obj->g))
static inline ENGINE *DH_get0_engine(DH *dh) { return dh->engine; }
#endif

#if !defined(OPENSSL_NO_EC)
IMPL_PKEY_GETTER(EC_KEY, ec)
#endif

#undef IMPL_PKEY_GETTER
#undef IMPL_KEY_ACCESSOR2
#undef IMPL_KEY_ACCESSOR3
#endif /* HAVE_OPAQUE_OPENSSL */

#if !defined(EVP_CTRL_AEAD_GET_TAG)
#  define EVP_CTRL_AEAD_GET_TAG EVP_CTRL_GCM_GET_TAG
#  define EVP_CTRL_AEAD_SET_TAG EVP_CTRL_GCM_SET_TAG
#  define EVP_CTRL_AEAD_SET_IVLEN EVP_CTRL_GCM_SET_IVLEN
#endif

#if !defined(HAVE_X509_GET0_NOTBEFORE)
#  define X509_get0_notBefore(x) X509_get_notBefore(x)
#  define X509_get0_notAfter(x) X509_get_notAfter(x)
#  define X509_CRL_get0_lastUpdate(x) X509_CRL_get_lastUpdate(x)
#  define X509_CRL_get0_nextUpdate(x) X509_CRL_get_nextUpdate(x)
#  define X509_set1_notBefore(x, t) X509_set_notBefore(x, t)
#  define X509_set1_notAfter(x, t) X509_set_notAfter(x, t)
#  define X509_CRL_set1_lastUpdate(x, t) X509_CRL_set_lastUpdate(x, t)
#  define X509_CRL_set1_nextUpdate(x, t) X509_CRL_set_nextUpdate(x, t)
#endif

#if !defined(HAVE_SSL_SESSION_GET_PROTOCOL_VERSION)
#  define SSL_SESSION_get_protocol_version(s) ((s)->ssl_version)
#endif

#if !defined(HAVE_TS_STATUS_INFO_GET0_STATUS)
#  define TS_STATUS_INFO_get0_status(a) ((a)->status)
#endif

#if !defined(HAVE_TS_STATUS_INFO_GET0_TEXT)
#  define TS_STATUS_INFO_get0_text(a) ((a)->text)
#endif

#if !defined(HAVE_TS_STATUS_INFO_GET0_FAILURE_INFO)
#  define TS_STATUS_INFO_get0_failure_info(a) ((a)->failure_info)
#endif

#if !defined(HAVE_TS_VERIFY_CTS_SET_CERTS)
#  define TS_VERIFY_CTS_set_certs(ctx, crts) ((ctx)->certs=(crts))
#endif

#if !defined(HAVE_TS_VERIFY_CTX_SET_STORE)
#  define TS_VERIFY_CTX_set_store(ctx, str) ((ctx)->store=(str))
#endif

#if !defined(HAVE_TS_VERIFY_CTX_ADD_FLAGS)
#  define TS_VERIFY_CTX_add_flags(ctx, f) ((ctx)->flags |= (f))
#endif

#if !defined(HAVE_TS_RESP_CTX_SET_TIME_CB)
#   define TS_RESP_CTX_set_time_cb(ctx, callback, dta) do { \
        (ctx)->time_cb = (callback); \
        (ctx)->time_cb_data = (dta); \
    } while (0)
#endif

/* added in 3.0.0 */
#if !defined(HAVE_TS_VERIFY_CTX_SET_CERTS)
#  define TS_VERIFY_CTX_set_certs(ctx, crts) TS_VERIFY_CTS_set_certs(ctx, crts)
#endif

#ifndef HAVE_EVP_MD_CTX_GET0_MD
#  define EVP_MD_CTX_get0_md(ctx) EVP_MD_CTX_md(ctx)
#endif

/*
 * OpenSSL 1.1.0 added EVP_MD_CTX_pkey_ctx(), and then it was renamed to
 * EVP_MD_CTX_get_pkey_ctx(x) in OpenSSL 3.0.
 */
#ifndef HAVE_EVP_MD_CTX_GET_PKEY_CTX
# ifdef HAVE_EVP_MD_CTX_PKEY_CTX
#  define EVP_MD_CTX_get_pkey_ctx(x) EVP_MD_CTX_pkey_ctx(x)
# else
#  define EVP_MD_CTX_get_pkey_ctx(x) (x)->pctx
# endif
#endif

#ifndef HAVE_EVP_PKEY_EQ
#  define EVP_PKEY_eq(a, b) EVP_PKEY_cmp(a, b)
#endif

#endif /* _OSSL_OPENSSL_MISSING_H_ */
