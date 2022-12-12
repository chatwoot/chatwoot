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

var isFunction = require( '@stdlib/assert-is-function' );


// MAIN //

/**
* Browser shim.
*
* @private
* @param {(string|null)} [encoding] - string encoding
* @param {Callback} clbk - callback to be invoked upon completion
* @throws {TypeError} callback argument must be a function
*
* @example
* function onRead( error ) {
*     if ( error ) {
*         return console.error( error.message );
*     }
* }
*
* stdin( onRead );
*/
function stdin() {
	var clbk = arguments[ arguments.length-1 ];
	if ( !isFunction( clbk ) ) {
		throw new TypeError( 'invalid argument. Callback argument must be a function. Value: `' + clbk + '`.' );
	}
	setTimeout( onTimeout, 0 );

	/**
	* Callback invoked upon a timeout.
	*
	* @private
	*/
	function onTimeout() {
		clbk( new Error( 'invalid operation. The environment does not support reading from `stdin`.' ) );
	}
}


// EXPORTS //

module.exports = stdin;
