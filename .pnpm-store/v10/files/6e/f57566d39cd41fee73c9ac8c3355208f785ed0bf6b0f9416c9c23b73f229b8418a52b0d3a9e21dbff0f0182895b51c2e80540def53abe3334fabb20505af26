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

var path = require( 'path' );
var cwd = require( 'process' ).cwd;
var logger = require( 'debug' );
var resolve = require( 'resolve' ).sync;
var parentPath = require( '@stdlib/fs-resolve-parent-path' ).sync;
var convertPath = require( '@stdlib/utils-convert-path' );
var isObject = require( './is_object.js' );
var unique = require( './unique.js' );
var validate = require( './validate.js' );
var DEFAULTS = require( './defaults.json' );


// VARIABLES //

var debug = logger( 'library-manifest:main' );

// NOTE: for the following, we explicitly avoid using stdlib packages in this particular package in order to avoid circular dependencies. This should not be problematic as (1) this package is unlikely to be used outside of Node.js and, thus, in environments lacking support for the built-in APIs, and (2) most of the historical bugs for the respective APIs were in environments such as IE and not the versions of V8 included in Node.js >= v0.10.x.
var hasOwnProp = Object.prototype.hasOwnProperty;
var objectKeys = Object.keys;


// MAIN //

/**
* Returns a configuration.
*
* @param {string} fpath - manifest file path
* @param {Object} conditions - conditions
* @param {Options} [options] - options
* @param {string} [options.basedir] - base search directory
* @param {string} [options.paths] - path convention
* @throws {TypeError} first argument must be a string
* @throws {TypeError} second argument must be an object
* @throws {TypeError} options argument must be a plain object
* @throws {TypeError} must provide valid options
* @returns {Object} configuration
*
* @example
* var conf = manifest( './manifest.json', {} );
*/
function manifest( fpath, conditions, options ) {
	var coptnames;
	var mpath;
	var ropts;
	var mopts;
	var conf;
	var opts;
	var deps;
	var obj;
	var key;
	var tmp;
	var err;
	var dir;
	var o;
	var i;
	var j;
	var k;

	if ( typeof fpath !== 'string' ) {
		throw new TypeError( 'invalid argument. First argument must be a string. Value: `'+fpath+'`.' );
	}
	opts = JSON.parse( JSON.stringify( DEFAULTS ) );
	if ( arguments.length > 2 ) {
		err = validate( opts, options );
		if ( err ) {
			throw err;
		}
		opts.basedir = path.resolve( cwd(), opts.basedir );
	} else {
		opts.basedir = cwd();
	}
	debug( 'Options: %s', JSON.stringify( opts ) );

	fpath = path.resolve( opts.basedir, fpath );
	dir = path.dirname( fpath );
	debug( 'Manifest file path: %s', fpath );

	conf = require( fpath ); // eslint-disable-line stdlib/no-dynamic-require

	// NOTE: Instead of using `@stdlib/utils/copy`, we stringify and then parse the configuration object to create a deep copy in an ES5 environment while avoiding circular dependencies. This assumes that the configuration object is valid JSON.
	conf = JSON.parse( JSON.stringify( conf ) );
	debug( 'Manifest: %s', JSON.stringify( conf ) );

	// TODO: validate a loaded manifest (conf) according to a JSON schema

	// Handle input conditions...
	if ( !isObject( conditions ) ) {
		throw new TypeError( 'invalid argument. Second argument must be an object. Value: `' + conditions + '`.' );
	}
	debug( 'Provided conditions: %s', JSON.stringify( conditions ) );
	coptnames = objectKeys( conf.options );
	for ( i = 0; i < coptnames.length; i++ ) {
		key = coptnames[ i ];
		if ( hasOwnProp.call( conditions, key ) ) {
			conf.options[ key ] = conditions[ key ];
		}
	}
	debug( 'Conditions for matching a configuration: %s', JSON.stringify( conf.options ) );

	// Resolve a configuration based on provided conditions...
	debug( 'Resolving matching configuration.' );
	for ( i = 0; i < conf.confs.length; i++ ) {
		o = conf.confs[ i ];

		// Require that all conditions must match in order to match a configuration...
		for ( j = 0; j < coptnames.length; j++ ) {
			key = coptnames[ j ];
			if (
				!hasOwnProp.call( o, key ) ||
				o[ key ] !== conf.options[ key ]
			) {
				break;
			}
		}
		// If we exhausted all the options, then we found a match...
		if ( j === coptnames.length ) {
			// NOTE: Instead of using `@stdlib/utils/copy`, we stringify and then parse the object to create a deep copy in an ES5 environment while avoiding circular dependencies. This assumes that the object is valid JSON.
			obj = JSON.parse( JSON.stringify( o ) );
			debug( 'Matching configuration: %s', JSON.stringify( obj ) );
			break;
		}
	}
	if ( obj === void 0 ) {
		debug( 'Unable to resolve a matching configuration.' );
		return {};
	}
	// Resolve manifest file paths...
	for ( i = 0; i < conf.fields.length; i++ ) {
		key = conf.fields[ i ].field;
		if ( hasOwnProp.call( obj, key ) ) {
			o = obj[ key ];
			if ( conf.fields[ i ].resolve ) {
				for ( j = 0; j < o.length; j++ ) {
					o[ j ] = path.resolve( dir, o[ j ] );
				}
			}
		}
	}
	// Resolve dependencies (WARNING: circular dependencies will cause an infinite loop)...
	deps = obj.dependencies;

	debug( 'Resolving %d dependencies.', deps.length );
	ropts = {
		'basedir': opts.basedir
	};
	for ( i = 0; i < deps.length; i++ ) {
		debug( 'Resolving dependency: %s', deps[ i ] );

		// Resolve a dependency's main entry point:
		mpath = resolve( deps[ i ], ropts );
		debug( 'Dependency entry point: %s', mpath );

		// Resolve a dependency's path by finding the dependency's `package.json`:
		mpath = parentPath( 'package.json', {
			'dir': path.dirname( mpath )
		});
		mpath = path.dirname( mpath );
		debug( 'Dependency path: %s', mpath );

		// Load the dependency configuration (recursive):
		mopts = {
			'basedir': mpath
		};
		o = manifest( path.join( mpath, opts.filename ), conditions, mopts );
		debug( 'Dependency manifest: %s', JSON.stringify( o ) );

		// Merge each field into the main configuration making sure to resolve file paths (note: we ignore whether a dependency specifies whether to generate relative paths; the only context where relative path generation is considered is the root manifest)...
		debug( 'Merging dependency manifest.' );
		for ( j = 0; j < conf.fields.length; j++ ) {
			key = conf.fields[ j ].field;
			if ( hasOwnProp.call( o, key ) ) {
				tmp = o[ key ];
				if ( conf.fields[ j ].resolve ) {
					for ( k = 0; k < tmp.length; k++ ) {
						tmp[ k ] = path.resolve( mpath, tmp[ k ] );
					}
				}
				obj[ key ] = obj[ key ].concat( tmp );
			}
		}
		debug( 'Resolved dependency: %s', deps[ i ] );
	}
	// Dedupe values (dependencies may share common dependencies)...
	debug( 'Removing duplicate entries.' );
	for ( i = 0; i < conf.fields.length; i++ ) {
		key = conf.fields[ i ].field;
		if ( hasOwnProp.call( obj, key ) ) {
			obj[ key ] = unique( obj[ key ] );
		}
	}
	// Generate relative paths (if specified)...
	debug( 'Generating relative paths.' );
	for ( i = 0; i < conf.fields.length; i++ ) {
		key = conf.fields[ i ].field;
		if (
			hasOwnProp.call( obj, key ) &&
			conf.fields[ i ].resolve &&
			conf.fields[ i ].relative
		) {
			tmp = obj[ key ];
			for ( j = 0; j < tmp.length; j++ ) {
				tmp[ j ] = path.relative( dir, tmp[ j ] );
			}
		}
	}
	// Convert paths to a particular path convention...
	if ( opts.paths ) {
		debug( 'Converting paths to specified convention.' );
		for ( i = 0; i < conf.fields.length; i++ ) {
			key = conf.fields[ i ].field;
			if ( hasOwnProp.call( obj, key ) ) {
				tmp = obj[ key ];
				for ( j = 0; j < tmp.length; j++ ) {
					tmp[ j ] = convertPath( tmp[ j ], opts.paths );
				}
			}
		}
	}
	debug( 'Final configuration: %s', JSON.stringify( obj ) );
	return obj;
}


// EXPORTS //

module.exports = manifest;
