'use strict';

var GetIntrinsic = require('get-intrinsic');

var $SyntaxError;
var $TypeError = GetIntrinsic('%TypeError%');

var callBound = require('call-bind/callBound');

var $BigIntToString = callBound('BigInt.prototype.toString', true);

var Type = require('../Type');

var isInteger = require('../../helpers/isInteger');

// https://262.ecma-international.org/14.0/#sec-numeric-types-bigint-tostring

module.exports = function BigIntToString(x, radix) {
	if (Type(x) !== 'BigInt') {
		throw new $TypeError('Assertion failed: `x` must be a BigInt');
	}

	if (!isInteger(radix) || radix < 2 || radix > 36) {
		throw new $TypeError('Assertion failed: `radix` must be an integer >= 2 and <= 36');
	}

	if (!$BigIntToString) {
		throw new $SyntaxError('BigInt is not supported');
	}

	return $BigIntToString(x, radix); // steps 1 - 12
};
