/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
var coneOfSilence = require('../data/silence');
var clock = require('../utils/clock');

/**
 * Sum the `byteLength` properties of the data in each AAC frame
 */
var sumFrameByteLengths = function(array) {
  var
    i,
    currentObj,
    sum = 0;

  // sum the byteLength's all each nal unit in the frame
  for (i = 0; i < array.length; i++) {
    currentObj = array[i];
    sum += currentObj.data.byteLength;
  }

  return sum;
};

// Possibly pad (prefix) the audio track with silence if appending this track
// would lead to the introduction of a gap in the audio buffer
var prefixWithSilence = function(
  track,
  frames,
  audioAppendStartTs,
  videoBaseMediaDecodeTime
) {
  var
    baseMediaDecodeTimeTs,
    frameDuration = 0,
    audioGapDuration = 0,
    audioFillFrameCount = 0,
    audioFillDuration = 0,
    silentFrame,
    i,
    firstFrame;

  if (!frames.length) {
    return;
  }

  baseMediaDecodeTimeTs =
    clock.audioTsToVideoTs(track.baseMediaDecodeTime, track.samplerate);
  // determine frame clock duration based on sample rate, round up to avoid overfills
  frameDuration = Math.ceil(clock.ONE_SECOND_IN_TS / (track.samplerate / 1024));

  if (audioAppendStartTs && videoBaseMediaDecodeTime) {
    // insert the shortest possible amount (audio gap or audio to video gap)
    audioGapDuration =
      baseMediaDecodeTimeTs - Math.max(audioAppendStartTs, videoBaseMediaDecodeTime);
    // number of full frames in the audio gap
    audioFillFrameCount = Math.floor(audioGapDuration / frameDuration);
    audioFillDuration = audioFillFrameCount * frameDuration;
  }

  // don't attempt to fill gaps smaller than a single frame or larger
  // than a half second
  if (audioFillFrameCount < 1 || audioFillDuration > clock.ONE_SECOND_IN_TS / 2) {
    return;
  }

  silentFrame = coneOfSilence()[track.samplerate];

  if (!silentFrame) {
    // we don't have a silent frame pregenerated for the sample rate, so use a frame
    // from the content instead
    silentFrame = frames[0].data;
  }

  for (i = 0; i < audioFillFrameCount; i++) {
    firstFrame = frames[0];

    frames.splice(0, 0, {
      data: silentFrame,
      dts: firstFrame.dts - frameDuration,
      pts: firstFrame.pts - frameDuration
    });
  }

  track.baseMediaDecodeTime -=
    Math.floor(clock.videoTsToAudioTs(audioFillDuration, track.samplerate));

  return audioFillDuration;
};

// If the audio segment extends before the earliest allowed dts
// value, remove AAC frames until starts at or after the earliest
// allowed DTS so that we don't end up with a negative baseMedia-
// DecodeTime for the audio track
var trimAdtsFramesByEarliestDts = function(adtsFrames, track, earliestAllowedDts) {
  if (track.minSegmentDts >= earliestAllowedDts) {
    return adtsFrames;
  }

  // We will need to recalculate the earliest segment Dts
  track.minSegmentDts = Infinity;

  return adtsFrames.filter(function(currentFrame) {
    // If this is an allowed frame, keep it and record it's Dts
    if (currentFrame.dts >= earliestAllowedDts) {
      track.minSegmentDts = Math.min(track.minSegmentDts, currentFrame.dts);
      track.minSegmentPts = track.minSegmentDts;
      return true;
    }
    // Otherwise, discard it
    return false;
  });
};

// generate the track's raw mdat data from an array of frames
var generateSampleTable = function(frames) {
  var
    i,
    currentFrame,
    samples = [];

  for (i = 0; i < frames.length; i++) {
    currentFrame = frames[i];
    samples.push({
      size: currentFrame.data.byteLength,
      duration: 1024 // For AAC audio, all samples contain 1024 samples
    });
  }
  return samples;
};

// generate the track's sample table from an array of frames
var concatenateFrameData = function(frames) {
  var
    i,
    currentFrame,
    dataOffset = 0,
    data = new Uint8Array(sumFrameByteLengths(frames));

  for (i = 0; i < frames.length; i++) {
    currentFrame = frames[i];

    data.set(currentFrame.data, dataOffset);
    dataOffset += currentFrame.data.byteLength;
  }
  return data;
};

module.exports = {
  prefixWithSilence: prefixWithSilence,
  trimAdtsFramesByEarliestDts: trimAdtsFramesByEarliestDts,
  generateSampleTable: generateSampleTable,
  concatenateFrameData: concatenateFrameData
};
