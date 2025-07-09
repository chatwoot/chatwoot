'use strict';

var assert = require('proclaim');
var traverse = require('../lib');
var toISOString = require('@segment/to-iso-string');

describe('isodate-traverse', function() {
  it('should convert isostrings', function() {
    var obj = { date: '2013-09-04T00:57:26.434Z' };
    traverse(obj);
    assert.strictEqual(toISOString(obj.date), '2013-09-04T00:57:26.434Z');
  });

  it('should not affect irrelevant object properties', function() {
    var obj = { a: '2013-12-13T23:35:50.000Z', b: 'foo', c: null };
    traverse(obj);
    assert.strictEqual(obj.b, 'foo');
    assert.strictEqual(obj.c, null);
  });

  it('should not affect irrelevant array indexes', function() {
    var obj = [ '2013-12-13T23:35:50.000Z', 'foo', null ];
    traverse(obj);
    assert.strictEqual(obj[1], 'foo');
    assert.strictEqual(obj[2], null);
  });

  it('should not convert numbers by default', function() {
    var obj = { number: '4000' };
    traverse(obj);
    assert.strictEqual(obj.number, '4000');
  });

  it.skip('should convert numbers if strict mode is disabled', function() {
    var obj = { date: '2012' };
    traverse(obj, false);
    assert.strictEqual(obj.date.getFullYear(), 2011);
  });

  it('should iterate through arrays', function() {
    var arr = [{ date: '2013-09-04T00:57:26.434Z' }];
    traverse(arr);
    assert.strictEqual(toISOString(arr[0].date), '2013-09-04T00:57:26.434Z');
  });

  it('should iterate through nested arrays', function() {
    var arr = [{
      date: '2013-09-04T00:57:26.434Z',
      array: [{ date: '2013-09-04T00:57:26.434Z' }]
    }];
    traverse(arr);
    assert.strictEqual(toISOString(arr[0].date), '2013-09-04T00:57:26.434Z');
    assert.strictEqual(toISOString(arr[0].array[0].date), '2013-09-04T00:57:26.434Z');
  });

  it.skip('should propagate the "strict" parameter for both types of traversals', function() {
    var obj = { a: '2012', b: [{ c: '2012' }] };
    traverse(obj, false);
    assert.strictEqual(obj.a.getFullYear(), 2011);
    assert.strictEqual(obj.b[0].c.getFullYear(), 2011);
  });

  it('should do nothing for non-objects or non-arrays', function() {
    var date = new Date();
    var ret = traverse(date, false);
    assert.strictEqual(ret, date);
  });

  it('should not break for objects with a `length` property', function() {
    var obj = { date: '2013-09-04T00:57:26.434Z', length: 43 };
    traverse(obj);
    assert.strictEqual(toISOString(obj.date), '2013-09-04T00:57:26.434Z');
  });
});
