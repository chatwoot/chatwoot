"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.findFourCC = void 0;

var _byteHelpers = require("./byte-helpers.js");

var CONSTANTS = {
  LIST: (0, _byteHelpers.toUint8)([0x4c, 0x49, 0x53, 0x54]),
  RIFF: (0, _byteHelpers.toUint8)([0x52, 0x49, 0x46, 0x46]),
  WAVE: (0, _byteHelpers.toUint8)([0x57, 0x41, 0x56, 0x45])
};

var normalizePath = function normalizePath(path) {
  if (typeof path === 'string') {
    return (0, _byteHelpers.stringToBytes)(path);
  }

  if (typeof path === 'number') {
    return path;
  }

  return path;
};

var normalizePaths = function normalizePaths(paths) {
  if (!Array.isArray(paths)) {
    return [normalizePath(paths)];
  }

  return paths.map(function (p) {
    return normalizePath(p);
  });
};

var findFourCC = function findFourCC(bytes, paths) {
  paths = normalizePaths(paths);
  bytes = (0, _byteHelpers.toUint8)(bytes);
  var results = [];

  if (!paths.length) {
    // short-circuit the search for empty paths
    return results;
  }

  var i = 0;

  while (i < bytes.length) {
    var type = bytes.subarray(i, i + 4);
    var size = (bytes[i + 7] << 24 | bytes[i + 6] << 16 | bytes[i + 5] << 8 | bytes[i + 4]) >>> 0; // skip LIST/RIFF and get the actual type

    if ((0, _byteHelpers.bytesMatch)(type, CONSTANTS.LIST) || (0, _byteHelpers.bytesMatch)(type, CONSTANTS.RIFF) || (0, _byteHelpers.bytesMatch)(type, CONSTANTS.WAVE)) {
      type = bytes.subarray(i + 8, i + 12);
      i += 4;
      size -= 4;
    }

    var data = bytes.subarray(i + 8, i + 8 + size);

    if ((0, _byteHelpers.bytesMatch)(type, paths[0])) {
      if (paths.length === 1) {
        // this is the end of the path and we've found the box we were
        // looking for
        results.push(data);
      } else {
        // recursively search for the next box along the path
        var subresults = findFourCC(data, paths.slice(1));

        if (subresults.length) {
          results = results.concat(subresults);
        }
      }
    }

    i += 8 + data.length;
  } // we've finished searching all of bytes


  return results;
};

exports.findFourCC = findFourCC;