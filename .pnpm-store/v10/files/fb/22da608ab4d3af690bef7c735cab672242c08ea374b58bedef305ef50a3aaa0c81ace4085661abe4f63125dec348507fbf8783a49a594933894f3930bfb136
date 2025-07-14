var Transmuxer = require('../lib/partial/transmuxer.js');
var utils = require('./utils');
var generatePMT = utils.generatePMT;
var videoPes = utils.videoPes;
var audioPes = utils.audioPes;
var packetize = utils.packetize;
var PAT = utils.PAT;

QUnit.module('Partial Transmuxer - Options');
[
  {options: {keepOriginalTimestamps: false}},
  {options: {keepOriginalTimestamps: true}},
  {options: {keepOriginalTimestamps: false, baseMediaDecodeTime: 15000}},
  {options: {keepOriginalTimestamps: true, baseMediaDecodeTime: 15000}},
  {options: {keepOriginalTimestamps: false}, baseMediaSetter: 15000},
  {options: {keepOriginalTimestamps: true}, baseMediaSetter: 15000}
].forEach(function(test) {
  var createTransmuxer = function() {
    var transmuxer = new Transmuxer(test.options);

    if (test.baseMediaSetter) {
      transmuxer.setBaseMediaDecodeTime(test.baseMediaSetter);
    }

    return transmuxer;
  };

  var name = '';

  Object.keys(test.options).forEach(function(optionName) {
    name += '' + optionName + ' ' + test.options[optionName] + ' ';
  });

  if (test.baseMediaSetter) {
    name += 'baseMediaDecodeTime setter ' + test.baseMediaSetter;
  }

  QUnit.test('Audio frames after video not trimmed, ' + name, function(assert) {
    var
    segments = [],
      earliestDts = 15000,
      transmuxer = createTransmuxer();

    transmuxer.on('data', function(segment) {
      segments.push(segment);
    });

    // the following transmuxer pushes add tiny video and
    // audio data to the transmuxer. When we add the data
    // we also set the pts/dts time so that audio should
    // not be trimmed.
    transmuxer.push(packetize(PAT));
    transmuxer.push(packetize(generatePMT({
      hasVideo: true,
      hasAudio: true
    })));

    transmuxer.push(packetize(audioPes([
      0x19, 0x47
    ], true, earliestDts + 1)));
    transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x07, // seq_parameter_set_rbsp
      0x27, 0x42, 0xe0, 0x0b,
      0xa9, 0x18, 0x60, 0x9d,
      0x80, 0x53, 0x06, 0x01,
      0x06, 0xb6, 0xc2, 0xb5,
      0xef, 0x7c, 0x04
    ], false, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
    ], true, earliestDts)));
    transmuxer.flush();

    // the partial transmuxer only generates a video segment
    // when all audio frames are trimmed. So we should have an audio and video
    // segment
    assert.equal(segments.length, 2, 'generated a video and an audio segment');
    assert.equal(segments[0].type, 'video', 'video segment exists');
    assert.equal(segments[1].type, 'audio', 'audio segment exists');
  });

  QUnit.test('Audio frames trimmed before video, ' + name, function(assert) {
    var
    segments = [],
      earliestDts = 15000,
      baseTime = test.options.baseMediaDecodeTime || test.baseMediaSetter || 0,
      transmuxer = createTransmuxer();

    transmuxer.on('data', function(segment) {
      segments.push(segment);
    });

    // the following transmuxer pushes add tiny video and
    // audio data to the transmuxer. When we add the data
    // we also set the pts/dts time so that audio should
    // be trimmed.
    transmuxer.push(packetize(PAT));
    transmuxer.push(packetize(generatePMT({
      hasVideo: true,
      hasAudio: true
    })));

    transmuxer.push(packetize(audioPes([
      0x19, 0x47
    ], true, earliestDts - baseTime - 1)));
    transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x07, // seq_parameter_set_rbsp
      0x27, 0x42, 0xe0, 0x0b,
      0xa9, 0x18, 0x60, 0x9d,
      0x80, 0x53, 0x06, 0x01,
      0x06, 0xb6, 0xc2, 0xb5,
      0xef, 0x7c, 0x04
    ], false, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
    ], true, earliestDts)));
    transmuxer.flush();

    // the partial transmuxer only generates a video segment
    // when all audio frames are trimmed.
    if (test.options.keepOriginalTimestamps && !baseTime) {
      assert.equal(segments.length, 2, 'generated both a video/audio segment');
      assert.equal(segments[0].type, 'video', 'segment is video');
      assert.equal(segments[1].type, 'audio', 'segment is audio');
    } else {
      assert.equal(segments.length, 1, 'generated only a video segment');
      assert.equal(segments[0].type, 'video', 'segment is video');
    }
  });
});
