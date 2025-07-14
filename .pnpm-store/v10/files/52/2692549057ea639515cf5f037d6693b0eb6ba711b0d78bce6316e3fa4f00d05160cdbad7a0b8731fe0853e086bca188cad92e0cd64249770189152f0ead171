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

/* eslint-disable no-sync */

'use strict';

// MODULES //

var fs = require( 'fs' );


// FUNCTIONS //

var fcn;
if ( typeof fs.accessSync === 'function' ) {
	fcn = fs.accessSync;
} else {
	fcn = fs.statSync;
}


// MAIN //

/**
* Synchronously tests whether a path exists on the filesystem.
*
* @param {(string|Buffer)} path - path to test
* @returns {boolean} boolean indicating whether the path exists
*
* @example
* var bool = existsSync( __dirname );
* // returns <boolean>
*/
function existsSync( path ) {
	try {
		fcn( path );
	} catch ( err ) { // eslint-disable-line no-unused-vars
		return false;
	}
	return true;
}


// EXPORTS //

module.exports = existsSync;
