'use strict';

var GetIntrinsic = require('get-intrinsic');
var CodePointAt = require('./CodePointAt');

var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('./Type');

// https://262.ecma-international.org/13.0/#sec-isstringwellformedunicode

module.exports = function IsStringWellFormedUnicode(string) {
	if (Type(string) !== 'String') {
		throw new $TypeError('Assertion failed: `string` must be a String');
	}
	var strLen = string.length; // step 1
	var k = 0; // step 2
	while (k !== strLen) { // step 3
		var cp = CodePointAt(string, k); // step 3.a
		if (cp['[[IsUnpairedSurrogate]]']) {
			return false; // step 3.b
		}
		k += cp['[[CodeUnitCount]]']; // step 3.c
	}
	return true; // step 4
};
