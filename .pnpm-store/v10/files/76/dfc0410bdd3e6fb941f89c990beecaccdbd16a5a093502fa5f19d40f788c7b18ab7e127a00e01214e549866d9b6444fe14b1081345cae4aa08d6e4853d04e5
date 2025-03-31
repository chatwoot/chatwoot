'use strict';

var callBind = require('call-bind');
var callBound = require('call-bind/callBound');
var GetIntrinsic = require('get-intrinsic');
var isTypedArray = require('is-typed-array');

var $ArrayBuffer = GetIntrinsic('ArrayBuffer', true);
var $Float32Array = GetIntrinsic('Float32Array', true);
var $byteLength = callBound('ArrayBuffer.prototype.byteLength', true);

// in node 0.10, ArrayBuffers have no prototype methods, but have an own slot-checking `slice` method
var abSlice = $ArrayBuffer && !$byteLength && new $ArrayBuffer().slice;
var $abSlice = abSlice && callBind(abSlice);

module.exports = $byteLength || $abSlice
	? function isArrayBuffer(obj) {
		if (!obj || typeof obj !== 'object') {
			return false;
		}
		try {
			if ($byteLength) {
				$byteLength(obj);
			} else {
				$abSlice(obj, 0);
			}
			return true;
		} catch (e) {
			return false;
		}
	}
	: $Float32Array
		// in node 0.8, ArrayBuffers have no prototype or own methods
		? function IsArrayBuffer(obj) {
			try {
				return (new $Float32Array(obj)).buffer === obj && !isTypedArray(obj);
			} catch (e) {
				return typeof obj === 'object' && e.name === 'RangeError';
			}
		}
		: function isArrayBuffer(obj) { // eslint-disable-line no-unused-vars
			return false;
		};
