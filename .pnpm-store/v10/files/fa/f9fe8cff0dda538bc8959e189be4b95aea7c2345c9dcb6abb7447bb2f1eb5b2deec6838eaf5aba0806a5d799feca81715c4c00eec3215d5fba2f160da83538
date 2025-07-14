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

#include "stdlib/number/float64/base/from_words.h"
#include "stdlib/number/float64/base/to_words.h"
#include <stdint.h>

/**
* Creates a double-precision floating-point number from a higher order word and a lower order word.
*
* @param high   higher order word
* @param low    lower order word
* @param x      destination for double-precision floating-point number
*
* @example
* #include <stdint.h>
*
* uint32_t high = 1074339512;
* uint32_t low = 1374389535;
*
* double x;
* stdlib_base_float64_from_words( high, low, &x );
*/
void stdlib_base_float64_from_words( const uint32_t high, const uint32_t low, double *x ) {
	stdlib_base_float64_words_t w;
	w.words.high = high;
	w.words.low = low;
	*x = w.value;
}
