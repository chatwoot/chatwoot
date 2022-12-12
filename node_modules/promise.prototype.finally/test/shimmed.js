'use strict';

var promiseFinally = require('../');
promiseFinally.shim();

var test = require('tape');

var runTests = require('./builtin');

test('shimmed', function (t) {
	runTests(t);

	t.end();
});
