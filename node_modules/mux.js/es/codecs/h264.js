/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 */
'use strict';

var Stream = require('../utils/stream.js');

var ExpGolomb = require('../utils/exp-golomb.js');

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

_NalByteStream.prototype = new Stream(); // values of profile_idc that indicate additional fields are included in the SPS
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

      default:
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
        sarScale = 1,
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
    expGolombDecoder = new ExpGolomb(data);
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
          sarScale = sarRatio[0] / sarRatio[1];
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

_H264Stream.prototype = new Stream();
module.exports = {
  H264Stream: _H264Stream,
  NalByteStream: _NalByteStream
};