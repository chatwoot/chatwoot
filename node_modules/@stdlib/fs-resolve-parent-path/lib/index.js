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

/**
* Resolve a path by walking parent directories.
*
* @module @stdlib/fs-resolve-parent-path
*
* @example
* var resolveParentPath = require( '@stdlib/fs-resolve-parent-path' );
*
* resolveParentPath( 'package.json', onPath );
*
* function onPath( error, path ) {
*     if ( error ) {
*         throw error;
*     }
*     console.log( path );
* }
*
* @example
* var resolveParentPath = require( '@stdlib/fs-resolve-parent-path' );
*
* var path = resolveParentPath.sync( 'package.json' );
*/

// MODULES //

var setReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );
var resolveParentPath = require( './async.js' );
var sync = require( './sync.js' );


// MAIN //

setReadOnly( resolveParentPath, 'sync', sync );


// EXPORTS //

module.exports = resolveParentPath;
