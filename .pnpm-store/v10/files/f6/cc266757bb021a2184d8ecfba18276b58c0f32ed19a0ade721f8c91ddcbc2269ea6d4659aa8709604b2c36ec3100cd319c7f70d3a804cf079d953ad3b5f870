'use strict';

var GetIntrinsic = require('get-intrinsic');
var callBound = require('call-bind/callBound');
var SLOT = require('internal-slot');

var $TypeError = GetIntrinsic('%TypeError%');

var ClearKeptObjects = require('./ClearKeptObjects');
var Type = require('./Type');

var $push = callBound('Array.prototype.push');

// https://262.ecma-international.org/12.0/#sec-addtokeptobjects

module.exports = function AddToKeptObjects(object) {
	if (Type(object) !== 'Object') {
		throw new $TypeError('Assertion failed: `object` must be an Object');
	}
	$push(SLOT.get(ClearKeptObjects, '[[es-abstract internal: KeptAlive]]'), object);
};
