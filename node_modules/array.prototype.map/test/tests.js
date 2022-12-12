var hasStrictMode = require('has-strict-mode')();

var global = Function('return this')(); // eslint-disable-line no-new-func
var identity = function (x) { return x; };
var arrayWrap = function (x) { return [x]; };

var canDistinguishSparseFromUndefined = 0 in [undefined]; // IE 6 - 8 have a bug where this returns false.
var undefinedIfNoSparseBug = canDistinguishSparseFromUndefined ? undefined : { valueOf: function () { return 0; } };

var createArrayLikeFromArray = function createArrayLike(arr) {
	var o = {};
	for (var i = 0; i < arr.length; i += 1) {
		if (i in arr) {
			o[i] = arr[i];
		}
	}
	o.length = arr.length;
	return o;
};

var getTestArr = function () {
	var arr = [2, 3, undefinedIfNoSparseBug, true, 'hej', null, false, 0];
	delete arr[1];
	return arr;
};

module.exports = function (map, t) {
	t.test('does not change the array it is called on', function (st) {
		var arr = getTestArr();
		var copy = getTestArr();
		map(arr, arrayWrap);
		st.deepEqual(arr, copy, 'array');

		var arrayLike = createArrayLikeFromArray(arr);
		map(arrayLike, arrayWrap);
		st.deepEqual(arrayLike, createArrayLikeFromArray(copy), 'arrayLike');

		st.end();
	});

	t.test('properly translates the values as according to the callback', function (st) {
		var expected = [[2], [3], [undefinedIfNoSparseBug], [true], ['hej'], [null], [false], [0]];
		delete expected[1];

		var result = map(getTestArr(), arrayWrap);
		st.deepEqual(result, expected, 'array');

		var arrayLikeResult = map(createArrayLikeFromArray(getTestArr()), arrayWrap);
		st.deepEqual(arrayLikeResult, expected, 'arrayLike');

		st.end();
	});

	t.test('skips non-existing values', function (st) {
		var array = [1, 2, 3, 4];
		var arrayLike = createArrayLikeFromArray([1, 2, 3, 4]);
		delete array[2];
		delete arrayLike[2];

		var i = 0;
		map(array, function () { i += 1; });
		st.equal(i, 3, 'array');

		i = 0;
		map(arrayLike, function () { i += 1; });
		st.equal(i, 3, 'arrayLike');

		st.end();
	});

	t.test('passes the correct values to the callback', function (st) {
		st.plan(5);

		var expectedValue = {};
		var arr = [expectedValue];
		var context = {};
		map(
			arr,
			function (value, key, list) {
				st.equal(arguments.length, 3);
				st.equal(value, expectedValue, 'first argument is the value');
				st.equal(key, 0, 'second argument is the index');
				st.equal(list, arr, 'third argument is the array being iterated');
				st.equal(this, context, 'receiver is the expected value');
			},
			context
		);

		st.end();
	});

	t.test('does not visit elements added to the array after it has begun', function (st) {
		st.plan(4);

		var arr = [1, 2, 3];
		var i = 0;
		map(arr, function (a) {
			i += 1;
			arr.push(a + 3);
		});
		st.deepEqual(arr, [1, 2, 3, 4, 5, 6], 'array has received 3 new elements');
		st.equal(i, 3, 'map callback only called thrice');

		var arrayLike = createArrayLikeFromArray([1, 2, 3]);
		i = 0;
		map(arrayLike, function (a) {
			i += 1;
			arrayLike[arrayLike.length] = a + 3;
			arrayLike.length += 1;
		});
		st.deepEqual(Array.prototype.slice.call(arrayLike), [1, 2, 3, 4, 5, 6], 'arrayLike has received 3 new elements');
		st.equal(i, 3, 'map callback only called thrice');

		st.end();
	});

	t.test('does not visit elements deleted from the array after it has begun', function (st) {
		var arr = [1, 2, 3];
		var actual = [];
		map(arr, function (x, i) {
			actual.push([i, x]);
			delete arr[1];
		});
		st.deepEqual(actual, [[0, 1], [2, 3]]);

		st.end();
	});

	t.test('sets the right context when given none', function (st) {
		var context;
		map([1], function () { context = this; });
		st.equal(context, global, 'receiver is global object in sloppy mode');

		st.test('strict mode', { skip: !hasStrictMode }, function (sst) {
			map([1], function () {
				'use strict';

				context = this;
			});
			sst.equal(context, undefined, 'receiver is undefined in strict mode');
			sst.end();
		});

		st.end();
	});

	t.test('empty array', function (st) {
		var arr = [];
		var actual = map(arr, identity);
		st.notEqual(actual, arr, 'empty array returns !== array');
		st.deepEqual(actual, arr, 'empty array returns empty array');

		st.end();
	});

	t.test('list arg boxing', function (st) {
		st.plan(3);

		map('f', function (item, index, list) {
			st.equal(item, 'f', 'letter matches');
			st.equal(typeof list, 'object', 'primitive list arg is boxed');
			st.equal(Object.prototype.toString.call(list), '[object String]', 'boxed list arg is a String');
		});

		st.end();
	});
};
