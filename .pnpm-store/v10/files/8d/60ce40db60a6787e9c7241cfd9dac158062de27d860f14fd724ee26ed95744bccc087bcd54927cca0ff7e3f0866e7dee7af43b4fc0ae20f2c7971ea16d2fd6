/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * A stream-based aac to mp4 converter. This utility can be used to
 * deliver mp4s to a SourceBuffer on platforms that support native
 * Media Source Extensions.
 */
'use strict';

var Stream = require('../utils/stream.js');

var aacUtils = require('./utils'); // Constants


var _AacStream;
/**
 * Splits an incoming stream of binary data into ADTS and ID3 Frames.
 */


_AacStream = function AacStream() {
  var everything = new Uint8Array(),
      timeStamp = 0;

  _AacStream.prototype.init.call(this);

  this.setTimestamp = function (timestamp) {
    timeStamp = timestamp;
  };

  this.push = function (bytes) {
    var frameSize = 0,
        byteIndex = 0,
        bytesLeft,
        chunk,
        packet,
        tempLength; // If there are bytes remaining from the last segment, prepend them to the
    // bytes that were pushed in

    if (everything.length) {
      tempLength = everything.length;
      everything = new Uint8Array(bytes.byteLength + tempLength);
      everything.set(everything.subarray(0, tempLength));
      everything.set(bytes, tempLength);
    } else {
      everything = bytes;
    }

    while (everything.length - byteIndex >= 3) {
      if (everything[byteIndex] === 'I'.charCodeAt(0) && everything[byteIndex + 1] === 'D'.charCodeAt(0) && everything[byteIndex + 2] === '3'.charCodeAt(0)) {
        // Exit early because we don't have enough to parse
        // the ID3 tag header
        if (everything.length - byteIndex < 10) {
          break;
        } // check framesize


        frameSize = aacUtils.parseId3TagSize(everything, byteIndex); // Exit early if we don't have enough in the buffer
        // to emit a full packet
        // Add to byteIndex to support multiple ID3 tags in sequence

        if (byteIndex + frameSize > everything.length) {
          break;
        }

        chunk = {
          type: 'timed-metadata',
          data: everything.subarray(byteIndex, byteIndex + frameSize)
        };
        this.trigger('data', chunk);
        byteIndex += frameSize;
        continue;
      } else if ((everything[byteIndex] & 0xff) === 0xff && (everything[byteIndex + 1] & 0xf0) === 0xf0) {
        // Exit early because we don't have enough to parse
        // the ADTS frame header
        if (everything.length - byteIndex < 7) {
          break;
        }

        frameSize = aacUtils.parseAdtsSize(everything, byteIndex); // Exit early if we don't have enough in the buffer
        // to emit a full packet

        if (byteIndex + frameSize > everything.length) {
          break;
        }

        packet = {
          type: 'audio',
          data: everything.subarray(byteIndex, byteIndex + frameSize),
          pts: timeStamp,
          dts: timeStamp
        };
        this.trigger('data', packet);
        byteIndex += frameSize;
        continue;
      }

      byteIndex++;
    }

    bytesLeft = everything.length - byteIndex;

    if (bytesLeft > 0) {
      everything = everything.subarray(byteIndex);
    } else {
      everything = new Uint8Array();
    }
  };

  this.reset = function () {
    everything = new Uint8Array();
    this.trigger('reset');
  };

  this.endTimeline = function () {
    everything = new Uint8Array();
    this.trigger('endedtimeline');
  };
};

_AacStream.prototype = new Stream();
module.exports = _AacStream;