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

var rescape = require( '@stdlib/utils-escape-regexp-string' );
var isFunction = require( '@stdlib/assert-is-function' );
var isString = require( '@stdlib/assert-is-string' ).isPrimitive;
var isRegExp = require( '@stdlib/assert-is-regexp' );
var format = require( '@stdlib/string-format' );


// MAIN //

/**
* Replace search occurrences with a replacement string.
*
* @param {string} str - input string
* @param {(string|RegExp)} search - search expression
* @param {(string|Function)} newval - replacement value or function
* @throws {TypeError} first argument must be a string
* @throws {TypeError} second argument argument must be a string or regular expression
* @throws {TypeError} third argument must be a string or function
* @returns {string} new string containing replacement(s)
*
* @example
* var str = 'beep';
* var out = replace( str, 'e', 'o' );
* // returns 'boop'
*
* @example
* var str = 'Hello World';
* var out = replace( str, /world/i, 'Mr. President' );
* // returns 'Hello Mr. President'
*
* @example
* var capitalize = require( '@stdlib/string-capitalize' );
*
* var str = 'Oranges and lemons say the bells of St. Clement\'s';
*
* function replacer( match, p1 ) {
*     return capitalize( p1 );
* }
*
* var out = replace( str, /([^\s]*)/gi, replacer);
* // returns 'Oranges And Lemons Say The Bells Of St. Clement\'s'
*/
function replace( str, search, newval ) {
	if ( !isString( str ) ) {
		throw new TypeError( format( 'invalid argument. First argument must be a string. Value: `%s`.', str ) );
	}
	if ( isString( search ) ) {
		search = rescape( search );
		search = new RegExp( search, 'g' );
	}
	else if ( !isRegExp( search ) ) {
		throw new TypeError( format( 'invalid argument. Second argument must be a string or regular expression. Value: `%s`.', search ) );
	}
	if ( !isString( newval ) && !isFunction( newval ) ) {
		throw new TypeError( format( 'invalid argument. Third argument must be a string or replacement function. Value: `%s`.', newval ) );
	}
	return str.replace( search, newval );
}


// EXPORTS //

module.exports = replace;
