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
 * Interface describing `toWords`.
 */
interface ToWords {
	/**
	* Splits a double-precision floating-point number into a higher order word (unsigned 32-bit integer) and a lower order word (unsigned 32-bit integer).
	*
	* @param x - input value
	* @returns output array
	*
	* @example
	* var w = toWords( 3.14e201 );
	* // returns [ 1774486211, 2479577218 ]
	*/
	( x: number ): Array<number>;

	/**
	* Splits a double-precision floating-point number into a higher order word (unsigned 32-bit integer) and a lower order word (unsigned 32-bit integer) and assigns results to a provided output array.
	*
	* @param x - input value
	* @param out - output array
	* @param stride - output array stride
	* @param offset - output array index offset
	* @returns output array
	*
	* @example
	* var Uint32Array = require( `@stdlib/array/uint32` );
	*
	* var out = new Uint32Array( 2 );
	*
	* var w = toWords.assign( 3.14e201, out, 1, 0 );
	* // returns <Uint32Array>[ 1774486211, 2479577218 ]
	*
	* var bool = ( w === out );
	* // returns true
	*/
	assign( x: number, out: Collection, stride: number, offset: number ): Collection; // tslint-disable-line max-line-length
}

/**
* Splits a double-precision floating-point number into a higher order word (unsigned 32-bit integer) and a lower order word (unsigned 32-bit integer).
*
* @param x - input value
* @returns output array
*
* @example
* var w = toWords( 3.14e201 );
* // returns [ 1774486211, 2479577218 ]
*/
declare var toWords: ToWords;


// EXPORTS //

export = toWords;
