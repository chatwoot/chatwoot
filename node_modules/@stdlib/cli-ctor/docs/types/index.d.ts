/*
* @license Apache-2.0
*
* Copyright (c) 2021 The Stdlib Authors.
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

// TypeScript Version: 2.0

/**
* Interface defining function options.
*/
interface Options {
	/**
	* Package meta information (package.json) (default: {}).
	*/
	pkg?: any;

	/**
	* Command-line interface version.
	*/
	version?: string;

	/**
	* Help text (default: '').
	*/
	help?: string;

	/**
	* Process title or a boolean indicating whether to set the process title (default: true).
	*/
	title?: string | boolean;

	/**
	* Boolean indicating whether to check if a command-line interface is an outdated version (default: true).
	*/
	updates?: boolean;

	/**
	* Command-line arguments.
	*/
	argv?: Array<any>;

	/**
	* Command-line interface options (default: {}).
	*/
	options?: Options;
}

/**
* Command-line interface.
*/
declare class CLI {
	/**
	* Command-line interface constructor.
	*
	* @param options - options
	* @param options.pkg - package meta information (package.json) (default: {})
	* @param options.version - command-line interface version
	* @param options.help - help text (default: '')
	* @param options.title - process title or a boolean indicating whether to set the process title (default: true)
	* @param options.updates - boolean indicating whether to check if a command-line interface is an outdated version (default: true)
	* @param options.argv - command-line arguments
	* @param options.options - command-line interface options (default: {})
	* @throws must provide valid options
	* @returns command-line interface
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
	constructor( options?: Options );

	/**
	* Returns parsed command-line arguments.
	*
	* @returns parsed command-line arguments
	*
	* @example
	* var cli = new CLI();
	*
	* var args = cli.args();
	* // returns <Array>
	*/
	args(): Array<string>;

	/**
	* Returns parsed command-line arguments.
	*
	* @returns parsed command-line arguments
	*
	* @example
	* var cli = new CLI();
	*
	* var args = cli.args();
	* // returns <Array>
	*/
	flags(): Array<string>;

	/**
	* Prints usage information and exits the process.
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
	help(): void;

	/**
	* Prints the command-line interface version and exits the process.
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
	version(): void;

	/**
	* Gracefully exits the command-line interface and the calling process.
	*
	* @param code - exit code (default: 0)
	* @throws must provide a nonnegative integer
	*
	* @example
	* var cli = new CLI();
	*
	* // Gracefully exit:
	* cli.close();
	*/
	close( code?: number ): void;

	/**
	* Exits the command-line interface and the calling process due to an error.
	*
	* ## Notes
	*
	* -   The value assigned to the `message` property of the provided `Error` object is printed to `stderr` prior to exiting the command-line interface and the calling process.
	*
	* @param error - error object
	* @param code - exit code (default: 1)
	* @throws second argument must be a nonnegative integer
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
	error( error: Error, code?: number ): void;

	/**
	* Forces the command-line interface (and the calling process) to exit.
	*
	* @param code - exit code (default: 0)
	* @throws must provide a nonnegative integer
	*
	* @example
	* var cli = new CLI();
	*
	* // Forcefully exit:
	* cli.exit();
	*/
	exit( code?: number ): void;
}


// EXPORTS //

export = CLI;
