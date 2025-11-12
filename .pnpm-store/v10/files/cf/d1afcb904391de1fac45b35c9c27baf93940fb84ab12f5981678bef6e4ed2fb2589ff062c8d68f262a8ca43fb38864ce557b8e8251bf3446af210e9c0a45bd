'use strict';

var
  stream,
  Stream = require('../lib/utils/stream'),
  QUnit = require('qunit');

QUnit.module('Stream', {
  beforeEach: function() {
    stream = new Stream();
    stream.init();
  }
});

QUnit.test('trigger calls listeners', function(assert) {
  var args = [];

  stream.on('test', function(data) {
      args.push(data);
  });

  stream.trigger('test', 1);
  stream.trigger('test', 2);

  assert.deepEqual(args, [1, 2]);
});

QUnit.test('callbacks can remove themselves', function(assert) {
  var args1 = [], args2 = [], args3 = [];

  stream.on('test', function(event) {
      args1.push(event);
  });
  stream.on('test', function t(event) {
      args2.push(event);
      stream.off('test', t);
  });
  stream.on('test', function(event) {
      args3.push(event);
  });

  stream.trigger('test', 1);
  stream.trigger('test', 2);

  assert.deepEqual(args1, [1, 2], 'first callback ran all times');
  assert.deepEqual(args2, [1], 'second callback removed after first run');
  assert.deepEqual(args3, [1, 2], 'third callback ran all times');
});
