/**
* @license Apache-2.0
*
* Copyright (c) 2021 The Stdlib Authors.
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

#include "stdlib/complex/reim.h"
#include "stdlib/complex/float64.h"

/**
* Returns the real and imaginary components of a double-precision complex floating-point number.
*
* @param z     double-precision complex floating-point number
* @param re    destination for real component
* @param im    destination for imaginary component
*
* @example
* #include "stdlib/complex/float64.h"
*
* stdlib_complex128_t z = stdlib_complex128( 5.0, 2.0 );
*
* // ...
*
* double re;
* double im;
*
* stdlib_reim( z, &re, &im );
*/
void stdlib_reim( const stdlib_complex128_t z, double *re, double *im ) {
	stdlib_complex128_parts_t v;
	v.value = z; // cppcheck-suppress unreadVariable
	*re = v.parts[ 0 ];
	*im = v.parts[ 1 ];
}
