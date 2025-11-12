"use strict";

var parseSampleFlags = function parseSampleFlags(flags) {
  return {
    isLeading: (flags[0] & 0x0c) >>> 2,
    dependsOn: flags[0] & 0x03,
    isDependedOn: (flags[1] & 0xc0) >>> 6,
    hasRedundancy: (flags[1] & 0x30) >>> 4,
    paddingValue: (flags[1] & 0x0e) >>> 1,
    isNonSyncSample: flags[1] & 0x01,
    degradationPriority: flags[2] << 8 | flags[3]
  };
};

module.exports = parseSampleFlags;