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

/**
* 64-bit complex number.
*/
declare class Complex64 {
	/**
	* 64-bit complex number constructor.
	*
	* @param real - real component
	* @param imag - imaginary component
	* @returns 64-bit complex number
	*
	* @example
	* var z = new Complex64( 5.0, 3.0 );
	* // returns <Complex64>
	*/
	constructor( real: number, imag: number );

	/**
	* Read-only property returning the real component.
	*
	* @returns real component
	*/
	readonly re: number;

	/**
	* Read-only property returning the imaginary component.
	*
	* @returns imaginary component
	*/
	readonly im: number;

	/**
	* Size (in bytes) of each component.
	*
	* @returns size of each component
	*
	* @example
	* var nbytes = Complex64.BYTES_PER_ELEMENT;
	* // returns 4
	*/
	readonly BYTES_PER_ELEMENT: 4;

	/**
	* Length (in bytes) of a complex number.
	*
	* @returns byte length
	*
	* @example
	* var z = new Complex64( 5.0, 3.0 );
	*
	* var nbytes = z.byteLength;
	* // returns 8
	*/
	readonly byteLength: 8;

	/**
	* Serializes a complex number as a string.
	*
	* @returns serialized complex number
	*
	* @example
	* var z = new Complex64( 5.0, 3.0 );
	*
	* var str = z.toString();
	* // returns '5 + 3i'
	*/
	toString(): string;

	/**
	* Serializes a complex number as a JSON object.
	*
	* ## Notes
	*
	* -   `JSON.stringify()` implicitly calls this method when stringifying a `Complex64` instance.
	*
	*
	* @returns serialized complex number
	*
	* @example
	* var z = new Complex64( 5.0, 3.0 );
	*
	* var obj = z.toJSON();
	* // returns { 'type': 'Complex64', 're': 5.0, 'im': 3.0 }
	*/
	toJSON(): any;
}


// EXPORTS //

export = Complex64;
