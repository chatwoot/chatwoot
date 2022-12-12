'use strict';

var define = require('define-properties');
var getPolyfill = require('./polyfill');

module.exports = function shimArrayPrototypeMap() {
	var polyfill = getPolyfill();
	define(
		Array.prototype,
		{ map: polyfill },
		{ map: function () { return Array.prototype.map !== polyfill; } }
	);
	return polyfill;
};
