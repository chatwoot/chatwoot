'use strict';

var GetIntrinsic = require('get-intrinsic');

var $BigInt = GetIntrinsic('%BigInt%', true);
var $RangeError = GetIntrinsic('%RangeError%');
var $SyntaxError = GetIntrinsic('%SyntaxError%');
var $TypeError = GetIntrinsic('%TypeError%');

var IsIntegralNumber = require('./IsIntegralNumber');
var Type = require('./Type');

// https://262.ecma-international.org/12.0/#sec-numbertobigint

module.exports = function NumberToBigInt(number) {
	if (Type(number) !== 'Number') {
		throw new $TypeError('Assertion failed: `number` must be a String');
	}
	if (!IsIntegralNumber(number)) {
		throw new $RangeError('The number ' + number + ' cannot be converted to a BigInt because it is not an integer');
	}
	if (!$BigInt) {
		throw new $SyntaxError('BigInts are not supported in this environment');
	}
	return $BigInt(number);
};
