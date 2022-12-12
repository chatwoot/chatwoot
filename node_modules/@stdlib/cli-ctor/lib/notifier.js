/**
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

// FIXME: remove this stub and create a stdlib equivalent of update-notifier

'use strict';

// MODULES //

var setReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );
var noop = require( '@stdlib/utils-noop' );


// MAIN //

/**
* Notifier constructor.
*
* @private
* @constructor
* @returns {Notifier} notifier instance
*
* @example
* var notifier = new Notifier();
*/
function Notifier() {
	if ( !(this instanceof Notifier) ) {
		return new Notifier();
	}
	return this;
}

/**
* Notifies whether a new version is available.
*
* @private
* @name notify
* @memberof Notifier.prototype
* @type {Function}
*/
setReadOnly( Notifier.prototype, 'notify', noop );


// EXPORTS //

module.exports = Notifier;
