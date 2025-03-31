'use strict';

var Stream = require('../utils/stream.js');
var mp4 = require('../mp4/mp4-generator.js');
var audioFrameUtils = require('../mp4/audio-frame-utils');
var trackInfo = require('../mp4/track-decode-info.js');
var ONE_SECOND_IN_TS = require('../utils/clock').ONE_SECOND_IN_TS;
var AUDIO_PROPERTIES = require('../constants/audio-properties.js');

/**
 * Constructs a single-track, ISO BMFF media segment from AAC data
 * events. The output of this stream can be fed to a SourceBuffer
 * configured with a suitable initialization segment.
 */
var AudioSegmentStream = function(track, options) {
  var
    adtsFrames = [],
    sequenceNumber = 0,
    earliestAllowedDts = 0,
    audioAppendStartTs = 0,
    videoBaseMediaDecodeTime = Infinity,
    segmentStartPts = null,
    segmentEndPts = null;

  options = options || {};

  AudioSegmentStream.prototype.init.call(this);

  this.push = function(data) {
    trackInfo.collectDtsInfo(track, data);

    if (track) {
      AUDIO_PROPERTIES.forEach(function(prop) {
        track[prop] = data[prop];
      });
    }

    // buffer audio data until end() is called
    adtsFrames.push(data);
  };

  this.setEarliestDts = function(earliestDts) {
    earliestAllowedDts = earliestDts;
  };

  this.setVideoBaseMediaDecodeTime = function(baseMediaDecodeTime) {
    videoBaseMediaDecodeTime = baseMediaDecodeTime;
  };

  this.setAudioAppendStart = function(timestamp) {
    audioAppendStartTs = timestamp;
  };

  this.processFrames_ = function() {
    var
      frames,
      moof,
      mdat,
      boxes,
      timingInfo;

    // return early if no audio data has been observed
    if (adtsFrames.length === 0) {
      return;
    }

    frames = audioFrameUtils.trimAdtsFramesByEarliestDts(
      adtsFrames, track, earliestAllowedDts);
    if (frames.length === 0) {
      // return early if the frames are all after the earliest allowed DTS
      // TODO should we clear the adtsFrames?
      return;
    }

    track.baseMediaDecodeTime = trackInfo.calculateTrackBaseMediaDecodeTime(
      track, options.keepOriginalTimestamps);

    audioFrameUtils.prefixWithSilence(
      track, frames, audioAppendStartTs, videoBaseMediaDecodeTime);

    // we have to build the index from byte locations to
    // samples (that is, adts frames) in the audio data
    track.samples = audioFrameUtils.generateSampleTable(frames);

    // concatenate the audio data to constuct the mdat
    mdat = mp4.mdat(audioFrameUtils.concatenateFrameData(frames));

    adtsFrames = [];

    moof = mp4.moof(sequenceNumber, [track]);

    // bump the sequence number for next time
    sequenceNumber++;

    track.initSegment = mp4.initSegment([track]);

    // it would be great to allocate this array up front instead of
    // throwing away hundreds of media segment fragments
    boxes = new Uint8Array(moof.byteLength + mdat.byteLength);

    boxes.set(moof);
    boxes.set(mdat, moof.byteLength);

    trackInfo.clearDtsInfo(track);

    if (segmentStartPts === null) {
      segmentEndPts = segmentStartPts = frames[0].pts;
    }

    segmentEndPts += frames.length * (ONE_SECOND_IN_TS * 1024 / track.samplerate);

    timingInfo = { start: segmentStartPts };

    this.trigger('timingInfo', timingInfo);
    this.trigger('data', {track: track, boxes: boxes});
  };

  this.flush = function() {
    this.processFrames_();
    // trigger final timing info
    this.trigger('timingInfo', {
      start: segmentStartPts,
      end: segmentEndPts
    });
    this.resetTiming_();
    this.trigger('done', 'AudioSegmentStream');
  };

  this.partialFlush = function() {
    this.processFrames_();
    this.trigger('partialdone', 'AudioSegmentStream');
  };

  this.endTimeline = function() {
    this.flush();
    this.trigger('endedtimeline', 'AudioSegmentStream');
  };

  this.resetTiming_ = function() {
    trackInfo.clearDtsInfo(track);
    segmentStartPts = null;
    segmentEndPts = null;
  };

  this.reset = function() {
    this.resetTiming_();
    adtsFrames = [];
    this.trigger('reset');
  };
};

AudioSegmentStream.prototype = new Stream();

module.exports = AudioSegmentStream;
