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
	flags: string;

	/**
	* Minimum field width (integer or `'*'`).
	*/
	width: string;

	/**
	* Precision (integer or `'*'`).
	*/
	precision: string;

	/**
	* Positional mapping from format specifier to argument index.
	*/
	mapping: number;
}

type StringOrToken = string | FormatIdentifier;

/**
* Tokenizes a string into an array of string parts and format identifier objects.
*
* @param str - input string
* @returns tokens
*
* @example
* var tokens = formatTokenize( 'Hello %s!' );
* // returns [ 'Hello ', {...}, '!' ]
*/
declare function formatTokenize( str: string ): Array<StringOrToken>;


// EXPORTS //

export = formatTokenize;
