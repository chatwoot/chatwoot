'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var CreateNonEnumerableDataPropertyOrThrow = require('./CreateNonEnumerableDataPropertyOrThrow');
var Get = require('./Get');
var HasProperty = require('./HasProperty');
var Type = require('./Type');

// https://262.ecma-international.org/13.0/#sec-installerrorcause

module.exports = function InstallErrorCause(O, options) {
	if (Type(O) !== 'Object') {
		throw new $TypeError('Assertion failed: Type(O) is not Object');
	}

	if (Type(options) === 'Object' && HasProperty(options, 'cause')) {
		var cause = Get(options, 'cause');
		CreateNonEnumerableDataPropertyOrThrow(O, 'cause', cause);
	}
};
