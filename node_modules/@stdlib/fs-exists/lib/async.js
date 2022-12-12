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

var fs = require( 'fs' );


// FUNCTIONS //

var fcn;
if ( typeof fs.access === 'function' ) {
	fcn = fs.access;
} else {
	fcn = fs.stat;
}


// MAIN //

/**
* Tests whether a path exists on the filesystem.
*
* @param {(string|Buffer)} path - path to test
* @param {Function} clbk - callback to invoke after testing path existence
*
* @example
* exists( __dirname, done );
*
* function done( error, bool ) {
*     if ( error ) {
*         console.error( error );
*     }
*     if ( bool ) {
*         console.log( '...path exists.' );
*     } else {
*         console.log( '...path does not exist.' );
*     }
* }
*/
function exists( path, clbk ) {
	fcn( path, done );

	/**
	* Callback invoked upon performing a filesystem call.
	*
	* @private
	* @param {(Error|null)} error - error object
	* @returns {void}
	*/
	function done( error ) {
		if ( clbk.length === 2 ) {
			if ( error ) {
				return clbk( error, false );
			}
			return clbk( null, true );
		}
		if ( error ) {
			return clbk( false );
		}
		return clbk( true );
	}
}


// EXPORTS //

module.exports = exists;
