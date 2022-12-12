'use strict';

var defineProperties = require('define-properties');
var bind = require('function-bind');
var isEnumerable = Object.prototype.propertyIsEnumerable;
var functionsHaveNames = function f() {}.name === 'f';
var fnNamesConfigurable = functionsHaveNames && Object.getOwnPropertyDescriptor && Object.getOwnPropertyDescriptor(function f() {}, 'name').configurable;

var runTests = require('./tests');

module.exports = function (t) {
	t.equal(Promise.prototype['finally'].length, 1, 'Promise.prototype.finally has a length of 1');
	t.test('Function name', { skip: !fnNamesConfigurable }, function (st) {
		st.equal(Promise.prototype['finally'].name, 'finally', 'Promise.prototype.finally has name "finally"');
		st.end();
	});

	t.test('enumerability', { skip: !defineProperties.supportsDescriptors }, function (et) {
		et.equal(false, isEnumerable.call(Promise.prototype, 'finally'), 'Promise.prototype.finally is not enumerable');
		et.end();
	});

	var supportsStrictMode = (function () { return typeof this === 'undefined'; }());

	t.test('bad object value', { skip: !supportsStrictMode }, function (st) {
		st['throws'](function () { return Promise.prototype['finally'].call(undefined); }, TypeError, 'undefined is not an object');
		st['throws'](function () { return Promise.prototype['finally'].call(null); }, TypeError, 'null is not an object');
		st.end();
	});

	runTests(bind.call(Function.call, Promise.prototype['finally']), t);
};
