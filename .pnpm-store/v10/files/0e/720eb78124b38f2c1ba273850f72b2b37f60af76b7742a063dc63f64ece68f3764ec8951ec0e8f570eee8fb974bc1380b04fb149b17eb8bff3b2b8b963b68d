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

#ifndef STDLIB_COMPLEX_FLOAT64_H
#define STDLIB_COMPLEX_FLOAT64_H

#include "stdlib/complex/float32.h"
#include <complex.h>
#include <stdint.h>

/*
* If C++, prevent name mangling so that the compiler emits a binary file having undecorated names, thus mirroring the behavior of a C compiler.
*/
#ifdef __cplusplus
extern "C" {
#endif

// Check for C11 support where we can precisely define a complex number and thus avoid issues concerning infinities and NaNs as real and/or imaginary components... (TODO: revisit the following check; similar to NumPy, we may want to check for a compile time variable (e.g., STDLIB_USE_C99_COMPLEX), rather than checking for C11 support, especially if we are not using C11 functionality)
#if defined(_Imaginary_I) && defined(CMPLX)

/**
* An opaque type definition for a double-precision complex floating-point number.
*/
typedef double complex stdlib_complex128_t;

// If we aren't going to use the native complex number type, we need to define a complex number as an "opaque" struct (here, "opaque" meaning type consumers should **not** be accessing the components directly, but only through dedicated functions) for storing the real and imaginary components...
#else

/**
* An opaque type definition for a double-precision complex floating-point number.
*
* @example
* stdlib_complex128_t z;
*
* // Set the real component:
* z.re = 5.0;
*
* // Set the imaginary component:
* z.im = 2.0;
*/
typedef struct {
	/**
	* Real component.
	*/
	double re;

	/**
	* Imaginary component.
	*/
	double im;
} stdlib_complex128_t;

#endif

/**
* An opaque type definition for a union for accessing the real and imaginary parts of a double-precision complex floating-point number.
*
* @example
* double real( const stdlib_complex128_t z ) {
*     stdlib_complex128_parts_t v;
*
*     // Assign a double-precision complex floating-point number:
*     v.value = z;
*
*     // Extract the real component:
*     double re = v.parts[ 0 ];
*
*     return re;
* }
*
* // ...
*
* // Create a complex number:
* stdlib_complex128_t z = stdlib_complex128( 5.0, 2.0 );
*
* // ...
*
* // Access the real component:
* double re = real( z );
* // returns 5.0
*/
typedef union {
	// An opaque type for the output value (e.g., could be a `struct` or a C99 complex number):
	stdlib_complex128_t value;

	// Leverage the fact that C99 specifies that complex numbers have the same representation and alignment as a two-element array (see <https://en.cppreference.com/w/c/language/arithmetic_types#Complex_floating_types>), where the first element is the real component and the second element is the imaginary component, thus allowing us to create a complex number irrespective of its native data type (e.g., `struct` vs `double complex`):
	double parts[ 2 ];
} stdlib_complex128_parts_t;

/**
* Returns a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128( const double real, const double imag );

/**
* Converts a single-precision floating-point number to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_float32( const float real );

/**
* Converts a double-precision floating-point number to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_float64( const double real );

/**
* Converts a single-precision complex floating-point number to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_complex64( const stdlib_complex64_t z );

/**
* Converts (copies) a double-precision complex floating-point number to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_complex128( const stdlib_complex128_t z );

/**
* Converts a signed 8-bit integer to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_int8( const int8_t real );

/**
* Converts an unsigned 8-bit integer to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_uint8( const uint8_t real );

/**
* Converts a signed 16-bit integer to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_int16( const int16_t real );

/**
* Converts an unsigned 16-bit integer to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_uint16( const uint16_t real );

/**
* Converts a signed 32-bit integer to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_int32( const int32_t real );

/**
* Converts an unsigned 32-bit integer to a double-precision complex floating-point number.
*/
stdlib_complex128_t stdlib_complex128_from_uint32( const uint32_t real );

/**
* Converts a double-precision complex floating-point number to a single-precision complex floating-point number.
*/
stdlib_complex64_t stdlib_complex128_to_complex64( const stdlib_complex128_t z );

#ifdef __cplusplus
}
#endif

#endif // !STDLIB_COMPLEX_FLOAT64_H
