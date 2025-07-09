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

// NOTE: for the following, we explicitly avoid using stdlib packages in this particular package in order to avoid circular dependencies. This should not be problematic as (1) this package is unlikely to be used outside of Node.js and, thus, in environments lacking support for the built-in APIs, and (2) most of the historical bugs for the respective APIs were in environments such as IE and not the versions of V8 included in Node.js >= v0.10.x.
var isObject = require( './is_object.js' );


// VARIABLES //

var hasOwnProp = Object.prototype.hasOwnProperty;


// MAIN //

/**
* Validates function options.
*
* @private
* @param {Object} opts - destination object
* @param {Options} options - function options
* @param {string} [options.basedir] - base search directory
* @param {string} [options.paths] - path convention
* @returns {Error|null} error or null
*
* @example
* var options = {
*     'basedir': '/beep/boop/foo/bar',
*     'paths': 'win32'
* };
* var opts = {};
* var err = validate( opts, options );
* if ( err ) {
*     throw err;
* }
*/
function validate( opts, options ) {
	if ( !isObject( options ) ) {
		return new TypeError( 'invalid argument. Options argument must be an object. Value: `' + options + '`.' );
	}
	if ( hasOwnProp.call( options, 'basedir' ) ) {
		opts.basedir = options.basedir;
		if ( typeof opts.basedir !== 'string' ) {
			return new TypeError( 'invalid option. `basedir` option must be a primitive string. Option: `' + opts.basedir + '`.' );
		}
	}
	if ( hasOwnProp.call( options, 'paths' ) ) {
		opts.paths = options.paths;
		if ( typeof opts.paths !== 'string' ) {
			return new TypeError( 'invalid option. `paths` option must be a primitive string. Option: `' + opts.paths + '`.' );
		}
	}
	return null;
}


// EXPORTS //

module.exports = validate;
