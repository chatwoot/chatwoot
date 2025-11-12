'use strict';

var GetIntrinsic = require('get-intrinsic');
var callBound = require('call-bind/callBound');

var $TypeError = GetIntrinsic('%TypeError%');

var StringToCodePoints = require('./StringToCodePoints');
var Type = require('./Type');

var isInteger = require('../helpers/isInteger');

var $indexOf = callBound('String.prototype.indexOf');

// https://262.ecma-international.org/13.0/#sec-getstringindex

module.exports = function GetStringIndex(S, e) {
	if (Type(S) !== 'String') {
		throw new $TypeError('Assertion failed: `S` must be a String');
	}
	if (!isInteger(e) || e < 0) {
		throw new $TypeError('Assertion failed: `e` must be a non-negative integer');
	}

	if (S === '') {
		return 0;
	}
	var codepoints = StringToCodePoints(S);
	var eUTF = e >= codepoints.length ? S.length : $indexOf(S, codepoints[e]);
	return eUTF;
};
