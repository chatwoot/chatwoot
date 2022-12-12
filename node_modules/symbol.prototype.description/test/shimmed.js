'use strict';

var originalSymbol = typeof Symbol === 'function' ? Symbol : null;
require('../auto');

var has = require('has');
var keys = require('reflect.ownkeys');
var hasSymbols = require('has-symbols')();
var test = require('tape');
var isEnumerable = Object.prototype.propertyIsEnumerable;

var runTests = require('./tests');
var getInferredName = require('es-abstract/helpers/getInferredName');

test('shimmed', function (t) {
	if (!hasSymbols) {
		t.fail('Symbols not supported in this environment');
		return t.end();
	}

	t.test('enumerability', function (et) {
		et.equal(false, isEnumerable.call(Symbol.prototype, 'description'), 'Symbol.prototype.description is not enumerable');
		et.end();
	});

	t.test('getter', function (st) {
		var desc = Object.getOwnPropertyDescriptor(Symbol.prototype, 'description');
		st.ok(desc, 'has a descriptor');
		st.equal(typeof desc.get, 'function', '"get" is a function');

		st.equal(desc.get.length, 0, 'getter length is 0');

		st.end();
	});

	t.test('hasOwnProperty', function (st) {
		var ownProperties = keys(originalSymbol);
		t.comment('expected original keys: ' + ownProperties);
		for (var i = 0; i < ownProperties.length; i++) {
			var p = ownProperties[i];
			if (p !== 'length' && p !== 'arguments' && p !== 'caller' && p !== 'callee') {
				st.ok(has(Symbol, p), 'has own property: ' + p);
			}
		}
		st.end();
	});

	var supportsStrictMode = (function () { return typeof this === 'undefined'; }());

	t.test('bad object value', { skip: !supportsStrictMode }, function (st) {
		st.throws(function () { return Object.values(undefined); }, TypeError, 'undefined is not an object');
		st.throws(function () { return Object.values(null); }, TypeError, 'null is not an object');
		st.end();
	});

	t.test('only possible when shimmed (or inference is supported)', function (st) {
		st.equal(Symbol('').description, '', 'Symbol("") description is empty string');
		st.end();
	});

	t.test('ensure global Symbol is NOT shimmed', { skip: !getInferredName }, function (st) {
		st.equal(Symbol, originalSymbol, 'global Symbol is not overridden');
		st.end();
	});

	runTests(function (x) { return x.description; }, t);

	t.end();
});
