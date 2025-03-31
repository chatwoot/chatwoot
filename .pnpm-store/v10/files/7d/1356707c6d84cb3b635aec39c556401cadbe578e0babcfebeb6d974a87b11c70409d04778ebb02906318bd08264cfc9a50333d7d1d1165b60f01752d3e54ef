'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var IsBigIntElementType = require('./IsBigIntElementType');
var IsUnclampedIntegerElementType = require('./IsUnclampedIntegerElementType');
var Type = require('./Type');
var ValidateTypedArray = require('./ValidateTypedArray');

var whichTypedArray = require('which-typed-array');

// https://262.ecma-international.org/12.0/#sec-validateintegertypedarray

var table60 = {
	__proto__: null,
	$Int8Array: 'Int8',
	$Uint8Array: 'Uint8',
	$Uint8ClampedArray: 'Uint8C',
	$Int16Array: 'Int16',
	$Uint16Array: 'Uint16',
	$Int32Array: 'Int32',
	$Uint32Array: 'Uint32',
	$BigInt64Array: 'BigInt64',
	$BigUint64Array: 'BigUint64',
	$Float32Array: 'Float32',
	$Float64Array: 'Float64'
};

module.exports = function ValidateIntegerTypedArray(typedArray) {
	var waitable = arguments.length > 1 ? arguments[1] : false; // step 1

	if (Type(waitable) !== 'Boolean') {
		throw new $TypeError('Assertion failed: `waitable` must be a Boolean');
	}

	var buffer = ValidateTypedArray(typedArray); // step 2

	var typeName = whichTypedArray(typedArray); // step 3

	var type = table60['$' + typeName]; // step 4

	if (waitable) { // step 5
		if (typeName !== 'Int32Array' && typeName !== 'BigInt64Array') {
			throw new $TypeError('Assertion failed: `typedArray` must be an Int32Array or BigInt64Array when `waitable` is true'); // step 5.a
		}
	} else if (!IsUnclampedIntegerElementType(type) && !IsBigIntElementType(type)) {
		throw new $TypeError('Assertion failed: `typedArray` must be an integer TypedArray'); // step 6.a
	}

	return buffer; // step 7
};
