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

import nextTick = require( './index' );


// TESTS //

// The function returns `undefined`...
{
	nextTick( (): void => { return; } ); // $ExpectType void
	nextTick( ( x: number ): number => x, 3.14 ); // $ExpectType void
}

// The compiler throws an error if the function is provided a first argument which is not a function...
{
	nextTick( '5' ); // $ExpectError
	nextTick( 5 ); // $ExpectError
	nextTick( true ); // $ExpectError
	nextTick( false ); // $ExpectError
	nextTick( null ); // $ExpectError
	nextTick( void 0 ); // $ExpectError
	nextTick( [] ); // $ExpectError
	nextTick( {} ); // $ExpectError
}

// The compiler throws an error if the function is provided insufficient arguments...
{
	nextTick(); // $ExpectError
}
