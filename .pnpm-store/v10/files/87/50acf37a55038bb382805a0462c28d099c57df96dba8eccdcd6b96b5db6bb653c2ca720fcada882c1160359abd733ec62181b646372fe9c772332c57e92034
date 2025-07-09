'use strict';

var
  QUnit = require('qunit'),
  probe = require('../lib/mp4/probe'),
  mp4Helpers = require('./utils/mp4-helpers'),
  box = mp4Helpers.box,

  // defined below
  moovWithoutMdhd,
  moovWithoutTkhd,
  moofWithTfdt,
  multiMoof,
  multiTraf,
  noTrunSamples,
  v1boxes;

QUnit.module('MP4 Probe');

QUnit.test('reads the timescale from an mdhd', function(assert) {
  // sampleMoov has a base timescale of 1000 with an override to 90kHz
  // in the mdhd
  assert.deepEqual(probe.timescale(new Uint8Array(mp4Helpers.sampleMoov)), {
    1: 90e3,
    2: 90e3
  }, 'found the timescale');
});

QUnit.test('reads tracks', function(assert) {
  var tracks = probe.tracks(new Uint8Array(mp4Helpers.sampleMoov));

  assert.equal(tracks.length, 2, 'two tracks');
  assert.equal(tracks[0].codec, 'avc1.4d400d', 'codec is correct');
  assert.equal(tracks[0].id, 1, 'id is correct');
  assert.equal(tracks[0].type, 'video', 'type is correct');
  assert.equal(tracks[0].timescale, 90e3, 'timescale is correct');

  assert.equal(tracks[1].codec, 'mp4a.40.2', 'codec is correct');
  assert.equal(tracks[1].id, 2, 'id is correct');
  assert.equal(tracks[1].type, 'audio', 'type is correct');
  assert.equal(tracks[1].timescale, 90e3, 'timescale is correct');
});

QUnit.test('returns null if the tkhd is missing', function(assert) {
  assert.equal(probe.timescale(new Uint8Array(moovWithoutTkhd)), null, 'indicated missing info');
});

QUnit.test('returns null if the mdhd is missing', function(assert) {
  assert.equal(probe.timescale(new Uint8Array(moovWithoutMdhd)), null, 'indicated missing info');
});

QUnit.test('startTime reads the base decode time from a tfdt', function(assert) {
  assert.equal(probe.startTime({
    4: 2
  }, new Uint8Array(moofWithTfdt)),
        0x01020304 / 2,
        'calculated base decode time');
});

QUnit.test('startTime returns the earliest base decode time', function(assert) {
  assert.equal(probe.startTime({
    4: 2,
    6: 1
  }, new Uint8Array(multiMoof)),
        0x01020304 / 2,
        'returned the earlier time');
});

QUnit.test('startTime parses 64-bit base decode times', function(assert) {
  assert.equal(probe.startTime({
    4: 3
  }, new Uint8Array(v1boxes)),
        0x0101020304 / 3,
        'parsed a long value');
});

QUnit.test('compositionStartTime calculates composition time using composition time' +
  'offset from first trun sample', function(assert) {
  assert.equal(probe.compositionStartTime({
    1: 6,
    4: 3
  }, new Uint8Array(moofWithTfdt)),
        (0x01020304 + 10) / 3,
        'calculated correct composition start time');
});

QUnit.test('compositionStartTime looks at only the first traf', function(assert) {
  assert.equal(probe.compositionStartTime({
    2: 6,
    4: 3
  }, new Uint8Array(multiTraf)),
        (0x01020304 + 10) / 3,
        'calculated composition start time from first traf');
});

QUnit.test('compositionStartTime uses default composition time offset of 0' +
  'if no trun samples present', function(assert) {
  assert.equal(probe.compositionStartTime({
    2: 6,
    4: 3
  }, new Uint8Array(noTrunSamples)),
        (0x01020304 + 0) / 3,
        'calculated correct composition start time using default offset');
});

QUnit.test('getTimescaleFromMediaHeader gets timescale for version 0 mdhd', function(assert) {
  var mdhd = new Uint8Array([
    0x00, // version 0
    0x00, 0x00, 0x00, // flags
    // version 0 has 32 bit creation_time, modification_time, and duration
    0x00, 0x00, 0x00, 0x02, // creation_time
    0x00, 0x00, 0x00, 0x03, // modification_time
    0x00, 0x00, 0x03, 0xe8, // timescale = 1000
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x02, 0x58, // 600 = 0x258 duration
    0x15, 0xc7 // 'eng' language
  ]);

  assert.equal(
    probe.getTimescaleFromMediaHeader(mdhd),
    1000,
    'got timescale from version 0 mdhd'
  );
});

QUnit.test('getTimescaleFromMediaHeader gets timescale for version 0 mdhd', function(assert) {
  var mdhd = new Uint8Array([
    0x01, // version 1
    0x00, 0x00, 0x00, // flags
    // version 1 has 64 bit creation_time, modification_time, and duration
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, // creation_time
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, // modification_time
    0x00, 0x00, 0x03, 0xe8, // timescale = 1000
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x58, // 600 = 0x258 duration
    0x15, 0xc7 // 'eng' language
  ]);

  assert.equal(
    probe.getTimescaleFromMediaHeader(mdhd),
    1000,
    'got timescale from version 1 mdhd'
  );
});

// ---------
// Test Data
// ---------

moovWithoutTkhd =
  box('moov',
      box('trak',
          box('mdia',
              box('mdhd',
                  0x00, // version 0
                  0x00, 0x00, 0x00, // flags
                  0x00, 0x00, 0x00, 0x02, // creation_time
                  0x00, 0x00, 0x00, 0x03, // modification_time
                  0x00, 0x00, 0x03, 0xe8, // timescale = 1000
                  0x00, 0x00, 0x00, 0x00,
                  0x00, 0x00, 0x02, 0x58, // 600 = 0x258 duration
                  0x15, 0xc7, // 'eng' language
                  0x00, 0x00),
              box('hdlr',
                  0x00, // version 1
                  0x00, 0x00, 0x00, // flags
                  0x00, 0x00, 0x00, 0x00, // pre_defined
                  mp4Helpers.typeBytes('vide'), // handler_type
                  0x00, 0x00, 0x00, 0x00, // reserved
                  0x00, 0x00, 0x00, 0x00, // reserved
                  0x00, 0x00, 0x00, 0x00, // reserved
                  mp4Helpers.typeBytes('one'), 0x00)))); // name

moovWithoutMdhd =
  box('moov',
      box('trak',
          box('tkhd',
              0x01, // version 1
              0x00, 0x00, 0x00, // flags
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x02, // creation_time
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x03, // modification_time
              0x00, 0x00, 0x00, 0x01, // track_ID
              0x00, 0x00, 0x00, 0x00, // reserved
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x02, 0x58, // 600 = 0x258 duration
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x00, // reserved
              0x00, 0x00, // layer
              0x00, 0x00, // alternate_group
              0x00, 0x00, // non-audio track volume
              0x00, 0x00, // reserved
              mp4Helpers.unityMatrix,
              0x01, 0x2c, 0x00, 0x00, // 300 in 16.16 fixed-point
              0x00, 0x96, 0x00, 0x00), // 150 in 16.16 fixed-point
          box('mdia',
              box('hdlr',
                  0x01, // version 1
                  0x00, 0x00, 0x00, // flags
                  0x00, 0x00, 0x00, 0x00, // pre_defined
                  mp4Helpers.typeBytes('vide'), // handler_type
                  0x00, 0x00, 0x00, 0x00, // reserved
                  0x00, 0x00, 0x00, 0x00, // reserved
                  0x00, 0x00, 0x00, 0x00, // reserved
                  mp4Helpers.typeBytes('one'), 0x00)))); // name

moofWithTfdt =
  box('moof',
      box('mfhd',
          0x00, // version
          0x00, 0x00, 0x00, // flags
          0x00, 0x00, 0x00, 0x04), // sequence_number
      box('traf',
          box('tfhd',
              0x00, // version
              0x00, 0x00, 0x3b, // flags
              0x00, 0x00, 0x00, 0x04, // track_ID = 4
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x01, // base_data_offset
              0x00, 0x00, 0x00, 0x02, // sample_description_index
              0x00, 0x00, 0x00, 0x03, // default_sample_duration,
              0x00, 0x00, 0x00, 0x04, // default_sample_size
              0x00, 0x00, 0x00, 0x05),
          box('tfdt',
              0x00, // version
              0x00, 0x00, 0x00, // flags
              0x01, 0x02, 0x03, 0x04), // baseMediaDecodeTime
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

noTrunSamples =
  box('moof',
      box('mfhd',
          0x00, // version
          0x00, 0x00, 0x00, // flags
          0x00, 0x00, 0x00, 0x04), // sequence_number
      box('traf',
          box('tfhd',
              0x00, // version
              0x00, 0x00, 0x3b, // flags
              0x00, 0x00, 0x00, 0x04, // track_ID = 4
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x01, // base_data_offset
              0x00, 0x00, 0x00, 0x02, // sample_description_index
              0x00, 0x00, 0x00, 0x03, // default_sample_duration,
              0x00, 0x00, 0x00, 0x04, // default_sample_size
              0x00, 0x00, 0x00, 0x05),
          box('tfdt',
              0x00, // version
              0x00, 0x00, 0x00, // flags
              0x01, 0x02, 0x03, 0x04), // baseMediaDecodeTime
          box('trun',
            0x00, // version
            0x00, 0x0f, 0x01, // flags: dataOffsetPresent, sampleDurationPresent,
                              // sampleSizePresent, sampleFlagsPresent,
                              // sampleCompositionTimeOffsetsPresent
            0x00, 0x00, 0x00, 0x00, // sample_count
            0x00, 0x00, 0x00, 0x00))); // data_offset, no first_sample_flags


multiTraf =
  box('moof',
      box('mfhd',
          0x00, // version
          0x00, 0x00, 0x00, // flags
          0x00, 0x00, 0x00, 0x04), // sequence_number
      box('traf',
          box('tfhd',
              0x00, // version
              0x00, 0x00, 0x3b, // flags
              0x00, 0x00, 0x00, 0x04, // track_ID = 4
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x01, // base_data_offset
              0x00, 0x00, 0x00, 0x02, // sample_description_index
              0x00, 0x00, 0x00, 0x03, // default_sample_duration,
              0x00, 0x00, 0x00, 0x04, // default_sample_size
              0x00, 0x00, 0x00, 0x05),
          box('tfdt',
              0x00, // version
              0x00, 0x00, 0x00, // flags
              0x01, 0x02, 0x03, 0x04), // baseMediaDecodeTime
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
            0x00, 0x00, 0x00, 0x14)), // signed sample_composition_time_offset = 20
        box('traf',
            box('tfhd',
                0x00, // version
                0x00, 0x00, 0x3b, // flags
                0x00, 0x00, 0x00, 0x02, // track_ID = 2
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x01, // base_data_offset
                0x00, 0x00, 0x00, 0x02, // sample_description_index
                0x00, 0x00, 0x00, 0x03, // default_sample_duration,
                0x00, 0x00, 0x00, 0x04, // default_sample_size
                0x00, 0x00, 0x00, 0x05),
            box('tfdt',
                0x00, // version
                0x00, 0x00, 0x00, // flags
                0x01, 0x02, 0x01, 0x02), // baseMediaDecodeTime
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
              0x00, 0x00, 0x00, 0x0b, // signed sample_composition_time_offset = 11
              // sample 2
              0x00, 0x00, 0x00, 0x0a, // sample_duration = 10
              0x00, 0x00, 0x00, 0x0a, // sample_size = 10
              0x00, 0x00, 0x00, 0x00, // sample_flags
              0x00, 0x00, 0x00, 0x05))); // signed sample_composition_time_offset = 5

multiMoof = moofWithTfdt
  .concat(box('moof',
              box('mfhd',
                  0x00, // version
                  0x00, 0x00, 0x00, // flags
                  0x00, 0x00, 0x00, 0x04), // sequence_number
              box('traf',
                  box('tfhd',
                      0x00, // version
                      0x00, 0x00, 0x3b, // flags
                      0x00, 0x00, 0x00, 0x06, // track_ID = 6
                      0x00, 0x00, 0x00, 0x00,
                      0x00, 0x00, 0x00, 0x01, // base_data_offset
                      0x00, 0x00, 0x00, 0x02, // sample_description_index
                      0x00, 0x00, 0x00, 0x03, // default_sample_duration,
                      0x00, 0x00, 0x00, 0x04, // default_sample_size
                      0x00, 0x00, 0x00, 0x05),
                  box('tfdt',
                      0x00, // version
                      0x00, 0x00, 0x00, // flags
                      0x01, 0x02, 0x03, 0x04), // baseMediaDecodeTime
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
                    0x00, 0x00, 0x00, 0x14, // signed sample_composition_time_offset = 20
                    // sample 2
                    0x00, 0x00, 0x00, 0x0a, // sample_duration = 10
                    0x00, 0x00, 0x00, 0x0a, // sample_size = 10
                    0x00, 0x00, 0x00, 0x00, // sample_flags
                    0x00, 0x00, 0x00, 0x0a)))); // signed sample_composition_time_offset = 10
v1boxes =
  box('moof',
      box('mfhd',
          0x01, // version
          0x00, 0x00, 0x00, // flags
          0x00, 0x00, 0x00, 0x04), // sequence_number
      box('traf',
          box('tfhd',
              0x01, // version
              0x00, 0x00, 0x3b, // flags
              0x00, 0x00, 0x00, 0x04, // track_ID = 4
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x01, // base_data_offset
              0x00, 0x00, 0x00, 0x02, // sample_description_index
              0x00, 0x00, 0x00, 0x03, // default_sample_duration,
              0x00, 0x00, 0x00, 0x04, // default_sample_size
              0x00, 0x00, 0x00, 0x05),
          box('tfdt',
              0x01, // version
              0x00, 0x00, 0x00, // flags
              0x00, 0x00, 0x00, 0x01,
              0x01, 0x02, 0x03, 0x04))); // baseMediaDecodeTime
