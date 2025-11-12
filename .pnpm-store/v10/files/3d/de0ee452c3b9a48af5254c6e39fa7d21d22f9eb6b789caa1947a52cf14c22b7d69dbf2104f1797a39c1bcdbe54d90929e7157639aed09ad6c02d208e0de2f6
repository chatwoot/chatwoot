import QUnit from 'qunit';
import Stream from '../src/stream';

QUnit.module('stream', {

  beforeEach() {
    this.stream = new Stream();
  },

  afterEach() {
    this.stream.dispose();
  }
});

QUnit.test('trigger calls listeners', function(assert) {
  const args = [];

  this.stream.on('test', function(data) {
    args.push(data);
  });

  this.stream.trigger('test', 1);
  this.stream.trigger('test', 2);

  assert.deepEqual(args, [1, 2]);
});

QUnit.test('callbacks can remove themselves', function(assert) {
  const args1 = [];
  const args2 = [];
  const args3 = [];
  const arg2Fn = (event) => {
    args2.push(event);
    this.stream.off('test', arg2Fn);
  };

  this.stream.on('test', (event) => {
    args1.push(event);
  });
  this.stream.on('test', arg2Fn);
  this.stream.on('test', (event) => {
    args3.push(event);
  });

  this.stream.trigger('test', 1);
  this.stream.trigger('test', 2);

  assert.deepEqual(args1, [1, 2], 'first callback ran all times');
  assert.deepEqual(args2, [1], 'second callback removed after first run');
  assert.deepEqual(args3, [1, 2], 'third callback ran all times');
});
