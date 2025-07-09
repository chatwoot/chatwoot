'use strict';

var
  QUnit = require('qunit'),
  clock = require('../lib/utils/clock');

QUnit.module('Clock Utils');

QUnit.test('converts from seconds to video timestamps', function(assert) {
  assert.equal(clock.secondsToVideoTs(0), 0, 'converts seconds to video timestamp');
  assert.equal(clock.secondsToVideoTs(1), 90000, 'converts seconds to video timestamp');
  assert.equal(clock.secondsToVideoTs(10), 900000, 'converts seconds to video timestamp');
  assert.equal(clock.secondsToVideoTs(-1), -90000, 'converts seconds to video timestamp');
  assert.equal(clock.secondsToVideoTs(3), 270000, 'converts seconds to video timestamp');
  assert.equal(clock.secondsToVideoTs(0.1), 9000, 'converts seconds to video timestamp');
});

QUnit.test('converts from seconds to audio timestamps', function(assert) {
  assert.equal(clock.secondsToAudioTs(0, 90000),
              0,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(1, 90000),
              90000,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(-1, 90000),
              -90000,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(3, 90000),
              270000,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(0, 44100),
              0,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(1, 44100),
              44100,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(3, 44100),
              132300,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(-1, 44100),
              -44100,
              'converts seconds to audio timestamp');
  assert.equal(clock.secondsToAudioTs(0.1, 44100),
              4410,
              'converts seconds to audio timestamp');
});

QUnit.test('converts from video timestamp to seconds', function(assert) {
  assert.equal(clock.videoTsToSeconds(0), 0, 'converts video timestamp to seconds');
  assert.equal(clock.videoTsToSeconds(90000), 1, 'converts video timestamp to seconds');
  assert.equal(clock.videoTsToSeconds(900000), 10, 'converts video timestamp to seconds');
  assert.equal(clock.videoTsToSeconds(-90000), -1, 'converts video timestamp to seconds');
  assert.equal(clock.videoTsToSeconds(270000), 3, 'converts video timestamp to seconds');
  assert.equal(clock.videoTsToSeconds(9000), 0.1, 'converts video timestamp to seconds');
});

QUnit.test('converts from audio timestamp to seconds', function(assert) {
  assert.equal(clock.audioTsToSeconds(0, 90000),
              0,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(90000, 90000),
              1,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(-90000, 90000),
              -1,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(270000, 90000),
              3,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(0, 44100),
              0,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(44100, 44100),
              1,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(132300, 44100),
              3,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(-44100, 44100),
              -1,
              'converts seconds to audio timestamp');
  assert.equal(clock.audioTsToSeconds(4410, 44100),
              0.1,
              'converts seconds to audio timestamp');
});

QUnit.test('converts from audio timestamp to video timestamp', function(assert) {
  assert.equal(clock.audioTsToVideoTs(0, 90000),
              0,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(90000, 90000),
              90000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(900000, 90000),
              900000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(-90000, 90000),
              -90000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(270000, 90000),
              270000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(9000, 90000),
              9000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(0, 44100),
              0,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(44100, 44100),
              90000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(441000, 44100),
              900000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(-44100, 44100),
              -90000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(132300, 44100),
              270000,
              'converts audio timestamp to video timestamp');
  assert.equal(clock.audioTsToVideoTs(4410, 44100),
              9000,
              'converts audio timestamp to video timestamp');
});

QUnit.test('converts from video timestamp to audio timestamp', function(assert) {
  assert.equal(clock.videoTsToAudioTs(0, 90000),
              0,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(90000, 90000),
              90000,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(900000, 90000),
              900000,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(-90000, 90000),
              -90000,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(270000, 90000),
              270000,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(9000, 90000),
              9000,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(0, 44100),
              0,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(90000, 44100),
              44100,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(900000, 44100),
              441000,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(-90000, 44100),
              -44100,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(270000, 44100),
              132300,
              'converts video timestamp to audio timestamp');
  assert.equal(clock.videoTsToAudioTs(9000, 44100),
              4410,
              'converts video timestamp to audio timestamp');
});

QUnit.test('converts from metadata timestamp to seconds', function(assert) {
  assert.equal(clock.metadataTsToSeconds(90000, 90000, false),
              0,
              'converts metadata timestamp to seconds and adjusts by timelineStartPts');

  assert.equal(clock.metadataTsToSeconds(270000, 90000, false),
              2,
              'converts metadata timestamp to seconds and adjusts by timelineStartPts');

  assert.equal(clock.metadataTsToSeconds(90000, 90000, true),
              1,
              'converts metadata timestamp to seconds while keeping original timestamps');

  assert.equal(clock.metadataTsToSeconds(180000, 0, true),
              2,
              'converts metadata timestamp to seconds while keeping original timestamps');
});
