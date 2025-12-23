/*
 * 'OpenSSL for Ruby' project
 * Copyright (C) 2001-2002  Michal Rokos <m.rokos@sh.cvut.cz>
 * All rights reserved.
 */
/*
 * This program is licensed under the same licence as Ruby.
 * (See the file 'LICENCE'.)
 */
#ifndef OSSL_CONFIG_H
#define OSSL_CONFIG_H

CONF *GetConfig(VALUE obj);
void Init_ossl_config(void);

#endif /* OSSL_CONFIG_H */
