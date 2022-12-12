'use strict';

var map = require('../');
var bind = require('function-bind');
var test = require('tape');
var runTests = require('./tests');

test('as a function', function (t) {
	t.test('bad array/this value', function (st) {
		st['throws'](bind.call(map, null, undefined, 'a'), TypeError, 'undefined is not an object');
		st['throws'](bind.call(map, null, null, 'a'), TypeError, 'null is not an object');
		st.end();
	});

	runTests(map, t);

	t.end();
});
