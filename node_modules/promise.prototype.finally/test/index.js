'use strict';

var promiseFinally = require('../');
var test = require('tape');
var runTests = require('./tests');

test('as a function', function (t) {
	t.test('bad Promise/this value', function (st) {
		st['throws'](function () { promiseFinally(undefined); }, TypeError, 'undefined is not an object');
		st['throws'](function () { promiseFinally(null); }, TypeError, 'null is not an object');
		st.end();
	});

	runTests(promiseFinally, t);

	t.end();
});
