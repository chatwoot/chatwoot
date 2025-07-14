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

import resolveParentPath = require( './index' );

const done = ( error: Error | null, path: string | null ) => {
	if ( error || path === null ) {
		throw error;
	}
};


// TESTS //

// The function does not have a return value...
{
	resolveParentPath( 'package.json', done ); // $ExpectType void
}

// The compiler throws an error if the function is provided a first argument which is not a string...
{
	resolveParentPath( 123, done ); // $ExpectError
	resolveParentPath( false, done ); // $ExpectError
	resolveParentPath( true, done ); // $ExpectError
	resolveParentPath( null, done ); // $ExpectError
	resolveParentPath( undefined, done ); // $ExpectError
	resolveParentPath( [], done ); // $ExpectError
	resolveParentPath( {}, done ); // $ExpectError
	resolveParentPath( ( x: number ): number => x, done ); // $ExpectError
}

// The compiler throws an error if the function is provided a callback argument which is not a function with the expected signature...
{
	resolveParentPath( '/var/log/', 1 ); // $ExpectError
	resolveParentPath( '/var/log/', false ); // $ExpectError
	resolveParentPath( '/var/log/', true ); // $ExpectError
	resolveParentPath( '/var/log/', null ); // $ExpectError
	resolveParentPath( '/var/log/', undefined ); // $ExpectError
	resolveParentPath( '/var/log/', [] ); // $ExpectError
	resolveParentPath( '/var/log/', {} ); // $ExpectError
	resolveParentPath( '/var/log/', ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided an options argument which is not an object...
{
	resolveParentPath( 'package.json', null, done ); // $ExpectError
}

// The compiler throws an error if the function is provided an `dir` option which is not a string...
{
	resolveParentPath( 'package.json', { 'dir': 123 }, done ); // $ExpectError
	resolveParentPath( 'package.json', { 'dir': true }, done ); // $ExpectError
	resolveParentPath( 'package.json', { 'dir': false }, done ); // $ExpectError
	resolveParentPath( 'package.json', { 'dir': null }, done ); // $ExpectError
	resolveParentPath( 'package.json', { 'dir': [] }, done ); // $ExpectError
	resolveParentPath( 'package.json', { 'dir': {} }, done ); // $ExpectError
	resolveParentPath( 'package.json', { 'dir': ( x: number ): number => x }, done ); // $ExpectError
}

// The compiler throws an error if the function is provided an unsupported number of arguments...
{
	resolveParentPath(); // $ExpectError
	resolveParentPath( 'C:\\foo\\bar\\baz' ); // $ExpectError
}

// Attached to main export is a `sync` method which returns a string or null...
{
	resolveParentPath.sync( 'package.json' ); // $ExpectType string | null
}

// The compiler throws an error if the `sync` method is provided a first argument which is not a string...
{
	resolveParentPath.sync( 123 ); // $ExpectError
	resolveParentPath.sync( false ); // $ExpectError
	resolveParentPath.sync( true ); // $ExpectError
	resolveParentPath.sync( null ); // $ExpectError
	resolveParentPath.sync( undefined ); // $ExpectError
	resolveParentPath.sync( [] ); // $ExpectError
	resolveParentPath.sync( {} ); // $ExpectError
	resolveParentPath.sync( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided an options argument which is not an object...
{
	resolveParentPath.sync( 'package.json', null ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided an `dir` option which is not a string...
{
	resolveParentPath.sync( 'package.json', { 'dir': 123 } ); // $ExpectError
	resolveParentPath.sync( 'package.json', { 'dir': true } ); // $ExpectError
	resolveParentPath.sync( 'package.json', { 'dir': false } ); // $ExpectError
	resolveParentPath.sync( 'package.json', { 'dir': null } ); // $ExpectError
	resolveParentPath.sync( 'package.json', { 'dir': [] } ); // $ExpectError
	resolveParentPath.sync( 'package.json', { 'dir': {} } ); // $ExpectError
	resolveParentPath.sync( 'package.json', { 'dir': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the `sync` method is provided an unsupported number of arguments...
{
	resolveParentPath.sync(); // $ExpectError
}
