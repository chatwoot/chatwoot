import {toUint8, stringToBytes, bytesMatch} from './byte-helpers.js';

const CONSTANTS = {
  LIST: toUint8([0x4c, 0x49, 0x53, 0x54]),
  RIFF: toUint8([0x52, 0x49, 0x46, 0x46]),
  WAVE: toUint8([0x57, 0x41, 0x56, 0x45])
};

const normalizePath = function(path) {
  if (typeof path === 'string') {
    return stringToBytes(path);
  }

  if (typeof path === 'number') {
    return path;
  }

  return path;
};

const normalizePaths = function(paths) {
  if (!Array.isArray(paths)) {
    return [normalizePath(paths)];
  }

  return paths.map((p) => normalizePath(p));
};

export const findFourCC = function(bytes, paths) {
  paths = normalizePaths(paths);
  bytes = toUint8(bytes);

  let results = [];

  if (!paths.length) {
    // short-circuit the search for empty paths
    return results;
  }

  let i = 0;

  while (i < bytes.length) {
    let type = bytes.subarray(i, i + 4);
    let size = ((bytes[i + 7] << 24 | bytes[i + 6] << 16 | bytes[i + 5] << 8 | bytes[i + 4]) >>> 0);

    // skip LIST/RIFF and get the actual type
    if (bytesMatch(type, CONSTANTS.LIST) || bytesMatch(type, CONSTANTS.RIFF) || bytesMatch(type, CONSTANTS.WAVE)) {
      type = bytes.subarray(i + 8, i + 12);
      i += 4;
      size -= 4;
    }

    const data = bytes.subarray(i + 8, i + 8 + size);

    if (bytesMatch(type, paths[0])) {
      if (paths.length === 1) {
        // this is the end of the path and we've found the box we were
        // looking for
        results.push(data);
      } else {
        // recursively search for the next box along the path
        const subresults = findFourCC(data, paths.slice(1));

        if (subresults.length) {
          results = results.concat(subresults);
        }
      }
    }

    i += 8 + data.length;
  }

  // we've finished searching all of bytes
  return results;
};
