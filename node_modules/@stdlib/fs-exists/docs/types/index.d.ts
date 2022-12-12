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

/**
* Callback invoked after testing for path existence.
*
* @param bool - boolean indicating whether a path exists
*/
type Unary = ( bool: boolean ) => void;

/**
* Callback invoked after testing for path existence.
*
* @param err - error argument
* @param bool - boolean indicating whether a path exists
*/
type Binary = ( err: Error | null, bool: boolean ) => void;

/**
* Callback invoked after testing for path existence.
*
* @param err - error argument
* @param bool - boolean indicating whether a path exists
*/
type Callback = Unary | Binary;

/**
* Interface for testing whether a path exists on the filesystem.
*/
interface Exists {
	/**
	* Tests whether a path exists on the filesystem.
	*
	* @param path - path to test
	* @param clbk - callback to invoke after testing path existence
	*
	* @example
	* exists( __dirname, done );
	*
	* function done( error, bool ) {
	*     if ( error ) {
	*         console.error( error );
	*     }
	*     if ( bool ) {
	*         console.log( '...path exists.' );
	*     } else {
	*         console.log( '...path does not exist.' );
	*     }
	* }
	*/
	( path: string, clbk: Callback ): void;

	/**
	* Synchronously tests whether a path exists on the filesystem.
	*
	* @param path - path to test
	* @returns boolean indicating whether the path exists
	*
	* @example
	* var bool = exists.sync( __dirname );
	* // returns <boolean>
	*/
	sync( path: string ): boolean;
}

/**
* Tests whether a path exists on the filesystem.
*
* @param path - path to test
* @param clbk - callback to invoke after testing path existence
*
* @example
* exists( __dirname, done );
*
* function done( error, bool ) {
*     if ( error ) {
*         console.error( error );
*     }
*     if ( bool ) {
*         console.log( '...path exists.' );
*     } else {
*         console.log( '...path does not exist.' );
*     }
* }
*
* @example
* var bool = exists.sync( __dirname );
* // returns <boolean>
*/
declare var exists: Exists;


// EXPORTS //

export = exists;
