'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var isFinite = require('../../helpers/isFinite');
var isNaN = require('../../helpers/isNaN');

var Type = require('../Type');

// https://262.ecma-international.org/12.0/#sec-numeric-types-number-add

module.exports = function NumberAdd(x, y) {
	if (Type(x) !== 'Number' || Type(y) !== 'Number') {
		throw new $TypeError('Assertion failed: `x` and `y` arguments must be Numbers');
	}

	if (isNaN(x) || isNaN(y) || (x === Infinity && y === -Infinity) || (x === -Infinity && y === Infinity)) {
		return NaN;
	}

	if (!isFinite(x)) {
		return x;
	}
	if (!isFinite(y)) {
		return y;
	}

	if (x === y && x === 0) { // both zeroes
		return Infinity / x === -Infinity && Infinity / y === -Infinity ? -0 : +0;
	}

	// shortcut for the actual spec mechanics
	return x + y;
};
