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
* Interface defining `isNumber` with methods for testing for primitives and objects, respectively.
*/
interface IsNumber {
	/**
	* Tests if a value is a number.
	*
	* @param value - value to test
	* @returns boolean indicating whether value is a number
	*
	* @example
	* var bool = isNumber( 3.14 );
	* // returns true
	*
	* @example
	* var bool = isNumber( new Number( 3.14 ) );
	* // returns true
	*
	* @example
	* var bool = isNumber( NaN );
	* // returns true
	*
	* @example
	* var bool = isNumber( null );
	* // returns false
	*/
	( value: any ): boolean;

	/**
	* Tests if a value is a number primitive.
	*
	* @param value - value to test
	* @returns boolean indicating if a value is a number primitive
	*
	* @example
	* var bool = isNumber.isPrimitive( 3.14 );
	* // returns true
	*
	* @example
	* var bool = isNumber.isPrimitive( NaN );
	* // returns true
	*
	* @example
	* var bool = isNumber.isPrimitive( new Number( 3.14 ) );
	* // returns false
	*/
	isPrimitive( value: any ): boolean;

	/**
	* Tests if a value is a number object.
	*
	* @param value - value to test
	* @returns boolean indicating if a value is a number object
	*
	* @example
	* var bool = isNumber.isObject( 3.14 );
	* // returns false
	*
	* @example
	* var bool = isNumber.isObject( new Number( 3.14 ) );
	* // returns true
	*/
	isObject( value: any ): boolean;
}

/**
* Tests if a value is a number.
*
* @param value - value to test
* @returns boolean indicating whether value is a number
*
* @example
* var bool = isNumber( 3.14 );
* // returns true
*
* @example
* var bool = isNumber( new Number( 3.14 ) );
* // returns true
*
* @example
* var bool = isNumber( NaN );
* // returns true
*
* @example
* var bool = isNumber( null );
* // returns false
*
* @example
* var bool = isNumber.isPrimitive( 3.14 );
* // returns true
*
* @example
* var bool = isNumber.isObject( new Number( 3.14 ) );
* // returns true
*/
declare var isNumber: IsNumber;


// EXPORTS //

export = isNumber;
