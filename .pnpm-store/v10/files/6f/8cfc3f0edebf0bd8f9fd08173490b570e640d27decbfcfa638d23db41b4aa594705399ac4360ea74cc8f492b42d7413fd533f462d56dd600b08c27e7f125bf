/**
* @license Apache-2.0
*
* Copyright (c) 2020 The Stdlib Authors.
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

var IS_LITTLE_ENDIAN = require( '@stdlib/assert-is-little-endian' );
var IS_BIG_ENDIAN = require( '@stdlib/assert-is-big-endian' );


// MAIN //

/**
* Platform byte order.
*
* @constant
* @type {string}
*/
var BYTE_ORDER;
if ( IS_LITTLE_ENDIAN && IS_BIG_ENDIAN ) {
	BYTE_ORDER = 'mixed-endian';
} else if ( IS_LITTLE_ENDIAN ) {
	BYTE_ORDER = 'little-endian';
} else if ( IS_BIG_ENDIAN ) {
	BYTE_ORDER = 'big-endian';
} else {
	BYTE_ORDER = 'unknown';
}


// EXPORTS //

module.exports = BYTE_ORDER;
