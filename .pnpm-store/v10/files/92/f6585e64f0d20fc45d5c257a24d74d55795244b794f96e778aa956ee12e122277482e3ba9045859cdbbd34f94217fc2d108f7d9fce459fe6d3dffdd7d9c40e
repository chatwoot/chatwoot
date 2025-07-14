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

import reFromString = require( './index' );


// TESTS //

// The function returns an object...
{
	reFromString( '/beep/' ); // $ExpectType RegExp | null
	reFromString( '/malformed' ); // $ExpectType RegExp | null
}

// The compiler throws an error if the function is provided a value other than a string...
{
	reFromString( true ); // $ExpectError
	reFromString( false ); // $ExpectError
	reFromString( 5 ); // $ExpectError
	reFromString( [] ); // $ExpectError
	reFromString( {} ); // $ExpectError
	reFromString( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided an invalid number of arguments...
{
	reFromString(); // $ExpectError
	reFromString( '/beep/', 2 ); // $ExpectError
	reFromString( '/beep/', 2, 3 ); // $ExpectError
}
