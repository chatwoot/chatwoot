'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var callBound = require('call-bind/callBound');
var $indexOf = callBound('String.prototype.indexOf', true);

var Canonicalize = require('./Canonicalize');
var Type = require('./Type');

var caseFolding = require('../helpers/caseFolding');
var forEach = require('../helpers/forEach');
var OwnPropertyKeys = require('../helpers/OwnPropertyKeys');

var A = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'; // step 1

// https://262.ecma-international.org/8.0/#sec-runtime-semantics-wordcharacters-abstract-operation

module.exports = function WordCharacters(IgnoreCase, Unicode) {
	if (Type(IgnoreCase) !== 'Boolean' || Type(Unicode) !== 'Boolean') {
		throw new $TypeError('Assertion failed: `IgnoreCase` and `Unicode` must be booleans');
	}

	var U = '';
	forEach(OwnPropertyKeys(caseFolding.C), function (c) {
		if (
			$indexOf(A, c) === -1 // c not in A
			&& $indexOf(A, Canonicalize(c, IgnoreCase, Unicode)) > -1 // canonicalized c IS in A
		) {
			U += caseFolding.C[c]; // step 3
		}
	});
	forEach(OwnPropertyKeys(caseFolding.S), function (c) {
		if (
			$indexOf(A, c) === -1 // c not in A
			&& $indexOf(A, Canonicalize(c, IgnoreCase, Unicode)) > -1 // canonicalized c IS in A
		) {
			U += caseFolding.S[c]; // step 3
		}
	});

	if ((!Unicode || !IgnoreCase) && U.length > 0) {
		throw new $TypeError('Assertion failed: `U` must be empty when `IgnoreCase` and `Unicode` are not both true'); // step 4
	}

	return A + U; // step 5, 6
};
