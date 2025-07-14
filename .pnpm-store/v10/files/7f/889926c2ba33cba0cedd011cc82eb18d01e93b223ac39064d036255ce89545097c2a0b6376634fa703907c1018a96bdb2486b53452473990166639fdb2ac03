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

// MAIN //

/**
* Tests if a value is an object; e.g., `{}`.
*
* @private
* @param {*} value - value to test
* @returns {boolean} boolean indicating whether value is an object
*
* @example
* var bool = isObject( {} );
* // returns true
*
* @example
* var bool = isObject( null );
* // returns false
*/
function isObject( value ) {
	return (
		typeof value === 'object' &&
		value !== null &&
		!Array.isArray( value )	// NOTE: we inline the `isObject` function from `@stdlib/assert/is-object` and use the built-in `isArray` method in this particular package in order to avoid circular dependencies. This should not be problematic as (1) this package is unlikely to be used outside of Node.js and, thus, in environments lacking support for the built-in APIs, and (2) most of the historical bugs for the respective APIs were in environments such as IE and not the versions of V8 included in Node.js >= v0.10.x.
	);
}


// EXPORTS //

module.exports = isObject;
