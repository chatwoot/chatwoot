'use strict';

var callBound = require('call-bind/callBound');
var GetIntrinsic = require('get-intrinsic');
var isRegex = require('is-regex');

var $exec = callBound('RegExp.prototype.exec');
var $TypeError = GetIntrinsic('%TypeError%');

module.exports = function regexTester(regex) {
	if (!isRegex(regex)) {
		throw new $TypeError('`regex` must be a RegExp');
	}
	return function test(s) {
		return $exec(regex, s) !== null;
	};
};
