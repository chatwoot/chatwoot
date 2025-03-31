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
* Buffer constructor.
*
* @module @stdlib/buffer-ctor
*
* @example
* var ctor = require( '@stdlib/buffer-ctor' );
*
* var b = new ctor( [ 1, 2, 3, 4 ] );
* // returns <Buffer>
*/

// MODULES //

var hasNodeBufferSupport = require( '@stdlib/assert-has-node-buffer-support' );
var main = require( './buffer.js' );
var polyfill = require( './polyfill.js' );


// MAIN //

var ctor;
if ( hasNodeBufferSupport() ) {
	ctor = main;
} else {
	ctor = polyfill;
}


// EXPORTS //

module.exports = ctor;
