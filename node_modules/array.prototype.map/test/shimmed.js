require('../shim')();

var test = require('tape');
var defineProperties = require('define-properties');
var bind = require('function-bind');
var hasStrictMode = require('has-strict-mode')();

var isEnumerable = Object.prototype.propertyIsEnumerable;
var functionsHaveNames = require('functions-have-names')();

var runTests = require('./tests');

test('shimmed', function (t) {
	t.equal(Array.prototype.map.length, 1, 'Array#map has a length of 1');
	t.test('Function name', { skip: !functionsHaveNames }, function (st) {
		st.equal(Array.prototype.map.name, 'map', 'Array#map has name "map"');
		st.end();
	});

	t.test('enumerability', { skip: !defineProperties.supportsDescriptors }, function (et) {
		et.equal(false, isEnumerable.call(Array.prototype, 'map'), 'Array#map is not enumerable');
		et.end();
	});

	var supportsStrictMode = (function () { return typeof this === 'undefined'; }());

	t.test('bad array/this value', { skip: !supportsStrictMode }, function (st) {
		st['throws'](function () { return Array.prototype.map.call(undefined, 'a'); }, TypeError, 'undefined is not an object');
		st['throws'](function () { return Array.prototype.map.call(null, 'a'); }, TypeError, 'null is not an object');
		st.end();
	});

	t.test('receiver boxing', function (st) {
		st.plan(hasStrictMode ? 3 : 2);

		var context = 'x';

		Array.prototype.map.call(
			'f',
			function () {
				st.equal(typeof this, 'object');
				st.equal(String.prototype.toString.call(this), context);
			},
			context
		);

		st.test('strict mode', { skip: !hasStrictMode }, function (sst) {
			sst.plan(2);

			Array.prototype.map.call(
				'f',
				function () {
					'use strict';

					sst.equal(typeof this, 'string');
					sst.equal(this, context);
				},
				context
			);
			sst.end();
		});

		st.end();
	});

	runTests(bind.call(Function.call, Array.prototype.map), t);

	t.end();
});
