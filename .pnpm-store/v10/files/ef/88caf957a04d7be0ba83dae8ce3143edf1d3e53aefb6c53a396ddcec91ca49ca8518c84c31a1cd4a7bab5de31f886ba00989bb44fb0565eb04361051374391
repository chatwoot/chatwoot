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

#include "stdlib/complex/float32.h"
#include <stdint.h>

/**
* Returns a single-precision complex floating-point number.
*
* @param real     real component
* @param imag     imaginary component
* @return         single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z = stdlib_complex64( 5.0f, 2.0f );
*/
stdlib_complex64_t stdlib_complex64( const float real, const float imag ) {
	stdlib_complex64_parts_t z;
	z.parts[ 0 ] = real;
	z.parts[ 1 ] = imag; // cppcheck-suppress unreadVariable
	return z.value;
}

/**
* Converts a single-precision floating-point number to a single-precision complex floating-point number.
*
* @param real    real component
* @return        single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z = stdlib_complex64_from_float32( 5.0f );
*/
stdlib_complex64_t stdlib_complex64_from_float32( const float real ) {
	stdlib_complex64_parts_t z;
	z.parts[ 0 ] = real;
	z.parts[ 1 ] = 0.0f; // cppcheck-suppress unreadVariable
	return z.value;
}

/**
* Converts a double-precision floating-point number to a single-precision complex floating-point number.
*
* @param real    real component
* @return        single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z = stdlib_complex64_from_float64( 5.0 );
*/
stdlib_complex64_t stdlib_complex64_from_float64( const double real ) {
	stdlib_complex64_parts_t z;
	z.parts[ 0 ] = (float)real;
	z.parts[ 1 ] = 0.0f; // cppcheck-suppress unreadVariable
	return z.value;
}

/**
* Converts (copies) a single-precision complex floating-point number to a single-precision complex floating-point number.
*
* @param z       single-precision complex floating-point number
* @return        single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z1 = stdlib_complex64( 5.0f, 3.0f );
* stdlib_complex64_t z2 = stdlib_complex64_from_complex64( z1 );
*/
stdlib_complex64_t stdlib_complex64_from_complex64( const stdlib_complex64_t z ) {
	stdlib_complex64_parts_t v1 = { z };
	stdlib_complex64_parts_t v2;
	v2.parts[ 0 ] = v1.parts[ 0 ];
	v2.parts[ 1 ] = v1.parts[ 1 ]; // cppcheck-suppress unreadVariable
	return v2.value;
}

/**
* Converts a signed 8-bit integer to a single-precision complex floating-point number.
*
* @param real    real component
* @return        single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z = stdlib_complex64_from_int8( 5 );
*/
stdlib_complex64_t stdlib_complex64_from_int8( const int8_t real ) {
	stdlib_complex64_parts_t z;
	z.parts[ 0 ] = (float)real;
	z.parts[ 1 ] = 0.0f; // cppcheck-suppress unreadVariable
	return z.value;
}

/**
* Converts an unsigned 8-bit integer to a single-precision complex floating-point number.
*
* @param real    real component
* @return        single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z = stdlib_complex64_from_uint8( 5 );
*/
stdlib_complex64_t stdlib_complex64_from_uint8( const uint8_t real ) {
	stdlib_complex64_parts_t z;
	z.parts[ 0 ] = (float)real;
	z.parts[ 1 ] = 0.0f; // cppcheck-suppress unreadVariable
	return z.value;
}

/**
* Converts a signed 16-bit integer to a single-precision complex floating-point number.
*
* @param real    real component
* @return        single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z = stdlib_complex64_from_int16( 5 );
*/
stdlib_complex64_t stdlib_complex64_from_int16( const int16_t real ) {
	stdlib_complex64_parts_t z;
	z.parts[ 0 ] = (float)real;
	z.parts[ 1 ] = 0.0f; // cppcheck-suppress unreadVariable
	return z.value;
}

/**
* Converts an unsigned 16-bit integer to a single-precision complex floating-point number.
*
* @param real    real component
* @return        single-precision complex floating-point number
*
* @example
* stdlib_complex64_t z = stdlib_complex64_from_uint16( 5 );
*/
stdlib_complex64_t stdlib_complex64_from_uint16( const uint16_t real ) {
	stdlib_complex64_parts_t z;
	z.parts[ 0 ] = (float)real;
	z.parts[ 1 ] = 0.0f; // cppcheck-suppress unreadVariable
	return z.value;
}
