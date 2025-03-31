'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var ToInt32 = require('../ToInt32');
var ToUint32 = require('../ToUint32');
var modulo = require('../modulo');
var Type = require('../Type');

// https://262.ecma-international.org/12.0/#sec-numeric-types-number-unsignedRightShift

module.exports = function NumberUnsignedRightShift(x, y) {
	if (Type(x) !== 'Number' || Type(y) !== 'Number') {
		throw new $TypeError('Assertion failed: `x` and `y` arguments must be Numbers');
	}

	var lnum = ToInt32(x);
	var rnum = ToUint32(y);

	var shiftCount = modulo(rnum, 32);

	return lnum >>> shiftCount;
};
