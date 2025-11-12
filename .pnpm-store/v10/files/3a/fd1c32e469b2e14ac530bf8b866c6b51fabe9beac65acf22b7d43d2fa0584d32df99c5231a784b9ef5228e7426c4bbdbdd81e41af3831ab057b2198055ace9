/**
 * Constructs a single-track, ISO BMFF media segment from H264 data
 * events. The output of this stream can be fed to a SourceBuffer
 * configured with a suitable initialization segment.
 * @param track {object} track metadata configuration
 * @param options {object} transmuxer options object
 * @param options.alignGopsAtEnd {boolean} If true, start from the end of the
 *        gopsToAlignWith list when attempting to align gop pts
 */
'use strict';

var Stream = require('../utils/stream.js');

var mp4 = require('../mp4/mp4-generator.js');

var trackInfo = require('../mp4/track-decode-info.js');

var frameUtils = require('../mp4/frame-utils');

var VIDEO_PROPERTIES = require('../constants/video-properties.js');

var VideoSegmentStream = function VideoSegmentStream(track, options) {
  var sequenceNumber = 0,
      nalUnits = [],
      frameCache = [],
      // gopsToAlignWith = [],
  config,
      pps,
      segmentStartPts = null,
      segmentEndPts = null,
      gops,
      ensureNextFrameIsKeyFrame = true;
  options = options || {};
  VideoSegmentStream.prototype.init.call(this);

  this.push = function (nalUnit) {
    trackInfo.collectDtsInfo(track, nalUnit);

    if (typeof track.timelineStartInfo.dts === 'undefined') {
      track.timelineStartInfo.dts = nalUnit.dts;
    } // record the track config


    if (nalUnit.nalUnitType === 'seq_parameter_set_rbsp' && !config) {
      config = nalUnit.config;
      track.sps = [nalUnit.data];
      VIDEO_PROPERTIES.forEach(function (prop) {
        track[prop] = config[prop];
      }, this);
    }

    if (nalUnit.nalUnitType === 'pic_parameter_set_rbsp' && !pps) {
      pps = nalUnit.data;
      track.pps = [nalUnit.data];
    } // buffer video until flush() is called


    nalUnits.push(nalUnit);
  };

  this.processNals_ = function (cacheLastFrame) {
    var i;
    nalUnits = frameCache.concat(nalUnits); // Throw away nalUnits at the start of the byte stream until
    // we find the first AUD

    while (nalUnits.length) {
      if (nalUnits[0].nalUnitType === 'access_unit_delimiter_rbsp') {
        break;
      }

      nalUnits.shift();
    } // Return early if no video data has been observed


    if (nalUnits.length === 0) {
      return;
    }

    var frames = frameUtils.groupNalsIntoFrames(nalUnits);

    if (!frames.length) {
      return;
    } // note that the frame cache may also protect us from cases where we haven't
    // pushed data for the entire first or last frame yet


    frameCache = frames[frames.length - 1];

    if (cacheLastFrame) {
      frames.pop();
      frames.duration -= frameCache.duration;
      frames.nalCount -= frameCache.length;
      frames.byteLength -= frameCache.byteLength;
    }

    if (!frames.length) {
      nalUnits = [];
      return;
    }

    this.trigger('timelineStartInfo', track.timelineStartInfo);

    if (ensureNextFrameIsKeyFrame) {
      gops = frameUtils.groupFramesIntoGops(frames);

      if (!gops[0][0].keyFrame) {
        gops = frameUtils.extendFirstKeyFrame(gops);

        if (!gops[0][0].keyFrame) {
          // we haven't yet gotten a key frame, so reset nal units to wait for more nal
          // units
          nalUnits = [].concat.apply([], frames).concat(frameCache);
          frameCache = [];
          return;
        }

        frames = [].concat.apply([], gops);
        frames.duration = gops.duration;
      }

      ensureNextFrameIsKeyFrame = false;
    }

    if (segmentStartPts === null) {
      segmentStartPts = frames[0].pts;
      segmentEndPts = segmentStartPts;
    }

    segmentEndPts += frames.duration;
    this.trigger('timingInfo', {
      start: segmentStartPts,
      end: segmentEndPts
    });

    for (i = 0; i < frames.length; i++) {
      var frame = frames[i];
      track.samples = frameUtils.generateSampleTableForFrame(frame);
      var mdat = mp4.mdat(frameUtils.concatenateNalDataForFrame(frame));
      trackInfo.clearDtsInfo(track);
      trackInfo.collectDtsInfo(track, frame);
      track.baseMediaDecodeTime = trackInfo.calculateTrackBaseMediaDecodeTime(track, options.keepOriginalTimestamps);
      var moof = mp4.moof(sequenceNumber, [track]);
      sequenceNumber++;
      track.initSegment = mp4.initSegment([track]);
      var boxes = new Uint8Array(moof.byteLength + mdat.byteLength);
      boxes.set(moof);
      boxes.set(mdat, moof.byteLength);
      this.trigger('data', {
        track: track,
        boxes: boxes,
        sequence: sequenceNumber,
        videoFrameDts: frame.dts,
        videoFramePts: frame.pts
      });
    }

    nalUnits = [];
  };

  this.resetTimingAndConfig_ = function () {
    config = undefined;
    pps = undefined;
    segmentStartPts = null;
    segmentEndPts = null;
  };

  this.partialFlush = function () {
    this.processNals_(true);
    this.trigger('partialdone', 'VideoSegmentStream');
  };

  this.flush = function () {
    this.processNals_(false); // reset config and pps because they may differ across segments
    // for instance, when we are rendition switching

    this.resetTimingAndConfig_();
    this.trigger('done', 'VideoSegmentStream');
  };

  this.endTimeline = function () {
    this.flush();
    this.trigger('endedtimeline', 'VideoSegmentStream');
  };

  this.reset = function () {
    this.resetTimingAndConfig_();
    frameCache = [];
    nalUnits = [];
    ensureNextFrameIsKeyFrame = true;
    this.trigger('reset');
  };
};

VideoSegmentStream.prototype = new Stream();
module.exports = VideoSegmentStream;