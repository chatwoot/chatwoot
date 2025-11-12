'use strict';

var forEach = require('for-each');
var callBind = require('call-bind');

var typedArrays = [
	'Float32Array',
	'Float64Array',
	'Int8Array',
	'Int16Array',
	'Int32Array',
	'Uint8Array',
	'Uint8ClampedArray',
	'Uint16Array',
	'Uint32Array',
	'BigInt64Array',
	'BigUint64Array'
];

var getters = {};
var hasProto = [].__proto__ === Array.prototype; // eslint-disable-line no-proto
var gOPD = Object.getOwnPropertyDescriptor;
var oDP = Object.defineProperty;
if (gOPD) {
	var getLength = function (x) {
		return x.length;
	};
	forEach(typedArrays, function (typedArray) {
		// In Safari 7, Typed Array constructors are typeof object
		if (typeof global[typedArray] === 'function' || typeof global[typedArray] === 'object') {
			var Proto = global[typedArray].prototype;
			var descriptor = gOPD(Proto, 'length');
			if (!descriptor && hasProto) {
				var superProto = Proto.__proto__; // eslint-disable-line no-proto
				descriptor = gOPD(superProto, 'length');
			}
			// Opera 12.16 has a magic length data property on instances AND on Proto
			if (descriptor && descriptor.get) {
				getters[typedArray] = callBind(descriptor.get);
			} else if (oDP) {
				// this is likely an engine where instances have a magic length data property
				var arr = new global[typedArray](2);
				descriptor = gOPD(arr, 'length');
				if (descriptor && descriptor.configurable) {
					oDP(arr, 'length', { value: 3 });
				}
				if (arr.length === 2) {
					getters[typedArray] = getLength;
				}
			}
		}
	});
}

var tryTypedArrays = function tryAllTypedArrays(value) {
	var foundLength;
	forEach(getters, function (getter) {
		if (typeof foundLength !== 'number') {
			try {
				var length = getter(value);
				if (typeof length === 'number') {
					foundLength = length;
				}
			} catch (e) {}
		}
	});
	return foundLength;
};

var isTypedArray = require('is-typed-array');

module.exports = function typedArrayLength(value) {
	if (!isTypedArray(value)) {
		return false;
	}
	return tryTypedArrays(value);
};
