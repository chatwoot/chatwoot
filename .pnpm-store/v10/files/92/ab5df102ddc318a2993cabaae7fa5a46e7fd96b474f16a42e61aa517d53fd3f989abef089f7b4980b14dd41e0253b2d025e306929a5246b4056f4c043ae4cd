'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('../Type');

var NumberAdd = require('./add');
var NumberUnaryMinus = require('./unaryMinus');

// https://262.ecma-international.org/12.0/#sec-numeric-types-number-subtract

module.exports = function NumberSubtract(x, y) {
	if (Type(x) !== 'Number' || Type(y) !== 'Number') {
		throw new $TypeError('Assertion failed: `x` and `y` arguments must be Numbers');
	}
	return NumberAdd(x, NumberUnaryMinus(y));
};
