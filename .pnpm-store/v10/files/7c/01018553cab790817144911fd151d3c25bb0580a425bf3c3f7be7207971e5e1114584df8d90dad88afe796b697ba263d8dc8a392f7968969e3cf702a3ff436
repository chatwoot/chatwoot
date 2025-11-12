"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getPages = void 0;

var _byteHelpers = require("./byte-helpers");

var SYNC_WORD = (0, _byteHelpers.toUint8)([0x4f, 0x67, 0x67, 0x53]);

var getPages = function getPages(bytes, start, end) {
  if (end === void 0) {
    end = Infinity;
  }

  bytes = (0, _byteHelpers.toUint8)(bytes);
  var pages = [];
  var i = 0;

  while (i < bytes.length && pages.length < end) {
    // we are unsynced,
    // find the next syncword
    if (!(0, _byteHelpers.bytesMatch)(bytes, SYNC_WORD, {
      offset: i
    })) {
      i++;
      continue;
    }

    var segmentLength = bytes[i + 27];
    pages.push(bytes.subarray(i, i + 28 + segmentLength));
    i += pages[pages.length - 1].length;
  }

  return pages.slice(start, end);
};

exports.getPages = getPages;