import QUnit from 'qunit';
import { segmentRange } from '../../src/segment/durationTimeParser.js';

QUnit.module('segmentRange');

QUnit.test('static range uses periodDuration if available', function(assert) {
  assert.deepEqual(
    segmentRange.static({
      periodDuration: 10,
      sourceDuration: 20,
      duration: 2,
      timescale: 1
    }),
    { start: 0, end: 5 },
    'uses periodDuration if available'
  );
});

QUnit.test('static range uses sourceDuration if available', function(assert) {
  assert.deepEqual(
    segmentRange.static({
      sourceDuration: 20,
      duration: 2,
      timescale: 1
    }),
    { start: 0, end: 10 },
    'uses periodDuration if available'
  );
});
