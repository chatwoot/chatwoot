import { padStart, toHexString, toBinaryString } from './byte-helpers.js'; // https://aomediacodec.github.io/av1-isobmff/#av1codecconfigurationbox-syntax
// https://developer.mozilla.org/en-US/docs/Web/Media/Formats/codecs_parameter#AV1

export var getAv1Codec = function getAv1Codec(bytes) {
  var codec = '';
  var profile = bytes[1] >>> 3;
  var level = bytes[1] & 0x1F;
  var tier = bytes[2] >>> 7;
  var highBitDepth = (bytes[2] & 0x40) >> 6;
  var twelveBit = (bytes[2] & 0x20) >> 5;
  var monochrome = (bytes[2] & 0x10) >> 4;
  var chromaSubsamplingX = (bytes[2] & 0x08) >> 3;
  var chromaSubsamplingY = (bytes[2] & 0x04) >> 2;
  var chromaSamplePosition = bytes[2] & 0x03;
  codec += profile + "." + padStart(level, 2, '0');

  if (tier === 0) {
    codec += 'M';
  } else if (tier === 1) {
    codec += 'H';
  }

  var bitDepth;

  if (profile === 2 && highBitDepth) {
    bitDepth = twelveBit ? 12 : 10;
  } else {
    bitDepth = highBitDepth ? 10 : 8;
  }

  codec += "." + padStart(bitDepth, 2, '0'); // TODO: can we parse color range??

  codec += "." + monochrome;
  codec += "." + chromaSubsamplingX + chromaSubsamplingY + chromaSamplePosition;
  return codec;
};
export var getAvcCodec = function getAvcCodec(bytes) {
  var profileId = toHexString(bytes[1]);
  var constraintFlags = toHexString(bytes[2] & 0xFC);
  var levelId = toHexString(bytes[3]);
  return "" + profileId + constraintFlags + levelId;
};
export var getHvcCodec = function getHvcCodec(bytes) {
  var codec = '';
  var profileSpace = bytes[1] >> 6;
  var profileId = bytes[1] & 0x1F;
  var tierFlag = (bytes[1] & 0x20) >> 5;
  var profileCompat = bytes.subarray(2, 6);
  var constraintIds = bytes.subarray(6, 12);
  var levelId = bytes[12];

  if (profileSpace === 1) {
    codec += 'A';
  } else if (profileSpace === 2) {
    codec += 'B';
  } else if (profileSpace === 3) {
    codec += 'C';
  }

  codec += profileId + "."; // ffmpeg does this in big endian

  var profileCompatVal = parseInt(toBinaryString(profileCompat).split('').reverse().join(''), 2); // apple does this in little endian...

  if (profileCompatVal > 255) {
    profileCompatVal = parseInt(toBinaryString(profileCompat), 2);
  }

  codec += profileCompatVal.toString(16) + ".";

  if (tierFlag === 0) {
    codec += 'L';
  } else {
    codec += 'H';
  }

  codec += levelId;
  var constraints = '';

  for (var i = 0; i < constraintIds.length; i++) {
    var v = constraintIds[i];

    if (v) {
      if (constraints) {
        constraints += '.';
      }

      constraints += v.toString(16);
    }
  }

  if (constraints) {
    codec += "." + constraints;
  }

  return codec;
};