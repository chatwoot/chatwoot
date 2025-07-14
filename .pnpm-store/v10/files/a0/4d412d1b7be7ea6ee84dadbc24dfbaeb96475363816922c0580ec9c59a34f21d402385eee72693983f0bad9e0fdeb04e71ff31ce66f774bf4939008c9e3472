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

var BYTE_ORDER = require( '@stdlib/os-byte-order' );


// MAIN //

/**
* Platform float word order.
*
* @constant
* @type {string}
*/
var FLOAT_WORD_ORDER;
if ( BYTE_ORDER === 'little-endian' || BYTE_ORDER === 'big-endian' ) {
	FLOAT_WORD_ORDER = BYTE_ORDER;
} else {
	FLOAT_WORD_ORDER = 'unknown';
}


// EXPORTS //

module.exports = FLOAT_WORD_ORDER;
