import {bytesMatch, toUint8} from './byte-helpers.js';

export const NAL_TYPE_ONE = toUint8([0x00, 0x00, 0x00, 0x01]);
export const NAL_TYPE_TWO = toUint8([0x00, 0x00, 0x01]);
export const EMULATION_PREVENTION = toUint8([0x00, 0x00, 0x03]);

/**
 * Expunge any "Emulation Prevention" bytes from a "Raw Byte
 * Sequence Payload"
 *
 * @param data {Uint8Array} the bytes of a RBSP from a NAL
 * unit
 * @return {Uint8Array} the RBSP without any Emulation
 * Prevention Bytes
 */
export const discardEmulationPreventionBytes = function(bytes) {
  const positions = [];

  let i = 1;

  // Find all `Emulation Prevention Bytes`
  while (i < bytes.length - 2) {
    if (bytesMatch(bytes.subarray(i, i + 3), EMULATION_PREVENTION)) {
      positions.push(i + 2);
      i++;
    }

    i++;
  }

  // If no Emulation Prevention Bytes were found just return the original
  // array
  if (positions.length === 0) {
    return bytes;
  }

  // Create a new array to hold the NAL unit data
  const newLength = bytes.length - positions.length;
  const newData = new Uint8Array(newLength);
  let sourceIndex = 0;

  for (i = 0; i < newLength; sourceIndex++, i++) {
    if (sourceIndex === positions[0]) {
      // Skip this byte
      sourceIndex++;
      // Remove this position index
      positions.shift();
    }
    newData[i] = bytes[sourceIndex];
  }

  return newData;
};

export const findNal = function(bytes, dataType, types, nalLimit = Infinity) {
  bytes = toUint8(bytes);
  types = [].concat(types);

  let i = 0;
  let nalStart;
  let nalsFound = 0;

  // keep searching until:
  // we reach the end of bytes
  // we reach the maximum number of nals they want to seach
  // NOTE: that we disregard nalLimit when we have found the start
  // of the nal we want so that we can find the end of the nal we want.
  while (i < bytes.length && (nalsFound < nalLimit || nalStart)) {
    let nalOffset;

    if (bytesMatch(bytes.subarray(i), NAL_TYPE_ONE)) {
      nalOffset = 4;
    } else if (bytesMatch(bytes.subarray(i), NAL_TYPE_TWO)) {
      nalOffset = 3;
    }

    // we are unsynced,
    // find the next nal unit
    if (!nalOffset) {
      i++;
      continue;
    }
    nalsFound++;

    if (nalStart) {
      return discardEmulationPreventionBytes(bytes.subarray(nalStart, i));
    }

    let nalType;

    if (dataType === 'h264') {
      nalType = (bytes[i + nalOffset] & 0x1f);
    } else if (dataType === 'h265') {
      nalType = (bytes[i + nalOffset] >> 1) & 0x3f;
    }

    if (types.indexOf(nalType) !== -1) {
      nalStart = i + nalOffset;
    }

    // nal header is 1 length for h264, and 2 for h265
    i += nalOffset + (dataType === 'h264' ? 1 : 2);
  }

  return bytes.subarray(0, 0);
};

export const findH264Nal = (bytes, type, nalLimit) => findNal(bytes, 'h264', type, nalLimit);
export const findH265Nal = (bytes, type, nalLimit) => findNal(bytes, 'h265', type, nalLimit);
