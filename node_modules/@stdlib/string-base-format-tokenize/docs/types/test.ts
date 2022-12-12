/*
* @license Apache-2.0
*
* Copyright (c) 2022 The Stdlib Authors.
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

import formatTokenize = require( './index' );


// TESTS //

// The function returns an array of string parts and format identifier objects...
{
	formatTokenize( 'Hello, %s!' ); // $ExpectType string
}

// The function does not compile if provided an argument other than a string...
{
	formatTokenize( true ); // $ExpectError
	formatTokenize( false ); // $ExpectError
	formatTokenize( null ); // $ExpectError
	formatTokenize( undefined ); // $ExpectError
	formatTokenize( 5 ); // $ExpectError
	formatTokenize( [] ); // $ExpectError
	formatTokenize( {} ); // $ExpectError
	formatTokenize( ( x: number ): number => x ); // $ExpectError
}

// The function does not compile if provided insufficient arguments...
{
	formatTokenize(); // $ExpectError
}
