'use strict';

var GetIntrinsic = require('get-intrinsic');
var $concat = GetIntrinsic('%Array.prototype.concat%');

var callBind = require('call-bind');

var callBound = require('call-bind/callBound');
var $slice = callBound('Array.prototype.slice');

var hasSymbols = require('has-symbols/shams')();
var isConcatSpreadable = hasSymbols && Symbol.isConcatSpreadable;

var empty = [];
var $concatApply = isConcatSpreadable ? callBind.apply($concat, empty) : null;
var $concatCall = isConcatSpreadable ? null : callBind($concat, empty);

var isArray = isConcatSpreadable ? require('isarray') : null;

module.exports = isConcatSpreadable
	// eslint-disable-next-line no-unused-vars
	? function safeArrayConcat(item) {
		for (var i = 0; i < arguments.length; i += 1) {
			var arg = arguments[i];
			if (arg && typeof arg === 'object' && typeof arg[isConcatSpreadable] === 'boolean') {
				if (!empty[isConcatSpreadable]) {
					empty[isConcatSpreadable] = true;
				}
				var arr = isArray(arg) ? $slice(arg) : [arg];
				arr[isConcatSpreadable] = true; // shadow the property. TODO: use [[Define]]
				arguments[i] = arr;
			}
		}
		return $concatApply(arguments);
	}
	: $concatCall;
