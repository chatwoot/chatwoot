/* eslint no-restricted-syntax: 0, no-with: 0, strict: 0 */

var test = require('tape');

var shimUnscopables = require('../');

test('`with` statement', { skip: typeof Symbol !== 'function' || !Symbol.unscopables }, function (t) {
	var entries;
	var concat;
	with ([]) {
		t.equal(concat, Array.prototype.concat, 'concat is dynamically bound');
		t.notEqual(entries, Array.prototype.entries, 'entries is not dynamically bound');
	}

	var obj = {
		foo: 1,
		bar: 2
	};
	var foo;
	var bar;
	obj[Symbol.unscopables] = { foo: true };
	with (obj) {
		t.equal(foo, undefined);
		t.equal(bar, obj.bar);
	}

	shimUnscopables('concat');

	with ([]) {
		t.notEqual(concat, Array.prototype.concat, 'concat is no longer dynamically bound');
		t.notEqual(entries, Array.prototype.entries, 'entries is still not dynamically bound');
	}

	t.end();
});
