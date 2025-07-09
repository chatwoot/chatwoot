/**
* @license Apache-2.0
*
* Copyright (c) 2019 The Stdlib Authors.
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

var proc = require( './process.js' );


// VARIABLES //

var NODE_VERSION = proc.versions.node;
var TIMEOUT = 10; // ms


// MAIN //

/**
* Sets the process exit code.
*
* @private
* @param {Object} proc - process object
* @param {NonNegativeInteger} code - exit code
* @returns {void}
*/
function exitCode( proc, code ) {
	var v;

	// Handle old Node.js versions lacking `process.exitCode` support...
	v = NODE_VERSION.split( '.' );
	v[ 0 ] = parseInt( v[ 0 ], 10 );
	v[ 1 ] = parseInt( v[ 1 ], 10 );

	// Case: >0.x.x
	if ( v[ 0 ] > 0 ) {
		proc.exitCode = code;
		return;
	}
	// Case: >0.10.x
	if ( v[ 1 ] > 10 ) {
		proc.exitCode = code;
		return;
	}
	// Case: <= 0.10.x
	proc.exitCode = code; // NOTE: assigning this property should have no operational effect in older Node.js versions

	// No choice but to forcefully exit during a subsequent turn of the event loop (note: the timeout duration is arbitrary; the main idea is to hopefully allow the event loop queue to drain before exiting the process, including the flushing of stdio streams which can be non-blocking/asynchronous)...
	setTimeout( onTimeout, TIMEOUT );

	/**
	* Callback invoked during a subsequent turn of the event loop.
	*
	* @private
	*/
	function onTimeout() {
		proc.exit( code );
	}
}


// EXPORTS //

module.exports = exitCode;
