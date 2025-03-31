'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var callBound = require('call-bind/callBound');
var $taSome = callBound('TypedArray.prototype.some', true);

var Type = require('./Type');

var isTypedArray = require('is-typed-array');

// https://262.ecma-international.org/6.0/#sec-validatetypedarray

module.exports = function ValidateTypedArray(O) {
	if (Type(O) !== 'Object') {
		throw new $TypeError('Assertion failed: O must be an Object');
	}
	if (!isTypedArray(O)) {
		throw new $TypeError('Assertion failed: O must be a TypedArray');
	}

	// without `.some` (like in node 0.10), there's no way to check buffer detachment, but also no way to be detached
	if ($taSome) {
		$taSome(O, function () { return true; });
	}

	return O.buffer;
};
