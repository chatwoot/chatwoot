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

'use strict';

// MODULES //

var Float32Array = require( '@stdlib/array-float32' );


// MAIN //

/**
* Returns the real and imaginary components of a single-precision complex floating-point number.
*
* @param {Complex64} z - complex number
* @returns {Float32Array} real and imaginary components
*
* @example
* var Complex64 = require( '@stdlib/complex-float32' );
*
* var z = new Complex64( 5.0, 3.0 );
*
* var out = reimf( z );
* // returns <Float32Array>[ 5.0, 3.0 ]
*/
function reimf( z ) {
	var out = new Float32Array( 2 );
	out[ 0 ] = z.re;
	out[ 1 ] = z.im;
	return out;
}


// EXPORTS //

module.exports = reimf;
