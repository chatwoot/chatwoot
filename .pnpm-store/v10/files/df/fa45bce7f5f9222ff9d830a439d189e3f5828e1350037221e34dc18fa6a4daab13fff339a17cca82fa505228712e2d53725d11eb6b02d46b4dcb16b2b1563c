'use strict';

var assertRecord = require('../helpers/assertRecord');
var fromPropertyDescriptor = require('../helpers/fromPropertyDescriptor');

var Type = require('./Type');

// https://262.ecma-international.org/6.0/#sec-frompropertydescriptor

module.exports = function FromPropertyDescriptor(Desc) {
	if (typeof Desc !== 'undefined') {
		assertRecord(Type, 'Property Descriptor', 'Desc', Desc);
	}

	return fromPropertyDescriptor(Desc);
};
