'use strict';
/*
  ======== A Handy Little QUnit Reference ========
  http://api.qunitjs.com/

  Test methods:
  module(name, {[setup][ ,teardown]})
  QUnit.test(name, callback)
  expect(numberOfAssertions)
  stop(increment)
  start(decrement)
  Test assertions:
  assert.ok(value, [message])
  assert.equal(actual, expected, [message])
  notEqual(actual, expected, [message])
  assert.deepEqual(actual, expected, [message])
  notDeepEqual(actual, expected, [message])
  assert.strictEqual(actual, expected, [message])
  notStrictEqual(actual, expected, [message])
  throws(block, [expected], [message])
*/
var
  mp4 = require('../lib/mp4'),
  mp4Helpers = require('./utils/mp4-helpers'),
  QUnit = require('qunit'),
  window = require('global/window'),
  typeBytes = mp4Helpers.typeBytes,
  box = mp4Helpers.box,
  unityMatrix = mp4Helpers.unityMatrix,
  BigInt = window.BigInt || Number,

  mvhd0 = box('mvhd',
             0x00, // version 0
             0x00, 0x00, 0x00, // flags
             0x00, 0x00, 0x00, 0x01, // creation_time
             0x00, 0x00, 0x00, 0x02, // modification_time
             0x00, 0x00, 0x00, 0x3c, // timescale
             0x00, 0x00, 0x02, 0x58, // 600 = 0x258 duration
             0x00, 0x01, 0x00, 0x00, // 1.0 rate
             0x01, 0x00, // 1.0 volume
             0x00, 0x00, // reserved
             0x00, 0x00, 0x00, 0x00, // reserved
             0x00, 0x00, 0x00, 0x00, // reserved
             unityMatrix,
             0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00,
             0x00, 0x00, 0x00, 0x00, // pre_defined
             0x00, 0x00, 0x00, 0x02),

  tkhd0 = box('tkhd',
              0x00, // version 0
              0x00, 0x00, 0x00, // flags
              0x00, 0x00, 0x00, 0x02, // creation_time
              0x00, 0x00, 0x00, 0x03, // modification_time
              0x00, 0x00, 0x00, 0x01, // track_ID
              0x00, 0x00, 0x00, 0x00, // reserved
              0x00, 0x00, 0x02, 0x58, // 600 = 0x258 duration
              0x00, 0x00, 0x00, 0x00,
              0x00, 0x00, 0x00, 0x00, // reserved
              0x00, 0x00, // layer
              0x00, 0x00, // alternate_group
              0x00, 0x00, // non-audio track volume
              0x00, 0x00, // reserved
              unityMatrix,
              0x01, 0x2c, 0x80, 0x00, // 300.5 in 16.16 fixed point
              0x00, 0x96, 0x80, 0x00), // 150.5 in 16.16 fixed point
  mdhd0 = box('mdhd',
              0x00, // version 0
              0x00, 0x00, 0x00, // flags
              0x00, 0x00, 0x00, 0x02, // creation_time
              0x00, 0x00, 0x00, 0x03, // modification_time
              0x00, 0x00, 0x00, 0x3c, // timescale
              0x00, 0x00, 0x02, 0x58, // 600 = 0x258 duration
              0x15, 0xc7, // 'eng' language
              0x00, 0x00);

QUnit.module('MP4 Inspector');

QUnit.test('produces an empty array for empty input', function(assert) {
  assert.strictEqual(mp4.tools.inspect(new Uint8Array([])).length, 0, 'returned an empty array');
});

QUnit.test('can parse a Box', function(assert) {
  var box = new Uint8Array([
    0x00, 0x00, 0x00, 0x00, // size 0
    0x00, 0x00, 0x00, 0x00 // boxtype 0
  ]);
  assert.deepEqual(mp4.tools.inspect(box), [{
    type: '\u0000\u0000\u0000\u0000',
    size: 0,
    data: box.subarray(box.byteLength)
  }], 'parsed a Box');
});

QUnit.test('can parse an ftyp', function(assert) {
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(box('ftyp',
    0x61, 0x76, 0x63, 0x31, // major brand
    0x00, 0x00, 0x00, 0x02, // minor version
    98, 111, 111, 112, // compatible brands
    98, 101, 101, 112 // compatible brands
  ))), [{
    type: 'ftyp',
    size: 4 * 6,
    majorBrand: 'avc1',
    minorVersion: 2,
    compatibleBrands: ['boop', 'beep']
  }], 'parsed an ftyp');
});

QUnit.test('can parse a pdin', function(assert) {
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(box('pdin',
    0x01, // version 1
    0x01, 0x02, 0x03, // flags
    0x00, 0x00, 0x04, 0x00, // 1024 = 0x400 bytes/second rate
    0x00, 0x00, 0x00, 0x01 // initial delay
  ))), [{
    size: 20,
    type: 'pdin',
    version: 1,
    flags: new Uint8Array([1, 2, 3]),
    rate: 1024,
    initialDelay: 1
  }], 'parsed a pdin');
});

QUnit.test('can parse an mdat', function(assert) {
  var mdat = new Uint8Array(box('mdat',
      0, 0, 0, 4, // length
      0x01, 0x02, 0x03, 0x04 // data
    ));
  assert.deepEqual(mp4.tools.inspect(mdat), [{
    size: 16,
    type: 'mdat',
    nals: [
      'slice_layer_without_partitioning_rbsp'
    ],
    byteLength: 8
  }], 'parsed an mdat');
});

QUnit.test('can parse a free or skip', function(assert) {
  var
    free = new Uint8Array(box('free',
                              0x01, 0x02, 0x03, 0x04)), // data
    skip = new Uint8Array(box('skip',
                              0x01, 0x02, 0x03, 0x04)); // data

  assert.deepEqual(mp4.tools.inspect(free), [{
      size: 12,
      type: 'free',
      data: free.subarray(free.byteLength - 4)
    }], 'parsed a free');
  assert.deepEqual(mp4.tools.inspect(skip), [{
      size: 12,
      type: 'skip',
      data: skip.subarray(skip.byteLength - 4)
    }], 'parsed a skip');
});

QUnit.test('can parse a version 0 mvhd', function(assert) {
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(mvhd0)), [{
    type: 'mvhd',
    version: 0,
    flags: new Uint8Array([0, 0, 0]),
    creationTime: new Date(1000 - 2082844800000),
    modificationTime: new Date(2000 - 2082844800000),
    timescale: 60,
    duration: 600,
    rate: 1,
    volume: 1,
    matrix: new Uint32Array(unityMatrix),
    size: 108,
    nextTrackId: 2
  }]);
});

QUnit.test('can parse a version 0 tkhd', function(assert) {
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(tkhd0)), [{
    type: 'tkhd',
    version: 0,
    flags: new Uint8Array([0, 0, 0]),
    creationTime: new Date(2000 - 2082844800000),
    modificationTime: new Date(3000 - 2082844800000),
    size: 92,
    trackId: 1,
    duration: 600,
    layer: 0,
    alternateGroup: 0,
    volume: 0,
    matrix: new Uint32Array(unityMatrix),
    width: 300.5,
    height: 150.5
  }]);
});

QUnit.test('can parse a version 0 mdhd', function(assert) {
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(mdhd0)), [{
    type: 'mdhd',
    version: 0,
    flags: new Uint8Array([0, 0, 0]),
    creationTime: new Date(2000 - 2082844800000),
    modificationTime: new Date(3000 - 2082844800000),
    size: 32,
    timescale: 60,
    duration: 600,
    language: 'eng'
  }]);
});

QUnit.test('can parse a moov', function(assert) {
  var data = mp4Helpers.sampleMoov;

  QUnit.dump.maxDepth = 100;
  var result = QUnit.dump.parse(mp4.tools.inspect(new Uint8Array(data)));
  var expected = QUnit.dump.parse([{
    type: 'moov',
    size: 1129,
    boxes: [{
      type: 'mvhd',
      version: 1,
      flags: new Uint8Array([0, 0, 0]),
      creationTime: new Date(1000 - 2082844800000),
      modificationTime: new Date(2000 - 2082844800000),
      timescale: 1000,
      duration: 600,
      rate: 1,
      size: 120,
      volume: 1,
      matrix: new Uint32Array(unityMatrix),
      nextTrackId: 2
    }, {
      type: 'trak',
      size: 519,
      boxes: [{
        type: 'tkhd',
        flags: new Uint8Array([0, 0, 0]),
        version: 1,
        creationTime: new Date(2000 - 2082844800000),
        modificationTime: new Date(3000 - 2082844800000),
        size: 104,
        trackId: 1,
        duration: 600,
        layer: 0,
        alternateGroup: 0,
        volume: 0,
        matrix: new Uint32Array(unityMatrix),
        width: 300,
        height: 150
      }, {
        type: 'edts',
        size: 36,
        boxes: [{
          type: 'elst',
          size: 28,
          version: 0,
          flags: new Uint8Array([0, 0, 0]),
          edits: [{
            segmentDuration: 0,
            mediaTime: 1024,
            mediaRate: 1.5
          }]
        }]
      }, {
        type: 'mdia',
        size: 371,
        boxes: [{
          type: 'mdhd',
          version: 1,
          flags: new Uint8Array([0, 0, 0]),
          creationTime: new Date(2000 - 2082844800000),
          modificationTime: new Date(3000 - 2082844800000),
          timescale: 90e3,
          duration: 600,
          language: 'eng',
          size: 44
        }, {
          type: 'hdlr',
          version: 1,
          flags: new Uint8Array([0, 0, 0]),
          handlerType: 'vide',
          name: 'one',
          size: 37
        }, {
          type: 'minf',
          size: 282,
          boxes: [{
            type: 'dinf',
            size: 36,
            boxes: [{
              type: 'dref',
              size: 28,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              dataReferences: [{
                type: 'url ',
                size: 12,
                version: 0,
                flags: new Uint8Array([0, 0, 1])
              }]
            }]
          }, {
            type: 'stbl',
            size: 238,
            boxes: [{
              type: 'stsd',
              size: 114,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              sampleDescriptions: [{
                config: [
                  {
                    avcLevelIndication: 13,
                    avcProfileIndication: 77,
                    configurationVersion: 0,
                    lengthSizeMinusOne: 0,
                    pps: [],
                    profileCompatibility: 64,
                    size: 0,
                    sps: [],
                    type: 'avcC'
                  }
                ],
                dataReferenceIndex: 0,
                depth: 0,
                frameCount: 0,
                height: 0,
                horizresolution: 0,
                size: 98,
                type: 'avc1',
                vertresolution: 0,
                width: 0
              }
              ]
            }, {
              type: 'stts',
              size: 24,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              timeToSamples: [{
                sampleCount: 1,
                sampleDelta: 1
              }]
            }, {
              type: 'stsc',
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              sampleToChunks: [{
                firstChunk: 2,
                samplesPerChunk: 3,
                sampleDescriptionIndex: 1
              }],
              size: 28
            }, {
              type: 'stco',
              size: 20,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              chunkOffsets: [1]
            }, {
              type: 'stss',
              size: 20,
              version: 0,
              flags: new Uint8Array([0, 0, 0]),
              syncSamples: [1]
            }, {
              type: 'ctts',
              size: 24,
              version: 0,
              flags: new Uint8Array([0, 0, 0]),
              compositionOffsets: [
                { sampleCount: 1, sampleOffset: 1 }
              ]
            }]
          }]
        }]
      }]
    }, {
      type: 'trak',
      size: 482,
      boxes: [{
        type: 'tkhd',
        flags: new Uint8Array([0, 0, 0]),
        version: 1,
        creationTime: new Date(2000 - 2082844800000),
        modificationTime: new Date(3000 - 2082844800000),
        size: 104,
        trackId: 2,
        duration: 600,
        layer: 0,
        alternateGroup: 0,
        volume: 0,
        matrix: new Uint32Array(unityMatrix),
        width: 300,
        height: 150
      }, {
        type: 'edts',
        size: 44,
        boxes: [{
          type: 'elst',
          size: 36,
          version: 1,
          flags: new Uint8Array([0, 0, 0]),
          edits: [{
            segmentDuration: 0,
            mediaTime: BigInt('0x1000000000000000'),
            mediaRate: 1.5
          }]
        }]
      }, {
        type: 'mdia',
        size: 326,
        boxes: [{
          type: 'mdhd',
          version: 1,
          flags: new Uint8Array([0, 0, 0]),
          creationTime: new Date(2000 - 2082844800000),
          modificationTime: new Date(3000 - 2082844800000),
          timescale: 90e3,
          duration: 600,
          language: 'eng',
          size: 44
        }, {
          type: 'hdlr',
          version: 1,
          flags: new Uint8Array([0, 0, 0]),
          handlerType: 'soun',
          name: 'one',
          size: 37
        }, {
          type: 'minf',
          size: 237,
          boxes: [{
            type: 'dinf',
            size: 36,
            boxes: [{
              type: 'dref',
              size: 28,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              dataReferences: [{
                type: 'url ',
                size: 12,
                version: 0,
                flags: new Uint8Array([0, 0, 1])
              }]
            }]
          }, {
            type: 'stbl',
            size: 193,
            boxes: [{
              type: 'stsd',
              size: 89,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              sampleDescriptions: [{
                channelcount: 0,
                dataReferenceIndex: 0,
                samplerate: 0,
                samplesize: 0,
                size: 73,
                streamDescriptor: {
                  decoderConfig: {
                    avgBitrate: 0,
                    bufferSize: 0,
                    decoderConfigDescriptor: {
                      audioObjectType: 0,
                      channelConfiguration: 0,
                      length: 0,
                      samplingFrequencyIndex: 0,
                      tag: 0
                    },
                    maxBitrate: 0,
                    objectProfileIndication: 64,
                    streamType: 2
                  },
                  esId: 0,
                  flags: {
                    0: 0,
                    1: 0,
                    2: 0
                  },
                  size: 0,
                  streamPriority: 0,
                  type: 'esds',
                  version: 0
                },
                type: 'mp4a'
              }]
            }, {
              type: 'stts',
              size: 24,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              timeToSamples: [{
                sampleCount: 1,
                sampleDelta: 1
              }]
            }, {
              type: 'stsc',
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              sampleToChunks: [{
                firstChunk: 2,
                samplesPerChunk: 3,
                sampleDescriptionIndex: 1
              }],
              size: 28
            }, {
              type: 'ctts',
              size: 24,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              compositionOffsets: [
                { sampleCount: 1, sampleOffset: -1 }
              ]
            }, {
              type: 'stco',
              size: 20,
              version: 1,
              flags: new Uint8Array([0, 0, 0]),
              chunkOffsets: [1]
            }]
          }]
        }]
      }]
    }]
  }]);
  assert.equal(result, expected, 'can parse moov');
});

QUnit.test('can parse an mvex', function(assert) {
  var mvex =
    box('mvex',
        box('trex',
            0x00, // version
            0x00, 0x00, 0x00, // flags
            0x00, 0x00, 0x00, 0x01, // track_ID
            0x00, 0x00, 0x00, 0x01, // default_sample_description_index
            0x00, 0x00, 0x00, 0x02, // default_sample_duration
            0x00, 0x00, 0x00, 0x03, // default_sample_size
            0x00, 0x61, 0x00, 0x01)); // default_sample_flags
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(mvex)), [{
    type: 'mvex',
    size: 40,
    boxes: [{
      type: 'trex',
      size: 32,
      version: 0,
      flags: new Uint8Array([0, 0, 0]),
      trackId: 1,
      defaultSampleDescriptionIndex: 1,
      defaultSampleDuration: 2,
      defaultSampleSize: 3,
      sampleDependsOn: 0,
      sampleIsDependedOn: 1,
      sampleHasRedundancy: 2,
      samplePaddingValue: 0,
      sampleIsDifferenceSample: true,
      sampleDegradationPriority: 1
    }]
  }], 'parsed an mvex');
});

QUnit.test('can parse a video stsd', function(assert) {
  var data = box('stsd',
                 0x00, // version 0
                 0x00, 0x00, 0x00, // flags
                 0x00, 0x00, 0x00, 0x01,
                 box('avc1',
                     0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, // reserved
                     0x00, 0x01, // data_reference_index
                     0x00, 0x00, // pre_defined
                     0x00, 0x00, // reserved
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, // pre_defined
                     0x01, 0x2c, // width = 300
                     0x00, 0x96, // height = 150
                     0x00, 0x48, 0x00, 0x00, // horizresolution
                     0x00, 0x48, 0x00, 0x00, // vertresolution
                     0x00, 0x00, 0x00, 0x00, // reserved
                     0x00, 0x01, // frame_count
                     0x04,
                     typeBytes('avc1'),
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, // compressorname
                     0x00, 0x18, // depth = 24
                     0x11, 0x11, // pre_defined
                     box('avcC',
                        0x01, // configurationVersion
                        0x00, // AVCProfileIndication??
                        0x00, // profile_compatibility
                        0x00, // AVCLevelIndication
                        0x1c, // lengthSizeMinusOne
                        0xe1, // numOfSequenceParameterSets
                        0x00, 0x01, // sequenceParameterSetLength
                        0x00, // "SPS"
                        0x02, // numOfPictureParameterSets
                        0x00, 0x02, // pictureParameterSetLength
                        0x01, 0x02, // "PPS"
                        0x00, 0x01, // pictureParameterSetLength
                        0xff), // "PPS"
                     box('btrt',
                        0x00, 0x00, 0x00, 0x00, // bufferSizeDB
                        0x00, 0x00, 0x00, 0x01, // maxBitrate
                        0x00, 0x00, 0x00, 0x01), // avgBitrate
                     box('pasp',
                        0x00, 0x00, 0x00, 0x01, // hSpacing
                        0x00, 0x00, 0x00, 0x01))); // vSpacing
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)), [{
    type: 'stsd',
    size: 163,
    version: 0,
    flags: new Uint8Array([0, 0, 0]),
    sampleDescriptions: [{
      type: 'avc1',
      size: 147,
      dataReferenceIndex: 1,
      width: 300,
      height: 150,
      horizresolution: 72,
      vertresolution: 72,
      frameCount: 1,
      depth: 24,
      config: [{
        type: 'avcC',
        size: 25,
        configurationVersion: 1,
        avcProfileIndication: 0,
        profileCompatibility: 0,
        avcLevelIndication: 0,
        lengthSizeMinusOne: 0,
        sps: [new Uint8Array(1)],
        pps: [new Uint8Array([1, 2]),
              new Uint8Array([0xff])]
      }, {
        type: 'btrt',
        size: 20,
        bufferSizeDB: 0,
        maxBitrate: 1,
        avgBitrate: 1
      }, {
        type: 'pasp',
        size: 16,
        data: new Uint8Array([0, 0, 0, 1, 0, 0, 0, 1])
      }]
    }]
  }]);
});

QUnit.test('can parse an audio stsd', function(assert) {
  var data = box('stsd',
                 0x00,                         // version 0
                 0x00, 0x00, 0x00,             // flags
                 0x00, 0x00, 0x00, 0x01,       // entry_count
                 box('mp4a',
                     0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00,         // reserved
                     0x00, 0x01,               // data_reference_index
                     0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00,   // reserved
                     0x00, 0x02,               // channelcount
                     0x00, 0x10,               // samplesize
                     0x00, 0x00,               // pre_defined
                     0x00, 0x00,               // reserved
                     0xbb, 0x80, 0x00, 0x00, // samplerate, fixed-point 16.16
                     box('esds',
                         0x00, // version 0
                         0x00, 0x00, 0x00, // flags
                         0x03, // tag, ES_DescrTag
                         0x00, // length
                         0x00, 0x01, // ES_ID
                         0x00, // streamDependenceFlag, URL_Flag, reserved, streamPriority

                         // DecoderConfigDescriptor
                         0x04, // tag, DecoderConfigDescrTag
                         0x0d, // length
                         0x40, // objectProfileIndication, AAC Main
                         0x15, // streamType, AudioStream. upstream, reserved
                         0x00, 0x00, 0xff, // bufferSizeDB
                         0x00, 0x00, 0x00, 0xff, // maxBitrate
                         0x00, 0x00, 0x00, 0xaa, // avgBitrate

                         // DecoderSpecificInfo
                         0x05, // tag, DecoderSpecificInfoTag
                         0x02, // length
                         // audioObjectType, samplingFrequencyIndex, channelConfiguration
                         0x11, 0x90,
                         // GASpecificConfig
                         0x06, 0x01, 0x02)));

  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)), [{
    version: 0,
    flags: new Uint8Array([0, 0, 0]),
    type: 'stsd',
    size: 91,
    sampleDescriptions: [{
      type: 'mp4a',
      dataReferenceIndex: 1,
      channelcount: 2,
      samplesize: 16,
      samplerate: 48000,
      size: 75,
      streamDescriptor: {
        type: 'esds',
        version: 0,
        size: 39,
        flags: new Uint8Array([0, 0, 0]),
        esId: 1,
        streamPriority: 0,
        decoderConfig: {
          objectProfileIndication: 0x40,
          streamType: 0x05,
          bufferSize: 0xff,
          maxBitrate: 0xff,
          avgBitrate: 0xaa,
          decoderConfigDescriptor: {
            tag: 5,
            length: 2,
            audioObjectType: 2,
            samplingFrequencyIndex: 3,
            channelConfiguration: 2
          }
        }
      }
    }]
  }], 'parsed an audio stsd');
});

QUnit.test('can parse an styp', function(assert) {
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(box('styp',
    0x61, 0x76, 0x63, 0x31, // major brand
    0x00, 0x00, 0x00, 0x02, // minor version
    98, 111, 111, 112 // compatible brands
  ))), [{
    type: 'styp',
    size: 4 * 5,
    majorBrand: 'avc1',
    minorVersion: 2,
    compatibleBrands: ['boop']
  }], 'parsed an styp');
});

QUnit.test('can parse a vmhd', function(assert) {
  var data = box('vmhd',
                 0x00, // version
                 0x00, 0x00, 0x00, // flags
                 0x00, 0x00, // graphicsmode
                 0x00, 0x00,
                 0x00, 0x00,
                 0x00, 0x00); // opcolor

  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'vmhd',
              size: 20,
              version: 0,
              flags: new Uint8Array([0, 0, 0]),
              graphicsmode: 0,
              opcolor: new Uint16Array([0, 0, 0])
            }]);
});

QUnit.test('can parse an stsz', function(assert) {
  var data = box('stsz',
                 0x00, // version
                 0x00, 0x00, 0x00, // flags
                 0x00, 0x00, 0x00, 0x00, // sample_size
                 0x00, 0x00, 0x00, 0x03, // sample_count
                 0x00, 0x00, 0x00, 0x01, // entry_size
                 0x00, 0x00, 0x00, 0x02, // entry_size
                 0x00, 0x00, 0x00, 0x03); // entry_size
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'stsz',
              size: 32,
              version: 0,
              flags: new Uint8Array([0, 0, 0]),
              sampleSize: 0,
              entries: [1, 2, 3]
            }]);
});

QUnit.test('can parse a moof', function(assert) {
  var data = box('moof',
                 box('mfhd',
                     0x00, // version
                     0x00, 0x00, 0x00, // flags
                     0x00, 0x00, 0x00, 0x04), // sequence_number
                 box('traf',
                     box('tfhd',
                        0x00, // version
                        0x00, 0x00, 0x3b, // flags
                        0x00, 0x00, 0x00, 0x01, // track_ID
                        0x00, 0x00, 0x00, 0x00,
                        0x00, 0x00, 0x00, 0x01, // base_data_offset
                        0x00, 0x00, 0x00, 0x02, // sample_description_index
                        0x00, 0x00, 0x00, 0x03, // default_sample_duration,
                        0x00, 0x00, 0x00, 0x04, // default_sample_size
                        0x00, 0x00, 0x00, 0x05))); // default_sample_flags
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'moof',
              size: 72,
              boxes: [{
                type: 'mfhd',
                size: 16,
                version: 0,
                flags: new Uint8Array([0, 0, 0]),
                sequenceNumber: 4
              },
              {
                type: 'traf',
                size: 48,
                boxes: [{
                  type: 'tfhd',
                  version: 0,
                  size: 40,
                  flags: new Uint8Array([0x00, 0, 0x3b]),
                  trackId: 1,
                  baseDataOffset: 1,
                  sampleDescriptionIndex: 2,
                  defaultSampleDuration: 3,
                  defaultSampleSize: 4,
                  defaultSampleFlags: 5
                }]
              }]
            }]);
});

QUnit.test('can parse a trun', function(assert) {
  var data = box('trun',
                 0x00, // version
                 0x00, 0x0b, 0x05, // flags
                 0x00, 0x00, 0x00, 0x02, // sample_count
                 0x00, 0x00, 0x00, 0x01, // data_offset
                 // first_sample_flags
                 // r:0000 il:10 sdo:01 sido:10 shr:01 spv:111 snss:1
                 // dp:1111 1110 1101 1100
                 0x09, 0x9f, 0xfe, 0xdc,

                 0x00, 0x00, 0x00, 0x09, // sample_duration
                 0x00, 0x00, 0x00, 0xff, // sample_size
                 0x00, 0x00, 0x00, 0x00, // sample_composition_time_offset

                 0x00, 0x00, 0x00, 0x08, // sample_duration
                 0x00, 0x00, 0x00, 0xfe, // sample_size
                 0x00, 0x00, 0x00, 0x00); // sample_composition_time_offset
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'trun',
              version: 0,
              size: 48,
              flags: new Uint8Array([0, 0x0b, 0x05]),
              dataOffset: 1,
              samples: [{
                duration: 9,
                size: 0xff,
                flags: {
                  isLeading: 2,
                  dependsOn: 1,
                  isDependedOn: 2,
                  hasRedundancy: 1,
                  paddingValue: 7,
                  isNonSyncSample: 1,
                  degradationPriority: 0xfedc
                },
                compositionTimeOffset: 0
              }, {
                duration: 8,
                size: 0xfe,
                compositionTimeOffset: 0
              }]
            }]);
});

QUnit.test('can parse a trun with per-sample flags', function(assert) {
  var data = box('trun',
                 0x00, // version
                 0x00, 0x0f, 0x00, // flags
                 0x00, 0x00, 0x00, 0x01, // sample_count

                 0x00, 0x00, 0x00, 0x09, // sample_duration
                 0x00, 0x00, 0x00, 0xff, // sample_size
                 // sample_flags
                 // r:0000 il:00 sdo:01, sido:11 shr:00 spv:010 snss:0
                 // dp: 0001 0010 0011 0100
                 0x01, 0xc4, 0x12, 0x34,
                 0x00, 0x00, 0x00, 0x00); // sample_composition_time_offset
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'trun',
              version: 0,
              size: 32,
              flags: new Uint8Array([0, 0x0f, 0x00]),
              samples: [{
                duration: 9,
                size: 0xff,
                flags: {
                  isLeading: 0,
                  dependsOn: 1,
                  isDependedOn: 3,
                  hasRedundancy: 0,
                  paddingValue: 2,
                  isNonSyncSample: 0,
                  degradationPriority: 0x1234
                },
                compositionTimeOffset: 0
              }]
            }]);

});

QUnit.test('can parse an sdtp', function(assert) {
  var data = box('sdtp',
                 0x00, // version
                 0x00, 0x00, 0x00, // flags
                 // reserved + sample_depends_on +
                 // sample_is_dependend_on + sample_has_redundancy
                 0x15,
                 // reserved + sample_depends_on +
                 // sample_is_dependend_on + sample_has_redundancy
                 0x27);
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)), [{
    type: 'sdtp',
    version: 0,
    flags: new Uint8Array([0, 0, 0]),
    size: 14,
    samples: [{
      dependsOn: 1,
      isDependedOn: 1,
      hasRedundancy: 1
    }, {
      dependsOn: 2,
      isDependedOn: 1,
      hasRedundancy: 3
    }]
  }]);
});

QUnit.test('can parse a sidx', function(assert) {
  var data = box('sidx',
                 0x00, // version
                 0x00, 0x00, 0x00, // flags
                 0x00, 0x00, 0x00, 0x02, // reference_ID
                 0x00, 0x00, 0x00, 0x01, // timescale
                 0x01, 0x02, 0x03, 0x04, // earliest_presentation_time
                 0x00, 0x00, 0x00, 0x00, // first_offset
                 0x00, 0x00,             // reserved
                 0x00, 0x02,             // reference_count
                 // first reference
                 0x80, 0x00, 0x00, 0x07, // reference_type(1) + referenced_size(31)
                 0x00, 0x00, 0x00, 0x08, // subsegment_duration
                 0x80, 0x00, 0x00, 0x09, // starts_with_SAP(1) + SAP_type(3) + SAP_delta_time(28)
                 // second reference
                 0x00, 0x00, 0x00, 0x03, // reference_type(1) + referenced_size(31)
                 0x00, 0x00, 0x00, 0x04, // subsegment_duration
                 0x10, 0x00, 0x00, 0x05  // starts_with_SAP(1) + SAP_type(3) + SAP_delta_time(28)
                );
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'sidx',
              version: 0,
              flags: new Uint8Array([0, 0x00, 0x00]),
              timescale: 1,
              earliestPresentationTime: 0x01020304,
              firstOffset: 0,
              referenceId: 2,
              size: 56,
              references: [{
                referenceType: 1,
                referencedSize: 7,
                subsegmentDuration: 8,
                startsWithSap: true,
                sapType: 0,
                sapDeltaTime: 9
                }, {
                referenceType: 0,
                referencedSize: 3,
                subsegmentDuration: 4,
                startsWithSap: false,
                sapType: 1,
                sapDeltaTime: 5
                }]

            }]);
});

QUnit.test('can parse a version 1 sidx', function(assert) {
  var data = box('sidx',
                  0x01, // version
                  0x00, 0x00, 0x00, // flags
                  0x00, 0x00, 0x00, 0x02, // reference_ID
                  0x00, 0x00, 0x00, 0x01, // timescale
                  0x00, 0x00, 0x00, 0x00, // earliest_presentation_time
                  0x01, 0x02, 0x03, 0x04,
                  0x00, 0x00, 0x00, 0x00, // first_offset
                  0x00, 0x00, 0x00, 0x00,
                  0x00, 0x00,             // reserved
                  0x00, 0x02,             // reference_count
                  // first reference
                  0x80, 0x00, 0x00, 0x07, // reference_type(1) + referenced_size(31)
                  0x00, 0x00, 0x00, 0x08, // subsegment_duration
                  0x80, 0x00, 0x00, 0x09, // starts_with_SAP(1) + SAP_type(3) + SAP_delta_time(28)
                  // second reference
                  0x00, 0x00, 0x00, 0x03, // reference_type(1) + referenced_size(31)
                  0x00, 0x00, 0x00, 0x04, // subsegment_duration
                  0x10, 0x00, 0x00, 0x05  // starts_with_SAP(1) + SAP_type(3) + SAP_delta_time(28)
  );
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
    [{
      type: 'sidx',
      version: 1,
      flags: new Uint8Array([0, 0x00, 0x00]),
      timescale: 1,
      earliestPresentationTime: 0x01020304,
      firstOffset: 0,
      referenceId: 2,
      size: 64,
      references: [{
        referenceType: 1,
        referencedSize: 7,
        subsegmentDuration: 8,
        startsWithSap: true,
        sapType: 0,
        sapDeltaTime: 9
      }, {
        referenceType: 0,
        referencedSize: 3,
        subsegmentDuration: 4,
        startsWithSap: false,
        sapType: 1,
        sapDeltaTime: 5
      }]

    }]);
});

QUnit.test('can parse a big version 1 sidx', function(assert) {
  var data = box('sidx',
                  0x01, // version
                  0x00, 0x00, 0x00, // flags
                  0x00, 0x00, 0x00, 0x02, // reference_ID
                  0x00, 0x00, 0x00, 0x01, // timescale
                  0x01, 0x02, 0x03, 0x04, // earliest_presentation_time
                  0x05, 0x06, 0x07, 0x08,
                  0x08, 0x07, 0x06, 0x05, // first_offset
                  0x04, 0x03, 0x02, 0x01,
                  0x00, 0x00,             // reserved
                  0x00, 0x02,             // reference_count
                  // first reference
                  0x80, 0x00, 0x00, 0x07, // reference_type(1) + referenced_size(31)
                  0x00, 0x00, 0x00, 0x08, // subsegment_duration
                  0x80, 0x00, 0x00, 0x09, // starts_with_SAP(1) + SAP_type(3) + SAP_delta_time(28)
                  // second reference
                  0x00, 0x00, 0x00, 0x03, // reference_type(1) + referenced_size(31)
                  0x00, 0x00, 0x00, 0x04, // subsegment_duration
                  0x10, 0x00, 0x00, 0x05  // starts_with_SAP(1) + SAP_type(3) + SAP_delta_time(28)
  );
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
    [{
      type: 'sidx',
      version: 1,
      flags: new Uint8Array([0, 0x00, 0x00]),
      timescale: 1,
      earliestPresentationTime: BigInt('0x0102030405060708'),
      firstOffset: BigInt('0x0807060504030201'),
      referenceId: 2,
      size: 64,
      references: [{
        referenceType: 1,
        referencedSize: 7,
        subsegmentDuration: 8,
        startsWithSap: true,
        sapType: 0,
        sapDeltaTime: 9
      }, {
        referenceType: 0,
        referencedSize: 3,
        subsegmentDuration: 4,
        startsWithSap: false,
        sapType: 1,
        sapDeltaTime: 5
      }]

    }]);
});

QUnit.test('can parse an smhd', function(assert) {
  var data = box('smhd',
                 0x00,             // version
                 0x00, 0x00, 0x00, // flags
                 0x00, 0xff,       // balance, fixed-point 8.8
                 0x00, 0x00);      // reserved

  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'smhd',
              size: 16,
              version: 0,
              flags: new Uint8Array([0, 0, 0]),
              balance: 0xff / Math.pow(2, 8)
            }],
            'parsed an smhd');
});

QUnit.test('can parse a version 0 tfdt', function(assert) {
  var data = box('tfdt',
                 0x00, // version
                 0x00, 0x00, 0x00, // flags
                 0x01, 0x02, 0x03, 0x04); // baseMediaDecodeTime
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'tfdt',
              version: 0,
              size: 16,
              flags: new Uint8Array([0, 0, 0]),
              baseMediaDecodeTime: 0x01020304
            }]);
});

QUnit.test('can parse a version 1 tfdt and return an unsigned integer value', function(assert) {
  var data = box('tfdt',
                 0x01, // version
                 0x00, 0x00, 0x00, // flags
                 0x81, 0x02, 0x03, 0x04,
                 0x05, 0x06, 0x07, 0x08); // baseMediaDecodeTime
  assert.deepEqual(mp4.tools.inspect(new Uint8Array(data)),
            [{
              type: 'tfdt',
              version: 1,
              size: 20,
              flags: new Uint8Array([0, 0, 0]),
              baseMediaDecodeTime: BigInt('0x8102030405060708')
            }]);
});

QUnit.test('can parse a series of boxes', function(assert) {
  var ftyp = [
    0x00, 0x00, 0x00, 0x18 // size 4 * 6 = 24
  ].concat(typeBytes('ftyp')).concat([
    0x69, 0x73, 0x6f, 0x6d, // major brand
    0x00, 0x00, 0x00, 0x02, // minor version
    98, 101, 101, 112, // compatible brands
    98, 111, 111, 112  // compatible brands
  ]);

  assert.deepEqual(mp4.tools.inspect(new Uint8Array(ftyp.concat(ftyp))),
            [{
              type: 'ftyp',
              size: 4 * 6,
              majorBrand: 'isom',
              minorVersion: 2,
              compatibleBrands: ['beep', 'boop']
            }, {
              type: 'ftyp',
              size: 4 * 6,
              majorBrand: 'isom',
              minorVersion: 2,
              compatibleBrands: ['beep', 'boop']
            }],
            'parsed two boxes in series');

});
