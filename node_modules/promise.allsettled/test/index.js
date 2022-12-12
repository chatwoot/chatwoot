'use strict';

var allSettled = require('..');
var test = require('tape');
var runTests = require('./tests');

test('as a function', function (t) {
	t.test('bad Promise/this value', function (st) {
		// below test is skipped, because for convenience, i'm explicitly turning `undefined` into `Promise` in the main export
		// eslint-disable-next-line no-useless-call
		// st['throws'](function () { any.call(undefined, []); }, TypeError, 'undefined is not an object');

		// eslint-disable-next-line no-useless-call
		st['throws'](function () { allSettled.call(null, []); }, TypeError, 'null is not an object');
		st.end();
	});

	runTests(allSettled, t);

	t.end();
});
