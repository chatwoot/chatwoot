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

var resolve = require( 'path' ).resolve;
var isString = require( '@stdlib/assert-is-string' ).isPrimitive;
var isFunction = require( '@stdlib/assert-is-function' );
var cwd = require( '@stdlib/process-cwd' );
var exists = require( '@stdlib/fs-exists' );
var validate = require( './validate.js' );


// MAIN //

/**
* Asynchronously resolves a path by walking parent directories.
*
* @param {string} path - path to resolve
* @param {Options} [options] - function options
* @param {string} [options.dir] - base directory
* @param {Callback} clbk - callback to invoke after resolving a path
* @throws {TypeError} first argument must be a string
* @throws {TypeError} callback argument must be a function
* @throws {TypeError} options argument must be an object
* @throws {TypeError} must provide valid options
*
* @example
* resolveParentPath( 'package.json', onPath );
*
* function onPath( error, path ) {
*     if ( error ) {
*         throw error;
*     }
*     console.log( path );
* }
*/
function resolveParentPath( path, options, clbk ) {
	var spath;
	var child;
	var opts;
	var done;
	var dir;
	var err;
	if ( !isString( path ) ) {
		throw new TypeError( 'invalid argument. First argument must be a string primitive. Value: `' + path + '`.' );
	}
	opts = {};
	if ( arguments.length > 2 ) {
		done = clbk;
		err = validate( opts, options );
		if ( err ) {
			throw err;
		}
	} else {
		done = options;
	}
	if ( !isFunction( done ) ) {
		throw new TypeError( 'invalid argument. Callback argument must be a function. Value: `' + done + '`.' );
	}
	if ( opts.dir ) {
		dir = resolve( cwd(), opts.dir );
	} else {
		dir = cwd();
	}
	spath = resolve( dir, path );
	exists( spath, onExists );

	/**
	* Callback invoked after checking for path existence.
	*
	* @private
	* @param {(Error|null)} error - error object
	* @param {boolean} bool - boolean indicating if a path exists
	* @returns {void}
	*/
	function onExists( error, bool ) { // eslint-disable-line handle-callback-err
		if ( bool ) {
			return done( null, spath );
		}
		// Resolve a parent directory:
		child = dir;
		dir = resolve( dir, '..' );

		// If we have already reached root, we cannot resolve any higher directories...
		if ( child === dir ) {
			return done( null, null );
		}
		// Resolve the next search path:
		spath = resolve( dir, path );
		exists( spath, onExists );
	}
}


// EXPORTS //

module.exports = resolveParentPath;
