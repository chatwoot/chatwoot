/*
* @license Apache-2.0
*
* Copyright (c) 2022 The Stdlib Authors.
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
* Format identifier object.
*/
interface FormatIdentifier {
	/**
	* Format specifier (one of 's', 'c', 'd', 'i', 'u', 'b', 'o', 'x', 'X', 'e', 'E', 'f', 'F', 'g', 'G').
	*/
	specifier: string;

	/**
	* Flags.
	*/
	flags?: string;

	/**
	* Minimum field width (integer or `'*'`).
	*/
	width?: string;

	/**
	* Precision (integer or `'*'`).
	*/
	precision?: string;

	/**
	* Positional mapping from format specifier to argument index.
	*/
	mapping?: number;
}

type StringOrToken = string | FormatIdentifier;

/**
* Generates string from a token array by interpolating values.
*
* @param tokens - string parts and format identifier objects
* @param ...args - variable values
* @throws invalid flags
* @returns formatted string
*
* @example
* var tokens = [ 'beep ', { 'specifier': 's' } ];
* var out = formatInterpolate( tokens, 'boop' );
* // returns 'beep boop'
*/
declare function formatInterpolate( tokens: Array<StringOrToken>, ...args: Array<any> ): string;


// EXPORTS //

export = formatInterpolate;
