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

#include "stdlib/math/base/assert/is_nan.h"
#include <node_api.h>
#include <stdint.h>
#include <assert.h>

/**
* Add-on namespace.
*/
namespace stdlib_math_base_assert_is_nan {

	/**
	* Tests if a double-precision floating-point numeric value is `NaN`.
	*
	* ## Notes
	*
	* -   When called from JavaScript, the function expects one argument:
	*
	*     -    `x`: a number
	*/
	napi_value node_is_nan( napi_env env, napi_callback_info info ) {
		napi_status status;

		size_t argc = 1;
		napi_value argv[ 1 ];
		status = napi_get_cb_info( env, info, &argc, argv, nullptr, nullptr );
		assert( status == napi_ok );

		if ( argc < 1 ) {
			napi_throw_error( env, nullptr, "invalid invocation. Must provide a number." );
			return nullptr;
		}

		napi_valuetype vtype0;
		status = napi_typeof( env, argv[ 0 ], &vtype0 );
		assert( status == napi_ok );

		napi_value v;
		double x;
		if ( vtype0 == napi_number ) {
			status = napi_get_value_double( env, argv[ 0 ], &x );
			assert( status == napi_ok );

			status = napi_create_int32( env, (int32_t)stdlib_base_is_nan( x ), &v );
			assert( status == napi_ok );
		} else {
			status = napi_create_int32( env, 0, &v );
			assert( status == napi_ok );
		}

		return v;
	}

	napi_value Init( napi_env env, napi_value exports ) {
		napi_status status;
		napi_value fcn;
		status = napi_create_function( env, "exports", NAPI_AUTO_LENGTH, node_is_nan, NULL, &fcn );
		assert( status == napi_ok );
		return fcn;
	}

	NAPI_MODULE( NODE_GYP_MODULE_NAME, Init )
} // end namespace stdlib_math_base_assert_is_nan
