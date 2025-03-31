'use strict';

var truncate = require('./truncate');
var Type = require('./Type');

var $isFinite = require('../helpers/isFinite');

// https://262.ecma-international.org/14.0/#sec-isintegralnumber

module.exports = function IsIntegralNumber(argument) {
	if (Type(argument) !== 'Number' || !$isFinite(argument)) {
		return false;
	}
	return truncate(argument) === argument;
};
