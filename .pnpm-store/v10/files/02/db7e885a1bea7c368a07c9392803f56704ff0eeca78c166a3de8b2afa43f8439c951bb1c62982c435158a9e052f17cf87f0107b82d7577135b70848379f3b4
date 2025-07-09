'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');
var max = GetIntrinsic('%Math.max%');
var min = GetIntrinsic('%Math.min%');

var Type = require('./Type');

// https://262.ecma-international.org/12.0/#clamping

module.exports = function clamp(x, lower, upper) {
	if (Type(x) !== 'Number' || Type(lower) !== 'Number' || Type(upper) !== 'Number' || !(lower <= upper)) {
		throw new $TypeError('Assertion failed: all three arguments must be MVs, and `lower` must be `<= upper`');
	}
	return min(max(lower, x), upper);
};
