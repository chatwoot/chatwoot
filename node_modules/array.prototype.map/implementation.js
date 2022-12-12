'use strict';

var ArraySpeciesCreate = require('es-abstract/2020/ArraySpeciesCreate');
var Call = require('es-abstract/2020/Call');
var CreateDataPropertyOrThrow = require('es-abstract/2020/CreateDataPropertyOrThrow');
var Get = require('es-abstract/2020/Get');
var HasProperty = require('es-abstract/2020/HasProperty');
var IsCallable = require('es-abstract/2020/IsCallable');
var ToUint32 = require('es-abstract/2020/ToUint32');
var ToObject = require('es-abstract/2020/ToObject');
var ToString = require('es-abstract/2020/ToString');
var callBound = require('call-bind/callBound');
var isString = require('is-string');

// Check failure of by-index access of string characters (IE < 9) and failure of `0 in boxedString` (Rhino)
var boxedString = Object('a');
var splitString = boxedString[0] !== 'a' || !(0 in boxedString);

var strSplit = callBound('String.prototype.split');

module.exports = function map(callbackfn) {
	var O = ToObject(this);
	var self = splitString && isString(O) ? strSplit(O, '') : O;
	var len = ToUint32(self.length);

	// If no callback function or if callback is not a callable function
	if (!IsCallable(callbackfn)) {
		throw new TypeError('Array.prototype.map callback must be a function');
	}

	var T;
	if (arguments.length > 1) {
		T = arguments[1];
	}

	var A = ArraySpeciesCreate(O, len);
	var k = 0;
	while (k < len) {
		var Pk = ToString(k);
		var kPresent = HasProperty(O, Pk);
		if (kPresent) {
			var kValue = Get(O, Pk);
			var mappedValue = Call(callbackfn, T, [kValue, k, O]);
			CreateDataPropertyOrThrow(A, Pk, mappedValue);
		}
		k += 1;
	}

	return A;
};
