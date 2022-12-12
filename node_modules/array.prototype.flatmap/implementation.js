'use strict';

var ArraySpeciesCreate = require('es-abstract/2020/ArraySpeciesCreate');
var FlattenIntoArray = require('es-abstract/2020/FlattenIntoArray');
var Get = require('es-abstract/2020/Get');
var IsCallable = require('es-abstract/2020/IsCallable');
var ToLength = require('es-abstract/2020/ToLength');
var ToObject = require('es-abstract/2020/ToObject');

module.exports = function flatMap(mapperFunction) {
	var O = ToObject(this);
	var sourceLen = ToLength(Get(O, 'length'));

	if (!IsCallable(mapperFunction)) {
		throw new TypeError('mapperFunction must be a function');
	}

	var T;
	if (arguments.length > 1) {
		T = arguments[1];
	}

	var A = ArraySpeciesCreate(O, 0);
	FlattenIntoArray(A, O, sourceLen, 0, 1, mapperFunction, T);
	return A;
};
