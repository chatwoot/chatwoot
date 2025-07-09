'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var callBound = require('call-bind/callBound');

var $keyFor = callBound('Symbol.keyFor', true);

var Type = require('./Type');

// https://262.ecma-international.org/14.0/#sec-keyforsymbol

module.exports = function KeyForSymbol(sym) {
	if (Type(sym) !== 'Symbol') {
		throw new $TypeError('Assertion failed: `sym` must be a Symbol');
	}
	return $keyFor(sym);
};
