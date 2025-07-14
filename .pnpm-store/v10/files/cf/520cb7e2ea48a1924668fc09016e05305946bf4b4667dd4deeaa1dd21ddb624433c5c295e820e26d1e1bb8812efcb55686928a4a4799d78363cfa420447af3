/**
 * mux.js
 *
 * Copyright (c) Brightcove
 * Licensed Apache-2.0 https://github.com/videojs/mux.js/blob/master/LICENSE
 *
 * Utilities to detect basic properties and metadata about TS Segments.
 */
'use strict';

var StreamTypes = require('./stream-types.js');

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
    case StreamTypes.H264_STREAM_TYPE:
      return 'video';

    case StreamTypes.ADTS_STREAM_TYPE:
      return 'audio';

    case StreamTypes.METADATA_STREAM_TYPE:
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

module.exports = {
  parseType: parseType,
  parsePat: parsePat,
  parsePmt: parsePmt,
  parsePayloadUnitStartIndicator: parsePayloadUnitStartIndicator,
  parsePesType: parsePesType,
  parsePesTime: parsePesTime,
  videoPacketContainsKeyFrame: videoPacketContainsKeyFrame
};