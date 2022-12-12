'use strict';

var padEnd = require('../implementation');
var callBind = require('call-bind');
var test = require('tape');
var hasStrictMode = require('has-strict-mode')();
var runTests = require('./tests');

test('as a function', function (t) {
	t.test('bad array/this value', { skip: !hasStrictMode }, function (st) {
		/* eslint no-useless-call: 0 */
		st['throws'](function () { padEnd.call(undefined); }, TypeError, 'undefined is not an object');
		st['throws'](function () { padEnd.call(null); }, TypeError, 'null is not an object');
		st.end();
	});

	runTests(callBind(padEnd), t);

	t.end();
});
