'use strict';

var requirePromise = require('./requirePromise');

var getPolyfill = require('./polyfill');
var define = require('define-properties');

module.exports = function shimAllSettled() {
	requirePromise();

	var polyfill = getPolyfill();
	define(Promise, { allSettled: polyfill }, {
		allSettled: function testAllSettled() {
			return Promise.allSettled !== polyfill;
		}
	});
	return polyfill;
};
