"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parseTs = void 0;

var _byteHelpers = require("./byte-helpers.js");

var SYNC_BYTE = 0x47; // use of maxPes is deprecated as we should always look at
// all pes packets to prevent being caught off guard by changes
// in that stream that happen after the pes specified

var parseTs = function parseTs(bytes, maxPes) {
  if (maxPes === void 0) {
    maxPes = Infinity;
  }

  bytes = (0, _byteHelpers.toUint8)(bytes);
  var startIndex = 0;
  var endIndex = 188;
  var pmt = {};
  var pesCount = 0;

  while (endIndex < bytes.byteLength && pesCount < maxPes) {
    if (bytes[startIndex] !== SYNC_BYTE && bytes[endIndex] !== SYNC_BYTE) {
      endIndex += 1;
      startIndex += 1;
      continue;
    }

    var packet = bytes.subarray(startIndex, endIndex);
    var pid = (packet[1] & 0x1f) << 8 | packet[2];
    var hasPusi = !!(packet[1] & 0x40);
    var hasAdaptationHeader = (packet[3] & 0x30) >>> 4 > 0x01;
    var payloadOffset = 4 + (hasAdaptationHeader ? packet[4] + 1 : 0);

    if (hasPusi) {
      payloadOffset += packet[payloadOffset] + 1;
    }

    if (pid === 0 && !pmt.pid) {
      pmt.pid = (packet[payloadOffset + 10] & 0x1f) << 8 | packet[payloadOffset + 11];
    } else if (pmt.pid && pid === pmt.pid) {
      var isNotForward = packet[payloadOffset + 5] & 0x01; // ignore forward pmt delarations

      if (!isNotForward) {
        continue;
      }

      pmt.streams = pmt.streams || {};
      var sectionLength = (packet[payloadOffset + 1] & 0x0f) << 8 | packet[payloadOffset + 2];
      var tableEnd = 3 + sectionLength - 4;
      var programInfoLength = (packet[payloadOffset + 10] & 0x0f) << 8 | packet[payloadOffset + 11];
      var offset = 12 + programInfoLength;

      while (offset < tableEnd) {
        // add an entry that maps the elementary_pid to the stream_type
        var i = payloadOffset + offset;
        var type = packet[i];
        var esPid = (packet[i + 1] & 0x1F) << 8 | packet[i + 2];
        var esLength = (packet[i + 3] & 0x0f) << 8 | packet[i + 4];
        var esInfo = packet.subarray(i + 5, i + 5 + esLength);
        var stream = pmt.streams[esPid] = {
          esInfo: esInfo,
          typeNumber: type,
          packets: [],
          type: '',
          codec: ''
        };

        if (type === 0x06 && (0, _byteHelpers.bytesMatch)(esInfo, [0x4F, 0x70, 0x75, 0x73], {
          offset: 2
        })) {
          stream.type = 'audio';
          stream.codec = 'opus';
        } else if (type === 0x1B || type === 0x20) {
          stream.type = 'video';
          stream.codec = 'avc1';
        } else if (type === 0x24) {
          stream.type = 'video';
          stream.codec = 'hev1';
        } else if (type === 0x10) {
          stream.type = 'video';
          stream.codec = 'mp4v.20';
        } else if (type === 0x0F) {
          stream.type = 'audio';
          stream.codec = 'aac';
        } else if (type === 0x81) {
          stream.type = 'audio';
          stream.codec = 'ac-3';
        } else if (type === 0x87) {
          stream.type = 'audio';
          stream.codec = 'ec-3';
        } else if (type === 0x03 || type === 0x04) {
          stream.type = 'audio';
          stream.codec = 'mp3';
        }

        offset += esLength + 5;
      }
    } else if (pmt.pid && pmt.streams) {
      pmt.streams[pid].packets.push(packet.subarray(payloadOffset));
      pesCount++;
    }

    startIndex += 188;
    endIndex += 188;
  }

  if (!pmt.streams) {
    pmt.streams = {};
  }

  return pmt;
};

exports.parseTs = parseTs;