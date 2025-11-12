'use strict';

var
  aacStream,
  AacStream = require('../lib/aac'),
  QUnit = require('qunit'),
  utils = require('./utils'),
  createId3Header,
  createId3FrameHeader,
  createAdtsHeader;

createId3Header = function(tagSize) {
  var header = [];

  header[0] = 'I'.charCodeAt(0);
  header[1] = 'D'.charCodeAt(0);
  header[2] = '3'.charCodeAt(0);
  // 2 version bytes, ID3v2.4.0 (major 4, revision 0)
  header[3] = 4;
  header[4] = 0;
  // unsynchronization, extended header, experimental indicator, footer present flags
  header[5] = 0;
  // "The ID3v2 tag size is the sum of the byte length of the extended
  // header, the padding and the frames after unsynchronisation. If a
  // footer is present this equals to ('total size' - 20) bytes, otherwise
  // ('total size' - 10) bytes."
  // http://id3.org/id3v2.4.0-structure
  header[6] = 0;
  header[7] = 0;
  header[8] = 0;
  header[9] = tagSize;

  return header;
};

createId3FrameHeader = function() {
  var header = [];

  // four byte frame ID, XYZ are experimental
  header[0] = 'X'.charCodeAt(0);
  header[1] = 'Y'.charCodeAt(0);
  header[2] = 'Z'.charCodeAt(0);
  header[3] = '0'.charCodeAt(0);
  // four byte sync safe integer size (excluding frame header)
  header[4] = 0;
  header[5] = 0;
  header[6] = 0;
  header[7] = 10;
  // two bytes for flags
  header[8] = 0;
  header[9] = 0;

  return header;
};

createAdtsHeader = function(frameLength) {
  // Header consists of 7 or 9 bytes (without or with CRC).
  // see: https://wiki.multimedia.cx/index.php/ADTS
  return utils.binaryStringToArrayOfBytes(''.concat(
    // 12 bits for syncword (0xFFF)
    '111111111111',
    // 1 bit MPEG version
    '0',
    // 2 bit layer (always 0)
    '00',
    // 1 bit protection absent (1 for no CRC)
    '1',
    // 2 bit profile
    '10',
    // 4 bit sampling frequency index
    '0110',
    // 1 bit private bit
    '0',
    // 3 bit channel config
    '100',
    // 2 bit (ignore)
    '00',
    // 2 bit (copright bits)
    '00',
    // 13 bit frame length (includes header length)
    utils.leftPad(frameLength.toString(2), 13),
    // 11 bit buffer fullness
    '11111111111',
    // 2 bit number of AAC frames minus 1
    '00'
    // 16 bit CRC (if present)
  ));
};

QUnit.module('AAC Stream', {
  beforeEach: function() {
    aacStream = new AacStream();
  }
});

QUnit.test('parses ID3 tag', function(assert) {
  var
    id3Count = 0,
    adtsCount = 0,
    frameHeader = createId3FrameHeader(),
    id3Tag = createId3Header(frameHeader.length).concat(frameHeader);

  aacStream.on('data', function(frame) {
    if (frame.type === 'timed-metadata') {
      id3Count += 1;
    } else if (frame.type === 'audio') {
      adtsCount += 1;
    }
  });

  aacStream.push(new Uint8Array(id3Tag));

  assert.equal(adtsCount, 0, 'no adts frames');
  assert.equal(id3Count, 1, 'one id3 chunk');
});

QUnit.test('parses two ID3 tags in sequence', function(assert) {
  var
    id3Count = 0,
    adtsCount = 0,
    frameHeader = createId3FrameHeader(),
    id3Tag = createId3Header(frameHeader.length).concat(frameHeader);

  aacStream.on('data', function(frame) {
    if (frame.type === 'timed-metadata') {
      id3Count += 1;
    } else if (frame.type === 'audio') {
      adtsCount += 1;
    }
  });

  aacStream.push(new Uint8Array(id3Tag.concat(id3Tag)));

  assert.equal(adtsCount, 0, 'no adts frames');
  assert.equal(id3Count, 2, 'two id3 chunks');
});

QUnit.test('does not parse second ID3 tag if it\'s incomplete', function(assert) {
  var
    id3Count = 0,
    adtsCount = 0,
    frameHeader = createId3FrameHeader(),
    id3Tag = createId3Header(frameHeader.length).concat(frameHeader);

  aacStream.on('data', function(frame) {
    if (frame.type === 'timed-metadata') {
      id3Count += 1;
    } else if (frame.type === 'audio') {
      adtsCount += 1;
    }
  });

  aacStream.push(new Uint8Array(id3Tag.concat(id3Tag.slice(0, id3Tag.length - 1))));

  assert.equal(adtsCount, 0, 'no adts frames');
  assert.equal(id3Count, 1, 'one id3 chunk');
});

QUnit.test('handles misaligned adts header', function(assert) {
  var
    id3Count = 0,
    adtsCount = 0,
    // fake adts frame
    adtsFrame = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    packetStream = createAdtsHeader(adtsFrame.length).concat(adtsFrame);

  aacStream.on('data', function(frame) {
    if (frame.type === 'timed-metadata') {
      id3Count += 1;
    } else if (frame.type === 'audio') {
      adtsCount += 1;
    }
  });

  // misalign by two bytes specific to a bug related to detecting sync bytes
  // (where we were only properly checking the second byte)
  aacStream.push(new Uint8Array([0x01, 0xf0].concat(packetStream)));

  assert.equal(adtsCount, 1, 'one adts frames');
  assert.equal(id3Count, 0, 'no id3 chunk');
});

QUnit.test('handles incomplete adts frame after id3 frame', function(assert) {
  var
    id3Count = 0,
    adtsCount = 0,
    id3FrameHeader = createId3FrameHeader(),
    id3Tag = createId3Header(id3FrameHeader.length).concat(id3FrameHeader),
    // in this case:
    //   id3 tag = 20 bytes
    //   adts header = 7 bytes
    //   total = 27 bytes
    // report the ADTS frame size as 20 bytes
    adtsHeader = createAdtsHeader(20),
    // no adts frame, stream was cut off
    packetStream = id3Tag.concat(adtsHeader);

  aacStream.on('data', function(frame) {
    if (frame.type === 'timed-metadata') {
      id3Count += 1;
    } else if (frame.type === 'audio') {
      adtsCount += 1;
    }
  });

  aacStream.push(new Uint8Array(packetStream));

  assert.equal(adtsCount, 0, 'no adts frame');
  assert.equal(id3Count, 1, 'one id3 chunk');
});

QUnit.test('emits data after receiving push', function(assert) {
  var
    array = new Uint8Array(109),
    count = 0;

  array[0] = 255;
  array[1] = 241;
  array[2] = 92;
  array[3] = 128;
  array[4] = 13;
  array[5] = 191;
  array[6] = 252;
  array[7] = 33;
  array[8] = 32;
  array[9] = 3;
  array[10] = 64;
  array[11] = 104;
  array[12] = 27;
  array[13] = 212;
  aacStream.setTimestamp(90);
  aacStream.on('data', function(frame) {
    if (frame.pts === 90 && frame.dts === 90) {
      count += 1;
    }
  });
  aacStream.push(array);
  assert.equal(count, 1);
});

QUnit.test('continues parsing after corrupted stream', function(assert) {
  var
    array = new Uint8Array(10000),
    adtsCount = 0,
    id3Count = 0;

  // an ID3 frame
  array[0] = 73;
  array[1] = 68;
  array[2] = 51;
  array[3] = 4;
  array[4] = 0;
  array[5] = 0;
  array[6] = 0;
  array[7] = 0;
  array[8] = 0;
  array[9] = 63;
  array[10] = 80;
  array[11] = 82;
  array[12] = 73;
  array[13] = 86;

  // an atds frame
  array[1020] = 255;
  array[1021] = 241;
  array[1022] = 92;
  array[1023] = 128;
  array[1024] = 13;
  array[1025] = 191;
  array[1026] = 252;
  array[1027] = 33;
  array[1028] = 32;
  array[1029] = 3;
  array[1030] = 64;
  array[1031] = 104;
  array[1032] = 27;
  array[1033] = 212;

  aacStream.on('data', function(frame) {
    if (frame.type === 'timed-metadata') {
      id3Count += 1;
    } else if (frame.type === 'audio') {
      adtsCount += 1;
    }
  });
  aacStream.push(array);
  assert.equal(adtsCount, 1);
  assert.equal(id3Count, 1);
});
