'use strict';

var segments = require('data-files!segments');

var
  QUnit = require('qunit'),
  utils = require('../lib/aac/utils.js'),
  testSegment = segments['test-aac-segment.aac']();

var id3TagOffset = 0;
var audioFrameOffset = 73;


QUnit.module('AAC Utils');

QUnit.test('correctly determines aac data', function(assert) {
  assert.ok(utils.isLikelyAacData(testSegment), 'test segment is aac');


  var id3Offset = utils.parseId3TagSize(testSegment, 0);
  var id3 = Array.prototype.slice.call(testSegment, 0, id3Offset);
  var segmentOnly = testSegment.subarray(id3Offset);
  var multipleId3 = new Uint8Array([]
    .concat(id3)
    .concat(id3)
    .concat(id3)
    .concat(id3)
    .concat(Array.prototype.slice.call(segmentOnly))
  );

  assert.ok(utils.isLikelyAacData(segmentOnly), 'test segment is aac without id3');
  assert.notOk(utils.isLikelyAacData(testSegment.subarray(id3Offset + 25)), 'non aac data not recognized');
  assert.notOk(utils.isLikelyAacData(testSegment.subarray(0, 5)), 'not enough aac data is not recognized');
  assert.ok(utils.isLikelyAacData(multipleId3), 'test segment with multilpe id3');
});


QUnit.test('correctly parses aac packet type', function(assert) {
  assert.equal(utils.parseType(testSegment, id3TagOffset), 'timed-metadata',
    'parsed timed-metadata type');
  assert.equal(utils.parseType(testSegment, 1), null,
    'parsed unknown type');
  assert.equal(utils.parseType(testSegment, audioFrameOffset), 'audio',
    'parsed audio type');
});

QUnit.test('correctly parses ID3 tag size', function(assert) {
  assert.equal(utils.parseId3TagSize(testSegment, id3TagOffset), 73,
    'correct id3 tag size');
});

QUnit.test('correctly parses timestamp from ID3 metadata', function(assert) {
  var frameSize = utils.parseId3TagSize(testSegment, id3TagOffset);
  var frame = testSegment.subarray(id3TagOffset, id3TagOffset + frameSize);

  assert.equal(utils.parseAacTimestamp(frame), 895690, 'correct aac timestamp');
});

QUnit.test('correctly parses adts frame size', function(assert) {
  assert.equal(utils.parseAdtsSize(testSegment, audioFrameOffset), 13,
    'correct adts frame size');
});

QUnit.test('correctly parses packet sample rate', function(assert) {
  var frameSize = utils.parseAdtsSize(testSegment, audioFrameOffset);
  var frame = testSegment.subarray(audioFrameOffset, audioFrameOffset + frameSize);

  assert.equal(utils.parseSampleRate(frame), 44100, 'correct sample rate');
});

QUnit.test('parses correct ID3 tag size', function(assert) {
  var packetStream = new Uint8Array(10);

  packetStream[9] = 63;

  assert.equal(utils.parseId3TagSize(packetStream, 0),
              73,
              'correctly parsed a header without a footer');
});

QUnit.test('parses correct ADTS Frame size', function(assert) {
  var packetStream = new Uint8Array(6);

  packetStream[3] = 128;
  packetStream[4] = 29;
  packetStream[5] = 255;

  assert.equal(utils.parseAdtsSize(packetStream, 0), 239, 'correctly parsed framesize');
});
