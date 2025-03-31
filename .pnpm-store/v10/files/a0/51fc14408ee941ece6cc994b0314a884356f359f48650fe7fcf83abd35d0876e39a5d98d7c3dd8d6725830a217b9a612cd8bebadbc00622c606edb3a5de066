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

import convertPath = require( './index' );


// TESTS //

// The function returns a string...
{
	convertPath( '/c/foo/bar/beep.c', 'win32' ); // $ExpectType string
	convertPath( '/c/foo/bar/beep.c', 'mixed' ); // $ExpectType string
	convertPath( 'C:\\foo\\bar\\beep.c', 'posix' ); // $ExpectType string
}

// The function does not compile if provided arguments having invalid types...
{
	convertPath( true, 'win32' ); // $ExpectError
	convertPath( false, 'win32' ); // $ExpectError
	convertPath( 3, 'win32' ); // $ExpectError
	convertPath( [], 'win32' ); // $ExpectError
	convertPath( {}, 'win32' ); // $ExpectError
	convertPath( ( x: number ): number => x, 'win32' ); // $ExpectError

	convertPath( '/c/foo/bar/beep.c', true ); // $ExpectError
	convertPath( '/c/foo/bar/beep.c', false ); // $ExpectError
	convertPath( '/c/foo/bar/beep.c', 5 ); // $ExpectError
	convertPath( '/c/foo/bar/beep.c', [] ); // $ExpectError
	convertPath( '/c/foo/bar/beep.c', {} ); // $ExpectError
	convertPath( '/c/foo/bar/beep.c', ( x: number ): number => x ); // $ExpectError
}

// The function does not compile if provided insufficient arguments...
{
	convertPath(); // $ExpectError
	convertPath( 'abc' ); // $ExpectError
}
