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

import Complex128 = require( './index' );


// TESTS //

// The function returns a 128-bit complex number with the expected properties...
{
	const x = new Complex128( 5.0, 3.0 ); // $ExpectType Complex128

	// tslint:disable-next-line:no-unused-expression
	x.im; // $ExpectType number

	// tslint:disable-next-line:no-unused-expression
	x.re; // $ExpectType number

	// tslint:disable-next-line:no-unused-expression
	x.BYTES_PER_ELEMENT; // $ExpectType 8

	// tslint:disable-next-line:no-unused-expression
	x.byteLength; // $ExpectType 16
}

// 128-bit complex number comes with a `toString` method to serialize a complex number as a string...
{
	const x = new Complex128( 5.0, 3.0 ); // $ExpectType Complex128

	// tslint:disable-next-line:no-unused-expression
	x.toString(); // $ExpectType string
}

// 128-bit complex number comes with a `toJSON` method to serialize a complex number as a JSON object...
{
	const x = new Complex128( 5.0, 3.0 ); // $ExpectType Complex128

	// tslint:disable-next-line:no-unused-expression
	x.toJSON(); // $ExpectType any
}

// The compiler throws an error if the constructor is invoked without the `new` keyword...
{
	Complex128( 5.0, 3.0 ); // $ExpectError
}

// The compiler throws an error if the constructor is provided an unsupported number of arguments...
{
	// tslint:disable-next-line:no-unused-expression
	new Complex128( 5.0 ); // $ExpectError

	// tslint:disable-next-line:no-unused-expression
	new Complex128( 5.0, 3.0, 1.0 ); // $ExpectError
}
