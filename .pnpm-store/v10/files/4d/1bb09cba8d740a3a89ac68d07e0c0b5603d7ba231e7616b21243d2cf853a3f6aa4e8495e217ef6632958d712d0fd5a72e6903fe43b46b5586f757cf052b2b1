'use strict';

var GetIntrinsic = require('get-intrinsic');

var $RangeError = GetIntrinsic('%RangeError%');
var $TypeError = GetIntrinsic('%TypeError%');

var ToIndex = require('./ToIndex');

var isTypedArray = require('is-typed-array');
var typedArrayByteOffset = require('typed-array-byte-offset');
var typedArrayLength = require('typed-array-length');
var whichTypedArray = require('which-typed-array');

var table60 = {
	__proto__: null,
	$Int8Array: 1,
	$Uint8Array: 1,
	$Uint8ClampedArray: 1,
	$Int16Array: 2,
	$Uint16Array: 2,
	$Int32Array: 4,
	$Uint32Array: 4,
	$BigInt64Array: 8,
	$BigUint64Array: 8,
	$Float32Array: 4,
	$Float64Array: 8
};

// https://262.ecma-international.org/12.0/#sec-validateatomicaccess

module.exports = function ValidateAtomicAccess(typedArray, requestIndex) {
	if (!isTypedArray(typedArray)) {
		throw new $TypeError('Assertion failed: `typedArray` must be a TypedArray'); // step 1
	}

	var length = typedArrayLength(typedArray); // step 2

	var accessIndex = ToIndex(requestIndex); // step 3

	/*
	// this assertion can never be reached
	if (!(accessIndex >= 0)) {
		throw new $TypeError('Assertion failed: accessIndex >= 0'); // step 4
	}
	*/

	if (accessIndex >= length) {
		throw new $RangeError('index out of range'); // step 5
	}

	var arrayTypeName = whichTypedArray(typedArray); // step 6

	var elementSize = table60['$' + arrayTypeName]; // step 7

	var offset = typedArrayByteOffset(typedArray); // step 8

	return (accessIndex * elementSize) + offset; // step 9
};
