'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('./Type');

var isSharedArrayBuffer = require('is-shared-array-buffer');

// https://262.ecma-international.org/8.0/#sec-issharedarraybuffer

module.exports = function IsSharedArrayBuffer(obj) {
	if (Type(obj) !== 'Object') {
		throw new $TypeError('Assertion failed: Type(O) is not Object');
	}

	return isSharedArrayBuffer(obj);
};
