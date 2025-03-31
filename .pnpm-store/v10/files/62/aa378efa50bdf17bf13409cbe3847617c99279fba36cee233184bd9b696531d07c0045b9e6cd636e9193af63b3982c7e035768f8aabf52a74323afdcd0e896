import {bytesMatch, toUint8} from './byte-helpers.js';
const SYNC_BYTE = 0x47;

// use of maxPes is deprecated as we should always look at
// all pes packets to prevent being caught off guard by changes
// in that stream that happen after the pes specified
export const parseTs = function(bytes, maxPes = Infinity) {
  bytes = toUint8(bytes);

  let startIndex = 0;
  let endIndex = 188;
  const pmt = {};
  let pesCount = 0;

  while (endIndex < bytes.byteLength && pesCount < maxPes) {
    if (bytes[startIndex] !== SYNC_BYTE && bytes[endIndex] !== SYNC_BYTE) {
      endIndex += 1;
      startIndex += 1;
      continue;
    }
    const packet = bytes.subarray(startIndex, endIndex);
    const pid = (((packet[1] & 0x1f) << 8) | packet[2]);
    const hasPusi = !!(packet[1] & 0x40);
    const hasAdaptationHeader = (((packet[3] & 0x30) >>> 4) > 0x01);
    let payloadOffset = 4 + (hasAdaptationHeader ? (packet[4] + 1) : 0);

    if (hasPusi) {
      payloadOffset += packet[payloadOffset] + 1;
    }

    if (pid === 0 && !pmt.pid) {
      pmt.pid = (packet[payloadOffset + 10] & 0x1f) << 8 | packet[payloadOffset + 11];
    } else if (pmt.pid && pid === pmt.pid) {
      const isNotForward = packet[payloadOffset + 5] & 0x01;

      // ignore forward pmt delarations
      if (!isNotForward) {
        continue;
      }
      pmt.streams = pmt.streams || {};

      const sectionLength = (packet[payloadOffset + 1] & 0x0f) << 8 | packet[payloadOffset + 2];
      const tableEnd = 3 + sectionLength - 4;
      const programInfoLength = (packet[payloadOffset + 10] & 0x0f) << 8 | packet[payloadOffset + 11];
      let offset = 12 + programInfoLength;

      while (offset < tableEnd) {
        // add an entry that maps the elementary_pid to the stream_type
        const i = payloadOffset + offset;
        const type = packet[i];
        const esPid = (packet[i + 1] & 0x1F) << 8 | packet[i + 2];
        const esLength = ((packet[i + 3] & 0x0f) << 8 | (packet[i + 4]));
        const esInfo = packet.subarray(i + 5, i + 5 + esLength);
        const stream = pmt.streams[esPid] = {
          esInfo,
          typeNumber: type,
          packets: [],
          type: '',
          codec: ''
        };

        if (type === 0x06 && bytesMatch(esInfo, [0x4F, 0x70, 0x75, 0x73], {offset: 2})) {
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
