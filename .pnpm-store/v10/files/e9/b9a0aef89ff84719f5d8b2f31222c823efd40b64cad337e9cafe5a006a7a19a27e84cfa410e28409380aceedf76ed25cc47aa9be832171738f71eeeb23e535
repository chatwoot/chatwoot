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

var isNumber = require( '@stdlib/assert-is-number' ).isPrimitive;
var defineProperty = require( '@stdlib/utils-define-property' );
var setReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );
var float64ToFloat32 = require( '@stdlib/number-float64-base-to-float32' );
var toStr = require( './tostring.js' );
var toJSON = require( './tojson.js' );


// MAIN //

/**
* 64-bit complex number constructor.
*
* @constructor
* @param {number} real - real component
* @param {number} imag - imaginary component
* @throws {TypeError} must invoke using the `new` keyword
* @throws {TypeError} real component must be a number primitive
* @throws {TypeError} imaginary component must be a number primitive
* @returns {Complex64} 64-bit complex number
*
* @example
* var z = new Complex64( 5.0, 3.0 );
* // returns <Complex64>
*/
function Complex64( real, imag ) {
	if ( !( this instanceof Complex64 ) ) {
		throw new TypeError( 'invalid invocation. Constructor must be called with the `new` keyword.' );
	}
	if ( !isNumber( real ) ) {
		throw new TypeError( 'invalid argument. Real component must be a number primitive. Value: `'+real+'`.' );
	}
	if ( !isNumber( imag ) ) {
		throw new TypeError( 'invalid argument. Imaginary component must be a number primitive. Value: `'+imag+'`.' );
	}
	defineProperty( this, 're', {
		'configurable': false,
		'enumerable': true,
		'writable': false,
		'value': float64ToFloat32( real )
	});
	defineProperty( this, 'im', {
		'configurable': false,
		'enumerable': true,
		'writable': false,
		'value': float64ToFloat32( imag )
	});
	return this;
}

/**
* Size (in bytes) of each component.
*
* @name BYTES_PER_ELEMENT
* @memberof Complex64
* @type {integer}
* @returns {integer} size of each component
*
* @example
* var nbytes = Complex64.BYTES_PER_ELEMENT;
* // returns 4
*/
setReadOnly( Complex64, 'BYTES_PER_ELEMENT', 4 );

/**
* Size (in bytes) of each component.
*
* @name BYTES_PER_ELEMENT
* @memberof Complex64.prototype
* @type {integer}
* @returns {integer} size of each component
*
* @example
* var z = new Complex64( 5.0, 3.0 );
*
* var nbytes = z.BYTES_PER_ELEMENT;
* // returns 4
*/
setReadOnly( Complex64.prototype, 'BYTES_PER_ELEMENT', 4 );

/**
* Length (in bytes) of a complex number.
*
* @name byteLength
* @memberof Complex64.prototype
* @type {integer}
* @returns {integer} byte length
*
* @example
* var z = new Complex64( 5.0, 3.0 );
*
* var nbytes = z.byteLength;
* // returns 8
*/
setReadOnly( Complex64.prototype, 'byteLength', 8 );

/**
* Serializes a complex number as a string.
*
* @name toString
* @memberof Complex64.prototype
* @type {Function}
* @returns {string} serialized complex number
*
* @example
* var z = new Complex64( 5.0, 3.0 );
*
* var str = z.toString();
* // returns '5 + 3i'
*/
setReadOnly( Complex64.prototype, 'toString', toStr );

/**
* Serializes a complex number as a JSON object.
*
* ## Notes
*
* -   `JSON.stringify()` implicitly calls this method when stringifying a `Complex64` instance.
*
*
* @name toJSON
* @memberof Complex64.prototype
* @type {Function}
* @returns {Object} serialized complex number
*
* @example
* var z = new Complex64( 5.0, 3.0 );
*
* var obj = z.toJSON();
* // returns { 'type': 'Complex64', 're': 5.0, 'im': 3.0 }
*/
setReadOnly( Complex64.prototype, 'toJSON', toJSON );


// EXPORTS //

module.exports = Complex64;
