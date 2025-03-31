import { bytesMatch, toUint8 } from './byte-helpers';
var SYNC_WORD = toUint8([0x4f, 0x67, 0x67, 0x53]);
export var getPages = function getPages(bytes, start, end) {
  if (end === void 0) {
    end = Infinity;
  }

  bytes = toUint8(bytes);
  var pages = [];
  var i = 0;

  while (i < bytes.length && pages.length < end) {
    // we are unsynced,
    // find the next syncword
    if (!bytesMatch(bytes, SYNC_WORD, {
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