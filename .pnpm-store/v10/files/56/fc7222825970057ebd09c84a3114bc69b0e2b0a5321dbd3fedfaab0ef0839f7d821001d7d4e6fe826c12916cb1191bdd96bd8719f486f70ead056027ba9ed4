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
* Test whether a path exists on the filesystem. For more information, see the [archive][1].
*
* [1]: https://github.com/nodejs/node-v0.x-archive/blob/d8baf8a2a4481940bfed0196308ae6189ca18eee/lib/fs.js#L222
*
* @module @stdlib/fs-exists
*
* @example
* var exists = require( '@stdlib/fs-exists' );
*
* exists( __dirname, done );
* exists( 'beepboop', done );
*
* function done( error, bool ) {
*     if ( error ) {
*         console.error( error.message );
*     } else {
*         console.log( bool );
*     }
* }
*
* @example
* var existsSync = require( '@stdlib/fs-exists' ).sync;
*
* console.log( existsSync( __dirname ) );
* // => true
*
* console.log( existsSync( 'beepboop' ) );
* // => false
*/

// MODULES //

var setReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );
var exists = require( './async.js' );
var sync = require( './sync.js' );


// MAIN //

setReadOnly( exists, 'sync', sync );


// EXPORTS //

module.exports = exists;
