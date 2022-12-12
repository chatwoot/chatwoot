'use strict';

var test = require('tape');

var isObject = require('../index');

test('returns true for objects', function (assert) {
	assert.equal(isObject({}), true);
	assert.equal(isObject([]), true);

	assert.end();
});

test('returns false for null', function (assert) {
	assert.equal(isObject(null), false);

	assert.end();
});

test('returns false for undefined', function (assert) {
	assert.equal(isObject(undefined), false);

	assert.end();
});

test('returns false for booleans', function (assert) {
	assert.equal(isObject(true), false);
	assert.equal(isObject(false), false);

	assert.end();
});

test('returns false for primitives', function (assert) {
	assert.equal(isObject(42), false);
	assert.equal(isObject('foo'), false);

	assert.end();
});

test('returns false for functions', function (assert) {
	assert.equal(isObject(function () {}), false);

	assert.end();
});
