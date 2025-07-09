"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getId3Offset = exports.getId3Size = void 0;

var _byteHelpers = require("./byte-helpers.js");

var ID3 = (0, _byteHelpers.toUint8)([0x49, 0x44, 0x33]);

var getId3Size = function getId3Size(bytes, offset) {
  if (offset === void 0) {
    offset = 0;
  }

  bytes = (0, _byteHelpers.toUint8)(bytes);
  var flags = bytes[offset + 5];
  var returnSize = bytes[offset + 6] << 21 | bytes[offset + 7] << 14 | bytes[offset + 8] << 7 | bytes[offset + 9];
  var footerPresent = (flags & 16) >> 4;

  if (footerPresent) {
    return returnSize + 20;
  }

  return returnSize + 10;
};

exports.getId3Size = getId3Size;

var getId3Offset = function getId3Offset(bytes, offset) {
  if (offset === void 0) {
    offset = 0;
  }

  bytes = (0, _byteHelpers.toUint8)(bytes);

  if (bytes.length - offset < 10 || !(0, _byteHelpers.bytesMatch)(bytes, ID3, {
    offset: offset
  })) {
    return offset;
  }

  offset += getId3Size(bytes, offset); // recursive check for id3 tags as some files
  // have multiple ID3 tag sections even though
  // they should not.

  return getId3Offset(bytes, offset);
};

exports.getId3Offset = getId3Offset;