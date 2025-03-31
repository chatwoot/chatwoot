'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('./Type');

// https://262.ecma-international.org/6.0/#sec-createiterresultobject

module.exports = function CreateIterResultObject(value, done) {
	if (Type(done) !== 'Boolean') {
		throw new $TypeError('Assertion failed: Type(done) is not Boolean');
	}
	return {
		value: value,
		done: done
	};
};
