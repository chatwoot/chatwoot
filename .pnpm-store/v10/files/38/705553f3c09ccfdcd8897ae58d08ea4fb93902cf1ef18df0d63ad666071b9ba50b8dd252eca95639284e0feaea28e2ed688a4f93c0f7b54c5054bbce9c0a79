import {toUint8, bytesMatch} from './byte-helpers.js';
const ID3 = toUint8([0x49, 0x44, 0x33]);

export const getId3Size = function(bytes, offset = 0) {
  bytes = toUint8(bytes);

  const flags = bytes[offset + 5];
  const returnSize = (bytes[offset + 6] << 21) |
                     (bytes[offset + 7] << 14) |
                     (bytes[offset + 8] << 7) |
                     (bytes[offset + 9]);
  const footerPresent = (flags & 16) >> 4;

  if (footerPresent) {
    return returnSize + 20;
  }

  return returnSize + 10;
};

export const getId3Offset = function(bytes, offset = 0) {
  bytes = toUint8(bytes);

  if ((bytes.length - offset) < 10 || !bytesMatch(bytes, ID3, {offset})) {
    return offset;
  }

  offset += getId3Size(bytes, offset);

  // recursive check for id3 tags as some files
  // have multiple ID3 tag sections even though
  // they should not.
  return getId3Offset(bytes, offset);
};

