import {LineStream} from '../src';
import QUnit from 'qunit';

QUnit.module('LineStream', {
  beforeEach() {
    this.lineStream = new LineStream();
  }
});
QUnit.test('empty inputs produce no tokens', function(assert) {
  let data = false;

  this.lineStream.on('data', function() {
    data = true;
  });
  this.lineStream.push('');
  assert.ok(!data, 'no tokens were produced');
});
QUnit.test('splits on newlines', function(assert) {
  const lines = [];

  this.lineStream.on('data', function(line) {
    lines.push(line);
  });
  this.lineStream.push('#EXTM3U\nmovie.ts\n');

  assert.strictEqual(2, lines.length, 'two lines are ready');
  assert.strictEqual('#EXTM3U', lines.shift(), 'the first line is the first token');
  assert.strictEqual('movie.ts', lines.shift(), 'the second line is the second token');
});
QUnit.test('empty lines become empty strings', function(assert) {
  const lines = [];

  this.lineStream.on('data', function(line) {
    lines.push(line);
  });
  this.lineStream.push('\n\n');

  assert.strictEqual(2, lines.length, 'two lines are ready');
  assert.strictEqual('', lines.shift(), 'the first line is empty');
  assert.strictEqual('', lines.shift(), 'the second line is empty');
});
QUnit.test('handles lines broken across appends', function(assert) {
  const lines = [];

  this.lineStream.on('data', function(line) {
    lines.push(line);
  });
  this.lineStream.push('#EXTM');
  assert.strictEqual(0, lines.length, 'no lines are ready');

  this.lineStream.push('3U\nmovie.ts\n');
  assert.strictEqual(2, lines.length, 'two lines are ready');
  assert.strictEqual('#EXTM3U', lines.shift(), 'the first line is the first token');
  assert.strictEqual('movie.ts', lines.shift(), 'the second line is the second token');
});
QUnit.test('stops sending events after deregistering', function(assert) {
  const temporaryLines = [];
  const temporary = function(line) {
    temporaryLines.push(line);
  };
  const permanentLines = [];
  const permanent = function(line) {
    permanentLines.push(line);
  };

  this.lineStream.on('data', temporary);
  this.lineStream.on('data', permanent);
  this.lineStream.push('line one\n');
  assert.strictEqual(
    temporaryLines.length,
    permanentLines.length,
    'both callbacks receive the event'
  );

  assert.ok(this.lineStream.off('data', temporary), 'a listener was removed');
  this.lineStream.push('line two\n');
  assert.strictEqual(1, temporaryLines.length, 'no new events are received');
  assert.strictEqual(2, permanentLines.length, 'new events are still received');
});

