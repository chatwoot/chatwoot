'use strict';

var GetIntrinsic = require('get-intrinsic');
var callBound = require('call-bind/callBound');

var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('./Type');

var isInteger = require('../helpers/isInteger');

var $charAt = callBound('String.prototype.charAt');

// https://262.ecma-international.org/12.0/#sec-splitmatch

module.exports = function SplitMatch(S, q, R) {
	if (Type(S) !== 'String') {
		throw new $TypeError('Assertion failed: `S` must be a String');
	}
	if (!isInteger(q)) {
		throw new $TypeError('Assertion failed: `q` must be an integer');
	}
	if (Type(R) !== 'String') {
		throw new $TypeError('Assertion failed: `R` must be a String');
	}
	var r = R.length;
	var s = S.length;
	if (q + r > s) {
		return 'not-matched';
	}

	for (var i = 0; i < r; i += 1) {
		if ($charAt(S, q + i) !== $charAt(R, i)) {
			return 'not-matched';
		}
	}

	return q + r;
};
