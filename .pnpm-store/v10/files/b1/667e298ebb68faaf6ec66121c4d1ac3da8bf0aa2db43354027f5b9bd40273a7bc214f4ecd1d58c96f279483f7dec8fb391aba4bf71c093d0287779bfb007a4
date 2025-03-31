'use strict';

var test = require('tape');

var names = require('../');

test('typed array names', function (t) {
	for (var i = 0; i < names.length; i++) {
		t.equal(typeof names[i], 'string', 'is string');
		t.equal(names.indexOf(names[i]), i, 'is unique');

		t.match(typeof global[names[i]], /^(?:function|undefined)$/, 'is a global function, or `undefined`');
	}

	t.end();
});
