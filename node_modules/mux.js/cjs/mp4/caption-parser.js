/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * Reads in-band CEA-708 captions out of FMP4 segments.
 * @see https://en.wikipedia.org/wiki/CEA-708
 */
'use strict';

var discardEmulationPreventionBytes = require('../tools/caption-packet-parser').discardEmulationPreventionBytes;

var CaptionStream = require('../m2ts/caption-stream').CaptionStream;

var findBox = require('../mp4/find-box.js');

var parseTfdt = require('../tools/parse-tfdt.js');

var parseTrun = require('../tools/parse-trun.js');

var parseTfhd = require('../tools/parse-tfhd.js');

var window = require('global/window');
/**
  * Maps an offset in the mdat to a sample based on the the size of the samples.
  * Assumes that `parseSamples` has been called first.
  *
  * @param {Number} offset - The offset into the mdat
  * @param {Object[]} samples - An array of samples, parsed using `parseSamples`
  * @return {?Object} The matching sample, or null if no match was found.
  *
  * @see ISO-BMFF-12/2015, Section 8.8.8
 **/


var mapToSample = function mapToSample(offset, samples) {
  var approximateOffset = offset;

  for (var i = 0; i < samples.length; i++) {
    var sample = samples[i];

    if (approximateOffset < sample.size) {
      return sample;
    }

    approximateOffset -= sample.size;
  }

  return null;
};
/**
  * Finds SEI nal units contained in a Media Data Box.
  * Assumes that `parseSamples` has been called first.
  *
  * @param {Uint8Array} avcStream - The bytes of the mdat
  * @param {Object[]} samples - The samples parsed out by `parseSamples`
  * @param {Number} trackId - The trackId of this video track
  * @return {Object[]} seiNals - the parsed SEI NALUs found.
  *   The contents of the seiNal should match what is expected by
  *   CaptionStream.push (nalUnitType, size, data, escapedRBSP, pts, dts)
  *
  * @see ISO-BMFF-12/2015, Section 8.1.1
  * @see Rec. ITU-T H.264, 7.3.2.3.1
 **/


var findSeiNals = function findSeiNals(avcStream, samples, trackId) {
  var avcView = new DataView(avcStream.buffer, avcStream.byteOffset, avcStream.byteLength),
      result = {
    logs: [],
    seiNals: []
  },
      seiNal,
      i,
      length,
      lastMatchedSample;

  for (i = 0; i + 4 < avcStream.length; i += length) {
    length = avcView.getUint32(i);
    i += 4; // Bail if this doesn't appear to be an H264 stream

    if (length <= 0) {
      continue;
    }

    switch (avcStream[i] & 0x1F) {
      case 0x06:
        var data = avcStream.subarray(i + 1, i + 1 + length);
        var matchingSample = mapToSample(i, samples);
        seiNal = {
          nalUnitType: 'sei_rbsp',
          size: length,
          data: data,
          escapedRBSP: discardEmulationPreventionBytes(data),
          trackId: trackId
        };

        if (matchingSample) {
          seiNal.pts = matchingSample.pts;
          seiNal.dts = matchingSample.dts;
          lastMatchedSample = matchingSample;
        } else if (lastMatchedSample) {
          // If a matching sample cannot be found, use the last
          // sample's values as they should be as close as possible
          seiNal.pts = lastMatchedSample.pts;
          seiNal.dts = lastMatchedSample.dts;
        } else {
          result.logs.push({
            level: 'warn',
            message: 'We\'ve encountered a nal unit without data at ' + i + ' for trackId ' + trackId + '. See mux.js#223.'
          });
          break;
        }

        result.seiNals.push(seiNal);
        break;

      default:
        break;
    }
  }

  return result;
};
/**
  * Parses sample information out of Track Run Boxes and calculates
  * the absolute presentation and decode timestamps of each sample.
  *
  * @param {Array<Uint8Array>} truns - The Trun Run boxes to be parsed
  * @param {Number|BigInt} baseMediaDecodeTime - base media decode time from tfdt
      @see ISO-BMFF-12/2015, Section 8.8.12
  * @param {Object} tfhd - The parsed Track Fragment Header
  *   @see inspect.parseTfhd
  * @return {Object[]} the parsed samples
  *
  * @see ISO-BMFF-12/2015, Section 8.8.8
 **/


var parseSamples = function parseSamples(truns, baseMediaDecodeTime, tfhd) {
  var currentDts = baseMediaDecodeTime;
  var defaultSampleDuration = tfhd.defaultSampleDuration || 0;
  var defaultSampleSize = tfhd.defaultSampleSize || 0;
  var trackId = tfhd.trackId;
  var allSamples = [];
  truns.forEach(function (trun) {
    // Note: We currently do not parse the sample table as well
    // as the trun. It's possible some sources will require this.
    // moov > trak > mdia > minf > stbl
    var trackRun = parseTrun(trun);
    var samples = trackRun.samples;
    samples.forEach(function (sample) {
      if (sample.duration === undefined) {
        sample.duration = defaultSampleDuration;
      }

      if (sample.size === undefined) {
        sample.size = defaultSampleSize;
      }

      sample.trackId = trackId;
      sample.dts = currentDts;

      if (sample.compositionTimeOffset === undefined) {
        sample.compositionTimeOffset = 0;
      }

      if (typeof currentDts === 'bigint') {
        sample.pts = currentDts + window.BigInt(sample.compositionTimeOffset);
        currentDts += window.BigInt(sample.duration);
      } else {
        sample.pts = currentDts + sample.compositionTimeOffset;
        currentDts += sample.duration;
      }
    });
    allSamples = allSamples.concat(samples);
  });
  return allSamples;
};
/**
  * Parses out caption nals from an FMP4 segment's video tracks.
  *
  * @param {Uint8Array} segment - The bytes of a single segment
  * @param {Number} videoTrackId - The trackId of a video track in the segment
  * @return {Object.<Number, Object[]>} A mapping of video trackId to
  *   a list of seiNals found in that track
 **/


var parseCaptionNals = function parseCaptionNals(segment, videoTrackId) {
  // To get the samples
  var trafs = findBox(segment, ['moof', 'traf']); // To get SEI NAL units

  var mdats = findBox(segment, ['mdat']);
  var captionNals = {};
  var mdatTrafPairs = []; // Pair up each traf with a mdat as moofs and mdats are in pairs

  mdats.forEach(function (mdat, index) {
    var matchingTraf = trafs[index];
    mdatTrafPairs.push({
      mdat: mdat,
      traf: matchingTraf
    });
  });
  mdatTrafPairs.forEach(function (pair) {
    var mdat = pair.mdat;
    var traf = pair.traf;
    var tfhd = findBox(traf, ['tfhd']); // Exactly 1 tfhd per traf

    var headerInfo = parseTfhd(tfhd[0]);
    var trackId = headerInfo.trackId;
    var tfdt = findBox(traf, ['tfdt']); // Either 0 or 1 tfdt per traf

    var baseMediaDecodeTime = tfdt.length > 0 ? parseTfdt(tfdt[0]).baseMediaDecodeTime : 0;
    var truns = findBox(traf, ['trun']);
    var samples;
    var result; // Only parse video data for the chosen video track

    if (videoTrackId === trackId && truns.length > 0) {
      samples = parseSamples(truns, baseMediaDecodeTime, headerInfo);
      result = findSeiNals(mdat, samples, trackId);

      if (!captionNals[trackId]) {
        captionNals[trackId] = {
          seiNals: [],
          logs: []
        };
      }

      captionNals[trackId].seiNals = captionNals[trackId].seiNals.concat(result.seiNals);
      captionNals[trackId].logs = captionNals[trackId].logs.concat(result.logs);
    }
  });
  return captionNals;
};
/**
  * Parses out inband captions from an MP4 container and returns
  * caption objects that can be used by WebVTT and the TextTrack API.
  * @see https://developer.mozilla.org/en-US/docs/Web/API/VTTCue
  * @see https://developer.mozilla.org/en-US/docs/Web/API/TextTrack
  * Assumes that `probe.getVideoTrackIds` and `probe.timescale` have been called first
  *
  * @param {Uint8Array} segment - The fmp4 segment containing embedded captions
  * @param {Number} trackId - The id of the video track to parse
  * @param {Number} timescale - The timescale for the video track from the init segment
  *
  * @return {?Object[]} parsedCaptions - A list of captions or null if no video tracks
  * @return {Number} parsedCaptions[].startTime - The time to show the caption in seconds
  * @return {Number} parsedCaptions[].endTime - The time to stop showing the caption in seconds
  * @return {String} parsedCaptions[].text - The visible content of the caption
 **/


var parseEmbeddedCaptions = function parseEmbeddedCaptions(segment, trackId, timescale) {
  var captionNals; // the ISO-BMFF spec says that trackId can't be zero, but there's some broken content out there

  if (trackId === null) {
    return null;
  }

  captionNals = parseCaptionNals(segment, trackId);
  var trackNals = captionNals[trackId] || {};
  return {
    seiNals: trackNals.seiNals,
    logs: trackNals.logs,
    timescale: timescale
  };
};
/**
  * Converts SEI NALUs into captions that can be used by video.js
 **/


var CaptionParser = function CaptionParser() {
  var isInitialized = false;
  var captionStream; // Stores segments seen before trackId and timescale are set

  var segmentCache; // Stores video track ID of the track being parsed

  var trackId; // Stores the timescale of the track being parsed

  var timescale; // Stores captions parsed so far

  var parsedCaptions; // Stores whether we are receiving partial data or not

  var parsingPartial;
  /**
    * A method to indicate whether a CaptionParser has been initalized
    * @returns {Boolean}
   **/

  this.isInitialized = function () {
    return isInitialized;
  };
  /**
    * Initializes the underlying CaptionStream, SEI NAL parsing
    * and management, and caption collection
   **/


  this.init = function (options) {
    captionStream = new CaptionStream();
    isInitialized = true;
    parsingPartial = options ? options.isPartial : false; // Collect dispatched captions

    captionStream.on('data', function (event) {
      // Convert to seconds in the source's timescale
      event.startTime = event.startPts / timescale;
      event.endTime = event.endPts / timescale;
      parsedCaptions.captions.push(event);
      parsedCaptions.captionStreams[event.stream] = true;
    });
    captionStream.on('log', function (log) {
      parsedCaptions.logs.push(log);
    });
  };
  /**
    * Determines if a new video track will be selected
    * or if the timescale changed
    * @return {Boolean}
   **/


  this.isNewInit = function (videoTrackIds, timescales) {
    if (videoTrackIds && videoTrackIds.length === 0 || timescales && typeof timescales === 'object' && Object.keys(timescales).length === 0) {
      return false;
    }

    return trackId !== videoTrackIds[0] || timescale !== timescales[trackId];
  };
  /**
    * Parses out SEI captions and interacts with underlying
    * CaptionStream to return dispatched captions
    *
    * @param {Uint8Array} segment - The fmp4 segment containing embedded captions
    * @param {Number[]} videoTrackIds - A list of video tracks found in the init segment
    * @param {Object.<Number, Number>} timescales - The timescales found in the init segment
    * @see parseEmbeddedCaptions
    * @see m2ts/caption-stream.js
   **/


  this.parse = function (segment, videoTrackIds, timescales) {
    var parsedData;

    if (!this.isInitialized()) {
      return null; // This is not likely to be a video segment
    } else if (!videoTrackIds || !timescales) {
      return null;
    } else if (this.isNewInit(videoTrackIds, timescales)) {
      // Use the first video track only as there is no
      // mechanism to switch to other video tracks
      trackId = videoTrackIds[0];
      timescale = timescales[trackId]; // If an init segment has not been seen yet, hold onto segment
      // data until we have one.
      // the ISO-BMFF spec says that trackId can't be zero, but there's some broken content out there
    } else if (trackId === null || !timescale) {
      segmentCache.push(segment);
      return null;
    } // Now that a timescale and trackId is set, parse cached segments


    while (segmentCache.length > 0) {
      var cachedSegment = segmentCache.shift();
      this.parse(cachedSegment, videoTrackIds, timescales);
    }

    parsedData = parseEmbeddedCaptions(segment, trackId, timescale);

    if (parsedData && parsedData.logs) {
      parsedCaptions.logs = parsedCaptions.logs.concat(parsedData.logs);
    }

    if (parsedData === null || !parsedData.seiNals) {
      if (parsedCaptions.logs.length) {
        return {
          logs: parsedCaptions.logs,
          captions: [],
          captionStreams: []
        };
      }

      return null;
    }

    this.pushNals(parsedData.seiNals); // Force the parsed captions to be dispatched

    this.flushStream();
    return parsedCaptions;
  };
  /**
    * Pushes SEI NALUs onto CaptionStream
    * @param {Object[]} nals - A list of SEI nals parsed using `parseCaptionNals`
    * Assumes that `parseCaptionNals` has been called first
    * @see m2ts/caption-stream.js
    **/


  this.pushNals = function (nals) {
    if (!this.isInitialized() || !nals || nals.length === 0) {
      return null;
    }

    nals.forEach(function (nal) {
      captionStream.push(nal);
    });
  };
  /**
    * Flushes underlying CaptionStream to dispatch processed, displayable captions
    * @see m2ts/caption-stream.js
   **/


  this.flushStream = function () {
    if (!this.isInitialized()) {
      return null;
    }

    if (!parsingPartial) {
      captionStream.flush();
    } else {
      captionStream.partialFlush();
    }
  };
  /**
    * Reset caption buckets for new data
   **/


  this.clearParsedCaptions = function () {
    parsedCaptions.captions = [];
    parsedCaptions.captionStreams = {};
    parsedCaptions.logs = [];
  };
  /**
    * Resets underlying CaptionStream
    * @see m2ts/caption-stream.js
   **/


  this.resetCaptionStream = function () {
    if (!this.isInitialized()) {
      return null;
    }

    captionStream.reset();
  };
  /**
    * Convenience method to clear all captions flushed from the
    * CaptionStream and still being parsed
    * @see m2ts/caption-stream.js
   **/


  this.clearAllCaptions = function () {
    this.clearParsedCaptions();
    this.resetCaptionStream();
  };
  /**
    * Reset caption parser
   **/


  this.reset = function () {
    segmentCache = [];
    trackId = null;
    timescale = null;

    if (!parsedCaptions) {
      parsedCaptions = {
        captions: [],
        // CC1, CC2, CC3, CC4
        captionStreams: {},
        logs: []
      };
    } else {
      this.clearParsedCaptions();
    }

    this.resetCaptionStream();
  };

  this.reset();
};

module.exports = CaptionParser;