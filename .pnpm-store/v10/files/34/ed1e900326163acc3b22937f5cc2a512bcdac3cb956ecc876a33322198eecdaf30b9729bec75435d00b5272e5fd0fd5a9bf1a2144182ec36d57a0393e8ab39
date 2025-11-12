'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var callBound = require('call-bind/callBound');

var $numberToString = callBound('Number.prototype.toString');

var Type = require('../Type');

var isInteger = require('../../helpers/isInteger');

// https://262.ecma-international.org/14.0/#sec-numeric-types-number-tostring

module.exports = function NumberToString(x, radix) {
	if (Type(x) !== 'Number') {
		throw new $TypeError('Assertion failed: `x` must be a Number');
	}
	if (!isInteger(radix) || radix < 2 || radix > 36) {
		throw new $TypeError('Assertion failed: `radix` must be an integer >= 2 and <= 36');
	}

	return $numberToString(x, radix); // steps 1 - 12
};
