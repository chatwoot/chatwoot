/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
'use strict';

var Stream = require('../utils/stream.js');
var ONE_SECOND_IN_TS = require('../utils/clock').ONE_SECOND_IN_TS;

var AdtsStream;

var
  ADTS_SAMPLING_FREQUENCIES = [
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

/*
 * Accepts a ElementaryStream and emits data events with parsed
 * AAC Audio Frames of the individual packets. Input audio in ADTS
 * format is unpacked and re-emitted as AAC frames.
 *
 * @see http://wiki.multimedia.cx/index.php?title=ADTS
 * @see http://wiki.multimedia.cx/?title=Understanding_AAC
 */
AdtsStream = function(handlePartialSegments) {
  var
    buffer,
    frameNum = 0;

  AdtsStream.prototype.init.call(this);

  this.skipWarn_ = function(start, end) {
    this.trigger('log', {
      level: 'warn',
      message: `adts skiping bytes ${start} to ${end} in frame ${frameNum} outside syncword`
    });
  };

  this.push = function(packet) {
    var
      i = 0,
      frameLength,
      protectionSkipBytes,
      frameEnd,
      oldBuffer,
      sampleCount,
      adtsFrameDuration;

    if (!handlePartialSegments) {
      frameNum = 0;
    }

    if (packet.type !== 'audio') {
      // ignore non-audio data
      return;
    }

    // Prepend any data in the buffer to the input data so that we can parse
    // aac frames the cross a PES packet boundary
    if (buffer && buffer.length) {
      oldBuffer = buffer;
      buffer = new Uint8Array(oldBuffer.byteLength + packet.data.byteLength);
      buffer.set(oldBuffer);
      buffer.set(packet.data, oldBuffer.byteLength);
    } else {
      buffer = packet.data;
    }

    // unpack any ADTS frames which have been fully received
    // for details on the ADTS header, see http://wiki.multimedia.cx/index.php?title=ADTS
    var skip;

    // We use i + 7 here because we want to be able to parse the entire header.
    // If we don't have enough bytes to do that, then we definitely won't have a full frame.
    while ((i + 7) < buffer.length) {
      // Look for the start of an ADTS header..
      if ((buffer[i] !== 0xFF) || (buffer[i + 1] & 0xF6) !== 0xF0) {
        if (typeof skip !== 'number') {
          skip = i;
        }
        // If a valid header was not found,  jump one forward and attempt to
        // find a valid ADTS header starting at the next byte
        i++;
        continue;
      }

      if (typeof skip === 'number') {
        this.skipWarn_(skip, i);
        skip = null;
      }

      // The protection skip bit tells us if we have 2 bytes of CRC data at the
      // end of the ADTS header
      protectionSkipBytes = (~buffer[i + 1] & 0x01) * 2;

      // Frame length is a 13 bit integer starting 16 bits from the
      // end of the sync sequence
      // NOTE: frame length includes the size of the header
      frameLength = ((buffer[i + 3] & 0x03) << 11) |
        (buffer[i + 4] << 3) |
        ((buffer[i + 5] & 0xe0) >> 5);

      sampleCount = ((buffer[i + 6] & 0x03) + 1) * 1024;
      adtsFrameDuration = (sampleCount * ONE_SECOND_IN_TS) /
        ADTS_SAMPLING_FREQUENCIES[(buffer[i + 2] & 0x3c) >>> 2];

      // If we don't have enough data to actually finish this ADTS frame,
      // then we have to wait for more data
      if ((buffer.byteLength - i) < frameLength) {
        break;
      }

      // Otherwise, deliver the complete AAC frame
      this.trigger('data', {
        pts: packet.pts + (frameNum * adtsFrameDuration),
        dts: packet.dts + (frameNum * adtsFrameDuration),
        sampleCount: sampleCount,
        audioobjecttype: ((buffer[i + 2] >>> 6) & 0x03) + 1,
        channelcount: ((buffer[i + 2] & 1) << 2) |
          ((buffer[i + 3] & 0xc0) >>> 6),
        samplerate: ADTS_SAMPLING_FREQUENCIES[(buffer[i + 2] & 0x3c) >>> 2],
        samplingfrequencyindex: (buffer[i + 2] & 0x3c) >>> 2,
        // assume ISO/IEC 14496-12 AudioSampleEntry default of 16
        samplesize: 16,
        // data is the frame without it's header
        data: buffer.subarray(i + 7 + protectionSkipBytes, i + frameLength)
      });

      frameNum++;
      i += frameLength;
    }

    if (typeof skip === 'number') {
      this.skipWarn_(skip, i);
      skip = null;
    }

    // remove processed bytes from the buffer.
    buffer = buffer.subarray(i);
  };

  this.flush = function() {
    frameNum = 0;
    this.trigger('done');
  };

  this.reset = function() {
    buffer = void 0;
    this.trigger('reset');
  };

  this.endTimeline = function() {
    buffer = void 0;
    this.trigger('endedtimeline');
  };
};

AdtsStream.prototype = new Stream();

module.exports = AdtsStream;
