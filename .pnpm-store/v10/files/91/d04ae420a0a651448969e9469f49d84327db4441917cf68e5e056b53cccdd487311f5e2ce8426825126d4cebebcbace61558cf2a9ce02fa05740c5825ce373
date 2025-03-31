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

var validate = require( './validate.js' );


// VARIABLES //

var REGEXP_STRING = '\\r?\\n';


// MAIN //

/**
* Returns a regular expression to match a newline character sequence.
*
* @param {Options} [options] - function options
* @param {string} [options.flags=''] - regular expression flags
* @param {boolean} [options.capture=false] - boolean indicating whether to create a capture group for the match
* @throws {TypeError} options argument must be an object
* @throws {TypeError} must provide valid options
* @returns {RegExp} regular expression
*
* @example
* var RE_EOL = reEOL();
* var bool = RE_EOL.test( '\r\n' );
* // returns true
*
* @example
* var replace = require( '@stdlib/string-replace' );
*
* var RE_EOL = reEOL({
*     'flags': 'g'
* });
* var str = '1\n2\n3';
* var out = replace( str, RE_EOL, '' );
*/
function reEOL( options ) {
	var opts;
	var err;
	if ( arguments.length > 0 ) {
		opts = {};
		err = validate( opts, options );
		if ( err ) {
			throw err;
		}
		if ( opts.capture ) {
			return new RegExp( '('+REGEXP_STRING+')', opts.flags );
		}
		return new RegExp( REGEXP_STRING, opts.flags );
	}
	return /\r?\n/;
}


// EXPORTS //

module.exports = reEOL;
