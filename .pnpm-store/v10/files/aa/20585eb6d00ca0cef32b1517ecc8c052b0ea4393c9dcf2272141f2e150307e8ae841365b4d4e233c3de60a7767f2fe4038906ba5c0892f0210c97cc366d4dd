'use strict';

var ArraySpeciesCreate = require('es-abstract/2023/ArraySpeciesCreate');
var FlattenIntoArray = require('es-abstract/2023/FlattenIntoArray');
var Get = require('es-abstract/2023/Get');
var ToIntegerOrInfinity = require('es-abstract/2023/ToIntegerOrInfinity');
var ToLength = require('es-abstract/2023/ToLength');
var ToObject = require('es-abstract/2023/ToObject');

module.exports = function flat() {
	var O = ToObject(this);
	var sourceLen = ToLength(Get(O, 'length'));

	var depthNum = 1;
	if (arguments.length > 0 && typeof arguments[0] !== 'undefined') {
		depthNum = ToIntegerOrInfinity(arguments[0]);
	}

	var A = ArraySpeciesCreate(O, 0);
	FlattenIntoArray(A, O, sourceLen, 0, depthNum);
	return A;
};
