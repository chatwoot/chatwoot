/**
* @license Apache-2.0
*
* Copyright (c) 2018 The Stdlib Authors.
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

'use strict';

// VARIABLES //

// NOTE: for the following, we explicitly avoid using stdlib packages in this particular package in order to avoid circular dependencies. This should not be problematic as (1) this package is unlikely to be used outside of Node.js and, thus, in environments lacking support for the built-in APIs, and (2) most of the historical bugs for the respective APIs were in environments such as IE and not the versions of V8 included in Node.js >= v0.10.x.
var objectKeys = Object.keys;


// MAIN //

/**
* Returns an array of unique values.
*
* @private
* @param {StringArray} arr - input array
* @returns {StringArray} array with unique values
*/
function unique( arr ) {
	var obj;
	var i;
	obj = {};
	for ( i = 0; i < arr.length; i++ ) {
		obj[ arr[i] ] = true;
	}
	return objectKeys( obj );
}


// EXPORTS //

module.exports = unique;
