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
* Interface for a regular expression to capture everything that is not a space immediately after the `function` keyword and before the first left parenthesis.
*/
interface ReFunctionName {
	/**
	* Returns a regular expression to capture everything that is not a space immediately after the `function` keyword and before the first left parenthesis.
	*
	* @returns regular expression
	*
	* @example
	* var RE_FUNCTION_NAME = reFunctionName();
	* function beep() {
	*     return 'boop';
	* }
	*
	* var str = RE_FUNCTION_NAME.exec( beep.toString() )[ 1 ];
	* // returns 'beep'
	*/
	(): RegExp;

	/**
	* Regular expression to capture everything that is not a space immediately after the `function` keyword and before the first left parenthesis.
	*
	* @example
	* var str = reFunctionName.REGEXP.exec( Math.sqrt.toString() )[ 1 ];
	* // returns 'sqrt'
	*/
	REGEXP: RegExp;
}

/**
* Returns a regular expression to capture everything that is not a space immediately after the `function` keyword and before the first left parenthesis.
*
* @returns regular expression
*
* @example
* var RE_FUNCTION_NAME = reFunctionName();
* function beep() {
*     return 'boop';
* }
*
* var str = RE_FUNCTION_NAME.exec( beep.toString() )[ 1 ];
* // returns 'beep'
*
* @example
* var str = reFunctionName.REGEXP.exec( Math.sqrt.toString() )[ 1 ];
* // returns 'sqrt'
*/
declare var reFunctionName: ReFunctionName;


// EXPORTS //

export = reFunctionName;
