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

import typeOf = require( './index' );


// TESTS //

// The function returns a string...
{
	typeOf( 5 ); // $ExpectType string
	typeOf( false ); // $ExpectType string
	typeOf( true ); // $ExpectType string
	typeOf( 'abc' ); // $ExpectType string
	typeOf( [] ); // $ExpectType string
	typeOf( {} ); // $ExpectType string
}

// The compiler throws an error if the function is provided an incorrect number of arguments...
{
	typeOf(); // $ExpectError
	typeOf( [], 2 ); // $ExpectError
}
