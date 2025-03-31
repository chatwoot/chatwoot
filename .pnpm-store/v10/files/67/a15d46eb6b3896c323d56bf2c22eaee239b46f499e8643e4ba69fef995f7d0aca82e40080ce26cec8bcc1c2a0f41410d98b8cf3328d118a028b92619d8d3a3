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

import setNonEnumerableReadOnly = require( './index' );


// TESTS //

// The function returns `undefined`...
{
	setNonEnumerableReadOnly( {}, 'foo', 'bar' ); // $ExpectType void
}

// The compiler throws an error if the function is provided a second argument which is not a valid property name...
{
	setNonEnumerableReadOnly( {}, true, 'bar' ); // $ExpectError
	setNonEnumerableReadOnly( {}, false, 'bar' ); // $ExpectError
	setNonEnumerableReadOnly( {}, null, 'bar' ); // $ExpectError
	setNonEnumerableReadOnly( {}, undefined, 'bar' ); // $ExpectError
	setNonEnumerableReadOnly( {}, [], 'bar' ); // $ExpectError
	setNonEnumerableReadOnly( {}, {}, 'bar' ); // $ExpectError
	setNonEnumerableReadOnly( {}, ( x: number ): number => x, 'bar' ); // $ExpectError
}

// The compiler throws an error if the function is provided insufficient arguments...
{
	setNonEnumerableReadOnly(); // $ExpectError
	setNonEnumerableReadOnly( {} ); // $ExpectError
	setNonEnumerableReadOnly( {}, 'foo' ); // $ExpectError
}
