/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#if !defined(_OSSL_PKCS7_H_)
#define _OSSL_PKCS7_H_

#define NewPKCS7(klass) \
    TypedData_Wrap_Struct((klass), &ossl_pkcs7_type, 0)
#define SetPKCS7(obj, pkcs7) do { \
    if (!(pkcs7)) { \
        ossl_raise(rb_eRuntimeError, "PKCS7 wasn't initialized."); \
    } \
    RTYPEDDATA_DATA(obj) = (pkcs7); \
} while (0)
#define GetPKCS7(obj, pkcs7) do { \
    TypedData_Get_Struct((obj), PKCS7, &ossl_pkcs7_type, (pkcs7)); \
    if (!(pkcs7)) { \
        ossl_raise(rb_eRuntimeError, "PKCS7 wasn't initialized."); \
    } \
} while (0)

extern const rb_data_type_t ossl_pkcs7_type;
extern VALUE cPKCS7;
extern VALUE cPKCS7Signer;
extern VALUE cPKCS7Recipient;
extern VALUE ePKCS7Error;

void Init_ossl_pkcs7(void);

#endif /* _OSSL_PKCS7_H_ */
