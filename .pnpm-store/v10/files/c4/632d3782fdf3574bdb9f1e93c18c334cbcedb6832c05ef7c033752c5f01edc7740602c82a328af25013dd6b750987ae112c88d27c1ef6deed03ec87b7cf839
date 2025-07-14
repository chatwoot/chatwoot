'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var Get = require('./Get');
var ToBoolean = require('./ToBoolean');
var Type = require('./Type');

// https://262.ecma-international.org/6.0/#sec-iteratorcomplete

module.exports = function IteratorComplete(iterResult) {
	if (Type(iterResult) !== 'Object') {
		throw new $TypeError('Assertion failed: Type(iterResult) is not Object');
	}
	return ToBoolean(Get(iterResult, 'done'));
};
