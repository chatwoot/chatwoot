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
* Interface defining function options.
*/
interface Options {
	/**
	* Base directory from which to search (default: current working directory).
	*/
	dir?: string;
}

/**
* Callback invoked after resolving a path.
*
* @param err - error argument
* @param path - resolved path
*/
type Callback = ( err: Error | null, path: string | null ) => void;

/**
* Interface for resolving a path by walking parent directories.
*/
interface ResolveParentPath {
	/**
	* Asynchronously resolves a path by walking parent directories.
	*
	* @param path - path to resolve
	* @param options - function options
	* @param options.dir - base directory
	* @param clbk - callback to invoke after resolving a path
	* @throws must provide valid options
	*
	* @example
	* resolveParentPath( 'package.json', { 'dir': __dirname }, onPath );
	*
	* function onPath( error, path ) {
	*     if ( error ) {
	*         throw error;
	*     }
	*     console.log( path );
	* }
	*/
	( path: string, options: Options, clbk: Callback ): void;

	/**
	* Asynchronously resolves a path by walking parent directories.
	*
	* @param path - path to resolve
	* @param clbk - callback to invoke after resolving a path
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
	( path: string, clbk: Callback ): void;

	/**
	* Synchronously resolves a path by walking parent directories.
	*
	* ## Notes
	*
	* -   If unable to resolve a path, the function returns `null` as the path result.
	*
	* @param path - path to resolve
	* @param options - function options
	* @param options.dir - base directory
	* @throws must provide valid options
	* @returns resolved path or null
	*
	* @example
	* var path = resolveParentPath.sync( 'package.json', { 'dir': __dirname } );
	*/
	sync( path: string, options?: Options ): string | null;
}

/**
* Asynchronously resolves a path by walking parent directories.
*
* @param path - path to resolve
* @param options - function options
* @param options.dir - base directory
* @param clbk - callback to invoke after resolving a path
* @throws must provide valid options
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
*
* @example
* var path = resolveParentPath.sync( 'package.json' );
*/
declare var resolveParentPath: ResolveParentPath;


// EXPORTS //

export = resolveParentPath;
