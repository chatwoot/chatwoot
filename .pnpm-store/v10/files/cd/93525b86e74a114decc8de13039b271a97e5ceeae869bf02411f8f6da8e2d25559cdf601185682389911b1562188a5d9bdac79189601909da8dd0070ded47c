import QUnit from 'qunit';
import { simpleTypeFromSourceType } from '../src/media-types';

QUnit.module('simpleTypeFromSourceType');

QUnit.test('simpleTypeFromSourceType converts HLS mime types to hls', function(assert) {
  assert.equal(
    simpleTypeFromSourceType('aPplicatiOn/x-MPegUrl'),
    'hls',
    'supports application/x-mpegurl'
  );
  assert.equal(
    simpleTypeFromSourceType('aPplicatiOn/VnD.aPPle.MpEgUrL'),
    'hls',
    'supports application/vnd.apple.mpegurl'
  );
});

QUnit.test('simpleTypeFromSourceType converts DASH mime type to dash', function(assert) {
  assert.equal(
    simpleTypeFromSourceType('aPplication/dAsh+xMl'),
    'dash',
    'supports application/dash+xml'
  );
});

QUnit.test(
  'simpleTypeFromSourceType does not convert non HLS/DASH mime types',
  function(assert) {
    assert.notOk(simpleTypeFromSourceType('video/mp4'), 'does not support video/mp4');
    assert.notOk(simpleTypeFromSourceType('video/x-flv'), 'does not support video/x-flv');
  }
);

QUnit.test('simpleTypeFromSourceType converts VHS media type to vhs-json', function(assert) {
  assert.equal(
    simpleTypeFromSourceType('application/vnd.videojs.vhs+json'),
    'vhs-json',
    'supports application/vnd.videojs.vhs+json'
  );
});
