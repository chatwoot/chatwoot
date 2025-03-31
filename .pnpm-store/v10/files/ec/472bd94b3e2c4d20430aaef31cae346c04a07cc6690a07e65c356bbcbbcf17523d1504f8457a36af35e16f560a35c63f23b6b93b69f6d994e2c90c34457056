/*
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

// TypeScript Version: 2.0

/// <reference types="@stdlib/types"/>

import { Collection } from '@stdlib/types/object';

/**
 * Interface describing `normalize`.
 */
interface Normalize {
	/**
	* Returns a normal number `y` and exponent `exp` satisfying \\(x = y \cdot 2^\mathrm{exp}\\).
	*
	* ## Notes
	*
	* -   The first element of the returned array corresponds to `y` and the second element to `exp`.
	*
	* @param x - input value
	* @returns output array
	*
	* @example
	* var pow = require( `@stdlib/math/base/special/pow` );
	*
	* var out = normalize( 3.14e-319 );
	* // returns <Float64Array>[ 1.4141234400356668e-303, -52 ]
	*
	* var y = out[ 0 ];
	* var exponent = out[ 1 ];
	*
	* var bool = ( y*pow(2.0, exponent) === 3.14e-319 );
	* // returns true
	*
	* @example
	* var out = normalize( 0.0 );
	* // returns [ 0.0, 0 ]
	*
	* @example
	* var PINF = require( '@stdlib/constants-float64-pinf' );
	*
	* var out = normalize( PINF );
	* // returns [ Infinity, 0 ]
	*
	* @example
	* var NINF = require( '@stdlib/constants-float64-ninf' );
	*
	* var out = normalize( NINF );
	* // returns [ -Infinity, 0 ]
	*
	* @example
	* var out = normalize( NaN );
	* // returns [ NaN, 0 ]
	*/
	( x: number ): Array<number>;

	/**
	* Returns a normal number and exponent satisfying `x = y * 2^exp` and assigns results to a provided output array.
	*
	* ## Notes
	*
	* -   The first element of the returned array corresponds to `y` and the second element to `exp`.
	*
	* @param x - input value
	* @param out - output array
	* @param stride - output array stride
	* @param offset - output array index offset
	* @returns output array
	*
	* @example
	* var out = new Float64Array( 2 );
	*
	* var v = normalize.assign( 3.14e-319, out, 1, 0 );
	* // returns <Float64Array>[ 1.4141234400356668e-303, -52 ]
	*
	* var bool = ( v === out );
	* // returns true
	*/
	assign( x: number, out: Collection, stride: number, offset: number ): Collection; // tslint-disable-line max-line-length
}

/**
* Returns a normal number `y` and exponent `exp` satisfying \\(x = y \cdot 2^\mathrm{exp}\\).
*
* ## Notes
*
* -   The first element of the returned array corresponds to `y` and the second to `exp`.
*
* @param x - input value
* @returns output array
*
* @example
* var pow = require( `@stdlib/math/base/special/pow` );
*
* var out = normalize( 3.14e-319 );
* // returns <Float64Array>[ 1.4141234400356668e-303, -52 ]
*
* var y = out[ 0 ];
* var exponent = out[ 1 ];
*
* var bool = ( y*pow(2.0, exponent) === 3.14e-319 );
* // returns true
*/
declare var normalize: Normalize;


// EXPORTS //

export = normalize;
