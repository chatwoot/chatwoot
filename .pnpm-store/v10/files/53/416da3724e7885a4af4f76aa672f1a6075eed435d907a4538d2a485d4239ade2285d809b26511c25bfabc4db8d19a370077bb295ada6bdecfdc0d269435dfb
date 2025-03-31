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

import copysign = require( './index' );


// TESTS //

// The function returns a number...
{
	copysign( -3.14, 10 ); // $ExpectType number
	copysign( 3.14, -10 ); // $ExpectType number
}

// The compiler throws an error if the function is provided values other than two numbers...
{
	copysign( true, 3 ); // $ExpectError
	copysign( false, 2 ); // $ExpectError
	copysign( '5', 1 ); // $ExpectError
	copysign( [], 1 ); // $ExpectError
	copysign( {}, 2 ); // $ExpectError
	copysign( ( x: number ): number => x, 2 ); // $ExpectError

	copysign( -9, true ); // $ExpectError
	copysign( -9, false ); // $ExpectError
	copysign( -5, '5' ); // $ExpectError
	copysign( -8, [] ); // $ExpectError
	copysign( -9, {} ); // $ExpectError
	copysign( -8, ( x: number ): number => x ); // $ExpectError

	copysign( [], true ); // $ExpectError
	copysign( {}, false ); // $ExpectError
	copysign( false, '5' ); // $ExpectError
	copysign( {}, [] ); // $ExpectError
	copysign( '5', ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided insufficient arguments...
{
	copysign(); // $ExpectError
	copysign( -3 ); // $ExpectError
}
