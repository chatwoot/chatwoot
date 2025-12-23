/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#if !defined(_OSSL_BN_H_)
#define _OSSL_BN_H_

extern VALUE cBN;
extern VALUE eBNError;

BN_CTX *ossl_bn_ctx_get(void);
#define ossl_bn_ctx ossl_bn_ctx_get()

#define GetBNPtr(obj) ossl_bn_value_ptr(&(obj))

VALUE ossl_bn_new(const BIGNUM *);
BIGNUM *ossl_bn_value_ptr(volatile VALUE *);
void Init_ossl_bn(void);


#endif /* _OSS_BN_H_ */
