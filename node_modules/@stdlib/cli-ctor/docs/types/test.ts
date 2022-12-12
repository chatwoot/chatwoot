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

/* tslint:disable:no-unused-expression */

import CLI = require( './index' );


// TESTS //

// The function returns a command-line interface...
{
	new CLI(); // $ExpectType CLI
	new CLI( { 'updates': false } ); // $ExpectType CLI
}

// The compiler throws an error if the constructor function is provided an argument that is not an options object...
{
	new CLI( 123 ); // $ExpectError
	new CLI( 'abc' ); // $ExpectError
	new CLI( null ); // $ExpectError
	new CLI( true ); // $ExpectError
	new CLI( false ); // $ExpectError
	new CLI( [] ); // $ExpectError
}

// The compiler throws an error if the function is provided a `version` option which is not a string...
{
	new CLI( { 'version': 123 } ); // $ExpectError
	new CLI( { 'version': true } ); // $ExpectError
	new CLI( { 'version': false } ); // $ExpectError
	new CLI( { 'version': null } ); // $ExpectError
	new CLI( { 'version': [] } ); // $ExpectError
	new CLI( { 'version': {} } ); // $ExpectError
	new CLI( { 'version': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the function is provided a `help` option which is not a string...
{
	new CLI( { 'help': 123 } ); // $ExpectError
	new CLI( { 'help': true } ); // $ExpectError
	new CLI( { 'help': false } ); // $ExpectError
	new CLI( { 'help': null } ); // $ExpectError
	new CLI( { 'help': [] } ); // $ExpectError
	new CLI( { 'help': {} } ); // $ExpectError
	new CLI( { 'help': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the function is provided a `title` option which is neither a string nor boolean...
{
	new CLI( { 'title': 123 } ); // $ExpectError
	new CLI( { 'title': null } ); // $ExpectError
	new CLI( { 'title': [] } ); // $ExpectError
	new CLI( { 'title': {} } ); // $ExpectError
	new CLI( { 'title': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the function is provided a `updates` option which is not a boolean...
{
	new CLI( { 'updates': 123 } ); // $ExpectError
	new CLI( { 'updates': 'abc' } ); // $ExpectError
	new CLI( { 'updates': null } ); // $ExpectError
	new CLI( { 'updates': [] } ); // $ExpectError
	new CLI( { 'updates': {} } ); // $ExpectError
	new CLI( { 'updates': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the function is provided an `argv` option which is not an array...
{
	new CLI( { 'argv': 'abc' } ); // $ExpectError
	new CLI( { 'argv': 123 } ); // $ExpectError
	new CLI( { 'argv': true } ); // $ExpectError
	new CLI( { 'argv': false } ); // $ExpectError
	new CLI( { 'argv': null } ); // $ExpectError
	new CLI( { 'argv': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the function is provided a `options` option which is not an options object...
{
	new CLI( { 'options': 'abc' } ); // $ExpectError
	new CLI( { 'options': 123 } ); // $ExpectError
	new CLI( { 'options': true } ); // $ExpectError
	new CLI( { 'options': false } ); // $ExpectError
	new CLI( { 'options': null } ); // $ExpectError
	new CLI( { 'options': [] } ); // $ExpectError
	new CLI( { 'options': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the constructor function is provided more than one argument...
{
	new CLI( {}, {} ); // $ExpectError
	new CLI( {}, {}, {} ); // $ExpectError
}
