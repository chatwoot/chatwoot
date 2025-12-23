/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#include RUBY_EXTCONF_H

#include <string.h> /* memcpy() */
#include <openssl/x509_vfy.h>

#include "openssl_missing.h"

/*** added in 1.1.0 ***/
#if !defined(HAVE_X509_CRL_GET0_SIGNATURE)
void
ossl_X509_CRL_get0_signature(const X509_CRL *crl, const ASN1_BIT_STRING **psig,
			     const X509_ALGOR **palg)
{
    if (psig != NULL)
	*psig = crl->signature;
    if (palg != NULL)
	*palg = crl->sig_alg;
}
#endif

#if !defined(HAVE_X509_REQ_GET0_SIGNATURE)
void
ossl_X509_REQ_get0_signature(const X509_REQ *req, const ASN1_BIT_STRING **psig,
			     const X509_ALGOR **palg)
{
    if (psig != NULL)
	*psig = req->signature;
    if (palg != NULL)
	*palg = req->sig_alg;
}
#endif
