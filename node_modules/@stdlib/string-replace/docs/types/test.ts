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

import replace = require( './index' );


// TESTS //

// The function returns a string...
{
	replace( 'abd', 'd', 'c' ); // $ExpectType string
	replace( 'abd', /[a-z]/, '1' ); // $ExpectType string
	replace( 'abd', /[a-z]/, (): string => 'z' ); // $ExpectType string
}

// The function does not compile if provided arguments of invalid types...
{
	replace( true, 'd', 'a' ); // $ExpectError
	replace( false, 'd', 'a' ); // $ExpectError
	replace( 3, 'd', 'a' ); // $ExpectError
	replace( [], 'd', 'a' ); // $ExpectError
	replace( {}, 'd', 'a' ); // $ExpectError
	replace( ( x: number ): number => x, 'd', 'a' ); // $ExpectError

	replace( 'abd', true, 'c' ); // $ExpectError
	replace( 'abd', false, 'c' ); // $ExpectError
	replace( 'abd', 5, 'c' ); // $ExpectError
	replace( 'abd', [], 'c' ); // $ExpectError
	replace( 'abd', {}, 'c' ); // $ExpectError
	replace( 'abd', ( x: number ): number => x, 'c' ); // $ExpectError

	replace( 'abd', 'd', true ); // $ExpectError
	replace( 'abd', 'd', false ); // $ExpectError
	replace( 'abd', 'd', 5 ); // $ExpectError
	replace( 'abd', 'd', [] ); // $ExpectError
	replace( 'abd', 'd', {} ); // $ExpectError
	replace( 'abd', 'd', /[a-z]/ ); // $ExpectError
}

// The function does not compile if provided insufficient arguments...
{
	replace(); // $ExpectError
	replace( 'abc' ); // $ExpectError
	replace( 'abc', 'a' ); // $ExpectError
}
