var
  mp2t = require('../lib/m2ts'),
  id3Generator = require('./utils/id3-generator'),
  MP2T_PACKET_LENGTH = mp2t.MP2T_PACKET_LENGTH,
  PMT,
  PAT,
  generatePMT,
  pesHeader,
  packetize,
  transportPacket,
  videoPes,
  adtsFrame,
  audioPes,
  timedMetadataPes,
  binaryStringToArrayOfBytes,
  leftPad;


PMT = [
  0x47, // sync byte
  // tei:0 pusi:1 tp:0 pid:0 0000 0010 0000
  0x40, 0x10,
  // tsc:01 afc:01 cc:0000 pointer_field:0000 0000
  0x50, 0x00,
  // tid:0000 0010 ssi:0 0:0 r:00 sl:0000 0001 1100
  0x02, 0x00, 0x1c,
  // pn:0000 0000 0000 0001
  0x00, 0x01,
  // r:00 vn:00 000 cni:1 sn:0000 0000 lsn:0000 0000
  0x01, 0x00, 0x00,
  // r:000 ppid:0 0011 1111 1111
  0x03, 0xff,
  // r:0000 pil:0000 0000 0000
  0x00, 0x00,
  // h264
  // st:0001 1010 r:000 epid:0 0000 0001 0001
  0x1b, 0x00, 0x11,
  // r:0000 esil:0000 0000 0000
  0x00, 0x00,
  // adts
  // st:0000 1111 r:000 epid:0 0000 0001 0010
  0x0f, 0x00, 0x12,
  // r:0000 esil:0000 0000 0000
  0x00, 0x00,

  // timed metadata
  // st:0001 0111 r:000 epid:0 0000 0001 0011
  0x15, 0x00, 0x13,
  // r:0000 esil:0000 0000 0000
  0x00, 0x00,

  // crc
  0x00, 0x00, 0x00, 0x00
];

/*
 Packet Header:
 | sb | tei pusi tp pid:5 | pid | tsc afc cc |
 with af:
 | afl | ... | <data> |
 without af:
 | <data> |

PAT:
 | pf? | ... |
 | tid | ssi '0' r sl:4 | sl | tsi:8 |
 | tsi | r vn cni | sn | lsn |

with program_number == '0':
 | pn | pn | r np:5 | np |
otherwise:
 | pn | pn | r pmp:5 | pmp |
*/

PAT = [
  0x47, // sync byte
  // tei:0 pusi:1 tp:0 pid:0 0000 0000 0000
  0x40, 0x00,
  // tsc:01 afc:01 cc:0000 pointer_field:0000 0000
  0x50, 0x00,
  // tid:0000 0000 ssi:0 0:0 r:00 sl:0000 0000 0000
  0x00, 0x00, 0x00,
  // tsi:0000 0000 0000 0000
  0x00, 0x00,
  // r:00 vn:00 000 cni:1 sn:0000 0000 lsn:0000 0000
  0x01, 0x00, 0x00,
  // pn:0000 0000 0000 0001
  0x00, 0x01,
  // r:000 pmp:0 0000 0010 0000
  0x00, 0x10,
  // crc32:0000 0000 0000 0000 0000 0000 0000 0000
  0x00, 0x00, 0x00, 0x00
];

generatePMT = function(options) {
  var PMT = [
    0x47, // sync byte
    // tei:0 pusi:1 tp:0 pid:0 0000 0010 0000
    0x40, 0x10,
    // tsc:01 afc:01 cc:0000 pointer_field:0000 0000
    0x50, 0x00,
    // tid:0000 0010 ssi:0 0:0 r:00 sl:0000 0001 1100
    0x02, 0x00, 0x1c,
    // pn:0000 0000 0000 0001
    0x00, 0x01,
    // r:00 vn:00 000 cni:1 sn:0000 0000 lsn:0000 0000
    0x01, 0x00, 0x00,
    // r:000 ppid:0 0011 1111 1111
    0x03, 0xff,
    // r:0000 pil:0000 0000 0000
    0x00, 0x00];

    if (options.hasVideo) {
      // h264
      PMT = PMT.concat([
        // st:0001 1010 r:000 epid:0 0000 0001 0001
        0x1b, 0x00, 0x11,
        // r:0000 esil:0000 0000 0000
        0x00, 0x00
      ]);
    }

    if (options.hasAudio) {
      // adts
      PMT = PMT.concat([
        // st:0000 1111 r:000 epid:0 0000 0001 0010
        0x0f, 0x00, 0x12,
        // r:0000 esil:0000 0000 0000
        0x00, 0x00
      ]);
    }

    if (options.hasMetadata) {
      // timed metadata
      PMT = PMT.concat([
        // st:0001 0111 r:000 epid:0 0000 0001 0011
        0x15, 0x00, 0x13,
        // r:0000 esil:0000 0000 0000
        0x00, 0x00
      ]);
    }

    // crc
    return PMT.concat([0x00, 0x00, 0x00, 0x00]);
};

pesHeader = function(first, pts, dataLength) {
  if (!dataLength) {
    dataLength = 0;
  } else {
    // Add the pes header length (only the portion after the
    // pes_packet_length field)
    dataLength += 3;
  }

  // PES_packet(), Rec. ITU-T H.222.0, Table 2-21
  var result = [
    // pscp:0000 0000 0000 0000 0000 0001
    0x00, 0x00, 0x01,
    // sid:0000 0000 ppl:0000 0000 0000 0000
    0x00, 0x00, 0x00,
    // 10 psc:00 pp:0 dai:1 c:0 ooc:0
    0x84,
    // pdf:?0 ef:1 erf:0 dtmf:0 acif:0 pcf:0 pef:0
    0x20 | (pts ? 0x80 : 0x00),
    // phdl:0000 0000
    (first ? 0x01 : 0x00) + (pts ? 0x05 : 0x00)
  ];

  // Only store 15 bits of the PTS for QUnit.testing purposes
  if (pts) {
    var
      pts32 = Math.floor(pts / 2), // right shift by 1
      leftMostBit = ((pts32 & 0x80000000) >>> 31) & 0x01,
      firstThree;

    pts = pts & 0xffffffff;        // remove left most bit
    firstThree = (leftMostBit << 3) | (((pts & 0xc0000000) >>> 29) & 0x06) | 0x01;
    result.push((0x2 << 4) | firstThree);
    result.push((pts >>> 22) & 0xff);
    result.push(((pts >>> 14) | 0x01) & 0xff);
    result.push((pts >>> 7) & 0xff);
    result.push(((pts << 1) | 0x01) & 0xff);

    // Add the bytes spent on the pts info
    dataLength += 5;
  }
  if (first) {
    result.push(0x00);
    dataLength += 1;
  }

  // Finally set the pes_packet_length field
  result[4] = (dataLength & 0x0000FF00) >> 8;
  result[5] = dataLength & 0x000000FF;

  return result;
};

packetize = function(data) {
  var packet = new Uint8Array(MP2T_PACKET_LENGTH);
  packet.set(data);
  return packet;
};

/**
 * Helper function to create transport stream PES packets
 * @param pid {uint8} - the program identifier (PID)
 * @param data {arraylike} - the payload bytes
 * @payload first {boolean} - true if this PES should be a payload
 * unit start
 */
transportPacket = function(pid, data, first, pts, isVideoData) {
  var
    adaptationFieldLength = 188 - data.length - 14 - (first ? 1 : 0) - (pts ? 5 : 0),
    // transport_packet(), Rec. ITU-T H.222.0, Table 2-2
    result = [
      // sync byte
      0x47,
      // tei:0 pusi:1 tp:0 pid:0 0000 0001 0001
      0x40, pid,
      // tsc:01 afc:11 cc:0000
      0x70
    ].concat([
      // afl
      adaptationFieldLength & 0xff,
      // di:0 rai:0 espi:0 pf:0 of:0 spf:0 tpdf:0 afef:0
      0x00
    ]),
    i;

  i = adaptationFieldLength - 1;
  while (i--) {
    // stuffing_bytes
    result.push(0xff);
  }

  // PES_packet(), Rec. ITU-T H.222.0, Table 2-21
  result = result.concat(pesHeader(first, pts, isVideoData ? 0 : data.length));

  return result.concat(data);
};

/**
 * Helper function to create video PES packets
 * @param data {arraylike} - the payload bytes
 * @payload first {boolean} - true if this PES should be a payload
 * unit start
 */
videoPes = function(data, first, pts) {
  return transportPacket(0x11, [
    // NAL unit start code
    0x00, 0x00, 0x01
  ].concat(data), first, pts, true);
};

/**
 * Helper function to create audio ADTS frame header
 * @param dataLength {number} - the payload byte count
 */
adtsFrame = function(dataLength) {
  var frameLength = dataLength + 7;
  return [
    0xff, 0xf1,                            // no CRC
    0x10,                                  // AAC Main, 44.1KHz
    0xb0 | ((frameLength & 0x1800) >> 11), // 2 channels
    (frameLength & 0x7f8) >> 3,
    ((frameLength & 0x07) << 5) + 7,       // frame length in bytes
    0x00                                   // one AAC per ADTS frame
  ];
};

/**
 * Helper function to create audio PES packets
 * @param data {arraylike} - the payload bytes
 * @payload first {boolean} - true if this PES should be a payload
 * unit start
 */
audioPes = function(data, first, pts) {
  return transportPacket(0x12,
    adtsFrame(data.length).concat(data),
    first, pts);
};

timedMetadataPes = function(data) {
  var id3 = id3Generator;
  return transportPacket(0x13, id3.id3Tag(id3.id3Frame('PRIV', 0x00, 0x01)));
};

binaryStringToArrayOfBytes = function(string) {
  var
    array = [],
    arrayIndex = 0,
    stringIndex = 0;

  while (stringIndex < string.length) {
    array[arrayIndex] = parseInt(string.slice(stringIndex, stringIndex + 8), 2);

    arrayIndex++;
    // next byte
    stringIndex += 8;
  }

  return array;
};

leftPad = function(string, targetLength) {
  if (string.length >= targetLength) {
    return string;
  }
  return new Array(targetLength - string.length + 1).join('0') + string;
};

module.exports = {
  PMT: PMT,
  PAT: PAT,
  generatePMT: generatePMT,
  pesHeader: pesHeader,
  packetize: packetize,
  transportPacket: transportPacket,
  videoPes: videoPes,
  adtsFrame: adtsFrame,
  audioPes: audioPes,
  timedMetadataPes: timedMetadataPes,
  binaryStringToArrayOfBytes: binaryStringToArrayOfBytes,
  leftPad: leftPad
};
