'use strict';

var GetIntrinsic = require('get-intrinsic');

var $Number = GetIntrinsic('%Number%');
var $TypeError = GetIntrinsic('%TypeError%');

var $isNaN = require('../helpers/isNaN');

var IsStringPrefix = require('./IsStringPrefix');
var StringToBigInt = require('./StringToBigInt');
var ToNumeric = require('./ToNumeric');
var ToPrimitive = require('./ToPrimitive');
var Type = require('./Type');

var BigIntLessThan = require('./BigInt/lessThan');
var NumberLessThan = require('./Number/lessThan');

// https://262.ecma-international.org/13.0/#sec-islessthan

// eslint-disable-next-line max-statements, max-lines-per-function
module.exports = function IsLessThan(x, y, LeftFirst) {
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
	var pxType = Type(px);
	var pyType = Type(py);
	if (pxType === 'String' && pyType === 'String') {
		if (IsStringPrefix(py, px)) {
			return false;
		}
		if (IsStringPrefix(px, py)) {
			return true;
		}
		/*
		c. Let k be the smallest non-negative integer such that the code unit at index k within px is different from the code unit at index k within py. (There must be such a k, for neither String is a prefix of the other.)
		d. Let m be the integer that is the numeric value of the code unit at index k within px.
		e. Let n be the integer that is the numeric value of the code unit at index k within py.
		f. If m < n, return true. Otherwise, return false.
		*/
		return px < py; // both strings, neither a prefix of the other. shortcut for steps 3 c-f
	}

	var nx;
	var ny;
	if (pxType === 'BigInt' && pyType === 'String') {
		ny = StringToBigInt(py);
		if (typeof ny === 'undefined') {
			return void undefined;
		}
		return BigIntLessThan(px, ny);
	}
	if (pxType === 'String' && pyType === 'BigInt') {
		nx = StringToBigInt(px);
		if (typeof nx === 'undefined') {
			return void undefined;
		}
		return BigIntLessThan(nx, py);
	}

	nx = ToNumeric(px);
	ny = ToNumeric(py);

	var nxType = Type(nx);
	if (nxType === Type(ny)) {
		return nxType === 'Number' ? NumberLessThan(nx, ny) : BigIntLessThan(nx, ny);
	}

	if ($isNaN(nx) || $isNaN(ny)) {
		return void undefined;
	}

	if (nx === -Infinity || ny === Infinity) {
		return true;
	}
	if (nx === Infinity || ny === -Infinity) {
		return false;
	}

	return nx < ny; // by now, these are both finite, and the same type
};
