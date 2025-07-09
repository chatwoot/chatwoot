'use strict';

var $StringValueOf = require('call-bind/callBound')('String.prototype.valueOf');

var Type = require('./Type');

// https://262.ecma-international.org/6.0/#sec-properties-of-the-string-prototype-object

module.exports = function thisStringValue(value) {
	if (Type(value) === 'String') {
		return value;
	}

	return $StringValueOf(value);
};
