'use strict';

var segments = require('data-files!segments');

var probe = require('../lib/mp4/probe');
var CaptionParser = require('../lib/mp4').CaptionParser;
var captionParser;

var dashInit = segments['dash-608-captions-init.mp4']();
// This file includes 2 segments data to force a flush
// of the first caption. The second caption is at 200s
var dashSegment = segments['dash-608-captions-seg.m4s']();
var malformedSei = segments['malformed-sei.m4s']();
var malformedSeiInit = segments['malformed-sei-init.mp4']();

var mp4Helpers = require('./utils/mp4-helpers');
var box = mp4Helpers.box;
var seiNalUnitGenerator = require('./utils/sei-nal-unit-generator');
var makeMdatFromCaptionPackets = seiNalUnitGenerator.makeMdatFromCaptionPackets;
var characters = seiNalUnitGenerator.characters;

var packets0;
var version0Moof;
var version0Segment;

var packets1;
var version1Moof;
var version1Segment;

QUnit.module('MP4 Caption Parser', {
  beforeEach: function() {
    captionParser = new CaptionParser();
    captionParser.init();
  },

  afterEach: function() {
    captionParser.reset();
  }
});

QUnit.test('parse captions from real segment', function(assert) {
  var trackIds;
  var timescales;
  var cc;

  trackIds = probe.videoTrackIds(dashInit);
  timescales = probe.timescale(dashInit);

  cc = captionParser.parse(dashSegment, trackIds, timescales);

  assert.equal(cc.captions.length, 1);
  assert.equal(cc.captions[0].text, '00:00:00',
    'real segment caption has correct text');
  assert.equal(cc.captions[0].stream, 'CC1',
    'real segment caption has correct stream');
  assert.equal(cc.captions[0].startTime, 0,
    'real segment caption has correct startTime');
  assert.equal(cc.captions[0].endTime, 119,
    'real segment caption has correct endTime');
  assert.equal(cc.captionStreams.CC1, true,
    'real segment caption streams have correct settings');
});

QUnit.test('parse captions when init segment received late', function(assert) {
  var trackIds;
  var timescales;
  var cc;

  trackIds = probe.videoTrackIds(dashInit);
  timescales = probe.timescale(dashInit);

  cc = captionParser.parse(dashSegment, [], {});
  assert.ok(!cc, 'there should not be any parsed captions yet');

  cc = captionParser.parse(dashSegment, trackIds, timescales);
  assert.equal(cc.captions.length, 1);
});

QUnit.test('parseTrackId for version 0 and version 1 boxes', function(assert) {
  var v0Captions;
  var v1Captions;

  v0Captions = captionParser.parse(
    new Uint8Array(version0Segment), // segment
    [1], // trackIds
    { 1: 90000 }); // timescales);

  assert.equal(v0Captions.captions.length, 1, 'got 1 version0 caption');
  assert.equal(v0Captions.captions[0].text, 'test string #1',
    'got the expected version0 caption text');
  assert.equal(v0Captions.captions[0].stream, 'CC1',
    'returned the correct caption stream CC1');
  assert.equal(v0Captions.captions[0].startTime, 10 / 90000,
    'the start time for version0 caption is correct');
  assert.equal(v0Captions.captions[0].endTime, 10 / 90000,
    'the end time for version0 caption is correct');
  assert.equal(v0Captions.captionStreams.CC1, true,
    'stream is CC1');
  assert.ok(!v0Captions.captionStreams.CC4,
    'stream is not CC4');

  // Clear parsed captions
  captionParser.clearParsedCaptions();

  v1Captions = captionParser.parse(
    new Uint8Array(version1Segment),
    [2], // trackIds
    { 2: 90000 }); // timescales

  assert.equal(v1Captions.captions.length, 1, 'got version1 caption');
  assert.equal(v1Captions.captions[0].text, 'test string #2',
    'got the expected version1 caption text');
  assert.equal(v1Captions.captions[0].stream, 'CC4',
    'returned the correct caption stream CC4');
  assert.equal(v1Captions.captions[0].startTime, 30 / 90000,
    'the start time for version1 caption is correct');
  assert.equal(v1Captions.captions[0].endTime, 30 / 90000,
    'the end time for version1 caption is correct');
  assert.equal(v1Captions.captionStreams.CC4, true,
    'stream is CC4');
  assert.ok(!v1Captions.captionStreams.CC1,
    'stream is not CC1');
});

QUnit.test('returns log on invalid sei nal parse', function(assert) {
  var trackIds;
  var timescales;
  var result;
  var logs = [];

  trackIds = probe.videoTrackIds(malformedSeiInit);
  timescales = probe.timescale(malformedSeiInit);

  result = captionParser.parse(malformedSei, trackIds, timescales);

  assert.deepEqual(result.logs, [
    {level: 'warn', message: 'We\'ve encountered a nal unit without data at 189975 for trackId 1. See mux.js#223.'}
  ], 'logged invalid sei nal');
});

// ---------
// Test Data
// ---------

// "test string #1", channel 1, field 1
packets0 = [
  // Send another command so that the second EOC isn't ignored
  { ccData: 0x1420, type: 0 },
  // RCL, resume caption loading
  { ccData: 0x1420, type: 0 },
  // 'test string #1'
  { ccData: characters('te'), type: 0 },
  { ccData: characters('st'), type: 0 },
  { ccData: characters(' s'), type: 0 },
  // 'test string #1' continued
  { ccData: characters('tr'), type: 0 },
  { ccData: characters('in'), type: 0 },
  { ccData: characters('g '), type: 0 },
  { ccData: characters('#1'), type: 0 },
  // EOC, End of Caption. End display
  { ccData: 0x142f, type: 0 },
  // EOC, End of Caption. Finished transmitting, begin display
  { ccData: 0x142f, type: 0 },
  // Send another command so that the second EOC isn't ignored
  { ccData: 0x1420, type: 0 },
  // EOC, End of Caption. End display
  { ccData: 0x142f, type: 0 }
];

// "test string #2", channel 2, field 2
packets1 = [
  // Send another command so that the second EOC isn't ignored
  { ccData: 0x1d20, type: 1 },
  // RCL, resume caption loading
  { ccData: 0x1d20, type: 1 },
  // 'test string #2'
  { ccData: characters('te'), type: 1 },
  { ccData: characters('st'), type: 1 },
  { ccData: characters(' s'), type: 1 },
  // 'test string #2' continued
  { ccData: characters('tr'), type: 1 },
  { ccData: characters('in'), type: 1 },
  { ccData: characters('g '), type: 1 },
  { ccData: characters('#2'), type: 1 },
  // EOC, End of Caption. End display
  { ccData: 0x1d2f, type: 1 },
  // EOC, End of Caption. Finished transmitting, begin display
  { ccData: 0x1d2f, type: 1 },
  // Send another command so that the second EOC isn't ignored
  { ccData: 0x1d20, type: 1 },
  // EOC, End of Caption. End display
  { ccData: 0x1d2f, type: 1 }
];

/**
 * version 0:
 * Uses version 0 boxes, no first sample flags
 * sample size, flags, duration, composition time offset included.
**/
version0Moof =
  box('moof',
    box('traf',
      box('tfhd',
        0x00, // version
        0x00, 0x00, 0x00, // flags
        0x00, 0x00, 0x00, 0x01, // track_ID
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // base_data_offset
        0x00, 0x00, 0x00, 0x00, // sample_description_index
        0x00, 0x00, 0x00, 0x00, // default_sample_duration
        0x00, 0x00, 0x00, 0x00, // default_sample_size
        0x00, 0x00, 0x00, 0x00), // default_sample_flags
      box('tfdt',
        0x00, // version
        0x00, 0x00, 0x00, // flags
        0x00, 0x00, 0x00, 0x00), // baseMediaDecodeTime,
      box('trun',
        0x00, // version
        0x00, 0x0f, 0x01, // flags: dataOffsetPresent, sampleDurationPresent,
                          // sampleSizePresent, sampleFlagsPresent,
                          // sampleCompositionTimeOffsetsPresent
        0x00, 0x00, 0x00, 0x02, // sample_count
        0x00, 0x00, 0x00, 0x00, // data_offset, no first_sample_flags
        // sample 1
        0x00, 0x00, 0x00, 0x0a, // sample_duration = 10
        0x00, 0x00, 0x00, 0x0a, // sample_size = 10
        0x00, 0x00, 0x00, 0x00, // sample_flags
        0x00, 0x00, 0x00, 0x0a, // signed sample_composition_time_offset = 10
        // sample 2
        0x00, 0x00, 0x00, 0x0a, // sample_duration = 10
        0x00, 0x00, 0x00, 0x0a, // sample_size = 10
        0x00, 0x00, 0x00, 0x00, // sample_flags
        0x00, 0x00, 0x00, 0x14))); // signed sample_composition_time_offset = 20

version0Segment = version0Moof.concat(makeMdatFromCaptionPackets(packets0));

/**
 * version 1:
 * Uses version 1 boxes, has first sample flags,
 * other samples include flags and composition time offset only.
**/
version1Moof =
  box('moof',
    box('traf',
      box('tfhd',
        0x01, // version
        0x00, 0x00, 0x18, // flags
        0x00, 0x00, 0x00, 0x02, // track_ID
        // no base_data_offset, sample_description_index
        0x00, 0x00, 0x00, 0x0a, // default_sample_duration = 10
        0x00, 0x00, 0x00, 0x0a), // default_sample_size = 10
      box('tfdt',
        0x01, // version
        0x00, 0x00, 0x00, // flags
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x14), // baseMediaDecodeTime = 20,
      box('trun',
        0x01, // version
        0x00, 0x0c, 0x05, // flags: dataOffsetPresent, sampleFlagsPresent,
                          // firstSampleFlagsPresent,
                          // sampleCompositionTimeOffsetsPresent
        0x00, 0x00, 0x00, 0x02, // sample_count
        0x00, 0x00, 0x00, 0x00, // data_offset, has first_sample_flags
        // sample 1
        0x00, 0x00, 0x00, 0x00, // sample_flags
        0x00, 0x00, 0x00, 0x0a, // signed sample_composition_time_offset = 10
        // sample 2
        0x00, 0x00, 0x00, 0x00, // sample_flags
        0x00, 0x00, 0x00, 0x14))); // signed sample_composition_time_offset = 20

version1Segment = version1Moof.concat(makeMdatFromCaptionPackets(packets1));
