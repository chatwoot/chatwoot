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

import defineProperty = require( './index' );


// TESTS //

// The function returns an object...
{
	defineProperty( {}, 'foo', { 'value': 'bar' } ); // $ExpectType any
}

// The compiler throws an error if the function is provided a second argument which is not a valid property name...
{
	defineProperty( {}, true, { 'value': 'bar' } ); // $ExpectError
	defineProperty( {}, false, { 'value': 'bar' } ); // $ExpectError
	defineProperty( {}, [], { 'value': 'bar' } ); // $ExpectError
	defineProperty( {}, {}, { 'value': 'bar' } ); // $ExpectError
	defineProperty( {}, ( x: number ): number => x, { 'value': 'bar' } ); // $ExpectError
}

// The compiler throws an error if the function is provided insufficient arguments...
{
	defineProperty(); // $ExpectError
	defineProperty( {} ); // $ExpectError
	defineProperty( {}, 'foo' ); // $ExpectError
}
