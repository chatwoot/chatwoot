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
* Interface defining function options.
*/
interface Options {
	/**
	* Boolean indicating whether to create a capture group for the match.
	*/
	capture?: boolean;

	/**
	* Regular expression flags.
	*/
	flags?: string;
}

/**
* Interface for a regular expression to match a newline character sequence.
*/
interface ReEOL {
	/**
	* Returns a regular expression to match a newline character sequence.
	*
	* @param options - function options
	* @param options.flags - regular expression flags (default: '')
	* @param options.capture - boolean indicating whether to create a capture group for the match (default: false)
	* @returns regular expression
	*
	* @example
	* var replace = require( `@stdlib/string/replace` );
	*
	* var RE_EOL = reEOL({
	*     'flags': 'g'
	* });
	* var str = '1\n2\n3';
	* var out = replace( str, RE_EOL, '' );
	* // returns '123'
	*/
	( options?: Options ): RegExp;

	/**
	* Regular expression to match a newline character sequence.
	*
	* @example
	* var bool = reEOL.REGEXP.test( 'abc' );
	* // returns false
	*/
	REGEXP: RegExp;

	/**
	* Regular expression to capture a newline character sequence.
	*
	* @example
	* var parts = reEOL.REGEXP_CAPTURE.exec( '\n' );
	* // returns [ '\n', '\n' ]
	*/
	REGEXP_CAPTURE: RegExp;
}

/**
* Returns a regular expression to match a newline character sequence.
*
* @param options - function options
* @param options.flags - regular expression flags (default: '')
* @param options.capture - boolean indicating whether to create a capture group for the match (default: false)
* @returns regular expression
*
* @example
* var RE_EOL = reEOL();
*
* var bool = RE_EOL.test( '\n' );
* // returns true
*
* bool = RE_EOL.test( '\\r\\n' );
* // returns false
*
* @example
* var replace = require( `@stdlib/string/replace` );
*
* var RE_EOL = reEOL({
*     'flags': 'g'
* });
* var str = '1\n2\n3';
* var out = replace( str, RE_EOL, '' );
* // returns '123'
*
* @example
* var bool = reEOL.REGEXP.test( '\r\n' );
* // returns true
*/
declare var reEOL: ReEOL;


// EXPORTS //

export = reEOL;
