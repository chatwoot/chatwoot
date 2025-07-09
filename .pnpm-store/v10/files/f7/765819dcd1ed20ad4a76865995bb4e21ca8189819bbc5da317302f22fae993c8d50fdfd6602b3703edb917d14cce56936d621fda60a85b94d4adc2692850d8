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

#include "stdlib/number/float64/base/to_words.h"
#include <stdint.h>

/**
* Splits a double-precision floating-point number into a higher order word and a lower order word.
*
* @param x      input value
* @param high   destination for higher order word
* @param low    destination for lower order word
*
* @example
* #include <stdint.h>
*
* uint32_t high;
* uint32_t low;
*
* stdlib_base_float64_to_words( 3.14, &high, &low );
*/
void stdlib_base_float64_to_words( const double x, uint32_t *high, uint32_t *low ) {
	stdlib_base_float64_words_t w;
	w.value = x;
	*high = w.words.high;
	*low = w.words.low;
}
