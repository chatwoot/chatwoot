'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var callBound = require('call-bind/callBound');
var has = require('has');

var $charCodeAt = callBound('String.prototype.charCodeAt');
var $toUpperCase = callBound('String.prototype.toUpperCase');

var Type = require('./Type');

var caseFolding = require('../helpers/caseFolding');

// https://262.ecma-international.org/6.0/#sec-runtime-semantics-canonicalize-ch

module.exports = function Canonicalize(ch, IgnoreCase, Unicode) {
	if (Type(ch) !== 'String') {
		throw new $TypeError('Assertion failed: `ch` must be a character');
	}

	if (Type(IgnoreCase) !== 'Boolean' || Type(Unicode) !== 'Boolean') {
		throw new $TypeError('Assertion failed: `IgnoreCase` and `Unicode` must be Booleans');
	}

	if (!IgnoreCase) {
		return ch; // step 1
	}

	if (Unicode) { // step 2
		if (has(caseFolding.C, ch)) {
			return caseFolding.C[ch];
		}
		if (has(caseFolding.S, ch)) {
			return caseFolding.S[ch];
		}
		return ch; // step 2.b
	}

	var u = $toUpperCase(ch); // step 2

	if (u.length !== 1) {
		return ch; // step 3
	}

	var cu = u; // step 4

	if ($charCodeAt(ch, 0) >= 128 && $charCodeAt(cu, 0) < 128) {
		return ch; // step 5
	}

	return cu;
};
