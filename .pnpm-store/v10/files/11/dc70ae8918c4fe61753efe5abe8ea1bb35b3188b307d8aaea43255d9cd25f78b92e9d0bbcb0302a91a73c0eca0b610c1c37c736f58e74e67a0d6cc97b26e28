'use strict';

var GetIntrinsic = require('get-intrinsic');

var $BigInt = GetIntrinsic('%BigInt%', true);
var $RangeError = GetIntrinsic('%RangeError%');
var $SyntaxError = GetIntrinsic('%SyntaxError%');
var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('./Type');

var isInteger = require('../helpers/isInteger');

// https://262.ecma-international.org/11.0/#sec-numbertobigint

module.exports = function NumberToBigInt(number) {
	if (Type(number) !== 'Number') {
		throw new $TypeError('Assertion failed: `number` must be a String');
	}
	if (!isInteger(number)) {
		throw new $RangeError('The number ' + number + ' cannot be converted to a BigInt because it is not an integer');
	}
	if (!$BigInt) {
		throw new $SyntaxError('BigInts are not supported in this environment');
	}
	return $BigInt(number);
};
