'use strict';

var GetIntrinsic = require('get-intrinsic');

var $Number = GetIntrinsic('%Number%');
var $TypeError = GetIntrinsic('%TypeError%');

var $isNaN = require('../helpers/isNaN');
var $isFinite = require('../helpers/isFinite');

var IsStringPrefix = require('./IsStringPrefix');
var ToNumber = require('./ToNumber');
var ToPrimitive = require('./ToPrimitive');
var Type = require('./Type');

// https://262.ecma-international.org/9.0/#sec-abstract-relational-comparison

module.exports = function AbstractRelationalComparison(x, y, LeftFirst) {
	if (Type(LeftFirst) !== 'Boolean') {
		throw new $TypeError('Assertion failed: LeftFirst argument must be a Boolean');
	}
	var px;
	var py;
	if (LeftFirst) {
		px = ToPrimitive(x, $Number);
		py = ToPrimitive(y, $Number);
	} else {
		py = ToPrimitive(y, $Number);
		px = ToPrimitive(x, $Number);
	}
	if (Type(px) === 'String' && Type(py) === 'String') {
		if (IsStringPrefix(py, px)) {
			return false;
		}
		if (IsStringPrefix(px, py)) {
			return true;
		}
		return px < py; // both strings, neither a prefix of the other. shortcut for steps 3 c-f
	}
	var nx = ToNumber(px);
	var ny = ToNumber(py);
	if ($isNaN(nx) || $isNaN(ny)) {
		return undefined;
	}
	if ($isFinite(nx) && $isFinite(ny) && nx === ny) {
		return false;
	}
	if (nx === Infinity) {
		return false;
	}
	if (ny === Infinity) {
		return true;
	}
	if (ny === -Infinity) {
		return false;
	}
	if (nx === -Infinity) {
		return true;
	}
	return nx < ny; // by now, these are both nonzero, finite, and not equal
};
