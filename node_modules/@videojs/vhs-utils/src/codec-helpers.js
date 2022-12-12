import {padStart, toHexString, toBinaryString} from './byte-helpers.js';

// https://aomediacodec.github.io/av1-isobmff/#av1codecconfigurationbox-syntax
// https://developer.mozilla.org/en-US/docs/Web/Media/Formats/codecs_parameter#AV1
export const getAv1Codec = function(bytes) {
  let codec = '';
  const profile = bytes[1] >>> 3;
  const level = bytes[1] & 0x1F;
  const tier = bytes[2] >>> 7;
  const highBitDepth = (bytes[2] & 0x40) >> 6;
  const twelveBit = (bytes[2] & 0x20) >> 5;
  const monochrome = (bytes[2] & 0x10) >> 4;
  const chromaSubsamplingX = (bytes[2] & 0x08) >> 3;
  const chromaSubsamplingY = (bytes[2] & 0x04) >> 2;
  const chromaSamplePosition = bytes[2] & 0x03;

  codec += `${profile}.${padStart(level, 2, '0')}`;

  if (tier === 0) {
    codec += 'M';
  } else if (tier === 1) {
    codec += 'H';
  }

  let bitDepth;

  if (profile === 2 && highBitDepth) {
    bitDepth = twelveBit ? 12 : 10;
  } else {
    bitDepth = highBitDepth ? 10 : 8;
  }

  codec += `.${padStart(bitDepth, 2, '0')}`;

  // TODO: can we parse color range??
  codec += `.${monochrome}`;
  codec += `.${chromaSubsamplingX}${chromaSubsamplingY}${chromaSamplePosition}`;

  return codec;
};

export const getAvcCodec = function(bytes) {
  const profileId = toHexString(bytes[1]);
  const constraintFlags = toHexString(bytes[2] & 0xFC);
  const levelId = toHexString(bytes[3]);

  return `${profileId}${constraintFlags}${levelId}`;
};

export const getHvcCodec = function(bytes) {
  let codec = '';
  const profileSpace = bytes[1] >> 6;
  const profileId = bytes[1] & 0x1F;
  const tierFlag = (bytes[1] & 0x20) >> 5;

  const profileCompat = bytes.subarray(2, 6);
  const constraintIds = bytes.subarray(6, 12);
  const levelId = bytes[12];

  if (profileSpace === 1) {
    codec += 'A';
  } else if (profileSpace === 2) {
    codec += 'B';
  } else if (profileSpace === 3) {
    codec += 'C';
  }

  codec += `${profileId}.`;

  // ffmpeg does this in big endian
  let profileCompatVal = parseInt(toBinaryString(profileCompat).split('').reverse().join(''), 2);

  // apple does this in little endian...
  if (profileCompatVal > 255) {
    profileCompatVal = parseInt(toBinaryString(profileCompat), 2);
  }

  codec += `${profileCompatVal.toString(16)}.`;

  if (tierFlag === 0) {
    codec += 'L';
  } else {
    codec += 'H';
  }

  codec += levelId;

  let constraints = '';

  for (let i = 0; i < constraintIds.length; i++) {
    const v = constraintIds[i];

    if (v) {
      if (constraints) {
        constraints += '.';
      }
      constraints += v.toString(16);
    }
  }

  if (constraints) {
    codec += `.${constraints}`;
  }

  return codec;
};
