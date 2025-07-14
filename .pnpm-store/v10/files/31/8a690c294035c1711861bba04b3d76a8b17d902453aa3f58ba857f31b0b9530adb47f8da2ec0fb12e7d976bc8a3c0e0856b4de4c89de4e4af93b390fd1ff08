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
* Interface for a regular expression to test if a string is an extended-length path.
*/
interface ReExtendedLengthPath {
	/**
	* Returns a regular expression to test if a string is an extended-length path.
	*
	* @returns regular expression
	*
	* @example
	* var RE_EXTENDED_LENGTH_PATH = reExtendedLengthPath();
	*
	* var bool = RE_EXTENDED_LENGTH_PATH.test( '\\\\?\\C:\\foo\\bar' );
	* // returns true
	*/
	(): RegExp;

	/**
	* Regular expression to test if a string is an extended-length path.
	*
	* @example
	* var bool = reExtendedLengthPath.REGEXP.test( 'C:\\foo\\bar' );
	* // returns false
	*/
	REGEXP: RegExp;
}

/**
* Returns a regular expression to test if a string is an extended-length path.
*
* @returns regular expression
*
* @example
* var RE_EXTENDED_LENGTH_PATH = reExtendedLengthPath();
*
* var bool = RE_EXTENDED_LENGTH_PATH.test( '\\\\?\\C:\\foo\\bar' );
* // returns true
*
* @example
* var bool = reExtendedLengthPath.REGEXP.test( 'C:\\foo\\bar' );
* // returns false
*/
declare var reExtendedLengthPath: ReExtendedLengthPath;


// EXPORTS //

export = reExtendedLengthPath;
