var test = require('tape');

var Individual = require('./index.js');

test('can create Individual', function (assert) {
    var obj = Individual('someName', 42);

    assert.equal(obj, 42);

    var obj2 = Individual('someName', 50);

    assert.equal(obj, 42);

    assert.end();
});

test('different keys', function (assert) {
    var obj = Individual('someName2', 42);
    var obj2 = Individual('otherName2', 50);

    assert.equal(obj, 42);
    assert.equal(obj2, 50);

    assert.end();
});
