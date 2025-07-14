'use strict';

var forEach = require('for-each');
var callBind = require('call-bind');

var typedArrays = require('available-typed-arrays')();

var getters = {};
var hasProto = require('has-proto')();

var gOPD = Object.getOwnPropertyDescriptor;
var oDP = Object.defineProperty;
if (gOPD) {
	var getByteOffset = function (x) {
		return x.byteOffset;
	};
	forEach(typedArrays, function (typedArray) {
		// In Safari 7, Typed Array constructors are typeof object
		if (typeof global[typedArray] === 'function' || typeof global[typedArray] === 'object') {
			var Proto = global[typedArray].prototype;
			var descriptor = gOPD(Proto, 'byteOffset');
			if (!descriptor && hasProto) {
				var superProto = Proto.__proto__; // eslint-disable-line no-proto
				descriptor = gOPD(superProto, 'byteOffset');
			}
			// Opera 12.16 has a magic byteOffset data property on instances AND on Proto
			if (descriptor && descriptor.get) {
				getters[typedArray] = callBind(descriptor.get);
			} else if (oDP) {
				// this is likely an engine where instances have a magic byteOffset data property
				var arr = new global[typedArray](2);
				descriptor = gOPD(arr, 'byteOffset');
				if (descriptor && descriptor.configurable) {
					oDP(arr, 'length', { value: 3 });
				}
				if (arr.length === 2) {
					getters[typedArray] = getByteOffset;
				}
			}
		}
	});
}

var tryTypedArrays = function tryAllTypedArrays(value) {
	var foundOffset;
	forEach(getters, function (getter) {
		if (typeof foundOffset !== 'number') {
			try {
				var offset = getter(value);
				if (typeof offset === 'number') {
					foundOffset = offset;
				}
			} catch (e) {}
		}
	});
	return foundOffset;
};

var isTypedArray = require('is-typed-array');

module.exports = function typedArrayByteOffset(value) {
	if (!isTypedArray(value)) {
		return false;
	}
	return tryTypedArrays(value);
};
