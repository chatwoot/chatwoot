/*
 * Written by Solar Designer <solar at openwall.com> in 2000-2002.
 * No copyright is claimed, and the software is hereby placed in the public
 * domain.  In case this attempt to disclaim copyright and place the software
 * in the public domain is deemed null and void, then the software is
 * Copyright (c) 2000-2002 Solar Designer and it is hereby released to the
 * general public under the following terms:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted.
 *
 * There's ABSOLUTELY NO WARRANTY, express or implied.
 *
 * See crypt_blowfish.c for more information.
 */

#include <gnu-crypt.h>

#if defined(_OW_SOURCE) || defined(__USE_OW)
#define __SKIP_GNU
#undef __SKIP_OW
#include <ow-crypt.h>
#undef __SKIP_GNU
#endif
