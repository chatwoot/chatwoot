'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var callBound = require('call-bind/callBound');
var $indexOf = callBound('String.prototype.indexOf', true);

var Canonicalize = require('./Canonicalize');
var Type = require('./Type');

var assertRecord = require('../helpers/assertRecord');
var caseFolding = require('../helpers/caseFolding');
var forEach = require('../helpers/forEach');
var OwnPropertyKeys = require('../helpers/OwnPropertyKeys');

var basicWordChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'; // step 1

// https://262.ecma-international.org/14.0/#sec-runtime-semantics-wordcharacters-abstract-operation

module.exports = function WordCharacters(rer) {
	assertRecord(Type, 'RegExp Record', 'rer', rer);

	var extraWordChars = '';
	forEach(OwnPropertyKeys(caseFolding.C), function (c) {
		if (
			$indexOf(basicWordChars, c) === -1 // c not in A
			&& $indexOf(basicWordChars, Canonicalize(rer, c)) > -1 // canonicalized c IS in A
		) {
			extraWordChars += caseFolding.C[c]; // step 3
		}
	});
	forEach(OwnPropertyKeys(caseFolding.S), function (c) {
		if (
			$indexOf(basicWordChars, c) === -1 // c not in A
			&& $indexOf(basicWordChars, Canonicalize(rer, c)) > -1 // canonicalized c IS in A
		) {
			extraWordChars += caseFolding.S[c]; // step 3
		}
	});

	if ((!rer['[[Unicode]]'] || !rer['[[IgnoreCase]]']) && extraWordChars.length > 0) {
		throw new $TypeError('Assertion failed: `extraWordChars` must be empty when `rer.[[IgnoreCase]]` and `rer.[[Unicode]]` are not both true'); // step 3
	}

	return basicWordChars + extraWordChars; // step 4
};
