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

import formatInterpolate = require( './index' );


// TESTS //

// The function returns a string...
{
	formatInterpolate( [ 'beep ', { 'specifier': 's' }], 'boop' ); // $ExpectType string
	formatInterpolate( [] ); // $ExpectType string
}

// The function does not compile if provided a first argument other than an array...
{
	formatInterpolate( 'abc' ); // $ExpectError
	formatInterpolate( true ); // $ExpectError
	formatInterpolate( false ); // $ExpectError
	formatInterpolate( null ); // $ExpectError
	formatInterpolate( undefined ); // $ExpectError
	formatInterpolate( 5 ); // $ExpectError
	formatInterpolate( {} ); // $ExpectError
	formatInterpolate( ( x: number ): number => x ); // $ExpectError
}

// The function does not compile if provided insufficient arguments...
{
	formatInterpolate(); // $ExpectError
}
