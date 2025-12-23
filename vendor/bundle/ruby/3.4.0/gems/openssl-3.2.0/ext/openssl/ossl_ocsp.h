/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2003  Michal Rokos <m.rokos@sh.cvut.cz>
 * Copyright (C) 2003  GOTOU Yuuzou <gotoyuzo@notwork.org>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#if !defined(_OSSL_OCSP_H_)
#define _OSSL_OCSP_H_

#if !defined(OPENSSL_NO_OCSP)
extern VALUE mOCSP;
extern VALUE cOCSPReq;
extern VALUE cOCSPRes;
extern VALUE cOCSPBasicRes;
#endif

void Init_ossl_ocsp(void);

#endif /* _OSSL_OCSP_H_ */
