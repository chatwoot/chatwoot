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

import getGlobal = require( './index' );


// TESTS //

// The function returns an object...
{
	getGlobal(); // $ExpectType any
	getGlobal( true ); // $ExpectType any
	getGlobal( false ); // $ExpectType any
}

// The compiler throws an error if the function is provided a value other than a boolean...
{
	getGlobal( 'abc' ); // $ExpectError
	getGlobal( 5 ); // $ExpectError
	getGlobal( [] ); // $ExpectError
	getGlobal( {} ); // $ExpectError
	getGlobal( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided more than one argument...
{
	getGlobal( true, 2 ); // $ExpectError
	getGlobal( true, 2, 3 ); // $ExpectError
}
