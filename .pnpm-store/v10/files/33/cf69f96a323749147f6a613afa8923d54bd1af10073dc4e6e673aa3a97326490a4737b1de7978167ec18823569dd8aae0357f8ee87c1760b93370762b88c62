/*! @name mux.js @version 6.0.1 @license Apache-2.0 */
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('global/window')) :
  typeof define === 'function' && define.amd ? define(['global/window'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.muxjs = factory(global.window));
}(this, (function (window) { 'use strict';

  function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

  var window__default = /*#__PURE__*/_interopDefaultLegacy(window);

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   *
   * A lightweight readable stream implemention that handles event dispatching.
   * Objects that inherit from streams should call init in their constructors.
   */

  var Stream = function Stream() {
    this.init = function () {
      var listeners = {};
      /**
       * Add a listener for a specified event type.
       * @param type {string} the event name
       * @param listener {function} the callback to be invoked when an event of
       * the specified type occurs
       */

      this.on = function (type, listener) {
        if (!listeners[type]) {
          listeners[type] = [];
        }

        listeners[type] = listeners[type].concat(listener);
      };
      /**
       * Remove a listener for a specified event type.
       * @param type {string} the event name
       * @param listener {function} a function previously registered for this
       * type of event through `on`
       */


      this.off = function (type, listener) {
        var index;

        if (!listeners[type]) {
          return false;
        }

        index = listeners[type].indexOf(listener);
        listeners[type] = listeners[type].slice();
        listeners[type].splice(index, 1);
        return index > -1;
      };
      /**
       * Trigger an event of the specified type on this stream. Any additional
       * arguments to this function are passed as parameters to event listeners.
       * @param type {string} the event name
       */


      this.trigger = function (type) {
        var callbacks, i, length, args;
        callbacks = listeners[type];

        if (!callbacks) {
          return;
        } // Slicing the arguments on every invocation of this method
        // can add a significant amount of overhead. Avoid the
        // intermediate object creation for the common case of a
        // single callback argument


        if (arguments.length === 2) {
          length = callbacks.length;

          for (i = 0; i < length; ++i) {
            callbacks[i].call(this, arguments[1]);
          }
        } else {
          args = [];
          i = arguments.length;

          for (i = 1; i < arguments.length; ++i) {
            args.push(arguments[i]);
          }

          length = callbacks.length;

          for (i = 0; i < length; ++i) {
            callbacks[i].apply(this, args);
          }
        }
      };
      /**
       * Destroys the stream and cleans up.
       */


      this.dispose = function () {
        listeners = {};
      };
    };
  };
  /**
   * Forwards all `data` events on this stream to the destination stream. The
   * destination stream should provide a method `push` to receive the data
   * events as they arrive.
   * @param destination {stream} the stream that will receive all `data` events
   * @param autoFlush {boolean} if false, we will not call `flush` on the destination
   *                            when the current stream emits a 'done' event
   * @see http://nodejs.org/api/stream.html#stream_readable_pipe_destination_options
   */


  Stream.prototype.pipe = function (destination) {
    this.on('data', function (data) {
      destination.push(data);
    });
    this.on('done', function (flushSource) {
      destination.flush(flushSource);
    });
    this.on('partialdone', function (flushSource) {
      destination.partialFlush(flushSource);
    });
    this.on('endedtimeline', function (flushSource) {
      destination.endTimeline(flushSource);
    });
    this.on('reset', function (flushSource) {
      destination.reset(flushSource);
    });
    return destination;
  }; // Default stream functions that are expected to be overridden to perform
  // actual work. These are provided by the prototype as a sort of no-op
  // implementation so that we don't have to check for their existence in the
  // `pipe` function above.


  Stream.prototype.push = function (data) {
    this.trigger('data', data);
  };

  Stream.prototype.flush = function (flushSource) {
    this.trigger('done', flushSource);
  };

  Stream.prototype.partialFlush = function (flushSource) {
    this.trigger('partialdone', flushSource);
  };

  Stream.prototype.endTimeline = function (flushSource) {
    this.trigger('endedtimeline', flushSource);
  };

  Stream.prototype.reset = function (flushSource) {
    this.trigger('reset', flushSource);
  };

  var stream = Stream;

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */
  var ONE_SECOND_IN_TS$5 = 90000,
      // 90kHz clock
  secondsToVideoTs,
      secondsToAudioTs,
      videoTsToSeconds,
      audioTsToSeconds,
      audioTsToVideoTs,
      videoTsToAudioTs,
      metadataTsToSeconds;

  secondsToVideoTs = function secondsToVideoTs(seconds) {
    return seconds * ONE_SECOND_IN_TS$5;
  };

  secondsToAudioTs = function secondsToAudioTs(seconds, sampleRate) {
    return seconds * sampleRate;
  };

  videoTsToSeconds = function videoTsToSeconds(timestamp) {
    return timestamp / ONE_SECOND_IN_TS$5;
  };

  audioTsToSeconds = function audioTsToSeconds(timestamp, sampleRate) {
    return timestamp / sampleRate;
  };

  audioTsToVideoTs = function audioTsToVideoTs(timestamp, sampleRate) {
    return secondsToVideoTs(audioTsToSeconds(timestamp, sampleRate));
  };

  videoTsToAudioTs = function videoTsToAudioTs(timestamp, sampleRate) {
    return secondsToAudioTs(videoTsToSeconds(timestamp), sampleRate);
  };
  /**
   * Adjust ID3 tag or caption timing information by the timeline pts values
   * (if keepOriginalTimestamps is false) and convert to seconds
   */


  metadataTsToSeconds = function metadataTsToSeconds(timestamp, timelineStartPts, keepOriginalTimestamps) {
    return videoTsToSeconds(keepOriginalTimestamps ? timestamp : timestamp - timelineStartPts);
  };

  var clock = {
    ONE_SECOND_IN_TS: ONE_SECOND_IN_TS$5,
    secondsToVideoTs: secondsToVideoTs,
    secondsToAudioTs: secondsToAudioTs,
    videoTsToSeconds: videoTsToSeconds,
    audioTsToSeconds: audioTsToSeconds,
    audioTsToVideoTs: audioTsToVideoTs,
    videoTsToAudioTs: videoTsToAudioTs,
    metadataTsToSeconds: metadataTsToSeconds
  };

  var ONE_SECOND_IN_TS$4 = clock.ONE_SECOND_IN_TS;

  var _AdtsStream;

  var ADTS_SAMPLING_FREQUENCIES$1 = [96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350];
  /*
   * Accepts a ElementaryStream and emits data events with parsed
   * AAC Audio Frames of the individual packets. Input audio in ADTS
   * format is unpacked and re-emitted as AAC frames.
   *
   * @see http://wiki.multimedia.cx/index.php?title=ADTS
   * @see http://wiki.multimedia.cx/?title=Understanding_AAC
   */

  _AdtsStream = function AdtsStream(handlePartialSegments) {
    var buffer,
        frameNum = 0;

    _AdtsStream.prototype.init.call(this);

    this.skipWarn_ = function (start, end) {
      this.trigger('log', {
        level: 'warn',
        message: "adts skiping bytes " + start + " to " + end + " in frame " + frameNum + " outside syncword"
      });
    };

    this.push = function (packet) {
      var i = 0,
          frameLength,
          protectionSkipBytes,
          oldBuffer,
          sampleCount,
          adtsFrameDuration;

      if (!handlePartialSegments) {
        frameNum = 0;
      }

      if (packet.type !== 'audio') {
        // ignore non-audio data
        return;
      } // Prepend any data in the buffer to the input data so that we can parse
      // aac frames the cross a PES packet boundary


      if (buffer && buffer.length) {
        oldBuffer = buffer;
        buffer = new Uint8Array(oldBuffer.byteLength + packet.data.byteLength);
        buffer.set(oldBuffer);
        buffer.set(packet.data, oldBuffer.byteLength);
      } else {
        buffer = packet.data;
      } // unpack any ADTS frames which have been fully received
      // for details on the ADTS header, see http://wiki.multimedia.cx/index.php?title=ADTS


      var skip; // We use i + 7 here because we want to be able to parse the entire header.
      // If we don't have enough bytes to do that, then we definitely won't have a full frame.

      while (i + 7 < buffer.length) {
        // Look for the start of an ADTS header..
        if (buffer[i] !== 0xFF || (buffer[i + 1] & 0xF6) !== 0xF0) {
          if (typeof skip !== 'number') {
            skip = i;
          } // If a valid header was not found,  jump one forward and attempt to
          // find a valid ADTS header starting at the next byte


          i++;
          continue;
        }

        if (typeof skip === 'number') {
          this.skipWarn_(skip, i);
          skip = null;
        } // The protection skip bit tells us if we have 2 bytes of CRC data at the
        // end of the ADTS header


        protectionSkipBytes = (~buffer[i + 1] & 0x01) * 2; // Frame length is a 13 bit integer starting 16 bits from the
        // end of the sync sequence
        // NOTE: frame length includes the size of the header

        frameLength = (buffer[i + 3] & 0x03) << 11 | buffer[i + 4] << 3 | (buffer[i + 5] & 0xe0) >> 5;
        sampleCount = ((buffer[i + 6] & 0x03) + 1) * 1024;
        adtsFrameDuration = sampleCount * ONE_SECOND_IN_TS$4 / ADTS_SAMPLING_FREQUENCIES$1[(buffer[i + 2] & 0x3c) >>> 2]; // If we don't have enough data to actually finish this ADTS frame,
        // then we have to wait for more data

        if (buffer.byteLength - i < frameLength) {
          break;
        } // Otherwise, deliver the complete AAC frame


        this.trigger('data', {
          pts: packet.pts + frameNum * adtsFrameDuration,
          dts: packet.dts + frameNum * adtsFrameDuration,
          sampleCount: sampleCount,
          audioobjecttype: (buffer[i + 2] >>> 6 & 0x03) + 1,
          channelcount: (buffer[i + 2] & 1) << 2 | (buffer[i + 3] & 0xc0) >>> 6,
          samplerate: ADTS_SAMPLING_FREQUENCIES$1[(buffer[i + 2] & 0x3c) >>> 2],
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
      } // remove processed bytes from the buffer.


      buffer = buffer.subarray(i);
    };

    this.flush = function () {
      frameNum = 0;
      this.trigger('done');
    };

    this.reset = function () {
      buffer = void 0;
      this.trigger('reset');
    };

    this.endTimeline = function () {
      buffer = void 0;
      this.trigger('endedtimeline');
    };
  };

  _AdtsStream.prototype = new stream();
  var adts = _AdtsStream;

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var ExpGolomb;
  /**
   * Parser for exponential Golomb codes, a variable-bitwidth number encoding
   * scheme used by h264.
   */

  ExpGolomb = function ExpGolomb(workingData) {
    var // the number of bytes left to examine in workingData
    workingBytesAvailable = workingData.byteLength,
        // the current word being examined
    workingWord = 0,
        // :uint
    // the number of bits left to examine in the current word
    workingBitsAvailable = 0; // :uint;
    // ():uint

    this.length = function () {
      return 8 * workingBytesAvailable;
    }; // ():uint


    this.bitsAvailable = function () {
      return 8 * workingBytesAvailable + workingBitsAvailable;
    }; // ():void


    this.loadWord = function () {
      var position = workingData.byteLength - workingBytesAvailable,
          workingBytes = new Uint8Array(4),
          availableBytes = Math.min(4, workingBytesAvailable);

      if (availableBytes === 0) {
        throw new Error('no bytes available');
      }

      workingBytes.set(workingData.subarray(position, position + availableBytes));
      workingWord = new DataView(workingBytes.buffer).getUint32(0); // track the amount of workingData that has been processed

      workingBitsAvailable = availableBytes * 8;
      workingBytesAvailable -= availableBytes;
    }; // (count:int):void


    this.skipBits = function (count) {
      var skipBytes; // :int

      if (workingBitsAvailable > count) {
        workingWord <<= count;
        workingBitsAvailable -= count;
      } else {
        count -= workingBitsAvailable;
        skipBytes = Math.floor(count / 8);
        count -= skipBytes * 8;
        workingBytesAvailable -= skipBytes;
        this.loadWord();
        workingWord <<= count;
        workingBitsAvailable -= count;
      }
    }; // (size:int):uint


    this.readBits = function (size) {
      var bits = Math.min(workingBitsAvailable, size),
          // :uint
      valu = workingWord >>> 32 - bits; // :uint
      // if size > 31, handle error

      workingBitsAvailable -= bits;

      if (workingBitsAvailable > 0) {
        workingWord <<= bits;
      } else if (workingBytesAvailable > 0) {
        this.loadWord();
      }

      bits = size - bits;

      if (bits > 0) {
        return valu << bits | this.readBits(bits);
      }

      return valu;
    }; // ():uint


    this.skipLeadingZeros = function () {
      var leadingZeroCount; // :uint

      for (leadingZeroCount = 0; leadingZeroCount < workingBitsAvailable; ++leadingZeroCount) {
        if ((workingWord & 0x80000000 >>> leadingZeroCount) !== 0) {
          // the first bit of working word is 1
          workingWord <<= leadingZeroCount;
          workingBitsAvailable -= leadingZeroCount;
          return leadingZeroCount;
        }
      } // we exhausted workingWord and still have not found a 1


      this.loadWord();
      return leadingZeroCount + this.skipLeadingZeros();
    }; // ():void


    this.skipUnsignedExpGolomb = function () {
      this.skipBits(1 + this.skipLeadingZeros());
    }; // ():void


    this.skipExpGolomb = function () {
      this.skipBits(1 + this.skipLeadingZeros());
    }; // ():uint


    this.readUnsignedExpGolomb = function () {
      var clz = this.skipLeadingZeros(); // :uint

      return this.readBits(clz + 1) - 1;
    }; // ():int


    this.readExpGolomb = function () {
      var valu = this.readUnsignedExpGolomb(); // :int

      if (0x01 & valu) {
        // the number is odd if the low order bit is set
        return 1 + valu >>> 1; // add 1 to make it even, and divide by 2
      }

      return -1 * (valu >>> 1); // divide by two then make it negative
    }; // Some convenience functions
    // :Boolean


    this.readBoolean = function () {
      return this.readBits(1) === 1;
    }; // ():int


    this.readUnsignedByte = function () {
      return this.readBits(8);
    };

    this.loadWord();
  };

  var expGolomb = ExpGolomb;

  var _H264Stream, _NalByteStream;

  var PROFILES_WITH_OPTIONAL_SPS_DATA;
  /**
   * Accepts a NAL unit byte stream and unpacks the embedded NAL units.
   */

  _NalByteStream = function NalByteStream() {
    var syncPoint = 0,
        i,
        buffer;

    _NalByteStream.prototype.init.call(this);
    /*
     * Scans a byte stream and triggers a data event with the NAL units found.
     * @param {Object} data Event received from H264Stream
     * @param {Uint8Array} data.data The h264 byte stream to be scanned
     *
     * @see H264Stream.push
     */


    this.push = function (data) {
      var swapBuffer;

      if (!buffer) {
        buffer = data.data;
      } else {
        swapBuffer = new Uint8Array(buffer.byteLength + data.data.byteLength);
        swapBuffer.set(buffer);
        swapBuffer.set(data.data, buffer.byteLength);
        buffer = swapBuffer;
      }

      var len = buffer.byteLength; // Rec. ITU-T H.264, Annex B
      // scan for NAL unit boundaries
      // a match looks like this:
      // 0 0 1 .. NAL .. 0 0 1
      // ^ sync point        ^ i
      // or this:
      // 0 0 1 .. NAL .. 0 0 0
      // ^ sync point        ^ i
      // advance the sync point to a NAL start, if necessary

      for (; syncPoint < len - 3; syncPoint++) {
        if (buffer[syncPoint + 2] === 1) {
          // the sync point is properly aligned
          i = syncPoint + 5;
          break;
        }
      }

      while (i < len) {
        // look at the current byte to determine if we've hit the end of
        // a NAL unit boundary
        switch (buffer[i]) {
          case 0:
            // skip past non-sync sequences
            if (buffer[i - 1] !== 0) {
              i += 2;
              break;
            } else if (buffer[i - 2] !== 0) {
              i++;
              break;
            } // deliver the NAL unit if it isn't empty


            if (syncPoint + 3 !== i - 2) {
              this.trigger('data', buffer.subarray(syncPoint + 3, i - 2));
            } // drop trailing zeroes


            do {
              i++;
            } while (buffer[i] !== 1 && i < len);

            syncPoint = i - 2;
            i += 3;
            break;

          case 1:
            // skip past non-sync sequences
            if (buffer[i - 1] !== 0 || buffer[i - 2] !== 0) {
              i += 3;
              break;
            } // deliver the NAL unit


            this.trigger('data', buffer.subarray(syncPoint + 3, i - 2));
            syncPoint = i - 2;
            i += 3;
            break;

          default:
            // the current byte isn't a one or zero, so it cannot be part
            // of a sync sequence
            i += 3;
            break;
        }
      } // filter out the NAL units that were delivered


      buffer = buffer.subarray(syncPoint);
      i -= syncPoint;
      syncPoint = 0;
    };

    this.reset = function () {
      buffer = null;
      syncPoint = 0;
      this.trigger('reset');
    };

    this.flush = function () {
      // deliver the last buffered NAL unit
      if (buffer && buffer.byteLength > 3) {
        this.trigger('data', buffer.subarray(syncPoint + 3));
      } // reset the stream state


      buffer = null;
      syncPoint = 0;
      this.trigger('done');
    };

    this.endTimeline = function () {
      this.flush();
      this.trigger('endedtimeline');
    };
  };

  _NalByteStream.prototype = new stream(); // values of profile_idc that indicate additional fields are included in the SPS
  // see Recommendation ITU-T H.264 (4/2013),
  // 7.3.2.1.1 Sequence parameter set data syntax

  PROFILES_WITH_OPTIONAL_SPS_DATA = {
    100: true,
    110: true,
    122: true,
    244: true,
    44: true,
    83: true,
    86: true,
    118: true,
    128: true,
    // TODO: the three profiles below don't
    // appear to have sps data in the specificiation anymore?
    138: true,
    139: true,
    134: true
  };
  /**
   * Accepts input from a ElementaryStream and produces H.264 NAL unit data
   * events.
   */

  _H264Stream = function H264Stream() {
    var nalByteStream = new _NalByteStream(),
        self,
        trackId,
        currentPts,
        currentDts,
        discardEmulationPreventionBytes,
        readSequenceParameterSet,
        skipScalingList;

    _H264Stream.prototype.init.call(this);

    self = this;
    /*
     * Pushes a packet from a stream onto the NalByteStream
     *
     * @param {Object} packet - A packet received from a stream
     * @param {Uint8Array} packet.data - The raw bytes of the packet
     * @param {Number} packet.dts - Decode timestamp of the packet
     * @param {Number} packet.pts - Presentation timestamp of the packet
     * @param {Number} packet.trackId - The id of the h264 track this packet came from
     * @param {('video'|'audio')} packet.type - The type of packet
     *
     */

    this.push = function (packet) {
      if (packet.type !== 'video') {
        return;
      }

      trackId = packet.trackId;
      currentPts = packet.pts;
      currentDts = packet.dts;
      nalByteStream.push(packet);
    };
    /*
     * Identify NAL unit types and pass on the NALU, trackId, presentation and decode timestamps
     * for the NALUs to the next stream component.
     * Also, preprocess caption and sequence parameter NALUs.
     *
     * @param {Uint8Array} data - A NAL unit identified by `NalByteStream.push`
     * @see NalByteStream.push
     */


    nalByteStream.on('data', function (data) {
      var event = {
        trackId: trackId,
        pts: currentPts,
        dts: currentDts,
        data: data,
        nalUnitTypeCode: data[0] & 0x1f
      };

      switch (event.nalUnitTypeCode) {
        case 0x05:
          event.nalUnitType = 'slice_layer_without_partitioning_rbsp_idr';
          break;

        case 0x06:
          event.nalUnitType = 'sei_rbsp';
          event.escapedRBSP = discardEmulationPreventionBytes(data.subarray(1));
          break;

        case 0x07:
          event.nalUnitType = 'seq_parameter_set_rbsp';
          event.escapedRBSP = discardEmulationPreventionBytes(data.subarray(1));
          event.config = readSequenceParameterSet(event.escapedRBSP);
          break;

        case 0x08:
          event.nalUnitType = 'pic_parameter_set_rbsp';
          break;

        case 0x09:
          event.nalUnitType = 'access_unit_delimiter_rbsp';
          break;
      } // This triggers data on the H264Stream


      self.trigger('data', event);
    });
    nalByteStream.on('done', function () {
      self.trigger('done');
    });
    nalByteStream.on('partialdone', function () {
      self.trigger('partialdone');
    });
    nalByteStream.on('reset', function () {
      self.trigger('reset');
    });
    nalByteStream.on('endedtimeline', function () {
      self.trigger('endedtimeline');
    });

    this.flush = function () {
      nalByteStream.flush();
    };

    this.partialFlush = function () {
      nalByteStream.partialFlush();
    };

    this.reset = function () {
      nalByteStream.reset();
    };

    this.endTimeline = function () {
      nalByteStream.endTimeline();
    };
    /**
     * Advance the ExpGolomb decoder past a scaling list. The scaling
     * list is optionally transmitted as part of a sequence parameter
     * set and is not relevant to transmuxing.
     * @param count {number} the number of entries in this scaling list
     * @param expGolombDecoder {object} an ExpGolomb pointed to the
     * start of a scaling list
     * @see Recommendation ITU-T H.264, Section 7.3.2.1.1.1
     */


    skipScalingList = function skipScalingList(count, expGolombDecoder) {
      var lastScale = 8,
          nextScale = 8,
          j,
          deltaScale;

      for (j = 0; j < count; j++) {
        if (nextScale !== 0) {
          deltaScale = expGolombDecoder.readExpGolomb();
          nextScale = (lastScale + deltaScale + 256) % 256;
        }

        lastScale = nextScale === 0 ? lastScale : nextScale;
      }
    };
    /**
     * Expunge any "Emulation Prevention" bytes from a "Raw Byte
     * Sequence Payload"
     * @param data {Uint8Array} the bytes of a RBSP from a NAL
     * unit
     * @return {Uint8Array} the RBSP without any Emulation
     * Prevention Bytes
     */


    discardEmulationPreventionBytes = function discardEmulationPreventionBytes(data) {
      var length = data.byteLength,
          emulationPreventionBytesPositions = [],
          i = 1,
          newLength,
          newData; // Find all `Emulation Prevention Bytes`

      while (i < length - 2) {
        if (data[i] === 0 && data[i + 1] === 0 && data[i + 2] === 0x03) {
          emulationPreventionBytesPositions.push(i + 2);
          i += 2;
        } else {
          i++;
        }
      } // If no Emulation Prevention Bytes were found just return the original
      // array


      if (emulationPreventionBytesPositions.length === 0) {
        return data;
      } // Create a new array to hold the NAL unit data


      newLength = length - emulationPreventionBytesPositions.length;
      newData = new Uint8Array(newLength);
      var sourceIndex = 0;

      for (i = 0; i < newLength; sourceIndex++, i++) {
        if (sourceIndex === emulationPreventionBytesPositions[0]) {
          // Skip this byte
          sourceIndex++; // Remove this position index

          emulationPreventionBytesPositions.shift();
        }

        newData[i] = data[sourceIndex];
      }

      return newData;
    };
    /**
     * Read a sequence parameter set and return some interesting video
     * properties. A sequence parameter set is the H264 metadata that
     * describes the properties of upcoming video frames.
     * @param data {Uint8Array} the bytes of a sequence parameter set
     * @return {object} an object with configuration parsed from the
     * sequence parameter set, including the dimensions of the
     * associated video frames.
     */


    readSequenceParameterSet = function readSequenceParameterSet(data) {
      var frameCropLeftOffset = 0,
          frameCropRightOffset = 0,
          frameCropTopOffset = 0,
          frameCropBottomOffset = 0,
          expGolombDecoder,
          profileIdc,
          levelIdc,
          profileCompatibility,
          chromaFormatIdc,
          picOrderCntType,
          numRefFramesInPicOrderCntCycle,
          picWidthInMbsMinus1,
          picHeightInMapUnitsMinus1,
          frameMbsOnlyFlag,
          scalingListCount,
          sarRatio = [1, 1],
          aspectRatioIdc,
          i;
      expGolombDecoder = new expGolomb(data);
      profileIdc = expGolombDecoder.readUnsignedByte(); // profile_idc

      profileCompatibility = expGolombDecoder.readUnsignedByte(); // constraint_set[0-5]_flag

      levelIdc = expGolombDecoder.readUnsignedByte(); // level_idc u(8)

      expGolombDecoder.skipUnsignedExpGolomb(); // seq_parameter_set_id
      // some profiles have more optional data we don't need

      if (PROFILES_WITH_OPTIONAL_SPS_DATA[profileIdc]) {
        chromaFormatIdc = expGolombDecoder.readUnsignedExpGolomb();

        if (chromaFormatIdc === 3) {
          expGolombDecoder.skipBits(1); // separate_colour_plane_flag
        }

        expGolombDecoder.skipUnsignedExpGolomb(); // bit_depth_luma_minus8

        expGolombDecoder.skipUnsignedExpGolomb(); // bit_depth_chroma_minus8

        expGolombDecoder.skipBits(1); // qpprime_y_zero_transform_bypass_flag

        if (expGolombDecoder.readBoolean()) {
          // seq_scaling_matrix_present_flag
          scalingListCount = chromaFormatIdc !== 3 ? 8 : 12;

          for (i = 0; i < scalingListCount; i++) {
            if (expGolombDecoder.readBoolean()) {
              // seq_scaling_list_present_flag[ i ]
              if (i < 6) {
                skipScalingList(16, expGolombDecoder);
              } else {
                skipScalingList(64, expGolombDecoder);
              }
            }
          }
        }
      }

      expGolombDecoder.skipUnsignedExpGolomb(); // log2_max_frame_num_minus4

      picOrderCntType = expGolombDecoder.readUnsignedExpGolomb();

      if (picOrderCntType === 0) {
        expGolombDecoder.readUnsignedExpGolomb(); // log2_max_pic_order_cnt_lsb_minus4
      } else if (picOrderCntType === 1) {
        expGolombDecoder.skipBits(1); // delta_pic_order_always_zero_flag

        expGolombDecoder.skipExpGolomb(); // offset_for_non_ref_pic

        expGolombDecoder.skipExpGolomb(); // offset_for_top_to_bottom_field

        numRefFramesInPicOrderCntCycle = expGolombDecoder.readUnsignedExpGolomb();

        for (i = 0; i < numRefFramesInPicOrderCntCycle; i++) {
          expGolombDecoder.skipExpGolomb(); // offset_for_ref_frame[ i ]
        }
      }

      expGolombDecoder.skipUnsignedExpGolomb(); // max_num_ref_frames

      expGolombDecoder.skipBits(1); // gaps_in_frame_num_value_allowed_flag

      picWidthInMbsMinus1 = expGolombDecoder.readUnsignedExpGolomb();
      picHeightInMapUnitsMinus1 = expGolombDecoder.readUnsignedExpGolomb();
      frameMbsOnlyFlag = expGolombDecoder.readBits(1);

      if (frameMbsOnlyFlag === 0) {
        expGolombDecoder.skipBits(1); // mb_adaptive_frame_field_flag
      }

      expGolombDecoder.skipBits(1); // direct_8x8_inference_flag

      if (expGolombDecoder.readBoolean()) {
        // frame_cropping_flag
        frameCropLeftOffset = expGolombDecoder.readUnsignedExpGolomb();
        frameCropRightOffset = expGolombDecoder.readUnsignedExpGolomb();
        frameCropTopOffset = expGolombDecoder.readUnsignedExpGolomb();
        frameCropBottomOffset = expGolombDecoder.readUnsignedExpGolomb();
      }

      if (expGolombDecoder.readBoolean()) {
        // vui_parameters_present_flag
        if (expGolombDecoder.readBoolean()) {
          // aspect_ratio_info_present_flag
          aspectRatioIdc = expGolombDecoder.readUnsignedByte();

          switch (aspectRatioIdc) {
            case 1:
              sarRatio = [1, 1];
              break;

            case 2:
              sarRatio = [12, 11];
              break;

            case 3:
              sarRatio = [10, 11];
              break;

            case 4:
              sarRatio = [16, 11];
              break;

            case 5:
              sarRatio = [40, 33];
              break;

            case 6:
              sarRatio = [24, 11];
              break;

            case 7:
              sarRatio = [20, 11];
              break;

            case 8:
              sarRatio = [32, 11];
              break;

            case 9:
              sarRatio = [80, 33];
              break;

            case 10:
              sarRatio = [18, 11];
              break;

            case 11:
              sarRatio = [15, 11];
              break;

            case 12:
              sarRatio = [64, 33];
              break;

            case 13:
              sarRatio = [160, 99];
              break;

            case 14:
              sarRatio = [4, 3];
              break;

            case 15:
              sarRatio = [3, 2];
              break;

            case 16:
              sarRatio = [2, 1];
              break;

            case 255:
              {
                sarRatio = [expGolombDecoder.readUnsignedByte() << 8 | expGolombDecoder.readUnsignedByte(), expGolombDecoder.readUnsignedByte() << 8 | expGolombDecoder.readUnsignedByte()];
                break;
              }
          }

          if (sarRatio) {
            sarRatio[0] / sarRatio[1];
          }
        }
      }

      return {
        profileIdc: profileIdc,
        levelIdc: levelIdc,
        profileCompatibility: profileCompatibility,
        width: (picWidthInMbsMinus1 + 1) * 16 - frameCropLeftOffset * 2 - frameCropRightOffset * 2,
        height: (2 - frameMbsOnlyFlag) * (picHeightInMapUnitsMinus1 + 1) * 16 - frameCropTopOffset * 2 - frameCropBottomOffset * 2,
        // sar is sample aspect ratio
        sarRatio: sarRatio
      };
    };
  };

  _H264Stream.prototype = new stream();
  var h264 = {
    H264Stream: _H264Stream,
    NalByteStream: _NalByteStream
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var codecs = {
    Adts: adts,
    h264: h264
  };

  var MAX_UINT32$1 = Math.pow(2, 32);

  var getUint64$4 = function getUint64(uint8) {
    var dv = new DataView(uint8.buffer, uint8.byteOffset, uint8.byteLength);
    var value;

    if (dv.getBigUint64) {
      value = dv.getBigUint64(0);

      if (value < Number.MAX_SAFE_INTEGER) {
        return Number(value);
      }

      return value;
    }

    return dv.getUint32(0) * MAX_UINT32$1 + dv.getUint32(4);
  };

  var numbers = {
    getUint64: getUint64$4,
    MAX_UINT32: MAX_UINT32$1
  };

  var MAX_UINT32 = numbers.MAX_UINT32;
  var box, dinf, esds, ftyp, mdat, mfhd, minf, moof, moov, mvex, mvhd, trak, tkhd, mdia, mdhd, hdlr, sdtp, stbl, stsd, traf, trex, trun$1, types, MAJOR_BRAND, MINOR_VERSION, AVC1_BRAND, VIDEO_HDLR, AUDIO_HDLR, HDLR_TYPES, VMHD, SMHD, DREF, STCO, STSC, STSZ, STTS; // pre-calculate constants

  (function () {
    var i;
    types = {
      avc1: [],
      // codingname
      avcC: [],
      btrt: [],
      dinf: [],
      dref: [],
      esds: [],
      ftyp: [],
      hdlr: [],
      mdat: [],
      mdhd: [],
      mdia: [],
      mfhd: [],
      minf: [],
      moof: [],
      moov: [],
      mp4a: [],
      // codingname
      mvex: [],
      mvhd: [],
      pasp: [],
      sdtp: [],
      smhd: [],
      stbl: [],
      stco: [],
      stsc: [],
      stsd: [],
      stsz: [],
      stts: [],
      styp: [],
      tfdt: [],
      tfhd: [],
      traf: [],
      trak: [],
      trun: [],
      trex: [],
      tkhd: [],
      vmhd: []
    }; // In environments where Uint8Array is undefined (e.g., IE8), skip set up so that we
    // don't throw an error

    if (typeof Uint8Array === 'undefined') {
      return;
    }

    for (i in types) {
      if (types.hasOwnProperty(i)) {
        types[i] = [i.charCodeAt(0), i.charCodeAt(1), i.charCodeAt(2), i.charCodeAt(3)];
      }
    }

    MAJOR_BRAND = new Uint8Array(['i'.charCodeAt(0), 's'.charCodeAt(0), 'o'.charCodeAt(0), 'm'.charCodeAt(0)]);
    AVC1_BRAND = new Uint8Array(['a'.charCodeAt(0), 'v'.charCodeAt(0), 'c'.charCodeAt(0), '1'.charCodeAt(0)]);
    MINOR_VERSION = new Uint8Array([0, 0, 0, 1]);
    VIDEO_HDLR = new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00, // pre_defined
    0x76, 0x69, 0x64, 0x65, // handler_type: 'vide'
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x56, 0x69, 0x64, 0x65, 0x6f, 0x48, 0x61, 0x6e, 0x64, 0x6c, 0x65, 0x72, 0x00 // name: 'VideoHandler'
    ]);
    AUDIO_HDLR = new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00, // pre_defined
    0x73, 0x6f, 0x75, 0x6e, // handler_type: 'soun'
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x53, 0x6f, 0x75, 0x6e, 0x64, 0x48, 0x61, 0x6e, 0x64, 0x6c, 0x65, 0x72, 0x00 // name: 'SoundHandler'
    ]);
    HDLR_TYPES = {
      video: VIDEO_HDLR,
      audio: AUDIO_HDLR
    };
    DREF = new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x01, // entry_count
    0x00, 0x00, 0x00, 0x0c, // entry_size
    0x75, 0x72, 0x6c, 0x20, // 'url' type
    0x00, // version 0
    0x00, 0x00, 0x01 // entry_flags
    ]);
    SMHD = new Uint8Array([0x00, // version
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, // balance, 0 means centered
    0x00, 0x00 // reserved
    ]);
    STCO = new Uint8Array([0x00, // version
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00 // entry_count
    ]);
    STSC = STCO;
    STSZ = new Uint8Array([0x00, // version
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x00, // sample_size
    0x00, 0x00, 0x00, 0x00 // sample_count
    ]);
    STTS = STCO;
    VMHD = new Uint8Array([0x00, // version
    0x00, 0x00, 0x01, // flags
    0x00, 0x00, // graphicsmode
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // opcolor
    ]);
  })();

  box = function box(type) {
    var payload = [],
        size = 0,
        i,
        result,
        view;

    for (i = 1; i < arguments.length; i++) {
      payload.push(arguments[i]);
    }

    i = payload.length; // calculate the total size we need to allocate

    while (i--) {
      size += payload[i].byteLength;
    }

    result = new Uint8Array(size + 8);
    view = new DataView(result.buffer, result.byteOffset, result.byteLength);
    view.setUint32(0, result.byteLength);
    result.set(type, 4); // copy the payload into the result

    for (i = 0, size = 8; i < payload.length; i++) {
      result.set(payload[i], size);
      size += payload[i].byteLength;
    }

    return result;
  };

  dinf = function dinf() {
    return box(types.dinf, box(types.dref, DREF));
  };

  esds = function esds(track) {
    return box(types.esds, new Uint8Array([0x00, // version
    0x00, 0x00, 0x00, // flags
    // ES_Descriptor
    0x03, // tag, ES_DescrTag
    0x19, // length
    0x00, 0x00, // ES_ID
    0x00, // streamDependenceFlag, URL_flag, reserved, streamPriority
    // DecoderConfigDescriptor
    0x04, // tag, DecoderConfigDescrTag
    0x11, // length
    0x40, // object type
    0x15, // streamType
    0x00, 0x06, 0x00, // bufferSizeDB
    0x00, 0x00, 0xda, 0xc0, // maxBitrate
    0x00, 0x00, 0xda, 0xc0, // avgBitrate
    // DecoderSpecificInfo
    0x05, // tag, DecoderSpecificInfoTag
    0x02, // length
    // ISO/IEC 14496-3, AudioSpecificConfig
    // for samplingFrequencyIndex see ISO/IEC 13818-7:2006, 8.1.3.2.2, Table 35
    track.audioobjecttype << 3 | track.samplingfrequencyindex >>> 1, track.samplingfrequencyindex << 7 | track.channelcount << 3, 0x06, 0x01, 0x02 // GASpecificConfig
    ]));
  };

  ftyp = function ftyp() {
    return box(types.ftyp, MAJOR_BRAND, MINOR_VERSION, MAJOR_BRAND, AVC1_BRAND);
  };

  hdlr = function hdlr(type) {
    return box(types.hdlr, HDLR_TYPES[type]);
  };

  mdat = function mdat(data) {
    return box(types.mdat, data);
  };

  mdhd = function mdhd(track) {
    var result = new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x02, // creation_time
    0x00, 0x00, 0x00, 0x03, // modification_time
    0x00, 0x01, 0x5f, 0x90, // timescale, 90,000 "ticks" per second
    track.duration >>> 24 & 0xFF, track.duration >>> 16 & 0xFF, track.duration >>> 8 & 0xFF, track.duration & 0xFF, // duration
    0x55, 0xc4, // 'und' language (undetermined)
    0x00, 0x00]); // Use the sample rate from the track metadata, when it is
    // defined. The sample rate can be parsed out of an ADTS header, for
    // instance.

    if (track.samplerate) {
      result[12] = track.samplerate >>> 24 & 0xFF;
      result[13] = track.samplerate >>> 16 & 0xFF;
      result[14] = track.samplerate >>> 8 & 0xFF;
      result[15] = track.samplerate & 0xFF;
    }

    return box(types.mdhd, result);
  };

  mdia = function mdia(track) {
    return box(types.mdia, mdhd(track), hdlr(track.type), minf(track));
  };

  mfhd = function mfhd(sequenceNumber) {
    return box(types.mfhd, new Uint8Array([0x00, 0x00, 0x00, 0x00, // flags
    (sequenceNumber & 0xFF000000) >> 24, (sequenceNumber & 0xFF0000) >> 16, (sequenceNumber & 0xFF00) >> 8, sequenceNumber & 0xFF // sequence_number
    ]));
  };

  minf = function minf(track) {
    return box(types.minf, track.type === 'video' ? box(types.vmhd, VMHD) : box(types.smhd, SMHD), dinf(), stbl(track));
  };

  moof = function moof(sequenceNumber, tracks) {
    var trackFragments = [],
        i = tracks.length; // build traf boxes for each track fragment

    while (i--) {
      trackFragments[i] = traf(tracks[i]);
    }

    return box.apply(null, [types.moof, mfhd(sequenceNumber)].concat(trackFragments));
  };
  /**
   * Returns a movie box.
   * @param tracks {array} the tracks associated with this movie
   * @see ISO/IEC 14496-12:2012(E), section 8.2.1
   */


  moov = function moov(tracks) {
    var i = tracks.length,
        boxes = [];

    while (i--) {
      boxes[i] = trak(tracks[i]);
    }

    return box.apply(null, [types.moov, mvhd(0xffffffff)].concat(boxes).concat(mvex(tracks)));
  };

  mvex = function mvex(tracks) {
    var i = tracks.length,
        boxes = [];

    while (i--) {
      boxes[i] = trex(tracks[i]);
    }

    return box.apply(null, [types.mvex].concat(boxes));
  };

  mvhd = function mvhd(duration) {
    var bytes = new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x00, // flags
    0x00, 0x00, 0x00, 0x01, // creation_time
    0x00, 0x00, 0x00, 0x02, // modification_time
    0x00, 0x01, 0x5f, 0x90, // timescale, 90,000 "ticks" per second
    (duration & 0xFF000000) >> 24, (duration & 0xFF0000) >> 16, (duration & 0xFF00) >> 8, duration & 0xFF, // duration
    0x00, 0x01, 0x00, 0x00, // 1.0 rate
    0x01, 0x00, // 1.0 volume
    0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, // transformation: unity matrix
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // pre_defined
    0xff, 0xff, 0xff, 0xff // next_track_ID
    ]);
    return box(types.mvhd, bytes);
  };

  sdtp = function sdtp(track) {
    var samples = track.samples || [],
        bytes = new Uint8Array(4 + samples.length),
        flags,
        i; // leave the full box header (4 bytes) all zero
    // write the sample table

    for (i = 0; i < samples.length; i++) {
      flags = samples[i].flags;
      bytes[i + 4] = flags.dependsOn << 4 | flags.isDependedOn << 2 | flags.hasRedundancy;
    }

    return box(types.sdtp, bytes);
  };

  stbl = function stbl(track) {
    return box(types.stbl, stsd(track), box(types.stts, STTS), box(types.stsc, STSC), box(types.stsz, STSZ), box(types.stco, STCO));
  };

  (function () {
    var videoSample, audioSample;

    stsd = function stsd(track) {
      return box(types.stsd, new Uint8Array([0x00, // version 0
      0x00, 0x00, 0x00, // flags
      0x00, 0x00, 0x00, 0x01]), track.type === 'video' ? videoSample(track) : audioSample(track));
    };

    videoSample = function videoSample(track) {
      var sps = track.sps || [],
          pps = track.pps || [],
          sequenceParameterSets = [],
          pictureParameterSets = [],
          i,
          avc1Box; // assemble the SPSs

      for (i = 0; i < sps.length; i++) {
        sequenceParameterSets.push((sps[i].byteLength & 0xFF00) >>> 8);
        sequenceParameterSets.push(sps[i].byteLength & 0xFF); // sequenceParameterSetLength

        sequenceParameterSets = sequenceParameterSets.concat(Array.prototype.slice.call(sps[i])); // SPS
      } // assemble the PPSs


      for (i = 0; i < pps.length; i++) {
        pictureParameterSets.push((pps[i].byteLength & 0xFF00) >>> 8);
        pictureParameterSets.push(pps[i].byteLength & 0xFF);
        pictureParameterSets = pictureParameterSets.concat(Array.prototype.slice.call(pps[i]));
      }

      avc1Box = [types.avc1, new Uint8Array([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // reserved
      0x00, 0x01, // data_reference_index
      0x00, 0x00, // pre_defined
      0x00, 0x00, // reserved
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // pre_defined
      (track.width & 0xff00) >> 8, track.width & 0xff, // width
      (track.height & 0xff00) >> 8, track.height & 0xff, // height
      0x00, 0x48, 0x00, 0x00, // horizresolution
      0x00, 0x48, 0x00, 0x00, // vertresolution
      0x00, 0x00, 0x00, 0x00, // reserved
      0x00, 0x01, // frame_count
      0x13, 0x76, 0x69, 0x64, 0x65, 0x6f, 0x6a, 0x73, 0x2d, 0x63, 0x6f, 0x6e, 0x74, 0x72, 0x69, 0x62, 0x2d, 0x68, 0x6c, 0x73, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // compressorname
      0x00, 0x18, // depth = 24
      0x11, 0x11 // pre_defined = -1
      ]), box(types.avcC, new Uint8Array([0x01, // configurationVersion
      track.profileIdc, // AVCProfileIndication
      track.profileCompatibility, // profile_compatibility
      track.levelIdc, // AVCLevelIndication
      0xff // lengthSizeMinusOne, hard-coded to 4 bytes
      ].concat([sps.length], // numOfSequenceParameterSets
      sequenceParameterSets, // "SPS"
      [pps.length], // numOfPictureParameterSets
      pictureParameterSets // "PPS"
      ))), box(types.btrt, new Uint8Array([0x00, 0x1c, 0x9c, 0x80, // bufferSizeDB
      0x00, 0x2d, 0xc6, 0xc0, // maxBitrate
      0x00, 0x2d, 0xc6, 0xc0 // avgBitrate
      ]))];

      if (track.sarRatio) {
        var hSpacing = track.sarRatio[0],
            vSpacing = track.sarRatio[1];
        avc1Box.push(box(types.pasp, new Uint8Array([(hSpacing & 0xFF000000) >> 24, (hSpacing & 0xFF0000) >> 16, (hSpacing & 0xFF00) >> 8, hSpacing & 0xFF, (vSpacing & 0xFF000000) >> 24, (vSpacing & 0xFF0000) >> 16, (vSpacing & 0xFF00) >> 8, vSpacing & 0xFF])));
      }

      return box.apply(null, avc1Box);
    };

    audioSample = function audioSample(track) {
      return box(types.mp4a, new Uint8Array([// SampleEntry, ISO/IEC 14496-12
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // reserved
      0x00, 0x01, // data_reference_index
      // AudioSampleEntry, ISO/IEC 14496-12
      0x00, 0x00, 0x00, 0x00, // reserved
      0x00, 0x00, 0x00, 0x00, // reserved
      (track.channelcount & 0xff00) >> 8, track.channelcount & 0xff, // channelcount
      (track.samplesize & 0xff00) >> 8, track.samplesize & 0xff, // samplesize
      0x00, 0x00, // pre_defined
      0x00, 0x00, // reserved
      (track.samplerate & 0xff00) >> 8, track.samplerate & 0xff, 0x00, 0x00 // samplerate, 16.16
      // MP4AudioSampleEntry, ISO/IEC 14496-14
      ]), esds(track));
    };
  })();

  tkhd = function tkhd(track) {
    var result = new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x07, // flags
    0x00, 0x00, 0x00, 0x00, // creation_time
    0x00, 0x00, 0x00, 0x00, // modification_time
    (track.id & 0xFF000000) >> 24, (track.id & 0xFF0000) >> 16, (track.id & 0xFF00) >> 8, track.id & 0xFF, // track_ID
    0x00, 0x00, 0x00, 0x00, // reserved
    (track.duration & 0xFF000000) >> 24, (track.duration & 0xFF0000) >> 16, (track.duration & 0xFF00) >> 8, track.duration & 0xFF, // duration
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // reserved
    0x00, 0x00, // layer
    0x00, 0x00, // alternate_group
    0x01, 0x00, // non-audio track volume
    0x00, 0x00, // reserved
    0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, // transformation: unity matrix
    (track.width & 0xFF00) >> 8, track.width & 0xFF, 0x00, 0x00, // width
    (track.height & 0xFF00) >> 8, track.height & 0xFF, 0x00, 0x00 // height
    ]);
    return box(types.tkhd, result);
  };
  /**
   * Generate a track fragment (traf) box. A traf box collects metadata
   * about tracks in a movie fragment (moof) box.
   */


  traf = function traf(track) {
    var trackFragmentHeader, trackFragmentDecodeTime, trackFragmentRun, sampleDependencyTable, dataOffset, upperWordBaseMediaDecodeTime, lowerWordBaseMediaDecodeTime;
    trackFragmentHeader = box(types.tfhd, new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x3a, // flags
    (track.id & 0xFF000000) >> 24, (track.id & 0xFF0000) >> 16, (track.id & 0xFF00) >> 8, track.id & 0xFF, // track_ID
    0x00, 0x00, 0x00, 0x01, // sample_description_index
    0x00, 0x00, 0x00, 0x00, // default_sample_duration
    0x00, 0x00, 0x00, 0x00, // default_sample_size
    0x00, 0x00, 0x00, 0x00 // default_sample_flags
    ]));
    upperWordBaseMediaDecodeTime = Math.floor(track.baseMediaDecodeTime / MAX_UINT32);
    lowerWordBaseMediaDecodeTime = Math.floor(track.baseMediaDecodeTime % MAX_UINT32);
    trackFragmentDecodeTime = box(types.tfdt, new Uint8Array([0x01, // version 1
    0x00, 0x00, 0x00, // flags
    // baseMediaDecodeTime
    upperWordBaseMediaDecodeTime >>> 24 & 0xFF, upperWordBaseMediaDecodeTime >>> 16 & 0xFF, upperWordBaseMediaDecodeTime >>> 8 & 0xFF, upperWordBaseMediaDecodeTime & 0xFF, lowerWordBaseMediaDecodeTime >>> 24 & 0xFF, lowerWordBaseMediaDecodeTime >>> 16 & 0xFF, lowerWordBaseMediaDecodeTime >>> 8 & 0xFF, lowerWordBaseMediaDecodeTime & 0xFF])); // the data offset specifies the number of bytes from the start of
    // the containing moof to the first payload byte of the associated
    // mdat

    dataOffset = 32 + // tfhd
    20 + // tfdt
    8 + // traf header
    16 + // mfhd
    8 + // moof header
    8; // mdat header
    // audio tracks require less metadata

    if (track.type === 'audio') {
      trackFragmentRun = trun$1(track, dataOffset);
      return box(types.traf, trackFragmentHeader, trackFragmentDecodeTime, trackFragmentRun);
    } // video tracks should contain an independent and disposable samples
    // box (sdtp)
    // generate one and adjust offsets to match


    sampleDependencyTable = sdtp(track);
    trackFragmentRun = trun$1(track, sampleDependencyTable.length + dataOffset);
    return box(types.traf, trackFragmentHeader, trackFragmentDecodeTime, trackFragmentRun, sampleDependencyTable);
  };
  /**
   * Generate a track box.
   * @param track {object} a track definition
   * @return {Uint8Array} the track box
   */


  trak = function trak(track) {
    track.duration = track.duration || 0xffffffff;
    return box(types.trak, tkhd(track), mdia(track));
  };

  trex = function trex(track) {
    var result = new Uint8Array([0x00, // version 0
    0x00, 0x00, 0x00, // flags
    (track.id & 0xFF000000) >> 24, (track.id & 0xFF0000) >> 16, (track.id & 0xFF00) >> 8, track.id & 0xFF, // track_ID
    0x00, 0x00, 0x00, 0x01, // default_sample_description_index
    0x00, 0x00, 0x00, 0x00, // default_sample_duration
    0x00, 0x00, 0x00, 0x00, // default_sample_size
    0x00, 0x01, 0x00, 0x01 // default_sample_flags
    ]); // the last two bytes of default_sample_flags is the sample
    // degradation priority, a hint about the importance of this sample
    // relative to others. Lower the degradation priority for all sample
    // types other than video.

    if (track.type !== 'video') {
      result[result.length - 1] = 0x00;
    }

    return box(types.trex, result);
  };

  (function () {
    var audioTrun, videoTrun, trunHeader; // This method assumes all samples are uniform. That is, if a
    // duration is present for the first sample, it will be present for
    // all subsequent samples.
    // see ISO/IEC 14496-12:2012, Section 8.8.8.1

    trunHeader = function trunHeader(samples, offset) {
      var durationPresent = 0,
          sizePresent = 0,
          flagsPresent = 0,
          compositionTimeOffset = 0; // trun flag constants

      if (samples.length) {
        if (samples[0].duration !== undefined) {
          durationPresent = 0x1;
        }

        if (samples[0].size !== undefined) {
          sizePresent = 0x2;
        }

        if (samples[0].flags !== undefined) {
          flagsPresent = 0x4;
        }

        if (samples[0].compositionTimeOffset !== undefined) {
          compositionTimeOffset = 0x8;
        }
      }

      return [0x00, // version 0
      0x00, durationPresent | sizePresent | flagsPresent | compositionTimeOffset, 0x01, // flags
      (samples.length & 0xFF000000) >>> 24, (samples.length & 0xFF0000) >>> 16, (samples.length & 0xFF00) >>> 8, samples.length & 0xFF, // sample_count
      (offset & 0xFF000000) >>> 24, (offset & 0xFF0000) >>> 16, (offset & 0xFF00) >>> 8, offset & 0xFF // data_offset
      ];
    };

    videoTrun = function videoTrun(track, offset) {
      var bytesOffest, bytes, header, samples, sample, i;
      samples = track.samples || [];
      offset += 8 + 12 + 16 * samples.length;
      header = trunHeader(samples, offset);
      bytes = new Uint8Array(header.length + samples.length * 16);
      bytes.set(header);
      bytesOffest = header.length;

      for (i = 0; i < samples.length; i++) {
        sample = samples[i];
        bytes[bytesOffest++] = (sample.duration & 0xFF000000) >>> 24;
        bytes[bytesOffest++] = (sample.duration & 0xFF0000) >>> 16;
        bytes[bytesOffest++] = (sample.duration & 0xFF00) >>> 8;
        bytes[bytesOffest++] = sample.duration & 0xFF; // sample_duration

        bytes[bytesOffest++] = (sample.size & 0xFF000000) >>> 24;
        bytes[bytesOffest++] = (sample.size & 0xFF0000) >>> 16;
        bytes[bytesOffest++] = (sample.size & 0xFF00) >>> 8;
        bytes[bytesOffest++] = sample.size & 0xFF; // sample_size

        bytes[bytesOffest++] = sample.flags.isLeading << 2 | sample.flags.dependsOn;
        bytes[bytesOffest++] = sample.flags.isDependedOn << 6 | sample.flags.hasRedundancy << 4 | sample.flags.paddingValue << 1 | sample.flags.isNonSyncSample;
        bytes[bytesOffest++] = sample.flags.degradationPriority & 0xF0 << 8;
        bytes[bytesOffest++] = sample.flags.degradationPriority & 0x0F; // sample_flags

        bytes[bytesOffest++] = (sample.compositionTimeOffset & 0xFF000000) >>> 24;
        bytes[bytesOffest++] = (sample.compositionTimeOffset & 0xFF0000) >>> 16;
        bytes[bytesOffest++] = (sample.compositionTimeOffset & 0xFF00) >>> 8;
        bytes[bytesOffest++] = sample.compositionTimeOffset & 0xFF; // sample_composition_time_offset
      }

      return box(types.trun, bytes);
    };

    audioTrun = function audioTrun(track, offset) {
      var bytes, bytesOffest, header, samples, sample, i;
      samples = track.samples || [];
      offset += 8 + 12 + 8 * samples.length;
      header = trunHeader(samples, offset);
      bytes = new Uint8Array(header.length + samples.length * 8);
      bytes.set(header);
      bytesOffest = header.length;

      for (i = 0; i < samples.length; i++) {
        sample = samples[i];
        bytes[bytesOffest++] = (sample.duration & 0xFF000000) >>> 24;
        bytes[bytesOffest++] = (sample.duration & 0xFF0000) >>> 16;
        bytes[bytesOffest++] = (sample.duration & 0xFF00) >>> 8;
        bytes[bytesOffest++] = sample.duration & 0xFF; // sample_duration

        bytes[bytesOffest++] = (sample.size & 0xFF000000) >>> 24;
        bytes[bytesOffest++] = (sample.size & 0xFF0000) >>> 16;
        bytes[bytesOffest++] = (sample.size & 0xFF00) >>> 8;
        bytes[bytesOffest++] = sample.size & 0xFF; // sample_size
      }

      return box(types.trun, bytes);
    };

    trun$1 = function trun(track, offset) {
      if (track.type === 'audio') {
        return audioTrun(track, offset);
      }

      return videoTrun(track, offset);
    };
  })();

  var mp4Generator = {
    ftyp: ftyp,
    mdat: mdat,
    moof: moof,
    moov: moov,
    initSegment: function initSegment(tracks) {
      var fileType = ftyp(),
          movie = moov(tracks),
          result;
      result = new Uint8Array(fileType.byteLength + movie.byteLength);
      result.set(fileType);
      result.set(movie, fileType.byteLength);
      return result;
    }
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */
  var toUnsigned$3 = function toUnsigned(value) {
    return value >>> 0;
  };

  var toHexString$1 = function toHexString(value) {
    return ('00' + value.toString(16)).slice(-2);
  };

  var bin = {
    toUnsigned: toUnsigned$3,
    toHexString: toHexString$1
  };

  var parseType$2 = function parseType(buffer) {
    var result = '';
    result += String.fromCharCode(buffer[0]);
    result += String.fromCharCode(buffer[1]);
    result += String.fromCharCode(buffer[2]);
    result += String.fromCharCode(buffer[3]);
    return result;
  };

  var parseType_1 = parseType$2;

  var toUnsigned$2 = bin.toUnsigned;

  var findBox = function findBox(data, path) {
    var results = [],
        i,
        size,
        type,
        end,
        subresults;

    if (!path.length) {
      // short-circuit the search for empty paths
      return null;
    }

    for (i = 0; i < data.byteLength;) {
      size = toUnsigned$2(data[i] << 24 | data[i + 1] << 16 | data[i + 2] << 8 | data[i + 3]);
      type = parseType_1(data.subarray(i + 4, i + 8));
      end = size > 1 ? i + size : data.byteLength;

      if (type === path[0]) {
        if (path.length === 1) {
          // this is the end of the path and we've found the box we were
          // looking for
          results.push(data.subarray(i + 8, end));
        } else {
          // recursively search for the next box along the path
          subresults = findBox(data.subarray(i + 8, end), path.slice(1));

          if (subresults.length) {
            results = results.concat(subresults);
          }
        }
      }

      i = end;
    } // we've finished searching all of data


    return results;
  };

  var findBox_1 = findBox;

  var tfhd = function tfhd(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      trackId: view.getUint32(4)
    },
        baseDataOffsetPresent = result.flags[2] & 0x01,
        sampleDescriptionIndexPresent = result.flags[2] & 0x02,
        defaultSampleDurationPresent = result.flags[2] & 0x08,
        defaultSampleSizePresent = result.flags[2] & 0x10,
        defaultSampleFlagsPresent = result.flags[2] & 0x20,
        durationIsEmpty = result.flags[0] & 0x010000,
        defaultBaseIsMoof = result.flags[0] & 0x020000,
        i;
    i = 8;

    if (baseDataOffsetPresent) {
      i += 4; // truncate top 4 bytes
      // FIXME: should we read the full 64 bits?

      result.baseDataOffset = view.getUint32(12);
      i += 4;
    }

    if (sampleDescriptionIndexPresent) {
      result.sampleDescriptionIndex = view.getUint32(i);
      i += 4;
    }

    if (defaultSampleDurationPresent) {
      result.defaultSampleDuration = view.getUint32(i);
      i += 4;
    }

    if (defaultSampleSizePresent) {
      result.defaultSampleSize = view.getUint32(i);
      i += 4;
    }

    if (defaultSampleFlagsPresent) {
      result.defaultSampleFlags = view.getUint32(i);
    }

    if (durationIsEmpty) {
      result.durationIsEmpty = true;
    }

    if (!baseDataOffsetPresent && defaultBaseIsMoof) {
      result.baseDataOffsetIsMoof = true;
    }

    return result;
  };

  var parseTfhd = tfhd;

  var parseSampleFlags = function parseSampleFlags(flags) {
    return {
      isLeading: (flags[0] & 0x0c) >>> 2,
      dependsOn: flags[0] & 0x03,
      isDependedOn: (flags[1] & 0xc0) >>> 6,
      hasRedundancy: (flags[1] & 0x30) >>> 4,
      paddingValue: (flags[1] & 0x0e) >>> 1,
      isNonSyncSample: flags[1] & 0x01,
      degradationPriority: flags[2] << 8 | flags[3]
    };
  };

  var parseSampleFlags_1 = parseSampleFlags;

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
        flags: parseSampleFlags_1(data.subarray(offset, offset + 4))
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
        sample.flags = parseSampleFlags_1(data.subarray(offset, offset + 4));
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

  var parseTrun = trun;

  var toUnsigned$1 = bin.toUnsigned;
  var getUint64$3 = numbers.getUint64;

  var tfdt = function tfdt(data) {
    var result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4))
    };

    if (result.version === 1) {
      result.baseMediaDecodeTime = getUint64$3(data.subarray(4));
    } else {
      result.baseMediaDecodeTime = toUnsigned$1(data[4] << 24 | data[5] << 16 | data[6] << 8 | data[7]);
    }

    return result;
  };

  var parseTfdt = tfdt;

  var toUnsigned = bin.toUnsigned;
  var toHexString = bin.toHexString;
  var getUint64$2 = numbers.getUint64;
  var timescale, startTime, compositionStartTime, getVideoTrackIds, getTracks, getTimescaleFromMediaHeader;
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

  timescale = function timescale(init) {
    var result = {},
        traks = findBox_1(init, ['moov', 'trak']); // mdhd timescale

    return traks.reduce(function (result, trak) {
      var tkhd, version, index, id, mdhd;
      tkhd = findBox_1(trak, ['tkhd'])[0];

      if (!tkhd) {
        return null;
      }

      version = tkhd[0];
      index = version === 0 ? 12 : 20;
      id = toUnsigned(tkhd[index] << 24 | tkhd[index + 1] << 16 | tkhd[index + 2] << 8 | tkhd[index + 3]);
      mdhd = findBox_1(trak, ['mdia', 'mdhd'])[0];

      if (!mdhd) {
        return null;
      }

      version = mdhd[0];
      index = version === 0 ? 12 : 20;
      result[id] = toUnsigned(mdhd[index] << 24 | mdhd[index + 1] << 16 | mdhd[index + 2] << 8 | mdhd[index + 3]);
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


  startTime = function startTime(timescale, fragment) {
    var trafs; // we need info from two childrend of each track fragment box

    trafs = findBox_1(fragment, ['moof', 'traf']); // determine the start times for each track

    var lowestTime = trafs.reduce(function (acc, traf) {
      var tfhd = findBox_1(traf, ['tfhd'])[0]; // get the track id from the tfhd

      var id = toUnsigned(tfhd[4] << 24 | tfhd[5] << 16 | tfhd[6] << 8 | tfhd[7]); // assume a 90kHz clock if no timescale was specified

      var scale = timescale[id] || 90e3; // get the base media decode time from the tfdt

      var tfdt = findBox_1(traf, ['tfdt'])[0];
      var dv = new DataView(tfdt.buffer, tfdt.byteOffset, tfdt.byteLength);
      var baseTime; // version 1 is 64 bit

      if (tfdt[0] === 1) {
        baseTime = getUint64$2(tfdt.subarray(4, 12));
      } else {
        baseTime = dv.getUint32(4);
      } // convert base time to seconds if it is a valid number.


      var seconds;

      if (typeof baseTime === 'bigint') {
        seconds = baseTime / window__default['default'].BigInt(scale);
      } else if (typeof baseTime === 'number' && !isNaN(baseTime)) {
        seconds = baseTime / scale;
      }

      if (seconds < Number.MAX_SAFE_INTEGER) {
        seconds = Number(seconds);
      }

      if (seconds < acc) {
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


  compositionStartTime = function compositionStartTime(timescales, fragment) {
    var trafBoxes = findBox_1(fragment, ['moof', 'traf']);
    var baseMediaDecodeTime = 0;
    var compositionTimeOffset = 0;
    var trackId;

    if (trafBoxes && trafBoxes.length) {
      // The spec states that track run samples contained within a `traf` box are contiguous, but
      // it does not explicitly state whether the `traf` boxes themselves are contiguous.
      // We will assume that they are, so we only need the first to calculate start time.
      var tfhd = findBox_1(trafBoxes[0], ['tfhd'])[0];
      var trun = findBox_1(trafBoxes[0], ['trun'])[0];
      var tfdt = findBox_1(trafBoxes[0], ['tfdt'])[0];

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
    } // Get timescale for this specific track. Assume a 90kHz clock if no timescale was
    // specified.


    var timescale = timescales[trackId] || 90e3; // return the composition start time, in seconds

    if (typeof baseMediaDecodeTime === 'bigint') {
      compositionTimeOffset = window__default['default'].BigInt(compositionTimeOffset);
      timescale = window__default['default'].BigInt(timescale);
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


  getVideoTrackIds = function getVideoTrackIds(init) {
    var traks = findBox_1(init, ['moov', 'trak']);
    var videoTrackIds = [];
    traks.forEach(function (trak) {
      var hdlrs = findBox_1(trak, ['mdia', 'hdlr']);
      var tkhds = findBox_1(trak, ['tkhd']);
      hdlrs.forEach(function (hdlr, index) {
        var handlerType = parseType_1(hdlr.subarray(8, 12));
        var tkhd = tkhds[index];
        var view;
        var version;
        var trackId;

        if (handlerType === 'vide') {
          view = new DataView(tkhd.buffer, tkhd.byteOffset, tkhd.byteLength);
          version = view.getUint8(0);
          trackId = version === 0 ? view.getUint32(12) : view.getUint32(20);
          videoTrackIds.push(trackId);
        }
      });
    });
    return videoTrackIds;
  };

  getTimescaleFromMediaHeader = function getTimescaleFromMediaHeader(mdhd) {
    // mdhd is a FullBox, meaning it will have its own version as the first byte
    var version = mdhd[0];
    var index = version === 0 ? 12 : 20;
    return toUnsigned(mdhd[index] << 24 | mdhd[index + 1] << 16 | mdhd[index + 2] << 8 | mdhd[index + 3]);
  };
  /**
   * Get all the video, audio, and hint tracks from a non fragmented
   * mp4 segment
   */


  getTracks = function getTracks(init) {
    var traks = findBox_1(init, ['moov', 'trak']);
    var tracks = [];
    traks.forEach(function (trak) {
      var track = {};
      var tkhd = findBox_1(trak, ['tkhd'])[0];
      var view, tkhdVersion; // id

      if (tkhd) {
        view = new DataView(tkhd.buffer, tkhd.byteOffset, tkhd.byteLength);
        tkhdVersion = view.getUint8(0);
        track.id = tkhdVersion === 0 ? view.getUint32(12) : view.getUint32(20);
      }

      var hdlr = findBox_1(trak, ['mdia', 'hdlr'])[0]; // type

      if (hdlr) {
        var type = parseType_1(hdlr.subarray(8, 12));

        if (type === 'vide') {
          track.type = 'video';
        } else if (type === 'soun') {
          track.type = 'audio';
        } else {
          track.type = type;
        }
      } // codec


      var stsd = findBox_1(trak, ['mdia', 'minf', 'stbl', 'stsd'])[0];

      if (stsd) {
        var sampleDescriptions = stsd.subarray(8); // gives the codec type string

        track.codec = parseType_1(sampleDescriptions.subarray(4, 8));
        var codecBox = findBox_1(sampleDescriptions, [track.codec])[0];
        var codecConfig, codecConfigType;

        if (codecBox) {
          // https://tools.ietf.org/html/rfc6381#section-3.3
          if (/^[asm]vc[1-9]$/i.test(track.codec)) {
            // we don't need anything but the "config" parameter of the
            // avc1 codecBox
            codecConfig = codecBox.subarray(78);
            codecConfigType = parseType_1(codecConfig.subarray(4, 8));

            if (codecConfigType === 'avcC' && codecConfig.length > 11) {
              track.codec += '.'; // left padded with zeroes for single digit hex
              // profile idc

              track.codec += toHexString(codecConfig[9]); // the byte containing the constraint_set flags

              track.codec += toHexString(codecConfig[10]); // level idc

              track.codec += toHexString(codecConfig[11]);
            } else {
              // TODO: show a warning that we couldn't parse the codec
              // and are using the default
              track.codec = 'avc1.4d400d';
            }
          } else if (/^mp4[a,v]$/i.test(track.codec)) {
            // we do not need anything but the streamDescriptor of the mp4a codecBox
            codecConfig = codecBox.subarray(28);
            codecConfigType = parseType_1(codecConfig.subarray(4, 8));

            if (codecConfigType === 'esds' && codecConfig.length > 20 && codecConfig[19] !== 0) {
              track.codec += '.' + toHexString(codecConfig[19]); // this value is only a single digit

              track.codec += '.' + toHexString(codecConfig[20] >>> 2 & 0x3f).replace(/^0/, '');
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

      var mdhd = findBox_1(trak, ['mdia', 'mdhd'])[0];

      if (mdhd) {
        track.timescale = getTimescaleFromMediaHeader(mdhd);
      }

      tracks.push(track);
    });
    return tracks;
  };

  var probe$2 = {
    // export mp4 inspector's findBox and parseType for backwards compatibility
    findBox: findBox_1,
    parseType: parseType_1,
    timescale: timescale,
    startTime: startTime,
    compositionStartTime: compositionStartTime,
    videoTrackIds: getVideoTrackIds,
    tracks: getTracks,
    getTimescaleFromMediaHeader: getTimescaleFromMediaHeader
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */
  // Convert an array of nal units into an array of frames with each frame being
  // composed of the nal units that make up that frame
  // Also keep track of cummulative data about the frame from the nal units such
  // as the frame duration, starting pts, etc.
  var groupNalsIntoFrames = function groupNalsIntoFrames(nalUnits) {
    var i,
        currentNal,
        currentFrame = [],
        frames = []; // TODO added for LHLS, make sure this is OK

    frames.byteLength = 0;
    frames.nalCount = 0;
    frames.duration = 0;
    currentFrame.byteLength = 0;

    for (i = 0; i < nalUnits.length; i++) {
      currentNal = nalUnits[i]; // Split on 'aud'-type nal units

      if (currentNal.nalUnitType === 'access_unit_delimiter_rbsp') {
        // Since the very first nal unit is expected to be an AUD
        // only push to the frames array when currentFrame is not empty
        if (currentFrame.length) {
          currentFrame.duration = currentNal.dts - currentFrame.dts; // TODO added for LHLS, make sure this is OK

          frames.byteLength += currentFrame.byteLength;
          frames.nalCount += currentFrame.length;
          frames.duration += currentFrame.duration;
          frames.push(currentFrame);
        }

        currentFrame = [currentNal];
        currentFrame.byteLength = currentNal.data.byteLength;
        currentFrame.pts = currentNal.pts;
        currentFrame.dts = currentNal.dts;
      } else {
        // Specifically flag key frames for ease of use later
        if (currentNal.nalUnitType === 'slice_layer_without_partitioning_rbsp_idr') {
          currentFrame.keyFrame = true;
        }

        currentFrame.duration = currentNal.dts - currentFrame.dts;
        currentFrame.byteLength += currentNal.data.byteLength;
        currentFrame.push(currentNal);
      }
    } // For the last frame, use the duration of the previous frame if we
    // have nothing better to go on


    if (frames.length && (!currentFrame.duration || currentFrame.duration <= 0)) {
      currentFrame.duration = frames[frames.length - 1].duration;
    } // Push the final frame
    // TODO added for LHLS, make sure this is OK


    frames.byteLength += currentFrame.byteLength;
    frames.nalCount += currentFrame.length;
    frames.duration += currentFrame.duration;
    frames.push(currentFrame);
    return frames;
  }; // Convert an array of frames into an array of Gop with each Gop being composed
  // of the frames that make up that Gop
  // Also keep track of cummulative data about the Gop from the frames such as the
  // Gop duration, starting pts, etc.


  var groupFramesIntoGops = function groupFramesIntoGops(frames) {
    var i,
        currentFrame,
        currentGop = [],
        gops = []; // We must pre-set some of the values on the Gop since we
    // keep running totals of these values

    currentGop.byteLength = 0;
    currentGop.nalCount = 0;
    currentGop.duration = 0;
    currentGop.pts = frames[0].pts;
    currentGop.dts = frames[0].dts; // store some metadata about all the Gops

    gops.byteLength = 0;
    gops.nalCount = 0;
    gops.duration = 0;
    gops.pts = frames[0].pts;
    gops.dts = frames[0].dts;

    for (i = 0; i < frames.length; i++) {
      currentFrame = frames[i];

      if (currentFrame.keyFrame) {
        // Since the very first frame is expected to be an keyframe
        // only push to the gops array when currentGop is not empty
        if (currentGop.length) {
          gops.push(currentGop);
          gops.byteLength += currentGop.byteLength;
          gops.nalCount += currentGop.nalCount;
          gops.duration += currentGop.duration;
        }

        currentGop = [currentFrame];
        currentGop.nalCount = currentFrame.length;
        currentGop.byteLength = currentFrame.byteLength;
        currentGop.pts = currentFrame.pts;
        currentGop.dts = currentFrame.dts;
        currentGop.duration = currentFrame.duration;
      } else {
        currentGop.duration += currentFrame.duration;
        currentGop.nalCount += currentFrame.length;
        currentGop.byteLength += currentFrame.byteLength;
        currentGop.push(currentFrame);
      }
    }

    if (gops.length && currentGop.duration <= 0) {
      currentGop.duration = gops[gops.length - 1].duration;
    }

    gops.byteLength += currentGop.byteLength;
    gops.nalCount += currentGop.nalCount;
    gops.duration += currentGop.duration; // push the final Gop

    gops.push(currentGop);
    return gops;
  };
  /*
   * Search for the first keyframe in the GOPs and throw away all frames
   * until that keyframe. Then extend the duration of the pulled keyframe
   * and pull the PTS and DTS of the keyframe so that it covers the time
   * range of the frames that were disposed.
   *
   * @param {Array} gops video GOPs
   * @returns {Array} modified video GOPs
   */


  var extendFirstKeyFrame = function extendFirstKeyFrame(gops) {
    var currentGop;

    if (!gops[0][0].keyFrame && gops.length > 1) {
      // Remove the first GOP
      currentGop = gops.shift();
      gops.byteLength -= currentGop.byteLength;
      gops.nalCount -= currentGop.nalCount; // Extend the first frame of what is now the
      // first gop to cover the time period of the
      // frames we just removed

      gops[0][0].dts = currentGop.dts;
      gops[0][0].pts = currentGop.pts;
      gops[0][0].duration += currentGop.duration;
    }

    return gops;
  };
  /**
   * Default sample object
   * see ISO/IEC 14496-12:2012, section 8.6.4.3
   */


  var createDefaultSample = function createDefaultSample() {
    return {
      size: 0,
      flags: {
        isLeading: 0,
        dependsOn: 1,
        isDependedOn: 0,
        hasRedundancy: 0,
        degradationPriority: 0,
        isNonSyncSample: 1
      }
    };
  };
  /*
   * Collates information from a video frame into an object for eventual
   * entry into an MP4 sample table.
   *
   * @param {Object} frame the video frame
   * @param {Number} dataOffset the byte offset to position the sample
   * @return {Object} object containing sample table info for a frame
   */


  var sampleForFrame = function sampleForFrame(frame, dataOffset) {
    var sample = createDefaultSample();
    sample.dataOffset = dataOffset;
    sample.compositionTimeOffset = frame.pts - frame.dts;
    sample.duration = frame.duration;
    sample.size = 4 * frame.length; // Space for nal unit size

    sample.size += frame.byteLength;

    if (frame.keyFrame) {
      sample.flags.dependsOn = 2;
      sample.flags.isNonSyncSample = 0;
    }

    return sample;
  }; // generate the track's sample table from an array of gops


  var generateSampleTable$1 = function generateSampleTable(gops, baseDataOffset) {
    var h,
        i,
        sample,
        currentGop,
        currentFrame,
        dataOffset = baseDataOffset || 0,
        samples = [];

    for (h = 0; h < gops.length; h++) {
      currentGop = gops[h];

      for (i = 0; i < currentGop.length; i++) {
        currentFrame = currentGop[i];
        sample = sampleForFrame(currentFrame, dataOffset);
        dataOffset += sample.size;
        samples.push(sample);
      }
    }

    return samples;
  }; // generate the track's raw mdat data from an array of gops


  var concatenateNalData = function concatenateNalData(gops) {
    var h,
        i,
        j,
        currentGop,
        currentFrame,
        currentNal,
        dataOffset = 0,
        nalsByteLength = gops.byteLength,
        numberOfNals = gops.nalCount,
        totalByteLength = nalsByteLength + 4 * numberOfNals,
        data = new Uint8Array(totalByteLength),
        view = new DataView(data.buffer); // For each Gop..

    for (h = 0; h < gops.length; h++) {
      currentGop = gops[h]; // For each Frame..

      for (i = 0; i < currentGop.length; i++) {
        currentFrame = currentGop[i]; // For each NAL..

        for (j = 0; j < currentFrame.length; j++) {
          currentNal = currentFrame[j];
          view.setUint32(dataOffset, currentNal.data.byteLength);
          dataOffset += 4;
          data.set(currentNal.data, dataOffset);
          dataOffset += currentNal.data.byteLength;
        }
      }
    }

    return data;
  }; // generate the track's sample table from a frame


  var generateSampleTableForFrame = function generateSampleTableForFrame(frame, baseDataOffset) {
    var sample,
        dataOffset = baseDataOffset || 0,
        samples = [];
    sample = sampleForFrame(frame, dataOffset);
    samples.push(sample);
    return samples;
  }; // generate the track's raw mdat data from a frame


  var concatenateNalDataForFrame = function concatenateNalDataForFrame(frame) {
    var i,
        currentNal,
        dataOffset = 0,
        nalsByteLength = frame.byteLength,
        numberOfNals = frame.length,
        totalByteLength = nalsByteLength + 4 * numberOfNals,
        data = new Uint8Array(totalByteLength),
        view = new DataView(data.buffer); // For each NAL..

    for (i = 0; i < frame.length; i++) {
      currentNal = frame[i];
      view.setUint32(dataOffset, currentNal.data.byteLength);
      dataOffset += 4;
      data.set(currentNal.data, dataOffset);
      dataOffset += currentNal.data.byteLength;
    }

    return data;
  };

  var frameUtils = {
    groupNalsIntoFrames: groupNalsIntoFrames,
    groupFramesIntoGops: groupFramesIntoGops,
    extendFirstKeyFrame: extendFirstKeyFrame,
    generateSampleTable: generateSampleTable$1,
    concatenateNalData: concatenateNalData,
    generateSampleTableForFrame: generateSampleTableForFrame,
    concatenateNalDataForFrame: concatenateNalDataForFrame
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */
  var highPrefix = [33, 16, 5, 32, 164, 27];
  var lowPrefix = [33, 65, 108, 84, 1, 2, 4, 8, 168, 2, 4, 8, 17, 191, 252];

  var zeroFill = function zeroFill(count) {
    var a = [];

    while (count--) {
      a.push(0);
    }

    return a;
  };

  var makeTable = function makeTable(metaTable) {
    return Object.keys(metaTable).reduce(function (obj, key) {
      obj[key] = new Uint8Array(metaTable[key].reduce(function (arr, part) {
        return arr.concat(part);
      }, []));
      return obj;
    }, {});
  };

  var silence;

  var silence_1 = function silence_1() {
    if (!silence) {
      // Frames-of-silence to use for filling in missing AAC frames
      var coneOfSilence = {
        96000: [highPrefix, [227, 64], zeroFill(154), [56]],
        88200: [highPrefix, [231], zeroFill(170), [56]],
        64000: [highPrefix, [248, 192], zeroFill(240), [56]],
        48000: [highPrefix, [255, 192], zeroFill(268), [55, 148, 128], zeroFill(54), [112]],
        44100: [highPrefix, [255, 192], zeroFill(268), [55, 163, 128], zeroFill(84), [112]],
        32000: [highPrefix, [255, 192], zeroFill(268), [55, 234], zeroFill(226), [112]],
        24000: [highPrefix, [255, 192], zeroFill(268), [55, 255, 128], zeroFill(268), [111, 112], zeroFill(126), [224]],
        16000: [highPrefix, [255, 192], zeroFill(268), [55, 255, 128], zeroFill(268), [111, 255], zeroFill(269), [223, 108], zeroFill(195), [1, 192]],
        12000: [lowPrefix, zeroFill(268), [3, 127, 248], zeroFill(268), [6, 255, 240], zeroFill(268), [13, 255, 224], zeroFill(268), [27, 253, 128], zeroFill(259), [56]],
        11025: [lowPrefix, zeroFill(268), [3, 127, 248], zeroFill(268), [6, 255, 240], zeroFill(268), [13, 255, 224], zeroFill(268), [27, 255, 192], zeroFill(268), [55, 175, 128], zeroFill(108), [112]],
        8000: [lowPrefix, zeroFill(268), [3, 121, 16], zeroFill(47), [7]]
      };
      silence = makeTable(coneOfSilence);
    }

    return silence;
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  /**
   * Sum the `byteLength` properties of the data in each AAC frame
   */

  var sumFrameByteLengths = function sumFrameByteLengths(array) {
    var i,
        currentObj,
        sum = 0; // sum the byteLength's all each nal unit in the frame

    for (i = 0; i < array.length; i++) {
      currentObj = array[i];
      sum += currentObj.data.byteLength;
    }

    return sum;
  }; // Possibly pad (prefix) the audio track with silence if appending this track
  // would lead to the introduction of a gap in the audio buffer


  var prefixWithSilence = function prefixWithSilence(track, frames, audioAppendStartTs, videoBaseMediaDecodeTime) {
    var baseMediaDecodeTimeTs,
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

    baseMediaDecodeTimeTs = clock.audioTsToVideoTs(track.baseMediaDecodeTime, track.samplerate); // determine frame clock duration based on sample rate, round up to avoid overfills

    frameDuration = Math.ceil(clock.ONE_SECOND_IN_TS / (track.samplerate / 1024));

    if (audioAppendStartTs && videoBaseMediaDecodeTime) {
      // insert the shortest possible amount (audio gap or audio to video gap)
      audioGapDuration = baseMediaDecodeTimeTs - Math.max(audioAppendStartTs, videoBaseMediaDecodeTime); // number of full frames in the audio gap

      audioFillFrameCount = Math.floor(audioGapDuration / frameDuration);
      audioFillDuration = audioFillFrameCount * frameDuration;
    } // don't attempt to fill gaps smaller than a single frame or larger
    // than a half second


    if (audioFillFrameCount < 1 || audioFillDuration > clock.ONE_SECOND_IN_TS / 2) {
      return;
    }

    silentFrame = silence_1()[track.samplerate];

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

    track.baseMediaDecodeTime -= Math.floor(clock.videoTsToAudioTs(audioFillDuration, track.samplerate));
    return audioFillDuration;
  }; // If the audio segment extends before the earliest allowed dts
  // value, remove AAC frames until starts at or after the earliest
  // allowed DTS so that we don't end up with a negative baseMedia-
  // DecodeTime for the audio track


  var trimAdtsFramesByEarliestDts = function trimAdtsFramesByEarliestDts(adtsFrames, track, earliestAllowedDts) {
    if (track.minSegmentDts >= earliestAllowedDts) {
      return adtsFrames;
    } // We will need to recalculate the earliest segment Dts


    track.minSegmentDts = Infinity;
    return adtsFrames.filter(function (currentFrame) {
      // If this is an allowed frame, keep it and record it's Dts
      if (currentFrame.dts >= earliestAllowedDts) {
        track.minSegmentDts = Math.min(track.minSegmentDts, currentFrame.dts);
        track.minSegmentPts = track.minSegmentDts;
        return true;
      } // Otherwise, discard it


      return false;
    });
  }; // generate the track's raw mdat data from an array of frames


  var generateSampleTable = function generateSampleTable(frames) {
    var i,
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
  }; // generate the track's sample table from an array of frames


  var concatenateFrameData = function concatenateFrameData(frames) {
    var i,
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

  var audioFrameUtils = {
    prefixWithSilence: prefixWithSilence,
    trimAdtsFramesByEarliestDts: trimAdtsFramesByEarliestDts,
    generateSampleTable: generateSampleTable,
    concatenateFrameData: concatenateFrameData
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var ONE_SECOND_IN_TS$3 = clock.ONE_SECOND_IN_TS;
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
      scale = track.samplerate / ONE_SECOND_IN_TS$3;
      baseMediaDecodeTime *= scale;
      baseMediaDecodeTime = Math.floor(baseMediaDecodeTime);
    }

    return baseMediaDecodeTime;
  };

  var trackDecodeInfo = {
    clearDtsInfo: clearDtsInfo,
    calculateTrackBaseMediaDecodeTime: calculateTrackBaseMediaDecodeTime,
    collectDtsInfo: collectDtsInfo
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   *
   * Reads in-band caption information from a video elementary
   * stream. Captions must follow the CEA-708 standard for injection
   * into an MPEG-2 transport streams.
   * @see https://en.wikipedia.org/wiki/CEA-708
   * @see https://www.gpo.gov/fdsys/pkg/CFR-2007-title47-vol1/pdf/CFR-2007-title47-vol1-sec15-119.pdf
   */
  // payload type field to indicate how they are to be
  // interpreted. CEAS-708 caption content is always transmitted with
  // payload type 0x04.

  var USER_DATA_REGISTERED_ITU_T_T35 = 4,
      RBSP_TRAILING_BITS = 128;
  /**
    * Parse a supplemental enhancement information (SEI) NAL unit.
    * Stops parsing once a message of type ITU T T35 has been found.
    *
    * @param bytes {Uint8Array} the bytes of a SEI NAL unit
    * @return {object} the parsed SEI payload
    * @see Rec. ITU-T H.264, 7.3.2.3.1
    */

  var parseSei = function parseSei(bytes) {
    var i = 0,
        result = {
      payloadType: -1,
      payloadSize: 0
    },
        payloadType = 0,
        payloadSize = 0; // go through the sei_rbsp parsing each each individual sei_message

    while (i < bytes.byteLength) {
      // stop once we have hit the end of the sei_rbsp
      if (bytes[i] === RBSP_TRAILING_BITS) {
        break;
      } // Parse payload type


      while (bytes[i] === 0xFF) {
        payloadType += 255;
        i++;
      }

      payloadType += bytes[i++]; // Parse payload size

      while (bytes[i] === 0xFF) {
        payloadSize += 255;
        i++;
      }

      payloadSize += bytes[i++]; // this sei_message is a 608/708 caption so save it and break
      // there can only ever be one caption message in a frame's sei

      if (!result.payload && payloadType === USER_DATA_REGISTERED_ITU_T_T35) {
        var userIdentifier = String.fromCharCode(bytes[i + 3], bytes[i + 4], bytes[i + 5], bytes[i + 6]);

        if (userIdentifier === 'GA94') {
          result.payloadType = payloadType;
          result.payloadSize = payloadSize;
          result.payload = bytes.subarray(i, i + payloadSize);
          break;
        } else {
          result.payload = void 0;
        }
      } // skip the payload and parse the next message


      i += payloadSize;
      payloadType = 0;
      payloadSize = 0;
    }

    return result;
  }; // see ANSI/SCTE 128-1 (2013), section 8.1


  var parseUserData = function parseUserData(sei) {
    // itu_t_t35_contry_code must be 181 (United States) for
    // captions
    if (sei.payload[0] !== 181) {
      return null;
    } // itu_t_t35_provider_code should be 49 (ATSC) for captions


    if ((sei.payload[1] << 8 | sei.payload[2]) !== 49) {
      return null;
    } // the user_identifier should be "GA94" to indicate ATSC1 data


    if (String.fromCharCode(sei.payload[3], sei.payload[4], sei.payload[5], sei.payload[6]) !== 'GA94') {
      return null;
    } // finally, user_data_type_code should be 0x03 for caption data


    if (sei.payload[7] !== 0x03) {
      return null;
    } // return the user_data_type_structure and strip the trailing
    // marker bits


    return sei.payload.subarray(8, sei.payload.length - 1);
  }; // see CEA-708-D, section 4.4


  var parseCaptionPackets = function parseCaptionPackets(pts, userData) {
    var results = [],
        i,
        count,
        offset,
        data; // if this is just filler, return immediately

    if (!(userData[0] & 0x40)) {
      return results;
    } // parse out the cc_data_1 and cc_data_2 fields


    count = userData[0] & 0x1f;

    for (i = 0; i < count; i++) {
      offset = i * 3;
      data = {
        type: userData[offset + 2] & 0x03,
        pts: pts
      }; // capture cc data when cc_valid is 1

      if (userData[offset + 2] & 0x04) {
        data.ccData = userData[offset + 3] << 8 | userData[offset + 4];
        results.push(data);
      }
    }

    return results;
  };

  var discardEmulationPreventionBytes$1 = function discardEmulationPreventionBytes(data) {
    var length = data.byteLength,
        emulationPreventionBytesPositions = [],
        i = 1,
        newLength,
        newData; // Find all `Emulation Prevention Bytes`

    while (i < length - 2) {
      if (data[i] === 0 && data[i + 1] === 0 && data[i + 2] === 0x03) {
        emulationPreventionBytesPositions.push(i + 2);
        i += 2;
      } else {
        i++;
      }
    } // If no Emulation Prevention Bytes were found just return the original
    // array


    if (emulationPreventionBytesPositions.length === 0) {
      return data;
    } // Create a new array to hold the NAL unit data


    newLength = length - emulationPreventionBytesPositions.length;
    newData = new Uint8Array(newLength);
    var sourceIndex = 0;

    for (i = 0; i < newLength; sourceIndex++, i++) {
      if (sourceIndex === emulationPreventionBytesPositions[0]) {
        // Skip this byte
        sourceIndex++; // Remove this position index

        emulationPreventionBytesPositions.shift();
      }

      newData[i] = data[sourceIndex];
    }

    return newData;
  }; // exports


  var captionPacketParser = {
    parseSei: parseSei,
    parseUserData: parseUserData,
    parseCaptionPackets: parseCaptionPackets,
    discardEmulationPreventionBytes: discardEmulationPreventionBytes$1,
    USER_DATA_REGISTERED_ITU_T_T35: USER_DATA_REGISTERED_ITU_T_T35
  };

  // Link To Transport
  // -----------------


  var CaptionStream$1 = function CaptionStream(options) {
    options = options || {};
    CaptionStream.prototype.init.call(this); // parse708captions flag, default to true

    this.parse708captions_ = typeof options.parse708captions === 'boolean' ? options.parse708captions : true;
    this.captionPackets_ = [];
    this.ccStreams_ = [new Cea608Stream(0, 0), // eslint-disable-line no-use-before-define
    new Cea608Stream(0, 1), // eslint-disable-line no-use-before-define
    new Cea608Stream(1, 0), // eslint-disable-line no-use-before-define
    new Cea608Stream(1, 1) // eslint-disable-line no-use-before-define
    ];

    if (this.parse708captions_) {
      this.cc708Stream_ = new Cea708Stream({
        captionServices: options.captionServices
      }); // eslint-disable-line no-use-before-define
    }

    this.reset(); // forward data and done events from CCs to this CaptionStream

    this.ccStreams_.forEach(function (cc) {
      cc.on('data', this.trigger.bind(this, 'data'));
      cc.on('partialdone', this.trigger.bind(this, 'partialdone'));
      cc.on('done', this.trigger.bind(this, 'done'));
    }, this);

    if (this.parse708captions_) {
      this.cc708Stream_.on('data', this.trigger.bind(this, 'data'));
      this.cc708Stream_.on('partialdone', this.trigger.bind(this, 'partialdone'));
      this.cc708Stream_.on('done', this.trigger.bind(this, 'done'));
    }
  };

  CaptionStream$1.prototype = new stream();

  CaptionStream$1.prototype.push = function (event) {
    var sei, userData, newCaptionPackets; // only examine SEI NALs

    if (event.nalUnitType !== 'sei_rbsp') {
      return;
    } // parse the sei


    sei = captionPacketParser.parseSei(event.escapedRBSP); // no payload data, skip

    if (!sei.payload) {
      return;
    } // ignore everything but user_data_registered_itu_t_t35


    if (sei.payloadType !== captionPacketParser.USER_DATA_REGISTERED_ITU_T_T35) {
      return;
    } // parse out the user data payload


    userData = captionPacketParser.parseUserData(sei); // ignore unrecognized userData

    if (!userData) {
      return;
    } // Sometimes, the same segment # will be downloaded twice. To stop the
    // caption data from being processed twice, we track the latest dts we've
    // received and ignore everything with a dts before that. However, since
    // data for a specific dts can be split across packets on either side of
    // a segment boundary, we need to make sure we *don't* ignore the packets
    // from the *next* segment that have dts === this.latestDts_. By constantly
    // tracking the number of packets received with dts === this.latestDts_, we
    // know how many should be ignored once we start receiving duplicates.


    if (event.dts < this.latestDts_) {
      // We've started getting older data, so set the flag.
      this.ignoreNextEqualDts_ = true;
      return;
    } else if (event.dts === this.latestDts_ && this.ignoreNextEqualDts_) {
      this.numSameDts_--;

      if (!this.numSameDts_) {
        // We've received the last duplicate packet, time to start processing again
        this.ignoreNextEqualDts_ = false;
      }

      return;
    } // parse out CC data packets and save them for later


    newCaptionPackets = captionPacketParser.parseCaptionPackets(event.pts, userData);
    this.captionPackets_ = this.captionPackets_.concat(newCaptionPackets);

    if (this.latestDts_ !== event.dts) {
      this.numSameDts_ = 0;
    }

    this.numSameDts_++;
    this.latestDts_ = event.dts;
  };

  CaptionStream$1.prototype.flushCCStreams = function (flushType) {
    this.ccStreams_.forEach(function (cc) {
      return flushType === 'flush' ? cc.flush() : cc.partialFlush();
    }, this);
  };

  CaptionStream$1.prototype.flushStream = function (flushType) {
    // make sure we actually parsed captions before proceeding
    if (!this.captionPackets_.length) {
      this.flushCCStreams(flushType);
      return;
    } // In Chrome, the Array#sort function is not stable so add a
    // presortIndex that we can use to ensure we get a stable-sort


    this.captionPackets_.forEach(function (elem, idx) {
      elem.presortIndex = idx;
    }); // sort caption byte-pairs based on their PTS values

    this.captionPackets_.sort(function (a, b) {
      if (a.pts === b.pts) {
        return a.presortIndex - b.presortIndex;
      }

      return a.pts - b.pts;
    });
    this.captionPackets_.forEach(function (packet) {
      if (packet.type < 2) {
        // Dispatch packet to the right Cea608Stream
        this.dispatchCea608Packet(packet);
      } else {
        // Dispatch packet to the Cea708Stream
        this.dispatchCea708Packet(packet);
      }
    }, this);
    this.captionPackets_.length = 0;
    this.flushCCStreams(flushType);
  };

  CaptionStream$1.prototype.flush = function () {
    return this.flushStream('flush');
  }; // Only called if handling partial data


  CaptionStream$1.prototype.partialFlush = function () {
    return this.flushStream('partialFlush');
  };

  CaptionStream$1.prototype.reset = function () {
    this.latestDts_ = null;
    this.ignoreNextEqualDts_ = false;
    this.numSameDts_ = 0;
    this.activeCea608Channel_ = [null, null];
    this.ccStreams_.forEach(function (ccStream) {
      ccStream.reset();
    });
  }; // From the CEA-608 spec:

  /*
   * When XDS sub-packets are interleaved with other services, the end of each sub-packet shall be followed
   * by a control pair to change to a different service. When any of the control codes from 0x10 to 0x1F is
   * used to begin a control code pair, it indicates the return to captioning or Text data. The control code pair
   * and subsequent data should then be processed according to the FCC rules. It may be necessary for the
   * line 21 data encoder to automatically insert a control code pair (i.e. RCL, RU2, RU3, RU4, RDC, or RTD)
   * to switch to captioning or Text.
  */
  // With that in mind, we ignore any data between an XDS control code and a
  // subsequent closed-captioning control code.


  CaptionStream$1.prototype.dispatchCea608Packet = function (packet) {
    // NOTE: packet.type is the CEA608 field
    if (this.setsTextOrXDSActive(packet)) {
      this.activeCea608Channel_[packet.type] = null;
    } else if (this.setsChannel1Active(packet)) {
      this.activeCea608Channel_[packet.type] = 0;
    } else if (this.setsChannel2Active(packet)) {
      this.activeCea608Channel_[packet.type] = 1;
    }

    if (this.activeCea608Channel_[packet.type] === null) {
      // If we haven't received anything to set the active channel, or the
      // packets are Text/XDS data, discard the data; we don't want jumbled
      // captions
      return;
    }

    this.ccStreams_[(packet.type << 1) + this.activeCea608Channel_[packet.type]].push(packet);
  };

  CaptionStream$1.prototype.setsChannel1Active = function (packet) {
    return (packet.ccData & 0x7800) === 0x1000;
  };

  CaptionStream$1.prototype.setsChannel2Active = function (packet) {
    return (packet.ccData & 0x7800) === 0x1800;
  };

  CaptionStream$1.prototype.setsTextOrXDSActive = function (packet) {
    return (packet.ccData & 0x7100) === 0x0100 || (packet.ccData & 0x78fe) === 0x102a || (packet.ccData & 0x78fe) === 0x182a;
  };

  CaptionStream$1.prototype.dispatchCea708Packet = function (packet) {
    if (this.parse708captions_) {
      this.cc708Stream_.push(packet);
    }
  }; // ----------------------
  // Session to Application
  // ----------------------
  // This hash maps special and extended character codes to their
  // proper Unicode equivalent. The first one-byte key is just a
  // non-standard character code. The two-byte keys that follow are
  // the extended CEA708 character codes, along with the preceding
  // 0x10 extended character byte to distinguish these codes from
  // non-extended character codes. Every CEA708 character code that
  // is not in this object maps directly to a standard unicode
  // character code.
  // The transparent space and non-breaking transparent space are
  // technically not fully supported since there is no code to
  // make them transparent, so they have normal non-transparent
  // stand-ins.
  // The special closed caption (CC) character isn't a standard
  // unicode character, so a fairly similar unicode character was
  // chosen in it's place.


  var CHARACTER_TRANSLATION_708 = {
    0x7f: 0x266a,
    // ♪
    0x1020: 0x20,
    // Transparent Space
    0x1021: 0xa0,
    // Nob-breaking Transparent Space
    0x1025: 0x2026,
    // …
    0x102a: 0x0160,
    // Š
    0x102c: 0x0152,
    // Œ
    0x1030: 0x2588,
    // █
    0x1031: 0x2018,
    // ‘
    0x1032: 0x2019,
    // ’
    0x1033: 0x201c,
    // “
    0x1034: 0x201d,
    // ”
    0x1035: 0x2022,
    // •
    0x1039: 0x2122,
    // ™
    0x103a: 0x0161,
    // š
    0x103c: 0x0153,
    // œ
    0x103d: 0x2120,
    // ℠
    0x103f: 0x0178,
    // Ÿ
    0x1076: 0x215b,
    // ⅛
    0x1077: 0x215c,
    // ⅜
    0x1078: 0x215d,
    // ⅝
    0x1079: 0x215e,
    // ⅞
    0x107a: 0x23d0,
    // ⏐
    0x107b: 0x23a4,
    // ⎤
    0x107c: 0x23a3,
    // ⎣
    0x107d: 0x23af,
    // ⎯
    0x107e: 0x23a6,
    // ⎦
    0x107f: 0x23a1,
    // ⎡
    0x10a0: 0x3138 // ㄸ (CC char)

  };

  var get708CharFromCode = function get708CharFromCode(code) {
    var newCode = CHARACTER_TRANSLATION_708[code] || code;

    if (code & 0x1000 && code === newCode) {
      // Invalid extended code
      return '';
    }

    return String.fromCharCode(newCode);
  };

  var within708TextBlock = function within708TextBlock(b) {
    return 0x20 <= b && b <= 0x7f || 0xa0 <= b && b <= 0xff;
  };

  var Cea708Window = function Cea708Window(windowNum) {
    this.windowNum = windowNum;
    this.reset();
  };

  Cea708Window.prototype.reset = function () {
    this.clearText();
    this.pendingNewLine = false;
    this.winAttr = {};
    this.penAttr = {};
    this.penLoc = {};
    this.penColor = {}; // These default values are arbitrary,
    // defineWindow will usually override them

    this.visible = 0;
    this.rowLock = 0;
    this.columnLock = 0;
    this.priority = 0;
    this.relativePositioning = 0;
    this.anchorVertical = 0;
    this.anchorHorizontal = 0;
    this.anchorPoint = 0;
    this.rowCount = 1;
    this.virtualRowCount = this.rowCount + 1;
    this.columnCount = 41;
    this.windowStyle = 0;
    this.penStyle = 0;
  };

  Cea708Window.prototype.getText = function () {
    return this.rows.join('\n');
  };

  Cea708Window.prototype.clearText = function () {
    this.rows = [''];
    this.rowIdx = 0;
  };

  Cea708Window.prototype.newLine = function (pts) {
    if (this.rows.length >= this.virtualRowCount && typeof this.beforeRowOverflow === 'function') {
      this.beforeRowOverflow(pts);
    }

    if (this.rows.length > 0) {
      this.rows.push('');
      this.rowIdx++;
    } // Show all virtual rows since there's no visible scrolling


    while (this.rows.length > this.virtualRowCount) {
      this.rows.shift();
      this.rowIdx--;
    }
  };

  Cea708Window.prototype.isEmpty = function () {
    if (this.rows.length === 0) {
      return true;
    } else if (this.rows.length === 1) {
      return this.rows[0] === '';
    }

    return false;
  };

  Cea708Window.prototype.addText = function (text) {
    this.rows[this.rowIdx] += text;
  };

  Cea708Window.prototype.backspace = function () {
    if (!this.isEmpty()) {
      var row = this.rows[this.rowIdx];
      this.rows[this.rowIdx] = row.substr(0, row.length - 1);
    }
  };

  var Cea708Service = function Cea708Service(serviceNum, encoding, stream) {
    this.serviceNum = serviceNum;
    this.text = '';
    this.currentWindow = new Cea708Window(-1);
    this.windows = [];
    this.stream = stream; // Try to setup a TextDecoder if an `encoding` value was provided

    if (typeof encoding === 'string') {
      this.createTextDecoder(encoding);
    }
  };
  /**
   * Initialize service windows
   * Must be run before service use
   *
   * @param  {Integer}  pts               PTS value
   * @param  {Function} beforeRowOverflow Function to execute before row overflow of a window
   */


  Cea708Service.prototype.init = function (pts, beforeRowOverflow) {
    this.startPts = pts;

    for (var win = 0; win < 8; win++) {
      this.windows[win] = new Cea708Window(win);

      if (typeof beforeRowOverflow === 'function') {
        this.windows[win].beforeRowOverflow = beforeRowOverflow;
      }
    }
  };
  /**
   * Set current window of service to be affected by commands
   *
   * @param  {Integer} windowNum Window number
   */


  Cea708Service.prototype.setCurrentWindow = function (windowNum) {
    this.currentWindow = this.windows[windowNum];
  };
  /**
   * Try to create a TextDecoder if it is natively supported
   */


  Cea708Service.prototype.createTextDecoder = function (encoding) {
    if (typeof TextDecoder === 'undefined') {
      this.stream.trigger('log', {
        level: 'warn',
        message: 'The `encoding` option is unsupported without TextDecoder support'
      });
    } else {
      try {
        this.textDecoder_ = new TextDecoder(encoding);
      } catch (error) {
        this.stream.trigger('log', {
          level: 'warn',
          message: 'TextDecoder could not be created with ' + encoding + ' encoding. ' + error
        });
      }
    }
  };

  var Cea708Stream = function Cea708Stream(options) {
    options = options || {};
    Cea708Stream.prototype.init.call(this);
    var self = this;
    var captionServices = options.captionServices || {};
    var captionServiceEncodings = {};
    var serviceProps; // Get service encodings from captionServices option block

    Object.keys(captionServices).forEach(function (serviceName) {
      serviceProps = captionServices[serviceName];

      if (/^SERVICE/.test(serviceName)) {
        captionServiceEncodings[serviceName] = serviceProps.encoding;
      }
    });
    this.serviceEncodings = captionServiceEncodings;
    this.current708Packet = null;
    this.services = {};

    this.push = function (packet) {
      if (packet.type === 3) {
        // 708 packet start
        self.new708Packet();
        self.add708Bytes(packet);
      } else {
        if (self.current708Packet === null) {
          // This should only happen at the start of a file if there's no packet start.
          self.new708Packet();
        }

        self.add708Bytes(packet);
      }
    };
  };

  Cea708Stream.prototype = new stream();
  /**
   * Push current 708 packet, create new 708 packet.
   */

  Cea708Stream.prototype.new708Packet = function () {
    if (this.current708Packet !== null) {
      this.push708Packet();
    }

    this.current708Packet = {
      data: [],
      ptsVals: []
    };
  };
  /**
   * Add pts and both bytes from packet into current 708 packet.
   */


  Cea708Stream.prototype.add708Bytes = function (packet) {
    var data = packet.ccData;
    var byte0 = data >>> 8;
    var byte1 = data & 0xff; // I would just keep a list of packets instead of bytes, but it isn't clear in the spec
    // that service blocks will always line up with byte pairs.

    this.current708Packet.ptsVals.push(packet.pts);
    this.current708Packet.data.push(byte0);
    this.current708Packet.data.push(byte1);
  };
  /**
   * Parse completed 708 packet into service blocks and push each service block.
   */


  Cea708Stream.prototype.push708Packet = function () {
    var packet708 = this.current708Packet;
    var packetData = packet708.data;
    var serviceNum = null;
    var blockSize = null;
    var i = 0;
    var b = packetData[i++];
    packet708.seq = b >> 6;
    packet708.sizeCode = b & 0x3f; // 0b00111111;

    for (; i < packetData.length; i++) {
      b = packetData[i++];
      serviceNum = b >> 5;
      blockSize = b & 0x1f; // 0b00011111

      if (serviceNum === 7 && blockSize > 0) {
        // Extended service num
        b = packetData[i++];
        serviceNum = b;
      }

      this.pushServiceBlock(serviceNum, i, blockSize);

      if (blockSize > 0) {
        i += blockSize - 1;
      }
    }
  };
  /**
   * Parse service block, execute commands, read text.
   *
   * Note: While many of these commands serve important purposes,
   * many others just parse out the parameters or attributes, but
   * nothing is done with them because this is not a full and complete
   * implementation of the entire 708 spec.
   *
   * @param  {Integer} serviceNum Service number
   * @param  {Integer} start      Start index of the 708 packet data
   * @param  {Integer} size       Block size
   */


  Cea708Stream.prototype.pushServiceBlock = function (serviceNum, start, size) {
    var b;
    var i = start;
    var packetData = this.current708Packet.data;
    var service = this.services[serviceNum];

    if (!service) {
      service = this.initService(serviceNum, i);
    }

    for (; i < start + size && i < packetData.length; i++) {
      b = packetData[i];

      if (within708TextBlock(b)) {
        i = this.handleText(i, service);
      } else if (b === 0x18) {
        i = this.multiByteCharacter(i, service);
      } else if (b === 0x10) {
        i = this.extendedCommands(i, service);
      } else if (0x80 <= b && b <= 0x87) {
        i = this.setCurrentWindow(i, service);
      } else if (0x98 <= b && b <= 0x9f) {
        i = this.defineWindow(i, service);
      } else if (b === 0x88) {
        i = this.clearWindows(i, service);
      } else if (b === 0x8c) {
        i = this.deleteWindows(i, service);
      } else if (b === 0x89) {
        i = this.displayWindows(i, service);
      } else if (b === 0x8a) {
        i = this.hideWindows(i, service);
      } else if (b === 0x8b) {
        i = this.toggleWindows(i, service);
      } else if (b === 0x97) {
        i = this.setWindowAttributes(i, service);
      } else if (b === 0x90) {
        i = this.setPenAttributes(i, service);
      } else if (b === 0x91) {
        i = this.setPenColor(i, service);
      } else if (b === 0x92) {
        i = this.setPenLocation(i, service);
      } else if (b === 0x8f) {
        service = this.reset(i, service);
      } else if (b === 0x08) {
        // BS: Backspace
        service.currentWindow.backspace();
      } else if (b === 0x0c) {
        // FF: Form feed
        service.currentWindow.clearText();
      } else if (b === 0x0d) {
        // CR: Carriage return
        service.currentWindow.pendingNewLine = true;
      } else if (b === 0x0e) {
        // HCR: Horizontal carriage return
        service.currentWindow.clearText();
      } else if (b === 0x8d) {
        // DLY: Delay, nothing to do
        i++;
      } else ;
    }
  };
  /**
   * Execute an extended command
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.extendedCommands = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[++i];

    if (within708TextBlock(b)) {
      i = this.handleText(i, service, {
        isExtended: true
      });
    }

    return i;
  };
  /**
   * Get PTS value of a given byte index
   *
   * @param  {Integer} byteIndex  Index of the byte
   * @return {Integer}            PTS
   */


  Cea708Stream.prototype.getPts = function (byteIndex) {
    // There's 1 pts value per 2 bytes
    return this.current708Packet.ptsVals[Math.floor(byteIndex / 2)];
  };
  /**
   * Initializes a service
   *
   * @param  {Integer} serviceNum Service number
   * @return {Service}            Initialized service object
   */


  Cea708Stream.prototype.initService = function (serviceNum, i) {
    var serviceName = 'SERVICE' + serviceNum;
    var self = this;
    var serviceName;
    var encoding;

    if (serviceName in this.serviceEncodings) {
      encoding = this.serviceEncodings[serviceName];
    }

    this.services[serviceNum] = new Cea708Service(serviceNum, encoding, self);
    this.services[serviceNum].init(this.getPts(i), function (pts) {
      self.flushDisplayed(pts, self.services[serviceNum]);
    });
    return this.services[serviceNum];
  };
  /**
   * Execute text writing to current window
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.handleText = function (i, service, options) {
    var isExtended = options && options.isExtended;
    var isMultiByte = options && options.isMultiByte;
    var packetData = this.current708Packet.data;
    var extended = isExtended ? 0x1000 : 0x0000;
    var currentByte = packetData[i];
    var nextByte = packetData[i + 1];
    var win = service.currentWindow;
    var char;
    var charCodeArray; // Use the TextDecoder if one was created for this service

    if (service.textDecoder_ && !isExtended) {
      if (isMultiByte) {
        charCodeArray = [currentByte, nextByte];
        i++;
      } else {
        charCodeArray = [currentByte];
      }

      char = service.textDecoder_.decode(new Uint8Array(charCodeArray));
    } else {
      char = get708CharFromCode(extended | currentByte);
    }

    if (win.pendingNewLine && !win.isEmpty()) {
      win.newLine(this.getPts(i));
    }

    win.pendingNewLine = false;
    win.addText(char);
    return i;
  };
  /**
   * Handle decoding of multibyte character
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.multiByteCharacter = function (i, service) {
    var packetData = this.current708Packet.data;
    var firstByte = packetData[i + 1];
    var secondByte = packetData[i + 2];

    if (within708TextBlock(firstByte) && within708TextBlock(secondByte)) {
      i = this.handleText(++i, service, {
        isMultiByte: true
      });
    }

    return i;
  };
  /**
   * Parse and execute the CW# command.
   *
   * Set the current window.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.setCurrentWindow = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[i];
    var windowNum = b & 0x07;
    service.setCurrentWindow(windowNum);
    return i;
  };
  /**
   * Parse and execute the DF# command.
   *
   * Define a window and set it as the current window.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.defineWindow = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[i];
    var windowNum = b & 0x07;
    service.setCurrentWindow(windowNum);
    var win = service.currentWindow;
    b = packetData[++i];
    win.visible = (b & 0x20) >> 5; // v

    win.rowLock = (b & 0x10) >> 4; // rl

    win.columnLock = (b & 0x08) >> 3; // cl

    win.priority = b & 0x07; // p

    b = packetData[++i];
    win.relativePositioning = (b & 0x80) >> 7; // rp

    win.anchorVertical = b & 0x7f; // av

    b = packetData[++i];
    win.anchorHorizontal = b; // ah

    b = packetData[++i];
    win.anchorPoint = (b & 0xf0) >> 4; // ap

    win.rowCount = b & 0x0f; // rc

    b = packetData[++i];
    win.columnCount = b & 0x3f; // cc

    b = packetData[++i];
    win.windowStyle = (b & 0x38) >> 3; // ws

    win.penStyle = b & 0x07; // ps
    // The spec says there are (rowCount+1) "virtual rows"

    win.virtualRowCount = win.rowCount + 1;
    return i;
  };
  /**
   * Parse and execute the SWA command.
   *
   * Set attributes of the current window.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.setWindowAttributes = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[i];
    var winAttr = service.currentWindow.winAttr;
    b = packetData[++i];
    winAttr.fillOpacity = (b & 0xc0) >> 6; // fo

    winAttr.fillRed = (b & 0x30) >> 4; // fr

    winAttr.fillGreen = (b & 0x0c) >> 2; // fg

    winAttr.fillBlue = b & 0x03; // fb

    b = packetData[++i];
    winAttr.borderType = (b & 0xc0) >> 6; // bt

    winAttr.borderRed = (b & 0x30) >> 4; // br

    winAttr.borderGreen = (b & 0x0c) >> 2; // bg

    winAttr.borderBlue = b & 0x03; // bb

    b = packetData[++i];
    winAttr.borderType += (b & 0x80) >> 5; // bt

    winAttr.wordWrap = (b & 0x40) >> 6; // ww

    winAttr.printDirection = (b & 0x30) >> 4; // pd

    winAttr.scrollDirection = (b & 0x0c) >> 2; // sd

    winAttr.justify = b & 0x03; // j

    b = packetData[++i];
    winAttr.effectSpeed = (b & 0xf0) >> 4; // es

    winAttr.effectDirection = (b & 0x0c) >> 2; // ed

    winAttr.displayEffect = b & 0x03; // de

    return i;
  };
  /**
   * Gather text from all displayed windows and push a caption to output.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   */


  Cea708Stream.prototype.flushDisplayed = function (pts, service) {
    var displayedText = []; // TODO: Positioning not supported, displaying multiple windows will not necessarily
    // display text in the correct order, but sample files so far have not shown any issue.

    for (var winId = 0; winId < 8; winId++) {
      if (service.windows[winId].visible && !service.windows[winId].isEmpty()) {
        displayedText.push(service.windows[winId].getText());
      }
    }

    service.endPts = pts;
    service.text = displayedText.join('\n\n');
    this.pushCaption(service);
    service.startPts = pts;
  };
  /**
   * Push a caption to output if the caption contains text.
   *
   * @param  {Service} service  The service object to be affected
   */


  Cea708Stream.prototype.pushCaption = function (service) {
    if (service.text !== '') {
      this.trigger('data', {
        startPts: service.startPts,
        endPts: service.endPts,
        text: service.text,
        stream: 'cc708_' + service.serviceNum
      });
      service.text = '';
      service.startPts = service.endPts;
    }
  };
  /**
   * Parse and execute the DSW command.
   *
   * Set visible property of windows based on the parsed bitmask.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.displayWindows = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[++i];
    var pts = this.getPts(i);
    this.flushDisplayed(pts, service);

    for (var winId = 0; winId < 8; winId++) {
      if (b & 0x01 << winId) {
        service.windows[winId].visible = 1;
      }
    }

    return i;
  };
  /**
   * Parse and execute the HDW command.
   *
   * Set visible property of windows based on the parsed bitmask.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.hideWindows = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[++i];
    var pts = this.getPts(i);
    this.flushDisplayed(pts, service);

    for (var winId = 0; winId < 8; winId++) {
      if (b & 0x01 << winId) {
        service.windows[winId].visible = 0;
      }
    }

    return i;
  };
  /**
   * Parse and execute the TGW command.
   *
   * Set visible property of windows based on the parsed bitmask.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.toggleWindows = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[++i];
    var pts = this.getPts(i);
    this.flushDisplayed(pts, service);

    for (var winId = 0; winId < 8; winId++) {
      if (b & 0x01 << winId) {
        service.windows[winId].visible ^= 1;
      }
    }

    return i;
  };
  /**
   * Parse and execute the CLW command.
   *
   * Clear text of windows based on the parsed bitmask.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.clearWindows = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[++i];
    var pts = this.getPts(i);
    this.flushDisplayed(pts, service);

    for (var winId = 0; winId < 8; winId++) {
      if (b & 0x01 << winId) {
        service.windows[winId].clearText();
      }
    }

    return i;
  };
  /**
   * Parse and execute the DLW command.
   *
   * Re-initialize windows based on the parsed bitmask.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.deleteWindows = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[++i];
    var pts = this.getPts(i);
    this.flushDisplayed(pts, service);

    for (var winId = 0; winId < 8; winId++) {
      if (b & 0x01 << winId) {
        service.windows[winId].reset();
      }
    }

    return i;
  };
  /**
   * Parse and execute the SPA command.
   *
   * Set pen attributes of the current window.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.setPenAttributes = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[i];
    var penAttr = service.currentWindow.penAttr;
    b = packetData[++i];
    penAttr.textTag = (b & 0xf0) >> 4; // tt

    penAttr.offset = (b & 0x0c) >> 2; // o

    penAttr.penSize = b & 0x03; // s

    b = packetData[++i];
    penAttr.italics = (b & 0x80) >> 7; // i

    penAttr.underline = (b & 0x40) >> 6; // u

    penAttr.edgeType = (b & 0x38) >> 3; // et

    penAttr.fontStyle = b & 0x07; // fs

    return i;
  };
  /**
   * Parse and execute the SPC command.
   *
   * Set pen color of the current window.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.setPenColor = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[i];
    var penColor = service.currentWindow.penColor;
    b = packetData[++i];
    penColor.fgOpacity = (b & 0xc0) >> 6; // fo

    penColor.fgRed = (b & 0x30) >> 4; // fr

    penColor.fgGreen = (b & 0x0c) >> 2; // fg

    penColor.fgBlue = b & 0x03; // fb

    b = packetData[++i];
    penColor.bgOpacity = (b & 0xc0) >> 6; // bo

    penColor.bgRed = (b & 0x30) >> 4; // br

    penColor.bgGreen = (b & 0x0c) >> 2; // bg

    penColor.bgBlue = b & 0x03; // bb

    b = packetData[++i];
    penColor.edgeRed = (b & 0x30) >> 4; // er

    penColor.edgeGreen = (b & 0x0c) >> 2; // eg

    penColor.edgeBlue = b & 0x03; // eb

    return i;
  };
  /**
   * Parse and execute the SPL command.
   *
   * Set pen location of the current window.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Integer}          New index after parsing
   */


  Cea708Stream.prototype.setPenLocation = function (i, service) {
    var packetData = this.current708Packet.data;
    var b = packetData[i];
    var penLoc = service.currentWindow.penLoc; // Positioning isn't really supported at the moment, so this essentially just inserts a linebreak

    service.currentWindow.pendingNewLine = true;
    b = packetData[++i];
    penLoc.row = b & 0x0f; // r

    b = packetData[++i];
    penLoc.column = b & 0x3f; // c

    return i;
  };
  /**
   * Execute the RST command.
   *
   * Reset service to a clean slate. Re-initialize.
   *
   * @param  {Integer} i        Current index in the 708 packet
   * @param  {Service} service  The service object to be affected
   * @return {Service}          Re-initialized service
   */


  Cea708Stream.prototype.reset = function (i, service) {
    var pts = this.getPts(i);
    this.flushDisplayed(pts, service);
    return this.initService(service.serviceNum, i);
  }; // This hash maps non-ASCII, special, and extended character codes to their
  // proper Unicode equivalent. The first keys that are only a single byte
  // are the non-standard ASCII characters, which simply map the CEA608 byte
  // to the standard ASCII/Unicode. The two-byte keys that follow are the CEA608
  // character codes, but have their MSB bitmasked with 0x03 so that a lookup
  // can be performed regardless of the field and data channel on which the
  // character code was received.


  var CHARACTER_TRANSLATION = {
    0x2a: 0xe1,
    // á
    0x5c: 0xe9,
    // é
    0x5e: 0xed,
    // í
    0x5f: 0xf3,
    // ó
    0x60: 0xfa,
    // ú
    0x7b: 0xe7,
    // ç
    0x7c: 0xf7,
    // ÷
    0x7d: 0xd1,
    // Ñ
    0x7e: 0xf1,
    // ñ
    0x7f: 0x2588,
    // █
    0x0130: 0xae,
    // ®
    0x0131: 0xb0,
    // °
    0x0132: 0xbd,
    // ½
    0x0133: 0xbf,
    // ¿
    0x0134: 0x2122,
    // ™
    0x0135: 0xa2,
    // ¢
    0x0136: 0xa3,
    // £
    0x0137: 0x266a,
    // ♪
    0x0138: 0xe0,
    // à
    0x0139: 0xa0,
    //
    0x013a: 0xe8,
    // è
    0x013b: 0xe2,
    // â
    0x013c: 0xea,
    // ê
    0x013d: 0xee,
    // î
    0x013e: 0xf4,
    // ô
    0x013f: 0xfb,
    // û
    0x0220: 0xc1,
    // Á
    0x0221: 0xc9,
    // É
    0x0222: 0xd3,
    // Ó
    0x0223: 0xda,
    // Ú
    0x0224: 0xdc,
    // Ü
    0x0225: 0xfc,
    // ü
    0x0226: 0x2018,
    // ‘
    0x0227: 0xa1,
    // ¡
    0x0228: 0x2a,
    // *
    0x0229: 0x27,
    // '
    0x022a: 0x2014,
    // —
    0x022b: 0xa9,
    // ©
    0x022c: 0x2120,
    // ℠
    0x022d: 0x2022,
    // •
    0x022e: 0x201c,
    // “
    0x022f: 0x201d,
    // ”
    0x0230: 0xc0,
    // À
    0x0231: 0xc2,
    // Â
    0x0232: 0xc7,
    // Ç
    0x0233: 0xc8,
    // È
    0x0234: 0xca,
    // Ê
    0x0235: 0xcb,
    // Ë
    0x0236: 0xeb,
    // ë
    0x0237: 0xce,
    // Î
    0x0238: 0xcf,
    // Ï
    0x0239: 0xef,
    // ï
    0x023a: 0xd4,
    // Ô
    0x023b: 0xd9,
    // Ù
    0x023c: 0xf9,
    // ù
    0x023d: 0xdb,
    // Û
    0x023e: 0xab,
    // «
    0x023f: 0xbb,
    // »
    0x0320: 0xc3,
    // Ã
    0x0321: 0xe3,
    // ã
    0x0322: 0xcd,
    // Í
    0x0323: 0xcc,
    // Ì
    0x0324: 0xec,
    // ì
    0x0325: 0xd2,
    // Ò
    0x0326: 0xf2,
    // ò
    0x0327: 0xd5,
    // Õ
    0x0328: 0xf5,
    // õ
    0x0329: 0x7b,
    // {
    0x032a: 0x7d,
    // }
    0x032b: 0x5c,
    // \
    0x032c: 0x5e,
    // ^
    0x032d: 0x5f,
    // _
    0x032e: 0x7c,
    // |
    0x032f: 0x7e,
    // ~
    0x0330: 0xc4,
    // Ä
    0x0331: 0xe4,
    // ä
    0x0332: 0xd6,
    // Ö
    0x0333: 0xf6,
    // ö
    0x0334: 0xdf,
    // ß
    0x0335: 0xa5,
    // ¥
    0x0336: 0xa4,
    // ¤
    0x0337: 0x2502,
    // │
    0x0338: 0xc5,
    // Å
    0x0339: 0xe5,
    // å
    0x033a: 0xd8,
    // Ø
    0x033b: 0xf8,
    // ø
    0x033c: 0x250c,
    // ┌
    0x033d: 0x2510,
    // ┐
    0x033e: 0x2514,
    // └
    0x033f: 0x2518 // ┘

  };

  var getCharFromCode = function getCharFromCode(code) {
    if (code === null) {
      return '';
    }

    code = CHARACTER_TRANSLATION[code] || code;
    return String.fromCharCode(code);
  }; // the index of the last row in a CEA-608 display buffer


  var BOTTOM_ROW = 14; // This array is used for mapping PACs -> row #, since there's no way of
  // getting it through bit logic.

  var ROWS = [0x1100, 0x1120, 0x1200, 0x1220, 0x1500, 0x1520, 0x1600, 0x1620, 0x1700, 0x1720, 0x1000, 0x1300, 0x1320, 0x1400, 0x1420]; // CEA-608 captions are rendered onto a 34x15 matrix of character
  // cells. The "bottom" row is the last element in the outer array.

  var createDisplayBuffer = function createDisplayBuffer() {
    var result = [],
        i = BOTTOM_ROW + 1;

    while (i--) {
      result.push('');
    }

    return result;
  };

  var Cea608Stream = function Cea608Stream(field, dataChannel) {
    Cea608Stream.prototype.init.call(this);
    this.field_ = field || 0;
    this.dataChannel_ = dataChannel || 0;
    this.name_ = 'CC' + ((this.field_ << 1 | this.dataChannel_) + 1);
    this.setConstants();
    this.reset();

    this.push = function (packet) {
      var data, swap, char0, char1, text; // remove the parity bits

      data = packet.ccData & 0x7f7f; // ignore duplicate control codes; the spec demands they're sent twice

      if (data === this.lastControlCode_) {
        this.lastControlCode_ = null;
        return;
      } // Store control codes


      if ((data & 0xf000) === 0x1000) {
        this.lastControlCode_ = data;
      } else if (data !== this.PADDING_) {
        this.lastControlCode_ = null;
      }

      char0 = data >>> 8;
      char1 = data & 0xff;

      if (data === this.PADDING_) {
        return;
      } else if (data === this.RESUME_CAPTION_LOADING_) {
        this.mode_ = 'popOn';
      } else if (data === this.END_OF_CAPTION_) {
        // If an EOC is received while in paint-on mode, the displayed caption
        // text should be swapped to non-displayed memory as if it was a pop-on
        // caption. Because of that, we should explicitly switch back to pop-on
        // mode
        this.mode_ = 'popOn';
        this.clearFormatting(packet.pts); // if a caption was being displayed, it's gone now

        this.flushDisplayed(packet.pts); // flip memory

        swap = this.displayed_;
        this.displayed_ = this.nonDisplayed_;
        this.nonDisplayed_ = swap; // start measuring the time to display the caption

        this.startPts_ = packet.pts;
      } else if (data === this.ROLL_UP_2_ROWS_) {
        this.rollUpRows_ = 2;
        this.setRollUp(packet.pts);
      } else if (data === this.ROLL_UP_3_ROWS_) {
        this.rollUpRows_ = 3;
        this.setRollUp(packet.pts);
      } else if (data === this.ROLL_UP_4_ROWS_) {
        this.rollUpRows_ = 4;
        this.setRollUp(packet.pts);
      } else if (data === this.CARRIAGE_RETURN_) {
        this.clearFormatting(packet.pts);
        this.flushDisplayed(packet.pts);
        this.shiftRowsUp_();
        this.startPts_ = packet.pts;
      } else if (data === this.BACKSPACE_) {
        if (this.mode_ === 'popOn') {
          this.nonDisplayed_[this.row_] = this.nonDisplayed_[this.row_].slice(0, -1);
        } else {
          this.displayed_[this.row_] = this.displayed_[this.row_].slice(0, -1);
        }
      } else if (data === this.ERASE_DISPLAYED_MEMORY_) {
        this.flushDisplayed(packet.pts);
        this.displayed_ = createDisplayBuffer();
      } else if (data === this.ERASE_NON_DISPLAYED_MEMORY_) {
        this.nonDisplayed_ = createDisplayBuffer();
      } else if (data === this.RESUME_DIRECT_CAPTIONING_) {
        if (this.mode_ !== 'paintOn') {
          // NOTE: This should be removed when proper caption positioning is
          // implemented
          this.flushDisplayed(packet.pts);
          this.displayed_ = createDisplayBuffer();
        }

        this.mode_ = 'paintOn';
        this.startPts_ = packet.pts; // Append special characters to caption text
      } else if (this.isSpecialCharacter(char0, char1)) {
        // Bitmask char0 so that we can apply character transformations
        // regardless of field and data channel.
        // Then byte-shift to the left and OR with char1 so we can pass the
        // entire character code to `getCharFromCode`.
        char0 = (char0 & 0x03) << 8;
        text = getCharFromCode(char0 | char1);
        this[this.mode_](packet.pts, text);
        this.column_++; // Append extended characters to caption text
      } else if (this.isExtCharacter(char0, char1)) {
        // Extended characters always follow their "non-extended" equivalents.
        // IE if a "è" is desired, you'll always receive "eè"; non-compliant
        // decoders are supposed to drop the "è", while compliant decoders
        // backspace the "e" and insert "è".
        // Delete the previous character
        if (this.mode_ === 'popOn') {
          this.nonDisplayed_[this.row_] = this.nonDisplayed_[this.row_].slice(0, -1);
        } else {
          this.displayed_[this.row_] = this.displayed_[this.row_].slice(0, -1);
        } // Bitmask char0 so that we can apply character transformations
        // regardless of field and data channel.
        // Then byte-shift to the left and OR with char1 so we can pass the
        // entire character code to `getCharFromCode`.


        char0 = (char0 & 0x03) << 8;
        text = getCharFromCode(char0 | char1);
        this[this.mode_](packet.pts, text);
        this.column_++; // Process mid-row codes
      } else if (this.isMidRowCode(char0, char1)) {
        // Attributes are not additive, so clear all formatting
        this.clearFormatting(packet.pts); // According to the standard, mid-row codes
        // should be replaced with spaces, so add one now

        this[this.mode_](packet.pts, ' ');
        this.column_++;

        if ((char1 & 0xe) === 0xe) {
          this.addFormatting(packet.pts, ['i']);
        }

        if ((char1 & 0x1) === 0x1) {
          this.addFormatting(packet.pts, ['u']);
        } // Detect offset control codes and adjust cursor

      } else if (this.isOffsetControlCode(char0, char1)) {
        // Cursor position is set by indent PAC (see below) in 4-column
        // increments, with an additional offset code of 1-3 to reach any
        // of the 32 columns specified by CEA-608. So all we need to do
        // here is increment the column cursor by the given offset.
        this.column_ += char1 & 0x03; // Detect PACs (Preamble Address Codes)
      } else if (this.isPAC(char0, char1)) {
        // There's no logic for PAC -> row mapping, so we have to just
        // find the row code in an array and use its index :(
        var row = ROWS.indexOf(data & 0x1f20); // Configure the caption window if we're in roll-up mode

        if (this.mode_ === 'rollUp') {
          // This implies that the base row is incorrectly set.
          // As per the recommendation in CEA-608(Base Row Implementation), defer to the number
          // of roll-up rows set.
          if (row - this.rollUpRows_ + 1 < 0) {
            row = this.rollUpRows_ - 1;
          }

          this.setRollUp(packet.pts, row);
        }

        if (row !== this.row_) {
          // formatting is only persistent for current row
          this.clearFormatting(packet.pts);
          this.row_ = row;
        } // All PACs can apply underline, so detect and apply
        // (All odd-numbered second bytes set underline)


        if (char1 & 0x1 && this.formatting_.indexOf('u') === -1) {
          this.addFormatting(packet.pts, ['u']);
        }

        if ((data & 0x10) === 0x10) {
          // We've got an indent level code. Each successive even number
          // increments the column cursor by 4, so we can get the desired
          // column position by bit-shifting to the right (to get n/2)
          // and multiplying by 4.
          this.column_ = ((data & 0xe) >> 1) * 4;
        }

        if (this.isColorPAC(char1)) {
          // it's a color code, though we only support white, which
          // can be either normal or italicized. white italics can be
          // either 0x4e or 0x6e depending on the row, so we just
          // bitwise-and with 0xe to see if italics should be turned on
          if ((char1 & 0xe) === 0xe) {
            this.addFormatting(packet.pts, ['i']);
          }
        } // We have a normal character in char0, and possibly one in char1

      } else if (this.isNormalChar(char0)) {
        if (char1 === 0x00) {
          char1 = null;
        }

        text = getCharFromCode(char0);
        text += getCharFromCode(char1);
        this[this.mode_](packet.pts, text);
        this.column_ += text.length;
      } // finish data processing

    };
  };

  Cea608Stream.prototype = new stream(); // Trigger a cue point that captures the current state of the
  // display buffer

  Cea608Stream.prototype.flushDisplayed = function (pts) {
    var content = this.displayed_ // remove spaces from the start and end of the string
    .map(function (row, index) {
      try {
        return row.trim();
      } catch (e) {
        // Ordinarily, this shouldn't happen. However, caption
        // parsing errors should not throw exceptions and
        // break playback.
        this.trigger('log', {
          level: 'warn',
          message: 'Skipping a malformed 608 caption at index ' + index + '.'
        });
        return '';
      }
    }, this) // combine all text rows to display in one cue
    .join('\n') // and remove blank rows from the start and end, but not the middle
    .replace(/^\n+|\n+$/g, '');

    if (content.length) {
      this.trigger('data', {
        startPts: this.startPts_,
        endPts: pts,
        text: content,
        stream: this.name_
      });
    }
  };
  /**
   * Zero out the data, used for startup and on seek
   */


  Cea608Stream.prototype.reset = function () {
    this.mode_ = 'popOn'; // When in roll-up mode, the index of the last row that will
    // actually display captions. If a caption is shifted to a row
    // with a lower index than this, it is cleared from the display
    // buffer

    this.topRow_ = 0;
    this.startPts_ = 0;
    this.displayed_ = createDisplayBuffer();
    this.nonDisplayed_ = createDisplayBuffer();
    this.lastControlCode_ = null; // Track row and column for proper line-breaking and spacing

    this.column_ = 0;
    this.row_ = BOTTOM_ROW;
    this.rollUpRows_ = 2; // This variable holds currently-applied formatting

    this.formatting_ = [];
  };
  /**
   * Sets up control code and related constants for this instance
   */


  Cea608Stream.prototype.setConstants = function () {
    // The following attributes have these uses:
    // ext_ :    char0 for mid-row codes, and the base for extended
    //           chars (ext_+0, ext_+1, and ext_+2 are char0s for
    //           extended codes)
    // control_: char0 for control codes, except byte-shifted to the
    //           left so that we can do this.control_ | CONTROL_CODE
    // offset_:  char0 for tab offset codes
    //
    // It's also worth noting that control codes, and _only_ control codes,
    // differ between field 1 and field2. Field 2 control codes are always
    // their field 1 value plus 1. That's why there's the "| field" on the
    // control value.
    if (this.dataChannel_ === 0) {
      this.BASE_ = 0x10;
      this.EXT_ = 0x11;
      this.CONTROL_ = (0x14 | this.field_) << 8;
      this.OFFSET_ = 0x17;
    } else if (this.dataChannel_ === 1) {
      this.BASE_ = 0x18;
      this.EXT_ = 0x19;
      this.CONTROL_ = (0x1c | this.field_) << 8;
      this.OFFSET_ = 0x1f;
    } // Constants for the LSByte command codes recognized by Cea608Stream. This
    // list is not exhaustive. For a more comprehensive listing and semantics see
    // http://www.gpo.gov/fdsys/pkg/CFR-2010-title47-vol1/pdf/CFR-2010-title47-vol1-sec15-119.pdf
    // Padding


    this.PADDING_ = 0x0000; // Pop-on Mode

    this.RESUME_CAPTION_LOADING_ = this.CONTROL_ | 0x20;
    this.END_OF_CAPTION_ = this.CONTROL_ | 0x2f; // Roll-up Mode

    this.ROLL_UP_2_ROWS_ = this.CONTROL_ | 0x25;
    this.ROLL_UP_3_ROWS_ = this.CONTROL_ | 0x26;
    this.ROLL_UP_4_ROWS_ = this.CONTROL_ | 0x27;
    this.CARRIAGE_RETURN_ = this.CONTROL_ | 0x2d; // paint-on mode

    this.RESUME_DIRECT_CAPTIONING_ = this.CONTROL_ | 0x29; // Erasure

    this.BACKSPACE_ = this.CONTROL_ | 0x21;
    this.ERASE_DISPLAYED_MEMORY_ = this.CONTROL_ | 0x2c;
    this.ERASE_NON_DISPLAYED_MEMORY_ = this.CONTROL_ | 0x2e;
  };
  /**
   * Detects if the 2-byte packet data is a special character
   *
   * Special characters have a second byte in the range 0x30 to 0x3f,
   * with the first byte being 0x11 (for data channel 1) or 0x19 (for
   * data channel 2).
   *
   * @param  {Integer} char0 The first byte
   * @param  {Integer} char1 The second byte
   * @return {Boolean}       Whether the 2 bytes are an special character
   */


  Cea608Stream.prototype.isSpecialCharacter = function (char0, char1) {
    return char0 === this.EXT_ && char1 >= 0x30 && char1 <= 0x3f;
  };
  /**
   * Detects if the 2-byte packet data is an extended character
   *
   * Extended characters have a second byte in the range 0x20 to 0x3f,
   * with the first byte being 0x12 or 0x13 (for data channel 1) or
   * 0x1a or 0x1b (for data channel 2).
   *
   * @param  {Integer} char0 The first byte
   * @param  {Integer} char1 The second byte
   * @return {Boolean}       Whether the 2 bytes are an extended character
   */


  Cea608Stream.prototype.isExtCharacter = function (char0, char1) {
    return (char0 === this.EXT_ + 1 || char0 === this.EXT_ + 2) && char1 >= 0x20 && char1 <= 0x3f;
  };
  /**
   * Detects if the 2-byte packet is a mid-row code
   *
   * Mid-row codes have a second byte in the range 0x20 to 0x2f, with
   * the first byte being 0x11 (for data channel 1) or 0x19 (for data
   * channel 2).
   *
   * @param  {Integer} char0 The first byte
   * @param  {Integer} char1 The second byte
   * @return {Boolean}       Whether the 2 bytes are a mid-row code
   */


  Cea608Stream.prototype.isMidRowCode = function (char0, char1) {
    return char0 === this.EXT_ && char1 >= 0x20 && char1 <= 0x2f;
  };
  /**
   * Detects if the 2-byte packet is an offset control code
   *
   * Offset control codes have a second byte in the range 0x21 to 0x23,
   * with the first byte being 0x17 (for data channel 1) or 0x1f (for
   * data channel 2).
   *
   * @param  {Integer} char0 The first byte
   * @param  {Integer} char1 The second byte
   * @return {Boolean}       Whether the 2 bytes are an offset control code
   */


  Cea608Stream.prototype.isOffsetControlCode = function (char0, char1) {
    return char0 === this.OFFSET_ && char1 >= 0x21 && char1 <= 0x23;
  };
  /**
   * Detects if the 2-byte packet is a Preamble Address Code
   *
   * PACs have a first byte in the range 0x10 to 0x17 (for data channel 1)
   * or 0x18 to 0x1f (for data channel 2), with the second byte in the
   * range 0x40 to 0x7f.
   *
   * @param  {Integer} char0 The first byte
   * @param  {Integer} char1 The second byte
   * @return {Boolean}       Whether the 2 bytes are a PAC
   */


  Cea608Stream.prototype.isPAC = function (char0, char1) {
    return char0 >= this.BASE_ && char0 < this.BASE_ + 8 && char1 >= 0x40 && char1 <= 0x7f;
  };
  /**
   * Detects if a packet's second byte is in the range of a PAC color code
   *
   * PAC color codes have the second byte be in the range 0x40 to 0x4f, or
   * 0x60 to 0x6f.
   *
   * @param  {Integer} char1 The second byte
   * @return {Boolean}       Whether the byte is a color PAC
   */


  Cea608Stream.prototype.isColorPAC = function (char1) {
    return char1 >= 0x40 && char1 <= 0x4f || char1 >= 0x60 && char1 <= 0x7f;
  };
  /**
   * Detects if a single byte is in the range of a normal character
   *
   * Normal text bytes are in the range 0x20 to 0x7f.
   *
   * @param  {Integer} char  The byte
   * @return {Boolean}       Whether the byte is a normal character
   */


  Cea608Stream.prototype.isNormalChar = function (char) {
    return char >= 0x20 && char <= 0x7f;
  };
  /**
   * Configures roll-up
   *
   * @param  {Integer} pts         Current PTS
   * @param  {Integer} newBaseRow  Used by PACs to slide the current window to
   *                               a new position
   */


  Cea608Stream.prototype.setRollUp = function (pts, newBaseRow) {
    // Reset the base row to the bottom row when switching modes
    if (this.mode_ !== 'rollUp') {
      this.row_ = BOTTOM_ROW;
      this.mode_ = 'rollUp'; // Spec says to wipe memories when switching to roll-up

      this.flushDisplayed(pts);
      this.nonDisplayed_ = createDisplayBuffer();
      this.displayed_ = createDisplayBuffer();
    }

    if (newBaseRow !== undefined && newBaseRow !== this.row_) {
      // move currently displayed captions (up or down) to the new base row
      for (var i = 0; i < this.rollUpRows_; i++) {
        this.displayed_[newBaseRow - i] = this.displayed_[this.row_ - i];
        this.displayed_[this.row_ - i] = '';
      }
    }

    if (newBaseRow === undefined) {
      newBaseRow = this.row_;
    }

    this.topRow_ = newBaseRow - this.rollUpRows_ + 1;
  }; // Adds the opening HTML tag for the passed character to the caption text,
  // and keeps track of it for later closing


  Cea608Stream.prototype.addFormatting = function (pts, format) {
    this.formatting_ = this.formatting_.concat(format);
    var text = format.reduce(function (text, format) {
      return text + '<' + format + '>';
    }, '');
    this[this.mode_](pts, text);
  }; // Adds HTML closing tags for current formatting to caption text and
  // clears remembered formatting


  Cea608Stream.prototype.clearFormatting = function (pts) {
    if (!this.formatting_.length) {
      return;
    }

    var text = this.formatting_.reverse().reduce(function (text, format) {
      return text + '</' + format + '>';
    }, '');
    this.formatting_ = [];
    this[this.mode_](pts, text);
  }; // Mode Implementations


  Cea608Stream.prototype.popOn = function (pts, text) {
    var baseRow = this.nonDisplayed_[this.row_]; // buffer characters

    baseRow += text;
    this.nonDisplayed_[this.row_] = baseRow;
  };

  Cea608Stream.prototype.rollUp = function (pts, text) {
    var baseRow = this.displayed_[this.row_];
    baseRow += text;
    this.displayed_[this.row_] = baseRow;
  };

  Cea608Stream.prototype.shiftRowsUp_ = function () {
    var i; // clear out inactive rows

    for (i = 0; i < this.topRow_; i++) {
      this.displayed_[i] = '';
    }

    for (i = this.row_ + 1; i < BOTTOM_ROW + 1; i++) {
      this.displayed_[i] = '';
    } // shift displayed rows up


    for (i = this.topRow_; i < this.row_; i++) {
      this.displayed_[i] = this.displayed_[i + 1];
    } // clear out the bottom row


    this.displayed_[this.row_] = '';
  };

  Cea608Stream.prototype.paintOn = function (pts, text) {
    var baseRow = this.displayed_[this.row_];
    baseRow += text;
    this.displayed_[this.row_] = baseRow;
  }; // exports


  var captionStream = {
    CaptionStream: CaptionStream$1,
    Cea608Stream: Cea608Stream,
    Cea708Stream: Cea708Stream
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var streamTypes = {
    H264_STREAM_TYPE: 0x1B,
    ADTS_STREAM_TYPE: 0x0F,
    METADATA_STREAM_TYPE: 0x15
  };

  var MAX_TS = 8589934592;
  var RO_THRESH = 4294967296;
  var TYPE_SHARED = 'shared';

  var handleRollover$1 = function handleRollover(value, reference) {
    var direction = 1;

    if (value > reference) {
      // If the current timestamp value is greater than our reference timestamp and we detect a
      // timestamp rollover, this means the roll over is happening in the opposite direction.
      // Example scenario: Enter a long stream/video just after a rollover occurred. The reference
      // point will be set to a small number, e.g. 1. The user then seeks backwards over the
      // rollover point. In loading this segment, the timestamp values will be very large,
      // e.g. 2^33 - 1. Since this comes before the data we loaded previously, we want to adjust
      // the time stamp to be `value - 2^33`.
      direction = -1;
    } // Note: A seek forwards or back that is greater than the RO_THRESH (2^32, ~13 hours) will
    // cause an incorrect adjustment.


    while (Math.abs(reference - value) > RO_THRESH) {
      value += direction * MAX_TS;
    }

    return value;
  };

  var TimestampRolloverStream$1 = function TimestampRolloverStream(type) {
    var lastDTS, referenceDTS;
    TimestampRolloverStream.prototype.init.call(this); // The "shared" type is used in cases where a stream will contain muxed
    // video and audio. We could use `undefined` here, but having a string
    // makes debugging a little clearer.

    this.type_ = type || TYPE_SHARED;

    this.push = function (data) {
      // Any "shared" rollover streams will accept _all_ data. Otherwise,
      // streams will only accept data that matches their type.
      if (this.type_ !== TYPE_SHARED && data.type !== this.type_) {
        return;
      }

      if (referenceDTS === undefined) {
        referenceDTS = data.dts;
      }

      data.dts = handleRollover$1(data.dts, referenceDTS);
      data.pts = handleRollover$1(data.pts, referenceDTS);
      lastDTS = data.dts;
      this.trigger('data', data);
    };

    this.flush = function () {
      referenceDTS = lastDTS;
      this.trigger('done');
    };

    this.endTimeline = function () {
      this.flush();
      this.trigger('endedtimeline');
    };

    this.discontinuity = function () {
      referenceDTS = void 0;
      lastDTS = void 0;
    };

    this.reset = function () {
      this.discontinuity();
      this.trigger('reset');
    };
  };

  TimestampRolloverStream$1.prototype = new stream();
  var timestampRolloverStream = {
    TimestampRolloverStream: TimestampRolloverStream$1,
    handleRollover: handleRollover$1
  };

  var percentEncode$1 = function percentEncode(bytes, start, end) {
    var i,
        result = '';

    for (i = start; i < end; i++) {
      result += '%' + ('00' + bytes[i].toString(16)).slice(-2);
    }

    return result;
  },
      // return the string representation of the specified byte range,
  // interpreted as UTf-8.
  parseUtf8 = function parseUtf8(bytes, start, end) {
    return decodeURIComponent(percentEncode$1(bytes, start, end));
  },
      // return the string representation of the specified byte range,
  // interpreted as ISO-8859-1.
  parseIso88591$1 = function parseIso88591(bytes, start, end) {
    return unescape(percentEncode$1(bytes, start, end)); // jshint ignore:line
  },
      parseSyncSafeInteger$1 = function parseSyncSafeInteger(data) {
    return data[0] << 21 | data[1] << 14 | data[2] << 7 | data[3];
  },
      tagParsers = {
    TXXX: function TXXX(tag) {
      var i;

      if (tag.data[0] !== 3) {
        // ignore frames with unrecognized character encodings
        return;
      }

      for (i = 1; i < tag.data.length; i++) {
        if (tag.data[i] === 0) {
          // parse the text fields
          tag.description = parseUtf8(tag.data, 1, i); // do not include the null terminator in the tag value

          tag.value = parseUtf8(tag.data, i + 1, tag.data.length).replace(/\0*$/, '');
          break;
        }
      }

      tag.data = tag.value;
    },
    WXXX: function WXXX(tag) {
      var i;

      if (tag.data[0] !== 3) {
        // ignore frames with unrecognized character encodings
        return;
      }

      for (i = 1; i < tag.data.length; i++) {
        if (tag.data[i] === 0) {
          // parse the description and URL fields
          tag.description = parseUtf8(tag.data, 1, i);
          tag.url = parseUtf8(tag.data, i + 1, tag.data.length);
          break;
        }
      }
    },
    PRIV: function PRIV(tag) {
      var i;

      for (i = 0; i < tag.data.length; i++) {
        if (tag.data[i] === 0) {
          // parse the description and URL fields
          tag.owner = parseIso88591$1(tag.data, 0, i);
          break;
        }
      }

      tag.privateData = tag.data.subarray(i + 1);
      tag.data = tag.privateData;
    }
  },
      _MetadataStream;

  _MetadataStream = function MetadataStream(options) {
    var settings = {
      // the bytes of the program-level descriptor field in MP2T
      // see ISO/IEC 13818-1:2013 (E), section 2.6 "Program and
      // program element descriptors"
      descriptor: options && options.descriptor
    },
        // the total size in bytes of the ID3 tag being parsed
    tagSize = 0,
        // tag data that is not complete enough to be parsed
    buffer = [],
        // the total number of bytes currently in the buffer
    bufferSize = 0,
        i;

    _MetadataStream.prototype.init.call(this); // calculate the text track in-band metadata track dispatch type
    // https://html.spec.whatwg.org/multipage/embedded-content.html#steps-to-expose-a-media-resource-specific-text-track


    this.dispatchType = streamTypes.METADATA_STREAM_TYPE.toString(16);

    if (settings.descriptor) {
      for (i = 0; i < settings.descriptor.length; i++) {
        this.dispatchType += ('00' + settings.descriptor[i].toString(16)).slice(-2);
      }
    }

    this.push = function (chunk) {
      var tag, frameStart, frameSize, frame, i, frameHeader;

      if (chunk.type !== 'timed-metadata') {
        return;
      } // if data_alignment_indicator is set in the PES header,
      // we must have the start of a new ID3 tag. Assume anything
      // remaining in the buffer was malformed and throw it out


      if (chunk.dataAlignmentIndicator) {
        bufferSize = 0;
        buffer.length = 0;
      } // ignore events that don't look like ID3 data


      if (buffer.length === 0 && (chunk.data.length < 10 || chunk.data[0] !== 'I'.charCodeAt(0) || chunk.data[1] !== 'D'.charCodeAt(0) || chunk.data[2] !== '3'.charCodeAt(0))) {
        this.trigger('log', {
          level: 'warn',
          message: 'Skipping unrecognized metadata packet'
        });
        return;
      } // add this chunk to the data we've collected so far


      buffer.push(chunk);
      bufferSize += chunk.data.byteLength; // grab the size of the entire frame from the ID3 header

      if (buffer.length === 1) {
        // the frame size is transmitted as a 28-bit integer in the
        // last four bytes of the ID3 header.
        // The most significant bit of each byte is dropped and the
        // results concatenated to recover the actual value.
        tagSize = parseSyncSafeInteger$1(chunk.data.subarray(6, 10)); // ID3 reports the tag size excluding the header but it's more
        // convenient for our comparisons to include it

        tagSize += 10;
      } // if the entire frame has not arrived, wait for more data


      if (bufferSize < tagSize) {
        return;
      } // collect the entire frame so it can be parsed


      tag = {
        data: new Uint8Array(tagSize),
        frames: [],
        pts: buffer[0].pts,
        dts: buffer[0].dts
      };

      for (i = 0; i < tagSize;) {
        tag.data.set(buffer[0].data.subarray(0, tagSize - i), i);
        i += buffer[0].data.byteLength;
        bufferSize -= buffer[0].data.byteLength;
        buffer.shift();
      } // find the start of the first frame and the end of the tag


      frameStart = 10;

      if (tag.data[5] & 0x40) {
        // advance the frame start past the extended header
        frameStart += 4; // header size field

        frameStart += parseSyncSafeInteger$1(tag.data.subarray(10, 14)); // clip any padding off the end

        tagSize -= parseSyncSafeInteger$1(tag.data.subarray(16, 20));
      } // parse one or more ID3 frames
      // http://id3.org/id3v2.3.0#ID3v2_frame_overview


      do {
        // determine the number of bytes in this frame
        frameSize = parseSyncSafeInteger$1(tag.data.subarray(frameStart + 4, frameStart + 8));

        if (frameSize < 1) {
          this.trigger('log', {
            level: 'warn',
            message: 'Malformed ID3 frame encountered. Skipping metadata parsing.'
          });
          return;
        }

        frameHeader = String.fromCharCode(tag.data[frameStart], tag.data[frameStart + 1], tag.data[frameStart + 2], tag.data[frameStart + 3]);
        frame = {
          id: frameHeader,
          data: tag.data.subarray(frameStart + 10, frameStart + frameSize + 10)
        };
        frame.key = frame.id;

        if (tagParsers[frame.id]) {
          tagParsers[frame.id](frame); // handle the special PRIV frame used to indicate the start
          // time for raw AAC data

          if (frame.owner === 'com.apple.streaming.transportStreamTimestamp') {
            var d = frame.data,
                size = (d[3] & 0x01) << 30 | d[4] << 22 | d[5] << 14 | d[6] << 6 | d[7] >>> 2;
            size *= 4;
            size += d[7] & 0x03;
            frame.timeStamp = size; // in raw AAC, all subsequent data will be timestamped based
            // on the value of this frame
            // we couldn't have known the appropriate pts and dts before
            // parsing this ID3 tag so set those values now

            if (tag.pts === undefined && tag.dts === undefined) {
              tag.pts = frame.timeStamp;
              tag.dts = frame.timeStamp;
            }

            this.trigger('timestamp', frame);
          }
        }

        tag.frames.push(frame);
        frameStart += 10; // advance past the frame header

        frameStart += frameSize; // advance past the frame body
      } while (frameStart < tagSize);

      this.trigger('data', tag);
    };
  };

  _MetadataStream.prototype = new stream();
  var metadataStream = _MetadataStream;

  var TimestampRolloverStream = timestampRolloverStream.TimestampRolloverStream; // object types

  var _TransportPacketStream, _TransportParseStream, _ElementaryStream; // constants


  var MP2T_PACKET_LENGTH$1 = 188,
      // bytes
  SYNC_BYTE$1 = 0x47;
  /**
   * Splits an incoming stream of binary data into MPEG-2 Transport
   * Stream packets.
   */

  _TransportPacketStream = function TransportPacketStream() {
    var buffer = new Uint8Array(MP2T_PACKET_LENGTH$1),
        bytesInBuffer = 0;

    _TransportPacketStream.prototype.init.call(this); // Deliver new bytes to the stream.

    /**
     * Split a stream of data into M2TS packets
    **/


    this.push = function (bytes) {
      var startIndex = 0,
          endIndex = MP2T_PACKET_LENGTH$1,
          everything; // If there are bytes remaining from the last segment, prepend them to the
      // bytes that were pushed in

      if (bytesInBuffer) {
        everything = new Uint8Array(bytes.byteLength + bytesInBuffer);
        everything.set(buffer.subarray(0, bytesInBuffer));
        everything.set(bytes, bytesInBuffer);
        bytesInBuffer = 0;
      } else {
        everything = bytes;
      } // While we have enough data for a packet


      while (endIndex < everything.byteLength) {
        // Look for a pair of start and end sync bytes in the data..
        if (everything[startIndex] === SYNC_BYTE$1 && everything[endIndex] === SYNC_BYTE$1) {
          // We found a packet so emit it and jump one whole packet forward in
          // the stream
          this.trigger('data', everything.subarray(startIndex, endIndex));
          startIndex += MP2T_PACKET_LENGTH$1;
          endIndex += MP2T_PACKET_LENGTH$1;
          continue;
        } // If we get here, we have somehow become de-synchronized and we need to step
        // forward one byte at a time until we find a pair of sync bytes that denote
        // a packet


        startIndex++;
        endIndex++;
      } // If there was some data left over at the end of the segment that couldn't
      // possibly be a whole packet, keep it because it might be the start of a packet
      // that continues in the next segment


      if (startIndex < everything.byteLength) {
        buffer.set(everything.subarray(startIndex), 0);
        bytesInBuffer = everything.byteLength - startIndex;
      }
    };
    /**
     * Passes identified M2TS packets to the TransportParseStream to be parsed
    **/


    this.flush = function () {
      // If the buffer contains a whole packet when we are being flushed, emit it
      // and empty the buffer. Otherwise hold onto the data because it may be
      // important for decoding the next segment
      if (bytesInBuffer === MP2T_PACKET_LENGTH$1 && buffer[0] === SYNC_BYTE$1) {
        this.trigger('data', buffer);
        bytesInBuffer = 0;
      }

      this.trigger('done');
    };

    this.endTimeline = function () {
      this.flush();
      this.trigger('endedtimeline');
    };

    this.reset = function () {
      bytesInBuffer = 0;
      this.trigger('reset');
    };
  };

  _TransportPacketStream.prototype = new stream();
  /**
   * Accepts an MP2T TransportPacketStream and emits data events with parsed
   * forms of the individual transport stream packets.
   */

  _TransportParseStream = function TransportParseStream() {
    var parsePsi, parsePat, parsePmt, self;

    _TransportParseStream.prototype.init.call(this);

    self = this;
    this.packetsWaitingForPmt = [];
    this.programMapTable = undefined;

    parsePsi = function parsePsi(payload, psi) {
      var offset = 0; // PSI packets may be split into multiple sections and those
      // sections may be split into multiple packets. If a PSI
      // section starts in this packet, the payload_unit_start_indicator
      // will be true and the first byte of the payload will indicate
      // the offset from the current position to the start of the
      // section.

      if (psi.payloadUnitStartIndicator) {
        offset += payload[offset] + 1;
      }

      if (psi.type === 'pat') {
        parsePat(payload.subarray(offset), psi);
      } else {
        parsePmt(payload.subarray(offset), psi);
      }
    };

    parsePat = function parsePat(payload, pat) {
      pat.section_number = payload[7]; // eslint-disable-line camelcase

      pat.last_section_number = payload[8]; // eslint-disable-line camelcase
      // skip the PSI header and parse the first PMT entry

      self.pmtPid = (payload[10] & 0x1F) << 8 | payload[11];
      pat.pmtPid = self.pmtPid;
    };
    /**
     * Parse out the relevant fields of a Program Map Table (PMT).
     * @param payload {Uint8Array} the PMT-specific portion of an MP2T
     * packet. The first byte in this array should be the table_id
     * field.
     * @param pmt {object} the object that should be decorated with
     * fields parsed from the PMT.
     */


    parsePmt = function parsePmt(payload, pmt) {
      var sectionLength, tableEnd, programInfoLength, offset; // PMTs can be sent ahead of the time when they should actually
      // take effect. We don't believe this should ever be the case
      // for HLS but we'll ignore "forward" PMT declarations if we see
      // them. Future PMT declarations have the current_next_indicator
      // set to zero.

      if (!(payload[5] & 0x01)) {
        return;
      } // overwrite any existing program map table


      self.programMapTable = {
        video: null,
        audio: null,
        'timed-metadata': {}
      }; // the mapping table ends at the end of the current section

      sectionLength = (payload[1] & 0x0f) << 8 | payload[2];
      tableEnd = 3 + sectionLength - 4; // to determine where the table is, we have to figure out how
      // long the program info descriptors are

      programInfoLength = (payload[10] & 0x0f) << 8 | payload[11]; // advance the offset to the first entry in the mapping table

      offset = 12 + programInfoLength;

      while (offset < tableEnd) {
        var streamType = payload[offset];
        var pid = (payload[offset + 1] & 0x1F) << 8 | payload[offset + 2]; // only map a single elementary_pid for audio and video stream types
        // TODO: should this be done for metadata too? for now maintain behavior of
        //       multiple metadata streams

        if (streamType === streamTypes.H264_STREAM_TYPE && self.programMapTable.video === null) {
          self.programMapTable.video = pid;
        } else if (streamType === streamTypes.ADTS_STREAM_TYPE && self.programMapTable.audio === null) {
          self.programMapTable.audio = pid;
        } else if (streamType === streamTypes.METADATA_STREAM_TYPE) {
          // map pid to stream type for metadata streams
          self.programMapTable['timed-metadata'][pid] = streamType;
        } // move to the next table entry
        // skip past the elementary stream descriptors, if present


        offset += ((payload[offset + 3] & 0x0F) << 8 | payload[offset + 4]) + 5;
      } // record the map on the packet as well


      pmt.programMapTable = self.programMapTable;
    };
    /**
     * Deliver a new MP2T packet to the next stream in the pipeline.
     */


    this.push = function (packet) {
      var result = {},
          offset = 4;
      result.payloadUnitStartIndicator = !!(packet[1] & 0x40); // pid is a 13-bit field starting at the last bit of packet[1]

      result.pid = packet[1] & 0x1f;
      result.pid <<= 8;
      result.pid |= packet[2]; // if an adaption field is present, its length is specified by the
      // fifth byte of the TS packet header. The adaptation field is
      // used to add stuffing to PES packets that don't fill a complete
      // TS packet, and to specify some forms of timing and control data
      // that we do not currently use.

      if ((packet[3] & 0x30) >>> 4 > 0x01) {
        offset += packet[offset] + 1;
      } // parse the rest of the packet based on the type


      if (result.pid === 0) {
        result.type = 'pat';
        parsePsi(packet.subarray(offset), result);
        this.trigger('data', result);
      } else if (result.pid === this.pmtPid) {
        result.type = 'pmt';
        parsePsi(packet.subarray(offset), result);
        this.trigger('data', result); // if there are any packets waiting for a PMT to be found, process them now

        while (this.packetsWaitingForPmt.length) {
          this.processPes_.apply(this, this.packetsWaitingForPmt.shift());
        }
      } else if (this.programMapTable === undefined) {
        // When we have not seen a PMT yet, defer further processing of
        // PES packets until one has been parsed
        this.packetsWaitingForPmt.push([packet, offset, result]);
      } else {
        this.processPes_(packet, offset, result);
      }
    };

    this.processPes_ = function (packet, offset, result) {
      // set the appropriate stream type
      if (result.pid === this.programMapTable.video) {
        result.streamType = streamTypes.H264_STREAM_TYPE;
      } else if (result.pid === this.programMapTable.audio) {
        result.streamType = streamTypes.ADTS_STREAM_TYPE;
      } else {
        // if not video or audio, it is timed-metadata or unknown
        // if unknown, streamType will be undefined
        result.streamType = this.programMapTable['timed-metadata'][result.pid];
      }

      result.type = 'pes';
      result.data = packet.subarray(offset);
      this.trigger('data', result);
    };
  };

  _TransportParseStream.prototype = new stream();
  _TransportParseStream.STREAM_TYPES = {
    h264: 0x1b,
    adts: 0x0f
  };
  /**
   * Reconsistutes program elementary stream (PES) packets from parsed
   * transport stream packets. That is, if you pipe an
   * mp2t.TransportParseStream into a mp2t.ElementaryStream, the output
   * events will be events which capture the bytes for individual PES
   * packets plus relevant metadata that has been extracted from the
   * container.
   */

  _ElementaryStream = function ElementaryStream() {
    var self = this,
        segmentHadPmt = false,
        // PES packet fragments
    video = {
      data: [],
      size: 0
    },
        audio = {
      data: [],
      size: 0
    },
        timedMetadata = {
      data: [],
      size: 0
    },
        programMapTable,
        parsePes = function parsePes(payload, pes) {
      var ptsDtsFlags;
      var startPrefix = payload[0] << 16 | payload[1] << 8 | payload[2]; // default to an empty array

      pes.data = new Uint8Array(); // In certain live streams, the start of a TS fragment has ts packets
      // that are frame data that is continuing from the previous fragment. This
      // is to check that the pes data is the start of a new pes payload

      if (startPrefix !== 1) {
        return;
      } // get the packet length, this will be 0 for video


      pes.packetLength = 6 + (payload[4] << 8 | payload[5]); // find out if this packets starts a new keyframe

      pes.dataAlignmentIndicator = (payload[6] & 0x04) !== 0; // PES packets may be annotated with a PTS value, or a PTS value
      // and a DTS value. Determine what combination of values is
      // available to work with.

      ptsDtsFlags = payload[7]; // PTS and DTS are normally stored as a 33-bit number.  Javascript
      // performs all bitwise operations on 32-bit integers but javascript
      // supports a much greater range (52-bits) of integer using standard
      // mathematical operations.
      // We construct a 31-bit value using bitwise operators over the 31
      // most significant bits and then multiply by 4 (equal to a left-shift
      // of 2) before we add the final 2 least significant bits of the
      // timestamp (equal to an OR.)

      if (ptsDtsFlags & 0xC0) {
        // the PTS and DTS are not written out directly. For information
        // on how they are encoded, see
        // http://dvd.sourceforge.net/dvdinfo/pes-hdr.html
        pes.pts = (payload[9] & 0x0E) << 27 | (payload[10] & 0xFF) << 20 | (payload[11] & 0xFE) << 12 | (payload[12] & 0xFF) << 5 | (payload[13] & 0xFE) >>> 3;
        pes.pts *= 4; // Left shift by 2

        pes.pts += (payload[13] & 0x06) >>> 1; // OR by the two LSBs

        pes.dts = pes.pts;

        if (ptsDtsFlags & 0x40) {
          pes.dts = (payload[14] & 0x0E) << 27 | (payload[15] & 0xFF) << 20 | (payload[16] & 0xFE) << 12 | (payload[17] & 0xFF) << 5 | (payload[18] & 0xFE) >>> 3;
          pes.dts *= 4; // Left shift by 2

          pes.dts += (payload[18] & 0x06) >>> 1; // OR by the two LSBs
        }
      } // the data section starts immediately after the PES header.
      // pes_header_data_length specifies the number of header bytes
      // that follow the last byte of the field.


      pes.data = payload.subarray(9 + payload[8]);
    },

    /**
      * Pass completely parsed PES packets to the next stream in the pipeline
     **/
    flushStream = function flushStream(stream, type, forceFlush) {
      var packetData = new Uint8Array(stream.size),
          event = {
        type: type
      },
          i = 0,
          offset = 0,
          packetFlushable = false,
          fragment; // do nothing if there is not enough buffered data for a complete
      // PES header

      if (!stream.data.length || stream.size < 9) {
        return;
      }

      event.trackId = stream.data[0].pid; // reassemble the packet

      for (i = 0; i < stream.data.length; i++) {
        fragment = stream.data[i];
        packetData.set(fragment.data, offset);
        offset += fragment.data.byteLength;
      } // parse assembled packet's PES header


      parsePes(packetData, event); // non-video PES packets MUST have a non-zero PES_packet_length
      // check that there is enough stream data to fill the packet

      packetFlushable = type === 'video' || event.packetLength <= stream.size; // flush pending packets if the conditions are right

      if (forceFlush || packetFlushable) {
        stream.size = 0;
        stream.data.length = 0;
      } // only emit packets that are complete. this is to avoid assembling
      // incomplete PES packets due to poor segmentation


      if (packetFlushable) {
        self.trigger('data', event);
      }
    };

    _ElementaryStream.prototype.init.call(this);
    /**
     * Identifies M2TS packet types and parses PES packets using metadata
     * parsed from the PMT
     **/


    this.push = function (data) {
      ({
        pat: function pat() {// we have to wait for the PMT to arrive as well before we
          // have any meaningful metadata
        },
        pes: function pes() {
          var stream, streamType;

          switch (data.streamType) {
            case streamTypes.H264_STREAM_TYPE:
              stream = video;
              streamType = 'video';
              break;

            case streamTypes.ADTS_STREAM_TYPE:
              stream = audio;
              streamType = 'audio';
              break;

            case streamTypes.METADATA_STREAM_TYPE:
              stream = timedMetadata;
              streamType = 'timed-metadata';
              break;

            default:
              // ignore unknown stream types
              return;
          } // if a new packet is starting, we can flush the completed
          // packet


          if (data.payloadUnitStartIndicator) {
            flushStream(stream, streamType, true);
          } // buffer this fragment until we are sure we've received the
          // complete payload


          stream.data.push(data);
          stream.size += data.data.byteLength;
        },
        pmt: function pmt() {
          var event = {
            type: 'metadata',
            tracks: []
          };
          programMapTable = data.programMapTable; // translate audio and video streams to tracks

          if (programMapTable.video !== null) {
            event.tracks.push({
              timelineStartInfo: {
                baseMediaDecodeTime: 0
              },
              id: +programMapTable.video,
              codec: 'avc',
              type: 'video'
            });
          }

          if (programMapTable.audio !== null) {
            event.tracks.push({
              timelineStartInfo: {
                baseMediaDecodeTime: 0
              },
              id: +programMapTable.audio,
              codec: 'adts',
              type: 'audio'
            });
          }

          segmentHadPmt = true;
          self.trigger('data', event);
        }
      })[data.type]();
    };

    this.reset = function () {
      video.size = 0;
      video.data.length = 0;
      audio.size = 0;
      audio.data.length = 0;
      this.trigger('reset');
    };
    /**
     * Flush any remaining input. Video PES packets may be of variable
     * length. Normally, the start of a new video packet can trigger the
     * finalization of the previous packet. That is not possible if no
     * more video is forthcoming, however. In that case, some other
     * mechanism (like the end of the file) has to be employed. When it is
     * clear that no additional data is forthcoming, calling this method
     * will flush the buffered packets.
     */


    this.flushStreams_ = function () {
      // !!THIS ORDER IS IMPORTANT!!
      // video first then audio
      flushStream(video, 'video');
      flushStream(audio, 'audio');
      flushStream(timedMetadata, 'timed-metadata');
    };

    this.flush = function () {
      // if on flush we haven't had a pmt emitted
      // and we have a pmt to emit. emit the pmt
      // so that we trigger a trackinfo downstream.
      if (!segmentHadPmt && programMapTable) {
        var pmt = {
          type: 'metadata',
          tracks: []
        }; // translate audio and video streams to tracks

        if (programMapTable.video !== null) {
          pmt.tracks.push({
            timelineStartInfo: {
              baseMediaDecodeTime: 0
            },
            id: +programMapTable.video,
            codec: 'avc',
            type: 'video'
          });
        }

        if (programMapTable.audio !== null) {
          pmt.tracks.push({
            timelineStartInfo: {
              baseMediaDecodeTime: 0
            },
            id: +programMapTable.audio,
            codec: 'adts',
            type: 'audio'
          });
        }

        self.trigger('data', pmt);
      }

      segmentHadPmt = false;
      this.flushStreams_();
      this.trigger('done');
    };
  };

  _ElementaryStream.prototype = new stream();
  var m2ts$1 = {
    PAT_PID: 0x0000,
    MP2T_PACKET_LENGTH: MP2T_PACKET_LENGTH$1,
    TransportPacketStream: _TransportPacketStream,
    TransportParseStream: _TransportParseStream,
    ElementaryStream: _ElementaryStream,
    TimestampRolloverStream: TimestampRolloverStream,
    CaptionStream: captionStream.CaptionStream,
    Cea608Stream: captionStream.Cea608Stream,
    Cea708Stream: captionStream.Cea708Stream,
    MetadataStream: metadataStream
  };

  for (var type in streamTypes) {
    if (streamTypes.hasOwnProperty(type)) {
      m2ts$1[type] = streamTypes[type];
    }
  }

  var m2ts_1 = m2ts$1;

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   *
   * Utilities to detect basic properties and metadata about Aac data.
   */

  var ADTS_SAMPLING_FREQUENCIES = [96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350];

  var parseId3TagSize = function parseId3TagSize(header, byteIndex) {
    var returnSize = header[byteIndex + 6] << 21 | header[byteIndex + 7] << 14 | header[byteIndex + 8] << 7 | header[byteIndex + 9],
        flags = header[byteIndex + 5],
        footerPresent = (flags & 16) >> 4; // if we get a negative returnSize clamp it to 0

    returnSize = returnSize >= 0 ? returnSize : 0;

    if (footerPresent) {
      return returnSize + 20;
    }

    return returnSize + 10;
  };

  var getId3Offset = function getId3Offset(data, offset) {
    if (data.length - offset < 10 || data[offset] !== 'I'.charCodeAt(0) || data[offset + 1] !== 'D'.charCodeAt(0) || data[offset + 2] !== '3'.charCodeAt(0)) {
      return offset;
    }

    offset += parseId3TagSize(data, offset);
    return getId3Offset(data, offset);
  }; // TODO: use vhs-utils


  var isLikelyAacData$2 = function isLikelyAacData(data) {
    var offset = getId3Offset(data, 0);
    return data.length >= offset + 2 && (data[offset] & 0xFF) === 0xFF && (data[offset + 1] & 0xF0) === 0xF0 && // verify that the 2 layer bits are 0, aka this
    // is not mp3 data but aac data.
    (data[offset + 1] & 0x16) === 0x10;
  };

  var parseSyncSafeInteger = function parseSyncSafeInteger(data) {
    return data[0] << 21 | data[1] << 14 | data[2] << 7 | data[3];
  }; // return a percent-encoded representation of the specified byte range
  // @see http://en.wikipedia.org/wiki/Percent-encoding


  var percentEncode = function percentEncode(bytes, start, end) {
    var i,
        result = '';

    for (i = start; i < end; i++) {
      result += '%' + ('00' + bytes[i].toString(16)).slice(-2);
    }

    return result;
  }; // return the string representation of the specified byte range,
  // interpreted as ISO-8859-1.


  var parseIso88591 = function parseIso88591(bytes, start, end) {
    return unescape(percentEncode(bytes, start, end)); // jshint ignore:line
  };

  var parseAdtsSize = function parseAdtsSize(header, byteIndex) {
    var lowThree = (header[byteIndex + 5] & 0xE0) >> 5,
        middle = header[byteIndex + 4] << 3,
        highTwo = header[byteIndex + 3] & 0x3 << 11;
    return highTwo | middle | lowThree;
  };

  var parseType$1 = function parseType(header, byteIndex) {
    if (header[byteIndex] === 'I'.charCodeAt(0) && header[byteIndex + 1] === 'D'.charCodeAt(0) && header[byteIndex + 2] === '3'.charCodeAt(0)) {
      return 'timed-metadata';
    } else if (header[byteIndex] & 0xff === 0xff && (header[byteIndex + 1] & 0xf0) === 0xf0) {
      return 'audio';
    }

    return null;
  };

  var parseSampleRate = function parseSampleRate(packet) {
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

  var parseAacTimestamp = function parseAacTimestamp(packet) {
    var frameStart, frameSize, frame, frameHeader; // find the start of the first frame and the end of the tag

    frameStart = 10;

    if (packet[5] & 0x40) {
      // advance the frame start past the extended header
      frameStart += 4; // header size field

      frameStart += parseSyncSafeInteger(packet.subarray(10, 14));
    } // parse one or more ID3 frames
    // http://id3.org/id3v2.3.0#ID3v2_frame_overview


    do {
      // determine the number of bytes in this frame
      frameSize = parseSyncSafeInteger(packet.subarray(frameStart + 4, frameStart + 8));

      if (frameSize < 1) {
        return null;
      }

      frameHeader = String.fromCharCode(packet[frameStart], packet[frameStart + 1], packet[frameStart + 2], packet[frameStart + 3]);

      if (frameHeader === 'PRIV') {
        frame = packet.subarray(frameStart + 10, frameStart + frameSize + 10);

        for (var i = 0; i < frame.byteLength; i++) {
          if (frame[i] === 0) {
            var owner = parseIso88591(frame, 0, i);

            if (owner === 'com.apple.streaming.transportStreamTimestamp') {
              var d = frame.subarray(i + 1);
              var size = (d[3] & 0x01) << 30 | d[4] << 22 | d[5] << 14 | d[6] << 6 | d[7] >>> 2;
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

  var utils = {
    isLikelyAacData: isLikelyAacData$2,
    parseId3TagSize: parseId3TagSize,
    parseAdtsSize: parseAdtsSize,
    parseType: parseType$1,
    parseSampleRate: parseSampleRate,
    parseAacTimestamp: parseAacTimestamp
  };

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


          frameSize = utils.parseId3TagSize(everything, byteIndex); // Exit early if we don't have enough in the buffer
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

          frameSize = utils.parseAdtsSize(everything, byteIndex); // Exit early if we don't have enough in the buffer
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

  _AacStream.prototype = new stream();
  var aac = _AacStream;

  // constants
  var AUDIO_PROPERTIES = ['audioobjecttype', 'channelcount', 'samplerate', 'samplingfrequencyindex', 'samplesize'];
  var audioProperties = AUDIO_PROPERTIES;

  var VIDEO_PROPERTIES = ['width', 'height', 'profileIdc', 'levelIdc', 'profileCompatibility', 'sarRatio'];
  var videoProperties = VIDEO_PROPERTIES;

  var H264Stream$1 = h264.H264Stream;
  var isLikelyAacData$1 = utils.isLikelyAacData;
  var ONE_SECOND_IN_TS$2 = clock.ONE_SECOND_IN_TS; // object types

  var _VideoSegmentStream$1, _AudioSegmentStream$1, _Transmuxer$1, _CoalesceStream;

  var retriggerForStream = function retriggerForStream(key, event) {
    event.stream = key;
    this.trigger('log', event);
  };

  var addPipelineLogRetriggers = function addPipelineLogRetriggers(transmuxer, pipeline) {
    var keys = Object.keys(pipeline);

    for (var i = 0; i < keys.length; i++) {
      var key = keys[i]; // skip non-stream keys and headOfPipeline
      // which is just a duplicate

      if (key === 'headOfPipeline' || !pipeline[key].on) {
        continue;
      }

      pipeline[key].on('log', retriggerForStream.bind(transmuxer, key));
    }
  };
  /**
   * Compare two arrays (even typed) for same-ness
   */


  var arrayEquals = function arrayEquals(a, b) {
    var i;

    if (a.length !== b.length) {
      return false;
    } // compare the value of each element in the array


    for (i = 0; i < a.length; i++) {
      if (a[i] !== b[i]) {
        return false;
      }
    }

    return true;
  };

  var generateSegmentTimingInfo = function generateSegmentTimingInfo(baseMediaDecodeTime, startDts, startPts, endDts, endPts, prependedContentDuration) {
    var ptsOffsetFromDts = startPts - startDts,
        decodeDuration = endDts - startDts,
        presentationDuration = endPts - startPts; // The PTS and DTS values are based on the actual stream times from the segment,
    // however, the player time values will reflect a start from the baseMediaDecodeTime.
    // In order to provide relevant values for the player times, base timing info on the
    // baseMediaDecodeTime and the DTS and PTS durations of the segment.

    return {
      start: {
        dts: baseMediaDecodeTime,
        pts: baseMediaDecodeTime + ptsOffsetFromDts
      },
      end: {
        dts: baseMediaDecodeTime + decodeDuration,
        pts: baseMediaDecodeTime + presentationDuration
      },
      prependedContentDuration: prependedContentDuration,
      baseMediaDecodeTime: baseMediaDecodeTime
    };
  };
  /**
   * Constructs a single-track, ISO BMFF media segment from AAC data
   * events. The output of this stream can be fed to a SourceBuffer
   * configured with a suitable initialization segment.
   * @param track {object} track metadata configuration
   * @param options {object} transmuxer options object
   * @param options.keepOriginalTimestamps {boolean} If true, keep the timestamps
   *        in the source; false to adjust the first segment to start at 0.
   */


  _AudioSegmentStream$1 = function AudioSegmentStream(track, options) {
    var adtsFrames = [],
        sequenceNumber,
        earliestAllowedDts = 0,
        audioAppendStartTs = 0,
        videoBaseMediaDecodeTime = Infinity;
    options = options || {};
    sequenceNumber = options.firstSequenceNumber || 0;

    _AudioSegmentStream$1.prototype.init.call(this);

    this.push = function (data) {
      trackDecodeInfo.collectDtsInfo(track, data);

      if (track) {
        audioProperties.forEach(function (prop) {
          track[prop] = data[prop];
        });
      } // buffer audio data until end() is called


      adtsFrames.push(data);
    };

    this.setEarliestDts = function (earliestDts) {
      earliestAllowedDts = earliestDts;
    };

    this.setVideoBaseMediaDecodeTime = function (baseMediaDecodeTime) {
      videoBaseMediaDecodeTime = baseMediaDecodeTime;
    };

    this.setAudioAppendStart = function (timestamp) {
      audioAppendStartTs = timestamp;
    };

    this.flush = function () {
      var frames, moof, mdat, boxes, frameDuration, segmentDuration, videoClockCyclesOfSilencePrefixed; // return early if no audio data has been observed

      if (adtsFrames.length === 0) {
        this.trigger('done', 'AudioSegmentStream');
        return;
      }

      frames = audioFrameUtils.trimAdtsFramesByEarliestDts(adtsFrames, track, earliestAllowedDts);
      track.baseMediaDecodeTime = trackDecodeInfo.calculateTrackBaseMediaDecodeTime(track, options.keepOriginalTimestamps); // amount of audio filled but the value is in video clock rather than audio clock

      videoClockCyclesOfSilencePrefixed = audioFrameUtils.prefixWithSilence(track, frames, audioAppendStartTs, videoBaseMediaDecodeTime); // we have to build the index from byte locations to
      // samples (that is, adts frames) in the audio data

      track.samples = audioFrameUtils.generateSampleTable(frames); // concatenate the audio data to constuct the mdat

      mdat = mp4Generator.mdat(audioFrameUtils.concatenateFrameData(frames));
      adtsFrames = [];
      moof = mp4Generator.moof(sequenceNumber, [track]);
      boxes = new Uint8Array(moof.byteLength + mdat.byteLength); // bump the sequence number for next time

      sequenceNumber++;
      boxes.set(moof);
      boxes.set(mdat, moof.byteLength);
      trackDecodeInfo.clearDtsInfo(track);
      frameDuration = Math.ceil(ONE_SECOND_IN_TS$2 * 1024 / track.samplerate); // TODO this check was added to maintain backwards compatibility (particularly with
      // tests) on adding the timingInfo event. However, it seems unlikely that there's a
      // valid use-case where an init segment/data should be triggered without associated
      // frames. Leaving for now, but should be looked into.

      if (frames.length) {
        segmentDuration = frames.length * frameDuration;
        this.trigger('segmentTimingInfo', generateSegmentTimingInfo( // The audio track's baseMediaDecodeTime is in audio clock cycles, but the
        // frame info is in video clock cycles. Convert to match expectation of
        // listeners (that all timestamps will be based on video clock cycles).
        clock.audioTsToVideoTs(track.baseMediaDecodeTime, track.samplerate), // frame times are already in video clock, as is segment duration
        frames[0].dts, frames[0].pts, frames[0].dts + segmentDuration, frames[0].pts + segmentDuration, videoClockCyclesOfSilencePrefixed || 0));
        this.trigger('timingInfo', {
          start: frames[0].pts,
          end: frames[0].pts + segmentDuration
        });
      }

      this.trigger('data', {
        track: track,
        boxes: boxes
      });
      this.trigger('done', 'AudioSegmentStream');
    };

    this.reset = function () {
      trackDecodeInfo.clearDtsInfo(track);
      adtsFrames = [];
      this.trigger('reset');
    };
  };

  _AudioSegmentStream$1.prototype = new stream();
  /**
   * Constructs a single-track, ISO BMFF media segment from H264 data
   * events. The output of this stream can be fed to a SourceBuffer
   * configured with a suitable initialization segment.
   * @param track {object} track metadata configuration
   * @param options {object} transmuxer options object
   * @param options.alignGopsAtEnd {boolean} If true, start from the end of the
   *        gopsToAlignWith list when attempting to align gop pts
   * @param options.keepOriginalTimestamps {boolean} If true, keep the timestamps
   *        in the source; false to adjust the first segment to start at 0.
   */

  _VideoSegmentStream$1 = function VideoSegmentStream(track, options) {
    var sequenceNumber,
        nalUnits = [],
        gopsToAlignWith = [],
        config,
        pps;
    options = options || {};
    sequenceNumber = options.firstSequenceNumber || 0;

    _VideoSegmentStream$1.prototype.init.call(this);

    delete track.minPTS;
    this.gopCache_ = [];
    /**
      * Constructs a ISO BMFF segment given H264 nalUnits
      * @param {Object} nalUnit A data event representing a nalUnit
      * @param {String} nalUnit.nalUnitType
      * @param {Object} nalUnit.config Properties for a mp4 track
      * @param {Uint8Array} nalUnit.data The nalUnit bytes
      * @see lib/codecs/h264.js
     **/

    this.push = function (nalUnit) {
      trackDecodeInfo.collectDtsInfo(track, nalUnit); // record the track config

      if (nalUnit.nalUnitType === 'seq_parameter_set_rbsp' && !config) {
        config = nalUnit.config;
        track.sps = [nalUnit.data];
        videoProperties.forEach(function (prop) {
          track[prop] = config[prop];
        }, this);
      }

      if (nalUnit.nalUnitType === 'pic_parameter_set_rbsp' && !pps) {
        pps = nalUnit.data;
        track.pps = [nalUnit.data];
      } // buffer video until flush() is called


      nalUnits.push(nalUnit);
    };
    /**
      * Pass constructed ISO BMFF track and boxes on to the
      * next stream in the pipeline
     **/


    this.flush = function () {
      var frames,
          gopForFusion,
          gops,
          moof,
          mdat,
          boxes,
          prependedContentDuration = 0,
          firstGop,
          lastGop; // Throw away nalUnits at the start of the byte stream until
      // we find the first AUD

      while (nalUnits.length) {
        if (nalUnits[0].nalUnitType === 'access_unit_delimiter_rbsp') {
          break;
        }

        nalUnits.shift();
      } // Return early if no video data has been observed


      if (nalUnits.length === 0) {
        this.resetStream_();
        this.trigger('done', 'VideoSegmentStream');
        return;
      } // Organize the raw nal-units into arrays that represent
      // higher-level constructs such as frames and gops
      // (group-of-pictures)


      frames = frameUtils.groupNalsIntoFrames(nalUnits);
      gops = frameUtils.groupFramesIntoGops(frames); // If the first frame of this fragment is not a keyframe we have
      // a problem since MSE (on Chrome) requires a leading keyframe.
      //
      // We have two approaches to repairing this situation:
      // 1) GOP-FUSION:
      //    This is where we keep track of the GOPS (group-of-pictures)
      //    from previous fragments and attempt to find one that we can
      //    prepend to the current fragment in order to create a valid
      //    fragment.
      // 2) KEYFRAME-PULLING:
      //    Here we search for the first keyframe in the fragment and
      //    throw away all the frames between the start of the fragment
      //    and that keyframe. We then extend the duration and pull the
      //    PTS of the keyframe forward so that it covers the time range
      //    of the frames that were disposed of.
      //
      // #1 is far prefereable over #2 which can cause "stuttering" but
      // requires more things to be just right.

      if (!gops[0][0].keyFrame) {
        // Search for a gop for fusion from our gopCache
        gopForFusion = this.getGopForFusion_(nalUnits[0], track);

        if (gopForFusion) {
          // in order to provide more accurate timing information about the segment, save
          // the number of seconds prepended to the original segment due to GOP fusion
          prependedContentDuration = gopForFusion.duration;
          gops.unshift(gopForFusion); // Adjust Gops' metadata to account for the inclusion of the
          // new gop at the beginning

          gops.byteLength += gopForFusion.byteLength;
          gops.nalCount += gopForFusion.nalCount;
          gops.pts = gopForFusion.pts;
          gops.dts = gopForFusion.dts;
          gops.duration += gopForFusion.duration;
        } else {
          // If we didn't find a candidate gop fall back to keyframe-pulling
          gops = frameUtils.extendFirstKeyFrame(gops);
        }
      } // Trim gops to align with gopsToAlignWith


      if (gopsToAlignWith.length) {
        var alignedGops;

        if (options.alignGopsAtEnd) {
          alignedGops = this.alignGopsAtEnd_(gops);
        } else {
          alignedGops = this.alignGopsAtStart_(gops);
        }

        if (!alignedGops) {
          // save all the nals in the last GOP into the gop cache
          this.gopCache_.unshift({
            gop: gops.pop(),
            pps: track.pps,
            sps: track.sps
          }); // Keep a maximum of 6 GOPs in the cache

          this.gopCache_.length = Math.min(6, this.gopCache_.length); // Clear nalUnits

          nalUnits = []; // return early no gops can be aligned with desired gopsToAlignWith

          this.resetStream_();
          this.trigger('done', 'VideoSegmentStream');
          return;
        } // Some gops were trimmed. clear dts info so minSegmentDts and pts are correct
        // when recalculated before sending off to CoalesceStream


        trackDecodeInfo.clearDtsInfo(track);
        gops = alignedGops;
      }

      trackDecodeInfo.collectDtsInfo(track, gops); // First, we have to build the index from byte locations to
      // samples (that is, frames) in the video data

      track.samples = frameUtils.generateSampleTable(gops); // Concatenate the video data and construct the mdat

      mdat = mp4Generator.mdat(frameUtils.concatenateNalData(gops));
      track.baseMediaDecodeTime = trackDecodeInfo.calculateTrackBaseMediaDecodeTime(track, options.keepOriginalTimestamps);
      this.trigger('processedGopsInfo', gops.map(function (gop) {
        return {
          pts: gop.pts,
          dts: gop.dts,
          byteLength: gop.byteLength
        };
      }));
      firstGop = gops[0];
      lastGop = gops[gops.length - 1];
      this.trigger('segmentTimingInfo', generateSegmentTimingInfo(track.baseMediaDecodeTime, firstGop.dts, firstGop.pts, lastGop.dts + lastGop.duration, lastGop.pts + lastGop.duration, prependedContentDuration));
      this.trigger('timingInfo', {
        start: gops[0].pts,
        end: gops[gops.length - 1].pts + gops[gops.length - 1].duration
      }); // save all the nals in the last GOP into the gop cache

      this.gopCache_.unshift({
        gop: gops.pop(),
        pps: track.pps,
        sps: track.sps
      }); // Keep a maximum of 6 GOPs in the cache

      this.gopCache_.length = Math.min(6, this.gopCache_.length); // Clear nalUnits

      nalUnits = [];
      this.trigger('baseMediaDecodeTime', track.baseMediaDecodeTime);
      this.trigger('timelineStartInfo', track.timelineStartInfo);
      moof = mp4Generator.moof(sequenceNumber, [track]); // it would be great to allocate this array up front instead of
      // throwing away hundreds of media segment fragments

      boxes = new Uint8Array(moof.byteLength + mdat.byteLength); // Bump the sequence number for next time

      sequenceNumber++;
      boxes.set(moof);
      boxes.set(mdat, moof.byteLength);
      this.trigger('data', {
        track: track,
        boxes: boxes
      });
      this.resetStream_(); // Continue with the flush process now

      this.trigger('done', 'VideoSegmentStream');
    };

    this.reset = function () {
      this.resetStream_();
      nalUnits = [];
      this.gopCache_.length = 0;
      gopsToAlignWith.length = 0;
      this.trigger('reset');
    };

    this.resetStream_ = function () {
      trackDecodeInfo.clearDtsInfo(track); // reset config and pps because they may differ across segments
      // for instance, when we are rendition switching

      config = undefined;
      pps = undefined;
    }; // Search for a candidate Gop for gop-fusion from the gop cache and
    // return it or return null if no good candidate was found


    this.getGopForFusion_ = function (nalUnit) {
      var halfSecond = 45000,
          // Half-a-second in a 90khz clock
      allowableOverlap = 10000,
          // About 3 frames @ 30fps
      nearestDistance = Infinity,
          dtsDistance,
          nearestGopObj,
          currentGop,
          currentGopObj,
          i; // Search for the GOP nearest to the beginning of this nal unit

      for (i = 0; i < this.gopCache_.length; i++) {
        currentGopObj = this.gopCache_[i];
        currentGop = currentGopObj.gop; // Reject Gops with different SPS or PPS

        if (!(track.pps && arrayEquals(track.pps[0], currentGopObj.pps[0])) || !(track.sps && arrayEquals(track.sps[0], currentGopObj.sps[0]))) {
          continue;
        } // Reject Gops that would require a negative baseMediaDecodeTime


        if (currentGop.dts < track.timelineStartInfo.dts) {
          continue;
        } // The distance between the end of the gop and the start of the nalUnit


        dtsDistance = nalUnit.dts - currentGop.dts - currentGop.duration; // Only consider GOPS that start before the nal unit and end within
        // a half-second of the nal unit

        if (dtsDistance >= -allowableOverlap && dtsDistance <= halfSecond) {
          // Always use the closest GOP we found if there is more than
          // one candidate
          if (!nearestGopObj || nearestDistance > dtsDistance) {
            nearestGopObj = currentGopObj;
            nearestDistance = dtsDistance;
          }
        }
      }

      if (nearestGopObj) {
        return nearestGopObj.gop;
      }

      return null;
    }; // trim gop list to the first gop found that has a matching pts with a gop in the list
    // of gopsToAlignWith starting from the START of the list


    this.alignGopsAtStart_ = function (gops) {
      var alignIndex, gopIndex, align, gop, byteLength, nalCount, duration, alignedGops;
      byteLength = gops.byteLength;
      nalCount = gops.nalCount;
      duration = gops.duration;
      alignIndex = gopIndex = 0;

      while (alignIndex < gopsToAlignWith.length && gopIndex < gops.length) {
        align = gopsToAlignWith[alignIndex];
        gop = gops[gopIndex];

        if (align.pts === gop.pts) {
          break;
        }

        if (gop.pts > align.pts) {
          // this current gop starts after the current gop we want to align on, so increment
          // align index
          alignIndex++;
          continue;
        } // current gop starts before the current gop we want to align on. so increment gop
        // index


        gopIndex++;
        byteLength -= gop.byteLength;
        nalCount -= gop.nalCount;
        duration -= gop.duration;
      }

      if (gopIndex === 0) {
        // no gops to trim
        return gops;
      }

      if (gopIndex === gops.length) {
        // all gops trimmed, skip appending all gops
        return null;
      }

      alignedGops = gops.slice(gopIndex);
      alignedGops.byteLength = byteLength;
      alignedGops.duration = duration;
      alignedGops.nalCount = nalCount;
      alignedGops.pts = alignedGops[0].pts;
      alignedGops.dts = alignedGops[0].dts;
      return alignedGops;
    }; // trim gop list to the first gop found that has a matching pts with a gop in the list
    // of gopsToAlignWith starting from the END of the list


    this.alignGopsAtEnd_ = function (gops) {
      var alignIndex, gopIndex, align, gop, alignEndIndex, matchFound;
      alignIndex = gopsToAlignWith.length - 1;
      gopIndex = gops.length - 1;
      alignEndIndex = null;
      matchFound = false;

      while (alignIndex >= 0 && gopIndex >= 0) {
        align = gopsToAlignWith[alignIndex];
        gop = gops[gopIndex];

        if (align.pts === gop.pts) {
          matchFound = true;
          break;
        }

        if (align.pts > gop.pts) {
          alignIndex--;
          continue;
        }

        if (alignIndex === gopsToAlignWith.length - 1) {
          // gop.pts is greater than the last alignment candidate. If no match is found
          // by the end of this loop, we still want to append gops that come after this
          // point
          alignEndIndex = gopIndex;
        }

        gopIndex--;
      }

      if (!matchFound && alignEndIndex === null) {
        return null;
      }

      var trimIndex;

      if (matchFound) {
        trimIndex = gopIndex;
      } else {
        trimIndex = alignEndIndex;
      }

      if (trimIndex === 0) {
        return gops;
      }

      var alignedGops = gops.slice(trimIndex);
      var metadata = alignedGops.reduce(function (total, gop) {
        total.byteLength += gop.byteLength;
        total.duration += gop.duration;
        total.nalCount += gop.nalCount;
        return total;
      }, {
        byteLength: 0,
        duration: 0,
        nalCount: 0
      });
      alignedGops.byteLength = metadata.byteLength;
      alignedGops.duration = metadata.duration;
      alignedGops.nalCount = metadata.nalCount;
      alignedGops.pts = alignedGops[0].pts;
      alignedGops.dts = alignedGops[0].dts;
      return alignedGops;
    };

    this.alignGopsWith = function (newGopsToAlignWith) {
      gopsToAlignWith = newGopsToAlignWith;
    };
  };

  _VideoSegmentStream$1.prototype = new stream();
  /**
   * A Stream that can combine multiple streams (ie. audio & video)
   * into a single output segment for MSE. Also supports audio-only
   * and video-only streams.
   * @param options {object} transmuxer options object
   * @param options.keepOriginalTimestamps {boolean} If true, keep the timestamps
   *        in the source; false to adjust the first segment to start at media timeline start.
   */

  _CoalesceStream = function CoalesceStream(options, metadataStream) {
    // Number of Tracks per output segment
    // If greater than 1, we combine multiple
    // tracks into a single segment
    this.numberOfTracks = 0;
    this.metadataStream = metadataStream;
    options = options || {};

    if (typeof options.remux !== 'undefined') {
      this.remuxTracks = !!options.remux;
    } else {
      this.remuxTracks = true;
    }

    if (typeof options.keepOriginalTimestamps === 'boolean') {
      this.keepOriginalTimestamps = options.keepOriginalTimestamps;
    } else {
      this.keepOriginalTimestamps = false;
    }

    this.pendingTracks = [];
    this.videoTrack = null;
    this.pendingBoxes = [];
    this.pendingCaptions = [];
    this.pendingMetadata = [];
    this.pendingBytes = 0;
    this.emittedTracks = 0;

    _CoalesceStream.prototype.init.call(this); // Take output from multiple


    this.push = function (output) {
      // buffer incoming captions until the associated video segment
      // finishes
      if (output.text) {
        return this.pendingCaptions.push(output);
      } // buffer incoming id3 tags until the final flush


      if (output.frames) {
        return this.pendingMetadata.push(output);
      } // Add this track to the list of pending tracks and store
      // important information required for the construction of
      // the final segment


      this.pendingTracks.push(output.track);
      this.pendingBytes += output.boxes.byteLength; // TODO: is there an issue for this against chrome?
      // We unshift audio and push video because
      // as of Chrome 75 when switching from
      // one init segment to another if the video
      // mdat does not appear after the audio mdat
      // only audio will play for the duration of our transmux.

      if (output.track.type === 'video') {
        this.videoTrack = output.track;
        this.pendingBoxes.push(output.boxes);
      }

      if (output.track.type === 'audio') {
        this.audioTrack = output.track;
        this.pendingBoxes.unshift(output.boxes);
      }
    };
  };

  _CoalesceStream.prototype = new stream();

  _CoalesceStream.prototype.flush = function (flushSource) {
    var offset = 0,
        event = {
      captions: [],
      captionStreams: {},
      metadata: [],
      info: {}
    },
        caption,
        id3,
        initSegment,
        timelineStartPts = 0,
        i;

    if (this.pendingTracks.length < this.numberOfTracks) {
      if (flushSource !== 'VideoSegmentStream' && flushSource !== 'AudioSegmentStream') {
        // Return because we haven't received a flush from a data-generating
        // portion of the segment (meaning that we have only recieved meta-data
        // or captions.)
        return;
      } else if (this.remuxTracks) {
        // Return until we have enough tracks from the pipeline to remux (if we
        // are remuxing audio and video into a single MP4)
        return;
      } else if (this.pendingTracks.length === 0) {
        // In the case where we receive a flush without any data having been
        // received we consider it an emitted track for the purposes of coalescing
        // `done` events.
        // We do this for the case where there is an audio and video track in the
        // segment but no audio data. (seen in several playlists with alternate
        // audio tracks and no audio present in the main TS segments.)
        this.emittedTracks++;

        if (this.emittedTracks >= this.numberOfTracks) {
          this.trigger('done');
          this.emittedTracks = 0;
        }

        return;
      }
    }

    if (this.videoTrack) {
      timelineStartPts = this.videoTrack.timelineStartInfo.pts;
      videoProperties.forEach(function (prop) {
        event.info[prop] = this.videoTrack[prop];
      }, this);
    } else if (this.audioTrack) {
      timelineStartPts = this.audioTrack.timelineStartInfo.pts;
      audioProperties.forEach(function (prop) {
        event.info[prop] = this.audioTrack[prop];
      }, this);
    }

    if (this.videoTrack || this.audioTrack) {
      if (this.pendingTracks.length === 1) {
        event.type = this.pendingTracks[0].type;
      } else {
        event.type = 'combined';
      }

      this.emittedTracks += this.pendingTracks.length;
      initSegment = mp4Generator.initSegment(this.pendingTracks); // Create a new typed array to hold the init segment

      event.initSegment = new Uint8Array(initSegment.byteLength); // Create an init segment containing a moov
      // and track definitions

      event.initSegment.set(initSegment); // Create a new typed array to hold the moof+mdats

      event.data = new Uint8Array(this.pendingBytes); // Append each moof+mdat (one per track) together

      for (i = 0; i < this.pendingBoxes.length; i++) {
        event.data.set(this.pendingBoxes[i], offset);
        offset += this.pendingBoxes[i].byteLength;
      } // Translate caption PTS times into second offsets to match the
      // video timeline for the segment, and add track info


      for (i = 0; i < this.pendingCaptions.length; i++) {
        caption = this.pendingCaptions[i];
        caption.startTime = clock.metadataTsToSeconds(caption.startPts, timelineStartPts, this.keepOriginalTimestamps);
        caption.endTime = clock.metadataTsToSeconds(caption.endPts, timelineStartPts, this.keepOriginalTimestamps);
        event.captionStreams[caption.stream] = true;
        event.captions.push(caption);
      } // Translate ID3 frame PTS times into second offsets to match the
      // video timeline for the segment


      for (i = 0; i < this.pendingMetadata.length; i++) {
        id3 = this.pendingMetadata[i];
        id3.cueTime = clock.metadataTsToSeconds(id3.pts, timelineStartPts, this.keepOriginalTimestamps);
        event.metadata.push(id3);
      } // We add this to every single emitted segment even though we only need
      // it for the first


      event.metadata.dispatchType = this.metadataStream.dispatchType; // Reset stream state

      this.pendingTracks.length = 0;
      this.videoTrack = null;
      this.pendingBoxes.length = 0;
      this.pendingCaptions.length = 0;
      this.pendingBytes = 0;
      this.pendingMetadata.length = 0; // Emit the built segment
      // We include captions and ID3 tags for backwards compatibility,
      // ideally we should send only video and audio in the data event

      this.trigger('data', event); // Emit each caption to the outside world
      // Ideally, this would happen immediately on parsing captions,
      // but we need to ensure that video data is sent back first
      // so that caption timing can be adjusted to match video timing

      for (i = 0; i < event.captions.length; i++) {
        caption = event.captions[i];
        this.trigger('caption', caption);
      } // Emit each id3 tag to the outside world
      // Ideally, this would happen immediately on parsing the tag,
      // but we need to ensure that video data is sent back first
      // so that ID3 frame timing can be adjusted to match video timing


      for (i = 0; i < event.metadata.length; i++) {
        id3 = event.metadata[i];
        this.trigger('id3Frame', id3);
      }
    } // Only emit `done` if all tracks have been flushed and emitted


    if (this.emittedTracks >= this.numberOfTracks) {
      this.trigger('done');
      this.emittedTracks = 0;
    }
  };

  _CoalesceStream.prototype.setRemux = function (val) {
    this.remuxTracks = val;
  };
  /**
   * A Stream that expects MP2T binary data as input and produces
   * corresponding media segments, suitable for use with Media Source
   * Extension (MSE) implementations that support the ISO BMFF byte
   * stream format, like Chrome.
   */


  _Transmuxer$1 = function Transmuxer(options) {
    var self = this,
        hasFlushed = true,
        videoTrack,
        audioTrack;

    _Transmuxer$1.prototype.init.call(this);

    options = options || {};
    this.baseMediaDecodeTime = options.baseMediaDecodeTime || 0;
    this.transmuxPipeline_ = {};

    this.setupAacPipeline = function () {
      var pipeline = {};
      this.transmuxPipeline_ = pipeline;
      pipeline.type = 'aac';
      pipeline.metadataStream = new m2ts_1.MetadataStream(); // set up the parsing pipeline

      pipeline.aacStream = new aac();
      pipeline.audioTimestampRolloverStream = new m2ts_1.TimestampRolloverStream('audio');
      pipeline.timedMetadataTimestampRolloverStream = new m2ts_1.TimestampRolloverStream('timed-metadata');
      pipeline.adtsStream = new adts();
      pipeline.coalesceStream = new _CoalesceStream(options, pipeline.metadataStream);
      pipeline.headOfPipeline = pipeline.aacStream;
      pipeline.aacStream.pipe(pipeline.audioTimestampRolloverStream).pipe(pipeline.adtsStream);
      pipeline.aacStream.pipe(pipeline.timedMetadataTimestampRolloverStream).pipe(pipeline.metadataStream).pipe(pipeline.coalesceStream);
      pipeline.metadataStream.on('timestamp', function (frame) {
        pipeline.aacStream.setTimestamp(frame.timeStamp);
      });
      pipeline.aacStream.on('data', function (data) {
        if (data.type !== 'timed-metadata' && data.type !== 'audio' || pipeline.audioSegmentStream) {
          return;
        }

        audioTrack = audioTrack || {
          timelineStartInfo: {
            baseMediaDecodeTime: self.baseMediaDecodeTime
          },
          codec: 'adts',
          type: 'audio'
        }; // hook up the audio segment stream to the first track with aac data

        pipeline.coalesceStream.numberOfTracks++;
        pipeline.audioSegmentStream = new _AudioSegmentStream$1(audioTrack, options);
        pipeline.audioSegmentStream.on('log', self.getLogTrigger_('audioSegmentStream'));
        pipeline.audioSegmentStream.on('timingInfo', self.trigger.bind(self, 'audioTimingInfo')); // Set up the final part of the audio pipeline

        pipeline.adtsStream.pipe(pipeline.audioSegmentStream).pipe(pipeline.coalesceStream); // emit pmt info

        self.trigger('trackinfo', {
          hasAudio: !!audioTrack,
          hasVideo: !!videoTrack
        });
      }); // Re-emit any data coming from the coalesce stream to the outside world

      pipeline.coalesceStream.on('data', this.trigger.bind(this, 'data')); // Let the consumer know we have finished flushing the entire pipeline

      pipeline.coalesceStream.on('done', this.trigger.bind(this, 'done'));
      addPipelineLogRetriggers(this, pipeline);
    };

    this.setupTsPipeline = function () {
      var pipeline = {};
      this.transmuxPipeline_ = pipeline;
      pipeline.type = 'ts';
      pipeline.metadataStream = new m2ts_1.MetadataStream(); // set up the parsing pipeline

      pipeline.packetStream = new m2ts_1.TransportPacketStream();
      pipeline.parseStream = new m2ts_1.TransportParseStream();
      pipeline.elementaryStream = new m2ts_1.ElementaryStream();
      pipeline.timestampRolloverStream = new m2ts_1.TimestampRolloverStream();
      pipeline.adtsStream = new adts();
      pipeline.h264Stream = new H264Stream$1();
      pipeline.captionStream = new m2ts_1.CaptionStream(options);
      pipeline.coalesceStream = new _CoalesceStream(options, pipeline.metadataStream);
      pipeline.headOfPipeline = pipeline.packetStream; // disassemble MPEG2-TS packets into elementary streams

      pipeline.packetStream.pipe(pipeline.parseStream).pipe(pipeline.elementaryStream).pipe(pipeline.timestampRolloverStream); // !!THIS ORDER IS IMPORTANT!!
      // demux the streams

      pipeline.timestampRolloverStream.pipe(pipeline.h264Stream);
      pipeline.timestampRolloverStream.pipe(pipeline.adtsStream);
      pipeline.timestampRolloverStream.pipe(pipeline.metadataStream).pipe(pipeline.coalesceStream); // Hook up CEA-608/708 caption stream

      pipeline.h264Stream.pipe(pipeline.captionStream).pipe(pipeline.coalesceStream);
      pipeline.elementaryStream.on('data', function (data) {
        var i;

        if (data.type === 'metadata') {
          i = data.tracks.length; // scan the tracks listed in the metadata

          while (i--) {
            if (!videoTrack && data.tracks[i].type === 'video') {
              videoTrack = data.tracks[i];
              videoTrack.timelineStartInfo.baseMediaDecodeTime = self.baseMediaDecodeTime;
            } else if (!audioTrack && data.tracks[i].type === 'audio') {
              audioTrack = data.tracks[i];
              audioTrack.timelineStartInfo.baseMediaDecodeTime = self.baseMediaDecodeTime;
            }
          } // hook up the video segment stream to the first track with h264 data


          if (videoTrack && !pipeline.videoSegmentStream) {
            pipeline.coalesceStream.numberOfTracks++;
            pipeline.videoSegmentStream = new _VideoSegmentStream$1(videoTrack, options);
            pipeline.videoSegmentStream.on('log', self.getLogTrigger_('videoSegmentStream'));
            pipeline.videoSegmentStream.on('timelineStartInfo', function (timelineStartInfo) {
              // When video emits timelineStartInfo data after a flush, we forward that
              // info to the AudioSegmentStream, if it exists, because video timeline
              // data takes precedence.  Do not do this if keepOriginalTimestamps is set,
              // because this is a particularly subtle form of timestamp alteration.
              if (audioTrack && !options.keepOriginalTimestamps) {
                audioTrack.timelineStartInfo = timelineStartInfo; // On the first segment we trim AAC frames that exist before the
                // very earliest DTS we have seen in video because Chrome will
                // interpret any video track with a baseMediaDecodeTime that is
                // non-zero as a gap.

                pipeline.audioSegmentStream.setEarliestDts(timelineStartInfo.dts - self.baseMediaDecodeTime);
              }
            });
            pipeline.videoSegmentStream.on('processedGopsInfo', self.trigger.bind(self, 'gopInfo'));
            pipeline.videoSegmentStream.on('segmentTimingInfo', self.trigger.bind(self, 'videoSegmentTimingInfo'));
            pipeline.videoSegmentStream.on('baseMediaDecodeTime', function (baseMediaDecodeTime) {
              if (audioTrack) {
                pipeline.audioSegmentStream.setVideoBaseMediaDecodeTime(baseMediaDecodeTime);
              }
            });
            pipeline.videoSegmentStream.on('timingInfo', self.trigger.bind(self, 'videoTimingInfo')); // Set up the final part of the video pipeline

            pipeline.h264Stream.pipe(pipeline.videoSegmentStream).pipe(pipeline.coalesceStream);
          }

          if (audioTrack && !pipeline.audioSegmentStream) {
            // hook up the audio segment stream to the first track with aac data
            pipeline.coalesceStream.numberOfTracks++;
            pipeline.audioSegmentStream = new _AudioSegmentStream$1(audioTrack, options);
            pipeline.audioSegmentStream.on('log', self.getLogTrigger_('audioSegmentStream'));
            pipeline.audioSegmentStream.on('timingInfo', self.trigger.bind(self, 'audioTimingInfo'));
            pipeline.audioSegmentStream.on('segmentTimingInfo', self.trigger.bind(self, 'audioSegmentTimingInfo')); // Set up the final part of the audio pipeline

            pipeline.adtsStream.pipe(pipeline.audioSegmentStream).pipe(pipeline.coalesceStream);
          } // emit pmt info


          self.trigger('trackinfo', {
            hasAudio: !!audioTrack,
            hasVideo: !!videoTrack
          });
        }
      }); // Re-emit any data coming from the coalesce stream to the outside world

      pipeline.coalesceStream.on('data', this.trigger.bind(this, 'data'));
      pipeline.coalesceStream.on('id3Frame', function (id3Frame) {
        id3Frame.dispatchType = pipeline.metadataStream.dispatchType;
        self.trigger('id3Frame', id3Frame);
      });
      pipeline.coalesceStream.on('caption', this.trigger.bind(this, 'caption')); // Let the consumer know we have finished flushing the entire pipeline

      pipeline.coalesceStream.on('done', this.trigger.bind(this, 'done'));
      addPipelineLogRetriggers(this, pipeline);
    }; // hook up the segment streams once track metadata is delivered


    this.setBaseMediaDecodeTime = function (baseMediaDecodeTime) {
      var pipeline = this.transmuxPipeline_;

      if (!options.keepOriginalTimestamps) {
        this.baseMediaDecodeTime = baseMediaDecodeTime;
      }

      if (audioTrack) {
        audioTrack.timelineStartInfo.dts = undefined;
        audioTrack.timelineStartInfo.pts = undefined;
        trackDecodeInfo.clearDtsInfo(audioTrack);

        if (pipeline.audioTimestampRolloverStream) {
          pipeline.audioTimestampRolloverStream.discontinuity();
        }
      }

      if (videoTrack) {
        if (pipeline.videoSegmentStream) {
          pipeline.videoSegmentStream.gopCache_ = [];
        }

        videoTrack.timelineStartInfo.dts = undefined;
        videoTrack.timelineStartInfo.pts = undefined;
        trackDecodeInfo.clearDtsInfo(videoTrack);
        pipeline.captionStream.reset();
      }

      if (pipeline.timestampRolloverStream) {
        pipeline.timestampRolloverStream.discontinuity();
      }
    };

    this.setAudioAppendStart = function (timestamp) {
      if (audioTrack) {
        this.transmuxPipeline_.audioSegmentStream.setAudioAppendStart(timestamp);
      }
    };

    this.setRemux = function (val) {
      var pipeline = this.transmuxPipeline_;
      options.remux = val;

      if (pipeline && pipeline.coalesceStream) {
        pipeline.coalesceStream.setRemux(val);
      }
    };

    this.alignGopsWith = function (gopsToAlignWith) {
      if (videoTrack && this.transmuxPipeline_.videoSegmentStream) {
        this.transmuxPipeline_.videoSegmentStream.alignGopsWith(gopsToAlignWith);
      }
    };

    this.getLogTrigger_ = function (key) {
      var self = this;
      return function (event) {
        event.stream = key;
        self.trigger('log', event);
      };
    }; // feed incoming data to the front of the parsing pipeline


    this.push = function (data) {
      if (hasFlushed) {
        var isAac = isLikelyAacData$1(data);

        if (isAac && this.transmuxPipeline_.type !== 'aac') {
          this.setupAacPipeline();
        } else if (!isAac && this.transmuxPipeline_.type !== 'ts') {
          this.setupTsPipeline();
        }

        hasFlushed = false;
      }

      this.transmuxPipeline_.headOfPipeline.push(data);
    }; // flush any buffered data


    this.flush = function () {
      hasFlushed = true; // Start at the top of the pipeline and flush all pending work

      this.transmuxPipeline_.headOfPipeline.flush();
    };

    this.endTimeline = function () {
      this.transmuxPipeline_.headOfPipeline.endTimeline();
    };

    this.reset = function () {
      if (this.transmuxPipeline_.headOfPipeline) {
        this.transmuxPipeline_.headOfPipeline.reset();
      }
    }; // Caption data has to be reset when seeking outside buffered range


    this.resetCaptions = function () {
      if (this.transmuxPipeline_.captionStream) {
        this.transmuxPipeline_.captionStream.reset();
      }
    };
  };

  _Transmuxer$1.prototype = new stream();
  var transmuxer$2 = {
    Transmuxer: _Transmuxer$1,
    VideoSegmentStream: _VideoSegmentStream$1,
    AudioSegmentStream: _AudioSegmentStream$1,
    AUDIO_PROPERTIES: audioProperties,
    VIDEO_PROPERTIES: videoProperties,
    // exported for testing
    generateSegmentTimingInfo: generateSegmentTimingInfo
  };

  var discardEmulationPreventionBytes = captionPacketParser.discardEmulationPreventionBytes;
  var CaptionStream = captionStream.CaptionStream;
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
          sample.pts = currentDts + window__default['default'].BigInt(sample.compositionTimeOffset);
          currentDts += window__default['default'].BigInt(sample.duration);
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
    var trafs = findBox_1(segment, ['moof', 'traf']); // To get SEI NAL units

    var mdats = findBox_1(segment, ['mdat']);
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
      var tfhd = findBox_1(traf, ['tfhd']); // Exactly 1 tfhd per traf

      var headerInfo = parseTfhd(tfhd[0]);
      var trackId = headerInfo.trackId;
      var tfdt = findBox_1(traf, ['tfdt']); // Either 0 or 1 tfdt per traf

      var baseMediaDecodeTime = tfdt.length > 0 ? parseTfdt(tfdt[0]).baseMediaDecodeTime : 0;
      var truns = findBox_1(traf, ['trun']);
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

  var captionParser = CaptionParser;

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var mp4 = {
    generator: mp4Generator,
    probe: probe$2,
    Transmuxer: transmuxer$2.Transmuxer,
    AudioSegmentStream: transmuxer$2.AudioSegmentStream,
    VideoSegmentStream: transmuxer$2.VideoSegmentStream,
    CaptionParser: captionParser
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   *
   * An object that stores the bytes of an FLV tag and methods for
   * querying and manipulating that data.
   * @see http://download.macromedia.com/f4v/video_file_format_spec_v10_1.pdf
   */

  var _FlvTag; // (type:uint, extraData:Boolean = false) extends ByteArray


  _FlvTag = function FlvTag(type, extraData) {
    var // Counter if this is a metadata tag, nal start marker if this is a video
    // tag. unused if this is an audio tag
    adHoc = 0,
        // :uint
    // The default size is 16kb but this is not enough to hold iframe
    // data and the resizing algorithm costs a bit so we create a larger
    // starting buffer for video tags
    bufferStartSize = 16384,
        // checks whether the FLV tag has enough capacity to accept the proposed
    // write and re-allocates the internal buffers if necessary
    prepareWrite = function prepareWrite(flv, count) {
      var bytes,
          minLength = flv.position + count;

      if (minLength < flv.bytes.byteLength) {
        // there's enough capacity so do nothing
        return;
      } // allocate a new buffer and copy over the data that will not be modified


      bytes = new Uint8Array(minLength * 2);
      bytes.set(flv.bytes.subarray(0, flv.position), 0);
      flv.bytes = bytes;
      flv.view = new DataView(flv.bytes.buffer);
    },
        // commonly used metadata properties
    widthBytes = _FlvTag.widthBytes || new Uint8Array('width'.length),
        heightBytes = _FlvTag.heightBytes || new Uint8Array('height'.length),
        videocodecidBytes = _FlvTag.videocodecidBytes || new Uint8Array('videocodecid'.length),
        i;

    if (!_FlvTag.widthBytes) {
      // calculating the bytes of common metadata names ahead of time makes the
      // corresponding writes faster because we don't have to loop over the
      // characters
      // re-test with test/perf.html if you're planning on changing this
      for (i = 0; i < 'width'.length; i++) {
        widthBytes[i] = 'width'.charCodeAt(i);
      }

      for (i = 0; i < 'height'.length; i++) {
        heightBytes[i] = 'height'.charCodeAt(i);
      }

      for (i = 0; i < 'videocodecid'.length; i++) {
        videocodecidBytes[i] = 'videocodecid'.charCodeAt(i);
      }

      _FlvTag.widthBytes = widthBytes;
      _FlvTag.heightBytes = heightBytes;
      _FlvTag.videocodecidBytes = videocodecidBytes;
    }

    this.keyFrame = false; // :Boolean

    switch (type) {
      case _FlvTag.VIDEO_TAG:
        this.length = 16; // Start the buffer at 256k

        bufferStartSize *= 6;
        break;

      case _FlvTag.AUDIO_TAG:
        this.length = 13;
        this.keyFrame = true;
        break;

      case _FlvTag.METADATA_TAG:
        this.length = 29;
        this.keyFrame = true;
        break;

      default:
        throw new Error('Unknown FLV tag type');
    }

    this.bytes = new Uint8Array(bufferStartSize);
    this.view = new DataView(this.bytes.buffer);
    this.bytes[0] = type;
    this.position = this.length;
    this.keyFrame = extraData; // Defaults to false
    // presentation timestamp

    this.pts = 0; // decoder timestamp

    this.dts = 0; // ByteArray#writeBytes(bytes:ByteArray, offset:uint = 0, length:uint = 0)

    this.writeBytes = function (bytes, offset, length) {
      var start = offset || 0,
          end;
      length = length || bytes.byteLength;
      end = start + length;
      prepareWrite(this, length);
      this.bytes.set(bytes.subarray(start, end), this.position);
      this.position += length;
      this.length = Math.max(this.length, this.position);
    }; // ByteArray#writeByte(value:int):void


    this.writeByte = function (byte) {
      prepareWrite(this, 1);
      this.bytes[this.position] = byte;
      this.position++;
      this.length = Math.max(this.length, this.position);
    }; // ByteArray#writeShort(value:int):void


    this.writeShort = function (short) {
      prepareWrite(this, 2);
      this.view.setUint16(this.position, short);
      this.position += 2;
      this.length = Math.max(this.length, this.position);
    }; // Negative index into array
    // (pos:uint):int


    this.negIndex = function (pos) {
      return this.bytes[this.length - pos];
    }; // The functions below ONLY work when this[0] == VIDEO_TAG.
    // We are not going to check for that because we dont want the overhead
    // (nal:ByteArray = null):int


    this.nalUnitSize = function () {
      if (adHoc === 0) {
        return 0;
      }

      return this.length - (adHoc + 4);
    };

    this.startNalUnit = function () {
      // remember position and add 4 bytes
      if (adHoc > 0) {
        throw new Error('Attempted to create new NAL wihout closing the old one');
      } // reserve 4 bytes for nal unit size


      adHoc = this.length;
      this.length += 4;
      this.position = this.length;
    }; // (nal:ByteArray = null):void


    this.endNalUnit = function (nalContainer) {
      var nalStart, // :uint
      nalLength; // :uint
      // Rewind to the marker and write the size

      if (this.length === adHoc + 4) {
        // we started a nal unit, but didnt write one, so roll back the 4 byte size value
        this.length -= 4;
      } else if (adHoc > 0) {
        nalStart = adHoc + 4;
        nalLength = this.length - nalStart;
        this.position = adHoc;
        this.view.setUint32(this.position, nalLength);
        this.position = this.length;

        if (nalContainer) {
          // Add the tag to the NAL unit
          nalContainer.push(this.bytes.subarray(nalStart, nalStart + nalLength));
        }
      }

      adHoc = 0;
    };
    /**
     * Write out a 64-bit floating point valued metadata property. This method is
     * called frequently during a typical parse and needs to be fast.
     */
    // (key:String, val:Number):void


    this.writeMetaDataDouble = function (key, val) {
      var i;
      prepareWrite(this, 2 + key.length + 9); // write size of property name

      this.view.setUint16(this.position, key.length);
      this.position += 2; // this next part looks terrible but it improves parser throughput by
      // 10kB/s in my testing
      // write property name

      if (key === 'width') {
        this.bytes.set(widthBytes, this.position);
        this.position += 5;
      } else if (key === 'height') {
        this.bytes.set(heightBytes, this.position);
        this.position += 6;
      } else if (key === 'videocodecid') {
        this.bytes.set(videocodecidBytes, this.position);
        this.position += 12;
      } else {
        for (i = 0; i < key.length; i++) {
          this.bytes[this.position] = key.charCodeAt(i);
          this.position++;
        }
      } // skip null byte


      this.position++; // write property value

      this.view.setFloat64(this.position, val);
      this.position += 8; // update flv tag length

      this.length = Math.max(this.length, this.position);
      ++adHoc;
    }; // (key:String, val:Boolean):void


    this.writeMetaDataBoolean = function (key, val) {
      var i;
      prepareWrite(this, 2);
      this.view.setUint16(this.position, key.length);
      this.position += 2;

      for (i = 0; i < key.length; i++) {
        // if key.charCodeAt(i) >= 255, handle error
        prepareWrite(this, 1);
        this.bytes[this.position] = key.charCodeAt(i);
        this.position++;
      }

      prepareWrite(this, 2);
      this.view.setUint8(this.position, 0x01);
      this.position++;
      this.view.setUint8(this.position, val ? 0x01 : 0x00);
      this.position++;
      this.length = Math.max(this.length, this.position);
      ++adHoc;
    }; // ():ByteArray


    this.finalize = function () {
      var dtsDelta, // :int
      len; // :int

      switch (this.bytes[0]) {
        // Video Data
        case _FlvTag.VIDEO_TAG:
          // We only support AVC, 1 = key frame (for AVC, a seekable
          // frame), 2 = inter frame (for AVC, a non-seekable frame)
          this.bytes[11] = (this.keyFrame || extraData ? 0x10 : 0x20) | 0x07;
          this.bytes[12] = extraData ? 0x00 : 0x01;
          dtsDelta = this.pts - this.dts;
          this.bytes[13] = (dtsDelta & 0x00FF0000) >>> 16;
          this.bytes[14] = (dtsDelta & 0x0000FF00) >>> 8;
          this.bytes[15] = (dtsDelta & 0x000000FF) >>> 0;
          break;

        case _FlvTag.AUDIO_TAG:
          this.bytes[11] = 0xAF; // 44 kHz, 16-bit stereo

          this.bytes[12] = extraData ? 0x00 : 0x01;
          break;

        case _FlvTag.METADATA_TAG:
          this.position = 11;
          this.view.setUint8(this.position, 0x02); // String type

          this.position++;
          this.view.setUint16(this.position, 0x0A); // 10 Bytes

          this.position += 2; // set "onMetaData"

          this.bytes.set([0x6f, 0x6e, 0x4d, 0x65, 0x74, 0x61, 0x44, 0x61, 0x74, 0x61], this.position);
          this.position += 10;
          this.bytes[this.position] = 0x08; // Array type

          this.position++;
          this.view.setUint32(this.position, adHoc);
          this.position = this.length;
          this.bytes.set([0, 0, 9], this.position);
          this.position += 3; // End Data Tag

          this.length = this.position;
          break;
      }

      len = this.length - 11; // write the DataSize field

      this.bytes[1] = (len & 0x00FF0000) >>> 16;
      this.bytes[2] = (len & 0x0000FF00) >>> 8;
      this.bytes[3] = (len & 0x000000FF) >>> 0; // write the Timestamp

      this.bytes[4] = (this.dts & 0x00FF0000) >>> 16;
      this.bytes[5] = (this.dts & 0x0000FF00) >>> 8;
      this.bytes[6] = (this.dts & 0x000000FF) >>> 0;
      this.bytes[7] = (this.dts & 0xFF000000) >>> 24; // write the StreamID

      this.bytes[8] = 0;
      this.bytes[9] = 0;
      this.bytes[10] = 0; // Sometimes we're at the end of the view and have one slot to write a
      // uint32, so, prepareWrite of count 4, since, view is uint8

      prepareWrite(this, 4);
      this.view.setUint32(this.length, this.length);
      this.length += 4;
      this.position += 4; // trim down the byte buffer to what is actually being used

      this.bytes = this.bytes.subarray(0, this.length);
      this.frameTime = _FlvTag.frameTime(this.bytes); // if bytes.bytelength isn't equal to this.length, handle error

      return this;
    };
  };

  _FlvTag.AUDIO_TAG = 0x08; // == 8, :uint

  _FlvTag.VIDEO_TAG = 0x09; // == 9, :uint

  _FlvTag.METADATA_TAG = 0x12; // == 18, :uint
  // (tag:ByteArray):Boolean {

  _FlvTag.isAudioFrame = function (tag) {
    return _FlvTag.AUDIO_TAG === tag[0];
  }; // (tag:ByteArray):Boolean {


  _FlvTag.isVideoFrame = function (tag) {
    return _FlvTag.VIDEO_TAG === tag[0];
  }; // (tag:ByteArray):Boolean {


  _FlvTag.isMetaData = function (tag) {
    return _FlvTag.METADATA_TAG === tag[0];
  }; // (tag:ByteArray):Boolean {


  _FlvTag.isKeyFrame = function (tag) {
    if (_FlvTag.isVideoFrame(tag)) {
      return tag[11] === 0x17;
    }

    if (_FlvTag.isAudioFrame(tag)) {
      return true;
    }

    if (_FlvTag.isMetaData(tag)) {
      return true;
    }

    return false;
  }; // (tag:ByteArray):uint {


  _FlvTag.frameTime = function (tag) {
    var pts = tag[4] << 16; // :uint

    pts |= tag[5] << 8;
    pts |= tag[6] << 0;
    pts |= tag[7] << 24;
    return pts;
  };

  var flvTag = _FlvTag;

  /**
   * The final stage of the transmuxer that emits the flv tags
   * for audio, video, and metadata. Also tranlates in time and
   * outputs caption data and id3 cues.
   */


  var CoalesceStream = function CoalesceStream(options) {
    // Number of Tracks per output segment
    // If greater than 1, we combine multiple
    // tracks into a single segment
    this.numberOfTracks = 0;
    this.metadataStream = options.metadataStream;
    this.videoTags = [];
    this.audioTags = [];
    this.videoTrack = null;
    this.audioTrack = null;
    this.pendingCaptions = [];
    this.pendingMetadata = [];
    this.pendingTracks = 0;
    this.processedTracks = 0;
    CoalesceStream.prototype.init.call(this); // Take output from multiple

    this.push = function (output) {
      // buffer incoming captions until the associated video segment
      // finishes
      if (output.text) {
        return this.pendingCaptions.push(output);
      } // buffer incoming id3 tags until the final flush


      if (output.frames) {
        return this.pendingMetadata.push(output);
      }

      if (output.track.type === 'video') {
        this.videoTrack = output.track;
        this.videoTags = output.tags;
        this.pendingTracks++;
      }

      if (output.track.type === 'audio') {
        this.audioTrack = output.track;
        this.audioTags = output.tags;
        this.pendingTracks++;
      }
    };
  };

  CoalesceStream.prototype = new stream();

  CoalesceStream.prototype.flush = function (flushSource) {
    var id3,
        caption,
        i,
        timelineStartPts,
        event = {
      tags: {},
      captions: [],
      captionStreams: {},
      metadata: []
    };

    if (this.pendingTracks < this.numberOfTracks) {
      if (flushSource !== 'VideoSegmentStream' && flushSource !== 'AudioSegmentStream') {
        // Return because we haven't received a flush from a data-generating
        // portion of the segment (meaning that we have only recieved meta-data
        // or captions.)
        return;
      } else if (this.pendingTracks === 0) {
        // In the case where we receive a flush without any data having been
        // received we consider it an emitted track for the purposes of coalescing
        // `done` events.
        // We do this for the case where there is an audio and video track in the
        // segment but no audio data. (seen in several playlists with alternate
        // audio tracks and no audio present in the main TS segments.)
        this.processedTracks++;

        if (this.processedTracks < this.numberOfTracks) {
          return;
        }
      }
    }

    this.processedTracks += this.pendingTracks;
    this.pendingTracks = 0;

    if (this.processedTracks < this.numberOfTracks) {
      return;
    }

    if (this.videoTrack) {
      timelineStartPts = this.videoTrack.timelineStartInfo.pts;
    } else if (this.audioTrack) {
      timelineStartPts = this.audioTrack.timelineStartInfo.pts;
    }

    event.tags.videoTags = this.videoTags;
    event.tags.audioTags = this.audioTags; // Translate caption PTS times into second offsets into the
    // video timeline for the segment, and add track info

    for (i = 0; i < this.pendingCaptions.length; i++) {
      caption = this.pendingCaptions[i];
      caption.startTime = caption.startPts - timelineStartPts;
      caption.startTime /= 90e3;
      caption.endTime = caption.endPts - timelineStartPts;
      caption.endTime /= 90e3;
      event.captionStreams[caption.stream] = true;
      event.captions.push(caption);
    } // Translate ID3 frame PTS times into second offsets into the
    // video timeline for the segment


    for (i = 0; i < this.pendingMetadata.length; i++) {
      id3 = this.pendingMetadata[i];
      id3.cueTime = id3.pts - timelineStartPts;
      id3.cueTime /= 90e3;
      event.metadata.push(id3);
    } // We add this to every single emitted segment even though we only need
    // it for the first


    event.metadata.dispatchType = this.metadataStream.dispatchType; // Reset stream state

    this.videoTrack = null;
    this.audioTrack = null;
    this.videoTags = [];
    this.audioTags = [];
    this.pendingCaptions.length = 0;
    this.pendingMetadata.length = 0;
    this.pendingTracks = 0;
    this.processedTracks = 0; // Emit the final segment

    this.trigger('data', event);
    this.trigger('done');
  };

  var coalesceStream = CoalesceStream;

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var TagList = function TagList() {
    var self = this;
    this.list = [];

    this.push = function (tag) {
      this.list.push({
        bytes: tag.bytes,
        dts: tag.dts,
        pts: tag.pts,
        keyFrame: tag.keyFrame,
        metaDataTag: tag.metaDataTag
      });
    };

    Object.defineProperty(this, 'length', {
      get: function get() {
        return self.list.length;
      }
    });
  };

  var tagList = TagList;

  var H264Stream = h264.H264Stream;

  var _Transmuxer, _VideoSegmentStream, _AudioSegmentStream, collectTimelineInfo, metaDataTag, extraDataTag;
  /**
   * Store information about the start and end of the tracka and the
   * duration for each frame/sample we process in order to calculate
   * the baseMediaDecodeTime
   */


  collectTimelineInfo = function collectTimelineInfo(track, data) {
    if (typeof data.pts === 'number') {
      if (track.timelineStartInfo.pts === undefined) {
        track.timelineStartInfo.pts = data.pts;
      } else {
        track.timelineStartInfo.pts = Math.min(track.timelineStartInfo.pts, data.pts);
      }
    }

    if (typeof data.dts === 'number') {
      if (track.timelineStartInfo.dts === undefined) {
        track.timelineStartInfo.dts = data.dts;
      } else {
        track.timelineStartInfo.dts = Math.min(track.timelineStartInfo.dts, data.dts);
      }
    }
  };

  metaDataTag = function metaDataTag(track, pts) {
    var tag = new flvTag(flvTag.METADATA_TAG); // :FlvTag

    tag.dts = pts;
    tag.pts = pts;
    tag.writeMetaDataDouble('videocodecid', 7);
    tag.writeMetaDataDouble('width', track.width);
    tag.writeMetaDataDouble('height', track.height);
    return tag;
  };

  extraDataTag = function extraDataTag(track, pts) {
    var i,
        tag = new flvTag(flvTag.VIDEO_TAG, true);
    tag.dts = pts;
    tag.pts = pts;
    tag.writeByte(0x01); // version

    tag.writeByte(track.profileIdc); // profile

    tag.writeByte(track.profileCompatibility); // compatibility

    tag.writeByte(track.levelIdc); // level

    tag.writeByte(0xFC | 0x03); // reserved (6 bits), NULA length size - 1 (2 bits)

    tag.writeByte(0xE0 | 0x01); // reserved (3 bits), num of SPS (5 bits)

    tag.writeShort(track.sps[0].length); // data of SPS

    tag.writeBytes(track.sps[0]); // SPS

    tag.writeByte(track.pps.length); // num of PPS (will there ever be more that 1 PPS?)

    for (i = 0; i < track.pps.length; ++i) {
      tag.writeShort(track.pps[i].length); // 2 bytes for length of PPS

      tag.writeBytes(track.pps[i]); // data of PPS
    }

    return tag;
  };
  /**
   * Constructs a single-track, media segment from AAC data
   * events. The output of this stream can be fed to flash.
   */


  _AudioSegmentStream = function AudioSegmentStream(track) {
    var adtsFrames = [],
        videoKeyFrames = [],
        oldExtraData;

    _AudioSegmentStream.prototype.init.call(this);

    this.push = function (data) {
      collectTimelineInfo(track, data);

      if (track) {
        track.audioobjecttype = data.audioobjecttype;
        track.channelcount = data.channelcount;
        track.samplerate = data.samplerate;
        track.samplingfrequencyindex = data.samplingfrequencyindex;
        track.samplesize = data.samplesize;
        track.extraData = track.audioobjecttype << 11 | track.samplingfrequencyindex << 7 | track.channelcount << 3;
      }

      data.pts = Math.round(data.pts / 90);
      data.dts = Math.round(data.dts / 90); // buffer audio data until end() is called

      adtsFrames.push(data);
    };

    this.flush = function () {
      var currentFrame,
          adtsFrame,
          lastMetaPts,
          tags = new tagList(); // return early if no audio data has been observed

      if (adtsFrames.length === 0) {
        this.trigger('done', 'AudioSegmentStream');
        return;
      }

      lastMetaPts = -Infinity;

      while (adtsFrames.length) {
        currentFrame = adtsFrames.shift(); // write out a metadata frame at every video key frame

        if (videoKeyFrames.length && currentFrame.pts >= videoKeyFrames[0]) {
          lastMetaPts = videoKeyFrames.shift();
          this.writeMetaDataTags(tags, lastMetaPts);
        } // also write out metadata tags every 1 second so that the decoder
        // is re-initialized quickly after seeking into a different
        // audio configuration.


        if (track.extraData !== oldExtraData || currentFrame.pts - lastMetaPts >= 1000) {
          this.writeMetaDataTags(tags, currentFrame.pts);
          oldExtraData = track.extraData;
          lastMetaPts = currentFrame.pts;
        }

        adtsFrame = new flvTag(flvTag.AUDIO_TAG);
        adtsFrame.pts = currentFrame.pts;
        adtsFrame.dts = currentFrame.dts;
        adtsFrame.writeBytes(currentFrame.data);
        tags.push(adtsFrame.finalize());
      }

      videoKeyFrames.length = 0;
      oldExtraData = null;
      this.trigger('data', {
        track: track,
        tags: tags.list
      });
      this.trigger('done', 'AudioSegmentStream');
    };

    this.writeMetaDataTags = function (tags, pts) {
      var adtsFrame;
      adtsFrame = new flvTag(flvTag.METADATA_TAG); // For audio, DTS is always the same as PTS. We want to set the DTS
      // however so we can compare with video DTS to determine approximate
      // packet order

      adtsFrame.pts = pts;
      adtsFrame.dts = pts; // AAC is always 10

      adtsFrame.writeMetaDataDouble('audiocodecid', 10);
      adtsFrame.writeMetaDataBoolean('stereo', track.channelcount === 2);
      adtsFrame.writeMetaDataDouble('audiosamplerate', track.samplerate); // Is AAC always 16 bit?

      adtsFrame.writeMetaDataDouble('audiosamplesize', 16);
      tags.push(adtsFrame.finalize());
      adtsFrame = new flvTag(flvTag.AUDIO_TAG, true); // For audio, DTS is always the same as PTS. We want to set the DTS
      // however so we can compare with video DTS to determine approximate
      // packet order

      adtsFrame.pts = pts;
      adtsFrame.dts = pts;
      adtsFrame.view.setUint16(adtsFrame.position, track.extraData);
      adtsFrame.position += 2;
      adtsFrame.length = Math.max(adtsFrame.length, adtsFrame.position);
      tags.push(adtsFrame.finalize());
    };

    this.onVideoKeyFrame = function (pts) {
      videoKeyFrames.push(pts);
    };
  };

  _AudioSegmentStream.prototype = new stream();
  /**
   * Store FlvTags for the h264 stream
   * @param track {object} track metadata configuration
   */

  _VideoSegmentStream = function VideoSegmentStream(track) {
    var nalUnits = [],
        config,
        h264Frame;

    _VideoSegmentStream.prototype.init.call(this);

    this.finishFrame = function (tags, frame) {
      if (!frame) {
        return;
      } // Check if keyframe and the length of tags.
      // This makes sure we write metadata on the first frame of a segment.


      if (config && track && track.newMetadata && (frame.keyFrame || tags.length === 0)) {
        // Push extra data on every IDR frame in case we did a stream change + seek
        var metaTag = metaDataTag(config, frame.dts).finalize();
        var extraTag = extraDataTag(track, frame.dts).finalize();
        metaTag.metaDataTag = extraTag.metaDataTag = true;
        tags.push(metaTag);
        tags.push(extraTag);
        track.newMetadata = false;
        this.trigger('keyframe', frame.dts);
      }

      frame.endNalUnit();
      tags.push(frame.finalize());
      h264Frame = null;
    };

    this.push = function (data) {
      collectTimelineInfo(track, data);
      data.pts = Math.round(data.pts / 90);
      data.dts = Math.round(data.dts / 90); // buffer video until flush() is called

      nalUnits.push(data);
    };

    this.flush = function () {
      var currentNal,
          tags = new tagList(); // Throw away nalUnits at the start of the byte stream until we find
      // the first AUD

      while (nalUnits.length) {
        if (nalUnits[0].nalUnitType === 'access_unit_delimiter_rbsp') {
          break;
        }

        nalUnits.shift();
      } // return early if no video data has been observed


      if (nalUnits.length === 0) {
        this.trigger('done', 'VideoSegmentStream');
        return;
      }

      while (nalUnits.length) {
        currentNal = nalUnits.shift(); // record the track config

        if (currentNal.nalUnitType === 'seq_parameter_set_rbsp') {
          track.newMetadata = true;
          config = currentNal.config;
          track.width = config.width;
          track.height = config.height;
          track.sps = [currentNal.data];
          track.profileIdc = config.profileIdc;
          track.levelIdc = config.levelIdc;
          track.profileCompatibility = config.profileCompatibility;
          h264Frame.endNalUnit();
        } else if (currentNal.nalUnitType === 'pic_parameter_set_rbsp') {
          track.newMetadata = true;
          track.pps = [currentNal.data];
          h264Frame.endNalUnit();
        } else if (currentNal.nalUnitType === 'access_unit_delimiter_rbsp') {
          if (h264Frame) {
            this.finishFrame(tags, h264Frame);
          }

          h264Frame = new flvTag(flvTag.VIDEO_TAG);
          h264Frame.pts = currentNal.pts;
          h264Frame.dts = currentNal.dts;
        } else {
          if (currentNal.nalUnitType === 'slice_layer_without_partitioning_rbsp_idr') {
            // the current sample is a key frame
            h264Frame.keyFrame = true;
          }

          h264Frame.endNalUnit();
        }

        h264Frame.startNalUnit();
        h264Frame.writeBytes(currentNal.data);
      }

      if (h264Frame) {
        this.finishFrame(tags, h264Frame);
      }

      this.trigger('data', {
        track: track,
        tags: tags.list
      }); // Continue with the flush process now

      this.trigger('done', 'VideoSegmentStream');
    };
  };

  _VideoSegmentStream.prototype = new stream();
  /**
   * An object that incrementally transmuxes MPEG2 Trasport Stream
   * chunks into an FLV.
   */

  _Transmuxer = function Transmuxer(options) {
    var self = this,
        packetStream,
        parseStream,
        elementaryStream,
        videoTimestampRolloverStream,
        audioTimestampRolloverStream,
        timedMetadataTimestampRolloverStream,
        adtsStream,
        h264Stream,
        videoSegmentStream,
        audioSegmentStream,
        captionStream,
        coalesceStream$1;

    _Transmuxer.prototype.init.call(this);

    options = options || {}; // expose the metadata stream

    this.metadataStream = new m2ts_1.MetadataStream();
    options.metadataStream = this.metadataStream; // set up the parsing pipeline

    packetStream = new m2ts_1.TransportPacketStream();
    parseStream = new m2ts_1.TransportParseStream();
    elementaryStream = new m2ts_1.ElementaryStream();
    videoTimestampRolloverStream = new m2ts_1.TimestampRolloverStream('video');
    audioTimestampRolloverStream = new m2ts_1.TimestampRolloverStream('audio');
    timedMetadataTimestampRolloverStream = new m2ts_1.TimestampRolloverStream('timed-metadata');
    adtsStream = new adts();
    h264Stream = new H264Stream();
    coalesceStream$1 = new coalesceStream(options); // disassemble MPEG2-TS packets into elementary streams

    packetStream.pipe(parseStream).pipe(elementaryStream); // !!THIS ORDER IS IMPORTANT!!
    // demux the streams

    elementaryStream.pipe(videoTimestampRolloverStream).pipe(h264Stream);
    elementaryStream.pipe(audioTimestampRolloverStream).pipe(adtsStream);
    elementaryStream.pipe(timedMetadataTimestampRolloverStream).pipe(this.metadataStream).pipe(coalesceStream$1); // if CEA-708 parsing is available, hook up a caption stream

    captionStream = new m2ts_1.CaptionStream(options);
    h264Stream.pipe(captionStream).pipe(coalesceStream$1); // hook up the segment streams once track metadata is delivered

    elementaryStream.on('data', function (data) {
      var i, videoTrack, audioTrack;

      if (data.type === 'metadata') {
        i = data.tracks.length; // scan the tracks listed in the metadata

        while (i--) {
          if (data.tracks[i].type === 'video') {
            videoTrack = data.tracks[i];
          } else if (data.tracks[i].type === 'audio') {
            audioTrack = data.tracks[i];
          }
        } // hook up the video segment stream to the first track with h264 data


        if (videoTrack && !videoSegmentStream) {
          coalesceStream$1.numberOfTracks++;
          videoSegmentStream = new _VideoSegmentStream(videoTrack); // Set up the final part of the video pipeline

          h264Stream.pipe(videoSegmentStream).pipe(coalesceStream$1);
        }

        if (audioTrack && !audioSegmentStream) {
          // hook up the audio segment stream to the first track with aac data
          coalesceStream$1.numberOfTracks++;
          audioSegmentStream = new _AudioSegmentStream(audioTrack); // Set up the final part of the audio pipeline

          adtsStream.pipe(audioSegmentStream).pipe(coalesceStream$1);

          if (videoSegmentStream) {
            videoSegmentStream.on('keyframe', audioSegmentStream.onVideoKeyFrame);
          }
        }
      }
    }); // feed incoming data to the front of the parsing pipeline

    this.push = function (data) {
      packetStream.push(data);
    }; // flush any buffered data


    this.flush = function () {
      // Start at the top of the pipeline and flush all pending work
      packetStream.flush();
    }; // Caption data has to be reset when seeking outside buffered range


    this.resetCaptions = function () {
      captionStream.reset();
    }; // Re-emit any data coming from the coalesce stream to the outside world


    coalesceStream$1.on('data', function (event) {
      self.trigger('data', event);
    }); // Let the consumer know we have finished flushing the entire pipeline

    coalesceStream$1.on('done', function () {
      self.trigger('done');
    });
  };

  _Transmuxer.prototype = new stream(); // forward compatibility

  var transmuxer$1 = _Transmuxer;

  // http://download.macromedia.com/f4v/video_file_format_spec_v10_1.pdf.
  // Technically, this function returns the header and a metadata FLV tag
  // if duration is greater than zero
  // duration in seconds
  // @return {object} the bytes of the FLV header as a Uint8Array


  var getFlvHeader = function getFlvHeader(duration, audio, video) {
    // :ByteArray {
    var headBytes = new Uint8Array(3 + 1 + 1 + 4),
        head = new DataView(headBytes.buffer),
        metadata,
        result,
        metadataLength; // default arguments

    duration = duration || 0;
    audio = audio === undefined ? true : audio;
    video = video === undefined ? true : video; // signature

    head.setUint8(0, 0x46); // 'F'

    head.setUint8(1, 0x4c); // 'L'

    head.setUint8(2, 0x56); // 'V'
    // version

    head.setUint8(3, 0x01); // flags

    head.setUint8(4, (audio ? 0x04 : 0x00) | (video ? 0x01 : 0x00)); // data offset, should be 9 for FLV v1

    head.setUint32(5, headBytes.byteLength); // init the first FLV tag

    if (duration <= 0) {
      // no duration available so just write the first field of the first
      // FLV tag
      result = new Uint8Array(headBytes.byteLength + 4);
      result.set(headBytes);
      result.set([0, 0, 0, 0], headBytes.byteLength);
      return result;
    } // write out the duration metadata tag


    metadata = new flvTag(flvTag.METADATA_TAG);
    metadata.pts = metadata.dts = 0;
    metadata.writeMetaDataDouble('duration', duration);
    metadataLength = metadata.finalize().length;
    result = new Uint8Array(headBytes.byteLength + metadataLength);
    result.set(headBytes);
    result.set(head.byteLength, metadataLength);
    return result;
  };

  var flvHeader = getFlvHeader;

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var flv = {
    tag: flvTag,
    Transmuxer: transmuxer$1,
    getFlvHeader: flvHeader
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var m2ts = m2ts_1;

  var ONE_SECOND_IN_TS$1 = clock.ONE_SECOND_IN_TS;
  /**
   * Constructs a single-track, ISO BMFF media segment from AAC data
   * events. The output of this stream can be fed to a SourceBuffer
   * configured with a suitable initialization segment.
   */

  var AudioSegmentStream = function AudioSegmentStream(track, options) {
    var adtsFrames = [],
        sequenceNumber = 0,
        earliestAllowedDts = 0,
        audioAppendStartTs = 0,
        videoBaseMediaDecodeTime = Infinity,
        segmentStartPts = null,
        segmentEndPts = null;
    options = options || {};
    AudioSegmentStream.prototype.init.call(this);

    this.push = function (data) {
      trackDecodeInfo.collectDtsInfo(track, data);

      if (track) {
        audioProperties.forEach(function (prop) {
          track[prop] = data[prop];
        });
      } // buffer audio data until end() is called


      adtsFrames.push(data);
    };

    this.setEarliestDts = function (earliestDts) {
      earliestAllowedDts = earliestDts;
    };

    this.setVideoBaseMediaDecodeTime = function (baseMediaDecodeTime) {
      videoBaseMediaDecodeTime = baseMediaDecodeTime;
    };

    this.setAudioAppendStart = function (timestamp) {
      audioAppendStartTs = timestamp;
    };

    this.processFrames_ = function () {
      var frames, moof, mdat, boxes, timingInfo; // return early if no audio data has been observed

      if (adtsFrames.length === 0) {
        return;
      }

      frames = audioFrameUtils.trimAdtsFramesByEarliestDts(adtsFrames, track, earliestAllowedDts);

      if (frames.length === 0) {
        // return early if the frames are all after the earliest allowed DTS
        // TODO should we clear the adtsFrames?
        return;
      }

      track.baseMediaDecodeTime = trackDecodeInfo.calculateTrackBaseMediaDecodeTime(track, options.keepOriginalTimestamps);
      audioFrameUtils.prefixWithSilence(track, frames, audioAppendStartTs, videoBaseMediaDecodeTime); // we have to build the index from byte locations to
      // samples (that is, adts frames) in the audio data

      track.samples = audioFrameUtils.generateSampleTable(frames); // concatenate the audio data to constuct the mdat

      mdat = mp4Generator.mdat(audioFrameUtils.concatenateFrameData(frames));
      adtsFrames = [];
      moof = mp4Generator.moof(sequenceNumber, [track]); // bump the sequence number for next time

      sequenceNumber++;
      track.initSegment = mp4Generator.initSegment([track]); // it would be great to allocate this array up front instead of
      // throwing away hundreds of media segment fragments

      boxes = new Uint8Array(moof.byteLength + mdat.byteLength);
      boxes.set(moof);
      boxes.set(mdat, moof.byteLength);
      trackDecodeInfo.clearDtsInfo(track);

      if (segmentStartPts === null) {
        segmentEndPts = segmentStartPts = frames[0].pts;
      }

      segmentEndPts += frames.length * (ONE_SECOND_IN_TS$1 * 1024 / track.samplerate);
      timingInfo = {
        start: segmentStartPts
      };
      this.trigger('timingInfo', timingInfo);
      this.trigger('data', {
        track: track,
        boxes: boxes
      });
    };

    this.flush = function () {
      this.processFrames_(); // trigger final timing info

      this.trigger('timingInfo', {
        start: segmentStartPts,
        end: segmentEndPts
      });
      this.resetTiming_();
      this.trigger('done', 'AudioSegmentStream');
    };

    this.partialFlush = function () {
      this.processFrames_();
      this.trigger('partialdone', 'AudioSegmentStream');
    };

    this.endTimeline = function () {
      this.flush();
      this.trigger('endedtimeline', 'AudioSegmentStream');
    };

    this.resetTiming_ = function () {
      trackDecodeInfo.clearDtsInfo(track);
      segmentStartPts = null;
      segmentEndPts = null;
    };

    this.reset = function () {
      this.resetTiming_();
      adtsFrames = [];
      this.trigger('reset');
    };
  };

  AudioSegmentStream.prototype = new stream();
  var audioSegmentStream = AudioSegmentStream;

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
      trackDecodeInfo.collectDtsInfo(track, nalUnit);

      if (typeof track.timelineStartInfo.dts === 'undefined') {
        track.timelineStartInfo.dts = nalUnit.dts;
      } // record the track config


      if (nalUnit.nalUnitType === 'seq_parameter_set_rbsp' && !config) {
        config = nalUnit.config;
        track.sps = [nalUnit.data];
        videoProperties.forEach(function (prop) {
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
        var mdat = mp4Generator.mdat(frameUtils.concatenateNalDataForFrame(frame));
        trackDecodeInfo.clearDtsInfo(track);
        trackDecodeInfo.collectDtsInfo(track, frame);
        track.baseMediaDecodeTime = trackDecodeInfo.calculateTrackBaseMediaDecodeTime(track, options.keepOriginalTimestamps);
        var moof = mp4Generator.moof(sequenceNumber, [track]);
        sequenceNumber++;
        track.initSegment = mp4Generator.initSegment([track]);
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

  VideoSegmentStream.prototype = new stream();
  var videoSegmentStream = VideoSegmentStream;

  var isLikelyAacData = utils.isLikelyAacData;

  var createPipeline = function createPipeline(object) {
    object.prototype = new stream();
    object.prototype.init.call(object);
    return object;
  };

  var tsPipeline = function tsPipeline(options) {
    var pipeline = {
      type: 'ts',
      tracks: {
        audio: null,
        video: null
      },
      packet: new m2ts_1.TransportPacketStream(),
      parse: new m2ts_1.TransportParseStream(),
      elementary: new m2ts_1.ElementaryStream(),
      timestampRollover: new m2ts_1.TimestampRolloverStream(),
      adts: new codecs.Adts(),
      h264: new codecs.h264.H264Stream(),
      captionStream: new m2ts_1.CaptionStream(options),
      metadataStream: new m2ts_1.MetadataStream()
    };
    pipeline.headOfPipeline = pipeline.packet; // Transport Stream

    pipeline.packet.pipe(pipeline.parse).pipe(pipeline.elementary).pipe(pipeline.timestampRollover); // H264

    pipeline.timestampRollover.pipe(pipeline.h264); // Hook up CEA-608/708 caption stream

    pipeline.h264.pipe(pipeline.captionStream);
    pipeline.timestampRollover.pipe(pipeline.metadataStream); // ADTS

    pipeline.timestampRollover.pipe(pipeline.adts);
    pipeline.elementary.on('data', function (data) {
      if (data.type !== 'metadata') {
        return;
      }

      for (var i = 0; i < data.tracks.length; i++) {
        if (!pipeline.tracks[data.tracks[i].type]) {
          pipeline.tracks[data.tracks[i].type] = data.tracks[i];
          pipeline.tracks[data.tracks[i].type].timelineStartInfo.baseMediaDecodeTime = options.baseMediaDecodeTime;
        }
      }

      if (pipeline.tracks.video && !pipeline.videoSegmentStream) {
        pipeline.videoSegmentStream = new videoSegmentStream(pipeline.tracks.video, options);
        pipeline.videoSegmentStream.on('timelineStartInfo', function (timelineStartInfo) {
          if (pipeline.tracks.audio && !options.keepOriginalTimestamps) {
            pipeline.audioSegmentStream.setEarliestDts(timelineStartInfo.dts - options.baseMediaDecodeTime);
          }
        });
        pipeline.videoSegmentStream.on('timingInfo', pipeline.trigger.bind(pipeline, 'videoTimingInfo'));
        pipeline.videoSegmentStream.on('data', function (data) {
          pipeline.trigger('data', {
            type: 'video',
            data: data
          });
        });
        pipeline.videoSegmentStream.on('done', pipeline.trigger.bind(pipeline, 'done'));
        pipeline.videoSegmentStream.on('partialdone', pipeline.trigger.bind(pipeline, 'partialdone'));
        pipeline.videoSegmentStream.on('endedtimeline', pipeline.trigger.bind(pipeline, 'endedtimeline'));
        pipeline.h264.pipe(pipeline.videoSegmentStream);
      }

      if (pipeline.tracks.audio && !pipeline.audioSegmentStream) {
        pipeline.audioSegmentStream = new audioSegmentStream(pipeline.tracks.audio, options);
        pipeline.audioSegmentStream.on('data', function (data) {
          pipeline.trigger('data', {
            type: 'audio',
            data: data
          });
        });
        pipeline.audioSegmentStream.on('done', pipeline.trigger.bind(pipeline, 'done'));
        pipeline.audioSegmentStream.on('partialdone', pipeline.trigger.bind(pipeline, 'partialdone'));
        pipeline.audioSegmentStream.on('endedtimeline', pipeline.trigger.bind(pipeline, 'endedtimeline'));
        pipeline.audioSegmentStream.on('timingInfo', pipeline.trigger.bind(pipeline, 'audioTimingInfo'));
        pipeline.adts.pipe(pipeline.audioSegmentStream);
      } // emit pmt info


      pipeline.trigger('trackinfo', {
        hasAudio: !!pipeline.tracks.audio,
        hasVideo: !!pipeline.tracks.video
      });
    });
    pipeline.captionStream.on('data', function (caption) {
      var timelineStartPts;

      if (pipeline.tracks.video) {
        timelineStartPts = pipeline.tracks.video.timelineStartInfo.pts || 0;
      } else {
        // This will only happen if we encounter caption packets before
        // video data in a segment. This is an unusual/unlikely scenario,
        // so we assume the timeline starts at zero for now.
        timelineStartPts = 0;
      } // Translate caption PTS times into second offsets into the
      // video timeline for the segment


      caption.startTime = clock.metadataTsToSeconds(caption.startPts, timelineStartPts, options.keepOriginalTimestamps);
      caption.endTime = clock.metadataTsToSeconds(caption.endPts, timelineStartPts, options.keepOriginalTimestamps);
      pipeline.trigger('caption', caption);
    });
    pipeline = createPipeline(pipeline);
    pipeline.metadataStream.on('data', pipeline.trigger.bind(pipeline, 'id3Frame'));
    return pipeline;
  };

  var aacPipeline = function aacPipeline(options) {
    var pipeline = {
      type: 'aac',
      tracks: {
        audio: null
      },
      metadataStream: new m2ts_1.MetadataStream(),
      aacStream: new aac(),
      audioRollover: new m2ts_1.TimestampRolloverStream('audio'),
      timedMetadataRollover: new m2ts_1.TimestampRolloverStream('timed-metadata'),
      adtsStream: new adts(true)
    }; // set up the parsing pipeline

    pipeline.headOfPipeline = pipeline.aacStream;
    pipeline.aacStream.pipe(pipeline.audioRollover).pipe(pipeline.adtsStream);
    pipeline.aacStream.pipe(pipeline.timedMetadataRollover).pipe(pipeline.metadataStream);
    pipeline.metadataStream.on('timestamp', function (frame) {
      pipeline.aacStream.setTimestamp(frame.timeStamp);
    });
    pipeline.aacStream.on('data', function (data) {
      if (data.type !== 'timed-metadata' && data.type !== 'audio' || pipeline.audioSegmentStream) {
        return;
      }

      pipeline.tracks.audio = pipeline.tracks.audio || {
        timelineStartInfo: {
          baseMediaDecodeTime: options.baseMediaDecodeTime
        },
        codec: 'adts',
        type: 'audio'
      }; // hook up the audio segment stream to the first track with aac data

      pipeline.audioSegmentStream = new audioSegmentStream(pipeline.tracks.audio, options);
      pipeline.audioSegmentStream.on('data', function (data) {
        pipeline.trigger('data', {
          type: 'audio',
          data: data
        });
      });
      pipeline.audioSegmentStream.on('partialdone', pipeline.trigger.bind(pipeline, 'partialdone'));
      pipeline.audioSegmentStream.on('done', pipeline.trigger.bind(pipeline, 'done'));
      pipeline.audioSegmentStream.on('endedtimeline', pipeline.trigger.bind(pipeline, 'endedtimeline'));
      pipeline.audioSegmentStream.on('timingInfo', pipeline.trigger.bind(pipeline, 'audioTimingInfo')); // Set up the final part of the audio pipeline

      pipeline.adtsStream.pipe(pipeline.audioSegmentStream);
      pipeline.trigger('trackinfo', {
        hasAudio: !!pipeline.tracks.audio,
        hasVideo: !!pipeline.tracks.video
      });
    }); // set the pipeline up as a stream before binding to get access to the trigger function

    pipeline = createPipeline(pipeline);
    pipeline.metadataStream.on('data', pipeline.trigger.bind(pipeline, 'id3Frame'));
    return pipeline;
  };

  var setupPipelineListeners = function setupPipelineListeners(pipeline, transmuxer) {
    pipeline.on('data', transmuxer.trigger.bind(transmuxer, 'data'));
    pipeline.on('done', transmuxer.trigger.bind(transmuxer, 'done'));
    pipeline.on('partialdone', transmuxer.trigger.bind(transmuxer, 'partialdone'));
    pipeline.on('endedtimeline', transmuxer.trigger.bind(transmuxer, 'endedtimeline'));
    pipeline.on('audioTimingInfo', transmuxer.trigger.bind(transmuxer, 'audioTimingInfo'));
    pipeline.on('videoTimingInfo', transmuxer.trigger.bind(transmuxer, 'videoTimingInfo'));
    pipeline.on('trackinfo', transmuxer.trigger.bind(transmuxer, 'trackinfo'));
    pipeline.on('id3Frame', function (event) {
      // add this to every single emitted segment even though it's only needed for the first
      event.dispatchType = pipeline.metadataStream.dispatchType; // keep original time, can be adjusted if needed at a higher level

      event.cueTime = clock.videoTsToSeconds(event.pts);
      transmuxer.trigger('id3Frame', event);
    });
    pipeline.on('caption', function (event) {
      transmuxer.trigger('caption', event);
    });
  };

  var Transmuxer = function Transmuxer(options) {
    var pipeline = null,
        hasFlushed = true;
    options = options || {};
    Transmuxer.prototype.init.call(this);
    options.baseMediaDecodeTime = options.baseMediaDecodeTime || 0;

    this.push = function (bytes) {
      if (hasFlushed) {
        var isAac = isLikelyAacData(bytes);

        if (isAac && (!pipeline || pipeline.type !== 'aac')) {
          pipeline = aacPipeline(options);
          setupPipelineListeners(pipeline, this);
        } else if (!isAac && (!pipeline || pipeline.type !== 'ts')) {
          pipeline = tsPipeline(options);
          setupPipelineListeners(pipeline, this);
        }

        hasFlushed = false;
      }

      pipeline.headOfPipeline.push(bytes);
    };

    this.flush = function () {
      if (!pipeline) {
        return;
      }

      hasFlushed = true;
      pipeline.headOfPipeline.flush();
    };

    this.partialFlush = function () {
      if (!pipeline) {
        return;
      }

      pipeline.headOfPipeline.partialFlush();
    };

    this.endTimeline = function () {
      if (!pipeline) {
        return;
      }

      pipeline.headOfPipeline.endTimeline();
    };

    this.reset = function () {
      if (!pipeline) {
        return;
      }

      pipeline.headOfPipeline.reset();
    };

    this.setBaseMediaDecodeTime = function (baseMediaDecodeTime) {
      if (!options.keepOriginalTimestamps) {
        options.baseMediaDecodeTime = baseMediaDecodeTime;
      }

      if (!pipeline) {
        return;
      }

      if (pipeline.tracks.audio) {
        pipeline.tracks.audio.timelineStartInfo.dts = undefined;
        pipeline.tracks.audio.timelineStartInfo.pts = undefined;
        trackDecodeInfo.clearDtsInfo(pipeline.tracks.audio);

        if (pipeline.audioRollover) {
          pipeline.audioRollover.discontinuity();
        }
      }

      if (pipeline.tracks.video) {
        if (pipeline.videoSegmentStream) {
          pipeline.videoSegmentStream.gopCache_ = [];
        }

        pipeline.tracks.video.timelineStartInfo.dts = undefined;
        pipeline.tracks.video.timelineStartInfo.pts = undefined;
        trackDecodeInfo.clearDtsInfo(pipeline.tracks.video); // pipeline.captionStream.reset();
      }

      if (pipeline.timestampRollover) {
        pipeline.timestampRollover.discontinuity();
      }
    };

    this.setRemux = function (val) {
      options.remux = val;

      if (pipeline && pipeline.coalesceStream) {
        pipeline.coalesceStream.setRemux(val);
      }
    };

    this.setAudioAppendStart = function (audioAppendStart) {
      if (!pipeline || !pipeline.tracks.audio || !pipeline.audioSegmentStream) {
        return;
      }

      pipeline.audioSegmentStream.setAudioAppendStart(audioAppendStart);
    }; // TODO GOP alignment support
    // Support may be a bit trickier than with full segment appends, as GOPs may be split
    // and processed in a more granular fashion


    this.alignGopsWith = function (gopsToAlignWith) {
      return;
    };
  };

  Transmuxer.prototype = new stream();
  var transmuxer = Transmuxer;

  var partial = {
    Transmuxer: transmuxer
  };

  var getUint64$1 = numbers.getUint64;

  var parseSidx = function parseSidx(data) {
    var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
        result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      references: [],
      referenceId: view.getUint32(4),
      timescale: view.getUint32(8)
    },
        i = 12;

    if (result.version === 0) {
      result.earliestPresentationTime = view.getUint32(i);
      result.firstOffset = view.getUint32(i + 4);
      i += 8;
    } else {
      // read 64 bits
      result.earliestPresentationTime = getUint64$1(data.subarray(i));
      result.firstOffset = getUint64$1(data.subarray(i + 8));
      i += 16;
    }

    i += 2; // reserved

    var referenceCount = view.getUint16(i);
    i += 2; // start of references

    for (; referenceCount > 0; i += 12, referenceCount--) {
      result.references.push({
        referenceType: (data[i] & 0x80) >>> 7,
        referencedSize: view.getUint32(i) & 0x7FFFFFFF,
        subsegmentDuration: view.getUint32(i + 4),
        startsWithSap: !!(data[i + 8] & 0x80),
        sapType: (data[i + 8] & 0x70) >>> 4,
        sapDeltaTime: view.getUint32(i + 8) & 0x0FFFFFFF
      });
    }

    return result;
  };

  var parseSidx_1 = parseSidx;

  var getUint64 = numbers.getUint64;

  var inspectMp4,
      _textifyMp,
      parseMp4Date = function parseMp4Date(seconds) {
    return new Date(seconds * 1000 - 2082844800000);
  },
      nalParse = function nalParse(avcStream) {
    var avcView = new DataView(avcStream.buffer, avcStream.byteOffset, avcStream.byteLength),
        result = [],
        i,
        length;

    for (i = 0; i + 4 < avcStream.length; i += length) {
      length = avcView.getUint32(i);
      i += 4; // bail if this doesn't appear to be an H264 stream

      if (length <= 0) {
        result.push('<span style=\'color:red;\'>MALFORMED DATA</span>');
        continue;
      }

      switch (avcStream[i] & 0x1F) {
        case 0x01:
          result.push('slice_layer_without_partitioning_rbsp');
          break;

        case 0x05:
          result.push('slice_layer_without_partitioning_rbsp_idr');
          break;

        case 0x06:
          result.push('sei_rbsp');
          break;

        case 0x07:
          result.push('seq_parameter_set_rbsp');
          break;

        case 0x08:
          result.push('pic_parameter_set_rbsp');
          break;

        case 0x09:
          result.push('access_unit_delimiter_rbsp');
          break;

        default:
          result.push('UNKNOWN NAL - ' + avcStream[i] & 0x1F);
          break;
      }
    }

    return result;
  },
      // registry of handlers for individual mp4 box types
  parse = {
    // codingname, not a first-class box type. stsd entries share the
    // same format as real boxes so the parsing infrastructure can be
    // shared
    avc1: function avc1(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
      return {
        dataReferenceIndex: view.getUint16(6),
        width: view.getUint16(24),
        height: view.getUint16(26),
        horizresolution: view.getUint16(28) + view.getUint16(30) / 16,
        vertresolution: view.getUint16(32) + view.getUint16(34) / 16,
        frameCount: view.getUint16(40),
        depth: view.getUint16(74),
        config: inspectMp4(data.subarray(78, data.byteLength))
      };
    },
    avcC: function avcC(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        configurationVersion: data[0],
        avcProfileIndication: data[1],
        profileCompatibility: data[2],
        avcLevelIndication: data[3],
        lengthSizeMinusOne: data[4] & 0x03,
        sps: [],
        pps: []
      },
          numOfSequenceParameterSets = data[5] & 0x1f,
          numOfPictureParameterSets,
          nalSize,
          offset,
          i; // iterate past any SPSs

      offset = 6;

      for (i = 0; i < numOfSequenceParameterSets; i++) {
        nalSize = view.getUint16(offset);
        offset += 2;
        result.sps.push(new Uint8Array(data.subarray(offset, offset + nalSize)));
        offset += nalSize;
      } // iterate past any PPSs


      numOfPictureParameterSets = data[offset];
      offset++;

      for (i = 0; i < numOfPictureParameterSets; i++) {
        nalSize = view.getUint16(offset);
        offset += 2;
        result.pps.push(new Uint8Array(data.subarray(offset, offset + nalSize)));
        offset += nalSize;
      }

      return result;
    },
    btrt: function btrt(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
      return {
        bufferSizeDB: view.getUint32(0),
        maxBitrate: view.getUint32(4),
        avgBitrate: view.getUint32(8)
      };
    },
    edts: function edts(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    elst: function elst(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4)),
        edits: []
      },
          entryCount = view.getUint32(4),
          i;

      for (i = 8; entryCount; entryCount--) {
        if (result.version === 0) {
          result.edits.push({
            segmentDuration: view.getUint32(i),
            mediaTime: view.getInt32(i + 4),
            mediaRate: view.getUint16(i + 8) + view.getUint16(i + 10) / (256 * 256)
          });
          i += 12;
        } else {
          result.edits.push({
            segmentDuration: getUint64(data.subarray(i)),
            mediaTime: getUint64(data.subarray(i + 8)),
            mediaRate: view.getUint16(i + 16) + view.getUint16(i + 18) / (256 * 256)
          });
          i += 20;
        }
      }

      return result;
    },
    esds: function esds(data) {
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        esId: data[6] << 8 | data[7],
        streamPriority: data[8] & 0x1f,
        decoderConfig: {
          objectProfileIndication: data[11],
          streamType: data[12] >>> 2 & 0x3f,
          bufferSize: data[13] << 16 | data[14] << 8 | data[15],
          maxBitrate: data[16] << 24 | data[17] << 16 | data[18] << 8 | data[19],
          avgBitrate: data[20] << 24 | data[21] << 16 | data[22] << 8 | data[23],
          decoderConfigDescriptor: {
            tag: data[24],
            length: data[25],
            audioObjectType: data[26] >>> 3 & 0x1f,
            samplingFrequencyIndex: (data[26] & 0x07) << 1 | data[27] >>> 7 & 0x01,
            channelConfiguration: data[27] >>> 3 & 0x0f
          }
        }
      };
    },
    ftyp: function ftyp(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        majorBrand: parseType_1(data.subarray(0, 4)),
        minorVersion: view.getUint32(4),
        compatibleBrands: []
      },
          i = 8;

      while (i < data.byteLength) {
        result.compatibleBrands.push(parseType_1(data.subarray(i, i + 4)));
        i += 4;
      }

      return result;
    },
    dinf: function dinf(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    dref: function dref(data) {
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        dataReferences: inspectMp4(data.subarray(8))
      };
    },
    hdlr: function hdlr(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4)),
        handlerType: parseType_1(data.subarray(8, 12)),
        name: ''
      },
          i = 8; // parse out the name field

      for (i = 24; i < data.byteLength; i++) {
        if (data[i] === 0x00) {
          // the name field is null-terminated
          i++;
          break;
        }

        result.name += String.fromCharCode(data[i]);
      } // decode UTF-8 to javascript's internal representation
      // see http://ecmanaut.blogspot.com/2006/07/encoding-decoding-utf8-in-javascript.html


      result.name = decodeURIComponent(escape(result.name));
      return result;
    },
    mdat: function mdat(data) {
      return {
        byteLength: data.byteLength,
        nals: nalParse(data)
      };
    },
    mdhd: function mdhd(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          i = 4,
          language,
          result = {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4)),
        language: ''
      };

      if (result.version === 1) {
        i += 4;
        result.creationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

        i += 8;
        result.modificationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

        i += 4;
        result.timescale = view.getUint32(i);
        i += 8;
        result.duration = view.getUint32(i); // truncating top 4 bytes
      } else {
        result.creationTime = parseMp4Date(view.getUint32(i));
        i += 4;
        result.modificationTime = parseMp4Date(view.getUint32(i));
        i += 4;
        result.timescale = view.getUint32(i);
        i += 4;
        result.duration = view.getUint32(i);
      }

      i += 4; // language is stored as an ISO-639-2/T code in an array of three 5-bit fields
      // each field is the packed difference between its ASCII value and 0x60

      language = view.getUint16(i);
      result.language += String.fromCharCode((language >> 10) + 0x60);
      result.language += String.fromCharCode(((language & 0x03e0) >> 5) + 0x60);
      result.language += String.fromCharCode((language & 0x1f) + 0x60);
      return result;
    },
    mdia: function mdia(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    mfhd: function mfhd(data) {
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        sequenceNumber: data[4] << 24 | data[5] << 16 | data[6] << 8 | data[7]
      };
    },
    minf: function minf(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    // codingname, not a first-class box type. stsd entries share the
    // same format as real boxes so the parsing infrastructure can be
    // shared
    mp4a: function mp4a(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        // 6 bytes reserved
        dataReferenceIndex: view.getUint16(6),
        // 4 + 4 bytes reserved
        channelcount: view.getUint16(16),
        samplesize: view.getUint16(18),
        // 2 bytes pre_defined
        // 2 bytes reserved
        samplerate: view.getUint16(24) + view.getUint16(26) / 65536
      }; // if there are more bytes to process, assume this is an ISO/IEC
      // 14496-14 MP4AudioSampleEntry and parse the ESDBox

      if (data.byteLength > 28) {
        result.streamDescriptor = inspectMp4(data.subarray(28))[0];
      }

      return result;
    },
    moof: function moof(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    moov: function moov(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    mvex: function mvex(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    mvhd: function mvhd(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          i = 4,
          result = {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4))
      };

      if (result.version === 1) {
        i += 4;
        result.creationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

        i += 8;
        result.modificationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

        i += 4;
        result.timescale = view.getUint32(i);
        i += 8;
        result.duration = view.getUint32(i); // truncating top 4 bytes
      } else {
        result.creationTime = parseMp4Date(view.getUint32(i));
        i += 4;
        result.modificationTime = parseMp4Date(view.getUint32(i));
        i += 4;
        result.timescale = view.getUint32(i);
        i += 4;
        result.duration = view.getUint32(i);
      }

      i += 4; // convert fixed-point, base 16 back to a number

      result.rate = view.getUint16(i) + view.getUint16(i + 2) / 16;
      i += 4;
      result.volume = view.getUint8(i) + view.getUint8(i + 1) / 8;
      i += 2;
      i += 2;
      i += 2 * 4;
      result.matrix = new Uint32Array(data.subarray(i, i + 9 * 4));
      i += 9 * 4;
      i += 6 * 4;
      result.nextTrackId = view.getUint32(i);
      return result;
    },
    pdin: function pdin(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
      return {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4)),
        rate: view.getUint32(4),
        initialDelay: view.getUint32(8)
      };
    },
    sdtp: function sdtp(data) {
      var result = {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        samples: []
      },
          i;

      for (i = 4; i < data.byteLength; i++) {
        result.samples.push({
          dependsOn: (data[i] & 0x30) >> 4,
          isDependedOn: (data[i] & 0x0c) >> 2,
          hasRedundancy: data[i] & 0x03
        });
      }

      return result;
    },
    sidx: parseSidx_1,
    smhd: function smhd(data) {
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        balance: data[4] + data[5] / 256
      };
    },
    stbl: function stbl(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    ctts: function ctts(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4)),
        compositionOffsets: []
      },
          entryCount = view.getUint32(4),
          i;

      for (i = 8; entryCount; i += 8, entryCount--) {
        result.compositionOffsets.push({
          sampleCount: view.getUint32(i),
          sampleOffset: view[result.version === 0 ? 'getUint32' : 'getInt32'](i + 4)
        });
      }

      return result;
    },
    stss: function stss(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4)),
        syncSamples: []
      },
          entryCount = view.getUint32(4),
          i;

      for (i = 8; entryCount; i += 4, entryCount--) {
        result.syncSamples.push(view.getUint32(i));
      }

      return result;
    },
    stco: function stco(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        chunkOffsets: []
      },
          entryCount = view.getUint32(4),
          i;

      for (i = 8; entryCount; i += 4, entryCount--) {
        result.chunkOffsets.push(view.getUint32(i));
      }

      return result;
    },
    stsc: function stsc(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          entryCount = view.getUint32(4),
          result = {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        sampleToChunks: []
      },
          i;

      for (i = 8; entryCount; i += 12, entryCount--) {
        result.sampleToChunks.push({
          firstChunk: view.getUint32(i),
          samplesPerChunk: view.getUint32(i + 4),
          sampleDescriptionIndex: view.getUint32(i + 8)
        });
      }

      return result;
    },
    stsd: function stsd(data) {
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        sampleDescriptions: inspectMp4(data.subarray(8))
      };
    },
    stsz: function stsz(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        sampleSize: view.getUint32(4),
        entries: []
      },
          i;

      for (i = 12; i < data.byteLength; i += 4) {
        result.entries.push(view.getUint32(i));
      }

      return result;
    },
    stts: function stts(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          result = {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        timeToSamples: []
      },
          entryCount = view.getUint32(4),
          i;

      for (i = 8; entryCount; i += 8, entryCount--) {
        result.timeToSamples.push({
          sampleCount: view.getUint32(i),
          sampleDelta: view.getUint32(i + 4)
        });
      }

      return result;
    },
    styp: function styp(data) {
      return parse.ftyp(data);
    },
    tfdt: parseTfdt,
    tfhd: parseTfhd,
    tkhd: function tkhd(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
          i = 4,
          result = {
        version: view.getUint8(0),
        flags: new Uint8Array(data.subarray(1, 4))
      };

      if (result.version === 1) {
        i += 4;
        result.creationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

        i += 8;
        result.modificationTime = parseMp4Date(view.getUint32(i)); // truncating top 4 bytes

        i += 4;
        result.trackId = view.getUint32(i);
        i += 4;
        i += 8;
        result.duration = view.getUint32(i); // truncating top 4 bytes
      } else {
        result.creationTime = parseMp4Date(view.getUint32(i));
        i += 4;
        result.modificationTime = parseMp4Date(view.getUint32(i));
        i += 4;
        result.trackId = view.getUint32(i);
        i += 4;
        i += 4;
        result.duration = view.getUint32(i);
      }

      i += 4;
      i += 2 * 4;
      result.layer = view.getUint16(i);
      i += 2;
      result.alternateGroup = view.getUint16(i);
      i += 2; // convert fixed-point, base 16 back to a number

      result.volume = view.getUint8(i) + view.getUint8(i + 1) / 8;
      i += 2;
      i += 2;
      result.matrix = new Uint32Array(data.subarray(i, i + 9 * 4));
      i += 9 * 4;
      result.width = view.getUint16(i) + view.getUint16(i + 2) / 65536;
      i += 4;
      result.height = view.getUint16(i) + view.getUint16(i + 2) / 65536;
      return result;
    },
    traf: function traf(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    trak: function trak(data) {
      return {
        boxes: inspectMp4(data)
      };
    },
    trex: function trex(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        trackId: view.getUint32(4),
        defaultSampleDescriptionIndex: view.getUint32(8),
        defaultSampleDuration: view.getUint32(12),
        defaultSampleSize: view.getUint32(16),
        sampleDependsOn: data[20] & 0x03,
        sampleIsDependedOn: (data[21] & 0xc0) >> 6,
        sampleHasRedundancy: (data[21] & 0x30) >> 4,
        samplePaddingValue: (data[21] & 0x0e) >> 1,
        sampleIsDifferenceSample: !!(data[21] & 0x01),
        sampleDegradationPriority: view.getUint16(22)
      };
    },
    trun: parseTrun,
    'url ': function url(data) {
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4))
      };
    },
    vmhd: function vmhd(data) {
      var view = new DataView(data.buffer, data.byteOffset, data.byteLength);
      return {
        version: data[0],
        flags: new Uint8Array(data.subarray(1, 4)),
        graphicsmode: view.getUint16(4),
        opcolor: new Uint16Array([view.getUint16(6), view.getUint16(8), view.getUint16(10)])
      };
    }
  };
  /**
   * Return a javascript array of box objects parsed from an ISO base
   * media file.
   * @param data {Uint8Array} the binary data of the media to be inspected
   * @return {array} a javascript array of potentially nested box objects
   */


  inspectMp4 = function inspectMp4(data) {
    var i = 0,
        result = [],
        view,
        size,
        type,
        end,
        box; // Convert data from Uint8Array to ArrayBuffer, to follow Dataview API

    var ab = new ArrayBuffer(data.length);
    var v = new Uint8Array(ab);

    for (var z = 0; z < data.length; ++z) {
      v[z] = data[z];
    }

    view = new DataView(ab);

    while (i < data.byteLength) {
      // parse box data
      size = view.getUint32(i);
      type = parseType_1(data.subarray(i + 4, i + 8));
      end = size > 1 ? i + size : data.byteLength; // parse type-specific data

      box = (parse[type] || function (data) {
        return {
          data: data
        };
      })(data.subarray(i + 8, end));

      box.size = size;
      box.type = type; // store this box and move to the next

      result.push(box);
      i = end;
    }

    return result;
  };
  /**
   * Returns a textual representation of the javascript represtentation
   * of an MP4 file. You can use it as an alternative to
   * JSON.stringify() to compare inspected MP4s.
   * @param inspectedMp4 {array} the parsed array of boxes in an MP4
   * file
   * @param depth {number} (optional) the number of ancestor boxes of
   * the elements of inspectedMp4. Assumed to be zero if unspecified.
   * @return {string} a text representation of the parsed MP4
   */


  _textifyMp = function textifyMp4(inspectedMp4, depth) {
    var indent;
    depth = depth || 0;
    indent = new Array(depth * 2 + 1).join(' '); // iterate over all the boxes

    return inspectedMp4.map(function (box, index) {
      // list the box type first at the current indentation level
      return indent + box.type + '\n' + // the type is already included and handle child boxes separately
      Object.keys(box).filter(function (key) {
        return key !== 'type' && key !== 'boxes'; // output all the box properties
      }).map(function (key) {
        var prefix = indent + '  ' + key + ': ',
            value = box[key]; // print out raw bytes as hexademical

        if (value instanceof Uint8Array || value instanceof Uint32Array) {
          var bytes = Array.prototype.slice.call(new Uint8Array(value.buffer, value.byteOffset, value.byteLength)).map(function (byte) {
            return ' ' + ('00' + byte.toString(16)).slice(-2);
          }).join('').match(/.{1,24}/g);

          if (!bytes) {
            return prefix + '<>';
          }

          if (bytes.length === 1) {
            return prefix + '<' + bytes.join('').slice(1) + '>';
          }

          return prefix + '<\n' + bytes.map(function (line) {
            return indent + '  ' + line;
          }).join('\n') + '\n' + indent + '  >';
        } // stringify generic objects


        return prefix + JSON.stringify(value, null, 2).split('\n').map(function (line, index) {
          if (index === 0) {
            return line;
          }

          return indent + '  ' + line;
        }).join('\n');
      }).join('\n') + ( // recursively textify the child boxes
      box.boxes ? '\n' + _textifyMp(box.boxes, depth + 1) : '');
    }).join('\n');
  };

  var mp4Inspector = {
    inspect: inspectMp4,
    textify: _textifyMp,
    parseType: parseType_1,
    findBox: findBox_1,
    parseTraf: parse.traf,
    parseTfdt: parse.tfdt,
    parseHdlr: parse.hdlr,
    parseTfhd: parse.tfhd,
    parseTrun: parse.trun,
    parseSidx: parse.sidx
  };

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */

  var tagTypes = {
    0x08: 'audio',
    0x09: 'video',
    0x12: 'metadata'
  },
      hex = function hex(val) {
    return '0x' + ('00' + val.toString(16)).slice(-2).toUpperCase();
  },
      hexStringList = function hexStringList(data) {
    var arr = [],
        i;

    while (data.byteLength > 0) {
      i = 0;
      arr.push(hex(data[i++]));
      data = data.subarray(i);
    }

    return arr.join(' ');
  },
      parseAVCTag = function parseAVCTag(tag, obj) {
    var avcPacketTypes = ['AVC Sequence Header', 'AVC NALU', 'AVC End-of-Sequence'],
        compositionTime = tag[1] & parseInt('01111111', 2) << 16 | tag[2] << 8 | tag[3];
    obj = obj || {};
    obj.avcPacketType = avcPacketTypes[tag[0]];
    obj.CompositionTime = tag[1] & parseInt('10000000', 2) ? -compositionTime : compositionTime;

    if (tag[0] === 1) {
      obj.nalUnitTypeRaw = hexStringList(tag.subarray(4, 100));
    } else {
      obj.data = hexStringList(tag.subarray(4));
    }

    return obj;
  },
      parseVideoTag = function parseVideoTag(tag, obj) {
    var frameTypes = ['Unknown', 'Keyframe (for AVC, a seekable frame)', 'Inter frame (for AVC, a nonseekable frame)', 'Disposable inter frame (H.263 only)', 'Generated keyframe (reserved for server use only)', 'Video info/command frame'],
        codecID = tag[0] & parseInt('00001111', 2);
    obj = obj || {};
    obj.frameType = frameTypes[(tag[0] & parseInt('11110000', 2)) >>> 4];
    obj.codecID = codecID;

    if (codecID === 7) {
      return parseAVCTag(tag.subarray(1), obj);
    }

    return obj;
  },
      parseAACTag = function parseAACTag(tag, obj) {
    var packetTypes = ['AAC Sequence Header', 'AAC Raw'];
    obj = obj || {};
    obj.aacPacketType = packetTypes[tag[0]];
    obj.data = hexStringList(tag.subarray(1));
    return obj;
  },
      parseAudioTag = function parseAudioTag(tag, obj) {
    var formatTable = ['Linear PCM, platform endian', 'ADPCM', 'MP3', 'Linear PCM, little endian', 'Nellymoser 16-kHz mono', 'Nellymoser 8-kHz mono', 'Nellymoser', 'G.711 A-law logarithmic PCM', 'G.711 mu-law logarithmic PCM', 'reserved', 'AAC', 'Speex', 'MP3 8-Khz', 'Device-specific sound'],
        samplingRateTable = ['5.5-kHz', '11-kHz', '22-kHz', '44-kHz'],
        soundFormat = (tag[0] & parseInt('11110000', 2)) >>> 4;
    obj = obj || {};
    obj.soundFormat = formatTable[soundFormat];
    obj.soundRate = samplingRateTable[(tag[0] & parseInt('00001100', 2)) >>> 2];
    obj.soundSize = (tag[0] & parseInt('00000010', 2)) >>> 1 ? '16-bit' : '8-bit';
    obj.soundType = tag[0] & parseInt('00000001', 2) ? 'Stereo' : 'Mono';

    if (soundFormat === 10) {
      return parseAACTag(tag.subarray(1), obj);
    }

    return obj;
  },
      parseGenericTag = function parseGenericTag(tag) {
    return {
      tagType: tagTypes[tag[0]],
      dataSize: tag[1] << 16 | tag[2] << 8 | tag[3],
      timestamp: tag[7] << 24 | tag[4] << 16 | tag[5] << 8 | tag[6],
      streamID: tag[8] << 16 | tag[9] << 8 | tag[10]
    };
  },
      inspectFlvTag = function inspectFlvTag(tag) {
    var header = parseGenericTag(tag);

    switch (tag[0]) {
      case 0x08:
        parseAudioTag(tag.subarray(11), header);
        break;

      case 0x09:
        parseVideoTag(tag.subarray(11), header);
        break;
    }

    return header;
  },
      inspectFlv = function inspectFlv(bytes) {
    var i = 9,
        // header
    dataSize,
        parsedResults = [],
        tag; // traverse the tags

    i += 4; // skip previous tag size

    while (i < bytes.byteLength) {
      dataSize = bytes[i + 1] << 16;
      dataSize |= bytes[i + 2] << 8;
      dataSize |= bytes[i + 3];
      dataSize += 11;
      tag = bytes.subarray(i, i + dataSize);
      parsedResults.push(inspectFlvTag(tag));
      i += dataSize + 4;
    }

    return parsedResults;
  },
      textifyFlv = function textifyFlv(flvTagArray) {
    return JSON.stringify(flvTagArray, null, 2);
  };

  var flvInspector = {
    inspectTag: inspectFlvTag,
    inspect: inspectFlv,
    textify: textifyFlv
  };

  var parsePid = function parsePid(packet) {
    var pid = packet[1] & 0x1f;
    pid <<= 8;
    pid |= packet[2];
    return pid;
  };

  var parsePayloadUnitStartIndicator = function parsePayloadUnitStartIndicator(packet) {
    return !!(packet[1] & 0x40);
  };

  var parseAdaptionField = function parseAdaptionField(packet) {
    var offset = 0; // if an adaption field is present, its length is specified by the
    // fifth byte of the TS packet header. The adaptation field is
    // used to add stuffing to PES packets that don't fill a complete
    // TS packet, and to specify some forms of timing and control data
    // that we do not currently use.

    if ((packet[3] & 0x30) >>> 4 > 0x01) {
      offset += packet[4] + 1;
    }

    return offset;
  };

  var parseType = function parseType(packet, pmtPid) {
    var pid = parsePid(packet);

    if (pid === 0) {
      return 'pat';
    } else if (pid === pmtPid) {
      return 'pmt';
    } else if (pmtPid) {
      return 'pes';
    }

    return null;
  };

  var parsePat = function parsePat(packet) {
    var pusi = parsePayloadUnitStartIndicator(packet);
    var offset = 4 + parseAdaptionField(packet);

    if (pusi) {
      offset += packet[offset] + 1;
    }

    return (packet[offset + 10] & 0x1f) << 8 | packet[offset + 11];
  };

  var parsePmt = function parsePmt(packet) {
    var programMapTable = {};
    var pusi = parsePayloadUnitStartIndicator(packet);
    var payloadOffset = 4 + parseAdaptionField(packet);

    if (pusi) {
      payloadOffset += packet[payloadOffset] + 1;
    } // PMTs can be sent ahead of the time when they should actually
    // take effect. We don't believe this should ever be the case
    // for HLS but we'll ignore "forward" PMT declarations if we see
    // them. Future PMT declarations have the current_next_indicator
    // set to zero.


    if (!(packet[payloadOffset + 5] & 0x01)) {
      return;
    }

    var sectionLength, tableEnd, programInfoLength; // the mapping table ends at the end of the current section

    sectionLength = (packet[payloadOffset + 1] & 0x0f) << 8 | packet[payloadOffset + 2];
    tableEnd = 3 + sectionLength - 4; // to determine where the table is, we have to figure out how
    // long the program info descriptors are

    programInfoLength = (packet[payloadOffset + 10] & 0x0f) << 8 | packet[payloadOffset + 11]; // advance the offset to the first entry in the mapping table

    var offset = 12 + programInfoLength;

    while (offset < tableEnd) {
      var i = payloadOffset + offset; // add an entry that maps the elementary_pid to the stream_type

      programMapTable[(packet[i + 1] & 0x1F) << 8 | packet[i + 2]] = packet[i]; // move to the next table entry
      // skip past the elementary stream descriptors, if present

      offset += ((packet[i + 3] & 0x0F) << 8 | packet[i + 4]) + 5;
    }

    return programMapTable;
  };

  var parsePesType = function parsePesType(packet, programMapTable) {
    var pid = parsePid(packet);
    var type = programMapTable[pid];

    switch (type) {
      case streamTypes.H264_STREAM_TYPE:
        return 'video';

      case streamTypes.ADTS_STREAM_TYPE:
        return 'audio';

      case streamTypes.METADATA_STREAM_TYPE:
        return 'timed-metadata';

      default:
        return null;
    }
  };

  var parsePesTime = function parsePesTime(packet) {
    var pusi = parsePayloadUnitStartIndicator(packet);

    if (!pusi) {
      return null;
    }

    var offset = 4 + parseAdaptionField(packet);

    if (offset >= packet.byteLength) {
      // From the H 222.0 MPEG-TS spec
      // "For transport stream packets carrying PES packets, stuffing is needed when there
      //  is insufficient PES packet data to completely fill the transport stream packet
      //  payload bytes. Stuffing is accomplished by defining an adaptation field longer than
      //  the sum of the lengths of the data elements in it, so that the payload bytes
      //  remaining after the adaptation field exactly accommodates the available PES packet
      //  data."
      //
      // If the offset is >= the length of the packet, then the packet contains no data
      // and instead is just adaption field stuffing bytes
      return null;
    }

    var pes = null;
    var ptsDtsFlags; // PES packets may be annotated with a PTS value, or a PTS value
    // and a DTS value. Determine what combination of values is
    // available to work with.

    ptsDtsFlags = packet[offset + 7]; // PTS and DTS are normally stored as a 33-bit number.  Javascript
    // performs all bitwise operations on 32-bit integers but javascript
    // supports a much greater range (52-bits) of integer using standard
    // mathematical operations.
    // We construct a 31-bit value using bitwise operators over the 31
    // most significant bits and then multiply by 4 (equal to a left-shift
    // of 2) before we add the final 2 least significant bits of the
    // timestamp (equal to an OR.)

    if (ptsDtsFlags & 0xC0) {
      pes = {}; // the PTS and DTS are not written out directly. For information
      // on how they are encoded, see
      // http://dvd.sourceforge.net/dvdinfo/pes-hdr.html

      pes.pts = (packet[offset + 9] & 0x0E) << 27 | (packet[offset + 10] & 0xFF) << 20 | (packet[offset + 11] & 0xFE) << 12 | (packet[offset + 12] & 0xFF) << 5 | (packet[offset + 13] & 0xFE) >>> 3;
      pes.pts *= 4; // Left shift by 2

      pes.pts += (packet[offset + 13] & 0x06) >>> 1; // OR by the two LSBs

      pes.dts = pes.pts;

      if (ptsDtsFlags & 0x40) {
        pes.dts = (packet[offset + 14] & 0x0E) << 27 | (packet[offset + 15] & 0xFF) << 20 | (packet[offset + 16] & 0xFE) << 12 | (packet[offset + 17] & 0xFF) << 5 | (packet[offset + 18] & 0xFE) >>> 3;
        pes.dts *= 4; // Left shift by 2

        pes.dts += (packet[offset + 18] & 0x06) >>> 1; // OR by the two LSBs
      }
    }

    return pes;
  };

  var parseNalUnitType = function parseNalUnitType(type) {
    switch (type) {
      case 0x05:
        return 'slice_layer_without_partitioning_rbsp_idr';

      case 0x06:
        return 'sei_rbsp';

      case 0x07:
        return 'seq_parameter_set_rbsp';

      case 0x08:
        return 'pic_parameter_set_rbsp';

      case 0x09:
        return 'access_unit_delimiter_rbsp';

      default:
        return null;
    }
  };

  var videoPacketContainsKeyFrame = function videoPacketContainsKeyFrame(packet) {
    var offset = 4 + parseAdaptionField(packet);
    var frameBuffer = packet.subarray(offset);
    var frameI = 0;
    var frameSyncPoint = 0;
    var foundKeyFrame = false;
    var nalType; // advance the sync point to a NAL start, if necessary

    for (; frameSyncPoint < frameBuffer.byteLength - 3; frameSyncPoint++) {
      if (frameBuffer[frameSyncPoint + 2] === 1) {
        // the sync point is properly aligned
        frameI = frameSyncPoint + 5;
        break;
      }
    }

    while (frameI < frameBuffer.byteLength) {
      // look at the current byte to determine if we've hit the end of
      // a NAL unit boundary
      switch (frameBuffer[frameI]) {
        case 0:
          // skip past non-sync sequences
          if (frameBuffer[frameI - 1] !== 0) {
            frameI += 2;
            break;
          } else if (frameBuffer[frameI - 2] !== 0) {
            frameI++;
            break;
          }

          if (frameSyncPoint + 3 !== frameI - 2) {
            nalType = parseNalUnitType(frameBuffer[frameSyncPoint + 3] & 0x1f);

            if (nalType === 'slice_layer_without_partitioning_rbsp_idr') {
              foundKeyFrame = true;
            }
          } // drop trailing zeroes


          do {
            frameI++;
          } while (frameBuffer[frameI] !== 1 && frameI < frameBuffer.length);

          frameSyncPoint = frameI - 2;
          frameI += 3;
          break;

        case 1:
          // skip past non-sync sequences
          if (frameBuffer[frameI - 1] !== 0 || frameBuffer[frameI - 2] !== 0) {
            frameI += 3;
            break;
          }

          nalType = parseNalUnitType(frameBuffer[frameSyncPoint + 3] & 0x1f);

          if (nalType === 'slice_layer_without_partitioning_rbsp_idr') {
            foundKeyFrame = true;
          }

          frameSyncPoint = frameI - 2;
          frameI += 3;
          break;

        default:
          // the current byte isn't a one or zero, so it cannot be part
          // of a sync sequence
          frameI += 3;
          break;
      }
    }

    frameBuffer = frameBuffer.subarray(frameSyncPoint);
    frameI -= frameSyncPoint;
    frameSyncPoint = 0; // parse the final nal

    if (frameBuffer && frameBuffer.byteLength > 3) {
      nalType = parseNalUnitType(frameBuffer[frameSyncPoint + 3] & 0x1f);

      if (nalType === 'slice_layer_without_partitioning_rbsp_idr') {
        foundKeyFrame = true;
      }
    }

    return foundKeyFrame;
  };

  var probe$1 = {
    parseType: parseType,
    parsePat: parsePat,
    parsePmt: parsePmt,
    parsePayloadUnitStartIndicator: parsePayloadUnitStartIndicator,
    parsePesType: parsePesType,
    parsePesTime: parsePesTime,
    videoPacketContainsKeyFrame: videoPacketContainsKeyFrame
  };

  var handleRollover = timestampRolloverStream.handleRollover;
  var probe = {};
  probe.ts = probe$1;
  probe.aac = utils;
  var ONE_SECOND_IN_TS = clock.ONE_SECOND_IN_TS;
  var MP2T_PACKET_LENGTH = 188,
      // bytes
  SYNC_BYTE = 0x47;
  /**
   * walks through segment data looking for pat and pmt packets to parse out
   * program map table information
   */

  var parsePsi_ = function parsePsi_(bytes, pmt) {
    var startIndex = 0,
        endIndex = MP2T_PACKET_LENGTH,
        packet,
        type;

    while (endIndex < bytes.byteLength) {
      // Look for a pair of start and end sync bytes in the data..
      if (bytes[startIndex] === SYNC_BYTE && bytes[endIndex] === SYNC_BYTE) {
        // We found a packet
        packet = bytes.subarray(startIndex, endIndex);
        type = probe.ts.parseType(packet, pmt.pid);

        switch (type) {
          case 'pat':
            pmt.pid = probe.ts.parsePat(packet);
            break;

          case 'pmt':
            var table = probe.ts.parsePmt(packet);
            pmt.table = pmt.table || {};
            Object.keys(table).forEach(function (key) {
              pmt.table[key] = table[key];
            });
            break;
        }

        startIndex += MP2T_PACKET_LENGTH;
        endIndex += MP2T_PACKET_LENGTH;
        continue;
      } // If we get here, we have somehow become de-synchronized and we need to step
      // forward one byte at a time until we find a pair of sync bytes that denote
      // a packet


      startIndex++;
      endIndex++;
    }
  };
  /**
   * walks through the segment data from the start and end to get timing information
   * for the first and last audio pes packets
   */


  var parseAudioPes_ = function parseAudioPes_(bytes, pmt, result) {
    var startIndex = 0,
        endIndex = MP2T_PACKET_LENGTH,
        packet,
        type,
        pesType,
        pusi,
        parsed;
    var endLoop = false; // Start walking from start of segment to get first audio packet

    while (endIndex <= bytes.byteLength) {
      // Look for a pair of start and end sync bytes in the data..
      if (bytes[startIndex] === SYNC_BYTE && (bytes[endIndex] === SYNC_BYTE || endIndex === bytes.byteLength)) {
        // We found a packet
        packet = bytes.subarray(startIndex, endIndex);
        type = probe.ts.parseType(packet, pmt.pid);

        switch (type) {
          case 'pes':
            pesType = probe.ts.parsePesType(packet, pmt.table);
            pusi = probe.ts.parsePayloadUnitStartIndicator(packet);

            if (pesType === 'audio' && pusi) {
              parsed = probe.ts.parsePesTime(packet);

              if (parsed) {
                parsed.type = 'audio';
                result.audio.push(parsed);
                endLoop = true;
              }
            }

            break;
        }

        if (endLoop) {
          break;
        }

        startIndex += MP2T_PACKET_LENGTH;
        endIndex += MP2T_PACKET_LENGTH;
        continue;
      } // If we get here, we have somehow become de-synchronized and we need to step
      // forward one byte at a time until we find a pair of sync bytes that denote
      // a packet


      startIndex++;
      endIndex++;
    } // Start walking from end of segment to get last audio packet


    endIndex = bytes.byteLength;
    startIndex = endIndex - MP2T_PACKET_LENGTH;
    endLoop = false;

    while (startIndex >= 0) {
      // Look for a pair of start and end sync bytes in the data..
      if (bytes[startIndex] === SYNC_BYTE && (bytes[endIndex] === SYNC_BYTE || endIndex === bytes.byteLength)) {
        // We found a packet
        packet = bytes.subarray(startIndex, endIndex);
        type = probe.ts.parseType(packet, pmt.pid);

        switch (type) {
          case 'pes':
            pesType = probe.ts.parsePesType(packet, pmt.table);
            pusi = probe.ts.parsePayloadUnitStartIndicator(packet);

            if (pesType === 'audio' && pusi) {
              parsed = probe.ts.parsePesTime(packet);

              if (parsed) {
                parsed.type = 'audio';
                result.audio.push(parsed);
                endLoop = true;
              }
            }

            break;
        }

        if (endLoop) {
          break;
        }

        startIndex -= MP2T_PACKET_LENGTH;
        endIndex -= MP2T_PACKET_LENGTH;
        continue;
      } // If we get here, we have somehow become de-synchronized and we need to step
      // forward one byte at a time until we find a pair of sync bytes that denote
      // a packet


      startIndex--;
      endIndex--;
    }
  };
  /**
   * walks through the segment data from the start and end to get timing information
   * for the first and last video pes packets as well as timing information for the first
   * key frame.
   */


  var parseVideoPes_ = function parseVideoPes_(bytes, pmt, result) {
    var startIndex = 0,
        endIndex = MP2T_PACKET_LENGTH,
        packet,
        type,
        pesType,
        pusi,
        parsed,
        frame,
        i,
        pes;
    var endLoop = false;
    var currentFrame = {
      data: [],
      size: 0
    }; // Start walking from start of segment to get first video packet

    while (endIndex < bytes.byteLength) {
      // Look for a pair of start and end sync bytes in the data..
      if (bytes[startIndex] === SYNC_BYTE && bytes[endIndex] === SYNC_BYTE) {
        // We found a packet
        packet = bytes.subarray(startIndex, endIndex);
        type = probe.ts.parseType(packet, pmt.pid);

        switch (type) {
          case 'pes':
            pesType = probe.ts.parsePesType(packet, pmt.table);
            pusi = probe.ts.parsePayloadUnitStartIndicator(packet);

            if (pesType === 'video') {
              if (pusi && !endLoop) {
                parsed = probe.ts.parsePesTime(packet);

                if (parsed) {
                  parsed.type = 'video';
                  result.video.push(parsed);
                  endLoop = true;
                }
              }

              if (!result.firstKeyFrame) {
                if (pusi) {
                  if (currentFrame.size !== 0) {
                    frame = new Uint8Array(currentFrame.size);
                    i = 0;

                    while (currentFrame.data.length) {
                      pes = currentFrame.data.shift();
                      frame.set(pes, i);
                      i += pes.byteLength;
                    }

                    if (probe.ts.videoPacketContainsKeyFrame(frame)) {
                      var firstKeyFrame = probe.ts.parsePesTime(frame); // PTS/DTS may not be available. Simply *not* setting
                      // the keyframe seems to work fine with HLS playback
                      // and definitely preferable to a crash with TypeError...

                      if (firstKeyFrame) {
                        result.firstKeyFrame = firstKeyFrame;
                        result.firstKeyFrame.type = 'video';
                      } else {
                        // eslint-disable-next-line
                        console.warn('Failed to extract PTS/DTS from PES at first keyframe. ' + 'This could be an unusual TS segment, or else mux.js did not ' + 'parse your TS segment correctly. If you know your TS ' + 'segments do contain PTS/DTS on keyframes please file a bug ' + 'report! You can try ffprobe to double check for yourself.');
                      }
                    }

                    currentFrame.size = 0;
                  }
                }

                currentFrame.data.push(packet);
                currentFrame.size += packet.byteLength;
              }
            }

            break;
        }

        if (endLoop && result.firstKeyFrame) {
          break;
        }

        startIndex += MP2T_PACKET_LENGTH;
        endIndex += MP2T_PACKET_LENGTH;
        continue;
      } // If we get here, we have somehow become de-synchronized and we need to step
      // forward one byte at a time until we find a pair of sync bytes that denote
      // a packet


      startIndex++;
      endIndex++;
    } // Start walking from end of segment to get last video packet


    endIndex = bytes.byteLength;
    startIndex = endIndex - MP2T_PACKET_LENGTH;
    endLoop = false;

    while (startIndex >= 0) {
      // Look for a pair of start and end sync bytes in the data..
      if (bytes[startIndex] === SYNC_BYTE && bytes[endIndex] === SYNC_BYTE) {
        // We found a packet
        packet = bytes.subarray(startIndex, endIndex);
        type = probe.ts.parseType(packet, pmt.pid);

        switch (type) {
          case 'pes':
            pesType = probe.ts.parsePesType(packet, pmt.table);
            pusi = probe.ts.parsePayloadUnitStartIndicator(packet);

            if (pesType === 'video' && pusi) {
              parsed = probe.ts.parsePesTime(packet);

              if (parsed) {
                parsed.type = 'video';
                result.video.push(parsed);
                endLoop = true;
              }
            }

            break;
        }

        if (endLoop) {
          break;
        }

        startIndex -= MP2T_PACKET_LENGTH;
        endIndex -= MP2T_PACKET_LENGTH;
        continue;
      } // If we get here, we have somehow become de-synchronized and we need to step
      // forward one byte at a time until we find a pair of sync bytes that denote
      // a packet


      startIndex--;
      endIndex--;
    }
  };
  /**
   * Adjusts the timestamp information for the segment to account for
   * rollover and convert to seconds based on pes packet timescale (90khz clock)
   */


  var adjustTimestamp_ = function adjustTimestamp_(segmentInfo, baseTimestamp) {
    if (segmentInfo.audio && segmentInfo.audio.length) {
      var audioBaseTimestamp = baseTimestamp;

      if (typeof audioBaseTimestamp === 'undefined' || isNaN(audioBaseTimestamp)) {
        audioBaseTimestamp = segmentInfo.audio[0].dts;
      }

      segmentInfo.audio.forEach(function (info) {
        info.dts = handleRollover(info.dts, audioBaseTimestamp);
        info.pts = handleRollover(info.pts, audioBaseTimestamp); // time in seconds

        info.dtsTime = info.dts / ONE_SECOND_IN_TS;
        info.ptsTime = info.pts / ONE_SECOND_IN_TS;
      });
    }

    if (segmentInfo.video && segmentInfo.video.length) {
      var videoBaseTimestamp = baseTimestamp;

      if (typeof videoBaseTimestamp === 'undefined' || isNaN(videoBaseTimestamp)) {
        videoBaseTimestamp = segmentInfo.video[0].dts;
      }

      segmentInfo.video.forEach(function (info) {
        info.dts = handleRollover(info.dts, videoBaseTimestamp);
        info.pts = handleRollover(info.pts, videoBaseTimestamp); // time in seconds

        info.dtsTime = info.dts / ONE_SECOND_IN_TS;
        info.ptsTime = info.pts / ONE_SECOND_IN_TS;
      });

      if (segmentInfo.firstKeyFrame) {
        var frame = segmentInfo.firstKeyFrame;
        frame.dts = handleRollover(frame.dts, videoBaseTimestamp);
        frame.pts = handleRollover(frame.pts, videoBaseTimestamp); // time in seconds

        frame.dtsTime = frame.dts / ONE_SECOND_IN_TS;
        frame.ptsTime = frame.pts / ONE_SECOND_IN_TS;
      }
    }
  };
  /**
   * inspects the aac data stream for start and end time information
   */


  var inspectAac_ = function inspectAac_(bytes) {
    var endLoop = false,
        audioCount = 0,
        sampleRate = null,
        timestamp = null,
        frameSize = 0,
        byteIndex = 0,
        packet;

    while (bytes.length - byteIndex >= 3) {
      var type = probe.aac.parseType(bytes, byteIndex);

      switch (type) {
        case 'timed-metadata':
          // Exit early because we don't have enough to parse
          // the ID3 tag header
          if (bytes.length - byteIndex < 10) {
            endLoop = true;
            break;
          }

          frameSize = probe.aac.parseId3TagSize(bytes, byteIndex); // Exit early if we don't have enough in the buffer
          // to emit a full packet

          if (frameSize > bytes.length) {
            endLoop = true;
            break;
          }

          if (timestamp === null) {
            packet = bytes.subarray(byteIndex, byteIndex + frameSize);
            timestamp = probe.aac.parseAacTimestamp(packet);
          }

          byteIndex += frameSize;
          break;

        case 'audio':
          // Exit early because we don't have enough to parse
          // the ADTS frame header
          if (bytes.length - byteIndex < 7) {
            endLoop = true;
            break;
          }

          frameSize = probe.aac.parseAdtsSize(bytes, byteIndex); // Exit early if we don't have enough in the buffer
          // to emit a full packet

          if (frameSize > bytes.length) {
            endLoop = true;
            break;
          }

          if (sampleRate === null) {
            packet = bytes.subarray(byteIndex, byteIndex + frameSize);
            sampleRate = probe.aac.parseSampleRate(packet);
          }

          audioCount++;
          byteIndex += frameSize;
          break;

        default:
          byteIndex++;
          break;
      }

      if (endLoop) {
        return null;
      }
    }

    if (sampleRate === null || timestamp === null) {
      return null;
    }

    var audioTimescale = ONE_SECOND_IN_TS / sampleRate;
    var result = {
      audio: [{
        type: 'audio',
        dts: timestamp,
        pts: timestamp
      }, {
        type: 'audio',
        dts: timestamp + audioCount * 1024 * audioTimescale,
        pts: timestamp + audioCount * 1024 * audioTimescale
      }]
    };
    return result;
  };
  /**
   * inspects the transport stream segment data for start and end time information
   * of the audio and video tracks (when present) as well as the first key frame's
   * start time.
   */


  var inspectTs_ = function inspectTs_(bytes) {
    var pmt = {
      pid: null,
      table: null
    };
    var result = {};
    parsePsi_(bytes, pmt);

    for (var pid in pmt.table) {
      if (pmt.table.hasOwnProperty(pid)) {
        var type = pmt.table[pid];

        switch (type) {
          case streamTypes.H264_STREAM_TYPE:
            result.video = [];
            parseVideoPes_(bytes, pmt, result);

            if (result.video.length === 0) {
              delete result.video;
            }

            break;

          case streamTypes.ADTS_STREAM_TYPE:
            result.audio = [];
            parseAudioPes_(bytes, pmt, result);

            if (result.audio.length === 0) {
              delete result.audio;
            }

            break;
        }
      }
    }

    return result;
  };
  /**
   * Inspects segment byte data and returns an object with start and end timing information
   *
   * @param {Uint8Array} bytes The segment byte data
   * @param {Number} baseTimestamp Relative reference timestamp used when adjusting frame
   *  timestamps for rollover. This value must be in 90khz clock.
   * @return {Object} Object containing start and end frame timing info of segment.
   */


  var inspect = function inspect(bytes, baseTimestamp) {
    var isAacData = probe.aac.isLikelyAacData(bytes);
    var result;

    if (isAacData) {
      result = inspectAac_(bytes);
    } else {
      result = inspectTs_(bytes);
    }

    if (!result || !result.audio && !result.video) {
      return null;
    }

    adjustTimestamp_(result, baseTimestamp);
    return result;
  };

  var tsInspector = {
    inspect: inspect,
    parseAudioPes_: parseAudioPes_
  };

  var muxjs = {
    codecs: codecs,
    mp4: mp4,
    flv: flv,
    mp2t: m2ts,
    partial: partial
  }; // include all the tools when the full library is required

  muxjs.mp4.tools = mp4Inspector;
  muxjs.flv.tools = flvInspector;
  muxjs.mp2t.tools = tsInspector;
  var lib = muxjs;

  return lib;

})));
