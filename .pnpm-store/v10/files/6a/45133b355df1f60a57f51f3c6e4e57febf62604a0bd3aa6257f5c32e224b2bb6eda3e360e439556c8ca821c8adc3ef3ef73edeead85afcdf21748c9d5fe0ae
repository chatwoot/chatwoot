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

/**
* Regular expression to match a newline character sequence.
*
* @module @stdlib/regexp-eol
*
* @example
* var reEOL = require( '@stdlib/regexp-eol' );
* var RE_EOL = reEOL();
*
* var bool = RE_EOL.test( '\n' );
* // returns true
*
* bool = RE_EOL.test( '\\r\\n' );
* // returns false
*
* @example
* var reEOL = require( '@stdlib/regexp-eol' );
* var replace = require( '@stdlib/string-replace' );
*
* var RE_EOL = reEOL({
*     'flags': 'g'
* });
* var str = '1\n2\n3';
* var out = replace( str, RE_EOL, '' );
*
* @example
* var reEOL = require( '@stdlib/regexp-eol' );
* var bool = reEOL.REGEXP.test( '\r\n' );
* // returns true
*/

// MODULES //

var setReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );
var reEOL = require( './main.js' );
var REGEXP_CAPTURE = require( './regexp_capture.js' );
var REGEXP = require( './regexp.js' );


// MAIN //

setReadOnly( reEOL, 'REGEXP', REGEXP );
setReadOnly( reEOL, 'REGEXP_CAPTURE', REGEXP_CAPTURE );


// EXPORTS //

module.exports = reEOL;
