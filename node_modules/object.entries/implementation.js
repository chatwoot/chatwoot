'use strict';

var RequireObjectCoercible = require('es-abstract/2020/RequireObjectCoercible');
var has = require('has');
var callBound = require('call-bind/callBound');
var $isEnumerable = callBound('Object.prototype.propertyIsEnumerable');

module.exports = function entries(O) {
	var obj = RequireObjectCoercible(O);
	var entrys = [];
	for (var key in obj) {
		if (has(obj, key) && $isEnumerable(obj, key)) {
			entrys.push([key, obj[key]]);
		}
	}
	return entrys;
};
