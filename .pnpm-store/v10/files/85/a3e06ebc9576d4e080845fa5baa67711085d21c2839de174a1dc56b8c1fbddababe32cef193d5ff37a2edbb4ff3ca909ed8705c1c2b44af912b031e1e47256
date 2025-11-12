var toUnsigned = require('../utils/bin').toUnsigned;

var getUint64 = require('../utils/numbers.js').getUint64;

var tfdt = function tfdt(data) {
  var result = {
    version: data[0],
    flags: new Uint8Array(data.subarray(1, 4))
  };

  if (result.version === 1) {
    result.baseMediaDecodeTime = getUint64(data.subarray(4));
  } else {
    result.baseMediaDecodeTime = toUnsigned(data[4] << 24 | data[5] << 16 | data[6] << 8 | data[7]);
  }

  return result;
};

module.exports = tfdt;