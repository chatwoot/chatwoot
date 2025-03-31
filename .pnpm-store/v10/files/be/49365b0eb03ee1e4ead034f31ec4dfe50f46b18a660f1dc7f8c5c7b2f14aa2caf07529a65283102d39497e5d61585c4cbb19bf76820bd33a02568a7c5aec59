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
var cwd = require( '@stdlib/process-cwd' );
var exists = require( '@stdlib/fs-exists' ).sync;
var validate = require( './validate.js' );


// MAIN //

/**
* Synchronously resolves a path by walking parent directories.
*
* @param {string} path - path to resolve
* @param {Options} [options] - function options
* @param {string} [options.dir] - base directory
* @throws {TypeError} first argument must be a string
* @throws {TypeError} options argument must be an object
* @throws {TypeError} must provide valid options
* @returns {(string|null)} resolved path or null
*
* @example
* var path = resolveParentPath( 'package.json' );
*/
function resolveParentPath( path, options ) {
	var spath;
	var child;
	var opts;
	var dir;
	var err;
	if ( !isString( path ) ) {
		throw new TypeError( 'invalid argument. First argument must be a string primitive. Value: `' + path + '`.' );
	}
	opts = {};
	if ( arguments.length > 1 ) {
		err = validate( opts, options );
		if ( err ) {
			throw err;
		}
	}
	if ( opts.dir ) {
		dir = resolve( cwd(), opts.dir );
	} else {
		dir = cwd();
	}
	// Start at a base directory and continue moving up through each parent directory until able to resolve a search path or until reaching the root directory...
	while ( child !== dir ) {
		spath = resolve( dir, path );
		if ( exists( spath ) ) {
			return spath;
		}
		child = dir;
		dir = resolve( dir, '..' );
	}
	return null;
}


// EXPORTS //

module.exports = resolveParentPath;
