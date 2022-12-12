/**
* @license Apache-2.0
*
* Copyright (c) 2018 The Stdlib Authors.
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

var Float64Array = require( '@stdlib/array-float64' );


// MAIN //

/**
* Returns the real and imaginary components of a double-precision complex floating-point number.
*
* @param {Complex128} z - complex number
* @returns {Float64Array} real and imaginary components
*
* @example
* var Complex128 = require( '@stdlib/complex-float64' );
*
* var z = new Complex128( 5.0, 3.0 );
*
* var out = reim( z );
* // returns <Float64Array>[ 5.0, 3.0 ]
*/
function reim( z ) {
	var out = new Float64Array( 2 );
	out[ 0 ] = z.re;
	out[ 1 ] = z.im;
	return out;
}


// EXPORTS //

module.exports = reim;
