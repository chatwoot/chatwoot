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

VALUE mX509;

#define DefX509Const(x) rb_define_const(mX509, #x, INT2NUM(X509_##x))
#define DefX509Default(x,i) \
  rb_define_const(mX509, "DEFAULT_" #x, rb_str_new2(X509_get_default_##i()))

ASN1_TIME *
ossl_x509_time_adjust(ASN1_TIME *s, VALUE time)
{
    time_t sec;

    int off_days;

    ossl_time_split(time, &sec, &off_days);
    return X509_time_adj_ex(s, off_days, 0, &sec);
}

void
Init_ossl_x509(void)
{
#if 0
    mOSSL = rb_define_module("OpenSSL");
#endif

    mX509 = rb_define_module_under(mOSSL, "X509");

    Init_ossl_x509attr();
    Init_ossl_x509cert();
    Init_ossl_x509crl();
    Init_ossl_x509ext();
    Init_ossl_x509name();
    Init_ossl_x509req();
    Init_ossl_x509revoked();
    Init_ossl_x509store();

    /* Constants are up-to-date with 1.1.1. */

    /* Certificate verification error code */
    DefX509Const(V_OK);
#if defined(X509_V_ERR_UNSPECIFIED) /* 1.0.1r, 1.0.2f, 1.1.0 */
    DefX509Const(V_ERR_UNSPECIFIED);
#endif
    DefX509Const(V_ERR_UNABLE_TO_GET_ISSUER_CERT);
    DefX509Const(V_ERR_UNABLE_TO_GET_CRL);
    DefX509Const(V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE);
    DefX509Const(V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE);
    DefX509Const(V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY);
    DefX509Const(V_ERR_CERT_SIGNATURE_FAILURE);
    DefX509Const(V_ERR_CRL_SIGNATURE_FAILURE);
    DefX509Const(V_ERR_CERT_NOT_YET_VALID);
    DefX509Const(V_ERR_CERT_HAS_EXPIRED);
    DefX509Const(V_ERR_CRL_NOT_YET_VALID);
    DefX509Const(V_ERR_CRL_HAS_EXPIRED);
    DefX509Const(V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD);
    DefX509Const(V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD);
    DefX509Const(V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD);
    DefX509Const(V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD);
    DefX509Const(V_ERR_OUT_OF_MEM);
    DefX509Const(V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT);
    DefX509Const(V_ERR_SELF_SIGNED_CERT_IN_CHAIN);
    DefX509Const(V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY);
    DefX509Const(V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE);
    DefX509Const(V_ERR_CERT_CHAIN_TOO_LONG);
    DefX509Const(V_ERR_CERT_REVOKED);
    DefX509Const(V_ERR_INVALID_CA);
    DefX509Const(V_ERR_PATH_LENGTH_EXCEEDED);
    DefX509Const(V_ERR_INVALID_PURPOSE);
    DefX509Const(V_ERR_CERT_UNTRUSTED);
    DefX509Const(V_ERR_CERT_REJECTED);
    DefX509Const(V_ERR_SUBJECT_ISSUER_MISMATCH);
    DefX509Const(V_ERR_AKID_SKID_MISMATCH);
    DefX509Const(V_ERR_AKID_ISSUER_SERIAL_MISMATCH);
    DefX509Const(V_ERR_KEYUSAGE_NO_CERTSIGN);
    DefX509Const(V_ERR_UNABLE_TO_GET_CRL_ISSUER);
    DefX509Const(V_ERR_UNHANDLED_CRITICAL_EXTENSION);
    DefX509Const(V_ERR_KEYUSAGE_NO_CRL_SIGN);
    DefX509Const(V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION);
    DefX509Const(V_ERR_INVALID_NON_CA);
    DefX509Const(V_ERR_PROXY_PATH_LENGTH_EXCEEDED);
    DefX509Const(V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE);
    DefX509Const(V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED);
    DefX509Const(V_ERR_INVALID_EXTENSION);
    DefX509Const(V_ERR_INVALID_POLICY_EXTENSION);
    DefX509Const(V_ERR_NO_EXPLICIT_POLICY);
    DefX509Const(V_ERR_DIFFERENT_CRL_SCOPE);
    DefX509Const(V_ERR_UNSUPPORTED_EXTENSION_FEATURE);
    DefX509Const(V_ERR_UNNESTED_RESOURCE);
    DefX509Const(V_ERR_PERMITTED_VIOLATION);
    DefX509Const(V_ERR_EXCLUDED_VIOLATION);
    DefX509Const(V_ERR_SUBTREE_MINMAX);
    DefX509Const(V_ERR_APPLICATION_VERIFICATION);
    DefX509Const(V_ERR_UNSUPPORTED_CONSTRAINT_TYPE);
    DefX509Const(V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX);
    DefX509Const(V_ERR_UNSUPPORTED_NAME_SYNTAX);
    DefX509Const(V_ERR_CRL_PATH_VALIDATION_ERROR);
#if defined(X509_V_ERR_PATH_LOOP)
    DefX509Const(V_ERR_PATH_LOOP);
#endif
#if defined(X509_V_ERR_SUITE_B_INVALID_VERSION)
    DefX509Const(V_ERR_SUITE_B_INVALID_VERSION);
    DefX509Const(V_ERR_SUITE_B_INVALID_ALGORITHM);
    DefX509Const(V_ERR_SUITE_B_INVALID_CURVE);
    DefX509Const(V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM);
    DefX509Const(V_ERR_SUITE_B_LOS_NOT_ALLOWED);
    DefX509Const(V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256);
#endif
    DefX509Const(V_ERR_HOSTNAME_MISMATCH);
    DefX509Const(V_ERR_EMAIL_MISMATCH);
    DefX509Const(V_ERR_IP_ADDRESS_MISMATCH);
#if defined(X509_V_ERR_DANE_NO_MATCH)
    DefX509Const(V_ERR_DANE_NO_MATCH);
#endif
#if defined(X509_V_ERR_EE_KEY_TOO_SMALL)
    DefX509Const(V_ERR_EE_KEY_TOO_SMALL);
    DefX509Const(V_ERR_CA_KEY_TOO_SMALL);
    DefX509Const(V_ERR_CA_MD_TOO_WEAK);
#endif
#if defined(X509_V_ERR_INVALID_CALL)
    DefX509Const(V_ERR_INVALID_CALL);
#endif
#if defined(X509_V_ERR_STORE_LOOKUP)
    DefX509Const(V_ERR_STORE_LOOKUP);
#endif
#if defined(X509_V_ERR_NO_VALID_SCTS)
    DefX509Const(V_ERR_NO_VALID_SCTS);
#endif
#if defined(X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION)
    DefX509Const(V_ERR_PROXY_SUBJECT_NAME_VIOLATION);
#endif
#if defined(X509_V_ERR_OCSP_VERIFY_NEEDED)
    DefX509Const(V_ERR_OCSP_VERIFY_NEEDED);
    DefX509Const(V_ERR_OCSP_VERIFY_FAILED);
    DefX509Const(V_ERR_OCSP_CERT_UNKNOWN);
#endif

    /* Certificate verify flags */
    /* Set by Store#flags= and StoreContext#flags=. */
    DefX509Const(V_FLAG_USE_CHECK_TIME);
    /* Set by Store#flags= and StoreContext#flags=. Enables CRL checking for the
     * certificate chain leaf. */
    DefX509Const(V_FLAG_CRL_CHECK);
    /* Set by Store#flags= and StoreContext#flags=. Enables CRL checking for all
     * certificates in the certificate chain */
    DefX509Const(V_FLAG_CRL_CHECK_ALL);
    /* Set by Store#flags= and StoreContext#flags=. Disables critical extension
     * checking. */
    DefX509Const(V_FLAG_IGNORE_CRITICAL);
    /* Set by Store#flags= and StoreContext#flags=. Disables workarounds for
     * broken certificates. */
    DefX509Const(V_FLAG_X509_STRICT);
    /* Set by Store#flags= and StoreContext#flags=. Enables proxy certificate
     * verification. */
    DefX509Const(V_FLAG_ALLOW_PROXY_CERTS);
    /* Set by Store#flags= and StoreContext#flags=. Enables certificate policy
     * constraints checking. */
    DefX509Const(V_FLAG_POLICY_CHECK);
    /* Set by Store#flags= and StoreContext#flags=.
     * Implies V_FLAG_POLICY_CHECK */
    DefX509Const(V_FLAG_EXPLICIT_POLICY);
    /* Set by Store#flags= and StoreContext#flags=.
     * Implies V_FLAG_POLICY_CHECK */
    DefX509Const(V_FLAG_INHIBIT_ANY);
    /* Set by Store#flags= and StoreContext#flags=.
     * Implies V_FLAG_POLICY_CHECK */
    DefX509Const(V_FLAG_INHIBIT_MAP);
    /* Set by Store#flags= and StoreContext#flags=. */
    DefX509Const(V_FLAG_NOTIFY_POLICY);
    /* Set by Store#flags= and StoreContext#flags=. Enables some additional
     * features including support for indirect signed CRLs. */
    DefX509Const(V_FLAG_EXTENDED_CRL_SUPPORT);
    /* Set by Store#flags= and StoreContext#flags=. Uses delta CRLs. If not
     * specified, deltas are ignored. */
    DefX509Const(V_FLAG_USE_DELTAS);
    /* Set by Store#flags= and StoreContext#flags=. Enables checking of the
     * signature of the root self-signed CA. */
    DefX509Const(V_FLAG_CHECK_SS_SIGNATURE);
    /* Set by Store#flags= and StoreContext#flags=. When constructing a
     * certificate chain, search the Store first for the issuer certificate.
     * Enabled by default in OpenSSL >= 1.1.0. */
    DefX509Const(V_FLAG_TRUSTED_FIRST);
#if defined(X509_V_FLAG_SUITEB_128_LOS_ONLY)
    /* Set by Store#flags= and StoreContext#flags=.
     * Enables Suite B 128 bit only mode. */
    DefX509Const(V_FLAG_SUITEB_128_LOS_ONLY);
#endif
#if defined(X509_V_FLAG_SUITEB_192_LOS)
    /* Set by Store#flags= and StoreContext#flags=.
     * Enables Suite B 192 bit only mode. */
    DefX509Const(V_FLAG_SUITEB_192_LOS);
#endif
#if defined(X509_V_FLAG_SUITEB_128_LOS)
    /* Set by Store#flags= and StoreContext#flags=.
     * Enables Suite B 128 bit mode allowing 192 bit algorithms. */
    DefX509Const(V_FLAG_SUITEB_128_LOS);
#endif
    /* Set by Store#flags= and StoreContext#flags=.
     * Allows partial chains if at least one certificate is in trusted store. */
    DefX509Const(V_FLAG_PARTIAL_CHAIN);
#if defined(X509_V_FLAG_NO_ALT_CHAINS)
    /* Set by Store#flags= and StoreContext#flags=. Suppresses searching for
     * a alternative chain. No effect in OpenSSL >= 1.1.0. */
    DefX509Const(V_FLAG_NO_ALT_CHAINS);
#endif
#if defined(X509_V_FLAG_NO_CHECK_TIME)
    /* Set by Store#flags= and StoreContext#flags=. Suppresses checking the
     * validity period of certificates and CRLs. No effect when the current
     * time is explicitly set by Store#time= or StoreContext#time=. */
    DefX509Const(V_FLAG_NO_CHECK_TIME);
#endif

    /* Set by Store#purpose=. SSL/TLS client. */
    DefX509Const(PURPOSE_SSL_CLIENT);
    /* Set by Store#purpose=. SSL/TLS server. */
    DefX509Const(PURPOSE_SSL_SERVER);
    /* Set by Store#purpose=. Netscape SSL server. */
    DefX509Const(PURPOSE_NS_SSL_SERVER);
    /* Set by Store#purpose=. S/MIME signing. */
    DefX509Const(PURPOSE_SMIME_SIGN);
    /* Set by Store#purpose=. S/MIME encryption. */
    DefX509Const(PURPOSE_SMIME_ENCRYPT);
    /* Set by Store#purpose=. CRL signing */
    DefX509Const(PURPOSE_CRL_SIGN);
    /* Set by Store#purpose=. No checks. */
    DefX509Const(PURPOSE_ANY);
    /* Set by Store#purpose=. OCSP helper. */
    DefX509Const(PURPOSE_OCSP_HELPER);
    /* Set by Store#purpose=. Time stamps signer. */
    DefX509Const(PURPOSE_TIMESTAMP_SIGN);

    DefX509Const(TRUST_COMPAT);
    DefX509Const(TRUST_SSL_CLIENT);
    DefX509Const(TRUST_SSL_SERVER);
    DefX509Const(TRUST_EMAIL);
    DefX509Const(TRUST_OBJECT_SIGN);
    DefX509Const(TRUST_OCSP_SIGN);
    DefX509Const(TRUST_OCSP_REQUEST);
    DefX509Const(TRUST_TSA);

    DefX509Default(CERT_AREA, cert_area);
    DefX509Default(CERT_DIR, cert_dir);
    DefX509Default(CERT_FILE, cert_file);
    DefX509Default(CERT_DIR_ENV, cert_dir_env);
    DefX509Default(CERT_FILE_ENV, cert_file_env);
    DefX509Default(PRIVATE_DIR, private_dir);
}
