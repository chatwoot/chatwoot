'use strict';

var $BooleanValueOf = require('call-bind/callBound')('Boolean.prototype.valueOf');

var Type = require('./Type');

// https://262.ecma-international.org/6.0/#sec-properties-of-the-boolean-prototype-object

module.exports = function thisBooleanValue(value) {
	if (Type(value) === 'Boolean') {
		return value;
	}

	return $BooleanValueOf(value);
};
