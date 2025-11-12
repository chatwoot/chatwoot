"use strict";

/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
var ONE_SECOND_IN_TS = require('../utils/clock').ONE_SECOND_IN_TS;
/**
 * Store information about the start and end of the track and the
 * duration for each frame/sample we process in order to calculate
 * the baseMediaDecodeTime
 */


var collectDtsInfo = function collectDtsInfo(track, data) {
  if (typeof data.pts === 'number') {
    if (track.timelineStartInfo.pts === undefined) {
      track.timelineStartInfo.pts = data.pts;
    }

    if (track.minSegmentPts === undefined) {
      track.minSegmentPts = data.pts;
    } else {
      track.minSegmentPts = Math.min(track.minSegmentPts, data.pts);
    }

    if (track.maxSegmentPts === undefined) {
      track.maxSegmentPts = data.pts;
    } else {
      track.maxSegmentPts = Math.max(track.maxSegmentPts, data.pts);
    }
  }

  if (typeof data.dts === 'number') {
    if (track.timelineStartInfo.dts === undefined) {
      track.timelineStartInfo.dts = data.dts;
    }

    if (track.minSegmentDts === undefined) {
      track.minSegmentDts = data.dts;
    } else {
      track.minSegmentDts = Math.min(track.minSegmentDts, data.dts);
    }

    if (track.maxSegmentDts === undefined) {
      track.maxSegmentDts = data.dts;
    } else {
      track.maxSegmentDts = Math.max(track.maxSegmentDts, data.dts);
    }
  }
};
/**
 * Clear values used to calculate the baseMediaDecodeTime between
 * tracks
 */


var clearDtsInfo = function clearDtsInfo(track) {
  delete track.minSegmentDts;
  delete track.maxSegmentDts;
  delete track.minSegmentPts;
  delete track.maxSegmentPts;
};
/**
 * Calculate the track's baseMediaDecodeTime based on the earliest
 * DTS the transmuxer has ever seen and the minimum DTS for the
 * current track
 * @param track {object} track metadata configuration
 * @param keepOriginalTimestamps {boolean} If true, keep the timestamps
 *        in the source; false to adjust the first segment to start at 0.
 */


var calculateTrackBaseMediaDecodeTime = function calculateTrackBaseMediaDecodeTime(track, keepOriginalTimestamps) {
  var baseMediaDecodeTime,
      scale,
      minSegmentDts = track.minSegmentDts; // Optionally adjust the time so the first segment starts at zero.

  if (!keepOriginalTimestamps) {
    minSegmentDts -= track.timelineStartInfo.dts;
  } // track.timelineStartInfo.baseMediaDecodeTime is the location, in time, where
  // we want the start of the first segment to be placed


  baseMediaDecodeTime = track.timelineStartInfo.baseMediaDecodeTime; // Add to that the distance this segment is from the very first

  baseMediaDecodeTime += minSegmentDts; // baseMediaDecodeTime must not become negative

  baseMediaDecodeTime = Math.max(0, baseMediaDecodeTime);

  if (track.type === 'audio') {
    // Audio has a different clock equal to the sampling_rate so we need to
    // scale the PTS values into the clock rate of the track
    scale = track.samplerate / ONE_SECOND_IN_TS;
    baseMediaDecodeTime *= scale;
    baseMediaDecodeTime = Math.floor(baseMediaDecodeTime);
  }

  return baseMediaDecodeTime;
};

module.exports = {
  clearDtsInfo: clearDtsInfo,
  calculateTrackBaseMediaDecodeTime: calculateTrackBaseMediaDecodeTime,
  collectDtsInfo: collectDtsInfo
};