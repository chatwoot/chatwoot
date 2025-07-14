/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * Utilities to detect basic properties and metadata about MP4s.
 */
'use strict';

var toUnsigned = require('../utils/bin').toUnsigned;
var toHexString = require('../utils/bin').toHexString;
var findBox = require('../mp4/find-box.js');
var parseType = require('../mp4/parse-type.js');
var parseTfhd = require('../tools/parse-tfhd.js');
var parseTrun = require('../tools/parse-trun.js');
var parseTfdt = require('../tools/parse-tfdt.js');
var getUint64 = require('../utils/numbers.js').getUint64;
var timescale, startTime, compositionStartTime, getVideoTrackIds, getTracks,
  getTimescaleFromMediaHeader;
var window = require('global/window');


/**
 * Parses an MP4 initialization segment and extracts the timescale
 * values for any declared tracks. Timescale values indicate the
 * number of clock ticks per second to assume for time-based values
 * elsewhere in the MP4.
 *
 * To determine the start time of an MP4, you need two pieces of
 * information: the timescale unit and the earliest base media decode
 * time. Multiple timescales can be specified within an MP4 but the
 * base media decode time is always expressed in the timescale from
 * the media header box for the track:
 * ```
 * moov > trak > mdia > mdhd.timescale
 * ```
 * @param init {Uint8Array} the bytes of the init segment
 * @return {object} a hash of track ids to timescale values or null if
 * the init segment is malformed.
 */
timescale = function(init) {
  var
    result = {},
    traks = findBox(init, ['moov', 'trak']);

  // mdhd timescale
  return traks.reduce(function(result, trak) {
    var tkhd, version, index, id, mdhd;

    tkhd = findBox(trak, ['tkhd'])[0];
    if (!tkhd) {
      return null;
    }
    version = tkhd[0];
    index = version === 0 ? 12 : 20;
    id = toUnsigned(tkhd[index]     << 24 |
                    tkhd[index + 1] << 16 |
                    tkhd[index + 2] <<  8 |
                    tkhd[index + 3]);

    mdhd = findBox(trak, ['mdia', 'mdhd'])[0];
    if (!mdhd) {
      return null;
    }
    version = mdhd[0];
    index = version === 0 ? 12 : 20;
    result[id] = toUnsigned(mdhd[index]     << 24 |
                            mdhd[index + 1] << 16 |
                            mdhd[index + 2] <<  8 |
                            mdhd[index + 3]);
    return result;
  }, result);
};

/**
 * Determine the base media decode start time, in seconds, for an MP4
 * fragment. If multiple fragments are specified, the earliest time is
 * returned.
 *
 * The base media decode time can be parsed from track fragment
 * metadata:
 * ```
 * moof > traf > tfdt.baseMediaDecodeTime
 * ```
 * It requires the timescale value from the mdhd to interpret.
 *
 * @param timescale {object} a hash of track ids to timescale values.
 * @return {number} the earliest base media decode start time for the
 * fragment, in seconds
 */
startTime = function(timescale, fragment) {
  var trafs, result;

  // we need info from two childrend of each track fragment box
  trafs = findBox(fragment, ['moof', 'traf']);

  // determine the start times for each track
  var lowestTime = trafs.reduce(function(acc, traf) {
    var tfhd = findBox(traf, ['tfhd'])[0];

    // get the track id from the tfhd
    var id = toUnsigned(tfhd[4] << 24 |
      tfhd[5] << 16 |
      tfhd[6] <<  8 |
      tfhd[7]);
    // assume a 90kHz clock if no timescale was specified
    var scale = timescale[id] || 90e3;

    // get the base media decode time from the tfdt
    var tfdt = findBox(traf, ['tfdt'])[0];
    var dv = new DataView(tfdt.buffer, tfdt.byteOffset, tfdt.byteLength);
    var baseTime;

    // version 1 is 64 bit
    if (tfdt[0] === 1) {
      baseTime = getUint64(tfdt.subarray(4, 12));
    } else {
      baseTime = dv.getUint32(4);
    }

    // convert base time to seconds if it is a valid number.
    let seconds;
    if (typeof baseTime === 'bigint') {
      seconds = baseTime / window.BigInt(scale);
    } else if (typeof baseTime === 'number' && !isNaN(baseTime)) {
      seconds = baseTime / scale;
    }

    if (seconds < Number.MAX_SAFE_INTEGER) {
      seconds = Number(seconds);
    }

    if (seconds < acc)  {
      acc = seconds;
    }

    return acc;
  }, Infinity);

  return typeof lowestTime === 'bigint' || isFinite(lowestTime) ? lowestTime : 0;
};

/**
 * Determine the composition start, in seconds, for an MP4
 * fragment.
 *
 * The composition start time of a fragment can be calculated using the base
 * media decode time, composition time offset, and timescale, as follows:
 *
 * compositionStartTime = (baseMediaDecodeTime + compositionTimeOffset) / timescale
 *
 * All of the aforementioned information is contained within a media fragment's
 * `traf` box, except for timescale info, which comes from the initialization
 * segment, so a track id (also contained within a `traf`) is also necessary to
 * associate it with a timescale
 *
 *
 * @param timescales {object} - a hash of track ids to timescale values.
 * @param fragment {Unit8Array} - the bytes of a media segment
 * @return {number} the composition start time for the fragment, in seconds
 **/
compositionStartTime = function(timescales, fragment) {
  var trafBoxes = findBox(fragment, ['moof', 'traf']);
  var baseMediaDecodeTime = 0;
  var compositionTimeOffset = 0;
  var trackId;

  if (trafBoxes && trafBoxes.length) {
    // The spec states that track run samples contained within a `traf` box are contiguous, but
    // it does not explicitly state whether the `traf` boxes themselves are contiguous.
    // We will assume that they are, so we only need the first to calculate start time.
    var tfhd = findBox(trafBoxes[0], ['tfhd'])[0];
    var trun = findBox(trafBoxes[0], ['trun'])[0];
    var tfdt = findBox(trafBoxes[0], ['tfdt'])[0];

    if (tfhd) {
      var parsedTfhd = parseTfhd(tfhd);

      trackId = parsedTfhd.trackId;
    }

    if (tfdt) {
      var parsedTfdt = parseTfdt(tfdt);

      baseMediaDecodeTime = parsedTfdt.baseMediaDecodeTime;
    }

    if (trun) {
      var parsedTrun = parseTrun(trun);

      if (parsedTrun.samples && parsedTrun.samples.length) {
        compositionTimeOffset = parsedTrun.samples[0].compositionTimeOffset || 0;
      }
    }
  }

  // Get timescale for this specific track. Assume a 90kHz clock if no timescale was
  // specified.
  var timescale = timescales[trackId] || 90e3;

  // return the composition start time, in seconds
  if (typeof baseMediaDecodeTime === 'bigint') {
    compositionTimeOffset = window.BigInt(compositionTimeOffset);
    timescale = window.BigInt(timescale);
  }

  var result = (baseMediaDecodeTime + compositionTimeOffset) / timescale;

  if (typeof result === 'bigint' && result < Number.MAX_SAFE_INTEGER) {
    result = Number(result);
  }

  return result;
};

/**
  * Find the trackIds of the video tracks in this source.
  * Found by parsing the Handler Reference and Track Header Boxes:
  *   moov > trak > mdia > hdlr
  *   moov > trak > tkhd
  *
  * @param {Uint8Array} init - The bytes of the init segment for this source
  * @return {Number[]} A list of trackIds
  *
  * @see ISO-BMFF-12/2015, Section 8.4.3
 **/
getVideoTrackIds = function(init) {
  var traks = findBox(init, ['moov', 'trak']);
  var videoTrackIds = [];

  traks.forEach(function(trak) {
    var hdlrs = findBox(trak, ['mdia', 'hdlr']);
    var tkhds = findBox(trak, ['tkhd']);

    hdlrs.forEach(function(hdlr, index) {
      var handlerType = parseType(hdlr.subarray(8, 12));
      var tkhd = tkhds[index];
      var view;
      var version;
      var trackId;

      if (handlerType === 'vide') {
        view = new DataView(tkhd.buffer, tkhd.byteOffset, tkhd.byteLength);
        version = view.getUint8(0);
        trackId = (version === 0) ? view.getUint32(12) : view.getUint32(20);

        videoTrackIds.push(trackId);
      }
    });
  });

  return videoTrackIds;
};

getTimescaleFromMediaHeader = function(mdhd) {
  // mdhd is a FullBox, meaning it will have its own version as the first byte
  var version = mdhd[0];
  var index = version === 0 ? 12 : 20;

  return toUnsigned(
    mdhd[index]     << 24 |
    mdhd[index + 1] << 16 |
    mdhd[index + 2] <<  8 |
    mdhd[index + 3]
  );
};

/**
 * Get all the video, audio, and hint tracks from a non fragmented
 * mp4 segment
 */
getTracks = function(init) {
  var traks = findBox(init, ['moov', 'trak']);
  var tracks = [];

  traks.forEach(function(trak) {
    var track = {};
    var tkhd = findBox(trak, ['tkhd'])[0];
    var view, tkhdVersion;

    // id
    if (tkhd) {
      view = new DataView(tkhd.buffer, tkhd.byteOffset, tkhd.byteLength);
      tkhdVersion = view.getUint8(0);

      track.id = (tkhdVersion === 0) ? view.getUint32(12) : view.getUint32(20);
    }

    var hdlr = findBox(trak, ['mdia', 'hdlr'])[0];

    // type
    if (hdlr) {
      var type = parseType(hdlr.subarray(8, 12));

      if (type === 'vide') {
        track.type = 'video';
      } else if (type === 'soun') {
        track.type = 'audio';
      } else {
        track.type = type;
      }
    }


    // codec
    var stsd = findBox(trak, ['mdia', 'minf', 'stbl', 'stsd'])[0];

    if (stsd) {
      var sampleDescriptions = stsd.subarray(8);
      // gives the codec type string
      track.codec = parseType(sampleDescriptions.subarray(4, 8));

      var codecBox = findBox(sampleDescriptions, [track.codec])[0];
      var codecConfig, codecConfigType;

      if (codecBox) {
        // https://tools.ietf.org/html/rfc6381#section-3.3
        if ((/^[asm]vc[1-9]$/i).test(track.codec)) {
          // we don't need anything but the "config" parameter of the
          // avc1 codecBox
          codecConfig = codecBox.subarray(78);
          codecConfigType = parseType(codecConfig.subarray(4, 8));

          if (codecConfigType === 'avcC' && codecConfig.length > 11) {
            track.codec += '.';

            // left padded with zeroes for single digit hex
            // profile idc
            track.codec +=  toHexString(codecConfig[9]);
            // the byte containing the constraint_set flags
            track.codec += toHexString(codecConfig[10]);
            // level idc
            track.codec += toHexString(codecConfig[11]);
          } else {
            // TODO: show a warning that we couldn't parse the codec
            // and are using the default
            track.codec = 'avc1.4d400d';
          }
        } else if ((/^mp4[a,v]$/i).test(track.codec)) {
          // we do not need anything but the streamDescriptor of the mp4a codecBox
          codecConfig = codecBox.subarray(28);
          codecConfigType = parseType(codecConfig.subarray(4, 8));

          if (codecConfigType === 'esds' && codecConfig.length > 20 && codecConfig[19] !== 0) {
            track.codec += '.' + toHexString(codecConfig[19]);
            // this value is only a single digit
            track.codec += '.' + toHexString((codecConfig[20] >>> 2) & 0x3f).replace(/^0/, '');
          } else {
            // TODO: show a warning that we couldn't parse the codec
            // and are using the default
            track.codec = 'mp4a.40.2';
          }
        } else {
          // flac, opus, etc
          track.codec = track.codec.toLowerCase();
        }
      }
    }

    var mdhd = findBox(trak, ['mdia', 'mdhd'])[0];

    if (mdhd) {
      track.timescale = getTimescaleFromMediaHeader(mdhd);
    }

    tracks.push(track);
  });

  return tracks;
};

module.exports = {
  // export mp4 inspector's findBox and parseType for backwards compatibility
  findBox: findBox,
  parseType: parseType,
  timescale: timescale,
  startTime: startTime,
  compositionStartTime: compositionStartTime,
  videoTrackIds: getVideoTrackIds,
  tracks: getTracks,
  getTimescaleFromMediaHeader: getTimescaleFromMediaHeader
};
