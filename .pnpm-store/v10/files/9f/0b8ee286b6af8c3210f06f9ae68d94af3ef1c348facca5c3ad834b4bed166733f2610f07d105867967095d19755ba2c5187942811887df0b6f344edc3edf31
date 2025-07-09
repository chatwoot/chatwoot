/*
* @license Apache-2.0
*
* Copyright (c) 2020 The Stdlib Authors.
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

/// <reference types="node"/>

import { Buffer } from 'buffer';

/**
* Interface defining function options.
*/
interface Options {
	/**
	* Encoding (default: null).
	*/
	encoding?: string | null;

	/**
	* Flag (default: 'r').
	*/
	flag?: string;
}

/**
* Callback invoked upon reading a file.
*
* @param err - error object
* @param file - file contents
*/
type Callback = ( err: Error | null, file: Buffer | string ) => void;

/**
* Interface for reading a file.
*/
interface ReadFile {
	/**
	* Asynchronously reads the entire contents of a file.
	*
	* @param file - file path or file descriptor
	* @param options - options
	* @param options.encoding - file encoding
	* @param options.flag - file status flag
	* @param clbk - callback to invoke after reading file contents
	*
	* @example
	* function onFile( error, data ) {
	*     if ( error ) {
	*         throw error;
	*     }
	*     console.log( data );
	* }
	* readFile( __filename, onFile );
	*/
	( file: string | Buffer | number, options: Options | string, clbk: Callback ): void; // tslint-disable-line max-line-length

	/**
	* Asynchronously reads the entire contents of a file.
	*
	* @param file - file path or file descriptor
	* @param clbk - callback to invoke after reading file contents
	*
	* @example
	* function onFile( error, data ) {
	*     if ( error ) {
	*         throw error;
	*     }
	*     console.log( data );
	* }
	* readFile( __filename, onFile );
	*/
	( file: string | Buffer | number, clbk: Callback ): void;

	/**
	* Synchronously reads the entire contents of a file.
	*
	* @param file - file path or file descriptor
	* @param option - options
	* @param options.encoding - file encoding
	* @param options.flag - file status flag
	* @returns file contents or an error
	*
	* @example
	* var out = readFile.sync( __filename );
	* if ( out instanceof Error ) {
	*     throw out;
	* }
	* console.log( out );
	*/
	sync( file: string | Buffer | number, options?: Options | string ): Buffer | string | Error; // tslint-disable-line max-line-length
}

/**
* Asynchronously reads the entire contents of a file.
*
* @param file - file path or file descriptor
* @param options - options
* @param options.encoding - file encoding
* @param options.flag - file status flag
* @param clbk - callback to invoke after reading file contents
*
* @example
* function onFile( error, data ) {
*     if ( error ) {
*         throw error;
*     }
*     console.log( data );
* }
* readFile( __filename, onFile );
*
* @example
* var out = readFile.sync( __filename );
* if ( out instanceof Error ) {
*     throw out;
* }
* console.log( out );
*/
declare var readFile: ReadFile;


// EXPORTS //

export = readFile;
