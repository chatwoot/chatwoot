/*! @name mux.js @version 6.0.1 @license Apache-2.0 */
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.muxjs = factory());
}(this, (function () { 'use strict';

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

  var discardEmulationPreventionBytes = function discardEmulationPreventionBytes(data) {
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
    discardEmulationPreventionBytes: discardEmulationPreventionBytes,
    USER_DATA_REGISTERED_ITU_T_T35: USER_DATA_REGISTERED_ITU_T_T35
  };

  // Link To Transport
  // -----------------


  var CaptionStream = function CaptionStream(options) {
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

  CaptionStream.prototype = new stream();

  CaptionStream.prototype.push = function (event) {
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

  CaptionStream.prototype.flushCCStreams = function (flushType) {
    this.ccStreams_.forEach(function (cc) {
      return flushType === 'flush' ? cc.flush() : cc.partialFlush();
    }, this);
  };

  CaptionStream.prototype.flushStream = function (flushType) {
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

  CaptionStream.prototype.flush = function () {
    return this.flushStream('flush');
  }; // Only called if handling partial data


  CaptionStream.prototype.partialFlush = function () {
    return this.flushStream('partialFlush');
  };

  CaptionStream.prototype.reset = function () {
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


  CaptionStream.prototype.dispatchCea608Packet = function (packet) {
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

  CaptionStream.prototype.setsChannel1Active = function (packet) {
    return (packet.ccData & 0x7800) === 0x1000;
  };

  CaptionStream.prototype.setsChannel2Active = function (packet) {
    return (packet.ccData & 0x7800) === 0x1800;
  };

  CaptionStream.prototype.setsTextOrXDSActive = function (packet) {
    return (packet.ccData & 0x7100) === 0x0100 || (packet.ccData & 0x78fe) === 0x102a || (packet.ccData & 0x78fe) === 0x182a;
  };

  CaptionStream.prototype.dispatchCea708Packet = function (packet) {
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
    CaptionStream: CaptionStream,
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

  var handleRollover = function handleRollover(value, reference) {
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

      data.dts = handleRollover(data.dts, referenceDTS);
      data.pts = handleRollover(data.pts, referenceDTS);
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
    handleRollover: handleRollover
  };

  var percentEncode = function percentEncode(bytes, start, end) {
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
    return decodeURIComponent(percentEncode(bytes, start, end));
  },
      // return the string representation of the specified byte range,
  // interpreted as ISO-8859-1.
  parseIso88591 = function parseIso88591(bytes, start, end) {
    return unescape(percentEncode(bytes, start, end)); // jshint ignore:line
  },
      parseSyncSafeInteger = function parseSyncSafeInteger(data) {
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
          tag.owner = parseIso88591(tag.data, 0, i);
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
        tagSize = parseSyncSafeInteger(chunk.data.subarray(6, 10)); // ID3 reports the tag size excluding the header but it's more
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

        frameStart += parseSyncSafeInteger(tag.data.subarray(10, 14)); // clip any padding off the end

        tagSize -= parseSyncSafeInteger(tag.data.subarray(16, 20));
      } // parse one or more ID3 frames
      // http://id3.org/id3v2.3.0#ID3v2_frame_overview


      do {
        // determine the number of bytes in this frame
        frameSize = parseSyncSafeInteger(tag.data.subarray(frameStart + 4, frameStart + 8));

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


  var MP2T_PACKET_LENGTH = 188,
      // bytes
  SYNC_BYTE = 0x47;
  /**
   * Splits an incoming stream of binary data into MPEG-2 Transport
   * Stream packets.
   */

  _TransportPacketStream = function TransportPacketStream() {
    var buffer = new Uint8Array(MP2T_PACKET_LENGTH),
        bytesInBuffer = 0;

    _TransportPacketStream.prototype.init.call(this); // Deliver new bytes to the stream.

    /**
     * Split a stream of data into M2TS packets
    **/


    this.push = function (bytes) {
      var startIndex = 0,
          endIndex = MP2T_PACKET_LENGTH,
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
        if (everything[startIndex] === SYNC_BYTE && everything[endIndex] === SYNC_BYTE) {
          // We found a packet so emit it and jump one whole packet forward in
          // the stream
          this.trigger('data', everything.subarray(startIndex, endIndex));
          startIndex += MP2T_PACKET_LENGTH;
          endIndex += MP2T_PACKET_LENGTH;
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
      if (bytesInBuffer === MP2T_PACKET_LENGTH && buffer[0] === SYNC_BYTE) {
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
  var m2ts = {
    PAT_PID: 0x0000,
    MP2T_PACKET_LENGTH: MP2T_PACKET_LENGTH,
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
      m2ts[type] = streamTypes[type];
    }
  }

  var m2ts_1 = m2ts;

  /**
   * mux.js
   *
   * Copyright (c) Brightcove
   * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
   */
  var ONE_SECOND_IN_TS$1 = 90000,
      // 90kHz clock
  secondsToVideoTs,
      secondsToAudioTs,
      videoTsToSeconds,
      audioTsToSeconds,
      audioTsToVideoTs,
      videoTsToAudioTs,
      metadataTsToSeconds;

  secondsToVideoTs = function secondsToVideoTs(seconds) {
    return seconds * ONE_SECOND_IN_TS$1;
  };

  secondsToAudioTs = function secondsToAudioTs(seconds, sampleRate) {
    return seconds * sampleRate;
  };

  videoTsToSeconds = function videoTsToSeconds(timestamp) {
    return timestamp / ONE_SECOND_IN_TS$1;
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
    ONE_SECOND_IN_TS: ONE_SECOND_IN_TS$1,
    secondsToVideoTs: secondsToVideoTs,
    secondsToAudioTs: secondsToAudioTs,
    videoTsToSeconds: videoTsToSeconds,
    audioTsToSeconds: audioTsToSeconds,
    audioTsToVideoTs: audioTsToVideoTs,
    videoTsToAudioTs: videoTsToAudioTs,
    metadataTsToSeconds: metadataTsToSeconds
  };

  var ONE_SECOND_IN_TS = clock.ONE_SECOND_IN_TS;

  var _AdtsStream;

  var ADTS_SAMPLING_FREQUENCIES = [96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350];
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
        adtsFrameDuration = sampleCount * ONE_SECOND_IN_TS / ADTS_SAMPLING_FREQUENCIES[(buffer[i + 2] & 0x3c) >>> 2]; // If we don't have enough data to actually finish this ADTS frame,
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

  var transmuxer = _Transmuxer;

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
    Transmuxer: transmuxer,
    getFlvHeader: flvHeader
  };

  return flv;

})));
