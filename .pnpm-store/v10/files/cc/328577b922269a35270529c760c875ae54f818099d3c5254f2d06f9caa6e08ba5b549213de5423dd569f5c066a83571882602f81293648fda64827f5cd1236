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

import stdin = require( './index' );

const onRead = ( error: Error | null, data: string | Buffer ) => {
	if ( error || !data ) {
		throw error;
	}
};


// TESTS //

// The function does not have a return value...
{
	stdin( onRead ); // $ExpectType void
	stdin( 'utf-8', onRead ); // $ExpectType void
}

// The compiler throws an error if the function is provided an `encoding` argument which is not a string or null...
{
	stdin( 123, onRead ); // $ExpectError
	stdin( false, onRead ); // $ExpectError
	stdin( true, onRead ); // $ExpectError
	stdin( undefined, onRead ); // $ExpectError
	stdin( [], onRead ); // $ExpectError
	stdin( {}, onRead ); // $ExpectError
	stdin( ( x: number ): number => x, onRead ); // $ExpectError
}

// The compiler throws an error if the function is provided a last argument which is not a function with the expected signature...
{
	stdin( 'abc' ); // $ExpectError
	stdin( 1 ); // $ExpectError
	stdin( false ); // $ExpectError
	stdin( true ); // $ExpectError
	stdin( null ); // $ExpectError
	stdin( undefined ); // $ExpectError
	stdin( [] ); // $ExpectError
	stdin( {} ); // $ExpectError
	stdin( ( x: number ): number => x ); // $ExpectError

	stdin( 'utf-8', 'abc' ); // $ExpectError
	stdin( 'utf-8', 1 ); // $ExpectError
	stdin( 'utf-8', false ); // $ExpectError
	stdin( 'utf-8', true ); // $ExpectError
	stdin( 'utf-8', null ); // $ExpectError
	stdin( 'utf-8', undefined ); // $ExpectError
	stdin( 'utf-8', [] ); // $ExpectError
	stdin( 'utf-8', {} ); // $ExpectError
	stdin( 'utf-8', ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided an unsupported number of arguments...
{
	stdin(); // $ExpectError
}
