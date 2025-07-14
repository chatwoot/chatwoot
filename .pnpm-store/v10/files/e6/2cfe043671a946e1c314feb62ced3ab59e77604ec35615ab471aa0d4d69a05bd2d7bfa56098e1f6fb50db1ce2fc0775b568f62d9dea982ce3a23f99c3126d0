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

// VARIABLES //

var hasOwnProp = Object.prototype.hasOwnProperty;
var isArray = Array.isArray;


// MAIN //

/**
* Validates function options.
*
* @private
* @param {Object} opts - destination object
* @param {Options} options - function options
* @param {Object} [options.pkg] - package meta information (package.json)
* @param {string} [options.version] - command-line interface version
* @param {string} [options.help] - help text
* @param {(string|boolean)} [options.title] - process title or a boolean indicating whether to set the process title
* @param {boolean} [options.updates] - boolean indicating whether to check if a command-line interface is an outdated version
* @param {Array} [options.argv] - command-line arguments
* @param {Options} [options.options] - command-line interface options
* @returns {(Error|null)} null or an error object
*
* @example
* var opts = {};
* var options = {
*     'pkg': {},
*     'version': '1.0.0',
*     'help': 'Usage: beep [options] <boop>',
*     'title': 'foo',
*     'updates': true
* };
* var err = validate( opts, options );
* if ( err ) {
*     throw err;
* }
*/
function validate( opts, options ) {
	if ( typeof options !== 'object' || options === null || isArray( options ) ) {
		return new TypeError( 'invalid argument. Options must be an object. Value: `' + options + '`.' );
	}
	if ( hasOwnProp.call( options, 'pkg' ) ) {
		opts.pkg = options.pkg;
		if ( typeof opts.pkg !== 'object' || opts.pkg === null || isArray( opts.pkg ) ) {
			return new TypeError( 'invalid option. `pkg` option must be an object. Option: `' + opts.pkg + '`.' );
		}
	}
	if ( hasOwnProp.call( options, 'help' ) ) {
		opts.help = options.help;
		if ( typeof opts.help !== 'string' ) {
			return new TypeError( 'invalid option. `help` option must be a string primitive. Option: `' + opts.help + '`.' );
		}
	}
	if ( hasOwnProp.call( options, 'version' ) ) {
		opts.version = options.version;
		if ( typeof opts.version !== 'string' ) {
			return new TypeError( 'invalid option. `version` option must be a string primitive. Option: `' + opts.version + '`.' );
		}
	}
	if ( hasOwnProp.call( options, 'title' ) ) {
		opts.title = options.title;
		if ( typeof opts.title !== 'string' && typeof opts.title !== 'boolean' ) {
			return new TypeError( 'invalid option. `title` option must be either a string or boolean primitive. Option: `' + opts.title + '`.' );
		}
	}
	if ( hasOwnProp.call( options, 'updates' ) ) {
		opts.updates = options.updates;
		if ( typeof opts.updates !== 'boolean' ) {
			return new TypeError( 'invalid option. `updates` option must be a boolean primitive. Option: `' + opts.updates + '`.' );
		}
	}
	if ( hasOwnProp.call( options, 'argv' ) ) {
		opts.argv = options.argv;
		if ( !isArray( opts.argv ) ) {
			return new TypeError( 'invalid option. `argv` option must be an array. Option: `' + opts.argv + '`.' );
		}
	}
	if ( hasOwnProp.call( options, 'options' ) ) {
		opts.options = options.options;
		if ( typeof opts.options !== 'object' || opts.options === null || isArray( opts.options ) ) {
			return new TypeError( 'invalid option. `options` option must be a plain object. Option: `' + opts.options + '`.' );
		}
	}
	return null;
}


// EXPORTS //

module.exports = validate;
