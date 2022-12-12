/*
* @license Apache-2.0
*
* Copyright (c) 2020 The Stdlib Authors.
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

import exists = require( './index' );

const done = ( error: Error | null, bool: boolean ) => {
	if ( error || ( bool !== true && bool !== false ) ) {
		throw error;
	}
};


// TESTS //

// The function does not have a return value...
{
	exists( 'beepboop', done ); // $ExpectType void
	exists( '/var/www/html', done ); // $ExpectType void
}

// The compiler throws an error if the function is provided a first argument which is not a string...
{
	exists( 1, done ); // $ExpectError
	exists( false, done ); // $ExpectError
	exists( true, done ); // $ExpectError
	exists( null, done ); // $ExpectError
	exists( undefined, done ); // $ExpectError
	exists( [], done ); // $ExpectError
	exists( {}, done ); // $ExpectError
	exists( ( x: number ): number => x, done ); // $ExpectError
}

// The compiler throws an error if the function is provided a second argument which is not a function with the expected signature...
{
	exists( 'beepboop', 1 ); // $ExpectError
	exists( 'beepboop', false ); // $ExpectError
	exists( 'beepboop', true ); // $ExpectError
	exists( 'beepboop', null ); // $ExpectError
	exists( 'beepboop', undefined ); // $ExpectError
	exists( 'beepboop', [] ); // $ExpectError
	exists( 'beepboop', {} ); // $ExpectError
	exists( 'beepboop', ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided an unsupported number of arguments...
{
	exists(); // $ExpectError
	exists( 'C:\\foo\\bar\\baz' ); // $ExpectError
}

// Attached to main export is a `sync` method which returns a boolean...
{
	exists.sync( '/var/www/html' ); // $ExpectType boolean
	exists.sync( '/foo/bar/baz' ); // $ExpectType boolean
}

// The compiler throws an error if the `sync` method is provided a first argument which is not a string...
{
	exists.sync( 1 ); // $ExpectError
	exists.sync( false ); // $ExpectError
	exists.sync( true ); // $ExpectError
	exists.sync( null ); // $ExpectError
	exists.sync( undefined ); // $ExpectError
	exists.sync( [] ); // $ExpectError
	exists.sync( {} ); // $ExpectError
	exists.sync( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided an unsupported number of arguments...
{
	exists.sync(); // $ExpectError
}
