/**
* @license Apache-2.0
*
* Copyright (c) 2020 The Stdlib Authors.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#ifndef STDLIB_OS_BYTE_ORDER_H
#define STDLIB_OS_BYTE_ORDER_H

/*
* The following attempts to determine the byte ordering of the host platform.
*
* The results are stored in the following macros:
*
* -   `STDLIB_OS_ORDER_LITTLE_ENDIAN`: an arbitrary constant.
* -   `STDLIB_OS_ORDER_BIG_ENDIAN`: an arbitrary constant.
* -   `STDLIB_OS_BYTE_ORDER`: either `STDLIB_OS_ORDER_LITTLE_ENDIAN` or `STDLIB_OS_ORDER_BIG_ENDIAN` or host defined.
*/

// The GNU preprocessor and Clang define macros for endianness (see http://gcc.gnu.org/onlinedocs/cpp/Common-Predefined-Macros.html#Common-Predefined-Macros):
#if defined(__ORDER_LITTLE_ENDIAN__) && defined(__ORDER_BIG_ENDIAN__) && defined(__BYTE_ORDER__)

#define STDLIB_OS_ORDER_BIG_ENDIAN     __ORDER_BIG_ENDIAN__
#define STDLIB_OS_ORDER_LITTLE_ENDIAN  __ORDER_LITTLE_ENDIAN__
#define STDLIB_OS_BYTE_ORDER           __BYTE_ORDER__

// If not defined by the preprocessor, we need to try to do it ourselves...

// GNU C Library (GLIBC) - Linux, GNU/kFreeBSD, GNU/Hurd, etc.
#elif defined(__GLIBC__)

#include <features.h>
#include <endian.h>
#define STDLIB_OS_ORDER_LITTLE_ENDIAN  __LITTLE_ENDIAN
#define STDLIB_OS_ORDER_BIG_ENDIAN     __BIG_ENDIAN
#define STDLIB_OS_BYTE_ORDER           __BYTE_ORDER

// OSX
#elif defined(__APPLE__)

#include <machine/endian.h>
#define STDLIB_OS_ORDER_LITTLE_ENDIAN  LITTLE_ENDIAN
#define STDLIB_OS_ORDER_BIG_ENDIAN     BIG_ENDIAN
#define STDLIB_OS_BYTE_ORDER           BYTE_ORDER

// FreeBSD
#elif defined(__FreeBSD__)

#include <machine/endian.h>
#define STDLIB_OS_ORDER_LITTLE_ENDIAN  _LITTLE_ENDIAN
#define STDLIB_OS_ORDER_BIG_ENDIAN     _BIG_ENDIAN
#define STDLIB_OS_BYTE_ORDER           _BYTE_ORDER

// Windows
#elif defined(_WIN32)

#define STDLIB_OS_ORDER_LITTLE_ENDIAN  1234
#define STDLIB_OS_ORDER_BIG_ENDIAN     4321
#define STDLIB_OS_BYTE_ORDER           STDLIB_OS_ORDER_LITTLE_ENDIAN

// Solaris
#elif defined(__sun)

#define STDLIB_OS_ORDER_LITTLE_ENDIAN  1234
#define STDLIB_OS_ORDER_BIG_ENDIAN     4321

#include <sys/isa_defs.h>
#ifdef _LITTLE_ENDIAN
#define STDLIB_OS_BYTE_ORDER  STDLIB_OS_ORDER_LITTLE_ENDIAN
#endif
#ifdef _BIG_ENDIAN
#define STDLIB_OS_BYTE_ORDER  STDLIB_OS_ORDER_BIG_ENDIAN
#endif

#endif // __BYTE_ORDER__, __ORDER_LITTLE_ENDIAN__, and __ORDER_BIG_ENDIAN__

#endif // !STDLIB_OS_BYTE_ORDER_H

