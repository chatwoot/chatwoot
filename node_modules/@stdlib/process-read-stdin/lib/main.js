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

var isFunction = require( '@stdlib/assert-is-function' );
var isString = require( '@stdlib/assert-is-string' ).isPrimitive;
var Buffer = require( '@stdlib/buffer-ctor' );
var string2buffer = require( '@stdlib/buffer-from-string' );
var stream = require( '@stdlib/streams-node-stdin' );
var nextTick = require( '@stdlib/utils-next-tick' );


// MAIN //

/**
* Reads data from `stdin`.
*
* @param {(string|null)} [encoding] - string encoding. If set, data will be returned as an encoded `string`.
* @param {Function} clbk - callback to be invoked upon reading all data from `stdin`
* @throws {TypeError} `encoding` argument must be a string
* @throws {TypeError} callback argument must be a function
* @returns {void}
*
* @example
* function onRead( error, data ) {
*     if ( error ) {
*         throw error;
*     }
*     console.log( data.toString() );
*     // => '...'
* }
*
* stdin( onRead );
*
* @example
* function onRead( error, data ) {
*     if ( error ) {
*         throw error;
*     }
*     console.log( data );
*     // => '...'
* }
*
* stdin( 'utf8', onRead );
*/
function stdin() {
	var clbk;
	var data;
	var enc;
	var len;

	if ( arguments.length === 1 ) {
		clbk = arguments[ 0 ];
	} else {
		enc = arguments[ 0 ];
		if ( !isString( enc ) ) {
			throw new TypeError( 'invalid argument. Encoding argument must be a string. Value: `' + enc + '`.' );
		}
		clbk = arguments[ 1 ];
	}
	if ( !isFunction( clbk ) ) {
		throw new TypeError( 'invalid argument. Callback argument must be a function. Value: `' + clbk + '`.' );
	}
	if ( enc ) {
		stream.setEncoding( enc );
	}
	// If the calling file is being run as a script and not as part of a pipeline, we should not expect to receive anything on `stdin`.
	if ( stream.isTTY ) {
		return nextTick( onTick );
	}
	data = [];
	len = 0;

	stream.on( 'readable', onReadable );
	stream.on( 'error', onError );
	stream.on( 'end', onEnd );

	/**
	* Callback invoked after the next tick.
	*
	* @private
	* @returns {void}
	*/
	function onTick() {
		if ( enc ) {
			return clbk( null, '' );
		}
		clbk( null, string2buffer( '' ) );
	}

	/**
	* Callback invoked once the stream has data to consume.
	*
	* @private
	*/
	function onReadable() {
		var chunk;
		while ( true ) {
			chunk = stream.read();
			if ( chunk === null ) {
				break;
			}
			if ( typeof chunk === 'string' ) {
				chunk = string2buffer( chunk );
			}
			data.push( chunk );
			len += chunk.length;
		}
	}

	/**
	* Callback invoked upon encountering a stream error.
	*
	* @private
	* @param {Error} error - error object
	*/
	function onError( error ) {
		clbk( error );
	}

	/**
	* Callback invoked after all data has been consumed.
	*
	* @private
	* @returns {void}
	*/
	function onEnd() {
		if ( enc ) {
			// Return a string...
			return clbk( null, data.join( '' ) );
		}
		// Return a buffer...
		clbk( null, Buffer.concat( data, len ) );
	}
}


// EXPORTS //

module.exports = stdin;
