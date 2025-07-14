"use strict";

var parseSampleFlags = require('./parse-sample-flags.js');

var trun = function trun(data) {
  var result = {
    version: data[0],
    flags: new Uint8Array(data.subarray(1, 4)),
    samples: []
  },
      view = new DataView(data.buffer, data.byteOffset, data.byteLength),
      // Flag interpretation
  dataOffsetPresent = result.flags[2] & 0x01,
      // compare with 2nd byte of 0x1
  firstSampleFlagsPresent = result.flags[2] & 0x04,
      // compare with 2nd byte of 0x4
  sampleDurationPresent = result.flags[1] & 0x01,
      // compare with 2nd byte of 0x100
  sampleSizePresent = result.flags[1] & 0x02,
      // compare with 2nd byte of 0x200
  sampleFlagsPresent = result.flags[1] & 0x04,
      // compare with 2nd byte of 0x400
  sampleCompositionTimeOffsetPresent = result.flags[1] & 0x08,
      // compare with 2nd byte of 0x800
  sampleCount = view.getUint32(4),
      offset = 8,
      sample;

  if (dataOffsetPresent) {
    // 32 bit signed integer
    result.dataOffset = view.getInt32(offset);
    offset += 4;
  } // Overrides the flags for the first sample only. The order of
  // optional values will be: duration, size, compositionTimeOffset


  if (firstSampleFlagsPresent && sampleCount) {
    sample = {
      flags: parseSampleFlags(data.subarray(offset, offset + 4))
    };
    offset += 4;

    if (sampleDurationPresent) {
      sample.duration = view.getUint32(offset);
      offset += 4;
    }

    if (sampleSizePresent) {
      sample.size = view.getUint32(offset);
      offset += 4;
    }

    if (sampleCompositionTimeOffsetPresent) {
      if (result.version === 1) {
        sample.compositionTimeOffset = view.getInt32(offset);
      } else {
        sample.compositionTimeOffset = view.getUint32(offset);
      }

      offset += 4;
    }

    result.samples.push(sample);
    sampleCount--;
  }

  while (sampleCount--) {
    sample = {};

    if (sampleDurationPresent) {
      sample.duration = view.getUint32(offset);
      offset += 4;
    }

    if (sampleSizePresent) {
      sample.size = view.getUint32(offset);
      offset += 4;
    }

    if (sampleFlagsPresent) {
      sample.flags = parseSampleFlags(data.subarray(offset, offset + 4));
      offset += 4;
    }

    if (sampleCompositionTimeOffsetPresent) {
      if (result.version === 1) {
        sample.compositionTimeOffset = view.getInt32(offset);
      } else {
        sample.compositionTimeOffset = view.getUint32(offset);
      }

      offset += 4;
    }

    result.samples.push(sample);
  }

  return result;
};

module.exports = trun;