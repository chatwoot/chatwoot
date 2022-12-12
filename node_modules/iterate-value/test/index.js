'use strict';

var test = require('tape');
var forEach = require('for-each');
var hasSymbols = require('has-symbols')();
var hasBigInts = require('has-bigints')();
var debug = require('object-inspect');
var iterate = require('..');

function testIteration(t, iterable, expected, message) {
	t.deepEqual(iterate(iterable), expected, 'no callback: ' + message);
	var values = [];
	iterate(iterable, function (x) { values.push(x); });
	t.deepEqual(values, expected, 'callback: ' + message);
	return values;
}

function testNonIterable(t, nonIterable, isNumber) {
	t['throws'](function () { iterate(nonIterable); }, TypeError, debug(nonIterable) + ' is not iterable');
	if (nonIterable != null && hasSymbols && (!isNumber || !nonIterable[Symbol.iterator])) {
		var o = Object(nonIterable);
		o[Symbol.iterator] = function () {
			return [1, 2, 3][Symbol.iterator]();
		};
		testIteration(t, o, [1, 2, 3], 'fake iterator works on non-iterable ' + debug(o));
	}
}

function getArguments() {
	return arguments;
}

test('non-iterables', function (t) {
	var numbers = [0, -0, NaN, Infinity, 42];
	var nonIterables = [
		undefined,
		null,
		true,
		false,
		{},
		/a/g,
		function () {}
	];
	if (hasSymbols) {
		nonIterables.push(Symbol.iterator);
	}
	if (hasBigInts) {
		nonIterables.push(BigInt(42), BigInt(0));
	}
	forEach(nonIterables, function (nonIterable) {
		testNonIterable(t, nonIterable);
	});
	if (hasSymbols && NaN[Symbol.iterator]) {
		t.comment('# SKIP core-js v2 makes numbers iterable, in violation of the spec');
	}
	forEach(numbers, function (number) {
		testNonIterable(t, number, true);
	});

	t.end();
});

test('strings', function (t) {
	testIteration(t, '', [], 'empty string');
	testIteration(t, 'abc', ['a', 'b', 'c'], debug('abc'));
	testIteration(t, 'a💩c', ['a', '💩', 'c'], debug('a💩c'));

	t.end();
});

test('arrays', function (t) {
	forEach([
		[],
		[1, 2, 3]
	], function (arr) {
		testIteration(t, arr, arr, debug(arr));
	});
	var sparse = [1, , 3]; // eslint-disable-line no-sparse-arrays
	var actual = testIteration(t, sparse, [1, undefined, 3], debug(sparse));
	t.ok(1 in actual, 'actual is not sparse');

	t.end();
});

test('arguments', function (t) {
	var empty = getArguments();
	testIteration(t, empty, [], debug(empty));

	var args = getArguments(1, 2, 3);
	testIteration(t, args, [1, 2, 3], debug(args));

	t.end();
});

test('Maps', { skip: typeof Map !== 'function' }, function (t) {
	var empty = new Map();
	testIteration(t, empty, [], debug(empty));

	var m = new Map();
	m.set(1, 2);
	m.set(3, 4);
	testIteration(t, m, [[1, 2], [3, 4]], debug(m));

	t.end();
});

test('Sets', { skip: typeof Set !== 'function' }, function (t) {
	var empty = new Set();
	testIteration(t, empty, [], debug(empty));

	var s = new Set();
	s.add(1);
	s.add(2);
	testIteration(t, s, [1, 2], debug(s));

	t.end();
});

test('non-function callbacks', function (t) {
	forEach([
		null,
		undefined,
		false,
		true,
		0,
		-0,
		NaN,
		42,
		Infinity,
		'',
		'abc',
		/a/g,
		[],
		{}
	], function (nonFunction) {
		t['throws'](
			function () { iterate([], nonFunction); },
			TypeError,
			debug(nonFunction) + ' is not a Function'
		);
	});

	t.end();
});
