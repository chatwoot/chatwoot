var getUint64 = require('../utils/numbers.js').getUint64;

var parseSidx = function parseSidx(data) {
  var view = new DataView(data.buffer, data.byteOffset, data.byteLength),
      result = {
    version: data[0],
    flags: new Uint8Array(data.subarray(1, 4)),
    references: [],
    referenceId: view.getUint32(4),
    timescale: view.getUint32(8)
  },
      i = 12;

  if (result.version === 0) {
    result.earliestPresentationTime = view.getUint32(i);
    result.firstOffset = view.getUint32(i + 4);
    i += 8;
  } else {
    // read 64 bits
    result.earliestPresentationTime = getUint64(data.subarray(i));
    result.firstOffset = getUint64(data.subarray(i + 8));
    i += 16;
  }

  i += 2; // reserved

  var referenceCount = view.getUint16(i);
  i += 2; // start of references

  for (; referenceCount > 0; i += 12, referenceCount--) {
    result.references.push({
      referenceType: (data[i] & 0x80) >>> 7,
      referencedSize: view.getUint32(i) & 0x7FFFFFFF,
      subsegmentDuration: view.getUint32(i + 4),
      startsWithSap: !!(data[i + 8] & 0x80),
      sapType: (data[i + 8] & 0x70) >>> 4,
      sapDeltaTime: view.getUint32(i + 8) & 0x0FFFFFFF
    });
  }

  return result;
};

module.exports = parseSidx;