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

import fromWords = require( './index' );


// TESTS //

// The function returns a number...
{
	fromWords( 1774486211, 2479577218 ); // $ExpectType number
}

// The function does not compile if provided a first argument that is not a number...
{
	fromWords( 'abc', 2479577218 ); // $ExpectError
	fromWords( true, 2479577218 ); // $ExpectError
	fromWords( false, 2479577218 ); // $ExpectError
	fromWords( [], 2479577218 ); // $ExpectError
	fromWords( {}, 2479577218 ); // $ExpectError
	fromWords( ( x: number ): number => x, 2479577218 ); // $ExpectError
}

// The function does not compile if provided a second argument that is not a number...
{
	fromWords( 1774486211, 'abc' ); // $ExpectError
	fromWords( 1774486211, true ); // $ExpectError
	fromWords( 1774486211, false ); // $ExpectError
	fromWords( 1774486211, [] ); // $ExpectError
	fromWords( 1774486211, {} ); // $ExpectError
	fromWords( 1774486211, ( x: number ): number => x ); // $ExpectError
}

// The function does not compile if provided insufficient arguments...
{
	fromWords(); // $ExpectError
	fromWords( 1774486211 ); // $ExpectError
}
