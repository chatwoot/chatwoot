/*
* @license Apache-2.0
*
* Copyright (c) 2019 The Stdlib Authors.
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
* Interface defining `isString` with methods for testing for primitives and objects, respectively.
*/
interface IsString {
	/**
	* Tests if a value is a string.
	*
	* @param value - value to test
	* @returns boolean indicating whether value is a string
	*
	* @example
	* var bool = isString( new String( 'beep' ) );
	* // returns true
	*
	* @example
	* var bool = isString( 'beep' );
	* // returns true
	*/
	( value: any ): boolean;

	/**
	* Tests if a value is a string primitive.
	*
	* @param value - value to test
	* @returns boolean indicating if a value is a string primitive
	*
	* @example
	* var bool = isString.isPrimitive( 'beep' );
	* // returns true
	*
	* @example
	* var bool = isString.isPrimitive( new String( 'beep' ) );
	* // returns false
	*/
	isPrimitive( value: any ): boolean;

	/**
	* Tests if a value is a string object.
	*
	* @param value - value to test
	* @returns boolean indicating if a value is a string object
	*
	* @example
	* var bool = isString.isObject( new String( 'beep' ) );
	* // returns true
	*
	* @example
	* var bool = isString.isObject( 'beep' );
	* // returns false
	*/
	isObject( value: any ): boolean;
}

/**
* Tests if a value is a string.
*
* @param value - value to test
* @returns boolean indicating whether value is a string
*
* @example
* var bool = isString( new String( 'beep' ) );
* // returns true
*
* @example
* var bool = isString( 'beep' );
* // returns true
*
* @example
* var bool = isString.isPrimitive( 'beep' );
* // returns true
*
* @example
* var bool = isString.isObject( 'beep' );
* // returns false
*/
declare var isString: IsString;


// EXPORTS //

export = isString;
