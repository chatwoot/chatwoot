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

import ldexp = require( './index' );


// TESTS //

// The function returns a number...
{
	ldexp( 0.5, 3 ); // $ExpectType number
}

// The function does not compile if provided values other than two numbers...
{
	ldexp( true, 3 ); // $ExpectError
	ldexp( false, 2 ); // $ExpectError
	ldexp( '5', 1 ); // $ExpectError
	ldexp( [], 1 ); // $ExpectError
	ldexp( {}, 2 ); // $ExpectError
	ldexp( ( x: number ): number => x, 2 ); // $ExpectError

	ldexp( 9, true ); // $ExpectError
	ldexp( 9, false ); // $ExpectError
	ldexp( 5, '5' ); // $ExpectError
	ldexp( 8, [] ); // $ExpectError
	ldexp( 9, {} ); // $ExpectError
	ldexp( 8, ( x: number ): number => x ); // $ExpectError

	ldexp( [], true ); // $ExpectError
	ldexp( {}, false ); // $ExpectError
	ldexp( false, '5' ); // $ExpectError
	ldexp( {}, [] ); // $ExpectError
	ldexp( '5', ( x: number ): number => x ); // $ExpectError
}

// The function does not compile if provided insufficient arguments...
{
	ldexp(); // $ExpectError
	ldexp( 3 ); // $ExpectError
}
