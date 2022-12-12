'use strict';

var arrayMethodBoxesProperly = require('es-array-method-boxes-properly');

var implementation = require('./implementation');

module.exports = function getPolyfill() {
	var method = Array.prototype.map;
	return arrayMethodBoxesProperly(method) ? method : implementation;
};
