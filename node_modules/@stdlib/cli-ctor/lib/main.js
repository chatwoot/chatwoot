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

/* eslint-disable stdlib/jsdoc-doctest, no-restricted-syntax */

'use strict';

// MODULES //

var parseArgs = require( 'minimist' ); // TODO: replace with stdlib equivalent
var defaults = require( './defaults.json' );
var isInteger = require( './is_integer.js' );
var validate = require( './validate.js' );
var proc = require( './process.js' );
var log = require( './console.js' );
var exitCode = require( './exit_code.js' );
var notifier = require( './notifier.js' );


// VARIABLES //

// NOTE: for the following, we explicitly avoid using stdlib packages in this particular package in order to avoid circular dependencies. This should not be problematic as (1) this package is unlikely to be used outside of Node.js and, thus, in environments lacking support for the built-in APIs, and (2) most of the historical bugs for the respective APIs were in environments such as IE and not the versions of V8 included in Node.js >= v0.10.x.
var defineProperty = Object.defineProperty;
var objectKeys = Object.keys;


// FUNCTIONS //

/**
* Defines a read-only non-enumerable property.
*
* @private
* @param {Object} obj - object on which to define the property
* @param {(string|symbol)} prop - property name
* @param {*} value - value to set
*
* @example
* var obj = {};
*
* setReadOnly( obj, 'foo', 'bar' );
*
* try {
*     obj.foo = 'boop';
* } catch ( err ) {
*     console.error( err.message );
* }
*/
function setReadOnly( obj, prop, value ) {
	defineProperty( obj, prop, {
		'configurable': false,
		'enumerable': false,
		'writable': false,
		'value': value
	});
}


// MAIN //

/**
* Command-line interface constructor.
*
* @constructor
* @param {Options} [options] - options
* @param {Object} [options.pkg={}] - package meta information (package.json)
* @param {string} [options.version] - command-line interface version
* @param {string} [options.help=""] - help text
* @param {(string|boolean)} [options.title=true] - process title or a boolean indicating whether to set the process title
* @param {boolean} [options.updates=true] - boolean indicating whether to check if a command-line interface is an outdated version
* @param {Array} [options.argv] - command-line arguments
* @param {Options} [options.options={}] - command-line interface options
* @throws {TypeError} must provide an object
* @throws {TypeError} must provide valid options
* @returns {CLI} command-line interface
*
* @example
* var opts = {
*     'pkg': require( './path/to/package.json' ),
*     'help': 'Usage: beep [options] <boop>',
*     'title': 'foo',
*     'updates': true,
*     'options': {
*         'boolean': [
*             'help',
*             'version'
*         ]
*     }
* };
* var cli = new CLI( opts );
* // returns <CLI>
*
* cli.close();
*/
function CLI( options ) {
	var nopts;
	var flags;
	var keys;
	var opts;
	var argv;
	var args;
	var self;
	var err;
	if ( !( this instanceof CLI ) ) {
		if ( arguments.length ) {
			return new CLI( options );
		}
		return new CLI();
	}
	opts = {
		'pkg': {},
		'help': defaults.help,
		'title': defaults.title,
		'version': defaults.version,
		'updates': defaults.updates,
		'argv': defaults.argv,
		'options': {}
	};
	if ( arguments.length ) {
		err = validate( opts, options );
		if ( err ) {
			throw err;
		}
	}
	self = this;

	// Force the process to exit if an error is encountered when writing to `stdout` or `stderr`:
	proc.stdout.on( 'error', proc.exit );
	proc.stderr.on( 'error', proc.exit );

	/**
	* Returns parsed command-line arguments.
	*
	* @name args
	* @memberof CLI#
	* @type {Function}
	* @returns {StringArray} parsed command-line arguments
	*
	* @example
	* var cli = new CLI();
	*
	* var args = cli.args();
	* // returns <Array>
	*/
	setReadOnly( this, 'args', getArgs );

	/**
	* Returns parsed command-line flags.
	*
	* @name flags
	* @memberof CLI#
	* @type {Function}
	* @returns {Object} parsed command-line flags
	*
	* @example
	* var cli = new CLI();
	*
	* var flags = cli.flags();
	* // returns <Object>
	*/
	setReadOnly( this, 'flags', getFlags );

	/**
	* Prints usage information and exits the process.
	*
	* @name help
	* @memberof CLI#
	* @type {Function}
	*
	* @example
	* var opts = {
	*     'help': 'Usage: beep [options] <boop>'
	* };
	* var cli = new CLI( opts );
	*
	* cli.help();
	* // => 'Usage: beep [options] <boop>'
	*/
	setReadOnly( this, 'help', help );

	/**
	* Prints the command-line interface version and exits the process.
	*
	* @name version
	* @memberof CLI#
	* @type {Function}
	*
	* @example
	* var opts = {
	*     'pkg': require( './path/to/package.json' )
	* };
	* var cli = new CLI( opts );
	*
	* cli.version();
	* // => '#.#.#'
	*/
	setReadOnly( this, 'version', version );

	// Check whether to set the process title...
	if ( opts.title === true && opts.pkg ) {
		if ( typeof opts.pkg.bin === 'object' && opts.pkg.bin !== null ) {
			keys = objectKeys( opts.pkg.bin );

			// Note: we don't have a way of knowing which command name in the `bin` hash was invoked; thus, we assume the first entry.
			proc.title = keys[ 0 ];
		} else if ( opts.pkg.name ) {
			proc.title = opts.pkg.name;
		}
	} else if ( opts.title ) {
		proc.title = opts.title;
	}
	// Check whether to notify the user of a new CLI version...
	if ( opts.updates && opts.pkg && opts.pkg.name && opts.pkg.version ) {
		nopts = {
			'pkg': opts.pkg
		};
		notifier( nopts ).notify();
	}
	// Determine the command-line interface version...
	if ( !opts.version && opts.pkg && opts.pkg.version ) {
		opts.version = opts.pkg.version;
	}
	// Parse command-line arguments:
	if ( opts.argv ) {
		opts.argv = opts.argv.slice( 2 );
	} else {
		opts.argv = proc.argv.slice( 2 );
	}
	argv = parseArgs( opts.argv, opts.options );

	// Cache parsed arguments:
	args = argv._;
	delete argv._;
	flags = argv;

	// Determine whether to print help text...
	if ( flags.help ) {
		return this.help( 0 );
	}
	// Determine whether to print the version...
	if ( flags.version ) {
		return this.version();
	}
	return this;

	/**
	* Returns parsed command-line arguments.
	*
	* @private
	* @returns {StringArray} parsed command-line arguments
	*/
	function getArgs() {
		return args.slice();
	}

	/**
	* Returns parsed command-line flags.
	*
	* @private
	* @returns {Object} parsed command-line flags
	*/
	function getFlags() {
		var keys;
		var o;
		var k;
		var i;

		keys = objectKeys( flags );
		o = {};
		for ( i = 0; i < keys.length; i++ ) {
			k = keys[ i ];
			o[ k ] = flags[ k ];
		}
		return o;
	}

	/**
	* Prints usage information.
	*
	* ## Notes
	*
	* -   Upon printing usage information, the function forces the process to exit.
	*
	* @private
	* @param {NonNegativeInteger} [code=0] - exit code
	*/
	function help( code ) {
		log.error( opts.help );
		self.close( code || 0 );
	}

	/**
	* Prints the command-line interface version.
	*
	* ## Notes
	*
	* -   Upon printing the version, the function forces the process to exit.
	*
	* @private
	*/
	function version() {
		log.error( opts.version );
		self.close();
	}
}

/**
* Gracefully exits the command-line interface and the calling process.
*
* @name close
* @memberof CLI.prototype
* @type {Function}
* @param {NonNegativeInteger} [code=0] - exit code
* @throws {TypeError} must provide a nonnegative integer
* @returns {void}
*
* @example
* var cli = new CLI();
*
* // Gracefully exit:
* cli.close();
*/
setReadOnly( CLI.prototype, 'close', function close( code ) {
	if ( arguments.length === 0 ) {
		exitCode( proc, 0 );
		return;
	}
	if ( typeof code !== 'number' || !isInteger( code ) || code < 0 ) {
		throw new TypeError( 'invalid argument. Must provide a nonnegative integer. Value: `' + code + '`.' );
	}
	exitCode( proc, code );
});

/**
* Exits the command-line interface and the calling process due to an error.
*
* ## Notes
*
* -   The value assigned to the `message` property of the provided `Error` object is printed to `stderr` prior to exiting the command-line interface and the calling process.
*
* @name error
* @memberof CLI.prototype
* @type {Function}
* @param {Error} error - error object
* @param {NonNegativeInteger} [code=1] - exit code
* @throws {TypeError} first argument must be an error object
* @throws {TypeError} second argument must be a nonnegative integer
* @returns {void}
*
* @example
* var cli = new CLI();
*
* // ...
*
* // Create an error object:
* var err = new Error( 'invalid operation' );
*
* // Exit the process:
* cli.error( err, 0 );
*/
setReadOnly( CLI.prototype, 'error', function onError( error, code ) {
	var c;
	if ( !( error instanceof Error ) ) {
		throw new TypeError( 'invalid argument. First argument must be an error object. Value: `' + error + '`.' );
	}
	if ( arguments.length > 1 ) {
		if ( typeof code !== 'number' || !isInteger( code ) || code < 0 ) {
			throw new TypeError( 'invalid argument. Second argument must be a nonnegative integer. Value: `' + code + '`.' );
		}
		c = code;
	} else {
		c = 1;
	}
	log.error( 'Error: %s', error.message );
	exitCode( proc, c );
});

/**
* Forces the command-line interface (and the calling process) to exit.
*
* @name exit
* @memberof CLI.prototype
* @type {Function}
* @param {NonNegativeInteger} [code=0] - exit code
* @throws {TypeError} must provide a nonnegative integer
* @returns {void}
*
* @example
* var cli = new CLI();
*
* // Forcefully exit:
* cli.exit();
*/
setReadOnly( CLI.prototype, 'exit', function exit( code ) {
	if ( arguments.length === 0 ) {
		return proc.exit( 0 );
	}
	if ( typeof code !== 'number' || !isInteger( code ) || code < 0 ) {
		throw new TypeError( 'invalid argument. Must provide a nonnegative integer. Value: `' + code + '`.' );
	}
	proc.exit( code );
});


// EXPORTS //

module.exports = CLI;
