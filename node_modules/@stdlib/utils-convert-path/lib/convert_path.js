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

// MODULES //

var isString = require( '@stdlib/assert-is-string' ).isPrimitive;
var reExtendedLengthPath = require( '@stdlib/regexp-extended-length-path' );
var lowercase = require( '@stdlib/string-lowercase' );
var replace = require( '@stdlib/string-replace' );


// VARIABLES //

var RE_WIN_DEVICE_ROOT = /^([A-Za-z]):[\\\/]+/; // eslint-disable-line no-useless-escape
var RE_POSIX_DEVICE_ROOT =/^\/([A-Za-z])\//;


// MAIN //

/**
* Converts between POSIX and Windows paths.
*
* @param {string} from - path to convert
* @param {string} to - output path convention
* @throws {TypeError} first argument must be a string
* @throws {TypeError} second argument must be a string
* @throws {RangeError} second argument must be a recognized output path convention
* @throws {Error} cannot convert a Windows extended-length path to a non-Windows path convention
* @returns {string} converted path
*
* @example
* var p = convertPath( '/c/foo/bar/beep.c', 'win32' );
* // returns 'c:\foo\bar\beep.c'
*
* @example
* var p = convertPath( '/c/foo/bar/beep.c', 'mixed' );
* // returns 'c:/foo/bar/beep.c'
*
* @example
* var p = convertPath( 'C:\\foo\\bar\\beep.c', 'posix' );
* // returns '/c/foo/bar/beep.c'
*
* @example
* var p = convertPath( 'C:\\foo\\bar\\beep.c', 'mixed' );
* // returns 'C:/foo/bar/beep.c'
*/
function convertPath( from, to ) {
	var device;
	var parts;
	var out;
	if ( !isString( from ) ) {
		throw new TypeError( 'invalid argument. First argument must be a string primitive. Value: `'+from+'`.' );
	}
	if ( !isString( to ) ) {
		throw new TypeError( 'invalid argument. Second argument must be a string primitive. Value: `'+to+'`.' );
	}
	if (
		to !== 'win32' &&
		to !== 'mixed' &&
		to !== 'posix'
	) {
		throw new Error( 'invalid argument. Second argument must be a recognized output path convention. Value: `'+to+'`.' );
	}
	out = from;

	// Convert to a Windows path convention by transforming a POSIX device root (if present) and using a Windows path separator...
	if ( to === 'win32' ) {
		parts = RE_POSIX_DEVICE_ROOT.exec( out );
		if ( parts ) {
			device = parts[ 1 ]+':\\';
			out = replace( out, RE_POSIX_DEVICE_ROOT, device );
		}
		return replace( out, '/', '\\' );
	}
	// Check for Windows extended-length paths...
	if ( reExtendedLengthPath.REGEXP.test( from ) ) {
		throw new Error( 'invalid argument. Cannot convert Windows extended-length paths to POSIX paths. Value: `'+from+'`.' );
	}
	// Convert to a mixed path convention by combining a Windows drive letter convention with a POSIX path separator...
	if ( to === 'mixed' ) {
		parts = RE_POSIX_DEVICE_ROOT.exec( out );
		if ( parts ) {
			device = parts[ 1 ]+':/';
			out = replace( out, RE_POSIX_DEVICE_ROOT, device );
		} else {
			parts = RE_WIN_DEVICE_ROOT.exec( out );
			if ( parts ) {
				device = parts[ 1 ]+':/';
				out = replace( out, RE_WIN_DEVICE_ROOT, device );
			}
		}
		return replace( out, '\\', '/' );
	}
	// Convert to a POSIX path convention by transforming a Windows device root (if present) and using a POSIX path separator...
	parts = RE_WIN_DEVICE_ROOT.exec( out );
	if ( parts ) {
		device = '/'+lowercase( parts[ 1 ] )+'/';
		out = replace( out, RE_WIN_DEVICE_ROOT, device );
	}
	return replace( out, '\\', '/' );
}


// EXPORTS //

module.exports = convertPath;
