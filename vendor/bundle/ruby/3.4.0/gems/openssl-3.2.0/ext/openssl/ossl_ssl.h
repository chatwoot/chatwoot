/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#if !defined(_OSSL_SSL_H_)
#define _OSSL_SSL_H_

#define GetSSL(obj, ssl) do { \
	TypedData_Get_Struct((obj), SSL, &ossl_ssl_type, (ssl)); \
	if (!(ssl)) { \
		ossl_raise(rb_eRuntimeError, "SSL is not initialized"); \
	} \
} while (0)

#define GetSSLSession(obj, sess) do { \
	TypedData_Get_Struct((obj), SSL_SESSION, &ossl_ssl_session_type, (sess)); \
	if (!(sess)) { \
		ossl_raise(rb_eRuntimeError, "SSL Session wasn't initialized."); \
	} \
} while (0)

extern const rb_data_type_t ossl_ssl_type;
extern const rb_data_type_t ossl_ssl_session_type;
extern VALUE mSSL;
extern VALUE cSSLSocket;
extern VALUE cSSLSession;

void Init_ossl_ssl(void);
void Init_ossl_ssl_session(void);

#endif /* _OSSL_SSL_H_ */
