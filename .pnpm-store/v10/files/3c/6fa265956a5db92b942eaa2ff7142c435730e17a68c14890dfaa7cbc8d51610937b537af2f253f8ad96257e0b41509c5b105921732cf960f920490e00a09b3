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

import reFunctionName = require( './index' );


// TESTS //

// The function returns a regular expression...
{
	reFunctionName(); // $ExpectType RegExp
}

// The compiler throws an error if the function is provided an unsupported number of arguments...
{
	reFunctionName( 1 ); // $ExpectError
	reFunctionName( 1, 2 ); // $ExpectError
}

// Attached to main export is a `REGEXP` property that is a regular expression...
{
	// tslint:disable-next-line:no-unused-expression
	reFunctionName.REGEXP; // $ExpectType RegExp
}
