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

/**
* Return a regular expression to test if a string is an extended-length path.
*
* @module @stdlib/regexp-extended-length-path
*
* @example
* var reExtendedLengthPath = require( '@stdlib/regexp-extended-length-path' );
* var RE_EXTENDED_LENGTH_PATH = reExtendedLengthPath();
*
* var bool = RE_EXTENDED_LENGTH_PATH.test( '\\\\?\\C:\\foo\\bar' );
* // returns true
*
* bool = RE_EXTENDED_LENGTH_PATH.test( 'C:\\foo\\bar' );
* // returns false
*/

// MODULES //

var setReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );
var reExtendedLengthPath = require( './main.js' );
var REGEXP = require( './regexp.js' );


// MAIN //

setReadOnly( reExtendedLengthPath, 'REGEXP', REGEXP );


// EXPORTS //

module.exports = reExtendedLengthPath;
