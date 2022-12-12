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

import readFile = require( './index' );

const onLoad = ( error: Error | null, file: string | Buffer ) => {
	if ( error || !file ) {
		throw error;
	}
};


// TESTS //

// The function does not have a return value...
{
	readFile( 'beepboop', onLoad ); // $ExpectType void
}

// The compiler throws an error if the function is provided a first argument which is not a string, buffer, or file descriptor...
{
	readFile( false, onLoad ); // $ExpectError
	readFile( true, onLoad ); // $ExpectError
	readFile( null, onLoad ); // $ExpectError
	readFile( undefined, onLoad ); // $ExpectError
	readFile( [], onLoad ); // $ExpectError
	readFile( {}, onLoad ); // $ExpectError
	readFile( ( x: number ): number => x, onLoad ); // $ExpectError
}

// The compiler throws an error if the function is provided a callback argument which is not a function with the expected signature...
{
	readFile( '/path/to/beepboop', 'abc' ); // $ExpectError
	readFile( '/path/to/beepboop', 1 ); // $ExpectError
	readFile( '/path/to/beepboop', false ); // $ExpectError
	readFile( '/path/to/beepboop', true ); // $ExpectError
	readFile( '/path/to/beepboop', null ); // $ExpectError
	readFile( '/path/to/beepboop', undefined ); // $ExpectError
	readFile( '/path/to/beepboop', [] ); // $ExpectError
	readFile( '/path/to/beepboop', {} ); // $ExpectError
	readFile( '/path/to/beepboop', ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided an options argument which is not an object or string...
{
	readFile( 'beepboop', false, onLoad ); // $ExpectError
	readFile( 'beepboop', true, onLoad ); // $ExpectError
	readFile( 'beepboop', null, onLoad ); // $ExpectError
	readFile( 'beepboop', undefined, onLoad ); // $ExpectError
	readFile( 'beepboop', 123, onLoad ); // $ExpectError
	readFile( 'beepboop', [], onLoad ); // $ExpectError
	readFile( 'beepboop', ( x: number ): number => x, onLoad ); // $ExpectError
}

// The compiler throws an error if the function is provided an `encoding` option which is not a string or null...
{
	readFile( 'beepboop', { 'encoding': 123 }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'encoding': true }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'encoding': false }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'encoding': [] }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'encoding': {} }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'encoding': ( x: number ): number => x }, onLoad ); // $ExpectError
}

// The compiler throws an error if the function is provided a `flag` option which is not a string...
{
	readFile( 'beepboop', { 'flag': 123 }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'flag': true }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'flag': false }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'flag': null }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'flag': [] }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'flag': {} }, onLoad ); // $ExpectError
	readFile( 'beepboop', { 'flag': ( x: number ): number => x }, onLoad ); // $ExpectError
}

// The compiler throws an error if the function is provided an unsupported number of arguments...
{
	readFile(); // $ExpectError
	readFile( 'C:\\foo\\bar\\baz\\beepboop' ); // $ExpectError
}

// Attached to main export is a `sync` method which returns a string or an error...
{
	readFile.sync( 'beepboop' ); // $ExpectType string | Buffer | Error
}

// The compiler throws an error if the `sync` method is provided a first argument which is not a string, buffer, or file descriptor...
{
	readFile.sync( false ); // $ExpectError
	readFile.sync( true ); // $ExpectError
	readFile.sync( null ); // $ExpectError
	readFile.sync( undefined ); // $ExpectError
	readFile.sync( [] ); // $ExpectError
	readFile.sync( {} ); // $ExpectError
	readFile.sync( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided an options argument which is not an object or string...
{
	readFile.sync( 'beepboop', null ); // $ExpectError
	readFile.sync( 'beepboop', true ); // $ExpectError
	readFile.sync( 'beepboop', false ); // $ExpectError
	readFile.sync( 'beepboop', 123 ); // $ExpectError
	readFile.sync( 'beepboop', [] ); // $ExpectError
	readFile.sync( 'beepboop', ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided an `encoding` option which is not a string or null...
{
	readFile.sync( 'beepboop', { 'encoding': 123 } ); // $ExpectError
	readFile.sync( 'beepboop', { 'encoding': true } ); // $ExpectError
	readFile.sync( 'beepboop', { 'encoding': false } ); // $ExpectError
	readFile.sync( 'beepboop', { 'encoding': [] } ); // $ExpectError
	readFile.sync( 'beepboop', { 'encoding': {} } ); // $ExpectError
	readFile.sync( 'beepboop', { 'encoding': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided a `flag` option which is not a string...
{
	readFile.sync( 'beepboop', { 'flag': 123 } ); // $ExpectError
	readFile.sync( 'beepboop', { 'flag': true } ); // $ExpectError
	readFile.sync( 'beepboop', { 'flag': false } ); // $ExpectError
	readFile.sync( 'beepboop', { 'flag': null } ); // $ExpectError
	readFile.sync( 'beepboop', { 'flag': [] } ); // $ExpectError
	readFile.sync( 'beepboop', { 'flag': {} } ); // $ExpectError
	readFile.sync( 'beepboop', { 'flag': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided an unsupported number of arguments...
{
	readFile.sync(); // $ExpectError
}
