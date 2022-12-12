'use strict';

if (typeof process !== 'undefined') {
	process.on('unhandledRejection', function () {});
}

var assertArray = function (t, value, length, assertType) {
	t.ok(Array.isArray(value), 'value is an array');
	t.equal(value.length, length, 'length is ' + length);
	if (typeof assertType === 'function') {
		for (var i = 0; i < value.length; i += 1) {
			assertType(value[i]);
		}
	}
};

var yes = function makeFulfilledResult(value) {
	return { status: 'fulfilled', value: value };
};
var no = function makeRejectedResult(reason) {
	return { status: 'rejected', reason: reason };
};

module.exports = function (allSettled, t) {
	if (typeof Promise !== 'function') {
		return t.skip('No global Promise detected');
	}

	var a = {};
	var b = {};
	var c = {};

	t.test('no promise values', function (st) {
		st.plan(1);
		allSettled([a, b, c]).then(function (results) {
			st.deepEqual(results, [yes(a), yes(b), yes(c)]);
		});
	});

	t.test('all fulfilled', function (st) {
		st.plan(1);
		allSettled([
			Promise.resolve(a),
			Promise.resolve(b),
			Promise.resolve(c)
		]).then(function (results) {
			st.deepEqual(results, [
				yes(a),
				yes(b),
				yes(c)
			]);
		});
	});

	t.test('all rejected', function (st) {
		st.plan(1);
		allSettled([
			Promise.reject(a),
			Promise.reject(b),
			Promise.reject(c)
		]).then(function (results) {
			st.deepEqual(results, [
				no(a),
				no(b),
				no(c)
			]);
		});
	});

	t.test('mixed', function (st) {
		st.plan(1);
		allSettled([
			a,
			Promise.resolve(b),
			Promise.reject(c)
		]).then(function (results) {
			st.deepEqual(results, [
				yes(a),
				yes(b),
				no(c)
			]);
		});
	});

	t.test('poisoned .then', function (st) {
		st.plan(1);
		var promise = new Promise(function () {});
		promise.then = function () { throw new EvalError(); };
		allSettled([promise]).then(function () {
			st.fail('should not reach here');
		}, function (reason) {
			st.equal(reason instanceof EvalError, true, 'expected error was thrown');
		});
	});

	var Subclass = (function () {
		try {
			// eslint-disable-next-line no-new-func
			return Function('class Subclass extends Promise { constructor(...args) { super(...args); this.thenArgs = []; } then(...args) { Subclass.thenArgs.push(args); this.thenArgs.push(args); return super.then(...args); } } Subclass.thenArgs = []; return Subclass;')();
		} catch (e) { /**/ }

		return false;
	}());
	t.test('inheritance', { skip: !Subclass }, function (st) {
		st.test('preserves correct subclass', function (s2t) {
			var promise = allSettled.call(Subclass, [1]);
			s2t.ok(promise instanceof Subclass, 'promise is instanceof Subclass');
			s2t.equal(promise.constructor, Subclass, 'promise.constructor is Subclass');

			s2t.end();
		});

		st.test('invokes the subclass’ then', function (s2t) {
			Subclass.thenArgs.length = 0;

			var original = Subclass.resolve();
			assertArray(s2t, Subclass.thenArgs, 0);
			assertArray(s2t, original.thenArgs, 0);

			allSettled.call(Subclass, [original]);

			assertArray(s2t, original.thenArgs, 1);
			/*
			 * TODO: uncomment. node v12+'s native implementation fails this check.
			 * Either v8's impl is wrong, or this package's impl is wrong - figure out which.
			 * assertArray(s2t, Subclass.thenArgs, 2);
			 */

			s2t.end();
		});
	});

	return t.comment('tests completed');
};
