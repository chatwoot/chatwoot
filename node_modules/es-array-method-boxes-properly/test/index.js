var test = require('tape');

var arrayMethodBoxesProperly = require('..');

test('arrayMethodBoxesProperly', function (t) {
	t.equal(typeof arrayMethodBoxesProperly, 'function', 'is a function');

	t.equal(typeof arrayMethodBoxesProperly(), 'boolean', 'returns a boolean');

	t.end();
});
