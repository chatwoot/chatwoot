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

// tslint:disable: no-construct
// tslint:disable: no-unused-expression

import Float32Array = require( './index' );


// TESTS //

// The function returns a typed array instance...
{
	new Float32Array( 10 ); // $ExpectType Float32Array
	new Float32Array( [ 2.1, 3.9, 5.2, 7.3 ] ); // $ExpectType Float32Array
}

// The constructor function has to be invoked with `new`...
{
	Float32Array( 10 ); // $ExpectError
	Float32Array( [ 2.1, 3.9, 5.2, 7.3 ] ); // $ExpectError
}
