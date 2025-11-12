/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * Utilities to detect basic properties and metadata about Aac data.
 */
'use strict';

var ADTS_SAMPLING_FREQUENCIES = [
  96000,
  88200,
  64000,
  48000,
  44100,
  32000,
  24000,
  22050,
  16000,
  12000,
  11025,
  8000,
  7350
];

var parseId3TagSize = function(header, byteIndex) {
  var
    returnSize = (header[byteIndex + 6] << 21) |
                 (header[byteIndex + 7] << 14) |
                 (header[byteIndex + 8] << 7) |
                 (header[byteIndex + 9]),
    flags = header[byteIndex + 5],
    footerPresent = (flags & 16) >> 4;

  // if we get a negative returnSize clamp it to 0
  returnSize = returnSize >= 0 ? returnSize : 0;

  if (footerPresent) {
    return returnSize + 20;
  }
  return returnSize + 10;
};

var getId3Offset = function(data, offset) {
  if (data.length - offset < 10 ||
      data[offset] !== 'I'.charCodeAt(0) ||
      data[offset + 1] !== 'D'.charCodeAt(0) ||
      data[offset + 2] !== '3'.charCodeAt(0)) {
    return offset;
  }

  offset += parseId3TagSize(data, offset);

  return getId3Offset(data, offset);
};


// TODO: use vhs-utils
var isLikelyAacData = function(data) {
  var offset = getId3Offset(data, 0);

  return data.length >= offset + 2 &&
    (data[offset] & 0xFF) === 0xFF &&
    (data[offset + 1] & 0xF0) === 0xF0 &&
    // verify that the 2 layer bits are 0, aka this
    // is not mp3 data but aac data.
    (data[offset + 1] & 0x16) === 0x10;
};

var parseSyncSafeInteger = function(data) {
  return (data[0] << 21) |
          (data[1] << 14) |
          (data[2] << 7) |
          (data[3]);
};

// return a percent-encoded representation of the specified byte range
// @see http://en.wikipedia.org/wiki/Percent-encoding
var percentEncode = function(bytes, start, end) {
  var i, result = '';
  for (i = start; i < end; i++) {
    result += '%' + ('00' + bytes[i].toString(16)).slice(-2);
  }
  return result;
};

// return the string representation of the specified byte range,
// interpreted as ISO-8859-1.
var parseIso88591 = function(bytes, start, end) {
  return unescape(percentEncode(bytes, start, end)); // jshint ignore:line
};

var parseAdtsSize = function(header, byteIndex) {
  var
    lowThree = (header[byteIndex + 5] & 0xE0) >> 5,
    middle = header[byteIndex + 4] << 3,
    highTwo = header[byteIndex + 3] & 0x3 << 11;

  return (highTwo | middle) | lowThree;
};

var parseType = function(header, byteIndex) {
  if ((header[byteIndex] === 'I'.charCodeAt(0)) &&
      (header[byteIndex + 1] === 'D'.charCodeAt(0)) &&
      (header[byteIndex + 2] === '3'.charCodeAt(0))) {
    return 'timed-metadata';
  } else if ((header[byteIndex] & 0xff === 0xff) &&
             ((header[byteIndex + 1] & 0xf0) === 0xf0)) {
    return 'audio';
  }
  return null;
};

var parseSampleRate = function(packet) {
  var i = 0;

  while (i + 5 < packet.length) {
    if (packet[i] !== 0xFF || (packet[i + 1] & 0xF6) !== 0xF0) {
      // If a valid header was not found,  jump one forward and attempt to
      // find a valid ADTS header starting at the next byte
      i++;
      continue;
    }
    return ADTS_SAMPLING_FREQUENCIES[(packet[i + 2] & 0x3c) >>> 2];
  }

  return null;
};

var parseAacTimestamp = function(packet) {
  var frameStart, frameSize, frame, frameHeader;

  // find the start of the first frame and the end of the tag
  frameStart = 10;
  if (packet[5] & 0x40) {
    // advance the frame start past the extended header
    frameStart += 4; // header size field
    frameStart += parseSyncSafeInteger(packet.subarray(10, 14));
  }

  // parse one or more ID3 frames
  // http://id3.org/id3v2.3.0#ID3v2_frame_overview
  do {
    // determine the number of bytes in this frame
    frameSize = parseSyncSafeInteger(packet.subarray(frameStart + 4, frameStart + 8));
    if (frameSize < 1) {
      return null;
    }
    frameHeader = String.fromCharCode(packet[frameStart],
                                      packet[frameStart + 1],
                                      packet[frameStart + 2],
                                      packet[frameStart + 3]);

    if (frameHeader === 'PRIV') {
      frame = packet.subarray(frameStart + 10, frameStart + frameSize + 10);

      for (var i = 0; i < frame.byteLength; i++) {
        if (frame[i] === 0) {
          var owner = parseIso88591(frame, 0, i);
          if (owner === 'com.apple.streaming.transportStreamTimestamp') {
            var d = frame.subarray(i + 1);
            var size = ((d[3] & 0x01)  << 30) |
                       (d[4]  << 22) |
                       (d[5] << 14) |
                       (d[6] << 6) |
                       (d[7] >>> 2);
            size *= 4;
            size += d[7] & 0x03;

            return size;
          }
          break;
        }
      }
    }

    frameStart += 10; // advance past the frame header
    frameStart += frameSize; // advance past the frame body
  } while (frameStart < packet.byteLength);
  return null;
};

module.exports = {
  isLikelyAacData: isLikelyAacData,
  parseId3TagSize: parseId3TagSize,
  parseAdtsSize: parseAdtsSize,
  parseType: parseType,
  parseSampleRate: parseSampleRate,
  parseAacTimestamp: parseAacTimestamp
};
