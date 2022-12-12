'use strict';

var padStart = require('../implementation');
var callBind = require('call-bind');
var test = require('tape');
var hasStrictMode = require('has-strict-mode')();
var runTests = require('./tests');

test('as a function', function (t) {
	t.test('bad array/this value', { skip: !hasStrictMode }, function (st) {
		/* eslint no-useless-call: 0 */
		st['throws'](function () { padStart.call(undefined); }, TypeError, 'undefined is not an object');
		st['throws'](function () { padStart.call(null); }, TypeError, 'null is not an object');
		st.end();
	});

	runTests(callBind(padStart), t);

	t.end();
});
