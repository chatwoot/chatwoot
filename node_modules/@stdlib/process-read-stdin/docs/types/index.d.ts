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

/// <reference types="node"/>

import { Buffer } from 'buffer';

/**
* Callback invoked upon reading all data from `stdin`.
*
* @param err - error object
* @param data - data contents
*/
type Callback = ( err: Error | null, data: Buffer | string ) => void;

/**
* Interface for reading from `stdin`.
*/
interface StdIn {
	/**
	* Reads data from `stdin`.
	*
	* @param encoding - string encoding. If set, data will be returned as an encoded `string`
	* @param clbk - callback to be invoked upon reading all data from `stdin`
	*
	* @example
	* function onRead( error, data ) {
	*     if ( error ) {
	*         throw error;
	*     }
	*     console.log( data );
	*     // => '...'
	* }
	*
	* stdin( 'utf8', onRead );
	*/
	( encoding: string | null, clbk: Callback ): void; // tslint-disable-line max-line-length

	/**
	* Reads data from `stdin`.
	*
	* @param clbk - callback to be invoked upon reading all data from `stdin`
	*
	* @example
	* function onRead( error, data ) {
	*     if ( error ) {
	*         throw error;
	*     }
	*     console.log( data.toString() );
	*     // => '...'
	* }
	*
	* stdin( onRead );
	*/
	( clbk: Callback ): void;
}

/**
* Reads data from `stdin`.
*
* @param encoding - string encoding. If set, data will be returned as an encoded `string`
* @param clbk - callback to be invoked upon reading all data from `stdin`
*
* @example
* function onRead( error, data ) {
*     if ( error ) {
*         throw error;
*     }
*     console.log( data.toString() );
*     // => '...'
* }
*
* stdin( onRead );
*
* @example
* function onRead( error, data ) {
*     if ( error ) {
*         throw error;
*     }
*     console.log( data );
*     // => '...'
* }
*
* stdin( 'utf8', onRead );
*/
declare var stdin: StdIn;


// EXPORTS //

export = stdin;
