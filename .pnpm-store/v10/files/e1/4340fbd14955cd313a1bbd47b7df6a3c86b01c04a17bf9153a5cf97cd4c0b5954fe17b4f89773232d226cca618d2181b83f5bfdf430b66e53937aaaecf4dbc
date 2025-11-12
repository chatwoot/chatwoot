'use strict';

var GetIntrinsic = require('get-intrinsic');
var callBound = require('call-bind/callBound');

var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('./Type');

var isInteger = require('../helpers/isInteger');

var $slice = callBound('String.prototype.slice');

// https://262.ecma-international.org/12.0/#sec-stringindexof

module.exports = function StringIndexOf(string, searchValue, fromIndex) {
	if (Type(string) !== 'String') {
		throw new $TypeError('Assertion failed: `string` must be a String');
	}
	if (Type(searchValue) !== 'String') {
		throw new $TypeError('Assertion failed: `searchValue` must be a String');
	}
	if (!isInteger(fromIndex) || fromIndex < 0) {
		throw new $TypeError('Assertion failed: `fromIndex` must be a non-negative integer');
	}

	var len = string.length;
	if (searchValue === '' && fromIndex <= len) {
		return fromIndex;
	}

	var searchLen = searchValue.length;
	for (var i = fromIndex; i <= (len - searchLen); i += 1) {
		var candidate = $slice(string, i, i + searchLen);
		if (candidate === searchValue) {
			return i;
		}
	}
	return -1;
};
