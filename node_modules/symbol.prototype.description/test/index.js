'use strict';

var hasSymbols = require('has-symbols')();
var test = require('tape');

var description = require('../');
var runTests = require('./tests');

test('as a function', function (t) {
	if (!hasSymbols) {
		t.fail('Symbols not supported in this environment');
		return t.end();
	}

	t.test('bad array/this value', function (st) {
		st.throws(function () { description(undefined); }, TypeError, 'undefined is not an object');
		st.throws(function () { description(null); }, TypeError, 'null is not an object');
		st.end();
	});

	runTests(description, t);

	t.end();
});
