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

#ifndef STDLIB_OS_FLOAT_WORD_ORDER_H
#define STDLIB_OS_FLOAT_WORD_ORDER_H

#include "stdlib/os/byte_order.h"

// The GNU preprocessor and Clang define macros for float word order (see http://gcc.gnu.org/onlinedocs/cpp/Common-Predefined-Macros.html#Common-Predefined-Macros):
#ifdef __FLOAT_WORD_ORDER__

#define STDLIB_OS_FLOAT_WORD_ORDER  __FLOAT_WORD_ORDER__

// If not defined by the preprocessor, we need to try to do it ourselves...

#elif defined(STDLIB_OS_BYTE_ORDER)

#define STDLIB_OS_FLOAT_WORD_ORDER  STDLIB_OS_BYTE_ORDER

#endif

#endif // !STDLIB_OS_FLOAT_WORD_ORDER_H

