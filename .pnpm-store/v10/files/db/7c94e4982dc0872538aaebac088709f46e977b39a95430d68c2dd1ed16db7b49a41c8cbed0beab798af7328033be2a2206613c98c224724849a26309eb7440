'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var IsInteger = require('./IsInteger');

var isNegativeZero = require('../helpers/isNegativeZero');

var typedArrayBuffer = require('typed-array-buffer');

// https://262.ecma-international.org/11.0/#sec-isvalidintegerindex

module.exports = function IsValidIntegerIndex(O, index) {
	// Assert: O is an Integer-Indexed exotic object.
	typedArrayBuffer(O); // step 1

	if (typeof index !== 'number') {
		throw new $TypeError('Assertion failed: Type(index) is not Number'); // step 2
	}

	if (!IsInteger(index)) { return false; } // step 3

	if (isNegativeZero(index)) { return false; } // step 4

	if (index < 0 || index >= O.length) { return false; } // step 5

	return true; // step 6
};
