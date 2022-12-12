import { toUint8, bytesMatch } from './byte-helpers.js';
var ID3 = toUint8([0x49, 0x44, 0x33]);
export var getId3Size = function getId3Size(bytes, offset) {
  if (offset === void 0) {
    offset = 0;
  }

  bytes = toUint8(bytes);
  var flags = bytes[offset + 5];
  var returnSize = bytes[offset + 6] << 21 | bytes[offset + 7] << 14 | bytes[offset + 8] << 7 | bytes[offset + 9];
  var footerPresent = (flags & 16) >> 4;

  if (footerPresent) {
    return returnSize + 20;
  }

  return returnSize + 10;
};
export var getId3Offset = function getId3Offset(bytes, offset) {
  if (offset === void 0) {
    offset = 0;
  }

  bytes = toUint8(bytes);

  if (bytes.length - offset < 10 || !bytesMatch(bytes, ID3, {
    offset: offset
  })) {
    return offset;
  }

  offset += getId3Size(bytes, offset); // recursive check for id3 tags as some files
  // have multiple ID3 tag sections even though
  // they should not.

  return getId3Offset(bytes, offset);
};