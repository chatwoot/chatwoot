/**
* @license Apache-2.0
*
* Copyright (c) 2022 The Stdlib Authors.
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

#include "stdlib/number/float64/base/normalize.h"
#include "stdlib/constants/float64/smallest_normal.h"
#include "stdlib/math/base/assert/is_infinite.h"
#include "stdlib/math/base/assert/is_nan.h"
#include "stdlib/math/base/special/abs.h"
#include <stdint.h>

// (1<<52)
static const double SCALAR = 4503599627370496.0;

/**
* Extracts a normal number y and exponent exp satisfying x = y * 2^exp.
*
* @private
* @param x        input value
* @param y        Normal number
* @param exp      Exponent
*
* @example
* #include <stdint.h>
*
* double x = 1.0;
* double y;
* int32_t exp;
*
* stdlib_base_float64_normalize( x, &y, &exp );
*/
void stdlib_base_float64_normalize( const double x, double *y, int32_t *exp ) {
	if ( stdlib_base_is_nan( x ) || stdlib_base_is_infinite( x ) ) {
		*y = x;
		*exp = 0;
		return;
	}
	if ( x != 0 && stdlib_base_abs( x ) < STDLIB_CONSTANT_FLOAT64_SMALLEST_NORMAL ) {
		*y = x * SCALAR;
		*exp = -52;
		return;
	}
	*y = x;
	*exp = 0;
	return;
}
