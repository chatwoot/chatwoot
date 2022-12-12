'use strict';

var defineProperties = require('define-properties');
var isEnumerable = Object.prototype.propertyIsEnumerable;
var functionsHaveNames = require('functions-have-names')();

var runTests = require('./tests');

module.exports = function (t) {
	t.equal(Promise.allSettled.length, 1, 'Promise.allSettled has a length of 1');
	t.test('Function name', { skip: !functionsHaveNames }, function (st) {
		st.equal(Promise.allSettled.name, 'allSettled', 'Promise.allSettled has name "allSettled"');
		st.end();
	});

	t.test('enumerability', { skip: !defineProperties.supportsDescriptors }, function (et) {
		et.equal(false, isEnumerable.call(Promise, 'allSettled'), 'Promise.allSettled is not enumerable');
		et.end();
	});

	var supportsStrictMode = (function () { return typeof this === 'undefined'; }());

	t.test('bad object value', { skip: !supportsStrictMode }, function (st) {
		st['throws'](function () { return Promise.allSettled.call(undefined); }, TypeError, 'undefined is not an object');
		st['throws'](function () { return Promise.allSettled.call(null); }, TypeError, 'null is not an object');
		st.end();
	});

	runTests(function allSettled(iterable) { return Promise.allSettled.call(typeof this === 'undefined' ? Promise : this, iterable); }, t);
};
