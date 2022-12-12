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

import isnan = require( './index' );


// TESTS //

// The function returns a boolean...
{
	isnan( NaN ); // $ExpectType boolean
	isnan( 2 ); // $ExpectType boolean
	isnan( 3 ); // $ExpectType boolean
}

// The function does not compile if provided a value other than a number...
{
	isnan( true ); // $ExpectError
	isnan( false ); // $ExpectError
	isnan( null ); // $ExpectError
	isnan( undefined ); // $ExpectError
	isnan( [] ); // $ExpectError
	isnan( {} ); // $ExpectError
	isnan( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided an unsupported number of arguments...
{
	isnan(); // $ExpectError
	isnan( undefined, 123 ); // $ExpectError
}
