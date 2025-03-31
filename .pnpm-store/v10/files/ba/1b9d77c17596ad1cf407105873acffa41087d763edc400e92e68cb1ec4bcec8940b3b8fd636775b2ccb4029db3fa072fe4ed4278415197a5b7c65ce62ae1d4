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

var proc = require( 'process' );


// MAIN //

/**
* Adds a callback to the "next tick queue".
*
* ## Notes
*
* -   The queue is fully drained after the current operation on the JavaScript stack runs to completion and before the event loop is allowed to continue.
*
* @param {Callback} clbk - callback
* @param {...*} [args] - arguments to provide to the callback upon invocation
*
* @example
* function beep() {
*     console.log( 'boop' );
* }
*
* nextTick( beep );
*/
function nextTick( clbk ) {
	var args;
	var i;

	args = [];
	for ( i = 1; i < arguments.length; i++ ) {
		args.push( arguments[ i ] );
	}
	proc.nextTick( wrapper );

	/**
	* Callback wrapper.
	*
	* ## Notes
	*
	* -   The ability to provide additional arguments was added in Node.js v1.8.1. The wrapper provides support for earlier Node.js versions.
	*
	* @private
	*/
	function wrapper() {
		clbk.apply( null, args );
	}
}


// EXPORTS //

module.exports = nextTick;
