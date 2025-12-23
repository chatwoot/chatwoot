#ifndef _DIGEST_COMPAT_RUBY_H_
#define _DIGEST_COMPAT_RUBY_H_

#include <ruby.h>

// HACK: define USHORT2NUM for Ruby < 2.6
#ifndef USHORT2NUM
#define USHORT2NUM(x) RB_INT2FIX(x)
#endif

#endif
