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

import fromString = require( './index' );

// TESTS //

// The function returns a buffer...
{
	fromString( 'beep boop' ); // $ExpectType Buffer
	fromString( 'beep boop', 'utf-8' ); // $ExpectType Buffer
}

// The compiler throws an error if the function is provided a first argument which is not a string...
{
	fromString( 123 ); // $ExpectError
	fromString( false ); // $ExpectError
	fromString( true ); // $ExpectError
	fromString( null ); // $ExpectError
	fromString( {} ); // $ExpectError
	fromString( [] ); // $ExpectError
	fromString( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided a second argument which is not a string...
{
	fromString( 'beep boop', 123 ); // $ExpectError
	fromString( 'beep boop', false ); // $ExpectError
	fromString( 'beep boop', true ); // $ExpectError
	fromString( 'beep boop', null ); // $ExpectError
	fromString( 'beep boop', {} ); // $ExpectError
	fromString( 'beep boop', [] ); // $ExpectError
	fromString( 'beep boop', ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided an invalid number of arguments...
{
	fromString(); // $ExpectError
	fromString( 'beep boop', 'utf-8', 3 ); // $ExpectError
}
