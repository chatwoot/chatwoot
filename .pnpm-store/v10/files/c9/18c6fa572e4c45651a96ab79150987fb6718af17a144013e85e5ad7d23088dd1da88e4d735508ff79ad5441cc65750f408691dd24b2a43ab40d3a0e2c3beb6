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

import manifest = require( './index' );


// TESTS //

// The function returns an object...
{
	manifest( './manifest.json', {} ); // $ExpectType any
}

// The compiler throws an error if the function is provided a first argument which is not a string...
{
	manifest( true ); // $ExpectError
	manifest( false ); // $ExpectError
	manifest( 5 ); // $ExpectError
	manifest( [] ); // $ExpectError
	manifest( {} ); // $ExpectError
	manifest( ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided a third argument which is not an options object...
{
	manifest( './manifest.json', {}, true ); // $ExpectError
	manifest( './manifest.json', {}, false ); // $ExpectError
	manifest( './manifest.json', {}, 'abc' ); // $ExpectError
	manifest( './manifest.json', {}, 123 ); // $ExpectError
	manifest( './manifest.json', {}, [] ); // $ExpectError
	manifest( './manifest.json', {}, ( x: number ): number => x ); // $ExpectError
}

// The compiler throws an error if the function is provided a `basedir` option which is not a string...
{
	manifest( './manifest.json', {}, { 'basedir': true } ); // $ExpectError
	manifest( './manifest.json', {}, { 'basedir': false } ); // $ExpectError
	manifest( './manifest.json', {}, { 'basedir': 123 } ); // $ExpectError
	manifest( './manifest.json', {}, { 'basedir': [] } ); // $ExpectError
	manifest( './manifest.json', {}, { 'basedir': {} } ); // $ExpectError
	manifest( './manifest.json', {}, { 'basedir': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the function is provided a `paths` option which is not a string...
{
	manifest( './manifest.json', {}, { 'paths': true } ); // $ExpectError
	manifest( './manifest.json', {}, { 'paths': false } ); // $ExpectError
	manifest( './manifest.json', {}, { 'paths': 123 } ); // $ExpectError
	manifest( './manifest.json', {}, { 'paths': [] } ); // $ExpectError
	manifest( './manifest.json', {}, { 'paths': {} } ); // $ExpectError
	manifest( './manifest.json', {}, { 'paths': ( x: number ): number => x } ); // $ExpectError
}

// The compiler throws an error if the function is provided an invalid number of arguments...
{
	manifest(); // $ExpectError
	manifest( './manifest.json' ); // $ExpectError
	manifest( './manifest.json', {}, {}, {} ); // $ExpectError
}
