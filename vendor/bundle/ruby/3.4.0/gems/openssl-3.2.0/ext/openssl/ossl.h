/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#if !defined(_OSSL_H_)
#define _OSSL_H_

#include RUBY_EXTCONF_H

#include <assert.h>
#include <ruby.h>
#include <errno.h>
#include <ruby/io.h>
#include <ruby/thread.h>
#include <openssl/opensslv.h>

#include <openssl/err.h>
#include <openssl/asn1.h>
#include <openssl/x509v3.h>
#include <openssl/ssl.h>
#include <openssl/pkcs12.h>
#include <openssl/pkcs7.h>
#include <openssl/rand.h>
#include <openssl/conf.h>
#ifndef OPENSSL_NO_TS
  #include <openssl/ts.h>
#endif
#include <openssl/crypto.h>
#if !defined(OPENSSL_NO_OCSP)
#  include <openssl/ocsp.h>
#endif
#include <openssl/bn.h>
#include <openssl/rsa.h>
#include <openssl/dsa.h>
#include <openssl/evp.h>
#include <openssl/dh.h>

#ifndef LIBRESSL_VERSION_NUMBER
# define OSSL_IS_LIBRESSL 0
# define OSSL_OPENSSL_PREREQ(maj, min, pat) \
      (OPENSSL_VERSION_NUMBER >= ((maj << 28) | (min << 20) | (pat << 12)))
# define OSSL_LIBRESSL_PREREQ(maj, min, pat) 0
#else
# define OSSL_IS_LIBRESSL 1
# define OSSL_OPENSSL_PREREQ(maj, min, pat) 0
# define OSSL_LIBRESSL_PREREQ(maj, min, pat) \
      (LIBRESSL_VERSION_NUMBER >= ((maj << 28) | (min << 20) | (pat << 12)))
#endif

#if OSSL_OPENSSL_PREREQ(3, 0, 0)
# define OSSL_3_const const
#else
# define OSSL_3_const /* const */
#endif

#if !defined(OPENSSL_NO_ENGINE) && !OSSL_OPENSSL_PREREQ(3, 0, 0)
# define OSSL_USE_ENGINE
#endif

#if OSSL_OPENSSL_PREREQ(3, 0, 0)
# define OSSL_USE_PROVIDER
#endif

/*
 * Common Module
 */
extern VALUE mOSSL;

/*
 * Common Error Class
 */
extern VALUE eOSSLError;

/*
 * CheckTypes
 */
#define OSSL_Check_Kind(obj, klass) do {\
  if (!rb_obj_is_kind_of((obj), (klass))) {\
    ossl_raise(rb_eTypeError, "wrong argument (%"PRIsVALUE")! (Expected kind of %"PRIsVALUE")",\
               rb_obj_class(obj), (klass));\
  }\
} while (0)

/*
 * Type conversions
 */
#if !defined(NUM2UINT64T) /* in case Ruby starts to provide */
#  if SIZEOF_LONG == 8
#    define NUM2UINT64T(x) ((uint64_t)NUM2ULONG(x))
#  elif defined(HAVE_LONG_LONG) && SIZEOF_LONG_LONG == 8
#    define NUM2UINT64T(x) ((uint64_t)NUM2ULL(x))
#  else
#    error "unknown platform; no 64-bit width integer"
#  endif
#endif

/*
 * Data Conversion
 */
STACK_OF(X509) *ossl_x509_ary2sk(VALUE);
STACK_OF(X509) *ossl_protect_x509_ary2sk(VALUE,int*);
VALUE ossl_x509_sk2ary(const STACK_OF(X509) *certs);
VALUE ossl_x509crl_sk2ary(const STACK_OF(X509_CRL) *crl);
VALUE ossl_x509name_sk2ary(const STACK_OF(X509_NAME) *names);
VALUE ossl_buf2str(char *buf, int len);
VALUE ossl_str_new(const char *, long, int *);
#define ossl_str_adjust(str, p) \
do{\
    long newlen = (long)((p) - (unsigned char*)RSTRING_PTR(str));\
    assert(newlen <= RSTRING_LEN(str));\
    rb_str_set_len((str), newlen);\
}while(0)
/*
 * Convert binary string to hex string. The caller is responsible for
 * ensuring out has (2 * len) bytes of capacity.
 */
void ossl_bin2hex(unsigned char *in, char *out, size_t len);

/*
 * Our default PEM callback
 */
/* Convert the argument to String and validate the length. Note this may raise. */
VALUE ossl_pem_passwd_value(VALUE);
/* Can be casted to pem_password_cb. If a password (String) is passed as the
 * "arbitrary data" (typically the last parameter of PEM_{read,write}_
 * functions), uses the value. If not, but a block is given, yields to it.
 * If not either, fallbacks to PEM_def_callback() which reads from stdin. */
int ossl_pem_passwd_cb(char *, int, int, void *);

/*
 * Clear BIO* with this in PEM/DER fallback scenarios to avoid decoding
 * errors piling up in OpenSSL::Errors
 */
#define OSSL_BIO_reset(bio) do { \
    (void)BIO_reset((bio)); \
    ossl_clear_error(); \
} while (0)

/*
 * ERRor messages
 */
PRINTF_ARGS(NORETURN(void ossl_raise(VALUE, const char *, ...)), 2, 3);
/* Make exception instance from str and OpenSSL error reason string. */
VALUE ossl_make_error(VALUE exc, VALUE str);
/* Clear OpenSSL error queue. If dOSSL is set, rb_warn() them. */
void ossl_clear_error(void);

/*
 * String to DER String
 */
VALUE ossl_to_der(VALUE);
VALUE ossl_to_der_if_possible(VALUE);

/*
 * Debug
 */
extern VALUE dOSSL;

#define OSSL_Debug(...) do { \
  if (dOSSL == Qtrue) { \
    fprintf(stderr, "OSSL_DEBUG: "); \
    fprintf(stderr, __VA_ARGS__); \
    fprintf(stderr, " [%s:%d]\n", __FILE__, __LINE__); \
  } \
} while (0)

/*
 * Include all parts
 */
#include "openssl_missing.h"
#include "ossl_asn1.h"
#include "ossl_bio.h"
#include "ossl_bn.h"
#include "ossl_cipher.h"
#include "ossl_config.h"
#include "ossl_digest.h"
#include "ossl_hmac.h"
#include "ossl_ns_spki.h"
#include "ossl_ocsp.h"
#include "ossl_pkcs12.h"
#include "ossl_pkcs7.h"
#include "ossl_pkey.h"
#include "ossl_rand.h"
#include "ossl_ssl.h"
#ifndef OPENSSL_NO_TS
  #include "ossl_ts.h"
#endif
#include "ossl_x509.h"
#include "ossl_engine.h"
#include "ossl_provider.h"
#include "ossl_kdf.h"

void Init_openssl(void);

#endif /* _OSSL_H_ */
