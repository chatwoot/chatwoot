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

#ifndef STDLIB_NUMBER_FLOAT64_BASE_TO_WORDS_H
#define STDLIB_NUMBER_FLOAT64_BASE_TO_WORDS_H

#include "stdlib/os/float_word_order.h"
#include "stdlib/os/byte_order.h"
#include <stdint.h>

/*
* If C++, prevent name mangling so that the compiler emits a binary file having undecorated names, thus mirroring the behavior of a C compiler.
*/
#ifdef __cplusplus
extern "C" {
#endif

/**
* An opaque type definition for a union for converting between a double-precision floating-point number and two unsigned 32-bit integers.
*
* @example
* #include <stdint.h>
*
* stdlib_base_float64_words_t w;
*
* // Assign a double-precision floating-point number:
* w.value = 3.14;
*
* // Extract the high and low words:
* uint32_t high = w.words.high;
* uint32_t low = w.words.low;
*/
typedef union {
	double value;
	struct {
#if STDLIB_OS_FLOAT_WORD_ORDER == STDLIB_OS_ORDER_LITTLE_ENDIAN
		uint32_t low;
		uint32_t high;
#elif STDLIB_OS_FLOAT_WORD_ORDER == STDLIB_OS_ORDER_BIG_ENDIAN
		uint32_t high;
		uint32_t low;
#endif
	} words;
} stdlib_base_float64_words_t;


/**
* Splits a double-precision floating-point number into a higher order word and a lower order word.
*/
void stdlib_base_float64_to_words( const double x, uint32_t *high, uint32_t *low );

#ifdef __cplusplus
}
#endif

#endif // !STDLIB_NUMBER_FLOAT64_BASE_TO_WORDS_H
